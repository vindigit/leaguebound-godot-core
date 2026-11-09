extends SceneTree

## Pool two or more venue-diagnostic ranges over the union of their matched
## fixtures (`BALANCE_SPEC.md` §14.2 and §17.4, `SIMULATION_SPEC.md` §19.4).
##
## §5.20 §13 measured the venue effect on one range under
## `simulation-v8-contest-capability` and recorded, in terms, what one range
## cannot settle: "one range at 250 pairs per level cannot separate the
## development movement from range scatter". Settling it needs a second range
## and then the two read *together* — and "together" has exactly one correct
## meaning here.
##
## **Two published rates must not be averaged.** A report-level average weights
## by report rather than by fixture, so two ranges of unequal size silently
## reweight each other; it cannot form the pooled interval, because the pooled
## standard error is a property of the combined per-fixture series and not of
## two summary numbers; and it has no way to notice that the two ranges shared a
## fixture, which would count one piece of evidence twice. So this runner does
## not read the published rates at all. It reads the per-fixture paired
## observations the ranges emitted, replays them into `VenueEffectEstimator`,
## and pools with `merge` — the union of fixture keys, refusing an overlap.
## Every published figure is then recomputed by the same estimator that judged
## each range on its own, over one combined series, with weight 1 per fixture.
##
## Nothing here simulates a game. It is arithmetic on observations another run
## recorded, which is what makes it cheap enough to re-run and impossible for it
## to change a measurement by re-deriving one.
##
## **The reproduction check is the point of the per-range block.** Each source
## range is re-estimated here from its own emitted rows and compared against the
## figure that range's own report published. If a replayed range does not
## reproduce its source to 1e-9, the rows and the report disagree and the pooled
## number is not evidence about anything — so that is a judged metric and not a
## note.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_venue_pooled_estimate.gd -- \
##       --reports=PATH,PATH [--competition=development] [--label=NAME]

## Section the source reports carry their per-fixture observations in.
const PAIRED_SECTION: String = "venue_paired_fixtures"

## Section the source reports carry their own published estimates in, used for
## the reproduction check.
const ESTIMATOR_SECTION: String = "venue_effect_estimator"

const ARM_HOME: StringName = &"home"
const ARM_NEUTRAL: StringName = &"neutral"
const ARM_REVERSED: StringName = &"reversed"

## Tolerance for "the replay reproduced the source report". These are the same
## IEEE-754 doubles summed in the same order, so the difference is expected to
## be exactly zero; the tolerance exists so the check is about agreement rather
## than about bit patterns.
const REPRODUCTION_TOLERANCE: float = 1e-9


## One source range: where it came from, its replayed estimator, and what its
## own report said before the replay.
class SourceRange:
	extends RefCounted

	var label: String = ""
	var path: String = ""
	var estimator: VenueEffectEstimator = null
	## What the source report published, for the reproduction check. NAN when
	## the report carried no estimator row for this competition.
	var published_win_rate: float = NAN
	var published_points_per_100: float = NAN

	func reproduces() -> bool:
		if is_nan(published_win_rate) or is_nan(published_points_per_100):
			return false
		return (
			absf(estimator.venue_attributable_win_rate() - published_win_rate)
				<= REPRODUCTION_TOLERANCE
			and absf(estimator.points_per_100() - published_points_per_100)
				<= REPRODUCTION_TOLERANCE)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var report_list: String = CalibrationCli.string_option(options, &"reports", "")
	var competition: String = CalibrationCli.string_option(options, &"competition", "development")
	var label: String = CalibrationCli.string_option(options, &"label", "venue_pooled")
	if report_list.is_empty():
		printerr("--reports=PATH,PATH is required")
		quit(2)
		return

	var sources: Array[SourceRange] = []
	for path: String in report_list.split(",", false):
		var source: SourceRange = _load(path.strip_edges(), competition)
		if source == null:
			quit(2)
			return
		sources.append(source)
	if sources.size() < 2:
		printerr("pooling needs at least two source ranges; got %d" % sources.size())
		quit(2)
		return

	var context := ReportContext.create(
		&"venue_pooled_estimate",
		"Venue effect pooled over matched fixtures from multiple ranges",
		CompetitionCatalog.rules_for(_competition_index(competition)),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "matched fixtures pooled over ranges"
	context.competition_id = StringName(competition)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"BELOW CERTIFICATION REQUIREMENT. §27.1 asks for %d complete games per "
		% CalibrationTargets.REQUIRED_COMPETITION_GAMES
		+ "competition; pooling two 250-pair ranges reaches 1,500. This is "
		+ "measured evidence and certifies nothing.")
	context.notes.append(
		"Pooling is the UNION OF FIXTURE KEYS over the per-fixture paired "
		+ "observations, weight 1 per matched fixture. Published range rates are "
		+ "never averaged: an average weights by report, cannot form the pooled "
		+ "interval, and cannot detect a shared fixture.")
	context.notes.append(
		"No game was simulated by this runner. Every observation was recorded by "
		+ "the source runs and is replayed unchanged.")

	var report := CalibrationReport.new(context)
	var pooled := VenueEffectEstimator.new()
	var seed_low: int = -1
	var seed_high: int = -1

	for source: SourceRange in sources:
		_report_source(report, source)
		if not pooled.merge(source.estimator):
			printerr("pooling refused overlapping fixtures from %s" % source.path)
		for key: StringName in source.estimator.complete_keys():
			var variation: int = String(key).get_slice("/", 1).to_int()
			seed_low = variation if seed_low < 0 else mini(seed_low, variation)
			seed_high = maxi(seed_high, variation)
	context.set_shard(0, 1, seed_low, seed_high)
	context.sample_count = pooled.pair_count()

	# The union must be exactly the sum of the parts. If it is not, two ranges
	# shared a fixture and `merge` refused it — which is the estimator behaving
	# correctly and the *pooling* being wrong, so it is judged here.
	var expected_pairs: int = 0
	for source: SourceRange in sources:
		expected_pairs += source.estimator.pair_count()
	report.add_metric(CalibrationMetric.boolean(
		&"pool.ranges_disjoint",
		"No fixture key appeared in more than one source range, so the union "
		+ "carries every matched fixture exactly once and the pooled sample is "
		+ "the sum of the ranges rather than smaller than it.",
		pooled.pair_count() == expected_pairs
			and pooled.overlapping_keys().is_empty(),
		"calibration estimator contract", pooled.pair_count()))
	report.add_metric(CalibrationMetric.boolean(
		&"pool.every_range_reproduced",
		"Every source range, re-estimated here from its own emitted per-fixture "
		+ "rows, reproduced the figure its own report published. A range that "
		+ "does not reproduce means the rows and the report disagree and the "
		+ "pooled estimate is not evidence.",
		_all_reproduce(sources), "calibration estimator contract",
		pooled.pair_count()))

	_report_estimator(report, "pooled", pooled, expected_pairs)
	_report_difference(report, sources)

	var payloads: Array[Dictionary] = []
	for source: SourceRange in sources:
		var payload: Dictionary = source.estimator.to_dictionary()
		payload["range"] = source.label
		payload["source_report"] = source.path
		payload["published_venue_attributable_win_rate"] = source.published_win_rate
		payload["published_points_per_100"] = source.published_points_per_100
		payload["reproduces_source"] = source.reproduces()
		payloads.append(payload)
	var pooled_payload: Dictionary = pooled.to_dictionary()
	pooled_payload["range"] = "pooled"
	payloads.append(pooled_payload)
	report.add_section(&"pooled_ranges", payloads)
	report.add_section(&"venue_paired_fixtures", pooled.fixture_rows())
	report.finish()
	quit(ReportWriter.publish(report, "venue_pooled_estimate_%s" % label))


## Rebuilds one range's estimator from the per-fixture rows its report carries.
##
## The rows are the observations, not the estimate: replaying them means the
## pooled figure is computed by the same code that judged each range alone.
func _load(path: String, competition: String) -> SourceRange:
	if not FileAccess.file_exists(path):
		printerr("report not found: %s" % path)
		return null
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("report is not a JSON object: %s" % path)
		return null
	var payload: Dictionary = parsed
	var sections: Dictionary = JsonRead.dictionary_at(payload, "sections")
	var rows: Array = JsonRead.array_at(sections, PAIRED_SECTION)
	if rows.is_empty():
		printerr(
			"report %s carries no '%s' section; rerun the diagnostic with --emit-pairs"
			% [path, PAIRED_SECTION])
		return null

	var source := SourceRange.new()
	source.path = path
	source.estimator = VenueEffectEstimator.new()
	for row: Dictionary in rows:
		if JsonRead.string_at(row, "competition") != competition:
			continue
		if source.label.is_empty():
			source.label = JsonRead.string_at(row, "range", "unnamed")
		var key := StringName(JsonRead.string_at(row, "fixture"))
		for arm_id: StringName in [ARM_HOME, ARM_NEUTRAL, ARM_REVERSED]:
			if not source.estimator.observe(
				key, arm_id,
				JsonRead.float_at(row, "%s_margin" % String(arm_id)),
				JsonRead.float_at(row, "%s_possessions" % String(arm_id))):
				printerr("duplicate observation in %s: %s/%s" % [path, key, arm_id])
	if source.estimator.pair_count() == 0:
		printerr("report %s carries no '%s' fixtures" % [path, competition])
		return null

	for row: Dictionary in JsonRead.array_at(sections, ESTIMATOR_SECTION):
		if JsonRead.string_at(row, "competition") != competition:
			continue
		source.published_win_rate = JsonRead.optional_float_at(
			row, "venue_attributable_win_rate")
		source.published_points_per_100 = JsonRead.optional_float_at(row, "points_per_100")
	return source


func _all_reproduce(sources: Array[SourceRange]) -> bool:
	for source: SourceRange in sources:
		if not source.reproduces():
			return false
	return true


func _competition_index(competition: String) -> int:
	for index: int in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(index)) == competition:
			return index
	printerr("unknown competition '%s'; using the first" % competition)
	return 0


## One source range, republished from the replay, beside what it originally said.
func _report_source(report: CalibrationReport, source: SourceRange) -> void:
	var estimator: VenueEffectEstimator = source.estimator
	var pairs: int = estimator.pair_count()
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.venue.attributable_home_win_rate" % source.label),
		"JUDGED §14.2 metric for this range alone, recomputed from its emitted "
		+ "per-fixture observations.",
		"matched pairs", estimator.venue_attributable_win_rate(),
		CalibrationTargets.home_win_rate(), pairs
	).with_interval(estimator.venue_attributable_win_rate_half_width()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.points_per_100" % source.label),
		"Paired two-arm venue contribution for this range alone.",
		"points per 100 possessions", estimator.points_per_100(), pairs
	).with_interval(estimator.points_per_100_half_width()))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.replay_reproduces_source" % source.label),
		"Replaying this range's per-fixture rows reproduces the venue-attributable "
		+ "win rate and the points-per-100 its own report published, to 1e-9. "
		+ "Source: " + source.path,
		source.reproduces(), "calibration estimator contract", pairs))


## The between-range difference, with the uncertainty that says whether it is a
## difference at all.
##
## Two ranges are disjoint fixture sets, so their paired series are independent
## and the standard errors add in quadrature. Reported for the first two sources;
## a difference is a statement about a pair.
func _report_difference(report: CalibrationReport, sources: Array[SourceRange]) -> void:
	var first: VenueEffectEstimator = sources[0].estimator
	var second: VenueEffectEstimator = sources[1].estimator
	var difference: float = (
		first.venue_attributable_win_rate() - second.venue_attributable_win_rate())
	var first_error: float = VenueEffectEstimator.standard_error(first.paired_win_gain())
	var second_error: float = VenueEffectEstimator.standard_error(second.paired_win_gain())
	var combined_error: float = sqrt(
		first_error * first_error + second_error * second_error)
	report.add_metric(CalibrationMetric.raw(
		StringName("pool.%s_minus_%s" % [sources[0].label, sources[1].label]),
		"Difference in venue-attributable home win rate between the two ranges. "
		+ "The ranges are disjoint fixture sets, so the paired series are "
		+ "independent and their standard errors add in quadrature. An interval "
		+ "covering zero means the ranges are not distinguishable and the "
		+ "per-range spread is scatter.",
		"matched pairs", difference,
		first.pair_count() + second.pair_count()
	).with_interval(1.96 * combined_error))
	report.add_metric(CalibrationMetric.boolean(
		&"pool.ranges_agree",
		"The two ranges' venue-attributable win rates agree within the 95% "
		+ "interval of their difference. Disagreement would mean the effect "
		+ "depends on the seed range, which is a defect and not a result.",
		absf(difference) <= 1.96 * combined_error,
		"calibration estimator contract",
		first.pair_count() + second.pair_count()))


## The published venue package, identical in shape and metric naming to the
## per-range diagnostic so the pooled row can be read against a range row
## without translating between two vocabularies.
func _report_estimator(
	report: CalibrationReport,
	competition_id: String,
	estimator: VenueEffectEstimator,
	expected_pairs: int,
) -> void:
	var pairs: int = estimator.pair_count()

	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.raw_home_win_rate" % competition_id),
		"Share of decided games won by the venue side at the production "
		+ "environment, with nothing subtracted.",
		"decided games", estimator.raw_home_win_rate(), pairs))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.neutral_home_win_rate" % competition_id),
		"The same share on the identical fixtures with the environment at zero. "
		+ "The control: it should centre on 0.50.",
		"decided games", estimator.neutral_home_win_rate(), pairs))
	report.add_metric(CalibrationMetric.banded(
		StringName("%s.venue.attributable_home_win_rate" % competition_id),
		"JUDGED §14.2 metric. The controlled, symmetrized paired venue-side win "
		+ "rate: 0.5 x [P(venue side wins when the environment favours it) + "
		+ "P(opposite venue side wins when the environment is reversed)], "
		+ "computed per matched fixture over the pooled union. Weight 1 per "
		+ "matched pair; interval is 1.96 x SE of the pooled paired series.",
		"matched pairs", estimator.venue_attributable_win_rate(),
		CalibrationTargets.home_win_rate(), pairs
	).with_interval(estimator.venue_attributable_win_rate_half_width()))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.venue.canonical_form_agrees" % competition_id),
		"The paired-fixture estimator and the directly-computed canonical form "
		+ "0.5 x [P(home arm) + P(reversed arm)] return the same value over the "
		+ "pooled union.",
		absf(estimator.canonical_venue_win_rate()
			- estimator.venue_attributable_win_rate()) <= 1e-9,
		"owner ruling, §14.2 home-win estimator", pairs))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.paired_win_rate_change" % competition_id),
		"The venue-attributable change in win rate on its own, pooled over both "
		+ "venue arms.",
		"matched pairs",
		estimator.venue_attributable_win_rate() - VenueEffectEstimator.NEUTRAL_WIN_BASELINE,
		pairs).with_interval(estimator.venue_attributable_win_rate_half_width()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.paired_margin_difference" % competition_id),
		"The venue's effect on final margin with the roster, the matchup and "
		+ "the seed cancelled, pooled over both venue arms.",
		"matched pairs", estimator.paired_margin_difference(), pairs
	).with_interval(estimator.paired_margin_half_width()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.points_per_100" % competition_id),
		"Venue-attributable points per 100 possessions: the paired two-arm "
		+ "margin gain over the possession base taken across the arms. **This "
		+ "is the figure §17.4 caps at +2.5.**",
		"points per 100 possessions", estimator.points_per_100(), pairs
	).with_interval(estimator.points_per_100_half_width()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.home_arm_points_per_100" % competition_id),
		"The single-arm reading, published for comparison. §17.4 is NOT judged "
		+ "on this figure.",
		"points per 100 possessions", estimator.home_arm_points_per_100(), pairs))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.venue.cap_respected" % competition_id),
		"The paired two-arm venue contribution is at or below the §17.4 "
		+ "combined cap of +2.5 points per 100 possessions.",
		estimator.cap_respected(), "BALANCE_SPEC.md §17.4", pairs))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.venue.reversal_agrees" % competition_id),
		"The home arm and the venue-reversed arm estimate the same environment "
		+ "effect within their combined intervals.",
		estimator.venue_reversal_agrees(), "SIMULATION_SPEC.md §19.4", pairs))

	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.matched_pairs" % competition_id),
		"Independent matched fixtures behind every paired figure above. This is "
		+ "the sample size.",
		"matched pairs", float(pairs), pairs))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.complete_games" % competition_id),
		"Complete games behind those pairs, which is three per pair. Three "
		+ "simulations of one fixture are one piece of independent evidence, and "
		+ "this figure is NOT the sample size.",
		"complete games", float(estimator.unique_games()), pairs))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.venue.sample_well_formed" % competition_id),
		"Every fixture offered carries all three arms, nothing was observed "
		+ "twice, and no range overlapped another.",
		estimator.is_well_formed(), "calibration estimator contract", pairs))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.venue.sample_complete" % competition_id),
		"The pooled estimator holds every matched pair its sources carried.",
		pairs == expected_pairs, "calibration estimator contract", pairs))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.venue.certification_sample_reached" % competition_id),
		"Share of §27.1's certifying sample this pool reached, against %d "
		% CalibrationTargets.REQUIRED_COMPETITION_GAMES
		+ "complete games per competition. Zero point something is not "
		+ "certification. Source: " + CalibrationTargets.sample_size_source(),
		"complete games",
		(
			float(estimator.unique_games())
			/ float(maxi(CalibrationTargets.REQUIRED_COMPETITION_GAMES, 1))
		),
		pairs))
