class_name RotationRole
extends RefCounted

## The seven usage-intent rotation roles locked by `SIMULATION_SPEC.md` §10.6.1.
##
## This replaces the previous `STARTER, ROTATION, LIMITED, EMERGENCY, DNP`
## enum, which `BALANCE_SPEC.md` §29.2 item 7 records as a defect: it mixed
## coach usage *intent* with availability *facts*. §10.6.1 is explicit that
## did-not-play, emergency duty, limited availability, medical unavailability,
## and non-registration are separate derived states — "A Starter who does not
## play remains a Starter; the engine records a DNP, not a demotion."
##
## Availability continues to live in `InjuryLimitation` and lineup state on
## `PlayerMatchProfile` / `PlayerMatchRuntime`, never here.
##
## Numeric privilege (`BALANCE_SPEC.md` §12.4): rotation role may affect planned
## minutes and substitution priority only. It may never affect ratings,
## capabilities, or success probability.


enum Value {
	STAR,
	STARTER,
	SIXTH_PLAYER,
	ROTATION,
	BENCH,
	RESERVE,
	DEVELOPMENTAL,
}

const COUNT: int = 7
const IDS: PackedStringArray = [
	"star",
	"starter",
	"sixth_player",
	"rotation",
	"bench",
	"reserve",
	"developmental",
]
const LABELS: PackedStringArray = [
	"Star",
	"Starter",
	"Sixth Player",
	"Rotation",
	"Bench",
	"Reserve",
	"Developmental",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown rotation role")
	return StringName(IDS[value])


static func label_of(value: int) -> String:
	assert(is_valid(value), "unknown rotation role")
	return LABELS[value]


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown rotation role id")
	return Value.ROTATION
