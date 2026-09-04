class_name TestGameStakes
extends GdUnitTestSuite

## The `GameStakes` contract and the four coaching decisions that read it.
##
## Stakes are the first input the engine has ever had that describes what a game
## is *for* rather than how it is played, so they are also the first place a
## drama script could hide behind a legitimate-sounding word. The contracts that
## keep them honest are all structural and all tested here:
##
## - a match built without a stakes argument is a regular-season game, and a
##   regular-season game resolves through arithmetic that multiplies by exactly
##   one — so nothing that existed before this input moves at all;
## - a tier changes only decision thresholds: rotation tolerance, timeout
##   reserve, settled-rotation patience, and the end-of-regulation window and
##   conviction. Every one of those is *which legal action a coach selects*;
## - no rating, capability, shot probability, turnover, foul, or rebound
##   probability differs between tiers when the inputs are held fixed;
## - a tier cannot see which team is which, which team is favoured, or how the
##   game ends, and it applies to both sides identically;
## - a championship game can still be a blowout, still reaches garbage time, and
##   a regular-season game can still reach overtime.
##
## The probability claims are asserted against the resolvers directly rather
## than inferred from an aggregate, because an aggregate cannot tell a coaching
## decision from a bonus.

const TOLERANCE: float = 0.000001


# --- the contract ----------------------------------------------------------------

## Three tiers, named and ordered, and no fourth one hiding behind a cast.
func test_the_contract_is_exactly_three_ordered_tiers() -> void:
	assert_int(GameStakes.COUNT).is_equal(3)
	assert_int(GameStakes.Value.REGULAR).is_equal(0)
	assert_int(GameStakes.Value.POSTSEASON).is_equal(1)
	assert_int(GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION).is_equal(2)
	assert_bool(GameStakes.is_valid(-1)).is_false()
	assert_bool(GameStakes.is_valid(GameStakes.COUNT)).is_false()
	for stakes in GameStakes.all():
		assert_bool(GameStakes.is_valid(stakes)).is_true()
		assert_int(GameStakes.from_id(GameStakes.id_of(stakes))).is_equal(stakes)
		assert_int(GameStakes.tier(stakes)).is_equal(stakes)


## **Requirement 1: missing context defaults to regular season.**
##
## Asserted on the default constructor argument, on the fixture factory, and on
## the calibration catalog, because "the default" is only useful if every
## existing way of building a match agrees on it.
func test_a_match_built_without_stakes_is_a_regular_season_game() -> void:
	assert_int(GameStakes.DEFAULT).is_equal(GameStakes.Value.REGULAR)
	assert_int(MatchFixtureFactory.standard_match().stakes)\
		.is_equal(GameStakes.Value.REGULAR)
	assert_int(CompetitionCatalog.match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 1, 0.5).stakes)\
		.is_equal(GameStakes.Value.REGULAR)
	assert_int(_match().stakes).is_equal(GameStakes.Value.REGULAR)
	for scenario in GoldenScenarios.names():
		assert_int(GoldenScenarios.input_for(scenario).stakes)\
			.override_failure_message("golden scenario %s is not a regular-season game" % scenario)\
			.is_equal(GameStakes.Value.REGULAR)


## **Requirement 2: regular-season behaviour is backward compatible.**
##
## Every stakes factor is exactly one at the regular tier, and every derived
## threshold is bit-identical to the tunable it came from. This is the assertion
## that explains why the committed golden ledgers did not move: the default path
## is not "close enough", it is the same arithmetic.
func test_the_regular_tier_multiplies_every_effect_by_exactly_one() -> void:
	var balance := SimulationBalanceProfile.new()
	var regular: int = GameStakes.Value.REGULAR
	assert_float(StakesPolicy.factor(0.9, regular)).is_equal(1.0)
	assert_float(StakesPolicy.minute_tolerance(balance, regular)).is_equal(1.0)
	assert_float(StakesPolicy.endgame_conviction(balance, regular)).is_equal(1.0)
	assert_int(StakesPolicy.timeout_reserve_ms(balance, regular))\
		.is_equal(balance.timeout_run_reserve_ms)
	assert_int(StakesPolicy.endgame_window_ms(balance, regular))\
		.is_equal(balance.endgame_possession_ms)
	assert_float(GarbageTimeRule.entry_threshold(
		balance, GarbageTimeRule.Mode.LEADING, regular))\
		.is_equal(balance.settled_leading_safety)
	assert_float(GarbageTimeRule.entry_threshold(
		balance, GarbageTimeRule.Mode.TRAILING, regular))\
		.is_equal(balance.settled_trailing_safety)


## A game played at the default and a game played at an explicit `REGULAR`
## produce the identical ledger, so the default is the tier and not a third
## unnamed state.
func test_the_default_and_an_explicit_regular_tier_are_the_same_game() -> void:
	var implicit: MatchInput = _match()
	var explicit: MatchInput = implicit.with_stakes(GameStakes.Value.REGULAR)
	assert_str(_ledger_hash(explicit, 5501)).is_equal(_ledger_hash(implicit, 5501))


## **Requirement 3: identical context, inputs and seed remain deterministic.**
##
## Every tier, twice, plus Play/Sim/Skip parity at the highest one — a stakes
## effect that reached the random stream would show up here before it showed up
## anywhere else.
func test_every_tier_reproduces_byte_for_byte_and_across_executors() -> void:
	var base: MatchInput = _match()
	for stakes in GameStakes.all():
		var input: MatchInput = base.with_stakes(stakes)
		var reference: String = _ledger_hash(input, 5610 + stakes)
		assert_str(_ledger_hash(input, 5610 + stakes))\
			.override_failure_message("tier %s did not reproduce" % GameStakes.id_of(stakes))\
			.is_equal(reference)
	var championship: MatchInput = base.with_stakes(
		GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		championship, SeededRandomSource.new(5620))
	var stepped := MatchSession.new(championship, SeededRandomSource.new(5620))
	stepped.open()
	while not stepped.is_complete():
		stepped.advance_possession()
	var skipped: MatchSimulationOutput = MatchSession.new(
		championship, SeededRandomSource.new(5620)).skip_to_final_result()
	var reference_hash: String = MatchLedgerSerializer.hash_output(simulated)
	assert_str(MatchLedgerSerializer.hash_output(stepped.build_output()))\
		.is_equal(reference_hash)
	assert_str(MatchLedgerSerializer.hash_output(skipped)).is_equal(reference_hash)


# --- what a tier may change ------------------------------------------------------

## **Requirement 4: stakes affect only authorized coaching decisions.**
##
## The four authorized thresholds move, monotonically and in the stated
## direction, and every one of them is bounded: nothing runs away with a tier.
func test_the_four_authorized_thresholds_move_and_stay_bounded() -> void:
	var balance := SimulationBalanceProfile.new()
	var previous_minutes: float = 0.0
	var previous_reserve: int = 0
	var previous_window: int = 0
	var previous_patience: float = 0.0
	var previous_conviction: float = 0.0
	for stakes in GameStakes.all():
		var minutes: float = StakesPolicy.minute_tolerance(balance, stakes)
		var reserve: int = StakesPolicy.timeout_reserve_ms(balance, stakes)
		var window: int = StakesPolicy.endgame_window_ms(balance, stakes)
		var patience: float = GarbageTimeRule.entry_threshold(
			balance, GarbageTimeRule.Mode.LEADING, stakes)
		var conviction: float = StakesPolicy.endgame_conviction(balance, stakes)
		assert_float(minutes).is_greater(previous_minutes - TOLERANCE)
		assert_int(reserve).is_greater_equal(previous_reserve)
		assert_int(window).is_greater_equal(previous_window)
		assert_float(patience).is_greater(previous_patience - TOLERANCE)
		assert_float(conviction).is_greater(previous_conviction - TOLERANCE)
		assert_float(minutes).is_less_equal(StakesPolicy.MAXIMUM_FACTOR)
		assert_float(conviction).is_less_equal(StakesPolicy.MAXIMUM_FACTOR)
		assert_int(reserve).is_less_equal(
			int(float(balance.timeout_run_reserve_ms) * StakesPolicy.MAXIMUM_FACTOR))
		assert_int(window).is_less_equal(
			int(float(balance.endgame_possession_ms) * StakesPolicy.MAXIMUM_FACTOR))
		previous_minutes = minutes
		previous_reserve = reserve
		previous_window = window
		previous_patience = patience
		previous_conviction = conviction
	assert_float(StakesPolicy.minute_tolerance(
		balance, GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)).is_greater(1.0)
	assert_int(StakesPolicy.timeout_reserve_ms(
		balance, GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION))\
		.is_greater(balance.timeout_run_reserve_ms)


## A step tunable large enough to be absurd is still bounded, so a mis-set
## profile is a bad game and never an unbounded one.
func test_no_step_can_push_a_factor_past_the_declared_maximum() -> void:
	for step: float in [0.0, 1.0, 5.0, 1000.0]:
		for stakes in GameStakes.all():
			var value: float = StakesPolicy.factor(step, stakes)
			assert_float(value).is_greater_equal(1.0)
			assert_float(value).is_less_equal(StakesPolicy.MAXIMUM_FACTOR)


## The end-of-regulation tie-seeking rule is the shot *value* preference, and a
## tier moves when it applies and how firmly — never which shot ties the game.
##
## Down three the three ties it and down two the two does, at every tier. A rule
## that started preferring the three when down two would be hunting a win
## instead of a tie, which is a different decision wearing this one's name.
func test_higher_stakes_widen_and_sharpen_the_tie_seeking_window_only() -> void:
	var input: MatchInput = _match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var balance: SimulationBalanceProfile = input.balance_profile
	var regular_window: int = StakesPolicy.endgame_window_ms(
		balance, GameStakes.Value.REGULAR)
	# A clock inside the championship window and outside the regular one.
	var clock_ms: int = regular_window + 8000
	assert_int(StakesPolicy.endgame_window_ms(
		balance, GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)).is_greater(clock_ms)
	for deficit: int in [2, 3]:
		var tying_zone: int = (
			ShotZone.Value.STANDARD_THREE if deficit == 3 else ShotZone.Value.MIDRANGE)
		var other_zone: int = (
			ShotZone.Value.MIDRANGE if deficit == 3 else ShotZone.Value.STANDARD_THREE)
		var regular: float = _endgame_multiplier(
			input, GameStakes.Value.REGULAR, rules.regulation_periods, clock_ms,
			-deficit, tying_zone)
		assert_float(regular).override_failure_message(
			"the tie-seeking rule fired outside the regular-season window").is_equal(1.0)
		var previous: float = 1.0
		for stakes: int in [
			GameStakes.Value.POSTSEASON, GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION
		]:
			var tying: float = _endgame_multiplier(
				input, stakes, rules.regulation_periods, clock_ms, -deficit, tying_zone)
			var other: float = _endgame_multiplier(
				input, stakes, rules.regulation_periods, clock_ms, -deficit, other_zone)
			assert_float(tying).override_failure_message(
				"tier %s did not prefer the levelling shot" % GameStakes.id_of(stakes))\
				.is_greater(1.0)
			assert_float(other).is_less(1.0)
			assert_float(tying).is_greater(previous - TOLERANCE)
			previous = tying


# --- what a tier may never change ------------------------------------------------

## **Requirement 5: shot probability and resolution are identical across tiers.**
##
## Same shooter, same defender, same zone, same contest, same fatigue, same
## random stream — the resolved make probability and the resolved outcome are
## the same at all three tiers, and the stream is left in the same place.
func test_the_same_shot_resolves_identically_at_every_tier() -> void:
	var base: MatchInput = _match()
	var reference_probability: float = -1.0
	var reference_made: bool = false
	var reference_draws: int = -1
	for stakes in GameStakes.all():
		var input: MatchInput = base.with_stakes(stakes)
		var counters: Dictionary = CountingRandomSource.counters()
		var counter := CountingRandomSource.new(SeededRandomSource.new(4242), counters)
		var outcome: ShotOutcome = _resolve_shot(input, counter)
		var draws: int = counters[&"next_float"]
		if reference_probability < 0.0:
			reference_probability = outcome.probability
			reference_made = outcome.made
			reference_draws = draws
			continue
		assert_float(outcome.probability).override_failure_message(
			"tier %s changed a shot probability" % GameStakes.id_of(stakes))\
			.is_equal(reference_probability)
		assert_bool(outcome.made).is_equal(reference_made)
		assert_int(draws).override_failure_message(
			"tier %s consumed a different number of random draws" % GameStakes.id_of(stakes))\
			.is_equal(reference_draws)


## The same for the three probabilities a stakes tier is explicitly forbidden to
## touch without a selected action: a turnover, a foul, and a rebound.
func test_turnover_foul_and_rebound_resolution_are_identical_at_every_tier() -> void:
	var base: MatchInput = _match()
	var turnovers: Array[String] = []
	var fouls: Array[String] = []
	var rebounds: Array[String] = []
	for stakes in GameStakes.all():
		var input: MatchInput = base.with_stakes(stakes)
		var context: PossessionContext = _late_context(input, -3)
		var capability := CapabilityCalculator.new(
			input.ratings_profile, input.balance_profile)
		var body := BodyEffects.new(input.balance_profile)
		var candidate := ActionCandidate.new(
			ActionFamily.Value.DRIVE, context.ball_handler_id, 1.0, &"",
			ShotZone.Value.RESTRICTED_RIM, false)
		var turnover: TurnoverOutcome = TurnoverResolver.new(
			capability, input.balance_profile).resolve_ball_handling(
				context, candidate, AdvantageResult.new(), SeededRandomSource.new(909))
		turnovers.append("%s|%d|%s|%s" % [
			turnover.occurred, turnover.cause, turnover.offender_id, turnover.defender_id])
		var foul: FoulCall = FoulResolver.new(
			capability, body, input.balance_profile).resolve_shooting_foul(
				context, context.ball_handler_id, ShotZone.Value.RESTRICTED_RIM,
				ShotContest.new(ContestBand.Value.MODERATE,
					input.away.starters()[0], &"", false, false, 0.6, 0.0),
				SeededRandomSource.new(910))
		fouls.append("%s|%d|%s|%d" % [
			foul.occurred, foul.foul_type, foul.fouler_id, foul.free_throws])
		var rebound: ReboundOutcome = ReboundResolver.new(
			capability, body, input.balance_profile).resolve(
				context, context.ball_handler_id, ShotZone.Value.MIDRANGE, false,
				SeededRandomSource.new(911))
		rebounds.append("%s|%s|%.12f" % [
			rebound.offensive, rebound.rebounder_id, rebound.offensive_probability])
	for index in range(1, GameStakes.COUNT):
		assert_str(turnovers[index]).override_failure_message(
			"a stakes tier changed turnover resolution").is_equal(turnovers[0])
		assert_str(fouls[index]).override_failure_message(
			"a stakes tier changed foul resolution").is_equal(fouls[0])
		assert_str(rebounds[index]).override_failure_message(
			"a stakes tier changed rebound resolution").is_equal(rebounds[0])


## The end-of-regulation rule selects a shot and never resolves one.
##
## Two boards that differ *only* in how much regulation is left — one inside the
## tie-seeking window, one far outside it — with the shooter, the defender, the
## zone, the contest, the fatigue, the shot clock and the random stream all held
## fixed. The resolved make probability, the resolved outcome, and the number of
## draws consumed are identical, at every tier.
##
## **This test exists because a mutation survived without it.** A forced late
## tie — "a levelling shot inside the last thirty seconds cannot miss" — was
## caught only by the committed golden ledgers, which is a real detector but a
## structural one: it says *something* moved, not that an execution probability
## was scripted. This says the second thing.
func test_the_endgame_window_changes_selection_and_never_resolution() -> void:
	var base: MatchInput = _match()
	for stakes in GameStakes.all():
		var input: MatchInput = base.with_stakes(stakes)
		var rules: CompetitionRuleProfile = input.rule_profile
		var window: int = StakesPolicy.endgame_window_ms(input.balance_profile, stakes)
		var reference_probability: float = -1.0
		var reference_made: bool = false
		var reference_draws: int = -1
		# Well inside the window, and well outside it, in the same period.
		for clock_ms: int in [maxi(window / 2, 4000), rules.period_length_ms(
			rules.regulation_periods) - 1000]:
			var snapshot: MatchSnapshot = _snapshot_at(
				input, rules.regulation_periods, clock_ms, -3)
			# The shot clock is a real execution input — a rushed shot is a worse
			# shot — so it is pinned rather than derived from the game clock.
			snapshot.shot_clock_ms = rules.shot_clock_seconds * 1000
			var counters: Dictionary = CountingRandomSource.counters()
			var counter := CountingRandomSource.new(SeededRandomSource.new(7331), counters)
			var context := PossessionContext.new(
				input, snapshot, input.home.team_id, MatchupState.new({}), 1)
			var capability := CapabilityCalculator.new(
				input.ratings_profile, input.balance_profile)
			var resolver := ShotResolver.new(
				capability, BodyEffects.new(input.balance_profile), input.balance_profile)
			var contest := ShotContest.new(
				ContestBand.Value.OPEN, input.away.starters()[0], &"", false, false, 0.2, 0.0)
			var outcome: ShotOutcome = resolver.resolve(
				context, input.home.starters()[0], ShotZone.Value.STANDARD_THREE, false,
				contest, AdvantageResult.new(), 1.0, 0.0, counter)
			var draws: int = counters[&"next_float"]
			if reference_probability < 0.0:
				reference_probability = outcome.probability
				reference_made = outcome.made
				reference_draws = draws
				continue
			assert_float(outcome.probability).override_failure_message(
				"the end-of-regulation window moved a make probability at tier %s"
					% GameStakes.id_of(stakes))\
				.is_equal(reference_probability)
			assert_bool(outcome.made).override_failure_message(
				"the end-of-regulation window forced a shot outcome at tier %s"
					% GameStakes.id_of(stakes))\
				.is_equal(reference_made)
			assert_int(draws).is_equal(reference_draws)
		# And the *selection* really does differ across that same boundary, so the
		# test above is not passing because the window is inert.
		var inside: float = _endgame_multiplier(
			input, stakes, rules.regulation_periods, maxi(window / 2, 4000), -3,
			ShotZone.Value.STANDARD_THREE)
		var outside: float = _endgame_multiplier(
			input, stakes, rules.regulation_periods,
			rules.period_length_ms(rules.regulation_periods) - 1000, -3,
			ShotZone.Value.STANDARD_THREE)
		assert_float(inside).override_failure_message(
			"the tie-seeking window is inert at tier %s" % GameStakes.id_of(stakes))\
			.is_greater(outside)


## **Requirement 6: capability resolution is identical across tiers.**
##
## All twenty-four capabilities for every player on both rosters, at rest and
## fatigued, in and out of the settled rotation. `CapabilityCalculator` has no
## stakes parameter at all, so a real leak would need a signature change rather
## than a silent edit — this is the behavioural half of that structural claim.
func test_no_rating_or_capability_moves_with_the_stakes() -> void:
	var base: MatchInput = _match()
	var signatures: Array[String] = []
	for stakes in GameStakes.all():
		var input: MatchInput = base.with_stakes(stakes)
		var snapshot: MatchSnapshot = _snapshot_at(input, 4, 120000, -24)
		snapshot.home.settled_mode = GarbageTimeRule.Mode.TRAILING
		snapshot.away.settled_mode = GarbageTimeRule.Mode.LEADING
		var capability := CapabilityCalculator.new(
			input.ratings_profile, input.balance_profile)
		var parts: PackedStringArray = []
		for team: TeamMatchProfile in [input.home, input.away]:
			var team_state: TeamMatchState = snapshot.state_for(team.team_id)
			for player: PlayerMatchProfile in team.players:
				var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player.player_id)
				runtime.acute_fatigue = 40.0
				parts.append(String(player.attributes.signature()))
				for key in CapabilityKey.all():
					parts.append("%.12f" % capability.capability_of(key, player, runtime))
		signatures.append("|".join(parts))
	for index in range(1, GameStakes.COUNT):
		assert_str(signatures[index]).override_failure_message(
			"tier %s changed a rating or a capability" % GameStakes.id_of(index))\
			.is_equal(signatures[0])


## **Requirement 7: reversing the scoreboard reverses leading/trailing policy.**
##
## At every tier. The stakes tier scales both thresholds by the same factor, so
## the two roles keep their gap and the sign of a team's own margin still picks
## which one applies to it.
func test_reversing_the_scoreboard_reverses_the_policy_at_every_tier() -> void:
	for stakes in GameStakes.all():
		var input: MatchInput = _match().with_stakes(stakes)
		var balance: SimulationBalanceProfile = input.balance_profile
		assert_float(GarbageTimeRule.entry_threshold(
			balance, GarbageTimeRule.Mode.LEADING, stakes))\
			.is_less(GarbageTimeRule.entry_threshold(
				balance, GarbageTimeRule.Mode.TRAILING, stakes))
		for margin: int in [20, 26, 34, 44]:
			var ahead: MatchSnapshot = _snapshot_at(input, 4, 300000, margin)
			var behind: MatchSnapshot = _snapshot_at(input, 4, 300000, -margin)
			assert_int(GarbageTimeRule.role_for(ahead, input.home.team_id))\
				.is_equal(GarbageTimeRule.Mode.LEADING)
			assert_int(GarbageTimeRule.role_for(behind, input.home.team_id))\
				.is_equal(GarbageTimeRule.Mode.TRAILING)
			assert_bool(_enters(input, ahead, input.home.team_id)).override_failure_message(
				"home at +%d behaved differently from away at +%d" % [margin, margin])\
				.is_equal(_enters(input, behind, input.away.team_id))
			assert_bool(_enters(input, ahead, input.away.team_id))\
				.is_equal(_enters(input, behind, input.home.team_id))
			assert_float(GarbageTimeRule.safety(ahead, input, balance))\
				.is_equal(GarbageTimeRule.safety(behind, input, balance))


## **Requirement 8: mirroring home and away mirrors behaviour.**
##
## Two identical rosters, the shirts swapped, the initial possession following
## the roster rather than the shirt — and the whole game comes back mirrored,
## possession for possession, at every tier.
##
## **The fixture sets `home_environment` to zero, and that is a deliberate
## isolation rather than a convenience.** §19.4 home advantage is a real,
## authorised, *pre-existing* asymmetry between the two shirts: it adds a
## bounded bonus to whichever team is at home, so a mirrored fixture with home
## advantage live is genuinely not symmetric — about half a shot per game
## resolves differently, at every tier including regular season. Leaving it on
## would make this test a flaky assertion about §19.4 wearing a stakes name. At
## zero the two `is_home` branches add and subtract exactly zero, the arithmetic
## is bit-identical on both sides, and what remains is the question actually
## being asked: does a stakes tier favour a shirt? It does not, and it has no
## field to do it through — `StakesPolicy` takes a balance profile and an
## integer.
func test_mirroring_home_and_away_mirrors_the_whole_game() -> void:
	for stakes in GameStakes.all():
		for seed_value: int in [5701, 5702, 5703]:
			var forward: MatchSimulationOutput = MatchEngine.new().simulate_match(
				_mirror_match(stakes, false), SeededRandomSource.new(seed_value))
			var swapped: MatchSimulationOutput = MatchEngine.new().simulate_match(
				_mirror_match(stakes, true), SeededRandomSource.new(seed_value))
			var label: String = "tier %s seed %d" % [GameStakes.id_of(stakes), seed_value]
			assert_int(swapped.final_result.away_score).override_failure_message(
				"%s treated home and away differently" % label)\
				.is_equal(forward.final_result.home_score)
			assert_int(swapped.final_result.home_score)\
				.is_equal(forward.final_result.away_score)
			assert_int(swapped.final_result.overtime_periods)\
				.is_equal(forward.final_result.overtime_periods)
			# Not merely the same scoreline: the same game. Every possession's
			# offense, outcome, elapsed time and action count, in order.
			assert_int(swapped.possessions.size())\
				.is_equal(forward.possessions.size())
			var limit: int = mini(swapped.possessions.size(), forward.possessions.size())
			for index in range(limit):
				assert_str(swapped.possessions[index].signature()).override_failure_message(
					"%s diverged at possession %d" % [label, index])\
					.is_equal(forward.possessions[index].signature())


## **Requirement 9: team identity and the expected winner do not reach the
## stakes policy.**
##
## `StakesPolicy` takes a balance profile and an integer and nothing else, so
## there is no channel for an identity to arrive through. The behavioural half:
## move both rosters by thirty rating points in either direction — which changes
## every expectation about the game and none of its public state — and the
## settled decision at a fixed board is unchanged at every tier.
func test_strength_identity_and_the_expected_winner_do_not_reach_the_policy() -> void:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	for stakes in GameStakes.all():
		var decisions: Array[String] = []
		for offset: float in [-30.0, 0.0, 30.0]:
			var input: MatchInput = _tilted_match(competition, offset, stakes)
			var parts: PackedStringArray = []
			for margin: int in [-30, -22, -18, 18, 22, 30]:
				var snapshot: MatchSnapshot = _snapshot_at(input, 4, 240000, margin)
				parts.append("%s%s" % [
					_enters(input, snapshot, input.home.team_id),
					_enters(input, snapshot, input.away.team_id)])
			decisions.append("|".join(parts))
		for index in range(1, decisions.size()):
			assert_str(decisions[index]).override_failure_message(
				"roster strength changed the settled decision at tier %s"
					% GameStakes.id_of(stakes))\
				.is_equal(decisions[0])
	# The same claim structurally: renaming the teams cannot change a threshold,
	# because the policy has nowhere to put a name.
	var balance := SimulationBalanceProfile.new()
	for stakes in GameStakes.all():
		assert_float(StakesPolicy.minute_tolerance(balance, stakes))\
			.is_equal(StakesPolicy.factor(balance.stakes_rotation_tightness_step, stakes))


# --- the garbage-time interaction ------------------------------------------------

## **Requirement 12: high-stakes garbage-time entry is later under matched
## conditions, and still mathematically bounded.**
##
## Two claims and both matter. At a board where a regular-season coach has
## already settled, a championship coach has not; and at a board decided beyond
## any argument, the championship coach settles anyway. Patience is a higher
## threshold on the same evidence, not an exemption from it.
func test_high_stakes_settle_later_but_still_settle() -> void:
	var regular: MatchInput = _match().with_stakes(GameStakes.Value.REGULAR)
	var final_game: MatchInput = _match().with_stakes(
		GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)
	var found_later: bool = false
	for margin: int in [18, 20, 22, 24, 26, 28, 30]:
		for clock_ms: int in [180000, 240000, 300000, 420000]:
			var snapshot: MatchSnapshot = _snapshot_at(regular, 4, clock_ms, margin)
			var settled_regular: bool = _enters(regular, snapshot, regular.home.team_id)
			var settled_final: bool = _enters(final_game, snapshot, final_game.home.team_id)
			# Patience only ever removes an activation; it never adds one.
			if settled_final:
				assert_bool(settled_regular).override_failure_message(
					"the championship coach settled where the regular one did not, at %d/%d"
						% [margin, clock_ms]).is_true()
			if settled_regular and not settled_final:
				found_later = true
	assert_bool(found_later).override_failure_message(
		"a championship game settled at exactly the same board as a regular one")\
		.is_true()
	# Decided beyond argument: the same coach settles.
	var decided: MatchSnapshot = _snapshot_at(final_game, 4, 90000, 40)
	assert_bool(_enters(final_game, decided, final_game.home.team_id))\
		.override_failure_message("a forty-point championship game never settled").is_true()


## The three guards under the settled rule are untouched by a tier: the
## eighteen-point coaching floor, the one-possession-pair guard, and the level
## game. A tier raises the evidence a coach wants; it does not let him settle a
## game the arithmetic has not decided.
func test_the_settled_guards_survive_the_highest_tier() -> void:
	var input: MatchInput = _match().with_stakes(
		GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)
	var balance: SimulationBalanceProfile = input.balance_profile
	var below_floor: int = balance.settled_minimum_margin - 1
	for clock_ms: int in [30000, 90000, 240000]:
		var snapshot: MatchSnapshot = _snapshot_at(input, 4, clock_ms, below_floor)
		assert_bool(_enters(input, snapshot, input.home.team_id)).override_failure_message(
			"a sub-floor margin settled a championship game").is_false()
	var level: MatchSnapshot = _snapshot_at(input, 4, 120000, 0)
	assert_bool(_enters(input, level, input.home.team_id)).is_false()
	assert_bool(_enters(input, level, input.away.team_id)).is_false()
	# No rest left to give: the one-pair guard still refuses a new entry.
	var buzzer: MatchSnapshot = _snapshot_at(input, 4, 4000, 40)
	assert_bool(_enters(input, buzzer, input.home.team_id)).override_failure_message(
		"a championship game newly settled with no time left to rest anyone").is_false()


## Reversing the scoreboard releases a settled championship coach, exactly as it
## releases a regular-season one. The state is not a latch at any tier.
func test_a_settled_championship_coach_is_released_when_the_lead_is_cut() -> void:
	var input: MatchInput = _match().with_stakes(
		GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)
	var snapshot: MatchSnapshot = _snapshot_at(input, 4, 240000, 6)
	snapshot.home.settled_mode = GarbageTimeRule.Mode.LEADING
	snapshot.away.settled_mode = GarbageTimeRule.Mode.TRAILING
	assert_bool(_leaves(input, snapshot, input.home.team_id)).is_true()
	assert_bool(_leaves(input, snapshot, input.away.team_id)).is_true()
	var flipped: MatchSnapshot = _snapshot_at(input, 4, 240000, -30)
	flipped.home.settled_mode = GarbageTimeRule.Mode.LEADING
	assert_bool(_leaves(input, flipped, input.home.team_id)).override_failure_message(
		"a coach whose lead became a deficit stayed in the settled rotation").is_true()


## **Requirement 10: a championship game can still become a blowout and still
## enter garbage time.**
##
## End to end, over a population of mismatched fixtures played as Finals. If a
## tier could keep a championship close, this is where it would show.
func test_championship_games_still_blow_out_and_still_reach_garbage_time() -> void:
	var blowouts: int = 0
	var activations: int = 0
	for variation in range(24):
		var input: MatchInput = _mismatched_match(
			variation, GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(5900 + variation))
		if absi(output.final_result.home_score - output.final_result.away_score) >= 20:
			blowouts += 1
		for event in output.events:
			if event.event_type == MatchDomainEvent.GARBAGE_TIME \
					and event.detail_id == &"entered":
				activations += 1
				break
	assert_int(blowouts).override_failure_message(
		"no championship game in twenty-four mismatched fixtures reached twenty points")\
		.is_greater(0)
	assert_int(activations).override_failure_message(
		"no championship game in twenty-four mismatched fixtures reached garbage time")\
		.is_greater(0)


## **Requirement 11: a regular-season game can still reach overtime.**
##
## The tie-seeking window is narrower at the regular tier, not closed, and the
## rest of the engine is untouched. The overtime golden scenario is the standing
## proof; this asserts it at the calibration fixtures the stakes diagnostic uses,
## so the two cannot drift apart.
## The seed block moved from 6100 to 6140 by the `simulation-v6-pass-creation`
## ruleset. §14.2 puts overtime at 4-8% of games, so forty fixtures expect one
## or two, and *which* forty finish level is a property of the scoring shape —
## any ruleset that changes the action mix moves it. The replacement block was
## searched for the same way the golden overtime seed is, and it carries more
## than one overtime so the check has a margin instead of hanging on a single
## game. Nothing about the assertion was weakened: it still requires a
## regular-season overtime to actually occur.
##
## Moved again from 6140 to 6380 by `simulation-v14-restart-contract`
## (`PROJECT_STATUS.md` §5.31), for the same reason and by the same search: a
## made free throw and a charged timeout no longer charge their throw-ins, so
## every possession after one starts on a different clock and 6140's forty
## fixtures stopped containing an overtime. The search over sixty consecutive
## blocks found 6220 and 6260 carrying one each and **6380 carrying three**,
## which is the widest margin available and the block taken. This is fixture
## maintenance, not overtime tuning: no overtime probability, window or
## threshold was touched, and §14.2's overtime rate is measured by the
## competition calibration runner, never here.
const OVERTIME_SEED_BLOCK: int = 6380


func test_regular_season_games_still_reach_overtime() -> void:
	var overtimes: int = 0
	for variation in range(40):
		var input: MatchInput = CompetitionCatalog.mirrored_match_for(
			CalibrationTargets.Competition.COLLEGE, variation, 0.5)
		assert_int(input.stakes).is_equal(GameStakes.Value.REGULAR)
		if MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(OVERTIME_SEED_BLOCK + variation)
		).final_result.overtime_periods > 0:
			overtimes += 1
	assert_int(overtimes).override_failure_message(
		"no regular-season game in forty even fixtures reached overtime")\
		.is_greater(0)


# --- the ledger ------------------------------------------------------------------

## **Requirement 13: state transitions remain reducer-owned and
## ledger-explained.**
##
## At the highest tier. Every settled-game substitution is preceded by a
## `GARBAGE_TIME` entry for that team, the reducer is the only writer of
## `settled_mode`, and replaying the committed events reproduces the final state
## exactly. Stakes add no event and no state of their own — they are an
## immutable input, so there is nothing for a tier to transition.
func test_state_transitions_stay_reducer_owned_at_the_highest_tier() -> void:
	var decided_reason: StringName = SubstitutionOrder.new(
		&"a", &"b", SubstitutionOrder.Reason.DECIDED_GAME).reason_id()
	var explained: int = 0
	for variation in range(12):
		var input: MatchInput = _mismatched_match(
			variation, GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(6200 + variation))
		var settled: Dictionary = {}
		for event in output.events:
			if event.event_type == MatchDomainEvent.GARBAGE_TIME:
				settled[event.team_id] = event.detail_id == &"entered"
				continue
			if event.event_type != MatchDomainEvent.CHECK_IN:
				continue
			if event.detail_id != decided_reason:
				continue
			assert_bool(settled.get(event.team_id, false)).override_failure_message(
				"a settled-game check-in with no live garbage-time entry")\
				.is_true()
			explained += 1
		# The reducer replays the committed ledger onto the final state.
		var replayed: MatchSnapshot = MatchStateReducer.new(input).apply_events(
			MatchSnapshot.new(input), output.events)
		assert_int(replayed.home.score).is_equal(output.final_result.home_score)
		assert_int(replayed.away.score).is_equal(output.final_result.away_score)
		assert_int(replayed.event_sequence)\
			.is_equal(output.final_result.final_event_sequence)
	assert_int(explained).override_failure_message(
		"no settled-game substitution occurred in twelve championship blowouts")\
		.is_greater(0)


## The five consumers, named. A stakes tier that acquired a sixth reader would
## be a contract change, and this is the assertion that makes it one: the
## engine's own source is searched for the fields a tier can be read through.
##
## `EndgameStrategy` is the fifth, added by
## `simulation-v11-quick-two-stakes-window`, and it is a deliberate contract
## change rather than an incidental one. `quick_two_preferred` has to begin
## where `GameManagement.endgame_multiplier`'s tie-seeking window ends, because
## the two rules hold opposite preferences at a three-point deficit and both
## multiply into the same §10.3 factor. That boundary is
## `StakesPolicy.endgame_window_ms`, which the tier already moves — so before
## this, quick-two was reading a stale copy of a boundary the tier had already
## shifted, and the whole of its window sat inside the tie-seeking one at both
## tiers above regular season.
##
## Routing the read through `GameManagement` would have kept this list at four
## names while making the behaviour just as stakes-dependent, which is the one
## thing this assertion exists to prevent. The tier still reaches only "how
## early he starts managing the last possession" — the circumstance in which a
## preference between two legal shots applies, never the probability that
## either goes in.
func test_only_the_declared_consumers_read_a_stakes_tier() -> void:
	var allowed: PackedStringArray = [
		"res://src/domain/basketball/model/match_input.gd",
		"res://src/domain/basketball/model/game_stakes.gd",
		"res://src/domain/basketball/simulation/stakes_policy.gd",
		"res://src/domain/basketball/simulation/game_management.gd",
		"res://src/domain/basketball/simulation/endgame_strategy.gd",
		"res://src/domain/basketball/simulation/garbage_time_rule.gd",
		"res://src/domain/basketball/simulation/match_session.gd",
		"res://src/domain/basketball/simulation/rotation_resolver.gd",
	]
	var offenders: PackedStringArray = []
	for path in _gdscript_paths("res://src"):
		if allowed.has(path):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		assert_object(file).is_not_null()
		var text: String = file.get_as_text()
		file.close()
		if text.contains(".stakes") or text.contains("StakesPolicy") \
				or text.contains("GameStakes"):
			offenders.append(path)
	assert_array(offenders).override_failure_message(
		"a stakes tier is read outside its declared consumers: %s" % ", ".join(offenders))\
		.is_empty()


# --- helpers ---------------------------------------------------------------------

func _match() -> MatchInput:
	return CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 3, 0.0)


## Two rosters far enough apart that blowouts happen, played at a stated tier.
##
## The tilt is ±7 rating points, lowered from ±9 by the
## `simulation-v6-pass-creation` ruleset. At ±9 the weaker roster now fouls out
## six of its ten players, and a ten-man roster with a six-foul limit has no
## legal fifth player left — which is not an engine defect but the upstream
## roster-supply problem `RotationResolver` names: §5 requires career services
## to authorise a replacement and forbids the engine from inventing one. ±7
## still blows eleven of the twelve games open and still produces several
## hundred settled-rotation check-ins, so the fixture tests exactly what it
## always tested, on a roster the calibration catalog can legally supply.
func _mismatched_match(variation: int, stakes: int) -> MatchInput:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var balance := SimulationBalanceProfile.new()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", variation * 2, balance, 7.0)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", variation * 2 + 1, balance, -7.0)
	return MatchInput.new(
		StringName("stakes_match_%d" % variation),
		StringName("stakes_game_%d" % variation),
		CompetitionCatalog.rules_for(competition),
		balance, home, away, home.team_id,
		CompetitionCatalog.ratings_profile(), 0.5, stakes)


## The same two identical rosters, optionally with the shirts swapped.
func _mirror_match(stakes: int, swapped: bool) -> MatchInput:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var balance := SimulationBalanceProfile.new()
	var first: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", 8, balance, 0.0)
	var second: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", 8, balance, 0.0)
	var home: TeamMatchProfile = second if swapped else first
	var away: TeamMatchProfile = first if swapped else second
	return MatchInput.new(
		&"stakes_mirror", &"stakes_mirror_game",
		CompetitionCatalog.rules_for(competition),
		balance, home, away, away.team_id if swapped else home.team_id,
		CompetitionCatalog.ratings_profile(), 0.0, stakes)


## Two rosters built from the same variation and moved by the same offset, so
## the matchup is unchanged and only the absolute quality moves.
func _tilted_match(competition: int, offset: float, stakes: int) -> MatchInput:
	var balance := SimulationBalanceProfile.new()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", 12, balance, offset)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", 13, balance, offset)
	return MatchInput.new(
		&"stakes_tilted", &"stakes_tilted_game",
		CompetitionCatalog.rules_for(competition),
		balance, home, away, home.team_id,
		CompetitionCatalog.ratings_profile(), 0.0, stakes)


func _ledger_hash(input: MatchInput, seed_value: int) -> String:
	return MatchLedgerSerializer.hash_output(
		MatchEngine.new().simulate_match(input, SeededRandomSource.new(seed_value)))


## A snapshot at a stated period, clock and home-minus-away margin, with a
## realized pace already on the board so the safety number has something to read.
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


## A live possession context late in a close game, with a ball handler set.
func _late_context(input: MatchInput, margin: int) -> PossessionContext:
	var snapshot: MatchSnapshot = _snapshot_at(input, 4, 30000, margin)
	var context := PossessionContext.new(
		input, snapshot, input.home.team_id, MatchupState.new({}), 1)
	context.ball_handler_id = input.home.starters()[0]
	return context


func _endgame_multiplier(
	input: MatchInput,
	stakes: int,
	period: int,
	clock_ms: int,
	margin: int,
	zone: int,
) -> float:
	var staked: MatchInput = input.with_stakes(stakes)
	var snapshot: MatchSnapshot = _snapshot_at(staked, period, clock_ms, margin)
	var context := PossessionContext.new(
		staked, snapshot, staked.home.team_id, MatchupState.new({}), 1)
	return GameManagement.endgame_multiplier(
		context, staked.balance_profile, ActionFamily.Value.PULL_UP, zone)


## The resolved shot for a fixed shooter, defender, zone, contest and stream.
func _resolve_shot(input: MatchInput, random_source: RandomSource) -> ShotOutcome:
	var snapshot: MatchSnapshot = _snapshot_at(input, 4, 20000, -3)
	var context := PossessionContext.new(
		input, snapshot, input.home.team_id, MatchupState.new({}), 1)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := ShotResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)
	var contest := ShotContest.new(
		ContestBand.Value.OPEN, input.away.starters()[0], &"", false, false, 0.2, 0.0)
	return resolver.resolve(
		context, input.home.starters()[0], ShotZone.Value.MIDRANGE, false, contest,
		AdvantageResult.new(), 1.0, 0.0, random_source)


func _gdscript_paths(root: String) -> PackedStringArray:
	var paths: PackedStringArray = []
	var directory: DirAccess = DirAccess.open(root)
	if directory == null:
		return paths
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var full: String = "%s/%s" % [root, entry]
		if directory.current_is_dir():
			paths.append_array(_gdscript_paths(full))
		elif entry.ends_with(".gd"):
			paths.append(full)
		entry = directory.get_next()
	directory.list_dir_end()
	return paths
