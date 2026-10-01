class_name TestBuilderDominanceFollowup
extends GdUnitTestSuite


func test_portfolio_exhausts_real_budgets_and_replays_seeded_caps() -> void:
	var ids: Dictionary = {}
	for spec in BuilderDominanceFixtures.portfolio():
		ids[spec["id"]] = true
		for seed_value: int in [910000,918181,920909]:
			var constructed: Dictionary = BuilderDominanceFixtures.construct(spec,seed_value,&"test")
			var record: Dictionary = constructed["record"]
			var state: PlayerDevelopmentState = constructed["state"]
			assert_array(Array(BuilderDominanceFixtures.independent_legality(record))).is_empty()
			assert_int(state.age).is_equal(14)
			assert_int(state.creation_budget.remaining()).is_equal(0)
			assert_float(state.point_ledger.balance()).is_equal(0.0)
			var replay: BuilderState = BuilderService.new().begin_build(spec["family"] as int,spec["prospect"] as int,
				MaturityProfile.Value.AVERAGE,BuilderDominanceFixtures.body_for(spec["family"] as int,spec["body_variant"] as int),
				SeededRandomSource.new(seed_value))
			assert_array(replay.caps.values()).is_equal(record["caps"])
			assert_array(replay.bases()).is_equal(record["bases"])
	assert_int(ids.size()).is_equal(22)


func test_tendency_only_variants_keep_all_construction_facts_identical() -> void:
	var reference: Dictionary = BuilderDominanceFixtures.construct(
		BuilderDominanceFixtures.portfolio()[0],919191,&"test")["record"]
	for index: int in [16,17]:
		var variant: Dictionary = BuilderDominanceFixtures.construct(
			BuilderDominanceFixtures.portfolio()[index],919191,&"test")["record"]
		for key: String in ["body","bases","caps","ratings","ap_spent","ap_granted","seed"]:
			assert_that(variant[key]).is_equal(reference[key])
		assert_bool(variant["tendencies"] != reference["tendencies"]).is_true()


func test_independent_validator_rejects_ap_economics_and_cap_corruptions() -> void:
	var original: Dictionary = BuilderDominanceFixtures.construct(
		BuilderDominanceFixtures.portfolio()[1],919191,&"test")["record"]
	var corrupt: Dictionary = original.duplicate(true)
	corrupt["ap_spent"] -= 1
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has(
		"independent AP reconciliation/exhaustion")).is_true()
	corrupt = original.duplicate(true)
	corrupt["caps"][0] += 1
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has(
		"seeded base/cap reconstruction")).is_true()
	corrupt = original.duplicate(true)
	corrupt["ratings"][0] = 76
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has(
		"rating/base/cap/starting maximum")).is_true()


func test_independent_validator_rejects_shape_body_and_tendency_corruptions() -> void:
	var original: Dictionary = BuilderDominanceFixtures.construct(
		BuilderDominanceFixtures.portfolio()[0],919191,&"test")["record"]
	var corrupt: Dictionary = original.duplicate(true)
	(corrupt["tendencies"] as Array).pop_back()
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has("canonical vector count")).is_true()
	corrupt = original.duplicate(true)
	corrupt["body"][3] += 1
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has("derived standing reach")).is_true()
	corrupt = original.duplicate(true)
	corrupt["family"] = 3
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has("family/prospect/maturity domain")).is_true()
	corrupt = original.duplicate(true)
	corrupt["tendencies"][0] = 6
	assert_bool(BuilderDominanceFixtures.independent_legality(corrupt).has("tendency domain")).is_true()


func test_legal_body_contrasts_expose_redistribution_and_seeded_caps() -> void:
	var small: Dictionary = BuilderDominanceFixtures.construct(
		BuilderDominanceFixtures.portfolio()[14],919191,&"small")["record"]
	var large: Dictionary = BuilderDominanceFixtures.construct(
		BuilderDominanceFixtures.portfolio()[15],919191,&"large")["record"]
	assert_bool(small["bases"] != large["bases"]).is_true()
	assert_bool(small["body"] != large["body"]).is_true()
	assert_int(small["ap_granted"]).is_equal(large["ap_granted"])
	assert_bool(small["current_overall"] <= 54 and large["current_overall"] <= 54).is_true()


func test_full_factorial_and_corrected_fixture_quartets_are_preserved() -> void:
	var selected: Array[int] = [0,1,2,3,4,5,6,7]
	assert_array(BuilderDominanceFixtures.experiment_cells(true,selected)).is_equal(selected)
	assert_array(BuilderDominanceFixtures.experiment_cells(false,selected)).is_equal([0])
	var contexts: Dictionary = {}
	for cell in range(8):
		var ctx: Dictionary = BuilderDominanceFixtures.context(cell)
		contexts["%s/%s/%s" % [ctx["role"],ctx["lineup"],ctx["opponent"]]] = true
		var quartet: Array[Dictionary] = []
		for phase in range(4):
			var variation: int = 71000000 + cell*1000 + phase
			var fixture: Dictionary = BuilderDominanceFixtures.match_for(
				BuilderDominanceFixtures.portfolio()[0],variation,cell)
			var input: MatchInput = fixture["input"]
			var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation-phase)
			assert_int(fixture["subject_roster"]).is_equal(pair[0])
			assert_int(fixture["opponent_roster"]).is_equal(pair[1])
			quartet.append({"seed":variation+1,"phase":phase,
				"home_subject":input.home.team_id == &"subject",
				"subject_opens":input.initial_possession_team_id == &"subject"})
		assert_array(Array(BuilderDominanceAudit.schedule_errors(quartet))).is_empty()
	assert_int(contexts.size()).is_equal(8)
	assert_str(String(CompetitionCatalog.VERSION)).is_equal("competition-catalog-v4-roster-pairing")


func test_matched_builds_hold_teammates_opponents_and_stream_identity_fixed() -> void:
	var original: Dictionary = BuilderDominanceFixtures.match_for(
		BuilderDominanceFixtures.portfolio()[0],71000000,0)
	for index: int in [1,8,16]:
		var other: Dictionary = BuilderDominanceFixtures.match_for(
			BuilderDominanceFixtures.portfolio()[index],71000000,0)
		assert_str(original["teammate_signature"]).is_equal(other["teammate_signature"])
		assert_str(original["opponent_signature"]).is_equal(other["opponent_signature"])
		var input: MatchInput = original["input"]
		var compared: MatchInput = other["input"]
		assert_str(String(input.match_id)).is_equal(String(compared.match_id))
		assert_str(String(input.initial_possession_team_id)).is_equal(String(compared.initial_possession_team_id))


func test_schedule_rejects_duplicates_incomplete_quartets_and_venue_bias() -> void:
	var rows: Array[Dictionary] = []
	for phase in range(4):
		rows.append({"seed":71+phase,"phase":phase,"home_subject":phase==0 or phase==3,
			"subject_opens":phase<2})
	assert_array(Array(BuilderDominanceAudit.schedule_errors(rows))).is_empty()
	rows[1]["seed"] = rows[0]["seed"]
	assert_bool(BuilderDominanceAudit.schedule_errors(rows).has("duplicate simulation seed within build")).is_true()
	rows[1]["seed"] = 72
	rows[2]["home_subject"] = true
	assert_bool(BuilderDominanceAudit.schedule_errors(rows).has("venue/opener quartet balance")).is_true()
	rows.pop_back()
	assert_bool(BuilderDominanceAudit.schedule_errors(rows).has("incomplete quartet")).is_true()


func test_denominator_and_score_corruptions_fail_for_intended_reason() -> void:
	var row: Dictionary = _valid_row()
	assert_array(Array(BuilderDominanceAudit.row_errors(row))).is_empty()
	row["possession_records"] += 1
	assert_bool(BuilderDominanceAudit.row_errors(row).has("possession denominator reconciliation")).is_true()
	row = _valid_row()
	row["defended_attempts"] = 1
	assert_bool(BuilderDominanceAudit.row_errors(row).has("defended shot denominator")).is_true()
	row = _valid_row()
	row["ledger_touches"] -= 1
	assert_bool(BuilderDominanceAudit.row_errors(row).has("player ledger reconciliation")).is_true()
	row = _valid_row()
	row["on_court_defense_possessions"] = -1
	assert_bool(BuilderDominanceAudit.row_errors(row).has("nonnegative finite integer count: on_court_defense_possessions")).is_true()


func test_real_freshman_game_instrument_is_deterministic_and_reconciles() -> void:
	var fixture: Dictionary = BuilderDominanceFixtures.match_for(
		BuilderDominanceFixtures.portfolio()[0],91000000,0)
	var input: MatchInput = fixture["input"]
	var first: MatchSimulationOutput = MatchSession.new(input,SeededRandomSource.new(91000001)).run_to_completion()
	var second: MatchSimulationOutput = MatchSession.new(input,SeededRandomSource.new(91000001)).run_to_completion()
	assert_str(first.signature()).is_equal(second.signature())
	var row: Dictionary = BuilderDominanceAudit.measure(input,first,fixture["subject_id"] as StringName)
	assert_array(Array(row["errors"] as PackedStringArray)).is_empty()
	assert_int(row["field_goals_attempted"]).is_greater(0)
	assert_int(row["on_court_offense_possessions"]).is_greater(0)
	assert_int(row["on_court_defense_possessions"]).is_greater(0)
	assert_int(row["defended_attempts"]).is_greater(0)


func _valid_row() -> Dictionary:
	return {"possession_starts":20,"possession_ends":20,"possession_records":20,
		"ledger_points":9,"points":9,"ledger_attempts":5,"field_goals_attempted":5,
		"ledger_touches":10,"touches":10,"reconciliation_errors":PackedStringArray(),
		"defended_makes":2,"defended_three_makes":1,"defended_attempts":5,
		"on_court_offense_possessions":8,"on_court_defense_possessions":9,
		"team_possessions":10,"opponent_possessions":10,"seconds_played":120,
		"field_goals_made":3,"three_pointers_made":1,"free_throws_made":2}
