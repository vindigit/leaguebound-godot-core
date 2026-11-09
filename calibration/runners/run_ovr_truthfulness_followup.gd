extends SceneTree

## Executable protocol: analysis/ovr_truthfulness_followup/protocol.json.
## Raw observations are bulky and belong under ignored reports/. Aggregate
## evidence and exact reproducibility manifests are checked in separately.
const PROTOCOL: String = "res://analysis/ovr_truthfulness_followup/protocol.json"
const ARMS: PackedStringArray = ["baseline", "all20_plus10_toward_caps", "scoring5_plus10_toward_caps"]

var _options: Dictionary
var _label: String
var _range: String
var _offset: int
var _manifest: Dictionary


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_options = CalibrationCli.parse(OS.get_cmdline_user_args())
	_range = CalibrationCli.string_option(_options, &"range", "A")
	_label = CalibrationCli.string_option(_options, &"label", _range)
	assert(_range == "A" or _range == "B" or _range == "smoke", "unknown frozen range")
	_offset = 100000 if _range == "B" else 0
	if _range == "smoke": _offset = -9000000
	var mode: String = CalibrationCli.string_option(_options, &"mode", "all")
	_manifest = {"version": OvrTruthfulnessAudit.VERSION, "range": _range,
		"protocol_sha256": FileAccess.get_sha256(PROTOCOL),
		"source_head": "899a3972e48e8ce63de07b47b2e593e9c97df4d2",
		"catalog": String(CompetitionCatalog.VERSION),
		"balance": BalanceProfileSet.default_set().version_signature(),
		"godot": Engine.get_version_info()["string"],
		"rng": SeededRandomSource.new(1).get_version(), "outputs": {},
		"certified": false, "production_behavior_changed": false}
	var git_output: Array = []
	var git_status: int = OS.execute("git", ["rev-parse", "HEAD"], git_output)
	_manifest["execution_head"] = str(git_output[0]).strip_edges() if git_status == 0 else "unavailable"
	_manifest["instrument_sha256"] = {
		"audit": FileAccess.get_sha256("res://calibration/harness/ovr_truthfulness_audit.gd"),
		"runner": FileAccess.get_sha256("res://calibration/runners/run_ovr_truthfulness_followup.gd"),
		"tests": FileAccess.get_sha256("res://tests/calibration/test_ovr_truthfulness_audit.gd")}
	_manifest["production_sha256"] = {}
	_source_hashes("res://src", _manifest["production_sha256"] as Dictionary)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	if mode == "all" or mode == "within": _within_player()
	if mode == "all" or mode == "catalog": _catalog_games()
	if mode == "all" or mode == "college": _college_games()
	if mode == "all" or mode == "histograms": _histograms()
	var after_hashes: Dictionary = {}
	_source_hashes("res://src", after_hashes)
	assert(after_hashes == (_manifest["production_sha256"] as Dictionary), "production source changed during collection")
	assert(FileAccess.get_sha256(PROTOCOL) == (_manifest["protocol_sha256"] as String), "protocol changed during collection")
	assert(FileAccess.get_sha256("res://calibration/harness/ovr_truthfulness_audit.gd") == (_manifest["instrument_sha256"]["audit"] as String), "audit changed during collection")
	assert(FileAccess.get_sha256("res://calibration/runners/run_ovr_truthfulness_followup.gd") == (_manifest["instrument_sha256"]["runner"] as String), "runner changed during collection")
	assert(FileAccess.get_sha256("res://tests/calibration/test_ovr_truthfulness_audit.gd") == (_manifest["instrument_sha256"]["tests"] as String), "tests changed during collection")
	_manifest["unchanged_source_after_collection"] = true
	_write_json("manifest", _manifest)
	print("OVR report %s %s completed" % [mode, _label])
	quit(0)


func _source_hashes(path: String, hashes: Dictionary) -> void:
	var directory: DirAccess = DirAccess.open(path)
	assert(directory != null, "source hash inventory directory missing")
	for entry in directory.get_files():
		if entry.ends_with(".gd"):
			hashes[path + "/" + entry] = FileAccess.get_sha256(path + "/" + entry)
	for entry in directory.get_directories():
		_source_hashes(path + "/" + entry, hashes)


func _raw_file(kind: String) -> FileAccess:
	var path: String = "res://reports/ovr_%s_%s.ndjson" % [kind, _label]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "cannot write OVR raw observations")
	_manifest["outputs"][kind] = {"path": path, "rows": 0, "games": 0}
	return file


func _store(file: FileAccess, kind: String, row: Dictionary) -> void:
	file.store_line(JSON.stringify(row))
	_manifest["outputs"][kind]["rows"] += 1


func _finish_raw(file: FileAccess, kind: String) -> void:
	file.close()
	_manifest["outputs"][kind]["sha256"] = FileAccess.get_sha256(_manifest["outputs"][kind]["path"] as String)


func _write_json(kind: String, payload: Dictionary) -> void:
	var path: String = "res://reports/ovr_%s_%s.json" % [kind, _label]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "cannot write OVR summary")
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _within_player() -> void:
	var clusters: int = CalibrationCli.int_option(_options, &"clusters", 8)
	assert(_range == "smoke" or clusters == 8, "confirmation sample cannot override frozen cluster count")
	var file: FileAccess = _raw_file("within")
	var source_first: int = 9800001 + _offset
	var game_first: int = 9810001 + _offset
	for family in PositionFamily.all():
		for index in range(clusters):
			var cluster: int = family * clusters + index
			var seed_value: int = source_first + cluster
			var schedule: Array[Dictionary] = OvrTruthfulnessAudit.schedule(cluster, game_first)
			assert(OvrTruthfulnessAudit.schedule_errors(schedule).is_empty(), "unbalanced OVR schedule")
			for arm in range(ARMS.size()):
				var state: PlayerDevelopmentState = OvrTruthfulnessAudit.legal_freshman(family, seed_value, &"subject_focus")
				var intervention: Dictionary = {"ap_granted": 0, "rating_points_applied": 0,
					"before": state.attributes.canonical_values(), "after": state.attributes.canonical_values(),
					"caps_unchanged": true}
				if arm > 0: intervention = OvrTruthfulnessAudit.improve(state, arm == 2)
				for assignment in schedule:
					var subject: TeamMatchProfile = _freshman_team(&"subject", seed_value * 100, state)
					var opponent: TeamMatchProfile = _freshman_team(&"opponent", seed_value * 100 + 20)
					var input: MatchInput = _paired_input(subject, opponent,
						CompetitionCatalog.rules_for(CalibrationTargets.Competition.HIGH_SCHOOL), assignment)
					var output: MatchSimulationOutput = MatchSession.new(input,
						SeededRandomSource.new(assignment["seed"] as int)).run_to_completion()
					assert(output.final_result.statistics.reconcile().is_empty(), "unreconciled OVR game")
					var row: Dictionary = OvrTruthfulnessAudit.measure(input, output,
						subject.player_by_id(state.player_id), subject.team_id)
					row.merge({"experiment": "within", "range": _range, "cluster": cluster,
						"arm": String(ARMS[arm]), "family": String(PositionFamily.id_of(family)),
						"competition": "high_school", "source_seed": seed_value,
						"teammate_seed_first": seed_value * 100, "opponent_seed_first": seed_value * 100 + 20,
						"intervention": intervention, "creation_ap": state.creation_budget.granted,
						"teammates_sha256": _team_hash(subject, state.player_id),
						"opponent_sha256": _team_hash(opponent),
						"caps": state.caps.values(), "maximum_potential": OverallCalculator.maximum_potential_overall(
							state.caps, input.ratings_profile), "ledger_sha256": MatchLedgerSerializer.hash_output(output)}, true)
					row.merge(assignment, true)
					_store(file, "within", row)
					_manifest["outputs"]["within"]["games"] += 1
			print("OVR within %s %s cluster %d/%d" % [_range, PositionFamily.id_of(family), index + 1, clusters])
	_finish_raw(file, "within")


func _team_hash(team: TeamMatchProfile, excluded: StringName = &"") -> String:
	var records: Array[Dictionary] = []
	for player in team.players:
		if player.player_id == excluded: continue
		records.append({"id": String(player.player_id), "body": player.body.signature(),
			"attributes": player.attributes.signature(), "tendencies": player.tendencies.values,
			"position": String(player.positions.primary), "rotation": player.rotation_role,
			"role": player.tactical_role.role})
	return JSON.stringify(records).sha256_text()


func _freshman_team(team_id: StringName, source_first: int,
		focus: PlayerDevelopmentState = null) -> TeamMatchProfile:
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	var families: PackedInt32Array = [0, 0, 1, 1, 2, 0, 0, 1, 1, 2]
	var focus_slot: int = -1
	if focus != null: focus_slot = [0, 2, 4][focus.position_family]
	for slot in range(10):
		var state: PlayerDevelopmentState = focus if slot == focus_slot else OvrTruthfulnessAudit.legal_freshman(
			families[slot], source_first + slot, StringName("%s_p%d" % [team_id, slot]))
		var rotation: int = RotationRole.Value.STARTER if slot < 5 else RotationRole.Value.ROTATION
		var player: PlayerMatchProfile = OvrTruthfulnessAudit.match_player(state, rotation)
		players.append(player)
		if slot < 5: starters.append(player.player_id)
	return TeamMatchProfile.new(team_id, players, starters, 0.5, null, CompetitionCatalog.balance_profile())


func _paired_input(subject: TeamMatchProfile, opponent: TeamMatchProfile,
		rules: CompetitionRuleProfile, assignment: Dictionary) -> MatchInput:
	var home: TeamMatchProfile = subject if assignment["subject_home"] else opponent
	var away: TeamMatchProfile = opponent if assignment["subject_home"] else subject
	var opening: StringName = subject.team_id if assignment["subject_opens"] else opponent.team_id
	return MatchInput.new(&"ovr_experiment", &"ovr_game", rules,
		CompetitionCatalog.balance_profile(), home, away, opening, CompetitionCatalog.ratings_profile(), 0.0)


func _catalog_games() -> void:
	var file: FileAccess = _raw_file("catalog")
	var seed_first: int = 9820001 + _offset
	for competition in CalibrationTargets.all_competitions():
		for variation in range(8):
			var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.0)
			var seed_value: int = seed_first + competition * 8 + variation
			var output: MatchSimulationOutput = MatchSession.new(input, SeededRandomSource.new(seed_value)).run_to_completion()
			assert(output.final_result.statistics.reconcile().is_empty(), "unreconciled catalog game")
			var digest: String = MatchLedgerSerializer.hash_output(output)
			var rosters: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation)
			for side in range(2):
				var team: TeamMatchProfile = input.home if side == 0 else input.away
				for player in team.players:
					var row: Dictionary = OvrTruthfulnessAudit.measure(input, output, player, team.team_id)
					row.merge({"experiment": "catalog", "range": _range,
						"competition": String(CalibrationTargets.competition_id(competition)),
						"cluster": competition * 2 + variation / 4, "variation": variation,
						"slot": variation % 4, "seed": seed_value, "roster_variation": rosters[side],
						"subject_home": side == 0, "subject_opens": input.initial_possession_team_id == team.team_id,
						"age": null, "caps": null, "maximum_potential": null,
						"ledger_sha256": digest}, true)
					_store(file, "catalog", row)
			_manifest["outputs"]["catalog"]["games"] += 1
			print("OVR catalog %s %s %d/8" % [_range, CalibrationTargets.competition_id(competition), variation + 1])
	_finish_raw(file, "catalog")


## Natural player draws are never selected for favorable OVR or match results.
## Team assembly is explicit experimental scaffolding because production has
## no roster constructor. Body snapshots use the original creation stream and
## the actual chronological milestones, not the final career's body.
func _college_games() -> void:
	var file: FileAccess = _raw_file("college")
	var simulator := CareerSimulator.new()
	simulator.capture_diagnostics = true
	for cluster in range(2):
		var teams: Array[TeamMatchProfile] = []
		var provenance: Dictionary = {}
		for side in range(2):
			var team_id := StringName("college_%d" % side)
			var players: Array[PlayerMatchProfile] = []
			var starters: Array[StringName] = []
			for slot in range(10):
				var seed_value: int = 9840001 + _offset + cluster * 20 + side * 10 + slot
				var career: CareerSimulator.CareerResult = simulator.simulate(seed_value, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)
				var state: PlayerDevelopmentState = career.final_state
				var class_index: int = slot % 3
				assert(career.college_values_by_class.size() == 3, "natural career lacks recorded college snapshots")
				var snapshot_values: Array[int] = []
				for value: int in career.college_values_by_class[class_index]: snapshot_values.append(value)
				var maturation := BodyMaturationService.new()
				var unchanged: String = state.attributes.signature()
				for year in range(2, 6 + class_index):
					maturation.resolve_increment(state, year, SeededRandomSource.new(seed_value).derive(&"confirm"))
				assert(state.attributes.signature() == unchanged, "body snapshot changed ratings")
				var player_id := StringName("%s_p%d" % [team_id, slot])
				var player := PlayerMatchProfile.new(player_id,
					PositionProfile.new(OvrTruthfulnessAudit.family_position(career.family)),
					state.body_state.realized_body.duplicate_body(), PlayerAttributes.from_values(snapshot_values), [],
					PlayerTendencies.new(), RotationRole.Value.STARTER if slot < 5 else RotationRole.Value.ROTATION,
					TacticalRole.new(OvrTruthfulnessAudit.family_role(career.family)))
				players.append(player)
				if slot < 5: starters.append(player_id)
				provenance[String(player_id)] = {"career_seed": seed_value, "path": String(CareerSimulator.path_id(career.path)),
					"prospect": String(ProspectProfile.id_of(career.prospect)), "family": String(PositionFamily.id_of(career.family)),
					"age": career.college_age_by_class[class_index], "class_year": class_index + 1,
					"snapshot_career_year": 5 + class_index, "growth_milestones": state.body_state.resolved_count(),
					"body_state_signature": state.body_state.signature(), "caps": career.starting_caps.values(),
					"creation_ap": state.creation_budget.granted, "creation_spent": state.creation_budget.spent,
					"maximum_potential": career.maximum_potential,
					"snapshot_recorded_ovr": career.college_overall_by_class[class_index]}
			teams.append(TeamMatchProfile.new(team_id, players, starters, 0.5, null, CompetitionCatalog.balance_profile()))
		for assignment in OvrTruthfulnessAudit.schedule(cluster, 9850001 + _offset):
			var input: MatchInput = _paired_input(teams[0], teams[1],
				CompetitionCatalog.rules_for(CalibrationTargets.Competition.COLLEGE), assignment)
			var output: MatchSimulationOutput = MatchSession.new(input,
				SeededRandomSource.new(assignment["seed"] as int)).run_to_completion()
			assert(output.final_result.statistics.reconcile().is_empty(), "unreconciled generated college game")
			var digest: String = MatchLedgerSerializer.hash_output(output)
			for team in teams:
				for player in team.players:
					var row: Dictionary = OvrTruthfulnessAudit.measure(input, output, player, team.team_id)
					row.merge(provenance[String(player.player_id)] as Dictionary, true)
					assert(row["current_ovr"] == row["snapshot_recorded_ovr"], "college reconstruction changed recorded ratings")
					row.merge({"experiment": "college", "range": _range, "competition": "college", "cluster": cluster,
						"slot": assignment["slot"], "seed": assignment["seed"], "subject_home": team.team_id == input.home.team_id,
						"subject_opens": team.team_id == input.initial_possession_team_id, "ledger_sha256": digest}, true)
					_store(file, "college", row)
			_manifest["outputs"]["college"]["games"] += 1
		print("OVR college %s source population %d/2" % [_range, cluster + 1])
	_finish_raw(file, "college")


func _histograms() -> void:
	var fixture_rows: Array[Dictionary] = []
	for competition in CalibrationTargets.all_competitions():
		for variation in range(CompetitionCatalog.ROSTER_VARIATION_PERIOD):
			var team: TeamMatchProfile = CompetitionCatalog.team_for(competition, &"histogram", variation,
				CompetitionCatalog.balance_profile())
			for player in team.players:
				fixture_rows.append({"competition": String(CalibrationTargets.competition_id(competition)),
					"roster_variation": variation, "player_id": String(player.player_id), "position": String(player.positions.primary),
					"rotation_role": String(RotationRole.id_of(player.rotation_role)), "tactical_role": String(player.tactical_role.id()),
					"values": player.attributes.canonical_values(), "current_ovr": OverallCalculator.current_overall(
						player.attributes, CompetitionCatalog.ratings_profile())})
	var careers: int = CalibrationCli.int_option(_options, &"careers", 1000)
	assert(_range == "smoke" or careers == 1000, "confirmation cannot override frozen natural histogram sample")
	var simulator := CareerSimulator.new()
	simulator.capture_diagnostics = true
	var natural_rows: Array[Dictionary] = []
	for index in range(careers):
		var seed_value: int = 9860001 + _offset + index
		var career: CareerSimulator.CareerResult = simulator.simulate(seed_value, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)
		natural_rows.append({"career_seed": seed_value, "family": String(PositionFamily.id_of(career.family)),
			"prospect": String(ProspectProfile.id_of(career.prospect)), "path": String(CareerSimulator.path_id(career.path)),
			"maturity": String(MaturityProfile.id_of(career.maturity)), "starting_current": career.starting_overall,
			"starting_values": career.starting_values, "exact_caps": career.starting_caps.values(),
			"maximum_potential": career.maximum_potential, "college_values": career.college_values_by_class,
			"college_current": Array(career.college_overall_by_class), "college_ages": Array(career.college_age_by_class),
			"peak_current": career.peak_overall, "peak_age": career.peak_age, "peak_values": career.peak_values,
			"final_current": career.final_overall, "final_values": career.final_state.attributes.canonical_values(),
			"final_age": career.final_state.age, "all_season_current": Array(career.overall_by_season),
			"all_season_ages": Array(career.age_by_season)})
		if (index + 1) % 100 == 0: print("OVR natural histogram %s %d/%d" % [_range, index + 1, careers])
	_write_json("histograms", {"version": OvrTruthfulnessAudit.VERSION, "range": _range,
		"fixture_rows": fixture_rows, "natural_rows": natural_rows,
		"mature_world_rarity_tested": false, "potential_is_attainment_prediction": false})
	_manifest["outputs"]["histograms"] = {"fixture_players": fixture_rows.size(), "natural_careers": natural_rows.size(),
		"path": "res://reports/ovr_histograms_%s.json" % _label,
		"sha256": FileAccess.get_sha256("res://reports/ovr_histograms_%s.json" % _label)}
