class_name MaturityProfile
extends RefCounted

## Body maturity timing, selected once at creation (`BALANCE_SPEC.md` §7.4.1,
## `GODOT_TDD.md` §5.5).
##
## Early maturity delivers more of the projected growth during high school;
## Late maturity delivers more of it afterwards. `GDD.md` §6.5 states plainly
## that neither timing is strictly better, so no timing profile may receive a
## larger total growth budget than another — only a different schedule.


enum Value { EARLY, AVERAGE, LATE }

const COUNT: int = 3
const IDS: PackedStringArray = ["early", "average", "late"]
const LABELS: PackedStringArray = ["Early", "Average", "Late"]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown maturity profile")
	return StringName(IDS[value])


static func label_of(value: int) -> String:
	assert(is_valid(value), "unknown maturity profile")
	return LABELS[value]


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown maturity profile id")
	return Value.AVERAGE
