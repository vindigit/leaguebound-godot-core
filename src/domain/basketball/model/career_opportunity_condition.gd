class_name CareerOpportunityCondition
extends RefCounted

## Why a career's seasons are permitted to be exceptional (`BALANCE_SPEC.md`
## §9.5, owner ruling 2026-08).
##
## §9.5's upper guardrail "is not a hard currency cap. It triggers a balance
## warning and requires the source ledger to explain why the season was
## exceptional." Stage 4 measured a rare-generational career passing that
## guardrail in seventeen of its twenty-three seasons, which is not seventeen
## unrelated anomalies — it is one career that was exceptional throughout, and
## recording it seventeen times as an unexplained surprise would say nothing.
##
## The owner ruling names that as a **persistent career condition**. A career
## either carries it or does not, it is fixed for the whole career, and it is
## the thing the bounded guardrail exception attaches to. A career without the
## condition that passes its guardrail is a defect, whatever its outcome label
## says, which is what stops the exception spreading to another path.
##
## This is a permission, not a grant. Holding the condition changes no AP cost,
## no §9.6 game-development cap, no population share, and no seasonal draw; it
## changes only how much ledgered opportunity a career may legitimately receive
## before the model is judged wrong.


enum Value {
	## The ordinary case. Seasons are expected inside the §9.5 band, and passing
	## the upper guardrail is permitted but unexplained-by-default.
	ORDINARY,
	## §8.4's rare-generational conjunction: an elite ceiling and an elite
	## career. Seasons routinely sit in the high-engagement tail, and the career
	## may exceed the summed guardrails by the bounded share the progression
	## profile carries.
	ELITE_OPPORTUNITY,
}

const COUNT: int = 2
const IDS: PackedStringArray = ["ordinary", "elite_opportunity"]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown career opportunity condition")
	return StringName(IDS[value])


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown career opportunity condition id")
	return Value.ORDINARY


## Whether this condition permits a career to exceed the summed §9.5 seasonal
## guardrails at all.
static func permits_guardrail_exception(value: int) -> bool:
	return value == Value.ELITE_OPPORTUNITY
