class_name TestHomeWinVerdictOwnership
extends GdUnitTestSuite

## Which metric owns the §14.2 home-win verdict.
##
## The owner ruling:
##
## > The §14.2 home-win target is judged by the controlled, symmetrized paired
## > venue-side win estimator. The marginal single-arm `home.win_rate` remains an
## > informational population diagnostic and does not independently determine the
## > home-environment calibration verdict.
##
## This suite asserts the ruling against the *emitted report*, not against the
## estimator's arithmetic — which is covered by
## `test_venue_effect_estimator.gd`. The distinction matters: an estimator can be
## perfectly correct while the runner still hands the verdict to the wrong
## metric, and that is precisely the state this ruling exists to end.
##
## The metrics are built here the way the runner builds them, from a
## `VenueEffectEstimator` and a marginal win rate, so the test pins the *shape*
## of the published contract rather than re-simulating games.

const TOLERANCE: float = 0.000001

## The §14.2 band, so a deliberately out-of-band marginal value can be chosen.
const BAND_MINIMUM: float = 0.53
const BAND_MAXIMUM: float = 0.56


func _estimator_in_band() -> VenueEffectEstimator:
	# 20 fixtures whose paired estimate lands inside 0.53-0.56: the venue side
	# wins 11 of 20 in each venue arm, giving 0.55.
	var estimator := VenueEffectEstimator.new()
	for index in range(20):
		var venue_wins: bool = index < 11
		var margin: float = 6.0 if venue_wins else -6.0
		estimator.observe(StringName("f%02d" % index),
			VenueEffectEstimator.ARM_HOME, margin, 100.0)
		estimator.observe(StringName("f%02d" % index),
			VenueEffectEstimator.ARM_NEUTRAL, 0.0, 100.0)
		estimator.observe(StringName("f%02d" % index),
			VenueEffectEstimator.ARM_REVERSED, margin, 100.0)
	return estimator


## The judged metric carries the §14.2 target and returns a real verdict.
func test_the_paired_estimator_is_the_judged_metric() -> void:
	var estimator: VenueEffectEstimator = _estimator_in_band()
	var judged: CalibrationMetric = CalibrationMetric.banded(
		&"top_domestic_pro.venue.attributable_home_win_rate",
		"JUDGED §14.2 metric.",
		"matched pairs", estimator.venue_attributable_win_rate(),
		CalibrationTargets.home_win_rate(), estimator.pair_count())

	assert_float(estimator.venue_attributable_win_rate()).is_equal_approx(0.55, TOLERANCE)
	assert_int(judged.verdict).is_not_equal(CalibrationMetric.Verdict.INFORMATIONAL)
	assert_int(judged.verdict).is_equal(CalibrationMetric.Verdict.PASS)
	assert_float(judged.target_minimum).is_equal_approx(BAND_MINIMUM, TOLERANCE)
	assert_float(judged.target_maximum).is_equal_approx(BAND_MAXIMUM, TOLERANCE)


## The marginal metric carries no target and can never fail the gate.
##
## This is the half of the ruling that is easy to get wrong. `home.win_rate` is
## still published — removing it would hide the evidence that the two estimators
## disagree — but a value far outside 0.53-0.56 must produce an informational
## verdict, not a failure. On Validation C the marginal metric read 0.4880 at
## overseas while the judged metric read 0.5400 on the same games; under the old
## arrangement that made the report red for a reason the ruling rejects.
func test_the_marginal_metric_is_informational_and_cannot_fail_the_gate() -> void:
	for marginal_value: float in [0.4880, 0.5880, 0.0, 1.0]:
		var informational: CalibrationMetric = CalibrationMetric.raw(
			&"top_domestic_pro.home.win_rate",
			"INFORMATIONAL population diagnostic: §14.2 is judged by "
			+ "`venue.attributable_home_win_rate`.",
			"decided games", marginal_value, 250).with_interval(0.062)

		assert_int(informational.verdict).override_failure_message(
			"the marginal home win rate at %.4f produced a verdict; the ruling "
			% marginal_value + "makes it informational"
		).is_equal(CalibrationMetric.Verdict.INFORMATIONAL)
		assert_bool(informational.failed()).is_false()
		assert_str(String(informational.verdict_id())).is_equal("informational")


## The two can disagree, and only one of them decides.
##
## Built from one set of games: the judged estimate is in band, the marginal
## reading is not. The report must pass.
func test_a_disagreement_is_resolved_by_the_judged_metric() -> void:
	var estimator: VenueEffectEstimator = _estimator_in_band()
	var judged: CalibrationMetric = CalibrationMetric.banded(
		&"x.venue.attributable_home_win_rate", "judged", "matched pairs",
		estimator.venue_attributable_win_rate(),
		CalibrationTargets.home_win_rate(), estimator.pair_count())
	# A marginal reading well below the band, as overseas produced on Val C.
	var informational: CalibrationMetric = CalibrationMetric.raw(
		&"x.home.win_rate", "informational", "decided games", 0.4880, 250)

	var report_failed: bool = judged.failed() or informational.failed()
	assert_bool(report_failed).override_failure_message(
		"a marginal reading outside the band still fails the report, so the "
		+ "marginal metric is still deciding the verdict"
	).is_false()
	assert_bool(judged.failed()).is_false()


## A genuine failure of the judged metric still fails.
##
## The ruling moves which metric decides; it does not make the gate unfailable.
## Top domestic did fail this band on both untouched validation ranges and must
## continue to.
func test_the_judged_metric_still_fails_when_the_venue_effect_is_wrong() -> void:
	var estimator := VenueEffectEstimator.new()
	# The venue side wins every game in both venue arms: 1.00, far above 0.56.
	for index in range(20):
		estimator.observe(StringName("f%02d" % index),
			VenueEffectEstimator.ARM_HOME, 9.0, 100.0)
		estimator.observe(StringName("f%02d" % index),
			VenueEffectEstimator.ARM_NEUTRAL, 0.0, 100.0)
		estimator.observe(StringName("f%02d" % index),
			VenueEffectEstimator.ARM_REVERSED, 9.0, 100.0)
	var judged: CalibrationMetric = CalibrationMetric.banded(
		&"x.venue.attributable_home_win_rate", "judged", "matched pairs",
		estimator.venue_attributable_win_rate(),
		CalibrationTargets.home_win_rate(), estimator.pair_count())

	assert_float(estimator.venue_attributable_win_rate()).is_equal_approx(1.0, TOLERANCE)
	assert_bool(judged.failed()).is_true()


## The §14.2 band itself is unchanged. No target was weakened by the ruling —
## only the estimator that reads it moved.
func test_the_fourteen_two_band_is_untouched() -> void:
	var band: CalibrationBand = CalibrationTargets.home_win_rate()
	assert_float(band.minimum).is_equal_approx(BAND_MINIMUM, TOLERANCE)
	assert_float(band.maximum).is_equal_approx(BAND_MAXIMUM, TOLERANCE)


## The runner publishes the marginal metric without a target, and the judged
## metric with one. Asserted against the runner's source so the emission shape
## cannot drift back without this failing.
func test_the_runner_emits_exactly_one_judged_home_win_metric() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://calibration/runners/run_home_court_diagnostics.gd")
	assert_str(source).is_not_empty()

	var judged_constructor: String = _constructor_for(
		source, "\"%s.venue.attributable_home_win_rate\"")
	var marginal_constructor: String = _constructor_for(source, "\"%s.home.win_rate\"")

	assert_str(judged_constructor).override_failure_message(
		"the paired estimator is emitted with CalibrationMetric.%s; the owner "
		% judged_constructor + "ruling makes it the judged §14.2 metric"
	).is_equal("banded")
	assert_str(marginal_constructor).override_failure_message(
		"`home.win_rate` is emitted with CalibrationMetric.%s; the owner ruling "
		% marginal_constructor + "makes it an informational population diagnostic"
	).is_equal("raw")


## The `CalibrationMetric` constructor used for the emission of one metric id.
##
## Finds the id, then walks back to the nearest `CalibrationMetric.<name>(`
## before it. A fixed-width character window was tried first and was wrong: it
## straddled unrelated code and reported whichever constructor happened to be
## nearby, which is exactly the kind of test that passes for the wrong reason.
func _constructor_for(source: String, metric_id_literal: String) -> String:
	var at: int = source.find(metric_id_literal)
	if at < 0:
		return "<metric id not found: %s>" % metric_id_literal
	var marker: String = "CalibrationMetric."
	var start: int = source.rfind(marker, at)
	if start < 0:
		return "<no CalibrationMetric constructor precedes the id>"
	var open_paren: int = source.find("(", start)
	if open_paren < 0:
		return "<malformed constructor call>"
	return source.substr(
		start + marker.length(), open_paren - start - marker.length()).strip_edges()
