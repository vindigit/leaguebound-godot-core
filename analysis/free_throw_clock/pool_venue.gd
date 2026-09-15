extends SceneTree

# Recombine separately scheduled competition runs through the same estimator
# the canonical runner uses. No simulation or fitting occurs here.
func _init() -> void:
	var pooled := VenueEffectEstimator.new()
	var reproduced: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var id: String = String(CalibrationTargets.competition_id(competition))
		var path: String = "res://analysis/free_throw_clock/venue_reports/home_court_diagnostics_ft_%s.json" % id
		var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var sections: Dictionary = payload["sections"]
		var estimator := VenueEffectEstimator.new()
		for row: Dictionary in sections["venue_paired_fixtures"]:
			assert(row["competition"] == id)
			for arm: StringName in [&"home", &"neutral", &"reversed"]:
				assert(estimator.observe(StringName(JsonRead.string_at(row, "fixture")), arm,
					JsonRead.float_at(row, "%s_margin" % arm), JsonRead.float_at(row, "%s_possessions" % arm)))
		assert(estimator.pair_count() == 200 and estimator.is_well_formed())
		var published: Dictionary = sections["venue_effect_estimator"][0]
		assert(absf(estimator.venue_attributable_win_rate() - JsonRead.float_at(published, "venue_attributable_win_rate")) < 1e-9)
		assert(absf(estimator.points_per_100() - JsonRead.float_at(published, "points_per_100")) < 1e-9)
		assert(pooled.merge(estimator))
		reproduced += 1
	assert(reproduced == 5 and pooled.pair_count() == 1000 and pooled.is_well_formed())
	var result: Dictionary = pooled.to_dictionary()
	result["source_reports_reproduced"] = reproduced
	result["certification"] = false
	var file := FileAccess.open("res://analysis/free_throw_clock/venue_pooled.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	print(JSON.stringify(result, "  "))
	quit(0)
