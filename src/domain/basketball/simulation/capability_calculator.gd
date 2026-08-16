class_name CapabilityCalculator
extends RefCounted

## The single owner of derived basketball capability (`SIMULATION_SPEC.md` §7).
##
## "A capability is a pure, versioned function of current ratings, body, active
## badges, and match context." Every resolver in this package asks this class;
## none of them re-derives a rating weight. That is what keeps one weight table,
## one version, and one place to change when the §31 sensitivity report lands.
##
## Weights come from `RatingsProfile` (`GODOT_TDD.md` §5.6). Fatigue conversion,
## injury share, and every other magnitude come from `SimulationBalanceProfile`.
## Nothing numeric is authored here.
##
## §7.4: Offensive and Defensive IQ "are not generic hidden bonuses added to
## every probability". They appear only where the §5.2 table places them, and
## never exceed the 45% non-primary share the table allows, so IQ improves the
## circumstances in which a technical rating is used and cannot substitute for
## it.
##
## Identity layers are absent by construction. `BALANCE_SPEC.md` §12.4:
## "Identity layers reach opportunity, never capability."

var _ratings: RatingsProfile
var _balance: SimulationBalanceProfile


func _init(p_ratings: RatingsProfile, p_balance: SimulationBalanceProfile) -> void:
	assert(p_ratings != null and p_balance != null,
		"capability resolution requires a versioned ratings and balance profile")
	_ratings = p_ratings
	_balance = p_balance


## The §5.2 weighted mean, before any match context. Public so contract tests
## can assert monotonicity on the pure function.
func base_capability(capability: int, attributes: PlayerAttributes, context: float = 0.0) -> float:
	return _ratings.capability_weights(capability).evaluate(attributes, context)


## The live capability: §5.2 base, then pregame condition, active injury
## limitation, and the §15.1 acute-fatigue band penalty scaled by the
## capability's own declared sensitivity.
func capability_of(
	capability: int,
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	context: float = 0.0,
) -> float:
	var base: float = base_capability(capability, player.attributes, context)
	var weights: CapabilityWeightSet = _ratings.capability_weights(capability)
	var penalty: float = (
		_balance.fatigue_capability_penalty(runtime.acute_fatigue) * weights.fatigue_sensitivity)
	return clampf(base * availability_factor(player) - penalty, 0.0, 1.0)


## Pregame condition and injury limitation, as a multiplicative availability
## factor. §17.3 keeps injuries an availability and execution effect; nothing
## here rewrites a stored rating.
func availability_factor(player: PlayerMatchProfile) -> float:
	var worst: float = 0.0
	for limitation in player.injury_limitations:
		worst = maxf(worst, limitation.severity)
	return clampf(player.condition * (1.0 - worst * _balance.injury_capability_share), 0.0, 1.0)


## A capability differential in §5.1 `RatingDifferential` units, which is what
## `SimulationBalanceProfile.opposed_probability` expects. One unit is a
## ten-point edge on the 25-99 scale.
func differential_units(attacker: float, defender: float) -> float:
	return (attacker - defender) * float(Rating.MAXIMUM - Rating.ACTIVE_MINIMUM) / 10.0


## The shot capability for a zone, with Shot Selection's contextual term
## supplied from the same relevant shooting rating §5.2 names.
func shot_capability(
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	zone: int,
) -> float:
	return capability_of(CapabilityKey.shotmaking_for_zone(zone), player, runtime)


## Shot Selection, whose tenth share is the relevant shooting rating for the
## attempt actually being considered.
func shot_selection(
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	zone: int,
) -> float:
	var relevant: float = base_capability(
		CapabilityKey.shotmaking_for_zone(zone), player.attributes)
	return capability_of(CapabilityKey.Value.SHOT_SELECTION, player, runtime, relevant)


## Help Recognition, whose tenth share is live assignment-execution quality.
## §5.2: that term "is not the tactical role identity, and it must not be
## implemented by reading" an identity id. The caller supplies execution
## quality built from chemistry, discipline, and current workload.
func help_recognition(
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	assignment_execution: float,
) -> float:
	return capability_of(
		CapabilityKey.Value.HELP_RECOGNITION, player, runtime, assignment_execution)
