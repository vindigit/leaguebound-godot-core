extends SceneTree

## Finds a seed at which each golden scenario still exercises the behaviour it
## is named for.
##
## `GoldenScenarios` deliberately verifies that a scenario still *contains* its
## behaviour, so a balance change that stops producing overtime fails rather
## than leaving a golden hash that passes while covering nothing. That check is
## only useful if re-deriving a seed is a command rather than an afternoon of
## guessing, which is what this tool is.
##
## It changes nothing on disk. It prints the seeds; updating `GoldenScenarios`
## and regenerating the hashes stays a deliberate edit, because a golden change
## requires an explicit engine or balance version change and review.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/find_scenario_seeds.gd -- \
##       [--scenario=NAME] [--limit=N]

const DEFAULT_LIMIT: int = 400


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var limit: int = CalibrationCli.int_option(options, &"limit", DEFAULT_LIMIT)
	var only: String = CalibrationCli.string_option(options, &"scenario", "")

	print("Searching for golden scenario seeds (limit %d per scenario)" % limit)
	var missing: int = 0
	for scenario in GoldenScenarios.names():
		if not only.is_empty() and String(scenario) != only:
			continue
		var current: int = GoldenScenarios.seed_for(scenario)
		if _satisfies(scenario, current):
			print("  %-24s seed %d still satisfies: %s" % [
				String(scenario), current, GoldenScenarios.describe_requirement(scenario)])
			continue
		var found: int = _search(scenario, limit)
		if found == 0:
			missing += 1
			printerr("  %-24s NO SEED FOUND in %d attempts for: %s" % [
				String(scenario), limit, GoldenScenarios.describe_requirement(scenario)])
			continue
		print("  %-24s seed %d NEEDED (was %d) for: %s" % [
			String(scenario), found, current,
			GoldenScenarios.describe_requirement(scenario)])
	quit(1 if missing > 0 else 0)


func _search(scenario: StringName, limit: int) -> int:
	for attempt in range(1, limit + 1):
		var candidate: int = attempt * 7919
		if _satisfies(scenario, candidate):
			return candidate
	return 0


func _satisfies(scenario: StringName, seed_value: int) -> bool:
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		GoldenScenarios.input_for(scenario), SeededRandomSource.new(seed_value))
	return GoldenScenarios.meets_requirement(scenario, output)
