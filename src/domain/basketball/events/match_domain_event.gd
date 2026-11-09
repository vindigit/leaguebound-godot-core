class_name MatchDomainEvent
extends RefCounted

## One ordered domain event (`SIMULATION_SPEC.md` §24.3).
##
## "Every official statistic derives from an ordered domain event with unique
## sequence ID. Applying the same event twice is rejected."
##
## The schema is fixed and typed rather than an open payload: `GODOT_TDD.md`
## §3.2 forbids untyped `Dictionary` payloads at cross-layer boundaries, and a
## fixed field order is what makes canonical serialization (and therefore the
## golden ledgers) possible at all. Field order below **is** the serialization
## order; changing it changes every golden hash and requires the fixtures to be
## regenerated deliberately.

# --- lifecycle --------------------------------------------------------------
const PERIOD_STARTED: StringName = &"period_started"
const PERIOD_ENDED: StringName = &"period_ended"
const MATCH_ENDED: StringName = &"match_ended"
const CHECK_IN: StringName = &"check_in"
const CHECK_OUT: StringName = &"check_out"

# --- possession structure ---------------------------------------------------
const POSSESSION_STARTED: StringName = &"possession_started"
const POSSESSION_ENDED: StringName = &"possession_ended"
const INBOUND: StringName = &"inbound"
const ADVANCE: StringName = &"advance"
const TRANSITION_ENTERED: StringName = &"transition_entered"
const HALF_COURT_ENTERED: StringName = &"half_court_entered"
const SHOT_CLOCK_RESET: StringName = &"shot_clock_reset"
const TIMEOUT: StringName = &"timeout"
const GARBAGE_TIME: StringName = &"garbage_time"
const ACTION_SELECTED: StringName = &"action_selected"

# --- action resolution ------------------------------------------------------
const PASS_COMPLETED: StringName = &"pass_completed"
const SCREEN_SET: StringName = &"screen_set"
const OFF_BALL_ACTION: StringName = &"off_ball_action"
const HELP_ROTATION: StringName = &"help_rotation"
const BOX_OUT: StringName = &"box_out"
const ADVANTAGE_CREATED: StringName = &"advantage_created"
const TURNOVER: StringName = &"turnover"
const STEAL: StringName = &"steal"

# --- shooting ---------------------------------------------------------------
const FIELD_GOAL_ATTEMPT: StringName = &"field_goal_attempt"
const FIELD_GOAL_MADE: StringName = &"field_goal_made"
const FIELD_GOAL_MISSED: StringName = &"field_goal_missed"
const BLOCK: StringName = &"block"
const ASSIST: StringName = &"assist"

# --- fouls and free throws --------------------------------------------------
const FOUL: StringName = &"foul"
const FOUL_OUT: StringName = &"foul_out"
const FREE_THROW_AWARDED: StringName = &"free_throw_awarded"
const FREE_THROW_MADE: StringName = &"free_throw_made"
const FREE_THROW_MISSED: StringName = &"free_throw_missed"

# --- rebounding -------------------------------------------------------------
const REBOUND: StringName = &"rebound"

const REBOUND_OFFENSIVE: StringName = &"offensive"
const REBOUND_DEFENSIVE: StringName = &"defensive"

var match_id: StringName
var sequence: int
var period: int
var clock_ms: int
var event_type: StringName
## The team the event belongs to. On `POSSESSION_ENDED` this is the offense
## whose possession ended, never the team receiving the ball next.
var team_id: StringName
var possession_id: int
## Stable ordering inside the possession. Lifecycle events outside a possession
## carry zero.
var action_sequence: int
var primary_player_id: StringName
var secondary_player_id: StringName
var tertiary_player_id: StringName
## Action family id, or the sub-action detail for lifecycle events.
var action_id: StringName
## Cause, foul type, rebound side, advantage level, or contest band.
var detail_id: StringName
var zone_id: StringName
var points: int
## A small typed integer whose meaning is fixed per event type: free-throw
## index, awarded free-throw count, or reset milliseconds.
var amount: int
## Explicit next-possession ownership on `POSSESSION_ENDED`.
var next_team_id: StringName


func _init(
	p_match_id: StringName = &"match",
	p_sequence: int = 1,
	p_period: int = 1,
	p_clock_ms: int = 0,
	p_event_type: StringName = &"event",
	p_team_id: StringName = &"",
	p_possession_id: int = 0,
	p_action_sequence: int = 0,
	p_primary_player_id: StringName = &"",
	p_secondary_player_id: StringName = &"",
	p_tertiary_player_id: StringName = &"",
	p_action_id: StringName = &"",
	p_detail_id: StringName = &"",
	p_zone_id: StringName = &"",
	p_points: int = 0,
	p_amount: int = 0,
	p_next_team_id: StringName = &"",
) -> void:
	assert(p_sequence > 0, "event sequence must be positive")
	assert(p_period > 0 and p_clock_ms >= 0, "event time is invalid")
	assert(not p_event_type.is_empty(), "event type is required")
	assert(p_points >= 0 and p_points <= 3, "event points are invalid")
	assert(p_possession_id >= 0 and p_action_sequence >= 0, "possession identity is invalid")
	match_id = p_match_id
	sequence = p_sequence
	period = p_period
	clock_ms = p_clock_ms
	event_type = p_event_type
	team_id = p_team_id
	possession_id = p_possession_id
	action_sequence = p_action_sequence
	primary_player_id = p_primary_player_id
	secondary_player_id = p_secondary_player_id
	tertiary_player_id = p_tertiary_player_id
	action_id = p_action_id
	detail_id = p_detail_id
	zone_id = p_zone_id
	points = p_points
	amount = p_amount
	next_team_id = p_next_team_id


## Canonical serialization with explicit field order (Stage 3 determinism
## contract). Never derived from `get_property_list()` or raw Variant bytes:
## both depend on declaration or engine internals rather than on an agreed
## contract.
func signature() -> String:
	return "%s|%d|%d|%d|%s|%s|%d|%d|%s|%s|%s|%s|%s|%s|%d|%d|%s" % [
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
	]
