class_name CapChangeLedger
extends RefCounted

## The cap-change ledger (`GODOT_TDD.md` §5.7, `BALANCE_SPEC.md` §8.3).
##
## Ordinary development never changes caps. Only the four §8.3 events do, and
## each records why. The critical invariant this ledger exists to make auditable
## is the last paragraph of §8.3:
##
##   "A potential-cap reduction by itself never lowers the current rating."
##
## So a cap entry records a cap movement and nothing else. Any accompanying
## current-rating loss is a separate health, injury, or decline effect with its
## own ledger entry, and is never inferred from the cap mutation.


enum Reason {
	GENERATION,        ## the exact caps drawn at career creation
	BREAKTHROUGH,      ## §8.3 unprompted positive breakthrough
	SETBACK,           ## §8.3 unprompted negative setback
	AUTHORED_EVENT,    ## §8.3 major authored development event
	INJURY,            ## §8.3 major or catastrophic injury
	MIGRATION,         ## a deterministic balance or schema migration
}

const REASON_IDS: PackedStringArray = [
	"generation", "breakthrough", "setback", "authored_event", "injury", "migration",
]

const SCHEMA_VERSION: int = 1


class Entry extends RefCounted:
	var career_year: int
	var attribute: int
	var previous_cap: int
	var new_cap: int
	var reason: int
	var balance_version: String

	func _init(
		p_career_year: int,
		p_attribute: int,
		p_previous_cap: int,
		p_new_cap: int,
		p_reason: int,
		p_balance_version: String,
	) -> void:
		assert(p_attribute >= 0 and p_attribute < AttributeKey.COUNT, "unknown attribute key")
		assert(p_reason >= 0 and p_reason < CapChangeLedger.REASON_IDS.size(),
			"unknown cap change reason")
		assert(not p_balance_version.is_empty(),
			"every cap change records the balance-profile version that produced it")
		career_year = p_career_year
		attribute = p_attribute
		previous_cap = p_previous_cap
		new_cap = p_new_cap
		reason = p_reason
		balance_version = p_balance_version

	func signature() -> String:
		return "y=%d;attr=%s;%d->%d;why=%s" % [
			career_year,
			AttributeKey.name_of(attribute),
			previous_cap,
			new_cap,
			CapChangeLedger.REASON_IDS[reason],
		]


var _entries: Array[Entry]


func _init(p_entries: Array[Entry] = []) -> void:
	_entries = p_entries.duplicate()


func record(
	career_year: int,
	attribute: int,
	previous_cap: int,
	new_cap: int,
	reason: int,
	balance_version: String,
) -> void:
	_entries.append(Entry.new(
		career_year, attribute, previous_cap, new_cap, reason, balance_version))


func entries() -> Array[Entry]:
	return _entries.duplicate()


func entry_count() -> int:
	return _entries.size()


## §8.3: at most one unprompted cap change per offseason.
func changes_in_year(career_year: int) -> int:
	var count: int = 0
	for entry in _entries:
		if entry.career_year == career_year and entry.reason != Reason.GENERATION:
			count += 1
	return count


func duplicate_ledger() -> CapChangeLedger:
	return CapChangeLedger.new(_entries.duplicate())


func signature() -> String:
	var parts: PackedStringArray = []
	for entry in _entries:
		parts.append(entry.signature())
	return "|".join(parts)
