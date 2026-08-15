class_name TacticalRole
extends RefCounted


var role_id: StringName


func _init(p_role_id: StringName = &"balanced") -> void:
	assert(not p_role_id.is_empty(), "tactical role is required")
	role_id = p_role_id
