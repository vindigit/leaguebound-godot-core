class_name SubstitutionOrder
extends RefCounted

## One planned substitution: who leaves and who enters.
##
## The engine turns each order into a `CHECK_OUT` / `CHECK_IN` pair in the
## ledger, which is what makes minutes played reconcile from events (§24.3)
## rather than from a counter the reducer could forget to advance.

enum Reason {
	FOULED_OUT,
	UNAVAILABLE,
	FOUL_TROUBLE,
	FATIGUE,
	PLANNED_MINUTES,
	DECIDED_GAME,
	CLOSING_LINEUP,
}

const REASON_IDS: PackedStringArray = [
	"fouled_out",
	"unavailable",
	"foul_trouble",
	"fatigue",
	"planned_minutes",
	"decided_game",
	"closing_lineup",
]

var outgoing_id: StringName
var incoming_id: StringName
var reason: int


func _init(
	p_outgoing_id: StringName,
	p_incoming_id: StringName,
	p_reason: int,
) -> void:
	assert(not p_outgoing_id.is_empty() and not p_incoming_id.is_empty(),
		"a substitution needs both players")
	assert(p_outgoing_id != p_incoming_id, "a player cannot replace himself")
	assert(p_reason >= 0 and p_reason < REASON_IDS.size(), "unknown substitution reason")
	outgoing_id = p_outgoing_id
	incoming_id = p_incoming_id
	reason = p_reason


func reason_id() -> StringName:
	return StringName(REASON_IDS[reason])


## Mandatory substitutions cannot be deferred to a convenient dead ball: §5.1
## forbids a fouled-out, ejected, or medically unavailable player from
## remaining on court at all.
func is_mandatory() -> bool:
	return reason == Reason.FOULED_OUT or reason == Reason.UNAVAILABLE
