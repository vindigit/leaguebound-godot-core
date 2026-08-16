class_name MatchLedgerSerializer
extends RefCounted

## Canonical serialization of an ordered event ledger, and its stable hash.
##
## The Stage 3 determinism contract forbids two shortcuts explicitly:
##
## - **Dictionary iteration order** is not the canonical format. Nothing here
##   walks a Dictionary; the field order comes from `MatchDomainEvent.signature`
##   and the record order comes from the ledger's own sequence.
## - **Raw Variant bytes** are not the canonical format either. `var_to_bytes`
##   encodes engine-internal representation, so a Godot patch release could
##   silently invalidate every golden fixture without any gameplay change.
##
## The serialized form is therefore plain text: one event per line, fields
## separated by `|`, in the declared order. It is diffable, which matters the
## first time a golden hash fails.

const RECORD_SEPARATOR: String = "\n"
const HASH_VERSION: StringName = &"ledger-sha256-v1"


static func serialize_events(events: Array[MatchDomainEvent]) -> String:
	var lines: PackedStringArray = []
	for event in events:
		lines.append(event.signature())
	return RECORD_SEPARATOR.join(lines)


## Serializes the full committed result: profile versions, final score, the
## reconciled box score, and the ledger. A golden hash over this catches a
## statistics regression that leaves the event stream untouched.
static func serialize_output(output: MatchSimulationOutput) -> String:
	var sections: PackedStringArray = []
	sections.append("version=%s" % HASH_VERSION)
	sections.append(output.final_result.signature())
	sections.append(serialize_events(output.events))
	return RECORD_SEPARATOR.join(sections)


static func hash_text(text: String) -> String:
	var context := HashingContext.new()
	var start_error: int = context.start(HashingContext.HASH_SHA256)
	assert(start_error == OK, "unable to initialize canonical ledger hashing")
	var update_error: int = context.update(text.to_utf8_buffer())
	assert(update_error == OK, "unable to hash canonical ledger material")
	return context.finish().hex_encode()


static func hash_events(events: Array[MatchDomainEvent]) -> String:
	return hash_text(serialize_events(events))


static func hash_output(output: MatchSimulationOutput) -> String:
	return hash_text(serialize_output(output))
