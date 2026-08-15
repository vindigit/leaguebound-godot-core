class_name SeededRandomSource
extends RandomSource


const VERSION: StringName = &"godot-pcg32-v1"

var _root_seed: int
var _rng: RandomNumberGenerator


func _init(seed_value: int = 1) -> void:
	_root_seed = seed_value
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value


func get_version() -> StringName:
	return VERSION


func next_u32() -> int:
	return _rng.randi()


func next_float() -> float:
	return _rng.randf()


func range_int(minimum: int, maximum: int) -> int:
	assert(minimum <= maximum, "minimum must not exceed maximum")
	return _rng.randi_range(minimum, maximum)


func derive(label: StringName) -> RandomSource:
	var child_seed := RandomStreamKey.derive_seed(_root_seed, label, VERSION)
	return SeededRandomSource.new(child_seed)


func snapshot_state() -> int:
	return _rng.state


func restore_state(state: int) -> void:
	_rng.state = state
