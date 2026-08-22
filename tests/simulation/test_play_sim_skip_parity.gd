class_name TestPlaySimSkipParity
extends GdUnitTestSuite

## `SIMULATION_SPEC.md` §23 and §27.5: Play, Sim, and Skip use the same
## authoritative outcome path.
##
## §2.1: "Manual play does not switch to separate shot, fatigue, or statistical
## rules." Parity here is structural rather than statistical — every mode drives
## one `MatchSession`, and each possession derives its random stream from the
## match identity and possession sequence rather than from the caller's
## consumption order. Stepping and running therefore produce the identical
## ledger, byte for byte.

const SEED: int = 20260815

## The seed at which `MatchFixtureFactory.even_match()` finishes regulation level
## and plays overtime — the same fixture and seed the `overtime` golden scenario
## pins, so this suite and the ledger exercise one agreed overtime game.
const OVERTIME_SEED: int = 190056


## Stepping possession by possession produces exactly the ledger a full Sim
## produces.
func test_stepped_play_matches_full_simulation() -> void:
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))

	var session := MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))
	session.open()
	var steps: int = 0
	while not session.is_complete():
		session.advance_possession()
		steps += 1
	var played: MatchSimulationOutput = session.build_output()

	assert_int(steps).is_greater(0)
	assert_str(played.signature()).is_equal(simulated.signature())
	assert_str(MatchLedgerSerializer.hash_output(played)).is_equal(
		MatchLedgerSerializer.hash_output(simulated))


## Skip-to-final-result matches a full Sim.
func test_skip_to_final_matches_full_simulation() -> void:
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))
	var session := MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))
	var skipped: MatchSimulationOutput = session.skip_to_final_result()
	assert_str(skipped.signature()).is_equal(simulated.signature())


## The same three executors, on a game that goes to overtime.
##
## Every other case in this suite plays a game that ends in regulation, which
## left the whole of the overtime path untested for parity. A mutation found it:
## a Skip that drives the session itself and stops at the end of regulation
## instead of delegating to `run_to_completion` produced identical output on
## every fixture here and survived. It is not an equivalent mutation — it
## changes the result of any game that reaches overtime — the suite simply never
## played one.
##
## The fixture and seed are the `overtime` golden scenario's, so the ledger and
## this suite agree on which overtime game is the reference, and the assertion
## checks that overtime actually happened rather than trusting the seed to keep
## producing it.
func test_all_three_executors_agree_on_a_game_that_reaches_overtime() -> void:
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.even_match(), SeededRandomSource.new(OVERTIME_SEED))
	assert_int(simulated.final_result.overtime_periods).override_failure_message(
		"the overtime fixture no longer reaches overtime, so this test is not "
		+ "exercising the path it exists for"
	).is_greater(0)

	var stepping := MatchSession.new(
		MatchFixtureFactory.even_match(), SeededRandomSource.new(OVERTIME_SEED))
	stepping.open()
	while not stepping.is_complete():
		stepping.advance_possession()
	var played: MatchSimulationOutput = stepping.build_output()

	var skipping := MatchSession.new(
		MatchFixtureFactory.even_match(), SeededRandomSource.new(OVERTIME_SEED))
	var skipped: MatchSimulationOutput = skipping.skip_to_final_result()

	assert_int(played.final_result.overtime_periods).is_equal(
		simulated.final_result.overtime_periods)
	assert_int(skipped.final_result.overtime_periods).override_failure_message(
		"Skip returned a result with fewer overtime periods than Sim, so it is "
		+ "not driving the same session to the same end"
	).is_equal(simulated.final_result.overtime_periods)
	assert_str(played.signature()).is_equal(simulated.signature())
	assert_str(skipped.signature()).is_equal(simulated.signature())
	assert_str(MatchLedgerSerializer.hash_output(skipped)).is_equal(
		MatchLedgerSerializer.hash_output(simulated))


## Skip-to-next-appearance stops at a real appearance and then finishes to the
## same result. §23.4: skipping "does not reduce rewards or apply a skip
## penalty" — the result is identical, not merely similar.
func test_skip_to_appearance_then_finish_matches_full_simulation() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var bench_id: StringName = input.home.players[6].player_id

	var session := MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))
	var appeared: bool = session.skip_until_on_court(bench_id)
	if appeared and not session.is_complete():
		assert_bool(session.snapshot().home.is_on_court(bench_id)).is_true()
	var finished: MatchSimulationOutput = session.run_to_completion()

	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))
	assert_str(finished.signature()).is_equal(simulated.signature())


## An interrupted session resumes without rerolling: §23.5 forbids a resume
## from re-rolling an opportunity or duplicating a result.
func test_resuming_a_partial_session_does_not_reroll() -> void:
	var first := MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(SEED))
	first.open()
	for index in range(5):
		first.advance_possession()
	var partial_events: Array[MatchDomainEvent] = first.events()
	var completed: MatchSimulationOutput = first.run_to_completion()

	# The first five possessions in the completed ledger are the ones the
	# partial session had already committed.
	for index in range(partial_events.size()):
		assert_str(completed.events[index].signature()).is_equal(
			partial_events[index].signature())


## The free-throw contract is shared: the manual path resolves through the same
## probability, and a valid perfect release is the documented guarantee rather
## than a different rule set (§12.4, §13.2).
func test_manual_and_automatic_free_throws_share_one_contract() -> void:
	var input: MatchInput = MatchFixtureFactory.quick_match()
	var snapshot := MatchSnapshot.new(input)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var body := BodyEffects.new(input.balance_profile)
	var matchups: MatchupState = MatchupResolver.new(capability, body).resolve(
		input.home, snapshot.home, input.away, snapshot.away)
	var context := PossessionContext.new(input, snapshot, input.home.team_id, matchups, 1)
	var shooter_id: StringName = context.offense_on_court()[0]
	var resolver := FreeThrowResolver.new(capability, input.balance_profile)

	# A valid perfect release is a guaranteed make.
	assert_bool(resolver.resolve_manual(
		context, shooter_id, true, 0.0, SeededRandomSource.new(1))).is_true()

	# Neutral manual timing resolves at the same probability the automatic path
	# uses, so neither mode is easier.
	var probability: float = resolver.probability(context, shooter_id)
	var automatic: int = 0
	var manual: int = 0
	for index in range(400):
		if resolver.resolve(context, shooter_id, SeededRandomSource.new(index + 1)):
			automatic += 1
		if resolver.resolve_manual(
			context, shooter_id, false, 0.5, SeededRandomSource.new(index + 1)
		):
			manual += 1
	assert_int(manual).is_equal(automatic)
	assert_float(probability).is_between(0.0, 1.0)
