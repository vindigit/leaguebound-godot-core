class_name PossessionRecord
extends RefCounted

## The terminal record of one team possession.
##
## The Stage 3 contract requires engine possessions to come from these records
## — "not presentation events or statistical estimates". The published
## `possessions estimate` (§24.2) still exists beside them, but it is derived
## separately and is never allowed to become the authority.
##
## An offensive rebound never creates a new record: it continues this one, so
## `offensive_rebounds` counts extra shot opportunities inside a single team
## possession.

var possession_id: int
var offense_team_id: StringName
var start_period: int
var start_clock_ms: int
var end_period: int
var end_clock_ms: int
var end_reason: int
var points_scored: int
var action_count: int
var offensive_rebounds: int
var next_possession_team_id: StringName
## Whether the ball changed hands live — a steal or a defensive rebound — which
## is what makes the next possession a transition opportunity (§16).
var live_transfer: bool = false


func _init(
	p_possession_id: int = 0,
	p_offense_team_id: StringName = &"",
	p_start_period: int = 1,
	p_start_clock_ms: int = 0,
	p_end_period: int = 1,
	p_end_clock_ms: int = 0,
	p_end_reason: int = PossessionEndReason.Value.TURNOVER,
	p_points_scored: int = 0,
	p_action_count: int = 0,
	p_offensive_rebounds: int = 0,
	p_next_possession_team_id: StringName = &"",
) -> void:
	assert(p_possession_id > 0, "a terminal possession record needs a stable identity")
	assert(PossessionEndReason.is_valid(p_end_reason), "unknown possession end reason")
	assert(p_points_scored >= 0, "a possession cannot score negative points")
	possession_id = p_possession_id
	offense_team_id = p_offense_team_id
	start_period = p_start_period
	start_clock_ms = p_start_clock_ms
	end_period = p_end_period
	end_clock_ms = p_end_clock_ms
	end_reason = p_end_reason
	points_scored = p_points_scored
	action_count = p_action_count
	offensive_rebounds = p_offensive_rebounds
	next_possession_team_id = p_next_possession_team_id


func end_reason_id() -> StringName:
	return PossessionEndReason.id_of(end_reason)


func signature() -> String:
	return "%d:%s:%d:%d:%d:%d:%s:%d:%d:%d:%s:%d" % [
		possession_id, offense_team_id, start_period, start_clock_ms,
		end_period, end_clock_ms, end_reason_id(), points_scored,
		action_count, offensive_rebounds, next_possession_team_id,
		1 if live_transfer else 0,
	]
