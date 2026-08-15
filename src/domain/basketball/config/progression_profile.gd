class_name ProgressionProfile
extends RefCounted

## Versioned owner of the upgrade cost table, seasonal availability, aging and
## decline curves, cap distributions, and the projected-peak model
## (`GODOT_TDD.md` §5.6).
##
## Consumed by `DevelopmentService`, `AttributeAllocator`, and
## `AggregateDevelopmentExecutor` — the three executors of the one canonical
## development contract (`BALANCE_SPEC.md` §9.7). All three are bound by the
## values here identically; there is no private NPC cost table.
##
## Every value in this class is a **Baseline**. The seasonal availability bands
## in particular are explicitly marked in §9.5 as "calibration inputs, not
## proven values", and §32 keeps them provisional until the report 7
## million-career run. Stage 2 implements them behind the registry and does not
## claim them as evidence.


## ---------------------------------------------------------------------------
## §9.1 Universal upgrade costs, determined by destination rating.
## ---------------------------------------------------------------------------
## Identical for all twenty attributes and for every executor. The bands are
## upper-inclusive destination thresholds paired with their AP cost.
var cost_band_ceilings: Array[int]
var cost_band_costs: Array[int]

## §9.2 Direct progress converted to general AP when the attribute is at cap.
var at_cap_conversion_efficiency: float

## ---------------------------------------------------------------------------
## §8.1 Player ceiling distributions, indexed by `ProspectProfile.Value`.
## ---------------------------------------------------------------------------
var ceiling_center: Array[int]
var ceiling_deviation: Array[float]
var ceiling_minimum: Array[int]
var ceiling_maximum: Array[int]

## §8.1 offsets applied to the ceiling centre per attribute emphasis.
var primary_offset_minimum: int
var primary_offset_maximum: int
var secondary_offset_minimum: int
var secondary_offset_maximum: int
var neutral_offset_minimum: int
var neutral_offset_maximum: int
var incompatible_offset_minimum: int
var incompatible_offset_maximum: int

## §8.1 per-attribute noise.
var cap_noise_deviation: float
var cap_noise_clip: int

## §8 exact caps are bounded to 40..99 regardless of the draw above.
const CAP_MINIMUM: int = 40
const CAP_MAXIMUM: int = 99

## ---------------------------------------------------------------------------
## §7.2 Growth availability multipliers by prospect profile and career phase.
## ---------------------------------------------------------------------------
## Indexed [prospect][phase]. These change the number and quality of generated
## opportunities, never the AP cost of a rating (§7.2).
var growth_availability: Array[Array]

## ---------------------------------------------------------------------------
## §9.5 Seasonal AP-equivalent availability by career phase.
## ---------------------------------------------------------------------------
var seasonal_ap_minimum: Array[int]
var seasonal_ap_maximum: Array[int]
var seasonal_ap_guardrail: Array[int]

## ---------------------------------------------------------------------------
## §10.2 Aging curves. Indexed by `AttributeCategory.Value`.
## ---------------------------------------------------------------------------
var growth_end_age: Array[int]
var plateau_end_age: Array[int]
var decline_start_age: Array[int]

## ---------------------------------------------------------------------------
## §10.3 Annual natural decline, expected total rating points per category.
## ---------------------------------------------------------------------------
var decline_age_band_floor: Array[int]
var decline_physical_minimum: Array[float]
var decline_physical_maximum: Array[float]
var decline_technical_minimum: Array[float]
var decline_technical_maximum: Array[float]
var decline_iq_minimum: Array[float]
var decline_iq_maximum: Array[float]

## §10.3 hard bound: natural decline cannot remove more than this many whole
## points from one attribute in one offseason without a major injury.
var maximum_natural_decline_per_offseason: int

## ---------------------------------------------------------------------------
## Projected-peak model (`BALANCE_SPEC.md` §6.3). Provisional pending report 7.
## ---------------------------------------------------------------------------
## Ordinary — not best-case — opportunity. §6.3 rule 5 makes honesty an
## acceptance requirement, so the central estimate deliberately assumes an
## ordinary career rather than a well-managed one.
var ordinary_opportunity_share: float
## Share of granted AP an ordinary career converts into retained rating gain
## rather than losing to misallocation, capped attributes, and surplus.
var ordinary_allocation_efficiency_low: float
var ordinary_allocation_efficiency_high: float
## Age at which an ordinary career reaches peak Overall, by prospect profile.
var expected_peak_age: Array[int]
## Minimum width of the displayed Projected Peak range, in Overall points.
## §6.3 forbids displaying Projected Peak as a single value, so the range can
## never collapse to zero width.
var projected_peak_minimum_width: int
var projected_peak_maximum_width: int

var version: StringName


func _init(p_version: StringName = &"progression-v1") -> void:
	assert(not p_version.is_empty(), "a progression profile requires a version")
	version = p_version

	cost_band_ceilings = [59, 69, 79, 89, 94, 99]
	cost_band_costs = [1, 2, 3, 5, 8, 12]
	at_cap_conversion_efficiency = 0.50

	ceiling_center = [75, 79, 83]
	ceiling_deviation = [7.0, 8.0, 9.0]
	ceiling_minimum = [58, 58, 58]
	ceiling_maximum = [92, 96, 99]

	primary_offset_minimum = 4
	primary_offset_maximum = 10
	secondary_offset_minimum = 1
	secondary_offset_maximum = 5
	neutral_offset_minimum = -3
	neutral_offset_maximum = 3
	incompatible_offset_minimum = -16
	incompatible_offset_maximum = -6

	cap_noise_deviation = 2.5
	cap_noise_clip = 6

	var ready_now_growth: Array[float] = [1.15, 0.90, 0.80]
	var balanced_growth: Array[float] = [1.00, 1.00, 1.00]
	var high_upside_growth: Array[float] = [0.85, 1.15, 1.20]
	growth_availability = [ready_now_growth, balanced_growth, high_upside_growth]

	seasonal_ap_minimum = [45, 8, 35, 30, 25, 24, 16, 8]
	seasonal_ap_maximum = [65, 16, 55, 48, 45, 40, 30, 22]
	seasonal_ap_guardrail = [78, 20, 68, 60, 56, 50, 38, 30]

	growth_end_age = [23, 25, 26, 27, 27, 31]
	plateau_end_age = [27, 29, 31, 32, 32, 36]
	decline_start_age = [28, 30, 32, 33, 33, 37]

	decline_age_band_floor = [28, 31, 34, 37, 40]
	decline_physical_minimum = [0.5, 1.5, 3.0, 4.0, 6.0]
	decline_physical_maximum = [1.5, 3.0, 5.0, 7.0, 10.0]
	decline_technical_minimum = [0.0, 0.0, 0.5, 1.5, 2.5]
	decline_technical_maximum = [0.0, 0.5, 1.5, 3.0, 5.0]
	decline_iq_minimum = [0.0, 0.0, 0.0, 0.0, 0.5]
	decline_iq_maximum = [0.5, 0.5, 0.0, 0.5, 1.5]
	maximum_natural_decline_per_offseason = 5

	ordinary_opportunity_share = 0.62
	ordinary_allocation_efficiency_low = 0.55
	ordinary_allocation_efficiency_high = 0.86
	expected_peak_age = [25, 27, 28]
	projected_peak_minimum_width = 6
	projected_peak_maximum_width = 12

	_validate()


static func default_profile() -> ProgressionProfile:
	return ProgressionProfile.new()


func _validate() -> void:
	assert(cost_band_ceilings.size() == cost_band_costs.size(),
		"every cost band requires a ceiling and a cost")
	assert(cost_band_ceilings[cost_band_ceilings.size() - 1] == Rating.MAXIMUM,
		"the final cost band must reach the maximum rating so no destination is uncosted")
	var previous_ceiling: int = Rating.ACTIVE_MINIMUM - 1
	var previous_cost: int = 0
	for index in range(cost_band_ceilings.size()):
		assert(cost_band_ceilings[index] > previous_ceiling, "cost band ceilings must increase")
		assert(cost_band_costs[index] >= previous_cost,
			"cost must not fall as the destination rating rises; §9.1 costs are progressive")
		assert(cost_band_costs[index] > 0, "every rating increase must cost at least one AP")
		previous_ceiling = cost_band_ceilings[index]
		previous_cost = cost_band_costs[index]
	assert(at_cap_conversion_efficiency > 0.0 and at_cap_conversion_efficiency < 1.0,
		"at-cap conversion must be lossy but non-zero (§9.2)")
	assert(ceiling_center.size() == ProspectProfile.COUNT, "one ceiling centre per prospect profile")
	assert(growth_availability.size() == ProspectProfile.COUNT,
		"one growth-availability row per prospect profile")
	assert(growth_end_age.size() == AttributeCategory.COUNT, "one aging curve per category")
	assert(projected_peak_minimum_width <= projected_peak_maximum_width,
		"projected-peak width guardrail is inverted")
	assert(projected_peak_minimum_width > 0,
		"Projected Peak is always a range and never a single number (§6.3)")
	for category in range(AttributeCategory.COUNT):
		assert(growth_end_age[category] <= plateau_end_age[category],
			"an aging curve cannot plateau before growth ends")
		assert(plateau_end_age[category] < decline_start_age[category],
			"decline cannot begin before the plateau ends")


## §9.1 AP cost of raising an attribute to `destination_rating`. The cost is a
## function of the destination only, and is identical for all twenty attributes
## and for every executor.
func upgrade_cost_for_destination(destination_rating: int) -> int:
	assert(destination_rating > Rating.ACTIVE_MINIMUM and destination_rating <= Rating.MAXIMUM,
		"only a real rating increase has a cost")
	for index in range(cost_band_ceilings.size()):
		if destination_rating <= cost_band_ceilings[index]:
			return cost_band_costs[index]
	assert(false, "destination rating fell outside every cost band")
	return cost_band_costs[cost_band_costs.size() - 1]


func growth_availability_for(prospect: int, phase: int) -> float:
	assert(ProspectProfile.is_valid(prospect), "unknown prospect profile")
	var row: Array[float] = growth_availability[prospect]
	assert(phase >= 0 and phase < row.size(), "unknown career phase")
	return row[phase]


func decline_band_index_for_age(age: int) -> int:
	var index: int = -1
	for band in range(decline_age_band_floor.size()):
		if age >= decline_age_band_floor[band]:
			index = band
	return index


func describe_tunables() -> Array[BalanceTunable]:
	var tunables: Array[BalanceTunable] = []
	for index in range(cost_band_ceilings.size()):
		tunables.append(BalanceTunable.new(
			StringName("progression.upgrade_cost.to_%d" % cost_band_ceilings[index]),
			&"attribute_point",
			float(cost_band_costs[index]),
			1.0,
			20.0
		))
	tunables.append(BalanceTunable.new(
		&"progression.at_cap_conversion_efficiency", &"share",
		at_cap_conversion_efficiency, 0.0, 1.0))
	for prospect in ProspectProfile.all():
		var prospect_id: StringName = ProspectProfile.id_of(prospect)
		tunables.append(BalanceTunable.new(
			StringName("progression.ceiling_center.%s" % prospect_id),
			&"rating", float(ceiling_center[prospect]), 58.0, 99.0))
		tunables.append(BalanceTunable.new(
			StringName("progression.ceiling_deviation.%s" % prospect_id),
			&"rating", ceiling_deviation[prospect], 0.0, 20.0))
		tunables.append(BalanceTunable.new(
			StringName("progression.expected_peak_age.%s" % prospect_id),
			&"year", float(expected_peak_age[prospect]), 20.0, 34.0))
	tunables.append(BalanceTunable.new(
		&"progression.cap_noise_deviation", &"rating", cap_noise_deviation, 0.0, 8.0))
	tunables.append(BalanceTunable.new(
		&"progression.ordinary_opportunity_share", &"share",
		ordinary_opportunity_share, 0.0, 1.0))
	tunables.append(BalanceTunable.new(
		&"progression.ordinary_allocation_efficiency_low", &"share",
		ordinary_allocation_efficiency_low, 0.0, 1.0))
	tunables.append(BalanceTunable.new(
		&"progression.ordinary_allocation_efficiency_high", &"share",
		ordinary_allocation_efficiency_high, 0.0, 1.0))
	tunables.append(BalanceTunable.new(
		&"progression.projected_peak_minimum_width", &"overall_point",
		float(projected_peak_minimum_width), 1.0, 20.0))
	tunables.append(BalanceTunable.new(
		&"progression.projected_peak_maximum_width", &"overall_point",
		float(projected_peak_maximum_width), 1.0, 20.0))
	tunables.append(BalanceTunable.new(
		&"progression.maximum_natural_decline_per_offseason", &"rating_point",
		float(maximum_natural_decline_per_offseason), 1.0, 10.0))
	return tunables
