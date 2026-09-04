class_name CalibrationMetric
extends RefCounted

## One measured quantity, its definition, its uncertainty, and its verdict.
##
## The brief requires every reported number to name its "exact metric definition
## and denominator" and to carry an "estimate, effect size, and confidence
## interval where applicable" plus a "pass/fail against the authoritative
## target". A metric that cannot state its denominator is a metric nobody can
## reproduce, so the field is required rather than optional.

enum Verdict {
	INFORMATIONAL, ## measured and reported; no authoritative target exists
	PASS,
	FAIL,
}

var metric_id: StringName
## Exact definition, including how the numerator and denominator are formed.
var definition: String
## What one unit of the denominator is.
var denominator: String
var estimate: float
## Half-width of the 95% interval; negative means "not applicable".
var interval_half_width: float
## Standardized effect size where two conditions are compared; NAN when unused.
var effect_size: float
var effect_size_kind: StringName
var sample_count: int
var target_minimum: float
var target_maximum: float
var target_source: String
var verdict: int
## The raw terms this estimate was derived from, so a sharded run can be
## recombined exactly rather than by averaging shard estimates. Metrics without
## one are reported by the aggregator as un-aggregatable.
var aggregation: MetricAggregation


static func raw(
	p_metric_id: StringName,
	p_definition: String,
	p_denominator: String,
	p_estimate: float,
	p_sample_count: int = 0,
) -> CalibrationMetric:
	var metric := CalibrationMetric.new()
	metric.metric_id = p_metric_id
	metric.definition = p_definition
	metric.denominator = p_denominator
	metric.estimate = p_estimate
	metric.interval_half_width = -1.0
	metric.effect_size = NAN
	metric.effect_size_kind = &""
	metric.sample_count = p_sample_count
	metric.target_minimum = NAN
	metric.target_maximum = NAN
	metric.target_source = ""
	metric.verdict = Verdict.INFORMATIONAL
	metric.aggregation = MetricAggregation.none()
	return metric


## A metric judged against an authoritative band. The verdict compares the
## point estimate with the band; the interval is reported beside it so a
## marginal pass is visible as marginal rather than presented as settled.
static func banded(
	p_metric_id: StringName,
	p_definition: String,
	p_denominator: String,
	p_estimate: float,
	band: CalibrationBand,
	p_sample_count: int,
	p_interval_half_width: float = -1.0,
) -> CalibrationMetric:
	var metric := raw(p_metric_id, p_definition, p_denominator, p_estimate, p_sample_count)
	metric.interval_half_width = p_interval_half_width
	metric.target_minimum = band.minimum
	metric.target_maximum = band.maximum
	metric.target_source = band.source
	metric.verdict = Verdict.PASS if band.contains(p_estimate) else Verdict.FAIL
	return metric


static func boolean(
	p_metric_id: StringName,
	p_definition: String,
	passed: bool,
	p_target_source: String,
	p_sample_count: int = 0,
) -> CalibrationMetric:
	var metric := raw(p_metric_id, p_definition, "boolean invariant", 1.0 if passed else 0.0, p_sample_count)
	metric.target_minimum = 1.0
	metric.target_maximum = 1.0
	metric.target_source = p_target_source
	metric.verdict = Verdict.PASS if passed else Verdict.FAIL
	return metric


func with_effect_size(value: float, kind: StringName) -> CalibrationMetric:
	effect_size = value
	effect_size_kind = kind
	return self


func with_interval(half_width: float) -> CalibrationMetric:
	interval_half_width = half_width
	return self


## Attaches the raw terms and rebuilds the estimate, interval, sample size, and
## verdict from them.
##
## Rebuilding rather than trusting the caller's estimate is deliberate: it means
## a single-shard report and a combined report are produced by the identical
## arithmetic, so the aggregation path is exercised on every ordinary run rather
## than only in CI.
func with_aggregation(value: MetricAggregation) -> CalibrationMetric:
	aggregation = value
	if not value.is_aggregatable():
		return self
	estimate = value.estimate()
	sample_count = value.effective_sample()
	var half_width: float = value.interval_half_width()
	if half_width >= 0.0:
		interval_half_width = half_width
	if verdict != Verdict.INFORMATIONAL:
		verdict = (
			Verdict.PASS
			if estimate >= target_minimum and estimate <= target_maximum
			else Verdict.FAIL
		)
	return self


func failed() -> bool:
	return verdict == Verdict.FAIL


func verdict_id() -> StringName:
	match verdict:
		Verdict.PASS:
			return &"pass"
		Verdict.FAIL:
			return &"fail"
		_:
			return &"informational"


func to_dictionary() -> Dictionary:
	var payload: Dictionary = {
		"metric": String(metric_id),
		"definition": definition,
		"denominator": denominator,
		"estimate": estimate,
		"sample_count": sample_count,
		"verdict": String(verdict_id()),
	}
	if interval_half_width >= 0.0:
		payload["interval_95"] = {
			"half_width": interval_half_width,
			"low": estimate - interval_half_width,
			"high": estimate + interval_half_width,
		}
	if not is_nan(effect_size):
		payload["effect_size"] = {"kind": String(effect_size_kind), "value": effect_size}
	if not is_nan(target_minimum) or not is_nan(target_maximum):
		payload["target"] = {
			"minimum": target_minimum,
			"maximum": target_maximum,
			"source": target_source,
		}
	if aggregation != null and aggregation.is_aggregatable():
		payload["aggregation"] = aggregation.to_dictionary()
	return payload


## Rebuilds a metric from an archived report, for the aggregator.
static func from_dictionary(payload: Dictionary) -> CalibrationMetric:
	var metric := CalibrationMetric.new()
	metric.metric_id = JsonRead.name_at(payload, "metric")
	metric.definition = JsonRead.string_at(payload, "definition")
	metric.denominator = JsonRead.string_at(payload, "denominator")
	metric.estimate = JsonRead.float_at(payload, "estimate")
	metric.sample_count = JsonRead.int_at(payload, "sample_count")
	metric.interval_half_width = -1.0
	metric.effect_size = NAN
	metric.effect_size_kind = &""
	metric.target_minimum = NAN
	metric.target_maximum = NAN
	metric.target_source = ""
	metric.verdict = Verdict.INFORMATIONAL
	metric.aggregation = MetricAggregation.from_dictionary(
		JsonRead.dictionary_at(payload, "aggregation"))

	var interval: Dictionary = JsonRead.dictionary_at(payload, "interval_95")
	if not interval.is_empty():
		metric.interval_half_width = JsonRead.float_at(interval, "half_width", -1.0)
	var target: Dictionary = JsonRead.dictionary_at(payload, "target")
	if not target.is_empty():
		metric.target_minimum = JsonRead.optional_float_at(target, "minimum")
		metric.target_maximum = JsonRead.optional_float_at(target, "maximum")
		metric.target_source = JsonRead.string_at(target, "source")
	var verdict_id: String = JsonRead.string_at(payload, "verdict", "informational")
	if verdict_id == "pass":
		metric.verdict = Verdict.PASS
	elif verdict_id == "fail":
		metric.verdict = Verdict.FAIL
	return metric


func describe() -> String:
	var text: String = "%-52s %12.4f" % [String(metric_id), estimate]
	if interval_half_width >= 0.0:
		text += " ±%.4f" % interval_half_width
	if not is_nan(target_minimum) and not is_nan(target_maximum):
		text += "  target[%.4f, %.4f]" % [target_minimum, target_maximum]
	if not is_nan(effect_size):
		text += "  %s=%.3f" % [String(effect_size_kind), effect_size]
	text += "  %s" % String(verdict_id()).to_upper()
	return text
