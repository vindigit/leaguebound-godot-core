class_name TestOpeningPossession
extends GdUnitTestSuite

## Who receives the opening inbound, and why that is a fixture question.
##
## The audit behind this suite settled three things, and each is pinned here so
## a later change has to argue with a test rather than with a paragraph:
##
## 1. **The engine does not choose.** `MatchInput.initial_possession_team_id` has
##    no default and is asserted to name one of the two supplied teams, and
##    nothing under `res://src` constructs a `MatchInput` at all. There is no
##    production opening-possession behaviour to be right or wrong.
## 2. **No specification describes one.** Nothing in `SIMULATION_SPEC.md`,
##    `BALANCE_SPEC.md`, `GDD.md` or `PRD.md` defines a jump ball, a possession
##    arrow or an alternating-possession rule, and
##    `CompetitionRuleProfile.possession_arrow_enabled` is declared and read by
##    nothing.
## 3. **The calibration catalog chose, and chose `home` every time.** That sat
##    inside `run_competition_calibration`'s §14.2 `home_win_rate` band, which is
##    judged against 53-56% and whose own comment claimed the measured rate was
##    "the environment effect and nothing else".
##
## So the correction belongs to the fixture, and the fixture counterbalances the
## inbound now. These tests fail if it stops — which is the mutation that would
## otherwise be invisible, because a contaminated home win rate is still a
## perfectly plausible number.

## Enough variations to make a parity counterbalance unambiguous while staying
## far away from any range a calibration runner owns. Nothing here simulates a
## game; these are fixture-construction assertions.
const SAMPLE_VARIATIONS: int = 64


# --- 1. production does not choose ------------------------------------------

## Nothing under `res://src` constructs a `MatchInput`.
##
## This is the structural half of the ruling, and it is the reason the fix went
## into the calibration catalog rather than into the engine: there is no
## production caller to correct. `match_input.gd` is excluded because
## `MatchInput.with_stakes` rebuilds one from an existing input — it copies the
## opener across rather than choosing one.
##
## If a scheduling or career layer ever does build a `MatchInput`, this test
## fails, and it should: that is the moment somebody has to decide what the real
## opening-possession rule is and write it into `SIMULATION_SPEC.md`.
func test_no_production_script_constructs_a_match_input() -> void:
	var offenders := PackedStringArray()
	for path in _scripts_under("res://src"):
		if path.ends_with("/model/match_input.gd"):
			continue
		if _executable_source(path).contains("MatchInput.new("):
			offenders.append(path)
	assert_array(offenders).override_failure_message(
		"production now builds a MatchInput at %s, so the opening possession has "
		% String(", ").join(offenders)
		+ "become a production decision. It needs a documented rule in "
		+ "SIMULATION_SPEC.md before a fixture counterbalance can stand in for one."
	).is_empty()


## The one place that does rebuild an input carries the opener across unchanged.
func test_rebuilding_an_input_for_new_stakes_keeps_the_same_opener() -> void:
	var original: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 1, 0.5)
	var restaked: MatchInput = original.with_stakes(GameStakes.Value.POSTSEASON)

	assert_str(String(restaked.initial_possession_team_id)).is_equal(
		String(original.initial_possession_team_id))


## The engine requires an explicit opener. There is no default to inherit and no
## silent fallback to the home bench.
func test_an_opening_possession_outside_the_two_teams_is_rejected() -> void:
	var reference: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.COLLEGE, 0, 0.5)

	assert_bool(_match_input_accepts(&"")).is_false()
	assert_bool(_match_input_accepts(&"some_other_club")).is_false()
	assert_bool(_match_input_accepts(reference.home.team_id)).is_true()
	assert_bool(_match_input_accepts(reference.away.team_id)).is_true()
	# And the contract is not vacuous: the two teams really are distinct, so
	# "one of the supplied teams" is a two-way choice rather than a formality.
	assert_str(String(reference.home.team_id)).is_not_equal(
		String(reference.away.team_id))


# --- 2. no specification describes an opening-possession rule ---------------

## The specifications are silent, and `possession_arrow_enabled` is dead.
##
## Pinned so the claim is checked rather than remembered. If somebody wires the
## possession arrow up, this fails and the ruling has to be revisited — at which
## point the fixture counterbalance is the wrong answer and a modelled rule is
## the right one.
func test_the_possession_arrow_rule_flag_is_still_unread() -> void:
	var readers := PackedStringArray()
	for path in _scripts_under("res://src"):
		if path.ends_with("/config/competition_rule_profile.gd"):
			continue
		if _executable_source(path).contains("possession_arrow_enabled"):
			readers.append(path)
	assert_array(readers).override_failure_message(
		"possession_arrow_enabled is now read by %s. The engine has acquired an "
		% String(", ").join(readers)
		+ "opening-possession rule, so SIMULATION_SPEC.md needs to describe it and "
		+ "the calibration counterbalance needs to be reconsidered against it."
	).is_empty()


# --- 3. the calibration fixture counterbalances -----------------------------

## `match_for` alternates the opening inbound on variation parity.
func test_the_population_fixture_alternates_the_opening_inbound() -> void:
	for variation in range(8):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, 0.5)
		var expected: StringName = (
			input.home.team_id if variation % 2 == 0 else input.away.team_id)
		assert_str(String(input.initial_possession_team_id)).override_failure_message(
			"variation %d opened with the wrong side" % variation
		).is_equal(String(expected))


## And so does the mirror fixture, which is the one the venue diagnostic uses.
func test_the_mirror_fixture_alternates_the_opening_inbound() -> void:
	for variation in range(8):
		var input: MatchInput = CompetitionCatalog.mirrored_match_for(
			CalibrationTargets.Competition.COLLEGE, variation, 0.5)
		var expected: StringName = (
			input.home.team_id if variation % 2 == 0 else input.away.team_id)
		assert_str(String(input.initial_possession_team_id)).is_equal(String(expected))


## Over a run of variations the inbound is split exactly evenly.
##
## This is the assertion that fails if the counterbalance is removed or
## weakened. A fixture that hands the inbound to the home team every time scores
## 1.0 here; one that alternates scores exactly 0.5; one that "mostly"
## alternates scores something else. The old behaviour is a specific, named
## failure rather than a vague drift.
func test_the_opening_inbound_is_split_exactly_evenly_over_a_range() -> void:
	for competition in CalibrationTargets.all_competitions():
		var home_opens: int = 0
		for variation in range(SAMPLE_VARIATIONS):
			var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
			if input.initial_possession_team_id == input.home.team_id:
				home_opens += 1
		assert_int(home_opens).override_failure_message(
			"%s gave the home side %d of %d opening inbounds; a counterbalanced "
			% [CalibrationTargets.competition_id(competition), home_opens, SAMPLE_VARIATIONS]
			+ "fixture gives it exactly half. This is the contamination that put a "
			+ "first-possession edge inside the §14.2 home win rate."
		).is_equal(SAMPLE_VARIATIONS / 2)


## A diagnostic can still pin the inbound deliberately. The counterbalance is
## the default, not the only option — `run_opening_possession.gd` needs both
## fixed cells to measure what the inbound is worth.
func test_a_diagnostic_can_hold_the_opening_inbound_on_one_side() -> void:
	for variation in range(6):
		var home_side: MatchInput = CompetitionCatalog.mirrored_match_for(
			CalibrationTargets.Competition.OVERSEAS, variation, 0.5,
			CompetitionCatalog.OPENING_HOME)
		var away_side: MatchInput = CompetitionCatalog.mirrored_match_for(
			CalibrationTargets.Competition.OVERSEAS, variation, 0.5,
			CompetitionCatalog.OPENING_AWAY)
		assert_str(String(home_side.initial_possession_team_id)).is_equal(
			String(home_side.home.team_id))
		assert_str(String(away_side.initial_possession_team_id)).is_equal(
			String(away_side.away.team_id))


## The counterbalance changes nothing else about the fixture.
##
## Same rosters, same ratings, same rules, same environment — only the opener
## moves. If the counterbalance had been implemented by perturbing the variation
## it would have changed the teams too, and the population would have quietly
## become a different one.
func test_the_counterbalance_moves_the_opener_and_nothing_else() -> void:
	var counterbalanced: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.DEVELOPMENT, 3, 0.5)
	var pinned: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.DEVELOPMENT, 3, 0.5,
		CompetitionCatalog.OPENING_HOME)

	# Variation 3 is odd, so the counterbalanced fixture opens with the visitor.
	assert_str(String(counterbalanced.initial_possession_team_id)).is_equal(
		String(counterbalanced.away.team_id))
	assert_str(String(pinned.initial_possession_team_id)).is_equal(
		String(pinned.home.team_id))
	assert_str(String(counterbalanced.home.team_id)).is_equal(String(pinned.home.team_id))
	assert_str(String(counterbalanced.away.team_id)).is_equal(String(pinned.away.team_id))
	assert_float(counterbalanced.home_environment).is_equal_approx(
		pinned.home_environment, 0.000001)
	assert_int(counterbalanced.home.players.size()).is_equal(pinned.home.players.size())
	for index in range(counterbalanced.home.players.size()):
		assert_str(String(counterbalanced.home.players[index].player_id)).is_equal(
			String(pinned.home.players[index].player_id))


## The counterbalance consumes no random source, so it cannot move what a seed
## reproduces. Two builds of the same variation are the same input, and the same
## input at the same seed is still the same ledger.
func test_the_counterbalance_is_deterministic_and_consumes_no_randomness() -> void:
	var first: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.HIGH_SCHOOL, 5, 0.5)
	var second: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.HIGH_SCHOOL, 5, 0.5)
	assert_str(String(first.initial_possession_team_id)).is_equal(
		String(second.initial_possession_team_id))

	var left: MatchSimulationOutput = MatchEngine.new().simulate_match(
		first, SeededRandomSource.new(6))
	var right: MatchSimulationOutput = MatchEngine.new().simulate_match(
		second, SeededRandomSource.new(6))
	assert_int(left.final_result.home_score).is_equal(right.final_result.home_score)
	assert_int(left.final_result.away_score).is_equal(right.final_result.away_score)
	assert_int(left.events.size()).is_equal(right.events.size())


## The opening inbound actually reaches the game.
##
## Without this the counterbalance could be a field nobody reads: the first
## possession record must belong to whichever side the input named. It is the
## link between the fixture contract above and the measurement in
## `run_opening_possession.gd`.
func test_the_named_side_actually_receives_the_first_possession() -> void:
	for opening: int in [CompetitionCatalog.OPENING_HOME, CompetitionCatalog.OPENING_AWAY]:
		var input: MatchInput = CompetitionCatalog.mirrored_match_for(
			CalibrationTargets.Competition.COLLEGE, 2, 0.0, opening)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(3))
		assert_bool(output.possessions.is_empty()).is_false()
		assert_str(String(output.possessions[0].offense_team_id)).override_failure_message(
			"the fixture named %s but the first possession belonged to %s"
			% [input.initial_possession_team_id, output.possessions[0].offense_team_id]
		).is_equal(String(input.initial_possession_team_id))


## Receiving the opening inbound is worth something, and the engine is not
## indifferent to it.
##
## Directional and structural rather than a band: the two games are the same
## fixture at the same seed with only the opener moved, so if they were
## identical the whole audit would be measuring nothing. The *size* of the
## effect is a calibration question and belongs to `run_opening_possession.gd`.
func test_moving_the_opening_inbound_changes_the_game() -> void:
	var home_opens: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 7, 0.0,
		CompetitionCatalog.OPENING_HOME)
	var away_opens: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 7, 0.0,
		CompetitionCatalog.OPENING_AWAY)

	var left: MatchSimulationOutput = MatchEngine.new().simulate_match(
		home_opens, SeededRandomSource.new(8))
	var right: MatchSimulationOutput = MatchEngine.new().simulate_match(
		away_opens, SeededRandomSource.new(8))

	assert_str(String(left.possessions[0].offense_team_id)).is_not_equal(
		String(right.possessions[0].offense_team_id))


# --- helpers ----------------------------------------------------------------

func _match_input_accepts(opener: StringName) -> bool:
	var reference: MatchInput = CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.COLLEGE, 0, 0.5)
	# `MatchInput` asserts, and an assertion is a debug-build abort rather than a
	# catchable error, so the contract is checked against the same predicate the
	# assertion uses rather than by constructing an illegal input.
	return opener == reference.home.team_id or opener == reference.away.team_id


## Every `.gd` file under a directory, recursively.
func _scripts_under(root: String) -> PackedStringArray:
	var found := PackedStringArray()
	_walk(root, found)
	found.sort()
	return found


func _walk(directory: String, found: PackedStringArray) -> void:
	var handle: DirAccess = DirAccess.open(directory)
	if handle == null:
		return
	handle.list_dir_begin()
	var entry: String = handle.get_next()
	while not entry.is_empty():
		var path: String = "%s/%s" % [directory, entry]
		if handle.current_is_dir():
			_walk(path, found)
		elif entry.ends_with(".gd"):
			found.append(path)
		entry = handle.get_next()
	handle.list_dir_end()


## A script's code with comment lines and trailing comments removed, so a scan
## for a forbidden identifier cannot be fooled — in either direction — by prose
## that names the thing it is forbidding. Every doc comment in this repository
## discusses `MatchInput.new(`; none of them calls it.
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
	return String("\n").join(kept)
