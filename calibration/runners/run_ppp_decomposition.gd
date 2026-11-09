extends SceneTree

## Where does top domestic's points-per-possession excess come from?
## (`BALANCE_SPEC.md` §14.1, Stage 4 diagnostic.)
##
## Top-domestic points per possession pools to 1.1847 ±0.0037 over 2,000 games
## against a 1.08-1.18 ceiling: a genuine failure of about +0.0047 whose whole
## magnitude is four ten-thousandths of a point per possession. Nothing about
## that number tells you where it lives, and no amount of re-measuring it will.
##
## So this takes it apart. `PppDecomposition` reads the ordered ledger and the
## possession records — never the box score — and produces terms that sum back
## to points per possession exactly:
##
## ```text
## PPP = 2PT points/possession + 3PT points/possession + FT points/possession
## ```
##
## Each term then splits into a rate and a volume, both of which have their own
## §14.1 band or their own basketball meaning, so an excess can be *attributed*
## rather than guessed at. Overseas is run alongside as the adjacent level: the
## two share every mechanism and differ only in profile, so a term that differs
## between them by more than its band allows is a profile question and a term
## that differs in neither is not the cause.
##
## The identities are enforced. Unexplained points, duplicated possessions,
## orphaned attempts and mismatched denominators are counted and published, and
## the report fails when any of them is non-zero. A decomposition that adds up
## because it discards what it cannot explain is worse than none.
##
## This is a diagnostic. It certifies nothing and tunes nothing.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_ppp_decomposition.gd -- \
##       [--games=N] [--competition=all|top_domestic_pro|...] [--range=diagnosis|diagnosis_second] \
##       [--label=NAME]

const DEFAULT_GAMES: int = 400

## Diagnosis ranges owned by this runner, disjoint from every range any other
## section uses — including §5.18's audit and validation ranges. Nothing is
## tuned against these; they exist to locate the excess.
const DIAGNOSIS_BASE: int = 840000
const DIAGNOSIS_SECOND_BASE: int = 845000

## Progress cadence. A 400-game five-level run is 2,000 simulations and takes
## long enough that silence is indistinguishable from a hang — the previous
## section learned that the expensive way.
const PROGRESS_EVERY: int = 50


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var range_name: String = CalibrationCli.string_option(options, &"range", "diagnosis")
	var label: String = CalibrationCli.string_option(options, &"label", "ppp_decomposition")
	var base: int = _range_base(range_name)
	var competitions: Array[int] = _competitions(selection)

	var context := ReportContext.create(
		&"ppp_decomposition",
		"Points-per-possession accounting decomposition",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per competition"
	context.sample_count = games
	context.competition_id = (
		CalibrationTargets.competition_id(competitions[0]) if competitions.size() == 1
		else &"all")
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"DIAGNOSTIC ONLY. Locates the §14.1 points-per-possession excess; "
		+ "certifies nothing and tunes nothing.")
	context.notes.append(
		"Every figure is read from the ordered ledger and the possession "
		+ "records. The box score is used only as a third reconciliation.")
	context.notes.append(
		"Seed range: %s, variations %d-%d, RNG seeds %d-%d."
		% [range_name, base, base + games - 1, base + 1, base + games])

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	for competition in competitions:
		var id: String = String(CalibrationTargets.competition_id(competition))
		print("decomposition: %s, %d games..." % [id, games])
		var decomposition: PppDecomposition = _simulate(competition, games, base)
		var payload: Dictionary = decomposition.to_dictionary()
		payload["competition"] = id
		rows.append(payload)
		_report_competition(report, id, decomposition)
		print("  %s: PPP %.4f over %d possessions, %d violation(s)" % [
			id, decomposition.totals.points_per_possession(),
			decomposition.totals.possessions, decomposition.violations.size()])
		for violation in decomposition.violations:
			printerr("  VIOLATION %s" % violation)
	report.add_section(&"decomposition", rows)
	report.finish()
	quit(ReportWriter.publish(report, "ppp_decomposition_%s" % label))


func _range_base(range_name: String) -> int:
	match range_name:
		"diagnosis":
			return DIAGNOSIS_BASE
		"diagnosis_second":
			return DIAGNOSIS_SECOND_BASE
		_:
			printerr("unknown range '%s'; using diagnosis" % range_name)
			return DIAGNOSIS_BASE


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


func _simulate(competition: int, games: int, base: int) -> PppDecomposition:
	var decomposition := PppDecomposition.new()
	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		decomposition.accumulate(input, output)
		if (index + 1) % PROGRESS_EVERY == 0:
			print("    %d/%d games, PPP so far %.4f" % [
				index + 1, games, decomposition.totals.points_per_possession()])
	return decomposition


func _report_competition(
	report: CalibrationReport,
	id: String,
	decomposition: PppDecomposition,
) -> void:
	var totals: PppDecomposition.Totals = decomposition.totals

	# --- the identities, judged ---------------------------------------------
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.accounting.identity_holds" % id),
		"2PT points + 3PT points + FT points equals the ledger's total points.",
		decomposition.identity_holds(), "ledger accounting identity", totals.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.accounting.unexplained_points" % id),
		"Ledger points not attributable to a two-point, three-point or free-throw "
		+ "term. Must be zero.",
		"points", float(decomposition.unexplained_points()), totals.games))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.accounting.reconciled" % id),
		"Every identity closed: no unexplained points, no duplicated possession, "
		+ "no orphaned attempt, and the possession records, the POSSESSION_ENDED "
		+ "events and the box score all agree.",
		decomposition.is_reconciled(), "ledger accounting identity", totals.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.accounting.violations" % id),
		"Reconciliation breaches found. Must be zero.",
		"breaches", float(decomposition.violations.size()), totals.games))

	# --- the headline and its exact parts -----------------------------------
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.ppp.total" % id),
		"Points per engine possession, from the ledger.",
		"engine possessions", totals.points_per_possession(), totals.possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.ppp.two_point" % id),
		"Two-point points per possession. The three ppp terms sum to the total.",
		"engine possessions", totals.two_point_ppp(), totals.possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.ppp.three_point" % id),
		"Three-point points per possession.",
		"engine possessions", totals.three_point_ppp(), totals.possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.ppp.free_throw" % id),
		"Free-throw points per possession.",
		"engine possessions", totals.free_throw_ppp(), totals.possessions))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.ppp.terms_sum_to_total" % id),
		"The three points-per-possession terms sum to the published total.",
		absf(totals.two_point_ppp() + totals.three_point_ppp()
			+ totals.free_throw_ppp() - totals.points_per_possession()) <= 1e-9,
		"ledger accounting identity", totals.possessions))

	# --- rates and volumes, each with its own meaning ------------------------
	var rates: Array[Array] = [
		["shooting.two_point_percentage", totals.two_point_percentage(),
			"Two-point field goals made over attempted."],
		["shooting.three_point_percentage", totals.three_point_percentage(),
			"Three-point field goals made over attempted."],
		["shooting.three_point_attempt_rate", totals.three_point_attempt_rate(),
			"Three-point attempts over all field-goal attempts."],
		["shooting.free_throw_percentage", totals.free_throw_percentage(),
			"Free throws made over attempted."],
		["shooting.free_throw_rate", totals.free_throw_rate(),
			"Free-throw attempts over field-goal attempts."],
		["possession.turnover_rate", totals.turnover_rate(),
			"Turnovers over engine possessions."],
		["possession.offensive_rebound_rate", totals.offensive_rebound_rate(),
			"Offensive rebounds over all rebounds."],
		["possession.extension_rate", totals.extension_rate(),
			"Share of possessions carrying at least one offensive rebound."],
		["possession.transition_share", totals.transition_share(),
			"Share of possessions that entered transition."],
		["possession.transition_ppp", totals.transition_ppp(),
			"Points per transition possession."],
		["creation.assisted_share", totals.assisted_share(),
			"Made field goals with a recorded creator, over all makes."],
		["creation.putback_percentage", totals.putback_percentage(),
			"Putback attempts converted."],
		["scoring.second_chance_ppp", totals.second_chance_ppp(),
			"Points after an offensive rebound, per possession."],
	]
	for row: Array in rates:
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s" % [id, row[0]]), row[2] as String,
			"see definition", row[1] as float, totals.possessions))

	# --- distributions -------------------------------------------------------
	for zone in range(ShotZone.COUNT):
		var zone_name: String = ShotZone.IDS[zone]
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.zone.%s.share" % [id, zone_name]),
			"Share of field-goal attempts taken from this zone.",
			"field-goal attempts", totals.zone_share(zone),
			totals.field_goals_attempted()))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.zone.%s.percentage" % [id, zone_name]),
			"Field goals made from this zone, over attempts from it.",
			"field-goal attempts", totals.zone_percentage(zone),
			totals.zone_attempts[zone]))
	for band in range(ContestBand.COUNT):
		var band_name: String = ContestBand.IDS[band]
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.contest.%s.share" % [id, band_name]),
			"Share of field-goal attempts taken against this contest band. The "
			+ "ledger's shot-quality axis.",
			"field-goal attempts", totals.contest_share(band),
			totals.field_goals_attempted()))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.contest.%s.percentage" % [id, band_name]),
			"Field goals made against this contest band, over attempts into it.",
			"field-goal attempts", totals.contest_percentage(band),
			totals.contest_attempts[band]))

	# --- splits that could move PPP without being scoring defects -----------
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.split.garbage_time_possession_share" % id),
		"Share of possessions played in garbage time.",
		"engine possessions",
		0.0 if totals.possessions == 0
		else float(totals.garbage_time_possessions) / float(totals.possessions),
		totals.possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.split.garbage_time_ppp" % id),
		"Points per possession inside garbage time.",
		"engine possessions",
		0.0 if totals.garbage_time_possessions == 0
		else float(totals.garbage_time_points) / float(totals.garbage_time_possessions),
		totals.garbage_time_possessions))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.split.foul_generated_trip_share" % id),
		"Share of possessions whose free throws came from a non-shooting foul.",
		"engine possessions",
		0.0 if totals.possessions == 0
		else float(totals.foul_generated_trips) / float(totals.possessions),
		totals.possessions))
