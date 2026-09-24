class_name TestMarginDecomposition
extends GdUnitTestSuite

## Arithmetic tests for `MarginDecomposition`, on synthetic rows.
##
## The margin report's conclusions rest on three claims about this class: that
## the six-term identity reconstructs the margin exactly, that the covariance
## shares therefore partition the margin variance and sum to one, and that the
## over-dispersion ratio is one when possessions really are independent. None of
## those can be checked against a simulated game — a simulated game has no known
## answer — so they are checked here against rows whose answer is known.
##
## The classification thresholds are here for the same reason. §14.2 defines a
## blowout as twenty points *or more* and a close game as five *or fewer*, and
## an off-by-one on either boundary would move a reported share by a percentage
## point or so and look like a calibration result.

const TOLERANCE: float = 0.000001


## §14.2 boundaries, on both sides of each edge.
func test_margin_classification_uses_the_specified_boundaries() -> void:
	var decomposition := MarginDecomposition.new()
	for margin in PackedInt32Array([0, 3, 5, 6, 19, 20, 21, 40]):
		decomposition.add(_row_with_margin(margin))

	# Blowouts: 20, 21, 40. Not 19.
	assert_int(decomposition.blowout_count()).is_equal(3)
	# Close: 0, 3, 5. Not 6.
	assert_int(decomposition.close_count()).is_equal(3)
	# One possession is three or fewer: 0, 3.
	assert_float(decomposition.one_possession_share()).is_equal_approx(2.0 / 8.0, TOLERANCE)
	# Two possessions is six or fewer: 0, 3, 5, 6.
	assert_float(decomposition.two_possession_share()).is_equal_approx(4.0 / 8.0, TOLERANCE)


## The sign convention is home-minus-away, and the shares are of absolute
## margin, so a twenty-point away win is a blowout too.
func test_classification_is_signless() -> void:
	var decomposition := MarginDecomposition.new()
	decomposition.add(_row_with_margin(22))
	decomposition.add(_row_with_margin(-22))
	assert_int(decomposition.blowout_count()).is_equal(2)
	assert_float(decomposition.blowout_share()).is_equal_approx(1.0, TOLERANCE)


## The identity closes on rows whose box scores are unrelated to each other, so
## it is closing by construction rather than by luck.
func test_the_six_term_identity_reconstructs_the_margin() -> void:
	var decomposition: MarginDecomposition = _varied_sample()
	assert_float(decomposition.worst_identity_error()).is_less(0.001)
	for row in decomposition.rows:
		var total: float = 0.0
		for value in row.components():
			total += value
		assert_float(total).is_equal_approx(row.margin(), 0.001)


## Because the components sum to the margin in every row, their covariance
## shares are a partition of the margin variance and sum to one.
func test_component_variance_shares_sum_to_one() -> void:
	var decomposition: MarginDecomposition = _varied_sample()
	var total: float = 0.0
	for component in range(MarginDecomposition.COMPONENT_COUNT):
		total += decomposition.variance_share(component)
	assert_float(total).is_equal_approx(1.0, 0.000001)


## A margin built from possessions that really are independent draws reports an
## over-dispersion ratio of one. This is the reference the engine is measured
## against, so it has to be exact on data whose answer is known.
func test_independent_possessions_report_a_ratio_near_one() -> void:
	var decomposition := MarginDecomposition.new()
	var random := SeededRandomSource.new(20260819)
	for index in range(4000):
		decomposition.add(_independent_row(index, random))
	assert_float(decomposition.within_game_possession_variance()).is_greater(0.5)
	# Sampling error on a ratio of two standard deviations at this sample is
	# well under two percent; the window is generous and still excludes the
	# defects it exists to catch.
	assert_float(decomposition.overdispersion_ratio()).is_greater(0.95)
	assert_float(decomposition.overdispersion_ratio()).is_less(1.05)


## A persistent game-level scoring multiplier — the failure mode the report
## calls a hot/cold state — pushes the ratio above one. Without this case the
## test above would pass on an estimator that always returned one.
func test_a_persistent_game_level_effect_raises_the_ratio() -> void:
	var decomposition := MarginDecomposition.new()
	var random := SeededRandomSource.new(20260819)
	for index in range(4000):
		decomposition.add(_correlated_row(index, random))
	assert_float(decomposition.overdispersion_ratio()).is_greater(1.15)


## The pregame regression separates what was settled before tip-off from what
## the game invented. On rows whose margin is a fixed multiple of the gap plus
## nothing else, it recovers the multiple and reports no residual.
func test_the_strength_regression_recovers_a_known_slope() -> void:
	var decomposition := MarginDecomposition.new()
	for index in range(40):
		var row: MarginDecomposition.GameRow = _row_with_margin(0)
		row.expected_gap = float(index) - 20.0
		var margin: int = int(roundf(row.expected_gap * 1.5))
		row.home_score = 100 + margin
		row.away_score = 100
		decomposition.add(row)
	assert_float(decomposition.strength_slope()).is_equal_approx(1.5, 0.05)
	assert_float(decomposition.strength_explained_share()).is_greater(0.99)
	assert_float(decomposition.residual_standard_deviation()).is_less(1.0)


## Banding is inclusive at the lower edge and exclusive at the upper, so the
## three matchup bands partition the sample exactly once.
func test_matchup_bands_partition_the_sample() -> void:
	var decomposition := MarginDecomposition.new()
	for index in range(30):
		var row: MarginDecomposition.GameRow = _row_with_margin(index)
		row.expected_gap = float(index) * 0.5 - 7.0
		decomposition.add(row)
	var near_even: int = decomposition.band(0.0, 1.5).size()
	var modest: int = decomposition.band(1.5, 4.0).size()
	var large: int = decomposition.band(4.0, INF).size()
	assert_int(near_even + modest + large).is_equal(decomposition.size())
	assert_int(near_even).is_greater(0)
	assert_int(modest).is_greater(0)
	assert_int(large).is_greater(0)


# --- fixtures ---------------------------------------------------------------

## A row whose margin is the supplied number and whose box score is consistent
## with it: the home team scores its margin entirely from free throws, which
## keeps the identity trivially satisfiable while the classification is tested.
func _row_with_margin(margin: int) -> MarginDecomposition.GameRow:
	var row := MarginDecomposition.GameRow.new()
	row.home_score = 100 + margin
	row.away_score = 100
	row.home_possessions = 100
	row.away_possessions = 100
	row.home_field_goals_attempted = 88
	row.away_field_goals_attempted = 88
	row.home_effective_field_goal = 0.53
	row.away_effective_field_goal = 0.53
	row.home_free_throws_made = 15 + margin
	row.away_free_throws_made = 15
	row.possession_outcome_counts = PackedInt32Array([0, 0, 0, 0, 0])
	return row


## Rows whose four channels all differ, so the identity and the variance
## partition are exercised rather than satisfied by symmetry.
func _varied_sample() -> MarginDecomposition:
	var decomposition := MarginDecomposition.new()
	var random := SeededRandomSource.new(4242)
	for index in range(200):
		var row := MarginDecomposition.GameRow.new()
		row.home_possessions = 96 + int(random.next_float() * 8.0)
		row.away_possessions = row.home_possessions + (1 if index % 2 == 0 else 0)
		row.home_field_goals_attempted = 82 + int(random.next_float() * 20.0)
		row.away_field_goals_attempted = 82 + int(random.next_float() * 20.0)
		row.home_effective_field_goal = 0.44 + random.next_float() * 0.20
		row.away_effective_field_goal = 0.44 + random.next_float() * 0.20
		row.home_turnovers = 9 + int(random.next_float() * 12.0)
		row.away_turnovers = 9 + int(random.next_float() * 12.0)
		row.home_offensive_rebounds = 6 + int(random.next_float() * 16.0)
		row.away_offensive_rebounds = 6 + int(random.next_float() * 16.0)
		row.home_free_throws_made = 8 + int(random.next_float() * 22.0)
		row.away_free_throws_made = 8 + int(random.next_float() * 22.0)
		row.possession_outcome_counts = PackedInt32Array([0, 0, 0, 0, 0])
		# The scores are *derived* from the box score, exactly as a real ledger
		# derives them, so the identity has something to reconstruct.
		row.home_score = int(roundf(
			2.0 * row.home_effective_field_goal * float(row.home_field_goals_attempted)
			+ float(row.home_free_throws_made)))
		row.away_score = int(roundf(
			2.0 * row.away_effective_field_goal * float(row.away_field_goals_attempted)
			+ float(row.away_free_throws_made)))
		# `components()` reads the stored efficiencies, so the rounding above has
		# to be handed back or the identity would carry the rounding error.
		row.home_effective_field_goal = (
			float(row.home_score - row.home_free_throws_made)
			/ (2.0 * float(row.home_field_goals_attempted)))
		row.away_effective_field_goal = (
			float(row.away_score - row.away_free_throws_made)
			/ (2.0 * float(row.away_field_goals_attempted)))
		decomposition.add(row)
	return decomposition


## One game of genuinely independent possessions, drawn from a fixed
## points-per-possession distribution.
func _independent_row(index: int, random: RandomSource) -> MarginDecomposition.GameRow:
	return _row_from_possessions(index, random, 1.0)


## The same, with a per-team game-level multiplier applied to every possession
## in that team-game.
func _correlated_row(index: int, random: RandomSource) -> MarginDecomposition.GameRow:
	return _row_from_possessions(index, random, 1.35)


func _row_from_possessions(
	index: int,
	random: RandomSource,
	spread: float,
) -> MarginDecomposition.GameRow:
	var row := MarginDecomposition.GameRow.new()
	row.variation = index
	row.home_possessions = 100
	row.away_possessions = 100
	row.possession_outcome_counts = PackedInt32Array([0, 0, 0, 0, 0])
	var home := _team_possessions(random, spread)
	var away := _team_possessions(random, spread)
	row.home_score = int(home[0])
	row.away_score = int(away[0])
	row.home_possession_points_squared = home[1]
	row.away_possession_points_squared = away[1]
	row.home_field_goals_attempted = 88
	row.away_field_goals_attempted = 88
	row.home_effective_field_goal = 0.53
	row.away_effective_field_goal = 0.53
	return row


## Returns `[total points, sum of squared possession points]` for one team-game.
## `spread` above one multiplies every scoring probability in the game by a
## draw shared across that team's possessions, which is the persistent
## game-level effect the ratio is supposed to detect.
func _team_possessions(random: RandomSource, spread: float) -> PackedFloat64Array:
	var multiplier: float = 1.0
	if spread > 1.0:
		multiplier = 1.0 + (random.next_float() - 0.5) * 2.0 * (spread - 1.0)
	var total: float = 0.0
	var squares: float = 0.0
	for _possession in range(100):
		var draw: float = random.next_float()
		var points: float = 0.0
		if draw < 0.19 * multiplier:
			points = 3.0
		elif draw < (0.19 + 0.29) * multiplier:
			points = 2.0
		elif draw < (0.19 + 0.29 + 0.02) * multiplier:
			points = 1.0
		total += points
		squares += points * points
	return PackedFloat64Array([total, squares])
