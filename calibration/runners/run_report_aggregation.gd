extends SceneTree

## Combines sharded calibration reports into one certification report.
##
## This is the job the deep-verification workflow was missing: it launched
## independent shards and never joined them, so nothing in CI ever produced a
## report resting on a §27.1 sample.
##
## The exit code is the gate. A missing shard, a duplicate shard, an overlapping
## seed interval, a profile-version mismatch, or a metric that changed
## definition between shards all fail the job. A run that aggregates cleanly but
## falls short of the required sample exits non-zero as well, because a
## certification job that passes without certifying anything is worse than no
## job at all.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_report_aggregation.gd -- \
##       --report=competition_calibration [--directory=res://reports] [--shards=N] \
##       [--label=NAME] [--allow-uncertified]

const DEFAULT_DIRECTORY: String = "res://reports"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var report_id := StringName(CalibrationCli.string_option(options, &"report", ""))
	var directory: String = CalibrationCli.string_option(
		options, &"directory", DEFAULT_DIRECTORY)
	var shards: int = CalibrationCli.int_option(options, &"shards", 0)
	var label: String = CalibrationCli.string_option(options, &"label", String(report_id))
	var allow_uncertified: bool = CalibrationCli.bool_option(
		options, &"allow-uncertified", false)

	if report_id.is_empty():
		printerr("--report=<report_id> is required")
		quit(2)
		return

	var result: ReportAggregator.Result = ReportAggregator.aggregate_directory(
		directory, report_id, shards)

	print("")
	print("=== Shard aggregation: %s ===" % report_id)
	print("  shards accepted: %d of %d expected" % [
		result.shards_accepted, result.shards_expected])
	print("  combined sample: %d" % result.combined_sample)
	for warning in result.warnings:
		print("  warning: %s" % warning)
	for rejection in result.rejections:
		printerr("  REJECTED: %s" % rejection)

	var path: String = ReportWriter.write(result.report, "certification_%s" % label)
	var summary_code: int = ReportWriter.summarize(result.report, path)

	if not result.ok():
		printerr("  aggregation rejected; nothing certified.")
		quit(1)
		return
	if not result.certified:
		if allow_uncertified:
			print("  aggregated cleanly but NOT certified; --allow-uncertified was set.")
			quit(0)
			return
		printerr("  aggregated cleanly but NOT certified: sample or verdicts fell short.")
		quit(1)
		return
	print("  CERTIFIED: combined sample met its requirement and every metric passed.")
	quit(summary_code)
