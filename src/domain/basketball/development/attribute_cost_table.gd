class_name AttributeCostTable
extends RefCounted

## The universal destination-rating cost table (`BALANCE_SPEC.md` §9.1).
##
## "The cost is determined by the destination rating and is identical for all 20
## attributes." §9.7.2 binds every executor to this one table: the full-detail
## NPC allocator "is not permitted to write a rating directly, to exceed a cap,
## to spend currency it was not granted, or to use a private cost table."
##
## This class is that shared table. The user path, `AttributeAllocator`, and
## `AggregateDevelopmentExecutor` all route through it, which is what makes the
## §9.7 cost-parity requirement a structural property rather than a convention
## two code paths might drift away from.
##
## Worked examples from §9.1, all covered by tests:
##   58 -> 60 costs 3 AP (one point into 59, two into 60)
##   69 -> 70 costs 3 AP
##   79 -> 80 costs 5 AP
##   94 -> 95 costs 12 AP
##   90 -> 99 costs 92 AP


## AP cost of raising `from_rating` to `to_rating`, summing the per-point cost
## of every intervening destination.
static func cost_to_raise(from_rating: int, to_rating: int, profile: ProgressionProfile) -> int:
	assert(to_rating >= from_rating, "the cost table prices increases, not reductions")
	var total: int = 0
	for destination in range(from_rating + 1, to_rating + 1):
		total += profile.upgrade_cost_for_destination(destination)
	return total


## AP cost of the single next whole point above `current_rating`.
static func cost_of_next_point(current_rating: int, profile: ProgressionProfile) -> int:
	assert(current_rating < Rating.MAXIMUM, "an attribute at the maximum has no next point")
	return profile.upgrade_cost_for_destination(current_rating + 1)


## The highest rating reachable from `current_rating` with `available_ap`,
## respecting `cap`. Returns `[reached_rating, ap_spent]`.
##
## Caps are checked before currency is consumed (§9.1), so a spend that would
## breach a cap is never charged.
static func maximum_reachable(
	current_rating: int,
	cap: int,
	available_ap: int,
	profile: ProgressionProfile,
) -> Array[int]:
	var rating: int = current_rating
	var spent: int = 0
	var remaining: int = available_ap
	while rating < cap and rating < Rating.MAXIMUM:
		var next_cost: int = cost_of_next_point(rating, profile)
		if next_cost > remaining:
			break
		remaining -= next_cost
		spent += next_cost
		rating += 1
	return [rating, spent]


## Spend a budget across attributes cheapest-point-first, respecting caps.
##
## This models the *ordinary* development pattern used by the projected-peak
## model and by aggregate resolution: a career that takes the cheapest available
## improvement rather than concentrating into an expensive specialism. It is
## deliberately not the Overall-maximising allocation — §6.3 rule 5 requires the
## projection to assume ordinary, not best-case, opportunity.
##
## Returns the resulting rating values; `spent_out` receives the AP consumed.
static func spend_cheapest_first(
	values: Array[int],
	caps: AttributeCaps,
	available_ap: int,
	profile: ProgressionProfile,
	spent_out: Array[int] = [],
) -> Array[int]:
	assert(values.size() == AttributeKey.COUNT, "expected the twenty canonical attributes")
	var result: Array[int] = values.duplicate()
	var remaining: int = available_ap
	var spent: int = 0

	while remaining > 0:
		# Canonical iteration order before any tie-break, so the choice is
		# reproducible rather than dependent on incidental ordering
		# (`GODOT_TDD.md` §5.2).
		var best_attribute: int = -1
		var best_cost: int = 0
		for attribute in AttributeKey.all():
			var current: int = result[attribute]
			if not caps.has_room(attribute, current) or current >= Rating.MAXIMUM:
				continue
			var cost: int = cost_of_next_point(current, profile)
			if cost > remaining:
				continue
			# Cheapest first; ties break toward the lower current rating, then
			# toward the lower canonical attribute index.
			if best_attribute == -1 or cost < best_cost \
					or (cost == best_cost and current < result[best_attribute]):
				best_attribute = attribute
				best_cost = cost
		if best_attribute == -1:
			break
		result[best_attribute] += 1
		remaining -= best_cost
		spent += best_cost

	spent_out.clear()
	spent_out.append(spent)
	return result


## Total AP required to fill every attribute to its cap. Used to recognise the
## careers for which additional opportunity buys nothing.
static func cost_to_fill_caps(
	values: Array[int],
	caps: AttributeCaps,
	profile: ProgressionProfile,
) -> int:
	var total: int = 0
	for attribute in AttributeKey.all():
		var current: int = values[attribute]
		var cap: int = caps.cap_for(attribute)
		if cap > current:
			total += cost_to_raise(current, cap, profile)
	return total
