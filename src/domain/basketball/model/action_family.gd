class_name ActionFamily
extends RefCounted

## The version 1.0 action families locked by `SIMULATION_SPEC.md` §10.1, plus
## the putback continuation §14.4 requires after an offensive rebound.
##
## `PICK_ACTION` covers "pick-and-roll or pick-and-pop action" as one family, as
## §10.1 lists it; the roll/pop branch is recorded as event detail rather than
## as a second family, so the eleven families stay eleven.
##
## A family is a *choice*, never a capability. §10.6.2 is explicit that a
## tactical role never gates action validity, so nothing here may be reached
## from an identity layer: validity comes from location, capability thresholds,
## body, clock, and rules (§10.2).


enum Value {
	PASS_SWING,
	DRIVE,
	PULL_UP,
	POST_ACTION,
	PICK_ACTION,
	HANDOFF,
	OFF_BALL_CUT,
	RELOCATION,
	SCREEN,
	RESET,
	TRANSITION_ATTACK,
	PUTBACK,
}

const COUNT: int = 12
const IDS: PackedStringArray = [
	"pass_swing",
	"drive",
	"pull_up",
	"post_action",
	"pick_action",
	"handoff",
	"off_ball_cut",
	"relocation",
	"screen",
	"reset",
	"transition_attack",
	"putback",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown action family")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown action family id")
	return Value.RESET


## Families that always resolve directly into a shot setup. Drive, post, pick,
## and transition actions *can* end in a shot, but only after the advantage
## state decides; they are therefore not listed here.
static func is_direct_shot(value: int) -> bool:
	return value == Value.PULL_UP or value == Value.PUTBACK


## Families whose execution moves the ball to another player.
static func transfers_ball(value: int) -> bool:
	return value == Value.PASS_SWING or value == Value.HANDOFF


## Off-ball families produce §11.4 evidence rather than a box-score statistic.
static func is_off_ball(value: int) -> bool:
	return (
		value == Value.OFF_BALL_CUT
		or value == Value.RELOCATION
		or value == Value.SCREEN
	)
