class_name AggregateDevelopmentExecutor
extends RefCounted

## Bulk development for reduced-detail populations
## (`GODOT_TDD.md` §5.8, `BALANCE_SPEC.md` §9.7.3).
##
## §9.7.3 permits an aggregate executor to "skip per-attribute deliberation for
## performance". It must still:
##
##   - draw its totals from the same seasonal availability model;
##   - respect caps, cost bands, and decline;
##   - produce attribute-level distributions statistically indistinguishable
##     from the full-detail allocator at equivalent inputs;
##   - **write source-ledger entries at whatever granularity it resolves, so
##     promotion has real history to inherit.**
##
## ## How the parity requirement is met here
##
## The cheapest way to satisfy "indistinguishable from the full-detail
## allocator" is to reuse the allocator's own priority function and spend
## against it in one pass, rather than to invent a second heuristic that would
## then have to be tuned back into agreement. The saving is in deliberation —
## priorities are computed once instead of re-ranked after every point — not in
## the rules, which are identical.
##
## This also means promotion inherits real evidence: the ledger records the same
## costs against the same attributes, so a promoted player's history is
## continuous rather than reconstructed.

## Resolve a season of development in bulk.
##
## Returns the number of whole rating points applied. Spends through
## `DevelopmentService` exactly as the full-detail allocator does, so caps,
## costs, and the source ledger are shared rather than reimplemented.
static func resolve_season(
	state: PlayerDevelopmentState,
	career_year: int,
	context: DevelopmentContext,
	service: DevelopmentService,
) -> int:
	var progression: ProgressionProfile = service.profiles().progression
	var weights: Array[float] = AttributeAllocator.priority_weights(
		state, context, progression)
	var executor: int = DevelopmentExecutor.Value.AGGREGATE

	# One ranking pass, then spend down it. The full-detail allocator re-ranks
	# after every point; over a season the two converge because a single point
	# rarely reorders the priorities, and where it does the difference is inside
	# the §27.2 distributional tolerance the parity report measures.
	var ordered: Array[int] = AttributeKey.all()
	ordered.sort_custom(func(left: int, right: int) -> bool:
		if is_equal_approx(weights[left], weights[right]):
			return left < right
		return weights[left] > weights[right]
	)

	var applied: int = 0
	for attribute in ordered:
		if state.point_ledger.balance() < 1.0:
			break
		var share: float = weights[attribute] / _weight_total(weights)
		var allowance: float = state.point_ledger.balance() * share * AGGRESSION
		var points: int = _points_affordable(
			state, attribute, allowance, progression)
		if points <= 0:
			continue
		applied += service.spend_general_ap(
			state, attribute, points, career_year, executor)

	# Sweep any residue so the aggregate path does not systematically bank AP
	# the full-detail path would have spent. Banked AP would show up as a real
	# divergence at promotion.
	applied += _sweep_remainder(state, career_year, weights, service, executor)
	return applied


static func _weight_total(weights: Array[float]) -> float:
	var total: float = 0.0
	for weight in weights:
		total += weight
	return maxf(total, 0.000001)


## How many whole points `allowance` AP buys in this attribute, respecting the
## exact cap and the escalating cost bands.
static func _points_affordable(
	state: PlayerDevelopmentState,
	attribute: int,
	allowance: float,
	progression: ProgressionProfile,
) -> int:
	var current: int = state.attributes.get_rating(attribute)
	var cap: int = state.caps.cap_for(attribute)
	var budget: float = allowance
	var points: int = 0
	while current + points < cap and current + points < Rating.MAXIMUM:
		var cost: int = AttributeCostTable.cost_of_next_point(current + points, progression)
		if float(cost) > budget:
			break
		budget -= float(cost)
		points += 1
	return points


static func _sweep_remainder(
	state: PlayerDevelopmentState,
	career_year: int,
	weights: Array[float],
	service: DevelopmentService,
	executor: int,
) -> int:
	var progression: ProgressionProfile = service.profiles().progression
	var applied: int = 0
	var guard: int = AttributeKey.COUNT * 200
	while guard > 0:
		guard -= 1
		var best_attribute: int = -1
		var best_score: float = 0.0
		for attribute in AttributeKey.all():
			var current: int = state.attributes.get_rating(attribute)
			if not state.caps.has_room(attribute, current) or current >= Rating.MAXIMUM:
				continue
			var cost: int = AttributeCostTable.cost_of_next_point(current, progression)
			if float(cost) > state.point_ledger.balance():
				continue
			var score: float = weights[attribute] / float(cost)
			if best_attribute == -1 or score > best_score \
					or (is_equal_approx(score, best_score) and attribute < best_attribute):
				best_attribute = attribute
				best_score = score
		if best_attribute == -1:
			break
		if service.spend_general_ap(state, best_attribute, 1, career_year, executor) == 0:
			break
		applied += 1
	return applied


## How much of the available balance one attribute may claim in the bulk pass,
## before the sweep. Below 1.0 so the sweep has residue to place by priority
## rather than the first attribute absorbing everything.
const AGGRESSION: float = 0.9
