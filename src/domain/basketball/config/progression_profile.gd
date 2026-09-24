class_name ProgressionProfile
extends RefCounted

## Versioned owner of the upgrade cost table, seasonal availability, aging and
## decline curves, cap distributions, and the projected-peak model
## (`GODOT_TDD.md` Â§5.6).
##
## Consumed by `DevelopmentService`, `AttributeAllocator`, and
## `AggregateDevelopmentExecutor` â€” the three executors of the one canonical
## development contract (`BALANCE_SPEC.md` Â§9.7). All three are bound by the
## values here identically; there is no private NPC cost table.
##
## Every value in this class is a **Baseline**. The seasonal availability bands
## in particular are explicitly marked in Â§9.5 as "calibration inputs, not
## proven values", and Â§32 keeps them provisional until the report 7
## million-career run. Stage 2 implements them behind the registry and does not
## claim them as evidence.


## ---------------------------------------------------------------------------
## Â§9.1 Universal upgrade costs, determined by destination rating.
## ---------------------------------------------------------------------------
## Identical for all twenty attributes and for every executor. The bands are
## upper-inclusive destination thresholds paired with their AP cost.
var cost_band_ceilings: Array[int]
var cost_band_costs: Array[int]

## Â§9.2 Direct progress converted to general AP when the attribute is at cap.
var at_cap_conversion_efficiency: float

## ---------------------------------------------------------------------------
## Â§8.1 Player ceiling distributions, indexed by `ProspectProfile.Value`.
## ---------------------------------------------------------------------------
var ceiling_center: Array[int]
var ceiling_deviation: Array[float]
var ceiling_minimum: Array[int]
var ceiling_maximum: Array[int]

## Â§8.1 offsets applied to the ceiling centre per attribute emphasis.
var primary_offset_minimum: int
var primary_offset_maximum: int
var secondary_offset_minimum: int
var secondary_offset_maximum: int
var neutral_offset_minimum: int
var neutral_offset_maximum: int
var incompatible_offset_minimum: int
var incompatible_offset_maximum: int

## Â§8.1 per-attribute noise.
var cap_noise_deviation: float
var cap_noise_clip: int

## Â§8 exact caps are bounded to 40..99 regardless of the draw above.
const CAP_MINIMUM: int = 40
const CAP_MAXIMUM: int = 99

## The earliest age a projected-peak forecast horizon may end. A horizon at or
## before the freshman year would credit a career no remaining opportunity at
## all, which is not a forecast.
const MINIMUM_FORECAST_HORIZON_AGE: int = 15

## ---------------------------------------------------------------------------
## Â§7.2 Growth availability multipliers by prospect profile and career phase.
## ---------------------------------------------------------------------------
## Indexed [prospect][phase]. These change the number and quality of generated
## opportunities, never the AP cost of a rating (Â§7.2).
var growth_availability: Array[Array]

## ---------------------------------------------------------------------------
## Â§9.5 Seasonal AP-equivalent availability by career phase.
## ---------------------------------------------------------------------------
var seasonal_ap_minimum: Array[int]
var seasonal_ap_maximum: Array[int]
var seasonal_ap_guardrail: Array[int]

## ---------------------------------------------------------------------------
## Â§9.6 Seasonal game-development caps by career phase.
## ---------------------------------------------------------------------------
## "Seasonal game-development caps are 12 AP-equivalent in HS, 16 in
## college/alternatives, and 20 in top domestic professional basketball."
##
## This bounds a **source**, not a season. Â§9.5's band is the total the season
## may deliver and it explicitly includes game participation, so the two bound
## different things: the Â§9.5 guardrail bounds everything a season grants, and
## this bounds how much of that total may be credited to games. A model that
## books a whole high-engagement season to game participation has not granted
## too much opportunity â€” it has attributed it to a source whose own cap forbids
## it, which is the kind of unfalsifiable provenance Â§9.7.2 exists to prevent.
var game_development_cap: Array[int]

## ---------------------------------------------------------------------------
## Â§9.5 owner ruling (2026-08): the bounded elite-opportunity exception.
## ---------------------------------------------------------------------------
## "Rare-generational careers may exceed the Â§9.5 high-engagement upper
## guardrail by up to 20% when caused by ledgered elite opportunity, while
## emitting the required balance warning."
##
## The share is stated against the quantity the ruling was made on. Stage 4
## measured the rare-generational cohort receiving 16.5% more lifetime
## opportunity than the sum of its own seasonal guardrails, and the owner set
## the ceiling at 20% of that same sum. So this bounds the **career against its
## summed seasonal guardrails**, not any single season: a career may be shaped
## so that some seasons sit further above their guardrail than others, and what
## it may not do is receive more across the whole career than the ruling allows.
##
## Per-season overage is still reported, and at the current settings runs higher
## than this share in the college and early professional phases. That is
## recorded in `PROJECT_STATUS.md` Â§5.8 rather than smoothed away, because a
## stricter per-season reading of the ruling is available to the owner and this
## implementation does not pre-empt it.
##
## The exception is a permission and never a grant. It changes no Â§9.1 cost, no
## Â§9.6 cap, no population share, and no seasonal draw.
var elite_opportunity_guardrail_allowance: float

## ---------------------------------------------------------------------------
## Â§10.2 Aging curves. Indexed by `AttributeCategory.Value`.
## ---------------------------------------------------------------------------
var growth_end_age: Array[int]
var plateau_end_age: Array[int]
var decline_start_age: Array[int]

## ---------------------------------------------------------------------------
## Â§10.3 Annual natural decline, expected total rating points per category.
## ---------------------------------------------------------------------------
var decline_age_band_floor: Array[int]
var decline_physical_minimum: Array[float]
var decline_physical_maximum: Array[float]
var decline_technical_minimum: Array[float]
var decline_technical_maximum: Array[float]
var decline_iq_minimum: Array[float]
var decline_iq_maximum: Array[float]

## Â§10.3 hard bound: natural decline cannot remove more than this many whole
## points from one attribute in one offseason without a major injury.
var maximum_natural_decline_per_offseason: int

## ---------------------------------------------------------------------------
## Projected-peak model (`BALANCE_SPEC.md` Â§6.3). Provisional pending report 7.
## ---------------------------------------------------------------------------
## The model forecasts the *opportunity* a career will receive and converts it
## through the exact §9.1 cost table against the player's own caps. Stage 4
## measured that split directly: given the true lifetime opportunity the
## conversion predicts the realized peak with a median error of zero and a
## standard deviation near half an Overall point, and the entire projected-peak
## bias came from the opportunity estimate. The opportunity model is therefore
## where the uncertainty lives, and it is the only part parameterised here.
##
## Opportunity is expressed as a share of the *expected* seasonal grant — the
## midpoint of each §9.5 band over the forecast horizon, scaled by the §7.2
## growth-availability multiplier. A share of 1.0 means "this career realizes
## exactly the expected grant every season through its horizon".
##
## ### Why these are per prospect profile
##
## §7.2 makes the prospect profile the thing that "change[s] the number and
## quality of opportunities generated", and §8.4 expects Ready Now and High
## Upside peaks to sit differently inside the outcome bands. The *dispersion* of
## career opportunity therefore differs by profile and not only its centre: a
## High Upside prospect has genuine access to the exceptional and generational
## outcomes a Ready Now prospect does not, so its honest forecast interval is
## wider. A single global interval cannot express that, and Stage 4 measured
## that no global setting reaches the §6.3 bands.
##
## The interval also narrows on its own wherever the caps bind, because the
## conversion saturates at Maximum Potential. That is the second half of the
## conditioning and it needs no parameter: a career with little headroom gets a
## narrow range because more opportunity could not have helped it.
var projected_peak_opportunity_low: Array[float]
var projected_peak_opportunity_high: Array[float]
## Age through which the forecast accrues opportunity, by prospect profile.
var projected_peak_horizon_age: Array[int]
## Age at which an ordinary career reaches peak Overall, by prospect profile.
## Used by the §6.3 rule 4 decline branch for a player already past his peak.
var expected_peak_age: Array[int]
## Minimum width of the displayed Projected Peak range, in Overall points.
## §6.3 forbids displaying Projected Peak as a single value, so the range can
## never collapse to zero width.
var projected_peak_minimum_width: int
## Per-career upper bound on the displayed width.
##
## §6.3's 6–12 guardrail is stated on the **median displayed range width**, not
## on every range. Clamping every career to 12 over-constrained the model: it
## forced one width onto careers whose genuine uncertainty differs by more than
## a factor of two, and Stage 4 measured the irreducible width varying from
## about 6 to about 16 across creation-time groups. This bound exists only to
## stop a range becoming uninformative; the median is what the report judges.
var projected_peak_maximum_width: int

var version: StringName


func _init(p_version: StringName = &"progression-v1") -> void:
	assert(not p_version.is_empty(), "a progression profile requires a version")
	version = p_version

	cost_band_ceilings = [59, 69, 79, 89, 94, 99]
	cost_band_costs = [1, 2, 3, 5, 8, 12]
	at_cap_conversion_efficiency = 0.50

	# Raised with the seasonal bands: §8.2 wants a top-domestic rostered current
	# OVR median of 77-81, and a ceiling centre that produced a Maximum Potential
	# near 72 made that unreachable however much AP a career received.
	ceiling_center = [81, 85, 88]
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

	# Stage 4 report 7 raised these from [45, 8, 35, 30, 25, 24, 16, 8] /
	# [65, 16, 55, 48, 45, 40, 30, 22]. BALANCE_SPEC §9.5 recorded the lifetime
	# conversion from seasonal availability to peak Overall as unmeasured and
	# named these bands the primary tunable for the §8.4 locked curve. The
	# measurement: a completed freshman near 48 OVR needs roughly 1,150 lifetime
	# AP-equivalent to reach a strong peak of 80-85 against the §9.1 escalating
	# cost bands, and the previous bands delivered about 470. §8.4 is the
	# acceptance target and these are the tunable, so the bands moved.
	seasonal_ap_minimum = [108, 18, 84, 72, 60, 58, 38, 19]
	seasonal_ap_maximum = [156, 38, 132, 115, 108, 96, 72, 53]
	seasonal_ap_guardrail = [187, 48, 163, 144, 134, 120, 91, 72]

	# Â§9.6, indexed by CareerPhase.Value: high school and summer circuit are
	# high-school basketball, college and the two alternative professional routes
	# are "college/alternatives", and the three top-domestic bands are top
	# domestic professional basketball.
	game_development_cap = [12, 12, 16, 16, 16, 20, 20, 20]

	# Â§9.5 owner ruling 2026-08. Measured overage at the ruling was 16.5%.
	elite_opportunity_guardrail_allowance = 0.20

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

	# Indexed by ProspectProfile.Value: ready_now, balanced, high_upside.
	# Fitted on seeds 1..600, tuned on seeds 200001..202000, and validated on two
	# untouched ranges. See PROJECT_STATUS.md §5.7 for the measurements.
	#
	# High Upside carries a materially wider interval than the other two because
	# it is the only profile with genuine access to the §8.4 exceptional and
	# generational outcomes; its honest forecast is less certain, and §6.3 makes
	# understating that a defect rather than a presentational nicety.
	projected_peak_opportunity_low = [0.585, 0.565, 0.625]
	projected_peak_opportunity_high = [1.140, 1.160, 1.540]
	projected_peak_horizon_age = [29, 29, 30]
	expected_peak_age = [29, 29, 30]
	projected_peak_minimum_width = 6
	projected_peak_maximum_width = 20

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
			"cost must not fall as the destination rating rises; Â§9.1 costs are progressive")
		assert(cost_band_costs[index] > 0, "every rating increase must cost at least one AP")
		previous_ceiling = cost_band_ceilings[index]
		previous_cost = cost_band_costs[index]
	assert(at_cap_conversion_efficiency > 0.0 and at_cap_conversion_efficiency < 1.0,
		"at-cap conversion must be lossy but non-zero (Â§9.2)")
	assert(ceiling_center.size() == ProspectProfile.COUNT, "one ceiling centre per prospect profile")
	assert(growth_availability.size() == ProspectProfile.COUNT,
		"one growth-availability row per prospect profile")
	assert(seasonal_ap_minimum.size() == CareerPhase.COUNT
		and seasonal_ap_maximum.size() == CareerPhase.COUNT
		and seasonal_ap_guardrail.size() == CareerPhase.COUNT,
		"one Â§9.5 seasonal band and guardrail per career phase")
	assert(elite_opportunity_guardrail_allowance >= 0.0,
		"the Â§9.5 elite-opportunity exception cannot be negative")
	assert(elite_opportunity_guardrail_allowance <= 0.5,
		"an exception larger than half the guardrail is not an exception")
	assert(game_development_cap.size() == CareerPhase.COUNT,
		"one Â§9.6 game-development cap per career phase")
	for phase in range(CareerPhase.COUNT):
		assert(seasonal_ap_minimum[phase] <= seasonal_ap_maximum[phase],
			"a Â§9.5 seasonal band is inverted")
		assert(seasonal_ap_guardrail[phase] >= seasonal_ap_maximum[phase],
			"the Â§9.5 high-engagement guardrail sits at or above the band maximum")
		assert(game_development_cap[phase] > 0,
			"game participation always develops something (Â§9.6)")
		assert(float(game_development_cap[phase]) <= float(seasonal_ap_guardrail[phase]),
			"the Â§9.6 game cap cannot exceed the whole season's Â§9.5 guardrail")
	assert(growth_end_age.size() == AttributeCategory.COUNT, "one aging curve per category")
	assert(projected_peak_minimum_width <= projected_peak_maximum_width,
		"projected-peak width guardrail is inverted")
	assert(projected_peak_minimum_width > 0,
		"Projected Peak is always a range and never a single number (Â§6.3)")
	assert(projected_peak_opportunity_low.size() == ProspectProfile.COUNT
		and projected_peak_opportunity_high.size() == ProspectProfile.COUNT
		and projected_peak_horizon_age.size() == ProspectProfile.COUNT,
		"the projected-peak opportunity model carries one row per prospect profile")
	for prospect in range(ProspectProfile.COUNT):
		assert(projected_peak_opportunity_low[prospect] > 0.0,
			"a forecast cannot assume a career receives no opportunity at all")
		assert(projected_peak_opportunity_low[prospect]
			<= projected_peak_opportunity_high[prospect],
			"the projected-peak opportunity interval is inverted")
		assert(projected_peak_horizon_age[prospect] >= MINIMUM_FORECAST_HORIZON_AGE,
			"the forecast horizon must lie beyond the freshman year")
	for category in range(AttributeCategory.COUNT):
		assert(growth_end_age[category] <= plateau_end_age[category],
			"an aging curve cannot plateau before growth ends")
		assert(plateau_end_age[category] < decline_start_age[category],
			"decline cannot begin before the plateau ends")


## Â§9.1 AP cost of raising an attribute to `destination_rating`. The cost is a
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
	tunables.append(BalanceTunable.new(
		&"progression.elite_opportunity_guardrail_allowance", &"share",
		elite_opportunity_guardrail_allowance, 0.0, 0.5))
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
	for prospect in ProspectProfile.all():
		var opportunity_id: StringName = ProspectProfile.id_of(prospect)
		tunables.append(BalanceTunable.new(
			StringName("progression.projected_peak_opportunity_low.%s" % opportunity_id),
			&"share", projected_peak_opportunity_low[prospect], 0.05, 3.0))
		tunables.append(BalanceTunable.new(
			StringName("progression.projected_peak_opportunity_high.%s" % opportunity_id),
			&"share", projected_peak_opportunity_high[prospect], 0.05, 3.0))
		tunables.append(BalanceTunable.new(
			StringName("progression.projected_peak_horizon_age.%s" % opportunity_id),
			&"year", float(projected_peak_horizon_age[prospect]), 15.0, 40.0))
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
