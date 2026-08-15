class_name TacticalRole
extends RefCounted

## The eleven version 1.0 tactical roles locked by `SIMULATION_SPEC.md` §10.6.2.
##
## This replaces the previous unconstrained `StringName` whose default was
## `balanced` — a value that is not one of the eleven roles at all
## (`BALANCE_SPEC.md` §29.2 item 6). §10.6.2 records that no consolidation was
## applied: all eleven are retained because each maps to a distinct opportunity
## vector, and merging any two would erase a real difference in candidate
## generation.
##
## Numeric privilege (`BALANCE_SPEC.md` §12.4): tactical role may affect
## `RoleOpportunity` in the §12.2 action-weight table and planned minutes and
## assignment. It modifies nothing else — never a capability, shot profile,
## contest, rebound candidate score, turnover risk, or foul curve. A tactical
## role also never gates action validity (§10.6.2): a `shooter` may drive.
##
## Assigning a role a player is unsuited for is legal and produces bad
## basketball, not corrected basketball. Nothing here silently reassigns.


enum Value {
	PRIMARY_CREATOR,
	SECONDARY_CREATOR,
	SHOOTER,
	SLASHER,
	CONNECTOR,
	POST_OPTION,
	ROLL_POP_BIG,
	PERIMETER_STOPPER,
	INTERIOR_ANCHOR,
	REBOUNDER,
	UTILITY_ENERGY,
}

const COUNT: int = 11
const IDS: PackedStringArray = [
	"primary_creator",
	"secondary_creator",
	"shooter",
	"slasher",
	"connector",
	"post_option",
	"roll_pop_big",
	"perimeter_stopper",
	"interior_anchor",
	"rebounder",
	"utility_energy",
]
const LABELS: PackedStringArray = [
	"Primary Creator",
	"Secondary Creator",
	"Shooter",
	"Slasher",
	"Connector",
	"Post Option",
	"Roll/Pop Big",
	"Perimeter Stopper",
	"Interior Anchor",
	"Rebounder",
	"Utility/Energy",
]

var role: int


func _init(p_role: int = Value.UTILITY_ENERGY) -> void:
	assert(is_valid(p_role), "tactical role must be one of the eleven locked version 1.0 roles")
	role = p_role


func id() -> StringName:
	return id_of(role)


func label() -> String:
	return label_of(role)


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown tactical role")
	return StringName(IDS[value])


static func label_of(value: int) -> String:
	assert(is_valid(value), "unknown tactical role")
	return LABELS[value]


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown tactical role id")
	return Value.UTILITY_ENERGY
