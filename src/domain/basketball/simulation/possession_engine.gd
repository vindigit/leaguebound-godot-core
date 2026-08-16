class_name PossessionEngine
extends RefCounted

## The multi-action possession state machine (`SIMULATION_SPEC.md` §9).
##
## The §9.2 flow is implemented as written: dead ball or inbound, advance or
## transition, half-court entry when transition does not resolve, initiator and
## action choice, defensive response, then advantage, turnover, foul, reset, or
## shot setup, then shot or free throws, then rebound or change of possession.
##
## The Stage 3 possession contract is enforced here rather than described:
##
## - one `POSSESSION_STARTED` and exactly one terminal `POSSESSION_ENDED`;
## - a stable possession id and an action sequence on every event;
## - an offensive rebound *continues* the possession — same id, no new start,
##   no extra team possession, and the rule profile's shot-clock reset;
## - `POSSESSION_ENDED.team_id` is the offence whose possession ended, with the
##   next-possession team carried in its own field;
## - every terminal result is a real basketball outcome from
##   `PossessionEndReason`.
##
## The engine keeps a working `MatchSnapshot` and folds its own events onto it
## through `MatchStateReducer` as it emits them. Participation, fouls, bonus
## state, and the clock are therefore read from the same reduction the ledger
## will produce — a substituted or fouled-out player cannot keep playing,
## because the engine is looking at the reduced lineup, not at a static list.
##
## Time only ever leaves through `_consume`, which is also the only thing that
## can end a possession on the buzzer. §9.4: "the engine cannot begin a new
## action after the period expires."

var _input: MatchInput
var _rules: CompetitionRuleProfile
var _balance: SimulationBalanceProfile
var _capability: CapabilityCalculator
var _body: BodyEffects
var _reducer: MatchStateReducer
var _matchup_resolver: MatchupResolver
var _participants: ParticipantSelector
var _generator: ActionCandidateGenerator
var _selector: ActionSelector
var _advantage_resolver: AdvantageResolver
var _turnover_resolver: TurnoverResolver
var _shot_resolver: ShotResolver
var _foul_resolver: FoulResolver
var _free_throw_resolver: FreeThrowResolver
var _rebound_resolver: ReboundResolver
var _clock: ClockResolver
var _rotation: RotationResolver

# Working state for the possession currently being resolved.
var _state: MatchSnapshot
var _writer: MatchEventWriter
var _context: PossessionContext
var _points_scored: int
var _terminated: bool
var _end_reason: int
var _next_team_id: StringName
var _live_transfer: bool


func _init(input: MatchInput) -> void:
	assert(input != null, "the possession engine is constructed for one match input")
	_input = input
	_rules = input.rule_profile
	_balance = input.balance_profile
	_capability = CapabilityCalculator.new(input.ratings_profile, _balance)
	_body = BodyEffects.new(_balance)
	_reducer = MatchStateReducer.new(input)
	_matchup_resolver = MatchupResolver.new(_capability, _body)
	_participants = ParticipantSelector.new(_capability, _balance)
	_generator = ActionCandidateGenerator.new(_capability, _body, _balance, _participants)
	_selector = ActionSelector.new()
	_advantage_resolver = AdvantageResolver.new(_capability, _body, _balance)
	_turnover_resolver = TurnoverResolver.new(_capability, _balance)
	_shot_resolver = ShotResolver.new(_capability, _body, _balance)
	_foul_resolver = FoulResolver.new(_capability, _body, _balance)
	_free_throw_resolver = FreeThrowResolver.new(_capability, _balance)
	_rebound_resolver = ReboundResolver.new(_capability, _body, _balance)
	_clock = ClockResolver.new(_balance)
	_rotation = RotationResolver.new(_balance)


## Resolves one complete team possession. `live_start` is true when the previous
## possession ended with a live ball — a steal or a defensive rebound — which is
## what makes a transition opportunity possible (§9.2, §16).
func simulate(
	snapshot: MatchSnapshot,
	input: MatchInput,
	random_source: RandomSource,
	live_start: bool = false,
) -> PossessionResult:
	assert(input == _input, "this engine was constructed for a different match input")
	assert(not snapshot.completed, "a completed match cannot resolve another possession")
	assert(snapshot.clock_ms > 0, "a possession cannot begin after period expiration")

	_state = snapshot.copy()
	_writer = MatchEventWriter.new(
		input.match_id, snapshot.event_sequence, snapshot.period, snapshot.clock_ms)
	_points_scored = 0
	_terminated = false
	_end_reason = PossessionEndReason.Value.TURNOVER
	_next_team_id = &""
	_live_transfer = false

	var offense_team_id: StringName = snapshot.possession_team_id
	var defense_team_id: StringName = input.opposing_team_id(offense_team_id)
	var possession_id: int = snapshot.possession_sequence + 1
	var matchups: MatchupState = _matchup_resolver.resolve(
		input.team_profile(offense_team_id),
		_state.state_for(offense_team_id),
		input.team_profile(defense_team_id),
		_state.state_for(defense_team_id))
	_context = PossessionContext.new(input, _state, offense_team_id, matchups, possession_id)
	_writer.possession_id = possession_id
	_writer.action_sequence = 0

	var start_period: int = snapshot.period
	var start_clock: int = snapshot.clock_ms

	var initiator_id: StringName = _participants.select_initiator(
		_context, random_source.derive(&"initiator"))
	_context.ball_handler_id = initiator_id
	_emit(
		MatchDomainEvent.POSSESSION_STARTED, offense_team_id, initiator_id, &"", &"",
		&"live" if live_start else &"dead_ball")

	_open_possession(random_source.derive(&"open"), live_start)
	_run_action_loop(random_source)

	if not _terminated:
		# The loop exits without terminating only when the safety bound was
		# reached. A possession that never ends is a defect, not an outcome, so
		# it resolves as the violation it actually is.
		_terminate_turnover(TurnoverResolver.shot_clock_violation(_context.ball_handler_id))

	var record := PossessionRecord.new(
		possession_id, offense_team_id, start_period, start_clock,
		_writer.period, _writer.clock_ms, _end_reason, _points_scored,
		_context.action_count, _context.offensive_rebounds, _next_team_id)
	record.live_transfer = _live_transfer
	var result := PossessionResult.new(
		_writer.events, start_clock - _writer.clock_ms, _next_team_id,
		PossessionNode.Value.POSSESSION_END, record)
	assert(result.has_exactly_one_start_and_end(),
		"a possession emits exactly one start and one terminal end event")
	return result


# --- §9.2 opening states ----------------------------------------------------

func _open_possession(random_source: RandomSource, live_start: bool) -> void:
	if not live_start:
		# DEAD_BALL -> INBOUND
		_consume(_clock.inbound_ms(random_source.derive(&"inbound")))
		if _terminated:
			return
		_emit(MatchDomainEvent.INBOUND, _context.offense.team_id, _context.ball_handler_id)
	# ADVANCE
	_consume(_clock.advance_ms(_context, random_source.derive(&"advance")))
	if _terminated:
		return
	_emit(MatchDomainEvent.ADVANCE, _context.offense.team_id, _context.ball_handler_id)
	# TRANSITION_DECISION
	if live_start and _enters_transition(random_source.derive(&"transition")):
		_context.in_transition = true
		_emit(
			MatchDomainEvent.TRANSITION_ENTERED, _context.offense.team_id,
			_context.ball_handler_id)
		return
	# HALF_COURT_ENTRY
	_consume(_clock.half_court_entry_ms(_context, random_source.derive(&"half_court")))
	if _terminated:
		return
	_emit(MatchDomainEvent.HALF_COURT_ENTERED, _context.offense.team_id, _context.ball_handler_id)


func _enters_transition(random_source: RandomSource) -> bool:
	var handler: PlayerMatchProfile = _context.offense_profile(_context.ball_handler_id)
	var tempo: float = _balance.opposing_tendency_multiplier(
		handler.tendencies.at(TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO))
	var coach: float = _balance.tendency_multiplier(_context.offense.game_plan.tempo_instruction)
	var share: float = clampf(
		_balance.transition_share_after_turnover * tempo * coach,
		_balance.transition_share_min,
		_balance.transition_share_max)
	return random_source.next_float() < share


# --- the action loop --------------------------------------------------------

func _run_action_loop(random_source: RandomSource) -> void:
	while not _terminated:
		if _state.shot_clock_ms <= 0:
			_terminate_turnover(TurnoverResolver.shot_clock_violation(_context.ball_handler_id))
			return
		if _context.action_count >= _balance.max_actions_per_possession:
			return
		_context.action_count += 1
		_writer.action_sequence = _context.action_count
		var action_stream: RandomSource = random_source.derive(
			StringName("action:%d" % _context.action_count))

		if _resolve_intentional_foul(action_stream.derive(&"intentional_foul")):
			continue

		var candidates: Array[ActionCandidate] = _generator.generate(_context)
		var selected: ActionCandidate = _selector.select(
			candidates, action_stream.derive(&"selection"))
		_consume(_clock.action_ms(_context, selected.action_family, action_stream.derive(&"time")))
		if _terminated:
			return
		_emit(
			MatchDomainEvent.ACTION_SELECTED, _context.offense.team_id, selected.actor_id,
			selected.target_id, &"", selected.action_id(), &"",
			ShotZone.id_of(selected.zone) if selected.is_shot() else &"")
		_resolve_action(selected, action_stream)


func _resolve_action(candidate: ActionCandidate, action_stream: RandomSource) -> void:
	var advantage: AdvantageResult = _advantage_resolver.resolve(
		_context, candidate, action_stream.derive(&"advantage"))
	_context.advantage = advantage
	if advantage.level != AdvantageLevel.Value.NONE:
		_emit(
			MatchDomainEvent.ADVANTAGE_CREATED, _context.offense.team_id,
			advantage.creator_id, advantage.beneficiary_id, &"",
			candidate.action_id(), advantage.level_id())

	match candidate.action_family:
		ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF:
			_resolve_pass(candidate, advantage, action_stream)
		ActionFamily.Value.PULL_UP, ActionFamily.Value.PUTBACK:
			_resolve_shot(candidate.actor_id, candidate.zone, candidate.dunk,
				candidate.action_family, advantage, action_stream)
		ActionFamily.Value.DRIVE, ActionFamily.Value.TRANSITION_ATTACK:
			_resolve_attack(candidate, advantage, action_stream, _balance.drive_finish_share)
		ActionFamily.Value.POST_ACTION:
			_resolve_attack(candidate, advantage, action_stream, _balance.post_finish_share)
		ActionFamily.Value.PICK_ACTION:
			_resolve_attack(candidate, advantage, action_stream, _balance.pick_finish_share)
		ActionFamily.Value.OFF_BALL_CUT:
			_resolve_cut(candidate, advantage, action_stream)
		ActionFamily.Value.SCREEN:
			_resolve_screen(candidate, advantage, action_stream)
		ActionFamily.Value.RELOCATION:
			_emit(
				MatchDomainEvent.OFF_BALL_ACTION, _context.offense.team_id, candidate.actor_id,
				candidate.target_id, &"", candidate.action_id(), advantage.level_id())
		ActionFamily.Value.RESET:
			_context.advantage = AdvantageResult.new()
			_context.last_passer_id = &""
		_:
			assert(false, "unhandled action family")


# --- action families --------------------------------------------------------

func _resolve_pass(
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	action_stream: RandomSource,
) -> void:
	var turnover: TurnoverOutcome = _turnover_resolver.resolve_pass(
		_context, candidate, advantage, action_stream.derive(&"turnover"))
	if turnover.occurred:
		_terminate_turnover(turnover)
		return
	_emit(
		MatchDomainEvent.PASS_COMPLETED, _context.offense.team_id, candidate.actor_id,
		candidate.target_id, &"", candidate.action_id(), advantage.level_id())
	_context.last_passer_id = candidate.actor_id
	_context.last_pass_created_advantage = advantage.is_material()
	_context.ball_handler_id = candidate.target_id


func _resolve_attack(
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	action_stream: RandomSource,
	finish_share: float,
) -> void:
	var offensive_foul: FoulCall = _foul_resolver.resolve_offensive_foul(
		_context, candidate, action_stream.derive(&"offensive_foul"))
	if offensive_foul.occurred:
		_terminate_offensive_foul(offensive_foul, candidate.actor_id)
		return

	var turnover: TurnoverOutcome = _turnover_resolver.resolve_ball_handling(
		_context, candidate, advantage, action_stream.derive(&"turnover"))
	if turnover.occurred:
		_terminate_turnover(turnover)
		return

	# Contact on the drive itself, before the shot exists. A defender who fouls
	# a driver stops the attempt from happening at all, so this cannot be
	# reached only on the branch where the drive fizzles out — checking it there
	# made a whistle possible only on the possessions where nobody attacked,
	# and left the bonus effectively unreachable (§13.1, §13.2).
	var contact: FoulCall = _foul_resolver.resolve_non_shooting_foul(
		_context, candidate, advantage, action_stream.derive(&"contact_foul"))
	if contact.occurred:
		_resolve_defensive_foul(contact, action_stream.derive(&"contact_consequences"))
		return

	var finishes: bool = (
		advantage.is_material()
		or _context.is_late_clock()
		or action_stream.derive(&"finish").next_float() < finish_share
	)
	if not finishes:
		_context.last_passer_id = &""
		return

	var zone: int = _attack_zone(candidate, advantage)
	var shooter: PlayerMatchProfile = _context.offense_profile(candidate.actor_id)
	var dunk: bool = (
		zone == ShotZone.Value.RESTRICTED_RIM
		and _body.dunk_is_available(shooter.body, shooter.attributes.vertical)
	)
	_resolve_shot(candidate.actor_id, zone, dunk, candidate.action_family, advantage, action_stream)


func _attack_zone(candidate: ActionCandidate, advantage: AdvantageResult) -> int:
	match candidate.action_family:
		ActionFamily.Value.PICK_ACTION:
			return ShotZone.Value.MIDRANGE
		_:
			return (
				ShotZone.Value.RESTRICTED_RIM
				if advantage.is_material()
				else ShotZone.Value.CLOSE_NON_RIM
			)


func _resolve_cut(
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	action_stream: RandomSource,
) -> void:
	_emit(
		MatchDomainEvent.OFF_BALL_ACTION, _context.offense.team_id, candidate.actor_id,
		candidate.target_id, &"", candidate.action_id(), advantage.level_id())
	if not advantage.is_material():
		return
	# A cutter running through traffic draws contact too. §13.1 lists help
	# timing among the sources of a foul, and a tagged cutter is exactly that.
	var contact: FoulCall = _foul_resolver.resolve_non_shooting_foul(
		_context, candidate, advantage, action_stream.derive(&"cut_contact"))
	if contact.occurred:
		_resolve_defensive_foul(contact, action_stream.derive(&"cut_consequences"))
		return
	if action_stream.derive(&"cut_finish").next_float() >= _balance.cut_finish_share:
		return
	# The cut is fed. That feed is a real pass — it can be turned over, and it
	# is the assist candidate if the finish drops.
	var feed := ActionCandidate.new(
		ActionFamily.Value.PASS_SWING, _context.ball_handler_id, 1.0, candidate.actor_id)
	if feed.actor_id == candidate.actor_id:
		return
	var turnover: TurnoverOutcome = _turnover_resolver.resolve_pass(
		_context, feed, advantage, action_stream.derive(&"feed_turnover"))
	if turnover.occurred:
		_terminate_turnover(turnover)
		return
	_emit(
		MatchDomainEvent.PASS_COMPLETED, _context.offense.team_id, feed.actor_id,
		candidate.actor_id, &"", feed.action_id(), advantage.level_id())
	_context.last_passer_id = feed.actor_id
	_context.last_pass_created_advantage = true
	_context.ball_handler_id = candidate.actor_id
	var cutter: PlayerMatchProfile = _context.offense_profile(candidate.actor_id)
	var dunk: bool = _body.dunk_is_available(cutter.body, cutter.attributes.vertical)
	_resolve_shot(
		candidate.actor_id, ShotZone.Value.RESTRICTED_RIM, dunk,
		ActionFamily.Value.OFF_BALL_CUT, advantage, action_stream)


func _resolve_screen(
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	action_stream: RandomSource,
) -> void:
	var illegal: FoulCall = _foul_resolver.resolve_offensive_foul(
		_context, candidate, action_stream.derive(&"illegal_screen"))
	if illegal.occurred:
		_terminate_offensive_foul(illegal, candidate.actor_id)
		return
	# §11.4: screens produce measurable events even when they never appear in
	# the public box score — separation generated, switch caused, advantage
	# continuation. That is the role-evaluation evidence §24.4 requires.
	_emit(
		MatchDomainEvent.SCREEN_SET, _context.offense.team_id, candidate.actor_id,
		candidate.target_id, &"", candidate.action_id(), advantage.level_id())
	if advantage.switch_occurred:
		_context.matchups.switch(candidate.actor_id, candidate.target_id)


# --- shots ------------------------------------------------------------------

func _resolve_shot(
	shooter_id: StringName,
	zone: int,
	dunk: bool,
	action_family: int,
	advantage: AdvantageResult,
	action_stream: RandomSource,
) -> void:
	var shot_stream: RandomSource = action_stream.derive(&"shot")
	var contest: ShotContest = _shot_resolver.build_contest(_context, shooter_id, zone, advantage)
	var assisted_state: StringName = _assisted_state(shooter_id, action_family)
	var defender_id: StringName = contest.primary_defender_id

	_emit(
		MatchDomainEvent.FIELD_GOAL_ATTEMPT, _context.offense.team_id, shooter_id,
		defender_id, &"", ActionFamily.id_of(action_family), contest.band_id(),
		ShotZone.id_of(zone), 0, 1 if dunk else 0)

	var blocker_id: StringName = _shot_resolver.resolve_block(
		_context, shooter_id, zone, dunk, contest, advantage, shot_stream.derive(&"block"))
	if not blocker_id.is_empty():
		_emit(
			MatchDomainEvent.BLOCK, _context.defense.team_id, blocker_id, shooter_id, &"",
			ActionFamily.id_of(action_family), &"", ShotZone.id_of(zone))
		_emit(
			MatchDomainEvent.FIELD_GOAL_MISSED, _context.offense.team_id, shooter_id,
			defender_id, blocker_id, ActionFamily.id_of(action_family), contest.band_id(),
			ShotZone.id_of(zone))
		_resolve_rebound(shooter_id, zone, true, action_stream)
		return

	var foul: FoulCall = _foul_resolver.resolve_shooting_foul(
		_context, shooter_id, zone, contest, shot_stream.derive(&"shooting_foul"))
	var outcome: ShotOutcome = _shot_resolver.resolve(
		_context, shooter_id, zone, dunk, contest, advantage,
		_catch_quality(shooter_id), _movement_load(action_family),
		shot_stream.derive(&"make"))

	if outcome.made:
		_points_scored += outcome.points
		_emit(
			MatchDomainEvent.FIELD_GOAL_MADE, _context.offense.team_id, shooter_id,
			defender_id, &"", ActionFamily.id_of(action_family), assisted_state,
			ShotZone.id_of(zone), outcome.points, 1 if dunk else 0)
		_credit_assist(shooter_id, action_family, zone, shot_stream.derive(&"assist"))
		if foul.occurred:
			# And-one: the basket counts and one free throw follows (§13).
			if _record_foul(foul, _context.defense.team_id):
				_resolve_disqualification(_context.defense.team_id, foul.fouler_id)
			_resolve_free_throws(shooter_id, 1, false, action_stream.derive(&"and_one"))
			return
		_terminate(PossessionEndReason.Value.MADE_SCORE, _context.defense.team_id, false)
		return

	_emit(
		MatchDomainEvent.FIELD_GOAL_MISSED, _context.offense.team_id, shooter_id,
		defender_id, &"", ActionFamily.id_of(action_family), contest.band_id(),
		ShotZone.id_of(zone))
	if foul.occurred:
		if _record_foul(foul, _context.defense.team_id):
			_resolve_disqualification(_context.defense.team_id, foul.fouler_id)
		_resolve_free_throws(
			shooter_id, foul.free_throws, false, action_stream.derive(&"shooting_fouled"))
		return
	_resolve_rebound(shooter_id, zone, false, action_stream)


## §11.3 assist attribution. The pass must have been the delivery that created
## this attempt; a receiver who then created his own shot is unassisted.
func _credit_assist(
	shooter_id: StringName,
	action_family: int,
	zone: int,
	random_source: RandomSource,
) -> void:
	if _context.last_passer_id.is_empty() or _context.last_passer_id == shooter_id:
		return
	if not _pass_created_shot(action_family):
		return
	var passer: PlayerMatchProfile = _context.offense_profile(_context.last_passer_id)
	var passer_runtime: PlayerMatchRuntime = _context.offense_runtime(_context.last_passer_id)
	var read: float = _capability.capability_of(
		CapabilityKey.Value.PASS_READ_QUALITY, passer, passer_runtime)
	var units: float = _capability.differential_units(read, 0.5)
	var probability: float = _balance.opposed_probability(
		_balance.assist_base, units, _balance.assist_floor, _balance.assist_ceiling)
	if random_source.next_float() >= probability:
		return
	_emit(
		MatchDomainEvent.ASSIST, _context.offense.team_id, _context.last_passer_id,
		shooter_id, &"", ActionFamily.id_of(action_family), &"", ShotZone.id_of(zone))
	_context.last_passer_id = &""


func _pass_created_shot(action_family: int) -> bool:
	return (
		action_family == ActionFamily.Value.PULL_UP
		or action_family == ActionFamily.Value.OFF_BALL_CUT
		or action_family == ActionFamily.Value.POST_ACTION
	)


func _assisted_state(shooter_id: StringName, action_family: int) -> StringName:
	if _context.last_passer_id.is_empty() or _context.last_passer_id == shooter_id:
		return &"unassisted"
	if _pass_created_shot(action_family):
		return &"catch_and_shoot"
	return &"created"


func _catch_quality(shooter_id: StringName) -> float:
	if _context.last_passer_id.is_empty() or _context.last_passer_id == shooter_id:
		return 1.0
	var passer: PlayerMatchProfile = _context.offense_profile(_context.last_passer_id)
	var passer_runtime: PlayerMatchRuntime = _context.offense_runtime(_context.last_passer_id)
	var accuracy: float = _capability.capability_of(
		CapabilityKey.Value.PASS_ACCURACY, passer, passer_runtime)
	# A pass that was completed at all is mostly a clean catch; accuracy moves
	# the remainder. §19.1 lets chemistry add a modest bounded amount on top.
	var floor_share: float = _balance.catch_quality_floor
	return clampf(
		floor_share
		+ accuracy * (1.0 - floor_share)
		+ _context.offense.chemistry * _balance.chemistry_pass_bonus_max,
		0.0,
		1.0)


func _movement_load(action_family: int) -> float:
	return SimulationBalanceProfile.ACTION_INTENSITY_SHARES[action_family]


# --- fouls and free throws --------------------------------------------------

func _resolve_intentional_foul(random_source: RandomSource) -> bool:
	if _context.ball_handler_id.is_empty():
		return false
	var call: FoulCall = _foul_resolver.resolve_intentional_foul(_context, random_source)
	if not call.occurred:
		return false
	_resolve_defensive_foul(call, random_source.derive(&"intentional_consequences"))
	return true


func _resolve_defensive_foul(call: FoulCall, random_source: RandomSource) -> void:
	if _record_foul(call, _context.defense.team_id):
		# The replacement enters before the free throws, as the rules require.
		_resolve_disqualification(_context.defense.team_id, call.fouler_id)
	_resolve_defensive_foul_consequences(call, random_source)


## The bonus branch. Free throws when the fouling team is over the threshold,
## an inbound with the rule profile's shot-clock reset when it is not.
func _resolve_defensive_foul_consequences(
	call: FoulCall,
	random_source: RandomSource,
) -> void:
	var team_fouls: int = _context.defense_state().team_fouls
	var attempts: int = _rules.bonus_free_throws_for(team_fouls)
	if attempts <= 0:
		_consume(_clock.dead_ball_ms())
		if _terminated:
			return
		_emit(
			MatchDomainEvent.SHOT_CLOCK_RESET, _context.offense.team_id,
			_context.ball_handler_id, &"", &"", &"", &"", &"", 0,
			_rules.offensive_rebound_reset_seconds * 1000)
		return
	_resolve_free_throws(
		call.drawn_by_id, attempts, _rules.is_one_and_one(team_fouls), random_source)


## §13.2: attempts, makes, team fouls, personal fouls, bonus state, and
## possession continuation are attributed exactly once. A missed final attempt
## is live where the rules say so.
func _resolve_free_throws(
	shooter_id: StringName,
	attempts: int,
	one_and_one: bool,
	random_source: RandomSource,
) -> void:
	assert(attempts > 0, "a free-throw sequence needs at least one attempt")
	var on_court: Array[StringName] = _context.offense_on_court()
	if shooter_id.is_empty() or not _context.offense_state().is_on_court(shooter_id):
		# The fouled player left the floor on the same whistle. The rules give
		# the attempts to a team-mate who is on court.
		shooter_id = on_court[0]
	_emit(
		MatchDomainEvent.FREE_THROW_AWARDED, _context.offense.team_id, shooter_id,
		&"", &"", &"", &"", &"", 0, attempts)

	var last_made: bool = false
	for index in range(attempts):
		# §9.4: free throws use separate event time and do not consume the shot
		# clock; the possession either ends or resets after the sequence.
		_consume(_clock.free_throw_ms())
		if _terminated:
			return
		var made: bool = _free_throw_resolver.resolve(
			_context, shooter_id, random_source.derive(StringName("attempt:%d" % (index + 1))))
		last_made = made
		if made:
			_points_scored += 1
		_emit(
			MatchDomainEvent.FREE_THROW_MADE if made else MatchDomainEvent.FREE_THROW_MISSED,
			_context.offense.team_id, shooter_id, &"", &"", &"", &"", &"", 0, index + 1)
		if one_and_one and index == 0 and not made:
			break

	if not last_made and _rules.final_free_throw_reboundable:
		_resolve_rebound(shooter_id, ShotZone.Value.RESTRICTED_RIM, false, random_source)
		return
	if not last_made:
		_terminate(PossessionEndReason.Value.DEFENSIVE_REBOUND, _context.defense.team_id, false)
		return
	_terminate(PossessionEndReason.Value.MADE_SCORE, _context.defense.team_id, false)


## Records the whistle and reports whether it disqualified the fouler.
##
## Disqualification is deliberately *not* applied here. The consequence of the
## foul — the turnover, or the free throws — is part of the same whistle and has
## to be attributed before the player leaves the floor. Applying it inline
## checked an offensive fouler out before his own turnover was recorded, which
## produced a ledger where a player who was not on court committed a turnover.
func _record_foul(call: FoulCall, fouling_team_id: StringName) -> bool:
	_emit(
		MatchDomainEvent.FOUL, fouling_team_id, call.fouler_id, call.drawn_by_id, &"",
		&"", call.type_id(), &"" if call.shooting_zone < 0 else ShotZone.id_of(call.shooting_zone))
	var team_state: TeamMatchState = _state.state_for(fouling_team_id)
	var runtime: PlayerMatchRuntime = team_state.runtime_by_id(call.fouler_id)
	return runtime.foul_count >= _rules.personal_foul_limit


## §5.1: a disqualified player leaves and cannot re-enter. On a defensive foul
## this happens before the free throws, exactly as the rules require.
func _resolve_disqualification(fouling_team_id: StringName, player_id: StringName) -> void:
	_emit(MatchDomainEvent.FOUL_OUT, fouling_team_id, player_id)
	_apply_substitutions(fouling_team_id)


## Substitutions inside a possession. A foul-out cannot wait for a convenient
## boundary: §5.1 forbids the player from remaining on court at all.
func _apply_substitutions(team_id: StringName) -> void:
	for order in _rotation.plan(_state, _input, team_id):
		_emit(
			MatchDomainEvent.CHECK_OUT, team_id, order.outgoing_id, &"", &"", &"",
			order.reason_id())
		_emit(
			MatchDomainEvent.CHECK_IN, team_id, order.incoming_id, &"", &"", &"",
			order.reason_id())


# --- rebounding -------------------------------------------------------------

func _resolve_rebound(
	shooter_id: StringName,
	zone: int,
	blocked: bool,
	action_stream: RandomSource,
) -> void:
	var rebound_stream: RandomSource = action_stream.derive(&"rebound")
	_consume(_clock.rebound_ms(rebound_stream.derive(&"time")))
	if _terminated:
		return
	var outcome: ReboundOutcome = _rebound_resolver.resolve(
		_context, shooter_id, zone, blocked, rebound_stream.derive(&"selection"))
	_emit(
		MatchDomainEvent.REBOUND, outcome.team_id, outcome.rebounder_id, shooter_id, &"",
		&"", outcome.side_id(), ShotZone.id_of(zone))

	if not outcome.offensive:
		_terminate(PossessionEndReason.Value.DEFENSIVE_REBOUND, _context.defense.team_id, true)
		return

	# §9.4 / §14.4: the possession continues. Same id, no new start event, no
	# extra team possession, and the rule profile's own shot-clock reset.
	_context.offensive_rebounds += 1
	_context.ball_handler_id = outcome.rebounder_id
	_context.last_passer_id = &""
	_context.in_transition = false
	_emit(
		MatchDomainEvent.SHOT_CLOCK_RESET, _context.offense.team_id, outcome.rebounder_id,
		&"", &"", &"", &"", &"", 0, _rules.offensive_rebound_reset_seconds * 1000)

	var loose_ball: FoulCall = _foul_resolver.resolve_loose_ball_foul(
		_context, outcome.rebounder_id, _context.defender_of(outcome.rebounder_id),
		rebound_stream.derive(&"loose_ball"))
	if loose_ball.occurred:
		if loose_ball.foul_type == FoulType.Value.OFFENSIVE:
			_terminate_offensive_foul(loose_ball, loose_ball.fouler_id)
			return
		_resolve_defensive_foul(loose_ball, rebound_stream.derive(&"loose_ball_consequences"))
		return

	# PUTBACK_DECISION (§9.1): straight back up, or reset into the half court
	# through the ordinary action loop.
	if not _rebound_resolver.attempts_putback(
		_context, outcome.rebounder_id, rebound_stream.derive(&"putback")
	):
		return
	_context.action_count += 1
	_writer.action_sequence = _context.action_count
	var putback: ActionCandidate = _generator.putback_candidate(_context, outcome.rebounder_id)
	_emit(
		MatchDomainEvent.ACTION_SELECTED, _context.offense.team_id, putback.actor_id,
		&"", &"", putback.action_id(), &"", ShotZone.id_of(putback.zone))
	_resolve_shot(
		putback.actor_id, putback.zone, putback.dunk, ActionFamily.Value.PUTBACK,
		AdvantageResult.new(AdvantageLevel.Value.SMALL, putback.actor_id, putback.actor_id),
		rebound_stream.derive(&"putback_shot"))


# --- termination ------------------------------------------------------------

func _emit_turnover(turnover: TurnoverOutcome) -> void:
	_emit(
		MatchDomainEvent.TURNOVER, _context.offense.team_id, turnover.offender_id,
		turnover.defender_id, &"", &"", turnover.cause_id())
	if turnover.credits_steal():
		_emit(
			MatchDomainEvent.STEAL, _context.defense.team_id, turnover.defender_id,
			turnover.offender_id, &"", &"", turnover.cause_id())


func _terminate_turnover(turnover: TurnoverOutcome) -> void:
	_emit_turnover(turnover)
	_terminate(
		PossessionEndReason.Value.TURNOVER, _context.defense.team_id, turnover.credits_steal())


## An offensive foul: the whistle, then the turnover it caused, then any
## disqualification, then the possession end. That order is what keeps the
## fouler on court for his own turnover.
func _terminate_offensive_foul(call: FoulCall, offender_id: StringName) -> void:
	var disqualified: bool = _record_foul(call, _context.offense.team_id)
	_emit_turnover(TurnoverResolver.offensive_foul_turnover(offender_id))
	if disqualified:
		_resolve_disqualification(_context.offense.team_id, call.fouler_id)
	_terminate(PossessionEndReason.Value.TURNOVER, _context.defense.team_id, false)


func _terminate(reason: int, next_team_id: StringName, live_transfer: bool) -> void:
	if _terminated:
		return
	_terminated = true
	_end_reason = reason
	_live_transfer = live_transfer
	_next_team_id = (
		next_team_id
		if PossessionEndReason.transfers_possession(reason)
		else _context.offense.team_id
	)
	# §5: `team_id` is the offence whose possession ended; the next-possession
	# team travels in its own field and is never overloaded onto this one.
	var event := _writer.emit(
		MatchDomainEvent.POSSESSION_ENDED, _context.offense.team_id, &"", &"", &"",
		&"", PossessionEndReason.id_of(reason), &"", 0, _points_scored, _next_team_id)
	_reducer.apply_event(_state, event)


# --- emission ---------------------------------------------------------------

func _emit(
	event_type: StringName,
	team_id: StringName,
	primary_player_id: StringName = &"",
	secondary_player_id: StringName = &"",
	tertiary_player_id: StringName = &"",
	action_id: StringName = &"",
	detail_id: StringName = &"",
	zone_id: StringName = &"",
	points: int = 0,
	amount: int = 0,
) -> void:
	assert(not _terminated, "a terminated possession cannot emit further events")
	var event := _writer.emit(
		event_type, team_id, primary_player_id, secondary_player_id, tertiary_player_id,
		action_id, detail_id, zone_id, points, amount)
	_reducer.apply_event(_state, event)


## Consumes clock time. This is the only path that ends a possession on the
## buzzer, and every caller checks `_terminated` immediately afterwards.
func _consume(elapsed_ms: int) -> void:
	if _terminated:
		return
	_writer.consume(elapsed_ms)
	if _writer.clock_ms <= 0:
		_terminate(PossessionEndReason.Value.PERIOD_EXPIRED, _context.offense.team_id, false)
