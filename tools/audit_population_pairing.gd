extends SceneTree

## No games or RNG. Archive actual rounded roster vectors and derived gaps.
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var competitions: Array = []
	var local_support: Array = []
	for round_index in range(117):
		var cells: Dictionary = {}
		var ladders: Dictionary = {}
		for variation in range(round_index * 468, (round_index + 1) * 468):
			var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
			cells[pair[0] * 117 + pair[1]] = true
			ladders[(pair[0] % 13) * 13 + pair[1] % 13] = true
		local_support.append({"first_variation": round_index * 468,
			"actual_ordered_roster_cells": cells.size(), "actual_ladder_cells": ladders.size()})
	for competition in range(5):
		var states: Array = []
		var strengths: Array[TeamStrengthIndex] = []
		var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
		var ratings: RatingsProfile = CompetitionCatalog.ratings_profile()
		for variation in range(117):
			var team: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"roster", variation)
			var strength: TeamStrengthIndex = TeamStrengthIndex.of_team(team, ratings, balance)
			strengths.append(strength)
			var vectors: Array = []
			for player in team.players:
				vectors.append(player.attributes.canonical_values())
			states.append({"variation": variation, "ladder_index": variation * 37 % 13,
				"ratings": vectors, "offense": strength.offense, "defense": strength.defense,
				"overall_capability": strength.overall})
		var legacy: Array[float] = []
		var corrected: Array[float] = []
		# 234 fixtures crosses the old complete roster period and opener parity.
		for variation in range(234):
			legacy.append(TeamStrengthIndex.expected_gap(strengths[2 * variation % 117], strengths[(2 * variation + 1) % 117]))
		for variation in range(54756):
			var pair: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
			corrected.append(TeamStrengthIndex.expected_gap(strengths[pair[0]], strengths[pair[1]]))
		competitions.append({"competition": CalibrationTargets.competition_id(competition),
			"roster_states": states, "legacy_234": _summary(legacy),
			"corrected_54756": _summary(corrected)})
	var report: Dictionary = {"catalog": CompetitionCatalog.VERSION,
		"scope": "Construction only; legacy denotes old adjacent pairing applied to unchanged current rosters. No game outcomes or independent local joint-population claim.",
		"raw_legacy_ladder_gap": {"2": 11, "-11": 2},
		"raw_legacy_rating_level_gap": {"0.7": 11, "-3.85": 2},
		"local_joint_support": "Each aligned 468-fixture block has 231 ordered roster cells and 25/169 ladder cells; its 117 base orientations have 117 roster cells and 13/169 ladder cells; full joint period 54756 fixtures.",
		"enumerated_local_support": local_support,
		"competitions": competitions}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else "res://analysis/roster_pairing_followup/construction_audit.json"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("Construction audit written: ", output)
	quit(0)


func _summary(gaps: Array[float]) -> Dictionary:
	var positive: int = 0
	var negative: int = 0
	var zero: int = 0
	var sum: float = 0.0
	var squares: float = 0.0
	var histogram: Dictionary = {}
	for gap in gaps:
		if gap > 0.00000001:
			positive += 1
		elif gap < -0.00000001:
			negative += 1
		else:
			zero += 1
		sum += gap
		squares += gap * gap
		var key: String = "%.9f" % gap
		histogram[key] = histogram.get(key, 0) + 1
	return {"n": gaps.size(), "positive": positive, "negative": negative, "zero": zero,
		"mean": sum / gaps.size(), "rms": sqrt(squares / gaps.size()),
		"gap_histogram_9dp": histogram}
