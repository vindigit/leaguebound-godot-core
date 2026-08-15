class_name PositionFamily
extends RefCounted

## The broad starting families from `GDD.md` §6.1 and PRD BUILD-001.
##
## Guard, Wing, and Big are *starting* families, not permanent position locks.
## `GDD.md` §6.1: "Exact primary and secondary positions emerge from physical
## dimensions, ratings, play style, and early performance." Nothing in the
## domain may treat a family as a permanent restriction on what a player can
## become, and no capability may read it.


enum Value { GUARD, WING, BIG }

const COUNT: int = 3
const IDS: PackedStringArray = ["guard", "wing", "big"]
const LABELS: PackedStringArray = ["Guard", "Wing", "Big"]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown position family")
	return StringName(IDS[value])


static func label_of(value: int) -> String:
	assert(is_valid(value), "unknown position family")
	return LABELS[value]


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown position family id")
	return Value.WING
