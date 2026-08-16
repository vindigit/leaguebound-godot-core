class_name MatchFinalResult
extends RefCounted

## The immutable committed result (`SIMULATION_SPEC.md` §25).
##
## Career systems consume this through one idempotent command. The engine "does
## not award cash, followers, Attribute Points, Badge Development Points,
## finalized awards, offers, or relationships directly", and nothing on this
## type is a career fact — it is evidence.
##
## The ruleset and balance versions travel with the result because §5.2 of
## `GODOT_TDD.md` requires a committed result to store what is needed to
## reproduce it.

var match_id: StringName
var game_id: StringName
var rule_profile_id: StringName
var rule_profile_version: StringName
var balance_profile_id: StringName
var balance_profile_version: StringName
var ratings_profile_version: StringName
var home_team_id: StringName
var away_team_id: StringName
var home_score: int
var away_score: int
var overtime_periods: int
var statistics: MatchStatistics
var final_event_sequence: int


func _init(
	p_match_id: StringName = &"match",
	p_game_id: StringName = &"game",
	p_rule_profile_id: StringName = &"rules",
	p_rule_profile_version: StringName = &"v1",
	p_balance_profile_id: StringName = &"balance",
	p_balance_profile_version: StringName = &"v1",
	p_home_team_id: StringName = &"home",
	p_away_team_id: StringName = &"away",
	p_home_score: int = 0,
	p_away_score: int = 0,
	p_overtime_periods: int = 0,
	p_statistics: MatchStatistics = null,
	p_final_event_sequence: int = 0,
	p_ratings_profile_version: StringName = &"ratings-v1",
) -> void:
	match_id = p_match_id
	game_id = p_game_id
	rule_profile_id = p_rule_profile_id
	rule_profile_version = p_rule_profile_version
	balance_profile_id = p_balance_profile_id
	balance_profile_version = p_balance_profile_version
	ratings_profile_version = p_ratings_profile_version
	home_team_id = p_home_team_id
	away_team_id = p_away_team_id
	home_score = p_home_score
	away_score = p_away_score
	overtime_periods = p_overtime_periods
	statistics = p_statistics if p_statistics != null else MatchStatistics.new()
	final_event_sequence = p_final_event_sequence


func period_scores(team_id: StringName) -> Array[int]:
	return statistics.team_line(team_id).period_scores.duplicate()


func signature() -> String:
	return "%s|%s|%s|%s|%s|%d|%d|%d|%d|%s" % [
		match_id, game_id, rule_profile_version, balance_profile_version,
		ratings_profile_version, home_score, away_score, overtime_periods,
		final_event_sequence, statistics.signature(),
	]
