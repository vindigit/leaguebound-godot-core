class_name PeriodCategory
extends RefCounted

## Which kind of period a period number is, given a competition's regulation
## length (`SIMULATION_SPEC.md` §4; `PROJECT_STATUS.md` §5.33, work-queue item
## 20).
##
## The owner ruling on made-field-goal clock stoppage is written against three
## period kinds and not against period numbers: a competition may stop the clock
## in the last minute of *every regulation period before the final one*, for
## longer in the *final regulation period*, and for longer again in *overtime*.
## Those three phrases are the whole vocabulary the rule needs.
##
## **It is derived, never stored.** A period number plus `regulation_periods` is
## enough to answer the question, and both are already authoritative — the number
## on `MatchState`, the count on `CompetitionRuleProfile`. Storing a category
## beside them would be a fourth fact that can disagree with the three that
## produce it.
##
## **No competition here has four regulation periods by assumption.** College
## plays two twenty-minute halves, so its final regulation period is period 2 and
## its only non-final one is period 1; the others play four quarters. Nothing
## below mentions a literal period number, which is what keeps a halves
## competition and a quarters competition on the same code path.


enum Value {
	## A regulation period with at least one more regulation period after it.
	## A competition that plays a single regulation period has none of these.
	NON_FINAL_REGULATION,
	## The last regulation period — the fourth quarter, or the second half.
	FINAL_REGULATION,
	## Any overtime period. Every overtime is the same category; a rule that
	## needed to tell a first overtime from a third would be a different rule
	## and would have to say so.
	OVERTIME,
}

const COUNT: int = 3
const IDS: PackedStringArray = [
	"non_final_regulation",
	"final_regulation",
	"overtime",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown period category")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown period category id")
	return Value.NON_FINAL_REGULATION


## The category of a one-based period number in a competition that plays
## `regulation_periods` periods of regulation.
##
## This is the same convention `CompetitionRuleProfile.period_length_ms` already
## uses to choose between a regulation and an overtime length — a period at or
## below the regulation count is regulation, anything above it is overtime — so
## the two cannot disagree about where regulation ends.
static func of(period: int, regulation_periods: int) -> int:
	assert(period > 0, "periods are one-based")
	assert(regulation_periods > 0, "regulation period count must be positive")
	if period > regulation_periods:
		return Value.OVERTIME
	if period == regulation_periods:
		return Value.FINAL_REGULATION
	return Value.NON_FINAL_REGULATION


## Whether this category is part of regulation. Published because the ruling is
## phrased as "regulation versus overtime" first and "final versus non-final"
## second, and a reader should be able to ask the first question on its own.
static func is_regulation(value: int) -> bool:
	assert(is_valid(value), "unknown period category")
	return value != Value.OVERTIME
