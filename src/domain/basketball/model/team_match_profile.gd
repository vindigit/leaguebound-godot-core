class_name TeamMatchProfile
extends RefCounted

## The immutable game-start facts for one team.
##
## This type deliberately no longer answers "who is on court". `SIMULATION_SPEC.md`
## §5.1 makes the lineup part of authoritative *match state*, and the Stage 3
## contract makes runtime lineup state the sole authority for participation.
## The previous `on_court_profiles()` read the static starter list, so a
## substituted or fouled-out player kept playing — the profile is now the
## roster and the plan, and `TeamMatchState` is the lineup.

var team_id: StringName
var players: Array[PlayerMatchProfile]
var rotation_plan: RotationPlan
var game_plan: TeamGamePlan
var chemistry: float
var _index: Dictionary


func _init(
	p_team_id: StringName = &"team",
	p_players: Array[PlayerMatchProfile] = [],
	p_starters: Array[StringName] = [],
	p_chemistry: float = 0.5,
	p_game_plan: TeamGamePlan = null,
	p_balance: SimulationBalanceProfile = null,
	p_rotation_plan: RotationPlan = null,
) -> void:
	assert(not p_team_id.is_empty(), "team identity is required")
	assert(p_players.size() >= 5, "a match team requires at least five players")
	assert(p_starters.size() == 5, "exactly five starters are required")
	assert(p_chemistry >= 0.0 and p_chemistry <= 1.0, "chemistry must be normalized")
	team_id = p_team_id
	players = p_players.duplicate()
	chemistry = p_chemistry
	game_plan = p_game_plan if p_game_plan != null else TeamGamePlan.balanced_plan()
	_index = {}
	for player in players:
		assert(player.is_available(), "unavailable players cannot enter the initial match roster")
		assert(not _index.has(player.player_id), "duplicate player identity")
		_index[player.player_id] = player
	for starter_id in p_starters:
		assert(_index.has(starter_id), "every starter must belong to the supplied team")
	var balance: SimulationBalanceProfile = (
		p_balance if p_balance != null else SimulationBalanceProfile.new())
	rotation_plan = (
		p_rotation_plan
		if p_rotation_plan != null
		else RotationPlan.from_roster(players, p_starters, balance)
	)


func starters() -> Array[StringName]:
	return rotation_plan.starters.duplicate()


func player_by_id(player_id: StringName) -> PlayerMatchProfile:
	assert(_index.has(player_id), "player does not belong to team")
	var player: PlayerMatchProfile = _index[player_id]
	return player


func has_player(player_id: StringName) -> bool:
	return _index.has(player_id)


## Canonical roster order. Establishing this before any weighted draw is what
## keeps the ledger reproducible (`GODOT_TDD.md` §5.2).
func player_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for player in players:
		ids.append(player.player_id)
	return ids
