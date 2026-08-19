class_name TestGuardrailException
extends GdUnitTestSuite

## The §9.5 elite-opportunity guardrail exception (owner ruling, 2026-08).
##
## The ruling: *rare-generational careers may exceed the §9.5 high-engagement
## upper guardrail by up to 20% when caused by ledgered elite opportunity, while
## emitting the required balance warning. The exception applies only to the
## rare-generational path and cannot alter AP costs, game-development caps,
## population shares, or adjacent outcome bands.*
##
## An exception is only as good as its edges, so every edge is a case here:
##
##   - **The ceiling.** 20% is permitted; more is a violation. Removing the
##     ceiling makes `test_an_excess_beyond_the_permitted_share_is_a_violation`
##     fail.
##   - **The scope.** The permission attaches to a named career condition, not
##     to an outcome label, so a career without the condition that exceeds its
##     guardrails is a violation whatever cohort it belongs to. Granting the
##     condition to another path makes `test_only_the_generational_path_carries
##     _the_condition` fail.
##   - **The evidence.** §9.5 requires the source ledger to explain an
##     exceptional season, and the ruling does not relax that. An unexplained
##     season is a violation even inside the 20%.
##   - **What it may not touch.** Costs, §9.6 caps, and population shares are
##     pinned so the exception cannot quietly become a discount.
##
## The bound is stated on the career against the sum of its own seasonal
## guardrails, which is the quantity the ruling was made on: Stage 4 measured
## 16.5% there and the owner set the ceiling at 20% of the same sum.

const SEED_BASE: int = 940000

var _profiles: BalanceProfileSet
var _builder: BuilderService
var _development: DevelopmentService


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_builder = BuilderService.new(_profiles)
	_development = DevelopmentService.new(_profiles)


func _player(seed_value: int, condition: int) -> PlayerDevelopmentState:
	var family: int = PositionFamily.Value.WING
	var source: RandomSource = SeededRandomSource.new(seed_value)
	var state: BuilderState = _builder.begin_build(
		family, ProspectProfile.Value.BALANCED, MaturityProfile.Value.AVERAGE,
		_builder.default_body_for_family(family), source)
	state.fill_remaining_anywhere()
	var confirmed: PlayerDevelopmentState = _builder.confirm(
		state, &"player", seed_value, SeededRandomSource.new(seed_value))
	confirmed.opportunity_condition = condition
	return confirmed


# --- the ceiling --------------------------------------------------------------


## The ruling's number, pinned. If it moves, the documentation in
## `BALANCE_SPEC.md` §9.5 and `PROJECT_STATUS.md` §5.8 is wrong and this fails
## rather than letting the two drift apart.
func test_the_permitted_share_is_twenty_percent() -> void:
	assert_float(_profiles.progression.elite_opportunity_guardrail_allowance)\
		.is_equal_approx(0.20, 0.000001)


## Inside the ceiling, with the condition, is permitted.
func test_an_excess_inside_the_permitted_share_is_allowed() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 1, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	# 19% above the summed guardrails.
	var violation: String = _development.career_opportunity_violation(
		state, 1190.0, 1000.0, 0)

	assert_str(violation).is_empty()


## Exactly at the ceiling is permitted: the ruling says "up to 20%".
func test_an_excess_exactly_at_the_permitted_share_is_allowed() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 2, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	assert_str(_development.career_opportunity_violation(
		state, 1200.0, 1000.0, 0)).is_empty()


## Beyond it is not. Removing the ceiling makes this pass a career the ruling
## forbids, which is the mutation this case exists for.
func test_an_excess_beyond_the_permitted_share_is_a_violation() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 3, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	var violation: String = _development.career_opportunity_violation(
		state, 1201.0, 1000.0, 0)

	assert_str(violation).is_not_empty()
	assert_str(violation).contains("exceeded the permitted")


# --- the scope ----------------------------------------------------------------


## The permission attaches to the condition, not to an outcome label. A career
## without it may not exceed its guardrails at all, so the exception cannot be
## claimed by another path simply by being given more opportunity.
func test_a_career_without_the_condition_may_not_exceed_at_all() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 4, CareerOpportunityCondition.Value.ORDINARY)

	var violation: String = _development.career_opportunity_violation(
		state, 1010.0, 1000.0, 0)

	assert_str(violation).is_not_empty()
	assert_str(violation).contains("only the elite-opportunity condition")


## And staying inside them is fine for such a career, so the case above is about
## the excess rather than about the condition being required for anything.
func test_a_career_without_the_condition_inside_its_guardrails_is_fine() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 5, CareerOpportunityCondition.Value.ORDINARY)

	assert_str(_development.career_opportunity_violation(
		state, 950.0, 1000.0, 0)).is_empty()


## The condition is a career fact, not a per-season flag, and §9.7.4 requires a
## promoted player to be the same player. A duplicated state must carry it, or
## promotion would silently change what the career is permitted to receive.
func test_the_condition_is_persistent_and_survives_duplication() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 6, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	var copy: PlayerDevelopmentState = state.duplicate_state()

	assert_int(copy.opportunity_condition)\
		.is_equal(CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)
	assert_str(copy.invariant_signature()).is_equal(state.invariant_signature())
	assert_str(state.invariant_signature()).contains("condition=elite_opportunity")


## A career that differs only in this condition is a different career, so the
## §9.7.4 invariant signature has to say so. Otherwise the permission could be
## added or removed by promotion without anything noticing.
func test_the_condition_is_part_of_the_invariant_signature() -> void:
	var ordinary: PlayerDevelopmentState = _player(
		SEED_BASE + 7, CareerOpportunityCondition.Value.ORDINARY)
	var elite: PlayerDevelopmentState = _player(
		SEED_BASE + 7, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	assert_str(elite.invariant_signature())\
		.is_not_equal(ordinary.invariant_signature())


# --- the evidence -------------------------------------------------------------


## §9.5 requires the ledger to explain an exceptional season and the ruling does
## not relax it. An unexplained season is a violation even well inside the 20%.
func test_an_unexplained_season_is_a_violation_inside_the_share() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 8, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	var violation: String = _development.career_opportunity_violation(
		state, 1050.0, 1000.0, 1)

	assert_str(violation).is_not_empty()
	assert_str(violation).contains("no source-ledger explanation")


## Even a career that never exceeded anything is in violation if it recorded an
## unexplained exceptional season, because the two are separate requirements.
func test_an_unexplained_season_is_a_violation_without_any_excess() -> void:
	var state: PlayerDevelopmentState = _player(
		SEED_BASE + 9, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	assert_str(_development.career_opportunity_violation(
		state, 900.0, 1000.0, 2)).is_not_empty()


# --- what the exception may not touch -----------------------------------------


## The exception is a permission, never a discount. A career carrying it pays
## the same §9.1 price for the same point as one that does not.
func test_the_exception_changes_no_attribute_point_cost() -> void:
	var elite: PlayerDevelopmentState = _player(
		SEED_BASE + 10, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)
	var ordinary: PlayerDevelopmentState = _player(
		SEED_BASE + 10, CareerOpportunityCondition.Value.ORDINARY)
	var attribute: int = AttributeKey.Key.PASSING
	for state: PlayerDevelopmentState in [elite, ordinary]:
		_development.grant_opportunity(
			state, 1, AttributePointSource.Value.TRAINING,
			DevelopmentExecutor.Value.MANUAL, 300.0, "budget")
		_development.spend_general_ap(
			state, attribute, 8, 1, DevelopmentExecutor.Value.MANUAL)

	assert_float(elite.point_ledger.total_attribute_spend())\
		.is_equal_approx(ordinary.point_ledger.total_attribute_spend(), 0.0001)
	assert_int(elite.attributes.get_rating(attribute))\
		.is_equal(ordinary.attributes.get_rating(attribute))


## And it does not lift the §9.6 seasonal game-development cap, which bounds a
## source rather than a season and is not what the ruling addresses.
func test_the_exception_does_not_lift_the_game_development_cap() -> void:
	var elite: PlayerDevelopmentState = _player(
		SEED_BASE + 11, CareerOpportunityCondition.Value.ELITE_OPPORTUNITY)

	_development.grant_game_development(
		elite, 1, CareerPhase.Value.PRO_PRIME,
		DevelopmentExecutor.Value.MANUAL, 500.0, "an enormous season")

	assert_float(elite.point_ledger.granted_from(1, AttributePointSource.Value.GAME))\
		.is_equal_approx(20.0, 0.0001)


## Population shares are not the exception's business either. §8.4's cohort
## sizes are fixed and the ruling explicitly may not move them.
func test_the_population_shares_are_unchanged() -> void:
	var shares: PackedFloat64Array = CareerSimulator.PATH_SHARES
	assert_float(shares[CareerSimulator.Path.GENERATIONAL])\
		.is_equal_approx(0.02, 0.000001)
	var total: float = 0.0
	for share: float in shares:
		total += share
	assert_float(total).is_equal_approx(1.0, 0.000001)


# --- the cohort in practice ---------------------------------------------------


## Only the rare-generational path carries the condition. Granting it to
## another path makes this fail, which is the scope mutation.
func test_only_the_generational_path_carries_the_condition() -> void:
	var simulator := CareerSimulator.new(_profiles)
	simulator.capture_diagnostics = true
	for path in range(CareerSimulator.PATH_COUNT):
		var career: CareerSimulator.CareerResult = simulator.simulate(
			SEED_BASE + 20, DevelopmentExecutor.Value.MANUAL, path)
		var expected: int = (
			CareerOpportunityCondition.Value.ELITE_OPPORTUNITY
			if path == CareerSimulator.Path.GENERATIONAL
			else CareerOpportunityCondition.Value.ORDINARY)
		assert_int(career.final_state.opportunity_condition)\
			.override_failure_message("path %s carries the wrong condition"
				% CareerSimulator.path_id(path))\
			.is_equal(expected)


## No career of any path may end in violation of the ruling. This is the
## end-to-end form: it fails if the cohort drifts past 20%, if the condition
## stops being set, or if an exceptional season loses its explanation.
func test_no_career_violates_the_ruling() -> void:
	var simulator := CareerSimulator.new(_profiles)
	for path in range(CareerSimulator.PATH_COUNT):
		for offset in range(6):
			var career: CareerSimulator.CareerResult = simulator.simulate(
				SEED_BASE + 100 + offset, DevelopmentExecutor.Value.MANUAL, path)
			assert_str(career.opportunity_violation)\
				.override_failure_message("path %s seed %d: %s" % [
					CareerSimulator.path_id(path), career.seed_value,
					career.opportunity_violation])\
				.is_empty()


## The generational cohort genuinely uses the exception, so the case above is
## not vacuously satisfied by a cohort that never approaches the guardrails.
func test_the_generational_cohort_actually_uses_the_exception() -> void:
	var simulator := CareerSimulator.new(_profiles)
	var used: int = 0
	var maximum: float = -1.0
	for offset in range(8):
		var career: CareerSimulator.CareerResult = simulator.simulate(
			SEED_BASE + 200 + offset, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		maximum = maxf(maximum, career.guardrail_overage_share)
		if career.guardrail_overage_share > 0.0:
			used += 1
		assert_int(career.guardrail_seasons).is_greater(0)
	assert_int(used).is_equal(8)
	# Inside the ruling, and far enough above zero that the exception is doing
	# real work rather than absorbing rounding.
	assert_float(maximum).is_greater(0.10)
	assert_float(maximum).is_less_equal(0.20)


## Every exceptional season still raises the §9.5 balance warning. The ruling
## permits the excess; it does not make it silent.
func test_the_exception_does_not_silence_the_seasonal_warning() -> void:
	var simulator := CareerSimulator.new(_profiles)
	var career: CareerSimulator.CareerResult = simulator.simulate(
		SEED_BASE + 300, DevelopmentExecutor.Value.MANUAL,
		CareerSimulator.Path.GENERATIONAL)

	assert_int(career.guardrail_seasons).is_greater(0)
	assert_int(career.guardrail_unexplained_seasons).is_equal(0)
	assert_float(career.guardrail_excess).is_greater(0.0)
