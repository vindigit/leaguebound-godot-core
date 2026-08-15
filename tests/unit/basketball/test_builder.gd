class_name TestBuilder
extends GdUnitTestSuite

## Builder suite (`GODOT_TDD.md` §13.2, `BALANCE_SPEC.md` §7.1/§7.3, Gate B1).

var _profiles: BalanceProfileSet
var _service: BuilderService
var _query: DevelopmentProjectionQuery


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_service = BuilderService.new(_profiles)
	_query = DevelopmentProjectionQuery.new(_profiles)


func _begin(prospect: int = ProspectProfile.Value.BALANCED, seed_value: int = 99) -> BuilderState:
	var family: int = PositionFamily.Value.WING
	return _service.begin_build(
		family,
		prospect,
		MaturityProfile.Value.AVERAGE,
		_service.default_body_for_family(family),
		SeededRandomSource.new(seed_value)
	)


func _complete(state: BuilderState) -> void:
	state.fill_remaining_anywhere()


## Gate B0 / `GODOT_TDD.md` §5.6: every tuneable has a name, unit, safe range,
## and version, and sits inside its declared range.
func test_balance_profiles_validate() -> void:
	assert_array(_profiles.validate()).is_empty()
	for tunable in _profiles.describe_tunables():
		assert_bool(tunable.tunable_name.is_empty()).is_false()
		assert_bool(tunable.unit.is_empty()).is_false()
		assert_bool(tunable.is_inside_safe_range()).is_true()


## §7.1, OD-B, PRD BUILD-006: confirmation is blocked while any creation AP
## remains.
func test_confirmation_is_blocked_while_creation_ap_remains() -> void:
	var state: BuilderState = _begin()
	assert_int(state.remaining()).is_greater(0)
	assert_bool(state.can_confirm()).is_false()
	assert_array(state.confirmation_failures()).is_not_empty()

	_complete(state)
	assert_int(state.remaining()).is_equal(0)
	assert_bool(state.can_confirm()).is_true()


## §7.1 / §28: creation AP never enters the career wallet, in any form.
func test_creation_ap_cannot_carry_into_the_career() -> void:
	var state: BuilderState = _begin()
	_complete(state)
	var confirmed: PlayerDevelopmentState = _service.confirm(
		state, &"user", 4242, SeededRandomSource.new(4242))

	assert_float(confirmed.point_ledger.balance()).is_equal(0.0)
	assert_float(confirmed.point_ledger.total_granted()).is_equal(0.0)
	assert_int(confirmed.point_ledger.entry_count()).is_equal(0)
	# The final spend record survives as history, not as currency.
	assert_int(confirmed.creation_budget.spent).is_equal(confirmed.creation_budget.granted)
	assert_int(confirmed.creation_budget.remaining()).is_equal(0)


## The ledger refuses a creation-sourced grant outright, so there is no code
## path by which creation currency becomes career currency.
func test_the_career_ledger_rejects_creation_sourced_grants() -> void:
	var ledger: AttributePointLedger = AttributePointLedger.new()
	await assert_error(func() -> void:
		ledger.grant(
			1, AttributePointSource.Value.CREATION,
			DevelopmentExecutor.Value.MANUAL, 50.0, "test")
	).is_runtime_error(
		"Assertion failed: creation Attribute Points can never enter the career wallet"
		+ " (§7.1, §28)")
	assert_float(ledger.balance()).is_equal(0.0)


## §7.1: whole-point allocation, universal bands, increasing costs. The spend
## recorded must reconcile exactly with the cost of the allocation.
func test_allocation_spend_reconciles_with_the_cost_table() -> void:
	var state: BuilderState = _begin()
	_complete(state)
	var bases: Array[int] = state.bases()
	var values: Array[int] = state.values()
	var expected: int = 0
	for attribute in AttributeKey.all():
		expected += AttributeCostTable.cost_to_raise(
			bases[attribute], values[attribute], _profiles.progression)
	assert_int(state.spent()).is_equal(expected)


## §9.1 worked examples, quoted directly from the specification.
func test_cost_table_reproduces_the_documented_examples() -> void:
	var progression: ProgressionProfile = _profiles.progression
	assert_int(AttributeCostTable.cost_to_raise(58, 60, progression)).is_equal(3)
	assert_int(AttributeCostTable.cost_to_raise(69, 70, progression)).is_equal(3)
	assert_int(AttributeCostTable.cost_to_raise(79, 80, progression)).is_equal(5)
	assert_int(AttributeCostTable.cost_to_raise(94, 95, progression)).is_equal(12)
	assert_int(AttributeCostTable.cost_to_raise(90, 99, progression)).is_equal(92)


## §7.1: the absolute starting maximum is in force during creation, and §7.3.3
## constraint 3 forbids calibration from relaxing it.
func test_the_absolute_starting_maximum_is_enforced() -> void:
	var state: BuilderState = _begin(ProspectProfile.Value.READY_NOW)
	var target: int = AttributeKey.Key.THREE_POINT
	while state.raise_attribute(target):
		pass
	assert_int(state.rating_for(target))\
		.is_less_equal(_profiles.builder.starting_absolute_maximum)


## §9.1: "Caps are checked before currency is consumed."
func test_allocation_never_exceeds_an_exact_cap() -> void:
	var state: BuilderState = _begin()
	_complete(state)
	for attribute in AttributeKey.all():
		assert_int(state.rating_for(attribute))\
			.is_less_equal(state.caps.cap_for(attribute))


## §8.1: caps are drawn deterministically from the career seed. Same seed, same
## caps; different seed, different caps.
func test_cap_generation_is_deterministic() -> void:
	var first: BuilderState = _begin(ProspectProfile.Value.BALANCED, 777)
	var second: BuilderState = _begin(ProspectProfile.Value.BALANCED, 777)
	assert_str(first.caps.signature()).is_equal(second.caps.signature())

	var different: BuilderState = _begin(ProspectProfile.Value.BALANCED, 778)
	assert_str(different.caps.signature()).is_not_equal(first.caps.signature())


## §8: every cap lies between 40 and 99.
func test_caps_stay_inside_their_domain() -> void:
	for prospect in ProspectProfile.all():
		for seed_value in range(20):
			var state: BuilderState = _begin(prospect, 1000 + seed_value)
			for cap in state.caps.values():
				assert_int(cap).is_greater_equal(ProgressionProfile.CAP_MINIMUM)
				assert_int(cap).is_less_equal(ProgressionProfile.CAP_MAXIMUM)


## §7.1: body redistributes at most 18 total rating points, is approximately
## zero-sum, and no single attribute moves more than four points.
func test_body_redistribution_stays_inside_its_bounds() -> void:
	var builder: BuilderProfile = _profiles.builder
	for family in PositionFamily.all():
		var height_bounds: Array[int] = BuilderRules.height_bounds_for_family(family, builder)
		for height in range(height_bounds[0], height_bounds[1] + 1):
			var weight_bounds: Array[int] = BuilderRules.weight_bounds_for_height(
				height, builder)
			var wingspan_bounds: Array[int] = BuilderRules.wingspan_bounds_for_height(
				height, builder)
			for weight: int in [weight_bounds[0], weight_bounds[1]]:
				for wingspan: int in [wingspan_bounds[0], wingspan_bounds[1]]:
					var body: BodyProfile = BodyProfile.new(height, weight, wingspan, 0)
					var modifiers: Array[int] = BuilderRules.body_redistribution(
						body, family, builder)
					var total: int = 0
					var absolute: int = 0
					for modifier in modifiers:
						total += modifier
						absolute += absi(modifier)
						assert_int(absi(modifier))\
							.is_less_equal(builder.body_redistribution_single_maximum)
					assert_int(absi(total))\
						.is_less_equal(BuilderRules.ZERO_SUM_TOLERANCE)
					assert_int(absolute)\
						.is_less_equal(builder.body_redistribution_total)


## §7.3.2: the confirmation screen reports all three development values, all
## exact caps, the projected adult range, and the archetype — and does not label
## a legal build as bad.
func test_confirmation_view_reports_every_required_value() -> void:
	var state: BuilderState = _begin()
	_complete(state)
	var view: BuilderConfirmationView = _query.builder_confirmation_view(state)

	assert_int(view.projection.current_overall).is_greater(0)
	assert_int(view.projection.maximum_potential)\
		.is_greater_equal(view.projection.current_overall)
	assert_bool(view.projection.projected_peak is OverallRange).is_true()
	assert_array(view.caps.values()).has_size(AttributeKey.COUNT)
	assert_bool(view.archetype.label().is_empty()).is_false()
	assert_bool(view.can_confirm).is_true()
	assert_array(view.blocking_failures).is_empty()
	assert_array(view.development_value_rows()).has_size(3)


## §7.4.2: the projected adult range is bounded, and the freshman body sits
## below its adult minimum on the skeletal dimensions — the player still has
## growing to do.
func test_projected_adult_range_is_bounded_and_forward_looking() -> void:
	var state: BuilderState = _begin()
	var range_model: BodyRange = state.projected_range
	assert_int(range_model.height_minimum).is_greater(state.body.height_inches)
	assert_int(range_model.height_maximum).is_greater(range_model.height_minimum)
	assert_int(range_model.standing_reach_minimum).is_greater(0)


## §7.1: the empty pre-allocation state is a preview only and cannot be
## confirmed. It must never be cited as the Builder's minimum outcome.
func test_the_empty_preview_is_not_a_completed_build() -> void:
	var state: BuilderState = _begin()
	assert_bool(state.can_confirm()).is_false()
	var view: BuilderConfirmationView = _query.builder_confirmation_view(state)
	assert_bool(view.can_confirm).is_false()
	assert_array(view.blocking_failures).is_not_empty()


## Reset returns the Builder to its opening state without leaving currency
## behind.
func test_reset_restores_the_full_budget() -> void:
	var state: BuilderState = _begin()
	var granted: int = state.budget.granted
	state.raise_attribute(AttributeKey.Key.HANDLE)
	state.raise_attribute(AttributeKey.Key.SPEED)
	assert_int(state.remaining()).is_less(granted)
	state.reset()
	assert_int(state.remaining()).is_equal(granted)
	assert_int(state.spent()).is_equal(0)


## Randomization is deterministic from the injected source
## (`GODOT_TDD.md` §5.2) and produces a confirmable build.
func test_randomization_is_deterministic_and_confirmable() -> void:
	var first: BuilderState = _begin(ProspectProfile.Value.HIGH_UPSIDE, 555)
	first.randomize_allocation(SeededRandomSource.new(31337))
	var second: BuilderState = _begin(ProspectProfile.Value.HIGH_UPSIDE, 555)
	second.randomize_allocation(SeededRandomSource.new(31337))

	assert_array(first.values()).is_equal(second.values())
	assert_bool(first.can_confirm()).is_true()


## §7.2: prospect profiles receive different creation budgets, and Ready Now
## receives the largest.
func test_prospect_profiles_receive_distinct_budgets() -> void:
	var builder: BuilderProfile = _profiles.builder
	var ready: int = builder.creation_budget_for(ProspectProfile.Value.READY_NOW)
	var balanced: int = builder.creation_budget_for(ProspectProfile.Value.BALANCED)
	var upside: int = builder.creation_budget_for(ProspectProfile.Value.HIGH_UPSIDE)
	assert_int(ready).is_greater(balanced)
	assert_int(balanced).is_greater(upside)


## §7.3.2: completed builds land in the locked band for their prospect profile.
## The exhaustive sweep lives in `tools/builder_calibration_harness.gd`; this is
## the regression guard that keeps the tuned values honest in CI.
func test_completed_builds_land_in_their_locked_bands() -> void:
	var band_low: Array[int] = [48, 46, 44]
	var band_high: Array[int] = [52, 50, 48]
	for prospect in ProspectProfile.all():
		for seed_value in range(12):
			var state: BuilderState = _begin(prospect, 2000 + seed_value)
			state.spend_remaining_weighted(_conventional_weights())
			state.fill_remaining_anywhere()
			assert_bool(state.can_confirm()).is_true()

			var overall: int = OverallCalculator.current_overall(
				state.attributes(), _profiles.ratings)
			assert_int(overall).is_greater_equal(band_low[prospect])
			assert_int(overall).is_less_equal(band_high[prospect])


## §7.3.2: no ordinary completed build exceeds approximately 54 current OVR.
func test_no_ordinary_completed_build_exceeds_the_ceiling() -> void:
	for prospect in ProspectProfile.all():
		for seed_value in range(12):
			var state: BuilderState = _begin(prospect, 3000 + seed_value)
			state.spend_remaining_weighted(_conventional_weights())
			state.fill_remaining_anywhere()
			assert_int(OverallCalculator.current_overall(
				state.attributes(), _profiles.ratings)).is_less_equal(54)


func _conventional_weights() -> Array[float]:
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(0.25)
	for attribute: int in CapGenerator.FAMILY_PRIMARY[PositionFamily.Value.WING]:
		weights[attribute] = 1.0
	for attribute: int in CapGenerator.FAMILY_SECONDARY[PositionFamily.Value.WING]:
		weights[attribute] = 0.7
	return weights
