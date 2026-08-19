class_name MarginDecomposition
extends RefCounted

## Where a final score margin actually came from.
##
## The Stage 4 brief asks for the final-margin variance to be partitioned into
## useful components. Two partitions are produced here and they answer different
## questions:
##
## 1. An exact additive identity. Every game's signed margin is rewritten as a
##    sum of six terms that reconstruct it to floating-point precision. Because
##    `M = sum(c_i)` holds game by game, `Var(M) = sum(Cov(c_i, M))` holds
##    exactly, so each term's covariance share is a real partition of the
##    variance and the shares sum to one. Nothing is dropped into a fudge
##    factor: the sixth term is defined as the residual of the identity and is
##    reported as such.
##
## 2. A pregame-strength regression. The margin is regressed on the
##    `TeamStrengthIndex` gap, which is fixed before tip-off. The R-squared is
##    the share of margin variance that legitimately belongs to one team being
##    better than the other; the rest is what the engine invented during the
##    game.
##
## The two partitions answer different questions on purpose. The first says
## which basketball channel carried the margin; the second says how much of it
## was earned pregame. A defect that inflates blowouts shows up as an excessive
## residual in the second and names its channel in the first.

## The exact identity, in order. `points_from_field = 2 * eFG * FGA` is an
## algebraic identity rather than an approximation, which is what lets the whole
## decomposition close.
enum Component {
	SHOOTING, ## 2 * mean(FGA) * delta eFG%
	POSSESSIONS, ## 2 * mean(eFG%) * delta engine possessions
	OFFENSIVE_REBOUNDS, ## 2 * mean(eFG%) * delta offensive rebounds
	TURNOVERS, ## -2 * mean(eFG%) * delta turnovers
	SHOT_VOLUME_RESIDUAL, ## 2 * mean(eFG%) * (delta FGA - delta poss - delta ORB + delta TOV)
	FREE_THROWS, ## delta free throws made
}

const COMPONENT_COUNT: int = 6
const COMPONENT_IDS: PackedStringArray = [
	"shooting_efficiency",
	"possessions",
	"offensive_rebounds",
	"turnovers",
	"shot_volume_residual",
	"free_throws",
]


## One completed game, reduced to the quantities the decomposition needs.
## Everything is signed home-minus-away so a component's sign means the same
## thing in every row.
class GameRow extends RefCounted:
	var variation: int
	var seed: int
	## Pregame, from `TeamStrengthIndex`. Fixed before tip-off.
	var expected_gap: float
	var home_strength: float
	var away_strength: float
	var home_starter_strength: float
	var away_starter_strength: float
	var home_bench_strength: float
	var away_bench_strength: float

	var home_score: int
	var away_score: int
	var regulation_home: int
	var regulation_away: int
	var overtime_periods: int

	var home_possessions: int
	var away_possessions: int
	var home_field_goals_attempted: int
	var away_field_goals_attempted: int
	var home_effective_field_goal: float
	var away_effective_field_goal: float
	var home_three_attempted: int
	var away_three_attempted: int
	var home_three_made: int
	var away_three_made: int
	var home_free_throws_made: int
	var away_free_throws_made: int
	var home_free_throws_attempted: int
	var away_free_throws_attempted: int
	var home_turnovers: int
	var away_turnovers: int
	var home_offensive_rebounds: int
	var away_offensive_rebounds: int
	var home_second_chance_points: int
	var away_second_chance_points: int
	var home_transition_points: int
	var away_transition_points: int
	var home_fouls: int
	var away_fouls: int
	var home_bonus_free_throws: int
	var away_bonus_free_throws: int
	var home_starter_minutes: float
	var away_starter_minutes: float
	var home_bench_minutes: float
	var away_bench_minutes: float
	var home_substitutions: int
	var away_substitutions: int
	var intentional_fouls: int
	## Check-ins whose reason is the §18.2 settled-game rotation, both teams.
	var decided_game_substitutions: int
	## Possessions scoring four or more points to one team: the tail the brief
	## calls unusually high-leverage.
	var home_high_leverage: int
	var away_high_leverage: int
	var high_leverage_points: int
	## Largest unanswered scoring run by either team, in points.
	var largest_run: int
	var period_margins: PackedFloat64Array

	## Sum of squared possession points for each team, so the within-game
	## variance of a possession outcome can be pooled across the sample. With
	## the count and the total already present, these three numbers are the
	## complete sufficient statistics for the independence test below.
	var home_possession_points_squared: float
	var away_possession_points_squared: float
	## Possessions scoring exactly 0, 1, 2, 3, and 4-or-more points, both teams.
	var possession_outcome_counts: PackedInt32Array

	func margin() -> float:
		return float(home_score - away_score)

	func absolute_margin() -> float:
		return absf(margin())

	func regulation_margin() -> float:
		return float(regulation_home - regulation_away)

	func home_points_per_possession() -> float:
		return float(home_score) / float(home_possessions) if home_possessions > 0 else 0.0

	func away_points_per_possession() -> float:
		return float(away_score) / float(away_possessions) if away_possessions > 0 else 0.0

	## The six-term identity. Summing `components()` reconstructs `margin()`.
	func components() -> PackedFloat64Array:
		var mean_attempts: float = 0.5 * float(
			home_field_goals_attempted + away_field_goals_attempted)
		var mean_efficiency: float = 0.5 * (
			home_effective_field_goal + away_effective_field_goal)
		var attempt_delta: float = float(
			home_field_goals_attempted - away_field_goals_attempted)
		var possession_delta: float = float(home_possessions - away_possessions)
		var rebound_delta: float = float(home_offensive_rebounds - away_offensive_rebounds)
		var turnover_delta: float = float(home_turnovers - away_turnovers)
		var residual_delta: float = (
			attempt_delta - possession_delta - rebound_delta + turnover_delta)
		var values := PackedFloat64Array()
		values.resize(COMPONENT_COUNT)
		values[Component.SHOOTING] = 2.0 * mean_attempts * (
			home_effective_field_goal - away_effective_field_goal)
		values[Component.POSSESSIONS] = 2.0 * mean_efficiency * possession_delta
		values[Component.OFFENSIVE_REBOUNDS] = 2.0 * mean_efficiency * rebound_delta
		values[Component.TURNOVERS] = -2.0 * mean_efficiency * turnover_delta
		values[Component.SHOT_VOLUME_RESIDUAL] = 2.0 * mean_efficiency * residual_delta
		values[Component.FREE_THROWS] = float(home_free_throws_made - away_free_throws_made)
		return values

	## How far the identity is from the realized margin. Kept as a measurement
	## rather than an assertion so the report can publish it: a decomposition
	## that silently stopped closing would otherwise keep producing confident
	## shares of the wrong total.
	func identity_error() -> float:
		var total: float = 0.0
		for value in components():
			total += value
		return absf(total - margin())

	func to_dictionary() -> Dictionary:
		return {
			"variation": variation,
			"seed": seed,
			"expected_gap": expected_gap,
			"home_strength": home_strength,
			"away_strength": away_strength,
			"home_score": home_score,
			"away_score": away_score,
			"margin": margin(),
			"regulation_margin": regulation_margin(),
			"overtime_periods": overtime_periods,
			"home_possessions": home_possessions,
			"away_possessions": away_possessions,
			"home_points_per_possession": home_points_per_possession(),
			"away_points_per_possession": away_points_per_possession(),
			"home_effective_field_goal": home_effective_field_goal,
			"away_effective_field_goal": away_effective_field_goal,
			"intentional_fouls": intentional_fouls,
			"largest_run": largest_run,
		}


var rows: Array[GameRow] = []


func add(row: GameRow) -> void:
	rows.append(row)


func size() -> int:
	return rows.size()


func margins() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.margin())
	return values


func absolute_margins() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.absolute_margin())
	return values


func expected_gaps() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.expected_gap)
	return values


func column(component: int) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.components()[component])
	return values


## `Cov(component, margin) / Var(margin)`. The shares sum to one because the
## components sum to the margin in every row.
func variance_share(component: int) -> float:
	var total: float = _variance(margins())
	if total <= 0.0:
		return 0.0
	return _covariance(column(component), margins()) / total


## Share of margin variance explained by the pregame strength gap, as the
## R-squared of the least-squares line. This is the legitimate part: two teams
## of different quality are supposed to produce different margins.
func strength_explained_share() -> float:
	var gaps: PackedFloat64Array = expected_gaps()
	var gap_variance: float = _variance(gaps)
	var margin_variance: float = _variance(margins())
	if gap_variance <= 0.0 or margin_variance <= 0.0:
		return 0.0
	var covariance: float = _covariance(gaps, margins())
	return (covariance * covariance) / (gap_variance * margin_variance)


## Points of margin per centi-capability point of pregame gap.
func strength_slope() -> float:
	var gaps: PackedFloat64Array = expected_gaps()
	var gap_variance: float = _variance(gaps)
	if gap_variance <= 0.0:
		return 0.0
	return _covariance(gaps, margins()) / gap_variance


## Residual standard deviation of the margin once the pregame gap is removed:
## the dispersion the engine generates within a fixed matchup.
func residual_standard_deviation() -> float:
	var explained: float = strength_explained_share()
	return sqrt(maxf(_variance(margins()) * (1.0 - explained), 0.0))


## The rows whose absolute pregame gap falls in `[lower, upper)`.
func band(lower: float, upper: float) -> MarginDecomposition:
	var subset := MarginDecomposition.new()
	for row in rows:
		var gap: float = absf(row.expected_gap)
		if gap >= lower and gap < upper:
			subset.add(row)
	return subset


func blowout_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.absolute_margin() >= 20.0)


func close_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.absolute_margin() <= 5.0)


func one_possession_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.absolute_margin() <= 3.0)


func two_possession_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.absolute_margin() <= 6.0)


func overtime_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.overtime_periods > 0)


func regulation_tie_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.regulation_margin() == 0.0)


func blowout_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.absolute_margin() >= 20.0)


func close_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.absolute_margin() <= 5.0)


func overtime_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.overtime_periods > 0)


func margin_standard_deviation() -> float:
	return sqrt(maxf(_variance(margins()), 0.0))


func worst_identity_error() -> float:
	var worst: float = 0.0
	for row in rows:
		worst = maxf(worst, row.identity_error())
	return worst


func absolute_margin_percentile(share: float) -> float:
	var sorted: PackedFloat64Array = absolute_margins()
	sorted.sort()
	return CalibrationStatistics.percentile(sorted, share)


func mean_of(values: PackedFloat64Array) -> float:
	return CalibrationStatistics.mean(values)


## The pooled within-team-game variance of one possession's points.
##
## This is the marginal dispersion of a single possession outcome, estimated
## inside games so that differences between games — roster quality, pace, rule
## profile — cannot leak into it. It is the reference the independence test
## below compares the realized margin against.
func within_game_possession_variance() -> float:
	var sum_squares: float = 0.0
	var degrees_of_freedom: float = 0.0
	for row in rows:
		sum_squares += _within_team(
			row.home_possession_points_squared, float(row.home_score), row.home_possessions)
		degrees_of_freedom += maxf(float(row.home_possessions - 1), 0.0)
		sum_squares += _within_team(
			row.away_possession_points_squared, float(row.away_score), row.away_possessions)
		degrees_of_freedom += maxf(float(row.away_possessions - 1), 0.0)
	if degrees_of_freedom <= 0.0:
		return 0.0
	return sum_squares / degrees_of_freedom


## The margin standard deviation the engine would produce if every possession in
## a game were an independent draw from the marginal distribution above.
##
## Comparing this with the realized margin standard deviation is the test the
## Stage 4 brief asks for under "possession outcomes being too independent or too
## correlated" and "game-level hot/cold states that persist too strongly". A
## ratio near one means the margin is exactly the accumulation of independent
## possessions. A ratio well above one means something inside a game is making
## possessions agree with each other, and that something is what inflates the
## tails.
func independent_margin_standard_deviation() -> float:
	if rows.is_empty():
		return 0.0
	var variance: float = within_game_possession_variance()
	var possessions: float = 0.0
	for row in rows:
		possessions += float(row.home_possessions + row.away_possessions)
	return sqrt(variance * possessions / float(rows.size()))


## Realized margin dispersion over the dispersion independent possessions imply.
func overdispersion_ratio() -> float:
	var independent: float = independent_margin_standard_deviation()
	if independent <= 0.0:
		return 0.0
	return margin_standard_deviation() / independent


## Share of possessions scoring exactly `points`, or four-or-more at index four.
func possession_outcome_share(bucket: int) -> float:
	var total: int = 0
	var matching: int = 0
	for row in rows:
		for index in range(row.possession_outcome_counts.size()):
			total += row.possession_outcome_counts[index]
			if index == bucket:
				matching += row.possession_outcome_counts[index]
	if total <= 0:
		return 0.0
	return float(matching) / float(total)


static func _within_team(sum_squares: float, total: float, count: int) -> float:
	if count < 2:
		return 0.0
	return maxf(sum_squares - total * total / float(count), 0.0)


func _share_where(predicate: Callable) -> float:
	if rows.is_empty():
		return 0.0
	return float(_count_where(predicate)) / float(rows.size())


func _count_where(predicate: Callable) -> int:
	var total: int = 0
	for row in rows:
		if predicate.call(row):
			total += 1
	return total


static func _variance(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	var mean: float = CalibrationStatistics.mean(values)
	var total: float = 0.0
	for value in values:
		total += (value - mean) * (value - mean)
	return total / float(values.size() - 1)


static func _covariance(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	assert(left.size() == right.size(), "covariance requires paired samples")
	if left.size() < 2:
		return 0.0
	var left_mean: float = CalibrationStatistics.mean(left)
	var right_mean: float = CalibrationStatistics.mean(right)
	var total: float = 0.0
	for index in range(left.size()):
		total += (left[index] - left_mean) * (right[index] - right_mean)
	return total / float(left.size() - 1)
