class_name AttributeProgress
extends RefCounted

## Hidden fractional direct progress toward the next whole rating point
## (`BALANCE_SPEC.md` §9.2, PRD PROG-002 and PROG-003).
##
## One direct-progress unit fills one AP of the *current* upgrade cost. When the
## bar reaches the required cost the rating increases by one and surplus
## progress carries into the next eligible point.
##
## Two rules shape this type:
##
## - The interface shows the bar without its exact fraction (PROG-003), so the
##   stored value is deliberately not rounded for display here. `fill_share`
##   returns a normalized share for the bar; the raw units stay hidden.
## - Hidden fractional progress is preserved across migrations
##   (`BALANCE_SPEC.md` §29.3, `GODOT_TDD.md` §5.7). It is a stored career fact
##   and is never recomputed or discarded.


var _units: Array[float]


func _init(p_units: Array[float] = []) -> void:
	_units = []
	if p_units.is_empty():
		for _index in range(AttributeKey.COUNT):
			_units.append(0.0)
	else:
		assert(p_units.size() == AttributeKey.COUNT,
			"exactly one progress accumulator per canonical attribute is required")
		for value in p_units:
			assert(value >= 0.0, "direct progress cannot be negative")
			_units.append(value)


func units_for(attribute: int) -> float:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	return _units[attribute]


func add_units(attribute: int, units: float) -> void:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	assert(units >= 0.0, "direct progress cannot be negative")
	_units[attribute] += units


func consume_units(attribute: int, units: float) -> void:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	assert(units <= _units[attribute] + 0.000001, "cannot consume progress that was never earned")
	_units[attribute] = maxf(0.0, _units[attribute] - units)


func clear(attribute: int) -> void:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	_units[attribute] = 0.0


## The share of the next whole point that is filled, for the progress bar. The
## exact fraction stays hidden from the interface (PROG-003); this is the bar
## geometry, not a number to print.
func fill_share(attribute: int, required_cost: int) -> float:
	assert(required_cost > 0, "a rating increase always costs at least one AP")
	return clampf(units_for(attribute) / float(required_cost), 0.0, 1.0)


func values() -> Array[float]:
	return _units.duplicate()


func duplicate_progress() -> AttributeProgress:
	return AttributeProgress.new(_units.duplicate())
