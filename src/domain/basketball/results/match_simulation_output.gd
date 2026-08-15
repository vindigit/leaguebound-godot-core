class_name MatchSimulationOutput
extends RefCounted


var final_result: MatchFinalResult
var events: Array[MatchDomainEvent]


func _init(p_final_result: MatchFinalResult = null, p_events: Array[MatchDomainEvent] = []) -> void:
	assert(p_final_result != null, "simulation output requires a final result")
	final_result = p_final_result
	events = p_events.duplicate()


func signature() -> String:
	var event_signatures := PackedStringArray()
	for event in events:
		event_signatures.append(event.signature())
	return "%s||%s" % [final_result.signature(), "|".join(event_signatures)]
