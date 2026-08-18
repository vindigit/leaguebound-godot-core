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
##
## ## Why the rare-generational entry is 1.70
##
## Measured rather than fitted. `run_generational_diagnostics.gd` replays each
## career's own starting build and caps through the projection's ordinary
## cheapest-first conversion at multiples of the budget it actually received.
## At this altitude the Â§9.1 cost table prices an Overall point near 160 AP â€”
## twenty attributes at 8 AP for a destination of 90-94 â€” and the measured curve
## agrees: the cohort's median converted budget of 2,415 AP produces a peak of
## 90, x1.10 produces 92, and x1.20 produces 93. Allocation is not an
## alternative: the Overall-maximising bound, which no legal allocator can beat,
## exceeds the realized career by 0.6 Overall, so no reordering of spending
## closes a three-point gap. The multiplier is therefore the measured x1.20.
##
## ## Its relationship to the Â§9.5 upper guardrails
##
## This is the honest and uncomfortable part of the correction, and it is
## reported rather than hidden. Summed across the twenty-three seasons of this
## career shape, the Â§9.5 high-engagement guardrails permit 2,695 AP-equivalent;
## a median peak of 93 needs about 3,140. The cohort therefore runs roughly 14%
## above the guardrail in aggregate, concentrated in the college and early
## professional seasons.
##
## Â§9.5 provides exactly one mechanism for that: "The upper guardrail is not a
## hard currency cap. It triggers a balance warning and requires the source
## ledger to explain why the season was exceptional." Every such season now does
## trigger one, carries a named non-offseason grant explaining it, and is
## counted in the report. The previous model exceeded the same guardrails
## silently while still missing the band, which is strictly worse.
##
## Â§8.4 is Locked (OD-A) and the Â§9.5 bands are Baselines that Â§9.5 itself
## records as provisional and still missing this band, so the tension resolves
## in Â§8.4's favour. It is written up in `PROJECT_STATUS.md` as a live
## Baseline-versus-Locked conflict rather than treated as settled.
const PATH_OPPORTUNITY: PackedFloat64Array = [0.62, 0.86, 1.02, 1.24, 1.70]
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
## Â§8.4 describes the generational outcome as the rare conjunction of an elite
## ceiling *and* an elite career, and Â§8.1 provides selection pressure as the
## mechanism. Drawing the top path's ceiling as the best of a small pool is that
## conjunction: the talent is selected, not granted, and every ceiling it yields
## was already reachable from the same distribution, which is what Â§8.2's
## prohibition on silently increasing a cap requires.
##
## ## Why the rare-generational pool is 3
##
## The pool exists to answer a specific measured defect, not to raise peaks. At
## a pool of 2 roughly a quarter of the cohort drew a ceiling whose Maximum
## Potential sat below the band the cohort is defined to reach; those careers
## filled every cap, stranded up to 1,200 AP-equivalent unspent, and peaked in
## the mid-eighties whatever opportunity they were given. That is a
## classification selecting careers incapable of its own band, and no
## opportunity setting can repair it.
##
## Measured on the tuning range at a fixed opportunity multiplier, raising the
## pool from 2 to 3 lifted the cohort's tenth percentile without moving its
## median at all â€” the median career is opportunity-bound and simply does not
## reach its ceiling. That is the signature of a lever acting on the right
## defect: it repairs the tail it was chosen for and leaves the centre alone.
##
## A pool of 4 tightens the tail slightly further and was measured, but it
## pushes the drawn ceiling against the profile's own 99 maximum often enough
## that the ceiling distribution begins to pile on the clip. Three is the
## smaller change and does not distort the distribution it selects from.
const PATH_CEILING_SELECTION_POOL: PackedInt32Array = [1, 1, 1, 1, 3]

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

	## --- Â§8.4 diagnostic instrumentation -----------------------------------
	##
	## Populated only when the simulator is asked to capture diagnostics. These
	## are measurements *of* the canonical development contract and never inputs
	## to it: nothing in the simulator, the domain, or any projection reads them
	## back, so a career runs identically whether or not they are recorded.
	##
	## They exist because the Â§8.4 rare-generational miss has several candidate
	## causes â€” too little legitimate opportunity, opportunity arriving after
	## decline, allocation that converts opportunity inefficiently, a cap shape
	## that forbids the band, or a cohort that cannot reach its own label â€” and a
	## median peak alone cannot tell them apart.
	var ap_granted_by_phase: PackedFloat64Array = []
	var ap_spent_by_phase: PackedFloat64Array = []
	var ap_granted_by_source: PackedFloat64Array = []
	var ap_debited_by_source: PackedFloat64Array = []
	## General AP still in the wallet when the career ended: opportunity that was
	## granted, ledgered, and never converted into a rating point.
	var ap_unspent: float = 0.0
	## Seasons whose granted total passed the Â§9.5 upper guardrail for the phase,
	## and by how much in total. Â§9.5 makes the guardrail a warning rather than a
	## cap, but an unreported breach is the same defect as a silent one.
	var guardrail_seasons: int = 0
	var guardrail_excess: float = 0.0
	## Seasons that passed the guardrail without a source-ledger explanation.
	## Â§9.5 permits an exceptional season; it does not permit an unexplained one,
	## so this must be zero on every career.
	var guardrail_unexplained_seasons: int = 0
	## Career year (one-based) whose season produced the peak Overall.
	var peak_season: int = 0
	var granted_before_peak: float = 0.0
	var granted_after_peak: float = 0.0
	## Ratings as they stood at the peak season. Caps never move in this
	## simulator â€” no Â§8.3 event fires â€” so `starting_caps` is also the cap
	## vector at the peak.
	var peak_values: Array[int] = []
	var attributes_at_cap_at_peak: int = 0
	## Share of the player's own per-attribute cap total actually filled *at the
	## peak*, as opposed to `cap_attainment`, which is measured at career end
	## after decline has removed points.
	var peak_cap_attainment: float = 0.0
	var overall_by_season: PackedInt32Array = []
	## Â§9.6 game-participation AP credited in each career year, indexed from the
	## freshman season. Carried per season rather than per career because Â§9.6's
	## cap is seasonal and a career total cannot show a single season breaching it.
	var game_ap_by_season: PackedFloat64Array = []
	## The finished player, retained so a caller can reconcile the ledger against
	## the ratings it claims to have bought. Held only under diagnostics: the
	## certification run keeps a million results alive and has no use for it.
	var final_state: PlayerDevelopmentState = null
	var age_by_season: PackedInt32Array = []

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
## Diagnostic-only sweep overrides for the two Â§8.4 levers the measurement
## identified. An empty array means "use the committed constant", which is what
## every production path uses: the career-progression report never sets these,
## so the shipped model is the one the constants describe.
##
## They exist so a tuning sweep can measure several candidate settings in one
## deterministic run instead of editing committed constants between runs, which
## is how a tuning range quietly becomes a validation range.
var path_opportunity_override: PackedFloat64Array = []
var path_ceiling_pool_override: PackedInt32Array = []


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
##
## `force_path` is a **diagnostic** override and defaults to no override at all.
## The population draw is still consumed, so a forced career is generated from
## exactly the stream a natural one of that path would use rather than from a
## shifted one. For the top two paths the override is therefore not merely
## statistically equivalent but bit-identical: `path_for` consumes one draw
## whatever it returns, and every path at or above `EXCEPTIONAL` takes the same
## prospect branch, so forcing `GENERATIONAL` on a seed reproduces precisely the
## career the population would have produced had that seed drawn the top path.
## That is what lets the Â§8.4 tail be measured at every seed instead of at the
## two percent of seeds that draw it, without inventing a second cohort.
##
## Nothing in the game calls this with an override; the production runner never
## passes one.
func simulate(seed_value: int, executor: int, force_path: int = -1) -> CareerResult:
	assert(force_path < PATH_COUNT, "unknown career outcome path")
	var source := SeededRandomSource.new(seed_value)
	var selector: RandomSource = source.derive(&"career_selection")
	var drawn_path: int = path_for(selector.next_float())
	var path: int = drawn_path if force_path < 0 else force_path
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
		ceiling_pool_for(path))
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
	var diagnostics: bool = capture_diagnostics
	if diagnostics:
		result.peak_values = state.attributes.canonical_values()
		result.peak_season = 0

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
		# Â§9.7.2 requires: a career that got more minutes records the uplift, a
		# career that got fewer records the shortfall it never realized. The
		# ledger rejects a negative grant outright, which is why the shortfall is
		# a debit rather than a grant of a negative amount.
		var scale: float = opportunity_for(path) * PATH_EFFICIENCY[path]
		var adjustment: float = granted * (scale - 1.0)
		if adjustment > 0.0001:
			# Â§9.6 caps what game participation may contribute in one season at
			# 12 AP-equivalent in high school, 16 in college, and 20 in top
			# domestic professional basketball. The previous model booked the
			# whole uplift to game participation, which for a well-managed career
			# was thirty-odd AP a season against a cap of twenty â€” opportunity
			# attributed to a source whose own cap forbids it. What games cannot
			# carry is Â§9.3 training and development-programme work, which Â§9.5
			# names as part of the same seasonal total. The amounts are unchanged;
			# what changes is that the ledger can now account for them.
			var from_games: float = _development.grant_game_development(
				state, career_year, phase, executor, adjustment,
				"path=%s game participation" % path_id(path))
			var from_training: float = adjustment - from_games
			if from_training > 0.0001:
				_development.grant_opportunity(
					state, career_year, AttributePointSource.Value.TRAINING,
					executor, from_training,
					"path=%s training and development programme" % path_id(path))
		elif adjustment < -0.0001:
			state.point_ledger.debit(
				career_year, AttributePointSource.Value.GAME, executor,
				-adjustment, state.balance_version, -1,
				"path=%s unrealized opportunity" % path_id(path))
		granted_total += granted + adjustment

		# Â§9.5 makes the upper guardrail a balance *warning* the source ledger
		# must explain, not a hard currency cap â€” so a season above it is legal
		# and a season above it that nobody counted is not. The judgment and the
		# explanation both come from the canonical service rather than from a
		# second copy of the rule here, and both are counted on every career
		# rather than only when diagnostics are being captured: a warning nobody
		# tallies is the same as no warning at all.
		if _development.exceeds_seasonal_guardrail(state, career_year, phase):
			result.guardrail_seasons += 1
			result.guardrail_excess += (
				_development.seasonal_granted_total(state, career_year)
				- float(_profiles.progression.seasonal_ap_guardrail[phase]))
			if not _development.seasonal_guardrail_is_explained(state, career_year, phase):
				result.guardrail_unexplained_seasons += 1

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
			if diagnostics:
				result.peak_season = career_year
				result.peak_values = state.attributes.canonical_values()
				result.granted_before_peak = granted_total
		if diagnostics:
			result.overall_by_season.append(current)
			result.age_by_season.append(state.age)

	result.seasons = seasons
	result.peak_overall = peak
	result.peak_age = peak_age
	result.final_overall = OverallCalculator.current_overall(state.attributes, _profiles.ratings)
	result.total_ap_granted = granted_total
	result.total_ap_spent = spent_total
	result.cap_attainment = _cap_attainment(state)
	if diagnostics:
		result.granted_after_peak = granted_total - result.granted_before_peak
		_capture_ledger_diagnostics(state, result)


## Walk the completed ledger once and record where a career's opportunity came
## from, where it went, and what it never converted.
##
## This is pure measurement. It runs after the career is over, reads only what
## the canonical contract already recorded, and writes nothing back into player
## state â€” a diagnostic that changed the thing it measures would be worthless
## and, under Â§9.7.4, a defect.
func _capture_ledger_diagnostics(
	state: PlayerDevelopmentState,
	result: CareerResult,
) -> void:
	var granted_by_phase := PackedFloat64Array()
	var spent_by_phase := PackedFloat64Array()
	granted_by_phase.resize(CareerPhase.COUNT)
	spent_by_phase.resize(CareerPhase.COUNT)
	var granted_by_source := PackedFloat64Array()
	var debited_by_source := PackedFloat64Array()
	granted_by_source.resize(AttributePointSource.COUNT)
	debited_by_source.resize(AttributePointSource.COUNT)
	var game_by_season := PackedFloat64Array()
	game_by_season.resize(result.seasons)

	for entry in state.point_ledger.entries():
		var phase: int = PHASE_BY_SEASON[
			mini(entry.career_year - 1, PHASE_BY_SEASON.size() - 1)]
		if entry.is_grant():
			granted_by_phase[phase] += entry.amount
			granted_by_source[entry.source] += entry.amount
			if entry.source == AttributePointSource.Value.GAME \
					and entry.career_year <= game_by_season.size():
				game_by_season[entry.career_year - 1] += entry.amount
		elif entry.source == AttributePointSource.Value.TRAINING:
			# In this simulator every TRAINING debit is an allocator spend: no
			# focused direct-progress event fires, so nothing else writes one.
			spent_by_phase[phase] += -entry.amount
		else:
			debited_by_source[entry.source] += -entry.amount

	result.ap_granted_by_phase = granted_by_phase
	result.ap_spent_by_phase = spent_by_phase
	result.ap_granted_by_source = granted_by_source
	result.ap_debited_by_source = debited_by_source
	result.ap_unspent = state.point_ledger.balance()
	result.game_ap_by_season = game_by_season
	result.final_state = state

	var filled: int = 0
	var ceiling: int = 0
	var at_cap: int = 0
	for attribute in range(AttributeKey.COUNT):
		var cap: int = state.caps.cap_for(attribute)
		filled += result.peak_values[attribute]
		ceiling += cap
		if result.peak_values[attribute] >= cap:
			at_cap += 1
	result.attributes_at_cap_at_peak = at_cap
	if ceiling > 0:
		result.peak_cap_attainment = float(filled) / float(ceiling)


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


## The Â§8.4 opportunity multiplier in force for a path.
##
## Reads the committed constant unless a diagnostic sweep has supplied a full
## override row. There is deliberately no partial override: a sweep that could
## replace one path's multiplier and leave the rest to a stale array would make
## the reported cohort depend on which entries were filled.
func opportunity_for(path: int) -> float:
	assert(path >= 0 and path < PATH_COUNT, "unknown career outcome path")
	if path_opportunity_override.size() == PATH_COUNT:
		return path_opportunity_override[path]
	return PATH_OPPORTUNITY[path]


## The Â§8.1 ceiling selection pool in force for a path. See `opportunity_for`.
func ceiling_pool_for(path: int) -> int:
	assert(path >= 0 and path < PATH_COUNT, "unknown career outcome path")
	if path_ceiling_pool_override.size() == PATH_COUNT:
		return path_ceiling_pool_override[path]
	return PATH_CEILING_SELECTION_POOL[path]
