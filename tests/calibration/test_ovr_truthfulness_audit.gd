class_name TestOvrTruthfulnessAudit
extends GdUnitTestSuite


func _uniform(value: int) -> Array[int]:
	var values: Array[int] = []
	for _index in range(20): values.append(value)
	return values


func test_exact_formula_matches_independent_rational_oracle() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	assert_float(ratings.mean_weight).is_equal(0.65)
	assert_float(ratings.top_weight).is_equal(0.25)
	assert_float(ratings.bottom_weight).is_equal(0.10)
	assert_int(RatingsProfile.TOP_COUNT).is_equal(8)
	assert_int(RatingsProfile.BOTTOM_COUNT).is_equal(6)
	var source := SeededRandomSource.new(440011)
	for _case in range(500):
		var values: Array[int] = []
		for _key in range(20): values.append(source.range_int(25, 99))
		assert_float(OverallCalculator.raw_overall(values, ratings)).is_equal_approx(
			float(OvrTruthfulnessAudit.oracle_numerator(values)) / 2400.0, 0.000000001)
		assert_int(OverallCalculator.overall_from_values(values, ratings)).is_equal(
			OvrTruthfulnessAudit.oracle_display(values))


func test_ordering_crossings_and_ties_preserve_monotonicity_and_oracle() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var ordered: Array[int] = [25, 30, 35, 40, 45, 50, 50, 50, 50, 55, 60, 65, 65, 65, 70, 75, 80, 85, 90, 99]
	for key in range(20):
		var values: Array[int] = ordered.duplicate()
		var previous_raw: float = -1.0
		var previous_display: int = 24
		for value in range(25, 100):
			values[key] = value
			var raw: float = OverallCalculator.raw_overall(values, ratings)
			var display: int = OverallCalculator.overall_from_values(values, ratings)
			assert_float(raw).is_greater_equal(previous_raw)
			assert_int(display).is_greater_equal(previous_display)
			assert_int(display).is_equal(OvrTruthfulnessAudit.oracle_display(values))
			previous_raw = raw
			previous_display = display


func test_exact_half_rounding_neighbor_and_helper_clamping() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var boundary: Array[int] = [25, 25, 26, 28, 28, 30, 30, 34, 41, 41, 44, 48, 54, 69, 76, 82, 84, 89, 92, 94]
	assert_int(OvrTruthfulnessAudit.oracle_numerator(boundary)).is_equal(135600)
	assert_int(OverallCalculator.overall_from_values(boundary, ratings)).is_equal(57)
	boundary[10] = 43
	assert_int(OverallCalculator.overall_from_values(boundary, ratings)).is_equal(56)
	boundary[10] = 45
	assert_int(OverallCalculator.overall_from_values(boundary, ratings)).is_equal(57)
	# Synthetic helper inputs test the clamp. Such values are never put into an
	# active PlayerAttributes or a generated player.
	assert_int(OverallCalculator.overall_from_values(_uniform(0), ratings)).is_equal(25)
	assert_int(OverallCalculator.overall_from_values(_uniform(120), ratings)).is_equal(99)
	assert_int(OverallCalculator.overall_from_values(_uniform(25), ratings)).is_equal(25)
	assert_int(OverallCalculator.overall_from_values(_uniform(99), ratings)).is_equal(99)


func test_position_permutation_has_no_permanent_attribute_weight() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var values: Array[int] = [25, 35, 45, 55, 65, 75, 85, 95, 99, 42, 52, 62, 72, 82, 92, 32, 48, 58, 68, 78]
	var expected: int = OvrTruthfulnessAudit.oracle_display(values)
	for _shift in range(20):
		values.append(values.pop_front())
		assert_int(OverallCalculator.current_overall(PlayerAttributes.from_values(values), ratings)).is_equal(expected)


func test_exact_caps_use_same_formula_and_do_not_change_current() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var state: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(PositionFamily.Value.WING, 440020, &"caps")
	var current: int = OverallCalculator.current_overall(state.attributes, ratings)
	assert_int(OverallCalculator.maximum_potential_overall(state.caps, ratings)).is_equal(
		OvrTruthfulnessAudit.oracle_display(state.caps.values()))
	for key in AttributeKey.all():
		state.caps = state.caps.with_cap(key, 99)
	assert_int(OverallCalculator.maximum_potential_overall(state.caps, ratings)).is_equal(99)
	assert_int(OverallCalculator.current_overall(state.attributes, ratings)).is_equal(current)


func test_non_rating_fields_cannot_change_current_and_social_fields_have_no_ingress() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var state: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(PositionFamily.Value.GUARD, 440021, &"identity")
	var expected: int = OverallCalculator.current_overall(state.attributes, ratings)
	state.position_family = PositionFamily.Value.BIG
	state.rotation_role = RotationRole.Value.STAR
	state.tactical_role = TacticalRole.new(TacticalRole.Value.REBOUNDER)
	state.detail_level = SimulationDetailLevel.Value.REDUCED
	state.prospect = ProspectProfile.Value.READY_NOW
	state.age = 37
	state.tendencies = PlayerTendencies.new([5, 1, 5, 1, 5, 1, 5, 1, 5, 1])
	assert_int(OverallCalculator.current_overall(state.attributes, ratings)).is_equal(expected)
	var source: String = FileAccess.get_file_as_string("res://src/domain/basketball/ratings/overall_calculator.gd")
	var executable: String = ""
	for line in source.split("\n"):
		executable += line.split("#")[0] + "\n"
	for excluded: String in ["position", "role", "reputation", "popularity", "morale", "trust", "team_fit", "followers"]:
		assert_str(executable).not_contains(excluded)
	# Potential is present only in its separate canonical function; current's
	# declaration accepts PlayerAttributes and RatingsProfile, with no state.
	assert_str(executable).contains("current_overall(attributes: PlayerAttributes, profile: RatingsProfile)")


func test_user_npc_projection_uses_identical_current_for_same_ratings() -> void:
	var user: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(PositionFamily.Value.WING, 440022, &"user")
	var npc: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(PositionFamily.Value.WING, 440022, &"npc")
	npc.detail_level = SimulationDetailLevel.Value.REDUCED
	npc.rotation_role = RotationRole.Value.RESERVE
	var query := DevelopmentProjectionQuery.new()
	assert_int(query.projection_for(user).current_overall).is_equal(query.projection_for(npc).current_overall)
	assert_int(query.projection_for(user).maximum_potential).is_equal(query.projection_for(npc).maximum_potential)
	assert_str(user.attributes.signature()).is_equal(npc.attributes.signature())


func test_record_json_roundtrip_preserves_ratings_caps_and_rederived_values() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var state: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(PositionFamily.Value.BIG, 440023, &"record")
	var attributes: Dictionary = {}
	var caps: Dictionary = {}
	for key in AttributeKey.all():
		attributes[String(AttributeKey.name_of(key))] = state.attributes.get_rating(key)
		caps[String(AttributeKey.name_of(key))] = state.caps.cap_for(key)
	var parsed: Dictionary = JSON.parse_string(JSON.stringify({"schema_version": 2, "attributes": attributes, "caps": caps}))
	var migrated: Dictionary = PlayerSystemMigration.migrate_player_record(parsed).record
	var values: Array[int] = []
	var cap_values: Array[int] = []
	for key in AttributeKey.all():
		values.append(migrated["attributes"][String(AttributeKey.name_of(key))] as int)
		cap_values.append(migrated["caps"][String(AttributeKey.name_of(key))] as int)
	var restored: PlayerAttributes = PlayerAttributes.from_values(values)
	var restored_caps := AttributeCaps.new(cap_values)
	assert_str(restored.signature()).is_equal(state.attributes.signature())
	assert_str(restored_caps.signature()).is_equal(state.caps.signature())
	assert_int(OverallCalculator.current_overall(restored, ratings)).is_equal(
		OverallCalculator.current_overall(state.attributes, ratings))
	assert_int(OverallCalculator.maximum_potential_overall(restored_caps, ratings)).is_equal(
		OverallCalculator.maximum_potential_overall(state.caps, ratings))
	assert_bool(migrated.has("current_overall")).is_false()
	assert_bool(migrated.has("maximum_potential")).is_false()


func test_existing_display_consumer_labels_and_current_cache_update() -> void:
	var builder := BuilderService.new()
	var build: BuilderState = builder.begin_build(PositionFamily.Value.WING, ProspectProfile.Value.BALANCED,
		MaturityProfile.Value.AVERAGE, builder.default_body_for_family(PositionFamily.Value.WING), SeededRandomSource.new(440024))
	build.fill_remaining_anywhere()
	var query := DevelopmentProjectionQuery.new()
	var view: BuilderConfirmationView = query.builder_confirmation_view(build)
	var rows: Array[Array] = view.development_value_rows()
	assert_str(rows[0][0]).is_equal("Current Overall")
	assert_str(rows[1][0]).is_equal("Maximum Potential")
	assert_str(rows[2][0]).is_equal("Projected Peak")
	assert_str(rows[0][1]).is_equal(str(OvrTruthfulnessAudit.oracle_display(build.values())))
	assert_str(rows[1][1]).is_equal(str(OvrTruthfulnessAudit.oracle_display(build.caps.values())))
	assert_str(rows[2][1]).is_equal(view.projection.projected_peak.to_display_string())
	var state: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(PositionFamily.Value.WING, 440024, &"cache")
	var before: int = query.projection_for(state).current_overall
	OvrTruthfulnessAudit.improve(state, false)
	var after: int = query.projection_for(state).current_overall
	assert_int(after).is_greater(before)
	assert_int(after).is_equal(OvrTruthfulnessAudit.oracle_display(state.attributes.canonical_values()))


func test_permitted_cap_reduction_exposes_locked_ordering_conflict_without_lowering_ratings() -> void:
	# This exact domain-level example is an owner-contract conflict, not a
	# performance fixture or a generated lifecycle prevalence measurement.
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var attributes: PlayerAttributes = PlayerAttributes.from_values(_uniform(80))
	var caps := AttributeCaps.new(_uniform(80))
	var ledger := CapChangeLedger.new()
	for key: int in [AttributeKey.Key.SPEED, AttributeKey.Key.STAMINA]:
		caps = caps.with_cap(key, 72)
		ledger.record(10, key, 80, 72, CapChangeLedger.Reason.INJURY, "owner-conflict-example")
	assert_int(ledger.entry_count()).is_equal(2)
	assert_int(OverallCalculator.current_overall(attributes, ratings)).is_equal(80)
	assert_int(OverallCalculator.maximum_potential_overall(caps, ratings)).is_equal(79)
	assert_int(caps.cap_for(AttributeKey.Key.SPEED)).is_less(attributes.speed)
	assert_bool(caps.has_room(AttributeKey.Key.SPEED, attributes.speed)).is_false()
	var projection_source: String = FileAccess.get_file_as_string("res://src/domain/basketball/ratings/development_projection.gd")
	assert_str(projection_source).contains("assert(p_current_overall <= p_maximum_potential")


func test_freshman_legality_and_real_development_intervention() -> void:
	for family in PositionFamily.all():
		var state: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(family, 440025 + family, &"legal")
		assert_array(Array(OvrTruthfulnessAudit.freshman_legality_errors(state))).is_empty()
		var cap_signature: String = state.caps.signature()
		var intervention: Dictionary = OvrTruthfulnessAudit.improve(state, true)
		assert_int(intervention["rating_points_applied"]).is_greater(0)
		assert_str(state.caps.signature()).is_equal(cap_signature)
		var before: Array[int] = intervention["before"]
		for key in range(5, 20):
			assert_int(state.attributes.get_rating(key)).is_equal(before[key])
		assert_float(state.point_ledger.balance()).is_equal(0.0)
		assert_float(state.point_ledger.total_attribute_spend()).is_equal(float(intervention["ap_granted"] as int))


func test_independent_cost_table_boundaries() -> void:
	var profile: ProgressionProfile = ProgressionProfile.default_profile()
	for destination in range(26, 100):
		assert_int(OvrTruthfulnessAudit.independent_point_cost(destination)).is_equal(
			profile.upgrade_cost_for_destination(destination))


func test_balanced_schedule_detects_duplicates_and_missing_exposure() -> void:
	var rows: Array[Dictionary] = OvrTruthfulnessAudit.schedule(3, 700001)
	assert_array(Array(OvrTruthfulnessAudit.schedule_errors(rows))).is_empty()
	rows[1]["seed"] = rows[0]["seed"]
	assert_array(Array(OvrTruthfulnessAudit.schedule_errors(rows))).contains("duplicate gameplay seed")
	rows = OvrTruthfulnessAudit.schedule(3, 700001)
	rows[2]["subject_home"] = rows[0]["subject_home"]
	rows[2]["subject_opens"] = rows[0]["subject_opens"]
	assert_array(Array(OvrTruthfulnessAudit.schedule_errors(rows))).contains("missing home/opener exposure")


func test_live_measurement_denominators_counts_and_determinism() -> void:
	var input: MatchInput = MatchFixtureFactory.quick_match()
	var output: MatchSimulationOutput = MatchSession.new(input, SeededRandomSource.new(440030)).run_to_completion()
	var before: String = output.signature()
	var player: PlayerMatchProfile = input.home.players[0]
	var row: Dictionary = OvrTruthfulnessAudit.measure(input, output, player, input.home.team_id)
	var line: PlayerStatLine = output.final_result.statistics.player_line(player.player_id)
	assert_str(output.signature()).is_equal(before)
	for key in OvrTruthfulnessAudit.STAT_KEYS:
		assert_int(row[String(key)]).is_equal(line.get(String(key)))
	assert_int(row["touches"]).is_equal(row["ledger_touches"])
	assert_int(row["team_possessions"]).is_equal(output.engine_possessions(input.home.team_id))
	assert_int(row["on_court_offense_possessions"]).is_greater(0)
	assert_int(row["on_court_offense_possessions"]).is_less_equal(row["team_possessions"] as int)
	assert_int(row["on_court_defense_possessions"]).is_less_equal(row["opponent_possessions"] as int)
	assert_int(row["opponent_fgm_on_court"]).is_less_equal(row["opponent_fga_on_court"] as int)
	var replay: MatchSimulationOutput = MatchSession.new(input, SeededRandomSource.new(440030)).run_to_completion()
	assert_str(MatchLedgerSerializer.hash_output(replay)).is_equal(MatchLedgerSerializer.hash_output(output))
