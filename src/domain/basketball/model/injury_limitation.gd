class_name InjuryLimitation
extends RefCounted


var limitation_id: StringName
var severity: float
var unavailable: bool


func _init(p_limitation_id: StringName = &"", p_severity: float = 0.0, p_unavailable: bool = false) -> void:
	assert(p_severity >= 0.0 and p_severity <= 1.0, "injury severity must be normalized")
	limitation_id = p_limitation_id
	severity = p_severity
	unavailable = p_unavailable
