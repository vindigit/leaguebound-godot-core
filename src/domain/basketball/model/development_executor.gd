class_name DevelopmentExecutor
extends RefCounted

## The three executors of the one canonical development contract
## (`BALANCE_SPEC.md` §9.7.1, OD-E).
##
## "Detail level changes how the contract is executed, never what it produces."
## All three are bound identically by the §9.1 cost table, exact caps and the
## §8.3 cap-change rules, §7.2 timing multipliers, §10 aging and decline, §9.5
## seasonal bands, the source ledger, and career-year completion receipts.
##
## The executor is recorded on every ledger entry so parity between the manual
## path and the allocator is measurable rather than asserted (§9.7.2, report 16).


enum Value {
	MANUAL,                 ## the user, spending personally and permanently
	FULL_DETAIL_ALLOCATOR,  ## named NPCs in full-detail simulation
	AGGREGATE,              ## reduced-detail populations resolved in bulk
}

const COUNT: int = 3
const IDS: PackedStringArray = ["manual", "full_detail_allocator", "aggregate"]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown development executor")
	return StringName(IDS[value])


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown development executor id")
	return Value.MANUAL
