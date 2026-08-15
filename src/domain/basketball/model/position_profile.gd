class_name PositionProfile
extends RefCounted


var primary: StringName
var secondary: Array[StringName]


func _init(p_primary: StringName = &"G", p_secondary: Array[StringName] = []) -> void:
	assert(not p_primary.is_empty(), "primary position is required")
	primary = p_primary
	secondary = []
	for position in p_secondary:
		if not position.is_empty() and position != primary and not secondary.has(position):
			secondary.append(position)
