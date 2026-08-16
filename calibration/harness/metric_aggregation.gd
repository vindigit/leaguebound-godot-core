class_name MetricAggregation
extends RefCounted

## The raw terms behind a metric, carried so shards can be recombined exactly.
##
## A sharded report cannot be certified by averaging its shards' estimates. A
## shard that resolved 900 attempts and a shard that resolved 1,100 do not
## contribute equally to a league shooting percentage, and a mean of two rounded
## percentages is not a percentage of anything. The aggregator therefore never
## sees an estimate it did not recompute: every metric carries the counts it was
## derived from, the aggregator sums those, and the estimate, the interval, and
## the verdict are all built again from the combined totals.
##
## Five kinds cover everything the suites report:
##
## - `PROPORTION` â€” a count of successes out of a count of trials. Combines by
##   summing both; the interval is Wilson, which is what Â§27.2 names.
## - `RATIO` â€” a sum over a sum, where the two are not successes and trials
##   (points over possessions, turnovers over possessions times one hundred).
##   Combines by summing both. It has no binomial interval, and reports none.
## - `MEAN` â€” a per-unit mean carried as count, sum, and sum of squares, so the
##   combined standard deviation is exact rather than approximated from shard
##   standard deviations.
## - `CONSTANT` â€” a value that must be identical in every shard (a target, a
##   documented goal). Combining is an identity check, not arithmetic.
##
## A metric with no aggregation payload cannot be combined. The aggregator
## reports it as un-aggregatable rather than guessing.

enum Kind {
	NONE,
	PROPORTION,
	RATIO,
	MEAN,
	CONSTANT,
	HISTOGRAM,
}

const KIND_IDS: PackedStringArray = [
	"none", "proportion", "ratio", "mean", "constant", "histogram",
]

## The histogram domain. It spans the negative range as well as the positive
## because some pooled percentiles are signed: the projected-peak bias is a
## realized-minus-predicted difference and is routinely negative.
const HISTOGRAM_MINIMUM: int = -120
const HISTOGRAM_MAXIMUM: int = 120

var kind: int = Kind.NONE
## PROPORTION: successes. RATIO: the numerator sum.
var numerator: float = 0.0
## PROPORTION: trials. RATIO: the denominator sum.
var denominator: float = 0.0
## MEAN: number of observations.
var count: int = 0
## MEAN: sum of the observations.
var sum: float = 0.0
## MEAN: sum of the squared observations.
var sum_of_squares: float = 0.0
## A fixed multiplier applied after the division, for rates stated per hundred.
var scale: float = 1.0
## HISTOGRAM: counts per integer bucket, indexed from `HISTOGRAM_MINIMUM`.
##
## A median is a percentile, and percentiles are not recoverable from summed
## moments â€” pooling shard medians is the same mistake as averaging shard rates.
## The Â§8.4 bands are stated on the median peak Overall, so without an exact
## pooling path the deep progression run could never certify the one target it
## exists to check. Overall is a bounded integer, so the whole distribution fits
## in a small count vector that pools by addition and yields the exact combined
## percentile.
var buckets: PackedInt32Array = PackedInt32Array()
## The percentile this metric reports from its histogram, on the unit interval.
var percentile_share: float = 0.5


static func none() -> MetricAggregation:
	return MetricAggregation.new()


static func proportion(successes: int, trials: int) -> MetricAggregation:
	var aggregation := MetricAggregation.new()
	aggregation.kind = Kind.PROPORTION
	aggregation.numerator = float(successes)
	aggregation.denominator = float(trials)
	return aggregation


static func ratio(
	numerator_sum: float,
	denominator_sum: float,
	p_scale: float = 1.0,
) -> MetricAggregation:
	var aggregation := MetricAggregation.new()
	aggregation.kind = Kind.RATIO
	aggregation.numerator = numerator_sum
	aggregation.denominator = denominator_sum
	aggregation.scale = p_scale
	return aggregation


## Builds the mean terms from the observations themselves, so the caller cannot
## accidentally supply a sum of squares that does not match its sum.
static func mean_of(values: PackedFloat64Array) -> MetricAggregation:
	var aggregation := MetricAggregation.new()
	aggregation.kind = Kind.MEAN
	aggregation.count = values.size()
	for value in values:
		aggregation.sum += value
		aggregation.sum_of_squares += value * value
	return aggregation


## A percentile over a bounded integer domain, carried as the whole
## distribution so shards pool exactly.
static func histogram_of(
	values: PackedFloat64Array,
	p_percentile_share: float = 0.5,
) -> MetricAggregation:
	var aggregation := MetricAggregation.new()
	aggregation.kind = Kind.HISTOGRAM
	aggregation.percentile_share = p_percentile_share
	aggregation.buckets = PackedInt32Array()
	aggregation.buckets.resize(HISTOGRAM_MAXIMUM - HISTOGRAM_MINIMUM + 1)
	aggregation.buckets.fill(0)
	for value in values:
		var bucket: int = clampi(
			int(roundf(value)) - HISTOGRAM_MINIMUM, 0, aggregation.buckets.size() - 1)
		aggregation.buckets[bucket] += 1
		aggregation.count += 1
		aggregation.sum += value
		aggregation.sum_of_squares += value * value
	return aggregation


static func constant(value: float) -> MetricAggregation:
	var aggregation := MetricAggregation.new()
	aggregation.kind = Kind.CONSTANT
	aggregation.sum = value
	aggregation.count = 1
	return aggregation


static func kind_id(value: int) -> StringName:
	return StringName(KIND_IDS[value])


static func kind_from_id(id_value: String) -> int:
	for index in range(KIND_IDS.size()):
		if KIND_IDS[index] == id_value:
			return index
	return Kind.NONE


func is_aggregatable() -> bool:
	return kind != Kind.NONE


## Folds another shard's terms into this one. Both must be the same kind and,
## for a rate stated per hundred, the same scale.
func combine(other: MetricAggregation) -> void:
	assert(kind == other.kind, "cannot combine metric aggregations of different kinds")
	assert(is_equal_approx(scale, other.scale), "cannot combine rates with different scales")
	match kind:
		Kind.PROPORTION, Kind.RATIO:
			numerator += other.numerator
			denominator += other.denominator
		Kind.MEAN:
			count += other.count
			sum += other.sum
			sum_of_squares += other.sum_of_squares
		Kind.HISTOGRAM:
			assert(buckets.size() == other.buckets.size(),
				"histogram domains must match before pooling")
			for index in range(buckets.size()):
				buckets[index] += other.buckets[index]
			count += other.count
			sum += other.sum
			sum_of_squares += other.sum_of_squares
		Kind.CONSTANT:
			# A constant is identical by contract; the aggregator checks that
			# before calling here, so folding is a no-op rather than a sum.
			pass
		_:
			assert(false, "an un-aggregatable metric cannot be combined")


## The estimate implied by the combined terms. This is the only place a sharded
## estimate is produced, which is what makes "never average shard means" true by
## construction rather than by review.
func estimate() -> float:
	match kind:
		Kind.PROPORTION, Kind.RATIO:
			return 0.0 if denominator <= 0.0 else scale * numerator / denominator
		Kind.MEAN:
			return 0.0 if count <= 0 else sum / float(count)
		Kind.HISTOGRAM:
			return _percentile_from_buckets()
		Kind.CONSTANT:
			return sum
		_:
			return 0.0


## The exact percentile of the pooled distribution. Walking the cumulative
## counts gives the same answer the concatenated observations would.
func _percentile_from_buckets() -> float:
	if count <= 0:
		return 0.0
	var target: float = clampf(percentile_share, 0.0, 1.0) * float(count)
	var cumulative: int = 0
	for index in range(buckets.size()):
		cumulative += buckets[index]
		if float(cumulative) >= target:
			return float(index + HISTOGRAM_MINIMUM)
	return float(buckets.size() - 1 + HISTOGRAM_MINIMUM)


## The sample size the combined metric rests on, in its own denominator's units.
func effective_sample() -> int:
	match kind:
		Kind.PROPORTION, Kind.RATIO:
			return int(roundf(denominator))
		Kind.MEAN, Kind.HISTOGRAM:
			return count
		_:
			return 0


## Half-width of the 95% interval, or -1 when the kind does not support one.
##
## A RATIO of two sums has no interval here: without the per-unit pairs the
## variance is not recoverable, and inventing one would be worse than reporting
## none. Runners that need an interval on a rate publish it as a MEAN over the
## per-unit values instead.
func interval_half_width() -> float:
	match kind:
		Kind.PROPORTION:
			if denominator <= 0.0:
				return -1.0
			var bounds: PackedFloat64Array = CalibrationStatistics.wilson_interval(
				int(roundf(numerator)), int(roundf(denominator)))
			return (bounds[1] - bounds[0]) / 2.0
		Kind.MEAN, Kind.HISTOGRAM:
			if count < 2:
				return -1.0
			var mean_value: float = sum / float(count)
			var variance: float = (
				(sum_of_squares - float(count) * mean_value * mean_value)
				/ float(count - 1))
			if variance <= 0.0:
				return 0.0
			return CalibrationStatistics.Z_95 * sqrt(variance) / sqrt(float(count))
		_:
			return -1.0


func duplicate_aggregation() -> MetricAggregation:
	var copy := MetricAggregation.new()
	copy.kind = kind
	copy.numerator = numerator
	copy.denominator = denominator
	copy.count = count
	copy.sum = sum
	copy.sum_of_squares = sum_of_squares
	copy.scale = scale
	copy.buckets = buckets.duplicate()
	copy.percentile_share = percentile_share
	return copy


func to_dictionary() -> Dictionary:
	return {
		"kind": String(kind_id(kind)),
		"numerator": numerator,
		"denominator": denominator,
		"count": count,
		"sum": sum,
		"sum_of_squares": sum_of_squares,
		"scale": scale,
		"buckets": buckets,
		"percentile_share": percentile_share,
	}


static func from_dictionary(payload: Dictionary) -> MetricAggregation:
	var aggregation := MetricAggregation.new()
	if payload.is_empty():
		return aggregation
	aggregation.kind = kind_from_id(JsonRead.string_at(payload, "kind", "none"))
	aggregation.numerator = JsonRead.float_at(payload, "numerator")
	aggregation.denominator = JsonRead.float_at(payload, "denominator")
	aggregation.count = JsonRead.int_at(payload, "count")
	aggregation.sum = JsonRead.float_at(payload, "sum")
	aggregation.sum_of_squares = JsonRead.float_at(payload, "sum_of_squares")
	aggregation.scale = JsonRead.float_at(payload, "scale", 1.0)
	aggregation.percentile_share = JsonRead.float_at(payload, "percentile_share", 0.5)
	aggregation.buckets = PackedInt32Array()
	for bucket: Variant in JsonRead.array_at(payload, "buckets"):
		var stored: float = 0.0
		if typeof(bucket) == TYPE_INT or typeof(bucket) == TYPE_FLOAT:
			stored = bucket
		aggregation.buckets.append(int(roundf(stored)))
	return aggregation
