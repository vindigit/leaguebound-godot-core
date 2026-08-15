class_name FatigueResolver
extends RefCounted


func apply(snapshot: MatchSnapshot, input: MatchInput, elapsed_ms: int) -> void:
	var elapsed_seconds := float(elapsed_ms) / 1000.0
	_apply_team(snapshot.home, input.home, elapsed_seconds, input.balance_profile)
	_apply_team(snapshot.away, input.away, elapsed_seconds, input.balance_profile)


func _apply_team(
	state: TeamMatchState,
	profile: TeamMatchProfile,
	elapsed_seconds: float,
	balance: SimulationBalanceProfile,
) -> void:
	for runtime in state.runtimes:
		if not runtime.on_court:
			continue
		var player := profile.player_by_id(runtime.player_id)
		var stamina_resistance := 0.55 + Rating.normalized(player.attributes.stamina) * 0.45
		var fatigue_delta := elapsed_seconds * balance.fatigue_per_second / stamina_resistance
		runtime.minutes_played_seconds += roundi(elapsed_seconds)
		runtime.acute_fatigue = clampf(runtime.acute_fatigue + fatigue_delta, 0.0, 1.0)
		runtime.current_energy = 1.0 - runtime.acute_fatigue
