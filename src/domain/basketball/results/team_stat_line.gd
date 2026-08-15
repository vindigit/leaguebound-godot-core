class_name TeamStatLine
extends RefCounted


var team_id: StringName
var points: int = 0
var field_goals_made: int = 0
var field_goals_attempted: int = 0
var three_pointers_made: int = 0
var three_pointers_attempted: int = 0
var turnovers: int = 0
var offensive_rebounds: int = 0
var defensive_rebounds: int = 0


func _init(p_team_id: StringName = &"team") -> void:
	team_id = p_team_id


func signature() -> String:
	return "%s:%d:%d:%d:%d:%d:%d:%d:%d" % [
		team_id, points, field_goals_made, field_goals_attempted,
		three_pointers_made, three_pointers_attempted, turnovers,
		offensive_rebounds, defensive_rebounds,
	]
