class_name PlayerTendencies
extends RefCounted


const SLIDER_COUNT: int = 10
const MINIMUM: int = 1
const MAXIMUM: int = 5

var values: Array[int]


func _init(p_values: Array[int] = []) -> void:
	values = []
	if p_values.is_empty():
		for _index in range(SLIDER_COUNT):
			values.append(3)
	else:
		assert(p_values.size() == SLIDER_COUNT, "exactly ten tendency sliders are required")
		for value in p_values:
			assert(value >= MINIMUM and value <= MAXIMUM, "tendency values must be from 1 through 5")
			values.append(value)


func at(index: int) -> int:
	assert(index >= 0 and index < SLIDER_COUNT, "unknown tendency slider")
	return values[index]
