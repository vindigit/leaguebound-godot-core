class_name MatchEventWriter
extends RefCounted

## Assembles ordered domain events with the current match context filled in.
##
## `MatchDomainEvent` has a wide fixed schema for canonical serialization; that
## makes positional construction at seventeen arguments a genuine hazard. The
## writer owns the context fields — match, sequence, period, clock, possession,
## action sequence — so a call site names only what the event is *about*.
##
## The writer never decides state. It appends in order and hands the event back;
## `MatchStateReducer` is the only thing that folds an event into state.

var match_id: StringName
var sequence: int
var period: int
var clock_ms: int
var possession_id: int
var action_sequence: int
var events: Array[MatchDomainEvent]


func _init(p_match_id: StringName, p_sequence: int, p_period: int, p_clock_ms: int) -> void:
	match_id = p_match_id
	sequence = p_sequence
	period = p_period
	clock_ms = p_clock_ms
	possession_id = 0
	action_sequence = 0
	events = []


func emit(
	event_type: StringName,
	team_id: StringName = &"",
	primary_player_id: StringName = &"",
	secondary_player_id: StringName = &"",
	tertiary_player_id: StringName = &"",
	action_id: StringName = &"",
	detail_id: StringName = &"",
	zone_id: StringName = &"",
	points: int = 0,
	amount: int = 0,
	next_team_id: StringName = &"",
) -> MatchDomainEvent:
	sequence += 1
	var event := MatchDomainEvent.new(
		match_id,
		sequence,
		period,
		clock_ms,
		event_type,
		team_id,
		possession_id,
		action_sequence,
		primary_player_id,
		secondary_player_id,
		tertiary_player_id,
		action_id,
		detail_id,
		zone_id,
		points,
		amount,
		next_team_id,
	)
	events.append(event)
	return event


## Advances the game clock the writer stamps onto subsequent events. Time is
## carried by event timestamps rather than by a side channel, so the clock — and
## with it every minute played — reconciles from the ledger alone.
func consume(elapsed_ms: int) -> int:
	assert(elapsed_ms >= 0, "time cannot run backwards")
	var applied: int = mini(elapsed_ms, clock_ms)
	clock_ms -= applied
	return applied
