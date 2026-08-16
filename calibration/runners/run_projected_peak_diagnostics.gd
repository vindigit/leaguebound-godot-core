extends SceneTree

## Projected Peak error decomposition (`BALANCE_SPEC.md` §6.3, §32 report 7).
##
## The pooled progression run reports the *symptom*: coverage far below the
## locked 70-85% band and a large positive median signed error, meaning the
## displayed range sits systematically below the realized peak. A symptom does
## not identify a cause, and §6.3 rule 5 makes projected-peak honesty an
## acceptance requirement rather than a presentation preference — so the fix has
## to be the model, not an offset applied to its output.
##
## This runner splits the total signed error into the two independent halves the
## model is actually made of:
##
##   total  = realized_peak - midpoint(displayed range)
##   budget = model_overall(true lifetime AP) - midpoint(displayed range)
##   conversion = realized_peak - model_overall(true lifetime AP)
##
## `model_overall(true lifetime AP)` is the projection's own AP-to-Overall
## conversion asked the counterfactual question "what would you have predicted
## had you known the real budget?". If `budget` carries the error, the model
## credits the career the wrong amount of opportunity. If `conversion` carries
## it, the model turns opportunity into Overall wrongly. The two have different
## fixes and the aggregate signed error cannot tell them apart.
##
## The counterfactual lives here, in the calibration layer, and is never
## available to `ProjectedPeakCalculator`: §28 makes a projection that reads
## realized career data a release blocker, and a forecast that consults the
## outcome is not a forecast.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_projected_peak_diagnostics.gd -- \
##       [--careers=N] [--shard=I --shards=N] [--label=NAME]

const DEFAULT_CAREERS: int = 1200

## Starting-Overall buckets for the subgroup table. A model that is honest on
## average but wrong at one end of the build distribution has a hidden failure,
## and §6.3 coverage stated only as a population share would conceal it.
const STARTING_OVERALL_EDGES: PackedInt32Array = [46, 48, 50]
const MAX_POTENTIAL_EDGES: PackedInt32Array = [72, 80, 86]


## One subgroup's accumulated observations. A typed record rather than a
## dictionary so the counts stay integers under warnings-as-errors.
class Subgroup extends RefCounted:
	var careers: int = 0
	var covered: int = 0
	var errors := PackedFloat64Array()
	var peaks := PackedFloat64Array()
	var widths := PackedFloat64Array()
	## §8.4 asks whether a band misses because the ceiling forbids it or because
	## the career never reaches the ceiling it has. Carrying both answers the
	## question the median peak alone cannot.
	var potentials := PackedFloat64Array()
	var attainment := PackedFloat64Array()
	var starts := PackedFloat64Array()
	var ap := PackedFloat64Array()

	func add(career: CareerSimulator.CareerResult, signed_error: float) -> void:
		careers += 1
		if career.projected_peak_covers_realized():
			covered += 1
		errors.append(signed_error)
		peaks.append(float(career.peak_overall))
		widths.append(float(career.projected_peak_width()))
		potentials.append(float(career.maximum_potential))
		attainment.append(career.cap_attainment)
		starts.append(float(career.starting_overall))
		ap.append(career.total_ap_granted)

	func coverage() -> float:
		return float(covered) / float(maxi(1, careers))


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = maxi(1, CalibrationCli.int_option(options, &"shards", 1))
	var label: String = CalibrationCli.string_option(options, &"label", "diagnostic")

	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var context := ReportContext.create(
		&"projected_peak_diagnostics",
		"Projected Peak error decomposition",
		null, null, SeededRandomSource.new(1).get_version())
	context.balance_profile_id = &"progression"
	context.balance_profile_version = profiles.progression.version
	context.sample_count = careers
	context.sample_unit = "complete player careers"
	context.set_shard(shard, shards, shard * careers + 1, shard * careers + careers)
	context.notes.append(
		"Diagnostic report. It measures why the §6.3 projected-peak metrics miss; "
		+ "the metrics themselves are judged by the career-progression report.")

	var report := CalibrationReport.new(context)
	var simulator := CareerSimulator.new(profiles)
	simulator.capture_diagnostics = true

	var rows: Array = []
	var total_error := PackedFloat64Array()
	var budget_error := PackedFloat64Array()
	var conversion_error := PackedFloat64Array()
	var clamp_effect := PackedFloat64Array()
	var ap_ratio_to_high := PackedFloat64Array()
	var realized_ap := PackedFloat64Array()
	var projected_ap_mid := PackedFloat64Array()
	var horizon_shortfall := PackedFloat64Array()
	var coverage_hits: int = 0

	var by_path: Dictionary = {}
	var by_prospect: Dictionary = {}
	var by_family: Dictionary = {}
	var by_maturity: Dictionary = {}
	var by_start: Dictionary = {}
	var by_potential: Dictionary = {}

	var base: int = shard * careers
	for index in range(careers):
		var career: CareerSimulator.CareerResult = simulator.simulate(
			base + index + 1, DevelopmentExecutor.Value.MANUAL)
		var midpoint: float = float(
			career.projected_peak_low + career.projected_peak_high) / 2.0

		# The model's own conversion, asked what it would have said with the true
		# budget. Unclamped, so the decomposition measures the conversion rather
		# than the ordering rules that bound it afterwards.
		var oracle: int = ProjectedPeakCalculator.overall_after_spending(
			career.starting_values, career.starting_caps,
			int(floorf(career.total_ap_granted)), profiles.ratings, profiles.progression)

		var total: float = float(career.peak_overall) - midpoint
		var budget: float = float(oracle) - midpoint
		var conversion: float = float(career.peak_overall) - float(oracle)

		# How much the [current, maximum-potential] clamp and the width guardrail
		# moved the displayed high bound away from the raw model estimate.
		var raw_high: int = ProjectedPeakCalculator.overall_after_spending(
			career.starting_values, career.starting_caps,
			int(floorf(career.projected_ap_high)), profiles.ratings, profiles.progression)
		clamp_effect.append(float(career.projected_peak_high) - float(raw_high))

		total_error.append(total)
		budget_error.append(budget)
		conversion_error.append(conversion)
		realized_ap.append(career.total_ap_granted)
		projected_ap_mid.append((career.projected_ap_low + career.projected_ap_high) / 2.0)
		if career.projected_ap_high > 0.0:
			ap_ratio_to_high.append(career.total_ap_granted / career.projected_ap_high)
		horizon_shortfall.append(float(career.peak_age)
			- float(profiles.progression.expected_peak_age[career.prospect]))
		if career.projected_peak_covers_realized():
			coverage_hits += 1

		_accumulate(by_path, CareerSimulator.path_id(career.path), career, total)
		_accumulate(by_prospect, ProspectProfile.id_of(career.prospect), career, total)
		_accumulate(by_family, PositionFamily.id_of(career.family), career, total)
		_accumulate(by_maturity, MaturityProfile.id_of(career.maturity), career, total)
		_accumulate(by_start, _bucket_id("start", career.starting_overall,
			STARTING_OVERALL_EDGES), career, total)
		_accumulate(by_potential, _bucket_id("potential", career.maximum_potential,
			MAX_POTENTIAL_EDGES), career, total)

	# --- headline decomposition ------------------------------------------------
	_add_median(report, &"diagnostic.total_signed_error", total_error,
		"Median realized peak minus displayed range midpoint. This is the §6.3 "
		+ "signed-error metric, repeated here so the two halves below sum to it.")
	_add_median(report, &"diagnostic.budget_signed_error", budget_error,
		"Median of the model's own conversion given the true lifetime AP, minus "
		+ "the displayed midpoint. Error attributable to crediting the wrong "
		+ "amount of opportunity.")
	_add_median(report, &"diagnostic.conversion_signed_error", conversion_error,
		"Median realized peak minus the model's conversion given the true "
		+ "lifetime AP. Error attributable to turning opportunity into Overall.")
	_add_median(report, &"diagnostic.clamp_effect_on_high_bound", clamp_effect,
		"Median displayed high bound minus the raw model high bound. Shows how "
		+ "much the ordering rules and the width guardrail move the range.")
	_add_median(report, &"diagnostic.peak_age_minus_expected", horizon_shortfall,
		"Median realized peak age minus the model's expected peak age. The model "
		+ "stops accruing opportunity at the expected age, so a positive value is "
		+ "opportunity the model never counted.")

	report.add_metric(CalibrationMetric.raw(
		&"diagnostic.mean_realized_lifetime_ap",
		"Mean AP-equivalent actually granted across a complete career.",
		"complete careers", CalibrationStatistics.mean(realized_ap), careers)
		.with_aggregation(MetricAggregation.mean_of(realized_ap)))
	report.add_metric(CalibrationMetric.raw(
		&"diagnostic.mean_projected_lifetime_ap",
		"Mean of the midpoint of the AP interval the projection credited to the "
		+ "remaining career at creation.",
		"complete careers", CalibrationStatistics.mean(projected_ap_mid), careers)
		.with_aggregation(MetricAggregation.mean_of(projected_ap_mid)))
	report.add_metric(CalibrationMetric.raw(
		&"diagnostic.realized_ap_over_projected_high",
		"Mean ratio of realized lifetime AP to the projection's own upper AP "
		+ "bound. A value above 1.0 means careers routinely exceed the most "
		+ "opportunity the model was willing to imagine.",
		"complete careers", CalibrationStatistics.mean(ap_ratio_to_high), careers)
		.with_aggregation(MetricAggregation.mean_of(ap_ratio_to_high)))
	report.add_metric(CalibrationMetric.banded(
		&"diagnostic.coverage",
		"Share of careers whose realized peak fell inside the displayed range.",
		"complete careers", 0.0,
		CalibrationTargets.projected_peak_coverage(), careers)
		.with_aggregation(MetricAggregation.proportion(coverage_hits, careers)))

	report.add_section(&"error_by_path", _rows_of(by_path))
	report.add_section(&"error_by_prospect", _rows_of(by_prospect))
	report.add_section(&"error_by_position_family", _rows_of(by_family))
	report.add_section(&"error_by_maturity", _rows_of(by_maturity))
	report.add_section(&"error_by_starting_overall", _rows_of(by_start))
	report.add_section(&"error_by_maximum_potential", _rows_of(by_potential))
	report.add_section(&"career_rows", rows)

	report.finish()
	_print_subgroups("path", by_path)
	_print_subgroups("prospect", by_prospect)
	_print_subgroups("starting overall", by_start)
	_print_subgroups("maximum potential", by_potential)
	# A diagnostic never gates: it exists to explain a failure, not to add one.
	ReportWriter.publish(report, "projected_peak_diagnostics_%s" % label)
	quit(0)


func _add_median(
	report: CalibrationReport,
	metric_id: StringName,
	values: PackedFloat64Array,
	definition: String,
) -> void:
	report.add_metric(CalibrationMetric.raw(
		metric_id, definition, "complete careers", 0.0, values.size())
		.with_aggregation(MetricAggregation.histogram_of(values, 0.50)))


func _accumulate(
	buckets: Dictionary,
	key: StringName,
	career: CareerSimulator.CareerResult,
	total: float,
) -> void:
	var id_value: String = String(key)
	if not buckets.has(id_value):
		buckets[id_value] = Subgroup.new()
	var bucket: Subgroup = buckets[id_value]
	bucket.add(career, total)


func _rows_of(buckets: Dictionary) -> Array:
	var rows: Array = []
	var keys: PackedStringArray = _sorted_keys(buckets)
	for key: String in keys:
		var bucket: Subgroup = buckets[key]
		var errors: PackedFloat64Array = bucket.errors.duplicate()
		errors.sort()
		var widths: PackedFloat64Array = bucket.widths.duplicate()
		widths.sort()
		var peaks: PackedFloat64Array = bucket.peaks.duplicate()
		peaks.sort()
		var potentials: PackedFloat64Array = bucket.potentials.duplicate()
		potentials.sort()
		rows.append({
			"group": key,
			"careers": bucket.careers,
			"coverage": bucket.coverage(),
			"median_signed_error": CalibrationStatistics.percentile(errors, 0.50),
			"p10_signed_error": CalibrationStatistics.percentile(errors, 0.10),
			"p90_signed_error": CalibrationStatistics.percentile(errors, 0.90),
			"median_width": CalibrationStatistics.percentile(widths, 0.50),
			"median_peak": CalibrationStatistics.percentile(peaks, 0.50),
			"p90_peak": CalibrationStatistics.percentile(peaks, 0.90),
			"median_maximum_potential": CalibrationStatistics.percentile(potentials, 0.50),
			"mean_cap_attainment": CalibrationStatistics.mean(bucket.attainment),
			"mean_starting_overall": CalibrationStatistics.mean(bucket.starts),
			"mean_lifetime_ap": CalibrationStatistics.mean(bucket.ap),
		})
	return rows


func _print_subgroups(title: String, buckets: Dictionary) -> void:
	print("")
	print("  --- by %s ---" % title)
	var keys: PackedStringArray = _sorted_keys(buckets)
	for key: String in keys:
		var bucket: Subgroup = buckets[key]
		var errors: PackedFloat64Array = bucket.errors.duplicate()
		errors.sort()
		var widths: PackedFloat64Array = bucket.widths.duplicate()
		widths.sort()
		var peaks: PackedFloat64Array = bucket.peaks.duplicate()
		peaks.sort()
		var potentials: PackedFloat64Array = bucket.potentials.duplicate()
		potentials.sort()
		print("  %-22s n=%-5d cover=%.3f err=%+.1f w=%.0f peak=%.0f/p90 %.0f maxpot=%.0f attain=%.3f ap=%.0f" % [
			key, bucket.careers, bucket.coverage(),
			CalibrationStatistics.percentile(errors, 0.50),
			CalibrationStatistics.percentile(widths, 0.50),
			CalibrationStatistics.percentile(peaks, 0.50),
			CalibrationStatistics.percentile(peaks, 0.90),
			CalibrationStatistics.percentile(potentials, 0.50),
			CalibrationStatistics.mean(bucket.attainment),
			CalibrationStatistics.mean(bucket.ap)])


## Dictionary keys as a sorted typed array, so the subgroup tables iterate under
## warnings-as-errors without a Variant round-trip.
func _sorted_keys(buckets: Dictionary) -> PackedStringArray:
	var keys := PackedStringArray()
	for key: Variant in buckets.keys():
		keys.append(str(key))
	keys.sort()
	return keys


func _bucket_id(prefix: String, value: int, edges: PackedInt32Array) -> StringName:
	for index in range(edges.size()):
		if value < edges[index]:
			return StringName("%s_below_%d" % [prefix, edges[index]])
	return StringName("%s_%d_plus" % [prefix, edges[edges.size() - 1]])
