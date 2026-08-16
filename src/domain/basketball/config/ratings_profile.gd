class_name RatingsProfile
extends RefCounted

## Versioned owner of the role-neutral Overall coefficients.
##
## `GODOT_TDD.md` §5.6: `RatingsProfile` owns Overall coefficients, capability
## weights, and rating band definitions, and is consumed by `OverallCalculator`
## and the capability calculators.
##
## The *structure* of the Overall blend is Locked by `BALANCE_SPEC.md` §6.1:
## mean of all twenty, mean of the top eight, mean of the bottom six,
## role-neutral, no positional weighting. The three coefficients are Baselines
## and remain provisional until reports 1 and 3 pass (§32).


const MEAN_WEIGHT_NAME: StringName = &"overall.mean_weight"
const TOP_WEIGHT_NAME: StringName = &"overall.top_weight"
const BOTTOM_WEIGHT_NAME: StringName = &"overall.bottom_weight"

## Locked structural counts. These are not tunables: changing them would change
## the shape of the blend, which §6.1 fixes and §32 excludes from ordinary
## balance changes.
const TOP_COUNT: int = 8
const BOTTOM_COUNT: int = 6

var version: StringName
var mean_weight: float
var top_weight: float
var bottom_weight: float

## `GODOT_TDD.md` §5.6 assigns capability weights to this profile, so the §5.2
## table lives here and every capability consumer reads it from one place.
## Keyed by `CapabilityKey.Value`; the array index is the enum value, which
## keeps lookup order canonical without depending on Dictionary iteration.
var _capability_weights: Array[CapabilityWeightSet] = []


func _init(
	p_version: StringName = &"ratings-v1",
	p_mean_weight: float = 0.65,
	p_top_weight: float = 0.25,
	p_bottom_weight: float = 0.10,
) -> void:
	assert(not p_version.is_empty(), "a ratings profile requires a version")
	assert(p_mean_weight >= 0.0 and p_top_weight >= 0.0 and p_bottom_weight >= 0.0,
		"Overall coefficients cannot be negative; a negative weight would break the §6.2 monotonicity guardrail")
	assert(
		absf(p_mean_weight + p_top_weight + p_bottom_weight - 1.0) < 0.000001,
		"Overall coefficients must sum to exactly 1.0 so the blend preserves the 25-99 scale"
	)
	version = p_version
	mean_weight = p_mean_weight
	top_weight = p_top_weight
	bottom_weight = p_bottom_weight
	_build_capability_weights()


static func default_profile() -> RatingsProfile:
	return RatingsProfile.new()


## The §5.2 weight row for one capability.
func capability_weights(capability: int) -> CapabilityWeightSet:
	assert(CapabilityKey.is_valid(capability), "unknown capability key")
	return _capability_weights[capability]


func all_capability_weights() -> Array[CapabilityWeightSet]:
	return _capability_weights.duplicate()


func _build_capability_weights() -> void:
	_capability_weights.resize(CapabilityKey.COUNT)
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.BALL_SECURITY, AttributeKey.Key.HANDLE,
		[AttributeKey.Key.HANDLE, AttributeKey.Key.STRENGTH, AttributeKey.Key.OFFENSIVE_IQ],
		[0.65, 0.15, 0.20], 0.0, 1.00))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.HANDLE_CREATION, AttributeKey.Key.HANDLE,
		[AttributeKey.Key.HANDLE, AttributeKey.Key.SPEED, AttributeKey.Key.OFFENSIVE_IQ],
		[0.55, 0.25, 0.20], 0.0, 1.00))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.PASS_ACCURACY, AttributeKey.Key.PASSING,
		[AttributeKey.Key.PASSING, AttributeKey.Key.VISION, AttributeKey.Key.OFFENSIVE_IQ],
		[0.65, 0.15, 0.20], 0.0, 0.70))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.PASS_READ_QUALITY, AttributeKey.Key.VISION,
		[AttributeKey.Key.VISION, AttributeKey.Key.OFFENSIVE_IQ, AttributeKey.Key.PASSING],
		[0.60, 0.25, 0.15], 0.0, 0.40))
	# Shot Selection: Offensive IQ 70%, Vision 20%, relevant shooting rating 10%.
	# The last term is context, supplied per attempt by the caller.
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.SHOT_SELECTION, AttributeKey.Key.OFFENSIVE_IQ,
		[AttributeKey.Key.OFFENSIVE_IQ, AttributeKey.Key.VISION],
		[0.70, 0.20], 0.10, 0.50))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.RIM_TOUCH_FINISH, AttributeKey.Key.SHORT_RANGE,
		[
			AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.STRENGTH,
			AttributeKey.Key.SPEED, AttributeKey.Key.OFFENSIVE_IQ,
		],
		[0.60, 0.15, 0.10, 0.15], 0.0, 0.80))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.DUNK_THREAT, AttributeKey.Key.DUNKING,
		[
			AttributeKey.Key.DUNKING, AttributeKey.Key.VERTICAL,
			AttributeKey.Key.STRENGTH, AttributeKey.Key.SPEED,
		],
		[0.60, 0.20, 0.10, 0.10], 0.0, 1.00))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.MIDRANGE_SHOTMAKING, AttributeKey.Key.MID_RANGE,
		[AttributeKey.Key.MID_RANGE, AttributeKey.Key.OFFENSIVE_IQ],
		[0.80, 0.20], 0.0, 0.80))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.THREE_POINT_SHOTMAKING, AttributeKey.Key.THREE_POINT,
		[AttributeKey.Key.THREE_POINT, AttributeKey.Key.OFFENSIVE_IQ],
		[0.82, 0.18], 0.0, 0.80))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.FREE_THROW_SHOTMAKING, AttributeKey.Key.FREE_THROW,
		[AttributeKey.Key.FREE_THROW, AttributeKey.Key.OFFENSIVE_IQ],
		[0.92, 0.08], 0.0, 0.40))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.OFF_BALL_TIMING, AttributeKey.Key.OFFENSIVE_IQ,
		[AttributeKey.Key.OFFENSIVE_IQ, AttributeKey.Key.SPEED, AttributeKey.Key.VISION],
		[0.60, 0.25, 0.15], 0.0, 0.90))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.OFFENSIVE_REBOUND_POSITIONING, AttributeKey.Key.OFFENSIVE_REBOUNDING,
		[
			AttributeKey.Key.OFFENSIVE_REBOUNDING, AttributeKey.Key.STRENGTH,
			AttributeKey.Key.VERTICAL, AttributeKey.Key.OFFENSIVE_IQ,
		],
		[0.60, 0.15, 0.15, 0.10], 0.0, 0.90))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.POINT_OF_ATTACK_CONTAINMENT, AttributeKey.Key.PERIMETER_DEFENSE,
		[
			AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.SPEED,
			AttributeKey.Key.STRENGTH, AttributeKey.Key.DEFENSIVE_IQ,
		],
		[0.55, 0.20, 0.10, 0.15], 0.0, 1.00))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.PERIMETER_CONTEST, AttributeKey.Key.PERIMETER_DEFENSE,
		[
			AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.SPEED,
			AttributeKey.Key.VERTICAL, AttributeKey.Key.DEFENSIVE_IQ,
		],
		[0.55, 0.15, 0.10, 0.20], 0.0, 0.90))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.INTERIOR_POSITIONING, AttributeKey.Key.INTERIOR_DEFENSE,
		[AttributeKey.Key.INTERIOR_DEFENSE, AttributeKey.Key.STRENGTH, AttributeKey.Key.DEFENSIVE_IQ],
		[0.60, 0.20, 0.20], 0.0, 0.70))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.RIM_PROTECTION, AttributeKey.Key.BLOCKING,
		[
			AttributeKey.Key.BLOCKING, AttributeKey.Key.INTERIOR_DEFENSE,
			AttributeKey.Key.VERTICAL, AttributeKey.Key.DEFENSIVE_IQ,
		],
		[0.55, 0.15, 0.15, 0.15], 0.0, 0.80))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.PASSING_LANE_DEFENSE, AttributeKey.Key.STEALING,
		[AttributeKey.Key.STEALING, AttributeKey.Key.DEFENSIVE_IQ, AttributeKey.Key.SPEED],
		[0.60, 0.25, 0.15], 0.0, 0.60))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.ON_BALL_DISRUPTION, AttributeKey.Key.STEALING,
		[
			AttributeKey.Key.STEALING, AttributeKey.Key.PERIMETER_DEFENSE,
			AttributeKey.Key.SPEED, AttributeKey.Key.DEFENSIVE_IQ,
		],
		[0.55, 0.20, 0.10, 0.15], 0.0, 0.90))
	# Help Recognition: Defensive IQ 75%, Speed 15%, assignment execution 10%.
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.HELP_RECOGNITION, AttributeKey.Key.DEFENSIVE_IQ,
		[AttributeKey.Key.DEFENSIVE_IQ, AttributeKey.Key.SPEED],
		[0.75, 0.15], 0.10, 0.60))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.DEFENSIVE_REBOUND_POSITIONING, AttributeKey.Key.DEFENSIVE_REBOUNDING,
		[
			AttributeKey.Key.DEFENSIVE_REBOUNDING, AttributeKey.Key.STRENGTH,
			AttributeKey.Key.VERTICAL, AttributeKey.Key.DEFENSIVE_IQ,
		],
		[0.60, 0.15, 0.15, 0.10], 0.0, 0.90))
	# §7.3 physical capabilities are single- or dual-input by definition.
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.COURT_SPEED, AttributeKey.Key.SPEED,
		[AttributeKey.Key.SPEED], [1.0], 0.0, 1.00))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.CONTACT_FORCE, AttributeKey.Key.STRENGTH,
		[AttributeKey.Key.STRENGTH], [1.0], 0.0, 0.60))
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.BURST_REACH, AttributeKey.Key.VERTICAL,
		[AttributeKey.Key.VERTICAL, AttributeKey.Key.SPEED], [0.60, 0.40], 0.0, 1.00))
	# Work Capacity is Stamina itself. Letting fatigue suppress it would make
	# tiredness compound on the very rating that resists tiredness.
	_register(CapabilityWeightSet.new(
		CapabilityKey.Value.WORK_CAPACITY, AttributeKey.Key.STAMINA,
		[AttributeKey.Key.STAMINA], [1.0], 0.0, 0.0))
	for capability in CapabilityKey.all():
		assert(_capability_weights[capability] != null,
			"every capability in SIMULATION_SPEC §7 needs a weight row")


func _register(weights: CapabilityWeightSet) -> void:
	_capability_weights[weights.capability] = weights


func describe_tunables() -> Array[BalanceTunable]:
	var tunables: Array[BalanceTunable] = []
	tunables.append(BalanceTunable.new(MEAN_WEIGHT_NAME, &"weight", mean_weight, 0.40, 0.85))
	tunables.append(BalanceTunable.new(TOP_WEIGHT_NAME, &"weight", top_weight, 0.05, 0.40))
	tunables.append(BalanceTunable.new(BOTTOM_WEIGHT_NAME, &"weight", bottom_weight, 0.02, 0.30))
	return tunables
