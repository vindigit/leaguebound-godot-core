extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var label: String = CalibrationCli.string_option(options, &"label", "current")
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://analysis/timing_pace_followup/score_margin_%s.json" % label))
	var cached: float = 0.0
	for arm: Dictionary in prior.arms:
		if arm.edge == 5.0:
			cached = arm.margins[0] as float
	var first: MatchSimulationOutput = MatchEngine.new().simulate_match(_edge_input(0), SeededRandomSource.new(3))
	var repeat: MatchSimulationOutput = MatchEngine.new().simulate_match(_edge_input(0), SeededRandomSource.new(3))
	var margin: int = first.final_result.home_score - first.final_result.away_score
	var result: Dictionary = {"label": label, "index": 0, "seed": 3, "edge": 5, "cached_margin": cached, "fresh_margin": margin, "cache_matches_fresh": float(margin) == cached, "fresh_hash": MatchLedgerSerializer.hash_output(first), "repeat_hash": MatchLedgerSerializer.hash_output(repeat), "repeat_matches": MatchLedgerSerializer.hash_output(first) == MatchLedgerSerializer.hash_output(repeat)}
	var file := FileAccess.open("res://analysis/timing_pace_followup/score_margin_%s_cache_replay.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	print(JSON.stringify(result))
	quit(0 if result.cache_matches_fresh == true and result.repeat_matches == true else 1)

func _edge_input(index: int) -> MatchInput:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var balance := SimulationBalanceProfile.new()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"home", index * 2, balance, 5.0)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"away", index * 2, balance, 0.0)
	return MatchInput.new(StringName("edge_match_%d" % index), StringName("edge_game_%d" % index), CompetitionCatalog.rules_for(competition), balance, home, away, home.team_id, CompetitionCatalog.ratings_profile(), 0.0)
