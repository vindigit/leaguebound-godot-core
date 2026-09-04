class_name ReportAggregationSuite
extends RefCounted

## Synthetic-shard tests for `ReportAggregator`.
##
## The fixtures are built in memory rather than read from disk so the cases can
## express things a real run would struggle to produce on demand — a duplicated
## shard index, a seed interval that overlaps its neighbour, a metric whose
## definition changed between shards.
##
## The most important case is `_pooling_is_not_averaging`. It builds two shards
## whose denominators differ by an order of magnitude, so the pooled proportion
## and the mean of the two shard proportions are far apart. Any implementation
## that averaged shard estimates would pass every other test here and fail that
## one.

const TOLERANCE: float = 0.000001


static func run() -> PackedStringArray:
	var failures := PackedStringArray()
	_pooling_is_not_averaging(failures)
	_pools_means_from_raw_moments(failures)
	_accepts_a_complete_disjoint_shard_set(failures)
	_rejects_a_missing_shard(failures)
	_rejects_a_duplicate_shard(failures)
	_rejects_overlapping_seed_intervals(failures)
	_rejects_a_profile_version_mismatch(failures)
	_rejects_a_changed_metric_definition(failures)
	_rejects_a_metric_absent_from_one_shard(failures)
	_reports_uncertified_when_the_sample_falls_short(failures)
	return failures


# --- cases -------------------------------------------------------------------

## Pooled proportions must weight by their own denominators.
##
## Shard 0 made 5 of 10; shard 1 made 900 of 1,000. The mean of the two rates is
## 0.70. The pooled rate is 905/1010 = 0.8960. Only the pooled value is a
## percentage of anything.
static func _pooling_is_not_averaging(failures: PackedStringArray) -> void:
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 10, 10, [_proportion_metric(5, 10)]),
		_shard(1, 2, 11, 1010, 1000, [_proportion_metric(900, 1000)]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(
		shards, &"synthetic", 2)
	if not result.ok():
		failures.append("pooling: a valid shard set was rejected: %s"
			% ", ".join(result.rejections))
		return
	var metric: CalibrationMetric = _metric_named(result.report, &"synthetic.rate")
	if metric == null:
		failures.append("pooling: the combined report has no synthetic.rate metric")
		return
	var expected: float = 905.0 / 1010.0
	if absf(metric.estimate - expected) > TOLERANCE:
		failures.append("pooling: expected pooled %.6f, got %.6f (mean of shards is 0.70)"
			% [expected, metric.estimate])
	if absf(metric.aggregation.numerator - 905.0) > TOLERANCE:
		failures.append("pooling: numerator did not sum to 905, got %.1f"
			% metric.aggregation.numerator)
	if absf(metric.aggregation.denominator - 1010.0) > TOLERANCE:
		failures.append("pooling: denominator did not sum to 1010, got %.1f"
			% metric.aggregation.denominator)
	if metric.sample_count != 1010:
		failures.append("pooling: effective sample was %d, expected 1010" % metric.sample_count)


## A pooled mean and its interval must come from summed moments, so the combined
## figure equals the mean of the concatenated observations exactly.
static func _pools_means_from_raw_moments(failures: PackedStringArray) -> void:
	var left := PackedFloat64Array([10.0, 12.0, 14.0])
	var right := PackedFloat64Array([100.0, 102.0])
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 3, 3, [_mean_metric(left)]),
		_shard(1, 2, 4, 5, 2, [_mean_metric(right)]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 2)
	if not result.ok():
		failures.append("mean pooling: valid shards rejected: %s" % ", ".join(result.rejections))
		return
	var metric: CalibrationMetric = _metric_named(result.report, &"synthetic.mean")
	if metric == null:
		failures.append("mean pooling: no synthetic.mean metric in the combined report")
		return
	var all := PackedFloat64Array([10.0, 12.0, 14.0, 100.0, 102.0])
	var expected: float = CalibrationStatistics.mean(all)
	if absf(metric.estimate - expected) > TOLERANCE:
		failures.append("mean pooling: expected %.6f, got %.6f" % [expected, metric.estimate])
	var expected_half: float = CalibrationStatistics.mean_interval_half_width(all)
	if absf(metric.interval_half_width - expected_half) > 0.0001:
		failures.append("mean pooling: interval half-width %.6f, expected %.6f"
			% [metric.interval_half_width, expected_half])


static func _accepts_a_complete_disjoint_shard_set(failures: PackedStringArray) -> void:
	var shards: Array[Dictionary] = []
	for index in range(4):
		shards.append(_shard(
			index, 4, index * 100 + 1, index * 100 + 100, 100,
			[_proportion_metric(45, 100)]))
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 4)
	if not result.ok():
		failures.append("complete set: rejected: %s" % ", ".join(result.rejections))
		return
	if result.shards_accepted != 4:
		failures.append("complete set: accepted %d shards, expected 4" % result.shards_accepted)
	if result.combined_sample != 400:
		failures.append("complete set: combined sample %d, expected 400" % result.combined_sample)
	if not result.certified:
		failures.append("complete set: a passing, sufficient sample was not certified")


static func _rejects_a_missing_shard(failures: PackedStringArray) -> void:
	var shards: Array[Dictionary] = [
		_shard(0, 3, 1, 100, 100, [_proportion_metric(45, 100)]),
		_shard(2, 3, 201, 300, 100, [_proportion_metric(45, 100)]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 3)
	_expect_rejection(failures, result, "missing shard 1", "missing shard")
	if result.certified:
		failures.append("missing shard: an incomplete set was certified")


static func _rejects_a_duplicate_shard(failures: PackedStringArray) -> void:
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 100, 100, [_proportion_metric(45, 100)]),
		_shard(0, 2, 101, 200, 100, [_proportion_metric(45, 100)]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 2)
	_expect_rejection(failures, result, "duplicate shard index", "duplicate shard")


static func _rejects_overlapping_seed_intervals(failures: PackedStringArray) -> void:
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 150, 100, [_proportion_metric(45, 100)]),
		_shard(1, 2, 100, 200, 100, [_proportion_metric(45, 100)]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 2)
	_expect_rejection(failures, result, "overlapping seed intervals", "overlapping seed")


static func _rejects_a_profile_version_mismatch(failures: PackedStringArray) -> void:
	var first: Dictionary = _shard(0, 2, 1, 100, 100, [_proportion_metric(45, 100)])
	var second: Dictionary = _shard(1, 2, 101, 200, 100, [_proportion_metric(45, 100)])
	var context: Dictionary = second["context"]
	var balance: Dictionary = context["balance_profile"]
	balance["version"] = "simulation-v9-different"
	context["balance_profile"] = balance
	second["context"] = context
	var result: ReportAggregator.Result = ReportAggregator.aggregate(
		[first, second] as Array[Dictionary], &"synthetic", 2)
	_expect_rejection(failures, result, "balance version mismatch", "identity does not match")


static func _rejects_a_changed_metric_definition(failures: PackedStringArray) -> void:
	var changed: Dictionary = _proportion_metric(45, 100)
	changed["definition"] = "a different definition entirely"
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 100, 100, [_proportion_metric(45, 100)]),
		_shard(1, 2, 101, 200, 100, [changed]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 2)
	_expect_rejection(failures, result, "changed metric definition", "different definitions")


static func _rejects_a_metric_absent_from_one_shard(failures: PackedStringArray) -> void:
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 100, 100, [_proportion_metric(45, 100), _mean_metric(
			PackedFloat64Array([1.0, 2.0]))]),
		_shard(1, 2, 101, 200, 100, [_proportion_metric(45, 100)]),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 2)
	_expect_rejection(failures, result, "metric absent from a shard", "appears in")


## Aggregating cleanly is not the same as certifying. A valid combination whose
## sample falls short must say so.
static func _reports_uncertified_when_the_sample_falls_short(
	failures: PackedStringArray,
) -> void:
	var shards: Array[Dictionary] = [
		_shard(0, 2, 1, 10, 10, [_proportion_metric(5, 10)], 100000),
		_shard(1, 2, 11, 20, 10, [_proportion_metric(5, 10)], 100000),
	]
	var result: ReportAggregator.Result = ReportAggregator.aggregate(shards, &"synthetic", 2)
	if not result.ok():
		failures.append("short sample: a valid set was rejected: %s"
			% ", ".join(result.rejections))
		return
	if result.certified:
		failures.append("short sample: 20 samples against a 100,000 requirement was certified")
	var metric: CalibrationMetric = _metric_named(
		result.report, &"certification.sample_reached")
	if metric == null or metric.verdict != CalibrationMetric.Verdict.FAIL:
		failures.append("short sample: certification.sample_reached did not fail")


# --- fixture builders --------------------------------------------------------

static func _shard(
	shard_index: int,
	shard_count: int,
	seed_start: int,
	seed_end: int,
	sample_count: int,
	metrics: Array,
	required_sample: int = 100,
) -> Dictionary:
	return {
		"schema": "leaguebound.calibration.report/1",
		"context": {
			"report_id": "synthetic",
			"title": "Synthetic shard",
			"commit_sha": "0123456789abcdef",
			"commit_note": "",
			"godot_version": "4.7.1-stable",
			"build_mode": "release (asserts stripped)",
			"rules_profile": {"id": "top_domestic_pro", "version": "competition-v1"},
			"balance_profile": {"id": "simulation_baseline", "version": "simulation-v2"},
			"ratings_profile_version": "ratings-v1",
			"targets_version": "calibration-targets-v1",
			"rng": {"algorithm": "godot-pcg32-v1", "stream_key_version": "sha256-stream-key-v1"},
			"seeds": "shard %d" % shard_index,
			"seed_range": {"start": seed_start, "end": seed_end},
			"shard": {"index": shard_index, "count": shard_count},
			"competition": "top_domestic_pro",
			"certification": {
				"required_sample": required_sample,
				"source": "BALANCE_SPEC.md §27.1",
			},
			"sample_count": sample_count,
			"sample_unit": "complete games",
			"elapsed_ms": 1000,
			"throughput_per_second": 1.0,
			"notes": [],
		},
		"summary": {
			"passed": true, "metric_count": metrics.size(),
			"judged_metric_count": metrics.size(), "failure_count": 0,
		},
		"metrics": metrics,
		"sections": {},
	}


static func _proportion_metric(successes: int, trials: int) -> Dictionary:
	return {
		"metric": "synthetic.rate",
		"definition": "A synthetic proportion.",
		"denominator": "trials",
		"estimate": 0.0 if trials <= 0 else float(successes) / float(trials),
		"sample_count": trials,
		"verdict": "pass",
		"target": {"minimum": 0.0, "maximum": 1.0, "source": "synthetic"},
		"aggregation": MetricAggregation.proportion(successes, trials).to_dictionary(),
	}


static func _mean_metric(values: PackedFloat64Array) -> Dictionary:
	var aggregation: MetricAggregation = MetricAggregation.mean_of(values)
	return {
		"metric": "synthetic.mean",
		"definition": "A synthetic mean.",
		"denominator": "observations",
		"estimate": aggregation.estimate(),
		"sample_count": values.size(),
		"verdict": "informational",
		"aggregation": aggregation.to_dictionary(),
	}


# --- helpers -----------------------------------------------------------------

static func _metric_named(report: CalibrationReport, metric_id: StringName) -> CalibrationMetric:
	for metric in report.metrics:
		if metric.metric_id == metric_id:
			return metric
	return null


static func _expect_rejection(
	failures: PackedStringArray,
	result: ReportAggregator.Result,
	case_name: String,
	fragment: String,
) -> void:
	if result.ok():
		failures.append("%s: the aggregator accepted an invalid shard set" % case_name)
		return
	for rejection in result.rejections:
		if rejection.findn(fragment) >= 0:
			return
	failures.append("%s: rejected, but no rejection mentioned '%s'; got: %s"
		% [case_name, fragment, ", ".join(result.rejections)])
