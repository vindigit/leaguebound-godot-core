class_name TestGenerationalProgression
extends GdUnitTestSuite

## The §8.4 rare-generational correction (`BALANCE_SPEC.md` §8.4 OD-A, §9.5,
## §9.6, §9.7; Gate B3).
##
## Stage 4 raised the rare-generational cohort's lifetime opportunity and its
## §8.1 ceiling selection pressure so the band the cohort is defined to reach
## becomes reachable. Both are legitimate levers and both are easy to
## counterfeit, so this suite is written against the counterfeits rather than
## against the result:
##
##   - Opportunity that is granted but never recorded, or recorded against a
##     source whose own §9.6 cap forbids it, is indistinguishable from a rating
##     handed out for free unless something reconciles the ledger against the
##     ratings. `test_every_rating_point_is_reconstructible_from_the_ledger`
##     does exactly that, and it fails for any direct rating write and for any
##     private cost table.
##   - A season above the §9.5 high-engagement guardrail is legal; a season
##     above it that nobody warned about is the defect. The guardrail cases fail
##     if the warning is removed, if the generic offseason note is allowed to
##     satisfy it, or if the excess simply stops being counted.
##   - An outcome label that granted ratings directly would satisfy §8.4 and
##     violate everything else. The cohort cases check that the label reaches a
##     rating only through opportunity the ledger accounts for, and that the
##     neighbouring cohorts are not carried into the band alongside it.
##
## Career-level cases run real careers through `CareerSimulator`, which drives
## the production `BuilderService`, `DevelopmentService`, `AttributeAllocator`,
## and `AgingResolver`. They are deliberately small samples: distributional
## claims belong to the calibration runners, and what is pinned here is
## structure that a handful of careers already fixes.

## Small enough to keep the suite quick, large enough that the §8.4 median is
## not decided by one career.
const COHORT: int = 40
const COHORT_SEED_BASE: int = 610000

var _profiles: BalanceProfileSet
var _builder: BuilderService
var _development: DevelopmentService

## One cohort per outcome path, simulated once and shared across every case that
## reads it. Each career is a full twenty-plus-season run through the production
## services, so re-simulating per test would dominate the suite.
static var _cohorts: Dictionary[int, Array] = {}


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_builder = BuilderService.new(_profiles)
	_development = DevelopmentService.new(_profiles)


func _cohort(path: int) -> Array:
	if not _cohorts.has(path):
		var simulator := CareerSimulator.new(_profiles)
		simulator.capture_diagnostics = true
		var results: Array = []
		for index in range(COHORT):
			results.append(simulator.simulate(
				COHORT_SEED_BASE + index + 1, DevelopmentExecutor.Value.MANUAL, path))
		_cohorts[path] = results
	return _cohorts[path]


func _median_peak(path: int) -> float:
	var peaks := PackedFloat64Array()
	for entry: CareerSimulator.CareerResult in _cohort(path):
		peaks.append(float(entry.peak_overall))
	peaks.sort()
	return CalibrationStatistics.percentile(peaks, 0.50)


func _player(seed_value: int) -> PlayerDevelopmentState:
	var family: int = PositionFamily.Value.WING
	var source: RandomSource = SeededRandomSource.new(seed_value)
	var state: BuilderState = _builder.begin_build(
		family, ProspectProfile.Value.BALANCED, MaturityProfile.Value.AVERAGE,
		_builder.default_body_for_family(family), source)
	state.fill_remaining_anywhere()
	return _builder.confirm(
		state, &"player", seed_value, SeededRandomSource.new(seed_value))


# --- §9.6 game-development caps ----------------------------------------------


## §9.6: "Seasonal game-development caps are 12 AP-equivalent in HS, 16 in
## college/alternatives, and 20 in top domestic professional basketball."
##
## The previous model booked a well-managed career's whole seasonal uplift to
## game participation — around thirty AP a season against a cap of twenty — so
## this is the regression that names the defect it replaced.
func test_game_development_stops_at_the_seasonal_cap() -> void:
	var player: PlayerDevelopmentState = _player(7101)

	var credited: float = _development.grant_game_development(
		player, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.MANUAL, 400.0, "one enormous season")

	assert_float(credited).is_equal_approx(12.0, 0.0001)
	assert_float(player.point_ledger.granted_from(1, AttributePointSource.Value.GAME))\
		.is_equal_approx(12.0, 0.0001)
	assert_float(player.point_ledger.balance()).is_equal_approx(12.0, 0.0001)


## The cap is a seasonal pool, not a per-grant limit. §9.6: "Played and
## simulated games share the same pool and formula."
func test_the_game_cap_is_a_seasonal_pool_not_a_per_grant_limit() -> void:
	var player: PlayerDevelopmentState = _player(7102)

	for _game in range(5):
		_development.grant_game_development(
			player, 3, CareerPhase.Value.PRO_PRIME,
			DevelopmentExecutor.Value.MANUAL, 8.0, "a good run")

	assert_float(player.point_ledger.granted_from(3, AttributePointSource.Value.GAME))\
		.is_equal_approx(20.0, 0.0001)


## Each phase carries its own cap, and a later career year starts a fresh pool.
func test_the_game_cap_follows_the_phase_and_resets_each_career_year() -> void:
	var player: PlayerDevelopmentState = _player(7103)

	_development.grant_game_development(
		player, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.MANUAL, 100.0, "high school")
	_development.grant_game_development(
		player, 2, CareerPhase.Value.COLLEGE,
		DevelopmentExecutor.Value.MANUAL, 100.0, "college")
	_development.grant_game_development(
		player, 3, CareerPhase.Value.PRO_EARLY,
		DevelopmentExecutor.Value.MANUAL, 100.0, "professional")

	assert_float(player.point_ledger.granted_from(1, AttributePointSource.Value.GAME))\
		.is_equal_approx(12.0, 0.0001)
	assert_float(player.point_ledger.granted_from(2, AttributePointSource.Value.GAME))\
		.is_equal_approx(16.0, 0.0001)
	assert_float(player.point_ledger.granted_from(3, AttributePointSource.Value.GAME))\
		.is_equal_approx(20.0, 0.0001)


## No season of a completed career may credit game participation beyond its
## §9.6 cap. This is the end-to-end form of the cases above: it fails if any
## executor reaches past `grant_game_development` to the raw ledger.
func test_no_career_season_exceeds_the_game_development_cap() -> void:
	var credited_seasons: int = 0
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		for season in range(entry.game_ap_by_season.size()):
			var phase: int = CareerSimulator.PHASE_BY_SEASON[
				mini(season, CareerSimulator.PHASE_BY_SEASON.size() - 1)]
			var cap: float = float(_profiles.progression.game_development_cap[phase])
			assert_float(entry.game_ap_by_season[season]).is_less_equal(cap + 0.0001)
			if entry.game_ap_by_season[season] > 0.0:
				credited_seasons += 1
	# A cap nothing ever reached for would make the assertion above vacuous.
	assert_int(credited_seasons).is_greater(0)


# --- §9.5 upper guardrail -----------------------------------------------------


## An ordinary season triggers nothing. §9.5's guardrail marks the boundary of
## the high-engagement tail, not the boundary of legality.
func test_an_ordinary_season_raises_no_guardrail_warning() -> void:
	var player: PlayerDevelopmentState = _player(7201)

	_development.grant_opportunity(
		player, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 100.0, "phase=college")

	assert_bool(_development.exceeds_seasonal_guardrail(
		player, 1, CareerPhase.Value.COLLEGE)).is_false()
	assert_str(_development.seasonal_guardrail_warning(
		player, 1, CareerPhase.Value.COLLEGE)).is_empty()
	assert_bool(_development.seasonal_guardrail_is_explained(
		player, 1, CareerPhase.Value.COLLEGE)).is_true()


## §9.5: passing the guardrail "triggers a balance warning and requires the
## source ledger to explain why the season was exceptional". Both halves.
func test_an_exceptional_season_warns_and_carries_its_explanation() -> void:
	var player: PlayerDevelopmentState = _player(7202)

	_development.grant_opportunity(
		player, 4, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 110.0, "phase=pro_early")
	_development.grant_opportunity(
		player, 4, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 40.0,
		"path=rare_generational training and development programme")

	assert_bool(_development.exceeds_seasonal_guardrail(
		player, 4, CareerPhase.Value.PRO_EARLY)).is_true()
	assert_bool(_development.seasonal_guardrail_is_explained(
		player, 4, CareerPhase.Value.PRO_EARLY)).is_true()
	var warning: String = _development.seasonal_guardrail_warning(
		player, 4, CareerPhase.Value.PRO_EARLY)
	assert_str(warning).is_not_empty()
	assert_str(warning).contains("rare_generational")
	assert_str(warning).contains("pro_early")


## The generic offseason grant explains nothing: every season of the phase gets
## one and its note names only the phase. A model that satisfied §9.5 with that
## note would carry a guardrail nothing could ever trip, so this case fails if
## the offseason source stops being excluded from the explanation.
func test_the_offseason_note_alone_does_not_explain_an_exceptional_season() -> void:
	var player: PlayerDevelopmentState = _player(7203)

	_development.grant_opportunity(
		player, 12, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 200.0, "phase=pro_prime")

	assert_bool(_development.exceeds_seasonal_guardrail(
		player, 12, CareerPhase.Value.PRO_PRIME)).is_true()
	assert_bool(_development.seasonal_guardrail_is_explained(
		player, 12, CareerPhase.Value.PRO_PRIME)).is_false()
	assert_str(_development.seasonal_guardrail_warning(
		player, 12, CareerPhase.Value.PRO_PRIME))\
		.contains("no source-ledger explanation")


## An unnamed grant is exactly the shape a hidden AP top-up takes, so an excess
## it produced must report as unexplained rather than pass quietly.
func test_an_unnamed_grant_cannot_explain_an_exceptional_season() -> void:
	var player: PlayerDevelopmentState = _player(7204)

	_development.grant_opportunity(
		player, 20, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 50.0, "phase=pro_late")
	_development.grant_opportunity(
		player, 20, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 40.0)

	assert_bool(_development.exceeds_seasonal_guardrail(
		player, 20, CareerPhase.Value.PRO_LATE)).is_true()
	assert_bool(_development.seasonal_guardrail_is_explained(
		player, 20, CareerPhase.Value.PRO_LATE)).is_false()


## Every guardrail-passing season of a completed rare-generational career must
## carry its explanation. The cohort genuinely exceeds the guardrail — that is
## the reported cost of reaching the §8.4 band — so the case checks it is not
## vacuous before asserting.
func test_every_exceptional_season_in_the_cohort_is_explained() -> void:
	var warned: int = 0
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		warned += entry.guardrail_seasons
		assert_int(entry.guardrail_unexplained_seasons).is_equal(0)
	assert_int(warned).is_greater(0)


# --- the seasonal total the guardrail is measured against --------------------


## The constant-time seasonal index must agree with a full ledger scan. If it
## drifts, every guardrail decision built on it is wrong and nothing else in
## this suite would notice.
func test_the_seasonal_total_matches_a_full_ledger_scan() -> void:
	var player: PlayerDevelopmentState = _player(7301)
	_development.grant_opportunity(
		player, 2, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 90.0, "phase=college")
	_development.grant_game_development(
		player, 2, CareerPhase.Value.COLLEGE,
		DevelopmentExecutor.Value.MANUAL, 30.0, "games")
	_development.grant_opportunity(
		player, 2, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 25.0, "training")
	_development.spend_general_ap(
		player, AttributeKey.Key.PASSING, 3, 2, DevelopmentExecutor.Value.MANUAL)

	var scanned: float = 0.0
	for entry in player.point_ledger.entries():
		if entry.career_year == 2 and entry.is_grant() \
				and entry.source != AttributePointSource.Value.AT_CAP_CONVERSION:
			scanned += entry.amount

	assert_float(_development.seasonal_granted_total(player, 2))\
		.is_equal_approx(scanned, 0.0001)
	# 90 offseason, plus 30 of games trimmed to the college cap of 16, plus 25
	# of training.
	assert_float(scanned).is_equal_approx(131.0, 0.0001)


## Spends and decline debits move opportunity a season already granted.
## Counting them would let a career that spent everything look like a season
## that granted nothing.
func test_spending_and_decline_do_not_reduce_the_seasonal_total() -> void:
	var player: PlayerDevelopmentState = _player(7302)
	_development.grant_opportunity(
		player, 5, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 80.0, "phase=pro_early")
	var before: float = _development.seasonal_granted_total(player, 5)

	_development.spend_general_ap(
		player, AttributeKey.Key.SPEED, 5, 5, DevelopmentExecutor.Value.MANUAL)
	player.point_ledger.debit(
		5, AttributePointSource.Value.DECLINE, DevelopmentExecutor.Value.MANUAL,
		3.0, player.balance_version, AttributeKey.Key.SPEED, "natural decline")

	assert_float(_development.seasonal_granted_total(player, 5))\
		.is_equal_approx(before, 0.0001)


## §9.2's at-cap conversion refunds progress the player already earned and could
## not spend. Counting it as seasonal availability would let a career sitting on
## its caps manufacture guardrail headroom out of its own stranded progress.
func test_the_at_cap_conversion_is_not_seasonal_availability() -> void:
	var player: PlayerDevelopmentState = _player(7303)
	_development.grant_opportunity(
		player, 6, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 40.0, "phase=pro_early")
	player.point_ledger.grant(
		6, AttributePointSource.Value.AT_CAP_CONVERSION,
		DevelopmentExecutor.Value.MANUAL, 25.0, player.balance_version, "converted")

	assert_float(_development.seasonal_granted_total(player, 6))\
		.is_equal_approx(40.0, 0.0001)
	assert_float(player.point_ledger.balance()).is_equal_approx(65.0, 0.0001)


## The index is rebuilt from the entries it is handed, so a duplicated ledger
## reports the same seasonal totals as the original.
func test_the_seasonal_index_survives_ledger_duplication() -> void:
	var player: PlayerDevelopmentState = _player(7304)
	_development.grant_opportunity(
		player, 8, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 70.0, "phase=pro_early")
	_development.grant_opportunity(
		player, 9, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 15.0, "training")

	var copy: AttributePointLedger = player.point_ledger.duplicate_ledger()

	assert_float(copy.granted_in_year(8)).is_equal_approx(70.0, 0.0001)
	assert_float(copy.granted_in_year(9)).is_equal_approx(15.0, 0.0001)
	assert_float(copy.granted_in_year(10)).is_equal_approx(0.0, 0.0001)


# --- the correction cannot be counterfeited ----------------------------------


## The strongest anti-shortcut case in the suite.
##
## §9.7.2 forbids an executor to "write a rating directly" or "use a private
## cost table". Every whole rating point a career gains is one `spend` entry
## naming its attribute, and every point it loses is a decline debit naming its
## attribute — so the finished rating vector is reconstructible from the
## starting build and the ledger alone, and a direct write breaks it at once.
##
## It pins the cost table in the same pass: the AP charged for each point must
## equal what §9.1 prices that destination at, so a cheaper private table for
## the top cohort fails here even if every rating agreed.
func test_every_rating_point_is_reconstructible_from_the_ledger() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		var state: PlayerDevelopmentState = entry.final_state
		var rebuilt: Array[int] = entry.starting_values.duplicate()
		var charged: float = 0.0
		var expected: float = 0.0
		for line in state.point_ledger.entries():
			if line.attribute < 0:
				continue
			if line.source == AttributePointSource.Value.DECLINE:
				rebuilt[line.attribute] -= int(roundf(-line.amount))
				continue
			if not line.is_spend():
				continue
			# The destination is whatever the attribute stood at when the point
			# was bought, replayed in ledger order.
			expected += float(_profiles.progression.upgrade_cost_for_destination(
				rebuilt[line.attribute] + 1))
			charged += -line.amount
			rebuilt[line.attribute] += 1
		for attribute in AttributeKey.all():
			assert_int(rebuilt[attribute])\
				.is_equal(state.attributes.get_rating(attribute))
		assert_float(charged).is_greater(0.0)
		assert_float(charged).is_equal_approx(expected, 0.0001)


## §9.5 permits one generic offseason-development phase per career year, and the
## receipt is what enforces it. The cohort handed the most opportunity is
## exactly where a duplicated season would hide, so every career is checked.
func test_annual_opportunity_resolves_once_per_career_year() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		var seen: Dictionary[int, int] = {}
		for line in entry.final_state.point_ledger.entries():
			if not line.is_grant() \
					or line.source != AttributePointSource.Value.OFFSEASON:
				continue
			if seen.has(line.career_year):
				seen[line.career_year] += 1
			else:
				seen[line.career_year] = 1
		assert_int(seen.size()).is_equal(entry.seasons)
		for year: int in seen.keys():
			assert_int(seen[year]).is_equal(1)


## Every unit of the rare-generational uplift arrives through a named source
## carrying a note. §9.7.2 requires provenance "for NPCs exactly as for the
## user", and unledgered AP is the shortest path to a §8.4 band that means
## nothing.
func test_the_generational_uplift_carries_ledger_provenance() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		var uplift: float = 0.0
		for line in entry.final_state.point_ledger.entries():
			if not line.is_grant():
				continue
			assert_bool(AttributePointSource.is_valid(line.source)).is_true()
			assert_bool(DevelopmentExecutor.is_valid(line.executor)).is_true()
			assert_bool(line.balance_version.is_empty()).is_false()
			assert_int(line.career_year).is_greater(0)
			if line.source == AttributePointSource.Value.OFFSEASON:
				continue
			assert_bool(line.note.is_empty()).is_false()
			uplift += line.amount
		assert_float(uplift).is_greater(0.0)


## The outcome label may shift opportunity; it may never reach a rating any
## other way. Only the three §9.5 seasonal sources appear on a career, so an
## authored event or an unattributed top-up smuggled in behind the label fails.
func test_the_outcome_label_grants_ratings_through_no_other_channel() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		for line in entry.final_state.point_ledger.entries():
			if not line.is_grant():
				continue
			assert_bool(
				line.source == AttributePointSource.Value.OFFSEASON
				or line.source == AttributePointSource.Value.GAME
				or line.source == AttributePointSource.Value.TRAINING).is_true()


## Opportunity that was granted must be opportunity the wallet actually saw.
## Granted minus everything removed is the balance, and any leak — a rating
## bought from currency that was never granted, or a grant that never reached
## the wallet — breaks the identity.
func test_the_wallet_reconciles_with_the_ledger() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		var ledger: AttributePointLedger = entry.final_state.point_ledger
		var net: float = ledger.total_granted() - ledger.total_spent()
		assert_float(net).is_equal_approx(ledger.balance(), 0.001)


## §9.7.2: no executor may exceed a cap, however much opportunity it is handed.
func test_the_generational_cohort_never_exceeds_a_cap() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		for attribute in AttributeKey.all():
			assert_int(entry.peak_values[attribute])\
				.is_less_equal(entry.starting_caps.cap_for(attribute))


# --- the §8.4 bands ----------------------------------------------------------


## The band the correction exists to reach.
func test_the_generational_cohort_reaches_its_locked_band() -> void:
	var band: CalibrationBand = CalibrationTargets.career_peak_overall(
		CalibrationTargets.CareerOutcome.GENERATIONAL)
	var median: float = _median_peak(CareerSimulator.Path.GENERATIONAL)
	assert_float(median).is_greater_equal(band.minimum)
	assert_float(median).is_less_equal(band.maximum)


## §8.4: "96+ ... must simply not occur through any ordinary path." The cohort
## with the most opportunity in the model is where it would occur first.
func test_the_generational_cohort_does_not_reach_ninety_six() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		assert_int(entry.peak_overall).is_less_equal(95)


## The neighbouring cohorts must not be carried up with the corrected one. A
## change that lifted every well-managed career would pass the case above and
## fail here, which is the point of having both.
func test_the_adjacent_cohorts_stay_inside_their_own_bands() -> void:
	var exceptional: CalibrationBand = CalibrationTargets.career_peak_overall(
		CalibrationTargets.CareerOutcome.EXCEPTIONAL)
	var exceptional_median: float = _median_peak(CareerSimulator.Path.EXCEPTIONAL)
	assert_float(exceptional_median).is_greater_equal(exceptional.minimum)
	assert_float(exceptional_median).is_less_equal(exceptional.maximum)

	var ordinary: CalibrationBand = CalibrationTargets.career_peak_overall(
		CalibrationTargets.CareerOutcome.ORDINARY)
	var ordinary_median: float = _median_peak(CareerSimulator.Path.ORDINARY)
	assert_float(ordinary_median).is_greater_equal(ordinary.minimum)
	assert_float(ordinary_median).is_less_equal(ordinary.maximum)


## Nothing below the top cohort may reach the generational band. §8.4 separates
## its bands on purpose, and a correction that widened the exceptional cohort
## into 92-95 would have relabelled rather than corrected.
func test_no_ordinary_career_reaches_the_generational_band() -> void:
	var floor_value: float = CalibrationTargets.career_peak_overall(
		CalibrationTargets.CareerOutcome.GENERATIONAL).minimum
	for entry: CareerSimulator.CareerResult in _cohort(CareerSimulator.Path.ORDINARY):
		assert_float(float(entry.peak_overall)).is_less(floor_value)


## §9.7.1: detail level changes how the contract is executed, never what it
## produces. The three executors receive identical opportunity under identical
## rules, so on one seed they must produce one career.
func test_every_executor_produces_the_same_generational_career() -> void:
	var simulator := CareerSimulator.new(_profiles)
	for offset in range(4):
		var seed_value: int = 740000 + offset
		var manual: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		var full: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR,
			CareerSimulator.Path.GENERATIONAL)
		var aggregate: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.AGGREGATE,
			CareerSimulator.Path.GENERATIONAL)
		assert_int(full.peak_overall).is_equal(manual.peak_overall)
		assert_int(aggregate.peak_overall).is_equal(manual.peak_overall)
		assert_float(full.total_ap_granted)\
			.is_equal_approx(manual.total_ap_granted, 0.0001)


## The diagnostic path override exists so the two-percent tail can be measured
## at every seed rather than at one seed in fifty. That is only sound if a
## forced career is the career the population would itself have produced, so the
## property is tested rather than assumed.
func test_the_forced_path_override_reproduces_the_natural_career() -> void:
	var simulator := CareerSimulator.new(_profiles)
	var checked: int = 0
	for offset in range(400):
		var seed_value: int = 750000 + offset
		var natural: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL)
		if natural.path != CareerSimulator.Path.GENERATIONAL:
			continue
		checked += 1
		var forced: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		assert_int(forced.peak_overall).is_equal(natural.peak_overall)
		assert_int(forced.maximum_potential).is_equal(natural.maximum_potential)
		assert_float(forced.total_ap_granted)\
			.is_equal_approx(natural.total_ap_granted, 0.0001)
	assert_int(checked).is_greater(0)


## Determinism: the corrected model reproduces exactly from the seed.
func test_the_corrected_cohort_is_deterministic() -> void:
	var first := CareerSimulator.new(_profiles)
	var second := CareerSimulator.new(_profiles)
	for offset in range(4):
		var seed_value: int = 760000 + offset
		var left: CareerSimulator.CareerResult = first.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		var right: CareerSimulator.CareerResult = second.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		assert_int(right.peak_overall).is_equal(left.peak_overall)
		assert_int(right.peak_age).is_equal(left.peak_age)
		assert_int(right.maximum_potential).is_equal(left.maximum_potential)
		assert_float(right.total_ap_granted)\
			.is_equal_approx(left.total_ap_granted, 0.0001)


## §6.3 is a protected passing system and this correction must leave it alone.
## The projection reads creation-time inputs only, so recomputing it from the
## build a rare-generational career started with must reproduce the range that
## career was shown — no realized outcome, and no outcome *label*, may reach it.
func test_the_outcome_label_never_reaches_the_projected_peak() -> void:
	for entry: CareerSimulator.CareerResult in _cohort(
			CareerSimulator.Path.GENERATIONAL):
		var recomputed: OverallRange = ProjectedPeakCalculator.project(
			PlayerAttributes.from_values(entry.starting_values),
			entry.starting_caps, entry.prospect, BuilderService.FRESHMAN_AGE,
			_profiles.ratings, _profiles.progression)
		assert_int(recomputed.low).is_equal(entry.projected_peak_low)
		assert_int(recomputed.high).is_equal(entry.projected_peak_high)
		# §6.3 rule 4 ordering survives the correction at the top of the range.
		assert_int(entry.projected_peak_high).is_less_equal(entry.maximum_potential)
		assert_int(entry.projected_peak_low).is_greater_equal(entry.starting_overall)
