class_name ProjectedPeakCalculator
extends RefCounted

## The one canonical Projected Peak model (`BALANCE_SPEC.md` §6.3).
##
## Projected Peak is the realistic best Overall this career is likely to reach.
## §6.3 rule 2 fixes its inputs exactly:
##
##   - available development opportunity for the remaining career;
##   - the prospect timing profile (§7.2);
##   - current age and the aging curves (§10.2);
##   - **ordinary — not best-case — opportunity**;
##   - exact per-attribute caps;
##   - expected decline.
##
## It is deterministic: no `RandomSource` is consulted. A projection that moved
## when reopened would be a defect, and §6.3 rule 3 requires it to be recomputed
## from current inputs rather than stored as a promise made at creation.
##
## ## Ordering rules (§6.3 rule 4)
##
## `CurrentOverall <= MaximumPotentialOverall` always holds, and the Projected
## Peak range lies at or below Maximum Potential and at or above Current
## Overall. The one documented exception is a player already in decline, whose
## range upper bound may equal his historical peak; callers pass that peak in.
##
## ## Honesty
##
## §6.3 rule 5: "Projected Peak must never be more optimistic than the evidence
## supports. Its honesty is an acceptance requirement, not a presentation
## preference." The model therefore scales granted opportunity by
## `ordinary_opportunity_share` and by an allocation efficiency below 1.0, so
## the central estimate describes an ordinary career rather than a well-managed
## one. The coverage rate, width guardrail, and signed-bias tolerance are all
## **provisional pending report 7** (§32); Stage 2 implements the model and does
## not claim it calibrated.


## Compute the Projected Peak range.
##
## `historical_peak_overall` supports the §6.3 rule 4 decline exception; pass -1
## when the career has no recorded peak yet.
static func project(
	attributes: PlayerAttributes,
	caps: AttributeCaps,
	prospect: int,
	age: int,
	ratings: RatingsProfile,
	progression: ProgressionProfile,
	opportunity_scale: float = 1.0,
	historical_peak_overall: int = -1,
) -> OverallRange:
	assert(ProspectProfile.is_valid(prospect), "unknown prospect profile")
	assert(opportunity_scale >= 0.0, "opportunity scale cannot be negative")

	var current_overall: int = OverallCalculator.current_overall(attributes, ratings)
	var maximum_potential: int = OverallCalculator.maximum_potential_overall(caps, ratings)
	assert(current_overall <= maximum_potential,
		"Current Overall exceeded Maximum Potential; caps and ratings have diverged")

	var current_values: Array[int] = attributes.canonical_values()
	var peak_age: int = progression.expected_peak_age[prospect]

	var low_ap: float = 0.0
	var high_ap: float = 0.0
	for season_age in range(age, peak_age):
		var phase: int = CareerPhase.default_phase_for_age(season_age)
		var growth_phase: int = CareerPhase.growth_phase_of(phase)
		var availability: float = progression.growth_availability_for(prospect, growth_phase)
		low_ap += float(progression.seasonal_ap_minimum[phase]) * availability
		high_ap += float(progression.seasonal_ap_maximum[phase]) * availability

	# Ordinary, not best-case (§6.3 rule 2), and scaled by the caller's context.
	low_ap *= progression.ordinary_opportunity_share \
		* progression.ordinary_allocation_efficiency_low * opportunity_scale
	high_ap *= progression.ordinary_opportunity_share \
		* progression.ordinary_allocation_efficiency_high * opportunity_scale

	var low_peak: int = _overall_after_spending(
		current_values, caps, int(floorf(low_ap)), ratings, progression)
	var high_peak: int = _overall_after_spending(
		current_values, caps, int(floorf(high_ap)), ratings, progression)

	# Expected decline for a player already past his peak age. §10.3 decline is
	# expressed in rating points per category; applied to Overall it lowers the
	# realistic ceiling without touching the stored ratings.
	if age >= peak_age:
		var decline: int = _expected_decline_overall(age, peak_age, progression)
		low_peak -= decline
		high_peak -= decline

	var low_bound: int = current_overall
	var high_bound: int = maximum_potential
	# §6.3 rule 4 exception: a declining player's upper bound may reach his
	# recorded historical peak even though his current Overall has fallen below.
	if historical_peak_overall >= 0:
		high_bound = mini(maximum_potential, maxi(high_bound, historical_peak_overall))
		low_bound = mini(low_bound, historical_peak_overall)

	var low_result: int = clampi(low_peak, low_bound, high_bound)
	var high_result: int = clampi(maxi(high_peak, low_result), low_bound, high_bound)

	return _apply_width_guardrail(low_result, high_result, low_bound, high_bound, progression)


static func _overall_after_spending(
	current_values: Array[int],
	caps: AttributeCaps,
	available_ap: int,
	ratings: RatingsProfile,
	progression: ProgressionProfile,
) -> int:
	if available_ap <= 0:
		return OverallCalculator.overall_from_values(current_values, ratings)
	var projected: Array[int] = AttributeCostTable.spend_cheapest_first(
		current_values, caps, available_ap, progression)
	return OverallCalculator.overall_from_values(projected, ratings)


## Expected Overall lost to natural decline between the peak age and now, using
## the §10.3 annual bands. Categories decline at different rates, so the Overall
## effect is the mean per-attribute loss across the twenty.
static func _expected_decline_overall(
	age: int,
	peak_age: int,
	progression: ProgressionProfile,
) -> int:
	var total_points: float = 0.0
	for season_age in range(peak_age, age + 1):
		var band: int = progression.decline_band_index_for_age(season_age)
		if band < 0:
			continue
		var physical: float = (
			progression.decline_physical_minimum[band]
			+ progression.decline_physical_maximum[band]
		) / 2.0
		var technical: float = (
			progression.decline_technical_minimum[band]
			+ progression.decline_technical_maximum[band]
		) / 2.0
		var iq: float = (
			progression.decline_iq_minimum[band] + progression.decline_iq_maximum[band]
		) / 2.0
		# The §10.3 columns are category totals, so the season's whole-roster
		# effect is their sum spread across the twenty attributes.
		total_points += (physical + technical + iq) / float(AttributeKey.COUNT)
	return int(roundf(total_points))


## Keep the displayed width inside the §6.3 guardrail without ever leaving the
## legal `[low_bound, high_bound]` interval.
##
## When the legal interval is itself narrower than the minimum width — a player
## whose caps are nearly filled — the honest answer is the whole interval, so
## the guardrail yields rather than inventing room that does not exist.
static func _apply_width_guardrail(
	low: int,
	high: int,
	low_bound: int,
	high_bound: int,
	progression: ProgressionProfile,
) -> OverallRange:
	var result_low: int = low
	var result_high: int = high
	var available: int = high_bound - low_bound

	if available <= progression.projected_peak_minimum_width:
		return OverallRange.new(low_bound, high_bound)

	var width: int = result_high - result_low
	if width < progression.projected_peak_minimum_width:
		var deficit: int = progression.projected_peak_minimum_width - width
		var raise_by: int = mini(deficit, high_bound - result_high)
		result_high += raise_by
		deficit -= raise_by
		if deficit > 0:
			result_low = maxi(low_bound, result_low - deficit)
	elif width > progression.projected_peak_maximum_width:
		var excess: int = width - progression.projected_peak_maximum_width
		var trim_low: int = excess / 2
		result_low += trim_low
		result_high -= (excess - trim_low)

	return OverallRange.new(result_low, maxi(result_low, result_high))
