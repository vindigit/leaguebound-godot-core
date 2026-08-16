class_name AdvantageLevel
extends RefCounted

## `SIMULATION_SPEC.md` §11.1: actions create an `AdvantageResult` before a shot
## or terminal outcome, and its level is one of these four.


enum Value {
	NONE,
	SMALL,
	CLEAR,
	BREAKDOWN,
}

const COUNT: int = 4
const IDS: PackedStringArray = ["none", "small", "clear", "breakdown"]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown advantage level")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown advantage level id")
	return Value.NONE


## The normalized shot-quality contribution of each level. Kept as a shape
## rather than a magnitude: `SimulationBalanceProfile` scales it.
static func quality_share(value: int) -> float:
	match value:
		Value.NONE:
			return 0.0
		Value.SMALL:
			return 0.35
		Value.CLEAR:
			return 0.70
		Value.BREAKDOWN:
			return 1.0
		_:
			assert(false, "unknown advantage level")
	return 0.0
