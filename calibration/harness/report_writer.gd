class_name ReportWriter
extends RefCounted

## Writes the machine-readable artifact and prints the human summary.
##
## Both are required by the brief: "Archive machine-readable reports as CI
## artifacts and provide a concise human-readable summary." The JSON is the
## artifact CI uploads; the printed block is what a person reads in the log
## without downloading anything.

const REPORT_DIRECTORY: String = "res://reports"


static func write(report: CalibrationReport, file_stem: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	var path: String = "%s/%s.json" % [REPORT_DIRECTORY, file_stem]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("unable to write calibration report to %s" % path)
		return ""
	file.store_string(JSON.stringify(report.to_dictionary(), "  ", false))
	file.close()
	return path


## Prints the provenance line, every metric, and the verdict. Returns the
## process exit code the runner should use.
static func summarize(report: CalibrationReport, path: String) -> int:
	print("")
	print("=== %s ===" % report.context.title)
	print("  %s" % report.context.describe())
	if not report.context.notes.is_empty():
		for note in report.context.notes:
			print("  note: %s" % note)
	print("")
	for metric in report.metrics:
		print("  %s" % metric.describe())
	print("")
	if not path.is_empty():
		print("  report: %s" % path)
	var failed: Array[CalibrationMetric] = report.failures()
	if failed.is_empty():
		print("  %d metric(s), %d judged, 0 failures: PASS" % [
			report.metrics.size(), report.judged_metric_count()])
		return 0
	for metric in failed:
		printerr("  FAIL %s: estimate %.4f outside %s target [%.4f, %.4f]" % [
			String(metric.metric_id), metric.estimate, metric.target_source,
			metric.target_minimum, metric.target_maximum])
	printerr("  %d metric(s), %d judged, %d failure(s): FAIL" % [
		report.metrics.size(), report.judged_metric_count(), failed.size()])
	return 1


## Convenience: write, summarize, and return the exit code.
static func publish(report: CalibrationReport, file_stem: String) -> int:
	var path: String = write(report, file_stem)
	return summarize(report, path)
