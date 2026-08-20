class_name TestGarbageTime
extends GdUnitTestSuite

## The asymmetric settled-rotation rule, and the line between coaching and a
## comeback script.
##
## `GarbageTimeRule` is the first mechanism in the engine whose *thresholds*
## differ by which side of the scoreboard a team is on, so it is also the first
## that could hide a rubber band inside a legitimate-sounding asymmetry. The
## contracts that keep it honest are all testable and all tested here:
##
## - the safety number is one shared property of the game, computed identically
##   for both teams, and the sign of a team's own margin picks its threshold;
## - swapping the two rosters swaps the two behaviours exactly;
## - it cannot activate in a competitive game, cannot activate early, and cannot
##   activate with no time left to rest anyone;
## - both coaches settle once the game is genuinely over;
## - leaving the state is the same rule read backwards, with hysteresis, and it
##   is driven by points the trailing team actually scored;
## - it moves *minutes* and nothing else — no rating, no probability.
##
## The last one is asserted against the resolvers directly rather than inferred
## from an aggregate, because an aggregate cannot tell a rotation from a bonus.

const TOLERANCE: float = 0.000001


# --- the safety number ---------------------------------------------------------

## One number, shared. Both teams read the same safety from the same board;
## nothing about it belongs to a side.
func test_safety_is_one_shared_property_of_the_game() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var ahead: MatchSnapshot = _snapshot_at(input, 4, 300000, 24)
	var behind: MatchSnapshot = _snapshot_at(input, 4, 300000, -24)
	assert_float(GarbageTimeRule.safety(ahead, input, balance))\
		.is_equal(GarbageTimeRule.safety(behind, input, balance))
	assert_float(GarbageTimeRule.safety(ahead, input, balance)).is_greater(0.0)


## A level game is never settled, and the safety of a level game is zero rather
## than a small number that a threshold might one day round past.
func test_a_level_game_has_no_safety_and_no_role() -> void:
	var input: MatchInput = _match()
	var snapshot: MatchSnapshot = _snapshot_at(input, 4, 60000, 0)
	assert_float(GarbageTimeRule.safety(snapshot, input, input.balance_profile)).is_equal(0.0)
	assert_int(GarbageTimeRule.role_for(snapshot, input.home.team_id))\
		.is_equal(GarbageTimeRule.Mode.NONE)
	assert_bool(_enters(input, snapshot, input.home.team_id)).is_false()
	assert_bool(_enters(input, snapshot, input.away.team_id)).is_false()


## Safety grows as the clock runs out at a fixed margin, and grows with the
## margin at a fixed clock. Both directions matter: a rule monotone in only one
## of them is reading half the scoreboard.
func test_safety_grows_with_the_margin_and_with_the_clock_running_out() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var early: float = GarbageTimeRule.safety(_snapshot_at(input, 3, 300000, 20), input, balance)
	var late: float = GarbageTimeRule.safety(_snapshot_at(input, 4, 120000, 20), input, balance)
	assert_float(late).is_greater(early)
	var small: float = GarbageTimeRule.safety(_snapshot_at(input, 4, 300000, 20), input, balance)
	var large: float = GarbageTimeRule.safety(_snapshot_at(input, 4, 300000, 30), input, balance)
	assert_float(large).is_greater(small)


# --- symmetry ------------------------------------------------------------------

## Reversing the scoreboard reverses the two roles and nothing else. The team
## that was protecting is now conceding, on the identical safety, and the
## thresholds follow the role rather than the shirt.
func test_reversing_the_scoreboard_swaps_the_two_roles() -> void:
	var input: MatchInput = _match()
	for margin: int in [18, 22, 26, 32]:
		var ahead: MatchSnapshot = _snapshot_at(input, 4, 240000, margin)
		var behind: MatchSnapshot = _snapshot_at(input, 4, 240000, -margin)
		assert_int(GarbageTimeRule.role_for(ahead, input.home.team_id))\
			.is_equal(GarbageTimeRule.Mode.LEADING)
		assert_int(GarbageTimeRule.role_for(ahead, input.away.team_id))\
			.is_equal(GarbageTimeRule.Mode.TRAILING)
		# Home at +m behaves exactly as away does at -m, and vice versa.
		assert_bool(_enters(input, ahead, input.home.team_id))\
			.override_failure_message("margin %d" % margin)\
			.is_equal(_enters(input, behind, input.away.team_id))
		assert_bool(_enters(input, ahead, input.away.team_id))\
			.is_equal(_enters(input, behind, input.home.team_id))


## Equal score and clock produce an identical decision whoever is holding it,
## and the decision is blind to who the players are: replacing both rosters with
## much stronger ones changes nothing, which is the direct statement that the
## rule cannot read strength, an intended winner, or a target final margin.
func test_the_rule_cannot_read_strength_or_an_intended_winner() -> void:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var weak: MatchInput = _tilted_match(competition, -6.0)
	var strong: MatchInput = _tilted_match(competition, 6.0)
	var weak_state: MatchSnapshot = _snapshot_at(weak, 4, 240000, 24)
	var strong_state: MatchSnapshot = _snapshot_at(strong, 4, 240000, 24)
	assert_float(GarbageTimeRule.safety(weak_state, weak, weak.balance_profile))\
		.is_equal(GarbageTimeRule.safety(strong_state, strong, strong.balance_profile))
	assert_bool(_enters(weak, weak_state, weak.home.team_id))\
		.is_equal(_enters(strong, strong_state, strong.home.team_id))


# --- the leading team rests earlier --------------------------------------------

## The whole of the correction, as one assertion: there is a window in which the
## leading coach has settled and the trailing coach has not, and it is the
## leading one who is there first.
func test_the_leading_coach_settles_before_the_trailing_one() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	assert_float(balance.settled_leading_safety).is_less(balance.settled_trailing_safety)

	var window: int = 0
	var both: int = 0
	# Walk the final period at a settled margin. Early in it neither coach has
	# moved; there is a stretch where only the leader has; by the end both have.
	for clock: int in [600000, 540000, 480000, 420000, 360000, 300000,
			240000, 180000, 120000, 60000, 30000]:
		var snapshot: MatchSnapshot = _snapshot_at(input, 4, clock, 22)
		var leader: bool = _enters(input, snapshot, input.home.team_id)
		var trailer: bool = _enters(input, snapshot, input.away.team_id)
		# The trailing coach never concedes before the leading one settles.
		assert_bool(trailer and not leader)\
			.override_failure_message("clock %d" % clock).is_false()
		if leader and not trailer:
			window += 1
		if leader and trailer:
			both += 1
	assert_int(window).override_failure_message(
		"there is no clock at which only the leading coach has settled").is_greater(0)
	assert_int(both).override_failure_message(
		"both coaches never settle, however decided the game becomes").is_greater(0)


## Neither coach settles while the game is competitive, at any clock. A margin
## below the coaching floor is never settled however safe the arithmetic says it
## is, which is the guard that keeps a twelve-point game a game.
func test_garbage_time_cannot_activate_in_a_close_game() -> void:
	var input: MatchInput = _match()
	var floor_margin: int = input.balance_profile.settled_minimum_margin
	assert_int(floor_margin).is_greater_equal(12)
	assert_int(floor_margin).is_less_equal(30)
	for margin: int in [1, 3, 5, 8, 11, floor_margin - 1]:
		for clock: int in [600000, 300000, 60000, 20000, 5000]:
			for signed: int in [margin, -margin]:
				var snapshot: MatchSnapshot = _snapshot_at(input, 4, clock, signed)
				assert_bool(_enters(input, snapshot, input.home.team_id))\
					.override_failure_message("margin %d clock %d" % [signed, clock])\
					.is_false()
				assert_bool(_enters(input, snapshot, input.away.team_id)).is_false()


## And neither settles early, however large the margin, because a lead is safe
## against what is left to play rather than against a number.
func test_garbage_time_cannot_activate_too_early() -> void:
	var input: MatchInput = _match()
	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in [18, 24, 30]:
		var snapshot: MatchSnapshot = _snapshot_at(
			input, 1, rules.period_length_ms(1) / 2, margin)
		assert_bool(_enters(input, snapshot, input.home.team_id))\
			.override_failure_message("margin %d in the first period" % margin).is_false()
		assert_bool(_enters(input, snapshot, input.away.team_id)).is_false()
	# A very large early margin does eventually qualify, and it should: forty
	# points at half time is not a competitive game. What must not happen is
	# eighteen points qualifying there.
	var huge: MatchSnapshot = _snapshot_at(input, 2, 1, 55)
	assert_bool(_enters(input, huge, input.home.team_id)).is_true()


## With less than a possession pair left there is no rest to give, so a coach
## who has not already settled does not start now.
func test_garbage_time_does_not_begin_with_no_time_to_rest_anyone() -> void:
	var input: MatchInput = _match()
	var snapshot: MatchSnapshot = _snapshot_at(input, 4, 4000, 30)
	assert_float(GarbageTimeRule.safety(snapshot, input, input.balance_profile))\
		.is_greater(input.balance_profile.settled_trailing_safety)
	assert_bool(_enters(input, snapshot, input.home.team_id)).is_false()
	assert_bool(_enters(input, snapshot, input.away.team_id)).is_false()


# --- leaving again --------------------------------------------------------------

## Re-entry into the competitive rotation is the same rule read backwards, with
## hysteresis, and it is symmetric: whichever coach holds the state leaves it on
## the identical condition.
func test_returning_to_the_competitive_rotation_is_rule_based_and_symmetric() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	assert_float(balance.settled_release_share).is_less_equal(1.0)
	assert_float(balance.settled_release_share).is_greater_equal(0.5)

	# Settled at 26 with four minutes left; the trailing team then scores.
	var settled: MatchSnapshot = _snapshot_at(input, 4, 240000, 26)
	settled.home.settled_mode = GarbageTimeRule.Mode.LEADING
	settled.away.settled_mode = GarbageTimeRule.Mode.TRAILING
	assert_bool(_leaves(input, settled, input.home.team_id)).is_false()

	var narrowed: MatchSnapshot = _snapshot_at(input, 4, 240000, 12)
	narrowed.home.settled_mode = GarbageTimeRule.Mode.LEADING
	narrowed.away.settled_mode = GarbageTimeRule.Mode.TRAILING
	assert_bool(_leaves(input, narrowed, input.home.team_id)).is_true()
	assert_bool(_leaves(input, narrowed, input.away.team_id)).is_true()

	# Mirrored: the away side holding the lead leaves on the same condition.
	var mirrored: MatchSnapshot = _snapshot_at(input, 4, 240000, -12)
	mirrored.home.settled_mode = GarbageTimeRule.Mode.TRAILING
	mirrored.away.settled_mode = GarbageTimeRule.Mode.LEADING
	assert_bool(_leaves(input, mirrored, input.away.team_id)).is_true()


## Hysteresis is real: the state survives a safety that would not have entered
## it, and only lets go below the release share. Without this a game balanced on
## the threshold alternates rotations every possession.
##
## The qualifying state is searched for rather than hard-coded, because the
## safety at a given clock is a function of the pace the fixture happens to
## play at and a literal would be asserting the fixture rather than the rule.
func test_the_state_has_hysteresis() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var entry: float = balance.settled_leading_safety
	var release: float = entry * balance.settled_release_share
	assert_float(release).is_less(entry)

	var found: bool = false
	for period: int in [3, 4]:
		for step: int in range(1, 40):
			var clock: int = step * 20000
			if clock > input.rule_profile.period_length_ms(period):
				break
			var snapshot: MatchSnapshot = _snapshot_at(input, period, clock, 24)
			var safety: float = GarbageTimeRule.safety(snapshot, input, balance)
			if safety >= entry or safety < release:
				continue
			found = true
			# Entry is refused at this safety.
			assert_bool(_enters(input, snapshot, input.home.team_id))\
				.override_failure_message("safety %f entered" % safety).is_false()
			# A team already settled stays settled at the identical state.
			snapshot.home.settled_mode = GarbageTimeRule.Mode.LEADING
			assert_bool(_leaves(input, snapshot, input.home.team_id))\
				.override_failure_message("safety %f released" % safety).is_false()
			break
		if found:
			break
	assert_bool(found).override_failure_message(
		"no state was found between the release and entry thresholds").is_true()


## A lead that changes hands ends the state for both coaches whatever the
## arithmetic says, because neither of them is doing what he was doing.
func test_a_lead_changing_hands_ends_the_state() -> void:
	var input: MatchInput = _match()
	var reversed: MatchSnapshot = _snapshot_at(input, 4, 240000, -25)
	reversed.home.settled_mode = GarbageTimeRule.Mode.LEADING
	assert_bool(_leaves(input, reversed, input.home.team_id)).is_true()


# --- nothing but minutes --------------------------------------------------------

## The same physical shot has the same make probability whatever the margin, in
## the settled state and out of it. Held fixed: shooter, defender, zone,
## contest, lineup, clock and random stream.
func test_the_same_shot_keeps_its_probability_in_and_out_of_garbage_time() -> void:
	var input: MatchInput = _match()
	var level: float = _shot_probability(input, _snapshot_at(input, 4, 240000, 0), false)
	assert_float(level).is_greater(0.0)
	assert_float(_shot_probability(input, _snapshot_at(input, 4, 240000, 30), false))\
		.is_equal(level)
	assert_float(_shot_probability(input, _snapshot_at(input, 4, 240000, -30), false))\
		.is_equal(level)
	# And the settled flag itself reaches no resolver.
	assert_float(_shot_probability(input, _snapshot_at(input, 4, 240000, 30), true))\
		.is_equal(level)
	assert_float(_shot_probability(input, _snapshot_at(input, 4, 240000, -30), true))\
		.is_equal(level)


## The trailing team is given no rating and no bonus. Capabilities resolved for
## the same player in the same lineup are identical whether his team is settled,
## ahead, or behind.
func test_the_trailing_team_receives_no_rating_or_capability_bonus() -> void:
	var input: MatchInput = _match()
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var reference: float = -1.0
	for margin: int in [0, 30, -30]:
		for settled: bool in [false, true]:
			var snapshot: MatchSnapshot = _snapshot_at(input, 4, 240000, margin)
			if settled:
				snapshot.home.settled_mode = GarbageTimeRule.Mode.TRAILING
				snapshot.away.settled_mode = GarbageTimeRule.Mode.TRAILING
			var shooter_id: StringName = input.home.starters()[0]
			var value: float = capability.capability_of(
				CapabilityKey.Value.THREE_POINT_SHOTMAKING,
				input.home.player_by_id(shooter_id),
				snapshot.home.runtime_by_id(shooter_id))
			if reference < 0.0:
				reference = value
			assert_float(value).override_failure_message(
				"margin %d settled %s" % [margin, settled]).is_equal(reference)


# --- interaction with the rest of the late game ---------------------------------

## Deliberate late-game fouling and the settled rotation cannot both apply.
## Fouling needs the defence within six points; settling needs eighteen. The two
## windows are disjoint by construction and the test says so at the boundary.
func test_intentional_fouling_and_garbage_time_cannot_overlap() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	assert_int(balance.intentional_foul_max_margin).is_less(balance.settled_minimum_margin)
	for margin: int in range(1, balance.settled_minimum_margin + 6):
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, 20000, margin)
		var foulable: bool = (
			margin > 0 and margin <= balance.intentional_foul_max_margin)
		var settled: bool = (
			_enters(input, snapshot, input.home.team_id)
			or _enters(input, snapshot, input.away.team_id))
		assert_bool(foulable and settled)\
			.override_failure_message("margin %d" % margin).is_false()


## Timeouts stay valid through the settled state: a coach still holds an
## allowance, still spends it only on a qualifying run, and never spends more
## than he has.
func test_timeout_logic_survives_the_settled_state() -> void:
	var input: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 77, 0.5)
	var allowance: int = input.rule_profile.timeouts_per_team
	for seed_value: int in [5511, 5512, 5513]:
		var session := MatchSession.new(input, SeededRandomSource.new(seed_value))
		var output: MatchSimulationOutput = session.run_to_completion()
		var home_called: int = 0
		var away_called: int = 0
		for event in output.events:
			if event.event_type != MatchDomainEvent.TIMEOUT:
				continue
			if event.team_id == input.home.team_id:
				home_called += 1
			else:
				away_called += 1
		assert_int(home_called).is_less_equal(allowance)
		assert_int(away_called).is_less_equal(allowance)
		var final_state: MatchSnapshot = session.snapshot()
		assert_int(final_state.home.timeouts_remaining).is_equal(allowance - home_called)
		assert_int(final_state.away.timeouts_remaining).is_equal(allowance - away_called)


# --- the ledger -----------------------------------------------------------------

## Every settled-game substitution in a played game is preceded by a
## `GARBAGE_TIME` entry for the same team that has not been resumed, and every
## entry names a mode and carries the margin it was taken at. A rotation the
## ledger cannot explain is the defect this asserts against.
func test_every_settled_substitution_is_explained_by_a_ledger_entry() -> void:
	var input: MatchInput = _population_match(41)
	var explained: int = 0
	for seed_value: int in [6601, 6602, 6603, 6604, 6605, 6606]:
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		var home_settled: bool = false
		var away_settled: bool = false
		for event in output.events:
			if event.event_type == MatchDomainEvent.GARBAGE_TIME:
				assert_bool(event.detail_id == &"entered" or event.detail_id == &"resumed")\
					.override_failure_message("unknown transition '%s'"
						% String(event.detail_id)).is_true()
				var mode: int = GarbageTimeRule.mode_from_id(event.action_id)
				assert_bool(GarbageTimeRule.is_valid_mode(mode)).is_true()
				if event.detail_id == &"entered":
					assert_int(mode).is_not_equal(GarbageTimeRule.Mode.NONE)
					assert_int(absi(event.amount))\
						.is_greater_equal(input.balance_profile.settled_minimum_margin)
					# The mode matches the sign of the margin it was taken at.
					var expected: int = (
						GarbageTimeRule.Mode.LEADING if event.amount > 0
						else GarbageTimeRule.Mode.TRAILING)
					assert_int(mode).is_equal(expected)
				if event.team_id == input.home.team_id:
					home_settled = event.detail_id == &"entered"
				else:
					away_settled = event.detail_id == &"entered"
				continue
			if event.event_type != MatchDomainEvent.CHECK_IN:
				continue
			if event.detail_id != SubstitutionOrder.new(
					&"a", &"b", SubstitutionOrder.Reason.DECIDED_GAME).reason_id():
				continue
			var live: bool = (
				home_settled if event.team_id == input.home.team_id else away_settled)
			assert_bool(live).override_failure_message(
				"a settled-game check-in with no live garbage-time entry").is_true()
			explained += 1
	assert_int(explained).override_failure_message(
		"no settled-game substitution occurred in six games; the rule is unreachable")\
		.is_greater(0)


# --- reconciliation, determinism and isolation ----------------------------------

## Minutes and lineup participation still reconcile from the ledger with the new
## event in it.
##
## Three claims, and the middle one is the one a rotation change can break: five
## players per team on court at every point of the ledger, every check-out
## matched by a live check-in, and total team minutes within one per cent of
## five times the game. A lost player or a double-counted one is worth twenty
## per cent of a team's minutes, so one per cent discriminates comfortably —
## while leaving room for the fraction of a second of period-end clock that the
## reducer does not charge to anybody, which predates this rule and belongs to
## the clock model rather than to the rotation.
func test_minutes_and_lineup_participation_reconcile() -> void:
	var input: MatchInput = _population_match(42)
	for seed_value: int in [7701, 7702]:
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(7000 + seed_value))
		var regulation: int = input.rule_profile.regulation_periods
		var periods: int = regulation + output.final_result.overtime_periods
		var expected: float = 0.0
		for index in range(periods):
			expected += float(input.rule_profile.period_length_ms(index + 1)) / 60000.0

		var on_court: Dictionary = {}
		for event in output.events:
			if event.event_type == MatchDomainEvent.CHECK_IN:
				assert_bool(on_court.has(event.primary_player_id)).override_failure_message(
					"a player checked in while already on court").is_false()
				on_court[event.primary_player_id] = event.team_id
			elif event.event_type == MatchDomainEvent.CHECK_OUT:
				assert_bool(on_court.has(event.primary_player_id)).override_failure_message(
					"a player checked out without being on court").is_true()
				on_court.erase(event.primary_player_id)
		assert_int(on_court.size()).override_failure_message(
			"the match ended with %d players on court" % on_court.size()).is_equal(10)

		for team: TeamMatchProfile in [input.home, input.away]:
			var minutes: float = 0.0
			for line: PlayerStatLine in output.final_result.statistics.players_for(team.team_id):
				assert_float(line.minutes_played()).is_greater_equal(0.0)
				minutes += line.minutes_played()
			var target: float = expected * 5.0
			assert_float(absf(minutes - target) / target).override_failure_message(
				"team %s played %f minutes against %f expected"
					% [team.team_id, minutes, target])\
				.is_less(0.01)


## Play, Sim and Skip produce the identical ledger with the settled state in it,
## and the same seed reproduces it byte for byte.
func test_play_sim_and_skip_agree_with_the_settled_state() -> void:
	var input: MatchInput = _population_match(43)
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(8801))
	var stepped := MatchSession.new(input, SeededRandomSource.new(8801))
	stepped.open()
	while not stepped.is_complete():
		stepped.advance_possession()
	var played: MatchSimulationOutput = stepped.build_output()
	var skipped: MatchSimulationOutput = MatchSession.new(
		input, SeededRandomSource.new(8801)).skip_to_final_result()
	var reference: String = MatchLedgerSerializer.hash_output(simulated)
	assert_str(MatchLedgerSerializer.hash_output(played)).is_equal(reference)
	assert_str(MatchLedgerSerializer.hash_output(skipped)).is_equal(reference)
	assert_str(MatchLedgerSerializer.hash_output(
		MatchEngine.new().simulate_match(input, SeededRandomSource.new(8801))))\
		.is_equal(reference)


## The settled state does not survive a game. Simulating other matches between
## two runs of the same one reproduces its ledger exactly.
func test_the_settled_state_does_not_leak_between_games() -> void:
	var input: MatchInput = _population_match(44)
	var first: String = MatchLedgerSerializer.hash_output(
		MatchEngine.new().simulate_match(input, SeededRandomSource.new(9901)))
	for interference: int in [45, 46, 47]:
		MatchEngine.new().simulate_match(
			_population_match(interference), SeededRandomSource.new(interference))
	assert_str(MatchLedgerSerializer.hash_output(
		MatchEngine.new().simulate_match(input, SeededRandomSource.new(9901))))\
		.is_equal(first)


## The safety number obeys the square-root law it is built on.
##
## The margin still to be played is a sum over the remaining possession pairs,
## so its standard deviation grows with the square root of them — which means
## **doubling the margin is exactly equivalent to quadrupling the possessions
## left**. That equivalence is the whole reason one constant serves five
## competitions and three period lengths, and it is the property a rule that
## divided by the possessions, or compared against a fixed clock, would break
## while still ordering the extremes correctly.
func test_safety_obeys_the_square_root_law() -> void:
	var input: MatchInput = _match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var final_period: int = rules.regulation_periods
	# A late state, and an earlier one with four times the regulation left.
	var late: MatchSnapshot = _snapshot_at(input, final_period, 150000, 14)
	var early: MatchSnapshot = _snapshot_at(input, final_period, 600000, 28)
	var late_pairs: float = GameManagement.possession_pairs_left(late, input)
	var early_pairs: float = GameManagement.possession_pairs_left(early, input)
	assert_float(early_pairs / late_pairs).override_failure_message(
		"the fixture did not produce a four-to-one ratio of possessions left")\
		.is_equal_approx(4.0, 0.05)
	assert_float(GarbageTimeRule.safety(early, input, balance)).is_equal_approx(
		GarbageTimeRule.safety(late, input, balance), 0.05)

	# And halving the margin at a fixed clock halves the safety, which pins the
	# numerator as well as the denominator.
	var half: MatchSnapshot = _snapshot_at(input, final_period, 150000, 7)
	assert_float(GarbageTimeRule.safety(half, input, balance) * 2.0).is_equal_approx(
		GarbageTimeRule.safety(late, input, balance), TOLERANCE)


## Thresholds scale with the competition rather than with a hard-coded clock.
## The same margin at the same *share* of the game remaining reaches the same
## decision in a thirty-two-minute school game and a forty-eight-minute
## professional one, because the safety number is built from possessions.
func test_the_thresholds_scale_across_game_lengths() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var input: MatchInput = CompetitionCatalog.mirrored_match_for(competition, 5, 0.0)
		var rules: CompetitionRuleProfile = input.rule_profile
		var final_period: int = rules.regulation_periods
		var quarter: int = rules.period_length_ms(final_period) / 4
		# A settled margin with a quarter of the last period left settles the
		# leader everywhere; a competitive one settles nobody anywhere.
		var settled: MatchSnapshot = _snapshot_at(input, final_period, quarter, 26)
		assert_bool(_enters(input, settled, input.home.team_id))\
			.override_failure_message(String(rules.profile_id)).is_true()
		var competitive: MatchSnapshot = _snapshot_at(input, final_period, quarter, 8)
		assert_bool(_enters(input, competitive, input.home.team_id))\
			.override_failure_message(String(rules.profile_id)).is_false()
		assert_bool(_enters(input, competitive, input.away.team_id)).is_false()
		# And nobody settles in the first period at that margin, in any of them.
		var early: MatchSnapshot = _snapshot_at(input, 1, rules.period_length_ms(1) / 2, 26)
		assert_bool(_enters(input, early, input.home.team_id))\
			.override_failure_message(String(rules.profile_id)).is_false()


# --- helpers ---------------------------------------------------------------------

func _match() -> MatchInput:
	return CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 3, 0.0)


func _population_match(variation: int) -> MatchInput:
	return CompetitionCatalog.match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, 0.5)


## A snapshot at a stated period, clock and home-minus-away margin, with a
## realized pace already on the board so the safety number has something to
## read.
func _snapshot_at(
	input: MatchInput,
	period: int,
	clock_ms: int,
	margin: int,
) -> MatchSnapshot:
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot := MatchSnapshot.new(input)
	snapshot.period = period
	snapshot.clock_ms = clock_ms
	snapshot.shot_clock_ms = mini(rules.shot_clock_seconds * 1000, clock_ms)
	var elapsed: int = GameManagement.elapsed_ms(snapshot, rules)
	# Two team possessions per pair, one pair per fourteen-and-a-bit seconds:
	# the pace every top-domestic report measures, scaled by the competition's
	# own pace environment so a slow competition reads as a slow one.
	var pair_ms: float = 14300.0 * 2.0 * rules.pace_multiplier
	snapshot.possession_sequence = maxi(1, int(roundf(float(elapsed) * 2.0 / pair_ms)))
	snapshot.home.score = 80 + maxi(margin, 0)
	snapshot.away.score = 80 + maxi(-margin, 0)
	return snapshot


func _enters(input: MatchInput, snapshot: MatchSnapshot, team_id: StringName) -> bool:
	return GarbageTimeRule.should_enter(
		snapshot, input, input.balance_profile, team_id)


func _leaves(input: MatchInput, snapshot: MatchSnapshot, team_id: StringName) -> bool:
	return GarbageTimeRule.should_leave(
		snapshot, input, input.balance_profile, team_id)


## The resolved make probability for a fixed shooter, defender and zone, read
## off the outcome the resolver returns rather than recomputed here.
func _shot_probability(
	input: MatchInput,
	snapshot: MatchSnapshot,
	settled: bool,
) -> float:
	if settled:
		snapshot.home.settled_mode = GarbageTimeRule.Mode.LEADING
		snapshot.away.settled_mode = GarbageTimeRule.Mode.TRAILING
	var context := PossessionContext.new(
		input, snapshot, input.home.team_id, MatchupState.new({}), 1)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := ShotResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)
	var contest := ShotContest.new(
		ContestBand.Value.OPEN, input.away.starters()[0], &"", false, false, 0.2, 0.0)
	var outcome: ShotOutcome = resolver.resolve(
		context, input.home.starters()[0], ShotZone.Value.MIDRANGE, false, contest,
		AdvantageResult.new(), 1.0, 0.0, SeededRandomSource.new(4242))
	return outcome.probability


## Two rosters built from the same variation, both moved by the same rating
## offset, so the matchup is unchanged and only the absolute quality moves.
func _tilted_match(competition: int, offset: float) -> MatchInput:
	var balance := SimulationBalanceProfile.new()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", 12, balance, offset)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", 13, balance, offset)
	return MatchInput.new(
		&"garbage_match",
		&"garbage_game",
		CompetitionCatalog.rules_for(competition),
		balance,
		home,
		away,
		home.team_id,
		CompetitionCatalog.ratings_profile(),
		0.0)
