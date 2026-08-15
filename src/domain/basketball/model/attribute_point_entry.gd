class_name AttributePointEntry
extends RefCounted

## One line of the AP-equivalent source ledger (`BALANCE_SPEC.md` §9.7.2).
##
## A grant carries a positive `amount`; a spend carries a negative `amount` and
## names the attribute it bought. Recording both in one ordered ledger is what
## makes anti-duplication checkable: a season's grants can be reconciled against
## its receipts, and a duplicated annual resolution shows up as two grants with
## the same source and career year rather than as a silently larger number.


var career_year: int
var source: int
var executor: int
var amount: float
var attribute: int
var balance_version: String
var note: String


func _init(
	p_career_year: int,
	p_source: int,
	p_executor: int,
	p_amount: float,
	p_balance_version: String,
	p_attribute: int = -1,
	p_note: String = "",
) -> void:
	assert(p_career_year > 0, "a ledger entry belongs to a real career year")
	assert(AttributePointSource.is_valid(p_source), "unknown attribute point source")
	assert(DevelopmentExecutor.is_valid(p_executor), "unknown development executor")
	assert(not p_balance_version.is_empty(),
		"every ledger entry records the balance-profile version that produced it")
	assert(p_attribute == -1 or (p_attribute >= 0 and p_attribute < AttributeKey.COUNT),
		"a ledger entry either names a canonical attribute or names none")
	career_year = p_career_year
	source = p_source
	executor = p_executor
	amount = p_amount
	attribute = p_attribute
	balance_version = p_balance_version
	note = p_note


func is_grant() -> bool:
	return amount > 0.0


func is_spend() -> bool:
	return amount < 0.0


func signature() -> String:
	var attribute_name: String = (
		String(AttributeKey.name_of(attribute)) if attribute >= 0 else "-"
	)
	return "y=%d;src=%s;exec=%s;amt=%.4f;attr=%s" % [
		career_year,
		AttributePointSource.id_of(source),
		DevelopmentExecutor.id_of(executor),
		amount,
		attribute_name,
	]
