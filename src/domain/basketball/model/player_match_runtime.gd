class_name PlayerMatchRuntime
extends RefCounted

## Mutable match-only state for one player (`SIMULATION_SPEC.md` §6).
##
## Acute fatigue is the hidden 0-100 value `BALANCE_SPEC.md` §15.1 defines, not
## a normalized share: the band table, the substitution threshold, and the
## capability penalty are all expressed on that scale, and converting at three
## call sites is how they drift apart.
##
## Availability facts live here and in `InjuryLimitation` — never in the
## rotation role (§10.6.1). A fouled-out Starter is still a Starter.

var player_id: StringName
var on_court: bool
var started: bool
var played_ms: int
var stint_ms: int
var rest_ms: int
var acute_fatigue: float
var foul_count: int
var fouled_out: bool
var ejected: bool
var touches: int
var usage_events: int
var matchup_id: StringName
var hot_context: float
var medically_available: bool


func _init(p_player_id: StringName = &"player", p_on_court: bool = false) -> void:
	player_id = p_player_id
	on_court = p_on_court
	started = p_on_court
	played_ms = 0
	stint_ms = 0
	rest_ms = 0
	acute_fatigue = 0.0
	foul_count = 0
	fouled_out = false
	ejected = false
	touches = 0
	usage_events = 0
	matchup_id = &""
	hot_context = 0.0
	medically_available = true


func copy() -> PlayerMatchRuntime:
	var result := PlayerMatchRuntime.new(player_id, on_court)
	result.started = started
	result.played_ms = played_ms
	result.stint_ms = stint_ms
	result.rest_ms = rest_ms
	result.acute_fatigue = acute_fatigue
	result.foul_count = foul_count
	result.fouled_out = fouled_out
	result.ejected = ejected
	result.touches = touches
	result.usage_events = usage_events
	result.matchup_id = matchup_id
	result.hot_context = hot_context
	result.medically_available = medically_available
	return result


func seconds_played() -> int:
	return played_ms / 1000


## §5.1: "A player who has fouled out, been ejected, or become medically
## unavailable cannot re-enter."
func is_eligible_to_play() -> bool:
	return medically_available and not fouled_out and not ejected


## Normalized remaining energy, for presentation and for the fatigue
## availability factor in the §10.3 weight construction.
func current_energy() -> float:
	return clampf(1.0 - acute_fatigue / 100.0, 0.0, 1.0)
