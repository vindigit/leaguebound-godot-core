extends GdUnitTestSuite


func test_wilson_endpoints_survive_serialization() -> void:
	for successes: int in [0, 1, 20, 39, 40]:
		var metric := CalibrationMetric.raw(&"test.rate", "successes per trial", "trials", 0.0)
		metric.with_aggregation(MetricAggregation.proportion(successes, 40))
		var expected := CalibrationStatistics.wilson_interval(successes, 40)
		var interval: Dictionary = metric.to_dictionary()["interval_95"]
		assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(expected[0], 0.000000001)
		assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(expected[1], 0.000000001)
		var restored := CalibrationMetric.from_dictionary(metric.to_dictionary())
		var restored_interval: Dictionary = restored.to_dictionary()["interval_95"]
		assert_float(JsonRead.float_at(restored_interval, "low")).is_equal_approx(expected[0], 0.000000001)
		assert_float(JsonRead.float_at(restored_interval, "high")).is_equal_approx(expected[1], 0.000000001)


func test_explicit_interval_override_stays_centered_on_estimate() -> void:
	var metric := CalibrationMetric.raw(&"test.fg", "makes per attempt", "attempts", 0.0)
	metric.with_aggregation(MetricAggregation.proportion(1, 40)).with_interval(0.12)
	var interval: Dictionary = metric.to_dictionary()["interval_95"]
	assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(-0.095, 0.000000001)
	assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(0.145, 0.000000001)
	var restored := CalibrationMetric.from_dictionary(metric.to_dictionary())
	assert_float(JsonRead.float_at(JsonRead.dictionary_at(restored.to_dictionary(), "interval_95"), "low")).is_equal_approx(-0.095, 0.000000001)


func test_archived_values_round_trip_without_reinterpretation() -> void:
	var archived := CalibrationMetric.raw(&"test.old", "historic", "games", 0.025).to_dictionary()
	archived["interval_95"] = {"half_width": 0.06, "low": -0.035, "high": 0.085}
	var restored := CalibrationMetric.from_dictionary(archived)
	var interval: Dictionary = restored.to_dictionary()["interval_95"]
	assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(-0.035, 0.000000001)
	assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(0.085, 0.000000001)


func test_known_wilson_endpoints_survive_json_and_console_rendering() -> void:
	var metric := CalibrationMetric.raw(&"known", "known", "trials", 0.0)
	metric.with_aggregation(MetricAggregation.proportion(0, 40))
	var payload: Dictionary = JSON.parse_string(JSON.stringify(metric.to_dictionary()))
	var round_trip := CalibrationMetric.from_dictionary(payload)
	var interval := JsonRead.dictionary_at(round_trip.to_dictionary(), "interval_95")
	assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(0.0, 0.000000001)
	assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(0.08762160245846368, 0.000000001)
	assert_str(round_trip.describe()).contains("[0.0000, 0.0876]")


func test_replacing_aggregation_clears_unavailable_interval() -> void:
	var metric := CalibrationMetric.raw(&"reuse", "reuse", "trials", 0.0)
	metric.with_aggregation(MetricAggregation.proportion(1, 40))
	metric.with_aggregation(MetricAggregation.ratio(10, 20))
	assert_bool(metric.to_dictionary().has("interval_95")).is_false()
	for values: PackedFloat64Array in [PackedFloat64Array(), PackedFloat64Array([7.0])]:
		metric.with_interval(0.0).with_aggregation(MetricAggregation.mean_of(values))
		assert_bool(metric.to_dictionary().has("interval_95")).is_false()
	metric.with_aggregation(MetricAggregation.mean_of(PackedFloat64Array([7.0, 9.0])))
	assert_float(metric.interval_half_width).is_equal_approx(1.959964, 0.000000001)
	metric.with_aggregation(MetricAggregation.proportion(1, 40))
	metric.with_aggregation(MetricAggregation.proportion(0, 0))
	assert_bool(metric.to_dictionary().has("interval_95")).is_false()


func test_legacy_width_only_payload_and_banded_verdict_are_preserved() -> void:
	var metric := CalibrationMetric.banded(&"test.band", "band", "games", 0.0,
		CalibrationBand.new(0.04, 0.08, "test contract"), 40)
	metric.with_aggregation(MetricAggregation.proportion(1, 40))
	assert_float(metric.estimate).is_equal_approx(0.025, 0.000000001)
	assert_bool(metric.failed()).is_true()
	var legacy := metric.to_dictionary()
	legacy["interval_95"] = {"half_width": 0.06}
	var restored := CalibrationMetric.from_dictionary(legacy)
	var interval := JsonRead.dictionary_at(restored.to_dictionary(), "interval_95")
	assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(-0.035, 0.000000001)
	assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(0.085, 0.000000001)
	assert_bool(restored.failed()).is_true()


func test_one_trial_has_a_bounded_interval() -> void:
	var metric := CalibrationMetric.raw(&"one", "one", "trials", 0.0)
	metric.with_aggregation(MetricAggregation.proportion(0, 1))
	var interval := JsonRead.dictionary_at(metric.to_dictionary(), "interval_95")
	assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(0.0, 0.000000001)
	assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(0.7934506882081973, 0.000000001)


func test_explicit_bounds_keep_banded_estimate_and_verdict() -> void:
	var metric := CalibrationMetric.banded(&"share", "share", "games", 0.025,
		CalibrationBand.new(0.04, 0.08, "test contract"), 40)
	metric.with_interval_bounds(0.004426831453704344, 0.12881369088183614)
	var interval := JsonRead.dictionary_at(metric.to_dictionary(), "interval_95")
	assert_float(JsonRead.float_at(interval, "low")).is_equal_approx(0.004426831453704344, 0.000000001)
	assert_float(JsonRead.float_at(interval, "high")).is_equal_approx(0.12881369088183614, 0.000000001)
	assert_float(metric.estimate).is_equal_approx(0.025, 0.000000001)
	assert_bool(metric.failed()).is_true()
