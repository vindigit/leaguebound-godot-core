class_name TestEventStatReconciliation
extends GdUnitTestSuite

## `SIMULATION_SPEC.md` §24.3: "The box score is a materialized projection of
## events and is reconciled at match completion."
##
## §14.2 sets the shipping tolerance for an impossible or unreconciled box score
## at zero, so these run over every scenario rather than one.


func test_box_score_reconciles_from_events_in_every_scenario() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var failures: PackedStringArray = output.final_result.statistics.reconcile()
		assert_array(failures).override_failure_message(
			"scenario %s: %s" % [scenario, ", ".join(failures)]).is_empty()


## The projection, the reduced state, and the final result all agree on score.
func test_projection_state_and_result_agree_on_score() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var statistics: MatchStatistics = output.final_result.statistics
		assert_int(statistics.team_line(output.final_result.home_team_id).points).is_equal(
			output.final_result.home_score)
		assert_int(statistics.team_line(output.final_result.away_team_id).points).is_equal(
			output.final_result.away_score)
		assert_int(output.final_result.final_event_sequence).is_equal(output.events.size())


## Every scoring event in the ledger is present in the box score exactly once.
func test_every_scoring_event_appears_exactly_once() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var points: Dictionary = {}
		var attempts: Dictionary = {}
		var threes: Dictionary = {}
		for event in output.events:
			match event.event_type:
				MatchDomainEvent.FIELD_GOAL_ATTEMPT:
					attempts[event.primary_player_id] = _count(attempts, event.primary_player_id) + 1
					if ShotZone.is_three(ShotZone.from_id(event.zone_id)):
						threes[event.primary_player_id] = _count(
							threes, event.primary_player_id) + 1
				MatchDomainEvent.FIELD_GOAL_MADE:
					points[event.primary_player_id] = _count(
						points, event.primary_player_id) + event.points
				MatchDomainEvent.FREE_THROW_MADE:
					points[event.primary_player_id] = _count(points, event.primary_player_id) + 1
				_:
					pass
		var statistics: MatchStatistics = output.final_result.statistics
		for player_id: StringName in attempts.keys():
			var line: PlayerStatLine = statistics.player_line(player_id)
			assert_int(line.field_goals_attempted).is_equal(_count(attempts, player_id))
			assert_int(line.three_pointers_attempted).is_equal(_count(threes, player_id))
			assert_int(line.points).is_equal(_count(points, player_id))


## Period scores sum to the final score.
func test_period_scores_sum_to_the_final_score() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for team in output.final_result.statistics.teams:
			var total: int = 0
			for score in team.period_scores:
				total += score
			assert_int(total).is_equal(team.points)


## §24.2: engine possessions come from terminal records; the estimate is
## published beside them and is never the authority.
func test_engine_possessions_and_estimate_are_separate() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for team in output.final_result.statistics.teams:
			assert_int(team.engine_possessions).is_equal(
				output.engine_possessions(team.team_id))
			assert_int(team.engine_possessions).is_greater(0)
			assert_float(team.possession_estimate).is_greater(0.0)
		# Possession alternates, so the two counts stay close. They are not
		# identical: a period that expires mid-possession leaves the ball with
		# the team that had it, which can hand one side an extra trip once per
		# period boundary.
		var home: TeamStatLine = output.final_result.statistics.team_line(
			output.final_result.home_team_id)
		var away: TeamStatLine = output.final_result.statistics.team_line(
			output.final_result.away_team_id)
		var periods: int = (
			GoldenScenarios.input_for(scenario).rule_profile.regulation_periods
			+ output.final_result.overtime_periods)
		assert_int(absi(home.engine_possessions - away.engine_possessions)).is_less_equal(periods)


## The ledger is contiguous and applied exactly once.
func test_event_ledger_is_contiguous() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size()):
			assert_int(output.events[index].sequence).is_equal(index + 1)


## §24.4 role-evaluation evidence has an engine event source: screens, off-ball
## actions, and advantages are all counted from real events.
func test_role_evaluation_evidence_comes_from_events() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var screens: int = 0
	var off_ball: int = 0
	var advantages: int = 0
	for event in output.events:
		match event.event_type:
			MatchDomainEvent.SCREEN_SET:
				screens += 1
			MatchDomainEvent.OFF_BALL_ACTION:
				off_ball += 1
			MatchDomainEvent.ADVANTAGE_CREATED:
				advantages += 1
			_:
				pass
	assert_int(screens).is_greater(0)
	assert_int(off_ball).is_greater(0)
	assert_int(advantages).is_greater(0)

	var projected_screens: int = 0
	var projected_off_ball: int = 0
	var projected_advantages: int = 0
	for line in output.final_result.statistics.players:
		projected_screens += line.screens_set
		projected_off_ball += line.off_ball_actions
		projected_advantages += line.advantages_created
	assert_int(projected_screens).is_equal(screens)
	assert_int(projected_off_ball).is_equal(off_ball)
	assert_int(projected_advantages).is_equal(advantages)


## Paint attempts and points are projected from the zone on the event.
func test_paint_summary_matches_the_zones_in_the_ledger() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var attempts: int = 0
	var points: int = 0
	for event in output.events:
		if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			if ShotZone.is_paint(ShotZone.from_id(event.zone_id)):
				attempts += 1
		elif event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
			if ShotZone.is_paint(ShotZone.from_id(event.zone_id)):
				points += event.points
	var projected_attempts: int = 0
	var projected_points: int = 0
	for team in output.final_result.statistics.teams:
		projected_attempts += team.paint_attempts
		projected_points += team.paint_points
	assert_int(projected_attempts).is_equal(attempts)
	assert_int(projected_points).is_equal(points)
	assert_int(attempts).is_greater(0)


func _count(counts: Dictionary, key: StringName) -> int:
	if not counts.has(key):
		return 0
	var value: int = counts[key]
	return value
