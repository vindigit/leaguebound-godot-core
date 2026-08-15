class_name TestOverallExclusion
extends GdUnitTestSuite

## Overall-exclusion dependency check (`GODOT_TDD.md` §13.2, §18 item 11;
## `BALANCE_SPEC.md` §6.2, §28; PRD BUILD-011).
##
## §6.2: "**Overall is never a simulation input.** No resolution path — shot,
## pass, defense, rebound, foul, rotation, matchup, or Tier B aggregation — may
## read Current Overall, Maximum Potential Overall, or Projected Peak... A
## dependency check enforcing this is a release blocker."
##
## §28 lists two release blockers this suite covers directly: "Any resolution
## path reads Current Overall, Maximum Potential Overall, or Projected Peak as a
## simulation input", and "A derived archetype grants any capability,
## opportunity, attribute, or probability."
##
## The check reads the simulation sources rather than trusting convention,
## because a convention is exactly what drifts.

## Directories whose contents resolve basketball. Anything here is a resolution
## path in the sense §6.2 means.
const RESOLUTION_ROOTS: PackedStringArray = [
	"res://src/domain/basketball/simulation",
	"res://src/domain/basketball/projections",
	"res://src/domain/basketball/results",
	"res://src/domain/basketball/events",
]

## Symbols a resolution path may never name.
const FORBIDDEN_SYMBOLS: PackedStringArray = [
	"OverallCalculator",
	"DevelopmentProjection",
	"ProjectedPeakCalculator",
	"DerivedArchetype",
	"OverallRange",
	"current_overall",
	"maximum_potential",
	"projected_peak",
	"archetype",
]


func test_no_resolution_path_reads_a_development_projection() -> void:
	var offences: PackedStringArray = []
	for root in RESOLUTION_ROOTS:
		_scan(root, offences)
	assert_array(offences).is_empty()


## The player-system domain types must not leak Overall into the match profile
## either. `SIMULATION_SPEC.md` §6 lists what the engine receives, and none of
## the three development values is on it.
func test_the_match_profile_carries_no_development_value() -> void:
	var profile: PlayerMatchProfile = PlayerMatchProfile.new(&"p1")
	for property: Dictionary in profile.get_property_list():
		var property_name: String = property["name"]
		var name: String = property_name.to_lower()
		for forbidden: String in ["overall", "potential", "projected", "archetype"]:
			assert_str(name).not_contains(forbidden)


## §5.5 rule 1: Overall is derived, never stored as authority. No persisted
## player-system fact may be one of the three values.
func test_no_persisted_state_stores_a_development_value() -> void:
	var state: PlayerDevelopmentState = _minimal_state()
	for property: Dictionary in state.get_property_list():
		var property_name: String = property["name"]
		var name: String = property_name.to_lower()
		for forbidden: String in ["overall", "potential", "projected_peak", "archetype"]:
			assert_str(name).not_contains(forbidden)


## §12.4: no capability may take rotation role, tactical role, or derived
## archetype as an input. "Identity layers reach opportunity, never capability."
func test_no_capability_reads_an_identity_layer() -> void:
	var source: String = _read("res://src/domain/basketball/simulation/capability_calculator.gd")
	for forbidden: String in ["tactical_role", "rotation_role", "archetype"]:
		assert_str(source).not_contains(forbidden)


func _scan(path: String, offences: PackedStringArray) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var full: String = "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_scan(full, offences)
		elif entry.ends_with(".gd"):
			_inspect(full, offences)
		entry = directory.get_next()
	directory.list_dir_end()


func _inspect(path: String, offences: PackedStringArray) -> void:
	var source: String = _read(path)
	var lines: PackedStringArray = source.split("\n")
	for index in range(lines.size()):
		var line: String = lines[index]
		var trimmed: String = line.strip_edges()
		# Comments are documentation, not dependencies. A file may explain why
		# it does not read Overall.
		if trimmed.begins_with("#"):
			continue
		for symbol in FORBIDDEN_SYMBOLS:
			if line.contains(symbol):
				offences.append("%s:%d reads '%s'" % [path, index + 1, symbol])


func _read(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_object(file).is_not_null()
	var source: String = file.get_as_text()
	file.close()
	return source


func _minimal_state() -> PlayerDevelopmentState:
	var values: Array[int] = []
	var caps: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		values.append(50)
		caps.append(80)
	var body: BodyProfile = BodyProfile.new(76, 190, 78, 0)
	return PlayerDevelopmentState.new(
		&"p1",
		PlayerAttributes.from_values(values),
		AttributeCaps.new(caps),
		BodyMaturationState.new(
			body,
			MaturityProfile.Value.AVERAGE,
			BodyRange.new(
				78, 84, 215, 260, 80, 87,
				body.standing_reach_inches + 4, body.standing_reach_inches + 14)
		),
		ProspectProfile.Value.BALANCED,
		PositionFamily.Value.WING,
		1,
		"test"
	)
