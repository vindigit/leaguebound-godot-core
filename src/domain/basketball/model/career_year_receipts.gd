class_name CareerYearReceipts
extends RefCounted

## Shared career-year completion receipts (`BALANCE_SPEC.md` §9.5, §9.7.2).
##
## "One career year permits at most one age increase, one natural
## development-or-decline resolution, one generic offseason-development phase,
## and one professional-service credit. Changing levels, assignment, recall,
## release, or a second offseason entry cannot rerun any of them."
##
## Crucially these receipts are shared across executors (§9.7.2): one career year
## permits one natural resolution *per player regardless of executor*. That is
## what stops a player being developed once as an aggregate row and again after
## promotion to full detail — the §9.7.4 detail-promotion invariance requirement.
##
## Balance owns the magnitude of eligible progression, not the scheduling or
## duplication of these structural resolutions, so nothing in a balance profile
## can relax a receipt.

const SCHEMA_VERSION: int = 1


enum Resolution {
	AGE_INCREASE,
	NATURAL_DEVELOPMENT_OR_DECLINE,
	GENERIC_OFFSEASON_DEVELOPMENT,
	PROFESSIONAL_SERVICE,
	BODY_GROWTH_INCREMENT,
}

const RESOLUTION_COUNT: int = 5
const RESOLUTION_IDS: PackedStringArray = [
	"age_increase",
	"natural_development_or_decline",
	"generic_offseason_development",
	"professional_service",
	"body_growth_increment",
]

## Stored as "career_year:resolution" keys so the receipt book serializes as a
## flat, order-independent set rather than a nested structure.
var _receipts: Dictionary


func _init(p_receipt_keys: PackedStringArray = []) -> void:
	_receipts = {}
	for key in p_receipt_keys:
		_receipts[key] = true


static func is_valid_resolution(resolution: int) -> bool:
	return resolution >= 0 and resolution < RESOLUTION_COUNT


static func _key(career_year: int, resolution: int) -> String:
	assert(career_year > 0, "a receipt belongs to a real career year")
	assert(is_valid_resolution(resolution), "unknown career-year resolution")
	return "%d:%s" % [career_year, RESOLUTION_IDS[resolution]]


func has_resolved(career_year: int, resolution: int) -> bool:
	return _receipts.has(_key(career_year, resolution))


## Claim a resolution for a career year. Returns `true` when the caller now owns
## it and `false` when it had already resolved.
##
## Returning a boolean rather than asserting is deliberate: a duplicate attempt
## is an ordinary, expected event — a reload, a level change, a recall — and the
## correct behaviour is to decline it quietly, not to crash. What must never
## happen is the resolution running twice.
func claim(career_year: int, resolution: int) -> bool:
	var key: String = _key(career_year, resolution)
	if _receipts.has(key):
		return false
	_receipts[key] = true
	return true


func keys() -> PackedStringArray:
	var result: PackedStringArray = []
	for key: String in _receipts.keys():
		result.append(key)
	result.sort()
	return result


func count() -> int:
	return _receipts.size()


func duplicate_receipts() -> CareerYearReceipts:
	return CareerYearReceipts.new(keys())


func signature() -> String:
	return ",".join(keys())
