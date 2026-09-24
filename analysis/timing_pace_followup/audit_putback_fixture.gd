extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var search: Array[Dictionary] = []
	var result: Dictionary = {"source_head": "743d845145268d223736e1bfb3a53bd2bf52fa6b", "old_semantics": "Previously pinned seed7095 under current v17 engine, not an old-head engine run.", "godot": Engine.get_version_info().string, "old": _audit(7095), "search": search}
	for seed_value: int in range(7096, 7301):
		var row: Dictionary = _audit(seed_value)
		search.append(row)
		if row.tagged_two_for_one == 1:
			result.selected_seed = seed_value
			break
	var file := FileAccess.open("res://analysis/timing_pace_followup/putback_fixture_audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	print(JSON.stringify(result))
	quit(0 if result.has("selected_seed") else 1)

func _audit(seed_value: int) -> Dictionary:
	var input: MatchInput = MatchFixtureFactory.offensive_rebound_match()
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(input, SeededRandomSource.new(seed_value))
	var state := MatchSnapshot.new(input)
	var reducer := MatchStateReducer.new(input)
	var rows: Array[Dictionary] = []
	var tagged: int = 0
	var mismatched: int = 0
	for event: MatchDomainEvent in output.events:
		var at_action: MatchSnapshot = state.copy()
		reducer._advance_clock(at_action, event)
		reducer.apply_event(state, event)
		if event.event_type != MatchDomainEvent.ACTION_SELECTED or event.action_id != ActionFamily.id_of(ActionFamily.Value.PUTBACK):
			continue
		var context := PossessionContext.new(input, at_action, event.team_id, MatchupState.new({}), event.possession_id)
		var expected: StringName = EndgameStrategy.active_tag(context, input.balance_profile)
		if event.detail_id != expected:
			mismatched += 1
		if event.detail_id == EndgameStrategy.TAG_TWO_FOR_ONE:
			tagged += 1
		rows.append({"sequence": event.sequence, "period": event.period, "clock_ms": event.clock_ms, "team": event.team_id, "margin": context.offense_margin(), "actual": event.detail_id, "expected": expected})
	print("seed=%d putbacks=%d tagged=%d mismatched=%d" % [seed_value, rows.size(), tagged, mismatched])
	return {"seed": seed_value, "putbacks": rows, "tagged_two_for_one": tagged, "tag_mismatches": mismatched, "ledger_sha256": MatchLedgerSerializer.hash_output(output)}
