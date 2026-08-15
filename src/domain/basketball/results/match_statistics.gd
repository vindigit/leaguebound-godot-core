class_name MatchStatistics
extends RefCounted


var players: Array[PlayerStatLine]
var teams: Array[TeamStatLine]


func _init(p_players: Array[PlayerStatLine] = [], p_teams: Array[TeamStatLine] = []) -> void:
	players = p_players.duplicate()
	teams = p_teams.duplicate()


func player_line(player_id: StringName) -> PlayerStatLine:
	for line in players:
		if line.player_id == player_id:
			return line
	assert(false, "missing player stat line")
	return players[0]


func team_line(team_id: StringName) -> TeamStatLine:
	for line in teams:
		if line.team_id == team_id:
			return line
	assert(false, "missing team stat line")
	return teams[0]


func signature() -> String:
	var parts := PackedStringArray()
	for team in teams:
		parts.append(team.signature())
	for player in players:
		parts.append(player.signature())
	return "|".join(parts)
