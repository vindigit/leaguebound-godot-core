class_name TestDevelopmentContract
extends GdUnitTestSuite

## Development parity, detail-promotion invariance, and receipt suites
## (`GODOT_TDD.md` §13.2, `BALANCE_SPEC.md` §9.7, OD-E; Gate B3).

var _profiles: BalanceProfileSet
var _builder: BuilderService
var _development: DevelopmentService


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_builder = BuilderService.new(_profiles)
	_development = DevelopmentService.new(_profiles)


func _player(seed_value: int, detail_level: int = SimulationDetailLevel.Value.FULL
		) -> PlayerDevelopmentState:
	var family: int = PositionFamily.Value.WING
	var source: RandomSource = SeededRandomSource.new(seed_value)
	var state: BuilderState = _builder.begin_build(
		family, ProspectProfile.Value.BALANCED, MaturityProfile.Value.AVERAGE,
		_builder.default_body_for_family(family), source)
	state.fill_remaining_anywhere()
	var confirmed: PlayerDevelopmentState = _builder.confirm(
		state, &"player", seed_value, SeededRandomSource.new(seed_value))
	confirmed.detail_level = detail_level
	return confirmed


func _context() -> DevelopmentContext:
	return DevelopmentContext.new(0.35, 0.5, CareerPhase.Value.HIGH_SCHOOL)


## §9.7.2: every executor is bound by the same universal cost table. The same
## grant must buy the same number of points for the user and for an NPC.
func test_user_and_npc_pay_the_same_costs() -> void:
	var user: PlayerDevelopmentState = _player(1001)
	var npc: PlayerDevelopmentState = _player(1001)

	_development.grant_opportunity(
		user, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, 60.0)
	_development.grant_opportunity(
		npc, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR, 60.0)

	var target: int = AttributeKey.Key.THREE_POINT
	var user_points: int = _development.spend_general_ap(
		user, target, 12, 1, DevelopmentExecutor.Value.MANUAL)
	var npc_points: int = _development.spend_general_ap(
		npc, target, 12, 1, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)

	assert_int(npc_points).is_equal(user_points)
	assert_float(npc.point_ledger.balance()).is_equal(user.point_ledger.balance())
	assert_int(npc.attributes.get_rating(target))\
		.is_equal(user.attributes.get_rating(target))


## §9.7.2: "The full-detail allocator receives AP-equivalent opportunity, not
## finished ratings. It is not permitted to... spend currency it was not
## granted." An allocator given nothing must change nothing.
func test_the_allocator_cannot_spend_currency_it_was_not_granted() -> void:
	var npc: PlayerDevelopmentState = _player(1002)
	var before: String = npc.attributes.signature()

	var applied: int = AttributeAllocator.allocate(npc, 1, _context(), _development)

	assert_int(applied).is_equal(0)
	assert_str(npc.attributes.signature()).is_equal(before)
	assert_float(npc.point_ledger.balance()).is_equal(0.0)


## §9.7.2: the allocator may never exceed a cap.
func test_the_allocator_never_exceeds_a_cap() -> void:
	var npc: PlayerDevelopmentState = _player(1003)
	_development.grant_opportunity(
		npc, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR, 5000.0)

	AttributeAllocator.allocate(npc, 1, _context(), _development)

	for attribute in AttributeKey.all():
		assert_int(npc.attributes.get_rating(attribute))\
			.is_less_equal(npc.caps.cap_for(attribute))


## §9.7.2: every AP-equivalent unit granted or spent records its source, career
## year, executor, and balance version — "for NPCs exactly as for the user".
func test_every_ledger_entry_names_its_source_and_executor() -> void:
	var npc: PlayerDevelopmentState = _player(1004)
	_development.grant_opportunity(
		npc, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR, 80.0)
	AttributeAllocator.allocate(npc, 1, _context(), _development)

	assert_int(npc.point_ledger.entry_count()).is_greater(1)
	for entry in npc.point_ledger.entries():
		assert_int(entry.career_year).is_greater(0)
		assert_bool(AttributePointSource.is_valid(entry.source)).is_true()
		assert_bool(DevelopmentExecutor.is_valid(entry.executor)).is_true()
		assert_bool(entry.balance_version.is_empty()).is_false()


## §9.7.4 / §28: "Changing a player's simulation detail level must not change
## the player." Ratings, caps, body, maturity state, accumulated development,
## and committed history must match exactly for the same seed.
func test_detail_promotion_is_invariant() -> void:
	for seed_value in range(8):
		var full: PlayerDevelopmentState = _player(
			2000 + seed_value, SimulationDetailLevel.Value.FULL)
		var reduced: PlayerDevelopmentState = _player(
			2000 + seed_value, SimulationDetailLevel.Value.REDUCED)

		assert_str(reduced.invariant_signature()).is_equal(full.invariant_signature())

		# Promote the reduced-detail player. Promotion adds evidence resolution;
		# it must not touch state.
		var before: String = reduced.invariant_signature()
		reduced.detail_level = SimulationDetailLevel.Value.FULL
		assert_str(reduced.invariant_signature()).is_equal(before)


## §9.7.3: an aggregate executor must respect caps, cost bands, and the source
## ledger, and must leave real history for promotion to inherit.
func test_the_aggregate_executor_respects_caps_costs_and_the_ledger() -> void:
	var npc: PlayerDevelopmentState = _player(3001, SimulationDetailLevel.Value.REDUCED)
	_development.grant_opportunity(
		npc, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.AGGREGATE, 120.0)

	var applied: int = AggregateDevelopmentExecutor.resolve_season(
		npc, 1, _context(), _development)

	assert_int(applied).is_greater(0)
	for attribute in AttributeKey.all():
		assert_int(npc.attributes.get_rating(attribute))\
			.is_less_equal(npc.caps.cap_for(attribute))

	var aggregate_entries: Array[AttributePointEntry] = npc.point_ledger.entries_for_executor(
		DevelopmentExecutor.Value.AGGREGATE)
	assert_array(aggregate_entries).is_not_empty()


## §9.7.3: the aggregate executor must produce results comparable to the
## full-detail allocator at equivalent inputs. The statistical test is report
## 16; this is the structural guard that the two paths do not diverge grossly.
func test_aggregate_and_full_detail_spend_comparably() -> void:
	var grant: float = 140.0
	var full: PlayerDevelopmentState = _player(3100)
	var aggregate: PlayerDevelopmentState = _player(3100)

	_development.grant_opportunity(
		full, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR, grant)
	_development.grant_opportunity(
		aggregate, 1, AttributePointSource.Value.OFFSEASON,
		DevelopmentExecutor.Value.AGGREGATE, grant)

	AttributeAllocator.allocate(full, 1, _context(), _development)
	AggregateDevelopmentExecutor.resolve_season(aggregate, 1, _context(), _development)

	# Neither path may bank opportunity the other spends.
	assert_float(full.point_ledger.balance()).is_less(1.0)
	assert_float(aggregate.point_ledger.balance()).is_less(1.0)

	var full_overall: int = OverallCalculator.current_overall(full.attributes, _profiles.ratings)
	var aggregate_overall: int = OverallCalculator.current_overall(
		aggregate.attributes, _profiles.ratings)
	assert_int(absi(full_overall - aggregate_overall)).is_less_equal(2)


## §9.5: one career year permits at most one generic offseason-development
## phase. A second entry cannot rerun it.
func test_receipts_prevent_duplicate_annual_development() -> void:
	var player: PlayerDevelopmentState = _player(4001)
	var first: float = _development.grant_seasonal_opportunity(
		player, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.MANUAL, SeededRandomSource.new(11))
	assert_float(first).is_greater(0.0)

	var second: float = _development.grant_seasonal_opportunity(
		player, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.MANUAL, SeededRandomSource.new(11))
	assert_float(second).is_equal(0.0)

	assert_int(player.point_ledger.grant_count_from(
		1, AttributePointSource.Value.OFFSEASON)).is_equal(1)


## §9.5: the receipt is shared across executors, so an aggregate resolution and
## a full-detail resolution cannot both run for the same career year.
func test_receipts_are_shared_across_executors() -> void:
	var player: PlayerDevelopmentState = _player(4002)
	_development.grant_seasonal_opportunity(
		player, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.AGGREGATE, SeededRandomSource.new(12))
	var second: float = _development.grant_seasonal_opportunity(
		player, 1, CareerPhase.Value.HIGH_SCHOOL,
		DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR, SeededRandomSource.new(12))
	assert_float(second).is_equal(0.0)


## §9.5: one age increase per career year.
func test_age_advances_once_per_career_year() -> void:
	var player: PlayerDevelopmentState = _player(4003)
	var age: int = player.age
	assert_bool(_development.advance_age(player, 1)).is_true()
	assert_int(player.age).is_equal(age + 1)
	assert_bool(_development.advance_age(player, 1)).is_false()
	assert_int(player.age).is_equal(age + 1)


## §10.2: natural development or decline resolves once at the shared career-year
## milestone. "There is no invisible weekly erosion."
func test_natural_annual_resolution_runs_once() -> void:
	var player: PlayerDevelopmentState = _player(4004)
	player.age = 35
	assert_bool(_development.resolve_natural_annual(
		player, 5, DevelopmentExecutor.Value.MANUAL)).is_true()
	var after_first: String = player.attributes.signature()
	assert_bool(_development.resolve_natural_annual(
		player, 5, DevelopmentExecutor.Value.MANUAL)).is_false()
	assert_str(player.attributes.signature()).is_equal(after_first)


## §8.3: "A potential-cap reduction by itself never lowers the current rating."
func test_a_cap_reduction_never_lowers_the_current_rating() -> void:
	var player: PlayerDevelopmentState = _player(5001)
	var target: int = AttributeKey.Key.HANDLE
	var current: int = player.attributes.get_rating(target)

	player.caps = player.caps.with_cap(target, ProgressionProfile.CAP_MINIMUM)
	assert_int(player.attributes.get_rating(target)).is_equal(current)
	# Further growth is blocked while current ability is above the cap.
	assert_bool(player.caps.has_room(target, current)).is_false()


## §9.2: direct progress fills the current upgrade cost, resolves whole points,
## and carries surplus into the next eligible point.
func test_direct_progress_resolves_points_and_carries_surplus() -> void:
	var player: PlayerDevelopmentState = _player(6001)
	var target: int = AttributeKey.Key.PASSING
	# Pin the rating well inside the 1 AP band so the arithmetic is unambiguous:
	# §9.1 charges 1 AP per point up to destination 59, then 2 AP from 60.
	var start: int = 50
	player.attributes.set_rating(target, start)
	player.caps = player.caps.with_cap(target, 90)

	var gained: int = _development.apply_direct_progress(
		player, target, 3.5, 1, DevelopmentExecutor.Value.MANUAL)

	assert_int(gained).is_equal(3)
	assert_int(player.attributes.get_rating(target)).is_equal(start + 3)
	# The surplus carries; it is not discarded and not rounded away.
	assert_float(player.progress.units_for(target)).is_equal_approx(0.5, 0.0001)


## §9.1 charges by destination rating, so crossing a band boundary changes what
## the same direct progress buys. Pinned at 59, 3.5 units buys exactly one point
## because destination 60 costs 2 AP.
func test_direct_progress_respects_the_cost_band_boundary() -> void:
	var player: PlayerDevelopmentState = _player(6003)
	var target: int = AttributeKey.Key.PASSING
	player.attributes.set_rating(target, 59)
	player.caps = player.caps.with_cap(target, 90)

	var gained: int = _development.apply_direct_progress(
		player, target, 3.5, 1, DevelopmentExecutor.Value.MANUAL)

	assert_int(gained).is_equal(1)
	assert_int(player.attributes.get_rating(target)).is_equal(60)
	assert_float(player.progress.units_for(target)).is_equal_approx(1.5, 0.0001)


## §9.2: at cap, unresolved direct progress converts to general AP at 50%
## efficiency, "rounded down only at the end of the event".
func test_direct_progress_converts_at_cap() -> void:
	var player: PlayerDevelopmentState = _player(6002)
	var target: int = AttributeKey.Key.VISION
	player.caps = player.caps.with_cap(target, player.attributes.get_rating(target))

	var before: float = player.point_ledger.balance()
	var gained: int = _development.apply_direct_progress(
		player, target, 9.0, 1, DevelopmentExecutor.Value.MANUAL)

	assert_int(gained).is_equal(0)
	assert_float(player.progress.units_for(target)).is_equal(0.0)
	assert_float(player.point_ledger.balance()).is_equal(before + 4.0)
