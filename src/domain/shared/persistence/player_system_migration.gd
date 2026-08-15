class_name PlayerSystemMigration
extends RefCounted

## Deterministic migrations for the player-system persisted schema
## (`GODOT_TDD.md` §5.7, §10.5; `BALANCE_SPEC.md` §7.4.4, §29.3).
##
## Stage 2 changed three persisted shapes, and each needs a migration rather
## than a reinterpretation:
##
##   1. `BodyProfile` gained `standing_reach_inches` (schema 1 -> 2).
##   2. `RotationRole` replaced `STARTER/ROTATION/LIMITED/EMERGENCY/DNP` with
##      the seven locked usage-intent IDs. The old enum mixed usage intent with
##      availability facts (`BALANCE_SPEC.md` §29.2 item 7).
##   3. `TacticalRole` replaced an unconstrained string, defaulting to
##      `balanced`, with the eleven locked IDs (§29.2 item 6).
##
## ## Rules these migrations obey
##
## - **Never silently reinterpret an existing save.** Every conversion is
##   recorded in the returned `notes`, and a value that cannot be mapped is
##   reported rather than guessed.
## - **Hidden fractional progress is preserved** (§29.3, §5.7). Direct progress
##   and decline debt pass through untouched.
## - **A migration may never resolve a growth increment, spend AP, or change a
##   cap as a side effect** (§5.7).
## - **A lost projected body range is reconstructed at its widest**, never
##   narrowed around the realized value to fabricate precision (§7.4.4).

const CURRENT_SCHEMA_VERSION: int = 2

## The legacy rotation values, in their old ordinal order.
const LEGACY_ROTATION_IDS: PackedStringArray = [
	"STARTER", "ROTATION", "LIMITED", "EMERGENCY", "DNP",
]


## Result of migrating one record.
class Result extends RefCounted:
	var record: Dictionary
	var notes: PackedStringArray
	var migrated: bool

	func _init(p_record: Dictionary, p_notes: PackedStringArray, p_migrated: bool) -> void:
		record = p_record
		notes = p_notes
		migrated = p_migrated


## Migrate one persisted player record to the current schema.
##
## Takes and returns a plain `Dictionary` because the persistence layer does not
## exist yet: infrastructure will supply these rows from SQLite. Keeping the
## migration at the record level means it can be tested exhaustively now,
## without a database.
static func migrate_player_record(source: Dictionary) -> Result:
	var record: Dictionary = source.duplicate(true)
	var notes: PackedStringArray = []

	var version: int = 1
	if record.has("schema_version"):
		var stored_version: int = record["schema_version"]
		version = stored_version

	if version >= CURRENT_SCHEMA_VERSION:
		return Result.new(record, notes, false)

	_migrate_body(record, notes)
	_migrate_rotation_role(record, notes)
	_migrate_tactical_role(record, notes)
	_migrate_projected_range(record, notes)
	_verify_hidden_fractions_preserved(source, record, notes)

	record["schema_version"] = CURRENT_SCHEMA_VERSION
	notes.append("schema %d -> %d" % [version, CURRENT_SCHEMA_VERSION])
	return Result.new(record, notes, true)


## Schema 1 stored height, weight, and wingspan only. Standing reach is derived
## from the two dimensions that determine it, which is the only recoverable
## answer — the measurement was never taken.
static func _migrate_body(record: Dictionary, notes: PackedStringArray) -> void:
	for key: String in ["body", "confirmed_freshman_body", "realized_body"]:
		if not record.has(key):
			continue
		var body: Dictionary = record[key]
		if body.has("standing_reach_inches"):
			var existing: int = body["standing_reach_inches"]
			if existing > 0:
				continue
		var height: int = body["height_inches"]
		var wingspan: int = body["wingspan_inches"]
		var reach: int = BodyProfile.derive_standing_reach(height, wingspan)
		body["standing_reach_inches"] = reach
		record[key] = body
		notes.append("%s: derived standing reach %d from height %d and wingspan %d" % [
			key, reach, height, wingspan])


## The old enum conflated usage intent with availability. The mapping keeps the
## intent and discards nothing: availability facts were never recoverable from
## the old value, so `EMERGENCY` and `DNP` map to the nearest *intent* and the
## note records that the availability reading was dropped rather than
## reinterpreted as a demotion.
##
## §10.6.1: "A Starter who does not play remains a Starter; the engine records a
## DNP, not a demotion."
static func _migrate_rotation_role(record: Dictionary, notes: PackedStringArray) -> void:
	if not record.has("rotation_role"):
		return
	var legacy: String = str(record["rotation_role"]).to_upper()
	var mapped: int = RotationRole.Value.ROTATION
	match legacy:
		"STARTER":
			mapped = RotationRole.Value.STARTER
		"ROTATION":
			mapped = RotationRole.Value.ROTATION
		"LIMITED":
			mapped = RotationRole.Value.BENCH
		"EMERGENCY":
			mapped = RotationRole.Value.RESERVE
		"DNP":
			# DNP is an availability outcome, not a usage intent. The old value
			# carries no recoverable intent, so the migration assigns the
			# neutral role and says so rather than inventing a demotion.
			mapped = RotationRole.Value.RESERVE
			notes.append(
				"rotation_role DNP was an availability fact, not a usage intent;"
				+ " assigned 'reserve' and dropped the availability reading")
		_:
			notes.append(
				"rotation_role '%s' is not a recognised legacy value; assigned 'rotation'"
					% legacy)
	record["rotation_role"] = String(RotationRole.id_of(mapped))
	if legacy != "DNP":
		notes.append("rotation_role %s -> %s" % [legacy, RotationRole.id_of(mapped)])


## The old default `balanced` is not one of the eleven roles at all. It maps to
## `utility_energy`, the flexible-assignment role, which is the closest honest
## reading of "no particular job".
static func _migrate_tactical_role(record: Dictionary, notes: PackedStringArray) -> void:
	if not record.has("tactical_role"):
		return
	var legacy: String = str(record["tactical_role"])
	for role in TacticalRole.all():
		if String(TacticalRole.id_of(role)) == legacy:
			return
	record["tactical_role"] = String(TacticalRole.id_of(TacticalRole.Value.UTILITY_ENERGY))
	notes.append(
		"tactical_role '%s' is not one of the eleven locked roles; assigned 'utility_energy'"
			% legacy)


## §7.4.4 / §5.7: "Any migration that cannot recover a stored projected range
## must reconstruct the widest range consistent with the realized body and
## record the limitation, never narrow a range around the realized value to
## fabricate precision."
static func _migrate_projected_range(record: Dictionary, notes: PackedStringArray) -> void:
	if record.has("projected_adult_range"):
		return
	if not record.has("realized_body"):
		return

	var body: Dictionary = record["realized_body"]
	var height: int = body["height_inches"]
	var weight: int = body["weight_pounds"]
	var wingspan: int = body["wingspan_inches"]
	var reach: int = body["standing_reach_inches"]
	var realized: BodyProfile = BodyProfile.new(height, weight, wingspan, reach)
	var reconstructed: BodyRange = BodyRange.widest_consistent_with(
		realized,
		RECONSTRUCTION_HEIGHT_SLACK,
		RECONSTRUCTION_WEIGHT_SLACK,
		RECONSTRUCTION_WINGSPAN_SLACK,
		RECONSTRUCTION_REACH_SLACK
	)
	record["projected_adult_range"] = {
		"height": [reconstructed.height_minimum, reconstructed.height_maximum],
		"weight": [reconstructed.weight_minimum, reconstructed.weight_maximum],
		"wingspan": [reconstructed.wingspan_minimum, reconstructed.wingspan_maximum],
		"standing_reach": [
			reconstructed.standing_reach_minimum,
			reconstructed.standing_reach_maximum,
		],
	}
	record["projected_range_reconstructed"] = true
	notes.append(
		"stored projected adult range was unrecoverable; reconstructed at its widest"
		+ " consistent with the realized body and flagged as reconstructed")


## §29.3 and §5.7: hidden fractional progress survives migrations. This does not
## transform anything — it verifies that nothing above dropped it, and reports
## if it did. A migration that silently reset a progress bar would be invisible
## in play and irreversible in a save.
static func _verify_hidden_fractions_preserved(
	source: Dictionary,
	record: Dictionary,
	notes: PackedStringArray,
) -> void:
	for key: String in ["direct_progress", "decline_debt"]:
		if not source.has(key):
			continue
		if not record.has(key):
			notes.append("ERROR: %s was lost during migration" % key)
			continue
		var before: Array = source[key]
		var after: Array = record[key]
		if before.size() != after.size():
			notes.append("ERROR: %s changed length during migration" % key)
			continue
		for index in range(before.size()):
			var before_value: float = before[index]
			var after_value: float = after[index]
			if not is_equal_approx(before_value, after_value):
				notes.append("ERROR: %s[%d] changed during migration" % [key, index])


## Slack used when reconstructing a lost projected adult range. Wide on purpose:
## §7.4.4 prefers an uninformative range to a fabricated one.
const RECONSTRUCTION_HEIGHT_SLACK: int = 8
const RECONSTRUCTION_WEIGHT_SLACK: int = 70
const RECONSTRUCTION_WINGSPAN_SLACK: int = 9
const RECONSTRUCTION_REACH_SLACK: int = 11
