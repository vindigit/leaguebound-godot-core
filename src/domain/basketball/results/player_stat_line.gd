class_name PlayerStatLine
extends RefCounted


var player_id: StringName
var team_id: StringName
var points: int = 0
var field_goals_made: int = 0
var field_goals_attempted: int = 0
var three_pointers_made: int = 0
var three_pointers_attempted: int = 0
var offensive_rebounds: int = 0
var defensive_rebounds: int = 0
var turnovers: int = 0
var personal_fouls: int = 0


func _init(p_player_id: StringName = &"player", p_team_id: StringName = &"team") -> void:
	player_id = p_player_id
	team_id = p_team_id


func signature() -> String:
	return "%s:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
		player_id, points, field_goals_made, field_goals_attempted,
		three_pointers_made, three_pointers_attempted, offensive_rebounds,
		defensive_rebounds, turnovers, personal_fouls,
	]
