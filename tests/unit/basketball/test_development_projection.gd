class_name TestDevelopmentProjection
extends GdUnitTestSuite

## Projection suite (`GODOT_TDD.md` §13.2, `BALANCE_SPEC.md` §6.3, Gate B1/B3).

var _ratings: RatingsProfile
var _progression: ProgressionProfile


func before_test() -> void:
	_ratings = RatingsProfile.default_profile()
	_progression = ProgressionProfile.default_profile()


func _player(rating: int, cap: int) -> Array:
	var values: Array[int] = []
	var caps: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		values.append(rating)
		caps.append(cap)
	return [PlayerAttributes.from_values(values), AttributeCaps.new(caps)]


func _project(
	rating: int,
	cap: int,
	prospect: int,
	age: int,
	opportunity_scale: float = 1.0,
) -> DevelopmentProjection:
	var pair: Array = _player(rating, cap)
	return DevelopmentProjection.of_player(
		pair[0] as PlayerAttributes, pair[1] as AttributeCaps,
		prospect, age, _ratings, _progression, opportunity_scale)


## §6.3: the three values are distinct in type and each carries its own label.
func test_the_three_values_have_distinct_labels() -> void:
	assert_str(DevelopmentProjection.CURRENT_OVERALL_LABEL).is_equal("Current Overall")
	assert_str(DevelopmentProjection.MAXIMUM_POTENTIAL_LABEL).is_equal("Maximum Potential")
	assert_str(DevelopmentProjection.PROJECTED_PEAK_LABEL).is_equal("Projected Peak")
	assert_bool(
		DevelopmentProjection.CURRENT_OVERALL_LABEL
		== DevelopmentProjection.MAXIMUM_POTENTIAL_LABEL
	).is_false()


## §6.3 rule 2 and §28: Projected Peak is always a range and never a single
## number. The type carries a low and a high, and the display form shows both.
func test_projected_peak_is_always_a_range() -> void:
	var projection: DevelopmentProjection = _project(
		45, 85, ProspectProfile.Value.BALANCED, 16)
	assert_bool(projection.projected_peak is OverallRange).is_true()
	assert_str(projection.projected_peak.to_display_string()).contains("-")
	assert_int(projection.projected_peak.low)\
		.is_less_equal(projection.projected_peak.high)


## §6.3 rule 4: the range lies at or below Maximum Potential and at or above
## Current Overall.
func test_projected_peak_respects_its_ordering_bounds() -> void:
	for rating: int in [30, 45, 60, 75]:
		for cap: int in [50, 70, 90, 99]:
			if cap < rating:
				continue
			for prospect in ProspectProfile.all():
				for age: int in [14, 18, 22, 26, 31, 36]:
					var projection: DevelopmentProjection = _project(
						rating, cap, prospect, age)
					assert_int(projection.projected_peak.high)\
						.is_less_equal(projection.maximum_potential)
					assert_int(projection.projected_peak.low)\
						.is_greater_equal(projection.current_overall)


## §6.3 rule 2: available development opportunity is an input. More opportunity
## cannot lower the projection.
func test_projected_peak_responds_to_opportunity_supply() -> void:
	var lean: DevelopmentProjection = _project(
		45, 90, ProspectProfile.Value.BALANCED, 16, 0.25)
	var rich: DevelopmentProjection = _project(
		45, 90, ProspectProfile.Value.BALANCED, 16, 2.0)
	assert_int(rich.projected_peak.high).is_greater_equal(lean.projected_peak.high)


## §6.3 rule 2: current age and the aging curves are inputs. A player with the
## same ratings and caps but less career left cannot project higher.
func test_projected_peak_falls_with_age() -> void:
	var young: DevelopmentProjection = _project(
		50, 90, ProspectProfile.Value.BALANCED, 16)
	var older: DevelopmentProjection = _project(
		50, 90, ProspectProfile.Value.BALANCED, 30)
	assert_int(older.projected_peak.high).is_less_equal(young.projected_peak.high)


## §6.3 rule 2: exact per-attribute caps are an input.
func test_projected_peak_responds_to_caps() -> void:
	# The low cap must actually bind. A cap of 60 does not: an ordinary career
	# supplies less opportunity than it takes to fill twenty attributes to 60
	# from 45, so both projections would land in the same place for reasons that
	# have nothing to do with the cap.
	var low_cap: DevelopmentProjection = _project(
		45, 50, ProspectProfile.Value.BALANCED, 16)
	var high_cap: DevelopmentProjection = _project(
		45, 95, ProspectProfile.Value.BALANCED, 16)

	assert_int(high_cap.projected_peak.high).is_greater(low_cap.projected_peak.high)
	assert_int(low_cap.projected_peak.high).is_less_equal(low_cap.maximum_potential)
	# A binding cap makes Maximum Potential itself the ceiling.
	assert_int(low_cap.maximum_potential).is_equal(50)


## §6.3 rule 2: the prospect timing profile is an input. High Upside carries
## more late growth availability than Ready Now (§7.2), so from the same
## freshman state it must not project lower.
func test_projected_peak_responds_to_timing_profile() -> void:
	var ready_now: DevelopmentProjection = _project(
		45, 95, ProspectProfile.Value.READY_NOW, 15)
	var high_upside: DevelopmentProjection = _project(
		45, 95, ProspectProfile.Value.HIGH_UPSIDE, 15)
	assert_int(high_upside.projected_peak.high).is_greater_equal(ready_now.projected_peak.high)


## §6.3 rule 3: recomputed from current inputs, not stored as a promise. The
## same inputs must always give the same answer — the model consults no
## `RandomSource`.
func test_projection_is_deterministic() -> void:
	for _attempt in range(5):
		var projection: DevelopmentProjection = _project(
			48, 88, ProspectProfile.Value.HIGH_UPSIDE, 17)
		assert_str(projection.signature()).is_equal(
			_project(48, 88, ProspectProfile.Value.HIGH_UPSIDE, 17).signature())


## §6.3: the range must not be so wide that it is uninformative. The guardrail
## yields only when the legal interval is itself narrower than the minimum.
func test_projected_peak_width_stays_inside_its_guardrail() -> void:
	var projection: DevelopmentProjection = _project(
		45, 90, ProspectProfile.Value.BALANCED, 16)
	assert_int(projection.projected_peak.width())\
		.is_less_equal(_progression.projected_peak_maximum_width)


## A player whose caps are already filled has no room, and the honest projection
## is the degenerate interval rather than an invented spread.
func test_a_filled_player_projects_no_further_growth() -> void:
	var projection: DevelopmentProjection = _project(
		80, 80, ProspectProfile.Value.BALANCED, 27)
	assert_int(projection.current_overall).is_equal(projection.maximum_potential)
	assert_int(projection.projected_peak.low).is_equal(projection.current_overall)
	assert_int(projection.projected_peak.high).is_equal(projection.maximum_potential)
