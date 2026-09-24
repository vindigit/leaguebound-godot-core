extends SceneTree

## Career and NPC progression calibration (`BALANCE_SPEC.md` Â§8.4 OD-A, Â§6.3,
## Â§9.7, Â§31 report 7 and report 16).
##
## Measures, for a population of complete careers:
##
## - the peak current-Overall distribution per Â§8.4 outcome band;
## - the population share above 95 current Overall;
## - the continuity of the deliberate 72-74 gap;
## - projected-peak coverage, median width, and median signed bias (Â§6.3);
## - the lifetime AP-to-peak-Overall conversion Â§9.5 says is unmeasured;
## - user, full-detail NPC, and aggregate executor parity (Â§9.7).
##
## A career here runs the real `BuilderService`, `DevelopmentService`,
## `AttributeAllocator`, and `AgingResolver` â€” it is not a second progression
## model. Matches are not simulated: Â§9.6 makes game participation a source of
## seasonal AP, and the AP is what progression consumes.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_career_progression.gd -- \
##       [--careers=N] [--shard=I --shards=N] [--label=NAME]

const DEFAULT_CAREERS: int = 20000

## Float slack for the career-level AP identity. Grants are fractional, so the
## residual is rounding rather than a real leak below this.
const AP_RECONCILIATION_TOLERANCE: float = 0.001


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = maxi(1, CalibrationCli.int_option(options, &"shards", 1))
	var label: String = CalibrationCli.string_option(options, &"label", "career")

	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var configuration: PackedStringArray = profiles.validate()
	var context := ReportContext.create(
		&"career_progression",
		"Career and NPC progression calibration",
		null, null, SeededRandomSource.new(1).get_version())
	context.balance_profile_id = &"progression"
	context.balance_profile_version = profiles.progression.version
	context.sample_count = careers
	context.sample_unit = "complete player careers"
	context.set_shard(shard, shards, shard * careers + 1, shard * careers + careers)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_CAREERS, CalibrationTargets.sample_size_source())
	context.notes.append(
		"Â§27.1 certification sample is %d complete careers; this run used %d."
			% [CalibrationTargets.REQUIRED_CAREERS, careers])
	context.notes.append(
		"Matches are not simulated. Â§9.6 makes game participation a source of seasonal "
		+ "AP-equivalent opportunity; the AP is what progression consumes.")

	var report := CalibrationReport.new(context)
	report.add_metric(CalibrationMetric.boolean(
		&"configuration.valid",
		"Gate B0: the balance profile set validates offline.",
		configuration.is_empty(), "BALANCE_SPEC.md Â§30 Gate B0"))
	for failure in configuration:
		context.notes.append("configuration failure: %s" % failure)
	report.add_metric(CalibrationMetric.boolean(
		&"sample.meets_certification_size",
		"Whether this run reached the Â§27.1 sample size for a certifying progression report.",
		careers >= CalibrationTargets.REQUIRED_CAREERS,
		CalibrationTargets.sample_size_source(), careers))

	var simulator := CareerSimulator.new(profiles)
	var manual: Array = _run_population(
		simulator, careers, shard, DevelopmentExecutor.Value.MANUAL)
	_judge_population(report, manual, careers)

	# Â§9.7 parity: a matched cohort under the full-detail allocator and the
	# aggregate executor, at a reduced size because parity is a comparison of
	# distributions rather than a tail measurement.
	var parity_size: int = maxi(1, mini(careers, 4000))
	var full_detail: Array = _run_population(
		simulator, parity_size, shard, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)
	var aggregate: Array = _run_population(
		simulator, parity_size, shard, DevelopmentExecutor.Value.AGGREGATE)
	var manual_slice: Array = manual.slice(0, parity_size)
	_judge_parity(report, &"manual_vs_full_detail", manual_slice, full_detail)
	_judge_parity(report, &"manual_vs_aggregate", manual_slice, aggregate)

	report.finish()
	quit(ReportWriter.publish(report, "career_progression_%s" % label))


func _run_population(
	simulator: CareerSimulator,
	careers: int,
	shard: int,
	executor: int,
) -> Array:
	var results: Array = []
	var base: int = shard * careers
	for index in range(careers):
		results.append(simulator.simulate(base + index + 1, executor))
	return results


func _judge_population(report: CalibrationReport, results: Array, careers: int) -> void:
	var peaks_by_path: Array[PackedFloat64Array] = []
	for path in range(CareerSimulator.PATH_COUNT):
		peaks_by_path.append(PackedFloat64Array())
	var all_peaks := PackedFloat64Array()
	var coverage_hits: int = 0
	var widths := PackedFloat64Array()
	var signed_errors := PackedFloat64Array()
	var above_95: int = 0
	var in_transition_gap: int = 0
	var ap_totals := PackedFloat64Array()
	# Â§9.1 prices a rating increase by its destination, so "AP spent" and "rating
	# points gained" are different quantities that diverge further the higher a
	# career climbs. Both are carried, and the identity that ties them to the
	# grant is judged rather than assumed.
	var ap_spent := PackedFloat64Array()
	var ap_unspent := PackedFloat64Array()
	var rating_points := PackedFloat64Array()
	var unreconciled: int = 0
	var cap_attainment := PackedFloat64Array()
	var peak_ages := PackedFloat64Array()
	# Â§9.5's upper guardrail is a balance warning rather than a currency cap, and
	# a warning nobody counts is indistinguishable from no guardrail at all. The
	# report therefore carries both halves of Â§9.5's sentence: how often a season
	# was exceptional, and whether the source ledger explained why.
	var guardrail_seasons: int = 0
	var guardrail_unexplained: int = 0
	var career_seasons: int = 0
	var guardrail_excess := PackedFloat64Array()
	# Â§9.5 owner ruling 2026-08. An exceptional season is a warning; a career
	# whose whole pattern of them is not permitted is a defect, and that is what
	# is judged.
	var guardrail_overage := PackedFloat64Array()
	var opportunity_violations: int = 0
	var violation_examples: PackedStringArray = []

	for entry: CareerSimulator.CareerResult in results:
		var career: CareerSimulator.CareerResult = entry
		peaks_by_path[career.path].append(float(career.peak_overall))
		all_peaks.append(float(career.peak_overall))
		widths.append(float(career.projected_peak_width()))
		signed_errors.append(career.projected_peak_signed_error())
		peak_ages.append(float(career.peak_age))
		guardrail_seasons += career.guardrail_seasons
		guardrail_unexplained += career.guardrail_unexplained_seasons
		career_seasons += career.seasons
		guardrail_excess.append(career.guardrail_excess)
		guardrail_overage.append(career.guardrail_overage_share)
		if not career.opportunity_violation.is_empty():
			opportunity_violations += 1
			if violation_examples.size() < 3:
				violation_examples.append("seed %d: %s"
					% [career.seed_value, career.opportunity_violation])
		ap_totals.append(career.total_ap_granted)
		ap_spent.append(career.total_ap_spent)
		ap_unspent.append(career.total_ap_unspent)
		rating_points.append(float(career.total_rating_points_gained))
		if absf(career.total_ap_granted_by_ledger - career.total_ap_spent
				- career.total_ap_debited_without_purchase
				- career.total_ap_unspent) > AP_RECONCILIATION_TOLERANCE:
			unreconciled += 1
		cap_attainment.append(career.cap_attainment)
		if career.projected_peak_covers_realized():
			coverage_hits += 1
		if career.peak_overall > 95:
			above_95 += 1
		if career.peak_overall == 72 or career.peak_overall == 73:
			in_transition_gap += 1

	# --- Â§8.4 locked peak distribution --------------------------------------
	var rows: Array = []
	for path in range(CareerSimulator.PATH_COUNT):
		var peaks: PackedFloat64Array = peaks_by_path[path]
		if peaks.is_empty():
			continue
		var sorted: PackedFloat64Array = peaks.duplicate()
		sorted.sort()
		var median: float = CalibrationStatistics.percentile(sorted, 0.50)
		var id: StringName = CareerSimulator.path_id(path)
		# The §8.4 band is stated on the median, and a median cannot be pooled
		# from summed moments. Carrying the whole peak-Overall distribution as a
		# histogram lets the deep run recover the exact combined median instead
		# of averaging shard medians, which would not be a median of anything.
		report.add_metric(CalibrationMetric.banded(
			StringName("career_peak.%s.median" % id),
			"Median peak current Overall reached at any point in a complete career, "
			+ "for careers classified %s." % id,
			"complete careers", median,
			CalibrationTargets.career_peak_overall(path), peaks.size())
			.with_aggregation(MetricAggregation.histogram_of(peaks, 0.50)))
		rows.append({
			"outcome": String(id),
			"careers": peaks.size(),
			"share": float(peaks.size()) / float(results.size()),
			"peak_p10": CalibrationStatistics.percentile(sorted, 0.10),
			"peak_median": median,
			"peak_p90": CalibrationStatistics.percentile(sorted, 0.90),
			"peak_min": sorted[0],
			"peak_max": sorted[sorted.size() - 1],
		})
	report.add_section(&"career_peak_distribution", rows)

	report.add_metric(CalibrationMetric.banded(
		&"career_peak.share_above_95",
		"Share of complete careers whose peak current Overall exceeded 95. Â§8.4 "
		+ "requires 96+ to be practically nonexistent.",
		"complete careers", 0.0,
		CalibrationTargets.share_above_95_overall(), results.size())
		.with_aggregation(MetricAggregation.proportion(above_95, results.size())))
	report.add_metric(CalibrationMetric.banded(
		&"career_peak.transition_gap_share",
		"Share of careers peaking at 72 or 73. Â§8.4 wants a continuous "
		+ "distribution across the deliberate gap rather than a spike or a hole.",
		"complete careers", 0.0,
		CalibrationTargets.transition_band_share(), results.size())
		.with_aggregation(MetricAggregation.proportion(in_transition_gap, results.size())))

	# --- Â§6.3 projected-peak honesty ----------------------------------------
	report.add_metric(CalibrationMetric.banded(
		&"projected_peak.coverage",
		"Share of careers whose realized peak Overall fell inside the Projected "
		+ "Peak range displayed at the start of the career.",
		"complete careers", 0.0,
		CalibrationTargets.projected_peak_coverage(), results.size())
		.with_aggregation(MetricAggregation.proportion(coverage_hits, results.size())))
	var sorted_widths: PackedFloat64Array = widths.duplicate()
	sorted_widths.sort()
	report.add_metric(CalibrationMetric.banded(
		&"projected_peak.median_width",
		"Median width of the displayed Projected Peak range, in Overall points.",
		"complete careers", 0.0,
		CalibrationTargets.projected_peak_median_width(), results.size())
		.with_aggregation(MetricAggregation.histogram_of(widths, 0.50)))
	var sorted_errors: PackedFloat64Array = signed_errors.duplicate()
	sorted_errors.sort()
	report.add_metric(CalibrationMetric.banded(
		&"projected_peak.median_signed_error",
		"Median of realized peak minus the midpoint of the displayed range. "
		+ "Positive means the display was systematically pessimistic.",
		"complete careers", 0.0,
		CalibrationTargets.projected_peak_signed_bias(), results.size())
		.with_aggregation(MetricAggregation.histogram_of(signed_errors, 0.50)))

	# --- Â§9.5 lifetime conversion, previously unmeasured --------------------
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_lifetime_ap_granted",
		"Mean AP-equivalent granted across a complete career. Â§9.5 records this "
		+ "conversion as unmeasured; this is the measurement.",
		"complete careers", CalibrationStatistics.mean(ap_totals), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(ap_totals))
		.with_aggregation(MetricAggregation.mean_of(ap_totals)))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_lifetime_ap_spent",
		"Mean AP-equivalent a complete career consumed buying ratings, summed "
		+ "from the Â§9.1 costs the cost table charged.",
		"complete careers", CalibrationStatistics.mean(ap_spent), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(ap_spent))
		.with_aggregation(MetricAggregation.mean_of(ap_spent)))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_lifetime_ap_unspent",
		"Mean AP-equivalent still in the wallet when a career ended: opportunity "
		+ "granted, ledgered, and never converted into a rating point.",
		"complete careers", CalibrationStatistics.mean(ap_unspent), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(ap_unspent))
		.with_aggregation(MetricAggregation.mean_of(ap_unspent)))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_rating_points_gained",
		"Mean whole rating points a complete career gained. Reported beside AP "
		+ "spent because Â§9.1 prices a point by its destination, so the two "
		+ "diverge as a career climbs and neither substitutes for the other.",
		"complete careers", CalibrationStatistics.mean(rating_points), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(rating_points))
		.with_aggregation(MetricAggregation.mean_of(rating_points)))
	report.add_metric(CalibrationMetric.banded(
		&"progression.ap_reconciliation_failures",
		"Share of careers whose ledger does not satisfy granted - spent - "
		+ "non-purchase debits = unspent. Any failure means AP-equivalent "
		+ "entered or left the wallet without an entry to account for it.",
		"complete careers",
		float(unreconciled) / float(maxi(1, results.size())),
		CalibrationBand.new(0.0, 0.0, "BALANCE_SPEC.md Â§9.7.2"), results.size())
		.with_aggregation(MetricAggregation.proportion(unreconciled, results.size())))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_peak_overall",
		"Mean peak current Overall across the whole population.",
		"complete careers", CalibrationStatistics.mean(all_peaks), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(all_peaks)))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_cap_attainment",
		"Mean share of the player's own per-attribute caps actually filled.",
		"complete careers", CalibrationStatistics.mean(cap_attainment), results.size()))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_peak_age",
		"Mean age at which peak current Overall was reached.",
		"complete careers", CalibrationStatistics.mean(peak_ages), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(peak_ages)))

	# --- Â§9.5 upper-guardrail warnings --------------------------------------
	#
	# Â§9.5: "The upper guardrail is not a hard currency cap. It triggers a
	# balance warning and requires the source ledger to explain why the season
	# was exceptional." Both halves are reported, and only the second is judged:
	# an exceptional season is permitted, an unexplained one is not. Reporting
	# the share without judging it would let a model drift into treating the
	# guardrail as decorative; judging the share itself would turn a warning
	# into the hard cap Â§9.5 says it is not.
	report.add_metric(CalibrationMetric.raw(
		&"progression.guardrail_season_share",
		"Share of career-seasons whose granted total passed the Â§9.5 "
		+ "high-engagement upper guardrail for the phase.",
		"career seasons",
		float(guardrail_seasons) / float(maxi(1, career_seasons)), career_seasons)
		.with_aggregation(MetricAggregation.proportion(
			guardrail_seasons, maxi(1, career_seasons))))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_guardrail_excess_ap",
		"Mean AP-equivalent granted above the Â§9.5 guardrail across a complete "
		+ "career, summed over the seasons that passed it.",
		"complete careers", CalibrationStatistics.mean(guardrail_excess), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(guardrail_excess))
		.with_aggregation(MetricAggregation.mean_of(guardrail_excess)))
	report.add_metric(CalibrationMetric.banded(
		&"progression.guardrail_warnings_explained",
		"Share of guardrail-passing seasons whose source ledger names a grant, "
		+ "other than the generic offseason phase, explaining the excess.",
		"guardrail seasons",
		1.0 if guardrail_seasons == 0
			else float(guardrail_seasons - guardrail_unexplained) / float(guardrail_seasons),
		CalibrationBand.new(1.0, 1.0, "BALANCE_SPEC.md Â§9.5"),
		guardrail_seasons)
		.with_aggregation(MetricAggregation.proportion(
			guardrail_seasons - guardrail_unexplained, maxi(1, guardrail_seasons))))
	report.add_metric(CalibrationMetric.raw(
		&"progression.mean_guardrail_overage_share",
		"Mean share by which a career's lifetime grant exceeded the sum of its "
		+ "own Â§9.5 seasonal guardrails. Negative means the career stayed inside "
		+ "them; the Â§9.5 owner ruling bounds this at 20% and only for a career "
		+ "carrying the elite-opportunity condition.",
		"complete careers",
		CalibrationStatistics.mean(guardrail_overage), results.size())
		.with_interval(CalibrationStatistics.mean_interval_half_width(guardrail_overage))
		.with_aggregation(MetricAggregation.mean_of(guardrail_overage)))
	for example in violation_examples:
		report.context.notes.append("opportunity violation: %s" % example)
	report.add_metric(CalibrationMetric.banded(
		&"progression.opportunity_ruling_violations",
		"Share of careers whose pattern of exceptional seasons the Â§9.5 owner "
		+ "ruling does not permit: an excess without the elite-opportunity "
		+ "condition, an excess beyond the bounded share, or an exceptional "
		+ "season the source ledger never explained.",
		"complete careers",
		float(opportunity_violations) / float(maxi(1, results.size())),
		CalibrationBand.new(0.0, 0.0, "BALANCE_SPEC.md Â§9.5 (owner ruling 2026-08)"),
		results.size())
		.with_aggregation(MetricAggregation.proportion(
			opportunity_violations, results.size())))


## Â§9.7 / Â§27.2: the manual path and the NPC executors receive identical
## opportunity under identical rules, so their outcome distributions must be
## statistically indistinguishable.
func _judge_parity(
	report: CalibrationReport,
	pair: StringName,
	left: Array,
	right: Array,
) -> void:
	var left_peaks := PackedFloat64Array()
	var right_peaks := PackedFloat64Array()
	for entry: CareerSimulator.CareerResult in left:
		var career: CareerSimulator.CareerResult = entry
		left_peaks.append(float(career.peak_overall))
	for entry: CareerSimulator.CareerResult in right:
		var career: CareerSimulator.CareerResult = entry
		right_peaks.append(float(career.peak_overall))

	assert(left_peaks.size() == right_peaks.size(),
		"a parity cohort is matched; unequal sizes would make the pooled ratio wrong")
	var left_sum: float = 0.0
	var right_sum: float = 0.0
	for value in left_peaks:
		left_sum += value
	for value in right_peaks:
		right_sum += value
	var effect: float = CalibrationStatistics.cohens_d(left_peaks, right_peaks)
	# The parity tolerance in the spec is a *relative* figure, so the metric is
	# the relative difference and the band is the fixed two percent. Reporting an
	# absolute difference against a tolerance derived from the sample's own mean
	# gave every shard a different target, which the aggregator correctly refused
	# to combine: a target that moves with the sample is not a target.
	#
	# The relative difference of two matched cohorts is a ratio of two sums, so
	# it pools exactly across shards.
	var metric := CalibrationMetric.banded(
		StringName("parity.%s.relative_peak_difference" % pair),
		"Relative difference in mean peak current Overall between two executors "
		+ "given equivalent opportunity, as (right - left) / left. One development "
		+ "contract binds all three executors.",
		"complete careers", 0.0,
		CalibrationBand.new(
			-CalibrationTargets.PARITY_EVENT_RELATIVE,
			CalibrationTargets.PARITY_EVENT_RELATIVE,
			CalibrationTargets.parity_source()),
		left_peaks.size())
	report.add_metric(metric
		.with_aggregation(MetricAggregation.ratio(right_sum - left_sum, left_sum))
		.with_effect_size(effect, &"cohens_d"))
