extends SceneTree

## Where does a competition's field-goal percentage come from?
## (`BALANCE_SPEC.md` §14.1, Stage 4 diagnostic.)
##
## High school and college have carried a §14.1 field-goal-percentage failure
## across several rulesets. Points per possession passes at both levels while
## field-goal percentage does not, which already rules out "these levels simply
## score too little" and makes the question specific: the shots are going in at
## a rate the band does not allow, while the points they produce are fine.
##
## This runner takes that rate apart along every axis that could carry it, from
## two independent directions:
##
## - `PppDecomposition` reads the **ordered ledger** and the possession records
##   — what was attempted, from where, against what contest, and whether it went
##   in — and reconciles against the box score as a third source.
## - `ShotTermAccumulator` reads the **terms of the make probability itself**
##   off `ShotResolver`, so the shooter's capability, the contest penalty, and
##   the movement, fatigue, clock and catch penalties are the production values
##   rather than a second copy of the arithmetic.
##
## Together those answer the question the §14.1 verdict cannot: whether a level
## shoots badly because its players are worse — which is the model working, and
## is not a defect — or because something in the shared profile reaches it
## differently, which is.
##
## A control competition is run alongside for exactly that reason. Every level
## shares one balance profile, so a term that differs between two levels by more
## than their rating gap explains is a profile question, and a term that differs
## in neither is not the cause.
##
## The identities are enforced and a breach fails the run. A decomposition that
## adds up because it discarded what it could not explain is worse than none.
##
## This is a diagnostic. It certifies nothing and tunes nothing.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_fg_decomposition.gd -- \
##       [--games=N] [--competition=high_school|college|...|all] [--bases=A,B] \
##       [--label=NAME]
##
## `--bases` takes one or more seed-range bases and runs `--games` from each.
## Two ranges given here are **pooled from the underlying per-team-game counts**
## by a single accumulator, which is the only correct way to combine them: an
## average of two published percentages weights by report rather than by
## team-game, and cannot form the pooled interval at all, because that interval
## is a property of the combined per-cluster series.

const DEFAULT_GAMES: int = 400

## Progress cadence. Any run past this length states where it is; a run that
## prints nothing is indistinguishable from a hung one.
const PROGRESS_EVERY: int = 50

## Default diagnosis base. Overridden by `--base` so the seed-range ledger is
## the caller's explicit choice rather than a constant that quietly gets reused.
const DEFAULT_BASE: int = 910000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var label: String = CalibrationCli.string_option(options, &"label", "fg_decomposition")
	var bases: Array[int] = _bases(
		CalibrationCli.string_option(options, &"bases", str(DEFAULT_BASE)))
	var competitions: Array[int] = _competitions(selection)
	var base: int = bases[0]
	var total_games: int = games * bases.size()

	var context := ReportContext.create(
		&"fg_decomposition",
		"Field-goal percentage accounting decomposition",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per competition"
	context.sample_count = total_games
	context.competition_id = (
		CalibrationTargets.competition_id(competitions[0]) if competitions.size() == 1
		else &"all")
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"DIAGNOSTIC ONLY. Locates the §14.1 field-goal-percentage failure; "
		+ "certifies nothing and tunes nothing.")
	context.notes.append(
		"Counts are read from the ordered ledger and reconciled against the "
		+ "possession records and the box score. Probability terms are read "
		+ "from ShotResolver itself and are not recomputed here.")
	context.notes.append(
		"Field-goal percentage intervals are the clustered ratio estimator over "
		+ "team-games, never a binomial interval over attempts.")
	for range_base in bases:
		context.notes.append(
			"Seed range: variations %d-%d, RNG seeds %d-%d."
			% [range_base, range_base + games - 1, range_base + 1, range_base + games])
	if bases.size() > 1:
		context.notes.append(
			"Pooled over %d ranges from the underlying per-team-game counts by "
			% bases.size()
			+ "one accumulator; no report-level percentage was averaged.")

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	var failed: bool = false
	for competition in competitions:
		var id: String = String(CalibrationTargets.competition_id(competition))
		print("fg decomposition: %s, %d games from each of %d range(s)..." % [
			id, games, bases.size()])
		var decomposition := PppDecomposition.new()
		var terms := ShotTermAccumulator.new()
		var accumulator := MatchMetricAccumulator.new()
		for range_base in bases:
			_simulate(competition, games, range_base, decomposition, terms, accumulator)

		var payload: Dictionary = decomposition.to_dictionary()
		payload.merge(terms.to_dictionary(), true)
		payload["competition"] = id
		payload["field_goal_percentage_half_width"] = (
			accumulator.field_goal_percentage_half_width())
		rows.append(payload)
		_report_competition(report, id, decomposition, terms, accumulator)

		var half_width: float = accumulator.field_goal_percentage_half_width()
		print("  %s: FG%% %.4f ±%.4f (%d/%d), PPP %.4f, %d violation(s), %d FG breach(es)" % [
			id, decomposition.totals.field_goal_percentage(), half_width,
			decomposition.totals.field_goals_made(),
			decomposition.totals.field_goals_attempted(),
			decomposition.totals.points_per_possession(),
			decomposition.violations.size(),
			decomposition.field_goal_identity_breaches().size()])
		for violation in decomposition.violations:
			printerr("  VIOLATION %s" % violation)
			failed = true
		for breach in decomposition.field_goal_identity_breaches():
			printerr("  FG IDENTITY BREACH %s: %s" % [id, breach])
			failed = true

	report.add_section(&"fg_decomposition", rows)
	report.finish()
	var status: int = ReportWriter.publish(report, "fg_decomposition_%s" % label)
	if failed:
		printerr("fg decomposition: an identity did not close; the decomposition is not usable")
		quit(1)
		return
	quit(status)


## Parses `--bases=A,B` into seed-range bases, refusing a repeated range.
##
## A duplicate would double-count one range's team-games into the pooled
## estimate and shrink its interval without adding a single new game, which is
## precisely the failure mode `PROJECT_STATUS.md` §5.21 records for pooling.
func _bases(raw: String) -> Array[int]:
	var bases: Array[int] = []
	for piece in raw.split(",", false):
		var trimmed: String = piece.strip_edges()
		if not trimmed.is_valid_int():
			printerr("ignoring non-integer seed base '%s'" % trimmed)
			continue
		var value: int = trimmed.to_int()
		if bases.has(value):
			printerr("seed base %d given twice; refusing to pool a range with itself" % value)
			continue
		bases.append(value)
	if bases.is_empty():
		printerr("no usable seed base; using %d" % DEFAULT_BASE)
		bases.append(DEFAULT_BASE)
	return bases


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


## Runs one competition with the shot-term probe attached.
##
## The probe is detached in every exit path, including the one where the loop
## body fails, so a later run in the same process can never inherit a sink
## belonging to an earlier competition.
func _simulate(
	competition: int,
	games: int,
	base: int,
	decomposition: PppDecomposition,
	terms: ShotTermAccumulator,
	accumulator: MatchMetricAccumulator,
) -> void:
	terms.attach()
	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		decomposition.accumulate(input, output)
		accumulator.accumulate(input, output)
		if (index + 1) % PROGRESS_EVERY == 0:
			print("    %d/%d games, FG%% so far %.4f" % [
				index + 1, games, decomposition.totals.field_goal_percentage()])
	ShotResolver.detach_probe()


func _report_competition(
	report: CalibrationReport,
	id: String,
	decomposition: PppDecomposition,
	terms: ShotTermAccumulator,
	accumulator: MatchMetricAccumulator,
) -> void:
	var totals: PppDecomposition.Totals = decomposition.totals

	# --- the identities, judged ---------------------------------------------
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.accounting.reconciled" % id),
		"Every identity closed: points, possessions, and the field-goal counts "
		+ "on the zone, contest-band, assisted-state and box-score axes.",
		decomposition.is_reconciled(), "ledger accounting identity", totals.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.accounting.unexplained_points" % id),
		"Ledger points not attributable to a two-point, three-point or "
		+ "free-throw term. Must be zero.",
		"points", float(decomposition.unexplained_points()), totals.games))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.accounting.field_goal_identities_hold" % id),
		"Zone attempts, contest-band attempts, assisted-state attempts and the "
		+ "box score all total the ledger's field-goal attempts, and likewise "
		+ "for makes.",
		decomposition.field_goal_identities_hold(),
		"field-goal accounting identity", totals.field_goals_attempted()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.accounting.field_goal_identity_breaches" % id),
		"Field-goal identity breaches found. Must be zero.",
		"breaches", float(decomposition.field_goal_identity_breaches().size()),
		totals.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.accounting.violations" % id),
		"Per-game reconciliation breaches found. Must be zero.",
		"breaches", float(decomposition.violations.size()), totals.games))

	# --- the headline, with the interval it must be read against ------------
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.fg.percentage" % id),
		"Field goals made divided by field goals attempted, from the ledger.",
		"field-goal attempts", totals.field_goal_percentage(),
		totals.field_goals_attempted())
		.with_interval(accumulator.field_goal_percentage_half_width()))
	_raw(report, id, "fg.made", "Made field goals.", "field goals",
		float(totals.field_goals_made()), totals.games)
	_raw(report, id, "fg.attempted", "Field-goal attempts.", "field goals",
		float(totals.field_goals_attempted()), totals.games)
	_raw(report, id, "fg.two_point_percentage", "Two-point percentage.",
		"two-point attempts", totals.two_point_percentage(), totals.two_point_attempted)
	_raw(report, id, "fg.two_point_made", "Made two-pointers.", "field goals",
		float(totals.two_point_made), totals.games)
	_raw(report, id, "fg.two_point_attempted", "Two-point attempts.", "field goals",
		float(totals.two_point_attempted), totals.games)
	_raw(report, id, "fg.three_point_percentage", "Three-point percentage.",
		"three-point attempts", totals.three_point_percentage(), totals.three_point_attempted)
	_raw(report, id, "fg.three_point_made", "Made three-pointers.", "field goals",
		float(totals.three_point_made), totals.games)
	_raw(report, id, "fg.three_point_attempted", "Three-point attempts.", "field goals",
		float(totals.three_point_attempted), totals.games)
	_raw(report, id, "fg.three_point_attempt_rate", "Three-point attempts over all attempts.",
		"field-goal attempts", totals.three_point_attempt_rate(), totals.field_goals_attempted())

	# --- points and the ppp terms they sum to -------------------------------
	_raw(report, id, "points.from_twos", "Points from two-pointers.", "points",
		float(totals.two_point_points()), totals.games)
	_raw(report, id, "points.from_threes", "Points from three-pointers.", "points",
		float(totals.three_point_points()), totals.games)
	_raw(report, id, "points.from_free_throws",
		"Points from free throws. A made free throw is worth one point by event "
		+ "type; the ledger's `points` field carries zero.",
		"points", float(totals.free_throw_points()), totals.games)
	_raw(report, id, "ppp.total", "Points per engine possession.", "engine possessions",
		totals.points_per_possession(), totals.possessions)
	_raw(report, id, "ppp.two_point", "Two-point contribution to points per possession.",
		"engine possessions", totals.two_point_ppp(), totals.possessions)
	_raw(report, id, "ppp.three_point", "Three-point contribution.", "engine possessions",
		totals.three_point_ppp(), totals.possessions)
	_raw(report, id, "ppp.free_throw", "Free-throw contribution.", "engine possessions",
		totals.free_throw_ppp(), totals.possessions)
	_raw(report, id, "possessions_per_game", "Engine possessions per game.", "games",
		totals.possessions_per_game(), totals.games)

	# --- the shot mix -------------------------------------------------------
	for zone in range(ShotZone.COUNT):
		var zone_name: String = ShotZone.IDS[zone]
		_raw(report, id, "zone.%s.share" % zone_name,
			"Share of field-goal attempts from this zone.", "field-goal attempts",
			totals.zone_share(zone), totals.field_goals_attempted())
		_raw(report, id, "zone.%s.percentage" % zone_name,
			"Accuracy within this zone.", "attempts in zone",
			totals.zone_percentage(zone), totals.zone_attempts[zone])
		_raw(report, id, "zone.%s.shooter_capability" % zone_name,
			"Mean shooter capability on attempts from this zone, read from "
			+ "ShotResolver.", "attempts in zone",
			terms.zone_capability(zone), terms.zone_shots[zone])
		_raw(report, id, "zone.%s.baseline" % zone_name,
			"Mean §13.1 open baseline for those shooters in this zone.",
			"attempts in zone", terms.zone_baseline(zone), terms.zone_shots[zone])

	# --- the contest distribution -------------------------------------------
	for band in range(ContestBand.COUNT):
		var band_name: String = ContestBand.IDS[band]
		_raw(report, id, "contest.%s.share" % band_name,
			"Share of field-goal attempts in this contest band.",
			"field-goal attempts", totals.contest_share(band), totals.field_goals_attempted())
		_raw(report, id, "contest.%s.percentage" % band_name,
			"Accuracy within this contest band.", "attempts in band",
			totals.contest_percentage(band), totals.contest_attempts[band])
		_raw(report, id, "contest.%s.defender_capability" % band_name,
			"Mean defender contest capability among attempts banded here.",
			"contests in band", terms.band_defender_capability(band), terms.band_contests[band])

	# --- creation -----------------------------------------------------------
	_raw(report, id, "creation.created_share",
		"Share of attempts carrying a recorded creator, taken from the attempt.",
		"field-goal attempts", totals.created_share(), totals.field_goals_attempted())
	_raw(report, id, "creation.created_percentage", "Accuracy on created attempts.",
		"created attempts", totals.created_percentage(), totals.created_attempts)
	_raw(report, id, "creation.uncreated_percentage", "Accuracy on uncreated attempts.",
		"uncreated attempts", totals.uncreated_percentage(), totals.uncreated_attempts)

	# --- the probability terms, from production ------------------------------
	_raw(report, id, "term.mean_shooter_capability",
		"Mean shooter capability over attempts that reached make resolution.",
		"unblocked attempts", terms.mean_shooter_capability(), terms.shots)
	_raw(report, id, "term.mean_defender_capability",
		"Mean primary-defender contest capability over all attempts.",
		"field-goal attempts", terms.mean_defender_capability(), terms.contests)
	_raw(report, id, "term.mean_pressure", "Mean §12.3 contest pressure.",
		"field-goal attempts", terms.mean_pressure(), terms.contests)
	_raw(report, id, "term.mean_contest_penalty",
		"Mean contest penalty applied, over all attempts.",
		"field-goal attempts", terms.mean_contest_penalty(), terms.contests)
	_raw(report, id, "term.mean_legal_contact",
		"Mean legal-contact share, the contact term feeding the shooting foul.",
		"field-goal attempts", terms.mean_legal_contact(), terms.contests)
	_raw(report, id, "term.mean_baseline",
		"Mean §13.1 open baseline before any penalty.",
		"unblocked attempts", terms.mean_baseline(), terms.shots)
	_raw(report, id, "term.mean_probability", "Mean realized make probability.",
		"unblocked attempts", terms.mean_probability(), terms.shots)
	_raw(report, id, "term.clamped_share",
		"Share of attempts whose probability was moved by a §13.2 floor or "
		+ "ceiling. A level routinely clamped is no longer described by the "
		+ "baseline curve.",
		"unblocked attempts", terms.clamped_share_value(), terms.shots)
	_raw(report, id, "term.residual",
		"Mean probability less the sum of the published terms. Non-zero only "
		+ "through the §13.2 clamp.",
		"unblocked attempts", terms.term_residual(), terms.shots)
	var means: Dictionary = terms.term_means()
	for key: String in means:
		var contribution: float = means[key]
		_raw(report, id, "term.%s" % key,
			"Mean signed contribution of this term to make probability.",
			"unblocked attempts", contribution, terms.shots)

	# --- the channels a correction must not travel through -------------------
	_raw(report, id, "control.block_rate", "Blocked attempts over field-goal attempts.",
		"field-goal attempts", totals.block_rate(), totals.field_goals_attempted())
	_raw(report, id, "control.shooting_foul_rate",
		"Shooting fouls over field-goal attempts.",
		"field-goal attempts", totals.shooting_foul_rate(), totals.field_goals_attempted())
	_raw(report, id, "control.turnovers", "Turnovers.", "possessions",
		float(totals.turnovers), totals.possessions)
	_raw(report, id, "control.turnover_rate", "Turnovers per possession.",
		"possessions", totals.turnover_rate(), totals.possessions)
	_raw(report, id, "control.offensive_rebound_extension_rate",
		"Share of possessions extended by an offensive rebound.",
		"possessions", totals.extension_rate(), totals.possessions)
	_raw(report, id, "control.free_throw_rate", "Free-throw attempts over field-goal attempts.",
		"field-goal attempts", totals.free_throw_rate(), totals.field_goals_attempted())
	_raw(report, id, "control.free_throw_percentage", "Free-throw percentage.",
		"free-throw attempts", totals.free_throw_percentage(), totals.free_throws_attempted)
	_raw(report, id, "control.assisted_share", "Assisted share of made field goals.",
		"made field goals", totals.assisted_share(), totals.field_goals_made())


func _raw(
	report: CalibrationReport,
	id: String,
	suffix: String,
	definition: String,
	denominator: String,
	value: float,
	sample: int,
) -> void:
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.%s" % [id, suffix]), definition, denominator, value, sample))
