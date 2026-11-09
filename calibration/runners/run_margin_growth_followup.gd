extends SceneTree

## Observation-only matched-arm margin audit. Each cell fixes variation, seed,
## opener and rule profile. The arms change only the roster assignment or the
## home-environment intervention. Output is line-delimited JSON so an
## interrupted run cannot masquerade as a complete cell.

const ARMS: PackedStringArray = ["ordinary_ab", "identical_aa", "reversed_ba"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var first: int = CalibrationCli.int_option(options, &"first", 42120000)
	var games: int = CalibrationCli.int_option(options, &"games", 40)
	var selection: String = CalibrationCli.string_option(options, &"competition", "top_domestic_pro")
	var label: String = CalibrationCli.string_option(options, &"label", "diagnostic")
	var competition: int = -1
	for value: int in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(value)) == selection:
			competition = value
	if competition < 0 or first < 0 or games <= 0 or first % 4 != 0 or games % 4 != 0:
		printerr("invalid competition or range; first and games must align to roster quartets")
		quit(2)
		return
	var folder: String = "res://analysis/margin_growth_followup/raw"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path: String = "%s/%s_%s.ndjson" % [folder, label, selection]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "cannot open margin growth archive")
	var header: Dictionary = {
		"kind": "header", "label": label, "competition": selection,
		"catalog": String(CompetitionCatalog.VERSION), "first_variation": first,
		"games_per_arm": games, "arms": Array(ARMS),
		"environments": [0.0, 0.5], "seed_rule": "variation+1",
		"opening_rule": "counterbalanced by variation parity",
	}
	file.store_line(JSON.stringify(header))
	var audit := MarginGrowthAudit.new()
	var count: int = 0
	for index: int in range(games):
		var variation: int = first + index
		var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
		var canonical: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		for arm: String in ARMS:
			for environment: float in [0.0, 0.5]:
				var input: MatchInput = _input(competition, variation, pair, arm, environment)
				assert(input.match_id == canonical.match_id and input.game_id == canonical.game_id,
					"matched arms must share derived random-stream identity")
				assert(input.initial_possession_team_id == canonical.initial_possession_team_id,
					"matched arms must share opener assignment")
				audit.attach()
				var output: MatchSimulationOutput = MatchSession.new(
					input, SeededRandomSource.new(variation + 1)).run_to_completion()
				audit.detach()
				var measurement: Dictionary = audit.measure(input, output)
				var measurement_errors: PackedStringArray = measurement["errors"] as PackedStringArray
				if not measurement_errors.is_empty():
					printerr("audit errors %s %d %s %.1f: %s" % [
						selection, variation, arm, environment, str(measurement_errors)])
				assert(measurement_errors.is_empty(), "margin audit ledger mismatch")
				file.store_line(JSON.stringify({
					"kind": "game", "variation": variation, "seed": variation + 1,
					"match_id": String(input.match_id),
					"arm": arm, "environment": environment,
					"home_roster": _roster_index(pair, arm, true),
					"away_roster": _roster_index(pair, arm, false),
					"opening_home": input.initial_possession_team_id == input.home.team_id,
					"home_score": output.final_result.home_score,
					"away_score": output.final_result.away_score,
					"overtime_periods": output.final_result.overtime_periods,
					"strength_gap": TeamStrengthIndex.expected_gap(
						TeamStrengthIndex.of_team(input.home, input.ratings_profile, input.balance_profile),
						TeamStrengthIndex.of_team(input.away, input.ratings_profile, input.balance_profile)),
					"measurement": measurement,
				}))
				count += 1
		if (index + 1) % 4 == 0:
			file.flush()
			print("margin growth %s %s %d/%d" % [label, selection, index + 1, games])
	file.store_line(JSON.stringify({"kind": "complete", "games": count}))
	file.close()
	print("complete %s %s %d %s" % [label, selection, count, path])
	quit(0)


func _roster_index(pair: PackedInt32Array, arm: String, home: bool) -> int:
	match arm:
		"ordinary_ab": return pair[0] if home else pair[1]
		"identical_aa": return pair[0]
		"reversed_ba": return pair[1] if home else pair[0]
	return -1


func _input(
	competition: int, variation: int, pair: PackedInt32Array,
	arm: String, environment: float,
) -> MatchInput:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", _roster_index(pair, arm, true), balance)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", _roster_index(pair, arm, false), balance)
	return MatchInput.new(
		StringName("calib_%s_%d" % [CalibrationTargets.competition_id(competition), variation]),
		StringName("calib_game_%d" % variation),
		CompetitionCatalog.rules_for(competition), balance, home, away,
		CompetitionCatalog.opening_team_id(
			CompetitionCatalog.OPENING_COUNTERBALANCED, variation, home, away),
		CompetitionCatalog.ratings_profile(), environment)
