class_name TestEndgameCorrections
extends GdUnitTestSuite

## The explicit regression fixtures for the nine behaviours `EndgameStrategy`
## got wrong when it first shipped under `simulation-v9-endgame-strategy`, and
## that `simulation-v10-endgame-corrections` changes (`PROJECT_STATUS.md`
## §5.26).
##
## `test_endgame_strategy.gd` proves each decision's gate in isolation. This
## suite is deliberately separate and deliberately narrow: one named fixture per
## corrected behaviour, each written so that reintroducing the original defect
## fails it, and each stating in its own name which defect it stands against.
## Where the correction is about what a coach does rather than what a predicate
## returns, the fixture drives a real possession or a real match through the
## public path and reads the ledger, because a predicate that is right and a
## ledger that is wrong is exactly the failure mode the v9 measurements did not
## catch.
##
## The nine, in the order the correction brief lists them:
##
## 1. college advancement refusal
## 2. top-domestic advancement eligibility
## 3. timeout-reserve preservation
## 4. tied-team final-shot hold
## 5. comfortable-lead clock drain
## 6. trailing intentional miss
## 7. live rebound following the miss
## 8. leading-team refusal to intentionally miss
## 9. non-bonus and repeated leading-foul prevention


# --- 1. college advancement refusal --------------------------------------------

## College does not advance the ball on a timeout. The grant it briefly carried
## came from reading the 2026-09-01 overtime ruling as though it had settled a
## §4 rule question, which it had not: a competition's rules are what the
## competition is, never what a §14.2 band is short of.
##
## Proven twice — at the rule profile, and at the decision under a state where
## every other condition holds, so the refusal is the flag's doing and not an
## accident of the fixture.
func test_college_refuses_to_advance_the_ball_on_a_timeout() -> void:
	var balance := SimulationBalanceProfile.new()
	var college: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.COLLEGE)
	assert_bool(college.timeout_advance_permitted).override_failure_message(
		"college must not grant timeout-advance").is_false()

	var snapshot: MatchSnapshot = _eligible_advance_snapshot(college, balance)
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, college, balance, &"home", false, false)).is_false()

	# The same state under the same college rules with only the grant flipped,
	# so the refusal is proven to be the flag's doing rather than an accident of
	# the fixture. Nothing else about the profile — clock, periods, shot clock,
	# allowance — differs between the two calls.
	var granted: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.COLLEGE)
	granted.timeout_advance_permitted = true
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, granted, balance, &"home", false, false)).is_true()


## And no college game produces one, which is the ledger-level statement of the
## same thing.
func test_no_college_game_emits_an_advance_timeout() -> void:
	for variation in range(960000, 960006):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.COLLEGE, variation, 0.5)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		assert_int(_count_advance_timeouts(output.events)).override_failure_message(
			"college game %d called an advance timeout" % variation).is_equal(0)


# --- 2. top-domestic advancement eligibility -----------------------------------

## The one competition the rule belongs to keeps it, and keeps it reachable:
## narrowing the decision must not quietly turn it off.
func test_top_domestic_still_advances_the_ball_when_a_coach_would() -> void:
	var balance := SimulationBalanceProfile.new()
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO)
	assert_bool(rules.timeout_advance_permitted).is_true()
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		_eligible_advance_snapshot(rules, balance), rules, balance, &"home", false, false)
	).is_true()


func test_the_advance_timeout_is_still_reachable_in_real_top_domestic_games() -> void:
	var found: int = 0
	for variation in range(960000, 960030):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, 0.5)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		found += _count_advance_timeouts(output.events)
	assert_int(found).override_failure_message(
		"the advance timeout never fired in 30 top domestic games; the correction "
		+ "turned the decision off rather than narrowing it").is_greater(0)


# --- 3. timeout-reserve preservation -------------------------------------------

## A coach keeps allowances in hand. Spending the last one to save a backcourt
## walk costs him the ability to stop the clock on the possession that follows,
## which is the larger of the two things.
##
## The run-stopping timeout stops being callable at `timeout_run_reserve_ms`
## (90 seconds) and the advance window opens at `timeout_advance_window_ms`
## (28), so nothing but an advance timeout can be called once the first one has
## been. A team that called any therefore has to finish the match still holding
## at least the reserve — the ledger statement of a bound that is otherwise
## only a predicate.
func test_an_advancing_team_finishes_the_match_still_holding_its_reserve() -> void:
	var balance := SimulationBalanceProfile.new()
	var reserve: int = balance.timeout_advance_reserve_timeouts
	assert_int(reserve).is_greater(0)
	assert_int(balance.timeout_advance_window_ms).is_less(balance.timeout_run_reserve_ms)

	var checked: int = 0
	for variation in range(960000, 960030):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, 0.5)
		var session := MatchSession.new(input, SeededRandomSource.new(variation + 1))
		var output: MatchSimulationOutput = session.run_to_completion()
		var final_state: MatchSnapshot = session.snapshot()
		for team_id: StringName in [input.home.team_id, input.away.team_id]:
			if _count_advance_timeouts(output.events, team_id) == 0:
				continue
			checked += 1
			assert_int(final_state.state_for(team_id).timeouts_remaining)\
				.override_failure_message(
					"%s advanced the ball in game %d and finished below the reserve"
					% [team_id, variation])\
				.is_greater_equal(reserve)
	assert_int(checked).override_failure_message(
		"no team called an advance timeout, so the reserve was never tested"
	).is_greater(0)


# --- 4. tied-team final-shot hold ----------------------------------------------

## Holding for the last shot of a tied game is the most ordinary
## end-of-regulation decision in basketball, and the first version of the rule
## refused it at every clock. It is admitted now on the condition that makes it
## a plan rather than a shot-clock violation: the shot clock has to outlast the
## game clock.
func test_a_tied_team_holds_for_the_final_shot() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var actor: StringName = input.home.starters()[0]

	var snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 16000, 0)
	snapshot.shot_clock_ms = 22000
	var tied: PossessionContext = _context(input, snapshot, input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(tied, balance)).is_true()
	# And the hold is not merely eligible: it reaches the reset it exists to
	# add weight to.
	assert_float(EndgameStrategy.action_multiplier(
		tied, balance, ActionFamily.Value.RESET, -1, actor, &"")
	).is_equal_approx(1.0 + balance.hold_reset_gain, 0.0001)

	# With a shot clock that expires first, holding would hand the ball back,
	# so the tied team wants the extra possession instead.
	snapshot.shot_clock_ms = 7000
	var would_violate: PossessionContext = _context(input, snapshot, input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(would_violate, balance)).is_false()


# --- 5. comfortable-lead clock drain -------------------------------------------

## A team with a safe lead wants the clock, not its closer's best look. The
## first version boosted the designated closer at every margin, which pushed a
## winning team toward an early attempt in games it had already won.
##
## The fixture states both halves: no boost for the closer, and the clock-drain
## weight on the reset still in place, so what replaced the boost is the
## draining the situation actually calls for rather than nothing at all.
func test_a_comfortable_lead_drains_the_clock_instead_of_boosting_its_closer() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var closer: StringName = input.home.starters()[0]
	var snapshot: MatchSnapshot = _snapshot_at(
		input, rules.regulation_periods, balance.designed_play_window_ms - 3000, 12)
	snapshot.shot_clock_ms = rules.shot_clock_seconds * 1000
	var context: PossessionContext = _context(input, snapshot, input.home.team_id)

	assert_bool(EndgameStrategy.designed_play_active(context, balance)).is_false()
	assert_float(EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.MIDRANGE, closer, closer)
	).override_failure_message("a safe lead boosted its closer's shot").is_equal(1.0)

	assert_bool(EndgameStrategy.hold_for_final_shot_active(context, balance)).is_true()
	assert_float(EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.RESET, -1, closer, closer)
	).is_equal_approx(1.0 + balance.hold_reset_gain, 0.0001)


# --- 6/7/8. the intentional miss, its rebound, and who never takes it ----------

## The scenario the tactic exists for, driven through the possession engine
## rather than asserted about a predicate: the defence is up three inside its
## own window and in the bonus, so it fouls; the offence shoots two; the first
## goes in, leaving it down two with one to shoot; and that last attempt is
## missed on purpose, because the point cannot tie the game and a live rebound
## can.
func test_a_trailing_team_intentionally_misses_its_final_free_throw() -> void:
	var possession: PossessionResult = _first_intentional_miss_possession()
	assert_object(possession).override_failure_message(
		"the intentional miss was not reachable in any seeded trailing-team trip"
	).is_not_null()

	var misses: Array[MatchDomainEvent] = possession.events.filter(
		func(event: MatchDomainEvent) -> bool:
			return (
				event.event_type == MatchDomainEvent.FREE_THROW_MISSED
				and event.detail_id == &"intentional"))
	assert_int(misses.size()).is_equal(1)
	# The last attempt of the trip, and only it.
	var awarded: MatchDomainEvent = _first_of(
		possession.events, MatchDomainEvent.FREE_THROW_AWARDED)
	assert_int(misses[0].amount).is_equal(awarded.amount)
	# The team that took it was the trailing one.
	assert_str(String(misses[0].team_id)).is_equal("home")


## The miss enters the ordinary live free-throw rebound the rules already
## define for a missed final attempt. It is not an automatic possession
## outcome: a `REBOUND` event follows it, resolved by the same rebound resolver
## against the same defence as any other miss, and the offence keeps the ball
## only when it actually wins the board.
func test_the_intentional_miss_enters_the_ordinary_live_rebound() -> void:
	var possession: PossessionResult = _first_intentional_miss_possession()
	assert_object(possession).is_not_null()

	var index: int = _index_of_intentional_miss(possession.events)
	assert_int(index).is_greater_equal(0)
	var rebound: MatchDomainEvent = null
	for offset in range(index + 1, possession.events.size()):
		if possession.events[offset].event_type == MatchDomainEvent.REBOUND:
			rebound = possession.events[offset]
			break
	assert_object(rebound).override_failure_message(
		"no rebound followed the intentional miss, so the ball was awarded rather "
		+ "than contested").is_not_null()
	assert_bool(
		rebound.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE
		or rebound.detail_id == MatchDomainEvent.REBOUND_DEFENSIVE
	).is_true()
	# There is no free-throw event between the miss and the board: the rebound
	# is the next thing that happens to the ball.
	for offset in range(index + 1, possession.events.size()):
		var event: MatchDomainEvent = possession.events[offset]
		if event.event_type == MatchDomainEvent.REBOUND:
			break
		assert_bool(
			event.event_type == MatchDomainEvent.FREE_THROW_MADE
			or event.event_type == MatchDomainEvent.FREE_THROW_MISSED
		).override_failure_message("another free throw followed the final attempt").is_false()


## And the board is genuinely contested — across seeds the defence wins it too.
## A decision that always produced an offensive rebound would be an award of
## the ball dressed as a miss, which is the shape this fixture exists to forbid.
func test_the_defence_can_win_the_board_after_an_intentional_miss() -> void:
	var offensive: int = 0
	var defensive: int = 0
	for seed_value in range(4000, 4160):
		var possession: PossessionResult = _intentional_miss_possession(seed_value)
		if possession == null:
			continue
		var index: int = _index_of_intentional_miss(possession.events)
		if index < 0:
			continue
		for offset in range(index + 1, possession.events.size()):
			if possession.events[offset].event_type != MatchDomainEvent.REBOUND:
				continue
			if possession.events[offset].detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
				offensive += 1
			else:
				defensive += 1
			break
	assert_int(offensive + defensive).override_failure_message(
		"no intentional miss was reachable at all").is_greater(0)
	assert_int(defensive).override_failure_message(
		"the defence never won a board after an intentional miss in %d attempts; "
		% (offensive + defensive)
		+ "the miss is an automatic possession outcome rather than a live ball"
	).is_greater(0)


## The mirror image, which is the defect this correction is for: the *leading*
## team at the line. The first version of the rule fired here — for a shooting
## team ahead by two or three — which inverted the tactic entirely. It must
## never fire now, at any lead, and the same fixture that produces an
## intentional miss for a trailing team must produce none when the scores are
## the other way round.
func test_a_leading_team_at_the_line_never_intentionally_misses() -> void:
	for seed_value in range(4000, 4160):
		var possession: PossessionResult = _intentional_miss_possession(seed_value, 3)
		if possession == null:
			continue
		assert_int(_index_of_intentional_miss(possession.events))\
			.override_failure_message(
				"a team leading by three intentionally missed on seed %d" % seed_value)\
			.is_equal(-1)


# --- 9. non-bonus and repeated leading-foul prevention -------------------------

## Below the team-foul threshold the leading-by-three whistle awards nothing:
## the offence keeps the ball, inbounds with a fresh shot clock, and can still
## shoot the three the foul was meant to prevent. The defence would have paid a
## team foul for the opposite of what it wanted.
func test_no_leading_by_three_foul_is_committed_outside_the_bonus() -> void:
	var input: MatchInput = _leading_foul_input()
	var engine := PossessionEngine.new(input)
	var rules: CompetitionRuleProfile = input.rule_profile
	for team_fouls: int in range(0, rules.team_foul_bonus_threshold):
		assert_int(rules.bonus_free_throws_for(team_fouls)).is_equal(0)
		for seed_value in range(7000, 7020):
			var snapshot: MatchSnapshot = _leading_foul_snapshot(input, team_fouls)
			var possession: PossessionResult = engine.simulate(
				snapshot, input, SeededRandomSource.new(seed_value), false, false)
			assert_int(_count_leading_protect_fouls(possession.events))\
				.override_failure_message(
					"a leading-by-three foul was committed at %d team fouls, which "
					% team_fouls + "awards no free throws")\
				.is_equal(0)


## And in the bonus, where the whistle does send the offence to the line, it is
## one decision rather than a standing condition: the eligibility that produced
## the first whistle still held on the action after it, so without an explicit
## guard the same defence fouled the same possession again and again.
func test_at_most_one_leading_by_three_foul_per_possession() -> void:
	var input: MatchInput = _leading_foul_input()
	var engine := PossessionEngine.new(input)
	var fouled: int = 0
	for seed_value in range(7000, 7060):
		var snapshot: MatchSnapshot = _leading_foul_snapshot(
			input, input.rule_profile.team_foul_bonus_threshold)
		var possession: PossessionResult = engine.simulate(
			snapshot, input, SeededRandomSource.new(seed_value), false, false)
		var count: int = _count_leading_protect_fouls(possession.events)
		assert_int(count).override_failure_message(
			"seed %d committed %d leading-by-three fouls in one possession"
			% [seed_value, count]).is_less_equal(1)
		fouled += count
	assert_int(fouled).override_failure_message(
		"the leading-by-three foul never fired in the bonus, so the once-per-"
		+ "possession bound was never tested").is_greater(0)


## The same bound over whole matches, where the possession loop, the period
## boundaries and the rotation all get a turn at it.
func test_no_played_match_commits_two_leading_by_three_fouls_in_one_possession() -> void:
	for variation in range(960000, 960012):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, 0.5)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		var per_possession: Dictionary[int, int] = {}
		for event in output.events:
			if event.event_type != MatchDomainEvent.FOUL:
				continue
			if event.detail_id != FoulType.id_of(FoulType.Value.LEADING_PROTECT):
				continue
			var count: int = per_possession.get(event.possession_id, 0) + 1
			per_possession[event.possession_id] = count
			assert_int(count).override_failure_message(
				"possession %d of game %d committed %d leading-by-three fouls"
				% [event.possession_id, variation, count]).is_less_equal(1)


# --- 10. quick-two stays outside the tie-seeking window at every stakes tier ----

## `EndgameStrategy.quick_two_preferred` exists to prefer a two at a
## three-point deficit *outside* the window `GameManagement.endgame_multiplier`
## already owns, where that rule is preferring the tying three. The two windows
## have to be complementary for either to mean anything, and the gate drew its
## own boundary from the raw `endgame_possession_ms` while the tie-seeking rule
## draws its from `StakesPolicy.endgame_window_ms` — the same constant scaled by
## the stakes tier. They agreed at regular-season stakes and nowhere else.
##
## A gate test could not see this, because every fixture in the suite carries
## `GameStakes.DEFAULT`. That is the §9 item 14 pattern exactly: a predicate
## correct at the one tier it was ever evaluated at.
func test_quick_two_never_overlaps_the_tie_seeking_window_at_any_stakes_tier() -> void:
	var balance := SimulationBalanceProfile.new()
	for stakes in range(GameStakes.COUNT):
		var input: MatchInput = MatchFixtureFactory.standard_match()
		input.stakes = stakes
		var rules: CompetitionRuleProfile = input.rule_profile
		var opens_at: int = StakesPolicy.endgame_window_ms(balance, stakes)

		# One millisecond inside the tie-seeking window: that rule owns this
		# state alone, whatever the tier moved the boundary to.
		var inside: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, opens_at, -3),
			input.home.team_id)
		assert_bool(EndgameStrategy.quick_two_preferred(inside, balance))\
			.override_failure_message(
				"quick-two fired at %dms, inside the %s tie-seeking window (opens %dms)"
				% [opens_at, GameStakes.id_of(stakes), opens_at]).is_false()

		# Just outside it, quick-two is the rule in force.
		var outside: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, opens_at + 2000, -3),
			input.home.team_id)
		assert_bool(EndgameStrategy.quick_two_preferred(outside, balance))\
			.override_failure_message(
				"quick-two refused at %dms, outside the %s tie-seeking window"
				% [opens_at + 2000, GameStakes.id_of(stakes)]).is_true()

		# And it keeps its own span past that boundary rather than a fixed clock.
		var beyond: PossessionContext = _context(
			input,
			_snapshot_at(
				input, rules.regulation_periods,
				opens_at + EndgameStrategy.quick_two_span_ms(balance) + 2000, -3),
			input.home.team_id)
		assert_bool(EndgameStrategy.quick_two_preferred(beyond, balance))\
			.override_failure_message(
				"quick-two fired beyond its own span at %s stakes"
				% GameStakes.id_of(stakes)).is_false()


## The regular-season clock boundaries remain unchanged to the millisecond.
## Timeout inventory is tested separately because it was never a real input to
## the follow-up sequence and is intentionally no longer part of this gate.
func test_regular_season_quick_two_clock_boundaries_are_unchanged() -> void:
	var balance := SimulationBalanceProfile.new()
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	assert_int(input.stakes).is_equal(GameStakes.Value.REGULAR)
	assert_int(StakesPolicy.endgame_window_ms(balance, GameStakes.Value.REGULAR))\
		.is_equal(balance.endgame_possession_ms)
	for clock: int in [
		balance.endgame_possession_ms,
		balance.endgame_possession_ms + 1000,
		balance.quick_two_window_ms,
		balance.quick_two_window_ms + 1000,
	]:
		var shipped: bool = (
			clock > balance.endgame_possession_ms
			and clock <= balance.quick_two_window_ms)
		var context: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, clock, -3),
			input.home.team_id)
		assert_bool(EndgameStrategy.quick_two_preferred(context, balance))\
			.override_failure_message("clock %dms" % clock).is_equal(shipped)


func test_quick_two_does_not_depend_on_an_unspent_timeout() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var clock: int = balance.endgame_possession_ms + 5000
	var with_timeout: MatchSnapshot = _snapshot_at(
		input, rules.regulation_periods, clock, -3)
	var without_timeout: MatchSnapshot = with_timeout.copy()
	without_timeout.home.timeouts_remaining = 0
	assert_bool(EndgameStrategy.quick_two_preferred(
		_context(input, with_timeout, input.home.team_id), balance)).is_true()
	assert_bool(EndgameStrategy.quick_two_preferred(
		_context(input, without_timeout, input.home.team_id), balance)).is_true()


## An immediate putback is still an action selected while the same endgame
## decision is in force. Its ledger tag must agree with every other action in
## that possession so activation reconstruction never silently drops it.
func test_putbacks_carry_the_endgame_decision_in_force() -> void:
	var found: int = 0
	# The offensive-rebound *fixture* at seed 7043 contains the exact case this
	# repair is for: a fourth-quarter putback while two-for-one is active.
	#
	# It used to be the committed `offensive_rebound` golden scenario, at that
	# scenario's own seed 7001. `simulation-v13` moved the clock every possession
	# starts on, and at 7001 the fourth-quarter putback now falls at a moment
	# when no endgame decision is in force — the scenario still has its
	# two-for-one and hold tags, and still has five putbacks, but the two no
	# longer coincide. The golden seed is deliberately *not* moved for this: 7001
	# still satisfies the requirement that scenario is named for, and rewriting a
	# golden fixture to keep an unrelated suite green would be the wrong way
	# round. This test owns its own seed instead, on the same fixture, found by
	# reachability search over 7001-9001 (`PROJECT_STATUS.md` §5.30).
	const TAGGED_PUTBACK_SEED: int = 7043
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.offensive_rebound_match(),
		SeededRandomSource.new(TAGGED_PUTBACK_SEED))
	for event in output.events:
		if (
			event.event_type == MatchDomainEvent.ACTION_SELECTED
			and event.action_id == ActionFamily.id_of(ActionFamily.Value.PUTBACK)
			and event.detail_id == EndgameStrategy.TAG_TWO_FOR_ONE
		):
			found += 1
	assert_int(found).override_failure_message(
		"the known endgame putback lost its two-for-one ledger tag").is_equal(1)


## A profile whose two quick-two numbers leave no span is a rule that can never
## fire at any tier, and `validate()` refuses it rather than shipping a dead
## window — the same standard the intentional-miss floor is held to.
func test_validate_refuses_a_quick_two_window_with_no_span() -> void:
	var balance := SimulationBalanceProfile.new()
	assert_array(balance.validate()).is_empty()
	balance.quick_two_window_ms = balance.endgame_possession_ms
	var failures: PackedStringArray = balance.validate()
	assert_int(failures.size()).override_failure_message(
		"a zero-span quick-two window must be rejected").is_greater(0)
	var mentioned: bool = false
	for failure in failures:
		if failure.contains("quick-two"):
			mentioned = true
	assert_bool(mentioned).override_failure_message(
		"validate() must name the quick-two window: %s" % ", ".join(failures)).is_true()


# --- helpers -------------------------------------------------------------------

## A snapshot in which every timeout-advance condition holds except, where the
## caller supplies one, the rule profile's own grant.
func _eligible_advance_snapshot(
	rules: CompetitionRuleProfile,
	balance: SimulationBalanceProfile,
) -> MatchSnapshot:
	var snapshot := MatchSnapshot.new(
		MatchFixtureFactory.match_between(
			MatchFixtureFactory.uniform_team(&"home", 70),
			MatchFixtureFactory.uniform_team(&"away", 70),
			rules, balance))
	snapshot.period = rules.regulation_periods
	snapshot.clock_ms = balance.timeout_advance_window_ms - 4000
	snapshot.shot_clock_ms = rules.shot_clock_seconds * 1000
	snapshot.home.score = 71
	snapshot.away.score = 73
	snapshot.home.timeouts_remaining = rules.timeouts_per_team
	snapshot.away.timeouts_remaining = rules.timeouts_per_team
	return snapshot


func _count_advance_timeouts(
	events: Array[MatchDomainEvent],
	team_id: StringName = &"",
) -> int:
	var count: int = 0
	for event in events:
		if event.event_type != MatchDomainEvent.TIMEOUT or event.detail_id != &"advance":
			continue
		if team_id.is_empty() or event.team_id == team_id:
			count += 1
	return count


func _count_leading_protect_fouls(events: Array[MatchDomainEvent]) -> int:
	var count: int = 0
	for event in events:
		if (
			event.event_type == MatchDomainEvent.FOUL
			and event.detail_id == FoulType.id_of(FoulType.Value.LEADING_PROTECT)
		):
			count += 1
	return count


func _first_of(events: Array[MatchDomainEvent], event_type: StringName) -> MatchDomainEvent:
	for event in events:
		if event.event_type == event_type:
			return event
	return null


func _index_of_intentional_miss(events: Array[MatchDomainEvent]) -> int:
	for index in range(events.size()):
		if (
			events[index].event_type == MatchDomainEvent.FREE_THROW_MISSED
			and events[index].detail_id == &"intentional"
		):
			return index
	return -1


## The match the intentional-miss and leading-foul fixtures are driven through.
##
## The two windows are widened from their shipped values for one reason: a
## possession that starts with three seconds left cannot fit a two-shot trip
## *and* the live rebound that follows it, so the fixture would be asserting
## about a period expiry rather than about the decision. Nothing else is
## touched — in particular the margins, the attempt index, and the bonus state
## the decisions actually key off are the production ones.
func _leading_foul_input() -> MatchInput:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	input.balance_profile.leading_foul_share = 1.0
	input.balance_profile.leading_foul_clock_ms = 30000
	input.balance_profile.intentional_miss_clock_ms = 30000
	return input


## The defence up exactly three, in the bonus at the caller's team-foul count,
## inside the final period with the offence in possession.
func _leading_foul_snapshot(input: MatchInput, defense_team_fouls: int) -> MatchSnapshot:
	return _leading_foul_snapshot_at_margin(input, defense_team_fouls, -3)


func _leading_foul_snapshot_at_margin(
	input: MatchInput,
	defense_team_fouls: int,
	margin: int,
) -> MatchSnapshot:
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 20000, margin)
	snapshot.shot_clock_ms = rules.shot_clock_seconds * 1000
	snapshot.possession_team_id = input.home.team_id
	snapshot.away.team_fouls = defense_team_fouls
	return snapshot


## One possession in which the defence, up three and in the bonus, fouls; the
## trailing offence shoots two; and — when the first attempt goes in — the last
## one is missed on purpose. Returns null when this seed's first attempt did
## not go in, because there is then no down-two state for the rule to be about.
##
## `margin` is the offence's margin, so -3 is the real scenario and +3 is the
## inverted one `test_a_leading_team_at_the_line_never_intentionally_misses`
## uses. At +3 the whistle comes from the trailing defence's ordinary §13.1
## desperation foul instead, which is the same free-throw trip from the other
## side of the scoreboard.
func _intentional_miss_possession(seed_value: int, margin: int = -3) -> PossessionResult:
	var input: MatchInput = _leading_foul_input()
	input.balance_profile.intentional_foul_share = 1.0
	input.balance_profile.intentional_foul_clock_ms = 30000
	var snapshot: MatchSnapshot = _leading_foul_snapshot_at_margin(
		input, input.rule_profile.team_foul_bonus_threshold, margin)
	var possession: PossessionResult = PossessionEngine.new(input).simulate(
		snapshot, input, SeededRandomSource.new(seed_value), false, false)
	var awarded: MatchDomainEvent = _first_of(
		possession.events, MatchDomainEvent.FREE_THROW_AWARDED)
	if awarded == null or awarded.amount < 2:
		return null
	var first: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.FREE_THROW_MADE)
	if first == null or first.amount != 1:
		return null
	return possession


func _first_intentional_miss_possession() -> PossessionResult:
	for seed_value in range(4000, 4160):
		var possession: PossessionResult = _intentional_miss_possession(seed_value)
		if possession != null and _index_of_intentional_miss(possession.events) >= 0:
			return possession
	return null


## Mirrors `TestEndgameStrategy._snapshot_at`: a snapshot at a stated period,
## clock and home-minus-away margin, with a realized pace on the board so the
## `GameManagement.remaining_ms`-derived reads have something consistent to work
## from.
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
	snapshot.possession_sequence = maxi(1, int(roundf(float(elapsed) / 7150.0)))
	snapshot.home.score = 80 + maxi(margin, 0)
	snapshot.away.score = 80 + maxi(-margin, 0)
	return snapshot


func _context(
	input: MatchInput,
	snapshot: MatchSnapshot,
	team_id: StringName,
) -> PossessionContext:
	return PossessionContext.new(input, snapshot, team_id, MatchupState.new({}), 1)
