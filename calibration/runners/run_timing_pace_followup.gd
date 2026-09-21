extends "res://calibration/runners/run_competition_calibration.gd"

## Matched pace measurements with canonical competition judgments and per-game
## raw terms. Only pace is overridden; every other profile field is checked.
## Inherits the standard runner CLI, plus --pace-scale=1.0.
## Raw rows are game clusters (the two teams are never treated as independent).

func _run_competition(competition: int, games: int, shard: int) -> MatchMetricAccumulator:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var scale: float = CalibrationCli.float_option(options, &"pace-scale", 1.0)
	var label: String = CalibrationCli.string_option(options, &"label", "pace")
	var rules: CompetitionRuleProfile = _scaled_rules(competition, scale)
	var totals := MatchMetricAccumulator.new()
	var rows: Array[Dictionary] = []
	var base: int = shard * games
	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		input.rule_profile = rules
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		totals.accumulate(input, output)
		var one := MatchMetricAccumulator.new()
		one.accumulate(input, output)
		assert(one.engine_possessions == output.possessions.size(), "possession denominators disagree")
		var row: Dictionary = {"variation": variation, "seed": variation + 1,
			"regulation_possessions": 0, "overtime_possessions": 0,
			"overtime_periods": output.final_result.overtime_periods}
		for record: PossessionRecord in output.possessions:
			var key: String = "regulation_possessions" if record.start_period <= rules.regulation_periods else "overtime_possessions"
			row[key] += 1
		for property: Dictionary in one.get_property_list():
			var name: String = str(property["name"])
			if not ((property["usage"] as int) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var value: Variant = one.get(name)
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				row[name] = value
		rows.append(row)
		if (index + 1) % 25 == 0:
			print("  %s %d/%d pace=%.6f" % [CalibrationTargets.competition_id(competition), index + 1, games, rules.pace_multiplier])
	var path: String = "res://reports/pace_raw_%s_%s.json" % [label, CalibrationTargets.competition_id(competition)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "cannot archive raw pace observations")
	file.store_string(JSON.stringify({"competition": CalibrationTargets.competition_id(competition),
		"pace_multiplier": rules.pace_multiplier, "pace_scale": scale,
		"seed_first": base + 1, "seed_last": base + games,
		"ruleset": String(CompetitionCatalog.balance_profile().version),
		"rows": rows}, "\t"))
	file.close()
	return totals
func _scaled_rules(competition: int, pace_scale: float) -> CompetitionRuleProfile:
	var source: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
	if is_equal_approx(pace_scale, 1.0):
		return source
	var copy := CompetitionRuleProfile.new(
		source.profile_id, source.version, source.regulation_periods,
		source.period_seconds, source.overtime_seconds, source.shot_clock_seconds,
		source.personal_foul_limit, source.offensive_rebound_reset_seconds,
		source.frontcourt_seconds, source.team_foul_bonus_threshold, source.bonus_kind,
		source.team_foul_double_bonus_threshold, source.double_bonus_free_throws,
		source.team_fouls_reset_each_period, source.final_free_throw_reboundable,
		source.possession_arrow_enabled, source.three_point_profile_id,
		source.restricted_area_profile_id, source.pace_environment_id,
		source.officiating_profile_id, source.roster_rule_profile_id,
		source.pace_multiplier * pace_scale, source.timeouts_per_team,
		source.timeout_advance_permitted, source.made_field_goal_clock_rule)
	for property: Dictionary in source.get_property_list():
		var name: String = str(property["name"])
		var usage: int = property["usage"] as int
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if name == "pace_multiplier" or name.begins_with("_"):
			continue
		assert(str(copy.get(name)) == str(source.get(name)),
			"the pace-scaled copy dropped '%s'; add it to _scaled_rules" % name)
	return copy
