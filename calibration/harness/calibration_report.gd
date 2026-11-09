class_name CalibrationReport
extends RefCounted

## A provenance block, an ordered list of metrics, and a verdict.
##
## The verdict is derived, never set: a report fails when any metric fails.
## There is no path for a runner to declare success over a failing metric, which
## is the property that makes the CI gate meaningful.

var context: ReportContext
var metrics: Array[CalibrationMetric]
## Free-form sub-tables (per-competition rows, per-attribute rows, tournament
## standings) that belong in the machine-readable artifact but are not
## themselves pass/fail metrics.
var sections: Dictionary


func _init(p_context: ReportContext = null) -> void:
	context = p_context
	metrics = []
	sections = {}


func add_metric(metric: CalibrationMetric) -> CalibrationMetric:
	metrics.append(metric)
	return metric


func add_section(name_value: StringName, payload: Variant) -> void:
	sections[String(name_value)] = payload


func finish() -> void:
	if context != null:
		context.finish()


func failures() -> Array[CalibrationMetric]:
	var failed: Array[CalibrationMetric] = []
	for metric in metrics:
		if metric.failed():
			failed.append(metric)
	return failed


func passed() -> bool:
	return failures().is_empty()


func judged_metric_count() -> int:
	var count: int = 0
	for metric in metrics:
		if metric.verdict != CalibrationMetric.Verdict.INFORMATIONAL:
			count += 1
	return count


func to_dictionary() -> Dictionary:
	var metric_payloads: Array = []
	for metric in metrics:
		metric_payloads.append(metric.to_dictionary())
	return {
		"schema": "leaguebound.calibration.report/1",
		"context": context.to_dictionary() if context != null else {},
		"summary": {
			"passed": passed(),
			"metric_count": metrics.size(),
			"judged_metric_count": judged_metric_count(),
			"failure_count": failures().size(),
		},
		"metrics": metric_payloads,
		"sections": sections,
	}
