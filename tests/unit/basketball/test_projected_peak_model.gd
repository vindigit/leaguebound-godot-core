class_name TestProjectedPeakModel
extends GdUnitTestSuite

## Projected Peak conditional-interval model (`BALANCE_SPEC.md` §6.3, §28,
## Gate B1/B3).
##
## The suite that existed before this one pinned the *contract* — three distinct
## values, a range and never a number, the §6.3 rule 4 ordering. It could not
## distinguish a correct model from the globally uniform one that failed
## calibration at 28% coverage, because a uniform interval satisfies every
## contract rule while being the wrong shape.
##
## These cases pin the *shape*. Each is written so that collapsing the
## conditional interval back to a global constant, deleting cap enforcement, or
## letting a realized career fact reach the model makes it fail.

var _ratings: RatingsProfile
var _progression: ProgressionProfile


func before_test() -> void:
	_ratings = RatingsProfile.default_profile()
	_progression = ProgressionProfile.default_profile()


func _uniform(rating: int, cap: int) -> Array:
	var values: Array[int] = []
	var caps: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		values.append(rating)
		caps.append(cap)
	return [PlayerAttributes.from_values(values), AttributeCaps.new(caps)]


func _range_for(
	rating: int,
	cap: int,
	prospect: int,
	age: int = BuilderService.FRESHMAN_AGE,
	progression: ProgressionProfile = null,
) -> OverallRange:
	var pair: Array = _uniform(rating, cap)
	return ProjectedPeakCalculator.project(
		pair[0] as PlayerAttributes, pair[1] as AttributeCaps, prospect, age,
		_ratings, progression if progression != null else _progression)


## A profile whose opportunity interval is one global constant across every
## prospect profile — the model this replaced. Used for mutation evidence.
func _globally_uniform_profile() -> ProgressionProfile:
	var mutated := ProgressionProfile.new(&"progression-mutation-uniform")
	mutated.projected_peak_opportunity_low = [0.55, 0.55, 0.55]
	mutated.projected_peak_opportunity_high = [1.25, 1.25, 1.25]
	mutated.projected_peak_horizon_age = [29, 29, 29]
	return mutated


# --- determinism and legality ------------------------------------------------

## §6.3 rule 3: recomputed from current inputs and never stored as a promise.
## The model consults no `RandomSource`, so repetition is exact.
func test_interval_generation_is_deterministic() -> void:
	for prospect in ProspectProfile.all():
		var first: OverallRange = _range_for(47, 90, prospect)
		for _attempt in range(4):
			var repeat: OverallRange = _range_for(47, 90, prospect)
			assert_int(repeat.low).is_equal(first.low)
			assert_int(repeat.high).is_equal(first.high)


## §6.3 rule 4 ordering holds across the whole legal domain, including the
## extreme but legal corners: a floor player, an apex player, a player whose
## caps equal his ratings, and a player past every decline band.
func test_bounds_and_ordering_hold_at_extremes() -> void:
	for rating: int in [25, 45, 70, 99]:
		for cap: int in [40, 60, 90, 99]:
			if cap < rating:
				continue
			for prospect in ProspectProfile.all():
				for age: int in [14, 18, 25, 30, 38, 44]:
					var pair: Array = _uniform(rating, cap)
					var attributes: PlayerAttributes = pair[0]
					var caps: AttributeCaps = pair[1]
					var projected: OverallRange = ProjectedPeakCalculator.project(
						attributes, caps, prospect, age, _ratings, _progression)
					var current: int = OverallCalculator.current_overall(attributes, _ratings)
					var maximum: int = OverallCalculator.maximum_potential_overall(
						caps, _ratings)
					assert_int(projected.low).is_less_equal(projected.high)
					assert_int(projected.low).is_greater_equal(current)
					assert_int(projected.high).is_less_equal(maximum)


## §28: no realized career fact may reach the model. Identity, career seed, and
## career year are not inputs, so two players differing only in those must
## project identically. A leak of any later-career state would show up here as a
## difference the model has no legal way to produce.
func test_projection_ignores_identity_and_career_state() -> void:
	var pair: Array = _uniform(47, 88)
	var attributes: PlayerAttributes = pair[0]
	var caps: AttributeCaps = pair[1]
	var direct: OverallRange = ProjectedPeakCalculator.project(
		attributes, caps, ProspectProfile.Value.BALANCED,
		BuilderService.FRESHMAN_AGE, _ratings, _progression)

	var builder := BuilderService.new(BalanceProfileSet.default_set())
	var query := DevelopmentProjectionQuery.new(BalanceProfileSet.default_set())
	var signatures: Array[String] = []
	for seed_value: int in PackedInt32Array([11, 9999, 123456]):
		var state: PlayerDevelopmentState = PlayerDevelopmentState.new(
			StringName("player_%d" % seed_value),
			attributes.duplicate_attributes(),
			caps.duplicate_caps(),
			BodyMaturationState.new(
				builder.default_body_for_family(PositionFamily.Value.WING),
				MaturityProfile.Value.AVERAGE,
				BodyMaturationPlanner.project_adult_range(
					builder.default_body_for_family(PositionFamily.Value.WING),
					BalanceProfileSet.default_set().builder)),
			ProspectProfile.Value.BALANCED,
			PositionFamily.Value.WING,
			seed_value,
			"balance-mutation-test",
			BuilderService.FRESHMAN_AGE)
		signatures.append(query.projection_for(state).projected_peak.signature())
	for signature in signatures:
		assert_str(signature).is_equal(direct.signature())


# --- the conditioning itself -------------------------------------------------

## The central claim. Two prospects with identical ratings, identical caps and
## identical age must receive *different* interval widths, because §7.2 makes
## the prospect profile the determinant of how much opportunity a career
## generates and a High Upside career has genuine access to outcomes a Ready Now
## career does not.
##
## Collapsing the per-profile opportunity interval to a global constant makes
## this fail, which is the mutation evidence for the conditioning.
func test_risk_profile_changes_the_interval_width() -> void:
	var ready_now: OverallRange = _range_for(46, 97, ProspectProfile.Value.READY_NOW)
	var high_upside: OverallRange = _range_for(46, 97, ProspectProfile.Value.HIGH_UPSIDE)
	assert_int(high_upside.width()).is_greater(ready_now.width())

	# Mutation evidence. Collapsing the per-profile opportunity interval to one
	# global constant must measurably reduce the width separation between the
	# profiles. It cannot remove it entirely — §7.2 growth availability still
	# differs by profile and legitimately moves expected opportunity — so the
	# assertion is on the separation the *conditioning* adds, which is the thing
	# the mutation deletes.
	var uniform: ProgressionProfile = _globally_uniform_profile()
	var flat_ready: OverallRange = _range_for(
		46, 97, ProspectProfile.Value.READY_NOW, BuilderService.FRESHMAN_AGE, uniform)
	var flat_upside: OverallRange = _range_for(
		46, 97, ProspectProfile.Value.HIGH_UPSIDE, BuilderService.FRESHMAN_AGE, uniform)
	assert_int(high_upside.width() - ready_now.width())\
		.is_greater(flat_upside.width() - flat_ready.width())


## A wider opportunity interval is more uncertainty, and more uncertainty may
## never produce a narrower displayed range. §6.3 permits a narrow range only
## when the evidence supports it; narrowing as uncertainty grows would be the
## precise form of dishonesty the section exists to forbid.
func test_more_uncertainty_never_narrows_the_interval() -> void:
	var confident := ProgressionProfile.new(&"progression-confident")
	confident.projected_peak_opportunity_low = [0.80, 0.80, 0.80]
	confident.projected_peak_opportunity_high = [1.05, 1.05, 1.05]
	var uncertain := ProgressionProfile.new(&"progression-uncertain")
	uncertain.projected_peak_opportunity_low = [0.50, 0.50, 0.50]
	uncertain.projected_peak_opportunity_high = [1.70, 1.70, 1.70]

	for prospect in ProspectProfile.all():
		var narrow: OverallRange = _range_for(
			46, 97, prospect, BuilderService.FRESHMAN_AGE, confident)
		var wide: OverallRange = _range_for(
			46, 97, prospect, BuilderService.FRESHMAN_AGE, uncertain)
		assert_int(wide.width()).is_greater_equal(narrow.width())


## The second half of the conditioning, and it needs no parameter: a career
## whose caps bind gets a narrow range because more opportunity could not have
## helped it. Removing cap enforcement from the conversion makes this fail.
func test_binding_caps_narrow_the_interval_without_a_rule() -> void:
	var open_ended: OverallRange = _range_for(46, 97, ProspectProfile.Value.HIGH_UPSIDE)
	var cap_bound: OverallRange = _range_for(46, 52, ProspectProfile.Value.HIGH_UPSIDE)
	assert_int(cap_bound.width()).is_less(open_ended.width())


## §9.1 costs and the exact caps bound reachable growth. A projection may never
## promise Overall the player's own caps cannot deliver, whatever opportunity is
## assumed — this is what stops the forecast becoming a wish.
func test_reachable_growth_respects_caps_under_any_opportunity() -> void:
	var extravagant := ProgressionProfile.new(&"progression-extravagant")
	extravagant.projected_peak_opportunity_low = [2.5, 2.5, 2.5]
	extravagant.projected_peak_opportunity_high = [3.0, 3.0, 3.0]
	for cap: int in [45, 60, 75, 90]:
		var pair: Array = _uniform(40, cap)
		var maximum: int = OverallCalculator.maximum_potential_overall(
			pair[1] as AttributeCaps, _ratings)
		var projected: OverallRange = ProjectedPeakCalculator.project(
			pair[0] as PlayerAttributes, pair[1] as AttributeCaps,
			ProspectProfile.Value.BALANCED, BuilderService.FRESHMAN_AGE,
			_ratings, extravagant)
		assert_int(projected.high).is_less_equal(maximum)


## The opportunity shares must actually be consumed. A model that ignored them
## would keep every contract test green while being uncalibratable.
func test_opportunity_shares_move_the_projection() -> void:
	var lean := ProgressionProfile.new(&"progression-lean")
	lean.projected_peak_opportunity_low = [0.30, 0.30, 0.30]
	lean.projected_peak_opportunity_high = [0.45, 0.45, 0.45]
	var rich := ProgressionProfile.new(&"progression-rich")
	rich.projected_peak_opportunity_low = [1.30, 1.30, 1.30]
	rich.projected_peak_opportunity_high = [1.80, 1.80, 1.80]

	var poor_range: OverallRange = _range_for(
		46, 95, ProspectProfile.Value.BALANCED, BuilderService.FRESHMAN_AGE, lean)
	var rich_range: OverallRange = _range_for(
		46, 95, ProspectProfile.Value.BALANCED, BuilderService.FRESHMAN_AGE, rich)
	assert_int(rich_range.high).is_greater(poor_range.high)
	assert_int(rich_range.low).is_greater(poor_range.low)


## The forecast horizon is a real input: a longer horizon accrues more expected
## opportunity, and a career with fewer seasons left cannot project higher.
func test_horizon_and_age_reduce_expected_opportunity() -> void:
	var progression: ProgressionProfile = ProgressionProfile.default_profile()
	var freshman: float = ProjectedPeakCalculator.expected_horizon_ap(
		ProspectProfile.Value.BALANCED, BuilderService.FRESHMAN_AGE, progression)
	var veteran: float = ProjectedPeakCalculator.expected_horizon_ap(
		ProspectProfile.Value.BALANCED, 27, progression)
	assert_float(freshman).is_greater(veteran)
	assert_float(veteran).is_greater_equal(0.0)

	var past_horizon: float = ProjectedPeakCalculator.expected_horizon_ap(
		ProspectProfile.Value.BALANCED, 40, progression)
	assert_float(past_horizon).is_equal(0.0)


## Regression against the model this replaced.
##
## The previous model paired the §9.5 band *minimum* with the band *maximum* over
## a horizon ending at the expected peak age, then discounted both by a 0.62
## "ordinary opportunity share" and allocation efficiencies of 0.55 and 0.86.
## Measured, that credited a mean of 603 AP against 1,198 actually granted and
## produced a median signed error of +10.0 — the range bracketed only
## poorly-managed careers.
##
## The legacy arithmetic is reproduced here from the same profile fields so the
## comparison is exact rather than a remembered number. A revert to that shape,
## or any change that reintroduces its scale of pessimism, fails this.
func test_regression_against_the_previous_pessimistic_model() -> void:
	const LEGACY_OPPORTUNITY_SHARE: float = 0.62
	const LEGACY_EFFICIENCY_LOW: float = 0.55
	const LEGACY_EFFICIENCY_HIGH: float = 0.86
	const LEGACY_PEAK_AGE: PackedInt32Array = [25, 27, 28]

	for prospect in ProspectProfile.all():
		var legacy_low: float = 0.0
		var legacy_high: float = 0.0
		for season_age in range(BuilderService.FRESHMAN_AGE, LEGACY_PEAK_AGE[prospect]):
			var phase: int = CareerPhase.default_phase_for_age(season_age)
			var availability: float = _progression.growth_availability_for(
				prospect, CareerPhase.growth_phase_of(phase))
			legacy_low += float(_progression.seasonal_ap_minimum[phase]) * availability
			legacy_high += float(_progression.seasonal_ap_maximum[phase]) * availability
		legacy_low *= LEGACY_OPPORTUNITY_SHARE * LEGACY_EFFICIENCY_LOW
		legacy_high *= LEGACY_OPPORTUNITY_SHARE * LEGACY_EFFICIENCY_HIGH

		var current: PackedFloat64Array = ProjectedPeakCalculator.projected_opportunity_ap(
			prospect, BuilderService.FRESHMAN_AGE, _progression)
		var legacy_midpoint: float = (legacy_low + legacy_high) / 2.0
		var current_midpoint: float = (current[0] + current[1]) / 2.0

		# The correction is large by construction: the measured shortfall was
		# roughly a factor of two in credited opportunity.
		assert_float(current_midpoint).is_greater(legacy_midpoint * 1.5)


## §6.3 forbids a single-value Projected Peak. The minimum width holds wherever
## the legal interval is wide enough to express it.
func test_minimum_width_holds_where_the_legal_interval_permits_it() -> void:
	for prospect in ProspectProfile.all():
		var projected: OverallRange = _range_for(46, 95, prospect)
		assert_int(projected.width())\
			.is_greater_equal(_progression.projected_peak_minimum_width)
		assert_int(projected.width())\
			.is_less_equal(_progression.projected_peak_maximum_width)
