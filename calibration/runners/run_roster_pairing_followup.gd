extends "res://calibration/runners/run_competition_calibration.gd"

## Matched fixture-only experiment. Use identical bytes on both source trees.
## Inherits canonical judgments; adds --environment=0.5 and raw game clusters.
func _run_competition(competition: int, games: int, shard: int) -> MatchMetricAccumulator:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var environment: float = CalibrationCli.float_option(options, &"environment", 0.5)
	var label: String = CalibrationCli.string_option(options, &"label", "roster")
	var totals := MatchMetricAccumulator.new()
	var rows: Array[Dictionary] = []
	var base: int = shard * games
	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, environment)
		var home_strength: Dictionary = _strength(input.home)
		var away_strength: Dictionary = _strength(input.away)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		totals.accumulate(input, output)
		var one := MatchMetricAccumulator.new()
		one.accumulate(input, output)
		assert(one.engine_possessions == output.possessions.size(), "possession denominator mismatch")
		var row: Dictionary = {
			"variation": variation, "seed": variation + 1, "block": variation / 4,
			"home_strength": home_strength, "away_strength": away_strength,
			"opening_home": input.initial_possession_team_id == input.home.team_id,
			"home_score": output.final_result.home_score,
			"away_score": output.final_result.away_score,
			"margin": output.final_result.home_score - output.final_result.away_score,
			"overtime_periods": output.final_result.overtime_periods,
			"regulation_possessions": 0, "overtime_possessions": 0}
		for record: PossessionRecord in output.possessions:
			var key: String = "regulation_possessions" if record.start_period <= input.rule_profile.regulation_periods else "overtime_possessions"
			row[key] += 1
		for property: Dictionary in one.get_property_list():
			if not ((property["usage"] as int) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var name: String = str(property["name"])
			var value: Variant = one.get(name)
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				row[name] = value
		rows.append(row)
		if (index + 1) % 20 == 0:
			print("roster %s %s %d/%d" % [label, CalibrationTargets.competition_id(competition), index + 1, games])
	var path: String = "res://reports/roster_raw_%s_%s.json" % [label, CalibrationTargets.competition_id(competition)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "cannot archive roster observations")
	file.store_string(JSON.stringify({"competition": CalibrationTargets.competition_id(competition),
		"catalog": String(CompetitionCatalog.VERSION), "environment": environment,
		"seed_first": base + 1, "seed_last": base + games, "rows": rows}, "\t"))
	file.close()
	return totals


func _strength(team: TeamMatchProfile) -> Dictionary:
	var attribute_sum: float = 0.0
	var overall_sum: float = 0.0
	var starter_sum: float = 0.0
	var vectors: Array = []
	var profile: RatingsProfile = CompetitionCatalog.ratings_profile()
	for index in range(team.players.size()):
		var values: Array[int] = team.players[index].attributes.canonical_values()
		vectors.append(values)
		for value in values:
			attribute_sum += value
		var overall: float = OverallCalculator.raw_overall(values, profile)
		overall_sum += overall
		if index < 5:
			starter_sum += overall
	return {"mean_attribute": attribute_sum / float(team.players.size() * AttributeKey.COUNT),
		"mean_raw_overall": overall_sum / float(team.players.size()),
		"starter_raw_overall": starter_sum / 5.0,
		"attribute_vectors": vectors}
