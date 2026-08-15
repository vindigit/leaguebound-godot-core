class_name BodyProfile
extends RefCounted

## Realized current body (`SIMULATION_SPEC.md` §6.1).
##
## This is the **realized current** body only. The engine never consumes the
## projected adult range, the maturity profile, or any unresolved growth — those
## live in `BodyMaturationState` in the career domain, and the match engine
## cannot resolve, advance, or observe growth (§6.1).
##
## `BALANCE_SPEC.md` §29.2 item 5 records the gap this closes: the previous type
## stored height, weight, and wingspan only. Standing reach is required by
## `GODOT_TDD.md` §5.5 and by the §6.1 interface, because reach — not height — is
## what actually governs contest arrival, block access, and rebound access.
##
## Body affects action validity, reach, positioning/leverage, and matchups, and
## nothing else. It "must never contribute a general bonus to unrelated
## outcomes, and it must never be read as a proxy for Overall" (§6.1).

const SCHEMA_VERSION: int = 2

## Credible bounds for an active basketball player. These reject corrupt or
## migrated-placeholder data rather than express a design preference; the
## Builder applies its own, tighter, family-specific limits.
const MINIMUM_HEIGHT_INCHES: int = 58
const MAXIMUM_HEIGHT_INCHES: int = 96
const MINIMUM_WEIGHT_POUNDS: int = 90
const MAXIMUM_WEIGHT_POUNDS: int = 400

var height_inches: int
var weight_pounds: int
var wingspan_inches: int
var standing_reach_inches: int


func _init(
	p_height_inches: int = 76,
	p_weight_pounds: int = 200,
	p_wingspan_inches: int = 78,
	p_standing_reach_inches: int = 0,
) -> void:
	assert(
		p_height_inches >= MINIMUM_HEIGHT_INCHES and p_height_inches <= MAXIMUM_HEIGHT_INCHES,
		"height must be a credible active-player height in inches"
	)
	assert(
		p_weight_pounds >= MINIMUM_WEIGHT_POUNDS and p_weight_pounds <= MAXIMUM_WEIGHT_POUNDS,
		"weight must be a credible active-player weight in pounds"
	)
	assert(p_wingspan_inches > 0, "wingspan must be positive")
	height_inches = p_height_inches
	weight_pounds = p_weight_pounds
	wingspan_inches = p_wingspan_inches
	standing_reach_inches = (
		p_standing_reach_inches
		if p_standing_reach_inches > 0
		else derive_standing_reach(p_height_inches, p_wingspan_inches)
	)
	assert(standing_reach_inches > height_inches,
		"standing reach is measured with the arm raised and always exceeds height")


## Standing reach derived from height and wingspan.
##
## Used when a record predates the standing-reach field (schema v1) and by the
## Builder when the user has not overridden it. The shares are owned by
## `BuilderProfile`; the parameterless form here exists so a bare `BodyProfile`
## can still satisfy its own invariant without reaching for a balance profile,
## which the purity boundary (`GODOT_TDD.md` §5.1) would not permit it to load.
static func derive_standing_reach(height: int, wingspan: int) -> int:
	return int(roundf(float(height) * 0.585 + float(wingspan) * 0.720))


func with_dimensions(
	p_height_inches: int,
	p_weight_pounds: int,
	p_wingspan_inches: int,
	p_standing_reach_inches: int,
) -> BodyProfile:
	return BodyProfile.new(
		p_height_inches, p_weight_pounds, p_wingspan_inches, p_standing_reach_inches)


func duplicate_body() -> BodyProfile:
	return BodyProfile.new(height_inches, weight_pounds, wingspan_inches, standing_reach_inches)


func signature() -> String:
	return "h=%d;w=%d;ws=%d;sr=%d" % [
		height_inches, weight_pounds, wingspan_inches, standing_reach_inches,
	]
