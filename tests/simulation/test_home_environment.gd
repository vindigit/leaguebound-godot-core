class_name TestHomeEnvironment
extends GdUnitTestSuite

## The §19.4 home environment and the §17.4 bounds on it.
##
## §19.4 lets home advantage affect "bounded officiating, communication,
## composure, and familiarity factors", says its aggregate is "calibrated as a
## small win-rate edge for otherwise even teams", and says it "never guarantees
## an outcome". §17.4 puts numbers on the bounds: no single modifier above four
## absolute probability points, and no more than +2.5 points per 100 possessions
## combined.
##
## The defects this suite exists to prevent are the ones that make a home
## advantage dishonest rather than the ones that make it wrong:
##
## - a flat bonus that makes an identical physical shot go in more often at home;
## - an effect that reads the score, the margin, the clock, or who is expected
##   to win, which is a comeback mechanism however it is labelled;
## - an effect attached to a team rather than to a building;
## - a second modifier added somewhere that the aggregation never sees.
##
## The *level* of the advantage is a calibration question and belongs to
## `run_home_court_diagnostics.gd`. What belongs here is that the mechanism
## producing it is bounded, symmetric, venue-keyed and auditable.

const HOME: StringName = &"home"
const AWAY: StringName = &"away"

## The seed range this suite owns, disjoint from every calibration range.
const SUITE_BASE: int = 770000
## Enough games to see an effect worth roughly a point a game without making the
## pull-request gate slow. The assertions below are directional or structural,
## never a band: a band at this sample would be a coin flip.
const SAMPLE: int = 12

const PRODUCTION_STRENGTH: float = 0.5


# --- neutral, defaults, and venue keying ------------------------------------

## 1. A neutral court applies no home effect at all.
##
## Proven on the context and in production: every channel is exactly zero, and
## a full game played at strength zero is byte-identical to one played with the
## environment removed from the engine entirely.
func test_a_neutral_court_applies_no_home_effect() -> void:
	var neutral := HomeEnvironmentContext.neutral()
	assert_bool(neutral.is_neutral()).is_true()
	assert_float(neutral.total_modifier()).is_equal(0.0)
	for channel in range(HomeEnvironmentContext.CHANNEL_COUNT):
		assert_float(neutral.modifier(channel)).override_failure_message(
			"channel %s contributed on a neutral court" % neutral.channel_id(channel)
		).is_equal(0.0)
	var built := HomeEnvironmentContext.from_profile(0.0, _balance())
	assert_bool(built.is_neutral()).is_true()
	assert_float(built.total_modifier()).is_equal(0.0)


## 2. A missing home context uses the documented default.
##
## `MatchInput`'s default strength is 0.5 and it builds its context from the
## balance profile, so an input constructed without naming an environment is a
## half-strength venue and not an unset one.
func test_a_missing_home_context_uses_the_documented_default() -> void:
	var input: MatchInput = _match(PRODUCTION_STRENGTH)
	assert_float(input.home_environment).is_equal(PRODUCTION_STRENGTH)
	assert_object(input.home_environment_context).is_not_null()
	assert_bool(input.home_environment_context.is_neutral()).is_false()
	assert_float(input.home_environment_context.strength).is_equal(PRODUCTION_STRENGTH)


## 3. Swapping the venue swaps the advantage, and 16. the mirrored event changes
## are the ones the swap implies.
##
## The same two rosters, the same seed, the venue moved. The visiting side's
## totals in one arm are the home side's in the other, so the difference the
## venue makes reverses rather than persisting.
func test_swapping_the_venue_swaps_the_advantage() -> void:
	var forward: float = _mean_venue_turnover_edge(false)
	var reversed_edge: float = _mean_venue_turnover_edge(true)
	# The venue side commits fewer live-ball turnovers than the visitor in both
	# arms, whichever roster is at home.
	assert_float(forward).override_failure_message(
		"the home side did not hold a turnover edge").is_less(0.0)
	assert_float(reversed_edge).override_failure_message(
		"the venue reversal did not reproduce the turnover edge").is_less(0.0)


## 4. Identical home and away identity does not create an effect.
##
## `MatchInput` forbids it outright, which is the strongest form of this
## guarantee: the situation cannot be constructed.
func test_identical_home_and_away_identity_is_rejected() -> void:
	var roster: TeamMatchProfile = CompetitionCatalog.team_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, HOME, 0)
	assert_bool(roster.team_id == roster.team_id).is_true()
	# Two profiles with one id is the case the engine must never be handed, and
	# `is_home` would answer true for both sides if it ever were.
	var input: MatchInput = _match(PRODUCTION_STRENGTH)
	assert_bool(input.is_home(input.home.team_id)).is_true()
	assert_bool(input.is_home(input.away.team_id)).is_false()


## 5. Team identity does not affect the modifier, and 6. neither does the
## expected winner or the final result.
##
## Proven by construction rather than by inspection: the context is built from
## one number. There is no argument through which a team id, a score, a margin
## or a result could reach it, and its whole public surface is read-only.
func test_the_modifier_reads_only_venue_strength() -> void:
	var balance: SimulationBalanceProfile = _balance()
	var first := HomeEnvironmentContext.from_profile(PRODUCTION_STRENGTH, balance)
	var second := HomeEnvironmentContext.from_profile(PRODUCTION_STRENGTH, balance)
	assert_float(first.officiating()).is_equal(second.officiating())
	assert_float(first.communication()).is_equal(second.communication())
	assert_float(first.composure()).is_equal(second.composure())
	assert_float(first.total_modifier()).is_equal(second.total_modifier())
	# The type's own executable surface carries no identity, score, clock or
	# outcome term. Comments are stripped first: the docstrings explain what the
	# type refuses to read, and a scan that could not tell an explanation from an
	# implementation would forbid documenting the rule.
	var code: String = _executable_source(
		"res://src/domain/basketball/model/home_environment_context.gd")
	assert_str(code).is_not_empty()
	for forbidden: String in [
		"team_id", "score", "margin", "clock", "period", "expected", "winner",
		"result", "leading", "trailing",
	]:
		assert_bool(code.contains(forbidden)).override_failure_message(
			"HomeEnvironmentContext reads '%s'; §19.4 gives it one input" % forbidden
		).is_false()


# --- caps -------------------------------------------------------------------

## 11. No single modifier exceeds four absolute probability points.
func test_no_single_modifier_exceeds_four_absolute_points() -> void:
	assert_float(HomeEnvironmentContext.MAX_SINGLE_MODIFIER).is_equal(0.04)
	var built := HomeEnvironmentContext.from_profile(1.0, _balance())
	for channel in range(HomeEnvironmentContext.CHANNEL_COUNT):
		assert_float(built.modifier(channel)).override_failure_message(
			"channel %s exceeded the §17.4 single-modifier cap" % built.channel_id(channel)
		).is_less_equal(HomeEnvironmentContext.MAX_SINGLE_MODIFIER)
	# A profile that asks for more is capped rather than obeyed.
	var greedy := HomeEnvironmentContext.new(1.0, 0.9, 0.0, 0.0)
	assert_float(greedy.officiating()).is_equal(HomeEnvironmentContext.MAX_SINGLE_MODIFIER)


## 12. Combined contributions never exceed the §17.4 budget, and 25. no hidden
## second home modifier bypasses the aggregation.
##
## The second half is the one that matters and it is checked against the source:
## every production read of the environment has to come through
## `home_environment_context`, so a new effect cannot be added without appearing
## in the channel list that `total_modifier` sums.
func test_combined_contributions_stay_inside_the_budget() -> void:
	var built := HomeEnvironmentContext.from_profile(1.0, _balance())
	var summed: float = 0.0
	for channel in range(HomeEnvironmentContext.CHANNEL_COUNT):
		summed += built.modifier(channel)
	assert_float(built.total_modifier()).is_equal_approx(summed, 0.000001)
	assert_float(built.total_modifier()).override_failure_message(
		"the channels together exceed the §17.4 combined budget"
	).is_less_equal(HomeEnvironmentContext.MAX_COMBINED_MODIFIER)
	# Every consumer reaches the environment through the context, so the sum
	# above is the whole of it.
	var raw_read := RegEx.new()
	# Any mention of the bare strength that is not the context object.
	assert_int(raw_read.compile("home_environment(?!_context)")).is_equal(OK)
	for path: String in [
		"res://src/domain/basketball/simulation/shot_resolver.gd",
		"res://src/domain/basketball/simulation/foul_resolver.gd",
		"res://src/domain/basketball/simulation/free_throw_resolver.gd",
		"res://src/domain/basketball/simulation/turnover_resolver.gd",
		"res://src/domain/basketball/simulation/possession_engine.gd",
		"res://src/domain/basketball/simulation/rebound_resolver.gd",
		"res://src/domain/basketball/simulation/advantage_resolver.gd",
		"res://src/domain/basketball/simulation/action_selector.gd",
		"res://src/domain/basketball/simulation/action_candidate_generator.gd",
	]:
		var code: String = _executable_source(path)
		assert_str(code).override_failure_message("could not read %s" % path).is_not_empty()
		assert_bool(raw_read.search(code) != null).override_failure_message(
			"%s reads the raw home_environment strength instead of the bounded context" % path
		).is_false()


## 9. An identical physical shot context receives no home make bonus.
##
## The strongest available form: the shot resolver is handed the identical
## shooter, zone, contest, advantage, catch quality, movement load and fatigue
## in both buildings, and must return the identical probability.
func test_an_identical_shot_context_has_no_home_make_bonus() -> void:
	var home_probability: float = _shot_probability(true)
	var away_probability: float = _shot_probability(false)
	assert_float(home_probability).override_failure_message(
		"an identical physical shot went in more often at home"
	).is_equal(away_probability)


## 10. Valid environment effects operate only through the documented channels.
func test_effects_operate_only_through_documented_channels() -> void:
	assert_int(HomeEnvironmentContext.CHANNEL_COUNT).is_equal(3)
	var built := HomeEnvironmentContext.from_profile(PRODUCTION_STRENGTH, _balance())
	var payload: Dictionary = built.to_dictionary()
	for channel in range(HomeEnvironmentContext.CHANNEL_COUNT):
		assert_bool(payload.has(String(built.channel_id(channel)))).override_failure_message(
			"channel %s is not in the audit payload" % built.channel_id(channel)).is_true()
	assert_bool(payload.has("total_modifier")).is_true()
	assert_bool(payload.has("strength")).is_true()


# --- ratings and capabilities ----------------------------------------------

## 7. Stored and derived player ratings are unchanged by the venue, and 8. so
## are capability values.
##
## §28 makes "chemistry, home court, morale, badges, or pressure exceed their
## documented caps" a release blocker, and the cleanest way to stay inside a cap
## on ratings is to never touch them. The environment is bounded context that
## sits outside stored ratings, so both sides' ratings and every capability must
## be identical in both buildings.
func test_the_venue_changes_no_rating_or_capability() -> void:
	var home_input: MatchInput = _match(PRODUCTION_STRENGTH)
	var neutral_input: MatchInput = _match(0.0)
	for team_id: StringName in [HOME, AWAY]:
		var venue_team: TeamMatchProfile = home_input.team_profile(team_id)
		var neutral_team: TeamMatchProfile = neutral_input.team_profile(team_id)
		for index in range(venue_team.players.size()):
			var venue_player: PlayerMatchProfile = venue_team.players[index]
			var neutral_player: PlayerMatchProfile = neutral_team.players[index]
			for key in AttributeKey.all():
				assert_int(venue_player.attributes.get_rating(key)).override_failure_message(
					"%s: attribute %s differs between venues"
					% [venue_player.player_id, AttributeKey.name_of(key)]
				).is_equal(neutral_player.attributes.get_rating(key))
	# Capabilities are derived from those ratings and the §5.2 weight table, and
	# the environment is in neither.
	var venue_capability := CapabilityCalculator.new(
		home_input.ratings_profile, home_input.balance_profile)
	var neutral_capability := CapabilityCalculator.new(
		neutral_input.ratings_profile, neutral_input.balance_profile)
	var runtime := PlayerMatchRuntime.new(home_input.home.players[0].player_id)
	for capability in range(CapabilityKey.COUNT):
		assert_float(venue_capability.capability_of(
			capability, home_input.home.players[0], runtime)
		).override_failure_message(
			"capability %s differs between venues" % CapabilityKey.id_of(capability)
		).is_equal(neutral_capability.capability_of(
			capability, neutral_input.home.players[0], runtime))


# --- no comeback mechanism --------------------------------------------------

## 17. The advantage does not depend on the score margin, and 18. it does not
## grow when the home team is behind.
##
## Measured in production rather than argued from the source: games are split at
## the point where the home side trails and where it leads, and the venue's
## effect on the *rate* of the things it touches has to be the same in both
## halves. A comeback mechanism is exactly a modifier whose size depends on
## which half a possession is in.
func test_the_advantage_does_not_depend_on_the_margin() -> void:
	var trailing := _RateSplit.new()
	var leading := _RateSplit.new()
	for index in range(SAMPLE):
		var variation: int = SUITE_BASE + index
		var input: MatchInput = _match(PRODUCTION_STRENGTH, variation)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		_split_turnovers_by_margin(input, output, trailing, leading)
	assert_int(trailing.opportunities).override_failure_message(
		"no possessions were played with the home side behind").is_greater(0)
	assert_int(leading.opportunities).override_failure_message(
		"no possessions were played with the home side ahead").is_greater(0)
	# The home turnover rate while behind must not differ from the rate while
	# ahead by more than ordinary variation. A rate that improves when the home
	# team trails is a rubber band whatever it is called.
	assert_float(absf(trailing.rate() - leading.rate())).override_failure_message(
		"the home turnover rate moved with the margin: %.4f behind, %.4f ahead"
		% [trailing.rate(), leading.rate()]
	).is_less(0.06)
	# The same question asked of the whistle, because officiating is the channel
	# a score-aware modifier would most naturally be written into. This is the
	# guard that a foul rate reading the scoreboard has to get past.
	assert_float(absf(trailing.foul_rate() - leading.foul_rate())).override_failure_message(
		"the home free-throw rate moved with the margin: %.4f behind, %.4f ahead"
		% [trailing.foul_rate(), leading.foul_rate()]
	).is_less(0.20)


## A neutral game cannot tell what the home modifiers are set to.
##
## The sharpest available form of "neutral contributes zero", and the one that
## catches a leak the context-level assertions cannot: two neutral games whose
## balance profiles carry *different* home modifiers must produce byte-identical
## ledgers. If any consumer applies an environment term without multiplying it
## through the venue strength, the two ledgers diverge and this fails; no test
## that only inspects `HomeEnvironmentContext` could see it, because the leak
## would be in the consumer.
func test_a_neutral_game_cannot_observe_the_home_modifiers() -> void:
	var signatures := PackedStringArray()
	for scale: float in [0.0, 1.0]:
		var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
		balance.home_officiating_modifier = 0.04 * scale
		balance.home_communication_modifier = 0.04 * scale
		balance.home_composure_modifier = 0.04 * scale
		var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
		var home_side: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, HOME, SUITE_BASE * 2, balance, 0.0)
		var away_side: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, AWAY, SUITE_BASE * 2, balance, 0.0)
		var input := MatchInput.new(
			&"neutral_leak", &"neutral_leak_game",
			CompetitionCatalog.rules_for(competition), balance,
			home_side, away_side, home_side.team_id,
			CompetitionCatalog.ratings_profile(), 0.0)
		assert_bool(input.home_environment_context.is_neutral()).is_true()
		signatures.append(MatchLedgerSerializer.hash_output(
			MatchEngine.new().simulate_match(input, SeededRandomSource.new(SUITE_BASE + 3))))
	assert_str(signatures[1]).override_failure_message(
		"a neutral game changed when the home modifiers changed: an effect is "
		+ "being applied without going through the venue strength"
	).is_equal(signatures[0])


## 17, 18, and 6, measured exactly rather than sampled.
##
## The whole-game split is too coarse to see this: a channel worth a couple of
## probability points moves a twelve-game turnover rate by less than its own
## sampling error, so a modifier that *tripled* when the home side trailed sat
## comfortably inside the tolerance. This asks the resolvers directly instead.
##
## The same possession is resolved `RESOLUTIONS` times against two scoreboards
## that differ only in the score — twenty points behind and twenty points ahead
## — with the identical lineups, matchups, clock, seeds and venue. §19.4's
## channels read the venue, so both columns have to come back the same. A
## comeback mechanism, a score-aware whistle, or an expected-winner term is a
## difference between two numbers that are otherwise required to be identical.
func test_no_channel_reads_the_scoreboard() -> void:
	# Asserted as exact equality rather than against a tolerance, and the
	# distinction matters: a channel worth four tenths of a probability point
	# moves these rates by about three thousandths, so any tolerance loose
	# enough to feel safe is looser than the whole effect and catches nothing.
	# None of these three resolvers reads the score on any path, so the two
	# columns are required to be identical to the last bit.
	# Compared as integer counts rather than as rates, so the comparison is
	# exact rather than approximate: a float assertion with any tolerance at all
	# is looser than the channels themselves, which move these counts by a few
	# dozen in six thousand.
	for at_home: bool in [true, false]:
		var side: String = "home" if at_home else "away"
		assert_int(_foul_count(at_home, -20)).override_failure_message(
			"the foul rate read the scoreboard (%s)" % side
		).is_equal(_foul_count(at_home, 20))
		assert_int(_pass_turnover_count(at_home, -20)).override_failure_message(
			"the pass turnover rate read the scoreboard (%s)" % side
		).is_equal(_pass_turnover_count(at_home, 20))
		assert_int(_handle_turnover_count(at_home, -20)).override_failure_message(
			"the handle turnover rate read the scoreboard (%s)" % side
		).is_equal(_handle_turnover_count(at_home, 20))


## 6 and 17, structurally. Two of the three consumers have no legitimate reason
## to know the score, and are asserted not to.
##
## The sampled version of this question cannot be made sharp enough on its own:
## a channel worth four tenths of a probability point moves a six-thousand-draw
## count by a few dozen, and a mutation placed where the §14.3 turnover floor
## clamps it can move it by nothing at all while still being live in a real
## game. So the score is forbidden at the source in the two files that never
## need it.
##
## Scoped to the three functions the venue reaches, not to whole files. Two
## things in these files read the score entirely legitimately and must keep
## doing so: §13.1's deliberate late-game foul is a coaching decision gated on
## score and clock, and §20.1 gives `FreeThrowResolver` a late-and-close
## pressure term that applies in both buildings. A scan that forbade those would
## be forbidding the specification.
func test_the_foul_and_turnover_resolvers_never_read_the_score() -> void:
	var scoreboard := RegEx.new()
	assert_int(scoreboard.compile(
		"offense_margin|defense_margin|margin_for|home_score|away_score"
	)).is_equal(OK)
	var targets: Array[PackedStringArray] = [
		PackedStringArray([
			"res://src/domain/basketball/simulation/foul_resolver.gd",
			"_contact_probability"]),
		PackedStringArray([
			"res://src/domain/basketball/simulation/turnover_resolver.gd",
			"resolve_pass"]),
		PackedStringArray([
			"res://src/domain/basketball/simulation/turnover_resolver.gd",
			"resolve_ball_handling"]),
	]
	for target: PackedStringArray in targets:
		var body: String = _function_source(target[0], target[1])
		assert_str(body).override_failure_message(
			"could not find %s in %s" % [target[1], target[0]]).is_not_empty()
		var found: RegExMatch = scoreboard.search(body)
		assert_bool(found != null).override_failure_message(
			"%s.%s reads the scoreboard ('%s'); §19.4's channels read the venue"
			% [target[0], target[1], "" if found == null else found.get_string()]
		).is_false()


## 5, measured. Team identity does not affect the modifier.
##
## The venue's lift on each channel is measured on a fixture whose teams are
## called `home` and `away`, and again on one whose identical teams are called
## something else. An exception keyed on a team id — the shape a "this club is
## different" rule takes — changes one column and not the other.
func test_team_identity_does_not_change_any_channel() -> void:
	var named: PackedFloat64Array = _channel_lifts(HOME, AWAY)
	var renamed: PackedFloat64Array = _channel_lifts(&"alpha", &"beta")
	var labels: PackedStringArray = ["foul", "pass turnover", "handle turnover"]
	for index in range(named.size()):
		assert_float(absf(named[index] - renamed[index])).override_failure_message(
			"the %s lift depended on the team's name: %.4f vs %.4f"
			% [labels[index], named[index], renamed[index]]
		).is_less(0.005)


## The venue's lift on each channel is non-zero, so the two tests above are
## comparing something rather than agreeing about nothing.
func test_every_channel_actually_moves_its_own_rate() -> void:
	var lifts: PackedFloat64Array = _channel_lifts(HOME, AWAY)
	var labels: PackedStringArray = ["foul", "pass turnover", "handle turnover"]
	for index in range(lifts.size()):
		assert_float(absf(lifts[index])).override_failure_message(
			"the %s channel moved nothing, so nothing above was tested"
			% labels[index]).is_greater(0.001)


## 19. Home advantage never guarantees an outcome, and 20. away teams still win
## a substantial share of equal-team games.
func test_away_teams_still_win_a_substantial_share() -> void:
	var away_wins: int = 0
	for index in range(SAMPLE):
		var variation: int = SUITE_BASE + 100 + index
		var input: MatchInput = _match(PRODUCTION_STRENGTH, variation)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		if output.final_result.away_score > output.final_result.home_score:
			away_wins += 1
	assert_int(away_wins).override_failure_message(
		"the visiting side won none of %d equal-team games" % SAMPLE).is_greater(0)
	assert_int(away_wins).override_failure_message(
		"the visiting side won every one of %d equal-team games" % SAMPLE).is_less(SAMPLE)


## 21. A stakes tier does not change the home-environment contract.
func test_stakes_tiers_do_not_change_the_home_contract() -> void:
	var regular: MatchInput = _match(PRODUCTION_STRENGTH)
	for stakes in GameStakes.all():
		var tiered: MatchInput = regular.with_stakes(stakes)
		assert_float(tiered.home_environment).is_equal(regular.home_environment)
		assert_float(tiered.home_environment_context.total_modifier()).override_failure_message(
			"stakes tier %s changed the home environment" % GameStakes.id_of(stakes)
		).is_equal(regular.home_environment_context.total_modifier())


# --- determinism, parity, reconciliation ------------------------------------

## 15. Determinism holds for identical venue, inputs and seed.
func test_identical_venue_inputs_and_seed_reproduce_the_ledger() -> void:
	for strength: float in [0.0, PRODUCTION_STRENGTH]:
		var first: MatchSimulationOutput = MatchEngine.new().simulate_match(
			_match(strength), SeededRandomSource.new(SUITE_BASE + 1))
		var second: MatchSimulationOutput = MatchEngine.new().simulate_match(
			_match(strength), SeededRandomSource.new(SUITE_BASE + 1))
		assert_str(MatchLedgerSerializer.hash_output(first)).override_failure_message(
			"a replay at strength %.2f produced a different ledger" % strength
		).is_equal(MatchLedgerSerializer.hash_output(second))


## 13. Neutral Play, Sim and Skip are identical, and 14. so are home ones.
func test_play_sim_and_skip_agree_at_every_venue() -> void:
	for strength: float in [0.0, PRODUCTION_STRENGTH]:
		var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
			_match(strength), SeededRandomSource.new(SUITE_BASE + 2))

		var play := MatchSession.new(
			_match(strength), SeededRandomSource.new(SUITE_BASE + 2))
		play.open()
		while not play.is_complete():
			play.advance_possession()
		var played: MatchSimulationOutput = play.build_output()

		var skip := MatchSession.new(
			_match(strength), SeededRandomSource.new(SUITE_BASE + 2))
		var skipped: MatchSimulationOutput = skip.skip_to_final_result()

		var expected: String = MatchLedgerSerializer.hash_output(simulated)
		assert_str(MatchLedgerSerializer.hash_output(played)).override_failure_message(
			"Play and Sim diverged at strength %.2f" % strength).is_equal(expected)
		assert_str(skipped.signature()).override_failure_message(
			"Skip and Sim diverged at strength %.2f" % strength).is_equal(simulated.signature())


## 22. Ledger and box-score totals reconcile at every venue.
func test_ledger_and_box_score_reconcile_at_every_venue() -> void:
	for strength: float in [0.0, PRODUCTION_STRENGTH]:
		for index in range(4):
			var variation: int = SUITE_BASE + 200 + index
			var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
				_match(strength, variation), SeededRandomSource.new(variation + 1))
			assert_array(output.final_result.statistics.reconcile()).override_failure_message(
				"the box score did not reconcile at strength %.2f" % strength).is_empty()


## 23. The diagnostic distinguishes home, away and neutral fixtures.
##
## The runner's own arms, exercised here so a fixture that quietly stopped
## varying the venue would fail in the suite rather than in a report nobody
## reads twice.
func test_the_diagnostic_distinguishes_the_three_fixtures() -> void:
	var venue: MatchInput = _venue_match(PRODUCTION_STRENGTH, false)
	var neutral: MatchInput = _venue_match(0.0, false)
	var reversed_venue: MatchInput = _venue_match(PRODUCTION_STRENGTH, true)
	assert_bool(neutral.home_environment_context.is_neutral()).is_true()
	assert_bool(venue.home_environment_context.is_neutral()).is_false()
	assert_str(String(venue.home.team_id)).is_equal(String(neutral.home.team_id))
	assert_str(String(reversed_venue.home.team_id)).override_failure_message(
		"the reversed arm did not swap the venue").is_not_equal(String(venue.home.team_id))
	assert_str(String(reversed_venue.away.team_id)).is_equal(String(venue.home.team_id))


# --- helpers ----------------------------------------------------------------

class _RateSplit:
	extends RefCounted
	var turnovers: int = 0
	var free_throws: int = 0
	var opportunities: int = 0

	func rate() -> float:
		return 0.0 if opportunities == 0 else float(turnovers) / float(opportunities)

	func foul_rate() -> float:
		return 0.0 if opportunities == 0 else float(free_throws) / float(opportunities)


func _balance() -> SimulationBalanceProfile:
	return CompetitionCatalog.balance_profile()


## Two identical rosters, one venue strength. Identical so that anything the
## measurement finds was produced by the building.
func _match(strength: float, variation: int = SUITE_BASE) -> MatchInput:
	return _venue_match(strength, false, variation)


func _venue_match(
	strength: float,
	reversed_venue: bool,
	variation: int = SUITE_BASE,
) -> MatchInput:
	var balance: SimulationBalanceProfile = _balance()
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var first: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, HOME, variation * 2, balance, 0.0)
	var second: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, AWAY, variation * 2, balance, 0.0)
	return MatchInput.new(
		StringName("home_suite_%d" % variation),
		StringName("home_suite_game_%d" % variation),
		CompetitionCatalog.rules_for(competition),
		balance,
		second if reversed_venue else first,
		first if reversed_venue else second,
		first.team_id,
		CompetitionCatalog.ratings_profile(),
		strength)


## The venue side's live-ball turnovers minus the visitor's, averaged over the
## sample. Negative means the venue side turned it over less.
func _mean_venue_turnover_edge(reversed_venue: bool) -> float:
	var total: float = 0.0
	for index in range(SAMPLE):
		var variation: int = SUITE_BASE + 300 + index
		var input: MatchInput = _venue_match(PRODUCTION_STRENGTH, reversed_venue, variation)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		var statistics: MatchStatistics = output.final_result.statistics
		total += float(
			statistics.team_line(input.home.team_id).turnovers
			- statistics.team_line(input.away.team_id).turnovers)
	return total / float(SAMPLE)


## Splits the home side's live-ball turnovers by whether it was behind or ahead
## when the possession started, using the running score from the ledger itself.
func _split_turnovers_by_margin(
	input: MatchInput,
	output: MatchSimulationOutput,
	trailing: _RateSplit,
	leading: _RateSplit,
) -> void:
	var home_score: int = 0
	var away_score: int = 0
	var home_possession: bool = false
	for event in output.events:
		match event.event_type:
			MatchDomainEvent.POSSESSION_STARTED:
				home_possession = event.team_id == input.home.team_id
				if home_possession:
					var split: _RateSplit = (
						trailing if home_score < away_score else leading)
					split.opportunities += 1
			MatchDomainEvent.TURNOVER:
				if event.team_id == input.home.team_id:
					var split: _RateSplit = (
						trailing if home_score < away_score else leading)
					split.turnovers += 1
			MatchDomainEvent.FREE_THROW_AWARDED:
				if event.team_id == input.home.team_id:
					var split: _RateSplit = (
						trailing if home_score < away_score else leading)
					split.free_throws += event.amount
			MatchDomainEvent.FIELD_GOAL_MADE, MatchDomainEvent.FREE_THROW_MADE:
				var points: int = maxi(event.points, 1)
				if event.team_id == input.home.team_id:
					home_score += points
				else:
					away_score += points
			_:
				pass


## The make probability for one fixed physical shot context, at a venue and
## away from it. Everything the resolver reads is held identical.
func _shot_probability(at_home: bool) -> float:
	var input: MatchInput = _match(PRODUCTION_STRENGTH)
	var team_id: StringName = input.home.team_id if at_home else input.away.team_id
	var offense: TeamMatchProfile = input.team_profile(team_id)
	var defense: TeamMatchProfile = input.team_profile(input.opposing_team_id(team_id))
	var context := PossessionContext.new(
		input, MatchSnapshot.new(input), team_id, MatchupState.new({}), 1)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := ShotResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)
	# The identical physical context on both benches: same band, same defender
	# slot, same openness, same catch quality, same movement load, same seed. The
	# rosters are identical, so "the same shooter" is literally true.
	var contest := ShotContest.new(
		ContestBand.Value.OPEN, defense.starters()[0], &"", false, false, 0.2, 0.0)
	return resolver.resolve(
		context, offense.starters()[0], ShotZone.Value.MIDRANGE, false, contest,
		AdvantageResult.new(), 1.0, 0.0, SeededRandomSource.new(1)).probability


## How many times each resolver is asked. Large enough that a two-point channel
## is far outside the sampling error of the comparison, and cheap because no
## game is played: this is the same technique the attribute-sensitivity suite
## uses to make a small effect exactly measurable.
const RESOLUTIONS: int = 6000


## A possession context at a stated scoreboard, with the venue and the team
## names supplied. Everything else is held identical.
func _context_at(
	at_home: bool,
	home_margin: int,
	home_id: StringName = HOME,
	away_id: StringName = AWAY,
) -> PossessionContext:
	var balance: SimulationBalanceProfile = _balance()
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var home_side: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, home_id, SUITE_BASE * 2, balance, 0.0)
	var away_side: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, away_id, SUITE_BASE * 2, balance, 0.0)
	var input := MatchInput.new(
		&"home_rate", &"home_rate_game", CompetitionCatalog.rules_for(competition),
		balance, home_side, away_side, home_side.team_id,
		CompetitionCatalog.ratings_profile(), PRODUCTION_STRENGTH)
	var snapshot := MatchSnapshot.new(input)
	snapshot.home.score = maxi(home_margin, 0) + 40
	snapshot.away.score = maxi(-home_margin, 0) + 40
	var offense_id: StringName = home_side.team_id if at_home else away_side.team_id
	return PossessionContext.new(input, snapshot, offense_id, MatchupState.new({}), 1)


## The share of `RESOLUTIONS` non-shooting contact checks that became a whistle.
func _foul_rate(at_home: bool, home_margin: int, home_id: StringName = HOME,
		away_id: StringName = AWAY) -> float:
	return float(_foul_count(at_home, home_margin, home_id, away_id)) / float(RESOLUTIONS)


## The raw count behind the rate, so a comparison can be exact.
func _foul_count(at_home: bool, home_margin: int, home_id: StringName = HOME,
		away_id: StringName = AWAY) -> int:
	var context: PossessionContext = _context_at(at_home, home_margin, home_id, away_id)
	var resolver := FoulResolver.new(
		CapabilityCalculator.new(context.input.ratings_profile, context.input.balance_profile),
		BodyEffects.new(context.input.balance_profile), context.input.balance_profile)
	var actor: StringName = context.offense_on_court()[0]
	var candidate := ActionCandidate.new(ActionFamily.Value.DRIVE, actor, 1.0, &"")
	var called: int = 0
	for index in range(RESOLUTIONS):
		var source: RandomSource = SeededRandomSource.new(index + 1)
		if resolver.resolve_non_shooting_foul(
			context, candidate, AdvantageResult.new(), source).occurred:
			called += 1
	return called


## The share of `RESOLUTIONS` deliveries that were turned over.
func _pass_turnover_rate(at_home: bool, home_margin: int, home_id: StringName = HOME,
		away_id: StringName = AWAY) -> float:
	return float(_pass_turnover_count(at_home, home_margin, home_id, away_id)) / float(RESOLUTIONS)


## The raw count behind the rate, so a comparison can be exact.
func _pass_turnover_count(at_home: bool, home_margin: int, home_id: StringName = HOME,
		away_id: StringName = AWAY) -> int:
	var context: PossessionContext = _context_at(at_home, home_margin, home_id, away_id)
	var resolver := TurnoverResolver.new(
		CapabilityCalculator.new(context.input.ratings_profile, context.input.balance_profile),
		context.input.balance_profile)
	# The fifth starter rather than the first. §14.3 floors the unforced pass
	# error at 1%, and a top passer in a neutral-advantage context sits on that
	# floor, where a communication term is clamped away before it can act. The
	# channel is real — the report measures it at about a quarter of the venue's
	# whole effect — and this is the context in which it is visible.
	var on_court: Array[StringName] = context.offense_on_court()
	context.ball_handler_id = on_court[4]
	var candidate := ActionCandidate.new(
		ActionFamily.Value.PASS_SWING, on_court[4], 1.0, on_court[0])
	var lost: int = 0
	for index in range(RESOLUTIONS):
		var source: RandomSource = SeededRandomSource.new(index + 1)
		if resolver.resolve_pass(context, candidate, AdvantageResult.new(), source).occurred:
			lost += 1
	return lost


## The share of `RESOLUTIONS` on-ball attacks that were turned over.
func _handle_turnover_rate(at_home: bool, home_margin: int, home_id: StringName = HOME,
		away_id: StringName = AWAY) -> float:
	return float(_handle_turnover_count(at_home, home_margin, home_id, away_id)) / float(RESOLUTIONS)


## The raw count behind the rate, so a comparison can be exact.
func _handle_turnover_count(at_home: bool, home_margin: int, home_id: StringName = HOME,
		away_id: StringName = AWAY) -> int:
	var context: PossessionContext = _context_at(at_home, home_margin, home_id, away_id)
	var resolver := TurnoverResolver.new(
		CapabilityCalculator.new(context.input.ratings_profile, context.input.balance_profile),
		context.input.balance_profile)
	var on_court: Array[StringName] = context.offense_on_court()
	context.ball_handler_id = on_court[0]
	var candidate := ActionCandidate.new(ActionFamily.Value.DRIVE, on_court[0], 1.0, &"")
	var lost: int = 0
	for index in range(RESOLUTIONS):
		var source: RandomSource = SeededRandomSource.new(index + 1)
		if resolver.resolve_ball_handling(
			context, candidate, AdvantageResult.new(), source).occurred:
			lost += 1
	return lost


## Each channel's venue lift: the rate with the venue's own side on offence
## minus the rate with the visitor on offence, at a level scoreboard.
func _channel_lifts(home_id: StringName, away_id: StringName) -> PackedFloat64Array:
	return PackedFloat64Array([
		_foul_rate(true, 0, home_id, away_id) - _foul_rate(false, 0, home_id, away_id),
		_pass_turnover_rate(true, 0, home_id, away_id)
			- _pass_turnover_rate(false, 0, home_id, away_id),
		_handle_turnover_rate(true, 0, home_id, away_id)
			- _handle_turnover_rate(false, 0, home_id, away_id),
	])


## One function's body, comments stripped, so a scan can be scoped to the code
## the venue actually reaches rather than to a whole file that legitimately does
## other things.
func _function_source(path: String, function_name: String) -> String:
	var code: String = _executable_source(path)
	var start: int = code.find("func %s(" % function_name)
	if start < 0:
		return ""
	var next: int = code.find("\nfunc ", start + 1)
	return code.substr(start, code.length() - start if next < 0 else next - start)


## A script's code with comment lines and trailing comments removed, so a scan
## for a forbidden identifier cannot be fooled — in either direction — by prose
## that names the thing it is forbidding.
func _executable_source(path: String) -> String:
	var raw: String = FileAccess.get_file_as_string(path)
	var kept := PackedStringArray()
	for line in raw.split("\n"):
		var text: String = line
		var comment: int = text.find("#")
		if comment >= 0:
			text = text.substr(0, comment)
		if not text.strip_edges().is_empty():
			kept.append(text)
	return "\n".join(kept)
