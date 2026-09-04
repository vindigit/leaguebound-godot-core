class_name TestApAccounting
extends GdUnitTestSuite

## Attribute Point accounting (`BALANCE_SPEC.md` §9.1, §9.2, §9.7.2, §10.3).
##
## `CareerResult.total_ap_spent` used to hold the number of whole rating points
## a career gained, which is not Attribute Points and is not close to them. §9.1
## prices a point by its destination — 1 AP below 60, rising to 12 AP at 95 and
## above — so the two quantities diverge further the higher a career climbs. A
## rare-generational career gains about 970 rating points and spends about 2,880
## AP buying them, so every figure taken from the old field understated lifetime
## spending by roughly two thirds.
##
## The correction renames the count to `total_rating_points_gained` and takes
## the real figure from the shared ledger, which recorded each §9.1 cost as the
## cost table charged it. These cases pin both halves: that the two quantities
## are genuinely different, and that the ledger is the only place either is
## calculated.

var _profiles: BalanceProfileSet
var _builder: BuilderService
var _development: DevelopmentService


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_builder = BuilderService.new(_profiles)
	_development = DevelopmentService.new(_profiles)


func _player(seed_value: int) -> PlayerDevelopmentState:
	var family: int = PositionFamily.Value.WING
	var source: RandomSource = SeededRandomSource.new(seed_value)
	var state: BuilderState = _builder.begin_build(
		family, ProspectProfile.Value.BALANCED, MaturityProfile.Value.AVERAGE,
		_builder.default_body_for_family(family), source)
	state.fill_remaining_anywhere()
	return _builder.confirm(
		state, &"player", seed_value, SeededRandomSource.new(seed_value))


## Raise one attribute to an exact starting point so a spend's price is known
## before it is charged, and lift the caps out of the way so the case measures
## the cost table rather than the player's own ceiling.
func _seed_rating(state: PlayerDevelopmentState, attribute: int, rating: int) -> void:
	state.caps = AttributeCaps.new()
	state.attributes.set_rating(attribute, rating)


# --- rating points are not Attribute Points ----------------------------------


## The claim the old field silently denied. Two careers that gain the same
## number of rating points spend different amounts of AP when those points land
## in different §9.1 bands, so a point count cannot stand in for a cost.
func test_equal_rating_gains_cost_more_at_higher_destinations() -> void:
	var cheap: PlayerDevelopmentState = _player(9101)
	var expensive: PlayerDevelopmentState = _player(9101)
	var attribute: int = AttributeKey.Key.FREE_THROW
	_seed_rating(cheap, attribute, 50)
	_seed_rating(expensive, attribute, 90)
	_development.grant_opportunity(
		cheap, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 500.0, "budget")
	_development.grant_opportunity(
		expensive, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 500.0, "budget")

	var cheap_points: int = _development.spend_general_ap(
		cheap, attribute, 5, 1, DevelopmentExecutor.Value.MANUAL)
	var expensive_points: int = _development.spend_general_ap(
		expensive, attribute, 5, 1, DevelopmentExecutor.Value.MANUAL)

	# The same five points in both careers.
	assert_int(cheap_points).is_equal(5)
	assert_int(expensive_points).is_equal(5)
	# 51..55 at 1 AP each; 91..94 at 8 AP and 95 at 12.
	assert_float(cheap.point_ledger.total_attribute_spend())\
		.is_equal_approx(5.0, 0.0001)
	assert_float(expensive.point_ledger.total_attribute_spend())\
		.is_equal_approx(44.0, 0.0001)
	assert_float(expensive.point_ledger.total_attribute_spend())\
		.is_greater(cheap.point_ledger.total_attribute_spend())


## The ledger's total must be the §9.1 cost table's own arithmetic, not an
## approximation of it.
func test_reported_ap_spent_equals_the_cost_table_for_those_destinations() -> void:
	var state: PlayerDevelopmentState = _player(9102)
	var attribute: int = AttributeKey.Key.MID_RANGE
	_seed_rating(state, attribute, 68)
	_development.grant_opportunity(
		state, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 500.0, "budget")

	_development.spend_general_ap(
		state, attribute, 14, 1, DevelopmentExecutor.Value.MANUAL)

	var reached: int = state.attributes.get_rating(attribute)
	var expected: int = AttributeCostTable.cost_to_raise(68, reached, _profiles.progression)
	assert_float(state.point_ledger.total_attribute_spend())\
		.is_equal_approx(float(expected), 0.0001)


## And it must equal the sum of the ledger's own spend entries, so nothing is
## being accumulated beside the ledger where it could drift.
func test_reported_ap_spent_equals_the_ledgers_own_debits() -> void:
	var state: PlayerDevelopmentState = _player(9103)
	_development.grant_opportunity(
		state, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 400.0, "budget")
	AttributeAllocator.allocate(
		state, 1, DevelopmentContext.new(0.35, 0.5, CareerPhase.Value.HIGH_SCHOOL),
		_development)

	var scanned: float = 0.0
	for entry in state.point_ledger.entries():
		if entry.is_attribute_spend():
			scanned += -entry.amount

	assert_float(scanned).is_greater(0.0)
	assert_float(state.point_ledger.total_attribute_spend())\
		.is_equal_approx(scanned, 0.0001)


## A ledger rebuilt from stored entries must report what the live one did, or a
## promoted or reloaded career would disagree with the one that produced it.
func test_the_spend_total_survives_ledger_duplication() -> void:
	var state: PlayerDevelopmentState = _player(9104)
	_development.grant_opportunity(
		state, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 200.0, "budget")
	_development.spend_general_ap(
		state, AttributeKey.Key.PASSING, 9, 1, DevelopmentExecutor.Value.MANUAL)

	var copy: AttributePointLedger = state.point_ledger.duplicate_ledger()

	assert_float(copy.total_attribute_spend())\
		.is_equal_approx(state.point_ledger.total_attribute_spend(), 0.0001)
	assert_float(copy.total_attribute_spend()).is_greater(0.0)


# --- what is and is not attribute spending ------------------------------------


## §10.3 decline removes standing without buying anything, so it must not be
## counted as AP the career spent on ratings. Counting it would make a declining
## career look like a spending one.
func test_decline_is_not_counted_as_attribute_spending() -> void:
	var state: PlayerDevelopmentState = _player(9105)
	_development.grant_opportunity(
		state, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 100.0, "budget")
	_development.spend_general_ap(
		state, AttributeKey.Key.SPEED, 4, 1, DevelopmentExecutor.Value.MANUAL)
	var spent: float = state.point_ledger.total_attribute_spend()

	state.point_ledger.debit(
		1, AttributePointSource.Value.DECLINE, DevelopmentExecutor.Value.MANUAL,
		6.0, state.balance_version, AttributeKey.Key.SPEED, "natural decline")

	assert_float(state.point_ledger.total_attribute_spend())\
		.is_equal_approx(spent, 0.0001)
	assert_float(state.point_ledger.total_debits_without_purchase())\
		.is_equal_approx(6.0, 0.0001)


## Opportunity a career never realized leaves the wallet without naming an
## attribute, and is likewise not spending.
func test_unrealized_opportunity_is_not_counted_as_attribute_spending() -> void:
	var state: PlayerDevelopmentState = _player(9106)
	_development.grant_opportunity(
		state, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 80.0, "phase=high_school")

	state.point_ledger.debit(
		1, AttributePointSource.Value.GAME, DevelopmentExecutor.Value.MANUAL,
		20.0, state.balance_version, -1, "unrealized opportunity")

	assert_float(state.point_ledger.total_attribute_spend())\
		.is_equal_approx(0.0, 0.0001)
	assert_float(state.point_ledger.balance()).is_equal_approx(60.0, 0.0001)


## The identity that ties the three together. Anything that entered or left the
## wallet without an entry to account for it breaks this.
func test_granted_minus_spent_minus_other_debits_equals_the_balance() -> void:
	var state: PlayerDevelopmentState = _player(9107)
	_development.grant_opportunity(
		state, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.MANUAL, 150.0, "phase=high_school")
	_development.grant_game_development(
		state, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.MANUAL, 30.0, "games")
	AttributeAllocator.allocate(
		state, 1, DevelopmentContext.new(0.35, 0.5, CareerPhase.Value.HIGH_SCHOOL),
		_development)
	state.point_ledger.debit(
		1, AttributePointSource.Value.DECLINE, DevelopmentExecutor.Value.MANUAL,
		3.0, state.balance_version, AttributeKey.Key.SPEED, "natural decline")

	var ledger: AttributePointLedger = state.point_ledger
	var residual: float = (ledger.total_granted()
		- ledger.total_attribute_spend()
		- ledger.total_debits_without_purchase()
		- ledger.balance())

	assert_float(residual).is_equal_approx(0.0, 0.0001)
	assert_float(ledger.total_attribute_spend()).is_greater(0.0)


# --- the career-level figures -------------------------------------------------


## The two quantities must both be reported and must not be equal, because a
## career that spent as many AP as it gained rating points would mean §9.1's
## escalating cost table had stopped escalating.
func test_a_career_reports_ap_spent_and_rating_points_separately() -> void:
	var simulator := CareerSimulator.new(_profiles)
	var career: CareerSimulator.CareerResult = simulator.simulate(
		920001, DevelopmentExecutor.Value.MANUAL, CareerSimulator.Path.GENERATIONAL)

	assert_int(career.total_rating_points_gained).is_greater(0)
	assert_float(career.total_ap_spent).is_greater(0.0)
	# Every point above 59 costs more than one AP and a career crosses that
	# early, so the AP figure must exceed the point count by a wide margin.
	assert_float(career.total_ap_spent)\
		.is_greater(float(career.total_rating_points_gained) * 2.0)


## And the career-level identity must close on every outcome path, not only on
## the one the correction was measured against.
##
## The distinction this pins was a real defect: `total_ap_granted` is the
## opportunity a career *realized*, and a path that realizes less than the
## season offered books the shortfall as a debit because the ledger will not
## accept a negative grant. Stating the identity on the realized figure closed
## for the rare-generational path, whose adjustment is always positive, and
## failed for 88% of the population. It has to be stated on the ledger's own
## grant total.
func test_every_outcome_path_reconciles_its_ledger() -> void:
	var simulator := CareerSimulator.new(_profiles)
	for path in range(CareerSimulator.PATH_COUNT):
		for offset in range(3):
			var career: CareerSimulator.CareerResult = simulator.simulate(
				920100 + offset, DevelopmentExecutor.Value.MANUAL, path)
			var residual: float = (career.total_ap_granted_by_ledger
				- career.total_ap_spent
				- career.total_ap_debited_without_purchase
				- career.total_ap_unspent)
			assert_float(residual)\
				.override_failure_message("path %s did not reconcile"
					% CareerSimulator.path_id(path))\
				.is_equal_approx(0.0, 0.001)


## The two grant figures are genuinely different for a path that leaves
## opportunity unrealized, so the case above is not two names for one number.
func test_realized_and_ledger_grants_differ_when_opportunity_is_unrealized() -> void:
	var simulator := CareerSimulator.new(_profiles)
	var career: CareerSimulator.CareerResult = simulator.simulate(
		920300, DevelopmentExecutor.Value.MANUAL, CareerSimulator.Path.POOR)

	assert_float(career.total_ap_granted_by_ledger)\
		.is_greater(career.total_ap_granted)


## §9.7.1: detail level changes how the contract is executed, never what it
## produces. The corrected AP figure is part of what it produces, so the three
## executors must agree on it as exactly as they agree on the ratings.
func test_every_executor_reports_the_same_ap_accounting() -> void:
	var simulator := CareerSimulator.new(_profiles)
	for offset in range(3):
		var seed_value: int = 920200 + offset
		var manual: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		for executor: int in [
				DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR,
				DevelopmentExecutor.Value.AGGREGATE]:
			var other: CareerSimulator.CareerResult = simulator.simulate(
				seed_value, executor, CareerSimulator.Path.GENERATIONAL)
			assert_float(other.total_ap_granted)\
				.is_equal_approx(manual.total_ap_granted, 0.0001)
			assert_float(other.total_ap_spent)\
				.is_equal_approx(manual.total_ap_spent, 0.0001)
			assert_float(other.total_ap_unspent)\
				.is_equal_approx(manual.total_ap_unspent, 0.0001)
			assert_int(other.total_rating_points_gained)\
				.is_equal(manual.total_rating_points_gained)


# --- pooling across shards ----------------------------------------------------


## A mean pools from its raw terms, not from shard estimates. The corrected AP
## quantities are reported as means, so a deep run that averaged three shard
## averages of unequal size would report a number that is not the mean of
## anything — the defect the aggregator exists to prevent.
func test_the_corrected_ap_means_pool_exactly_across_shards() -> void:
	var left := PackedFloat64Array([2900.0, 3100.0, 3000.0])
	var right := PackedFloat64Array([2500.0, 2700.0])
	var pooled := PackedFloat64Array()
	pooled.append_array(left)
	pooled.append_array(right)

	var aggregation: MetricAggregation = MetricAggregation.mean_of(left)
	aggregation.combine(MetricAggregation.mean_of(right))

	assert_float(aggregation.estimate())\
		.is_equal_approx(CalibrationStatistics.mean(pooled), 0.0001)
	# The naive shard-average would be 2,733.3 against a true mean of 2,840.
	assert_float(aggregation.estimate()).is_not_equal(
		(CalibrationStatistics.mean(left) + CalibrationStatistics.mean(right)) / 2.0)


## The reconciliation metric is a proportion, so it pools as a ratio of counts
## and a single failing career anywhere in a sharded run survives pooling.
func test_a_reconciliation_failure_survives_shard_pooling() -> void:
	var clean: MetricAggregation = MetricAggregation.proportion(0, 400)
	var dirty: MetricAggregation = MetricAggregation.proportion(1, 400)
	clean.combine(dirty)

	assert_float(clean.estimate()).is_greater(0.0)
	assert_float(clean.estimate()).is_equal_approx(1.0 / 800.0, 0.000001)
