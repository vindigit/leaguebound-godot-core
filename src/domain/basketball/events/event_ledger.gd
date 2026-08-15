class_name EventLedger
extends RefCounted


var events: Array[MatchDomainEvent] = []


func append(event: MatchDomainEvent) -> void:
	assert(event != null, "event is required")
	var expected_sequence := events.size() + 1
	assert(event.sequence == expected_sequence, "events must be appended exactly once in sequence")
	if not events.is_empty():
		assert(event.match_id == events[0].match_id, "a ledger cannot mix matches")
	events.append(event)


func append_all(new_events: Array[MatchDomainEvent]) -> void:
	for event in new_events:
		append(event)


func signatures() -> PackedStringArray:
	var result := PackedStringArray()
	for event in events:
		result.append(event.signature())
	return result
