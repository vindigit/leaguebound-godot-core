class_name AttributePointLedger
extends RefCounted

## The AP-equivalent source ledger, shared by the user and every NPC executor
## (`GODOT_TDD.md` §5.5, `BALANCE_SPEC.md` §9.7.2).
##
## The ledger owns the career wallet balance. It is the only place general AP
## exists, which is what makes the §7.1 creation-currency prohibition
## enforceable: `grant` rejects an `AttributePointSource.CREATION` entry
## outright, so there is no code path by which creation AP can become career
## currency. §28 lists that leak as a release blocker.
##
## Aggregate executors write entries "at whatever granularity [they resolve], so
## promotion has real history to inherit" (§9.7.3). The ledger therefore accepts
## coarse entries without complaint; what it does not accept is an unattributed
## one.

const SCHEMA_VERSION: int = 1

var _entries: Array[AttributePointEntry]
var _balance: float
## Running total of AP-equivalent *granted* in each career year, excluding the
## §9.2 at-cap conversion.
##
## This is the §9.5 seasonal total, and it lives here because the ledger is the
## only object that sees every entry. §9.7.2 binds every executor to the §9.5
## seasonal bands and upper guardrails, so the guardrail has to be checkable on
## every season of every career; a check that cost a full ledger scan would be
## one nobody could afford to run in production, and an unaffordable rule is an
## unenforced one.
##
## The at-cap conversion is excluded because §9.2 makes it a refund of progress
## the player already earned and could not spend, not new seasonal availability.
var _granted_by_year: Dictionary[int, float]


func _init(p_entries: Array[AttributePointEntry] = []) -> void:
	_entries = []
	_balance = 0.0
	_granted_by_year = {}
	for entry in p_entries:
		_entries.append(entry)
		_balance += entry.amount
		_index_grant(entry)


## Available general AP. Fractional balances are legal because game development
## (§9.6) and decline (§10.3) both accumulate fractionally.
func balance() -> float:
	return _balance


func whole_points_available() -> int:
	return int(floorf(_balance))


func entries() -> Array[AttributePointEntry]:
	return _entries.duplicate()


func entry_count() -> int:
	return _entries.size()


## Grant AP-equivalent opportunity.
##
## Creation AP is rejected here by design. §7.1 forbids creation currency from
## being carried into the career, converted, refunded, or banked; the career
## wallet simply has no door it can come through.
func grant(
	career_year: int,
	source: int,
	executor: int,
	amount: float,
	balance_version: String,
	note: String = "",
) -> void:
	assert(source != AttributePointSource.Value.CREATION,
		"creation Attribute Points can never enter the career wallet (§7.1, §28)")
	assert(amount > 0.0, "a grant adds AP-equivalent opportunity")
	_append(AttributePointEntry.new(
		career_year, source, executor, amount, balance_version, -1, note))


## Record a loss of AP-equivalent standing, used by natural decline.
func debit(
	career_year: int,
	source: int,
	executor: int,
	amount: float,
	balance_version: String,
	attribute: int = -1,
	note: String = "",
) -> void:
	assert(amount > 0.0, "pass the magnitude; the ledger records the sign")
	_append(AttributePointEntry.new(
		career_year, source, executor, -amount, balance_version, attribute, note))


## Spend AP on a named attribute. Callers check caps and costs first; the ledger
## enforces only that the wallet can cover the spend.
func spend(
	career_year: int,
	executor: int,
	attribute: int,
	cost: int,
	balance_version: String,
	source: int = AttributePointSource.Value.TRAINING,
	note: String = "",
) -> void:
	assert(cost > 0, "a spend consumes AP")
	assert(float(cost) <= _balance + 0.000001, "insufficient AP-equivalent balance")
	_append(AttributePointEntry.new(
		career_year, source, executor, -float(cost), balance_version, attribute, note))


func _append(entry: AttributePointEntry) -> void:
	_entries.append(entry)
	_balance += entry.amount
	_index_grant(entry)


## Keep the §9.5 seasonal total current. Only grants count toward the seasonal
## band: a spend moves opportunity into a rating and a decline debit removes
## standing, and neither is availability the season delivered.
func _index_grant(entry: AttributePointEntry) -> void:
	if not entry.is_grant():
		return
	if entry.source == AttributePointSource.Value.AT_CAP_CONVERSION:
		return
	var year: int = entry.career_year
	if _granted_by_year.has(year):
		_granted_by_year[year] += entry.amount
	else:
		_granted_by_year[year] = entry.amount


## AP-equivalent granted in one career year against the §9.5 seasonal band.
##
## Constant time, so §9.7.2's requirement that every executor be bound by the
## §9.5 guardrail can actually be enforced on every season rather than sampled.
func granted_in_year(career_year: int) -> float:
	if not _granted_by_year.has(career_year):
		return 0.0
	return _granted_by_year[career_year]


## Total granted from one source in one career year. This is the anti-duplication
## probe: §9.5 permits at most one natural development-or-decline resolution and
## one generic offseason phase per career year, so a second grant from the same
## source in the same year is a duplication defect, not a larger reward.
func granted_from(career_year: int, source: int) -> float:
	var total: float = 0.0
	for entry in _entries:
		if entry.career_year == career_year and entry.source == source and entry.is_grant():
			total += entry.amount
	return total


func grant_count_from(career_year: int, source: int) -> int:
	var count: int = 0
	for entry in _entries:
		if entry.career_year == career_year and entry.source == source and entry.is_grant():
			count += 1
	return count


func total_granted() -> float:
	var total: float = 0.0
	for entry in _entries:
		if entry.is_grant():
			total += entry.amount
	return total


func total_spent() -> float:
	var total: float = 0.0
	for entry in _entries:
		if entry.is_spend():
			total -= entry.amount
	return total


func entries_for_executor(executor: int) -> Array[AttributePointEntry]:
	var matching: Array[AttributePointEntry] = []
	for entry in _entries:
		if entry.executor == executor:
			matching.append(entry)
	return matching


func duplicate_ledger() -> AttributePointLedger:
	return AttributePointLedger.new(_entries.duplicate())


func signature() -> String:
	var parts: PackedStringArray = []
	for entry in _entries:
		parts.append(entry.signature())
	return "|".join(parts)
