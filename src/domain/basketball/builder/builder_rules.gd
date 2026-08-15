class_name BuilderRules
extends RefCounted

## Pure Builder rules: body limits, the §7.1 starting redistribution, and
## allocation validation.
##
## Everything here is a static function of value objects and a versioned
## profile. `GODOT_TDD.md` §6.2 makes a Builder scene that computes a cost
## table, re-derives an archetype, or recomputes Overall a release blocker, so
## these functions are the only implementation and presentation consumes their
## results as a projection.


## Credible freshman height range for a starting family. Guard, Wing, and Big
## are broad starting families, not permanent position locks (`GDD.md` §6.1,
## PRD BUILD-001) — these bound the *freshman measurement*, not the player's
## future.
static func height_bounds_for_family(family: int, profile: BuilderProfile) -> Array[int]:
	assert(PositionFamily.is_valid(family), "unknown position family")
	return [profile.family_height_minimum[family], profile.family_height_maximum[family]]


## Weight a given height implies, before the user's own selection.
static func reference_weight_for_height(height: int, profile: BuilderProfile) -> int:
	return int(roundf(
		float(profile.weight_reference_pounds)
		+ float(height - profile.weight_reference_height) * profile.weight_pounds_per_inch
	))


static func weight_bounds_for_height(height: int, profile: BuilderProfile) -> Array[int]:
	var reference: int = reference_weight_for_height(height, profile)
	return [
		maxi(BodyProfile.MINIMUM_WEIGHT_POUNDS, reference - profile.weight_selectable_margin),
		mini(BodyProfile.MAXIMUM_WEIGHT_POUNDS, reference + profile.weight_selectable_margin),
	]


static func wingspan_bounds_for_height(height: int, profile: BuilderProfile) -> Array[int]:
	return [height + profile.wingspan_delta_minimum, height + profile.wingspan_delta_maximum]


## Whether a body is a legal Builder selection for a family.
##
## `GDD.md` §6.1: "Physical dimensions are selected freely within credible
## position limits. Point forwards, stretch bigs, and other uncommon profiles
## remain possible but require the corresponding investment and tradeoffs."
## These bounds enforce credibility, never conventionality.
static func body_selection_failures(
	body: BodyProfile,
	family: int,
	profile: BuilderProfile,
) -> PackedStringArray:
	var failures: PackedStringArray = []
	var height_bounds: Array[int] = height_bounds_for_family(family, profile)
	if body.height_inches < height_bounds[0] or body.height_inches > height_bounds[1]:
		failures.append("height %d outside the %s freshman range %d..%d" % [
			body.height_inches, PositionFamily.label_of(family),
			height_bounds[0], height_bounds[1]])
		return failures

	var weight_bounds: Array[int] = weight_bounds_for_height(body.height_inches, profile)
	if body.weight_pounds < weight_bounds[0] or body.weight_pounds > weight_bounds[1]:
		failures.append("weight %d outside the credible range %d..%d for height %d" % [
			body.weight_pounds, weight_bounds[0], weight_bounds[1], body.height_inches])

	var wingspan_bounds: Array[int] = wingspan_bounds_for_height(body.height_inches, profile)
	if body.wingspan_inches < wingspan_bounds[0] or body.wingspan_inches > wingspan_bounds[1]:
		failures.append("wingspan %d outside the credible range %d..%d for height %d" % [
			body.wingspan_inches, wingspan_bounds[0], wingspan_bounds[1], body.height_inches])

	return failures


## The §7.1 body redistribution: "Body choices redistribute at most 18 total
## rating points and are approximately zero-sum. No body selection can create
## more than a four-point direct modifier on one starting attribute."
##
## Three properties are enforced here rather than hoped for:
##
##   - **Zero-sum.** The influence vectors are mean-centred before scaling, so a
##     body trades strengths instead of granting them. §7.4.3 rule 6: body is
##     "not free Overall".
##   - **Bounded per attribute.** Every modifier is clamped to the profile's
##     single-attribute maximum.
##   - **Bounded in total.** The vector is scaled down if the sum of absolute
##     modifiers would exceed the profile's redistribution total.
##
## Applies once, at creation. §7.4.3 rule 5: "Later growth does not grant a
## second redistribution."
static func body_redistribution(
	body: BodyProfile,
	family: int,
	profile: BuilderProfile,
) -> Array[int]:
	var height_bounds: Array[int] = height_bounds_for_family(family, profile)
	var size_deviation: float = _deviation(
		float(body.height_inches), float(height_bounds[0]), float(height_bounds[1]))

	# Length beyond what the height implies counts toward size: reach, not
	# stature, is what governs contest and block access (`SIMULATION_SPEC.md`
	# §6.1).
	var wingspan_bounds: Array[int] = wingspan_bounds_for_height(body.height_inches, profile)
	var length_deviation: float = _deviation(
		float(body.wingspan_inches), float(wingspan_bounds[0]), float(wingspan_bounds[1]))
	var combined_size: float = clampf((size_deviation + length_deviation) / 2.0, -1.0, 1.0)

	var weight_bounds: Array[int] = weight_bounds_for_height(body.height_inches, profile)
	var mass_deviation: float = _deviation(
		float(body.weight_pounds), float(weight_bounds[0]), float(weight_bounds[1]))

	var size_centred: Array[float] = _mean_centred(profile.size_influence)
	var mass_centred: Array[float] = _mean_centred(profile.mass_influence)

	var raw: Array[float] = []
	for attribute in AttributeKey.all():
		raw.append(
			combined_size * size_centred[attribute] * profile.size_redistribution_scale
			+ mass_deviation * mass_centred[attribute] * profile.mass_redistribution_scale
		)

	# Scale down before rounding if the total would exceed the §7.1 budget, so
	# the bound is respected without distorting the shape of the tradeoff.
	var absolute_total: float = 0.0
	for value in raw:
		absolute_total += absf(value)
	if absolute_total > float(profile.body_redistribution_total) and absolute_total > 0.0:
		var scale: float = float(profile.body_redistribution_total) / absolute_total
		for index in range(raw.size()):
			raw[index] *= scale

	var modifiers: Array[int] = []
	for value in raw:
		modifiers.append(clampi(
			int(roundf(value)),
			-profile.body_redistribution_single_maximum,
			profile.body_redistribution_single_maximum
		))

	var balanced: Array[int] = _rebalance_to_zero_sum(modifiers, raw, profile)
	return _trim_to_absolute_budget(balanced, profile)


## Starting ratings after the one-time body redistribution.
static func body_adjusted_bases(
	body: BodyProfile,
	family: int,
	profile: BuilderProfile,
) -> Array[int]:
	var bases: Array[int] = profile.base_ratings()
	var modifiers: Array[int] = body_redistribution(body, family, profile)
	var adjusted: Array[int] = []
	for attribute in AttributeKey.all():
		adjusted.append(clampi(
			bases[attribute] + modifiers[attribute],
			Rating.ACTIVE_MINIMUM,
			profile.starting_absolute_maximum
		))
	return adjusted


## Validate a complete allocation against bases, costs, caps, and the starting
## maxima. Returns every failure so the Builder can report them together.
static func allocation_failures(
	values: Array[int],
	bases: Array[int],
	caps: AttributeCaps,
	budget: CreationBudget,
	builder: BuilderProfile,
	progression: ProgressionProfile,
) -> PackedStringArray:
	var failures: PackedStringArray = []
	assert(values.size() == AttributeKey.COUNT, "expected the twenty canonical attributes")

	var total_cost: int = 0
	for attribute in AttributeKey.all():
		var value: int = values[attribute]
		var base: int = bases[attribute]
		var name: StringName = AttributeKey.name_of(attribute)

		if value < base:
			failures.append("%s below its body-adjusted base; allocation only raises" % name)
			continue
		if not Rating.is_valid_active(value):
			failures.append("%s outside the 25-99 active domain" % name)
			continue
		if value > builder.starting_absolute_maximum:
			failures.append("%s exceeds the absolute starting maximum of %d" % [
				name, builder.starting_absolute_maximum])
		if value > caps.cap_for(attribute):
			failures.append("%s exceeds its exact cap of %d" % [name, caps.cap_for(attribute)])
		total_cost += AttributeCostTable.cost_to_raise(base, value, progression)

	if total_cost != budget.spent:
		failures.append("allocation costs %d AP but %d was recorded as spent" % [
			total_cost, budget.spent])

	# §7.1, OD-B, PRD BUILD-006: confirmation is impossible while creation AP
	# remains. This is the gate, and it is checked here so no caller can confirm
	# without passing through it.
	if not budget.is_exhausted():
		failures.append(
			("%d creation Attribute Points remain unspent;" % budget.remaining())
			+ " the budget must reach zero before confirmation (§7.1)"
		)

	return failures


## Caps for the Builder must permit the starting maxima to be meaningful. A cap
## below the body-adjusted base would make an attribute unimprovable from the
## start, which §8 does not intend at creation.
static func caps_permit_bases(caps: AttributeCaps, bases: Array[int]) -> bool:
	for attribute in AttributeKey.all():
		if caps.cap_for(attribute) < bases[attribute]:
			return false
	return true


static func _deviation(value: float, minimum: float, maximum: float) -> float:
	if maximum <= minimum:
		return 0.0
	var centre: float = (minimum + maximum) / 2.0
	return clampf((value - centre) / ((maximum - minimum) / 2.0), -1.0, 1.0)


static func _mean_centred(influence: Array[float]) -> Array[float]:
	var total: float = 0.0
	for value in influence:
		total += value
	var mean: float = total / float(influence.size())
	var centred: Array[float] = []
	for value in influence:
		centred.append(value - mean)
	return centred


## Rounding a mean-centred vector can leave a small non-zero sum. Nudge the
## attributes with the largest rounding residual until the total is back inside
## the "approximately zero-sum" tolerance §7.1 allows.
static func _rebalance_to_zero_sum(
	modifiers: Array[int],
	raw: Array[float],
	profile: BuilderProfile,
) -> Array[int]:
	var result: Array[int] = modifiers.duplicate()
	var guard: int = AttributeKey.COUNT * 2
	while guard > 0:
		var total: int = 0
		for value in result:
			total += value
		if absi(total) <= ZERO_SUM_TOLERANCE:
			break
		guard -= 1

		var direction: int = -1 if total > 0 else 1
		var best_attribute: int = -1
		var best_residual: float = 0.0
		for attribute in AttributeKey.all():
			var adjusted: int = result[attribute] + direction
			if absi(adjusted) > profile.body_redistribution_single_maximum:
				continue
			# Prefer the attribute whose rounded value sits furthest from its
			# raw value in the direction we need, so the correction lands where
			# rounding did the most damage.
			var residual: float = (raw[attribute] - float(result[attribute])) * float(direction)
			if best_attribute == -1 or residual > best_residual:
				best_attribute = attribute
				best_residual = residual
		if best_attribute == -1:
			break
		result[best_attribute] += direction
	return result


## Enforce the §7.1 "at most 18 total rating points" bound after rounding.
##
## Scaling the raw vector before rounding gets close, but rounding twenty values
## can add up to a point in either direction, so the bound has to be enforced on
## the integers that are actually applied — not on the floats they came from.
##
## Trimming happens in pairs: one positive modifier and one negative modifier
## each move a step toward zero. That removes two points of absolute
## redistribution while leaving the sum untouched, so the zero-sum property
## established above survives the trim rather than having to be re-established.
static func _trim_to_absolute_budget(
	modifiers: Array[int],
	profile: BuilderProfile,
) -> Array[int]:
	var result: Array[int] = modifiers.duplicate()
	var guard: int = AttributeKey.COUNT * 2
	while guard > 0:
		var absolute: int = 0
		for value in result:
			absolute += absi(value)
		if absolute <= profile.body_redistribution_total:
			break
		guard -= 1

		# Trim the smallest non-zero magnitudes first: they carry the least of
		# the body's actual story, so the shape of the tradeoff is preserved.
		var positive: int = _smallest_nonzero(result, 1)
		var negative: int = _smallest_nonzero(result, -1)
		if positive == -1 or negative == -1:
			break
		result[positive] -= 1
		result[negative] += 1
	return result


static func _smallest_nonzero(modifiers: Array[int], sign: int) -> int:
	var best: int = -1
	for attribute in AttributeKey.all():
		var value: int = modifiers[attribute]
		if sign > 0 and value <= 0:
			continue
		if sign < 0 and value >= 0:
			continue
		if best == -1 or absi(value) < absi(modifiers[best]):
			best = attribute
	return best


## §7.1 says "approximately zero-sum", not exactly. One rating point of slack
## absorbs rounding without letting a body grant a systematic advantage.
const ZERO_SUM_TOLERANCE: int = 1
