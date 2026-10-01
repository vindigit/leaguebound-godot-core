extends SceneTree

## Raw game evidence only. Analysis and inferential assertions remain separate.
## --range=exploration|validation_a|validation_b --out=res://reports/builder_followup
## --cells=0,1,... (smoke only); --quartets=2 (frozen confirmation size)
var _errors: PackedStringArray = []
const SOURCE_FILES: PackedStringArray = [
	"res://analysis/builder_dominance_followup/protocol.json",
	"res://analysis/builder_dominance_followup/analyze.py",
	"res://analysis/builder_dominance_followup/test_analysis.py",
	"res://calibration/harness/builder_dominance_fixtures.gd",
	"res://calibration/harness/builder_dominance_audit.gd",
	"res://calibration/runners/run_builder_dominance_followup.gd",
	"res://tests/calibration/test_builder_dominance_followup.gd"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_hashes: Dictionary = {}
	for path in SOURCE_FILES:
		source_hashes[path] = FileAccess.get_sha256(path)
	var production_hashes: Dictionary = {}
	_source_hashes("res://src",production_hashes)
	var git_output: Array = []
	var git_status: int = OS.execute("git",["rev-parse","HEAD"],git_output)
	var execution_head: String = str(git_output[0]).strip_edges() if git_status == 0 else "unavailable"
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var label: String = CalibrationCli.string_option(options,&"range","exploration")
	var starts: Dictionary = {"exploration":61000000,"validation_a":71000000,"validation_b":81000000,"smoke":91000000}
	assert(starts.has(label), "predeclared range required")
	var base: int = starts[label]
	var quartets: int = CalibrationCli.int_option(options,&"quartets",2)
	assert(quartets == 2 or label == "smoke", "confirmation sample frozen at two quartets per cell")
	var cells_option: String = CalibrationCli.string_option(options,&"cells","0" if label == "exploration" or label == "smoke" else "0,1,2,3,4,5,6,7")
	var cells: Array[int] = []
	for value in cells_option.split(","):
		cells.append(value.to_int())
	if label.begins_with("validation"):
		assert(cells == [0,1,2,3,4,5,6,7], "confirmation context coverage frozen")
	var out_dir: String = CalibrationCli.string_option(options,&"out","res://reports/builder_followup")
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir)) == OK,
		"cannot create observation directory")
	var file: FileAccess = FileAccess.open(out_dir.path_join(label + ".ndjson"),FileAccess.WRITE)
	assert(file != null, "cannot create raw evidence")
	var portfolio: Array[Dictionary] = BuilderDominanceFixtures.portfolio()
	var manifests: Dictionary = {}
	var count: int = 0
	var started: int = Time.get_ticks_msec()
	for spec in portfolio:
		var use_cells: Array[int] = BuilderDominanceFixtures.experiment_cells(spec["primary"] as bool,cells)
		for cell in use_cells:
			for quartet in range(quartets):
				var block: Array[Dictionary] = []
				for phase in range(4):
					var variation: int = base + cell * 1000 + quartet * 4 + phase
					var fixture: Dictionary = BuilderDominanceFixtures.match_for(spec,variation,cell)
					var input: MatchInput = fixture["input"]
					var output: MatchSimulationOutput = MatchSession.new(input,
						SeededRandomSource.new(variation + 1)).run_to_completion()
					var row: Dictionary = BuilderDominanceAudit.measure(input,output,fixture["subject_id"] as StringName)
					row.merge({"range":label,"build_id":spec["id"],"primary":spec["primary"],
						"cell":cell,"quartet":quartet,"cluster":"%d:%d" % [cell,quartet],
						"phase":phase,"variation":variation,"seed":variation+1,
						"home_subject":input.home.team_id == &"subject",
						"subject_opens":input.initial_possession_team_id == &"subject",
						"context":fixture["context"],"build":fixture["build_record"],
						"subject_roster":fixture["subject_roster"],"opponent_roster":fixture["opponent_roster"],
						"teammate_signature":fixture["teammate_signature"],
						"opponent_signature":fixture["opponent_signature"],
						"fixture_version":BuilderDominanceFixtures.VERSION,
						"audit_version":BuilderDominanceAudit.VERSION,
						"catalog_version":String(CompetitionCatalog.VERSION),
						"ruleset":String(input.balance_profile.version),
						"competition_rule_version":String(input.rule_profile.version),
						"ratings_profile_version":String(input.ratings_profile.version)})
					_errors.append_array(row["errors"] as PackedStringArray)
					assert((row["errors"] as PackedStringArray).is_empty(), "raw evidence reconciliation failed")
					block.append(row)
					file.store_line(JSON.stringify(row))
					file.flush()
					count += 1
					var key: String = "%s:%d" % [spec["id"],fixture["subject_roster"]]
					manifests[key] = fixture["build_record"]
				_errors.append_array(BuilderDominanceAudit.schedule_errors(block))
		print("Builder %s %s complete; %d games, %.2fs/game" % [label,spec["id"],count,
			float(Time.get_ticks_msec()-started)/1000.0/float(count)])
	file.close()
	for path in SOURCE_FILES:
		assert(source_hashes[path] == FileAccess.get_sha256(path), "instrument changed during collection")
	var final_production: Dictionary = {}
	_source_hashes("res://src",final_production)
	assert(production_hashes == final_production, "production changed during collection")
	var metadata: Dictionary = {"range":label,"games":count,"quartets_per_cell":quartets,
		"completed_utc":Time.get_datetime_string_from_system(true),
		"rng_version":String(SeededRandomSource.VERSION),
		"execution_head":execution_head,"instrument_sha256":source_hashes,
		"production_sha256":production_hashes,"production_behavior_changed":false,"certified":false,
		"cells":cells,"seed_first":base+1,"seed_last":base+cells[-1]*1000+quartets*4,
		"balance_versions":BalanceProfileSet.default_set().version_signature(),
		"fixtures":BuilderDominanceFixtures.VERSION,"audit":BuilderDominanceAudit.VERSION,
		"ruleset":String(SimulationBalanceProfile.new().version),"catalog":String(CompetitionCatalog.VERSION),
		"godot":Engine.get_version_info(),"elapsed_ms":Time.get_ticks_msec()-started,
		"errors":_errors,"build_manifest":manifests}
	var meta_file: FileAccess = FileAccess.open(out_dir.path_join(label+".metadata.json"),FileAccess.WRITE)
	assert(meta_file != null, "cannot write observation metadata")
	meta_file.store_string(JSON.stringify(metadata,"  "))
	meta_file.close()
	print("Builder dominance observations: %d games, %d instrument errors" % [count,_errors.size()])
	quit(0 if _errors.is_empty() else 1)


func _source_hashes(path: String, hashes: Dictionary) -> void:
	var directory: DirAccess = DirAccess.open(path)
	assert(directory != null,"source inventory directory unavailable")
	for entry in directory.get_files():
		if entry.ends_with(".gd"):
			hashes[path.path_join(entry)] = FileAccess.get_sha256(path.path_join(entry))
	for entry in directory.get_directories():
		_source_hashes(path.path_join(entry),hashes)
