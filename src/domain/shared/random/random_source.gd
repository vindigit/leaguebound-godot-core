class_name RandomSource
extends RefCounted


func get_version() -> StringName:
	assert(false, "RandomSource.get_version must be implemented")
	return &"unimplemented"


func next_u32() -> int:
	assert(false, "RandomSource.next_u32 must be implemented")
	return 0


func next_float() -> float:
	assert(false, "RandomSource.next_float must be implemented")
	return 0.0


func range_int(minimum: int, maximum: int) -> int:
	assert(minimum <= maximum, "minimum must not exceed maximum")
	assert(false, "RandomSource.range_int must be implemented")
	return minimum


func derive(label: StringName) -> RandomSource:
	assert(not label.is_empty(), "child stream labels must be stable and non-empty")
	assert(false, "RandomSource.derive must be implemented")
	return self


func snapshot_state() -> int:
	assert(false, "RandomSource.snapshot_state must be implemented")
	return 0


func restore_state(_state: int) -> void:
	assert(false, "RandomSource.restore_state must be implemented")
