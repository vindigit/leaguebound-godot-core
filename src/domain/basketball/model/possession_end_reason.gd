class_name PossessionEndReason
extends RefCounted

## Why a team possession terminated.
##
## The Stage 3 possession contract requires exactly one terminal end event per
## possession, and requires the reason to be a real basketball outcome rather
## than "the engine ran out of scaffold". An offensive rebound is deliberately
## absent: it *continues* the possession and never terminates one.


enum Value {
	MADE_SCORE,
	DEFENSIVE_REBOUND,
	TURNOVER,
	PERIOD_EXPIRED,
}

const COUNT: int = 4
const IDS: PackedStringArray = [
	"made_score",
	"defensive_rebound",
	"turnover",
	"period_expired",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown possession end reason")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown possession end reason id")
	return Value.TURNOVER


## A period expiring is a clock fact, not a basketball result: it is the one
## reason that does not hand the ball to the other team.
static func transfers_possession(value: int) -> bool:
	return value != Value.PERIOD_EXPIRED
