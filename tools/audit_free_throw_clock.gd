extends SceneTree

## Diagnostic only: replay actual production ledgers, showing what FT event
## timestamps charge. Does not bless the observed behaviour as a contract.
## Run after import with --headless --path . --script res://tools/audit_free_throw_clock.gd.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var rows: Array[Dictionary] = []
	var covered: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var input: MatchInput = CompetitionCatalog.match_for(competition, 0, 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(991001))
		var state := MatchSnapshot.new(input)
		var reducer := MatchStateReducer.new(input)
		var attempts: int = 0
		var clock_charged: int = 0
		var shot_clock_charged: int = 0
		var player_minutes_charged: int = 0
		for event: MatchDomainEvent in output.events:
			var before_clock: int = state.clock_ms
			var before_shot: int = state.shot_clock_ms
			var before_minutes: int = _played_ms(state)
			reducer.apply_event(state, event)
			if event.event_type in [MatchDomainEvent.FREE_THROW_MADE, MatchDomainEvent.FREE_THROW_MISSED]:
				attempts += 1
				clock_charged += before_clock - state.clock_ms
				shot_clock_charged += before_shot - state.shot_clock_ms
				player_minutes_charged += _played_ms(state) - before_minutes
		if attempts > 0:
			covered += 1
		rows.append({"profile": input.rule_profile.profile_id, "seed": 991001,
			"attempts": attempts, "game_clock_ms_charged": clock_charged,
			"shot_clock_ms_charged": shot_clock_charged,
			"summed_player_played_ms_charged": player_minutes_charged})
	print(JSON.stringify({"diagnostic_only": true, "profiles_with_attempts": covered, "rows": rows}, "  "))
	quit(0 if covered == 5 else 1)


func _played_ms(state: MatchSnapshot) -> int:
	var total: int = 0
	for team: TeamMatchState in [state.home, state.away]:
		for runtime: PlayerMatchRuntime in team.runtimes:
			total += runtime.played_ms
	return total
