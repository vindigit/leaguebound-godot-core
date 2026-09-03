class_name TestPppDecomposition
extends GdUnitTestSuite

## The points-per-possession accounting identity, and the contest correction
## that §5.20 chose from it.
##
## Two different kinds of assertion live here, and the distinction matters:
##
## - **The accounting**, which must be exact. If `2PT + 3PT + FT` does not equal
##   the ledger's points, or the possession denominators disagree, every
##   attribution built on the decomposition is worthless — and worse, it will
##   still add up and still look reasonable.
## - **The correction's contract**, which must move the thing it was chosen for
##   and leave alone the things it was not. A scoring reduction hiding behind a
##   turnover increase would pass a points-per-possession band and fail
##   basketball; these tests exist so that trade cannot be made silently.
##
## The identity half of this suite has already earned its place. It caught the
## decomposition reading `event.points` on `FREE_THROW_MADE`, which the ledger
## leaves at zero because a free throw's value is carried by the event type —
## about thirty points a game, silently missing, on the very first run.

const TOLERANCE: float = 0.000001

## Enough games to exercise the identity across overtime, foul-outs, offensive
## rebounds and garbage time without making the suite slow.
const IDENTITY_GAMES: int = 6

## A range this suite owns, disjoint from every calibration range.
const SUITE_BASE: int = 890000


func _decompose(competition: int, games: int, span: float = -1.0) -> PppDecomposition:
	var decomposition := PppDecomposition.new()
	for index in range(games):
		var variation: int = SUITE_BASE + index
		var balance := SimulationBalanceProfile.new()
		if span >= 0.0:
			balance.contest_capability_span = span
		var home: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"home", variation * 2, balance, 0.0)
		var away: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"away", variation * 2 + 1, balance, 0.0)
		var input := MatchInput.new(
			StringName("ppp_%d" % variation), StringName("ppp_game_%d" % variation),
			CompetitionCatalog.rules_for(competition), balance, home, away,
			CompetitionCatalog.opening_team_id(
				CompetitionCatalog.OPENING_COUNTERBALANCED, variation, home, away),
			CompetitionCatalog.ratings_profile(), 0.5)
		decomposition.accumulate(
			input, MatchEngine.new().simulate_match(
				input, SeededRandomSource.new(variation + 1)))
	return decomposition


# --- 1. the accounting identity ---------------------------------------------

## `2PT points + 3PT points + FT points` equals the ledger's total points, and
## the three points-per-possession terms sum to the published total.
func test_the_scoring_terms_account_for_every_point() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, IDENTITY_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	assert_bool(decomposition.identity_holds()).override_failure_message(
		"%d ledger points are not attributable to a 2PT, 3PT or FT term"
		% decomposition.unexplained_points()).is_true()
	assert_int(decomposition.unexplained_points()).is_equal(0)
	assert_int(totals.accounted_points()).is_equal(totals.points)
	assert_float(
		totals.two_point_ppp() + totals.three_point_ppp() + totals.free_throw_ppp()
	).is_equal_approx(totals.points_per_possession(), TOLERANCE)


## A made free throw counts as one point.
##
## Pinned explicitly because the ledger does not say so in the field a reader
## would look in: `FREE_THROW_MADE` carries `points = 0` and uses `amount` for
## the attempt index. Any future decomposition that reads `event.points` here
## will silently lose every free-throw point, which is the exact defect this
## constant was introduced to prevent.
func test_a_made_free_throw_is_worth_one_point_by_event_type() -> void:
	assert_int(PppDecomposition.FREE_THROW_POINTS).is_equal(1)

	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, 2)
	var totals: PppDecomposition.Totals = decomposition.totals
	assert_int(totals.free_throws_made).is_greater(0)
	assert_int(totals.free_throw_points()).is_equal(totals.free_throws_made)


# --- 2. possession-denominator reconciliation -------------------------------

## The possession count reconciles independently against three sources: the
## `POSSESSION_ENDED` events, the possession records, and the box score's own
## points total. All three are produced by different code paths.
func test_the_possession_denominator_reconciles_against_every_source() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.OVERSEAS, IDENTITY_GAMES)

	assert_array(decomposition.violations).override_failure_message(
		"reconciliation breaches: %s" % String(", ").join(decomposition.violations)
	).is_empty()
	assert_bool(decomposition.is_reconciled()).is_true()
	assert_int(decomposition.totals.possessions).is_greater(0)


## The reconciliation can actually fail. A gate that cannot fire is not a gate,
## and this one is load-bearing: it is the only thing standing between a wrong
## decomposition and a decomposition that adds up.
func test_the_reconciliation_reports_a_breach_rather_than_absorbing_it() -> void:
	var decomposition := PppDecomposition.new()
	decomposition.totals.points = 100
	decomposition.totals.two_point_made = 10   # 20 points accounted, 100 claimed

	assert_bool(decomposition.identity_holds()).is_false()
	assert_int(decomposition.unexplained_points()).is_equal(80)
	assert_bool(decomposition.is_reconciled()).is_false()


# --- 3. the correction moves the component it was chosen for ----------------

## Widening the contest capability span shifts the contest-band distribution
## away from `OPEN` and raises the mean contest penalty.
##
## This is the mechanism §5.20 diagnosed and the one the correction targets. It
## is asserted directionally rather than against a number, because the exact
## distribution is a calibration measurement and belongs to the runner.
func test_widening_the_capability_span_shifts_contest_pressure_upward() -> void:
	var narrow: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, IDENTITY_GAMES, 0.35)
	var wide: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, IDENTITY_GAMES, 0.60)

	var open_band: int = ContestBand.Value.OPEN
	assert_float(wide.totals.contest_share(open_band)).override_failure_message(
		"a wider capability span did not reduce the share of open shots"
	).is_less(narrow.totals.contest_share(open_band))
	# And the shipped value sits between the two, which is what makes it a
	# correction of this mechanism rather than a coincidence.
	assert_float(SimulationBalanceProfile.new().contest_capability_span
		).is_greater(0.35)
	assert_float(SimulationBalanceProfile.new().contest_capability_span
		).is_less(0.60)


## The span is what the shipped profile actually carries, and it is inside the
## declared safe range.
func test_the_shipped_capability_span_is_the_corrected_value() -> void:
	var shipped := SimulationBalanceProfile.new()
	assert_float(shipped.contest_capability_span).is_equal_approx(0.46, TOLERANCE)
	assert_str(String(shipped.version)).is_equal("simulation-v11-quick-two-stakes-window")
	# The other three contest tunables were not touched by the correction.
	assert_float(shipped.contest_base_pressure).is_equal_approx(0.38, TOLERANCE)
	assert_float(shipped.contest_advantage_relief).is_equal_approx(0.55, TOLERANCE)
	assert_float(shipped.contest_help_weight).is_equal_approx(0.55, TOLERANCE)


# --- 4. unrelated components do not move ------------------------------------

## The correction does not pay for its points with turnovers, offensive
## rebounding, or assists.
##
## This is the compensation check, and it is the one that separates a
## correction from an offset. A scoring reduction financed by a turnover
## increase would satisfy a points-per-possession band and be a different game.
## The tolerances are loose because the sample is small; the point is that these
## quantities do not move *systematically* with the contest span, and a
## mechanism that reached them would move them far more than this.
func test_the_correction_does_not_pay_for_itself_with_turnovers_or_rebounds() -> void:
	var narrow: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, IDENTITY_GAMES, 0.35)
	var wide: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, IDENTITY_GAMES, 0.60)

	assert_float(absf(
		wide.totals.turnover_rate() - narrow.totals.turnover_rate()
	)).override_failure_message(
		"turnover rate moved with the contest span: %.4f -> %.4f"
		% [narrow.totals.turnover_rate(), wide.totals.turnover_rate()]
	).is_less(0.03)
	assert_float(absf(
		wide.totals.offensive_rebound_rate() - narrow.totals.offensive_rebound_rate()
	)).override_failure_message(
		"offensive rebound rate moved with the contest span: %.4f -> %.4f"
		% [narrow.totals.offensive_rebound_rate(), wide.totals.offensive_rebound_rate()]
	).is_less(0.05)
	assert_float(absf(
		wide.totals.assisted_share() - narrow.totals.assisted_share()
	)).override_failure_message(
		"assisted share moved with the contest span: %.4f -> %.4f"
		% [narrow.totals.assisted_share(), wide.totals.assisted_share()]
	).is_less(0.06)


# --- 5. levels stay governed by their own profiles ---------------------------

## Every competition draws its rules from its own profile and its balance from
## the one shared profile. The correction is a single shared value; nothing
## about it is competition-scoped.
func test_the_balance_profile_is_shared_and_the_rules_are_per_competition() -> void:
	var seen_rule_ids: Dictionary = {}
	for competition in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		seen_rule_ids[rules.profile_id] = true
		# One shared balance profile, carrying one shared contest span.
		var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
		assert_float(balance.contest_capability_span).is_equal_approx(0.46, TOLERANCE)
	assert_int(seen_rule_ids.size()).override_failure_message(
		"competitions no longer have distinct rule profiles"
	).is_equal(CalibrationTargets.all_competitions().size())


# --- 11. no competition-ID or target-reading shortcut ------------------------

## Neither the contest construction nor the balance profile reads a competition
## identity or a calibration target.
##
## This is the guard against the correction that was explicitly forbidden: a
## "top domestic points-per-possession correction" keyed on which league is
## playing. The engine must not be able to ask.
func test_the_contest_path_cannot_read_a_competition_or_a_target() -> void:
	var forbidden := RegEx.new()
	# `rule_profile` and the individual competition id strings were added after a
	# mutation battery walked straight past this guard: a high-school-only and a
	# college-only scoring bonus, and a competition-scoped contest relief, all
	# reached their per-league branch through
	# `context.input.rule_profile.profile_id` and matched none of the four
	# patterns this regex used to carry.
	#
	# A bare `profile_id` is deliberately *not* forbidden: the balance profile
	# has one of its own, naming the balance profile rather than a league, so
	# forbidding the token outright would fail on a file that is doing nothing
	# wrong. `rule_profile` is the route to a competition, and it is the one
	# that is banned.
	assert_int(forbidden.compile(
		"CalibrationTargets|CompetitionCatalog|competition_id|rule_profile"
		+ "|high_school|college|domestic_development|overseas|top_domestic"
	)).is_equal(OK)
	for path: String in [
		"res://src/domain/basketball/simulation/shot_resolver.gd",
		"res://src/domain/basketball/config/simulation_balance_profile.gd",
	]:
		var code: String = _executable_source(path)
		assert_str(code).override_failure_message("could not read %s" % path).is_not_empty()
		var found: RegExMatch = forbidden.search(code)
		assert_bool(found != null).override_failure_message(
			"%s reads a competition identity or a calibration target ('%s'); the "
			% [path, "" if found == null else found.get_string()]
			+ "correction must be a shared mechanism, not a per-league adjustment"
		).is_false()


## The contest pressure formula reads defensive capability, reach, help and the
## offence's advantage — and no score, margin or clock.
##
## A contest that could see the scoreboard would be a comeback mechanism with a
## defensive label on it.
func test_contest_pressure_never_reads_the_scoreboard() -> void:
	var scoreboard := RegEx.new()
	assert_int(scoreboard.compile(
		"offense_margin|defense_margin|margin_for|home_score|away_score"
	)).is_equal(OK)
	var body: String = _function_source(
		"res://src/domain/basketball/simulation/shot_resolver.gd", "build_contest")
	assert_str(body).is_not_empty()
	var found: RegExMatch = scoreboard.search(body)
	assert_bool(found != null).override_failure_message(
		"build_contest reads the scoreboard ('%s')"
		% ("" if found == null else found.get_string())).is_false()


# --- 13. golden-ledger behaviour remains explainable ------------------------

## Every golden scenario still produces the behaviour it is named for.
##
## The regeneration harness refuses to write a hash for a scenario that stopped
## exercising its own requirement, so this asserts the same property the
## regeneration depended on — that the one hash which moved moved because the
## game changed, not because the fixture stopped being the fixture.
func test_every_golden_scenario_still_exercises_its_named_behaviour() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		assert_bool(GoldenScenarios.meets_requirement(scenario, output)
		).override_failure_message(
			"golden scenario '%s' no longer produces %s"
			% [scenario, GoldenScenarios.describe_requirement(scenario)]
		).is_true()


# --- helpers ----------------------------------------------------------------

func _function_source(path: String, function_name: String) -> String:
	var code: String = _executable_source(path)
	var start: int = code.find("func %s(" % function_name)
	if start < 0:
		return ""
	var next: int = code.find("\nfunc ", start + 1)
	return code.substr(start, code.length() - start if next < 0 else next - start)


## A script's code with comments removed, so a scan for a forbidden identifier
## cannot be fooled by prose that names the thing it forbids.
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
