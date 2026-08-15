class_name MatchDomainEvent
extends RefCounted


const POSSESSION_STARTED: StringName = &"possession_started"
const ACTION_SELECTED: StringName = &"action_selected"
const TURNOVER: StringName = &"turnover"
const FIELD_GOAL_ATTEMPT: StringName = &"field_goal_attempt"
const FIELD_GOAL_MADE: StringName = &"field_goal_made"
const FIELD_GOAL_MISSED: StringName = &"field_goal_missed"
const REBOUND: StringName = &"rebound"
const FOUL: StringName = &"foul"
const POSSESSION_ENDED: StringName = &"possession_ended"

var match_id: StringName
var sequence: int
var period: int
var clock_ms: int
var event_type: StringName
var team_id: StringName
var primary_player_id: StringName
var secondary_player_id: StringName
var action_id: StringName
var points: int


func _init(
	p_match_id: StringName = &"match",
	p_sequence: int = 1,
	p_period: int = 1,
	p_clock_ms: int = 0,
	p_event_type: StringName = &"event",
	p_team_id: StringName = &"",
	p_primary_player_id: StringName = &"",
	p_secondary_player_id: StringName = &"",
	p_action_id: StringName = &"",
	p_points: int = 0,
) -> void:
	assert(p_sequence > 0, "event sequence must be positive")
	assert(p_period > 0 and p_clock_ms >= 0, "event time is invalid")
	assert(not p_event_type.is_empty(), "event type is required")
	assert(p_points >= 0 and p_points <= 3, "event points are invalid")
	match_id = p_match_id
	sequence = p_sequence
	period = p_period
	clock_ms = p_clock_ms
	event_type = p_event_type
	team_id = p_team_id
	primary_player_id = p_primary_player_id
	secondary_player_id = p_secondary_player_id
	action_id = p_action_id
	points = p_points


func signature() -> String:
	return "%s|%d|%d|%d|%s|%s|%s|%s|%s|%d" % [
		match_id, sequence, period, clock_ms, event_type, team_id,
		primary_player_id, secondary_player_id, action_id, points,
	]
