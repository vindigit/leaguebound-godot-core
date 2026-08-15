class_name TestEventStatReconciliation
extends GdUnitTestSuite


func test_box_score_points_reconcile_to_final_score() -> void:
	var input := MatchFixtureFactory.standard_match()
	var output := MatchEngine.new().simulate_match(input, SeededRandomSource.new(91))
	assert_int(output.final_result.statistics.team_line(input.home.team_id).points).is_equal(output.final_result.home_score)
	assert_int(output.final_result.statistics.team_line(input.away.team_id).points).is_equal(output.final_result.away_score)
	assert_int(output.final_result.final_event_sequence).is_equal(output.events.size())
