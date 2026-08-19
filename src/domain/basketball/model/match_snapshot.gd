class_name MatchSnapshot
extends RefCounted

## Authoritative match state (`SIMULATION_SPEC.md` §5).
##
## §5.1: "Score, clock, possession, fouls, and box score can change only through
## domain events." That invariant is enforced structurally in Stage 3 — every
## field here is written by `MatchStateReducer` folding the ordered ledger, and
## by nothing else. The possession engine reduces onto its own working copy with
## the same function, so the state it decides from and the state the ledger
## produces cannot diverge.

var match_id: StringName
var period: int
var clock_ms: int
## The shot clock for the live possession. Reset on a new possession and, per
## the rule profile, on an offensive rebound (§9.4).
var shot_clock_ms: int
var home: TeamMatchState
var away: TeamMatchState
## The offense of the live possession, or the team that will inbound next.
var possession_team_id: StringName
## Explicit next-possession ownership. The Stage 3 contract forbids overloading
## `POSSESSION_ENDED.team_id` with this: that field identifies the offense whose
## possession ended.
var next_possession_team_id: StringName
## Stable identity of the live possession; zero when no possession is live.
var possession_id: int
## Count of possessions started, which is also the next possession id.
var possession_sequence: int
var event_sequence: int
var overtime_periods: int
var completed: bool


func _init(input: MatchInput = null) -> void:
	if input == null:
		match_id = &""
		period = 1
		clock_ms = 0
		shot_clock_ms = 0
		home = TeamMatchState.new()
		away = TeamMatchState.new()
		possession_team_id = &""
		next_possession_team_id = &""
		possession_id = 0
		possession_sequence = 0
		event_sequence = 0
		overtime_periods = 0
		completed = false
		return
	match_id = input.match_id
	period = 1
	clock_ms = input.rule_profile.period_seconds * 1000
	shot_clock_ms = input.rule_profile.shot_clock_seconds * 1000
	home = TeamMatchState.new(input.home)
	away = TeamMatchState.new(input.away)
	home.timeouts_remaining = input.rule_profile.timeouts_per_team
	away.timeouts_remaining = input.rule_profile.timeouts_per_team
	possession_team_id = input.initial_possession_team_id
	next_possession_team_id = input.initial_possession_team_id
	possession_id = 0
	possession_sequence = 0
	event_sequence = 0
	overtime_periods = 0
	completed = false


func copy() -> MatchSnapshot:
	var result := MatchSnapshot.new()
	result.match_id = match_id
	result.period = period
	result.clock_ms = clock_ms
	result.shot_clock_ms = shot_clock_ms
	result.home = home.copy()
	result.away = away.copy()
	result.possession_team_id = possession_team_id
	result.next_possession_team_id = next_possession_team_id
	result.possession_id = possession_id
	result.possession_sequence = possession_sequence
	result.event_sequence = event_sequence
	result.overtime_periods = overtime_periods
	result.completed = completed
	return result


func state_for(team_id: StringName) -> TeamMatchState:
	if team_id == home.team_id:
		return home
	assert(team_id == away.team_id, "unknown team identity")
	return away


func score_for(team_id: StringName) -> int:
	return state_for(team_id).score


func opposing_team_id(team_id: StringName) -> StringName:
	if team_id == home.team_id:
		return away.team_id
	assert(team_id == away.team_id, "unknown team identity")
	return home.team_id


## The scoring margin from one team's point of view, used by the §10.3
## score/clock factor and by late-game foul strategy.
func margin_for(team_id: StringName) -> int:
	return score_for(team_id) - score_for(opposing_team_id(team_id))


func is_final_regulation_or_later(rules: CompetitionRuleProfile) -> bool:
	return period >= rules.regulation_periods
