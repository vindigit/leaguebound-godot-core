class_name CapabilityWeightSet
extends RefCounted

## One row of the `BALANCE_SPEC.md` §5.2 capability weight table.
##
## Two things in that table are structural rather than tunable and are asserted
## here rather than left to review:
##
## 1. "Primary inputs must retain at least 55% of the weight."
## 2. Every capability must name its primary skill.
##
## The exact percentages are Baselines and stay versioned tunables until the
## §31 attribute-sensitivity and build-diversity reports pass.
##
## `contextual_share` covers the two rows whose final term is not an attribute:
## Shot Selection's "relevant shooting rating 10%" and Help Recognition's
## "role execution 10%". §5.2 is explicit that the latter "is not the tactical
## role identity, and it must not be implemented by reading a `TacticalRole`
## ID" — it is the live quality of the player's current defensive assignment,
## supplied by the caller as match context.

const PRIMARY_WEIGHT_FLOOR: float = 0.55

var capability: int
var primary_attribute: int
var attribute_keys: Array[int]
var attribute_shares: Array[float]
var contextual_share: float
## How much of the §15.1 fatigue penalty this capability absorbs.
##
## §17.1: fatigue "affects burst, stability, decision execution, contest
## arrival, ball security, and recovery. It does not directly subtract the same
## flat amount from all ratings." A uniform penalty would be exactly the flat
## subtraction that sentence forbids, so each capability declares its own share
## and Work Capacity — the capability Stamina *is* — declares zero.
var fatigue_sensitivity: float


func _init(
	p_capability: int,
	p_primary_attribute: int,
	p_attribute_keys: Array[int],
	p_attribute_shares: Array[float],
	p_contextual_share: float = 0.0,
	p_fatigue_sensitivity: float = 1.0,
) -> void:
	assert(p_fatigue_sensitivity >= 0.0 and p_fatigue_sensitivity <= 1.0,
		"fatigue sensitivity is a share of the §15.1 band penalty")
	assert(CapabilityKey.is_valid(p_capability), "unknown capability key")
	assert(p_attribute_keys.size() == p_attribute_shares.size(),
		"every weighted attribute needs exactly one share")
	assert(not p_attribute_keys.is_empty(), "a capability must weight at least one attribute")
	assert(p_attribute_keys.has(p_primary_attribute),
		"a capability must name a primary skill that it actually weights")
	assert(p_contextual_share >= 0.0 and p_contextual_share < 1.0,
		"the contextual share must be a proper fraction")
	var total: float = p_contextual_share
	var primary_share: float = 0.0
	for index in range(p_attribute_keys.size()):
		assert(p_attribute_shares[index] > 0.0, "a zero-weight attribute does not belong in the table")
		total += p_attribute_shares[index]
		if p_attribute_keys[index] == p_primary_attribute:
			primary_share = p_attribute_shares[index]
	assert(absf(total - 1.0) < 0.000001, "capability weights must sum to exactly 1.0")
	assert(primary_share >= PRIMARY_WEIGHT_FLOOR - 0.000001,
		"BALANCE_SPEC §5.2 requires the primary input to retain at least 55% of the weight")
	capability = p_capability
	primary_attribute = p_primary_attribute
	attribute_keys = p_attribute_keys.duplicate()
	attribute_shares = p_attribute_shares.duplicate()
	contextual_share = p_contextual_share
	fatigue_sensitivity = p_fatigue_sensitivity


## Weighted mean on the 25-99 scale, normalized to the unit interval, before
## any context modifier. `context` supplies the non-attribute term for the two
## rows that declare one; it is ignored when `contextual_share` is zero.
func evaluate(attributes: PlayerAttributes, context: float) -> float:
	var total: float = 0.0
	for index in range(attribute_keys.size()):
		total += Rating.normalized(attributes.get_rating(attribute_keys[index])) * attribute_shares[index]
	if contextual_share > 0.0:
		total += clampf(context, 0.0, 1.0) * contextual_share
	return clampf(total, 0.0, 1.0)


func describe() -> String:
	var parts: PackedStringArray = []
	for index in range(attribute_keys.size()):
		parts.append("%s=%.2f" % [
			AttributeKey.name_of(attribute_keys[index]),
			attribute_shares[index],
		])
	if contextual_share > 0.0:
		parts.append("context=%.2f" % contextual_share)
	return "%s: %s" % [CapabilityKey.id_of(capability), ", ".join(parts)]
