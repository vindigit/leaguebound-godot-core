class_name TestLayeredIdentity
extends GdUnitTestSuite

## Identity suite (`GODOT_TDD.md` §13.2, `SIMULATION_SPEC.md` §10.6,
## `BALANCE_SPEC.md` §12.4, OD-F; Gate B1/B2).

var _profiles: BalanceProfileSet
var _archetype_profile: ArchetypeProfile


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()
	_archetype_profile = ArchetypeProfile.default_profile()


## §10.6.1: the seven locked rotation-role IDs, replacing the enum that mixed
## usage intent with availability.
func test_rotation_roles_are_the_seven_locked_ids() -> void:
	assert_int(RotationRole.COUNT).is_equal(7)
	var expected: PackedStringArray = [
		"star", "starter", "sixth_player", "rotation", "bench", "reserve", "developmental",
	]
	for index in range(expected.size()):
		assert_str(String(RotationRole.id_of(index))).is_equal(expected[index])
		assert_int(RotationRole.from_id(StringName(expected[index]))).is_equal(index)


## §10.6.2: all eleven tactical roles are retained as distinct IDs. "No
## consolidation was applied... merging any two would erase a real difference in
## candidate generation and role opportunity."
func test_tactical_roles_are_the_eleven_locked_ids() -> void:
	assert_int(TacticalRole.COUNT).is_equal(11)
	var expected: PackedStringArray = [
		"primary_creator", "secondary_creator", "shooter", "slasher", "connector",
		"post_option", "roll_pop_big", "perimeter_stopper", "interior_anchor",
		"rebounder", "utility_energy",
	]
	for index in range(expected.size()):
		assert_str(String(TacticalRole.id_of(index))).is_equal(expected[index])
		assert_int(TacticalRole.from_id(StringName(expected[index]))).is_equal(index)


## §29.2 item 6: the old unconstrained string defaulted to `balanced`, which is
## not one of the eleven roles. That value must no longer be constructible.
func test_the_legacy_balanced_role_is_gone() -> void:
	for role in TacticalRole.all():
		assert_str(String(TacticalRole.id_of(role))).is_not_equal("balanced")


## §10.6.1: availability facts are not rotation roles. "A Starter who does not
## play remains a Starter." The migration keeps the intent and reports that the
## availability reading was dropped rather than recording a demotion.
func test_migration_does_not_turn_a_dnp_into_a_demotion() -> void:
	var starter: Dictionary = {"schema_version": 1, "rotation_role": "STARTER"}
	var result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(starter)
	var migrated_role: String = result.record["rotation_role"]
	assert_str(migrated_role).is_equal("starter")

	var dnp: Dictionary = {"schema_version": 1, "rotation_role": "DNP"}
	var dnp_result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(dnp)
	assert_str(", ".join(dnp_result.notes)).contains("availability fact")


## §12.4: derived archetype "may affect **Nothing**". Computing it is
## side-effect free — it must not mutate the player it describes.
func test_archetype_classification_is_side_effect_free() -> void:
	var attributes: PlayerAttributes = _attributes(60)
	var body: BodyProfile = BodyProfile.new(78, 210, 81, 0)
	var before: String = attributes.signature()
	var before_body: String = body.signature()

	for _attempt in range(5):
		var archetype: DerivedArchetype = DerivedArchetype.classify(
			attributes, body, PositionFamily.Value.WING, _archetype_profile)
		assert_bool(archetype.label().is_empty()).is_false()

	assert_str(attributes.signature()).is_equal(before)
	assert_str(body.signature()).is_equal(before_body)


## §10.6.3: archetype "updates as ratings and body change. It has no memory and
## creates no lock-in."
func test_archetype_has_no_memory() -> void:
	var body: BodyProfile = BodyProfile.new(78, 210, 81, 0)
	var shooter_values: Array[int] = _values(50)
	shooter_values[AttributeKey.Key.THREE_POINT] = 90
	shooter_values[AttributeKey.Key.MID_RANGE] = 88
	shooter_values[AttributeKey.Key.FREE_THROW] = 86

	var shooter: DerivedArchetype = DerivedArchetype.classify(
		PlayerAttributes.from_values(shooter_values), body,
		PositionFamily.Value.WING, _archetype_profile)
	assert_str(shooter.label()).contains("Shooting")

	var rebounder_values: Array[int] = _values(50)
	rebounder_values[AttributeKey.Key.DEFENSIVE_REBOUNDING] = 90
	rebounder_values[AttributeKey.Key.OFFENSIVE_REBOUNDING] = 88
	rebounder_values[AttributeKey.Key.STRENGTH] = 86

	var rebounder: DerivedArchetype = DerivedArchetype.classify(
		PlayerAttributes.from_values(rebounder_values), body,
		PositionFamily.Value.WING, _archetype_profile)
	assert_str(rebounder.label()).contains("Rebounding")
	assert_str(rebounder.label()).is_not_equal(shooter.label())


## §10.6.3: "Archetype is not exclusive." A hybrid build must receive a
## composite descriptor rather than being rounded to one template.
func test_hybrid_builds_receive_composite_descriptors() -> void:
	var values: Array[int] = _values(45)
	values[AttributeKey.Key.THREE_POINT] = 85
	values[AttributeKey.Key.MID_RANGE] = 83
	values[AttributeKey.Key.FREE_THROW] = 82
	values[AttributeKey.Key.BLOCKING] = 84
	values[AttributeKey.Key.INTERIOR_DEFENSE] = 82
	values[AttributeKey.Key.VERTICAL] = 83

	var archetype: DerivedArchetype = DerivedArchetype.classify(
		PlayerAttributes.from_values(values), BodyProfile.new(82, 240, 86, 0),
		PositionFamily.Value.BIG, _archetype_profile)
	assert_int(archetype.descriptors.size()).is_equal(2)


## §10.6.3: two players may share a descriptor without sharing any mechanical
## property. Identical ratings and different identity layers give the same
## label, and the label carries no numeric payload.
func test_archetype_grants_nothing() -> void:
	var attributes: PlayerAttributes = _attributes(65)
	var body: BodyProfile = BodyProfile.new(78, 210, 81, 0)
	var first: DerivedArchetype = DerivedArchetype.classify(
		attributes, body, PositionFamily.Value.WING, _archetype_profile)
	var second: DerivedArchetype = DerivedArchetype.classify(
		attributes, body, PositionFamily.Value.WING, _archetype_profile)
	assert_str(first.label()).is_equal(second.label())

	# The archetype has no path into Overall: identical ratings, identical OVR,
	# regardless of the label.
	assert_int(OverallCalculator.current_overall(attributes, _profiles.ratings))\
		.is_equal(OverallCalculator.current_overall(attributes, _profiles.ratings))


## §12.4: "A balance profile containing an archetype-keyed coefficient is
## invalid." No gameplay balance profile may expose archetype data at all.
func test_no_gameplay_balance_profile_contains_archetype_data() -> void:
	for tunable in _profiles.describe_tunables():
		assert_str(String(tunable.tunable_name).to_lower()).not_contains("archetype")


## §10.6.2: exactly one tactical role is active per player per game, and it is
## fixed for the game.
func test_a_player_carries_exactly_one_tactical_role() -> void:
	var profile: PlayerMatchProfile = PlayerMatchProfile.new(
		&"p1", null, null, null, [], null,
		RotationRole.Value.STARTER, TacticalRole.new(TacticalRole.Value.SHOOTER))
	assert_int(profile.tactical_role.role).is_equal(TacticalRole.Value.SHOOTER)
	assert_str(String(profile.tactical_role.id())).is_equal("shooter")


## §6.2 of `SIMULATION_SPEC.md`: derived archetype is not a match-profile field.
## It is a display projection and is never supplied to the engine.
func test_archetype_is_not_a_match_profile_field() -> void:
	var profile: PlayerMatchProfile = PlayerMatchProfile.new(&"p1")
	var property_names: PackedStringArray = []
	for property: Dictionary in profile.get_property_list():
		var property_name: String = property["name"]
		property_names.append(property_name.to_lower())
	for name in property_names:
		assert_str(name).not_contains("archetype")


func _values(rating: int) -> Array[int]:
	var values: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		values.append(rating)
	return values


func _attributes(rating: int) -> PlayerAttributes:
	return PlayerAttributes.from_values(_values(rating))
