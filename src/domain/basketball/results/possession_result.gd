class_name PossessionResult
extends RefCounted


var events: Array[MatchDomainEvent]
var elapsed_ms: int
var next_possession_team_id: StringName
var final_node: PossessionNode.Value


func _init(
	p_events: Array[MatchDomainEvent] = [],
	p_elapsed_ms: int = 0,
	p_next_possession_team_id: StringName = &"",
	p_final_node: PossessionNode.Value = PossessionNode.Value.POSSESSION_END,
) -> void:
	assert(p_elapsed_ms >= 0, "possession time cannot be negative")
	events = p_events.duplicate()
	elapsed_ms = p_elapsed_ms
	next_possession_team_id = p_next_possession_team_id
	final_node = p_final_node
