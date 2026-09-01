class_name TestGameManagement
extends GdUnitTestSuite

## Score-and-clock coaching, and the line between it and a rubber band.
##
## `GameManagement` is the first mechanism in the engine whose behaviour depends
## on the scoreboard outside the last forty seconds of a game, so it is also the
## first that could hide a comeback script. The contracts that keep it honest
## are all testable and all tested here:
##
## - it is *off* through ordinary basketball, which is what leaves every §14.1
##   band measured on the basketball it was measured on before;
## - it is symmetric — the same rule, computed the same way, for whichever team
##   happens to be ahead;
## - it reads the score, the clock, the pace and the rules, and nothing else. Not
##   a rating, not a strength index, not an intended winner, not a target margin;
## - it changes which action a coach prefers and how long a possession takes. It
##   never changes whether a shot goes in.
##
## The last of those is the one that matters most, and it is asserted directly
## against the resolvers rather than inferred from an aggregate.

const ORDINARY_MARGINS: PackedInt32Array = [0, 2, 4, 6, 8, 10]


# --- the mechanism is off through ordinary basketball ------------------------

## Nothing happens at any ordinary score with any ordinary amount of time left.
##
## This is the §14.1 guarantee stated as a test: if `pressure` were non-zero in
## the body of a game, every possession, efficiency and shot-mix band would have
## been re-measured under a different engine than the one that certified them.
func test_pressure_is_zero_through_ordinary_basketball() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	for period in range(1, rules.regulation_periods + 1):
		for margin: int in ORDINARY_MARGINS:
			var snapshot: MatchSnapshot = _snapshot_at(
				input, period, rules.period_length_ms(period) / 2, margin)
			if period < rules.regulation_periods:
				assert_float(_pressure(input, snapshot, input.home.team_id))\
					.override_failure_message(
						"period %d, margin %d" % [period, margin]).is_equal(0.0)


## And it is on when a trailing team is genuinely out of time.
func test_pressure_reaches_its_ceiling_when_the_clock_runs_out() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var snapshot: MatchSnapshot = _snapshot_at(
		input, input.rule_profile.regulation_periods, 20000, 9)
	assert_float(_pressure(input, snapshot, input.home.team_id)).is_equal(1.0)
	assert_float(_pressure(input, snapshot, input.away.team_id)).is_equal(1.0)


## A settled twenty-point margin with a whole half still to play is not an
## endgame, and the rule says so.
func test_a_large_early_margin_is_not_an_endgame() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var snapshot: MatchSnapshot = _snapshot_at(input, 2, 60000, 20)
	assert_float(_pressure(input, snapshot, input.home.team_id)).is_equal(0.0)


# --- symmetry ----------------------------------------------------------------

## Both teams compute the same number. `pressure` is a property of the game, not
## of a side: it is the same for the team that is ahead and the team that is
## behind, and only the sign of their own margin decides which half of the
## policy each of them applies.
func test_both_teams_share_one_pressure() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in [-14, -7, -3, 3, 7, 14]:
		var snapshot: MatchSnapshot = _snapshot_at(
			input, rules.regulation_periods, 120000, margin)
		assert_float(_pressure(input, snapshot, input.home.team_id))\
			.is_equal(_pressure(input, snapshot, input.away.team_id))


## Reversing the scoreboard reverses the policy exactly. The protecting factor
## at `+m` and the chasing factor at `-m` are mirror images of one another
## around the same pressure, which is what "identical score-state policy for
## both teams" means operationally.
func test_the_policy_mirrors_when_the_scoreboard_is_reversed() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var ahead: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 150000, 12)
	var behind: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 150000, -12)
	var intensity: float = _pressure(input, ahead, input.home.team_id)
	assert_float(intensity).is_greater(0.0)
	assert_float(intensity).is_equal(_pressure(input, behind, input.home.team_id))

	var protecting: float = GameManagement.pace_multiplier(
		_context(input, ahead, input.home.team_id), balance)
	var chasing: float = GameManagement.pace_multiplier(
		_context(input, behind, input.home.team_id), balance)
	assert_float(protecting).is_equal(1.0 + balance.protect_pace_gain * intensity)
	assert_float(chasing).is_equal(1.0 - balance.chase_pace_relief * intensity)

	# The away side, at the same two snapshots, holds the opposite role and the
	# opposite factor. Nothing distinguishes the two teams but the sign.
	assert_float(GameManagement.pace_multiplier(
		_context(input, ahead, input.away.team_id), balance)).is_equal(chasing)
	assert_float(GameManagement.pace_multiplier(
		_context(input, behind, input.away.team_id), balance)).is_equal(protecting)

	# The action mix mirrors on the same terms, and *both* halves of it are
	# asserted. Checking only the chasing half would let a policy that protects
	# nobody pass: the trailing team would still hunt threes, the leading team
	# would keep playing as though the game were level, and the asymmetry would
	# be invisible to every test that only looks at the side that is behind.
	var protect_reset: float = GameManagement.action_multiplier(
		_context(input, ahead, input.home.team_id), balance, ActionFamily.Value.RESET, -1)
	var protect_three: float = GameManagement.action_multiplier(
		_context(input, ahead, input.home.team_id), balance,
		ActionFamily.Value.PULL_UP, ShotZone.Value.STANDARD_THREE)
	assert_float(protect_reset).is_equal(1.0 + balance.protect_reset_gain * intensity)
	assert_float(protect_three).is_equal(1.0 - balance.protect_three_relief * intensity)
	assert_float(GameManagement.action_multiplier(
		_context(input, behind, input.away.team_id), balance,
		ActionFamily.Value.RESET, -1)).is_equal(protect_reset)
	assert_float(GameManagement.action_multiplier(
		_context(input, behind, input.away.team_id), balance,
		ActionFamily.Value.PULL_UP, ShotZone.Value.STANDARD_THREE)).is_equal(protect_three)

	# And the crash decision, which is the third channel and the one with the
	# largest measured effect on the margin.
	var protect_crash: float = GameManagement.crash_multiplier(
		_context(input, ahead, input.home.team_id), balance)
	var chase_crash: float = GameManagement.crash_multiplier(
		_context(input, behind, input.home.team_id), balance)
	assert_float(protect_crash).is_equal(1.0 - balance.protect_crash_relief * intensity)
	assert_float(chase_crash).is_equal(1.0 + balance.chase_crash_gain * intensity)
	assert_float(GameManagement.crash_multiplier(
		_context(input, ahead, input.away.team_id), balance)).is_equal(chase_crash)
	assert_float(GameManagement.crash_multiplier(
		_context(input, behind, input.away.team_id), balance)).is_equal(protect_crash)


## The policy is blind to who the players are. Holding the score, clock, period
## and realized pace fixed and replacing both rosters with much stronger ones
## leaves every factor identical, which is the direct statement that the rule
## cannot be reading strength, an intended winner, or a target margin — there is
## nothing in its inputs that could carry one.
func test_the_policy_cannot_read_strength_or_an_intended_winner() -> void:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var weak: MatchInput = _tilted_match(competition, -6.0)
	var strong: MatchInput = _tilted_match(competition, 6.0)
	var period: int = weak.rule_profile.regulation_periods
	var weak_state: MatchSnapshot = _snapshot_at(weak, period, 150000, 12)
	var strong_state: MatchSnapshot = _snapshot_at(strong, period, 150000, 12)
	assert_float(_pressure(weak, weak_state, weak.home.team_id))\
		.is_equal(_pressure(strong, strong_state, strong.home.team_id))
	assert_float(GameManagement.pace_multiplier(
		_context(weak, weak_state, weak.home.team_id), weak.balance_profile))\
		.is_equal(GameManagement.pace_multiplier(
			_context(strong, strong_state, strong.home.team_id), strong.balance_profile))


# --- bounds ------------------------------------------------------------------

## Leading-team clock control is bounded, in both the tunable and the realized
## factor, and the protecting gain is the larger of the two by construction.
func test_pace_control_is_bounded() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	# Pinned against fixed, coaching-plausible values as well as against the
	# profile's own safe range: a bound derived only from the thing being
	# changed cannot notice the thing being changed.
	assert_float(balance.protect_pace_gain).is_greater(0.0)
	assert_float(balance.protect_pace_gain).is_less_equal(0.30)
	assert_float(balance.chase_pace_relief).is_greater_equal(0.0)
	assert_float(balance.chase_pace_relief).is_less(balance.protect_pace_gain)

	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in [-30, -12, -1, 0, 1, 12, 30]:
		for clock: int in [10000, 90000, 300000]:
			var snapshot: MatchSnapshot = _snapshot_at(
				input, rules.regulation_periods, clock, margin)
			var factor: float = GameManagement.pace_multiplier(
				_context(input, snapshot, input.home.team_id), balance)
			assert_float(factor).is_greater_equal(1.0 - balance.chase_pace_relief)
			assert_float(factor).is_less_equal(1.0 + balance.protect_pace_gain)


## The chasing side's higher-variance strategy is a change of *selection*. The
## three-point candidate becomes more attractive; nothing about the attempt
## itself improves, and the factor stays inside the §12.2 guardrail the rest of
## the weight product lives under.
func test_the_chasing_strategy_changes_selection_and_stays_inside_its_guardrail() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var behind: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 150000, -12)
	var context: PossessionContext = _context(input, behind, input.home.team_id)
	var intensity: float = _pressure(input, behind, input.home.team_id)
	var three: float = GameManagement.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.STANDARD_THREE)
	var reset: float = GameManagement.action_multiplier(
		context, balance, ActionFamily.Value.RESET, -1)
	assert_float(three).is_equal(1.0 + balance.chase_three_gain * intensity)
	assert_float(reset).is_equal(1.0 - balance.chase_three_gain * intensity)
	assert_float(three).is_less_equal(balance.score_clock_max)
	assert_float(reset).is_greater_equal(balance.score_clock_min)


# --- no probability changes hands --------------------------------------------

## The scoreboard does not reach the shot.
##
## Held fixed: the shooter, the defender, the zone, the contest, the lineup, the
## clock and the random stream. Moved: a thirty-point swing, in both directions.
## The resolved make probability is identical to the last bit, which is the
## property §20.3 states as "the score alone cannot cause the trailing team to
## receive an artificial make bonus". A team thirty ahead and a team thirty
## behind take the identical shot; what the score is allowed to change is which
## shot they choose to take, and that is asserted separately above.
func test_the_score_grants_no_shot_probability() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var level: float = _shot_probability(
		input, _snapshot_at(input, rules.regulation_periods, 150000, 0))
	var ahead: float = _shot_probability(
		input, _snapshot_at(input, rules.regulation_periods, 150000, 30))
	var behind: float = _shot_probability(
		input, _snapshot_at(input, rules.regulation_periods, 150000, -30))
	assert_float(level).is_greater(0.0)
	assert_float(ahead).is_equal(level)
	assert_float(behind).is_equal(level)


## The same for the free throw, where §20.1 does allow a pressure term. It is
## keyed on the *absolute* margin, so a team eighteen points behind and a team
## eighteen points ahead shoot the identical free throw.
func test_the_free_throw_pressure_term_is_symmetric() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var ahead: float = _free_throw_probability(
		input, _snapshot_at(input, rules.regulation_periods, 20000, 3))
	var behind: float = _free_throw_probability(
		input, _snapshot_at(input, rules.regulation_periods, 20000, -3))
	assert_float(ahead).is_equal(behind)


# --- the last possession of regulation ---------------------------------------

## Down two the tying shot is a two; down three it is a three. The rule prefers
## the value that levels the game and takes weight off the one that does not,
## and it is the deficit that decides — not which team is holding it.
func test_the_endgame_rule_seeks_the_tying_shot_value() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var clock: int = balance.endgame_possession_ms - 2000

	var down_two: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, clock, -2), input.home.team_id)
	assert_float(_endgame(down_two, balance, ShotZone.Value.MIDRANGE))\
		.is_equal(1.0 + balance.endgame_tie_gain)
	assert_float(_endgame(down_two, balance, ShotZone.Value.STANDARD_THREE))\
		.is_equal(1.0 - balance.endgame_tie_relief)

	var down_three: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, clock, -3), input.home.team_id)
	assert_float(_endgame(down_three, balance, ShotZone.Value.STANDARD_THREE))\
		.is_equal(1.0 + balance.endgame_tie_gain)
	assert_float(_endgame(down_three, balance, ShotZone.Value.MIDRANGE))\
		.is_equal(1.0 - balance.endgame_tie_relief)

	# The away side, at the mirrored deficit, gets exactly the same preference.
	var away_down_two: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, clock, 2), input.away.team_id)
	assert_float(_endgame(away_down_two, balance, ShotZone.Value.MIDRANGE))\
		.is_equal(1.0 + balance.endgame_tie_gain)


## And it applies to nothing else: not to a deficit a single shot cannot level,
## not to a leading team, not with time for another possession, and not before
## the final period.
func test_the_endgame_rule_applies_only_to_a_levelling_deficit() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var clock: int = balance.endgame_possession_ms - 2000
	for margin: int in [-8, -4, -1, 0, 1, 2, 3, 8]:
		var inside: PossessionContext = _context(
			input,
			_snapshot_at(input, rules.regulation_periods, clock, margin),
			input.home.team_id)
		var expected_change: bool = margin == -2 or margin == -3
		assert_bool(_endgame(inside, balance, ShotZone.Value.STANDARD_THREE) != 1.0)\
			.override_failure_message("margin %d" % margin).is_equal(expected_change)

	var early: PossessionContext = _context(
		input, _snapshot_at(input, 1, clock, -3), input.home.team_id)
	assert_float(_endgame(early, balance, ShotZone.Value.STANDARD_THREE)).is_equal(1.0)

	var too_much_time: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.endgame_possession_ms + 5000, -3),
		input.home.team_id)
	assert_float(_endgame(too_much_time, balance, ShotZone.Value.STANDARD_THREE)).is_equal(1.0)


# --- timeouts ----------------------------------------------------------------

## Every competition profile grants a small, phase-appropriate allowance, and
## both teams get the same one.
func test_every_competition_grants_a_bounded_timeout_allowance() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		assert_int(rules.timeouts_per_team)\
			.override_failure_message(String(rules.profile_id)).is_greater_equal(3)
		assert_int(rules.timeouts_per_team).is_less_equal(9)


## A timeout is spent, never replenished, and never over-spent — including
## through overtime, which grants no more of them.
func test_timeouts_are_spent_and_never_replenished() -> void:
	var input: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 31, 0.5)
	var allowance: int = input.rule_profile.timeouts_per_team
	for seed_value: int in [8101, 8102, 8103, 8104]:
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
		assert_int(final_state.home.timeouts_remaining).is_greater_equal(0)


## Every run-stopping timeout in a played game answers a run at least as long
## as the threshold, is called by the team that was *not* on the run, and is
## called with enough regulation left for the coach to still want it.
##
## Top domestic also grants `EndgameStrategy`'s timeout-to-advance, so not
## every `TIMEOUT` event in these games is this rule's — `detail_id`
## distinguishes them (`&"run"` versus `&"advance"`), and each is checked
## against its own contract rather than one loop assuming every timeout is a
## run-stopping one.
##
## The seed set is wider than the three games this needs for the *run-stopping*
## half. `simulation-v10-endgame-corrections` turned the advance timeout from
## something called on every trailing possession of a close finish into a
## coaching decision made about 0.14 times a game (`PROJECT_STATUS.md` §5.26),
## and at that rate a three-game reachability assertion is a coin flip rather
## than a test. Twenty games is the smallest set that makes finding one a
## property of the engine instead of a property of the seeds.
func test_timeouts_trigger_only_under_valid_conditions() -> void:
	var input: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 32, 0.5)
	var balance: SimulationBalanceProfile = input.balance_profile
	assert_int(balance.timeout_run_points).is_greater_equal(5)
	assert_int(balance.timeout_run_points).is_less_equal(12)

	var found: int = 0
	var found_advance: int = 0
	for seed_value: int in range(9201, 9221):
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		var run_team: StringName = &""
		var run_points: int = 0
		var possession_index: int = 0
		var records: Array[PossessionRecord] = output.possessions
		for event in output.events:
			if event.event_type == MatchDomainEvent.POSSESSION_ENDED:
				var record: PossessionRecord = records[possession_index]
				possession_index += 1
				if record.points_scored > 0:
					if record.offense_team_id == run_team:
						run_points += record.points_scored
					else:
						run_team = record.offense_team_id
						run_points = record.points_scored
				continue
			if event.event_type != MatchDomainEvent.TIMEOUT:
				continue
			if event.detail_id == &"advance":
				found_advance += 1
				assert_bool(input.rule_profile.timeout_advance_permitted).is_true()
				assert_int(event.period).is_less_equal(input.rule_profile.regulation_periods)
				continue
			found += 1
			assert_int(run_points).is_greater_equal(balance.timeout_run_points)
			assert_str(String(event.team_id)).is_not_equal(String(run_team))
			assert_int(event.period).is_less_equal(input.rule_profile.regulation_periods)
			run_team = &""
			run_points = 0
	assert_int(found).override_failure_message(
		"no run-stopping timeout was called in three full games; the trigger is unreachable"
	).is_greater(0)
	assert_int(found_advance).override_failure_message(
		"no advance timeout was called in twenty full games at a competition that "
		+ "grants it; the §5.26 narrowing turned the decision off rather than "
		+ "making it a decision"
	).is_greater(0)


## A timeout rests everybody on the floor, on both sides, by the same amount. A
## rest that reached one bench only would be a comeback mechanism wearing a
## rule's clothes.
func test_a_timeout_rests_both_teams_equally() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var reducer := MatchStateReducer.new(input)
	var snapshot := MatchSnapshot.new(input)
	var recovery: float = input.balance_profile.timeout_recovery_points
	for team_state: TeamMatchState in [snapshot.home, snapshot.away]:
		for runtime in team_state.runtimes:
			runtime.acute_fatigue = 50.0
	var writer := MatchEventWriter.new(
		input.match_id, snapshot.event_sequence, snapshot.period, snapshot.clock_ms)
	writer.emit(MatchDomainEvent.TIMEOUT, input.home.team_id, &"", &"", &"", &"", &"run")
	for event in writer.events:
		reducer.apply_event(snapshot, event)
	for team_state: TeamMatchState in [snapshot.home, snapshot.away]:
		for runtime in team_state.runtimes:
			var expected: float = 50.0 - recovery if runtime.on_court else 50.0
			assert_float(runtime.acute_fatigue).is_equal(expected)
	assert_int(snapshot.home.timeouts_remaining)\
		.is_equal(input.rule_profile.timeouts_per_team - 1)
	assert_int(snapshot.away.timeouts_remaining)\
		.is_equal(input.rule_profile.timeouts_per_team)


# --- helpers -----------------------------------------------------------------

## A snapshot at a stated period, clock and home-minus-away margin, with a
## realized pace already on the board so `pressure` has something to read.
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
	# Two possessions per fourteen seconds elapsed, which is the pace every
	# top-domestic report measures. Setting it explicitly keeps the fixture from
	# depending on a simulated game to establish one.
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


func _pressure(input: MatchInput, snapshot: MatchSnapshot, team_id: StringName) -> float:
	return GameManagement.pressure_for(snapshot, input, team_id, input.balance_profile)


func _endgame(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
	zone: int,
) -> float:
	return GameManagement.endgame_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, zone)


## The resolved make probability for a fixed shooter, defender and zone, read
## off the outcome the resolver returns rather than recomputed here.
func _shot_probability(input: MatchInput, snapshot: MatchSnapshot) -> float:
	var context: PossessionContext = _context(input, snapshot, input.home.team_id)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := ShotResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)
	var contest := ShotContest.new(
		ContestBand.Value.OPEN, input.away.starters()[0], &"", false, false, 0.2, 0.0)
	var outcome: ShotOutcome = resolver.resolve(
		context, input.home.starters()[0], ShotZone.Value.MIDRANGE, false, contest,
		AdvantageResult.new(), 1.0, 0.0, SeededRandomSource.new(4242))
	return outcome.probability


func _free_throw_probability(input: MatchInput, snapshot: MatchSnapshot) -> float:
	var context: PossessionContext = _context(input, snapshot, input.home.team_id)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := FreeThrowResolver.new(capability, input.balance_profile)
	return resolver.probability(context, input.home.starters()[0])


## Two rosters built from the same variation, both moved by the same rating
## offset, so the *matchup* is unchanged and only the absolute quality moves.
func _tilted_match(competition: int, offset: float) -> MatchInput:
	var balance := SimulationBalanceProfile.new()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", 12, balance, offset)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", 13, balance, offset)
	return MatchInput.new(
		&"management_match",
		&"management_game",
		CompetitionCatalog.rules_for(competition),
		balance,
		home,
		away,
		home.team_id,
		CompetitionCatalog.ratings_profile(),
		0.0)
