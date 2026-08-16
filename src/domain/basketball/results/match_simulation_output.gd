class_name MatchSimulationOutput
extends RefCounted

## One completed simulation: the committed result, the ordered ledger, and the
## terminal possession records.
##
## The possession records travel with the output because the Stage 3 contract
## makes them the authority for engine possessions — "not presentation events or
## statistical estimates". A consumer that wants possession counts reads these;
## a consumer that wants basketball reads the ledger.

var final_result: MatchFinalResult
var events: Array[MatchDomainEvent]
var possessions: Array[PossessionRecord]


func _init(
	p_final_result: MatchFinalResult = null,
	p_events: Array[MatchDomainEvent] = [],
	p_possessions: Array[PossessionRecord] = [],
) -> void:
	assert(p_final_result != null, "simulation output requires a final result")
	final_result = p_final_result
	events = p_events.duplicate()
	possessions = p_possessions.duplicate()


func engine_possessions(team_id: StringName) -> int:
	var count: int = 0
	for record in possessions:
		if record.offense_team_id == team_id:
			count += 1
	return count


## Canonical text over result, ledger, and possession records. Used by the
## determinism suite and by the committed golden hashes.
func signature() -> String:
	var event_signatures := PackedStringArray()
	for event in events:
		event_signatures.append(event.signature())
	var possession_signatures := PackedStringArray()
	for record in possessions:
		possession_signatures.append(record.signature())
	return "%s||%s||%s" % [
		final_result.signature(),
		"|".join(event_signatures),
		"|".join(possession_signatures),
	]
