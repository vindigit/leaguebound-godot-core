extends SceneTree

## Regenerates the committed golden ledger hashes, and verifies that each
## scenario still exercises the behaviour it is named for.
##
## Run to regenerate after an intended engine or balance change:
##   godot --headless --path . --script res://tools/golden_ledger_harness.gd
##
## Regeneration is deliberately a separate, explicit action. A harness that
## rewrote the file as a side effect of running the suite would turn every
## golden test green forever, which is worse than having no golden test at all.
##
## `--dump=<scenario>` prints one scenario's whole serialized ledger and writes
## nothing. A changed golden hash says a scenario moved and says nothing about
## where; diffing two dumps says which event first differed, which is what a
## reviewer needs to accept or reject the change.
##   godot --headless --path . --script res://tools/golden_ledger_harness.gd -- \
##       --dump=regulation

const OUTPUT_PATH: String = "res://tests/golden/match_golden_hashes.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var dump: String = CalibrationCli.string_option(options, &"dump", "")
	if not dump.is_empty():
		_dump(StringName(dump))
		return
	_regenerate()


## One scenario's complete ledger, one event per line, for a first-divergence
## diff against the same scenario from an unmodified tree.
func _dump(scenario: StringName) -> void:
	if not GoldenScenarios.names().has(scenario):
		printerr("unknown golden scenario '%s'" % scenario)
		quit(2)
		return
	print(MatchLedgerSerializer.serialize_output(GoldenScenarios.simulate(scenario)))
	quit(0)


func _regenerate() -> void:
	var failures: PackedStringArray = []
	var records: Dictionary = {}
	var ordered: Array[String] = []
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		if not GoldenScenarios.meets_requirement(scenario, output):
			failures.append("scenario '%s' no longer produces %s" % [
				scenario, GoldenScenarios.describe_requirement(scenario)])
		var entry: Dictionary = {
			"seed": GoldenScenarios.seed_for(scenario),
			"hash": MatchLedgerSerializer.hash_output(output),
			"events": output.events.size(),
			"possessions": output.possessions.size(),
			"home_score": output.final_result.home_score,
			"away_score": output.final_result.away_score,
			"overtime_periods": output.final_result.overtime_periods,
		}
		records[String(scenario)] = entry
		ordered.append(String(scenario))
		print("%-22s seed=%-10d %s  %d-%d  events=%d" % [
			scenario, GoldenScenarios.seed_for(scenario), entry["hash"],
			output.final_result.home_score, output.final_result.away_score,
			output.events.size()])

	if not failures.is_empty():
		for failure in failures:
			printerr("SCENARIO: %s" % failure)
		printerr("Golden scenarios no longer cover what they claim; fix the fixture or the seed.")
		quit(1)
		return

	var document: Dictionary = {
		"version": String(MatchLedgerSerializer.HASH_VERSION),
		"scenarios": records,
		"order": ordered,
	}
	var file: FileAccess = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("unable to write %s" % OUTPUT_PATH)
		quit(1)
		return
	file.store_string("%s\n" % JSON.stringify(document, "\t", true))
	file.close()
	print("Wrote %d golden scenario hashes to %s" % [ordered.size(), OUTPUT_PATH])
	quit(0)
