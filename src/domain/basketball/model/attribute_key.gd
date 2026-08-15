class_name AttributeKey
extends RefCounted


enum Key {
	SHORT_RANGE,
	DUNKING,
	MID_RANGE,
	THREE_POINT,
	FREE_THROW,
	HANDLE,
	PASSING,
	VISION,
	OFFENSIVE_IQ,
	PERIMETER_DEFENSE,
	INTERIOR_DEFENSE,
	STEALING,
	BLOCKING,
	DEFENSIVE_IQ,
	OFFENSIVE_REBOUNDING,
	DEFENSIVE_REBOUNDING,
	SPEED,
	STRENGTH,
	STAMINA,
	VERTICAL,
}

const COUNT: int = 20
const NAMES: PackedStringArray = [
	"short_range",
	"dunking",
	"mid_range",
	"three_point",
	"free_throw",
	"handle",
	"passing",
	"vision",
	"offensive_iq",
	"perimeter_defense",
	"interior_defense",
	"stealing",
	"blocking",
	"defensive_iq",
	"offensive_rebounding",
	"defensive_rebounding",
	"speed",
	"strength",
	"stamina",
	"vertical",
]


static func all() -> Array[int]:
	var keys: Array[int] = []
	for key in range(COUNT):
		keys.append(key)
	return keys


static func name_of(key: int) -> StringName:
	assert(key >= 0 and key < COUNT, "unknown attribute key")
	return StringName(NAMES[key])
