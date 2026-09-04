class_name CountingRandomSource
extends RandomSource

## A profiling decorator over a real `RandomSource`.
##
## It exists so the performance report can state how many stream derivations and
## draws a complete game actually costs without instrumenting production code.
## Domain code sees an ordinary `RandomSource`; the counters live here, in the
## calibration package, and nothing in `src/` knows this type exists.
##
## The wrapper is transparent: it forwards every call to the wrapped source and
## returns wrapped children, so a profiled run consumes the identical stream a
## bare run does and produces the identical ledger.

var _inner: RandomSource
var _counters: Dictionary


func _init(p_inner: RandomSource = null, p_counters: Dictionary = {}) -> void:
	_inner = p_inner
	_counters = p_counters
	if not _counters.has(&"derive"):
		_counters[&"derive"] = 0
		_counters[&"next_float"] = 0
		_counters[&"next_u32"] = 0
		_counters[&"range_int"] = 0


static func counters() -> Dictionary:
	return {&"derive": 0, &"next_float": 0, &"next_u32": 0, &"range_int": 0}


func get_version() -> StringName:
	return _inner.get_version()


func next_u32() -> int:
	_bump(&"next_u32")
	return _inner.next_u32()


func next_float() -> float:
	_bump(&"next_float")
	return _inner.next_float()


func range_int(minimum: int, maximum: int) -> int:
	_bump(&"range_int")
	return _inner.range_int(minimum, maximum)


func derive(label: StringName) -> RandomSource:
	_bump(&"derive")
	return CountingRandomSource.new(_inner.derive(label), _counters)


func snapshot_state() -> int:
	return _inner.snapshot_state()


func restore_state(state: int) -> void:
	_inner.restore_state(state)


func _bump(key: StringName) -> void:
	var current: int = _counters[key]
	_counters[key] = current + 1
