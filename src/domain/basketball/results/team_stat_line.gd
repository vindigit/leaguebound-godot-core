class_name TeamStatLine
extends RefCounted

## The required team and game statistics (`SIMULATION_SPEC.md` §24.2).
##
## `engine_possessions` and `possession_estimate` are deliberately separate.
## The Stage 3 contract requires engine possessions to come from terminal
## possession records; the estimate is the conventional
## `FGA + w·FTA − ORB + TOV` figure kept beside it so calibration reports can
## compare the two without either becoming the other.

var team_id: StringName
var points: int = 0
var field_goals_made: int = 0
var field_goals_attempted: int = 0
var three_pointers_made: int = 0
var three_pointers_attempted: int = 0
var free_throws_made: int = 0
var free_throws_attempted: int = 0
var offensive_rebounds: int = 0
var defensive_rebounds: int = 0
var assists: int = 0
## §11.3: made field goals whose ledger event carries a recorded creator. Team
## assists can never exceed this, which is the reconciliation that makes assist
## attribution checkable from the box score rather than only from the ledger.
var assisted_field_goals_made: int = 0
var steals: int = 0
var blocks: int = 0
var turnovers: int = 0
var personal_fouls: int = 0
## §13: team fouls accumulated across the game, and the number of periods in
## which the team reached the rule profile's bonus threshold.
var team_fouls: int = 0
var periods_in_bonus: int = 0
var bonus_free_throws_awarded: int = 0
## §24.2 engine possessions, counted from terminal possession records.
var engine_possessions: int = 0
var possession_estimate: float = 0.0
var paint_attempts: int = 0
var paint_points: int = 0
var transition_points: int = 0
var second_chance_points: int = 0
var period_scores: Array[int] = []
var largest_lead: int = 0
var lead_changes: int = 0
var ties: int = 0


func _init(p_team_id: StringName = &"team") -> void:
	team_id = p_team_id
	period_scores = []


func total_rebounds() -> int:
	return offensive_rebounds + defensive_rebounds


## §14 / Stage 3 rebounding contract: offensive rebound percentage is
## `ORB / (ORB + opponent DREB)` on reboundable misses. The opponent line is a
## required argument precisely because the denominator is not self-contained.
func offensive_rebound_percentage(opponent: TeamStatLine) -> float:
	var denominator: int = offensive_rebounds + opponent.defensive_rebounds
	if denominator <= 0:
		return 0.0
	return float(offensive_rebounds) / float(denominator)


func points_reconcile() -> bool:
	var two_point_makes: int = field_goals_made - three_pointers_made
	return points == two_point_makes * 2 + three_pointers_made * 3 + free_throws_made


func signature() -> String:
	var periods: PackedStringArray = []
	for score in period_scores:
		periods.append(str(score))
	return "%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%.2f:%d:%d:%d:%d:%s:%d:%d:%d" % [
		team_id, points, field_goals_made, field_goals_attempted,
		three_pointers_made, three_pointers_attempted,
		free_throws_made, free_throws_attempted,
		offensive_rebounds, defensive_rebounds, assists, assisted_field_goals_made,
		steals, blocks,
		turnovers, personal_fouls, team_fouls, periods_in_bonus,
		engine_possessions, possession_estimate,
		paint_attempts, paint_points, transition_points, second_chance_points,
		",".join(periods), largest_lead, lead_changes, ties,
	]
