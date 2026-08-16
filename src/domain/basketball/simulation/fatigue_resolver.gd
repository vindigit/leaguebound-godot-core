class_name FatigueResolver
extends RefCounted

## Acute match fatigue (`SIMULATION_SPEC.md` §17.1, `BALANCE_SPEC.md` §15.1).
##
## Fatigue changes from time on court, action intensity, and rest on the bench,
## with Stamina resisting accumulation and speeding recovery. §17.1 is explicit
## about what it must not become: "It does not directly subtract the same flat
## amount from all ratings." The subtraction happens per capability, through the
## sensitivity share each one declares (`CapabilityWeightSet`).
##
## This is called by the reducer as the ledger's timestamps advance the clock,
## so fatigue is a function of the committed event stream rather than a side
## channel the engine could forget to update.

var _balance: SimulationBalanceProfile


func _init(p_balance: SimulationBalanceProfile) -> void:
	_balance = p_balance


func apply_elapsed(state: MatchSnapshot, input: MatchInput, elapsed_ms: int) -> void:
	if elapsed_ms <= 0:
		return
	_apply_team(state.home, input.home, elapsed_ms)
	_apply_team(state.away, input.away, elapsed_ms)


## §15.1 additional load for one high-intensity action, charged to the player
## who performed it.
func apply_action_load(
	state: MatchSnapshot,
	team_id: StringName,
	player_id: StringName,
	action_family: int,
) -> void:
	var team_state: TeamMatchState = state.state_for(team_id)
	if not team_state.has_player(player_id):
		return
	var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player_id)
	runtime.acute_fatigue = clampf(
		runtime.acute_fatigue + _balance.action_load(action_family), 0.0, 100.0)


func _apply_team(
	state: TeamMatchState,
	profile: TeamMatchProfile,
	elapsed_ms: int,
) -> void:
	var minutes: float = float(elapsed_ms) / 60000.0
	for runtime in state.runtimes:
		var player: PlayerMatchProfile = profile.player_by_id(runtime.player_id)
		if runtime.on_court:
			runtime.played_ms += elapsed_ms
			runtime.stint_ms += elapsed_ms
			runtime.rest_ms = 0
			runtime.acute_fatigue = clampf(
				runtime.acute_fatigue
				+ minutes * _balance.fatigue_per_active_minute(player.attributes.stamina),
				0.0,
				100.0)
		else:
			runtime.rest_ms += elapsed_ms
			runtime.stint_ms = 0
			runtime.acute_fatigue = clampf(
				runtime.acute_fatigue
				- minutes * _balance.recovery_per_bench_minute(player.attributes.stamina),
				0.0,
				100.0)
