class_name ActionCandidate
extends RefCounted

## One valid action the offense could take next (`SIMULATION_SPEC.md` §10.2).
##
## "An impossible action receives no weight." A candidate exists only because
## location, role, matchup, clock, capability threshold, tactics, and health all
## permitted it; the weight then expresses preference, never possibility.
##
## The weight is built by `ActionCandidateGenerator` from the §10.3 factors and
## clamped by the §12.2 guardrails. The factor breakdown is retained so the §28
## resolution trace can explain a selection without recomputing it.
##
## The breakdown is kept as the nine numbers themselves and rendered only when
## something asks for it. It used to be formatted into a string for every
## candidate as the candidate was built: with roughly twenty-five candidates per
## action and a nine-argument format each, the engine spent a measurable share
## of every possession composing text that nothing read. Storing the factors is
## free, and `describe()` produces the identical string on demand.

## Factor order matches the §10.3 weight construction, left to right.
const FACTOR_COUNT: int = 9
const FACTOR_NAMES: PackedStringArray = [
	"role", "tend", "coach", "fit", "match", "clock", "conf", "fat", "use",
]

var action_family: int
var actor_id: StringName
## Pass receiver, screener, handoff target, or cutter, depending on family.
var target_id: StringName
## The shot zone this candidate would attack, or -1 for a non-shot action.
var zone: int
var dunk: bool
var weight: float
## The §10.3 factors in `FACTOR_NAMES` order, empty when the candidate was not
## built through the weight construction (a putback, for example).
var factors: PackedFloat64Array


func _init(
	p_action_family: int = ActionFamily.Value.RESET,
	p_actor_id: StringName = &"",
	p_weight: float = 1.0,
	p_target_id: StringName = &"",
	p_zone: int = -1,
	p_dunk: bool = false,
	p_factors: PackedFloat64Array = PackedFloat64Array(),
) -> void:
	assert(ActionFamily.is_valid(p_action_family), "unknown action family")
	assert(p_weight >= 0.0, "action weight cannot be negative")
	assert(p_zone == -1 or ShotZone.is_valid(p_zone), "unknown shot zone")
	assert(p_factors.is_empty() or p_factors.size() == FACTOR_COUNT,
		"a weight breakdown carries one value per §10.3 factor")
	action_family = p_action_family
	actor_id = p_actor_id
	weight = p_weight
	target_id = p_target_id
	zone = p_zone
	dunk = p_dunk
	factors = p_factors


func action_id() -> StringName:
	return ActionFamily.id_of(action_family)


func is_shot() -> bool:
	return zone >= 0


## The §28 resolution trace for this candidate, rendered on demand.
func describe() -> String:
	if factors.is_empty():
		return "%s weight=%.3f" % [action_id(), weight]
	var parts: PackedStringArray = []
	for index in range(FACTOR_COUNT):
		parts.append("%s=%.2f" % [FACTOR_NAMES[index], factors[index]])
	return " ".join(parts)
