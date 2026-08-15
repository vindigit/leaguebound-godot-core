class_name ActionCandidate
extends RefCounted


var action_id: StringName
var weight: float


func _init(p_action_id: StringName = &"reset", p_weight: float = 1.0) -> void:
	assert(not p_action_id.is_empty(), "action identity is required")
	assert(p_weight >= 0.0, "action weight cannot be negative")
	action_id = p_action_id
	weight = p_weight
