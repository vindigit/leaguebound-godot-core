class_name TestMatchInvariants
extends GdUnitTestSuite


func test_match_events_are_contiguous_and_terminal_result_is_not_tied() -> void:
	var output := MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(),
		SeededRandomSource.new(20260814)
	)
	for index in range(output.events.size()):
		assert_int(output.events[index].sequence).is_equal(index + 1)
	assert_bool(output.final_result.home_score != output.final_result.away_score).is_true()
