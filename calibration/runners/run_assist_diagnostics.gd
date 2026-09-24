extends SceneTree

## The assist decomposition (`BALANCE_SPEC.md` §14.1 assist percentage,
## §14.3 conditional credit curve, `SIMULATION_SPEC.md` §11.3 and §24.3).
##
## Assist percentage is one number covering two entirely different defects. A
## competition can miss its band because too few shots are genuinely created by
## a pass — a *creation* deficit — or because enough are and the ledger fails to
## credit them — an *attribution* deficit. The two need opposite corrections, so
## this report refuses to print the headline without the decomposition that
## separates them.
##
## Everything here is measured from the ordered ledger by `AssistChainAudit`,
## which rebuilds the passer-to-shot relationship independently and then
## disagrees with the engine where the engine is wrong. The audit's own
## reconstruction is never used to *produce* an assist; it exists to check one.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_assist_diagnostics.gd -- \
##       [--games=N] [--competition=high_school|...|all] [--first-variation=N] [--label=NAME]

const DEFAULT_GAMES: int = 60
const DEFAULT_FIRST_VARIATION: int = 600000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var first: int = CalibrationCli.int_option(
		options, &"first-variation", DEFAULT_FIRST_VARIATION)
	var label: String = CalibrationCli.string_option(options, &"label", "assist")

	var competitions: Array[int] = _selected(selection)
	var context := ReportContext.create(
		&"assist_diagnostics",
		"Assist creation and attribution decomposition",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per competition"
	context.sample_count = games * competitions.size()
	context.seed_description = "%d..%d" % [first + 1, first + games]
	context.seed_start = first + 1
	context.seed_end = first + games
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	if competitions.size() == 1:
		context.competition_id = CalibrationTargets.competition_id(competitions[0])
	context.notes.append(
		"Every figure is reconstructed from the ordered ledger, not from the box score. "
		+ "`assist_percentage` is credited ASSIST events over made field goals; the "
		+ "conditional conversion is credited assists over qualifying passes whose shot "
		+ "scored, which is the §14.3 curve's own denominator.")
	context.notes.append(
		"§27.1 certification sample is %d complete games per competition; this run used %d."
			% [CalibrationTargets.REQUIRED_COMPETITION_GAMES, games])

	var report := CalibrationReport.new(context)
	report.add_metric(CalibrationMetric.boolean(
		&"sample.meets_certification_size",
		"Whether this run reached the §27.1 sample size for a certifying report.",
		games >= CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source(),
		games))

	var summary: Array = []
	var audits: Array[AssistChainAudit] = []
	var labels: PackedStringArray = PackedStringArray()
	for competition in competitions:
		var audit: AssistChainAudit = _run_competition(competition, games, first)
		_judge(report, competition, audit)
		summary.append(_row(competition, audit))
		audits.append(audit)
		labels.append(String(CalibrationTargets.competition_id(competition)))
	report.add_section(&"assist_table", summary)

	report.finish()
	_print_table(labels, audits)
	quit(ReportWriter.publish(report, "assist_diagnostics_%s" % label))


func _selected(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


func _run_competition(competition: int, games: int, first: int) -> AssistChainAudit:
	var audit := AssistChainAudit.new()
	for index in range(games):
		var variation: int = first + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		audit.accumulate(input, output)
	return audit


func _judge(report: CalibrationReport, competition: int, audit: AssistChainAudit) -> void:
	var id: StringName = CalibrationTargets.competition_id(competition)

	report.add_metric(CalibrationMetric.banded(
		StringName("%s.assist_percentage" % id),
		"Credited ASSIST events over made field goals, both counted from the ledger.",
		"made field goals", 0.0,
		CalibrationTargets.assist_percentage(competition), audit.made_field_goals)
		.with_aggregation(MetricAggregation.proportion(
			audit.assists, audit.made_field_goals)))

	# The §14.3 conditional. Judged against the locked curve's own floor and
	# ceiling: the baseline is the rate at an even capability matchup, and a
	# population contains better and worse passers, so the *population* rate is
	# required to sit inside the curve rather than on its baseline.
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.assist_credit_conversion" % id),
		"Credited assists over qualifying passes whose shot scored. This is the "
		+ "§14.3 conditional's own denominator: a made field goal reached by a live "
		+ "pass to the shooter in a family the delivery created.",
		"qualifying made field goals", 0.0,
		CalibrationTargets.assist_credit_conversion(),
		audit.qualifying_passes_whose_shot_scored)
		.with_aggregation(MetricAggregation.proportion(
			audit.qualifying_made_shots_credited, audit.qualifying_passes_whose_shot_scored)))

	# --- the accounting identity ---------------------------------------------
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.assisted_plus_unassisted" % id),
		"assisted FGM + unassisted FGM == total eligible FGM, exactly.",
		audit.identity_holds(), "SIMULATION_SPEC.md §24.3", audit.made_field_goals))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.no_duplicate_assists" % id),
		"No made field goal carried more than one credited assister.",
		audit.duplicate_assists == 0, "SIMULATION_SPEC.md §11.3", audit.made_field_goals))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.no_orphan_assists" % id),
		"Every credited assist attached to the made field goal it belongs to.",
		audit.orphan_assists == 0, "SIMULATION_SPEC.md §24.3", audit.assists))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.no_self_assists" % id),
		"No player was credited with assisting his own basket.",
		audit.self_assists == 0, "SIMULATION_SPEC.md §11.3", audit.assists))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.no_cross_team_assists" % id),
		"Every credited assist belongs to the scoring team.",
		audit.cross_team_assists == 0, "SIMULATION_SPEC.md §11.3", audit.assists))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.team_equals_player_assists" % id),
		"Team assists equal the sum of player assists in every game.",
		audit.reconciliation_failures == 0, "SIMULATION_SPEC.md §24.3", audit.games))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.identity.no_unexplained_assists" % id),
		"Every credited assist is explained by the ledger chain the audit rebuilt "
		+ "independently: a live pass, to this shooter, in a created family.",
		audit.unexplained_assists == 0, "SIMULATION_SPEC.md §24.3", audit.assists))

	# --- the creation-versus-attribution split -------------------------------
	_raw(report, StringName("%s.made_field_goals" % id),
		"Total made field goals.", "made field goals",
		float(audit.made_field_goals), audit.made_field_goals)
	_ratio_metric(report, StringName("%s.assisted_share" % id),
		"Assisted made field goals over total made field goals.",
		"made field goals", audit.assisted_field_goals, audit.made_field_goals)
	_ratio_metric(report, StringName("%s.unassisted_share" % id),
		"Unassisted made field goals over total made field goals.",
		"made field goals", audit.unassisted_field_goals, audit.made_field_goals)
	_ratio_metric(report, StringName("%s.made_with_qualifying_prior_pass" % id),
		"Made field goals reached by a live qualifying pass, over all made field goals. "
		+ "This is the creation ceiling: no attribution rule can credit more than this.",
		"made field goals", audit.made_with_qualifying_prior_pass, audit.made_field_goals)
	_ratio_metric(report, StringName("%s.made_with_recorded_direct_creator" % id),
		"Made field goals whose FIELD_GOAL_MADE event records a non-unassisted state.",
		"made field goals", audit.made_with_recorded_direct_creator, audit.made_field_goals)
	_ratio_metric(report, StringName("%s.pass_created_attempt_share" % id),
		"Field-goal attempts reached by a live qualifying pass, over all attempts.",
		"field-goal attempts", audit.pass_created_attempts, audit.attempts)
	_ratio_metric(report, StringName("%s.catch_and_shoot_share" % id),
		"Pass-created pull-up attempts over all attempts.",
		"field-goal attempts", audit.catch_and_shoot_attempts, audit.attempts)
	_ratio_metric(report, StringName("%s.self_created_share" % id),
		"Attempts with no live qualifying pass, over all attempts.",
		"field-goal attempts", audit.self_created_attempts, audit.attempts)
	_raw(report, StringName("%s.uncredited_qualifying_makes" % id),
		"Qualifying made field goals that received no assist credit at all.",
		"qualifying made field goals",
		float(audit.uncredited_qualifying_makes), audit.qualifying_passes_whose_shot_scored)
	_raw(report, StringName("%s.broken_chains" % id),
		"Live creation chains invalidated before a shot resolved, all causes.",
		"chains", float(audit.total_broken_chains()), audit.passes_completed)

	# --- turnover relationship ------------------------------------------------
	_ratio_metric(report, StringName("%s.pass_turnover_rate" % id),
		"Bad-pass and interception turnovers over all pass attempts "
		+ "(completed passes plus pass turnovers).",
		"pass attempts", audit.pass_turnovers, audit.passes_completed + audit.pass_turnovers)
	_raw(report, StringName("%s.assist_to_turnover" % id),
		"Credited assists over all turnovers.", "turnovers",
		audit.assist_to_turnover(), audit.turnovers)

	report.add_section(
		StringName("assisted_rate_by_action_family.%s" % id),
		audit.rate_rows(audit.made_by_family, audit.assisted_by_family))
	report.add_section(
		StringName("assisted_rate_by_zone.%s" % id),
		audit.rate_rows(audit.made_by_zone, audit.assisted_by_zone))
	report.add_section(
		StringName("assisted_rate_by_phase.%s" % id),
		audit.rate_rows(audit.made_by_phase, audit.assisted_by_phase))
	report.add_section(
		StringName("assisted_rate_by_scorer_role.%s" % id),
		audit.rate_rows(audit.made_by_scorer_role, audit.assisted_by_scorer_role))
	report.add_section(
		StringName("assisted_rate_by_scorer_archetype.%s" % id),
		audit.rate_rows(audit.made_by_scorer_archetype, audit.assisted_by_scorer_archetype))
	report.add_section(
		StringName("assists_by_passer_role.%s" % id),
		audit.share_rows(audit.assists_by_passer_role))
	report.add_section(
		StringName("assists_by_passer_archetype.%s" % id),
		audit.share_rows(audit.assists_by_passer_archetype))
	report.add_section(
		StringName("attempts_by_action_family.%s" % id),
		audit.rate_rows(audit.attempts_by_family, audit.pass_created_attempts_by_family))
	report.add_section(
		StringName("broken_chains.%s" % id), audit.break_rows())


func _raw(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	denominator: String,
	estimate: float,
	sample_count: int,
) -> void:
	report.add_metric(CalibrationMetric.raw(
		metric_id, definition, denominator, estimate, sample_count))


func _ratio_metric(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	denominator: String,
	successes: int,
	trials: int,
) -> void:
	report.add_metric(CalibrationMetric.raw(metric_id, definition, denominator, 0.0, trials)
		.with_aggregation(MetricAggregation.proportion(successes, trials)))


func _row(competition: int, audit: AssistChainAudit) -> Dictionary:
	return {
		"competition": String(CalibrationTargets.competition_id(competition)),
		"games": audit.games,
		"made_field_goals": audit.made_field_goals,
		"assisted_field_goals": audit.assisted_field_goals,
		"unassisted_field_goals": audit.unassisted_field_goals,
		"made_with_qualifying_prior_pass": audit.made_with_qualifying_prior_pass,
		"made_with_recorded_direct_creator": audit.made_with_recorded_direct_creator,
		"attempts": audit.attempts,
		"pass_created_attempts": audit.pass_created_attempts,
		"catch_and_shoot_attempts": audit.catch_and_shoot_attempts,
		"self_created_attempts": audit.self_created_attempts,
		"qualifying_passes": audit.qualifying_passes,
		"qualifying_passes_whose_shot_scored": audit.qualifying_passes_whose_shot_scored,
		"qualifying_made_shots_credited": audit.qualifying_made_shots_credited,
		"uncredited_qualifying_makes": audit.uncredited_qualifying_makes,
		"assist_percentage": audit.assist_percentage(),
		"assist_credit_conversion": audit.credit_conversion(),
		"pass_created_attempt_share": audit.pass_created_attempt_share(),
		"catch_and_shoot_share": audit.catch_and_shoot_share(),
		"self_created_share": audit.self_created_share(),
		"pass_turnover_rate": audit.pass_turnover_rate(),
		"assist_to_turnover": audit.assist_to_turnover(),
		"passes_completed": audit.passes_completed,
		"pass_turnovers": audit.pass_turnovers,
		"turnovers": audit.turnovers,
		"broken_chains": audit.total_broken_chains(),
		"state_disagreements": audit.state_disagreements,
		"unexplained_assists": audit.unexplained_assists,
		"identity_holds": audit.identity_holds(),
	}


func _print_table(labels: PackedStringArray, audits: Array[AssistChainAudit]) -> void:
	print("")
	print("  %-18s %7s %7s %7s %7s %7s %7s %7s %7s" % [
		"competition", "FGM", "AST%", "qual%", "conv%", "PC-att%", "C&S%", "self%", "pTOV%"])
	for index in range(audits.size()):
		var audit: AssistChainAudit = audits[index]
		print("  %-18s %7d %6.1f%% %6.1f%% %6.1f%% %6.1f%% %6.1f%% %6.1f%% %6.1f%%" % [
			labels[index], audit.made_field_goals,
			100.0 * audit.assist_percentage(),
			100.0 * AssistChainAudit._ratio(
				float(audit.made_with_qualifying_prior_pass),
				float(audit.made_field_goals)),
			100.0 * audit.credit_conversion(),
			100.0 * audit.pass_created_attempt_share(),
			100.0 * audit.catch_and_shoot_share(),
			100.0 * audit.self_created_share(),
			100.0 * audit.pass_turnover_rate(),
		])
	print("")
