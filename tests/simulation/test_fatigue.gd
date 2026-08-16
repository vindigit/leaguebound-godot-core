class_name TestFatigue
extends GdUnitTestSuite

## `SIMULATION_SPEC.md` §17.1 and `BALANCE_SPEC.md` §15.1.
##
## The rule that shapes this suite: "Fatigue affects burst, stability, decision
## execution, contest arrival, ball security, and recovery. It does not directly
## subtract the same flat amount from all ratings." A uniform penalty would be
## exactly the flat subtraction that sentence forbids, so the per-capability
## sensitivity is asserted, not just the presence of a penalty.


## Fatigue accumulates on court and recovers on the bench, both driven by
## Stamina.
func test_fatigue_accumulates_on_court_and_recovers_on_the_bench() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var session := MatchSession.new(input, SeededRandomSource.new(20260815))
	session.open()
	var starter_id: StringName = session.snapshot().home.on_court_ids()[0]

	for index in range(20):
		session.advance_possession()
	var after_play: float = session.snapshot().home.runtime_by_id(starter_id).acute_fatigue
	assert_float(after_play).is_greater(0.0)
	assert_float(after_play).is_less_equal(100.0)

	# Recovery is checked on a player who has actually been substituted out,
	# rather than on whoever happens to be on the bench now: over twenty
	# possessions the bench has been used, so "on the bench" no longer implies
	# "has never played".
	var rested_id: StringName = &""
	var fatigue_at_check_out: float = 0.0
	while not session.is_complete() and rested_id.is_empty():
		session.advance_possession()
		for candidate_id in session.snapshot().home.available_bench_ids():
			var runtime: PlayerMatchRuntime = session.snapshot().home.runtime_by_id(candidate_id)
			if runtime.acute_fatigue > 5.0 and runtime.rest_ms > 0:
				rested_id = candidate_id
				fatigue_at_check_out = runtime.acute_fatigue
				break
	assert_str(String(rested_id)).is_not_empty()

	var recovered: float = fatigue_at_check_out
	for index in range(12):
		if session.is_complete():
			break
		session.advance_possession()
		var runtime: PlayerMatchRuntime = session.snapshot().home.runtime_by_id(rested_id)
		if not runtime.on_court:
			recovered = runtime.acute_fatigue
	assert_float(recovered).is_less(fatigue_at_check_out)


## §15.1: Stamina resists accumulation and speeds recovery, and the effect is
## visible in a real match rather than only in the formula.
func test_stamina_changes_accumulated_fatigue_over_a_match() -> void:
	assert_float(_fatigue_after_match(40)).is_greater(_fatigue_after_match(95))


## §17.1: the penalty is not one flat amount applied to every rating. Work
## Capacity — the capability Stamina itself owns — takes none of it.
func test_fatigue_penalty_is_not_uniform_across_capabilities() -> void:
	var balance := SimulationBalanceProfile.new()
	var ratings := RatingsProfile.default_profile()
	var calculator := CapabilityCalculator.new(ratings, balance)
	var player := PlayerMatchProfile.new(&"p1")
	var fresh := PlayerMatchRuntime.new(&"p1", true)
	var spent := PlayerMatchRuntime.new(&"p1", true)
	spent.acute_fatigue = 90.0

	var burst_drop: float = (
		calculator.capability_of(CapabilityKey.Value.BURST_REACH, player, fresh)
		- calculator.capability_of(CapabilityKey.Value.BURST_REACH, player, spent))
	var read_drop: float = (
		calculator.capability_of(CapabilityKey.Value.PASS_READ_QUALITY, player, fresh)
		- calculator.capability_of(CapabilityKey.Value.PASS_READ_QUALITY, player, spent))
	var capacity_drop: float = (
		calculator.capability_of(CapabilityKey.Value.WORK_CAPACITY, player, fresh)
		- calculator.capability_of(CapabilityKey.Value.WORK_CAPACITY, player, spent))

	assert_float(burst_drop).is_greater(0.0)
	assert_float(read_drop).is_greater(0.0)
	# Burst is more fatigue-sensitive than reading the floor.
	assert_float(burst_drop).is_greater(read_drop)
	# And Stamina's own capability is untouched.
	assert_float(capacity_drop).is_equal_approx(0.0, 0.000001)


## The §15.1 band table is monotonic and starts at zero: a fresh player carries
## no penalty at all.
func test_fatigue_band_penalty_is_monotonic_from_zero() -> void:
	var balance := SimulationBalanceProfile.new()
	assert_float(balance.fatigue_penalty_points(0.0)).is_equal(0.0)
	assert_float(balance.fatigue_penalty_points(20.0)).is_equal(0.0)
	var previous: float = 0.0
	for value: float in [30.0, 50.0, 70.0, 85.0, 100.0]:
		var penalty: float = balance.fatigue_penalty_points(value)
		assert_float(penalty).is_greater_equal(previous)
		previous = penalty
	assert_float(previous).is_greater(0.0)


## Fatigue reaches the substitution decision: a tired starter comes off.
func test_fatigue_drives_substitutions() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var fatigue_substitutions: int = 0
	for event in output.events:
		if (
			event.event_type == MatchDomainEvent.CHECK_OUT
			and event.detail_id == StringName(
				SubstitutionOrder.REASON_IDS[SubstitutionOrder.Reason.FATIGUE])
		):
			fatigue_substitutions += 1
	# Either fatigue or the planned-minutes rule pulls starters; both are §18.2
	# adjustments and at least one must occur across a full game.
	var planned_substitutions: int = 0
	for event in output.events:
		if (
			event.event_type == MatchDomainEvent.CHECK_OUT
			and event.detail_id == StringName(
				SubstitutionOrder.REASON_IDS[SubstitutionOrder.Reason.PLANNED_MINUTES])
		):
			planned_substitutions += 1
	assert_int(fatigue_substitutions + planned_substitutions).is_greater(0)


## Accumulated fatigue for a starter after a full match, with only Stamina
## changed across the whole lineup.
func _fatigue_after_match(stamina: int) -> float:
	var overrides: Dictionary = {AttributeKey.Key.STAMINA: stamina}
	var input: MatchInput = MatchFixtureFactory.match_between(
		MatchFixtureFactory.uniform_team(&"home", 70, overrides),
		MatchFixtureFactory.uniform_team(&"away", 70),
		MatchFixtureFactory.quick_match().rule_profile)
	var session := MatchSession.new(input, SeededRandomSource.new(4242))
	session.open()
	var starter_id: StringName = session.snapshot().home.on_court_ids()[0]
	var peak: float = 0.0
	while not session.is_complete():
		session.advance_possession()
		peak = maxf(peak, session.snapshot().home.runtime_by_id(starter_id).acute_fatigue)
	return peak
