class_name ProspectProfile
extends RefCounted

## The three broad prospect profiles from `BALANCE_SPEC.md` §7.2.
##
## A prospect profile changes the creation budget, the cap-generation centre,
## and the share of growth availability by career phase. It is not a difficulty
## setting (§3.1) and it never changes the AP cost of a rating (§7.2).


enum Value { READY_NOW, BALANCED, HIGH_UPSIDE }

const COUNT: int = 3
const IDS: PackedStringArray = ["ready_now", "balanced", "high_upside"]
const LABELS: PackedStringArray = ["Ready Now", "Balanced", "High Upside"]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown prospect profile")
	return StringName(IDS[value])


static func label_of(value: int) -> String:
	assert(is_valid(value), "unknown prospect profile")
	return LABELS[value]


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown prospect profile id")
	return Value.BALANCED
