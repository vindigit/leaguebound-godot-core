class_name PossessionContext
extends RefCounted

## The live input context for one possession (`SIMULATION_SPEC.md` §9.3).
##
## The spec's `PossessionContext` lists offense and defense lineups, score,
## clock, spacing, matchups, both game plans, chemistry, and home environment.
## This carries the same information by reference to the authoritative state
## rather than by copying it, because the possession engine reduces its own
## events onto that state as it goes: a context that had snapshotted the lineup
## would be reading a lineup one substitution out of date, which is precisely
## the defect Stage 3 exists to remove.

var input: MatchInput
## The working snapshot. Authoritative for lineup, fouls, clock, and score
## throughout resolution.
var state: MatchSnapshot
var offense: TeamMatchProfile
var defense: TeamMatchProfile
var matchups: MatchupState
var possession_id: int
## Ball location and possession-history facts the action families read.
var ball_handler_id: StringName
var last_passer_id: StringName
var last_pass_created_advantage: bool
var in_transition: bool
var offensive_rebounds: int
var action_count: int
var advantage: AdvantageResult


func _init(
	p_input: MatchInput,
	p_state: MatchSnapshot,
	p_offense_team_id: StringName,
	p_matchups: MatchupState,
	p_possession_id: int,
) -> void:
	assert(p_input != null and p_state != null, "a possession requires input and state")
	assert(p_matchups != null, "a possession requires resolved defensive assignments")
	input = p_input
	state = p_state
	offense = p_input.team_profile(p_offense_team_id)
	defense = p_input.team_profile(p_input.opposing_team_id(p_offense_team_id))
	matchups = p_matchups
	possession_id = p_possession_id
	ball_handler_id = &""
	last_passer_id = &""
	last_pass_created_advantage = false
	in_transition = false
	offensive_rebounds = 0
	action_count = 0
	advantage = AdvantageResult.new()


func offense_state() -> TeamMatchState:
	return state.state_for(offense.team_id)


func defense_state() -> TeamMatchState:
	return state.state_for(defense.team_id)


func offense_on_court() -> Array[StringName]:
	return offense_state().on_court_ids()


func defense_on_court() -> Array[StringName]:
	return defense_state().on_court_ids()


func offense_profile(player_id: StringName) -> PlayerMatchProfile:
	return offense.player_by_id(player_id)


func defense_profile(player_id: StringName) -> PlayerMatchProfile:
	return defense.player_by_id(player_id)


func offense_runtime(player_id: StringName) -> PlayerMatchRuntime:
	return offense_state().runtime_by_id(player_id)


func defense_runtime(player_id: StringName) -> PlayerMatchRuntime:
	return defense_state().runtime_by_id(player_id)


## The defender currently assigned to an offensive player, falling back to the
## nearest available on-court defender so a resolver never faces an empty
## assignment mid-switch.
func defender_of(offense_player_id: StringName) -> StringName:
	var assigned: StringName = matchups.defender_for(offense_player_id)
	if not assigned.is_empty() and defense_state().is_on_court(assigned):
		return assigned
	var on_court: Array[StringName] = defense_on_court()
	assert(not on_court.is_empty(), "a live possession requires defenders on court")
	return on_court[0]


func is_late_clock() -> bool:
	return state.shot_clock_ms <= 5000


func is_late_game() -> bool:
	return (
		state.period >= input.rule_profile.regulation_periods
		and state.clock_ms <= input.balance_profile.intentional_foul_clock_ms
	)


func offense_margin() -> int:
	return state.margin_for(offense.team_id)
