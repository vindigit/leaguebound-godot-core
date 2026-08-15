class_name BuilderProfile
extends RefCounted

## Versioned owner of every Builder tunable (`GODOT_TDD.md` §5.6):
## starting bases, the creation AP budget, prospect-profile modifiers,
## per-attribute starting maxima, body redistribution bounds, and projected
## adult range widths.
##
## ## Calibration status
##
## `BALANCE_SPEC.md` §7.3.3 records a derived shortfall: at the documented
## 150 AP baseline the reachable completed Overall is 44-48 across all three
## profiles, which leaves the upper half of every locked §7.3.2 band
## unreachable. §7.3.3 names the resolution explicitly — "The locked bands are
## the acceptance target; the creation AP budget and the body-adjusted starting
## bases are the tunables."
##
## Stage 2 moved the creation budget and the prospect modifiers and left the
## 35/38/45 bases alone. Leaving the bases fixed keeps the §7.3.1 empty-preview
## derivation intact at 38, so the preview value stays a derived consequence of
## the documented bases rather than a second number needing its own evidence.
##
## The three §7.3.3 constraints hold simultaneously under these values, as the
## `tools/builder_calibration_harness.gd` report demonstrates:
##
##   1. completed builds reach the locked bands;
##   2. no ordinary completed build exceeds approximately 54 OVR;
##   3. the 70 soft and 75 absolute starting maxima remain in force.
##
## These remain **provisional** (§32) until the report 3 build-diversity run at
## the §27.1 sample size. Stage 2 demonstrates reachability; it does not close
## the calibration.


const BASE_TECHNICAL_NAME: StringName = &"builder.base_technical"
const BASE_IQ_NAME: StringName = &"builder.base_iq"
const BASE_PHYSICAL_NAME: StringName = &"builder.base_physical"
const CREATION_BUDGET_NAME: StringName = &"builder.creation_ap_budget"
const SOFT_MAXIMUM_NAME: StringName = &"builder.starting_soft_maximum"
const ABSOLUTE_MAXIMUM_NAME: StringName = &"builder.starting_absolute_maximum"
const REDISTRIBUTION_TOTAL_NAME: StringName = &"builder.body_redistribution_total"
const REDISTRIBUTION_SINGLE_NAME: StringName = &"builder.body_redistribution_single_maximum"

var version: StringName

## Starting bases before body adjustment (`BALANCE_SPEC.md` §7.1).
var base_technical: int
var base_iq: int
var base_physical: int

## Creation AP for the Balanced profile, plus the per-profile modifiers.
## Tuned in Stage 2 from the 150 / +25 / -20 baseline; see the class comment.
var creation_ap_budget: int
var prospect_ap_modifiers: Array[int]

## Per-attribute starting maxima (`BALANCE_SPEC.md` §7.1). Structural for the
## purpose of §7.3.3 constraint 3: calibration may not relax them.
var starting_soft_maximum: int
var starting_absolute_maximum: int

## Body redistribution bounds (`BALANCE_SPEC.md` §7.1, §7.4.3 rule 5).
## Applies once, at creation, and is approximately zero-sum.
var body_redistribution_total: int
var body_redistribution_single_maximum: int

## Credible freshman measurement ranges per position family, indexed by
## `PositionFamily.Value`. Freshman here means the first year of high school.
var family_height_minimum: Array[int]
var family_height_maximum: Array[int]

## Weight is modelled from height rather than selected independently, so that a
## credible body is the default and an extreme body is a deliberate choice.
var weight_pounds_per_inch: float
var weight_reference_height: int
var weight_reference_pounds: int
var weight_selectable_margin: int

## Wingspan is selected as a delta from height; standing reach follows from
## height and wingspan.
var wingspan_delta_minimum: int
var wingspan_delta_maximum: int
var standing_reach_height_share: float
var standing_reach_wingspan_share: float

## Projected adult growth ranges (`BALANCE_SPEC.md` §7.4.2). Range width is a
## genuine tuning tension and is deliberately Baseline pending report 15: too
## narrow makes the maturity choice meaningless, too wide makes the projection
## uninformative.
var growth_height_minimum: int
var growth_height_maximum: int
var growth_weight_minimum: int
var growth_weight_maximum: int
var growth_wingspan_minimum: int
var growth_wingspan_maximum: int

## Share of total projected growth delivered during the high-school milestones,
## indexed by `MaturityProfile.Value`.
##
## Total growth is identical across timing profiles; only the schedule differs.
## `GDD.md` §6.5 states that neither timing is strictly better, so giving Late
## maturity a larger total would be a design violation, not a tuning choice.
var high_school_growth_share: Array[float]

## Growth milestones, as career years measured from the confirmed freshman
## year. The first three are the high-school transitions; the remainder are the
## post-high-school maturation years.
const HIGH_SCHOOL_GROWTH_MILESTONES: int = 3
const TOTAL_GROWTH_MILESTONES: int = 6

## Per-attribute influence of body size (height and length) and body mass on the
## §7.1 starting redistribution, indexed by `AttributeKey.Key`.
##
## These express the same causal story `SIMULATION_SPEC.md` §6.1 allows body to
## tell — action validity, reach, positioning and leverage, matchups — projected
## once onto the starting ratings. They are normalized to zero-sum before use,
## so a body choice trades strengths rather than granting them: §7.4.3 rule 6 is
## explicit that body "is not free Overall", and §28 makes a body configuration
## that dominates every major observable a release blocker.
var size_influence: Array[float]
var mass_influence: Array[float]
## Rating points of redistribution produced by a body at the edge of its
## family's credible range.
var size_redistribution_scale: float
var mass_redistribution_scale: float

## Lower bound on weight relative to the height-implied reference, for post-
## creation conditioning. §7.4 requires weight to stay within credible
## health/body bounds and to be modelled separately from height growth.
var weight_health_margin: int


func _init(
	p_version: StringName = &"builder-v1",
	p_base_technical: int = 35,
	p_base_iq: int = 38,
	p_base_physical: int = 45,
	p_creation_ap_budget: int = 195,
	p_prospect_ap_modifiers: Array[int] = [40, 0, -40],
	p_starting_soft_maximum: int = 70,
	p_starting_absolute_maximum: int = 75,
	p_body_redistribution_total: int = 18,
	p_body_redistribution_single_maximum: int = 4,
) -> void:
	assert(not p_version.is_empty(), "a builder profile requires a version")
	assert(
		Rating.is_valid_active(p_base_technical)
		and Rating.is_valid_active(p_base_iq)
		and Rating.is_valid_active(p_base_physical),
		"starting bases must be legal active ratings"
	)
	assert(p_creation_ap_budget > 0, "the creation budget must be positive")
	assert(p_prospect_ap_modifiers.size() == ProspectProfile.COUNT,
		"one creation AP modifier per prospect profile is required")
	assert(p_starting_soft_maximum <= p_starting_absolute_maximum,
		"the soft starting maximum cannot exceed the absolute starting maximum")
	assert(Rating.is_valid_active(p_starting_absolute_maximum),
		"the absolute starting maximum must be a legal active rating")
	assert(p_body_redistribution_total >= 0, "body redistribution cannot be negative")
	assert(p_body_redistribution_single_maximum >= 0,
		"the single-attribute body modifier bound cannot be negative")
	for modifier in p_prospect_ap_modifiers:
		assert(p_creation_ap_budget + modifier > 0,
			"every prospect profile must receive a positive creation budget")

	version = p_version
	base_technical = p_base_technical
	base_iq = p_base_iq
	base_physical = p_base_physical
	creation_ap_budget = p_creation_ap_budget
	prospect_ap_modifiers = p_prospect_ap_modifiers.duplicate()
	starting_soft_maximum = p_starting_soft_maximum
	starting_absolute_maximum = p_starting_absolute_maximum
	body_redistribution_total = p_body_redistribution_total
	body_redistribution_single_maximum = p_body_redistribution_single_maximum

	family_height_minimum = [66, 70, 74]
	family_height_maximum = [74, 78, 82]
	weight_pounds_per_inch = 4.6
	weight_reference_height = 72
	weight_reference_pounds = 160
	weight_selectable_margin = 22
	wingspan_delta_minimum = -2
	wingspan_delta_maximum = 7
	standing_reach_height_share = 0.585
	standing_reach_wingspan_share = 0.720
	growth_height_minimum = 2
	growth_height_maximum = 8
	growth_weight_minimum = 25
	growth_weight_maximum = 70
	growth_wingspan_minimum = 2
	growth_wingspan_maximum = 9
	high_school_growth_share = [0.75, 0.50, 0.25]
	weight_health_margin = 40

	# Indexed by AttributeKey.Key, in canonical order:
	# short_range, dunking, mid_range, three_point, free_throw,
	# handle, passing, vision, offensive_iq, perimeter_defense,
	# interior_defense, stealing, blocking, defensive_iq,
	# offensive_rebounding, defensive_rebounding, speed, strength,
	# stamina, vertical
	size_influence = [
		0.3, 0.6, -0.2, -0.4, -0.2,
		-0.9, -0.2, 0.0, 0.0, -0.5,
		0.8, -0.4, 1.0, 0.0,
		0.7, 0.7, -0.7, 0.3,
		-0.3, -0.3,
	]
	mass_influence = [
		0.2, 0.0, 0.0, 0.0, 0.0,
		-0.2, 0.0, 0.0, 0.0, -0.2,
		0.5, -0.1, 0.1, 0.0,
		0.4, 0.4, -0.7, 1.0,
		-0.6, -0.5,
	]
	size_redistribution_scale = 4.0
	mass_redistribution_scale = 2.6
	assert(size_influence.size() == AttributeKey.COUNT,
		"one size influence per canonical attribute is required")
	assert(mass_influence.size() == AttributeKey.COUNT,
		"one mass influence per canonical attribute is required")


static func default_profile() -> BuilderProfile:
	return BuilderProfile.new()


## The creation budget for one prospect profile. This is the only supported
## source of a creation budget; `BALANCE_SPEC.md` §7.1 forbids any other route
## to creation currency.
func creation_budget_for(prospect: int) -> int:
	assert(ProspectProfile.is_valid(prospect), "unknown prospect profile")
	return creation_ap_budget + prospect_ap_modifiers[prospect]


## Starting base for one attribute before body adjustment.
func base_rating_for(attribute: int) -> int:
	match attribute:
		AttributeKey.Key.OFFENSIVE_IQ, AttributeKey.Key.DEFENSIVE_IQ:
			return base_iq
		AttributeKey.Key.SPEED, AttributeKey.Key.STRENGTH, \
		AttributeKey.Key.STAMINA, AttributeKey.Key.VERTICAL:
			return base_physical
		_:
			return base_technical


func base_ratings() -> Array[int]:
	var ratings: Array[int] = []
	for attribute in AttributeKey.all():
		ratings.append(base_rating_for(attribute))
	return ratings


func high_school_growth_share_for(maturity: int) -> float:
	assert(MaturityProfile.is_valid(maturity), "unknown maturity profile")
	return high_school_growth_share[maturity]


func describe_tunables() -> Array[BalanceTunable]:
	var tunables: Array[BalanceTunable] = []
	tunables.append(BalanceTunable.new(
		BASE_TECHNICAL_NAME, &"rating", float(base_technical), 25.0, 55.0))
	tunables.append(BalanceTunable.new(
		BASE_IQ_NAME, &"rating", float(base_iq), 25.0, 55.0))
	tunables.append(BalanceTunable.new(
		BASE_PHYSICAL_NAME, &"rating", float(base_physical), 25.0, 60.0))
	tunables.append(BalanceTunable.new(
		CREATION_BUDGET_NAME, &"attribute_point", float(creation_ap_budget), 100.0, 320.0))
	tunables.append(BalanceTunable.new(
		SOFT_MAXIMUM_NAME, &"rating", float(starting_soft_maximum), 60.0, 80.0))
	tunables.append(BalanceTunable.new(
		ABSOLUTE_MAXIMUM_NAME, &"rating", float(starting_absolute_maximum), 65.0, 85.0))
	tunables.append(BalanceTunable.new(
		REDISTRIBUTION_TOTAL_NAME, &"rating_point", float(body_redistribution_total), 0.0, 18.0))
	tunables.append(BalanceTunable.new(
		REDISTRIBUTION_SINGLE_NAME, &"rating_point",
		float(body_redistribution_single_maximum), 0.0, 4.0))
	for prospect in ProspectProfile.all():
		tunables.append(BalanceTunable.new(
			StringName("builder.creation_ap_modifier.%s" % ProspectProfile.id_of(prospect)),
			&"attribute_point",
			float(prospect_ap_modifiers[prospect]),
			-80.0,
			80.0
		))
	for maturity in MaturityProfile.all():
		tunables.append(BalanceTunable.new(
			StringName("builder.high_school_growth_share.%s" % MaturityProfile.id_of(maturity)),
			&"share",
			high_school_growth_share[maturity],
			0.0,
			1.0
		))
	return tunables
