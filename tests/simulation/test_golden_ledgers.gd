class_name TestGoldenLedgers
extends GdUnitTestSuite

## Committed golden ledgers for the six required scenarios.
##
## The Stage 3 determinism contract: "Same seed plus identical versioned input
## must reproduce the full ordered ledger and final result", with committed
## golden hashes for regulation, overtime, offensive-rebound continuation,
## foul/free-throw, substitution/foul-out, and late-game situations.
##
## A golden hash that no longer covers its scenario is worse than no golden
## hash, so each one is checked twice: the hash must match, and the reproduced
## match must still contain the behaviour the scenario is named for.

var _document: Dictionary = {}


func before() -> void:
	var file: FileAccess = FileAccess.open(GoldenScenarios.HASH_PATH, FileAccess.READ)
	assert_object(file).override_failure_message(
		"missing committed golden hashes; run tools/golden_ledger_harness.gd").is_not_null()
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_bool(parsed is Dictionary).is_true()
	_document = parsed


func test_every_required_scenario_has_a_committed_hash() -> void:
	var scenarios: Dictionary = _document["scenarios"]
	for scenario in GoldenScenarios.names():
		assert_bool(scenarios.has(String(scenario))).override_failure_message(
			"no committed golden hash for scenario %s" % scenario).is_true()
	assert_int(scenarios.size()).is_equal(GoldenScenarios.names().size())


func test_committed_hashes_reproduce_exactly() -> void:
	var scenarios: Dictionary = _document["scenarios"]
	for scenario in GoldenScenarios.names():
		var entry: Dictionary = scenarios[String(scenario)]
		var expected_hash: String = entry["hash"]
		assert_int(_entry_int(entry, "seed")).is_equal(GoldenScenarios.seed_for(scenario))
		assert_str(GoldenScenarios.hash_of(scenario)).override_failure_message(
			"golden ledger changed for scenario %s; regenerate deliberately with tools/golden_ledger_harness.gd"
			% scenario
		).is_equal(expected_hash)


## The committed shape is checked alongside the hash so a failure says what
## moved, not merely that something did.
func test_committed_shape_matches_the_reproduced_match() -> void:
	var scenarios: Dictionary = _document["scenarios"]
	for scenario in GoldenScenarios.names():
		var entry: Dictionary = scenarios[String(scenario)]
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		assert_int(output.events.size()).is_equal(_entry_int(entry, "events"))
		assert_int(output.possessions.size()).is_equal(_entry_int(entry, "possessions"))
		assert_int(output.final_result.home_score).is_equal(_entry_int(entry, "home_score"))
		assert_int(output.final_result.away_score).is_equal(_entry_int(entry, "away_score"))
		assert_int(output.final_result.overtime_periods).is_equal(
			_entry_int(entry, "overtime_periods"))


## Each scenario still exercises the behaviour it claims to cover.
func test_every_scenario_still_covers_its_behaviour() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		assert_bool(
			GoldenScenarios.meets_requirement(scenario, output)
		).override_failure_message(
			"scenario %s no longer produces %s" % [
				scenario, GoldenScenarios.describe_requirement(scenario)]
		).is_true()


## Reproduction is exact across repeated runs, not merely equal in the hash.
func test_repeated_simulation_reproduces_the_full_ledger() -> void:
	for scenario in GoldenScenarios.names():
		var first: MatchSimulationOutput = GoldenScenarios.simulate_uncached(scenario)
		var second: MatchSimulationOutput = GoldenScenarios.simulate_uncached(scenario)
		assert_int(first.events.size()).is_equal(second.events.size())
		for index in range(first.events.size()):
			assert_str(first.events[index].signature()).is_equal(
				second.events[index].signature())
		assert_str(first.signature()).is_equal(second.signature())


## A different seed produces a different ledger: the hash is tracking the
## simulation, not a constant.
func test_a_different_seed_changes_the_ledger() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var first: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(7001))
	var second: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(7002))
	assert_str(MatchLedgerSerializer.hash_output(first)).is_not_equal(
		MatchLedgerSerializer.hash_output(second))


## Canonical serialization is explicit text in a declared field order — not
## Dictionary iteration order, and not raw Variant bytes.
func test_canonical_serialization_is_explicit_and_ordered() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var serialized: String = MatchLedgerSerializer.serialize_events(output.events)
	var lines: PackedStringArray = serialized.split(MatchLedgerSerializer.RECORD_SEPARATOR)
	assert_int(lines.size()).is_equal(output.events.size())
	# Field order is the declared order, and the first two fields are the match
	# identity and the sequence number.
	var first_fields: PackedStringArray = lines[0].split("|")
	assert_str(first_fields[0]).is_equal(String(output.events[0].match_id))
	assert_str(first_fields[1]).is_equal(str(output.events[0].sequence))
	# Hashing the same text twice is stable.
	assert_str(MatchLedgerSerializer.hash_text(serialized)).is_equal(
		MatchLedgerSerializer.hash_text(serialized))


## JSON numbers decode as floats, so the committed integers are converted
## through an explicitly typed step rather than an unchecked cast.
func _entry_int(entry: Dictionary, key: String) -> int:
	var value: float = entry[key]
	return int(value)
