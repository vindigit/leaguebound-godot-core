class_name MatchMetricAccumulator
extends RefCounted

## Accumulates the `BALANCE_SPEC.md` §14 team, game-shape, and role metrics over
## a batch of complete games.
##
## Every rate below is a ratio of two accumulated totals, never a mean of
## per-game ratios: averaging per-game percentages weights a 60-attempt game the
## same as a 90-attempt one and produces a number that does not match the
## league's own arithmetic. The `definition` strings the runner publishes name
## the numerator and denominator explicitly for the same reason.
##
## Two possession figures are kept side by side and never mixed. Engine
## possessions come from terminal possession records; the classic estimate
## `FGA + w*FTA - ORB + TOV` is reported beside it. §14 bands judge engine
## possessions. **Offensive rebound percentage uses `ORB / (ORB + opponent
## DREB)` and never a possession count as its denominator.**

# --- team totals, summed over every team-game -------------------------------
var team_games: int = 0
var games: int = 0
var overtime_games: int = 0
var home_wins: int = 0
var decided_games: int = 0
var close_games: int = 0
var blowout_games: int = 0

var points: int = 0
var engine_possessions: int = 0
var possession_estimate: float = 0.0
var field_goals_made: int = 0
var field_goals_attempted: int = 0
var three_pointers_made: int = 0
var three_pointers_attempted: int = 0
var free_throws_made: int = 0
var free_throws_attempted: int = 0
var offensive_rebounds: int = 0
var defensive_rebounds: int = 0
## The §14 offensive-rebound denominator: own ORB plus the opponent's DREB.
var offensive_rebound_chances: int = 0
var assists: int = 0
var steals: int = 0
var blocks: int = 0
var turnovers: int = 0
var personal_fouls: int = 0
var paint_points: int = 0
var second_chance_points: int = 0

# --- per-rotation-role minutes and usage ------------------------------------
var minutes_by_rotation_role: PackedFloat64Array
var appearances_by_rotation_role: PackedInt32Array
var usage_by_rotation_role: PackedInt32Array
var starts_by_rotation_role: PackedInt32Array

# --- per-tactical-role shot zone mix ----------------------------------------
var attempts_by_tactical_role: PackedInt32Array
var three_attempts_by_tactical_role: PackedInt32Array
var paint_attempts_by_tactical_role: PackedInt32Array

# --- player-level distributions for leader plausibility ---------------------
var top_scorer_points: PackedFloat64Array
var starter_minutes: PackedFloat64Array
## Per-team-game points, kept so the report can publish an interval rather than
## a bare mean.
var team_game_points: PackedFloat64Array
var team_game_possessions: PackedFloat64Array
## Per-team-game field goals made and attempted.
##
## Field-goal percentage is a **ratio of two totals**, not a mean of independent
## Bernoulli trials: the attempts inside one team-game share a roster, a
## matchup, a game plan and a fatigue path, so they are correlated and a
## binomial interval over `field_goals_attempted` understates the width. These
## two series are the clusters the ratio estimator needs, kept for the same
## reason `team_game_points` and `team_game_possessions` are kept for points per
## possession.
var team_game_field_goals_made: PackedFloat64Array
var team_game_field_goals_attempted: PackedFloat64Array


func _init() -> void:
	minutes_by_rotation_role = _blank_float(RotationRole.COUNT)
	appearances_by_rotation_role = _blank_int(RotationRole.COUNT)
	usage_by_rotation_role = _blank_int(RotationRole.COUNT)
	starts_by_rotation_role = _blank_int(RotationRole.COUNT)
	attempts_by_tactical_role = _blank_int(TacticalRole.COUNT)
	three_attempts_by_tactical_role = _blank_int(TacticalRole.COUNT)
	paint_attempts_by_tactical_role = _blank_int(TacticalRole.COUNT)
	top_scorer_points = PackedFloat64Array()
	starter_minutes = PackedFloat64Array()
	team_game_points = PackedFloat64Array()
	team_game_possessions = PackedFloat64Array()
	team_game_field_goals_made = PackedFloat64Array()
	team_game_field_goals_attempted = PackedFloat64Array()


func accumulate(input: MatchInput, output: MatchSimulationOutput) -> void:
	var result: MatchFinalResult = output.final_result
	var statistics: MatchStatistics = result.statistics
	games += 1
	if result.overtime_periods > 0:
		overtime_games += 1
	var margin: int = absi(result.home_score - result.away_score)
	if margin > 0:
		decided_games += 1
		if result.home_score > result.away_score:
			home_wins += 1
	if margin <= 5:
		close_games += 1
	if margin >= 20:
		blowout_games += 1

	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		var line: TeamStatLine = statistics.team_line(team_id)
		var opponent: TeamStatLine = statistics.team_line(input.opposing_team_id(team_id))
		_accumulate_team(line, opponent)
		_accumulate_players(input, statistics, team_id)


func _accumulate_team(line: TeamStatLine, opponent: TeamStatLine) -> void:
	team_games += 1
	points += line.points
	engine_possessions += line.engine_possessions
	possession_estimate += line.possession_estimate
	field_goals_made += line.field_goals_made
	field_goals_attempted += line.field_goals_attempted
	three_pointers_made += line.three_pointers_made
	three_pointers_attempted += line.three_pointers_attempted
	free_throws_made += line.free_throws_made
	free_throws_attempted += line.free_throws_attempted
	offensive_rebounds += line.offensive_rebounds
	defensive_rebounds += line.defensive_rebounds
	offensive_rebound_chances += line.offensive_rebounds + opponent.defensive_rebounds
	assists += line.assists
	steals += line.steals
	blocks += line.blocks
	turnovers += line.turnovers
	personal_fouls += line.personal_fouls
	paint_points += line.paint_points
	second_chance_points += line.second_chance_points
	team_game_points.append(float(line.points))
	team_game_possessions.append(float(line.engine_possessions))
	team_game_field_goals_made.append(float(line.field_goals_made))
	team_game_field_goals_attempted.append(float(line.field_goals_attempted))


func _accumulate_players(
	input: MatchInput,
	statistics: MatchStatistics,
	team_id: StringName,
) -> void:
	var profile: TeamMatchProfile = input.team_profile(team_id)
	var best_points: int = 0
	for line in statistics.players_for(team_id):
		var player: PlayerMatchProfile = profile.player_by_id(line.player_id)
		var minutes: float = float(line.seconds_played) / 60.0
		minutes_by_rotation_role[player.rotation_role] += minutes
		appearances_by_rotation_role[player.rotation_role] += 1
		usage_by_rotation_role[player.rotation_role] += (
			line.field_goals_attempted + line.turnovers)
		if line.started:
			starts_by_rotation_role[player.rotation_role] += 1
			starter_minutes.append(minutes)
		var role: int = player.tactical_role.role
		attempts_by_tactical_role[role] += line.field_goals_attempted
		three_attempts_by_tactical_role[role] += line.three_pointers_attempted
		paint_attempts_by_tactical_role[role] += line.paint_attempts
		best_points = maxi(best_points, line.points)
	top_scorer_points.append(float(best_points))


# --- derived rates -----------------------------------------------------------

func possessions_per_game() -> float:
	return _ratio(float(engine_possessions), float(team_games))


func possession_estimate_per_game() -> float:
	return _ratio(possession_estimate, float(team_games))


func points_per_game() -> float:
	return _ratio(float(points), float(team_games))


func points_per_possession() -> float:
	return _ratio(float(points), float(engine_possessions))


## The 95% half-width of points per possession.
##
## Points per possession is a *ratio of two sums*, not a mean and not a
## proportion, so neither of the intervals this class already knows how to make
## is the right one: the numerator and the denominator both vary from team-game
## to team-game and they covary strongly — a fast game scores more points and
## uses more possessions. The linearized ratio estimator is the interval that
## accounts for that, and without it the §14.1 row most likely to sit on its
## band boundary is the one row published with no interval at all.
func points_per_possession_half_width() -> float:
	return ratio_half_width(team_game_points, team_game_possessions, points_per_possession())


## The 95% half-width of field-goal percentage, treating each team-game as the
## sampling unit.
##
## §14.1 judges a *rate*, and the rate's uncertainty is not binomial. Attempts
## within a team-game are drawn against one opponent, by one roster, down one
## fatigue path, so they are positively correlated; a binomial interval over the
## attempt count assumes they are independent games and reports a width that is
## too narrow — for a 400-game run, by roughly a factor of two. This is the same
## clustered ratio estimator `points_per_possession_half_width` uses, and it is
## the interval a §14.1 verdict on field-goal percentage must be read against.
func field_goal_percentage_half_width() -> float:
	return ratio_half_width(
		team_game_field_goals_made,
		team_game_field_goals_attempted,
		field_goal_percentage())


## The 95% half-width of `sum(numerators) / sum(denominators)` over paired
## per-cluster series, by the standard linearized ratio estimator: the residual
## `y_i - R * x_i` carries the covariance the two totals share, which is exactly
## what makes a ratio's variance different from either total's own.
static func ratio_half_width(
	numerators: PackedFloat64Array,
	denominators: PackedFloat64Array,
	estimate: float,
) -> float:
	var count: int = denominators.size()
	if count < 2 or numerators.size() != count:
		return 0.0
	var mean_denominator: float = 0.0
	for value in denominators:
		mean_denominator += value
	mean_denominator /= float(count)
	if mean_denominator <= 0.0:
		return 0.0
	var residual_sum: float = 0.0
	for index in range(count):
		var residual: float = numerators[index] - estimate * denominators[index]
		residual_sum += residual * residual
	var variance: float = residual_sum / float(count - 1)
	return 1.96 * sqrt(variance / float(count)) / mean_denominator


func field_goal_percentage() -> float:
	return _ratio(float(field_goals_made), float(field_goals_attempted))


func three_point_percentage() -> float:
	return _ratio(float(three_pointers_made), float(three_pointers_attempted))


func three_point_attempt_rate() -> float:
	return _ratio(float(three_pointers_attempted), float(field_goals_attempted))


func free_throw_percentage() -> float:
	return _ratio(float(free_throws_made), float(free_throws_attempted))


func free_throw_attempt_rate() -> float:
	return _ratio(float(free_throws_attempted), float(field_goals_attempted))


func turnovers_per_100_possessions() -> float:
	return 100.0 * _ratio(float(turnovers), float(engine_possessions))


## `ORB / (ORB + opponent DREB)`. Never a possession count.
func offensive_rebound_percentage() -> float:
	return _ratio(float(offensive_rebounds), float(offensive_rebound_chances))


## Assists as a share of the team's own made field goals.
func assist_percentage() -> float:
	return _ratio(float(assists), float(field_goals_made))


func steals_per_game() -> float:
	return _ratio(float(steals), float(team_games))


func blocks_per_game() -> float:
	return _ratio(float(blocks), float(team_games))


func fouls_per_game() -> float:
	return _ratio(float(personal_fouls), float(team_games))


func home_win_rate() -> float:
	return _ratio(float(home_wins), float(decided_games))


func overtime_rate() -> float:
	return _ratio(float(overtime_games), float(games))


func close_game_rate() -> float:
	return _ratio(float(close_games), float(games))


func blowout_rate() -> float:
	return _ratio(float(blowout_games), float(games))


func mean_minutes_for_rotation_role(role: int) -> float:
	return _ratio(minutes_by_rotation_role[role], float(appearances_by_rotation_role[role]))


func three_attempt_share_for_tactical_role(role: int) -> float:
	return _ratio(
		float(three_attempts_by_tactical_role[role]), float(attempts_by_tactical_role[role]))


func paint_attempt_share_for_tactical_role(role: int) -> float:
	return _ratio(
		float(paint_attempts_by_tactical_role[role]), float(attempts_by_tactical_role[role]))


## The machine-readable per-role rows the report archives.
func role_rows() -> Array:
	var rows: Array = []
	for role in RotationRole.all():
		if appearances_by_rotation_role[role] <= 0:
			continue
		rows.append({
			"rotation_role": String(RotationRole.id_of(role)),
			"appearances": appearances_by_rotation_role[role],
			"mean_minutes": mean_minutes_for_rotation_role(role),
			"starts": starts_by_rotation_role[role],
			"mean_usage_events": _ratio(
				float(usage_by_rotation_role[role]),
				float(appearances_by_rotation_role[role])),
		})
	return rows


func tactical_role_rows() -> Array:
	var rows: Array = []
	for role in TacticalRole.all():
		if attempts_by_tactical_role[role] <= 0:
			continue
		rows.append({
			"tactical_role": String(TacticalRole.id_of(role)),
			"field_goal_attempts": attempts_by_tactical_role[role],
			"three_point_attempt_share": three_attempt_share_for_tactical_role(role),
			"paint_attempt_share": paint_attempt_share_for_tactical_role(role),
		})
	return rows


# --- interval helpers --------------------------------------------------------

## The 95% half-width on a rate formed from two accumulated counts, treating the
## numerator as binomial in the denominator.
func proportion_half_width(successes: int, trials: int) -> float:
	if trials <= 0:
		return 0.0
	var p: float = float(successes) / float(trials)
	return CalibrationStatistics.Z_95 * sqrt(maxf(p * (1.0 - p) / float(trials), 0.0))


func _ratio(numerator: float, denominator: float) -> float:
	if denominator <= 0.0:
		return 0.0
	return numerator / denominator


func _blank_float(size: int) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	values.resize(size)
	values.fill(0.0)
	return values


func _blank_int(size: int) -> PackedInt32Array:
	var values := PackedInt32Array()
	values.resize(size)
	values.fill(0)
	return values
