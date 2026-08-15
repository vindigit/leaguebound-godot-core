class_name TeamMatchState
extends RefCounted


var team_id: StringName
var score: int
var team_fouls: int
var runtimes: Array[PlayerMatchRuntime]


func _init(profile: TeamMatchProfile = null) -> void:
	if profile == null:
		team_id = &""
		score = 0
		team_fouls = 0
		runtimes = []
		return
	team_id = profile.team_id
	score = 0
	team_fouls = 0
	runtimes = []
	for player in profile.players:
		runtimes.append(PlayerMatchRuntime.new(player.player_id, profile.starters.has(player.player_id)))


func copy() -> TeamMatchState:
	var result := TeamMatchState.new()
	result.team_id = team_id
	result.score = score
	result.team_fouls = team_fouls
	result.runtimes = []
	for runtime in runtimes:
		result.runtimes.append(runtime.copy())
	return result


func runtime_by_id(player_id: StringName) -> PlayerMatchRuntime:
	for runtime in runtimes:
		if runtime.player_id == player_id:
			return runtime
	assert(false, "unknown player runtime")
	return runtimes[0]
