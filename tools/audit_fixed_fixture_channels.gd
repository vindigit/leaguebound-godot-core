extends SceneTree

## Reproduce the existing 24-game compensation-channel snapshot, without
## modifying any expected value, target, tolerance or production parameter.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var decomposition := PppDecomposition.new()
	for index in range(24):
		var variation: int = 905000 + index
		var input: MatchInput = CompetitionCatalog.match_for(CalibrationTargets.Competition.COLLEGE, variation, 0.5)
		decomposition.accumulate(input, MatchEngine.new().simulate_match(input, SeededRandomSource.new(variation + 1)))
	var totals: PppDecomposition.Totals = decomposition.totals
	assert(decomposition.field_goal_identities_hold())
	print(JSON.stringify({"games": 24, "variation_first": 905000, "variation_last": 905023,
		"ruleset": String(CompetitionCatalog.balance_profile().version),
		"college_pace": CompetitionCatalog.rules_for(CalibrationTargets.Competition.COLLEGE).pace_multiplier,
		"turnover_rate": totals.turnover_rate(), "extension_rate": totals.extension_rate(),
		"offensive_rebound_rate": totals.offensive_rebound_rate(), "assisted_share": totals.assisted_share(),
		"possessions_both_teams_per_game": totals.possessions_per_game()}))
	quit(0)
