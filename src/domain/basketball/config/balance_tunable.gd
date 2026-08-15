class_name BalanceTunable
extends RefCounted

## One named, validated production tunable.
##
## `BALANCE_SPEC.md` §4 prohibits anonymous numeric literals inside resolution
## code, and `GODOT_TDD.md` §5.6 fails Gate 0 for any tunable without a name,
## unit, safe range, and version. Every profile in this package publishes its
## values as `BalanceTunable` records so the Gate B0 configuration-integrity
## test can assert those four facts without reflection.


var tunable_name: StringName
var unit: StringName
var value: float
var safe_minimum: float
var safe_maximum: float


func _init(
	p_tunable_name: StringName,
	p_unit: StringName,
	p_value: float,
	p_safe_minimum: float,
	p_safe_maximum: float,
) -> void:
	assert(not p_tunable_name.is_empty(), "a tunable requires a stable name")
	assert(not p_unit.is_empty(), "a tunable requires a documented unit")
	assert(p_safe_minimum <= p_safe_maximum, "tunable safe range is inverted")
	tunable_name = p_tunable_name
	unit = p_unit
	value = p_value
	safe_minimum = p_safe_minimum
	safe_maximum = p_safe_maximum


func is_inside_safe_range() -> bool:
	return value >= safe_minimum and value <= safe_maximum


func describe() -> String:
	return "%s = %s %s (safe %s..%s)" % [
		tunable_name,
		value,
		unit,
		safe_minimum,
		safe_maximum,
	]
