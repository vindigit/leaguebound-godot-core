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
##
## Only a *bonus* award is a one-and-one. A shooting foul in the same fixture
## awards its attempts outright, and both are taken however the first lands —
## `FoulResolver.resolve_shooting_foul` passes `one_and_one = false`. This test
## previously applied the one-and-one rule to every award in the fixture, so a
## perfectly legal two-shot shooting foul whose first attempt missed read as a
## contract violation. It now separates the two and checks both rules, because
## the two-shot case needs asserting just as much as the earned-attempt case.
func test_one_and_one_second_attempt_must_be_earned() -> void:
	var rules: CompetitionRuleProfile = MatchFixtureFactory.one_and_one_match().rule_profile
	assert_bool(rules.is_one_and_one(1)).is_true()
	# Two attempts are awarded; the second is conditional on the first.
	assert_int(rules.bonus_free_throws_for(1)).is_equal(2)
	assert_int(rules.bonus_free_throws_for(0)).is_equal(0)

	# This test owns its match rather than borrowing a golden scenario.
	#
	# The golden `late_game` ledger happens to contain four one-and-one awards
	# whose first attempt was *made*, and none that forfeited. The forfeiture
	# branch was therefore never exercised there: the old version of this test
	# counted shooting fouls into its missed-first tally, so it reported coverage
	# of a rule it never reached. Seed 6078 on the same fixture produces three
	# forfeits and three earned second attempts, so both halves of §13.2's
	# one-and-one rule are genuinely asserted.
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.one_and_one_match(), SeededRandomSource.new(6078))
	var missed_bonus_firsts: int = 0
	var made_bonus_firsts: int = 0
	var shooting_sequences: int = 0
	for index in range(output.events.size() - 2):
		var event: MatchDomainEvent = output.events[index]
		if event.event_type != MatchDomainEvent.FREE_THROW_AWARDED:
			continue
		var first: MatchDomainEvent = output.events[index + 1]
		var following: MatchDomainEvent = output.events[index + 2]
		var another_attempt: bool = (
			following.event_type == MatchDomainEvent.FREE_THROW_MADE
			or following.event_type == MatchDomainEvent.FREE_THROW_MISSED)

		if _causing_foul_type(output, index) == FoulType.Value.SHOOTING:
			# A shooting foul is never a one-and-one: every awarded attempt is
			# taken, whatever the first one did.
			shooting_sequences += 1
			assert_int(_attempts_taken(output, index)).is_equal(event.amount)
			continue

		if first.event_type == MatchDomainEvent.FREE_THROW_MISSED:
			missed_bonus_firsts += 1
			# The earned attempt is forfeited; the ball is live instead.
			assert_bool(another_attempt).is_false()
			assert_int(_attempts_taken(output, index)).is_equal(1)
		elif first.event_type == MatchDomainEvent.FREE_THROW_MADE:
			made_bonus_firsts += 1
			# Making the first earns the second.
			assert_bool(another_attempt).is_true()
			assert_int(_attempts_taken(output, index)).is_equal(event.amount)
	assert_int(missed_bonus_firsts).is_greater(0)
	assert_int(made_bonus_firsts).is_greater(0)
	assert_int(shooting_sequences).is_greater(0)


## The foul that produced an award, found by searching back to the nearest
## whistle. The ledger records the award count but not the bonus kind, so the
## causing foul is what distinguishes an earned second attempt from an outright
## one.
func _causing_foul_type(output: MatchSimulationOutput, award_index: int) -> int:
	for back in range(award_index - 1, maxi(award_index - 8, -1), -1):
		var event: MatchDomainEvent = output.events[back]
		if event.event_type == MatchDomainEvent.FOUL:
			for foul_type in FoulType.all():
				if event.detail_id == FoulType.id_of(foul_type):
					return foul_type
			return -1
	return -1


## The `FoulType` a FOUL event records, or -1 when the detail is unrecognized.
func _foul_type_of(event: MatchDomainEvent) -> int:
	for foul_type in FoulType.all():
		if event.detail_id == FoulType.id_of(foul_type):
			return foul_type
	return -1


func _attempts_taken(output: MatchSimulationOutput, award_index: int) -> int:
	var taken: int = 0
	for scan in range(award_index + 1, output.events.size()):
		var attempt: MatchDomainEvent = output.events[scan]
		if (
			attempt.event_type != MatchDomainEvent.FREE_THROW_MADE
			and attempt.event_type != MatchDomainEvent.FREE_THROW_MISSED
		):
			break
		taken += 1
	return taken


## Regression guard for the buzzer defect: a foul drawn with the period almost
## expired still has its awarded attempts taken.
##
## `foul_free_throw` at seed 4242 previously produced a two-shot shooting foul
## at one second remaining whose free-throw event time expired the period before
## either attempt was emitted, leaving an award nothing ever took. The general
## attribution test above catches the symptom across every scenario; this one
## names the cause, so a regression cannot be mistaken for an unrelated drift.
func test_awarded_free_throws_survive_the_period_buzzer() -> void:
	var checked: int = 0
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size()):
			var event: MatchDomainEvent = output.events[index]
			if event.event_type != MatchDomainEvent.FREE_THROW_AWARDED:
				continue
			var taken: int = _attempts_taken(output, index)
			# A one-and-one whose first attempt missed is the only legal shortfall.
			if taken < event.amount:
				assert_int(taken).is_equal(1)
				assert_str(String(output.events[index + 1].event_type)).is_equal(
					String(MatchDomainEvent.FREE_THROW_MISSED))
			assert_int(taken).is_greater(0)
			checked += 1
	assert_int(checked).is_greater(0)


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
	while not session.is_complete():
		session.advance_possession()
	var output: MatchSimulationOutput = session.build_output()

	# The reset is asserted from the ledger rather than from snapshots sampled
	# between possessions.
	#
	# `advance_possession` folds a period transition and the first possession of
	# the new period into one call, so a snapshot taken after it can show a
	# non-zero team-foul count that is entirely legitimate — the count reset and
	# was then incremented by a foul in that first possession. Sampling could not
	# tell that apart from a reset that never happened, which made the old form
	# pass or fail on where the fouls happened to land. Replaying the ordered
	# events checks every boundary instead of the ones sampling happened to see.
	var boundaries_with_prior_fouls: int = 0
	var home_running: int = 0
	var away_running: int = 0
	var carried_into_period: int = 0
	for event in output.events:
		if event.event_type == MatchDomainEvent.PERIOD_STARTED:
			carried_into_period = maxi(home_running, away_running)
			if carried_into_period > 0:
				boundaries_with_prior_fouls += 1
			home_running = 0
			away_running = 0
			continue
		if event.event_type != MatchDomainEvent.FOUL:
			continue
		if not FoulType.advances_team_fouls(_foul_type_of(event)):
			continue
		if event.team_id == input.home.team_id:
			home_running += 1
		else:
			away_running += 1
	assert_int(boundaries_with_prior_fouls).is_greater(0)

	# The reduced state agrees with that replay for the final period, which is
	# what proves the reducer is the thing doing the resetting.
	assert_int(session.snapshot().home.team_fouls).is_equal(home_running)
	assert_int(session.snapshot().away.team_fouls).is_equal(away_running)

	# Personal fouls survive the reset: the game total equals the ledger total.
	var ledger_fouls: int = 0
	for event in output.events:
		if event.event_type == MatchDomainEvent.FOUL:
			ledger_fouls += 1
	var projected: int = 0
	for team in output.final_result.statistics.teams:
		projected += team.personal_fouls
	assert_int(projected).is_equal(ledger_fouls)
