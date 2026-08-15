class_name PossessionContext
extends RefCounted


var offense: TeamMatchProfile
var defense: TeamMatchProfile
var period: int
var clock_ms: int
var home_score: int
var away_score: int


func _init(
	p_offense: TeamMatchProfile = null,
	p_defense: TeamMatchProfile = null,
	p_period: int = 1,
	p_clock_ms: int = 0,
	p_home_score: int = 0,
	p_away_score: int = 0,
) -> void:
	assert(p_offense != null and p_defense != null, "a possession requires offense and defense")
	assert(p_offense.team_id != p_defense.team_id, "offense and defense must differ")
	assert(p_period > 0 and p_clock_ms >= 0, "period and clock context are invalid")
	offense = p_offense
	defense = p_defense
	period = p_period
	clock_ms = p_clock_ms
	home_score = p_home_score
	away_score = p_away_score
