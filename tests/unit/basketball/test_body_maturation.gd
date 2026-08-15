class_name TestBodyMaturation
extends GdUnitTestSuite

## Body suite (`GODOT_TDD.md` §13.2, `BALANCE_SPEC.md` §7.4,
## `SIMULATION_SPEC.md` §6.3, Gate B3).

var _profiles: BalanceProfileSet
var _builder: BuilderService
var _body_service: BodyMaturationService


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_builder = BuilderService.new(_profiles)
	_body_service = BodyMaturationService.new(_profiles)


func _confirmed(
	maturity: int = MaturityProfile.Value.AVERAGE,
	seed_value: int = 4242,
) -> PlayerDevelopmentState:
	var family: int = PositionFamily.Value.WING
	var source: RandomSource = SeededRandomSource.new(seed_value)
	var state: BuilderState = _builder.begin_build(
		family, ProspectProfile.Value.BALANCED, maturity,
		_builder.default_body_for_family(family), source)
	state.fill_remaining_anywhere()
	return _builder.confirm(state, &"player", seed_value, SeededRandomSource.new(seed_value))


func _grow_fully(state: PlayerDevelopmentState, seed_value: int) -> void:
	for career_year in _body_service.milestone_career_years():
		_body_service.resolve_increment(
			state, career_year, SeededRandomSource.new(seed_value))


## §7.4.3 rule 1: growth is a function of the versioned career seed. Reloading,
## changing simulation detail, Play/Sim choice, or device cannot reroll it.
func test_growth_is_deterministic_from_the_career_seed() -> void:
	var first: PlayerDevelopmentState = _confirmed(MaturityProfile.Value.AVERAGE, 8888)
	var second: PlayerDevelopmentState = _confirmed(MaturityProfile.Value.AVERAGE, 8888)
	_grow_fully(first, 8888)
	_grow_fully(second, 8888)
	assert_str(first.body_state.signature()).is_equal(second.body_state.signature())


## §7.4.2: the realized adult body falls inside the stored projected range on
## every dimension, in every career.
func test_realized_adult_body_stays_inside_the_stored_range() -> void:
	for maturity in MaturityProfile.all():
		for seed_value in range(25):
			var state: PlayerDevelopmentState = _confirmed(maturity, 7000 + seed_value)
			_grow_fully(state, 7000 + seed_value)
			var body_state: BodyMaturationState = state.body_state
			assert_bool(body_state.is_final(BuilderProfile.TOTAL_GROWTH_MILESTONES)).is_true()
			assert_array(
				body_state.projected_range.containment_failures(body_state.realized_body)
			).is_empty()


## §6.3: growth is idempotent per career year. A second attempt on the same year
## must not resolve, and must leave the body untouched.
func test_growth_resolves_once_per_career_year() -> void:
	var state: PlayerDevelopmentState = _confirmed()
	var year: int = _body_service.milestone_career_years()[0]

	assert_bool(_body_service.resolve_increment(
		state, year, SeededRandomSource.new(4242))).is_true()
	var after_first: String = state.body_state.signature()

	assert_bool(_body_service.resolve_increment(
		state, year, SeededRandomSource.new(4242))).is_false()
	assert_str(state.body_state.signature()).is_equal(after_first)
	assert_int(state.body_state.resolved_count()).is_equal(1)


## §9.5: the shared career-year receipt is what enforces once-only, so it must
## actually be claimed.
func test_growth_claims_the_shared_career_year_receipt() -> void:
	var state: PlayerDevelopmentState = _confirmed()
	var year: int = _body_service.milestone_career_years()[0]
	assert_bool(state.receipts.has_resolved(
		year, CareerYearReceipts.Resolution.BODY_GROWTH_INCREMENT)).is_false()
	_body_service.resolve_increment(state, year, SeededRandomSource.new(4242))
	assert_bool(state.receipts.has_resolved(
		year, CareerYearReceipts.Resolution.BODY_GROWTH_INCREMENT)).is_true()


## §7.4.3 rule 4 / §28: a body increment may not alter any of the twenty public
## ratings as a side effect.
func test_growth_never_changes_a_rating() -> void:
	var state: PlayerDevelopmentState = _confirmed()
	var before: String = state.attributes.signature()
	_grow_fully(state, 4242)
	assert_str(state.attributes.signature()).is_equal(before)


## §7.4.3 rule 3: growth never invalidates a confirmed build, never re-runs
## allocation, never refunds or re-charges AP, and never changes a cap.
func test_growth_touches_neither_caps_nor_currency() -> void:
	var state: PlayerDevelopmentState = _confirmed()
	var caps_before: String = state.caps.signature()
	var ledger_before: int = state.point_ledger.entry_count()
	var budget_before: int = state.creation_budget.spent

	_grow_fully(state, 4242)

	assert_str(state.caps.signature()).is_equal(caps_before)
	assert_int(state.point_ledger.entry_count()).is_equal(ledger_before)
	assert_int(state.creation_budget.spent).is_equal(budget_before)


## `GDD.md` §6.5 / §7.4.2 report 15: Early, Average, and Late must produce
## materially different realized high-school bodies while every realization
## stays inside its stored range.
func test_timing_profiles_produce_different_high_school_bodies() -> void:
	var high_school_years: Array[int] = _body_service.milestone_career_years().slice(
		0, BuilderProfile.HIGH_SCHOOL_GROWTH_MILESTONES)
	var heights: Array[int] = []
	for maturity in MaturityProfile.all():
		var state: PlayerDevelopmentState = _confirmed(maturity, 5150)
		for year in high_school_years:
			_body_service.resolve_increment(state, year, SeededRandomSource.new(5150))
		heights.append(state.body_state.realized_body.height_inches)

	# Early delivers more growth during high school than Late.
	assert_int(heights[MaturityProfile.Value.EARLY])\
		.is_greater(heights[MaturityProfile.Value.LATE])
	assert_int(heights[MaturityProfile.Value.EARLY])\
		.is_greater_equal(heights[MaturityProfile.Value.AVERAGE])


## `GDD.md` §6.5: "Neither timing is strictly better." Total growth is identical
## across timing profiles; only the schedule differs.
func test_timing_profiles_deliver_the_same_total_growth() -> void:
	var adult_heights: Array[int] = []
	for maturity in MaturityProfile.all():
		var state: PlayerDevelopmentState = _confirmed(maturity, 5150)
		_grow_fully(state, 5150)
		adult_heights.append(state.body_state.realized_body.height_inches)
	for height in adult_heights:
		assert_int(height).is_equal(adult_heights[0])


## §7.4: weight evolution and training are modelled separately from height
## growth and stay within credible health bounds.
func test_weight_training_is_separate_and_bounded() -> void:
	var state: PlayerDevelopmentState = _confirmed()
	var height_before: int = state.body_state.realized_body.height_inches

	_body_service.apply_weight_training(state, 500)
	assert_int(state.body_state.realized_body.weight_pounds)\
		.is_less_equal(state.body_state.projected_range.weight_maximum)
	assert_int(state.body_state.realized_body.height_inches).is_equal(height_before)

	_body_service.apply_weight_training(state, -500)
	assert_int(state.body_state.realized_body.weight_pounds)\
		.is_greater_equal(state.body_state.weight_health_floor())
	assert_int(state.body_state.realized_body.height_inches).is_equal(height_before)


## §6.3 `REACH_ADULT_BODY`: once all scheduled increments resolve, no further
## increment is legal.
func test_no_increment_is_legal_after_the_body_is_final() -> void:
	var state: PlayerDevelopmentState = _confirmed()
	_grow_fully(state, 4242)
	var beyond: int = _body_service.milestone_career_years()[
		BuilderProfile.TOTAL_GROWTH_MILESTONES - 1] + 1
	assert_bool(_body_service.resolve_increment(
		state, beyond, SeededRandomSource.new(4242))).is_false()


## §7.4.4 / §5.7: a migration that cannot recover a stored projected range
## reconstructs the widest consistent range and records the limitation — it
## never narrows around the realized value to fabricate precision.
func test_lost_projected_range_is_reconstructed_at_its_widest() -> void:
	var record: Dictionary = {
		"schema_version": 1,
		"realized_body": {
			"height_inches": 78,
			"weight_pounds": 210,
			"wingspan_inches": 81,
		},
	}
	var result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(record)
	assert_bool(result.migrated).is_true()
	assert_bool(result.record.has("projected_adult_range")).is_true()
	assert_bool(result.record["projected_range_reconstructed"]).is_true()

	var projected: Dictionary = result.record["projected_adult_range"]
	var height_range: Array = projected["height"]
	var low: int = height_range[0]
	var high: int = height_range[1]
	# Wide, not narrow: the realized value sits strictly inside a real interval.
	assert_int(low).is_less(78)
	assert_int(high).is_greater(78)
	assert_int(high - low).is_greater_equal(PlayerSystemMigration.RECONSTRUCTION_HEIGHT_SLACK)

	var notes: String = ", ".join(result.notes)
	assert_str(notes).contains("reconstructed")
