class_name CalibrationStatistics
extends RefCounted

## Estimators, intervals, and effect sizes for the calibration reports.
##
## `BALANCE_SPEC.md` §27.2 is explicit that "statistical significance without a
## meaningful effect is insufficient" and that every report carries an effect
## size and an interval. This class is the only place those are computed, so a
## runner cannot quietly publish a point estimate with no uncertainty attached.


## Normal quantile for a 95% two-sided interval.
const Z_95: float = 1.959964


static func mean(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


## Sample standard deviation (Bessel-corrected).
static func standard_deviation(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	var average: float = mean(values)
	var total: float = 0.0
	for value in values:
		var delta: float = value - average
		total += delta * delta
	return sqrt(total / float(values.size() - 1))


static func percentile(sorted_values: PackedFloat64Array, share: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var bounded: float = clampf(share, 0.0, 1.0)
	var position: float = bounded * float(sorted_values.size() - 1)
	var low: int = floori(position)
	var high: int = ceili(position)
	if low == high:
		return sorted_values[low]
	return lerpf(sorted_values[low], sorted_values[high], position - float(low))


## Half-width of the 95% confidence interval on a mean.
static func mean_interval_half_width(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	return Z_95 * standard_deviation(values) / sqrt(float(values.size()))


## Wilson score interval on a proportion. `BALANCE_SPEC.md` §27.2 names Wilson
## explicitly for the rare-event bands; using it everywhere keeps one estimator.
static func wilson_interval(successes: int, trials: int) -> PackedFloat64Array:
	if trials <= 0:
		return PackedFloat64Array([0.0, 0.0])
	var n: float = float(trials)
	var p: float = float(successes) / n
	var z2: float = Z_95 * Z_95
	var denominator: float = 1.0 + z2 / n
	var centre: float = (p + z2 / (2.0 * n)) / denominator
	var spread: float = (
		Z_95 * sqrt(p * (1.0 - p) / n + z2 / (4.0 * n * n)) / denominator)
	return PackedFloat64Array([maxf(0.0, centre - spread), minf(1.0, centre + spread)])


## Cohen's d for two independent samples with pooled standard deviation.
static func cohens_d(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	if left.size() < 2 or right.size() < 2:
		return 0.0
	var left_sd: float = standard_deviation(left)
	var right_sd: float = standard_deviation(right)
	var left_n: float = float(left.size())
	var right_n: float = float(right.size())
	var pooled_variance: float = (
		((left_n - 1.0) * left_sd * left_sd + (right_n - 1.0) * right_sd * right_sd)
		/ (left_n + right_n - 2.0))
	if pooled_variance <= 0.0:
		return 0.0
	return (mean(right) - mean(left)) / sqrt(pooled_variance)


## Half-width of the 95% interval on a difference of two independent means.
static func difference_interval_half_width(
	left: PackedFloat64Array,
	right: PackedFloat64Array,
) -> float:
	if left.size() < 2 or right.size() < 2:
		return 0.0
	var left_sd: float = standard_deviation(left)
	var right_sd: float = standard_deviation(right)
	var variance: float = (
		left_sd * left_sd / float(left.size()) + right_sd * right_sd / float(right.size()))
	return Z_95 * sqrt(variance)


## Half-width of the 95% interval on a difference of two proportions.
static func proportion_difference_half_width(
	left_successes: int,
	left_trials: int,
	right_successes: int,
	right_trials: int,
) -> float:
	if left_trials <= 0 or right_trials <= 0:
		return 0.0
	var left_p: float = float(left_successes) / float(left_trials)
	var right_p: float = float(right_successes) / float(right_trials)
	var variance: float = (
		left_p * (1.0 - left_p) / float(left_trials)
		+ right_p * (1.0 - right_p) / float(right_trials))
	return Z_95 * sqrt(maxf(variance, 0.0))


## Spearman rank correlation, used by the OVR truthfulness suite where the
## relationship is expected to be monotone but not linear.
static func spearman(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	if left.size() != right.size() or left.size() < 3:
		return 0.0
	var left_ranks: PackedFloat64Array = _ranks(left)
	var right_ranks: PackedFloat64Array = _ranks(right)
	return pearson(left_ranks, right_ranks)


static func pearson(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	if left.size() != right.size() or left.size() < 2:
		return 0.0
	var left_mean: float = mean(left)
	var right_mean: float = mean(right)
	var covariance: float = 0.0
	var left_variance: float = 0.0
	var right_variance: float = 0.0
	for index in range(left.size()):
		var left_delta: float = left[index] - left_mean
		var right_delta: float = right[index] - right_mean
		covariance += left_delta * right_delta
		left_variance += left_delta * left_delta
		right_variance += right_delta * right_delta
	if left_variance <= 0.0 or right_variance <= 0.0:
		return 0.0
	return covariance / sqrt(left_variance * right_variance)


## Average ranks with ties resolved to their mean rank.
static func _ranks(values: PackedFloat64Array) -> PackedFloat64Array:
	var order: Array[int] = []
	for index in range(values.size()):
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return values[a] < values[b])
	var ranks: PackedFloat64Array = PackedFloat64Array()
	ranks.resize(values.size())
	var position: int = 0
	while position < order.size():
		var last: int = position
		while last + 1 < order.size() and values[order[last + 1]] == values[order[position]]:
			last += 1
		var average_rank: float = float(position + last) / 2.0 + 1.0
		for index in range(position, last + 1):
			ranks[order[index]] = average_rank
		position = last + 1
	return ranks
