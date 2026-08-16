class_name TurnoverCause
extends RefCounted

## `SIMULATION_SPEC.md` §11.2: "Turnovers require a cause and actor
## attribution." A steal is credited only when a defender caused a qualifying
## live-ball turnover, which is why `INTERCEPTION` and `STRIP` are separated
## from `BAD_PASS` and `LOST_HANDLE`.


enum Value {
	BAD_PASS,
	INTERCEPTION,
	LOST_HANDLE,
	STRIP,
	OFFENSIVE_FOUL,
	SHOT_CLOCK,
	OUT_OF_BOUNDS,
	TRAVEL_OR_VIOLATION,
}

const COUNT: int = 8
const IDS: PackedStringArray = [
	"bad_pass",
	"interception",
	"lost_handle",
	"strip",
	"offensive_foul",
	"shot_clock",
	"out_of_bounds",
	"travel_or_violation",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown turnover cause")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown turnover cause id")
	return Value.LOST_HANDLE


## Only a defender-caused live-ball turnover credits a steal (§11.2).
static func credits_steal(value: int) -> bool:
	return value == Value.INTERCEPTION or value == Value.STRIP
