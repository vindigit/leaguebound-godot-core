class_name PlayerMatchRuntime
extends RefCounted


var player_id: StringName
var on_court: bool
var minutes_played_seconds: int
var current_energy: float
var acute_fatigue: float
var foul_count: int
var touches: int
var usage_events: int
var matchup_id: StringName
var hot_context: float
var medically_available: bool


func _init(p_player_id: StringName = &"player", p_on_court: bool = false) -> void:
	player_id = p_player_id
	on_court = p_on_court
	minutes_played_seconds = 0
	current_energy = 1.0
	acute_fatigue = 0.0
	foul_count = 0
	touches = 0
	usage_events = 0
	matchup_id = &""
	hot_context = 0.0
	medically_available = true


func copy() -> PlayerMatchRuntime:
	var result := PlayerMatchRuntime.new(player_id, on_court)
	result.minutes_played_seconds = minutes_played_seconds
	result.current_energy = current_energy
	result.acute_fatigue = acute_fatigue
	result.foul_count = foul_count
	result.touches = touches
	result.usage_events = usage_events
	result.matchup_id = matchup_id
	result.hot_context = hot_context
	result.medically_available = medically_available
	return result
