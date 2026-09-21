extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var label: String = CalibrationCli.string_option(options, &"label", "current")
	var search_enabled: bool = CalibrationCli.string_option(options, &"search", "no") == "yes"
	var all_edges: bool = CalibrationCli.string_option(options, &"edges", "all") == "all"
	var suite := TestScoreMargin.new()
	var arms: Array[Dictionary] = []
	var edges: Array[float] = [5.0]
	if all_edges:
		edges = [0.0, 2.0, 5.0]
	for edge: float in edges:
		var margins: PackedFloat64Array = suite._edge_margins(edge)
		var cached: PackedFloat64Array = suite._edge_margins(edge)
		var upsets: int = 0
		for value: float in margins:
			if value < 0.0:
				upsets += 1
		arms.append({"edge": edge, "margins": Array(margins), "games": margins.size(), "cache_repeat_equal": margins == cached, "mean": suite._mean(margins), "minimum": suite._minimum(margins), "maximum": suite._maximum(margins), "sample_sd": suite._standard_deviation(margins), "upsets": upsets})
		print("%s edge=%s upsets=%d mean=%f" % [label, edge, upsets, suite._mean(margins)])
	var searched: Array[Dictionary] = []
	if search_enabled:
		for index: int in range(24, 129):
			var input: MatchInput = _edge_input(index, 5.0)
			var output: MatchSimulationOutput = MatchEngine.new().simulate_match(input, SeededRandomSource.new(index * 15485863 + 3))
			var row: Dictionary = _row(index, input, output)
			searched.append(row)
			print("witness candidate index=%d margin=%d" % [index, row.margin])
			if row.margin < 0:
				break
	var result: Dictionary = {"label": label, "godot": Engine.get_version_info().string, "engine_version": SimulationBalanceProfile.new().version, "pace": CompetitionCatalog.rules_for(CalibrationTargets.Competition.TOP_DOMESTIC_PRO).pace_multiplier, "portfolio_indices": "0..23 unchanged", "seed_formula": "index * 15485863 + 3", "arms": arms, "witness_search": searched}
	var file := FileAccess.open("res://analysis/timing_pace_followup/score_margin_%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t") + "\n")
	suite.free()
	quit(0)

func _edge_input(index: int, edge: float) -> MatchInput:
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	var balance := SimulationBalanceProfile.new()
	var home: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"home", index * 2, balance, edge)
	var away: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"away", index * 2, balance, 0.0)
	return MatchInput.new(StringName("edge_match_%d" % index), StringName("edge_game_%d" % index), CompetitionCatalog.rules_for(competition), balance, home, away, home.team_id, CompetitionCatalog.ratings_profile(), 0.0)

func _row(index: int, input: MatchInput, output: MatchSimulationOutput) -> Dictionary:
	var home_ledger: int = 0
	var away_ledger: int = 0
	for event: MatchDomainEvent in output.events:
		var points: int = event.points if event.event_type == MatchDomainEvent.FIELD_GOAL_MADE else (1 if event.event_type == MatchDomainEvent.FREE_THROW_MADE else 0)
		if event.team_id == input.home.team_id:
			home_ledger += points
		elif event.team_id == input.away.team_id:
			away_ledger += points
	return {"index": index, "seed": index * 15485863 + 3, "home_score": output.final_result.home_score, "away_score": output.final_result.away_score, "home_ledger": home_ledger, "away_ledger": away_ledger, "margin": output.final_result.home_score - output.final_result.away_score, "ledger_sha256": MatchLedgerSerializer.hash_output(output), "reconciliation": Array(output.final_result.statistics.reconcile())}
