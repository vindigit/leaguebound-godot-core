extends SceneTree

## What each contest tunable is worth, measured on matched fixtures.
##
## §5.20's decomposition located the points-per-possession excess in shot
## conversion rather than in shot mix, turnovers, offensive rebounding or free
## throws, and located *that* in the contest-band distribution: two thirds of
## every level's attempts are `open` or `light`, `heavy` is about two per cent
## and `smothered` never happens at all. Accuracy falls steeply and correctly
## across the bands — 58.9 / 42.7 / 32.3 / 23.4 per cent at overseas — so the
## bands work and the *distribution feeding them* does not.
##
## This sweep measures what moving each contest tunable actually does, rather
## than inferring it from the band arithmetic. Every cell plays the **identical
## fixtures at the identical seeds**, so a cell-to-cell difference is the
## tunable and nothing else. A 200-game cell measures points per possession to
## about ±0.009 on its own, which cannot resolve a 0.005 effect; the paired
## difference against the baseline cell can, because the roster, the matchup and
## the draw sequence all cancel.
##
## Nothing here is a correction. It produces the evidence a correction has to be
## chosen from, on a range that serves no other purpose.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_contest_sweep.gd -- \
##       [--games=N] [--competition=top_domestic_pro] [--tunable=capability_span|base_pressure|advantage_relief] \
##       [--values=0.35,0.45,0.55] [--label=NAME]

const DEFAULT_GAMES: int = 200

## The tuning range. Disjoint from every diagnosis, validation, audit and
## mutation range any section owns. Values are fitted here and nowhere else.
const TUNING_BASE: int = 850000

const PROGRESS_EVERY: int = 50

const TUNABLE_CAPABILITY_SPAN: String = "capability_span"
const TUNABLE_BASE_PRESSURE: String = "base_pressure"
const TUNABLE_ADVANTAGE_RELIEF: String = "advantage_relief"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(
		options, &"competition", "top_domestic_pro")
	var tunable: String = CalibrationCli.string_option(
		options, &"tunable", TUNABLE_CAPABILITY_SPAN)
	var values_text: String = CalibrationCli.string_option(options, &"values", "")
	var label: String = CalibrationCli.string_option(options, &"label", "contest_sweep")

	var competition: int = _competition(selection)
	var values: PackedFloat64Array = _values(values_text, tunable)

	var context := ReportContext.create(
		&"contest_sweep",
		"Contest tunable sweep",
		CompetitionCatalog.rules_for(competition),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per cell"
	context.sample_count = games
	context.competition_id = CalibrationTargets.competition_id(competition)
	context.set_shard(0, 1, TUNING_BASE + 1, TUNING_BASE + games)
	context.notes.append(
		"TUNING RANGE. Values are fitted here. No conclusion from this range may "
		+ "be quoted as validation.")
	context.notes.append(
		"Every cell plays the identical fixtures at the identical seeds, so a "
		+ "cell-to-cell difference is the tunable with roster, matchup and draw "
		+ "sequence cancelled.")
	context.notes.append(
		"Seed range: tuning, variations %d-%d, RNG seeds %d-%d."
		% [TUNING_BASE, TUNING_BASE + games - 1, TUNING_BASE + 1, TUNING_BASE + games])
	context.notes.append("Tunable swept: contest.%s." % tunable)

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	var baseline_ppp: float = 0.0
	for cell in range(values.size()):
		var value: float = values[cell]
		print("sweep: contest.%s = %.4f, %d games..." % [tunable, value, games])
		var decomposition: PppDecomposition = _simulate(competition, games, tunable, value)
		var totals: PppDecomposition.Totals = decomposition.totals
		if cell == 0:
			baseline_ppp = totals.points_per_possession()
		var payload: Dictionary = totals.to_dictionary()
		payload["tunable"] = "contest.%s" % tunable
		payload["value"] = value
		payload["ppp_delta_vs_first_cell"] = totals.points_per_possession() - baseline_ppp
		payload["reconciled"] = decomposition.is_reconciled()
		rows.append(payload)
		_report_cell(report, tunable, value, decomposition, baseline_ppp)
		print("  %s=%.4f: PPP %.4f (%+.4f vs first cell), mean contest penalty %.4f, %d violation(s)"
			% [tunable, value, totals.points_per_possession(),
				totals.points_per_possession() - baseline_ppp,
				_mean_contest_penalty(totals), decomposition.violations.size()])
		for violation in decomposition.violations:
			printerr("  VIOLATION %s" % violation)
	report.add_section(&"sweep", rows)
	report.finish()
	quit(ReportWriter.publish(report, "contest_sweep_%s" % label))


func _competition(selection: String) -> int:
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return competition
	printerr("unknown competition '%s'; using top_domestic_pro" % selection)
	return CalibrationTargets.Competition.TOP_DOMESTIC_PRO


## The swept values. The first is always the shipped baseline, so every cell has
## something to be a difference against.
func _values(values_text: String, tunable: String) -> PackedFloat64Array:
	var shipped := SimulationBalanceProfile.new()
	var baseline: float = _current(shipped, tunable)
	var values := PackedFloat64Array([baseline])
	if values_text.is_empty():
		return values
	for token in values_text.split(",", false):
		var parsed: float = token.strip_edges().to_float()
		if not is_equal_approx(parsed, baseline):
			values.append(parsed)
	return values


static func _current(profile: SimulationBalanceProfile, tunable: String) -> float:
	match tunable:
		TUNABLE_BASE_PRESSURE:
			return profile.contest_base_pressure
		TUNABLE_ADVANTAGE_RELIEF:
			return profile.contest_advantage_relief
		_:
			return profile.contest_capability_span


static func _apply(profile: SimulationBalanceProfile, tunable: String, value: float) -> void:
	match tunable:
		TUNABLE_BASE_PRESSURE:
			profile.contest_base_pressure = value
		TUNABLE_ADVANTAGE_RELIEF:
			profile.contest_advantage_relief = value
		_:
			profile.contest_capability_span = value


func _simulate(
	competition: int,
	games: int,
	tunable: String,
	value: float,
) -> PppDecomposition:
	var decomposition := PppDecomposition.new()
	for index in range(games):
		var variation: int = TUNING_BASE + index
		# Built exactly as `CompetitionCatalog.match_for` builds it, then the one
		# tunable is moved. Same rosters, same rules, same opening inbound.
		var balance := SimulationBalanceProfile.new()
		_apply(balance, tunable, value)
		var home: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"home", variation * 2, balance, 0.0)
		var away: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"away", variation * 2 + 1, balance, 0.0)
		var input := MatchInput.new(
			StringName("sweep_%s_%d" % [
				CalibrationTargets.competition_id(competition), variation]),
			StringName("sweep_game_%d" % variation),
			CompetitionCatalog.rules_for(competition),
			balance, home, away,
			CompetitionCatalog.opening_team_id(
				CompetitionCatalog.OPENING_COUNTERBALANCED, variation, home, away),
			CompetitionCatalog.ratings_profile(), 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		decomposition.accumulate(input, output)
		if (index + 1) % PROGRESS_EVERY == 0:
			print("    %d/%d games, PPP so far %.4f" % [
				index + 1, games, decomposition.totals.points_per_possession()])
	return decomposition


## The average probability penalty a shot carries, which is the quantity the
## band distribution actually delivers to the make roll.
static func _mean_contest_penalty(totals: PppDecomposition.Totals) -> float:
	var shipped := SimulationBalanceProfile.new()
	var attempts: int = totals.field_goals_attempted()
	if attempts == 0:
		return 0.0
	var weighted: float = 0.0
	for band in range(ContestBand.COUNT):
		weighted += float(totals.contest_attempts[band]) * shipped.contest_penalty(band)
	return weighted / float(attempts)


func _report_cell(
	report: CalibrationReport,
	tunable: String,
	value: float,
	decomposition: PppDecomposition,
	baseline_ppp: float,
) -> void:
	var totals: PppDecomposition.Totals = decomposition.totals
	var cell: String = "%s_%s" % [tunable, String.num(value, 3).replace(".", "p")]

	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.reconciled" % cell),
		"The ledger accounting identity closed for this cell.",
		decomposition.is_reconciled(), "ledger accounting identity", totals.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.ppp" % cell),
		"Points per engine possession at this tunable value.",
		"engine possessions", totals.points_per_possession(), totals.possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.ppp_delta" % cell),
		"Points per possession minus the shipped-baseline cell, on the identical "
		+ "fixtures at the identical seeds.",
		"engine possessions",
		totals.points_per_possession() - baseline_ppp, totals.possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.mean_contest_penalty" % cell),
		"Attempt-weighted mean contest probability penalty delivered to the make "
		+ "roll.",
		"field-goal attempts", _mean_contest_penalty(totals),
		totals.field_goals_attempted()))
	for row: Array in [
		["field_goal_percentage",
			float(totals.field_goals_made()) / maxf(float(totals.field_goals_attempted()), 1.0)],
		["two_point_percentage", totals.two_point_percentage()],
		["three_point_percentage", totals.three_point_percentage()],
		["three_point_attempt_rate", totals.three_point_attempt_rate()],
		["free_throw_rate", totals.free_throw_rate()],
		["turnover_rate", totals.turnover_rate()],
		["offensive_rebound_rate", totals.offensive_rebound_rate()],
		["assisted_share", totals.assisted_share()],
		["possessions_per_game", totals.possessions_per_game()],
	]:
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s" % [cell, row[0] as String]),
			"Measured at this tunable value.",
			"see definition", row[1] as float, totals.possessions))
	for band in range(ContestBand.COUNT):
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.contest.%s.share" % [cell, ContestBand.IDS[band]]),
			"Share of field-goal attempts in this contest band.",
			"field-goal attempts", totals.contest_share(band),
			totals.field_goals_attempted()))
