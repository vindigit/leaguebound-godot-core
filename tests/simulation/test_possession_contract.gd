class_name TestPossessionContract
extends GdUnitTestSuite

## The Stage 3 possession contract.
##
## These are structural invariants, not statistical expectations: each one must
## hold on every possession of every fixture, so they are asserted across whole
## games rather than on a hand-built example.


func test_every_possession_has_exactly_one_start_and_one_end() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var starts: Dictionary = {}
	var ends: Dictionary = {}
	for event in output.events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			starts[event.possession_id] = _count(starts, event.possession_id) + 1
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			ends[event.possession_id] = _count(ends, event.possession_id) + 1
	assert_int(starts.size()).is_greater(0)
	assert_int(ends.size()).is_equal(starts.size())
	for record in output.possessions:
		assert_int(_count(starts, record.possession_id)).is_equal(1)
		assert_int(_count(ends, record.possession_id)).is_equal(1)


## Possession identity is stable and monotonic, and every in-possession event
## carries an action sequence that only ever advances.
func test_possession_and_action_identity_are_stable() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var expected_id: int = 0
	for record in output.possessions:
		expected_id += 1
		assert_int(record.possession_id).is_equal(expected_id)

	var current_possession: int = 0
	var last_action: int = 0
	for event in output.events:
		if event.possession_id == 0:
			continue
		if event.possession_id != current_possession:
			assert_int(event.possession_id).is_greater(current_possession)
			current_possession = event.possession_id
			last_action = 0
		assert_int(event.action_sequence).is_greater_equal(last_action)
		last_action = event.action_sequence


## An offensive rebound continues the same possession: no new start event, no
## extra team possession, and the possession id is unchanged.
func test_offensive_rebound_does_not_start_a_new_possession() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.OFFENSIVE_REBOUND)
	var continued: int = 0
	for record in output.possessions:
		continued += record.offensive_rebounds
	assert_int(continued).is_greater(0)

	# Every offensive rebound belongs to a possession that is still live, and no
	# start event ever follows one inside the same possession.
	var live_possession: int = 0
	for index in range(output.events.size()):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			live_possession = event.possession_id
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			live_possession = 0
		elif (
			event.event_type == MatchDomainEvent.REBOUND
			and event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE
		):
			assert_int(live_possession).is_equal(event.possession_id)

	# Engine possessions are counted from terminal records, so continuation
	# cannot inflate them.
	for team_id: StringName in [
		output.final_result.home_team_id, output.final_result.away_team_id
	]:
		assert_int(output.final_result.statistics.team_line(team_id).engine_possessions).is_equal(
			output.engine_possessions(team_id))


## `POSSESSION_ENDED.team_id` identifies the offence whose possession ended.
## The next-possession team travels in its own field.
func test_possession_end_identifies_the_offence_that_ended() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var offense_by_possession: Dictionary = {}
	for event in output.events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			offense_by_possession[event.possession_id] = event.team_id
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			var started_offense: StringName = offense_by_possession[event.possession_id]
			assert_str(String(event.team_id)).is_equal(String(started_offense))
			assert_str(String(event.next_team_id)).is_not_empty()

	# And the next possession actually belongs to the team the end event named.
	var expected_next: StringName = &""
	for event in output.events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED and not expected_next.is_empty():
			assert_str(String(event.team_id)).is_equal(String(expected_next))
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			expected_next = event.next_team_id


## A made basket, a defensive rebound, and a turnover each hand the ball over;
## an expiring period does not.
func test_terminal_reasons_transfer_possession_correctly() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var seen: Dictionary = {}
	for record in output.possessions:
		seen[record.end_reason] = true
		var opponent: StringName = (
			output.final_result.away_team_id
			if record.offense_team_id == output.final_result.home_team_id
			else output.final_result.home_team_id
		)
		if PossessionEndReason.transfers_possession(record.end_reason):
			assert_str(String(record.next_possession_team_id)).is_equal(String(opponent))
		else:
			assert_str(String(record.next_possession_team_id)).is_equal(
				String(record.offense_team_id))
	# The three ordinary terminal paths all occur in one regulation game.
	assert_bool(seen.has(PossessionEndReason.Value.MADE_SCORE)).is_true()
	assert_bool(seen.has(PossessionEndReason.Value.DEFENSIVE_REBOUND)).is_true()
	assert_bool(seen.has(PossessionEndReason.Value.TURNOVER)).is_true()


## Every terminal path, including the period-expiry one, is reachable across the
## fixture set.
func test_period_expiry_terminates_a_possession() -> void:
	var expired: int = 0
	for scenario in GoldenScenarios.names():
		for record in GoldenScenarios.simulate(scenario).possessions:
			if record.end_reason == PossessionEndReason.Value.PERIOD_EXPIRED:
				expired += 1
	assert_int(expired).is_greater(0)


## §9.4: an offensive rebound uses the rule profile's own reset, not a full
## shot clock.
func test_offensive_rebound_applies_the_rule_profile_reset() -> void:
	var input: MatchInput = MatchFixtureFactory.offensive_rebound_match()
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(GoldenScenarios.seed_for(GoldenScenarios.OFFENSIVE_REBOUND)))
	var expected_ms: int = input.rule_profile.offensive_rebound_reset_seconds * 1000
	var checked: int = 0
	for index in range(output.events.size() - 1):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type != MatchDomainEvent.REBOUND:
			continue
		if event.detail_id != MatchDomainEvent.REBOUND_OFFENSIVE:
			continue
		var next_event: MatchDomainEvent = output.events[index + 1]
		assert_str(String(next_event.event_type)).is_equal(
			String(MatchDomainEvent.SHOT_CLOCK_RESET))
		assert_int(next_event.amount).is_equal(expected_ms)
		checked += 1
	assert_int(checked).is_greater(0)
	assert_int(expected_ms).is_less(input.rule_profile.shot_clock_seconds * 1000)


## A shot-clock violation is a real terminal path, not a silent reset.
func test_shot_clock_violations_are_recorded_as_turnovers() -> void:
	var violations: int = 0
	for scenario in GoldenScenarios.names():
		for event in GoldenScenarios.simulate(scenario).events:
			if (
				event.event_type == MatchDomainEvent.TURNOVER
				and event.detail_id == TurnoverCause.id_of(TurnoverCause.Value.SHOT_CLOCK)
			):
				violations += 1
	assert_int(violations).is_greater(0)


func _count(counts: Dictionary, key: int) -> int:
	if not counts.has(key):
		return 0
	var value: int = counts[key]
	return value
