class_name MatchStateReducer
extends RefCounted

## The only function that changes match state (`SIMULATION_SPEC.md` §5.1).
##
## "Score, clock, possession, fouls, and box score can change only through
## domain events." That is enforced structurally: nothing outside this class
## writes to a `MatchSnapshot` during a match, and the possession engine folds
## its own events onto its working copy with the same `apply_event`, so the
## state it decides from and the state the ledger produces cannot diverge.
##
## Clock advance is derived from the events' own timestamps. Minutes played and
## acute fatigue therefore reconcile from the ledger alone — there is no second
## counter that could drift out of step with it (§24.3).

var _fatigue_resolver: FatigueResolver
var _rules: CompetitionRuleProfile
var _input: MatchInput


func _init(p_input: MatchInput) -> void:
	assert(p_input != null, "the reducer needs the match input to read the rule profile")
	_input = p_input
	_rules = p_input.rule_profile
	_fatigue_resolver = FatigueResolver.new(p_input.balance_profile)


## Folds one event into the supplied state, in place.
func apply_event(state: MatchSnapshot, event: MatchDomainEvent) -> void:
	assert(event.sequence == state.event_sequence + 1,
		"event application must be exactly once and in sequence")
	state.event_sequence = event.sequence
	_advance_clock(state, event)

	match event.event_type:
		MatchDomainEvent.PERIOD_STARTED:
			_apply_period_started(state, event)
		MatchDomainEvent.PERIOD_ENDED:
			state.clock_ms = 0
		MatchDomainEvent.MATCH_ENDED:
			# §5.1: "Match completion is terminal except for the idempotent
			# career-result commit."
			state.completed = true
		MatchDomainEvent.CHECK_IN:
			var entering: PlayerMatchRuntime = state.state_for(event.team_id).runtime_by_id(
				event.primary_player_id)
			assert(entering.is_eligible_to_play(),
				"a fouled-out, ejected, or unavailable player cannot check in")
			entering.on_court = true
			entering.stint_ms = 0
			if event.period == 1 and event.clock_ms == _rules.period_length_ms(1):
				entering.started = true
		MatchDomainEvent.CHECK_OUT:
			var leaving: PlayerMatchRuntime = state.state_for(event.team_id).runtime_by_id(
				event.primary_player_id)
			leaving.on_court = false
			leaving.rest_ms = 0
		MatchDomainEvent.POSSESSION_STARTED:
			state.possession_id = event.possession_id
			state.possession_sequence = maxi(state.possession_sequence, event.possession_id)
			state.possession_team_id = event.team_id
			state.shot_clock_ms = mini(_rules.shot_clock_seconds * 1000, state.clock_ms)
			if not event.primary_player_id.is_empty():
				state.state_for(event.team_id).runtime_by_id(event.primary_player_id).touches += 1
		MatchDomainEvent.POSSESSION_ENDED:
			# §24.2 engine possessions: counted from the terminal record of the
			# offence whose possession ended, never from a presentation event.
			state.state_for(event.team_id).possessions += 1
			state.possession_id = 0
			state.next_possession_team_id = event.next_team_id
			state.possession_team_id = event.next_team_id
		MatchDomainEvent.SHOT_CLOCK_RESET:
			state.shot_clock_ms = mini(event.amount, state.clock_ms)
		MatchDomainEvent.PASS_COMPLETED:
			if not event.secondary_player_id.is_empty():
				state.state_for(event.team_id).runtime_by_id(event.secondary_player_id).touches += 1
		MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			var shooter: PlayerMatchRuntime = state.state_for(event.team_id).runtime_by_id(
				event.primary_player_id)
			shooter.usage_events += 1
		MatchDomainEvent.FIELD_GOAL_MADE:
			state.state_for(event.team_id).add_points(event.points)
		MatchDomainEvent.TURNOVER:
			state.state_for(event.team_id).runtime_by_id(event.primary_player_id).usage_events += 1
		MatchDomainEvent.FOUL:
			_apply_foul(state, event)
		MatchDomainEvent.FOUL_OUT:
			state.state_for(event.team_id).runtime_by_id(event.primary_player_id).fouled_out = true
		MatchDomainEvent.FREE_THROW_AWARDED:
			state.state_for(event.team_id).runtime_by_id(event.primary_player_id).usage_events += 1
		MatchDomainEvent.FREE_THROW_MADE:
			state.state_for(event.team_id).add_points(1)
		MatchDomainEvent.ACTION_SELECTED:
			_apply_action_load(state, event)
		_:
			pass


func apply_events(snapshot: MatchSnapshot, events: Array[MatchDomainEvent]) -> MatchSnapshot:
	var next: MatchSnapshot = snapshot.copy()
	for event in events:
		apply_event(next, event)
	return next


func _apply_period_started(state: MatchSnapshot, event: MatchDomainEvent) -> void:
	state.period = event.period
	state.clock_ms = event.clock_ms
	state.shot_clock_ms = mini(_rules.shot_clock_seconds * 1000, state.clock_ms)
	if event.period > _rules.regulation_periods:
		state.overtime_periods = event.period - _rules.regulation_periods
	if state.home.period_scores.size() < event.period:
		state.home.add_period()
		state.away.add_period()
	if _rules.team_fouls_reset_each_period:
		state.home.team_fouls = 0
		state.away.team_fouls = 0


func _apply_foul(state: MatchSnapshot, event: MatchDomainEvent) -> void:
	var foul_type: int = FoulType.from_id(event.detail_id)
	var team_state: TeamMatchState = state.state_for(event.team_id)
	team_state.runtime_by_id(event.primary_player_id).foul_count += 1
	if FoulType.advances_team_fouls(foul_type):
		team_state.team_fouls += 1
		team_state.total_team_fouls += 1


func _apply_action_load(state: MatchSnapshot, event: MatchDomainEvent) -> void:
	if event.action_id.is_empty() or event.primary_player_id.is_empty():
		return
	_fatigue_resolver.apply_action_load(
		state, event.team_id, event.primary_player_id, ActionFamily.from_id(event.action_id))


## Moves the clock to the event's timestamp, charging the elapsed time to
## minutes played, acute fatigue, bench recovery, and the shot clock.
func _advance_clock(state: MatchSnapshot, event: MatchDomainEvent) -> void:
	if event.period != state.period:
		# A period boundary is not elapsed time; `PERIOD_STARTED` sets the clock.
		return
	if event.clock_ms >= state.clock_ms:
		return
	var elapsed: int = state.clock_ms - event.clock_ms
	state.clock_ms = event.clock_ms
	state.shot_clock_ms = maxi(0, state.shot_clock_ms - elapsed)
	_fatigue_resolver.apply_elapsed(state, _input, elapsed)
