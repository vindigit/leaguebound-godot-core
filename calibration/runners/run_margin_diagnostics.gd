extends SceneTree

## Score-margin decomposition (`BALANCE_SPEC.md` §14.2, Stage 4 margin brief).
##
## This runner exists because the §14.2 game-shape failure — 34.5% blowouts
## against a target of 8-18%, 19.3% close games against 22-34% — is a statement
## about the *dispersion* of the final margin, and a competition report that
## prints three shares cannot say where that dispersion came from. This one can.
##
## Every game contributes one `MarginDecomposition.GameRow`, and the report
## publishes three things the competition report does not:
##
## 1. The pregame `TeamStrengthIndex` gap, computed from simulation-relevant
##    capabilities only, and the share of margin variance it explains. Overall is
##    never read; §6.2 forbids it as a simulation input and a diagnostic built on
##    it would be describing a number the engine never sees.
## 2. An exact six-term additive decomposition of the signed margin, with each
##    term's covariance share of the margin variance. The shares sum to one
##    because the terms sum to the margin in every row.
## 3. The same game-shape metrics conditioned on the pregame gap, so a blowout
##    between two teams that were never close can be told apart from a blowout in
##    a game that should have been even. Correcting the second without
##    destroying the first is the whole point of the exercise.
##
## Symmetry diagnostics are reported beside them: home and away are drawn from
## the same population and given the same tactics, so any systematic asymmetry
## in minutes, substitutions, possessions or strength is a defect rather than a
## finding about basketball.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_margin_diagnostics.gd -- \
##       [--games=N] [--competition=top_domestic_pro] [--shard=I --shards=N] [--label=NAME]

const DEFAULT_GAMES: int = 400

## Matchup bands, in `TeamStrengthIndex` centi-capability points of pregame gap.
## Fixed rather than sample-quantiles so two runs cut the population the same
## way; the report publishes the share of games landing in each band so a fixture
## whose population drifted is visible rather than silently re-banded.
const BAND_EVEN_MAX: float = 1.5
const BAND_MODEST_MAX: float = 4.0

const BAND_IDS: PackedStringArray = ["near_even", "modest", "large"]
const BAND_LOWER: PackedFloat64Array = [0.0, BAND_EVEN_MAX, BAND_MODEST_MAX]
const BAND_UPPER: PackedFloat64Array = [BAND_EVEN_MAX, BAND_MODEST_MAX, INF]

## Absolute-margin percentiles published beside the median, so the shape of the
## tail is legible rather than summarized by one share.
const REPORTED_PERCENTILES: PackedFloat64Array = [0.10, 0.25, 0.75, 0.90, 0.95, 0.99]

## `population` samples the calibration fixture the competition report uses.
## `mirror` plays every game between two identical rosters, which fixes the
## pregame gap at exactly zero and leaves only the dispersion the engine itself
## produces. The §14.2 bands describe a real league and are judged on
## `population` only; a mirror run is a measurement of the engine, not of the
## competition, and the report says so rather than letting a reader mistake one
## for the other.
const MODE_POPULATION: String = "population"
const MODE_MIRROR: String = "mirror"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(
		options, &"competition", "top_domestic_pro")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = maxi(1, CalibrationCli.int_option(options, &"shards", 1))
	var label: String = CalibrationCli.string_option(options, &"label", "margin")
	var mode: String = CalibrationCli.string_option(options, &"mode", MODE_POPULATION)
	# §19.4 home environment strength. Exposed so a symmetry run can switch it
	# off: with it on, "is the home side favoured" and "is the engine symmetric"
	# are the same measurement and neither can be read.
	var home_environment: float = CalibrationCli.float_option(
		options, &"home_environment", 0.5)
	var competition: int = _competition(selection)
	if mode != MODE_POPULATION and mode != MODE_MIRROR:
		printerr("unknown mode '%s'; using %s" % [mode, MODE_POPULATION])
		mode = MODE_POPULATION

	var context := ReportContext.create(
		&"margin_diagnostics",
		"Score-margin decomposition",
		CompetitionCatalog.rules_for(competition),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games"
	context.sample_count = games
	context.competition_id = CalibrationTargets.competition_id(competition)
	context.set_shard(shard, shards, shard * games + 1, shard * games + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"Pregame strength is the planned-minute-weighted mean of the §5.2 capability "
		+ "values in TeamStrengthIndex. Overall is not read.")
	context.notes.append(
		"Matchup bands are absolute pregame gap in centi-capability points: "
		+ "near-even < %.1f, modest %.1f-%.1f, large >= %.1f."
			% [BAND_EVEN_MAX, BAND_EVEN_MAX, BAND_MODEST_MAX, BAND_MODEST_MAX])

	context.notes.append(
		"Fixture mode: %s; home environment %.2f." % [mode, home_environment])
	if mode == MODE_MIRROR:
		context.notes.append(
			"Mirror matches are played between two identical rosters. The §14.2 "
			+ "bands describe a real league and are not a target for this mode; "
			+ "the shares below are reported as engine dispersion only.")

	var decomposition: MarginDecomposition = _simulate(
		competition, games, shard, mode, home_environment)
	var report := CalibrationReport.new(context)
	_judge(report, decomposition, mode)
	report.add_section(&"component_variance", _component_rows(decomposition))
	report.add_section(&"matchup_bands", _band_rows(decomposition))
	report.add_section(&"margin_histogram", _histogram_rows(decomposition))
	report.finish()
	_print_summary(decomposition)
	quit(ReportWriter.publish(report, "margin_diagnostics_%s" % label))


func _competition(selection: String) -> int:
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return competition
	printerr("unknown competition '%s'; using top_domestic_pro" % selection)
	return CalibrationTargets.Competition.TOP_DOMESTIC_PRO


func _simulate(
	competition: int,
	games: int,
	shard: int,
	mode: String,
	home_environment: float,
) -> MarginDecomposition:
	var decomposition := MarginDecomposition.new()
	var base: int = shard * games
	for index in range(games):
		var variation: int = base + index
		# Built exactly as the competition runner builds it, so the population
		# this report explains is the population that report measures.
		var input: MatchInput = (
			CompetitionCatalog.mirrored_match_for(competition, variation, home_environment)
			if mode == MODE_MIRROR
			else CompetitionCatalog.match_for(competition, variation, home_environment)
		)
		var seed_value: int = variation + 1
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		decomposition.add(_row(input, output, variation, seed_value))
	return decomposition


func _row(
	input: MatchInput,
	output: MatchSimulationOutput,
	variation: int,
	seed_value: int,
) -> MarginDecomposition.GameRow:
	var row := MarginDecomposition.GameRow.new()
	row.variation = variation
	row.seed = seed_value

	var home_index: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.home, input.ratings_profile, input.balance_profile)
	var away_index: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.away, input.ratings_profile, input.balance_profile)
	row.expected_gap = TeamStrengthIndex.expected_gap(home_index, away_index)
	row.home_strength = home_index.overall
	row.away_strength = away_index.overall
	row.home_starter_strength = home_index.starters
	row.away_starter_strength = away_index.starters
	row.home_bench_strength = home_index.bench
	row.away_bench_strength = away_index.bench

	var result: MatchFinalResult = output.final_result
	var home: TeamStatLine = result.statistics.team_line(input.home.team_id)
	var away: TeamStatLine = result.statistics.team_line(input.away.team_id)
	row.home_score = result.home_score
	row.away_score = result.away_score
	row.overtime_periods = result.overtime_periods

	var regulation: int = input.rule_profile.regulation_periods
	row.regulation_home = _regulation_score(home, regulation)
	row.regulation_away = _regulation_score(away, regulation)

	row.home_possessions = home.engine_possessions
	row.away_possessions = away.engine_possessions
	row.home_field_goals_attempted = home.field_goals_attempted
	row.away_field_goals_attempted = away.field_goals_attempted
	row.home_effective_field_goal = _effective_field_goal(home)
	row.away_effective_field_goal = _effective_field_goal(away)
	row.home_three_attempted = home.three_pointers_attempted
	row.away_three_attempted = away.three_pointers_attempted
	row.home_three_made = home.three_pointers_made
	row.away_three_made = away.three_pointers_made
	row.home_free_throws_made = home.free_throws_made
	row.away_free_throws_made = away.free_throws_made
	row.home_free_throws_attempted = home.free_throws_attempted
	row.away_free_throws_attempted = away.free_throws_attempted
	row.home_turnovers = home.turnovers
	row.away_turnovers = away.turnovers
	row.home_offensive_rebounds = home.offensive_rebounds
	row.away_offensive_rebounds = away.offensive_rebounds
	row.home_second_chance_points = home.second_chance_points
	row.away_second_chance_points = away.second_chance_points
	row.home_transition_points = home.transition_points
	row.away_transition_points = away.transition_points
	row.home_fouls = home.personal_fouls
	row.away_fouls = away.personal_fouls
	row.home_bonus_free_throws = home.bonus_free_throws_awarded
	row.away_bonus_free_throws = away.bonus_free_throws_awarded

	_fill_minutes(row, input, result)
	_fill_event_terms(row, input, output)
	_fill_period_margins(row, home, away)
	return row


func _regulation_score(line: TeamStatLine, regulation_periods: int) -> int:
	var total: int = 0
	for index in range(mini(regulation_periods, line.period_scores.size())):
		total += line.period_scores[index]
	return total


func _effective_field_goal(line: TeamStatLine) -> float:
	if line.field_goals_attempted <= 0:
		return 0.0
	return (
		float(line.field_goals_made) + 0.5 * float(line.three_pointers_made)
	) / float(line.field_goals_attempted)


## Starter and bench minutes, and the starter-strength split, so an asymmetric
## rotation is visible as a number rather than inferred.
func _fill_minutes(
	row: MarginDecomposition.GameRow,
	input: MatchInput,
	result: MatchFinalResult,
) -> void:
	for team: TeamMatchProfile in [input.home, input.away]:
		var starters: Array[StringName] = team.starters()
		var starter_minutes: float = 0.0
		var bench_minutes: float = 0.0
		for line: PlayerStatLine in result.statistics.players_for(team.team_id):
			if starters.has(line.player_id):
				starter_minutes += line.minutes_played()
			else:
				bench_minutes += line.minutes_played()
		if team.team_id == input.home.team_id:
			row.home_starter_minutes = starter_minutes
			row.home_bench_minutes = bench_minutes
		else:
			row.away_starter_minutes = starter_minutes
			row.away_bench_minutes = bench_minutes


## Substitutions, intentional fouls, high-leverage possessions, and the largest
## unanswered run — all read from the ledger and the possession records rather
## than recomputed from the box score.
func _fill_event_terms(
	row: MarginDecomposition.GameRow,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	for event in output.events:
		if event.event_type == MatchDomainEvent.CHECK_IN and event.detail_id != &"starting_lineup":
			if event.team_id == input.home.team_id:
				row.home_substitutions += 1
			elif event.team_id == input.away.team_id:
				row.away_substitutions += 1
			if event.detail_id == &"decided_game":
				row.decided_game_substitutions += 1
		elif event.event_type == MatchDomainEvent.FOUL and event.detail_id == &"intentional":
			row.intentional_fouls += 1

	row.possession_outcome_counts = PackedInt32Array()
	row.possession_outcome_counts.resize(5)
	var run_team: StringName = &""
	var run_points: int = 0
	var largest: int = 0
	for record: PossessionRecord in output.possessions:
		var points: float = float(record.points_scored)
		if record.offense_team_id == input.home.team_id:
			row.home_possession_points_squared += points * points
		else:
			row.away_possession_points_squared += points * points
		row.possession_outcome_counts[mini(record.points_scored, 4)] += 1
		if record.points_scored >= 4:
			if record.offense_team_id == input.home.team_id:
				row.home_high_leverage += 1
			else:
				row.away_high_leverage += 1
			row.high_leverage_points += record.points_scored
		if record.points_scored <= 0:
			continue
		if record.offense_team_id == run_team:
			run_points += record.points_scored
		else:
			run_team = record.offense_team_id
			run_points = record.points_scored
		largest = maxi(largest, run_points)
	row.largest_run = largest


func _fill_period_margins(
	row: MarginDecomposition.GameRow,
	home: TeamStatLine,
	away: TeamStatLine,
) -> void:
	row.period_margins = PackedFloat64Array()
	var periods: int = mini(home.period_scores.size(), away.period_scores.size())
	for index in range(periods):
		row.period_margins.append(float(home.period_scores[index] - away.period_scores[index]))


# --- judging ----------------------------------------------------------------

func _judge(
	report: CalibrationReport,
	decomposition: MarginDecomposition,
	mode: String,
) -> void:
	var games: int = decomposition.size()
	var judged: bool = mode == MODE_POPULATION

	report.add_metric(CalibrationMetric.boolean(
		&"decomposition.identity_closes",
		"The six-term margin identity reconstructs every game's signed margin to "
		+ "within a thousandth of a point. A partition of a total that is not the "
		+ "margin is not a partition of the margin.",
		decomposition.worst_identity_error() < 0.001,
		"Stage 4 margin brief, phase 2",
		games))

	report.add_metric(_shape_metric(
		&"shape.blowout_rate",
		"Games decided by twenty points or more, divided by games played.",
		decomposition.blowout_share(), decomposition.blowout_count(),
		CalibrationTargets.blowout_share(), games, judged))
	report.add_metric(_shape_metric(
		&"shape.close_game_rate",
		"Games decided by five points or fewer, divided by games played.",
		decomposition.close_share(), decomposition.close_count(),
		CalibrationTargets.close_game_share(), games, judged))
	report.add_metric(_shape_metric(
		&"shape.overtime_rate",
		"Games reaching at least one overtime period, divided by games played.",
		decomposition.overtime_share(), decomposition.overtime_count(),
		CalibrationTargets.overtime_frequency(), games, judged))

	report.add_metric(CalibrationMetric.raw(
		&"shape.margin_standard_deviation",
		"Standard deviation of the signed home-minus-away final margin. This is "
		+ "the quantity the §14.2 shares are three views of.",
		"complete games", decomposition.margin_standard_deviation(), games))
	report.add_metric(CalibrationMetric.raw(
		&"shape.mean_absolute_margin",
		"Mean absolute final margin.", "complete games",
		CalibrationStatistics.mean(decomposition.absolute_margins()), games)
		.with_aggregation(MetricAggregation.mean_of(decomposition.absolute_margins())))
	report.add_metric(CalibrationMetric.raw(
		&"shape.median_absolute_margin",
		"Median absolute final margin.", "complete games",
		decomposition.absolute_margin_percentile(0.50), games))
	for percentile in REPORTED_PERCENTILES:
		report.add_metric(CalibrationMetric.raw(
			StringName("shape.absolute_margin_p%02d" % int(percentile * 100.0)),
			"Percentile of the absolute final margin.", "complete games",
			decomposition.absolute_margin_percentile(percentile), games))
	report.add_metric(CalibrationMetric.raw(
		&"shape.one_possession_rate",
		"Games decided by three points or fewer.", "complete games",
		decomposition.one_possession_share(), games))
	report.add_metric(CalibrationMetric.raw(
		&"shape.two_possession_rate",
		"Games decided by six points or fewer.", "complete games",
		decomposition.two_possession_share(), games))
	report.add_metric(CalibrationMetric.raw(
		&"shape.regulation_tie_rate",
		"Games level at the end of regulation. Every one of them must enter "
		+ "overtime, so this is the overtime rate's own denominator.",
		"complete games", decomposition.regulation_tie_share(), games))
	report.add_metric(CalibrationMetric.boolean(
		&"shape.regulation_ties_enter_overtime",
		"Every regulation tie reached overtime and every overtime game was tied "
		+ "at the end of regulation.",
		_ties_and_overtime_agree(decomposition),
		"SIMULATION_SPEC.md §3.1", games))

	# --- pregame strength ---------------------------------------------------
	report.add_metric(CalibrationMetric.raw(
		&"strength.explained_variance_share",
		"R-squared of the least-squares regression of signed final margin on the "
		+ "pregame TeamStrengthIndex gap. The share of margin variance that was "
		+ "settled before tip-off.",
		"complete games", decomposition.strength_explained_share(), games))
	report.add_metric(CalibrationMetric.raw(
		&"strength.slope_points_per_capability_point",
		"Least-squares slope: points of final margin per centi-capability point "
		+ "of pregame gap.",
		"complete games", decomposition.strength_slope(), games))
	report.add_metric(CalibrationMetric.raw(
		&"strength.residual_standard_deviation",
		"Standard deviation of the final margin after the pregame gap is removed: "
		+ "the dispersion the engine generates inside a fixed matchup.",
		"complete games", decomposition.residual_standard_deviation(), games))
	report.add_metric(CalibrationMetric.raw(
		&"strength.gap_standard_deviation",
		"Standard deviation of the pregame gap itself. This is a property of the "
		+ "calibration fixture, not of the engine.",
		"complete games", _standard_deviation(decomposition.expected_gaps()), games))
	report.add_metric(CalibrationMetric.raw(
		&"strength.mean_absolute_gap",
		"Mean absolute pregame gap.", "complete games",
		_mean_absolute(decomposition.expected_gaps()), games))

	# --- component variance shares ------------------------------------------
	for component in range(MarginDecomposition.COMPONENT_COUNT):
		report.add_metric(CalibrationMetric.raw(
			StringName("component.%s_variance_share" % MarginDecomposition.COMPONENT_IDS[component]),
			"Cov(component, margin) / Var(margin). The six shares sum to one.",
			"complete games", decomposition.variance_share(component), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("component.%s_standard_deviation" % MarginDecomposition.COMPONENT_IDS[component]),
			"Standard deviation of this component of the signed margin, in points.",
			"complete games", _standard_deviation(decomposition.column(component)), games))

	# --- symmetry -----------------------------------------------------------
	_judge_symmetry(report, decomposition)

	# --- per-band shape -----------------------------------------------------
	for index in range(BAND_IDS.size()):
		_judge_band(
			report, decomposition, StringName(BAND_IDS[index]),
			BAND_LOWER[index], BAND_UPPER[index])

	# --- late game and possession detail ------------------------------------
	report.add_metric(CalibrationMetric.raw(
		&"late_game.intentional_fouls_per_game",
		"Fouls emitted with the intentional type, per game.", "complete games",
		_mean_of(decomposition, func(row: MarginDecomposition.GameRow) -> float:
			return float(row.intentional_fouls)), games))
	report.add_metric(CalibrationMetric.raw(
		&"late_game.decided_game_substitutions_per_game",
		"Check-ins whose reason is the §18.2 settled-game rotation, per game, "
		+ "both teams. Zero would mean the rule never fires.",
		"complete games",
		_mean_of(decomposition, func(row: MarginDecomposition.GameRow) -> float:
			return float(row.decided_game_substitutions)), games))
	report.add_metric(CalibrationMetric.raw(
		&"late_game.decided_game_share",
		"Share of games in which the §18.2 settled-game rotation fired at least "
		+ "once.", "complete games",
		_mean_of(decomposition, func(row: MarginDecomposition.GameRow) -> float:
			return 1.0 if row.decided_game_substitutions > 0 else 0.0), games))
	report.add_metric(CalibrationMetric.raw(
		&"possession.high_leverage_per_game",
		"Possessions scoring four or more points to one team, per game.",
		"complete games",
		_mean_of(decomposition, func(row: MarginDecomposition.GameRow) -> float:
			return float(row.home_high_leverage + row.away_high_leverage)), games))
	report.add_metric(CalibrationMetric.raw(
		&"possession.largest_run_mean",
		"Mean largest unanswered scoring run, in points.", "complete games",
		_mean_of(decomposition, func(row: MarginDecomposition.GameRow) -> float:
			return float(row.largest_run)), games))
	report.add_metric(CalibrationMetric.raw(
		&"possession.points_variance",
		"Pooled within-team-game variance of one possession's points. Estimated "
		+ "inside games, so differences between games cannot leak into it.",
		"engine possessions", decomposition.within_game_possession_variance(), games))
	report.add_metric(CalibrationMetric.raw(
		&"possession.independent_margin_standard_deviation",
		"The margin standard deviation implied if every possession were an "
		+ "independent draw from the marginal distribution above.",
		"complete games", decomposition.independent_margin_standard_deviation(), games))
	report.add_metric(CalibrationMetric.raw(
		&"possession.overdispersion_ratio",
		"Realized margin standard deviation divided by the independent-possession "
		+ "implication. One means the margin is exactly accumulated independent "
		+ "possessions; above one means possessions inside a game agree with each "
		+ "other and the tails are inflated by that agreement.",
		"complete games", decomposition.overdispersion_ratio(), games))
	for bucket in range(5):
		report.add_metric(CalibrationMetric.raw(
			StringName("possession.outcome_share_%d" % bucket),
			"Share of possessions scoring exactly this many points; the last "
			+ "bucket is four or more.",
			"engine possessions", decomposition.possession_outcome_share(bucket), games))
	report.add_metric(CalibrationMetric.raw(
		&"scoring.points_per_possession",
		"Total points over total engine possessions across both teams.",
		"engine possessions", _points_per_possession(decomposition), games))
	report.add_metric(CalibrationMetric.raw(
		&"scoring.possessions_per_team_game",
		"Engine possessions per team per game.", "team-games",
		_mean_of(decomposition, func(row: MarginDecomposition.GameRow) -> float:
			return 0.5 * float(row.home_possessions + row.away_possessions)), games))


func _judge_symmetry(report: CalibrationReport, decomposition: MarginDecomposition) -> void:
	var strength_bias: float = _mean_of(decomposition,
		func(row: MarginDecomposition.GameRow) -> float:
			return row.home_strength - row.away_strength)
	var minute_bias: float = _mean_of(decomposition,
		func(row: MarginDecomposition.GameRow) -> float:
			return row.home_starter_minutes - row.away_starter_minutes)
	var substitution_bias: float = _mean_of(decomposition,
		func(row: MarginDecomposition.GameRow) -> float:
			return float(row.home_substitutions - row.away_substitutions))
	var possession_bias: float = _mean_of(decomposition,
		func(row: MarginDecomposition.GameRow) -> float:
			return float(row.home_possessions - row.away_possessions))

	# The signed margin is the symmetry check that matters, and it is the one a
	# small sample cannot answer: at a margin standard deviation near 18 the
	# standard error over 16 games is 4.5 points, so an honest engine produces
	# an eight-point "home edge" in a sixteen-game sample about one time in
	# five. The population report is where the question gets settled.
	var margins: PackedFloat64Array = decomposition.margins()
	report.add_metric(CalibrationMetric.raw(
		&"symmetry.mean_signed_margin",
		"Mean home-minus-away final margin. On the mirror fixture with the home "
		+ "environment switched off, the only asymmetry left is that home "
		+ "inbounds first, so this should sit near one possession's points.",
		"complete games", CalibrationStatistics.mean(margins), decomposition.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(margins)))
	report.add_metric(CalibrationMetric.raw(
		&"symmetry.mean_strength_difference",
		"Mean home-minus-away pregame strength. Home and away are drawn from the "
		+ "same population, so a non-zero mean is a fixture asymmetry.",
		"complete games", strength_bias, decomposition.size()))
	report.add_metric(CalibrationMetric.raw(
		&"symmetry.mean_starter_minute_difference",
		"Mean home-minus-away starter minutes. Both sides run the same rotation "
		+ "shape, so this should be zero to within ordinary game variation.",
		"complete games", minute_bias, decomposition.size()))
	report.add_metric(CalibrationMetric.raw(
		&"symmetry.mean_substitution_difference",
		"Mean home-minus-away non-starting check-ins.", "complete games",
		substitution_bias, decomposition.size()))
	report.add_metric(CalibrationMetric.raw(
		&"symmetry.mean_possession_difference",
		"Mean home-minus-away engine possessions. Possession alternates, so this "
		+ "is bounded by one in a correct engine.",
		"complete games", possession_bias, decomposition.size()))


func _judge_band(
	report: CalibrationReport,
	decomposition: MarginDecomposition,
	band_id: StringName,
	lower: float,
	upper: float,
) -> void:
	var subset: MarginDecomposition = decomposition.band(lower, upper)
	report.add_metric(CalibrationMetric.raw(
		StringName("band.%s.games" % band_id),
		"Games whose absolute pregame gap falls in this band.", "complete games",
		float(subset.size()), subset.size()))
	if subset.size() < 2:
		return
	report.add_metric(CalibrationMetric.raw(
		StringName("band.%s.blowout_rate" % band_id),
		"Blowout share inside this matchup band. A blowout between mismatched "
		+ "teams is basketball; a blowout between even teams is the defect.",
		"complete games", subset.blowout_share(), subset.size()))
	report.add_metric(CalibrationMetric.raw(
		StringName("band.%s.close_game_rate" % band_id),
		"Close-game share inside this matchup band.", "complete games",
		subset.close_share(), subset.size()))
	report.add_metric(CalibrationMetric.raw(
		StringName("band.%s.overtime_rate" % band_id),
		"Overtime share inside this matchup band.", "complete games",
		subset.overtime_share(), subset.size()))
	report.add_metric(CalibrationMetric.raw(
		StringName("band.%s.mean_absolute_margin" % band_id),
		"Mean absolute margin inside this matchup band.", "complete games",
		CalibrationStatistics.mean(subset.absolute_margins()), subset.size()))
	report.add_metric(CalibrationMetric.raw(
		StringName("band.%s.margin_standard_deviation" % band_id),
		"Standard deviation of the signed margin inside this matchup band.",
		"complete games", subset.margin_standard_deviation(), subset.size()))


## A §14.2 share, judged against its band on the population fixture and reported
## without a verdict on the mirror fixture. Mirror games are a measurement of the
## engine rather than of a league, and giving them the league's target would let
## a diagnostic fixture manufacture a pass.
func _shape_metric(
	metric_id: StringName,
	definition: String,
	estimate: float,
	successes: int,
	band: CalibrationBand,
	games: int,
	judged: bool,
) -> CalibrationMetric:
	var metric: CalibrationMetric = (
		CalibrationMetric.raw(
			metric_id,
			definition + " Reported without a verdict: the mirror fixture is not "
			+ "the population §14.2 describes.",
			"complete games", estimate, games)
		if not judged
		else CalibrationMetric.banded(
			metric_id, definition, "complete games", estimate, band, games)
	)
	return metric.with_aggregation(MetricAggregation.proportion(successes, games))


func _ties_and_overtime_agree(decomposition: MarginDecomposition) -> bool:
	for row in decomposition.rows:
		var tied: bool = row.regulation_margin() == 0.0
		if tied != (row.overtime_periods > 0):
			return false
	return true


func _points_per_possession(decomposition: MarginDecomposition) -> float:
	var points: float = 0.0
	var possessions: float = 0.0
	for row in decomposition.rows:
		points += float(row.home_score + row.away_score)
		possessions += float(row.home_possessions + row.away_possessions)
	return points / possessions if possessions > 0.0 else 0.0


func _mean_of(decomposition: MarginDecomposition, extractor: Callable) -> float:
	var values := PackedFloat64Array()
	for row in decomposition.rows:
		var value: float = extractor.call(row)
		values.append(value)
	return CalibrationStatistics.mean(values)


func _mean_absolute(values: PackedFloat64Array) -> float:
	var absolute := PackedFloat64Array()
	for value in values:
		absolute.append(absf(value))
	return CalibrationStatistics.mean(absolute)


func _standard_deviation(values: PackedFloat64Array) -> float:
	return CalibrationStatistics.standard_deviation(values)


# --- report sections --------------------------------------------------------

func _component_rows(decomposition: MarginDecomposition) -> Array:
	var rows: Array = []
	for component in range(MarginDecomposition.COMPONENT_COUNT):
		rows.append({
			"component": MarginDecomposition.COMPONENT_IDS[component],
			"variance_share": decomposition.variance_share(component),
			"standard_deviation": _standard_deviation(decomposition.column(component)),
			"mean": CalibrationStatistics.mean(decomposition.column(component)),
		})
	return rows


func _band_rows(decomposition: MarginDecomposition) -> Array:
	var rows: Array = []
	for index in range(BAND_IDS.size()):
		var subset: MarginDecomposition = decomposition.band(
			BAND_LOWER[index], BAND_UPPER[index])
		rows.append({
			"band": BAND_IDS[index],
			"games": subset.size(),
			"share_of_population": (
				float(subset.size()) / float(decomposition.size())
				if decomposition.size() > 0 else 0.0),
			"blowout_rate": subset.blowout_share(),
			"close_game_rate": subset.close_share(),
			"overtime_rate": subset.overtime_share(),
			"mean_absolute_margin": (
				CalibrationStatistics.mean(subset.absolute_margins())
				if subset.size() > 0 else 0.0),
			"margin_standard_deviation": subset.margin_standard_deviation(),
		})
	return rows


func _histogram_rows(decomposition: MarginDecomposition) -> Array:
	var buckets: Dictionary = {}
	for row in decomposition.rows:
		var bucket: int = int(row.absolute_margin() / 5.0) * 5
		var current: int = buckets.get(bucket, 0)
		buckets[bucket] = current + 1
	var keys: Array = buckets.keys()
	keys.sort()
	var rows: Array = []
	for key: int in keys:
		var count: int = buckets[key]
		rows.append({
			"absolute_margin_floor": key,
			"games": count,
			"share": float(count) / float(decomposition.size()),
		})
	return rows


func _print_summary(decomposition: MarginDecomposition) -> void:
	print("")
	print("  margin sd %.2f   mean |margin| %.2f   median |margin| %.1f" % [
		decomposition.margin_standard_deviation(),
		CalibrationStatistics.mean(decomposition.absolute_margins()),
		decomposition.absolute_margin_percentile(0.50)])
	print("  strength R2 %.4f   slope %.3f pts/cap-pt   residual sd %.2f" % [
		decomposition.strength_explained_share(),
		decomposition.strength_slope(),
		decomposition.residual_standard_deviation()])
	print("  possession var %.4f   independent margin sd %.2f   overdispersion %.3f" % [
		decomposition.within_game_possession_variance(),
		decomposition.independent_margin_standard_deviation(),
		decomposition.overdispersion_ratio()])
	print("")
	print("  %-24s %10s %10s" % ["component", "var share", "sd"])
	for component in range(MarginDecomposition.COMPONENT_COUNT):
		print("  %-24s %10.4f %10.2f" % [
			MarginDecomposition.COMPONENT_IDS[component],
			decomposition.variance_share(component),
			_standard_deviation(decomposition.column(component))])
	print("")
	print("  %-10s %7s %9s %9s %9s %9s" % [
		"band", "games", "blowout", "close", "ot", "sd"])
	for index in range(BAND_IDS.size()):
		var subset: MarginDecomposition = decomposition.band(
			BAND_LOWER[index], BAND_UPPER[index])
		print("  %-10s %7d %9.4f %9.4f %9.4f %9.2f" % [
			BAND_IDS[index], subset.size(), subset.blowout_share(),
			subset.close_share(), subset.overtime_share(),
			subset.margin_standard_deviation()])
	print("")
