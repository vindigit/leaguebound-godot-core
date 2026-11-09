class_name TestMarginGrowthAudit
extends GdUnitTestSuite


func after_test() -> void:
	ShotResolver.detach_probe()


func test_known_signed_components_are_not_only_an_identity_check() -> void:
	var h: Dictionary = MarginGrowthAudit.blank_side()
	var a: Dictionary = MarginGrowthAudit.blank_side()
	h.merge({"field_goals_attempted": 10, "field_points": 15, "expected_field_points": 9.0,
		"possessions": 8, "offensive_rebounds": 3, "turnovers": 2, "free_throws_made": 4, "points": 19}, true)
	a.merge({"field_goals_attempted": 6, "field_points": 6, "expected_field_points": 5.0,
		"possessions": 9, "offensive_rebounds": 1, "turnovers": 3, "free_throws_made": 1, "points": 7}, true)
	var segment: Dictionary = MarginGrowthAudit.finish_segment({"home": h, "away": a})
	var expected: Dictionary = {"shooting_efficiency": 4.0, "possession_imbalance": -1.25,
		"offensive_rebounds": 2.5, "turnovers": 1.25, "shot_volume_residual": 2.5, "free_throws": 3.0}
	for key: String in expected:
		assert_float((segment["components"][key] as float)).is_equal_approx((expected[key] as float), 0.000001)
	assert_float((segment["conditional_components"]["shooting_innovation"] as float)).is_equal_approx(5.0, 0.000001)
	assert_float((segment["conditional_components"]["turnovers"] as float)).is_equal_approx(13.0 / 15.0, 0.000001)
	assert_int((segment["margin"] as int)).is_equal(12)
	assert_float((segment["identity_error"] as float)).is_less(0.000001)
	assert_float((segment["conditional_identity_error"] as float)).is_less(0.000001)
	var reversed: Dictionary = MarginGrowthAudit.components(a, h, true)
	for key: String in reversed:
		assert_float((reversed[key] as float)).is_equal_approx(-(segment["conditional_components"][key] as float), 0.000001)


func test_zero_attempt_side_still_closes() -> void:
	var h: Dictionary = MarginGrowthAudit.blank_side()
	var a: Dictionary = MarginGrowthAudit.blank_side()
	h.merge({"possessions": 1, "free_throws_made": 2, "points": 2}, true)
	a.merge({"possessions": 1, "field_goals_attempted": 1, "field_points": 3, "expected_field_points": 0.6, "points": 3}, true)
	var row: Dictionary = MarginGrowthAudit.finish_segment({"home": h, "away": a})
	assert_float((row["conditional_identity_error"] as float)).is_less(0.000001)
	assert_float((row["components"]["shooting_efficiency"] as float)).is_equal_approx(-1.5, 0.000001)
	assert_float((row["components"]["shot_volume_residual"] as float)).is_equal_approx(-1.5, 0.000001)


func test_exact_late_and_normalized_period_boundaries() -> void:
	var pro: CompetitionRuleProfile = CompetitionCatalog.rules_for(CompetitionCatalog.Profile.TOP_DOMESTIC_PRO)
	var college: CompetitionRuleProfile = CompetitionCatalog.rules_for(CompetitionCatalog.Profile.COLLEGE)
	assert_str(MarginGrowthAudit.window_for(pro, 4, 120001)).is_equal("early_regulation")
	assert_str(MarginGrowthAudit.window_for(pro, 4, 120000)).is_equal("late_regulation")
	assert_str(MarginGrowthAudit.window_for(pro, 3, 120000)).is_equal("early_regulation")
	assert_str(MarginGrowthAudit.window_for(pro, 5, 240000)).is_equal("overtime")
	assert_int(MarginGrowthAudit.quarter_for(college, 1, 600000)).is_equal(0)
	assert_int(MarginGrowthAudit.quarter_for(college, 1, 599999)).is_equal(1)
	assert_int(MarginGrowthAudit.quarter_for(college, 2, 1200000, true)).is_equal(2)
	assert_int(MarginGrowthAudit.quarter_for(pro, 2, 720000, true)).is_equal(1)
	assert_int(MarginGrowthAudit.quarter_for(pro, 4, 0)).is_equal(3)
	assert_int(MarginGrowthAudit.quarter_for(pro, 5, 300000)).is_equal(-1)


func test_hand_authored_ledger_has_known_period_and_shooting_answers() -> void:
	var fixture: Dictionary = MarginGrowthFixtures.known_ledger()
	var audit: MarginGrowthAudit = MarginGrowthFixtures.observer_for(fixture)
	var row: Dictionary = audit.measure(fixture["input"] as MatchInput, fixture["output"] as MatchSimulationOutput)
	assert_array(Array(row["errors"] as PackedStringArray)).is_empty()
	assert_int((row["final"]["margin"] as int)).is_equal(-2)
	assert_int((row["pre_late_margin"] as int)).is_equal(-1)
	assert_int((row["regulation_margin"] as int)).is_equal(0)
	assert_int((row["late_margin_increment"] as int)).is_equal(1)
	assert_int((row["late_absolute_expansion"] as int)).is_equal(-1)
	var expected_periods: Array[int] = [2, -3, 0, 1, -2]
	for index in range(expected_periods.size()):
		assert_int((row["periods"][index]["margin"] as int)).is_equal(expected_periods[index])
	assert_float((row["final"]["home"]["expected_field_points"] as float)).is_equal_approx(2.35, 0.000001)
	assert_float((row["final"]["away"]["expected_field_points"] as float)).is_equal_approx(3.7, 0.000001)
	assert_float((row["final"]["conditional_components"]["shooting_innovation"] as float)).is_equal_approx(-1.65, 0.000001)
	assert_float((row["final"]["home"]["conditional_shot_variance"] as float)).is_equal_approx(3.5275, 0.000001)
	assert_array(Array(MarginGrowthAudit.coverage_errors(row["coverage"] as Dictionary))).is_empty()
	assert_int((row["coverage"]["straddled_late_boundary"] as int)).is_equal(1)
	assert_int((row["windows"]["early_regulation"]["away"]["live_ms"] as int)).is_equal(40000)
	assert_int((row["windows"]["late_regulation"]["away"]["live_ms"] as int)).is_equal(1000)
	assert_int((row["windows"]["late_regulation"]["away"]["possessions"] as int)).is_equal(0)
	assert_int((row["windows"]["late_regulation"]["away"]["turnovers"] as int)).is_equal(1)


func test_missing_channel_coverage_is_a_failure() -> void:
	var fixture: Dictionary = MarginGrowthFixtures.known_ledger()
	var audit: MarginGrowthAudit = MarginGrowthFixtures.observer_for(fixture)
	var coverage: Dictionary = audit.measure(fixture["input"] as MatchInput, fixture["output"] as MatchSimulationOutput)["coverage"]
	for key in MarginGrowthAudit.REQUIRED_COVERAGE:
		var omitted: Dictionary = coverage.duplicate()
		omitted[key] = 0
		assert_bool(MarginGrowthAudit.coverage_errors(omitted).has("unwitnessed channel: " + key)).is_true()
	assert_int(MarginGrowthAudit.coverage_errors({}).size()).is_equal(MarginGrowthAudit.REQUIRED_COVERAGE.size())


func test_dropped_probe_and_wrong_probability_outcome_cannot_pass() -> void:
	var fixture: Dictionary = MarginGrowthFixtures.known_ledger()
	var audit := MarginGrowthAudit.new()
	var row: Dictionary = audit.measure(fixture["input"] as MatchInput, fixture["output"] as MatchSimulationOutput)
	assert_bool((row["errors"] as PackedStringArray).has("shot probe/attempt/outcome count mismatch")).is_true()
	fixture["probes"][1]["made"] = false
	audit = MarginGrowthFixtures.observer_for(fixture)
	row = audit.measure(fixture["input"] as MatchInput, fixture["output"] as MatchSimulationOutput)
	assert_bool((row["errors"] as PackedStringArray).has("probe make outcome disagrees with ledger")).is_true()


func test_score_possession_and_sequence_corruption_is_rejected() -> void:
	var fixture: Dictionary = MarginGrowthFixtures.known_ledger()
	var output: MatchSimulationOutput = fixture["output"]
	output.final_result.home_score += 1
	output.possessions[0].points_scored += 1
	output.events[0].sequence += 1
	var audit: MarginGrowthAudit = MarginGrowthFixtures.observer_for(fixture)
	var errors: PackedStringArray = audit.measure(fixture["input"] as MatchInput, output)["errors"]
	assert_bool(errors.has("final score disagrees with scoring events")).is_true()
	assert_bool(errors.has("possession points disagree with scoring events")).is_true()
	assert_bool(errors.has("event sequence mismatch at 1")).is_true()


func test_period_score_and_nonfinite_probability_are_rejected() -> void:
	var fixture: Dictionary = MarginGrowthFixtures.known_ledger()
	var input: MatchInput = fixture["input"]
	var output: MatchSimulationOutput = fixture["output"]
	output.final_result.statistics.team_line(input.home.team_id).period_scores[0] += 1
	fixture["probes"][1]["probability"] = NAN
	var audit: MarginGrowthAudit = MarginGrowthFixtures.observer_for(fixture)
	var errors: PackedStringArray = audit.measure(input, output)["errors"]
	assert_bool(errors.has("shot probability outside unit interval")).is_true()
	assert_bool(errors.has("period score disagrees with events: home.1")).is_true()


func test_attempt_shooter_and_timestamp_linkage_are_checked() -> void:
	for property: String in ["shooter", "clock", "period"]:
		var fixture: Dictionary = MarginGrowthFixtures.known_ledger()
		var output: MatchSimulationOutput = fixture["output"]
		# Corrupt exactly one dimension so another guard cannot mask its loss.
		if property == "shooter":
			output.events[2].primary_player_id = &"wrong-shooter"
		elif property == "clock":
			output.events[2].clock_ms -= 1
		else:
			output.events[2].period += 1
		var audit: MarginGrowthAudit = MarginGrowthFixtures.observer_for(fixture)
		var errors: PackedStringArray = audit.measure(fixture["input"] as MatchInput, output)["errors"]
		assert_bool(errors.has("attempt/outcome ownership mismatch")).is_true()
