class_name TurnoverResolver
extends RefCounted

## Live-ball turnovers with a cause and an actor (`SIMULATION_SPEC.md` §11.2).
##
## "Turnover probability is built from action risk, ball security/pass quality,
## defender disruption, pressure, fatigue, decision quality, spacing, and
## badges. A steal is credited only when a defender caused a qualifying
## live-ball turnover."
##
## The defender who *could* have caused it is chosen from the actual defensive
## context — the assignment for on-ball actions, the passing lane for passes —
## and the split between an unforced mistake and a defender-caused one is a
## second, separate check. That separation is what keeps steal rate and turnover
## rate independently tunable (§27.2).

var _capability: CapabilityCalculator
var _balance: SimulationBalanceProfile


func _init(p_capability: CapabilityCalculator, p_balance: SimulationBalanceProfile) -> void:
	_capability = p_capability
	_balance = p_balance


## The on-ball turnover check for a drive, post, pick, or transition attack.
func resolve_ball_handling(
	context: PossessionContext,
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	random_source: RandomSource,
) -> TurnoverOutcome:
	var actor: PlayerMatchProfile = context.offense_profile(candidate.actor_id)
	var actor_runtime: PlayerMatchRuntime = context.offense_runtime(candidate.actor_id)
	var defender_id: StringName = context.defender_of(candidate.actor_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)

	var security: float = _capability.capability_of(
		CapabilityKey.Value.BALL_SECURITY, actor, actor_runtime)
	var disruption: float = _capability.capability_of(
		CapabilityKey.Value.ON_BALL_DISRUPTION, defender, defender_runtime)
	var units: float = _capability.differential_units(disruption, security)

	# A defender-caused strip and an unforced lost handle are separate events
	# with separate rates. §14.3's "valid strip converts to steal" figure is
	# conditional on the *attempt*, so the attempt has its own frequency —
	# driven by coverage pressure and the defender's gamble slider — rather than
	# being carved out of the turnovers that happened anyway.
	if _attempts_disruption(context, defender, _balance.steal_opportunity_on_ball, random_source):
		var strip: float = _balance.opposed_probability(
			_balance.steal_conversion_base,
			units,
			_balance.steal_conversion_floor,
			_balance.steal_conversion_ceiling)
		if random_source.next_float() < strip:
			return TurnoverOutcome.new(
				true, TurnoverCause.Value.STRIP, candidate.actor_id, defender_id)

	var probability: float = _balance.opposed_probability(
		_balance.turnover_base * (0.60 + advantage.turnover_risk),
		units,
		_balance.turnover_floor,
		_balance.turnover_ceiling)
	if random_source.next_float() >= probability:
		return TurnoverOutcome.none()
	return TurnoverOutcome.new(
		true, TurnoverCause.Value.LOST_HANDLE, candidate.actor_id, defender_id)


## The pass turnover check. The relevant defender is the one covering the
## *receiver*, because that is who plays the lane.
func resolve_pass(
	context: PossessionContext,
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	random_source: RandomSource,
) -> TurnoverOutcome:
	var passer: PlayerMatchProfile = context.offense_profile(candidate.actor_id)
	var passer_runtime: PlayerMatchRuntime = context.offense_runtime(candidate.actor_id)
	var defender_id: StringName = context.defender_of(candidate.target_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)

	var accuracy: float = _capability.capability_of(
		CapabilityKey.Value.PASS_ACCURACY, passer, passer_runtime)
	var read: float = _capability.capability_of(
		CapabilityKey.Value.PASS_READ_QUALITY, passer, passer_runtime)
	# §19.1: chemistry has a modest bounded effect on pass and catch quality.
	var quality: float = clampf(
		accuracy * 0.6 + read * 0.4 + context.offense.chemistry * _balance.chemistry_pass_bonus_max,
		0.0,
		1.0)
	var denial: float = _capability.capability_of(
		CapabilityKey.Value.PASSING_LANE_DEFENSE, defender, defender_runtime)
	# §10.4: a creative passer attempts riskier deliveries. The slider changes
	# the risk taken, never the accuracy applied to it.
	var creativity: float = _balance.tendency_multiplier(
		passer.tendencies.at(TendencySlider.Value.SAFE_CREATIVE_PASSING))
	var units: float = _capability.differential_units(denial, quality)

	# The lane is played on its own terms, exactly as the strip is.
	if _attempts_disruption(context, defender, _balance.steal_opportunity_pass, random_source):
		var interception: float = _balance.opposed_probability(
			_balance.steal_conversion_base,
			units,
			_balance.steal_conversion_floor,
			_balance.steal_conversion_ceiling)
		if random_source.next_float() < interception:
			return TurnoverOutcome.new(
				true, TurnoverCause.Value.INTERCEPTION, candidate.actor_id, defender_id)

	var probability: float = _balance.opposed_probability(
		_balance.turnover_base * (0.55 + advantage.turnover_risk) * creativity,
		units,
		_balance.turnover_floor,
		_balance.turnover_ceiling)
	if random_source.next_float() >= probability:
		return TurnoverOutcome.none()
	# An inaccurate pass that nobody intercepted went out of bounds or hit the
	# floor; §11.2 distinguishes the two, and openness decides which.
	if random_source.next_float() < quality:
		return TurnoverOutcome.new(
			true, TurnoverCause.Value.OUT_OF_BOUNDS, candidate.actor_id, &"")
	return TurnoverOutcome.new(true, TurnoverCause.Value.BAD_PASS, candidate.actor_id, &"")


## Whether the defender actually goes for the ball. §13.3: "Stealing and
## Blocking increase success after a valid attempt; they do not independently
## force constant gambling. The Disciplined ↔ Gamble tendency and coach
## instructions determine attempt frequency." The Stealing rating is therefore
## absent from this check by design — it decides whether the gamble works, not
## whether it is taken.
func _attempts_disruption(
	context: PossessionContext,
	defender: PlayerMatchProfile,
	base_share: float,
	random_source: RandomSource,
) -> bool:
	var gamble: float = _balance.tendency_multiplier(
		defender.tendencies.at(TendencySlider.Value.DISCIPLINED_GAMBLE))
	var coach: float = _balance.tendency_multiplier(
		context.defense.game_plan.gamble_instruction)
	var coverage: float = CoverageFamily.ball_pressure_share(
		context.defense.game_plan.coverage_family)
	var share: float = clampf(base_share * gamble * coach * (0.70 + coverage * 0.60), 0.0, 1.0)
	return random_source.next_float() < share


## A shot-clock violation. The engine, not a draw, decides when this happens;
## the cause is recorded so it reconciles like any other turnover.
static func shot_clock_violation(offender_id: StringName) -> TurnoverOutcome:
	return TurnoverOutcome.new(true, TurnoverCause.Value.SHOT_CLOCK, offender_id, &"")


static func offensive_foul_turnover(offender_id: StringName) -> TurnoverOutcome:
	return TurnoverOutcome.new(true, TurnoverCause.Value.OFFENSIVE_FOUL, offender_id, &"")
