class_name TestPlayerModel
extends GdUnitTestSuite

## Canonical model, validation, serialization, and migration suite
## (`GODOT_TDD.md` §5.5, §5.7, §13.2).


## `BALANCE_SPEC.md` §29.1 item 1: all twenty canonical attributes exist exactly
## once, with stable IDs.
func test_all_twenty_attributes_exist_exactly_once() -> void:
	assert_int(AttributeKey.COUNT).is_equal(20)
	assert_int(AttributeKey.NAMES.size()).is_equal(20)

	var seen: Dictionary = {}
	for key in AttributeKey.all():
		var name: StringName = AttributeKey.name_of(key)
		assert_bool(seen.has(name)).is_false()
		seen[name] = true
	assert_int(seen.size()).is_equal(20)


## The twenty IDs are stable. `GDD.md` §6.3 lists them; a reordering of the enum
## must not silently change a save, so the IDs are asserted literally.
func test_attribute_ids_are_stable() -> void:
	var expected: PackedStringArray = [
		"short_range", "dunking", "mid_range", "three_point", "free_throw",
		"handle", "passing", "vision", "offensive_iq", "perimeter_defense",
		"interior_defense", "stealing", "blocking", "defensive_iq",
		"offensive_rebounding", "defensive_rebounding", "speed", "strength",
		"stamina", "vertical",
	]
	for index in range(expected.size()):
		assert_str(String(AttributeKey.name_of(index))).is_equal(expected[index])


## Serialization names every attribute by its stable ID and round-trips.
func test_attribute_serialization_is_stable() -> void:
	var values: Array[int] = []
	for index in range(AttributeKey.COUNT):
		values.append(30 + index * 3)
	var attributes: PlayerAttributes = PlayerAttributes.from_values(values)

	var signature: String = attributes.signature()
	for key in AttributeKey.all():
		assert_str(signature).contains(
			"%s=%d" % [AttributeKey.name_of(key), values[key]])

	assert_array(attributes.duplicate_attributes().canonical_values()).is_equal(values)


## `BALANCE_SPEC.md` §5: active ratings are whole numbers from 25 through 99,
## and a value below 25 "is reserved for non-player placeholders and cannot
## appear on an active basketball player".
func test_rating_domain_is_enforced() -> void:
	assert_bool(Rating.is_valid_active(24)).is_false()
	assert_bool(Rating.is_valid_active(25)).is_true()
	assert_bool(Rating.is_valid_active(99)).is_true()
	assert_bool(Rating.is_valid_active(100)).is_false()

	assert_float(Rating.normalized(25)).is_equal(0.0)
	assert_float(Rating.normalized(99)).is_equal(1.0)


func test_a_sub_active_rating_is_rejected() -> void:
	await assert_error(func() -> void:
		var _attributes: PlayerAttributes = PlayerAttributes.new(24)
	).is_runtime_error(
		"Assertion failed: short_range must be a whole-number active-player rating"
		+ " from 25 through 99")


## §8: every cap lies between 40 and 99.
func test_cap_domain_is_enforced() -> void:
	var caps: Array[int] = []
	for _index in range(AttributeKey.COUNT):
		caps.append(39)
	await assert_error(func() -> void:
		var _model: AttributeCaps = AttributeCaps.new(caps)
	).is_runtime_error(
		"Assertion failed: cap for short_range must lie between 40 and 99")


## §8.3: caps are immutable values. A cap change produces a new instance rather
## than editing one a caller already holds.
func test_caps_are_immutable() -> void:
	var caps: AttributeCaps = AttributeCaps.new()
	var original: String = caps.signature()
	var updated: AttributeCaps = caps.with_cap(AttributeKey.Key.HANDLE, 55)
	assert_str(caps.signature()).is_equal(original)
	assert_int(updated.cap_for(AttributeKey.Key.HANDLE)).is_equal(55)


## `SIMULATION_SPEC.md` §6.1 / `GODOT_TDD.md` §5.5: `BodyProfile` carries
## standing reach. §29.2 item 5 recorded its absence as a gap.
func test_body_profile_carries_standing_reach() -> void:
	var body: BodyProfile = BodyProfile.new(78, 210, 82, 0)
	assert_int(body.standing_reach_inches).is_greater(body.height_inches)
	assert_int(BodyProfile.SCHEMA_VERSION).is_equal(2)


## Standing reach never falls as height or wingspan rises.
##
## Monotone *non-decreasing* is the exact property `BodyMaturationPlanner` needs:
## it derives the projected reach bounds from the corners of the height/wingspan
## box, and that is only sound if no interior pair can produce a reach outside
## them. Strict increase per single inch does not hold and is not required —
## the shares are fractional, so a one-inch step can round to the same integer.
func test_standing_reach_never_falls_as_height_or_wingspan_rises() -> void:
	for height in range(BodyProfile.MINIMUM_HEIGHT_INCHES, 90):
		for wingspan in range(height - 2, height + 10):
			var base: int = BodyProfile.derive_standing_reach(height, wingspan)
			assert_int(BodyProfile.derive_standing_reach(height + 1, wingspan))\
				.is_greater_equal(base)
			assert_int(BodyProfile.derive_standing_reach(height, wingspan + 1))\
				.is_greater_equal(base)


## Over a real growth span the increase is strict, so reach is not a constant
## dressed up as a derivation.
func test_standing_reach_rises_across_a_growth_span() -> void:
	var freshman: int = BodyProfile.derive_standing_reach(72, 74)
	var adult: int = BodyProfile.derive_standing_reach(78, 82)
	assert_int(adult).is_greater(freshman)


## §5.7 / §29.3: hidden fractional progress is preserved across migrations.
func test_migration_preserves_hidden_fractional_progress() -> void:
	var progress: Array = [0.5, 1.25, 0.0]
	var record: Dictionary = {
		"schema_version": 1,
		"body": {"height_inches": 76, "weight_pounds": 190, "wingspan_inches": 78},
		"direct_progress": progress.duplicate(),
		"decline_debt": [0.125],
	}
	var result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(record)

	assert_bool(result.migrated).is_true()
	assert_array(result.record["direct_progress"]).is_equal(progress)
	assert_array(result.record["decline_debt"]).is_equal([0.125])
	assert_str(", ".join(result.notes)).not_contains("ERROR")


## §5.7: a migration may never resolve a growth increment, spend AP, or change a
## cap as a side effect.
func test_migration_has_no_side_effects_on_caps_or_currency() -> void:
	var caps: Array = [80, 81, 82]
	var record: Dictionary = {
		"schema_version": 1,
		"body": {"height_inches": 76, "weight_pounds": 190, "wingspan_inches": 78},
		"caps": caps.duplicate(),
		"ap_balance": 12.0,
		"resolved_growth_increments": 2,
	}
	var result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(record)

	assert_array(result.record["caps"]).is_equal(caps)
	assert_float(result.record["ap_balance"]).is_equal(12.0)
	assert_int(result.record["resolved_growth_increments"]).is_equal(2)


## Schema 1 records gain a derived standing reach; already-current records are
## left alone.
func test_migration_derives_standing_reach_only_when_missing() -> void:
	var record: Dictionary = {
		"schema_version": 1,
		"body": {"height_inches": 76, "weight_pounds": 190, "wingspan_inches": 78},
	}
	var result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(record)
	var reach: int = result.record["body"]["standing_reach_inches"]
	assert_int(reach).is_equal(BodyProfile.derive_standing_reach(76, 78))
	assert_str(", ".join(result.notes)).contains("derived standing reach")

	var current: Dictionary = {
		"schema_version": PlayerSystemMigration.CURRENT_SCHEMA_VERSION,
		"body": {
			"height_inches": 76, "weight_pounds": 190,
			"wingspan_inches": 78, "standing_reach_inches": 101,
		},
	}
	var untouched: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(
		current)
	assert_bool(untouched.migrated).is_false()
	assert_int(untouched.record["body"]["standing_reach_inches"]).is_equal(101)


## A migration never silently reinterprets a save: every conversion is reported.
func test_migration_reports_every_conversion() -> void:
	var record: Dictionary = {
		"schema_version": 1,
		"body": {"height_inches": 76, "weight_pounds": 190, "wingspan_inches": 78},
		"rotation_role": "LIMITED",
		"tactical_role": "balanced",
	}
	var result: PlayerSystemMigration.Result = PlayerSystemMigration.migrate_player_record(record)
	var notes: String = ", ".join(result.notes)
	assert_str(notes).contains("rotation_role")
	assert_str(notes).contains("tactical_role")
	assert_str(notes).contains("schema 1 -> 2")
	var migrated_tactical: String = result.record["tactical_role"]
	assert_str(migrated_tactical).is_equal("utility_energy")


## §9.5: the receipt book refuses a duplicate claim rather than crashing —
## a reload or level change is an ordinary event.
func test_receipts_decline_duplicates_quietly() -> void:
	var receipts: CareerYearReceipts = CareerYearReceipts.new()
	assert_bool(receipts.claim(1, CareerYearReceipts.Resolution.AGE_INCREASE)).is_true()
	assert_bool(receipts.claim(1, CareerYearReceipts.Resolution.AGE_INCREASE)).is_false()
	# A different year and a different resolution are both still available.
	assert_bool(receipts.claim(2, CareerYearReceipts.Resolution.AGE_INCREASE)).is_true()
	assert_bool(receipts.claim(
		1, CareerYearReceipts.Resolution.PROFESSIONAL_SERVICE)).is_true()
