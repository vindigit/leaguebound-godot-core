class_name TestMatchInvariants
extends GdUnitTestSuite

## The `SIMULATION_SPEC.md` §5.1 match invariants.
##
## These hold on every event of every fixture, so they are checked by replaying
## the whole ledger rather than by inspecting a final state that could be
## consistent while the path to it was not.


## "Exactly one offense and one defense exist during a live possession."
func test_exactly_one_offence_is_live_at_a_time() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var live_offense: StringName = &""
		for event in output.events:
			if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
				assert_str(String(live_offense)).is_empty()
				live_offense = event.team_id
			elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
				assert_str(String(live_offense)).is_equal(String(event.team_id))
				live_offense = &""
		assert_str(String(live_offense)).is_empty()


## "A field goal attempt has exactly one shooter. A made field goal has one shot
## value and at most one assister."
func test_each_attempt_has_one_shooter_and_at_most_one_assister() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var assists_since_make: int = 0
		for event in output.events:
			match event.event_type:
				MatchDomainEvent.FIELD_GOAL_ATTEMPT:
					assert_str(String(event.primary_player_id)).is_not_empty()
				MatchDomainEvent.FIELD_GOAL_MADE:
					assert_str(String(event.primary_player_id)).is_not_empty()
					assert_bool(event.points == 2 or event.points == 3).is_true()
					assists_since_make = 0
				MatchDomainEvent.ASSIST:
					assists_since_make += 1
					assert_int(assists_since_make).is_less_equal(1)
				_:
					pass


## "A rebound can occur only after a reboundable miss."
func test_rebounds_follow_a_miss() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var missed: bool = false
		for event in output.events:
			match event.event_type:
				MatchDomainEvent.FIELD_GOAL_MISSED, MatchDomainEvent.FREE_THROW_MISSED:
					missed = true
				MatchDomainEvent.REBOUND:
					assert_bool(missed).is_true()
					missed = false
				MatchDomainEvent.FIELD_GOAL_MADE, MatchDomainEvent.FREE_THROW_MADE:
					missed = false
				_:
					pass


## The clock never runs backwards inside a period, and never exceeds the period
## length.
func test_the_clock_is_monotonic_within_each_period() -> void:
	for scenario in GoldenScenarios.names():
		var input: MatchInput = GoldenScenarios.input_for(scenario)
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var period: int = 0
		var clock: int = 0
		for event in output.events:
			if event.period != period:
				assert_int(event.period).is_greater(period)
				period = event.period
				clock = input.rule_profile.period_length_ms(period)
			assert_int(event.clock_ms).is_less_equal(clock)
			assert_int(event.clock_ms).is_greater_equal(0)
			clock = event.clock_ms


## Score changes only through scoring events, and the final score is the sum of
## them. §5.1: "Score, clock, possession, fouls, and box score can change only
## through domain events."
func test_score_changes_only_through_scoring_events() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var totals: Dictionary = {}
		for event in output.events:
			if (
				event.event_type != MatchDomainEvent.FIELD_GOAL_MADE
				and event.event_type != MatchDomainEvent.FREE_THROW_MADE
			):
				continue
			var points: int = event.points if event.points > 0 else 1
			var current: int = totals.get(event.team_id, 0)
			totals[event.team_id] = current + points
		var home_total: int = totals.get(output.final_result.home_team_id, 0)
		var away_total: int = totals.get(output.final_result.away_team_id, 0)
		assert_int(home_total).is_equal(output.final_result.home_score)
		assert_int(away_total).is_equal(output.final_result.away_score)


## Match completion is terminal, and a completed match is never tied.
func test_completed_matches_are_terminal_and_decided() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		assert_int(output.final_result.home_score).is_not_equal(output.final_result.away_score)
		var ended: int = 0
		for index in range(output.events.size()):
			if output.events[index].event_type == MatchDomainEvent.MATCH_ENDED:
				ended += 1
				# Nothing follows the end of a match.
				assert_int(index).is_equal(output.events.size() - 1)
		assert_int(ended).is_equal(1)


## The ledger is contiguous and each event is applied exactly once.
func test_match_events_are_contiguous() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	for index in range(output.events.size()):
		assert_int(output.events[index].sequence).is_equal(index + 1)


## Overtime is entered only from a tie at the end of regulation, and each extra
## period is counted once.
func test_overtime_follows_a_tied_regulation() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.OVERTIME)
	var input: MatchInput = GoldenScenarios.input_for(GoldenScenarios.OVERTIME)
	assert_int(output.final_result.overtime_periods).is_greater(0)

	var home: TeamStatLine = output.final_result.statistics.team_line(
		output.final_result.home_team_id)
	var away: TeamStatLine = output.final_result.statistics.team_line(
		output.final_result.away_team_id)
	assert_int(home.period_scores.size()).is_equal(
		input.rule_profile.regulation_periods + output.final_result.overtime_periods)
	# The score was level at the end of regulation.
	var home_regulation: int = 0
	var away_regulation: int = 0
	for index in range(input.rule_profile.regulation_periods):
		home_regulation += home.period_scores[index]
		away_regulation += away.period_scores[index]
	assert_int(home_regulation).is_equal(away_regulation)
