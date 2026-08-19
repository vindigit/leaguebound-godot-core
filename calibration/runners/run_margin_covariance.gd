extends SceneTree

## Is the score margin a random walk? (`BALANCE_SPEC.md` §14.2, Stage 4.)
##
## The previous margin analysis reconstructed the final-margin variance as
## `2 n sigma^2` and concluded that §14.2 is unreachable at §14.1's possession
## economy. That reconstruction is exact only under `Cov(A, B) = 0`, and the
## covariance was never measured. This runner measures it, and measures the
## three further things that decide whether the conclusion survives:
##
## - the covariance between the two teams' scoring, raw and once the shared
##   pregame inputs are regressed out;
## - the autocovariance of the margin's own increments, which says whether the
##   path is a random walk possession by possession;
## - the variance ratio at seven horizons, which says the same thing at the
##   horizons a coach actually acts on.
##
## It then publishes the feasibility frontier: what the margin distribution
## would have to look like to satisfy each §14.2 target, computed by rescaling
## the *measured* margin distribution rather than by assuming a normal one, and
## the covariance each rescaling implies through the identity
## `Var(A - B) = Var(A) + Var(B) - 2 Cov(A, B)`.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_margin_covariance.gd -- \
##       [--games=N] [--competition=top_domestic_pro] [--mode=population|mirror] \
##       [--shard=I --shards=N] [--label=NAME] [--home_environment=F]

const DEFAULT_GAMES: int = 400

## The ledger event a coaching timeout would carry. Compared as a literal rather
## than through `MatchDomainEvent` because the engine does not emit one yet: the
## count below is the measurement that says so.
const TIMEOUT_EVENT_TYPE: StringName = &"timeout"

## The independence resampling. The seed is a diagnostic constant far outside
## every simulation range, and the stream never touches a match.
const BOOTSTRAP_SEED: int = 987654321
const BOOTSTRAP_REPEATS: int = 20

## Permutations of each game's own increments used to measure the finite-sample
## artefact the variance ratio would show with no behaviour in it at all.
const CONTROL_PERMUTATIONS: int = 8

## Half-width, in points, of the window the regulation-margin density at zero is
## read over. Wide enough that the estimate is not three games' worth of noise,
## narrow enough that the density is still local.
const TIE_DENSITY_HALF_WIDTH: float = 2.5

## The damped-walk frontier: absolute margins at which a leading team is assumed
## to start protecting, and the points per possession it gives up doing so.
const DAMPING_THRESHOLDS: PackedFloat64Array = [10.0, 15.0]
const DAMPING_PENALTIES: PackedFloat64Array = [0.00, 0.05, 0.10, 0.15, 0.20, 0.30]
const DAMPING_REPEATS: int = 10

const MODE_POPULATION: String = "population"
const MODE_MIRROR: String = "mirror"

## Matchup bands in `TeamStrengthIndex` centi-capability points, identical to
## `run_margin_diagnostics.gd` so the two reports cut the population the same way.
const BAND_EVEN_MAX: float = 1.5
const BAND_MODEST_MAX: float = 4.0
const BAND_IDS: PackedStringArray = ["near_even", "modest", "large"]
const BAND_LOWER: PackedFloat64Array = [0.0, BAND_EVEN_MAX, BAND_MODEST_MAX]
const BAND_UPPER: PackedFloat64Array = [BAND_EVEN_MAX, BAND_MODEST_MAX, INF]

## Dispersion scale factors the frontier is evaluated at. One is the measured
## distribution; below one is a tighter league.
const FRONTIER_SCALES: PackedFloat64Array = [
	1.00, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.40, 0.30]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(
		options, &"competition", "top_domestic_pro")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = maxi(1, CalibrationCli.int_option(options, &"shards", 1))
	var label: String = CalibrationCli.string_option(options, &"label", "covariance")
	var mode: String = CalibrationCli.string_option(options, &"mode", MODE_POPULATION)
	var home_environment: float = CalibrationCli.float_option(
		options, &"home_environment", 0.5)
	var competition: int = _competition(selection)
	if mode != MODE_POPULATION and mode != MODE_MIRROR:
		printerr("unknown mode '%s'; using %s" % [mode, MODE_POPULATION])
		mode = MODE_POPULATION

	var context := ReportContext.create(
		&"margin_covariance",
		"Score-margin covariance and random-walk test",
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
		"Var(A - B) = Var(A) + Var(B) - 2 Cov(A, B). The reconstruction error below is "
		+ "the identity checked on the measured columns, not asserted.")
	context.notes.append(
		"Increment autocorrelation and the variance ratio are centred inside each "
		+ "team-game, so between-game effects — roster quality, pace, rule profile — "
		+ "cannot appear as serial structure.")
	context.notes.append(
		"Fixture mode: %s; home environment %.2f." % [mode, home_environment])
	if mode == MODE_MIRROR:
		context.notes.append(
			"Mirror matches are played between two identical rosters. §14.2 describes "
			+ "a real league and is not a target for this mode.")

	var sample: ScoringCovariance = _simulate(competition, games, shard, mode, home_environment)
	var report := CalibrationReport.new(context)
	_judge_shape(report, sample, mode)
	_report_identity(report, sample)
	_report_conditioned(report, sample)
	_report_path(report, sample)
	_report_states(report, sample)
	_report_behaviour(report, sample)
	_report_independence(report, sample)
	_report_feasibility(report, sample)
	report.add_section(&"gap_bands", _gap_band_rows(sample))
	report.add_section(&"possession_bands", _possession_band_rows(sample))
	report.add_section(&"period_covariance", _period_rows(sample))
	report.add_section(&"score_states", _state_rows(sample))
	report.add_section(&"variance_ratio", _variance_ratio_rows(sample))
	report.add_section(&"feasibility_frontier", _frontier_rows(sample))
	report.add_section(&"damping_frontier", _damping_rows(sample))
	report.finish()
	quit(ReportWriter.publish(report, "margin_covariance_%s" % label))


func _competition(selection: String) -> int:
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return competition
	printerr("unknown competition '%s'; using top_domestic_pro" % selection)
	return CalibrationTargets.Competition.TOP_DOMESTIC_PRO


# --- sampling ----------------------------------------------------------------

func _simulate(
	competition: int,
	games: int,
	shard: int,
	mode: String,
	home_environment: float,
) -> ScoringCovariance:
	var sample := ScoringCovariance.new()
	var base: int = shard * games
	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = (
			CompetitionCatalog.mirrored_match_for(competition, variation, home_environment)
			if mode == MODE_MIRROR
			else CompetitionCatalog.match_for(competition, variation, home_environment)
		)
		var seed_value: int = variation + 1
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		sample.add(_row(input, output, variation, seed_value))
	return sample


func _row(
	input: MatchInput,
	output: MatchSimulationOutput,
	variation: int,
	seed_value: int,
) -> ScoringCovariance.GameRow:
	var row := ScoringCovariance.GameRow.new()
	row.variation = variation
	row.seed = seed_value
	row.home_environment = input.home_environment

	var home_index: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.home, input.ratings_profile, input.balance_profile)
	var away_index: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.away, input.ratings_profile, input.balance_profile)
	row.expected_gap = TeamStrengthIndex.expected_gap(home_index, away_index)
	row.home_strength = home_index.overall
	row.away_strength = away_index.overall

	var result: MatchFinalResult = output.final_result
	var home: TeamStatLine = result.statistics.team_line(input.home.team_id)
	var away: TeamStatLine = result.statistics.team_line(input.away.team_id)
	row.home_points = result.home_score
	row.away_points = result.away_score
	row.overtime_periods = result.overtime_periods
	row.home_possessions = home.engine_possessions
	row.away_possessions = away.engine_possessions

	var regulation: int = input.rule_profile.regulation_periods
	row.regulation_home = _regulation_score(home, regulation)
	row.regulation_away = _regulation_score(away, regulation)
	for index in range(home.period_scores.size()):
		row.home_period_points.append(float(home.period_scores[index]))
	for index in range(away.period_scores.size()):
		row.away_period_points.append(float(away.period_scores[index]))

	_fill_path(row, input, output)
	_fill_events(row, input, output)
	return row


func _regulation_score(line: TeamStatLine, regulation_periods: int) -> int:
	var total: int = 0
	for index in range(mini(regulation_periods, line.period_scores.size())):
		total += line.period_scores[index]
	return total


## Walks the possession records once and fills everything that is a property of
## the margin *path*: the state each possession was played in, lead changes,
## runs, the signed increments and their autocovariance, and the variance-ratio
## accumulators.
func _fill_path(
	row: ScoringCovariance.GameRow,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	var records: Array[PossessionRecord] = output.possessions
	var increments := PackedFloat64Array()
	var is_home_possession := PackedInt32Array()
	var home_points_by_possession := PackedFloat64Array()
	var away_points_by_possession := PackedFloat64Array()
	var margin: int = 0
	var elapsed_ms: float = 0.0
	var previous_sign: int = 0
	var largest_lead: int = 0
	var run_team: StringName = &""
	var run_points: int = 0

	for record: PossessionRecord in records:
		var is_home: bool = record.offense_team_id == input.home.team_id
		var state: int = ScoringCovariance.state_for_margin(absi(margin))
		var duration_ms: float = float(record.start_clock_ms - record.end_clock_ms)
		if record.end_period != record.start_period:
			duration_ms = float(record.start_clock_ms)
		duration_ms = maxf(duration_ms, 0.0)
		elapsed_ms += duration_ms
		row.state_seconds[state] += duration_ms / 1000.0
		row.state_actions[state] += float(record.action_count)
		# Which side of the scoreboard the team with the ball was on, read from
		# the margin *before* this possession so its own points cannot decide it.
		var offense_margin: int = margin if is_home else -margin
		if offense_margin > 0:
			row.leading_state_points[state] += float(record.points_scored)
			row.leading_state_possessions[state] += 1.0
			row.leading_state_seconds[state] += duration_ms / 1000.0
		elif offense_margin < 0:
			row.trailing_state_points[state] += float(record.points_scored)
			row.trailing_state_possessions[state] += 1.0
			row.trailing_state_seconds[state] += duration_ms / 1000.0
		var points: int = record.points_scored
		var bucket: int = mini(points, ScoringCovariance.OUTCOME_BUCKETS - 1)
		if record.start_period <= input.rule_profile.regulation_periods:
			if is_home:
				row.home_outcome_counts[bucket] += 1.0
			else:
				row.away_outcome_counts[bucket] += 1.0
		if is_home:
			row.home_state_points[state] += float(points)
			row.home_state_possessions[state] += 1.0
			home_points_by_possession.append(float(points))
			increments.append(float(points))
			is_home_possession.append(1)
		else:
			row.away_state_points[state] += float(points)
			row.away_state_possessions[state] += 1.0
			away_points_by_possession.append(float(points))
			increments.append(-float(points))
			is_home_possession.append(0)

		# Lead changes and ties are read at the *new* score, so a possession
		# that ties the game counts a tie and one that goes ahead counts a
		# change of leader.
		margin += points if is_home else -points
		var sign_now: int = signi(margin)
		if sign_now == 0:
			row.ties += 1
		elif previous_sign != 0 and sign_now != previous_sign:
			row.lead_changes += 1
		if sign_now != 0:
			previous_sign = sign_now
		largest_lead = maxi(largest_lead, absi(margin))

		if points > 0:
			if record.offense_team_id == run_team:
				run_points += points
			else:
				if run_points >= ScoringCovariance.RUN_POINTS:
					row.runs += 1
					row.run_points_total += run_points
				row.largest_run = maxi(row.largest_run, run_points)
				run_team = record.offense_team_id
				run_points = points
	if run_points >= ScoringCovariance.RUN_POINTS:
		row.runs += 1
		row.run_points_total += run_points
	row.largest_run = maxi(row.largest_run, run_points)
	row.largest_lead = largest_lead
	row.seconds_per_possession = (
		(elapsed_ms / 1000.0) / float(records.size()) if not records.is_empty() else 0.0)

	var home_mean: float = CalibrationStatistics.mean(home_points_by_possession)
	var away_mean: float = CalibrationStatistics.mean(away_points_by_possession)
	_fill_increment_terms(row, increments, is_home_possession, home_mean, away_mean, false)
	# The permuted control, averaged over several permutations so the correction
	# is not itself noisy. The permutation stream is derived from the diagnostic
	# seed and is never the match's own source, so nothing here can change a
	# simulated game.
	var permutation: RandomSource = SeededRandomSource.new(row.seed).derive(&"diagnostic:permute")
	for repeat in range(CONTROL_PERMUTATIONS):
		var order: PackedInt32Array = _permutation(
			increments.size(), permutation.derive(StringName("permutation:%d" % repeat)))
		var shuffled := PackedFloat64Array()
		var shuffled_home := PackedInt32Array()
		for index in order:
			shuffled.append(increments[index])
			shuffled_home.append(is_home_possession[index])
		_fill_increment_terms(row, shuffled, shuffled_home, home_mean, away_mean, true)


## A Fisher-Yates permutation on a diagnostic-only stream.
func _permutation(count: int, random_source: RandomSource) -> PackedInt32Array:
	var order := PackedInt32Array()
	for index in range(count):
		order.append(index)
	for index in range(count - 1, 0, -1):
		var swap_with: int = random_source.range_int(0, index)
		var held: int = order[index]
		order[index] = order[swap_with]
		order[swap_with] = held
	return order


## Centres each team's possession points on its own mean inside this game, then
## accumulates the lag products and the windowed sums of the signed sequence.
##
## Centring inside the team-game is what makes this a measurement of the
## engine's *path* rather than of the population: two teams of different
## quality differ in mean possession value, and an uncentred sequence would
## report that difference as serial structure.
func _fill_increment_terms(
	row: ScoringCovariance.GameRow,
	increments: PackedFloat64Array,
	is_home_possession: PackedInt32Array,
	home_mean: float,
	away_mean: float,
	control: bool,
) -> void:
	var centred := PackedFloat64Array()
	for index in range(increments.size()):
		var offset: float = home_mean if is_home_possession[index] == 1 else -away_mean
		centred.append(increments[index] - offset)

	var squares: float = 0.0
	var count: float = 0.0
	var lag_products: PackedFloat64Array = (
		row.control_lag_products if control else row.lag_products)
	var lag_counts: PackedFloat64Array = (
		row.control_lag_counts if control else row.lag_counts)
	var window_squares: PackedFloat64Array = (
		row.control_window_squares if control else row.window_squares)
	var window_counts: PackedFloat64Array = (
		row.control_window_counts if control else row.window_counts)

	for index in range(centred.size()):
		squares += centred[index] * centred[index]
		count += 1.0
		for lag in range(1, ScoringCovariance.MAX_LAG + 1):
			if index + lag >= centred.size():
				break
			lag_products[lag] += centred[index] * centred[index + lag]
			lag_counts[lag] += 1.0

	for window_index in range(ScoringCovariance.WINDOW_LENGTHS.size()):
		var length: int = ScoringCovariance.WINDOW_LENGTHS[window_index]
		if centred.size() < length:
			continue
		var running: float = 0.0
		for index in range(length):
			running += centred[index]
		window_squares[window_index] += running * running
		window_counts[window_index] += 1.0
		for index in range(length, centred.size()):
			running += centred[index] - centred[index - length]
			window_squares[window_index] += running * running
			window_counts[window_index] += 1.0

	if control:
		row.control_increment_squares += squares
		row.control_increment_count += count
		row.control_lag_products = lag_products
		row.control_lag_counts = lag_counts
		row.control_window_squares = window_squares
		row.control_window_counts = window_counts
		return
	row.increment_squares += squares
	row.increment_count += count
	row.lag_products = lag_products
	row.lag_counts = lag_counts
	row.window_squares = window_squares
	row.window_counts = window_counts


## Reads the ledger once for the score-state shot mix, the settled-game split,
## substitutions, timeouts and intentional fouls. Score is accumulated from the
## scoring events themselves, so every event has a well-defined margin state
## without needing to be mapped back onto a possession.
func _fill_events(
	row: ScoringCovariance.GameRow,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	var margin: int = 0
	for event: MatchDomainEvent in output.events:
		var is_home: bool = event.team_id == input.home.team_id
		var state: int = ScoringCovariance.state_for_margin(absi(margin))
		match event.event_type:
			MatchDomainEvent.FIELD_GOAL_ATTEMPT:
				var three: bool = ShotZone.is_three(ShotZone.from_id(event.zone_id))
				if is_home:
					row.home_state_field_goals[state] += 1.0
					if three:
						row.home_state_threes[state] += 1.0
				else:
					row.away_state_field_goals[state] += 1.0
					if three:
						row.away_state_threes[state] += 1.0
				var shooter_margin: int = margin if is_home else -margin
				if shooter_margin > 0:
					row.leading_state_field_goals[state] += 1.0
					if three:
						row.leading_state_threes[state] += 1.0
				elif shooter_margin < 0:
					row.trailing_state_field_goals[state] += 1.0
					if three:
						row.trailing_state_threes[state] += 1.0
			MatchDomainEvent.FIELD_GOAL_MADE:
				margin += event.points if is_home else -event.points
			MatchDomainEvent.FREE_THROW_MADE:
				margin += 1 if is_home else -1
			MatchDomainEvent.FOUL:
				if event.detail_id == &"intentional":
					row.intentional_fouls += 1
					row.state_intentional_fouls[state] += 1.0
			MatchDomainEvent.CHECK_IN:
				if event.detail_id != &"starting_lineup":
					row.substitutions += 1
					row.state_substitutions[state] += 1.0
			TIMEOUT_EVENT_TYPE:
				row.timeouts += 1
	_fill_settled_split(row, input, output)


## Splits each team's points at the first §18.2 `decided_game` check-in.
func _fill_settled_split(
	row: ScoringCovariance.GameRow,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	var settled: bool = false
	var home_before: float = 0.0
	var away_before: float = 0.0
	var home_after: float = 0.0
	var away_after: float = 0.0
	for event: MatchDomainEvent in output.events:
		if event.event_type == MatchDomainEvent.CHECK_IN and event.detail_id == &"decided_game":
			settled = true
			continue
		var points: int = 0
		if event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
			points = event.points
		elif event.event_type == MatchDomainEvent.FREE_THROW_MADE:
			points = 1
		if points == 0:
			continue
		var is_home: bool = event.team_id == input.home.team_id
		if settled:
			if is_home:
				home_after += float(points)
			else:
				away_after += float(points)
		elif is_home:
			home_before += float(points)
		else:
			away_before += float(points)
	row.settled = settled
	row.home_points_before_settled = home_before
	row.away_points_before_settled = away_before
	row.home_points_after_settled = home_after
	row.away_points_after_settled = away_after


# --- reporting ---------------------------------------------------------------

func _judge_shape(report: CalibrationReport, sample: ScoringCovariance, mode: String) -> void:
	var games: int = sample.size()
	var judged: bool = mode == MODE_POPULATION
	_share(report, &"shape.blowout_rate",
		"Games decided by 20 or more points",
		sample.blowout_share(), sample.blowout_count(), games,
		CalibrationTargets.blowout_share(), judged)
	_share(report, &"shape.close_game_rate",
		"Games decided by five or fewer points",
		sample.close_share(), sample.close_count(), games,
		CalibrationTargets.close_game_share(), judged)
	_share(report, &"shape.overtime_rate",
		"Games reaching at least one overtime period",
		sample.overtime_share(), sample.overtime_count(), games,
		CalibrationTargets.overtime_frequency(), judged)
	_share(report, &"shape.home_win_rate",
		"Home wins over completed games",
		sample.home_win_share(), sample.home_win_count(), games,
		CalibrationTargets.home_win_rate(), judged)
	report.add_metric(CalibrationMetric.raw(&"shape.margin_standard_deviation",
		"Sample standard deviation of the signed final margin", "games",
		sample.margin_standard_deviation(), games))
	report.add_metric(CalibrationMetric.raw(&"shape.mean_absolute_margin",
		"Mean absolute final margin", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return row.absolute_margin()), games))
	report.add_metric(CalibrationMetric.raw(&"shape.median_absolute_margin",
		"Median absolute final margin", "games",
		sample.absolute_margin_percentile(0.50), games))
	report.add_metric(CalibrationMetric.raw(&"shape.one_possession_rate",
		"Games decided by three or fewer points", "games",
		sample.one_possession_share(), games))
	report.add_metric(CalibrationMetric.raw(&"shape.two_possession_rate",
		"Games decided by six or fewer points", "games",
		sample.two_possession_share(), games))
	report.add_metric(CalibrationMetric.raw(&"shape.regulation_tie_rate",
		"Games level at the end of regulation", "games",
		sample.regulation_tie_share(), games))
	report.add_metric(CalibrationMetric.raw(&"scoring.points_per_possession",
		"Total points over total engine possessions, both teams", "team-games",
		_points_per_possession(sample), games * 2))
	report.add_metric(CalibrationMetric.raw(&"scoring.possessions_per_team_game",
		"Engine possessions per team-game", "team-games",
		_possessions_per_team_game(sample), games * 2))


func _report_identity(report: CalibrationReport, sample: ScoringCovariance) -> void:
	var games: int = sample.size()
	report.add_metric(CalibrationMetric.raw(&"variance.home_points",
		"Var(home final points)", "games", sample.home_points_variance(), games))
	report.add_metric(CalibrationMetric.raw(&"variance.away_points",
		"Var(away final points)", "games", sample.away_points_variance(), games))
	report.add_metric(CalibrationMetric.raw(&"variance.margin",
		"Var(home points - away points)", "games", sample.margin_variance(), games))
	report.add_metric(CalibrationMetric.raw(&"variance.margin_reconstructed",
		"Var(A) + Var(B) - 2 Cov(A, B) from the measured columns", "games",
		sample.reconstructed_margin_variance(), games))
	report.add_metric(CalibrationMetric.raw(&"variance.reconstruction_error",
		"Absolute difference between the measured and reconstructed margin variance",
		"games", sample.reconstruction_error(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.points",
		"Cov(home final points, away final points)", "games",
		sample.points_covariance(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.points_correlation",
		"Corr(home final points, away final points)", "games",
		sample.points_correlation(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.points_per_possession",
		"Cov(home points per possession, away points per possession)", "games",
		sample.points_per_possession_covariance(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.points_per_possession_correlation",
		"Corr(home points per possession, away points per possession)", "games",
		sample.points_per_possession_correlation(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.residual_points",
		"Cov of both teams' points after regressing out pregame strength, realized "
		+ "pace, total possessions and the home environment", "games",
		sample.residual_points_covariance(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.residual_correlation",
		"Corr of the same residuals", "games",
		sample.residual_points_correlation(), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.possessions",
		"Cov(home engine possessions, away engine possessions)", "games",
		ScoringCovariance.covariance(sample.home_possessions(), sample.away_possessions()),
		games))
	report.add_metric(CalibrationMetric.raw(&"covariance.shared_possession_component",
		"Covariance a shared possession count alone implies: "
		+ "mean(ppp_home) * mean(ppp_away) * Cov(n_home, n_away)", "games",
		sample.shared_possession_covariance(), games))


func _report_conditioned(report: CalibrationReport, sample: ScoringCovariance) -> void:
	for index in range(BAND_IDS.size()):
		var band: ScoringCovariance = sample.gap_band(BAND_LOWER[index], BAND_UPPER[index])
		report.add_metric(CalibrationMetric.raw(
			StringName("covariance.gap_%s" % BAND_IDS[index]),
			"Cov(home points, away points) among games in the %s pregame-gap band"
				% BAND_IDS[index],
			"games", band.points_covariance(), band.size()))
	var low: float = sample.possession_quantile(1.0 / 3.0)
	var high: float = sample.possession_quantile(2.0 / 3.0)
	var thirds: Array[ScoringCovariance] = [
		sample.possession_band(-INF, low),
		sample.possession_band(low, high),
		sample.possession_band(high, INF),
	]
	var third_ids: PackedStringArray = ["slow", "median", "fast"]
	for index in range(thirds.size()):
		report.add_metric(CalibrationMetric.raw(
			StringName("covariance.possessions_%s_third" % third_ids[index]),
			"Cov(home points, away points) among the %s third of games by total "
				% third_ids[index] + "engine possessions",
			"games", thirds[index].points_covariance(), thirds[index].size()))


func _report_path(report: CalibrationReport, sample: ScoringCovariance) -> void:
	var games: int = sample.size()
	report.add_metric(CalibrationMetric.raw(&"path.increment_variance",
		"Pooled variance of one signed possession increment, centred inside each "
		+ "team-game", "possessions", sample.increment_variance(), games))
	for lag in range(1, ScoringCovariance.MAX_LAG + 1):
		report.add_metric(CalibrationMetric.raw(
			StringName("path.increment_autocorrelation_lag_%d" % lag),
			"Lag-%d autocorrelation of the centred signed possession increments" % lag,
			"possession pairs", sample.increment_autocorrelation(lag), games))
	for lag in range(1, ScoringCovariance.MAX_LAG + 1):
		report.add_metric(CalibrationMetric.raw(
			StringName("path.control_autocorrelation_lag_%d" % lag),
			"Lag-%d autocorrelation on the permuted control: the finite-sample "
				% lag + "artefact of centring inside a game, with no behaviour in it",
			"possession pairs", sample.control_increment_autocorrelation(lag), games))
	report.add_metric(CalibrationMetric.raw(&"path.local_variance_multiplier",
		"1 + 2 * sum of the reported lag autocorrelations", "possessions",
		sample.local_variance_multiplier(), games))
	for index in range(ScoringCovariance.WINDOW_LENGTHS.size()):
		var length: int = ScoringCovariance.WINDOW_LENGTHS[index]
		report.add_metric(CalibrationMetric.raw(
			StringName("path.variance_ratio_%d" % length),
			"Var(margin change over %d possessions) / (%d * Var(one increment)), "
				% [length, length]
				+ "uncorrected: falls with the horizon even without structure",
			"windows", sample.variance_ratio(index), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("path.variance_ratio_corrected_%d" % length),
			"The same ratio divided by its value on a permutation of the same game's "
			+ "own increments. One is a random walk at this horizon.",
			"windows", sample.corrected_variance_ratio(index), games))


func _report_states(report: CalibrationReport, sample: ScoringCovariance) -> void:
	var games: int = sample.size()
	for state in range(ScoringCovariance.STATE_COUNT):
		var id_value: String = ScoringCovariance.STATE_IDS[state]
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_possession_share" % id_value),
			"Share of team possessions played at this absolute margin", "possessions",
			sample.state_share_of_possessions(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_points_per_possession" % id_value),
			"Points per possession in this state", "possessions",
			sample.state_points_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_three_point_rate" % id_value),
			"Three-point attempts over field-goal attempts in this state", "attempts",
			sample.state_three_point_rate(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_seconds_per_possession" % id_value),
			"Live seconds consumed per possession in this state", "possessions",
			sample.state_seconds_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_actions_per_possession" % id_value),
			"Selected actions per possession in this state", "possessions",
			sample.state_actions_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_covariance" % id_value),
			"Cov of the two teams' points scored while the game was in this state. "
			+ "Dominated by time in state; the rate covariance below is the term to read.",
			"games", sample.state_covariance(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_rate_covariance" % id_value),
			"Cov of the two teams' points per possession inside this state, over the "
			+ "games where both played at least ten possessions in it",
			"games", sample.state_points_per_possession_covariance(state),
			sample.state_rate_sample(state)))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_leading_points_per_possession" % id_value),
			"Points per possession for the team that was ahead when the possession "
			+ "started", "possessions", sample.leading_points_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_trailing_points_per_possession" % id_value),
			"Points per possession for the team that was behind when the possession "
			+ "started", "possessions", sample.trailing_points_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_leading_drift" % id_value),
			"Leading minus trailing points per possession: the margin's drift inside "
			+ "this state. Zero is driftless; positive means leads run away.",
			"possessions", sample.leading_drift(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_leading_seconds_per_possession" % id_value),
			"Seconds the leading team consumed per possession in this state",
			"possessions", sample.leading_seconds_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_trailing_seconds_per_possession" % id_value),
			"Seconds the trailing team consumed per possession in this state",
			"possessions", sample.trailing_seconds_per_possession(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_leading_three_point_rate" % id_value),
			"Three-point attempt share for the leading team in this state",
			"attempts", sample.leading_three_point_rate(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_trailing_three_point_rate" % id_value),
			"Three-point attempt share for the trailing team in this state",
			"attempts", sample.trailing_three_point_rate(state), games))
		report.add_metric(CalibrationMetric.raw(
			StringName("state.%s_rate_correlation" % id_value),
			"The same as a correlation", "games",
			sample.state_points_per_possession_correlation(state),
			sample.state_rate_sample(state)))


func _report_behaviour(report: CalibrationReport, sample: ScoringCovariance) -> void:
	var games: int = sample.size()
	report.add_metric(CalibrationMetric.raw(&"behaviour.lead_changes_per_game",
		"Changes of leader over completed games", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.lead_changes)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.ties_per_game",
		"Scoring plays that levelled the game", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.ties)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.largest_lead_mean",
		"Largest lead either team held", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.largest_lead)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.runs_per_game",
		"Unanswered scoring streaks of %d or more points" % ScoringCovariance.RUN_POINTS,
		"games", sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.runs)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.run_points_mean",
		"Mean points in a qualifying run", "runs",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return row.mean_run_points()), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.largest_run_mean",
		"Largest unanswered streak, in points", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.largest_run)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.timeouts_per_game",
		"Timeouts recorded in the ledger", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.timeouts)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.intentional_fouls_per_game",
		"Deliberate late-game fouls", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.intentional_fouls)), games))
	report.add_metric(CalibrationMetric.raw(&"behaviour.substitutions_per_game",
		"Check-ins that are not the starting lineup", "games",
		sample.mean_of(func(row: ScoringCovariance.GameRow) -> float:
			return float(row.substitutions)), games))
	var settled: ScoringCovariance = sample.settled_rows()
	report.add_metric(CalibrationMetric.raw(&"behaviour.settled_game_share",
		"Games that reached the §18.2 settled-game window", "games",
		float(settled.size()) / float(maxi(games, 1)), games))
	report.add_metric(CalibrationMetric.raw(&"covariance.before_settled",
		"Cov of the two teams' points scored before the settled-game window opened",
		"games", settled.covariance_before_settled(), settled.size()))
	report.add_metric(CalibrationMetric.raw(&"covariance.after_settled",
		"Cov of the two teams' points scored after the settled-game window opened",
		"games", settled.covariance_after_settled(), settled.size()))


## The measured margin distribution against the one independent possessions
## would have produced from the same games' own possession-outcome
## distributions. Regulation only, because the resampled game has no overtime.
func _report_independence(report: CalibrationReport, sample: ScoringCovariance) -> void:
	var games: int = sample.size()
	var stream: RandomSource = SeededRandomSource.new(
		BOOTSTRAP_SEED).derive(&"independence")
	var synthetic: PackedFloat64Array = sample.independence_margins(stream, BOOTSTRAP_REPEATS)
	var measured := PackedFloat64Array()
	for row: ScoringCovariance.GameRow in sample.rows:
		measured.append(row.regulation_margin())
	report.add_metric(CalibrationMetric.raw(&"independence.samples",
		"Resampled regulation games: %d repeats per measured game" % BOOTSTRAP_REPEATS,
		"resampled games", float(synthetic.size()), synthetic.size()))
	report.add_metric(CalibrationMetric.raw(&"independence.margin_standard_deviation",
		"Standard deviation of the resampled regulation margin", "resampled games",
		sqrt(maxf(ScoringCovariance.variance(synthetic), 0.0)), synthetic.size()))
	report.add_metric(CalibrationMetric.raw(&"independence.measured_regulation_sd",
		"Standard deviation of the measured regulation margin", "games",
		sqrt(maxf(ScoringCovariance.variance(measured), 0.0)), games))
	report.add_metric(CalibrationMetric.raw(&"independence.blowout_rate",
		"Resampled share at or beyond 20 points", "resampled games",
		ScoringCovariance.share_at_or_above(synthetic, 20.0), synthetic.size()))
	report.add_metric(CalibrationMetric.raw(&"independence.close_game_rate",
		"Resampled share within five points", "resampled games",
		ScoringCovariance.share_at_or_below(synthetic, 5.0), synthetic.size()))
	report.add_metric(CalibrationMetric.raw(&"independence.tie_rate",
		"Resampled share exactly level: the overtime rate an independent-possession "
		+ "league would produce", "resampled games",
		ScoringCovariance.share_at_or_below(synthetic, 0.0), synthetic.size()))
	report.add_metric(CalibrationMetric.raw(&"independence.measured_tie_rate",
		"Measured share level at the end of regulation", "games",
		sample.regulation_tie_share(), games))


# --- feasibility -------------------------------------------------------------

## What the measured distribution would have to become, and what covariance
## that implies. The frontier is computed by rescaling the *measured* signed
## margins rather than by assuming normality: the engine's margin distribution
## is what it is, and a normal approximation is exactly the assumption this
## report exists to stop making.
func _report_feasibility(report: CalibrationReport, sample: ScoringCovariance) -> void:
	var games: int = sample.size()
	var blowout: float = _scale_for_share(
		sample, 20.0, true, CalibrationTargets.blowout_share().maximum)
	var close_scale: float = _scale_for_share(
		sample, 5.0, false, CalibrationTargets.close_game_share().minimum)
	var overtime: float = _scale_for_tie(sample, CalibrationTargets.overtime_frequency().minimum)
	var current: float = sample.margin_standard_deviation()
	report.add_metric(CalibrationMetric.raw(&"feasibility.scale_for_blowout_ceiling",
		"Dispersion scale that brings the measured margin distribution to the §14.2 "
		+ "blowout ceiling; 0 means unreachable at any scale", "games", blowout, games))
	report.add_metric(CalibrationMetric.raw(&"feasibility.scale_for_close_floor",
		"Dispersion scale that reaches the §14.2 close-game floor", "games",
		close_scale, games))
	report.add_metric(CalibrationMetric.raw(&"feasibility.scale_for_overtime_floor",
		"Dispersion scale whose implied tie density reaches the §14.2 overtime floor",
		"games", overtime, games))
	report.add_metric(CalibrationMetric.raw(&"feasibility.margin_sd_for_blowout_ceiling",
		"Margin standard deviation at the blowout-ceiling scale", "games",
		blowout * current, games))
	report.add_metric(CalibrationMetric.raw(&"feasibility.margin_sd_for_overtime_floor",
		"Margin standard deviation at the overtime-floor scale", "games",
		overtime * current, games))
	var binding: float = minf(
		blowout if blowout > 0.0 else 1.0, overtime if overtime > 0.0 else 1.0)
	var required_variance: float = binding * binding * sample.margin_variance()
	var required_covariance: float = 0.5 * (
		sample.home_points_variance() + sample.away_points_variance() - required_variance)
	report.add_metric(CalibrationMetric.raw(&"feasibility.required_covariance",
		"Cov(A, B) that would produce the binding required margin variance while both "
		+ "teams keep their measured marginal scoring variance", "games",
		required_covariance, games))
	var spread: float = sqrt(maxf(
		sample.home_points_variance() * sample.away_points_variance(), 0.0))
	report.add_metric(CalibrationMetric.raw(&"feasibility.required_correlation",
		"The same requirement expressed as Corr(A, B)", "games",
		required_covariance / spread if spread > 0.0 else 0.0, games))
	report.add_metric(CalibrationMetric.raw(&"feasibility.tie_density_at_zero",
		"Regulation-margin density at zero, read over a %.1f-point half-width window. "
			% TIE_DENSITY_HALF_WIDTH
		+ "The overtime rate any margin distribution of this shape can produce.",
		"games", _scaled_tie_share(sample, 1.0), games))
	report.add_metric(CalibrationMetric.raw(&"feasibility.required_variance_ratio",
		"Required margin variance over the measured margin variance", "games",
		binding * binding, games))


## The smallest scale at which the rescaled absolute margin satisfies a bound.
## Returns zero when no scale in the grid does.
func _scale_for_share(
	sample: ScoringCovariance,
	threshold: float,
	at_or_above: bool,
	target: float,
) -> float:
	for scale in FRONTIER_SCALES:
		var share: float = _scaled_share(sample, threshold, at_or_above, scale)
		if at_or_above and share <= target:
			return scale
		if not at_or_above and share >= target:
			return scale
	return 0.0


func _scaled_share(
	sample: ScoringCovariance,
	threshold: float,
	at_or_above: bool,
	scale: float,
) -> float:
	var matching: int = 0
	for row: ScoringCovariance.GameRow in sample.rows:
		var value: float = row.absolute_margin() * scale
		if at_or_above and value >= threshold:
			matching += 1
		elif not at_or_above and value <= threshold:
			matching += 1
	return float(matching) / float(maxi(sample.size(), 1))


## The scale at which the implied probability of an exactly level regulation
## score reaches a target.
##
## A rescaled sample has no integer support, so counting exact zeros in it
## measures the scale factor rather than the distribution. The tie probability
## is instead read as the *density* of the regulation margin at zero — the mass
## within `TIE_DENSITY_HALF_WIDTH` points of level, divided by that window's
## width — which is the probability of landing on the single integer zero. At
## scale one it reproduces the measured tie rate, which is the check that the
## estimator is the right one.
func _scale_for_tie(sample: ScoringCovariance, target: float) -> float:
	for scale in FRONTIER_SCALES:
		if _scaled_tie_share(sample, scale) >= target:
			return scale
	return 0.0


func _scaled_tie_share(sample: ScoringCovariance, scale: float) -> float:
	if sample.size() <= 0:
		return 0.0
	var window: float = TIE_DENSITY_HALF_WIDTH / scale
	var matching: int = 0
	for row: ScoringCovariance.GameRow in sample.rows:
		if absf(row.regulation_margin()) <= window:
			matching += 1
	var mass: float = float(matching) / float(sample.size())
	return mass / (2.0 * TIE_DENSITY_HALF_WIDTH)


# --- sections ----------------------------------------------------------------

func _gap_band_rows(sample: ScoringCovariance) -> Array:
	var rows: Array = []
	for index in range(BAND_IDS.size()):
		var band: ScoringCovariance = sample.gap_band(BAND_LOWER[index], BAND_UPPER[index])
		rows.append({
			"band": BAND_IDS[index],
			"games": band.size(),
			"points_covariance": band.points_covariance(),
			"points_correlation": band.points_correlation(),
			"residual_covariance": band.residual_points_covariance(),
			"margin_variance": band.margin_variance(),
			"reconstructed_margin_variance": band.reconstructed_margin_variance(),
			"blowout_rate": band.blowout_share(),
			"close_game_rate": band.close_share(),
			"overtime_rate": band.overtime_share(),
			"margin_standard_deviation": band.margin_standard_deviation(),
		})
	return rows


func _possession_band_rows(sample: ScoringCovariance) -> Array:
	var low: float = sample.possession_quantile(1.0 / 3.0)
	var high: float = sample.possession_quantile(2.0 / 3.0)
	var lower: PackedFloat64Array = PackedFloat64Array([-INF, low, high])
	var upper: PackedFloat64Array = PackedFloat64Array([low, high, INF])
	var ids: PackedStringArray = ["slow", "median", "fast"]
	var rows: Array = []
	for index in range(ids.size()):
		var band: ScoringCovariance = sample.possession_band(lower[index], upper[index])
		rows.append({
			"band": ids[index],
			"games": band.size(),
			"points_covariance": band.points_covariance(),
			"points_correlation": band.points_correlation(),
			"margin_variance": band.margin_variance(),
			"mean_total_possessions": band.mean_of(
				func(row: ScoringCovariance.GameRow) -> float: return row.total_possessions()),
		})
	return rows


func _period_rows(sample: ScoringCovariance) -> Array:
	var rows: Array = []
	for index in range(sample.maximum_period_count()):
		rows.append({
			"period": index + 1,
			"games": sample.period_sample(index),
			"covariance": sample.period_covariance(index),
			"correlation": sample.period_correlation(index),
		})
	return rows


func _state_rows(sample: ScoringCovariance) -> Array:
	var rows: Array = []
	for state in range(ScoringCovariance.STATE_COUNT):
		rows.append({
			"state": ScoringCovariance.STATE_IDS[state],
			"possession_share": sample.state_share_of_possessions(state),
			"points_per_possession": sample.state_points_per_possession(state),
			"three_point_rate": sample.state_three_point_rate(state),
			"seconds_per_possession": sample.state_seconds_per_possession(state),
			"actions_per_possession": sample.state_actions_per_possession(state),
			"covariance": sample.state_covariance(state),
			"correlation": sample.state_correlation(state),
			"leading_points_per_possession": sample.leading_points_per_possession(state),
			"trailing_points_per_possession": sample.trailing_points_per_possession(state),
			"leading_drift": sample.leading_drift(state),
			"leading_seconds_per_possession": sample.leading_seconds_per_possession(state),
			"trailing_seconds_per_possession": sample.trailing_seconds_per_possession(state),
			"substitutions": sample.state_total(
				func(row: ScoringCovariance.GameRow) -> float:
					return row.state_substitutions[state]),
			"intentional_fouls": sample.state_total(
				func(row: ScoringCovariance.GameRow) -> float:
					return row.state_intentional_fouls[state]),
		})
	return rows


func _variance_ratio_rows(sample: ScoringCovariance) -> Array:
	var rows: Array = []
	for index in range(ScoringCovariance.WINDOW_LENGTHS.size()):
		rows.append({
			"window_possessions": ScoringCovariance.WINDOW_LENGTHS[index],
			"variance_ratio": sample.variance_ratio(index),
		})
	return rows


func _frontier_rows(sample: ScoringCovariance) -> Array:
	var rows: Array = []
	var margin_variance: float = sample.margin_variance()
	var marginal: float = sample.home_points_variance() + sample.away_points_variance()
	for scale in FRONTIER_SCALES:
		var scaled_variance: float = scale * scale * margin_variance
		rows.append({
			"scale": scale,
			"margin_standard_deviation": scale * sample.margin_standard_deviation(),
			"blowout_rate": _scaled_share(sample, 20.0, true, scale),
			"close_game_rate": _scaled_share(sample, 5.0, false, scale),
			"implied_tie_rate": _scaled_tie_share(sample, scale),
			"required_covariance": 0.5 * (marginal - scaled_variance),
			"required_correlation": (
				0.5 * (marginal - scaled_variance)
				/ sqrt(maxf(sample.home_points_variance() * sample.away_points_variance(), 1e-9))),
		})
	return rows


## What a legitimate late-game mechanism would have to be worth.
##
## Each row damps the leading team by a stated number of points per possession
## once the margin passes the threshold, and reports the §14.2 shares that
## result. The penalty column is the answer to "how much less effective does a
## team protecting a lead have to become", which is a question about basketball
## rather than about arithmetic, and is therefore one an owner can rule on.
func _damping_rows(sample: ScoringCovariance) -> Array:
	var rows: Array = []
	var efficiency: float = _points_per_possession(sample)
	for threshold: float in DAMPING_THRESHOLDS:
		for penalty: float in DAMPING_PENALTIES:
			var stream: RandomSource = SeededRandomSource.new(BOOTSTRAP_SEED).derive(
				StringName("damped:%d:%d" % [int(threshold), int(penalty * 100.0)]))
			var margins: PackedFloat64Array = sample.damped_margins(
				stream, DAMPING_REPEATS, penalty, threshold)
			rows.append({
				"threshold_points": threshold,
				"penalty_points_per_possession": penalty,
				"penalty_share_of_efficiency": (
					penalty / efficiency if efficiency > 0.0 else 0.0),
				"margin_standard_deviation": sqrt(
					maxf(ScoringCovariance.variance(margins), 0.0)),
				"blowout_rate": ScoringCovariance.share_at_or_above(margins, 20.0),
				"close_game_rate": ScoringCovariance.share_at_or_below(margins, 5.0),
				"tie_rate": ScoringCovariance.share_at_or_below(margins, 0.0),
				"samples": margins.size(),
			})
	return rows


# --- helpers -----------------------------------------------------------------

func _share(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	estimate: float,
	successes: int,
	trials: int,
	band: CalibrationBand,
	judged: bool,
) -> void:
	var interval: PackedFloat64Array = CalibrationStatistics.wilson_interval(successes, trials)
	var half_width: float = 0.5 * (interval[1] - interval[0])
	if judged:
		report.add_metric(CalibrationMetric.banded(
			metric_id, definition, "games", estimate, band, trials, half_width))
		return
	var metric: CalibrationMetric = CalibrationMetric.raw(
		metric_id, definition, "games", estimate, trials)
	metric.interval_half_width = half_width
	report.add_metric(metric)


func _points_per_possession(sample: ScoringCovariance) -> float:
	var points: float = 0.0
	var possessions: float = 0.0
	for row: ScoringCovariance.GameRow in sample.rows:
		points += float(row.home_points + row.away_points)
		possessions += row.total_possessions()
	return points / possessions if possessions > 0.0 else 0.0


func _possessions_per_team_game(sample: ScoringCovariance) -> float:
	var possessions: float = 0.0
	for row: ScoringCovariance.GameRow in sample.rows:
		possessions += row.total_possessions()
	return possessions / float(maxi(sample.size() * 2, 1))
