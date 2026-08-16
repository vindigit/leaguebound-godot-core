class_name TestFoulsAndFreeThrows
extends GdUnitTestSuite

## `SIMULATION_SPEC.md` §13, and the Stage 3 foul contract.
##
## The contract is explicit that a foul must "generate valid illegal-contact
## candidates from real action and defensive context", and that the engine must
## not "tune a generic once-per-possession foul probability upward to
## manufacture the desired total". These tests check the consequences of that:
## the five types, the bonus tiers, and-one, the final-attempt rebound, foul-out,
## and the period reset all resolve through real branches.


## §13.1: the abstraction distinguishes shooting, non-shooting defensive,
## offensive, loose-ball, and intentional fouls.
func test_multiple_foul_types_occur_across_the_fixture_set() -> void:
	var seen: Dictionary = {}
	for scenario in GoldenScenarios.names():
		for event in GoldenScenarios.simulate(scenario).events:
			if event.event_type == MatchDomainEvent.FOUL:
				seen[String(event.detail_id)] = true
	assert_bool(seen.has(String(FoulType.id_of(FoulType.Value.SHOOTING)))).is_true()
	assert_bool(
		seen.has(String(FoulType.id_of(FoulType.Value.NON_SHOOTING_DEFENSIVE)))).is_true()
	assert_bool(seen.has(String(FoulType.id_of(FoulType.Value.OFFENSIVE)))).is_true()


## An offensive foul is a turnover charged to the offence (§11.2), and it does
## not advance the fouling team's bonus counter.
func test_offensive_fouls_become_turnovers_and_do_not_advance_the_bonus() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.SUBSTITUTION_FOUL_OUT)
	var offensive_fouls: int = 0
	for index in range(output.events.size() - 1):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type != MatchDomainEvent.FOUL:
			continue
		if event.detail_id != FoulType.id_of(FoulType.Value.OFFENSIVE):
			continue
		offensive_fouls += 1
		# The fouling team is the offence, and the possession ends as a turnover.
		# The scan runs to the end of the possession rather than over a fixed
		# window: a foul-out on the same whistle inserts an arbitrary number of
		# substitution events between the whistle and the turnover.
		var turnover_found: bool = false
		for ahead in range(index + 1, output.events.size()):
			var later: MatchDomainEvent = output.events[ahead]
			if later.event_type == MatchDomainEvent.TURNOVER:
				assert_str(String(later.detail_id)).is_equal(
					String(TurnoverCause.id_of(TurnoverCause.Value.OFFENSIVE_FOUL)))
				turnover_found = true
				break
			if later.event_type == MatchDomainEvent.POSSESSION_ENDED:
				break
		assert_bool(turnover_found).is_true()
	assert_int(offensive_fouls).is_greater(0)
	assert_bool(FoulType.advances_team_fouls(FoulType.Value.OFFENSIVE)).is_false()


## §13: an and-one is a made basket plus exactly one free throw.
func test_and_one_awards_exactly_one_attempt_after_a_made_basket() -> void:
	var found: int = 0
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size() - 2):
			if output.events[index].event_type != MatchDomainEvent.FIELD_GOAL_MADE:
				continue
			for ahead in range(index + 1, mini(index + 5, output.events.size())):
				var later: MatchDomainEvent = output.events[ahead]
				if later.event_type == MatchDomainEvent.FREE_THROW_AWARDED:
					assert_int(later.amount).is_equal(1)
					found += 1
					break
				if later.event_type == MatchDomainEvent.POSSESSION_ENDED:
					break
	assert_int(found).is_greater(0)


## Every awarded attempt is taken exactly once, and every taken attempt belongs
## to an award. §13.2: "Attempts, makes, team fouls, personal fouls, bonus
## state, and possession continuation are attributed exactly once."
func test_free_throw_attempts_are_attributed_exactly_once() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var taken: int = 0
		var awards: int = 0
		var index: int = 0
		while index < output.events.size():
			var event: MatchDomainEvent = output.events[index]
			if event.event_type != MatchDomainEvent.FREE_THROW_AWARDED:
				index += 1
				continue
			awards += 1
			var group_taken: int = 0
			var last_missed: bool = false
			var scan: int = index + 1
			while scan < output.events.size():
				var attempt: MatchDomainEvent = output.events[scan]
				if attempt.event_type == MatchDomainEvent.FREE_THROW_MADE:
					group_taken += 1
					last_missed = false
				elif attempt.event_type == MatchDomainEvent.FREE_THROW_MISSED:
					group_taken += 1
					last_missed = true
				else:
					break
				# Attempt indices are one-based and strictly increasing.
				assert_int(attempt.amount).is_equal(group_taken)
				scan += 1
			# Every awarded attempt is taken, except the earned second attempt
			# of a one-and-one whose first attempt was missed.
			assert_int(group_taken).is_less_equal(event.amount)
			if group_taken < event.amount:
				assert_int(group_taken).is_equal(1)
				assert_bool(last_missed).is_true()
			taken += group_taken
			index = scan
		assert_int(awards).is_greater(0)

		# The projection agrees with the ledger, exactly once per attempt.
		var projected: int = 0
		for team in output.final_result.statistics.teams:
			projected += team.free_throws_attempted
		assert_int(projected).is_equal(taken)


## §13.2 one-and-one: the second attempt exists only if the first is made.
func test_one_and_one_second_attempt_must_be_earned() -> void:
	var rules: CompetitionRuleProfile = MatchFixtureFactory.one_and_one_match().rule_profile
	assert_bool(rules.is_one_and_one(1)).is_true()
	# Two attempts are awarded; the second is conditional on the first.
	assert_int(rules.bonus_free_throws_for(1)).is_equal(2)
	assert_int(rules.bonus_free_throws_for(0)).is_equal(0)

	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.LATE_GAME)
	var missed_firsts: int = 0
	var made_firsts: int = 0
	for index in range(output.events.size() - 1):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type != MatchDomainEvent.FREE_THROW_AWARDED:
			continue
		var first: MatchDomainEvent = output.events[index + 1]
		if first.event_type == MatchDomainEvent.FREE_THROW_MISSED:
			missed_firsts += 1
			# The earned attempt is forfeited; the ball is live instead.
			var following: MatchDomainEvent = output.events[index + 2]
			assert_str(String(following.event_type)).is_not_equal(
				String(MatchDomainEvent.FREE_THROW_MADE))
			assert_str(String(following.event_type)).is_not_equal(
				String(MatchDomainEvent.FREE_THROW_MISSED))
		elif first.event_type == MatchDomainEvent.FREE_THROW_MADE:
			made_firsts += 1
			# Making the first earns the second.
			var following: MatchDomainEvent = output.events[index + 2]
			assert_bool(
				following.event_type == MatchDomainEvent.FREE_THROW_MADE
				or following.event_type == MatchDomainEvent.FREE_THROW_MISSED
			).is_true()
	assert_int(missed_firsts).is_greater(0)
	assert_int(made_firsts).is_greater(0)


## A missed final attempt is live where the rules say so (§13.2, §14).
func test_missed_final_free_throw_is_reboundable() -> void:
	var rebounds_after_miss: int = 0
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		assert_bool(GoldenScenarios.input_for(scenario).rule_profile.final_free_throw_reboundable
			).is_true()
		for index in range(output.events.size() - 1):
			if output.events[index].event_type != MatchDomainEvent.FREE_THROW_MISSED:
				continue
			var next_event: MatchDomainEvent = output.events[index + 1]
			if next_event.event_type == MatchDomainEvent.REBOUND:
				rebounds_after_miss += 1
	assert_int(rebounds_after_miss).is_greater(0)


## The bonus is reached, and once reached a non-shooting foul produces free
## throws rather than an inbound.
func test_bonus_state_converts_non_shooting_fouls_into_free_throws() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.FOUL_FREE_THROW)
	var rules: CompetitionRuleProfile = GoldenScenarios.input_for(
		GoldenScenarios.FOUL_FREE_THROW).rule_profile
	assert_int(rules.team_foul_bonus_threshold).is_equal(1)

	var converted: int = 0
	for index in range(output.events.size() - 1):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type != MatchDomainEvent.FOUL:
			continue
		if event.detail_id != FoulType.id_of(FoulType.Value.NON_SHOOTING_DEFENSIVE):
			continue
		for ahead in range(index + 1, output.events.size()):
			var later: MatchDomainEvent = output.events[ahead]
			if later.event_type == MatchDomainEvent.FREE_THROW_AWARDED:
				converted += 1
				break
			if later.event_type == MatchDomainEvent.POSSESSION_ENDED:
				break
	assert_int(converted).is_greater(0)

	for team in output.final_result.statistics.teams:
		assert_int(team.periods_in_bonus).is_greater(0)


## §5.1: a player who has fouled out cannot re-enter, and the substitution
## happens on the same whistle.
func test_foul_out_removes_the_player_and_replaces_him() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.SUBSTITUTION_FOUL_OUT)
	var limit: int = GoldenScenarios.input_for(
		GoldenScenarios.SUBSTITUTION_FOUL_OUT).rule_profile.personal_foul_limit
	var fouled_out: Array[StringName] = []
	for index in range(output.events.size()):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type == MatchDomainEvent.FOUL_OUT:
			fouled_out.append(event.primary_player_id)
			# He leaves on the same whistle. The check-out is not necessarily
			# the very next event: one whistle can carry several substitutions,
			# and they are emitted in canonical roster order.
			var checked_out: bool = false
			for ahead in range(index + 1, output.events.size()):
				var later: MatchDomainEvent = output.events[ahead]
				if (
					later.event_type == MatchDomainEvent.CHECK_OUT
					and later.primary_player_id == event.primary_player_id
				):
					checked_out = true
					break
				if later.event_type == MatchDomainEvent.POSSESSION_STARTED:
					break
			assert_bool(checked_out).is_true()
		elif event.event_type == MatchDomainEvent.CHECK_IN:
			# §5.1: he cannot re-enter.
			assert_bool(fouled_out.has(event.primary_player_id)).is_false()
	assert_int(fouled_out.size()).is_greater(0)

	for player_id in fouled_out:
		var line: PlayerStatLine = output.final_result.statistics.player_line(player_id)
		assert_bool(line.fouled_out).is_true()
		assert_int(line.personal_fouls).is_greater_equal(limit)


## Team fouls reset each period; personal fouls never do.
func test_team_fouls_reset_each_period_and_personal_fouls_do_not() -> void:
	var input: MatchInput = MatchFixtureFactory.bonus_match()
	assert_bool(input.rule_profile.team_fouls_reset_each_period).is_true()
	var session := MatchSession.new(input, SeededRandomSource.new(4242))
	session.open()

	var observed_reset: bool = false
	var previous_period: int = session.snapshot().period
	var fouls_before_reset: int = 0
	while not session.is_complete():
		session.advance_possession()
		var snapshot: MatchSnapshot = session.snapshot()
		if snapshot.period != previous_period:
			if fouls_before_reset > 0:
				assert_int(snapshot.home.team_fouls).is_equal(0)
				assert_int(snapshot.away.team_fouls).is_equal(0)
				observed_reset = true
			previous_period = snapshot.period
		fouls_before_reset = maxi(
			fouls_before_reset, maxi(snapshot.home.team_fouls, snapshot.away.team_fouls))
	assert_bool(observed_reset).is_true()

	# Personal fouls survive the reset: the game total equals the ledger total.
	var output: MatchSimulationOutput = session.build_output()
	var ledger_fouls: int = 0
	for event in output.events:
		if event.event_type == MatchDomainEvent.FOUL:
			ledger_fouls += 1
	var projected: int = 0
	for team in output.final_result.statistics.teams:
		projected += team.personal_fouls
	assert_int(projected).is_equal(ledger_fouls)
