class_name BodyMaturationState
extends RefCounted

## The persistent body career fact (`BALANCE_SPEC.md` §7.4, `GODOT_TDD.md` §5.5).
##
## Confirmed freshman body, maturity profile, stored projected adult range,
## realized current body, and the resolved-increment ledger are all **stored
## career facts, not derived values** (§7.4.4, `GODOT_TDD.md` §5.7). They carry a
## schema version, and any migration that cannot recover a stored projected
## range must reconstruct the widest consistent range and record the limitation.
##
## This type owns the once-only guarantee. `has_resolved` is the receipt check;
## `resolve` refuses a duplicate rather than quietly re-applying it, so a reload
## or a detail-level change cannot grow a player twice.

const SCHEMA_VERSION: int = 1

## How far below the confirmed freshman weight a player may fall through
## conditioning before the body is considered outside credible health bounds.
const WEIGHT_LOSS_ALLOWANCE_POUNDS: int = 15

var confirmed_freshman_body: BodyProfile
var maturity: int
var projected_range: BodyRange
var realized_body: BodyProfile
var reconstructed_range: bool

var _increments: Array[GrowthIncrement]


func _init(
	p_confirmed_freshman_body: BodyProfile,
	p_maturity: int,
	p_projected_range: BodyRange,
	p_realized_body: BodyProfile = null,
	p_increments: Array[GrowthIncrement] = [],
	p_reconstructed_range: bool = false,
) -> void:
	assert(p_confirmed_freshman_body != null, "a confirmed freshman body is required")
	assert(MaturityProfile.is_valid(p_maturity), "unknown maturity profile")
	assert(p_projected_range != null, "a stored projected adult range is required")
	confirmed_freshman_body = p_confirmed_freshman_body
	maturity = p_maturity
	projected_range = p_projected_range
	realized_body = (
		p_realized_body if p_realized_body != null
		else p_confirmed_freshman_body.duplicate_body()
	)
	reconstructed_range = p_reconstructed_range
	_increments = p_increments.duplicate()
	assert(
		projected_range.permits_intermediate(
			realized_body, confirmed_freshman_body, weight_health_floor()),
		"the realized body has left the stored projected range"
	)


## Lower bound on weight for a still-growing player, from the confirmed freshman
## weight. §7.4 requires weight to stay "within credible health/body bounds";
## this is that floor, expressed relative to the body the player was confirmed
## with rather than as a universal number.
func weight_health_floor() -> int:
	return maxi(
		BodyProfile.MINIMUM_WEIGHT_POUNDS,
		confirmed_freshman_body.weight_pounds - WEIGHT_LOSS_ALLOWANCE_POUNDS
	)


## §6.3 idempotency: has the increment for this career year already resolved?
func has_resolved(career_year: int) -> bool:
	for increment in _increments:
		if increment.career_year == career_year:
			return true
	return false


func resolved_increments() -> Array[GrowthIncrement]:
	return _increments.duplicate()


func resolved_count() -> int:
	return _increments.size()


## Apply one increment. Refuses a duplicate career year and refuses any result
## that would leave the stored projected range.
func resolve(increment: GrowthIncrement, total_milestones: int) -> void:
	assert(not has_resolved(increment.career_year),
		"a growth increment already resolved for career year %d; §6.3 permits exactly one"
			% increment.career_year)
	assert(not is_final(total_milestones),
		"the body is final; no further increment is legal (§6.3 REACH_ADULT_BODY)")

	var failures: PackedStringArray = projected_range.intermediate_failures(
		increment.resulting_body, confirmed_freshman_body, weight_health_floor())
	assert(
		failures.is_empty(),
		"growth left the stored projected adult range: %s" % ", ".join(failures)
	)

	_increments.append(increment)
	realized_body = increment.resulting_body

	# §7.4.2 structural invariant: the realized *adult* body falls inside the
	# stored range on every dimension. Checked once, when growth completes.
	if is_final(total_milestones):
		var adult_failures: PackedStringArray = projected_range.containment_failures(realized_body)
		assert(
			adult_failures.is_empty(),
			"the realized adult body fell outside the stored projected range: %s"
				% ", ".join(adult_failures)
		)


## §6.3 `REACH_ADULT_BODY`: all scheduled increments resolved, no further
## increment is legal.
func is_final(total_milestones: int) -> bool:
	return _increments.size() >= total_milestones


func duplicate_state() -> BodyMaturationState:
	return BodyMaturationState.new(
		confirmed_freshman_body.duplicate_body(),
		maturity,
		projected_range.duplicate_range(),
		realized_body.duplicate_body(),
		_increments.duplicate(),
		reconstructed_range
	)


func signature() -> String:
	var parts: PackedStringArray = []
	parts.append("freshman=%s" % confirmed_freshman_body.signature())
	parts.append("maturity=%s" % MaturityProfile.id_of(maturity))
	parts.append("range=%s" % projected_range.signature())
	parts.append("realized=%s" % realized_body.signature())
	for increment in _increments:
		parts.append("inc[%s]" % increment.signature())
	return "|".join(parts)
