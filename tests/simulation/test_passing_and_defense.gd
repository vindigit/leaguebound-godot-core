class_name TestPassingAndDefense
extends GdUnitTestSuite

## Assist qualification (§11.3), steal attribution (§11.2), and block
## attribution (§12.7).
##
## The shared rule across all three: credit follows a cause. An assist requires
## the pass that created the shot, a steal requires a defender who caused a
## qualifying live-ball turnover, and a block requires an event where the shot
## was actually blocked.


## §11.3: an assist belongs to the passer, precedes a made basket, and is
## credited to a team-mate.
func test_assists_qualify_against_a_made_basket_by_a_team_mate() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var assists: int = 0
	for index in range(output.events.size()):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type != MatchDomainEvent.ASSIST:
			continue
		assists += 1
		assert_str(String(event.primary_player_id)).is_not_equal(
			String(event.secondary_player_id))
		# The immediately preceding scoring event is the basket it created.
		var preceding: MatchDomainEvent = output.events[index - 1]
		assert_str(String(preceding.event_type)).is_equal(
			String(MatchDomainEvent.FIELD_GOAL_MADE))
		assert_str(String(preceding.primary_player_id)).is_equal(
			String(event.secondary_player_id))
		# Passer and scorer are on the same team.
		var statistics: MatchStatistics = output.final_result.statistics
		assert_str(String(statistics.player_line(event.primary_player_id).team_id)).is_equal(
			String(statistics.player_line(event.secondary_player_id).team_id))
	assert_int(assists).is_greater(0)


## An assist never exceeds the made baskets it could have created.
func test_assists_never_exceed_made_field_goals() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for team in output.final_result.statistics.teams:
			assert_int(team.assists).is_less_equal(team.field_goals_made)


## A pass that the receiver turns into his own creation is unassisted: the
## engine records the assisted state on the made-basket event.
func test_assisted_state_is_recorded_on_every_made_basket() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var seen: Dictionary = {}
	for event in output.events:
		if event.event_type != MatchDomainEvent.FIELD_GOAL_MADE:
			continue
		assert_str(String(event.detail_id)).is_not_empty()
		seen[String(event.detail_id)] = true
	assert_bool(seen.has("unassisted")).is_true()
	assert_bool(seen.has("catch_and_shoot") or seen.has("created")).is_true()


## §11.2: a steal is credited only when a defender caused a qualifying
## live-ball turnover, and every steal is paired with that turnover.
func test_steals_are_credited_only_for_defender_caused_turnovers() -> void:
	var steals: int = 0
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size()):
			var event: MatchDomainEvent = output.events[index]
			if event.event_type != MatchDomainEvent.STEAL:
				continue
			steals += 1
			var preceding: MatchDomainEvent = output.events[index - 1]
			assert_str(String(preceding.event_type)).is_equal(String(MatchDomainEvent.TURNOVER))
			# The cause must be one that credits a steal.
			var cause: int = TurnoverCause.from_id(preceding.detail_id)
			assert_bool(TurnoverCause.credits_steal(cause)).is_true()
			# The steal belongs to the defence, the turnover to the offence.
			assert_str(String(event.team_id)).is_not_equal(String(preceding.team_id))
			assert_str(String(event.primary_player_id)).is_equal(
				String(preceding.secondary_player_id))
	assert_int(steals).is_greater(0)


## An unforced turnover credits nobody.
func test_unforced_turnovers_credit_no_steal() -> void:
	var unforced: int = 0
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size() - 1):
			var event: MatchDomainEvent = output.events[index]
			if event.event_type != MatchDomainEvent.TURNOVER:
				continue
			var cause: int = TurnoverCause.from_id(event.detail_id)
			if TurnoverCause.credits_steal(cause):
				continue
			unforced += 1
			assert_str(String(output.events[index + 1].event_type)).is_not_equal(
				String(MatchDomainEvent.STEAL))
	assert_int(unforced).is_greater(0)


## §12.7: "A block is credited only when it produces a blocked-shot event." The
## blocked attempt is always recorded as a miss, and the blocker is a defender.
func test_blocks_accompany_a_missed_attempt_by_a_defender() -> void:
	var blocks: int = 0
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size() - 1):
			var event: MatchDomainEvent = output.events[index]
			if event.event_type != MatchDomainEvent.BLOCK:
				continue
			blocks += 1
			var following: MatchDomainEvent = output.events[index + 1]
			assert_str(String(following.event_type)).is_equal(
				String(MatchDomainEvent.FIELD_GOAL_MISSED))
			assert_str(String(following.primary_player_id)).is_equal(
				String(event.secondary_player_id))
			assert_str(String(event.team_id)).is_not_equal(String(following.team_id))
	assert_int(blocks).is_greater(0)


## Rating sensitivity for Stealing, Blocking, Passing, and Vision lives in
## `TestAttributeContracts`, which samples the resolvers directly. Whole-game
## counts of rare events — a short fixture produces one or two blocks — cannot
## separate a real effect from the draw, and a test that cannot fail when the
## effect disappears is not testing it.
