class_name BodyRange
extends RefCounted

## The bounded projected adult body range (`BALANCE_SPEC.md` §7.4.2).
##
## Displayed by the Builder, **stored at confirmation, and immutable for the
## career**. §7.4.2 marks three facts as Structural invariants:
##
##   - the displayed range is stored at confirmation and cannot change;
##   - the realized adult body must fall inside it on every dimension;
##   - the exact adult body is drawn deterministically from the versioned career
##     seed at creation and stays hidden until each increment resolves.
##
## Only the range *widths* are tunable (Baseline pending report 15). The binding
## nature of the range is not.


const SCHEMA_VERSION: int = 1

var height_minimum: int
var height_maximum: int
var weight_minimum: int
var weight_maximum: int
var wingspan_minimum: int
var wingspan_maximum: int
var standing_reach_minimum: int
var standing_reach_maximum: int


func _init(
	p_height_minimum: int,
	p_height_maximum: int,
	p_weight_minimum: int,
	p_weight_maximum: int,
	p_wingspan_minimum: int,
	p_wingspan_maximum: int,
	p_standing_reach_minimum: int,
	p_standing_reach_maximum: int,
) -> void:
	assert(p_height_minimum <= p_height_maximum, "projected height range is inverted")
	assert(p_weight_minimum <= p_weight_maximum, "projected weight range is inverted")
	assert(p_wingspan_minimum <= p_wingspan_maximum, "projected wingspan range is inverted")
	assert(p_standing_reach_minimum <= p_standing_reach_maximum,
		"projected standing reach range is inverted")
	height_minimum = p_height_minimum
	height_maximum = p_height_maximum
	weight_minimum = p_weight_minimum
	weight_maximum = p_weight_maximum
	wingspan_minimum = p_wingspan_minimum
	wingspan_maximum = p_wingspan_maximum
	standing_reach_minimum = p_standing_reach_minimum
	standing_reach_maximum = p_standing_reach_maximum


## §7.4.2 Containment, the structural invariant: "Realized **adult** body must
## fall inside the stored range on every dimension."
##
## The range projects the *adult* body, so a still-growing player legitimately
## sits below its lower bound — a freshman who will grow four more inches has
## not yet reached his projected adult height. Full containment is therefore
## checked at adulthood; `permits_intermediate` covers the years in between and
## enforces the half of §7.4.3 rule 2 that binds throughout, namely that no
## increment may take a dimension *above* the stored range.
func contains_body(body: BodyProfile) -> bool:
	return (
		body.height_inches >= height_minimum and body.height_inches <= height_maximum
		and body.weight_pounds >= weight_minimum and body.weight_pounds <= weight_maximum
		and body.wingspan_inches >= wingspan_minimum and body.wingspan_inches <= wingspan_maximum
		and body.standing_reach_inches >= standing_reach_minimum
		and body.standing_reach_inches <= standing_reach_maximum
	)


## Whether a still-growing body is legal: never above the projected adult
## maximum on any dimension, and never shrinking on a skeletal dimension.
##
## Height, wingspan, and standing reach are skeletal and only ever increase.
## Weight is not: `BALANCE_SPEC.md` §7.4 requires weight evolution and training
## to be modelled separately from height growth, and a player can legitimately
## lose weight. Weight is therefore bounded above by the projection and below by
## the health floor the caller supplies, rather than being monotone.
func permits_intermediate(
	body: BodyProfile,
	freshman: BodyProfile,
	weight_health_floor: int,
) -> bool:
	return intermediate_failures(body, freshman, weight_health_floor).is_empty()


func intermediate_failures(
	body: BodyProfile,
	freshman: BodyProfile,
	weight_health_floor: int,
) -> PackedStringArray:
	var failures: PackedStringArray = []
	if body.height_inches > height_maximum or body.height_inches < freshman.height_inches:
		failures.append("height %d outside %d..%d in progress" % [
			body.height_inches, freshman.height_inches, height_maximum])
	if body.wingspan_inches > wingspan_maximum or body.wingspan_inches < freshman.wingspan_inches:
		failures.append("wingspan %d outside %d..%d in progress" % [
			body.wingspan_inches, freshman.wingspan_inches, wingspan_maximum])
	if (body.standing_reach_inches > standing_reach_maximum
			or body.standing_reach_inches < freshman.standing_reach_inches):
		failures.append("standing reach %d outside %d..%d in progress" % [
			body.standing_reach_inches, freshman.standing_reach_inches, standing_reach_maximum])
	if body.weight_pounds > weight_maximum or body.weight_pounds < weight_health_floor:
		failures.append("weight %d outside %d..%d in progress" % [
			body.weight_pounds, weight_health_floor, weight_maximum])
	return failures


func containment_failures(body: BodyProfile) -> PackedStringArray:
	var failures: PackedStringArray = []
	if body.height_inches < height_minimum or body.height_inches > height_maximum:
		failures.append("height %d outside %d..%d" % [
			body.height_inches, height_minimum, height_maximum])
	if body.weight_pounds < weight_minimum or body.weight_pounds > weight_maximum:
		failures.append("weight %d outside %d..%d" % [
			body.weight_pounds, weight_minimum, weight_maximum])
	if body.wingspan_inches < wingspan_minimum or body.wingspan_inches > wingspan_maximum:
		failures.append("wingspan %d outside %d..%d" % [
			body.wingspan_inches, wingspan_minimum, wingspan_maximum])
	if (body.standing_reach_inches < standing_reach_minimum
			or body.standing_reach_inches > standing_reach_maximum):
		failures.append("standing reach %d outside %d..%d" % [
			body.standing_reach_inches, standing_reach_minimum, standing_reach_maximum])
	return failures


## The widest range consistent with a realized body, used by the §7.4.4 /
## `GODOT_TDD.md` §5.7 migration rule when a stored range cannot be recovered.
##
## The rule is deliberately asymmetric: reconstruct **wide** and record the
## limitation. Narrowing a range around the realized value to fabricate
## precision is prohibited, because it would turn a lost fact into a false
## certainty the player would read as a real projection.
static func widest_consistent_with(
	body: BodyProfile,
	height_slack: int,
	weight_slack: int,
	wingspan_slack: int,
	reach_slack: int,
) -> BodyRange:
	assert(height_slack >= 0 and weight_slack >= 0 and wingspan_slack >= 0 and reach_slack >= 0,
		"reconstruction slack cannot be negative")
	return BodyRange.new(
		maxi(BodyProfile.MINIMUM_HEIGHT_INCHES, body.height_inches - height_slack),
		mini(BodyProfile.MAXIMUM_HEIGHT_INCHES, body.height_inches + height_slack),
		maxi(BodyProfile.MINIMUM_WEIGHT_POUNDS, body.weight_pounds - weight_slack),
		mini(BodyProfile.MAXIMUM_WEIGHT_POUNDS, body.weight_pounds + weight_slack),
		maxi(1, body.wingspan_inches - wingspan_slack),
		body.wingspan_inches + wingspan_slack,
		maxi(1, body.standing_reach_inches - reach_slack),
		body.standing_reach_inches + reach_slack
	)


func duplicate_range() -> BodyRange:
	return BodyRange.new(
		height_minimum, height_maximum,
		weight_minimum, weight_maximum,
		wingspan_minimum, wingspan_maximum,
		standing_reach_minimum, standing_reach_maximum
	)


func signature() -> String:
	return "h=%d..%d;w=%d..%d;ws=%d..%d;sr=%d..%d" % [
		height_minimum, height_maximum,
		weight_minimum, weight_maximum,
		wingspan_minimum, wingspan_maximum,
		standing_reach_minimum, standing_reach_maximum,
	]
