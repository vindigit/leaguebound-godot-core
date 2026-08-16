class_name ShotZone
extends RefCounted

## The shot zones required by `SIMULATION_SPEC.md` §12.1.
##
## "Shot zones at minimum include restricted rim, close non-rim, midrange,
## standard three, and deep three. Public logs can group these more simply."
##
## The zone selects the shot profile (`BALANCE_SPEC.md` §13.1/§13.2), the point
## value, the rebound trajectory profile (§14.1), and whether the attempt counts
## toward the paint summary required by §24.2.


enum Value {
	RESTRICTED_RIM,
	CLOSE_NON_RIM,
	MIDRANGE,
	STANDARD_THREE,
	DEEP_THREE,
}

const COUNT: int = 5
const IDS: PackedStringArray = [
	"restricted_rim",
	"close_non_rim",
	"midrange",
	"standard_three",
	"deep_three",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown shot zone")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown shot zone id")
	return Value.MIDRANGE


static func is_three(value: int) -> bool:
	return value == Value.STANDARD_THREE or value == Value.DEEP_THREE


## Points in paint (`SIMULATION_SPEC.md` §24.2) covers the two interior zones.
static func is_paint(value: int) -> bool:
	return value == Value.RESTRICTED_RIM or value == Value.CLOSE_NON_RIM


static func points_for(value: int) -> int:
	return 3 if is_three(value) else 2
