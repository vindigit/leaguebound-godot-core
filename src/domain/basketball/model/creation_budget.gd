class_name CreationBudget
extends RefCounted

## The creation Attribute Point budget (`BALANCE_SPEC.md` §7.1, OD-B; PRD
## BUILD-006; `GODOT_TDD.md` §5.5).
##
## Creation AP is a **separate budget from the career wallet**. §7.1 requires it
## to be fully spent before a build can be confirmed, and forbids every escape
## route: retained creation currency "cannot be carried into the career,
## converted to direct progress, refunded, or banked for later seasons."
## §28 lists "Creation Attribute Points survive build confirmation in any form"
## as a release blocker.
##
## This type therefore exposes no transfer, refund, convert, or bank operation
## at all. The absence is the enforcement — a method that could move creation AP
## into the career wallet would be the defect, so none exists. `is_exhausted` is
## the only gate the Builder consults before permitting confirmation.
##
## The design consequence §7.1 draws is worth restating: this makes weak builds
## a consequence of allocation, not of hoarding. An intentionally poor player is
## produced by spending the full budget into incompatible, redundant, or
## role-irrelevant attributes — which is legal and unblocked.

const SCHEMA_VERSION: int = 1

var granted: int
var spent: int


func _init(p_granted: int, p_spent: int = 0) -> void:
	assert(p_granted > 0, "a creation budget must grant a positive number of Attribute Points")
	assert(p_spent >= 0 and p_spent <= p_granted, "creation spend must lie within the grant")
	granted = p_granted
	spent = p_spent


func remaining() -> int:
	return granted - spent


## §7.1: the Builder blocks confirmation while any creation AP remains unspent.
func is_exhausted() -> bool:
	return remaining() == 0


func can_afford(cost: int) -> bool:
	assert(cost >= 0, "a cost cannot be negative")
	return cost <= remaining()


func spend(cost: int) -> void:
	assert(cost >= 0, "a cost cannot be negative")
	assert(can_afford(cost), "insufficient creation Attribute Points")
	spent += cost


## Refunding *within the Builder* is legal and is not a currency escape: the
## user has not confirmed, no career exists yet, and the AP returns to the same
## creation budget it came from. It can never leave this object.
func refund_within_builder(cost: int) -> void:
	assert(cost >= 0, "a refund cannot be negative")
	assert(cost <= spent, "cannot refund creation Attribute Points that were never spent")
	spent -= cost


func duplicate_budget() -> CreationBudget:
	return CreationBudget.new(granted, spent)
