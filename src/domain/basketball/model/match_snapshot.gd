class_name MatchSnapshot
extends RefCounted


var match_id: StringName
var period: int
var clock_ms: int
var home: TeamMatchState
var away: TeamMatchState
var possession_team_id: StringName
var possession_sequence: int
var event_sequence: int
var overtime_periods: int
var completed: bool


func _init(input: MatchInput = null) -> void:
	if input == null:
		match_id = &""
		period = 1
		clock_ms = 0
		home = TeamMatchState.new()
		away = TeamMatchState.new()
		possession_team_id = &""
		possession_sequence = 0
		event_sequence = 0
		overtime_periods = 0
		completed = false
		return
	match_id = input.match_id
	period = 1
	clock_ms = input.rule_profile.period_seconds * 1000
	home = TeamMatchState.new(input.home)
	away = TeamMatchState.new(input.away)
	possession_team_id = input.initial_possession_team_id
	possession_sequence = 0
	event_sequence = 0
	overtime_periods = 0
	completed = false


func copy() -> MatchSnapshot:
	var result := MatchSnapshot.new()
	result.match_id = match_id
	result.period = period
	result.clock_ms = clock_ms
	result.home = home.copy()
	result.away = away.copy()
	result.possession_team_id = possession_team_id
	result.possession_sequence = possession_sequence
	result.event_sequence = event_sequence
	result.overtime_periods = overtime_periods
	result.completed = completed
	return result


func score_for(team_id: StringName) -> int:
	if team_id == home.team_id:
		return home.score
	assert(team_id == away.team_id, "unknown team identity")
	return away.score


func opposing_team_id(team_id: StringName) -> StringName:
	if team_id == home.team_id:
		return away.team_id
	assert(team_id == away.team_id, "unknown team identity")
	return home.team_id
