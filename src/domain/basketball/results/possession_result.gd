class_name PossessionResult
extends RefCounted

## Everything one team possession produced.
##
## The events are the authority; `record` is the terminal possession fact the
## engine counts possessions from, and `elapsed_ms` is a convenience derived
## from the event timestamps rather than a second source of truth.

var events: Array[MatchDomainEvent]
var elapsed_ms: int
var next_possession_team_id: StringName
var final_node: int
var record: PossessionRecord


func _init(
	p_events: Array[MatchDomainEvent] = [],
	p_elapsed_ms: int = 0,
	p_next_possession_team_id: StringName = &"",
	p_final_node: int = PossessionNode.Value.POSSESSION_END,
	p_record: PossessionRecord = null,
) -> void:
	assert(p_elapsed_ms >= 0, "possession time cannot be negative")
	events = p_events.duplicate()
	elapsed_ms = p_elapsed_ms
	next_possession_team_id = p_next_possession_team_id
	final_node = p_final_node
	record = p_record


## Exactly one start and one terminal end event per possession is a structural
## invariant, not a statistical expectation, so it is checked here where the
## possession is assembled as well as in the test suite.
func has_exactly_one_start_and_end() -> bool:
	var starts: int = 0
	var ends: int = 0
	for event in events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			starts += 1
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			ends += 1
	return starts == 1 and ends == 1
