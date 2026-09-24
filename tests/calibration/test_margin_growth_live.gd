class_name TestMarginGrowthLive
extends GdUnitTestSuite


func after_test() -> void:
	ShotResolver.detach_probe()


func test_observer_preserves_seed_and_real_ledgers_close_with_coverage() -> void:
	var coverage: Dictionary = {}
	for scenario in GoldenScenarios.names():
		var input: MatchInput = GoldenScenarios.input_for(scenario)
		var audit := MarginGrowthAudit.new()
		audit.attach()
		var observed: MatchSimulationOutput = MatchSession.new(input,
			SeededRandomSource.new(GoldenScenarios.seed_for(scenario))).run_to_completion()
		audit.detach()
		var plain: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		assert_str(observed.signature()).is_equal(plain.signature())
		var row: Dictionary = audit.measure(input, observed)
		assert_array(Array(row["errors"] as PackedStringArray)).is_empty()
		for key: String in row["coverage"]:
			coverage[key] = (coverage.get(key, 0) as int) + (row["coverage"][key] as int)
		var period_margin: int = 0
		for segment: Dictionary in row["periods"]:
			period_margin += (segment["margin"] as int)
		assert_int(period_margin).is_equal(observed.final_result.home_score - observed.final_result.away_score)
	assert_array(Array(MarginGrowthAudit.coverage_errors(coverage))).is_empty()
