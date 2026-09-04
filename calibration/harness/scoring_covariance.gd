class_name ScoringCovariance
extends RefCounted

## Whether the two teams' scoring is independent, and where the final margin's
## variance actually comes from.
##
## `MarginDecomposition` answers "which basketball channel carried the margin".
## This answers a different question, and the one the identity
##
## ```text
## Var(A - B) = Var(A) + Var(B) - 2 Cov(A, B)
## ```
##
## makes unavoidable: the previous margin analysis measured each team's
## marginal scoring variance and reconstructed the margin as `2 n sigma^2`,
## which is the right answer only when `Cov(A, B)` is zero. That is an
## assumption, not a measurement, and this class is the measurement.
##
## Three instruments, because "is the covariance zero" is three different
## questions:
##
## 1. **Game-level covariance.** `Cov(A, B)` between the two teams' final
##    points, their points per possession, and their period-by-period scoring,
##    raw and after the pregame strength, the realized pace and the home
##    environment are regressed out. The raw term contains everything two teams
##    share; the residual term is what is left once the shared *inputs* are
##    removed, and only the second can be attributed to in-game behaviour.
## 2. **Increment autocovariance.** The margin as a path rather than an endpoint.
##    Each possession contributes a signed increment; the lag-k autocovariance of
##    those increments, centred inside the game so between-game effects cannot
##    leak in, says whether the path is a random walk. A pure random walk has
##    every lag at zero.
## 3. **The variance ratio.** `Var(margin change over L possessions)` divided by
##    `L * Var(one possession increment)`. This is the same statement at every
##    horizon at once: one for a random walk, below one for a path that reverts,
##    above one for a path that trends. Short-lag autocovariances can be zero
##    while a long-horizon mechanism — a coach protecting a lead for six
##    minutes — still moves the endpoint, and the variance ratio is the
##    instrument that sees it.
##
## Nothing here judges. The §14.2 verdicts stay in the runner; this class
## reports terms.

## Absolute-margin bands the possession is played in, read from the score
## *before* the possession starts so the possession's own points cannot decide
## which bucket it lands in.
enum State {
	CLOSE, ## within one two-possession swing: |margin| <= 5
	ORDINARY, ## 6..14
	DECIDED, ## 15 or more
}

const STATE_COUNT: int = 3
const STATE_IDS: PackedStringArray = ["close", "ordinary", "decided"]
const STATE_CLOSE_MAX: int = 5
const STATE_ORDINARY_MAX: int = 14

## Unanswered points at or above which a scoring streak counts as a run. Six is
## the smallest streak a coach is conventionally described as calling time out
## for, which is what makes it the useful threshold to report against.
const RUN_POINTS: int = 6

## Lags reported for the increment autocovariance. Eight possessions is roughly
## two minutes of a top-domestic game.
const MAX_LAG: int = 8

## Horizons the variance ratio is reported at, in team-possessions of the
## alternating sequence. Eighty is about a period and a half.
const WINDOW_LENGTHS: PackedInt32Array = [1, 2, 5, 10, 20, 40, 80]

## Possession point buckets: 0, 1, 2, 3, 4, 5, and six-or-more.
const OUTCOME_BUCKETS: int = 7


## One completed game. Everything signed home-minus-away, so a sign means the
## same thing in every row.
class GameRow extends RefCounted:
	var variation: int
	var seed: int
	var expected_gap: float
	var home_strength: float
	var away_strength: float
	var home_environment: float

	var home_points: int
	var away_points: int
	var regulation_home: int
	var regulation_away: int
	var overtime_periods: int
	var home_possessions: int
	var away_possessions: int
	## Elapsed live seconds divided by team possessions: the realized pace both
	## teams played at, which is shared by construction.
	var seconds_per_possession: float

	var home_period_points: PackedFloat64Array
	var away_period_points: PackedFloat64Array

	## Indexed by `State`.
	var home_state_points: PackedFloat64Array
	var away_state_points: PackedFloat64Array
	var home_state_possessions: PackedFloat64Array
	var away_state_possessions: PackedFloat64Array
	var home_state_field_goals: PackedFloat64Array
	var away_state_field_goals: PackedFloat64Array
	var home_state_threes: PackedFloat64Array
	var away_state_threes: PackedFloat64Array
	## Points and possessions split by whether the team with the ball was ahead
	## or behind when the possession started. Indexed by `State`. This is the
	## direct measurement of margin drift: a leading team that outscores a
	## trailing one inside the decided state is a margin that runs away, and a
	## trailing one that outscores the leader is a comeback mechanism.
	var leading_state_points: PackedFloat64Array
	var trailing_state_points: PackedFloat64Array
	var leading_state_possessions: PackedFloat64Array
	var trailing_state_possessions: PackedFloat64Array
	var leading_state_seconds: PackedFloat64Array
	var trailing_state_seconds: PackedFloat64Array
	var leading_state_threes: PackedFloat64Array
	var trailing_state_threes: PackedFloat64Array
	var leading_state_field_goals: PackedFloat64Array
	var trailing_state_field_goals: PackedFloat64Array
	var state_seconds: PackedFloat64Array
	var state_actions: PackedFloat64Array
	var state_substitutions: PackedFloat64Array
	var state_intentional_fouls: PackedFloat64Array

	## The §18.2 settled-game window, split at the first `decided_game` check-in
	## the ledger carries. Before it the game was still being played; after it
	## both coaches have started resting people.
	var settled: bool
	var home_points_before_settled: float
	var away_points_before_settled: float
	var home_points_after_settled: float
	var away_points_after_settled: float
	var possessions_after_settled: float

	## §18.2 garbage time, read from the `GARBAGE_TIME` events in the ledger.
	var garbage_activations: int
	var garbage_resumptions: int
	var leading_activated: bool
	var trailing_activated: bool
	## State at the *first* activation of the game, which is the one the
	## comeback and false-positive questions are asked about.
	var activation_margin: float
	var activation_remaining_share: float
	var activation_home_leading: bool
	## Player-time on court, split at that first activation, so a coach who rests
	## his starters earlier shows up as a number rather than as a story.
	var starter_ms_before: float
	var bench_ms_before: float
	var leading_starter_ms_after: float
	var leading_bench_ms_after: float
	var trailing_starter_ms_after: float
	var trailing_bench_ms_after: float

	var lead_changes: int
	var ties: int
	var largest_lead: int
	var runs: int
	var run_points_total: int
	var largest_run: int
	var timeouts: int
	var intentional_fouls: int
	var substitutions: int

	## Increment autocovariance accumulators, centred on the team's own mean
	## inside this game.
	var increment_squares: float
	var increment_count: float
	var lag_products: PackedFloat64Array
	var lag_counts: PackedFloat64Array
	## Variance-ratio accumulators, indexed by `WINDOW_LENGTHS`.
	var window_squares: PackedFloat64Array
	var window_counts: PackedFloat64Array
	## The identical accumulators computed on a deterministic permutation of the
	## same game's own increments. A permutation destroys every serial and
	## score-state structure while preserving the multiset exactly, so it carries
	## the whole of the finite-sample bias that centring inside a game creates
	## and none of the behaviour. The real statistic divided by this one is the
	## bias-free measurement.
	var control_increment_squares: float
	var control_increment_count: float
	var control_lag_products: PackedFloat64Array
	var control_lag_counts: PackedFloat64Array
	var control_window_squares: PackedFloat64Array
	var control_window_counts: PackedFloat64Array
	## Possessions scoring 0, 1, 2, ... `OUTCOME_BUCKETS - 1` or more points,
	## per team. These are the complete sufficient statistics for resampling a
	## game under independence.
	var home_outcome_counts: PackedFloat64Array
	var away_outcome_counts: PackedFloat64Array

	func _init() -> void:
		home_period_points = PackedFloat64Array()
		away_period_points = PackedFloat64Array()
		home_state_points = _zeros(STATE_COUNT)
		away_state_points = _zeros(STATE_COUNT)
		home_state_possessions = _zeros(STATE_COUNT)
		away_state_possessions = _zeros(STATE_COUNT)
		home_state_field_goals = _zeros(STATE_COUNT)
		away_state_field_goals = _zeros(STATE_COUNT)
		home_state_threes = _zeros(STATE_COUNT)
		away_state_threes = _zeros(STATE_COUNT)
		leading_state_points = _zeros(STATE_COUNT)
		trailing_state_points = _zeros(STATE_COUNT)
		leading_state_possessions = _zeros(STATE_COUNT)
		trailing_state_possessions = _zeros(STATE_COUNT)
		leading_state_seconds = _zeros(STATE_COUNT)
		trailing_state_seconds = _zeros(STATE_COUNT)
		leading_state_threes = _zeros(STATE_COUNT)
		trailing_state_threes = _zeros(STATE_COUNT)
		leading_state_field_goals = _zeros(STATE_COUNT)
		trailing_state_field_goals = _zeros(STATE_COUNT)
		garbage_activations = 0
		garbage_resumptions = 0
		leading_activated = false
		trailing_activated = false
		activation_margin = 0.0
		activation_remaining_share = 0.0
		activation_home_leading = false
		state_seconds = _zeros(STATE_COUNT)
		state_actions = _zeros(STATE_COUNT)
		state_substitutions = _zeros(STATE_COUNT)
		state_intentional_fouls = _zeros(STATE_COUNT)
		lag_products = _zeros(MAX_LAG + 1)
		lag_counts = _zeros(MAX_LAG + 1)
		window_squares = _zeros(WINDOW_LENGTHS.size())
		window_counts = _zeros(WINDOW_LENGTHS.size())
		control_lag_products = _zeros(MAX_LAG + 1)
		control_lag_counts = _zeros(MAX_LAG + 1)
		control_window_squares = _zeros(WINDOW_LENGTHS.size())
		control_window_counts = _zeros(WINDOW_LENGTHS.size())
		home_outcome_counts = _zeros(OUTCOME_BUCKETS)
		away_outcome_counts = _zeros(OUTCOME_BUCKETS)
		settled = false

	static func _zeros(count: int) -> PackedFloat64Array:
		var values := PackedFloat64Array()
		values.resize(count)
		values.fill(0.0)
		return values

	func margin() -> float:
		return float(home_points - away_points)

	func absolute_margin() -> float:
		return absf(margin())

	func regulation_margin() -> float:
		return float(regulation_home - regulation_away)

	func total_possessions() -> float:
		return float(home_possessions + away_possessions)

	func home_points_per_possession() -> float:
		return float(home_points) / float(home_possessions) if home_possessions > 0 else 0.0

	func away_points_per_possession() -> float:
		return float(away_points) / float(away_possessions) if away_possessions > 0 else 0.0

	func mean_run_points() -> float:
		return float(run_points_total) / float(runs) if runs > 0 else 0.0


var rows: Array[GameRow] = []


func add(row: GameRow) -> void:
	rows.append(row)


func size() -> int:
	return rows.size()


# --- column accessors -------------------------------------------------------

func home_points() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(float(row.home_points))
	return values


func away_points() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(float(row.away_points))
	return values


func margins() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.margin())
	return values


func home_points_per_possession() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.home_points_per_possession())
	return values


func away_points_per_possession() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(row.away_points_per_possession())
	return values


func home_possessions() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(float(row.home_possessions))
	return values


func away_possessions() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(float(row.away_possessions))
	return values


func column(getter: Callable) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for row in rows:
		values.append(_as_float(getter.call(row)))
	return values


# --- the identity ------------------------------------------------------------

func home_points_variance() -> float:
	return variance(home_points())


func away_points_variance() -> float:
	return variance(away_points())


func margin_variance() -> float:
	return variance(margins())


func points_covariance() -> float:
	return covariance(home_points(), away_points())


func points_correlation() -> float:
	return correlation(home_points(), away_points())


func points_per_possession_covariance() -> float:
	return covariance(home_points_per_possession(), away_points_per_possession())


func points_per_possession_correlation() -> float:
	return correlation(home_points_per_possession(), away_points_per_possession())


## `Var(A) + Var(B) - 2 Cov(A, B)`. Identical to `margin_variance()` up to
## floating-point error; published beside it so the identity is checked rather
## than asserted in prose.
func reconstructed_margin_variance() -> float:
	return home_points_variance() + away_points_variance() - 2.0 * points_covariance()


func reconstruction_error() -> float:
	return absf(margin_variance() - reconstructed_margin_variance())


## The part of `Cov(A, B)` a shared possession count alone would produce:
## both teams play the same game, so a fast game gives both of them more
## chances. `Cov(n_A e_A, n_B e_B)` with efficiency held at its mean is
## `e_A e_B Cov(n_A, n_B)`.
func shared_possession_covariance() -> float:
	var home_efficiency: float = CalibrationStatistics.mean(home_points_per_possession())
	var away_efficiency: float = CalibrationStatistics.mean(away_points_per_possession())
	return home_efficiency * away_efficiency * covariance(home_possessions(), away_possessions())


## Covariance of the two teams' points once pregame strength, realized pace and
## the home environment are projected out of each side by least squares. What
## remains is the covariance in-game behaviour created, which is the term the
## §14.2 question is actually about.
func residual_points_covariance() -> float:
	var residuals: Array[PackedFloat64Array] = _points_residuals()
	return covariance(residuals[0], residuals[1])


func residual_points_correlation() -> float:
	var residuals: Array[PackedFloat64Array] = _points_residuals()
	return correlation(residuals[0], residuals[1])


func _points_residuals() -> Array[PackedFloat64Array]:
	var strength_home: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.home_strength)
	var strength_away: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.away_strength)
	var pace: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.seconds_per_possession)
	var possessions: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.total_possessions())
	var environment: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.home_environment)
	var home_design: Array[PackedFloat64Array] = [
		strength_home, strength_away, pace, possessions, environment]
	var away_design: Array[PackedFloat64Array] = [
		strength_away, strength_home, pace, possessions, environment]
	var result: Array[PackedFloat64Array] = [
		residuals_of(home_points(), home_design),
		residuals_of(away_points(), away_design),
	]
	return result


# --- conditioned covariance --------------------------------------------------

## The subset whose absolute pregame gap falls in `[lower, upper)`.
func gap_band(lower: float, upper: float) -> ScoringCovariance:
	var subset := ScoringCovariance.new()
	for row in rows:
		var gap: float = absf(row.expected_gap)
		if gap >= lower and gap < upper:
			subset.add(row)
	return subset


## The subset whose total possessions fall in `[lower, upper)`.
func possession_band(lower: float, upper: float) -> ScoringCovariance:
	var subset := ScoringCovariance.new()
	for row in rows:
		var total: float = row.total_possessions()
		if total >= lower and total < upper:
			subset.add(row)
	return subset


func possession_quantile(share: float) -> float:
	var totals: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.total_possessions())
	totals.sort()
	return CalibrationStatistics.percentile(totals, share)


## Covariance of the two teams' points scored inside one absolute-margin state.
func state_covariance(state: int) -> float:
	return covariance(
		column(func(row: GameRow) -> float: return row.home_state_points[state]),
		column(func(row: GameRow) -> float: return row.away_state_points[state]))


func state_correlation(state: int) -> float:
	return correlation(
		column(func(row: GameRow) -> float: return row.home_state_points[state]),
		column(func(row: GameRow) -> float: return row.away_state_points[state]))


func state_share_of_possessions(state: int) -> float:
	var inside: float = 0.0
	var total: float = 0.0
	for row in rows:
		inside += row.home_state_possessions[state] + row.away_state_possessions[state]
		total += row.total_possessions()
	return inside / total if total > 0.0 else 0.0


func state_points_per_possession(state: int) -> float:
	var points: float = 0.0
	var possessions: float = 0.0
	for row in rows:
		points += row.home_state_points[state] + row.away_state_points[state]
		possessions += row.home_state_possessions[state] + row.away_state_possessions[state]
	return points / possessions if possessions > 0.0 else 0.0


func state_three_point_rate(state: int) -> float:
	var threes: float = 0.0
	var attempts: float = 0.0
	for row in rows:
		threes += row.home_state_threes[state] + row.away_state_threes[state]
		attempts += row.home_state_field_goals[state] + row.away_state_field_goals[state]
	return threes / attempts if attempts > 0.0 else 0.0


func state_seconds_per_possession(state: int) -> float:
	var seconds: float = 0.0
	var possessions: float = 0.0
	for row in rows:
		seconds += row.state_seconds[state]
		possessions += row.home_state_possessions[state] + row.away_state_possessions[state]
	return seconds / possessions if possessions > 0.0 else 0.0


func state_actions_per_possession(state: int) -> float:
	var actions: float = 0.0
	var possessions: float = 0.0
	for row in rows:
		actions += row.state_actions[state]
		possessions += row.home_state_possessions[state] + row.away_state_possessions[state]
	return actions / possessions if possessions > 0.0 else 0.0


## Covariance of the two teams' *efficiency* inside one state, over the games
## where both of them played enough possessions in it for a rate to mean
## anything. The raw covariance of state points is dominated by how long the
## game stayed in the state — a game that stays close gives both teams many
## close-state possessions — and says almost nothing about whether the teams'
## scoring agreed.
func state_points_per_possession_covariance(state: int, minimum_possessions: int = 10) -> float:
	var pair: Array[PackedFloat64Array] = _state_rate_columns(state, minimum_possessions)
	return covariance(pair[0], pair[1])


func state_points_per_possession_correlation(state: int, minimum_possessions: int = 10) -> float:
	var pair: Array[PackedFloat64Array] = _state_rate_columns(state, minimum_possessions)
	return correlation(pair[0], pair[1])


func state_rate_sample(state: int, minimum_possessions: int = 10) -> int:
	return _state_rate_columns(state, minimum_possessions)[0].size()


func _state_rate_columns(state: int, minimum_possessions: int) -> Array[PackedFloat64Array]:
	var home := PackedFloat64Array()
	var away := PackedFloat64Array()
	for row in rows:
		var home_possessions: float = row.home_state_possessions[state]
		var away_possessions: float = row.away_state_possessions[state]
		if home_possessions < float(minimum_possessions):
			continue
		if away_possessions < float(minimum_possessions):
			continue
		home.append(row.home_state_points[state] / home_possessions)
		away.append(row.away_state_points[state] / away_possessions)
	var result: Array[PackedFloat64Array] = [home, away]
	return result


## Points per possession for the team that was ahead when the possession
## started, inside one absolute-margin state. Compared with the trailing team's
## rate in the same state, this is the whole of the margin's drift: equal rates
## mean a driftless margin, a higher leading rate means leads run away, and a
## higher trailing rate is the comeback mechanism §20.3 forbids.
func leading_points_per_possession(state: int) -> float:
	return _rate(
		func(row: GameRow) -> float: return row.leading_state_points[state],
		func(row: GameRow) -> float: return row.leading_state_possessions[state])


func trailing_points_per_possession(state: int) -> float:
	return _rate(
		func(row: GameRow) -> float: return row.trailing_state_points[state],
		func(row: GameRow) -> float: return row.trailing_state_possessions[state])


func leading_seconds_per_possession(state: int) -> float:
	return _rate(
		func(row: GameRow) -> float: return row.leading_state_seconds[state],
		func(row: GameRow) -> float: return row.leading_state_possessions[state])


func trailing_seconds_per_possession(state: int) -> float:
	return _rate(
		func(row: GameRow) -> float: return row.trailing_state_seconds[state],
		func(row: GameRow) -> float: return row.trailing_state_possessions[state])


func leading_three_point_rate(state: int) -> float:
	return _rate(
		func(row: GameRow) -> float: return row.leading_state_threes[state],
		func(row: GameRow) -> float: return row.leading_state_field_goals[state])


func trailing_three_point_rate(state: int) -> float:
	return _rate(
		func(row: GameRow) -> float: return row.trailing_state_threes[state],
		func(row: GameRow) -> float: return row.trailing_state_field_goals[state])


## The drift: how many points per possession the leading team gains on the
## trailing one inside a state. Zero is a driftless margin.
func leading_drift(state: int) -> float:
	return leading_points_per_possession(state) - trailing_points_per_possession(state)


func _rate(numerator: Callable, denominator: Callable) -> float:
	return _pooled(numerator, denominator)


func state_total(getter: Callable) -> float:
	var total: float = 0.0
	for row in rows:
		total += _as_float(getter.call(row))
	return total


## Period-by-period scoring covariance. Periods beyond a row's length are
## skipped rather than zero-filled, so an overtime column is the covariance
## among the games that played it.
func period_covariance(period_index: int) -> float:
	var home := PackedFloat64Array()
	var away := PackedFloat64Array()
	for row in rows:
		if period_index >= row.home_period_points.size():
			continue
		if period_index >= row.away_period_points.size():
			continue
		home.append(row.home_period_points[period_index])
		away.append(row.away_period_points[period_index])
	return covariance(home, away)


func period_correlation(period_index: int) -> float:
	var home := PackedFloat64Array()
	var away := PackedFloat64Array()
	for row in rows:
		if period_index >= row.home_period_points.size():
			continue
		if period_index >= row.away_period_points.size():
			continue
		home.append(row.home_period_points[period_index])
		away.append(row.away_period_points[period_index])
	return correlation(home, away)


func period_sample(period_index: int) -> int:
	var count: int = 0
	for row in rows:
		if period_index < row.home_period_points.size():
			count += 1
	return count


func maximum_period_count() -> int:
	var count: int = 0
	for row in rows:
		count = maxi(count, row.home_period_points.size())
	return count


## The settled-game subset, split at the first §18.2 `decided_game` check-in.
func settled_rows() -> ScoringCovariance:
	var subset := ScoringCovariance.new()
	for row in rows:
		if row.settled:
			subset.add(row)
	return subset


func covariance_before_settled() -> float:
	return covariance(
		column(func(row: GameRow) -> float: return row.home_points_before_settled),
		column(func(row: GameRow) -> float: return row.away_points_before_settled))


# --- §18.2 garbage time -------------------------------------------------------

func activated_rows() -> ScoringCovariance:
	var subset := ScoringCovariance.new()
	for row in rows:
		if row.garbage_activations > 0:
			subset.add(row)
	return subset


func activation_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.garbage_activations > 0)


func leading_activation_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.leading_activated)


func trailing_activation_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.trailing_activated)


func both_settled_share() -> float:
	return _share_where(func(row: GameRow) -> bool:
		return row.leading_activated and row.trailing_activated)


func resumption_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.garbage_resumptions > 0)


## Activated games whose final margin says the state was called too early. The
## strict form is a game that finished inside one two-possession swing.
func false_positive_share(threshold: float) -> float:
	var activated: ScoringCovariance = activated_rows()
	if activated.size() <= 0:
		return 0.0
	return activated._share_where(func(row: GameRow) -> bool:
		return row.absolute_margin() <= threshold)


## Activated games won by the side that was behind when the state began. A
## non-zero figure is not a defect — a comeback the trailing team earned is a
## comeback — but a large one means the state is being entered before the game
## is over.
func comeback_share() -> float:
	var activated: ScoringCovariance = activated_rows()
	if activated.size() <= 0:
		return 0.0
	return activated._share_where(func(row: GameRow) -> bool:
		return (row.margin() > 0.0) != row.activation_home_leading and row.margin() != 0.0)


## Share of on-court player-time taken by starters, pooled over activated games.
func starter_share_before() -> float:
	return _pooled(
		func(row: GameRow) -> float: return row.starter_ms_before,
		func(row: GameRow) -> float: return row.starter_ms_before + row.bench_ms_before)


func leading_starter_share_after() -> float:
	return _pooled(
		func(row: GameRow) -> float: return row.leading_starter_ms_after,
		func(row: GameRow) -> float:
			return row.leading_starter_ms_after + row.leading_bench_ms_after)


func trailing_starter_share_after() -> float:
	return _pooled(
		func(row: GameRow) -> float: return row.trailing_starter_ms_after,
		func(row: GameRow) -> float:
			return row.trailing_starter_ms_after + row.trailing_bench_ms_after)


func covariance_after_settled() -> float:
	return covariance(
		column(func(row: GameRow) -> float: return row.home_points_after_settled),
		column(func(row: GameRow) -> float: return row.away_points_after_settled))


# --- the margin as a path ----------------------------------------------------

## Lag-k autocorrelation of the signed possession increments, pooled over games
## and centred inside each team-game. Zero at every lag is a random walk.
func increment_autocorrelation(lag: int) -> float:
	var zero: float = _pooled(
		func(row: GameRow) -> float: return row.increment_squares,
		func(row: GameRow) -> float: return row.increment_count)
	if zero <= 0.0:
		return 0.0
	var lagged: float = _pooled(
		func(row: GameRow) -> float: return row.lag_products[lag],
		func(row: GameRow) -> float: return row.lag_counts[lag])
	return lagged / zero


func increment_variance() -> float:
	return _pooled(
		func(row: GameRow) -> float: return row.increment_squares,
		func(row: GameRow) -> float: return row.increment_count)


## `1 + 2 * sum(rho_k)` over the reported lags: the factor by which local serial
## structure multiplies the random-walk variance.
func local_variance_multiplier() -> float:
	var total: float = 1.0
	for lag in range(1, MAX_LAG + 1):
		total += 2.0 * increment_autocorrelation(lag)
	return total


## `Var(margin change over L possessions) / (L * Var(one increment))`.
func variance_ratio(window_index: int) -> float:
	var length: float = float(WINDOW_LENGTHS[window_index])
	var single: float = increment_variance()
	if single <= 0.0:
		return 0.0
	var windowed: float = _pooled(
		func(row: GameRow) -> float: return row.window_squares[window_index],
		func(row: GameRow) -> float: return row.window_counts[window_index])
	return windowed / (length * single)


## The same lag-k autocorrelation measured on the permuted control. For an
## exchangeable sequence the population value is not zero but `-1/(N-1)`, which
## is exactly the artefact this column exists to expose.
func control_increment_autocorrelation(lag: int) -> float:
	var zero: float = _pooled(
		func(row: GameRow) -> float: return row.control_increment_squares,
		func(row: GameRow) -> float: return row.control_increment_count)
	if zero <= 0.0:
		return 0.0
	var lagged: float = _pooled(
		func(row: GameRow) -> float: return row.control_lag_products[lag],
		func(row: GameRow) -> float: return row.control_lag_counts[lag])
	return lagged / zero


func control_variance_ratio(window_index: int) -> float:
	var length: float = float(WINDOW_LENGTHS[window_index])
	var single: float = _pooled(
		func(row: GameRow) -> float: return row.control_increment_squares,
		func(row: GameRow) -> float: return row.control_increment_count)
	if single <= 0.0:
		return 0.0
	var windowed: float = _pooled(
		func(row: GameRow) -> float: return row.control_window_squares[window_index],
		func(row: GameRow) -> float: return row.control_window_counts[window_index])
	return windowed / (length * single)


## The variance ratio divided by the permuted control's variance ratio. One is
## a random walk at that horizon; below one is a path that reverts; above one is
## a path that trends. This is the number to read — the uncorrected ratio falls
## with the horizon even for a sequence with no structure at all, because
## centring inside a game forces the whole sequence to sum to zero.
func corrected_variance_ratio(window_index: int) -> float:
	var control: float = control_variance_ratio(window_index)
	if control <= 0.0:
		return 0.0
	return variance_ratio(window_index) / control


func _pooled(numerator: Callable, denominator: Callable) -> float:
	var top: float = 0.0
	var bottom: float = 0.0
	for row in rows:
		top += _as_float(numerator.call(row))
		bottom += _as_float(denominator.call(row))
	return top / bottom if bottom > 0.0 else 0.0


# --- shape -------------------------------------------------------------------

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


func home_win_share() -> float:
	return _share_where(func(row: GameRow) -> bool: return row.margin() > 0.0)


func blowout_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.absolute_margin() >= 20.0)


func close_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.absolute_margin() <= 5.0)


func overtime_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.overtime_periods > 0)


func home_win_count() -> int:
	return _count_where(func(row: GameRow) -> bool: return row.margin() > 0.0)


func margin_standard_deviation() -> float:
	return sqrt(maxf(margin_variance(), 0.0))


func absolute_margin_percentile(share: float) -> float:
	var sorted: PackedFloat64Array = column(
		func(row: GameRow) -> float: return row.absolute_margin())
	sorted.sort()
	return CalibrationStatistics.percentile(sorted, share)


func mean_of(getter: Callable) -> float:
	return CalibrationStatistics.mean(column(getter))


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


# --- the independence model --------------------------------------------------

## The margin distribution independent possessions would have produced.
##
## Every regulation possession in the sample is pooled into one empirical
## distribution of possession outcomes, and each game is rebuilt by drawing its
## own regulation possession counts from that pool, independently for the two
## teams. The result is a league of average teams playing the measured pace
## with the measured possession-value distribution and nothing else: no shared
## game state, no serial structure, no score-aware behaviour.
##
## Pooling matters. Resampling each game from *its own* outcomes looks more
## faithful and is wrong: a game's realized efficiency is already the sample
## mean of those possessions, so drawing from it reproduces that realization and
## then adds the same sampling noise a second time, inflating the null by the
## exact quantity the null is supposed to isolate.
##
## Because the pool is common to every game, this null carries no between-team
## strength term. It is therefore the right comparison for the mirror fixture,
## where the pregame gap is exactly zero, and on a population fixture it must be
## read beside the strength-explained variance the report publishes separately.
func independence_margins(random_source: RandomSource, repeats: int) -> PackedFloat64Array:
	var pool: PackedFloat64Array = pooled_outcome_counts()
	var cumulative: PackedFloat64Array = _cumulative(pool)
	var margins := PackedFloat64Array()
	for row in rows:
		var home_draws: int = int(roundf(_sum(row.home_outcome_counts)))
		var away_draws: int = int(roundf(_sum(row.away_outcome_counts)))
		if home_draws <= 0 or away_draws <= 0:
			continue
		var game_stream: RandomSource = random_source.derive(
			StringName("bootstrap:%d" % row.variation))
		for repeat in range(repeats):
			var stream: RandomSource = game_stream.derive(StringName("draw:%d" % repeat))
			var total: int = 0
			for draw in range(home_draws):
				total += _sample(cumulative, stream.next_float())
			for draw in range(away_draws):
				total -= _sample(cumulative, stream.next_float())
			margins.append(float(total))
	return margins


## The margin distribution a *damped* walk would have produced.
##
## Identical to `independence_margins` except that once the margin passes
## `threshold`, the team that is ahead loses `penalty` points from each of its
## possessions. That is the whole family of legitimate late-game mechanisms
## reduced to its one measurable consequence: a leading team that rests its
## starters, burns clock, stops crashing the glass and takes the safe shot
## scores less than the team chasing it, and how much less is the only thing
## the final margin can tell them apart by.
##
## Running the model across a grid of penalties turns "can basketball behaviour
## reach §14.2" into a number a person can judge: the penalty required, read
## against the penalty real garbage time actually produces.
func damped_margins(
	random_source: RandomSource,
	repeats: int,
	penalty: float,
	threshold: float,
) -> PackedFloat64Array:
	var pool: PackedFloat64Array = pooled_outcome_counts()
	var cumulative: PackedFloat64Array = _cumulative(pool)
	var mean_points: float = pooled_points_per_possession()
	var margins := PackedFloat64Array()
	for row in rows:
		var home_draws: int = int(roundf(_sum(row.home_outcome_counts)))
		var away_draws: int = int(roundf(_sum(row.away_outcome_counts)))
		var pairs: int = mini(home_draws, away_draws)
		if pairs <= 0:
			continue
		var game_stream: RandomSource = random_source.derive(
			StringName("damped:%d" % row.variation))
		for repeat in range(repeats):
			var stream: RandomSource = game_stream.derive(StringName("draw:%d" % repeat))
			var margin: float = 0.0
			for pair in range(pairs):
				var home_points: float = float(_sample(cumulative, stream.next_float()))
				var away_points: float = float(_sample(cumulative, stream.next_float()))
				# The penalty is applied by *losing possessions*, not by shaving
				# a fraction of a point off each one. A margin that can land on a
				# non-integer has no exact ties in it, and the overtime rate is
				# read from exactly that, so a continuous shave would answer the
				# blowout question and silently destroy the overtime one.
				if penalty > 0.0 and absf(margin) >= threshold:
					var loss_rate: float = clampf(penalty / maxf(mean_points, 0.01), 0.0, 1.0)
					if margin > 0.0 and stream.next_float() < loss_rate:
						home_points = 0.0
					elif margin < 0.0 and stream.next_float() < loss_rate:
						away_points = 0.0
				margin += home_points - away_points
			margins.append(margin)
	return margins


## Mean points in one pooled regulation possession.
func pooled_points_per_possession() -> float:
	var pool: PackedFloat64Array = pooled_outcome_counts()
	var total: float = 0.0
	var points: float = 0.0
	for bucket in range(OUTCOME_BUCKETS):
		total += pool[bucket]
		points += pool[bucket] * float(bucket)
	return points / total if total > 0.0 else 0.0


## Every regulation possession in the sample, bucketed by points scored.
func pooled_outcome_counts() -> PackedFloat64Array:
	var pool := PackedFloat64Array()
	pool.resize(OUTCOME_BUCKETS)
	pool.fill(0.0)
	for row in rows:
		for bucket in range(OUTCOME_BUCKETS):
			pool[bucket] += row.home_outcome_counts[bucket] + row.away_outcome_counts[bucket]
	return pool


static func share_at_or_above(values: PackedFloat64Array, threshold: float) -> float:
	if values.is_empty():
		return 0.0
	var matching: int = 0
	for value in values:
		if absf(value) >= threshold:
			matching += 1
	return float(matching) / float(values.size())


static func share_at_or_below(values: PackedFloat64Array, threshold: float) -> float:
	if values.is_empty():
		return 0.0
	var matching: int = 0
	for value in values:
		if absf(value) <= threshold:
			matching += 1
	return float(matching) / float(values.size())


static func _cumulative(counts: PackedFloat64Array) -> PackedFloat64Array:
	var total: float = _sum(counts)
	var cumulative := PackedFloat64Array()
	var running: float = 0.0
	for count in counts:
		running += count
		cumulative.append(running / total if total > 0.0 else 0.0)
	return cumulative


static func _sum(values: PackedFloat64Array) -> float:
	var total: float = 0.0
	for value in values:
		total += value
	return total


static func _sample(cumulative: PackedFloat64Array, draw: float) -> int:
	for index in range(cumulative.size()):
		if draw <= cumulative[index]:
			return index
	return cumulative.size() - 1


# --- estimators --------------------------------------------------------------

static func variance(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	var average: float = CalibrationStatistics.mean(values)
	var total: float = 0.0
	for value in values:
		total += (value - average) * (value - average)
	return total / float(values.size() - 1)


static func covariance(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	assert(left.size() == right.size(), "covariance requires paired samples")
	if left.size() < 2:
		return 0.0
	var left_mean: float = CalibrationStatistics.mean(left)
	var right_mean: float = CalibrationStatistics.mean(right)
	var total: float = 0.0
	for index in range(left.size()):
		total += (left[index] - left_mean) * (right[index] - right_mean)
	return total / float(left.size() - 1)


static func correlation(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	var spread: float = sqrt(maxf(variance(left), 0.0) * maxf(variance(right), 0.0))
	if spread <= 0.0:
		return 0.0
	return covariance(left, right) / spread


## Least-squares residuals of `response` on an intercept and `predictors`.
##
## Built by modified Gram-Schmidt rather than by normal equations, because the
## predictors passed to it are not guaranteed to be independent and a singular
## system is not an error here. A mirror fixture holds both strength columns at
## the same value and the home environment fixed for every game; those are
## legitimate runs, and the right answer is to project onto whatever the
## predictors actually span rather than to fail or, worse, to return zeros and
## silently report the raw covariance as a residual one.
static func residuals_of(
	response: PackedFloat64Array,
	predictors: Array[PackedFloat64Array],
) -> PackedFloat64Array:
	var count: int = response.size()
	if count < 2:
		return response.duplicate()
	var basis: Array[PackedFloat64Array] = []
	var intercept := PackedFloat64Array()
	intercept.resize(count)
	intercept.fill(1.0 / sqrt(float(count)))
	basis.append(intercept)
	for predictor in predictors:
		if predictor.size() != count:
			continue
		var scale: float = sqrt(maxf(_dot(predictor, predictor), 0.0))
		if scale <= 0.0:
			continue
		var vector: PackedFloat64Array = predictor.duplicate()
		for existing in basis:
			var projection: float = _dot(vector, existing)
			for index in range(count):
				vector[index] -= projection * existing[index]
		var length: float = sqrt(maxf(_dot(vector, vector), 0.0))
		# A predictor the accepted basis already explains contributes nothing
		# and would only make the projection ill-conditioned.
		if length <= 1e-9 * scale:
			continue
		for index in range(count):
			vector[index] /= length
		basis.append(vector)
	var residuals: PackedFloat64Array = response.duplicate()
	for vector in basis:
		var projection: float = _dot(residuals, vector)
		for index in range(count):
			residuals[index] -= projection * vector[index]
	return residuals


static func _dot(left: PackedFloat64Array, right: PackedFloat64Array) -> float:
	var total: float = 0.0
	for index in range(left.size()):
		total += left[index] * right[index]
	return total


## A `Callable` returns `Variant`; every getter passed to this class returns a
## number, and this is the one place that narrowing happens.
static func _as_float(value: Variant) -> float:
	return value as float


## The absolute-margin state a possession is played in.
static func state_for_margin(absolute_margin: int) -> int:
	if absolute_margin <= STATE_CLOSE_MAX:
		return State.CLOSE
	if absolute_margin <= STATE_ORDINARY_MAX:
		return State.ORDINARY
	return State.DECIDED
