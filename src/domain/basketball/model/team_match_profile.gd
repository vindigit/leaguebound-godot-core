class_name TeamMatchProfile
extends RefCounted


var team_id: StringName
var players: Array[PlayerMatchProfile]
var starters: Array[StringName]
var chemistry: float


func _init(
	p_team_id: StringName = &"team",
	p_players: Array[PlayerMatchProfile] = [],
	p_starters: Array[StringName] = [],
	p_chemistry: float = 0.5,
) -> void:
	assert(not p_team_id.is_empty(), "team identity is required")
	assert(p_players.size() >= 5, "a match team requires at least five players")
	assert(p_starters.size() == 5, "exactly five starters are required")
	assert(p_chemistry >= 0.0 and p_chemistry <= 1.0, "chemistry must be normalized")
	team_id = p_team_id
	players = p_players.duplicate()
	starters = p_starters.duplicate()
	chemistry = p_chemistry
	var player_ids: Array[StringName] = []
	for player in players:
		assert(player.is_available(), "unavailable players cannot enter the initial match roster")
		assert(not player_ids.has(player.player_id), "duplicate player identity")
		player_ids.append(player.player_id)
	for starter_id in starters:
		assert(player_ids.has(starter_id), "every starter must belong to the supplied team")


func player_by_id(player_id: StringName) -> PlayerMatchProfile:
	for player in players:
		if player.player_id == player_id:
			return player
	assert(false, "player does not belong to team")
	return players[0]


func on_court_profiles() -> Array[PlayerMatchProfile]:
	var result: Array[PlayerMatchProfile] = []
	for starter_id in starters:
		result.append(player_by_id(starter_id))
	return result
