class_name ContestBand
extends RefCounted

## `SIMULATION_SPEC.md` §12.3 contest bands.
##
## "Contest is created from actual defensive positioning and capabilities. It is
## not selected as independent random flavor after shot probability is known."
## The band is therefore always derived from a contest pressure score, never
## drawn on its own.


enum Value {
	OPEN,
	LIGHT,
	MODERATE,
	HEAVY,
	SMOTHERED,
}

const COUNT: int = 5
const IDS: PackedStringArray = ["open", "light", "moderate", "heavy", "smothered"]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown contest band")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown contest band id")
	return Value.OPEN


## Maps a normalized contest pressure (0 = unguarded, 1 = smothered) onto a
## band. The thresholds are evenly spaced because the pressure score itself
## carries the balance shaping; a second nonlinearity here would hide it.
static func from_pressure(pressure: float) -> int:
	var bounded: float = clampf(pressure, 0.0, 1.0)
	if bounded < 0.20:
		return Value.OPEN
	if bounded < 0.40:
		return Value.LIGHT
	if bounded < 0.60:
		return Value.MODERATE
	if bounded < 0.82:
		return Value.HEAVY
	return Value.SMOTHERED
