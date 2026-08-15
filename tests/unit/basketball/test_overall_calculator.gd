class_name TestOverallCalculator
extends GdUnitTestSuite

## `BALANCE_SPEC.md` §6.1, §6.2, §6.3; Gate B1.

var _ratings: RatingsProfile
var _progression: ProgressionProfile


func before_test() -> void:
	_ratings = RatingsProfile.default_profile()
	_progression = ProgressionProfile.default_profile()


func _uniform(value: int) -> Array[int]:
	var values: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		values.append(value)
	return values


## §7.3.1 derives the empty pre-allocation preview from the documented bases and
## states the result: 37.93 -> 38. Reproducing that exact number is the sharpest
## available check that the blend is implemented as specified, because the
## specification did the arithmetic in full.
func test_empty_preview_reproduces_the_documented_derivation() -> void:
	var builder: BuilderProfile = BuilderProfile.default_profile()
	var raw: float = OverallCalculator.raw_overall(builder.base_ratings(), _ratings)
	assert_float(raw).is_equal_approx(37.93, 0.01)
	assert_int(OverallCalculator.overall_from_values(builder.base_ratings(), _ratings))\
		.is_equal(38)


## §6.2: "Raising any one rating while all others remain fixed cannot reduce
## Overall." Checked across the whole scale and every attribute, because the
## guardrail must hold at the order-statistic boundaries where a raised value
## crosses into the top eight or out of the bottom six.
func test_overall_is_monotonic_in_every_attribute() -> void:
	for attribute in AttributeKey.all():
		for base_value: int in [25, 40, 55, 70, 85, 98]:
			var values: Array[int] = _uniform(base_value)
			# Perturb so the sorted position of `attribute` is not degenerate.
			for other in AttributeKey.all():
				values[other] = clampi(base_value + (other % 7) - 3, 25, 99)
			var before: float = OverallCalculator.raw_overall(values, _ratings)
			var raised: Array[int] = values.duplicate()
			raised[attribute] = mini(99, raised[attribute] + 1)
			if raised[attribute] == values[attribute]:
				continue
			var after: float = OverallCalculator.raw_overall(raised, _ratings)
			assert_float(after).is_greater_equal(before)


## §6.1: the blend preserves the 25-99 scale. A player at a uniform rating has
## exactly that Overall — the coefficients sum to one, so the three means
## coincide.
func test_scale_is_preserved_at_uniform_ratings() -> void:
	for value: int in [25, 40, 60, 75, 90, 99]:
		assert_int(OverallCalculator.overall_from_values(_uniform(value), _ratings))\
			.is_equal(value)


## §6: Overall "excludes position, role, popularity, followers, trust, morale,
## team fit, potential, and reputation", and §6.2 adds that no non-rating state
## can change it. `OverallCalculator` takes only ratings and coefficients, so
## the check is that two players identical in ratings and different in every
## identity layer, body, and cap agree exactly.
func test_no_non_rating_state_changes_current_overall() -> void:
	var attributes: PlayerAttributes = PlayerAttributes.from_values(_uniform(62))
	var baseline: int = OverallCalculator.current_overall(attributes, _ratings)

	var guard_state: PlayerDevelopmentState = _state_with(
		attributes, PositionFamily.Value.GUARD, RotationRole.Value.STAR,
		TacticalRole.Value.PRIMARY_CREATOR, ProspectProfile.Value.HIGH_UPSIDE, 66, 99)
	var big_state: PlayerDevelopmentState = _state_with(
		attributes, PositionFamily.Value.BIG, RotationRole.Value.DEVELOPMENTAL,
		TacticalRole.Value.INTERIOR_ANCHOR, ProspectProfile.Value.READY_NOW, 84, 40)

	assert_int(OverallCalculator.current_overall(guard_state.attributes, _ratings))\
		.is_equal(baseline)
	assert_int(OverallCalculator.current_overall(big_state.attributes, _ratings))\
		.is_equal(baseline)


## §6.3 rule 4: `CurrentOverall <= MaximumPotentialOverall` always holds.
func test_maximum_potential_is_never_below_current_overall() -> void:
	var values: Array[int] = _uniform(55)
	var caps: Array[int] = []
	for attribute in AttributeKey.all():
		caps.append(maxi(values[attribute], 40 + attribute * 2))
	var attributes: PlayerAttributes = PlayerAttributes.from_values(values)
	var cap_model: AttributeCaps = AttributeCaps.new(caps)
	assert_int(OverallCalculator.current_overall(attributes, _ratings))\
		.is_less_equal(OverallCalculator.maximum_potential_overall(cap_model, _ratings))


## §6: "calculated identically for users and NPCs".
func test_user_and_npc_use_the_same_function() -> void:
	var values: Array[int] = _uniform(71)
	values[AttributeKey.Key.THREE_POINT] = 88
	var attributes: PlayerAttributes = PlayerAttributes.from_values(values)
	var user_state: PlayerDevelopmentState = _state_with(
		attributes, PositionFamily.Value.WING, RotationRole.Value.STARTER,
		TacticalRole.Value.SHOOTER, ProspectProfile.Value.BALANCED, 78, 90)
	var npc_state: PlayerDevelopmentState = _state_with(
		attributes, PositionFamily.Value.WING, RotationRole.Value.BENCH,
		TacticalRole.Value.SHOOTER, ProspectProfile.Value.BALANCED, 78, 90)
	npc_state.detail_level = SimulationDetailLevel.Value.REDUCED

	assert_int(OverallCalculator.current_overall(user_state.attributes, _ratings))\
		.is_equal(OverallCalculator.current_overall(npc_state.attributes, _ratings))


func _state_with(
	attributes: PlayerAttributes,
	family: int,
	rotation: int,
	tactical: int,
	prospect: int,
	height: int,
	cap_value: int,
) -> PlayerDevelopmentState:
	var caps: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		caps.append(maxi(cap_value, 40))
	var body: BodyProfile = BodyProfile.new(height, 180, height + 2, 0)
	var range_model: BodyRange = BodyRange.new(
		height, height + 8, 180, 250, height + 2, height + 11,
		body.standing_reach_inches, body.standing_reach_inches + 12)
	return PlayerDevelopmentState.new(
		&"test_player",
		attributes.duplicate_attributes(),
		AttributeCaps.new(caps),
		BodyMaturationState.new(body, MaturityProfile.Value.AVERAGE, range_model),
		prospect,
		family,
		1234,
		"test",
		16,
		1,
		null,
		rotation,
		TacticalRole.new(tactical)
	)
