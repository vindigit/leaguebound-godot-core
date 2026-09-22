class_name TestPopulationPairing
extends GdUnitTestSuite

var _strength_cache: Dictionary = {}

## Exercise the real consumer; suppress only its automatic simulation launch.
class FixtureRunner extends "res://calibration/runners/run_home_court_diagnostics.gd":
	func _run() -> void:
		pass

## Construction contracts, not game outcomes or independent-sample claims.
## A local 468-fixture block has 25/169 ladder-pair cells (13 ladder cells in the base orientation). The complete
## joint population requires 54,756 fixtures; uncertainty belongs to quartets.

func test_legacy_pairing_has_a_two_point_raw_ladder_gap() -> void:
	var histogram: Dictionary = {}
	for variation in range(13):
		var gap: int = ((2 * variation * 37) % 13) - (((2 * variation + 1) * 37) % 13)
		histogram[gap] = histogram.get(gap, 0) + 1
	assert_int(histogram.size()).is_equal(2)
	assert_int(histogram[2]).is_equal(11)
	assert_int(histogram[-11]).is_equal(2)
	assert_float(2.0 * 2.1 / 12.0 * 2).is_equal_approx(0.7, 0.000001)
	assert_float(2.0 * 2.1 / 12.0 * -11).is_equal_approx(-3.85, 0.000001)


func test_full_cartesian_cycle_and_aligned_marginals() -> void:
	var joint: Dictionary = {}
	for round_index in range(117):
		var first_counts: Dictionary = {}
		var second_counts: Dictionary = {}
		var ladder_cells: Dictionary = {}
		var actual_cells: Dictionary = {}
		var actual_ladder_cells: Dictionary = {}
		for index in range(117):
			var variation: int = 4 * (round_index * 117 + index)
			var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
			assert_int(pair.size()).is_equal(2)
			for state in pair:
				assert_bool(state >= 0 and state < 117).is_true()
			first_counts[pair[0]] = first_counts.get(pair[0], 0) + 1
			second_counts[pair[1]] = second_counts.get(pair[1], 0) + 1
			var key: int = pair[0] * 117 + pair[1]
			joint[key] = joint.get(key, 0) + 1
			ladder_cells[(pair[0] % 13) * 13 + pair[1] % 13] = true
			for phase in range(4):
				var actual: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation + phase)
				var expected: PackedInt32Array = PackedInt32Array([pair[1], pair[0]]) if phase == 1 or phase == 2 else pair
				if actual != expected:
					assert_array(actual).is_equal(expected)
					return
				actual_cells[actual[0] * 117 + actual[1]] = true
				actual_ladder_cells[(actual[0] % 13) * 13 + actual[1] % 13] = true
		assert_int(first_counts.size()).is_equal(117)
		assert_int(second_counts.size()).is_equal(117)
		assert_int(ladder_cells.size()).is_equal(13)
		assert_int(actual_cells.size()).is_equal(231)
		assert_int(actual_ladder_cells.size()).is_equal(25)
		if first_counts.size() != 117 or second_counts.size() != 117 or actual_cells.size() != 231:
			return
		for count: int in first_counts.values() + second_counts.values():
			assert_int(count).is_equal(1)
	assert_int(joint.size()).is_equal(13689)
	for count: int in joint.values():
		assert_int(count).is_equal(1)


func test_actual_rounded_rosters_cross_venue_and_opener() -> void:
	var nonzero: int = 0
	for competition in range(5):
		for pair_index in range(117):
			var first: MatchInput = CompetitionCatalog.match_for(competition, pair_index * 4)
			var a: String = _signature(first.home)
			var b: String = _signature(first.away)
			var gap: float = _gap(first)
			if absf(gap) > 0.001:
				nonzero += 1
			for phase in range(4):
				var input: MatchInput = CompetitionCatalog.match_for(competition, pair_index * 4 + phase)
				var swapped: bool = phase == 1 or phase == 2
				var home_signature: String = _signature(input.home)
				var away_signature: String = _signature(input.away)
				if home_signature != (b if swapped else a) or away_signature != (a if swapped else b):
					assert_bool(false).override_failure_message("actual roster crossover failed competition=%d pair=%d phase=%d" % [competition, pair_index, phase]).is_true()
					return
				assert_str(String(input.initial_possession_team_id)).is_equal("home" if phase % 2 == 0 else "away")
				assert_float(_gap(input)).is_equal_approx(-gap if swapped else gap, 0.000001)
	assert_int(nonzero).is_greater(0)


func test_roster_period_repeatability_and_eligibility() -> void:
	for competition in range(5):
		var distinct: Dictionary = {}
		for variation in range(117):
			var team: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"home", variation)
			var signature: String = _signature(team)
			distinct[signature] = true
			assert_str(_signature(CompetitionCatalog.team_for(competition, &"away", variation + 117))).is_equal(signature)
			assert_int(team.players.size()).is_equal(10)
			assert_int(team.starters().size()).is_equal(5)
			var ids: Dictionary = {}
			for player in team.players:
				ids[player.player_id] = true
				assert_bool(player.is_available()).is_true()
				assert_int(player.attributes.canonical_values().size()).is_equal(20)
				for rating in player.attributes.canonical_values():
					assert_bool(rating >= Rating.ACTIVE_MINIMUM and rating <= Rating.MAXIMUM).is_true()
			assert_int(ids.size()).is_equal(10)
			for starter in team.starters():
				assert_bool(ids.has(starter)).is_true()
		assert_int(distinct.size()).is_equal(117)
	var before: MatchInput = CompetitionCatalog.match_for(4, 54755)
	CompetitionCatalog.match_for(0, 123456)
	var after: MatchInput = CompetitionCatalog.match_for(4, 54755)
	assert_str(_signature(after.home)).is_equal(_signature(before.home))
	assert_str(_signature(after.away)).is_equal(_signature(before.away))
	assert_bool(after.home != before.home and after.home.players[0] != before.home.players[0]).is_true()


func test_explicit_offsets_and_openers_remain_venue_attached() -> void:
	for competition in range(5):
		for variation: int in [0, 1, 2, 3, 467, 468, 54755]:
			var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
			for opening: int in [CompetitionCatalog.OPENING_HOME, CompetitionCatalog.OPENING_AWAY]:
				var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 1.0, 3.0, -2.0, opening)
				assert_str(_signature(input.home)).is_equal(_signature(CompetitionCatalog.team_for(competition, &"home", pair[0], null, 3.0)))
				assert_str(_signature(input.away)).is_equal(_signature(CompetitionCatalog.team_for(competition, &"away", pair[1], null, -2.0)))
				assert_str(String(input.initial_possession_team_id)).is_equal("home" if opening == CompetitionCatalog.OPENING_HOME else "away")


func test_direct_mirror_keeps_original_roster_schedule() -> void:
	for competition in range(5):
		for variation: int in [0, 1, 2, 3, 13, 117, 468, 54755]:
			var input: MatchInput = CompetitionCatalog.mirrored_match_for(competition, variation, 0.0)
			var expected: String = _signature(CompetitionCatalog.team_for(competition, &"home", variation * 2))
			assert_str(_signature(input.home)).is_equal(expected)
			assert_str(_signature(input.away)).is_equal(expected)
			assert_str(String(input.initial_possession_team_id)).is_equal("home" if variation % 2 == 0 else "away")
			for opening: int in [CompetitionCatalog.OPENING_HOME, CompetitionCatalog.OPENING_AWAY]:
				var explicit: MatchInput = CompetitionCatalog.mirrored_match_for(competition, variation, 1.0, opening)
				assert_str(_signature(explicit.home)).is_equal(expected)
				assert_str(_signature(explicit.away)).is_equal(expected)
				assert_str(String(explicit.initial_possession_team_id)).is_equal("home" if opening == CompetitionCatalog.OPENING_HOME else "away")


func test_large_variations_preserve_identity_profiles_and_cycle() -> void:
	for competition in range(5):
		for base: int in [23400000, 28080000, 32760000, 54756]:
			for offset in range(-1, 4):
				var variation: int = base + offset
				var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.0)
				var reduced: MatchInput = CompetitionCatalog.match_for(competition, variation % 54756, 1.0)
				assert_str(_signature(input.home)).is_equal(_signature(reduced.home))
				assert_str(_signature(input.away)).is_equal(_signature(reduced.away))
				assert_str(String(input.match_id)).is_equal("calib_%s_%d" % [CalibrationTargets.competition_id(competition), variation])
				assert_str(String(input.game_id)).is_equal("calib_game_%d" % variation)
				assert_float(input.home_environment).is_equal(0.0)
				assert_str(String(input.rule_profile.version)).is_equal(String(CompetitionCatalog.rules_for(competition).version))
				assert_str(String(input.balance_profile.version)).is_equal(String(CompetitionCatalog.balance_profile().version))
				assert_str(String(input.ratings_profile.version)).is_equal(String(CompetitionCatalog.ratings_profile().version))
				for team: TeamMatchProfile in [input.home, input.away]:
					assert_str(String(team.team_id)).is_equal("home" if team == input.home else "away")
					for index in range(10):
						assert_str(String(team.players[index].player_id)).is_equal("%s_p%d" % [team.team_id, index + 1])


## Structural wiring checks only: these runners construct inline custom inputs.
## Actual rounded roster behavior is independently exercised above.
func test_custom_population_consumers_share_the_schedule() -> void:
	for entry: Array in [["run_contest_sweep.gd", 1], ["run_fg_counterfactual.gd", 2], ["run_home_court_diagnostics.gd", 1]]:
		var source: String = FileAccess.get_file_as_string("res://calibration/runners/" + (entry[0] as String))
		var executable: String = ""
		for line in source.split("\n"):
			executable += line.split("#")[0] + "\n"
		assert_int(executable.count("CompetitionCatalog.population_roster_variations(variation)")).is_equal(entry[1])
		assert_bool(executable.contains("variation * 2 + 1")).is_false()
		assert_int(executable.count("roster_variations[0]")).is_equal(entry[1])
		assert_int(executable.count("roster_variations[1]")).is_equal(entry[1])


func test_actual_venue_consumer_preserves_int64_mirror_indices() -> void:
	var runner := FixtureRunner.new()
	# These upper witnesses remain safe through team_for's largest multiplication:
	# 2 * (2^56 + 1) * 37 < INT64_MAX. No expected path packs/casts to int32.
	var variations: Array[int] = [1073741823, 1073741824, 1073741825,
		2147483648, 1099511627776, 72057594037927936, 72057594037927937]
	for competition in range(5):
		for variation in variations:
			for mode: String in ["mirror", "population"]:
				var first_variation: int = variation * 2
				var second_variation: int = first_variation
				if mode == "population":
					var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
					first_variation = pair[0]
					second_variation = pair[1]
				var first: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"home", first_variation)
				var second: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"away", second_variation)
				for environment: float in [0.0, 0.5]:
					for reversed: bool in [false, true]:
						var input: MatchInput = runner._venue_input(competition, variation, mode, environment, reversed)
						var home_expected: String = _complete_team_signature(second if reversed else first)
						var away_expected: String = _complete_team_signature(first if reversed else second)
						if _complete_team_signature(input.home) != home_expected or _complete_team_signature(input.away) != away_expected:
							runner.free()
							assert_bool(false).override_failure_message("actual venue consumer roster mismatch competition=%d variation=%d mode=%s reversed=%s environment=%s" % [competition, variation, mode, reversed, environment]).is_true()
							return
						assert_str(String(input.initial_possession_team_id)).is_equal("home" if variation % 2 == 0 else "away")
						assert_str(String(input.home.team_id)).is_equal("away" if reversed else "home")
						assert_str(String(input.away.team_id)).is_equal("home" if reversed else "away")
						assert_str(String(input.match_id)).is_equal("home_court_%s_%d" % [CalibrationTargets.competition_id(competition), variation])
						assert_str(String(input.game_id)).is_equal("home_court_game_%d" % variation)
						assert_float(input.home_environment).is_equal(environment)
						assert_str(String(input.rule_profile.version)).is_equal(String(CompetitionCatalog.rules_for(competition).version))
						assert_str(String(input.balance_profile.version)).is_equal(String(CompetitionCatalog.balance_profile().version))
						assert_str(String(input.ratings_profile.version)).is_equal(String(CompetitionCatalog.ratings_profile().version))
	runner.free()


func _complete_team_signature(team: TeamMatchProfile) -> String:
	var identities: Array = []
	for player in team.players:
		identities.append([player.player_id, player.badges.size(), player.injury_limitations.size(),
			player.qualitative_durability_band, player.is_available()])
	var plan: TeamGamePlan = team.game_plan
	return JSON.stringify([team.team_id, team.chemistry, _signature(team), identities,
		team.rotation_plan.starters, team.rotation_plan.substitution_order,
		team.rotation_plan.closing_lineup, team.rotation_plan.planned_minute_share,
		[plan.coverage_family, plan.tempo_instruction, plan.shot_profile_instruction,
			plan.ball_movement_instruction, plan.help_instruction, plan.crash_instruction,
			plan.gamble_instruction, plan.strictness, plan.trust]])


func _gap(input: MatchInput) -> float:
	return TeamStrengthIndex.expected_gap(
		_strength(input.home, input), _strength(input.away, input))


func _strength(team: TeamMatchProfile, input: MatchInput) -> TeamStrengthIndex:
	var key: String = _signature(team)
	if not _strength_cache.has(key):
		_strength_cache[key] = TeamStrengthIndex.of_team(team, input.ratings_profile, input.balance_profile)
	return _strength_cache[key] as TeamStrengthIndex


## Normalize only identity; retain every rating, body dimension and role.
func _signature(team: TeamMatchProfile) -> String:
	var rows: Array = []
	for player in team.players:
		rows.append([player.attributes.canonical_values(), player.positions.primary,
			player.positions.secondary, player.body.height_inches, player.body.weight_pounds,
			player.body.wingspan_inches, player.body.standing_reach_inches,
			player.rotation_role, player.tactical_role.role, player.condition,
			player.tendencies.values, team.rotation_plan.share_for(player.player_id)])
	return JSON.stringify(rows)
