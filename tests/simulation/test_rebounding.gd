class_name TestRebounding
extends GdUnitTestSuite

## `SIMULATION_SPEC.md` §14 and the Stage 3 rebounding contract.
##
## The defect being closed was total: every miss became a defensive rebound, so
## offensive rebounding, putbacks, and second-chance points did not exist.


## Every reboundable miss produces exactly one rebound, credited to one player.
func test_every_reboundable_miss_produces_one_rebound() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.OFFENSIVE_REBOUND)
	var misses: int = 0
	var rebounds: int = 0
	var free_throw_misses: int = 0
	for event in output.events:
		match event.event_type:
			MatchDomainEvent.FIELD_GOAL_MISSED:
				misses += 1
			MatchDomainEvent.FREE_THROW_MISSED:
				free_throw_misses += 1
			MatchDomainEvent.REBOUND:
				rebounds += 1
				assert_str(String(event.primary_player_id)).is_not_empty()
				assert_str(String(event.team_id)).is_not_empty()
			_:
				pass
	assert_int(misses).is_greater(0)
	assert_int(rebounds).is_greater(0)
	# A missed shot is rebounded unless the period expired first, and some
	# missed free throws are live too, so rebounds sit between the two counts.
	assert_int(rebounds).is_less_equal(misses + free_throw_misses)


## Both sides of the glass are attributed, and both appear.
func test_offensive_and_defensive_rebounds_are_both_attributed() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.OFFENSIVE_REBOUND)
	var offensive: int = 0
	var defensive: int = 0
	for event in output.events:
		if event.event_type != MatchDomainEvent.REBOUND:
			continue
		if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
			offensive += 1
			# An offensive rebound belongs to the team that was attacking.
			assert_str(String(event.team_id)).is_equal(String(_offense_of(output, event)))
		else:
			defensive += 1
			assert_str(String(event.team_id)).is_not_equal(String(_offense_of(output, event)))
	assert_int(offensive).is_greater(0)
	assert_int(defensive).is_greater(0)

	var statistics: MatchStatistics = output.final_result.statistics
	var projected_offensive: int = 0
	var projected_defensive: int = 0
	for team in statistics.teams:
		projected_offensive += team.offensive_rebounds
		projected_defensive += team.defensive_rebounds
	assert_int(projected_offensive).is_equal(offensive)
	assert_int(projected_defensive).is_equal(defensive)


## The offensive rebound percentage uses `ORB / (ORB + opponent DREB)`.
func test_offensive_rebound_percentage_uses_the_required_denominator() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.OFFENSIVE_REBOUND)
	var home: TeamStatLine = output.final_result.statistics.team_line(
		output.final_result.home_team_id)
	var away: TeamStatLine = output.final_result.statistics.team_line(
		output.final_result.away_team_id)

	var expected: float = float(home.offensive_rebounds) / float(
		home.offensive_rebounds + away.defensive_rebounds)
	assert_float(home.offensive_rebound_percentage(away)).is_equal_approx(expected, 0.0001)
	# The denominator is the opponent's defensive rebounds, not the team's own.
	assert_int(home.offensive_rebounds + away.defensive_rebounds).is_not_equal(
		home.offensive_rebounds + home.defensive_rebounds)
	assert_float(home.offensive_rebound_percentage(away)).is_between(0.0, 1.0)


## §14.4: an offensive rebound can produce an immediate putback, and a putback
## is a real attempt with its own zone.
func test_offensive_rebounds_produce_putbacks() -> void:
	var putbacks: int = 0
	for scenario in GoldenScenarios.names():
		for event in GoldenScenarios.simulate(scenario).events:
			if (
				event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT
				and event.action_id == ActionFamily.id_of(ActionFamily.Value.PUTBACK)
			):
				putbacks += 1
				assert_str(String(event.zone_id)).is_equal(
					String(ShotZone.id_of(ShotZone.Value.RESTRICTED_RIM)))
	assert_int(putbacks).is_greater(0)


## Second-chance points exist and are attributed to the possession that earned
## them.
func test_second_chance_points_are_recorded() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.OFFENSIVE_REBOUND)
	var total: int = 0
	for team in output.final_result.statistics.teams:
		total += team.second_chance_points
	assert_int(total).is_greater(0)


## Rebounding responds to the Defensive Rebounding rating: a team built to
## rebound keeps more of the defensive glass.
func test_defensive_rebounding_rating_changes_the_defensive_glass() -> void:
	var strong: float = _defensive_rebound_share(95)
	var weak: float = _defensive_rebound_share(40)
	assert_float(strong).is_greater(weak)


func _offense_of(output: MatchSimulationOutput, event: MatchDomainEvent) -> StringName:
	for record in output.possessions:
		if record.possession_id == event.possession_id:
			return record.offense_team_id
	return &""


## Share of available defensive rebounds the home team collects, with only its
## Defensive Rebounding rating changed.
func _defensive_rebound_share(rating: int) -> float:
	var overrides: Dictionary = {AttributeKey.Key.DEFENSIVE_REBOUNDING: rating}
	var collected: int = 0
	var available: int = 0
	for seed_value: int in [4242, 91, 20260815]:
		var input: MatchInput = MatchFixtureFactory.match_between(
			MatchFixtureFactory.uniform_team(&"home", 70, overrides),
			MatchFixtureFactory.uniform_team(&"away", 70),
			MatchFixtureFactory.quick_match().rule_profile)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		var home: TeamStatLine = output.final_result.statistics.team_line(&"home")
		var away: TeamStatLine = output.final_result.statistics.team_line(&"away")
		collected += home.defensive_rebounds
		available += home.defensive_rebounds + away.offensive_rebounds
	return float(collected) / float(maxi(available, 1))
