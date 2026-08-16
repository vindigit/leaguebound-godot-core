extends SceneTree

## Team and player basketball calibration, per competition profile
## (`BALANCE_SPEC.md` §14, §31 report 4 and report 5).
##
## Every §14.1 metric, the §14.2 game-shape metrics, and the §14.2 rotation
## minutes are measured and judged against `CalibrationTargets`. Engine
## possessions and the classic possession estimate are reported side by side and
## never substituted for one another, and offensive rebound percentage uses
## `ORB / (ORB + opponent DREB)`.
##
## Sample size is a command-line argument, and the report always states the size
## reached against the §27.1 certification requirement of 100,000 complete games
## per competition. A run below that size is reported as measured-but-not-
## certified rather than being allowed to look like a certification.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_competition_calibration.gd -- \
##       [--games=N] [--competition=high_school|college|development|overseas|top_domestic_pro|all] \
##       [--shard=I --shards=N] [--label=NAME]

const DEFAULT_GAMES: int = 120

## One competition's summary line. A typed row rather than a bare Dictionary so
## the printed table and the archived JSON cannot drift apart, and so the
## project's typed-access warnings stay satisfied.
class CompetitionRow extends RefCounted:
	var competition: String
	var games: int
	var engine_possessions_per_game: float
	var possession_estimate_per_game: float
	var points_per_game: float
	var points_per_possession: float
	var field_goal_percentage: float
	var three_point_percentage: float
	var three_point_attempt_rate: float
	var free_throw_percentage: float
	var free_throw_attempt_rate: float
	var turnovers_per_100_possessions: float
	var offensive_rebound_percentage: float
	var assist_percentage: float
	var steals_per_game: float
	var blocks_per_game: float
	var fouls_per_game: float
	var home_win_rate: float
	var overtime_rate: float
	var close_game_rate: float
	var blowout_rate: float

	func to_dictionary() -> Dictionary:
		return {
			"competition": competition,
			"games": games,
			"engine_possessions_per_game": engine_possessions_per_game,
			"possession_estimate_per_game": possession_estimate_per_game,
			"points_per_game": points_per_game,
			"points_per_possession": points_per_possession,
			"field_goal_percentage": field_goal_percentage,
			"three_point_percentage": three_point_percentage,
			"three_point_attempt_rate": three_point_attempt_rate,
			"free_throw_percentage": free_throw_percentage,
			"free_throw_attempt_rate": free_throw_attempt_rate,
			"turnovers_per_100_possessions": turnovers_per_100_possessions,
			"offensive_rebound_percentage": offensive_rebound_percentage,
			"assist_percentage": assist_percentage,
			"steals_per_game": steals_per_game,
			"blocks_per_game": blocks_per_game,
			"fouls_per_game": fouls_per_game,
			"home_win_rate": home_win_rate,
			"overtime_rate": overtime_rate,
			"close_game_rate": close_game_rate,
			"blowout_rate": blowout_rate,
		}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = maxi(1, CalibrationCli.int_option(options, &"shards", 1))
	var label: String = CalibrationCli.string_option(options, &"label", "competition")

	var competitions: Array[int] = _selected(selection)
	var context := ReportContext.create(
		&"competition_calibration",
		"Competition basketball calibration",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per competition"
	context.sample_count = games * competitions.size()
	context.seed_description = "shard %d of %d, seeds %d..%d per competition" % [
		shard, shards, shard * games + 1, shard * games + games]
	context.notes.append(
		"§27.1 certification sample is %d complete games per competition; this run used %d."
			% [CalibrationTargets.REQUIRED_COMPETITION_GAMES, games])
	context.notes.append(
		"Rule profiles are per competition; the provenance block names the first only. "
		+ "Each metric row carries its own competition id.")

	var report := CalibrationReport.new(context)
	report.add_metric(CalibrationMetric.boolean(
		&"sample.meets_certification_size",
		"Whether this run reached the §27.1 sample size for a certifying competition report.",
		games >= CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source(),
		games))

	var rows: Array[CompetitionRow] = []
	var payloads: Array = []
	for competition in competitions:
		var accumulator: MatchMetricAccumulator = _run_competition(competition, games, shard)
		_judge(report, competition, accumulator, games)
		var row: CompetitionRow = _row(competition, accumulator)
		rows.append(row)
		payloads.append(row.to_dictionary())
		report.add_section(
			StringName("rotation_roles.%s" % CalibrationTargets.competition_id(competition)),
			accumulator.role_rows())
		report.add_section(
			StringName("tactical_roles.%s" % CalibrationTargets.competition_id(competition)),
			accumulator.tactical_role_rows())
	report.add_section(&"competition_table", payloads)

	report.finish()
	_print_table(rows)
	quit(ReportWriter.publish(report, "competition_calibration_%s" % label))


func _selected(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


func _run_competition(competition: int, games: int, shard: int) -> MatchMetricAccumulator:
	var accumulator := MatchMetricAccumulator.new()
	var base: int = shard * games
	for index in range(games):
		var variation: int = base + index
		# Home and away are drawn from the same population, so the measured home
		# win rate is the environment effect and nothing else. Alternating the
		# level offset keeps some games mismatched, which is what produces a
		# credible blowout share.
		var tilt: float = float((variation % 5) - 2) * 1.5
		var input: MatchInput = CompetitionCatalog.match_for(
			competition, variation, 0.5, 0.0, tilt)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		accumulator.accumulate(input, output)
	return accumulator


func _judge(
	report: CalibrationReport,
	competition: int,
	totals: MatchMetricAccumulator,
	games: int,
) -> void:
	var id: StringName = CalibrationTargets.competition_id(competition)

	report.add_metric(CalibrationMetric.banded(
		StringName("%s.possessions_per_game" % id),
		"Engine possessions from terminal possession records, per team per game.",
		"team-games", totals.possessions_per_game(),
		CalibrationTargets.possessions_per_game(competition), totals.team_games,
		CalibrationStatistics.mean_interval_half_width(totals.team_game_possessions)))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.possession_estimate_per_game" % id),
		"Classic estimate FGA + w*FTA - ORB + TOV, per team per game. Reported "
		+ "beside engine possessions and never substituted for them.",
		"team-games", totals.possession_estimate_per_game(), totals.team_games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.points_per_game" % id),
		"Points per team per game.",
		"team-games", totals.points_per_game(), totals.team_games)
		.with_interval(CalibrationStatistics.mean_interval_half_width(totals.team_game_points)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.points_per_possession" % id),
		"Total points divided by total engine possessions.",
		"engine possessions", totals.points_per_possession(),
		CalibrationTargets.points_per_possession(competition), totals.engine_possessions))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.field_goal_percentage" % id),
		"Field goals made divided by field goals attempted.",
		"field-goal attempts", totals.field_goal_percentage(),
		CalibrationTargets.field_goal_percentage(competition), totals.field_goals_attempted,
		totals.proportion_half_width(totals.field_goals_made, totals.field_goals_attempted)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.three_point_percentage" % id),
		"Three-pointers made divided by three-pointers attempted.",
		"three-point attempts", totals.three_point_percentage(),
		CalibrationTargets.three_point_percentage(competition), totals.three_pointers_attempted,
		totals.proportion_half_width(
			totals.three_pointers_made, totals.three_pointers_attempted)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.three_point_attempt_rate" % id),
		"Three-point attempts divided by all field-goal attempts.",
		"field-goal attempts", totals.three_point_attempt_rate(),
		CalibrationTargets.three_point_attempt_rate(competition), totals.field_goals_attempted,
		totals.proportion_half_width(
			totals.three_pointers_attempted, totals.field_goals_attempted)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.free_throw_percentage" % id),
		"Free throws made divided by free throws attempted.",
		"free-throw attempts", totals.free_throw_percentage(),
		CalibrationTargets.free_throw_percentage(competition), totals.free_throws_attempted,
		totals.proportion_half_width(totals.free_throws_made, totals.free_throws_attempted)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.free_throw_attempt_rate" % id),
		"Free-throw attempts divided by field-goal attempts.",
		"field-goal attempts", totals.free_throw_attempt_rate(),
		CalibrationTargets.free_throw_attempt_rate(competition), totals.field_goals_attempted))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.turnovers_per_100_possessions" % id),
		"Turnovers times 100 divided by engine possessions.",
		"engine possessions", totals.turnovers_per_100_possessions(),
		CalibrationTargets.turnovers_per_100(competition), totals.engine_possessions))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.offensive_rebound_percentage" % id),
		"ORB / (ORB + opponent DREB). Possession count is never the denominator.",
		"offensive-rebound chances", totals.offensive_rebound_percentage(),
		CalibrationTargets.offensive_rebound_percentage(competition),
		totals.offensive_rebound_chances,
		totals.proportion_half_width(
			totals.offensive_rebounds, totals.offensive_rebound_chances)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.assist_percentage" % id),
		"Assists divided by the team's own made field goals.",
		"made field goals", totals.assist_percentage(),
		CalibrationTargets.assist_percentage(competition), totals.field_goals_made,
		totals.proportion_half_width(totals.assists, totals.field_goals_made)))

	# --- §14.2 game shape ---------------------------------------------------
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.home_win_rate" % id),
		"Home wins divided by games with a decided result.",
		"decided games", totals.home_win_rate(),
		CalibrationTargets.home_win_rate(), totals.decided_games,
		totals.proportion_half_width(totals.home_wins, totals.decided_games)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.overtime_rate" % id),
		"Games reaching at least one overtime period, divided by games played.",
		"complete games", totals.overtime_rate(),
		CalibrationTargets.overtime_frequency(), totals.games,
		totals.proportion_half_width(totals.overtime_games, totals.games)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.close_game_rate" % id),
		"Games decided by five points or fewer, divided by games played.",
		"complete games", totals.close_game_rate(),
		CalibrationTargets.close_game_share(), totals.games,
		totals.proportion_half_width(totals.close_games, totals.games)))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.blowout_rate" % id),
		"Games decided by twenty points or more, divided by games played.",
		"complete games", totals.blowout_rate(),
		CalibrationTargets.blowout_share(), totals.games,
		totals.proportion_half_width(totals.blowout_games, totals.games)))

	# --- §14.2 rotation minutes: certified for top domestic only ------------
	var starter_mean: float = totals.mean_minutes_for_rotation_role(RotationRole.Value.STARTER)
	if competition == CalibrationTargets.Competition.TOP_DOMESTIC_PRO:
		report.add_metric(CalibrationMetric.banded(
			StringName("%s.starter_mean_minutes" % id),
			"Mean minutes played by players whose rotation role is Starter.",
			"starter appearances", starter_mean,
			CalibrationTargets.starter_minutes(),
			totals.appearances_by_rotation_role[RotationRole.Value.STARTER],
			CalibrationStatistics.mean_interval_half_width(totals.starter_minutes)))
		report.add_metric(CalibrationMetric.banded(
			StringName("%s.star_mean_minutes" % id),
			"Mean minutes played by players whose rotation role is Star.",
			"star appearances",
			totals.mean_minutes_for_rotation_role(RotationRole.Value.STAR),
			CalibrationTargets.rotation_minutes_envelope(),
			totals.appearances_by_rotation_role[RotationRole.Value.STAR]))
		report.add_metric(CalibrationMetric.banded(
			StringName("%s.rotation_mean_minutes" % id),
			"Mean minutes played by players whose rotation role is Rotation.",
			"rotation appearances",
			totals.mean_minutes_for_rotation_role(RotationRole.Value.ROTATION),
			CalibrationTargets.rotation_minutes_envelope(),
			totals.appearances_by_rotation_role[RotationRole.Value.ROTATION]))
	else:
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.starter_mean_minutes" % id),
			"Mean minutes played by Starters. §14.2 states its minute bands for "
			+ "top domestic professional basketball only, so this is reported "
			+ "without a verdict at other competitions.",
			"starter appearances", starter_mean,
			totals.appearances_by_rotation_role[RotationRole.Value.STARTER]))

	# --- stat-leader plausibility -------------------------------------------
	var sorted_leaders: PackedFloat64Array = totals.top_scorer_points.duplicate()
	sorted_leaders.sort()
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.team_leading_scorer_mean" % id),
		"Mean points scored by each team-game's leading scorer.",
		"team-games", CalibrationStatistics.mean(totals.top_scorer_points), totals.team_games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.team_leading_scorer_p99" % id),
		"99th percentile of the leading scorer's points, for tail plausibility.",
		"team-games", CalibrationStatistics.percentile(sorted_leaders, 0.99), totals.team_games))


func _row(competition: int, totals: MatchMetricAccumulator) -> CompetitionRow:
	var row := CompetitionRow.new()
	row.competition = String(CalibrationTargets.competition_id(competition))
	row.games = totals.games
	row.engine_possessions_per_game = totals.possessions_per_game()
	row.possession_estimate_per_game = totals.possession_estimate_per_game()
	row.points_per_game = totals.points_per_game()
	row.points_per_possession = totals.points_per_possession()
	row.field_goal_percentage = totals.field_goal_percentage()
	row.three_point_percentage = totals.three_point_percentage()
	row.three_point_attempt_rate = totals.three_point_attempt_rate()
	row.free_throw_percentage = totals.free_throw_percentage()
	row.free_throw_attempt_rate = totals.free_throw_attempt_rate()
	row.turnovers_per_100_possessions = totals.turnovers_per_100_possessions()
	row.offensive_rebound_percentage = totals.offensive_rebound_percentage()
	row.assist_percentage = totals.assist_percentage()
	row.steals_per_game = totals.steals_per_game()
	row.blocks_per_game = totals.blocks_per_game()
	row.fouls_per_game = totals.fouls_per_game()
	row.home_win_rate = totals.home_win_rate()
	row.overtime_rate = totals.overtime_rate()
	row.close_game_rate = totals.close_game_rate()
	row.blowout_rate = totals.blowout_rate()
	return row


func _print_table(rows: Array[CompetitionRow]) -> void:
	print("")
	print("  %-18s %6s %6s %6s %6s %6s %6s %6s %6s %6s %6s %6s %6s %5s %5s" % [
		"competition", "poss", "pts", "PPP", "FG%", "3P%", "3PAr", "FT%", "FTAr",
		"TOV", "ORB%", "AST%", "PF", "STL", "BLK"])
	for row in rows:
		print(
			"  %-18s %6.1f %6.1f %6.3f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %5.1f %5.1f"
			% [
				row.competition, row.engine_possessions_per_game, row.points_per_game,
				row.points_per_possession,
				100.0 * row.field_goal_percentage,
				100.0 * row.three_point_percentage,
				100.0 * row.three_point_attempt_rate,
				100.0 * row.free_throw_percentage,
				100.0 * row.free_throw_attempt_rate,
				row.turnovers_per_100_possessions,
				100.0 * row.offensive_rebound_percentage,
				100.0 * row.assist_percentage,
				row.fouls_per_game, row.steals_per_game, row.blocks_per_game,
			])
	print("")
	print("  home win rate / overtime / close / blowout, by competition:")
	for row in rows:
		print("  %-18s %6.1f%% %6.1f%% %6.1f%% %6.1f%%" % [
			row.competition, 100.0 * row.home_win_rate, 100.0 * row.overtime_rate,
			100.0 * row.close_game_rate, 100.0 * row.blowout_rate])
