class_name PlayerStatLine
extends RefCounted

## The required player box score (`SIMULATION_SPEC.md` §24.1) plus the
## role-evaluation evidence §24.4 requires.
##
## §24.4: player match rating "can include off-ball/screen/defensive events
## unavailable in the public box score, but every contribution must have an
## engine event source." The evidence counters below are those sources — they
## are not invented statistics, and none of them appears in a public box score.
##
## Every field here is a projection of the ordered ledger. Nothing writes to a
## stat line except `BoxScoreProjector`.

var player_id: StringName
var team_id: StringName
var seconds_played: int = 0
var started: bool = false
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
var steals: int = 0
var blocks: int = 0
var turnovers: int = 0
var personal_fouls: int = 0
var fouled_out: bool = false
var plus_minus: int = 0
## §24.2 zone summary.
var paint_attempts: int = 0
var paint_points: int = 0
var dunk_attempts: int = 0
var dunks_made: int = 0

# --- §24.4 role-evaluation evidence -----------------------------------------
var touches: int = 0
var passes_completed: int = 0
var screens_set: int = 0
var screen_advantages_created: int = 0
var off_ball_actions: int = 0
var advantages_created: int = 0


func _init(p_player_id: StringName = &"player", p_team_id: StringName = &"team") -> void:
	player_id = p_player_id
	team_id = p_team_id


func total_rebounds() -> int:
	return offensive_rebounds + defensive_rebounds


func minutes_played() -> float:
	return float(seconds_played) / 60.0


## Points must equal the events that produced them. A stat line that fails this
## is unreconciled, and §14.2 puts the shipping tolerance for that at zero.
func points_reconcile() -> bool:
	var two_point_makes: int = field_goals_made - three_pointers_made
	return points == two_point_makes * 2 + three_pointers_made * 3 + free_throws_made


func signature() -> String:
	return "%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
		player_id, seconds_played, 1 if started else 0, points,
		field_goals_made, field_goals_attempted,
		three_pointers_made, three_pointers_attempted,
		free_throws_made, free_throws_attempted,
		offensive_rebounds, defensive_rebounds, assists, steals, blocks,
		turnovers, personal_fouls, 1 if fouled_out else 0, plus_minus,
		paint_attempts, paint_points, dunk_attempts, dunks_made,
		touches, screens_set, advantages_created,
	]
