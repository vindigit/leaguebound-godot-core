extends SceneTree

## The PR-gate calibration smoke run.
##
## The Stage 4 brief is explicit that a small band check "may be retained as a
## quick structural smoke test" but must not be used as release certification.
## This tool is that smoke test, and it is built so it cannot be mistaken for a
## certification:
##
## - the control limits are deliberately broad — roughly the §14.1 bands widened
##   to catch a *structural* collapse, not a tuning drift;
## - every metric names the sample size it used against the §27.1 requirement;
## - the printed verdict says "structural smoke" rather than "pass".
##
## What it actually catches is an event family that stopped firing: no assists,
## no free throws, no offensive rebounds, a possession count that halved. Those
## are regressions a reviewer must see in PR time.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_calibration_smoke.gd -- \
##       [--games=N] [--label=NAME]

const DEFAULT_GAMES: int = 6

## How far outside its §14.1 band a metric may sit before the smoke run calls it
## a structural collapse. A band is widened by this share of its own width.
const CONTROL_SLACK: float = 1.25


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var label: String = CalibrationCli.string_option(options, &"label", "smoke")
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO

	var context := ReportContext.create(
		&"calibration_smoke",
		"Deterministic calibration smoke (structural, not a certification)",
		CompetitionCatalog.rules_for(competition),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_count = games
	context.sample_unit = "complete games"
	context.seed_description = "1..%d" % games
	context.notes.append(
		"STRUCTURAL SMOKE ONLY. Control limits are the §14.1 bands widened by %.0f%% of "
			% (CONTROL_SLACK * 100.0)
		+ "their own width. §27.1 requires %d games per competition to certify; this run "
			% CalibrationTargets.REQUIRED_COMPETITION_GAMES
		+ "used %d." % games)

	var totals := MatchMetricAccumulator.new()
	for index in range(games):
		var input: MatchInput = CompetitionCatalog.match_for(competition, index, 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(index + 1))
		totals.accumulate(input, output)

	var report := CalibrationReport.new(context)
	_check(report, &"possessions_per_game",
		"Engine possessions per team per game.", "team-games",
		totals.possessions_per_game(),
		CalibrationTargets.possessions_per_game(competition), totals.team_games)
	_check(report, &"points_per_possession",
		"Points divided by engine possessions.", "engine possessions",
		totals.points_per_possession(),
		CalibrationTargets.points_per_possession(competition), totals.engine_possessions)
	_check(report, &"field_goal_percentage",
		"Field goals made over attempted.", "field-goal attempts",
		totals.field_goal_percentage(),
		CalibrationTargets.field_goal_percentage(competition), totals.field_goals_attempted)
	_check(report, &"three_point_attempt_rate",
		"Three-point attempts over all field-goal attempts.", "field-goal attempts",
		totals.three_point_attempt_rate(),
		CalibrationTargets.three_point_attempt_rate(competition), totals.field_goals_attempted)
	_check(report, &"free_throw_attempt_rate",
		"Free-throw attempts over field-goal attempts.", "field-goal attempts",
		totals.free_throw_attempt_rate(),
		CalibrationTargets.free_throw_attempt_rate(competition), totals.field_goals_attempted)
	_check(report, &"turnovers_per_100_possessions",
		"Turnovers times 100 over engine possessions.", "engine possessions",
		totals.turnovers_per_100_possessions(),
		CalibrationTargets.turnovers_per_100(competition), totals.engine_possessions)
	_check(report, &"offensive_rebound_percentage",
		"ORB / (ORB + opponent DREB).", "offensive-rebound chances",
		totals.offensive_rebound_percentage(),
		CalibrationTargets.offensive_rebound_percentage(competition),
		totals.offensive_rebound_chances)
	_check(report, &"assist_percentage",
		"Assists over the team's own made field goals.", "made field goals",
		totals.assist_percentage(),
		CalibrationTargets.assist_percentage(competition), totals.field_goals_made)

	# The event families that must simply exist. A zero here is a branch that
	# stopped firing, which no statistical band would catch as clearly.
	_require_nonzero(report, &"assists", totals.assists)
	_require_nonzero(report, &"free_throws_attempted", totals.free_throws_attempted)
	_require_nonzero(report, &"offensive_rebounds", totals.offensive_rebounds)
	_require_nonzero(report, &"steals", totals.steals)
	_require_nonzero(report, &"blocks", totals.blocks)
	_require_nonzero(report, &"three_pointers_attempted", totals.three_pointers_attempted)
	_require_nonzero(report, &"personal_fouls", totals.personal_fouls)

	report.finish()
	var code: int = ReportWriter.publish(report, "calibration_smoke_%s" % label)
	print("  verdict: structural smoke only; not a §27.1 certification.")
	quit(code)


## Judges a metric against its §14.1 band widened by `CONTROL_SLACK`.
func _check(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	denominator: String,
	estimate: float,
	band: CalibrationBand,
	sample_count: int,
) -> void:
	var slack: float = (band.maximum - band.minimum) * CONTROL_SLACK
	var control := CalibrationBand.new(
		band.minimum - slack, band.maximum + slack,
		"%s widened to a structural control limit" % band.source)
	report.add_metric(CalibrationMetric.banded(
		metric_id, definition, denominator, estimate, control, sample_count))


func _require_nonzero(report: CalibrationReport, metric_id: StringName, total: int) -> void:
	report.add_metric(CalibrationMetric.boolean(
		StringName("event_family.%s.present" % metric_id),
		"The event family fired at least once across the smoke sample.",
		total > 0, "structural: a basketball branch that stopped firing", total))
