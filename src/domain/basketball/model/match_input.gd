class_name MatchInput
extends RefCounted

## The immutable, upstream-validated input to one match (`GODOT_TDD.md` §5.3).
##
## Career and world services validate the legal roster, game-day registration,
## eligibility, and availability *before* this exists (`SIMULATION_SPEC.md` §5).
## The engine never invents membership, contracts, rights, assignments, import
## changes, or replacement players; it consumes what it is handed.

var match_id: StringName
var game_id: StringName
var rule_profile: CompetitionRuleProfile
var balance_profile: SimulationBalanceProfile
## The §5.2 capability weight table travels with the match so a resolver never
## re-derives rating weights of its own.
var ratings_profile: RatingsProfile
var home: TeamMatchProfile
var away: TeamMatchProfile
var initial_possession_team_id: StringName
## §19.4 home environment strength, normalized. Bounded officiating,
## communication, composure, and familiarity effects only; it never guarantees
## an outcome.
var home_environment: float


func _init(
	p_match_id: StringName = &"match",
	p_game_id: StringName = &"game",
	p_rule_profile: CompetitionRuleProfile = null,
	p_balance_profile: SimulationBalanceProfile = null,
	p_home: TeamMatchProfile = null,
	p_away: TeamMatchProfile = null,
	p_initial_possession_team_id: StringName = &"",
	p_ratings_profile: RatingsProfile = null,
	p_home_environment: float = 0.5,
) -> void:
	assert(not p_match_id.is_empty() and not p_game_id.is_empty(),
		"match and game identity are required")
	assert(p_rule_profile != null and p_balance_profile != null,
		"versioned rule and balance profiles are required")
	assert(p_home != null and p_away != null, "two validated team profiles are required")
	assert(p_home.team_id != p_away.team_id, "home and away identities must differ")
	assert(
		p_initial_possession_team_id == p_home.team_id
		or p_initial_possession_team_id == p_away.team_id,
		"initial possession must belong to one supplied team"
	)
	assert(p_home_environment >= 0.0 and p_home_environment <= 1.0,
		"home environment strength must be normalized")
	match_id = p_match_id
	game_id = p_game_id
	rule_profile = p_rule_profile
	balance_profile = p_balance_profile
	ratings_profile = p_ratings_profile if p_ratings_profile != null else RatingsProfile.default_profile()
	home = p_home
	away = p_away
	initial_possession_team_id = p_initial_possession_team_id
	home_environment = p_home_environment


func team_profile(team_id: StringName) -> TeamMatchProfile:
	if team_id == home.team_id:
		return home
	assert(team_id == away.team_id, "unknown team identity")
	return away


func opposing_team_id(team_id: StringName) -> StringName:
	if team_id == home.team_id:
		return away.team_id
	assert(team_id == away.team_id, "unknown team identity")
	return home.team_id


func is_home(team_id: StringName) -> bool:
	return team_id == home.team_id
