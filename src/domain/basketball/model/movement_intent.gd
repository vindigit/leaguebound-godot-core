class_name MovementIntent
extends RefCounted

## The movement intents listed by `SIMULATION_SPEC.md` §16.2.
##
## "The engine advances tactical locations at possession-action boundaries."
## An intent is state, not animation: it records what a player is trying to do
## between two authoritative frames.


enum Value {
	ADVANCE_BALL,
	FILL_LANE,
	RIM_RUN,
	TRAIL,
	CUT,
	RELOCATE,
	SET_SCREEN,
	ROLL_OR_POP,
	POST_SEAL,
	CLOSE_OUT,
	HELP_TAG,
	RECOVER,
	BOX_OUT,
	PURSUE_REBOUND,
}

const COUNT: int = 14
const IDS: PackedStringArray = [
	"advance_ball",
	"fill_lane",
	"rim_run",
	"trail",
	"cut",
	"relocate",
	"set_screen",
	"roll_or_pop",
	"post_seal",
	"close_out",
	"help_tag",
	"recover",
	"box_out",
	"pursue_rebound",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown movement intent")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown movement intent id")
	return Value.RELOCATE
