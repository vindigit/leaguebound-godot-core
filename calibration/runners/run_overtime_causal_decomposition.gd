extends SceneTree

## The §14.2 overtime causal decomposition (`PROJECT_STATUS.md` §5.34).
##
## `PROJECT_STATUS.md` §5.28 measured college at 0.0310 and top domestic at
## 0.0223 against a locked 0.0400-0.0800 band. §5.29-§5.33 corrected the endgame
## repertoire, the restart contract, the made-field-goal clock matrix and the
## pace environment, and none of them moved either number. This runner is the
## diagnostic that has to answer *why* before a sixth behaviour is proposed.
##
## **It changes nothing.** No target, no tolerance, no production probability
## and no ruleset version. It reads finished games and reports where the missing
## regulation-tie mass goes, separately for each competition, because college
## and top domestic may not share a cause and must not be forced through one
## correction.
##
## **Two roster arms, because the population is a hypothesis of its own.**
## `--rosters=generated` walks `CompetitionCatalog.match_for`, the population the
## §14 bands are measured against. `--rosters=mirror` walks
## `CompetitionCatalog.mirrored_match_for`, two identical rosters, where the
## pregame strength gap is exactly zero by construction. If overtime passes on
## mirrors and fails on the population, the cause is roster generation and not
## the possession engine — and the reverse is equally decisive.
##
## Run:
##   godot --headless --path . --script \
##     res://calibration/runners/run_overtime_causal_decomposition.gd -- \
##     [--games=N] [--competition=college|top_domestic_pro|all] \
##     [--rosters=generated|mirror] [--base=SEED] \
##     [--shard=I --shards=N] [--label=NAME] [--verify-determinism]
##
##   godot --headless --path . --script \
##     res://calibration/runners/run_overtime_causal_decomposition.gd -- \
##     --aggregate --label=NAME [--directory=res://reports]

const REPORT_ID: StringName = &"overtime_causal_decomposition"
const DEFAULT_GAMES: int = 500

## Seed bases, disjoint from every range another section owns and from each
## other. Two disjoint ranges are what separate a real miss from one seed
## range's luck, and the §5.28 evidence already records college moving between
## ranges — so a pooled result is never reported without both.
const RANGE_A_BASE: int = 940000
const RANGE_B_BASE: int = 6940000

## The §14.2 band, quoted so the report can state the gap. **Read only.** No
## code path here may move it, and the owner decision package exists precisely
## because a target is not a runner's to change.
const OVERTIME_BAND_MINIMUM: float = 0.0400
const OVERTIME_BAND_MAXIMUM: float = 0.0800


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	if CalibrationCli.bool_option(options, &"aggregate", false):
		_aggregate(options)
		return
	_measure(options)


# --- measurement --------------------------------------------------------------

func _measure(options: Dictionary) -> void:
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var rosters: String = CalibrationCli.string_option(options, &"rosters", "generated")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = CalibrationCli.int_option(options, &"shards", 1)
	var base: int = CalibrationCli.int_option(options, &"base", RANGE_A_BASE)
	var label: String = CalibrationCli.string_option(options, &"label", "")
	var verify: bool = CalibrationCli.bool_option(options, &"verify-determinism", false)
	assert(games > 0, "games must be positive")
	assert(shards > 0 and shard >= 0 and shard < shards, "invalid shard")
	assert(rosters == "generated" or rosters == "mirror", "unknown roster arm")

	var start: int = base + shard * games
	var competitions: Array[int] = _competitions(selection)
	var exit_code: int = 0
	for competition in competitions:
		var report: CalibrationReport = _measure_one(
			competition, games, start, shard, shards, rosters, verify)
		var stem: String = "%s_%s_%s_shard%02d" % [
			REPORT_ID,
			CalibrationTargets.competition_id(competition),
			label if not label.is_empty() else rosters,
			shard,
		]
		exit_code = maxi(exit_code, ReportWriter.publish(report, stem))
	quit(exit_code)


func _measure_one(
	competition: int,
	games: int,
	start: int,
	shard: int,
	shards: int,
	rosters: String,
	verify: bool,
) -> CalibrationReport:
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var context := ReportContext.create(
		REPORT_ID,
		"Overtime causal decomposition (%s, %s rosters)" % [
			CalibrationTargets.competition_id(competition), rosters],
		rules,
		balance,
		SeededRandomSource.new(1).get_version())
	context.competition_id = CalibrationTargets.competition_id(competition)
	context.sample_unit = "complete games"
	context.sample_count = games
	context.set_shard(shard, shards, start + 1, start + games)
	# Stated so the report says out loud that it is nowhere near a §27.1 sample,
	# rather than passing a certification check it never attempted.
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"DIAGNOSTIC ONLY. No target, tolerance, ruleset version or production "
		+ "probability is read for writing here, and none is changed.")
	context.notes.append(
		"Roster arm: %s. %s" % [
			rosters,
			"CompetitionCatalog.match_for — the generated calibration population."
			if rosters == "generated"
			else "CompetitionCatalog.mirrored_match_for — identical rosters, "
			+ "pregame strength gap exactly zero."])
	context.notes.append(
		"Every figure is replayed from the committed ledger through the "
		+ "production MatchStateReducer. The instrument consumes no random "
		+ "source and cannot change what a seed produces.")
	context.notes.append(
		"NOT a BALANCE_SPEC.md §27.1 certification. Nothing here is certified.")

	var tally := OvertimeDecomposition.Tally.new()
	var determinism_checked: int = 0
	var determinism_failures: int = 0
	for index in range(games):
		var variation: int = start + index
		var input: MatchInput = _input_for(competition, rosters, variation)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		OvertimeDecomposition.measure(tally, input, output)
		if verify and index % 100 == 0:
			determinism_checked += 1
			var repeat_input: MatchInput = _input_for(competition, rosters, variation)
			var repeat: MatchSimulationOutput = MatchSession.new(
				repeat_input, SeededRandomSource.new(variation + 1)).run_to_completion()
			if repeat.signature() != output.signature():
				determinism_failures += 1
		if games > 500 and (index + 1) % 500 == 0:
			print("  %s/%s: %d/%d" % [
				CalibrationTargets.competition_id(competition), rosters, index + 1, games])

	var report := CalibrationReport.new(context)
	_add_metrics(report, tally, competition, rosters)
	# Emitted on every shard, verified or not. `ReportAggregator` requires every
	# metric to appear in every shard with the same definition, and a metric that
	# only some shards carry rejects the whole aggregation — so a shard that
	# checked nothing reports nothing checked rather than omitting the row.
	_invariant(report, &"instrument.repeated_seed_signature_identical",
		"Re-simulated seeds that reproduced their output signature byte for byte, "
		+ "over seeds re-simulated. The instrument reads finished games and must "
		+ "not change what a seed produces.",
		"Stage 4 brief: instrumentation must not change seeded outcomes",
		determinism_checked - determinism_failures, determinism_checked)
	report.add_section(&"tally", tally.to_dictionary())
	report.add_section(&"funnel", _funnel_section(tally))
	report.finish()
	return report


func _input_for(competition: int, rosters: String, variation: int) -> MatchInput:
	if rosters == "mirror":
		return CompetitionCatalog.mirrored_match_for(competition, variation, 0.5)
	return CompetitionCatalog.match_for(competition, variation, 0.5)


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return [
			CalibrationTargets.Competition.COLLEGE,
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO,
		] as Array[int]
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	assert(false, "unknown competition '%s'" % selection)
	return [] as Array[int]


# --- metrics ------------------------------------------------------------------

## The metrics that go through the canonical aggregator. Every one carries a
## `MetricAggregation`, so a sharded run recombines from raw terms and the
## Wilson interval is recomputed rather than averaged.
func _add_metrics(
	report: CalibrationReport,
	tally: OvertimeDecomposition.Tally,
	competition: int,
	rosters: String,
) -> void:
	var games: int = tally.count_of(&"games")

	_proportion(report, &"overtime_rate",
		"Games whose final result carries at least one overtime period, over all games.",
		tally.count_of(&"overtime_entries"), games)
	_proportion(report, &"regulation_tie_rate",
		"Games whose replayed regulation score was level at the horn, over all games. "
		+ "Derived from the ledger independently of the result's overtime count.",
		tally.count_of(&"regulation_ties"), games)
	_invariant(report, &"invariant.regulation_ties_equal_overtime_entries",
		"Games whose replayed regulation tie and recorded overtime entry agree, "
		+ "over all games. One is the other's proof (Hypothesis A).",
		"Stage 4 brief Hypothesis A: regulation_ties == games_entering_overtime",
		games - tally.count_of(&"invariant.tie_overtime_mismatch"), games)
	_invariant(report, &"invariant.no_level_final_score",
		"Games finishing on an unlevel score, over all games.",
		"SIMULATION_SPEC.md §3.1: a match ends only on an unlevel score",
		games - tally.count_of(&"anomaly.final_score_level"), games)
	_invariant(report, &"invariant.no_negative_score",
		"Games finishing with both team scores non-negative, over all games.",
		"SIMULATION_SPEC.md §5.1: scores accumulate from scoring events",
		games - tally.count_of(&"anomaly.negative_score"), games)
	_invariant(report, &"invariant.regulation_end_observed",
		"Games whose end of regulation was located in their own ledger, over all games.",
		"Stage 4 brief Phase 1: regulation completion must be detectable",
		games - tally.count_of(&"anomaly.regulation_end_not_observed"), games)

	_proportion(report, &"multiple_overtime_share",
		"Games reaching a second overtime period, over games reaching overtime.",
		tally.count_of(&"overtime_multiple"), tally.count_of(&"overtime_entries"))
	_proportion(report, &"close_game_rate",
		"Games whose regulation margin was five points or fewer, over all games.",
		tally.count_of(&"close_game"), games)
	_proportion(report, &"blowout_rate",
		"Games whose regulation margin was twenty points or more, over all games.",
		tally.count_of(&"blowout"), games)

	_mean(report, &"regulation_margin_signed_mean",
		"Mean signed regulation margin, home minus away.", tally,
		&"regulation_margin_signed", "games")
	_mean(report, &"regulation_margin_signed_sd",
		"Standard deviation of the signed regulation margin.", tally,
		&"regulation_margin_signed", "games", true)
	_mean(report, &"regulation_margin_abs_mean",
		"Mean absolute regulation margin.", tally, &"regulation_margin_abs", "games")

	for index in range(OvertimeDecomposition.FUNNEL_STAGES.size()):
		var stage: String = OvertimeDecomposition.FUNNEL_STAGES[index]
		_proportion(report, StringName("funnel.%s" % stage),
			"Games reaching funnel stage %s, over all games." % stage,
			tally.count_of(StringName("funnel.%s" % stage)), games)
		if index > 0:
			_proportion(report, StringName("funnel.%s.given_previous" % stage),
				"Games reaching stage %s among games that reached the stage before it."
				% stage,
				tally.count_of(StringName("funnel.%s.given_previous_hits" % stage)),
				tally.count_of(StringName("funnel.%s.given_previous_trials" % stage)))

	for checkpoint in OvertimeDecomposition.CHECKPOINT_NAMES:
		var observed: int = int(tally.moment_of(
			StringName("cp.%s.margin" % checkpoint))[0])
		if observed <= 0:
			continue
		_mean(report, StringName("checkpoint.%s.margin_sd" % checkpoint),
			"Standard deviation of the signed margin at %s of regulation." % checkpoint,
			tally, StringName("cp.%s.margin" % checkpoint), "games", true)
		_mean(report, StringName("checkpoint.%s.abs_margin_mean" % checkpoint),
			"Mean absolute margin at %s of regulation." % checkpoint,
			tally, StringName("cp.%s.abs_margin" % checkpoint), "games")
		_mean(report, StringName("checkpoint.%s.possessions_remaining" % checkpoint),
			"Regulation possessions still to be played at %s." % checkpoint,
			tally, StringName("cp.%s.possessions_remaining" % checkpoint), "games")
		_proportion(report, StringName("checkpoint.%s.zero_margin" % checkpoint),
			"Games level at %s, over games observed there." % checkpoint,
			tally.count_of(StringName("cp.%s.density.0" % checkpoint)), observed)

	for mechanism in OvertimeDecomposition.MECHANISMS:
		_ratio(report, StringName("mechanism.%s.per_game" % mechanism),
			"Activations of %s per game, evaluated from the production "
			% mechanism + "predicate against replayed state, not from the "
			+ "priority-ordered ledger tag.",
			float(tally.count_of(StringName("mech.%s.activations" % mechanism))),
			float(games), "games")

	_ratio(report, &"intentional_foul_cycles_per_game",
		"Intentional fouls charged per game.",
		float(tally.count_of(&"cycle.intentional_foul")), float(games), "games")
	_mean(report, &"population.abs_expected_gap_mean",
		"Mean absolute pregame expected-margin gap between the two rosters.",
		tally, &"population.abs_expected_gap", "games")
	_mean(report, &"population.abs_expected_gap_sd",
		"Standard deviation of the absolute pregame expected-margin gap.",
		tally, &"population.abs_expected_gap", "games", true)

	report.add_metric(CalibrationMetric.raw(
		&"context.band_minimum",
		"The locked §14.2 overtime band's lower bound, quoted for reference. "
		+ "This runner never writes it.",
		"share", OVERTIME_BAND_MINIMUM, games))
	report.add_metric(CalibrationMetric.raw(
		&"context.competition", "Competition measured.", "enum",
		float(competition), games))
	report.add_metric(CalibrationMetric.raw(
		&"context.roster_arm", "0 = generated population, 1 = mirrored rosters.",
		"enum", 1.0 if rosters == "mirror" else 0.0, games))


## An invariant reported as a proportion rather than as a bare boolean, so a
## sharded run recombines it from raw counts and a breach in one shard cannot be
## lost by an aggregation that had nothing to add.
func _invariant(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	source: String,
	holding: int,
	games: int,
) -> void:
	var estimate: float = 0.0 if games == 0 else float(holding) / float(games)
	var metric := CalibrationMetric.raw(metric_id, definition, "games", estimate, games)
	metric.target_minimum = 1.0
	metric.target_maximum = 1.0
	metric.target_source = source
	# The verdict has to be judged *before* the terms are attached:
	# `with_aggregation` recomputes a verdict only for a metric that already has
	# one, so an invariant left informational here is an invariant that can never
	# fail — which is worse than not reporting it at all.
	metric.verdict = (
		CalibrationMetric.Verdict.PASS if estimate >= 1.0
		else CalibrationMetric.Verdict.FAIL)
	report.add_metric(metric.with_aggregation(
		MetricAggregation.proportion(holding, games)))


func _proportion(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	successes: int,
	trials: int,
) -> void:
	var metric := CalibrationMetric.raw(
		metric_id, definition, "games", 0.0 if trials == 0 else float(successes) / float(trials),
		trials)
	report.add_metric(metric.with_aggregation(
		MetricAggregation.proportion(successes, trials)))


func _ratio(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	numerator: float,
	denominator: float,
	unit: String,
) -> void:
	var metric := CalibrationMetric.raw(
		metric_id, definition, unit,
		0.0 if denominator == 0.0 else numerator / denominator, int(denominator))
	report.add_metric(metric.with_aggregation(
		MetricAggregation.ratio(numerator, denominator)))


func _mean(
	report: CalibrationReport,
	metric_id: StringName,
	definition: String,
	tally: OvertimeDecomposition.Tally,
	key: StringName,
	unit: String,
	deviation: bool = false,
) -> void:
	var terms: PackedFloat64Array = tally.moment_of(key)
	var aggregation := MetricAggregation.new()
	aggregation.kind = MetricAggregation.Kind.MEAN
	aggregation.count = int(terms[0])
	aggregation.sum = terms[1]
	aggregation.sum_of_squares = terms[2]
	if not deviation:
		var metric := CalibrationMetric.raw(
			metric_id, definition, unit, tally.mean_of(key), int(terms[0]))
		report.add_metric(metric.with_aggregation(aggregation))
		return
	# A standard deviation is not a mean, so it is reported without an
	# aggregation payload rather than with one the aggregator would recombine as
	# though it were. The mean metric beside it carries the terms a combined
	# deviation is rebuilt from.
	report.add_metric(CalibrationMetric.raw(
		metric_id, definition, unit, tally.deviation_of(key), int(terms[0])))


func _funnel_section(tally: OvertimeDecomposition.Tally) -> Dictionary:
	var rows: Array = []
	var games: int = tally.count_of(&"games")
	for index in range(OvertimeDecomposition.FUNNEL_STAGES.size()):
		var stage: String = OvertimeDecomposition.FUNNEL_STAGES[index]
		var reached: int = tally.count_of(StringName("funnel.%s" % stage))
		var trials: int = tally.count_of(
			StringName("funnel.%s.given_previous_trials" % stage))
		var hits: int = tally.count_of(StringName("funnel.%s.given_previous_hits" % stage))
		rows.append({
			"stage": stage,
			"count": reached,
			"rate_of_all_games": 0.0 if games == 0 else float(reached) / float(games),
			"given_previous_trials": trials,
			"given_previous_hits": hits,
			"rate_given_previous": 0.0 if trials == 0 else float(hits) / float(trials),
		})
	return {"games": games, "stages": rows}


# --- aggregation --------------------------------------------------------------

## Combines this report's shards two ways and checks that they agree.
##
## `ReportAggregator` recombines the metrics from their raw terms — the canonical
## path every other sharded report uses. The counter sections are summed
## independently here, and the overtime rate rebuilt from the summed counters is
## compared with the aggregator's. Two paths that disagree mean one of them is
## wrong, and a decomposition nobody can recombine is a decomposition nobody can
## check.
func _aggregate(options: Dictionary) -> void:
	var directory: String = CalibrationCli.string_option(
		options, &"directory", "res://reports")
	var label: String = CalibrationCli.string_option(options, &"label", "aggregate")
	var shards: int = CalibrationCli.int_option(options, &"shards", 0)
	var result: ReportAggregator.Result = ReportAggregator.aggregate_directory(
		directory, REPORT_ID, shards)

	print("")
	print("=== Overtime decomposition shard aggregation: %s ===" % label)
	print("  shards accepted: %d of %d expected" % [
		result.shards_accepted, result.shards_expected])
	print("  combined sample: %d games" % result.combined_sample)
	for warning in result.warnings:
		print("  warning: %s" % warning)
	for rejection in result.rejections:
		printerr("  REJECTED: %s" % rejection)

	var merged := OvertimeDecomposition.Tally.new()
	var merged_shards: int = 0
	var access: DirAccess = DirAccess.open(directory)
	if access != null:
		var names: PackedStringArray = access.get_files()
		names.sort()
		for file_name in names:
			if not file_name.ends_with(".json"):
				continue
			var payload: Dictionary = _read_json("%s/%s" % [directory, file_name])
			if payload.is_empty():
				continue
			var context_payload: Dictionary = JsonRead.dictionary_at(payload, "context")
			if JsonRead.name_at(context_payload, "report_id") != REPORT_ID:
				continue
			var sections: Dictionary = JsonRead.dictionary_at(payload, "sections")
			var tally_payload: Dictionary = JsonRead.dictionary_at(sections, "tally")
			if tally_payload.is_empty():
				continue
			merged.merge(OvertimeDecomposition.Tally.from_dictionary(tally_payload))
			merged_shards += 1

	var summed_games: int = merged.count_of(&"games")
	var summed_rate: float = (
		0.0 if summed_games == 0
		else float(merged.count_of(&"overtime_entries")) / float(summed_games))
	var canonical_rate: float = NAN
	for metric in result.report.metrics:
		if metric.metric_id == &"overtime_rate":
			canonical_rate = metric.estimate
	print("  counter sections merged: %d shard(s), %d games" % [merged_shards, summed_games])
	print("  overtime rate — counters %.6f, canonical aggregator %.6f" % [
		summed_rate, canonical_rate])
	var comparable: bool = not is_nan(canonical_rate)
	var agree: bool = comparable and absf(summed_rate - canonical_rate) < 1e-9
	print("  aggregation paths agree: %s" % (
		"yes" if agree
		else ("NO" if comparable
			else "NOT COMPARABLE — the canonical aggregation produced no estimate")))
	print("")
	_print_report(merged, label)

	var path: String = ReportWriter.write(result.report, "aggregate_%s" % label)
	ReportWriter.summarize(result.report, path)
	_write_merged(merged, label)
	if not result.ok() or not agree:
		quit(1)
		return
	quit(0)


func _write_merged(tally: OvertimeDecomposition.Tally, label: String) -> void:
	var directory: String = ProjectSettings.globalize_path("res://reports")
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = "res://reports/merged_%s_%s.json" % [REPORT_ID, label]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("unable to write merged counters to %s" % path)
		return
	file.store_string(JSON.stringify(tally.to_dictionary(), "  ", false))
	file.close()
	print("  merged counters: %s" % path)


func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var payload: Dictionary = parsed
		return payload
	return {}


# --- human summary ------------------------------------------------------------

func _print_report(tally: OvertimeDecomposition.Tally, label: String) -> void:
	var games: int = tally.count_of(&"games")
	if games == 0:
		return
	print("--- %s (%d games) ---" % [label, games])
	print("  overtime %.4f   regulation ties %.4f   band %.4f-%.4f" % [
		_rate(tally.count_of(&"overtime_entries"), games),
		_rate(tally.count_of(&"regulation_ties"), games),
		OVERTIME_BAND_MINIMUM, OVERTIME_BAND_MAXIMUM])
	print("  regulation margin: mean %.3f  sd %.3f  |margin| mean %.3f" % [
		tally.mean_of(&"regulation_margin_signed"),
		tally.deviation_of(&"regulation_margin_signed"),
		tally.mean_of(&"regulation_margin_abs")])
	print("  close %.4f   blowout %.4f" % [
		_rate(tally.count_of(&"close_game"), games),
		_rate(tally.count_of(&"blowout"), games)])
	print("  funnel:")
	for index in range(OvertimeDecomposition.FUNNEL_STAGES.size()):
		var stage: String = OvertimeDecomposition.FUNNEL_STAGES[index]
		var reached: int = tally.count_of(StringName("funnel.%s" % stage))
		var trials: int = tally.count_of(
			StringName("funnel.%s.given_previous_trials" % stage))
		var hits: int = tally.count_of(StringName("funnel.%s.given_previous_hits" % stage))
		print("    %-34s n=%-7d %.4f of games   given previous %s" % [
			stage, reached, _rate(reached, games),
			"n/a" if trials == 0 else "%d/%d = %.4f" % [hits, trials, _rate(hits, trials)]])


func _rate(numerator: int, denominator: int) -> float:
	return 0.0 if denominator == 0 else float(numerator) / float(denominator)
