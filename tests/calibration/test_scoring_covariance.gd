class_name TestScoringCovariance
extends GdUnitTestSuite

## Arithmetic tests for `ScoringCovariance`, on rows whose answers are known.
##
## The §5.11 conclusion rests on five claims about this class, and a simulated
## game cannot check any of them because a simulated game has no known answer:
##
## - `Var(A - B) = Var(A) + Var(B) - 2 Cov(A, B)` closes exactly, so the
##   covariance term is a real accounting of the margin's variance rather than
##   a quantity reported beside it;
## - the covariance estimator recovers a covariance that was put in on purpose;
## - residualizing removes a linear predictor and leaves the covariance that was
##   not explained by it;
## - the permutation control returns one on a sequence with no serial structure,
##   which is what licenses reading the corrected variance ratio at all;
## - damping the leading team reduces the margin's dispersion monotonically,
##   which is the model the feasibility frontier is computed from.
##
## The last two are the ones that would fail silently. A variance ratio with a
## broken control still prints a number.

const TOLERANCE: float = 0.000001


# --- the identity ------------------------------------------------------------

## The identity closes on arbitrary unrelated scores. Every row here has a
## different pair of totals, so nothing about the construction makes the two
## sides agree except the algebra.
func test_the_margin_variance_identity_closes_exactly() -> void:
	var sample := ScoringCovariance.new()
	var home_totals: PackedInt32Array = [101, 88, 120, 95, 77, 133, 104, 91]
	var away_totals: PackedInt32Array = [96, 103, 99, 95, 84, 118, 87, 112]
	for index in range(home_totals.size()):
		sample.add(_row(home_totals[index], away_totals[index]))
	assert_float(sample.reconstruction_error()).is_less(TOLERANCE)
	assert_float(sample.reconstructed_margin_variance())\
		.is_equal_approx(sample.margin_variance(), TOLERANCE)


## A covariance that was put in deliberately comes back out. `away = 2 * home`
## up to a constant makes `Cov(A, B) = 2 Var(A)` exactly, and the margin's
## variance falls out of the identity rather than being measured separately.
func test_a_known_covariance_is_recovered() -> void:
	var sample := ScoringCovariance.new()
	var home_totals: PackedInt32Array = [90, 95, 100, 105, 110]
	for total in home_totals:
		sample.add(_row(total, 2 * total - 100))
	assert_float(sample.points_covariance())\
		.is_equal_approx(2.0 * sample.home_points_variance(), TOLERANCE)
	assert_float(sample.points_correlation()).is_equal_approx(1.0, 0.000001)
	assert_float(sample.reconstruction_error()).is_less(TOLERANCE)


## Zero covariance is reported as zero rather than as something small: the whole
## §5.11 argument turns on being able to tell those apart.
func test_orthogonal_columns_report_no_covariance() -> void:
	var sample := ScoringCovariance.new()
	var home_totals: PackedInt32Array = [100, 100, 110, 110]
	var away_totals: PackedInt32Array = [95, 105, 95, 105]
	for index in range(home_totals.size()):
		sample.add(_row(home_totals[index], away_totals[index]))
	assert_float(sample.points_covariance()).is_equal_approx(0.0, TOLERANCE)
	assert_float(sample.margin_variance()).is_equal_approx(
		sample.home_points_variance() + sample.away_points_variance(), TOLERANCE)


# --- residualization ---------------------------------------------------------

## A covariance that is entirely a shared linear predictor disappears once that
## predictor is projected out; a covariance that is not survives it.
func test_residualization_removes_a_shared_predictor() -> void:
	var shared := ScoringCovariance.new()
	for step in range(8):
		# Both teams score in proportion to the same strength column, and
		# nothing else links them.
		var strength: float = 70.0 + float(step)
		var row: ScoringCovariance.GameRow = _row(
			int(roundf(strength * 1.4)), int(roundf(strength * 1.3)))
		row.home_strength = strength
		row.away_strength = strength
		shared.add(row)
	assert_float(shared.points_covariance()).is_greater(1.0)
	assert_float(absf(shared.residual_points_covariance())).is_less(0.01)


# --- the path ----------------------------------------------------------------

## The permutation control is what the corrected variance ratio is divided by,
## so it has to reproduce the artefact and contain none of the behaviour. On a
## sample whose real and control accumulators are identical by construction, the
## corrected ratio is exactly one at every horizon.
func test_the_corrected_variance_ratio_is_one_without_serial_structure() -> void:
	var sample := ScoringCovariance.new()
	for step in range(6):
		var row: ScoringCovariance.GameRow = _row(100 + step, 98 + step)
		# The real and control accumulators are filled with the same numbers,
		# which is the situation a permutation produces when order carries no
		# information at all.
		row.increment_squares = 160.0
		row.increment_count = 100.0
		row.control_increment_squares = 160.0
		row.control_increment_count = 100.0
		for index in range(ScoringCovariance.WINDOW_LENGTHS.size()):
			var length: float = float(ScoringCovariance.WINDOW_LENGTHS[index])
			row.window_squares[index] = 1.6 * length * 90.0
			row.window_counts[index] = 90.0
			row.control_window_squares[index] = 1.6 * length * 90.0
			row.control_window_counts[index] = 90.0
		sample.add(row)
	for index in range(ScoringCovariance.WINDOW_LENGTHS.size()):
		assert_float(sample.corrected_variance_ratio(index))\
			.override_failure_message("window %d" % ScoringCovariance.WINDOW_LENGTHS[index])\
			.is_equal_approx(1.0, TOLERANCE)


## A control that is *smaller* than the real statistic is a path that trends,
## and a larger one is a path that reverts. The corrected ratio has to move in
## that direction, or the frontier is being read with the sign inverted.
func test_the_corrected_variance_ratio_moves_with_the_real_statistic() -> void:
	var trending := _path_sample(1.20)
	var reverting := _path_sample(0.80)
	assert_float(trending.corrected_variance_ratio(3)).is_greater(1.0)
	assert_float(reverting.corrected_variance_ratio(3)).is_less(1.0)


# --- the replay models -------------------------------------------------------

## Independent possessions drawn from the pooled distribution reproduce the
## dispersion that distribution implies, and damping the leading team reduces it
## monotonically. Both are the feasibility frontier's own arithmetic.
func test_damping_the_leading_team_reduces_dispersion_monotonically() -> void:
	var sample := _outcome_sample()
	var stream: RandomSource = SeededRandomSource.new(24680)
	var undamped: PackedFloat64Array = sample.independence_margins(stream.derive(&"a"), 40)
	assert_int(undamped.size()).is_greater(0)
	var previous: float = sqrt(ScoringCovariance.variance(undamped))
	assert_float(previous).is_greater(5.0)
	for penalty: float in [0.05, 0.10, 0.20]:
		var damped: PackedFloat64Array = sample.damped_margins(
			stream.derive(StringName("d%d" % int(penalty * 100.0))), 40, penalty, 15.0)
		var deviation: float = sqrt(ScoringCovariance.variance(damped))
		assert_float(deviation)\
			.override_failure_message("penalty %.2f" % penalty).is_less(previous)
		previous = deviation


## The damped model keeps the margin on the integer lattice. It has to: the
## overtime rate is read as the share of margins that are exactly zero, and a
## penalty applied as a fraction of a point would drive that share to nothing
## while answering the blowout question perfectly well.
func test_the_damped_model_keeps_the_margin_on_the_lattice() -> void:
	var sample := _outcome_sample()
	var damped: PackedFloat64Array = sample.damped_margins(
		SeededRandomSource.new(1357), 20, 0.20, 12.0)
	assert_int(damped.size()).is_greater(0)
	for value in damped:
		assert_float(absf(value - roundf(value)))\
			.override_failure_message("margin %f is not an integer" % value)\
			.is_less(TOLERANCE)


# --- classification ----------------------------------------------------------

## §14.2 boundaries, on both sides of each edge, on the same convention
## `MarginDecomposition` uses.
func test_margin_classification_uses_the_specified_boundaries() -> void:
	var sample := ScoringCovariance.new()
	for margin: int in [0, 3, 5, 6, 19, 20, 21, 40]:
		sample.add(_row(100 + margin, 100))
	assert_int(sample.blowout_count()).is_equal(3)
	assert_int(sample.close_count()).is_equal(3)
	assert_float(sample.one_possession_share()).is_equal_approx(2.0 / 8.0, TOLERANCE)
	assert_float(sample.two_possession_share()).is_equal_approx(4.0 / 8.0, TOLERANCE)


## The absolute-margin state a possession is played in, on both sides of each
## boundary. A possession played at exactly five points is close; at six it is
## not; at fifteen it is decided.
func test_score_states_use_the_documented_boundaries() -> void:
	assert_int(ScoringCovariance.state_for_margin(0)).is_equal(ScoringCovariance.State.CLOSE)
	assert_int(ScoringCovariance.state_for_margin(5)).is_equal(ScoringCovariance.State.CLOSE)
	assert_int(ScoringCovariance.state_for_margin(6)).is_equal(ScoringCovariance.State.ORDINARY)
	assert_int(ScoringCovariance.state_for_margin(14)).is_equal(ScoringCovariance.State.ORDINARY)
	assert_int(ScoringCovariance.state_for_margin(15)).is_equal(ScoringCovariance.State.DECIDED)
	assert_int(ScoringCovariance.state_for_margin(60)).is_equal(ScoringCovariance.State.DECIDED)


# --- helpers -----------------------------------------------------------------

func _row(home_points: int, away_points: int) -> ScoringCovariance.GameRow:
	var row := ScoringCovariance.GameRow.new()
	row.home_points = home_points
	row.away_points = away_points
	row.regulation_home = home_points
	row.regulation_away = away_points
	row.home_possessions = 100
	row.away_possessions = 100
	row.seconds_per_possession = 14.3
	row.home_environment = 0.5
	row.home_period_points = PackedFloat64Array([float(home_points)])
	row.away_period_points = PackedFloat64Array([float(away_points)])
	return row


## Rows whose real window accumulator is `factor` times the control's, which is
## the shape of a trending or reverting path.
func _path_sample(factor: float) -> ScoringCovariance:
	var sample := ScoringCovariance.new()
	for step in range(6):
		var row: ScoringCovariance.GameRow = _row(100 + step, 98 + step)
		row.increment_squares = 160.0
		row.increment_count = 100.0
		row.control_increment_squares = 160.0
		row.control_increment_count = 100.0
		for index in range(ScoringCovariance.WINDOW_LENGTHS.size()):
			var length: float = float(ScoringCovariance.WINDOW_LENGTHS[index])
			row.control_window_squares[index] = 1.6 * length * 90.0
			row.control_window_counts[index] = 90.0
			row.window_squares[index] = factor * 1.6 * length * 90.0
			row.window_counts[index] = 90.0
		sample.add(row)
	return sample


## Rows carrying a realistic possession-outcome distribution, so the replay
## models have something to draw from.
func _outcome_sample() -> ScoringCovariance:
	var sample := ScoringCovariance.new()
	# Roughly the measured top-domestic shape: half the possessions score
	# nothing, most of the rest are worth two or three.
	var shape: PackedFloat64Array = [51.0, 2.0, 28.0, 18.0, 1.0, 0.0, 0.0]
	for step in range(24):
		var row: ScoringCovariance.GameRow = _row(100, 100)
		for bucket in range(ScoringCovariance.OUTCOME_BUCKETS):
			row.home_outcome_counts[bucket] = shape[bucket]
			row.away_outcome_counts[bucket] = shape[bucket]
		row.variation = step
		sample.add(row)
	return sample
