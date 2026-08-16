class_name TestSimulationBalance
extends GdUnitTestSuite

## Gate B0 for the simulation half of the balance bundle.
##
## `BALANCE_SPEC.md` §4: "Every production tuning constant belongs to a named
## balance profile. Anonymous numeric literals are prohibited inside resolution
## code." `GODOT_TDD.md` §5.6 fails Gate 0 for any tunable without a name, unit,
## safe range, and version.


func test_every_simulation_tunable_is_named_and_inside_its_safe_range() -> void:
	var profile := SimulationBalanceProfile.new()
	var failures: PackedStringArray = profile.validate()
	assert_array(failures).override_failure_message(", ".join(failures)).is_empty()

	var tunables: Array[BalanceTunable] = profile.describe_tunables()
	assert_int(tunables.size()).is_greater(50)
	for tunable in tunables:
		assert_str(String(tunable.tunable_name)).is_not_empty()
		assert_str(String(tunable.unit)).is_not_empty()
		assert_bool(tunable.is_inside_safe_range()).override_failure_message(
			tunable.describe()).is_true()


func test_the_profile_carries_an_identity_and_version() -> void:
	var profile := SimulationBalanceProfile.new()
	assert_str(String(profile.profile_id)).is_not_empty()
	assert_str(String(profile.version)).is_not_empty()


## §13.1 baselines rise monotonically with the relevant rating, in every family.
func test_shot_baselines_are_monotonic_in_the_rating() -> void:
	var profile := SimulationBalanceProfile.new()
	for zone in ShotZone.all():
		var previous: float = -1.0
		for capability: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var value: float = profile.shot_baseline(zone, capability, false)
			assert_float(value).override_failure_message(
				"zone %s is not monotonic in capability" % ShotZone.id_of(zone)
			).is_greater(previous)
			previous = value
	var previous_free_throw: float = -1.0
	for capability: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var value: float = profile.free_throw_baseline(capability)
		assert_float(value).is_greater(previous_free_throw)
		previous_free_throw = value


## §13.2 floors and ceilings bound every family, and a dunk is easier than the
## same-rated non-dunk attempt it replaces.
func test_shot_floors_and_ceilings_bound_every_family() -> void:
	var profile := SimulationBalanceProfile.new()
	for zone in ShotZone.all():
		assert_float(profile.shot_floor(zone, false)).is_less(profile.shot_ceiling(zone, false))
	assert_float(profile.shot_baseline(ShotZone.Value.RESTRICTED_RIM, 0.5, true)).is_greater(
		profile.shot_baseline(ShotZone.Value.RESTRICTED_RIM, 0.5, false))
	# A deep three is harder than a standard one at the same capability.
	assert_float(profile.shot_baseline(ShotZone.Value.DEEP_THREE, 0.5, false)).is_less(
		profile.shot_baseline(ShotZone.Value.STANDARD_THREE, 0.5, false))


## §14.3: an ordinary ten-point capability edge changes a qualifying event's
## probability by roughly 15-25% relative, and a twenty-five-point edge by
## 40-70%, without leaving the event's own bounds.
func test_opposed_curves_respond_within_the_required_band() -> void:
	var profile := SimulationBalanceProfile.new()
	var base: float = profile.advantage_base
	var one_unit: float = profile.opposed_probability(
		base, 1.0, profile.advantage_floor, profile.advantage_ceiling)
	var relative: float = one_unit / base - 1.0
	assert_float(relative).is_between(0.15, 0.25)

	var big_edge: float = profile.opposed_probability(
		base, 2.5, profile.advantage_floor, profile.advantage_ceiling)
	var big_relative: float = big_edge / base - 1.0
	assert_float(big_relative).is_between(0.40, 0.70)

	# The bounds hold at the extremes.
	assert_float(profile.opposed_probability(
		base, 50.0, profile.advantage_floor, profile.advantage_ceiling)
	).is_equal_approx(profile.advantage_ceiling, 0.000001)
	assert_float(profile.opposed_probability(
		base, -50.0, profile.advantage_floor, profile.advantage_ceiling)
	).is_equal_approx(profile.advantage_floor, 0.000001)


## §12.1: the five-position mapping is centred, and the opposing pole is the
## reciprocal.
func test_tendency_multipliers_are_centred_and_reciprocal() -> void:
	var profile := SimulationBalanceProfile.new()
	assert_float(profile.tendency_multiplier(TendencySlider.NEUTRAL_POSITION)).is_equal(1.0)
	for position in range(PlayerTendencies.MINIMUM, PlayerTendencies.MAXIMUM + 1):
		assert_float(
			profile.tendency_multiplier(position) * profile.opposing_tendency_multiplier(position)
		).is_equal_approx(1.0, 0.000001)
	assert_float(profile.tendency_multiplier(5)).is_greater(profile.tendency_multiplier(1))


## §12.2: a valid candidate weight is clamped to 0.15-3.50 times its family
## base, and only invalidity can reach zero.
func test_candidate_weights_are_clamped_to_their_band() -> void:
	var profile := SimulationBalanceProfile.new()
	var base: float = profile.action_base_weight(ActionFamily.Value.DRIVE)
	assert_float(profile.clamp_candidate_weight(0.0, base)).is_equal_approx(
		profile.candidate_weight_min * base, 0.000001)
	assert_float(profile.clamp_candidate_weight(1000.0, base)).is_equal_approx(
		profile.candidate_weight_max * base, 0.000001)
	for family in ActionFamily.all():
		assert_float(profile.action_base_weight(family)).is_greater(0.0)


## §5.2 and §12.4: the capability table is complete, sums to one, and no
## capability reads an identity layer.
func test_capability_weight_table_is_complete_and_bounded() -> void:
	var profile := RatingsProfile.default_profile()
	for capability in CapabilityKey.all():
		var weights: CapabilityWeightSet = profile.capability_weights(capability)
		assert_int(weights.capability).is_equal(capability)
		var total: float = weights.contextual_share
		for share in weights.attribute_shares:
			assert_float(share).is_greater(0.0)
			total += share
		assert_float(total).override_failure_message(
			"capability %s weights do not sum to 1.0" % CapabilityKey.id_of(capability)
		).is_equal_approx(1.0, 0.000001)
		assert_bool(weights.attribute_keys.has(weights.primary_attribute)).is_true()
		assert_float(weights.fatigue_sensitivity).is_between(0.0, 1.0)


## §12.4: role opportunity is tactical role's whole numeric privilege, and it
## stays inside the §12.2 bounds for every pair.
func test_role_opportunity_stays_inside_its_bounds() -> void:
	var table := RoleOpportunityTable.new()
	assert_array(table.validate()).is_empty()
	var neutral_pairs: int = 0
	for role in TacticalRole.all():
		for family in ActionFamily.all():
			if is_equal_approx(table.opportunity(role, family), RoleOpportunityTable.NEUTRAL):
				neutral_pairs += 1
	# The table is sparse by design: most pairs are neutral and only the §10.6.2
	# opportunity vectors are emphasised.
	assert_int(neutral_pairs).is_greater(0)
	assert_int(neutral_pairs).is_less(TacticalRole.COUNT * ActionFamily.COUNT)


## The rule profiles model real bonus structures without naming a league.
func test_rule_profiles_model_their_bonus_structures() -> void:
	var school := CompetitionRuleProfile.school_profile()
	assert_int(school.bonus_free_throws_for(school.team_foul_bonus_threshold - 1)).is_equal(0)
	assert_bool(school.is_one_and_one(school.team_foul_bonus_threshold)).is_true()
	assert_bool(school.is_one_and_one(school.team_foul_double_bonus_threshold)).is_false()
	assert_int(school.bonus_free_throws_for(school.team_foul_double_bonus_threshold)).is_equal(2)

	var professional := CompetitionRuleProfile.professional_profile()
	assert_bool(professional.is_one_and_one(professional.team_foul_bonus_threshold)).is_false()
	assert_int(
		professional.bonus_free_throws_for(professional.team_foul_bonus_threshold)).is_equal(2)
	# Overtime periods use their own length.
	assert_int(professional.period_length_ms(1)).is_equal(professional.period_seconds * 1000)
	assert_int(
		professional.period_length_ms(professional.regulation_periods + 1)
	).is_equal(professional.overtime_seconds * 1000)
