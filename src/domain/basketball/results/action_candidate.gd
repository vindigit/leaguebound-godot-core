class_name ActionCandidate
extends RefCounted

## One valid action the offense could take next (`SIMULATION_SPEC.md` §10.2).
##
## "An impossible action receives no weight." A candidate exists only because
## location, role, matchup, clock, capability threshold, tactics, and health all
## permitted it; the weight then expresses preference, never possibility.
##
## The weight is built by `ActionCandidateGenerator` from the §10.3 factors and
## clamped by the §12.2 guardrails. `trace` records the factor breakdown so the
## §28 resolution trace can explain a selection without recomputing it.

var action_family: int
var actor_id: StringName
## Pass receiver, screener, handoff target, or cutter, depending on family.
var target_id: StringName
## The shot zone this candidate would attack, or -1 for a non-shot action.
var zone: int
var dunk: bool
var weight: float
var trace: String


func _init(
	p_action_family: int = ActionFamily.Value.RESET,
	p_actor_id: StringName = &"",
	p_weight: float = 1.0,
	p_target_id: StringName = &"",
	p_zone: int = -1,
	p_dunk: bool = false,
	p_trace: String = "",
) -> void:
	assert(ActionFamily.is_valid(p_action_family), "unknown action family")
	assert(p_weight >= 0.0, "action weight cannot be negative")
	assert(p_zone == -1 or ShotZone.is_valid(p_zone), "unknown shot zone")
	action_family = p_action_family
	actor_id = p_actor_id
	weight = p_weight
	target_id = p_target_id
	zone = p_zone
	dunk = p_dunk
	trace = p_trace


func action_id() -> StringName:
	return ActionFamily.id_of(action_family)


func is_shot() -> bool:
	return zone >= 0
