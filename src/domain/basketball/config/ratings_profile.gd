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


static func default_profile() -> RatingsProfile:
	return RatingsProfile.new()


func describe_tunables() -> Array[BalanceTunable]:
	var tunables: Array[BalanceTunable] = []
	tunables.append(BalanceTunable.new(MEAN_WEIGHT_NAME, &"weight", mean_weight, 0.40, 0.85))
	tunables.append(BalanceTunable.new(TOP_WEIGHT_NAME, &"weight", top_weight, 0.05, 0.40))
	tunables.append(BalanceTunable.new(BOTTOM_WEIGHT_NAME, &"weight", bottom_weight, 0.02, 0.30))
	return tunables
