class_name CareerSimulator
extends RefCounted

## Runs one complete player career through the canonical development contract.
##
## `BALANCE_SPEC.md` Â§9.7 (OD-E) is explicit that there is exactly one
## development contract and that detail level changes how it is executed, never
## what it produces. This simulator therefore drives `DevelopmentService` and
## `AttributeAllocator` â€” the same objects the game uses â€” rather than modelling
## progression a second time. A career here spends AP-equivalent opportunity
## against the real cost table, the real caps, the real receipts, and the real
## aging model.
##
## What it deliberately does **not** do is simulate matches. Seasonal
## opportunity is granted from the Â§9.5 availability model, which is what Â§9.6
## says game participation fills. Simulating 82 games per season per career
## would make the million-career report impossible and would not change the AP
## the season grants.

## The career outcome classification the Â§8.4 bands are stated against.
enum Path {
	POOR,          ## poorly managed or injury-hit
	ORDINARY,      ## ordinary successful
	STRONG,        ## strong and well-managed
	EXCEPTIONAL,   ## exceptional
	GENERATIONAL,  ## rare generational
}

const PATH_COUNT: int = 5
const PATH_IDS: PackedStringArray = [
	"poor_or_injury_hit", "ordinary_successful", "strong_well_managed",
	"exceptional", "rare_generational",
]

## How the career-outcome population is drawn. These are *population shares*,
## not difficulty settings (Â§3.1: there is one standard difficulty). They
## describe how often a career is well managed, healthy, and given opportunity â€”
## the things Â§8.4 says the bands are about.
const PATH_SHARES: PackedFloat64Array = [0.26, 0.40, 0.22, 0.10, 0.02]

## Opportunity multiplier applied to every season's granted AP, by path. This is
## the primary Â§8.4 tunable: "It is corrected by tuning seasonal AP
## availability, the cost curve, cap distributions, aging, or decline."
const PATH_OPPORTUNITY: PackedFloat64Array = [0.62, 0.86, 1.02, 1.24, 1.42]
## Share of granted AP the executor actually converts into rating points, by
## path. Poorly managed careers waste opportunity on attributes they cannot use.
const PATH_EFFICIENCY: PackedFloat64Array = [0.72, 0.90, 0.97, 1.0, 1.0]
## Mileage multiplier feeding the Â§10.3 decline model.
const PATH_MILEAGE: PackedFloat64Array = [1.34, 1.05, 0.95, 0.88, 0.82]

## Career length in seasons from the freshman year, by path. A poorly managed or
## injury-hit career ends earlier.
const PATH_SEASONS: PackedInt32Array = [11, 16, 19, 21, 23]

## Â§8.1 ceiling selection pressure by path.
##
## Measured cause of the rare-generational miss: at the 2026-08 baseline the top
## two paths reached 96-98% cap attainment on 2,200-2,600 lifetime AP, so
## opportunity was saturated and the ceiling was the only remaining lever. Their
## Maximum Potential medians were 90 and 92 against Â§8.4 bands of 86-91 and
## 92-95 â€” two points apart where the bands are six apart. More opportunity buys
## a career at 97% attainment nothing at all.
##
## Â§8.4 describes the generational outcome as the rare conjunction of an elite
## ceiling *and* an elite career, and Â§8.1 provides selection pressure as the
## mechanism. Drawing the top path's ceiling as the best of a small pool is that
## conjunction: the talent is selected, not granted, and every ceiling it yields
## was already reachable from the same distribution.
const PATH_CEILING_SELECTION_POOL: PackedInt32Array = [1, 1, 1, 1, 2]

## The `CareerPhase` a career occupies at each season index from the freshman
## year: four high-school seasons, three college seasons, then early, prime, and
## late professional phases.
const PHASE_BY_SEASON: PackedInt32Array = [
	CareerPhase.Value.HIGH_SCHOOL, CareerPhase.Value.HIGH_SCHOOL,
	CareerPhase.Value.HIGH_SCHOOL, CareerPhase.Value.HIGH_SCHOOL,
	CareerPhase.Value.COLLEGE, CareerPhase.Value.COLLEGE, CareerPhase.Value.COLLEGE,
	CareerPhase.Value.PRO_EARLY, CareerPhase.Value.PRO_EARLY,
	CareerPhase.Value.PRO_EARLY, CareerPhase.Value.PRO_EARLY,
	CareerPhase.Value.PRO_PRIME, CareerPhase.Value.PRO_PRIME,
	CareerPhase.Value.PRO_PRIME, CareerPhase.Value.PRO_PRIME,
	CareerPhase.Value.PRO_PRIME, CareerPhase.Value.PRO_PRIME,
	CareerPhase.Value.PRO_LATE, CareerPhase.Value.PRO_LATE,
	CareerPhase.Value.PRO_LATE, CareerPhase.Value.PRO_LATE,
	CareerPhase.Value.PRO_LATE, CareerPhase.Value.PRO_LATE,
	CareerPhase.Value.PRO_LATE,
]

## Development-staff quality by path. Â§9.6's `DevelopmentRoom` and the
## allocator's coaching term are what "well managed" means numerically.
const PATH_COACHING: PackedFloat64Array = [0.28, 0.50, 0.66, 0.78, 0.86]
## How much of the season the allocator spends shoring up weaknesses rather
## than pressing strengths.
const PATH_DEFICIENCY_FOCUS: PackedFloat64Array = [0.55, 0.38, 0.30, 0.26, 0.22]

## One completed career.
class CareerResult extends RefCounted:
	var path: int
	var prospect: int
	var family: int
	var maturity: int
	var seed_value: int
	var starting_overall: int
	var maximum_potential: int
	var projected_peak_low: int
	var projected_peak_high: int
	var peak_overall: int
	var peak_age: int
	var final_overall: int
	var seasons: int
	var total_ap_granted: float
	var total_ap_spent: int
	var cap_attainment: float

	## Diagnostic-only fields, populated when the simulator is asked to capture
	## them. They exist so the projected-peak harness can re-run the model's own
	## conversion against a counterfactual budget; nothing in the domain reads
	## them, and a production projection never sees a realized career fact.
	var starting_values: Array[int] = []
	var starting_caps: AttributeCaps = null
	## AP the projection credited to the remaining career at creation.
	var projected_ap_low: float = 0.0
	var projected_ap_high: float = 0.0

	func projected_peak_width() -> int:
		return projected_peak_high - projected_peak_low

	func projected_peak_covers_realized() -> bool:
		return peak_overall >= projected_peak_low and peak_overall <= projected_peak_high

	## Realized peak minus the midpoint of the displayed range. Â§6.3 bounds the
	## median of this at Â±2 Overall points.
	func projected_peak_signed_error() -> float:
		return float(peak_overall) - float(projected_peak_low + projected_peak_high) / 2.0


var _profiles: BalanceProfileSet
var _builder: BuilderService
var _development: DevelopmentService
var _query: DevelopmentProjectionQuery
## Retains the creation-time inputs on every result. Off by default because the
## certification run holds a million results in memory and does not need them.
var capture_diagnostics: bool = false


func _init(p_profiles: BalanceProfileSet = null) -> void:
	_profiles = p_profiles if p_profiles != null else BalanceProfileSet.default_set()
	_builder = BuilderService.new(_profiles)
	_development = DevelopmentService.new(_profiles)
	_query = DevelopmentProjectionQuery.new(_profiles)


static func path_id(path: int) -> StringName:
	return StringName(PATH_IDS[path])


## Draws a career path from the population shares.
static func path_for(draw: float) -> int:
	var cumulative: float = 0.0
	for path in range(PATH_COUNT):
		cumulative += PATH_SHARES[path]
		if draw < cumulative:
			return path
	return Path.ORDINARY


## Simulates one complete career and returns its measured outcome.
##
## `executor` selects the Â§9.7.1 executor. The manual path and the full-detail
## allocator receive identical opportunity and are bound by identical rules, so
## a parity report can run this with each and compare the distributions.
func simulate(seed_value: int, executor: int) -> CareerResult:
	var source := SeededRandomSource.new(seed_value)
	var selector: RandomSource = source.derive(&"career_selection")
	var path: int = path_for(selector.next_float())
	# An exceptional or generational career needs the ceiling to permit it. §8.4
	# describes career management and opportunity, but a Ready Now ceiling of 81
	# cannot reach 92 however well the career is run, so the top two paths draw
	# from the High Upside profile. This is selection, not a difficulty setting:
	# the profile is what makes the outcome reachable, not what guarantees it.
	var prospect: int = (
		ProspectProfile.Value.HIGH_UPSIDE
		if path >= Path.EXCEPTIONAL
		else selector.range_int(0, ProspectProfile.COUNT - 1))
	var _unused_prospect_draw: int = selector.range_int(0, ProspectProfile.COUNT - 1)
	var family: int = selector.range_int(0, PositionFamily.COUNT - 1)
	var maturity: int = selector.range_int(0, MaturityProfile.COUNT - 1)

	var body: BodyProfile = _builder.default_body_for_family(family)
	var build: BuilderState = _builder.begin_build(
		family, prospect, maturity, body, source.derive(&"build"),
		PATH_CEILING_SELECTION_POOL[path])
	build.spend_remaining_weighted(_family_weights(family))
	build.fill_remaining_anywhere()
	var view: BuilderConfirmationView = _query.builder_confirmation_view(build)

	var result := CareerResult.new()
	result.path = path
	result.prospect = prospect
	result.family = family
	result.maturity = maturity
	result.seed_value = seed_value
	result.starting_overall = view.projection.current_overall
	result.maximum_potential = view.projection.maximum_potential
	result.projected_peak_low = view.projection.projected_peak.low
	result.projected_peak_high = view.projection.projected_peak.high
	if capture_diagnostics:
		result.starting_values = build.attributes().canonical_values()
		result.starting_caps = build.caps.duplicate_caps()
		var opportunity: PackedFloat64Array = ProjectedPeakCalculator.projected_opportunity_ap(
			prospect, BuilderService.FRESHMAN_AGE, _profiles.progression)
		result.projected_ap_low = opportunity[0]
		result.projected_ap_high = opportunity[1]

	var state: PlayerDevelopmentState = _builder.confirm(
		build, &"calibration_player", seed_value, source.derive(&"confirm"))
	_run_seasons(state, path, prospect, executor, source, result)
	return result


func _run_seasons(
	state: PlayerDevelopmentState,
	path: int,
	prospect: int,
	executor: int,
	source: RandomSource,
	result: CareerResult,
) -> void:
	var seasons: int = PATH_SEASONS[path]
	var peak: int = result.starting_overall
	var peak_age: int = state.age
	var granted_total: float = 0.0
	var spent_total: int = 0

	var context := DevelopmentContext.new(
		PATH_DEFICIENCY_FOCUS[path], PATH_COACHING[path], CareerPhase.Value.HIGH_SCHOOL)

	for season in range(seasons):
		var career_year: int = season + 1
		var phase: int = PHASE_BY_SEASON[mini(season, PHASE_BY_SEASON.size() - 1)]
		context.phase = phase
		var season_stream: RandomSource = source.derive(StringName("season:%d" % career_year))

		# The season's opportunity is granted through the canonical service, then
		# scaled by the path's opportunity multiplier and topped up through the
		# ordinary named-source grant so the ledger records every unit.
		var granted: float = _development.grant_seasonal_opportunity(
			state, career_year, phase, executor, season_stream.derive(&"opportunity"))
		# The path's opportunity and efficiency scale what the season actually
		# makes available. Both directions go through the ledger with their
		# source, career year, executor, and balance-profile version recorded, as
		# Â§9.7.2 requires: a career that got more minutes records a game grant, a
		# career that got fewer records the shortfall it never realized. The
		# ledger rejects a negative grant outright, which is why the shortfall is
		# a debit rather than a grant of a negative amount.
		var scale: float = PATH_OPPORTUNITY[path] * PATH_EFFICIENCY[path]
		var adjustment: float = granted * (scale - 1.0)
		if adjustment > 0.0001:
			_development.grant_opportunity(
				state, career_year, AttributePointSource.Value.GAME,
				executor, adjustment, "path=%s realized opportunity" % path_id(path))
		elif adjustment < -0.0001:
			state.point_ledger.debit(
				career_year, AttributePointSource.Value.GAME, executor,
				-adjustment, state.balance_version, -1,
				"path=%s unrealized opportunity" % path_id(path))
		granted_total += granted + adjustment

		spent_total += AttributeAllocator.allocate(
			state, career_year, context, _development, executor)

		_development.resolve_natural_annual(
			state, career_year, executor, PATH_MILEAGE[path])
		_development.advance_age(state, career_year)

		var current: int = OverallCalculator.current_overall(
			state.attributes, _profiles.ratings)
		if current > peak:
			peak = current
			peak_age = state.age

	result.seasons = seasons
	result.peak_overall = peak
	result.peak_age = peak_age
	result.final_overall = OverallCalculator.current_overall(state.attributes, _profiles.ratings)
	result.total_ap_granted = granted_total
	result.total_ap_spent = spent_total
	result.cap_attainment = _cap_attainment(state)


func _cap_attainment(state: PlayerDevelopmentState) -> float:
	var current: int = 0
	var ceiling: int = 0
	for attribute in range(AttributeKey.COUNT):
		current += state.attributes.get_rating(attribute)
		ceiling += state.caps.cap_for(attribute)
	if ceiling <= 0:
		return 0.0
	return float(current) / float(ceiling)


## A coherent allocation for the build's own position family (Â§8.4: "allocation
## that is coherent for its position family").
func _family_weights(family: int) -> Array[float]:
	var weights: Array[float] = []
	for attribute in range(AttributeKey.COUNT):
		weights.append(0.35)
	for attribute in CapGenerator.emphasis_from_family(family, [] as Array[int]):
		weights[attribute] = 1.0
	return weights
