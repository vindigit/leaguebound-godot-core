class_name AttributeCategory
extends RefCounted

## Aging categories from `BALANCE_SPEC.md` §10.2.
##
## The specification groups the twenty attributes into six aging curves rather
## than giving each attribute its own. This class is the single mapping from an
## `AttributeKey` to its curve, so the aging model, the decline model, and the
## projected-peak model cannot disagree about which curve an attribute follows.


enum Value {
	EXPLOSIVE,      ## Speed and Vertical: decline begins 28, strong after 33
	STAMINA,        ## decline begins 30, strong after 35
	STRENGTH,       ## decline begins 32, strong after 36
	TECHNICAL,      ## scoring/handle/passing: decline begins 33, moderate after 37
	POSITIONAL,     ## rebounding and positional defense: decline begins 33
	IQ,             ## decline begins 37, mild after 40
}

const COUNT: int = 6
const IDS: PackedStringArray = [
	"explosive",
	"stamina",
	"strength",
	"technical",
	"positional",
	"iq",
]

## The three broad decline families used by the §10.3 annual decline table,
## which reports Physical / Technical / IQ columns rather than all six curves.
enum DeclineFamily { PHYSICAL, TECHNICAL, IQ }


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown attribute category")
	return StringName(IDS[value])


static func of_attribute(attribute: int) -> int:
	match attribute:
		AttributeKey.Key.SPEED, AttributeKey.Key.VERTICAL:
			return Value.EXPLOSIVE
		AttributeKey.Key.STAMINA:
			return Value.STAMINA
		AttributeKey.Key.STRENGTH:
			return Value.STRENGTH
		AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.DUNKING, \
		AttributeKey.Key.MID_RANGE, AttributeKey.Key.THREE_POINT, \
		AttributeKey.Key.FREE_THROW, AttributeKey.Key.HANDLE, \
		AttributeKey.Key.PASSING, AttributeKey.Key.VISION:
			return Value.TECHNICAL
		AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.INTERIOR_DEFENSE, \
		AttributeKey.Key.STEALING, AttributeKey.Key.BLOCKING, \
		AttributeKey.Key.OFFENSIVE_REBOUNDING, AttributeKey.Key.DEFENSIVE_REBOUNDING:
			return Value.POSITIONAL
		AttributeKey.Key.OFFENSIVE_IQ, AttributeKey.Key.DEFENSIVE_IQ:
			return Value.IQ
		_:
			assert(false, "unknown attribute key")
	return Value.TECHNICAL


static func decline_family_of(category: int) -> int:
	match category:
		Value.EXPLOSIVE, Value.STAMINA, Value.STRENGTH:
			return DeclineFamily.PHYSICAL
		Value.TECHNICAL, Value.POSITIONAL:
			return DeclineFamily.TECHNICAL
		Value.IQ:
			return DeclineFamily.IQ
		_:
			assert(false, "unknown attribute category")
	return DeclineFamily.TECHNICAL
