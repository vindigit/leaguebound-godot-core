class_name ClockResolver
extends RefCounted

## Time consumption per state transition (`SIMULATION_SPEC.md` §9.4).
##
## "Each state transition consumes time from a bounded distribution defined by
## action, pace, game plan, pressure, and rules. Time is never negative and the
## engine cannot begin a new action after the period expires."
##
## Pace is a real input rather than a constant: the offence's tempo instruction
## and its ball handler's Push Transition ↔ Control Tempo slider stretch or
## compress the band, which is what makes a patient team consume more clock per
## possession without changing anyone's ratings.
##
## **`running_clock_inbound_ms` is not charged for every inbound.** The game clock
## restarts on the legal touch whenever it was stopped, so a throw-in that
## follows a whistle costs nothing and `PossessionEngine` emits its `INBOUND` at
## the possession's own starting clock. What this draw models is the other case:
## the restart after a made basket in open play, where the clock never stopped
## and the seconds spent inbounding are seconds the offence genuinely loses
## (`PROJECT_STATUS.md` §5.30). Charging it on a stopped clock is the defect that
## section closes, which is why the caller decides and this function does not.

var _balance: SimulationBalanceProfile
## The competition's pace environment (§4). Every draw is scaled by it, so the
## §14.1 possessions band is a property of the competition rather than of the
## shared time bands.
var _pace_multiplier: float


func _init(
	p_balance: SimulationBalanceProfile,
	p_rules: CompetitionRuleProfile = null,
) -> void:
	_balance = p_balance
	_pace_multiplier = 1.0 if p_rules == null else p_rules.pace_multiplier


## The inbound that happens on a *running* clock. See the class note: the caller
## charges this only when the clock never stopped.
func running_clock_inbound_ms(random_source: RandomSource) -> int:
	return _draw(
		_balance.inbound_seconds_min, _balance.inbound_seconds_max,
		_pace_multiplier, random_source)


func advance_ms(context: PossessionContext, random_source: RandomSource) -> int:
	return _draw(
		_balance.advance_seconds_min, _balance.advance_seconds_max,
		_pace(context), random_source)


func transition_ms(context: PossessionContext, random_source: RandomSource) -> int:
	return _draw(
		_balance.transition_seconds_min, _balance.transition_seconds_max,
		_pace(context), random_source)


func half_court_entry_ms(context: PossessionContext, random_source: RandomSource) -> int:
	return _draw(
		_balance.half_court_entry_seconds_min, _balance.half_court_entry_seconds_max,
		_pace(context), random_source)


func action_ms(context: PossessionContext, action_family: int, random_source: RandomSource) -> int:
	var elapsed: int = 0
	match action_family:
		ActionFamily.Value.RESET:
			elapsed = _draw(
				_balance.reset_seconds_min, _balance.reset_seconds_max,
				_pace(context), random_source)
		ActionFamily.Value.POST_ACTION:
			elapsed = _draw(
				_balance.post_action_seconds_min, _balance.post_action_seconds_max,
				_pace(context), random_source)
		ActionFamily.Value.TRANSITION_ATTACK:
			elapsed = _draw(
				_balance.transition_seconds_min, _balance.transition_seconds_max,
				_pace(context), random_source)
		_:
			elapsed = _draw(
				_balance.action_seconds_min, _balance.action_seconds_max,
				_pace(context), random_source)

	# A selected final action is already under way. If its ordinary bounded draw
	# would cross the horn, schedule its release immediately before the horn so
	# the action can resolve. This applies only once the existing desperation
	# threshold says the designed play must commit; it never changes which shot
	# succeeds and cannot manufacture an attempt from a possession that has not
	# reached action selection.
	if EndgameStrategy.final_release_due(
		context, _balance, _balance.desperation_clock_ms
	):
		var deadline: int = context.state.shot_clock_ms
		if deadline > 1:
			return mini(elapsed, deadline - 1)
	return elapsed


func rebound_ms(random_source: RandomSource) -> int:
	return _draw(
		_balance.rebound_seconds_min, _balance.rebound_seconds_max,
		_pace_multiplier, random_source)


## §9.4: "Dead-ball fouls and free throws use separate event time without
## incorrectly consuming shot-clock time." The possession engine restores the
## shot clock explicitly around these.
func free_throw_ms() -> int:
	return _balance.free_throw_event_seconds * 1000


func dead_ball_ms() -> int:
	return _balance.dead_ball_event_seconds * 1000


## A pace multiplier around 1.0: below one is quicker, above one is slower.
##
## Three separable terms, each bounded on its own: the competition's pace
## environment, the tempo the coach and the ball handler prefer, and §18.2's
## score-and-clock management. Keeping the third outside the second's clamp is
## deliberate — a coach protecting a lead is not expressing a tempo preference,
## he is managing a scoreboard, and a report that wanted to attribute the two
## separately could not if they shared a bound.
func _pace(context: PossessionContext) -> float:
	var coach: float = _balance.opposing_tendency_multiplier(
		context.offense.game_plan.tempo_instruction)
	var player: float = 1.0
	if not context.ball_handler_id.is_empty():
		var handler: PlayerMatchProfile = context.offense_profile(context.ball_handler_id)
		player = _balance.tendency_multiplier(
			handler.tendencies.at(TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO))
	var tempo: float = clampf(
		pow(coach, _balance.coach_preference_share) * pow(player, _balance.player_preference_share),
		0.70,
		1.40)
	return _pace_multiplier * tempo * GameManagement.pace_multiplier(context, _balance)


func _draw(
	minimum_seconds: int,
	maximum_seconds: int,
	pace: float,
	random_source: RandomSource,
) -> int:
	assert(minimum_seconds >= 0 and maximum_seconds >= minimum_seconds,
		"a time band must be non-negative and ordered")
	var seconds: int = random_source.range_int(minimum_seconds, maximum_seconds)
	return maxi(0, int(roundf(float(seconds) * 1000.0 * pace)))
