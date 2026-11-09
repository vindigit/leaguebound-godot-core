class_name AdvantageResolver
extends RefCounted

## `SIMULATION_SPEC.md` §11.1: every action produces an `AdvantageResult` before
## a shot or terminal outcome.
##
## The examples in §11.1 name the comparisons directly, and each is implemented
## against the §5.2 capabilities rather than against raw ratings:
##
## - a drive compares Handle Creation, Court Speed, and Ball Security against
##   containment, help recognition, and interior positioning;
## - a pass compares Pass Accuracy and Read Quality against denial and
##   passing-lane defence;
## - a screen combines screener force and handler creation against navigation
##   and coverage;
## - a cut combines Off-Ball Timing and speed against defensive awareness.
##
## The advantage carries the turnover risk and foul pressure the continuation
## will consume, so a possession's later steps inherit what its earlier steps
## created.

var _capability: CapabilityCalculator
var _body: BodyEffects
var _balance: SimulationBalanceProfile

## The share of the non-material remainder that still counts as a small
## advantage. Without it, "not clear" collapses to "nothing happened".
const SMALL_ADVANTAGE_SHARE: float = 0.45
## The share of material advantages that break the defence down entirely.
const BREAKDOWN_SHARE: float = 0.25


func _init(
	p_capability: CapabilityCalculator,
	p_body: BodyEffects,
	p_balance: SimulationBalanceProfile,
) -> void:
	_capability = p_capability
	_body = p_body
	_balance = p_balance


func resolve(
	context: PossessionContext,
	candidate: ActionCandidate,
	random_source: RandomSource,
) -> AdvantageResult:
	var actor: PlayerMatchProfile = context.offense_profile(candidate.actor_id)
	var actor_runtime: PlayerMatchRuntime = context.offense_runtime(candidate.actor_id)
	var defender_id: StringName = context.defender_of(candidate.actor_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)
	var coverage: int = context.defense.game_plan.coverage_family

	var attack: float = _attack_capability(context, candidate, actor, actor_runtime)
	var resist: float = _resist_capability(context, candidate, defender, defender_runtime)
	# §6.1 matchups: size and speed mismatch enters advantage, and only here.
	var mismatch: float = _body.size_mismatch(actor.body, defender.body)
	if candidate.action_family == ActionFamily.Value.DRIVE:
		# A driver benefits from being quicker, not taller; a size edge helps
		# him absorb contact rather than beat the first step.
		mismatch *= 0.5
	var units: float = _capability.differential_units(attack + mismatch, resist)
	var material: float = _balance.opposed_probability(
		_balance.advantage_base, units, _balance.advantage_floor, _balance.advantage_ceiling)

	var draw: float = random_source.next_float()
	var level: int = AdvantageLevel.Value.NONE
	if draw < material * BREAKDOWN_SHARE:
		level = AdvantageLevel.Value.BREAKDOWN
	elif draw < material:
		level = AdvantageLevel.Value.CLEAR
	elif draw < material + (1.0 - material) * SMALL_ADVANTAGE_SHARE:
		level = AdvantageLevel.Value.SMALL

	var switched: bool = false
	if (
		candidate.action_family == ActionFamily.Value.PICK_ACTION
		or candidate.action_family == ActionFamily.Value.SCREEN
		or candidate.action_family == ActionFamily.Value.HANDOFF
	):
		switched = random_source.next_float() < CoverageFamily.switch_share(coverage)

	var creator_id: StringName = candidate.actor_id
	var beneficiary_id: StringName = candidate.actor_id
	if candidate.action_family == ActionFamily.Value.SCREEN and not candidate.target_id.is_empty():
		# A screen is set *for* someone: the screener creates, the handler
		# benefits. §11.4 requires that contribution to be visible even though
		# it never becomes a box-score statistic.
		beneficiary_id = candidate.target_id
	elif (
		ActionFamily.transfers_ball(candidate.action_family)
		and not candidate.target_id.is_empty()
	):
		# §11.1 gives `creatorId` and `beneficiaryId` separate fields precisely
		# so a pass can create for somebody else. The passer was recorded as his
		# own beneficiary here, which meant the openness a completed pass
		# produced was credited to the man who no longer had the ball: the §10.3
		# advantage continuation lifted the *passer's* next candidates, and the
		# receiver — the player the delivery actually freed — carried none of it
		# into his own decision. A pass could therefore never create a shot.
		beneficiary_id = candidate.target_id

	return AdvantageResult.new(
		level,
		creator_id,
		beneficiary_id,
		level >= AdvantageLevel.Value.CLEAR,
		switched,
		_turnover_risk(context, candidate, coverage, level),
		_foul_pressure(context, candidate, coverage, level))


func _attack_capability(
	context: PossessionContext,
	candidate: ActionCandidate,
	actor: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
) -> float:
	match candidate.action_family:
		ActionFamily.Value.DRIVE, ActionFamily.Value.TRANSITION_ATTACK:
			return (
				_capability.capability_of(CapabilityKey.Value.HANDLE_CREATION, actor, runtime) * 0.55
				+ _capability.capability_of(CapabilityKey.Value.COURT_SPEED, actor, runtime) * 0.25
				+ _capability.capability_of(CapabilityKey.Value.BALL_SECURITY, actor, runtime) * 0.20
			)
		ActionFamily.Value.PICK_ACTION:
			var screener_force: float = 0.0
			if not candidate.target_id.is_empty():
				screener_force = _capability.capability_of(
					CapabilityKey.Value.CONTACT_FORCE,
					context.offense_profile(candidate.target_id),
					context.offense_runtime(candidate.target_id))
			return (
				_capability.capability_of(CapabilityKey.Value.HANDLE_CREATION, actor, runtime) * 0.60
				+ screener_force * 0.40
			)
		ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF:
			# §11.3: "Vision increases recognition and creation; Passing
			# increases execution." This roll *is* the creation — whether the
			# delivery found a team-mate the defence had left — so Read Quality
			# leads it and Pass Accuracy supports it. Execution is charged
			# separately, against the same two capabilities in the opposite
			# proportion, by `TurnoverResolver.resolve_pass` and by the catch
			# quality the delivery carries. That is what keeps the two
			# attributes distinct: high Vision with poor Passing sees the open
			# man and turns it over, high Passing with poor Vision delivers the
			# obvious pass safely and creates less.
			return (
				_capability.capability_of(CapabilityKey.Value.PASS_ACCURACY, actor, runtime) * 0.40
				+ _capability.capability_of(CapabilityKey.Value.PASS_READ_QUALITY, actor, runtime) * 0.60
			)
		ActionFamily.Value.POST_ACTION:
			return (
				_capability.capability_of(CapabilityKey.Value.RIM_TOUCH_FINISH, actor, runtime) * 0.55
				+ _capability.capability_of(CapabilityKey.Value.CONTACT_FORCE, actor, runtime) * 0.45
			)
		ActionFamily.Value.SCREEN:
			return (
				_capability.capability_of(CapabilityKey.Value.CONTACT_FORCE, actor, runtime) * 0.55
				+ _capability.capability_of(CapabilityKey.Value.OFF_BALL_TIMING, actor, runtime) * 0.45
			)
		_:
			return (
				_capability.capability_of(CapabilityKey.Value.OFF_BALL_TIMING, actor, runtime) * 0.65
				+ _capability.capability_of(CapabilityKey.Value.COURT_SPEED, actor, runtime) * 0.35
			)


func _resist_capability(
	context: PossessionContext,
	candidate: ActionCandidate,
	defender: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
) -> float:
	var execution: float = clampf(
		context.defense.chemistry * 0.5 + runtime.current_energy() * 0.5, 0.0, 1.0)
	var help: float = _capability.help_recognition(defender, runtime, execution)
	match candidate.action_family:
		ActionFamily.Value.DRIVE, ActionFamily.Value.TRANSITION_ATTACK, ActionFamily.Value.PICK_ACTION:
			return (
				_capability.capability_of(
					CapabilityKey.Value.POINT_OF_ATTACK_CONTAINMENT, defender, runtime) * 0.60
				+ help * 0.20
				+ _interior_help(context) * 0.20
			)
		ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF:
			return (
				_capability.capability_of(
					CapabilityKey.Value.PASSING_LANE_DEFENSE, defender, runtime) * 0.55
				+ help * 0.45
			)
		ActionFamily.Value.POST_ACTION:
			return (
				_capability.capability_of(
					CapabilityKey.Value.INTERIOR_POSITIONING, defender, runtime) * 0.70
				+ help * 0.30
			)
		_:
			return (
				help * 0.55
				+ _capability.capability_of(
					CapabilityKey.Value.PERIMETER_CONTEST, defender, runtime) * 0.45
			)


## The best rim protection currently on the floor for the defence, weighted by
## how much the coverage actually sends help (§15.2).
func _interior_help(context: PossessionContext) -> float:
	var best: float = 0.0
	for defender_id in context.defense_on_court():
		var defender: PlayerMatchProfile = context.defense_profile(defender_id)
		var runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)
		best = maxf(best, _capability.capability_of(
			CapabilityKey.Value.RIM_PROTECTION, defender, runtime))
	return best * CoverageFamily.help_share(context.defense.game_plan.coverage_family)


func _turnover_risk(
	context: PossessionContext,
	candidate: ActionCandidate,
	coverage: int,
	level: int,
) -> float:
	var base: float = 0.35
	match candidate.action_family:
		ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF:
			base = 0.55
		ActionFamily.Value.DRIVE, ActionFamily.Value.PICK_ACTION:
			base = 0.45
		ActionFamily.Value.TRANSITION_ATTACK:
			base = 0.50
		ActionFamily.Value.POST_ACTION:
			base = 0.40
		_:
			base = 0.20
	var pressure: float = CoverageFamily.ball_pressure_share(coverage)
	var relief: float = AdvantageLevel.quality_share(level) * 0.35
	return clampf(base * (0.70 + pressure * 0.60) - relief, 0.0, 1.0)


func _foul_pressure(
	context: PossessionContext,
	candidate: ActionCandidate,
	coverage: int,
	level: int,
) -> float:
	var base: float = 0.25
	match candidate.action_family:
		ActionFamily.Value.DRIVE, ActionFamily.Value.TRANSITION_ATTACK:
			base = 0.65
		ActionFamily.Value.POST_ACTION:
			base = 0.55
		ActionFamily.Value.PICK_ACTION:
			base = 0.40
		ActionFamily.Value.OFF_BALL_CUT:
			base = 0.35
		ActionFamily.Value.SCREEN:
			base = 0.30
		_:
			base = 0.15
	var pressure: float = CoverageFamily.ball_pressure_share(coverage)
	return clampf(base * (0.75 + pressure * 0.50) + AdvantageLevel.quality_share(level) * 0.15, 0.0, 1.0)
