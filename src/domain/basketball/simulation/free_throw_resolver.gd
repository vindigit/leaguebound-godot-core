class_name FreeThrowResolver
extends RefCounted

## Free-throw execution (`SIMULATION_SPEC.md` §13.2).
##
## "Free Throw is the primary technical rating. Fatigue, pressure, injury, and
## competition environment are bounded context."
##
## The manual timing challenge and the automatic path resolve through this same
## outcome contract (§2.1, §23): `resolve` is what Sim calls, and
## `resolve_manual` is what Play calls once the user's release has been
## measured. Neither switches to different shooting rules — the manual path only
## replaces the sampled execution with a measured one, and a valid visible
## perfect release guarantees success under the same rule as every other shot
## (§12.4).

var _capability: CapabilityCalculator
var _balance: SimulationBalanceProfile


func _init(p_capability: CapabilityCalculator, p_balance: SimulationBalanceProfile) -> void:
	_capability = p_capability
	_balance = p_balance


## The make probability for one attempt, before any execution sample.
func probability(
	context: PossessionContext,
	shooter_id: StringName,
) -> float:
	var shooter: PlayerMatchProfile = context.offense_profile(shooter_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(shooter_id)
	var capability: float = _capability.capability_of(
		CapabilityKey.Value.FREE_THROW_SHOTMAKING, shooter, runtime)
	var value: float = _balance.free_throw_baseline(capability)
	value -= clampf(runtime.acute_fatigue / 100.0, 0.0, 1.0) * _balance.fatigue_shot_penalty_max * 0.5
	# §20.1 pressure: late and close raises the stakes. It changes stability,
	# not the rating, and it stays inside the §13.2 floor and ceiling.
	if context.is_late_game() and absf(float(context.offense_margin())) <= 5.0:
		var composure: float = Rating.normalized(shooter.attributes.offensive_iq)
		value -= (1.0 - composure) * _balance.clock_desperation_penalty_max * 0.35
	if not context.input.is_home(context.offense.team_id):
		value -= _balance.home_environment_shot_bonus * context.input.home_environment
	return clampf(value, _balance.floor_free_throw, _balance.ceiling_free_throw)


## Automatic execution (§12.5): simulated release quality against the resolved
## probability.
func resolve(
	context: PossessionContext,
	shooter_id: StringName,
	random_source: RandomSource,
) -> bool:
	return random_source.next_float() < probability(context, shooter_id)


## Manual execution (§12.4, §13.2). A release inside a valid perfect zone is a
## guaranteed make; anything else resolves through the same probability with the
## measured timing contributing inside its documented bounds.
##
## The engine measures raw user timing "without correction, magnetic snapping,
## or launch-day assistance" (§13.4) — `timing_quality` is that measurement, not
## an adjusted one.
func resolve_manual(
	context: PossessionContext,
	shooter_id: StringName,
	perfect_release: bool,
	timing_quality: float,
	random_source: RandomSource,
) -> bool:
	if perfect_release:
		return true
	var adjusted: float = clampf(
		probability(context, shooter_id) + (clampf(timing_quality, 0.0, 1.0) - 0.5) * 0.28,
		_balance.floor_free_throw,
		_balance.ceiling_free_throw)
	return random_source.next_float() < adjusted
