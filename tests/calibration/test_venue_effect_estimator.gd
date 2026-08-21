class_name TestVenueEffectEstimator
extends GdUnitTestSuite

## Arithmetic tests for `VenueEffectEstimator`, on rows whose answers are known.
##
## The §17.4 cap verdict rests entirely on this class, and a simulated game
## cannot check any of it because a simulated game has no known answer. The
## metric this replaced was formed from one arm and still printed a plausible
## number every time it ran, which is the whole reason a broken estimator is
## expensive: it does not announce itself.
##
## Seven properties, each of which a defective estimator could fail while still
## reporting something that looks like a venue effect:
##
## - it reads **both** venue arms, so a reversal that disagrees moves the answer;
## - it pairs by fixture identity, so two arms of one game are differenced
##   against each other and never against a different game;
## - it is invariant to the order the arms and fixtures arrive in;
## - it pools shards by union of fixture keys and refuses an overlap;
## - it refuses a fixture missing an arm rather than estimating from what
##   survived;
## - it reports pairs and complete games as the different numbers they are;
## - a duplicated observation is refused rather than counted twice.

const TOLERANCE: float = 0.000001


# --- helpers ----------------------------------------------------------------

## One complete matched triple with margins chosen by the caller. Possessions
## default to 100 so `points_per_100` reads directly as the margin gain.
func _observe_triple(
	estimator: VenueEffectEstimator,
	key: StringName,
	home_margin: float,
	neutral_margin: float,
	reversed_margin: float,
	possessions: float = 100.0,
) -> void:
	estimator.observe(key, VenueEffectEstimator.ARM_HOME, home_margin, possessions)
	estimator.observe(key, VenueEffectEstimator.ARM_NEUTRAL, neutral_margin, possessions)
	estimator.observe(key, VenueEffectEstimator.ARM_REVERSED, reversed_margin, possessions)


# --- it uses both arms -------------------------------------------------------

## The published contribution is the mean of the two venue arms' estimates, so
## moving the reversed arm alone must move it. The metric this replaced could
## not: it read the home arm and stopped.
func test_the_reversed_arm_moves_the_published_contribution() -> void:
	var first := VenueEffectEstimator.new()
	_observe_triple(first, &"f0", 4.0, 0.0, 4.0)
	# Home arm identical, reversed arm halved. A home-arm-only estimator returns
	# the same number for both of these; the paired estimator must not.
	var second := VenueEffectEstimator.new()
	_observe_triple(second, &"f0", 4.0, 0.0, 2.0)

	assert_float(first.paired_margin_difference()).is_equal_approx(4.0, TOLERANCE)
	assert_float(second.paired_margin_difference()).is_equal_approx(3.0, TOLERANCE)
	assert_float(first.home_arm_points_per_100()).is_equal_approx(
		second.home_arm_points_per_100(), TOLERANCE)
	assert_bool(
		absf(first.points_per_100() - second.points_per_100()) > 0.5).is_true()


## The two arm estimates are `h - n` and `r + n`, and their mean is `(h + r)/2`:
## the control cancels. That is a property of the design rather than an accident,
## and it is what allows the neutral arm to be read as an independent check
## instead of as an input to the answer. Pinned so a future edit that quietly
## folds the control back in is caught.
func test_the_neutral_control_cancels_out_of_the_pooled_estimate() -> void:
	var unbiased := VenueEffectEstimator.new()
	_observe_triple(unbiased, &"f0", 6.0, 0.0, 2.0)
	var biased := VenueEffectEstimator.new()
	# The same two venue arms against a control displaced by three points.
	_observe_triple(biased, &"f0", 6.0, 3.0, 2.0)

	assert_float(unbiased.paired_margin_difference()).is_equal_approx(4.0, TOLERANCE)
	assert_float(biased.paired_margin_difference()).is_equal_approx(4.0, TOLERANCE)
	# The single-arm reading, by contrast, moves by exactly the control's bias.
	assert_float(unbiased.home_arm_points_per_100()).is_equal_approx(6.0, TOLERANCE)
	assert_float(biased.home_arm_points_per_100()).is_equal_approx(3.0, TOLERANCE)


## The neutral arm is required even though it cancels. A triple without it is
## not a matched triple, and estimating from the two arms that survived would be
## reporting a sample the fixture never produced.
func test_a_missing_neutral_arm_is_refused_even_though_it_cancels() -> void:
	var estimator := VenueEffectEstimator.new()
	estimator.observe(&"f0", VenueEffectEstimator.ARM_HOME, 6.0, 100.0)
	estimator.observe(&"f0", VenueEffectEstimator.ARM_REVERSED, 2.0, 100.0)

	assert_int(estimator.pair_count()).is_equal(0)
	assert_array(estimator.incomplete_keys()).contains([&"f0"])
	assert_bool(estimator.is_well_formed()).is_false()
	assert_float(estimator.points_per_100()).is_equal_approx(0.0, TOLERANCE)


# --- it pairs identical fixtures --------------------------------------------

## Arms are differenced within a fixture key, never across keys.
##
## **The controls have to differ between fixtures for this to test anything**,
## and a mutation proved it: misaligning the reversed arm's control by one
## fixture survived an earlier version of this test whose two fixtures happened
## to share a neutral margin. The identical control cancelled either way.
##
## Worse, the *mean* cannot catch this class of defect at all. Shifting every
## control by one position cyclically changes each fixture's gain by
## `(n[i+1] - n[i])/2`, and those differences sum to zero around the cycle — so
## the published mean is exactly unchanged while every per-fixture value is
## wrong. Only the series discriminates, so the series is what is asserted.
func test_arms_are_differenced_within_a_fixture_and_not_across_fixtures() -> void:
	var estimator := VenueEffectEstimator.new()
	_observe_triple(estimator, &"f0", 10.0, 4.0, -4.0)
	_observe_triple(estimator, &"f1", -2.0, -6.0, -10.0)

	# f0: home gain 10-4 = 6, reversed gain -4+4 = 0, pooled 3.
	# f1: home gain -2-(-6) = 4, reversed gain -10+(-6) = -16, pooled -6.
	var gains: PackedFloat64Array = estimator.paired_margin_gain()
	assert_int(gains.size()).is_equal(2)
	assert_float(gains[0]).is_equal_approx(3.0, TOLERANCE)
	assert_float(gains[1]).is_equal_approx(-6.0, TOLERANCE)
	assert_float(estimator.paired_margin_difference()).is_equal_approx(-1.5, TOLERANCE)

	# The two arm series, pinned separately. A control borrowed from the wrong
	# fixture moves exactly one of these and leaves the other alone.
	var home_gains: PackedFloat64Array = estimator.home_arm_margin_gain()
	var reversed_gains: PackedFloat64Array = estimator.reversed_arm_margin_gain()
	assert_float(home_gains[0]).is_equal_approx(6.0, TOLERANCE)
	assert_float(home_gains[1]).is_equal_approx(4.0, TOLERANCE)
	assert_float(reversed_gains[0]).is_equal_approx(0.0, TOLERANCE)
	assert_float(reversed_gains[1]).is_equal_approx(-16.0, TOLERANCE)


## The same defect stated as the property it violates, on a sample large enough
## that a mean-only check would certainly pass.
##
## Every fixture here has a different control, and every fixture's venue effect
## is exactly +4 by construction. Correct pairing therefore gives a series that
## is constant at +4 with zero dispersion. Any misalignment of the controls
## leaves the mean at +4 and blows the dispersion up, so the interval is the
## thing that detects it — which is why the interval is asserted and not just
## the estimate.
func test_correct_pairing_shows_up_as_zero_dispersion_not_as_the_mean() -> void:
	var estimator := VenueEffectEstimator.new()
	for index in range(40):
		# A control that genuinely varies fixture to fixture.
		var control: float = float(index % 7) - 3.0
		# Both venue arms carry the same +4 effect over that control.
		_observe_triple(
			estimator, StringName("f%02d" % index),
			control + 4.0, control, -control + 4.0)

	assert_float(estimator.paired_margin_difference()).is_equal_approx(4.0, TOLERANCE)
	assert_float(estimator.paired_margin_half_width()).override_failure_message(
		"the paired series should be exactly constant when every fixture carries "
		+ "the same effect; dispersion here means the arms are being differenced "
		+ "against the wrong fixture's control"
	).is_equal_approx(0.0, TOLERANCE)


## The per-fixture series comes back in lexicographic key order regardless of
## the order the fixtures were observed in.
##
## This one caught a real defect. `Array[StringName].sort()` orders by Godot's
## internal `StringName` pointer rather than alphabetically, so the series came
## back in whatever order the engine happened to have interned the names —
## stable inside one run and not across runs. The published means are
## order-independent and were never wrong, but the series is written into the
## report, and a report whose rows reorder between two runs of the same seed
## range is not a reproducible artifact.
func test_the_paired_series_is_ordered_by_fixture_key_not_by_arrival() -> void:
	var estimator := VenueEffectEstimator.new()
	_observe_triple(estimator, &"z_last", 8.0, 0.0, 8.0)
	_observe_triple(estimator, &"a_first", 2.0, 0.0, 2.0)
	_observe_triple(estimator, &"m_middle", 4.0, 0.0, 4.0)

	var keys: Array[StringName] = estimator.complete_keys()
	assert_array(keys).is_equal([&"a_first", &"m_middle", &"z_last"])
	var gains: PackedFloat64Array = estimator.paired_margin_gain()
	assert_float(gains[0]).is_equal_approx(2.0, TOLERANCE)
	assert_float(gains[1]).is_equal_approx(4.0, TOLERANCE)
	assert_float(gains[2]).is_equal_approx(8.0, TOLERANCE)


## A fixture carrying only one arm contributes to nothing at all — not to the
## paired series, not to the arm win rates, and not to the possession base.
func test_a_fixture_with_one_arm_contributes_to_no_published_figure() -> void:
	var estimator := VenueEffectEstimator.new()
	_observe_triple(estimator, &"f0", 4.0, 0.0, 4.0, 100.0)
	# A stray home-arm observation with a wild margin and a wild possession
	# count. If any published figure moves, something is reading it.
	estimator.observe(&"orphan", VenueEffectEstimator.ARM_HOME, 500.0, 9000.0)

	assert_int(estimator.pair_count()).is_equal(1)
	assert_float(estimator.paired_margin_difference()).is_equal_approx(4.0, TOLERANCE)
	assert_float(estimator.possession_base()).is_equal_approx(100.0, TOLERANCE)
	assert_float(estimator.raw_home_win_rate()).is_equal_approx(1.0, TOLERANCE)
	assert_bool(estimator.is_well_formed()).is_false()


# --- it is invariant to ordering --------------------------------------------

## The order the arms are recorded in cannot move any published figure. The
## estimator is handed observations by a loop, and a loop's order is not part of
## the measurement.
func test_the_estimate_is_invariant_to_the_order_the_arms_arrive_in() -> void:
	var forward := VenueEffectEstimator.new()
	_observe_triple(forward, &"f0", 5.0, 1.0, 3.0)
	_observe_triple(forward, &"f1", -1.0, 2.0, 7.0)

	var shuffled := VenueEffectEstimator.new()
	shuffled.observe(&"f1", VenueEffectEstimator.ARM_REVERSED, 7.0, 100.0)
	shuffled.observe(&"f0", VenueEffectEstimator.ARM_NEUTRAL, 1.0, 100.0)
	shuffled.observe(&"f1", VenueEffectEstimator.ARM_HOME, -1.0, 100.0)
	shuffled.observe(&"f0", VenueEffectEstimator.ARM_REVERSED, 3.0, 100.0)
	shuffled.observe(&"f1", VenueEffectEstimator.ARM_NEUTRAL, 2.0, 100.0)
	shuffled.observe(&"f0", VenueEffectEstimator.ARM_HOME, 5.0, 100.0)

	assert_float(shuffled.paired_margin_difference()).is_equal_approx(
		forward.paired_margin_difference(), TOLERANCE)
	assert_float(shuffled.points_per_100()).is_equal_approx(
		forward.points_per_100(), TOLERANCE)
	assert_float(shuffled.points_per_100_half_width()).is_equal_approx(
		forward.points_per_100_half_width(), TOLERANCE)
	assert_float(shuffled.venue_attributable_win_rate()).is_equal_approx(
		forward.venue_attributable_win_rate(), TOLERANCE)
	assert_int(shuffled.pair_count()).is_equal(forward.pair_count())


## Swapping which venue arm is called `home` and which is called `reversed`
## negates the control's role and leaves the pooled estimate where it was. An
## estimator that weighted the two arms unequally would fail this.
func test_the_pooled_estimate_is_symmetric_in_the_two_venue_arms() -> void:
	var original := VenueEffectEstimator.new()
	_observe_triple(original, &"f0", 6.0, 0.0, 2.0)
	var swapped := VenueEffectEstimator.new()
	_observe_triple(swapped, &"f0", 2.0, 0.0, 6.0)

	assert_float(swapped.paired_margin_difference()).is_equal_approx(
		original.paired_margin_difference(), TOLERANCE)
	assert_float(swapped.points_per_100()).is_equal_approx(
		original.points_per_100(), TOLERANCE)


# --- it pools shards correctly ----------------------------------------------

## Two disjoint shards pool to the sample that ran, and to the estimate the two
## halves imply. Nothing is weighted by shard: a shard is a scheduling unit and
## not a stratum.
func test_disjoint_shards_pool_by_union_of_fixtures() -> void:
	var first := VenueEffectEstimator.new()
	_observe_triple(first, &"a0", 6.0, 0.0, 6.0)
	_observe_triple(first, &"a1", 2.0, 0.0, 2.0)
	var second := VenueEffectEstimator.new()
	_observe_triple(second, &"b0", 0.0, 0.0, 0.0)
	_observe_triple(second, &"b1", 4.0, 0.0, 4.0)

	assert_bool(first.merge(second)).is_true()
	assert_int(first.pair_count()).is_equal(4)
	assert_int(first.unique_games()).is_equal(12)
	assert_bool(first.is_well_formed()).is_true()
	# Per-fixture gains 6, 2, 0, 4 → mean 3.
	assert_float(first.paired_margin_difference()).is_equal_approx(3.0, TOLERANCE)
	assert_float(first.points_per_100()).is_equal_approx(3.0, TOLERANCE)


## Merging is order-independent: pooling A into B gives the same estimate as
## pooling B into A.
func test_pooling_is_independent_of_shard_order() -> void:
	var left := VenueEffectEstimator.new()
	_observe_triple(left, &"a0", 6.0, 1.0, 6.0)
	var right := VenueEffectEstimator.new()
	_observe_triple(right, &"b0", 2.0, -1.0, 0.0)

	var forward := VenueEffectEstimator.new()
	_observe_triple(forward, &"a0", 6.0, 1.0, 6.0)
	forward.merge(right)
	var backward := VenueEffectEstimator.new()
	_observe_triple(backward, &"b0", 2.0, -1.0, 0.0)
	backward.merge(left)

	assert_float(backward.paired_margin_difference()).is_equal_approx(
		forward.paired_margin_difference(), TOLERANCE)
	assert_int(backward.pair_count()).is_equal(forward.pair_count())


## A shard that repeats a fixture key the pool already owns is refused. This is
## the shape a re-run takes when its seed range was not moved, and pooling it
## would double a game's weight while reporting twice the sample.
func test_an_overlapping_shard_is_refused_rather_than_pooled() -> void:
	var pool := VenueEffectEstimator.new()
	_observe_triple(pool, &"a0", 6.0, 0.0, 6.0)
	var overlapping := VenueEffectEstimator.new()
	_observe_triple(overlapping, &"a0", 6.0, 0.0, 6.0)
	_observe_triple(overlapping, &"a1", 0.0, 0.0, 0.0)

	assert_bool(pool.merge(overlapping)).is_false()
	assert_array(pool.overlapping_keys()).contains(["a0"])
	assert_bool(pool.is_well_formed()).is_false()
	# The non-overlapping fixture is still pooled, and the duplicate is not.
	assert_int(pool.pair_count()).is_equal(2)
	assert_float(pool.paired_margin_difference()).is_equal_approx(3.0, TOLERANCE)


# --- it reports unique games accurately -------------------------------------

## Pairs and complete games are different numbers. Three arms of one fixture are
## three simulations and one piece of independent evidence, and reporting the
## simulation count as the sample size is how "25,000 games" gets written down.
func test_pairs_and_complete_games_are_reported_as_different_numbers() -> void:
	var estimator := VenueEffectEstimator.new()
	for index in range(250):
		_observe_triple(estimator, StringName("f%d" % index), 1.0, 0.0, 1.0)

	assert_int(estimator.pair_count()).is_equal(250)
	assert_int(estimator.unique_games()).is_equal(750)
	var payload: Dictionary = estimator.to_dictionary()
	assert_int(payload["pairs"] as int).is_equal(250)
	assert_int(payload["unique_games"] as int).is_equal(750)


## An incomplete fixture is excluded from both counts, so neither figure can be
## inflated by a fixture that did not finish.
func test_an_incomplete_fixture_raises_neither_count() -> void:
	var estimator := VenueEffectEstimator.new()
	_observe_triple(estimator, &"f0", 1.0, 0.0, 1.0)
	estimator.observe(&"f1", VenueEffectEstimator.ARM_HOME, 1.0, 100.0)
	estimator.observe(&"f1", VenueEffectEstimator.ARM_NEUTRAL, 0.0, 100.0)

	assert_int(estimator.pair_count()).is_equal(1)
	assert_int(estimator.unique_games()).is_equal(3)
	assert_int(estimator.incomplete_keys().size()).is_equal(1)


# --- it cannot pass by duplicating observations -----------------------------

## Recording the same arm of the same fixture twice is refused. The second copy
## changes nothing: not the estimate, not the interval, not the sample count.
func test_a_duplicated_observation_is_refused_and_changes_nothing() -> void:
	var estimator := VenueEffectEstimator.new()
	_observe_triple(estimator, &"f0", 6.0, 0.0, 6.0)
	_observe_triple(estimator, &"f1", 0.0, 0.0, 0.0)
	var estimate_before: float = estimator.points_per_100()
	var interval_before: float = estimator.points_per_100_half_width()

	assert_bool(
		estimator.observe(&"f0", VenueEffectEstimator.ARM_HOME, 6.0, 100.0)).is_false()
	assert_bool(
		estimator.observe(&"f1", VenueEffectEstimator.ARM_REVERSED, 0.0, 100.0)).is_false()

	assert_int(estimator.pair_count()).is_equal(2)
	assert_float(estimator.points_per_100()).is_equal_approx(estimate_before, TOLERANCE)
	assert_float(estimator.points_per_100_half_width()).is_equal_approx(
		interval_before, TOLERANCE)
	assert_int(estimator.duplicate_attempts().size()).is_equal(2)
	assert_bool(estimator.is_well_formed()).is_false()


## The interval cannot be narrowed by replaying the sample. Duplicating every
## fixture would halve a naive standard error while adding no information; here
## it is refused and the interval does not move.
func test_replaying_the_whole_sample_does_not_narrow_the_interval() -> void:
	var estimator := VenueEffectEstimator.new()
	for index in range(40):
		_observe_triple(estimator, StringName("f%d" % index), float(index % 5), 0.0, 0.0)
	var interval_before: float = estimator.points_per_100_half_width()
	var pairs_before: int = estimator.pair_count()

	for index in range(40):
		_observe_triple(estimator, StringName("f%d" % index), float(index % 5), 0.0, 0.0)

	assert_int(estimator.pair_count()).is_equal(pairs_before)
	assert_float(estimator.points_per_100_half_width()).is_equal_approx(
		interval_before, TOLERANCE)
	assert_bool(interval_before > 0.0).is_true()
	assert_bool(estimator.is_well_formed()).is_false()


# --- the published figures --------------------------------------------------

## The raw and neutral win rates are read off their own arms, and the
## venue-attributable rate is the baseline plus the paired gain rather than a
## subtraction of the two columns. On a constructed sample all three are known.
func test_the_three_win_rates_are_each_what_they_claim_to_be() -> void:
	var estimator := VenueEffectEstimator.new()
	# Four fixtures. Home arm wins 3 of 4; neutral arm wins 2 of 4; reversed arm
	# wins 3 of 4. Paired win gain per fixture: (wv(h)-wv(n) + wv(r)-wv(-n))/2.
	_observe_triple(estimator, &"f0", 5.0, 5.0, 5.0)
	_observe_triple(estimator, &"f1", 5.0, -5.0, 5.0)
	_observe_triple(estimator, &"f2", 5.0, 5.0, -5.0)
	_observe_triple(estimator, &"f3", -5.0, -5.0, 5.0)

	assert_float(estimator.raw_home_win_rate()).is_equal_approx(0.75, TOLERANCE)
	assert_float(estimator.neutral_home_win_rate()).is_equal_approx(0.5, TOLERANCE)
	# f0: (1-1 + 1-0)/2 = 0.5   f1: (1-0 + 1-1)/2 = 0.5
	# f2: (1-1 + 0-0)/2 = 0.0   f3: (0-0 + 1-1)/2 = 0.0
	# mean = 0.25 → 0.75
	assert_float(estimator.venue_attributable_win_rate()).is_equal_approx(0.75, TOLERANCE)


## The cap judges the paired two-arm contribution. A sample whose home arm
## breaches +2.5 while the pooled estimate does not must be judged on the
## pooled estimate — which is exactly the overseas case the previous report
## recorded as a failure of the metric rather than of the level.
func test_the_cap_judges_the_pooled_contribution_and_not_the_home_arm() -> void:
	var estimator := VenueEffectEstimator.new()
	# Home arm gain +4.0 a game, reversed arm gain +0.4: pooled +2.2.
	for index in range(50):
		_observe_triple(estimator, StringName("f%d" % index), 4.0, 0.0, 0.4)

	assert_float(estimator.home_arm_points_per_100()).is_equal_approx(4.0, TOLERANCE)
	assert_float(estimator.points_per_100()).is_equal_approx(2.2, TOLERANCE)
	assert_bool(estimator.cap_respected()).is_true()


## And a genuine breach is still a breach. The correction may not be a way of
## making the cap unfailable.
func test_a_genuine_breach_of_the_cap_is_still_reported() -> void:
	var estimator := VenueEffectEstimator.new()
	for index in range(50):
		_observe_triple(estimator, StringName("f%d" % index), 4.0, 0.0, 4.0)

	assert_float(estimator.points_per_100()).is_equal_approx(4.0, TOLERANCE)
	assert_bool(estimator.cap_respected()).is_false()


## The possession base is taken across the arms, so a scale drawn from one arm
## cannot set the published units. Doubling only the home arm's possessions
## moves the base by a third, not by a half.
func test_the_possession_base_is_taken_across_the_arms() -> void:
	var estimator := VenueEffectEstimator.new()
	estimator.observe(&"f0", VenueEffectEstimator.ARM_HOME, 3.0, 200.0)
	estimator.observe(&"f0", VenueEffectEstimator.ARM_NEUTRAL, 0.0, 100.0)
	estimator.observe(&"f0", VenueEffectEstimator.ARM_REVERSED, 3.0, 100.0)

	assert_float(estimator.possession_base()).is_equal_approx(400.0 / 3.0, TOLERANCE)
	assert_float(estimator.points_per_100()).is_equal_approx(
		100.0 * 3.0 / (400.0 / 3.0), TOLERANCE)


## The reversal control fails when the two arms disagree beyond their combined
## intervals, and passes when they agree. Both directions are pinned: a control
## that always passes is not a control.
func test_the_reversal_control_fails_on_disagreement_and_passes_on_agreement() -> void:
	var agreeing := VenueEffectEstimator.new()
	for index in range(60):
		var jitter: float = 1.0 if index % 2 == 0 else -1.0
		_observe_triple(agreeing, StringName("f%d" % index), 2.0 + jitter, 0.0, 2.0 - jitter)
	assert_bool(agreeing.venue_reversal_agrees()).is_true()

	var disagreeing := VenueEffectEstimator.new()
	for index in range(60):
		var jitter: float = 0.2 if index % 2 == 0 else -0.2
		_observe_triple(
			disagreeing, StringName("f%d" % index), 8.0 + jitter, 0.0, -4.0 + jitter)
	assert_bool(disagreeing.venue_reversal_agrees()).is_false()


## An empty estimator publishes zeroes and no verdict-bearing nonsense, and says
## it is not well formed only when something was actually offered and refused.
func test_an_empty_estimator_reports_nothing_rather_than_a_number() -> void:
	var estimator := VenueEffectEstimator.new()

	assert_int(estimator.pair_count()).is_equal(0)
	assert_int(estimator.unique_games()).is_equal(0)
	assert_float(estimator.points_per_100()).is_equal_approx(0.0, TOLERANCE)
	assert_float(estimator.possession_base()).is_equal_approx(0.0, TOLERANCE)
	assert_bool(estimator.is_well_formed()).is_true()
