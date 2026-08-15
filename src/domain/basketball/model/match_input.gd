class_name MatchInput
extends RefCounted


var match_id: StringName
var game_id: StringName
var rule_profile: CompetitionRuleProfile
var balance_profile: SimulationBalanceProfile
var home: TeamMatchProfile
var away: TeamMatchProfile
var initial_possession_team_id: StringName


func _init(
	p_match_id: StringName = &"match",
	p_game_id: StringName = &"game",
	p_rule_profile: CompetitionRuleProfile = null,
	p_balance_profile: SimulationBalanceProfile = null,
	p_home: TeamMatchProfile = null,
	p_away: TeamMatchProfile = null,
	p_initial_possession_team_id: StringName = &"",
) -> void:
	assert(not p_match_id.is_empty() and not p_game_id.is_empty(), "match and game identity are required")
	assert(p_rule_profile != null and p_balance_profile != null, "versioned rule and balance profiles are required")
	assert(p_home != null and p_away != null, "two validated team profiles are required")
	assert(p_home.team_id != p_away.team_id, "home and away identities must differ")
	assert(
		p_initial_possession_team_id == p_home.team_id or p_initial_possession_team_id == p_away.team_id,
		"initial possession must belong to one supplied team"
	)
	match_id = p_match_id
	game_id = p_game_id
	rule_profile = p_rule_profile
	balance_profile = p_balance_profile
	home = p_home
	away = p_away
	initial_possession_team_id = p_initial_possession_team_id
