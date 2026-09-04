class_name ReportContext
extends RefCounted

## The provenance block every calibration report must carry.
##
## The Stage 4 brief fixes the list: commit SHA, Godot version and build mode,
## rules profile and version, balance profile and version, RNG algorithm and
## version, seed or seed range, sample count, elapsed time and throughput.
## Building it here rather than in each runner is what stops one report from
## quietly omitting the field that would have explained a discrepancy.
##
## The commit SHA is read from `.git` directly rather than by shelling out, so a
## report is reproducible on a machine with no git binary on PATH and the
## harness never depends on a developer's local environment.

var report_id: StringName
var title: String
var commit_sha: String
var commit_dirty_note: String
var godot_version: String
var build_mode: String
var rules_profile_id: StringName
var rules_profile_version: StringName
var balance_profile_id: StringName
var balance_profile_version: StringName
var ratings_profile_version: StringName
var targets_version: StringName
var rng_algorithm: StringName
var rng_stream_key_version: StringName
var seed_description: String
## The seed interval this run consumed, inclusive. The aggregator uses these to
## reject overlapping shards: two shards that share a seed have simulated the
## same games twice, and summing them would inflate the sample without adding
## any information. A free-text seed description cannot be checked, so the
## interval is carried structurally beside it.
var seed_start: int
var seed_end: int
## Which shard of how many. `shard_count` is the number the aggregator will
## require to be present before it certifies anything.
var shard_index: int
var shard_count: int
## The competition this run measured, or empty when the report is not
## per-competition. Shards of different competitions are never combined.
var competition_id: StringName
## The Â§27.1 sample this report's owning requirement asks for, in `sample_unit`,
## and the section that owns it. Zero means no certification requirement.
var certification_sample_required: int
var certification_source: String
var sample_count: int
var sample_unit: String
var elapsed_ms: int
var notes: PackedStringArray

var _started_us: int


static func create(
	p_report_id: StringName,
	p_title: String,
	rules: CompetitionRuleProfile,
	balance: SimulationBalanceProfile,
	rng_version: StringName,
	ratings: RatingsProfile = null,
) -> ReportContext:
	var context := ReportContext.new()
	context.report_id = p_report_id
	context.title = p_title
	context.commit_sha = _read_commit_sha()
	context.commit_dirty_note = ""
	context.godot_version = Engine.get_version_info().get("string", "unknown")
	context.build_mode = _build_mode()
	context.rules_profile_id = rules.profile_id if rules != null else &"n/a"
	context.rules_profile_version = rules.version if rules != null else &"n/a"
	context.balance_profile_id = balance.profile_id if balance != null else &"n/a"
	context.balance_profile_version = balance.version if balance != null else &"n/a"
	var ratings_profile: RatingsProfile = (
		ratings if ratings != null else RatingsProfile.default_profile())
	context.ratings_profile_version = ratings_profile.version
	context.targets_version = CalibrationTargets.VERSION
	context.rng_algorithm = rng_version
	context.rng_stream_key_version = RandomStreamKey.VERSION
	context.seed_description = "unspecified"
	context.seed_start = 0
	context.seed_end = 0
	context.shard_index = 0
	context.shard_count = 1
	context.competition_id = &""
	context.certification_sample_required = 0
	context.certification_source = ""
	context.sample_count = 0
	context.sample_unit = "samples"
	context.elapsed_ms = 0
	context.notes = PackedStringArray()
	context._started_us = Time.get_ticks_usec()
	return context


## Records the shard's identity and its inclusive seed interval, and writes the
## human-readable description from them so the two cannot disagree.
func set_shard(
	p_shard_index: int,
	p_shard_count: int,
	p_seed_start: int,
	p_seed_end: int,
) -> void:
	assert(p_shard_count >= 1, "a run is at least one shard")
	assert(p_shard_index >= 0 and p_shard_index < p_shard_count, "shard index out of range")
	assert(p_seed_end >= p_seed_start, "a seed interval must be ordered")
	shard_index = p_shard_index
	shard_count = p_shard_count
	seed_start = p_seed_start
	seed_end = p_seed_end
	seed_description = "shard %d of %d, seeds %d..%d inclusive" % [
		p_shard_index, p_shard_count, p_seed_start, p_seed_end]


func require_certification_sample(required: int, source: String) -> void:
	certification_sample_required = required
	certification_source = source


func finish() -> void:
	elapsed_ms = int((Time.get_ticks_usec() - _started_us) / 1000)


func throughput_per_second() -> float:
	if elapsed_ms <= 0:
		return 0.0
	return float(sample_count) * 1000.0 / float(elapsed_ms)


func to_dictionary() -> Dictionary:
	return {
		"report_id": String(report_id),
		"title": title,
		"commit_sha": commit_sha,
		"commit_note": commit_dirty_note,
		"godot_version": godot_version,
		"build_mode": build_mode,
		"rules_profile": {
			"id": String(rules_profile_id),
			"version": String(rules_profile_version),
		},
		"balance_profile": {
			"id": String(balance_profile_id),
			"version": String(balance_profile_version),
		},
		"ratings_profile_version": String(ratings_profile_version),
		"targets_version": String(targets_version),
		"rng": {
			"algorithm": String(rng_algorithm),
			"stream_key_version": String(rng_stream_key_version),
		},
		"seeds": seed_description,
		"seed_range": {"start": seed_start, "end": seed_end},
		"shard": {"index": shard_index, "count": shard_count},
		"competition": String(competition_id),
		"certification": {
			"required_sample": certification_sample_required,
			"source": certification_source,
		},
		"sample_count": sample_count,
		"sample_unit": sample_unit,
		"elapsed_ms": elapsed_ms,
		"throughput_per_second": throughput_per_second(),
		"notes": notes,
	}


## Rebuilds a context from an archived report, for the aggregator.
static func from_dictionary(payload: Dictionary) -> ReportContext:
	var context := ReportContext.new()
	context.report_id = JsonRead.name_at(payload, "report_id")
	context.title = JsonRead.string_at(payload, "title")
	context.commit_sha = JsonRead.string_at(payload, "commit_sha")
	context.commit_dirty_note = JsonRead.string_at(payload, "commit_note")
	context.godot_version = JsonRead.string_at(payload, "godot_version")
	context.build_mode = JsonRead.string_at(payload, "build_mode")
	var rules: Dictionary = JsonRead.dictionary_at(payload, "rules_profile")
	context.rules_profile_id = JsonRead.name_at(rules, "id")
	context.rules_profile_version = JsonRead.name_at(rules, "version")
	var balance: Dictionary = JsonRead.dictionary_at(payload, "balance_profile")
	context.balance_profile_id = JsonRead.name_at(balance, "id")
	context.balance_profile_version = JsonRead.name_at(balance, "version")
	context.ratings_profile_version = JsonRead.name_at(payload, "ratings_profile_version")
	context.targets_version = JsonRead.name_at(payload, "targets_version")
	var rng: Dictionary = JsonRead.dictionary_at(payload, "rng")
	context.rng_algorithm = JsonRead.name_at(rng, "algorithm")
	context.rng_stream_key_version = JsonRead.name_at(rng, "stream_key_version")
	context.seed_description = JsonRead.string_at(payload, "seeds")
	var seed_range: Dictionary = JsonRead.dictionary_at(payload, "seed_range")
	context.seed_start = JsonRead.int_at(seed_range, "start")
	context.seed_end = JsonRead.int_at(seed_range, "end")
	var shard: Dictionary = JsonRead.dictionary_at(payload, "shard")
	context.shard_index = JsonRead.int_at(shard, "index")
	context.shard_count = JsonRead.int_at(shard, "count", 1)
	context.competition_id = JsonRead.name_at(payload, "competition")
	var certification: Dictionary = JsonRead.dictionary_at(payload, "certification")
	context.certification_sample_required = JsonRead.int_at(certification, "required_sample")
	context.certification_source = JsonRead.string_at(certification, "source")
	context.sample_count = JsonRead.int_at(payload, "sample_count")
	context.sample_unit = JsonRead.string_at(payload, "sample_unit")
	context.elapsed_ms = JsonRead.int_at(payload, "elapsed_ms")
	context.notes = PackedStringArray()
	for note: Variant in JsonRead.array_at(payload, "notes"):
		context.notes.append(str(note))
	context._started_us = Time.get_ticks_usec()
	return context


## The identity fields two shards must agree on before they may be combined.
## A mismatch in any of them means the shards measured different things.
func identity_signature() -> String:
	return "|".join(PackedStringArray([
		String(report_id), commit_sha, build_mode,
		String(rules_profile_id), String(rules_profile_version),
		String(balance_profile_id), String(balance_profile_version),
		String(ratings_profile_version), String(targets_version),
		String(rng_algorithm), String(rng_stream_key_version),
		String(competition_id), sample_unit,
	]))


func describe() -> String:
	return (
		"commit=%s godot=%s build=%s rules=%s/%s balance=%s/%s ratings=%s targets=%s "
		+ "rng=%s+%s seeds=%s n=%d %s elapsed=%dms rate=%.1f/s"
	) % [
		commit_sha, godot_version, build_mode,
		rules_profile_id, rules_profile_version,
		balance_profile_id, balance_profile_version,
		ratings_profile_version, targets_version,
		rng_algorithm, rng_stream_key_version,
		seed_description, sample_count, sample_unit,
		elapsed_ms, throughput_per_second(),
	]


# --- provenance --------------------------------------------------------------

## Resolves HEAD without a git binary: read `.git/HEAD`, follow the ref, and
## fall back to `packed-refs` for a freshly cloned checkout.
static func _read_commit_sha() -> String:
	var head: String = _read_text("res://.git/HEAD")
	if head.is_empty():
		return "unknown"
	head = head.strip_edges()
	if not head.begins_with("ref:"):
		return head
	var ref_path: String = head.substr(4).strip_edges()
	var direct: String = _read_text("res://.git/%s" % ref_path)
	if not direct.is_empty():
		return direct.strip_edges()
	var packed: String = _read_text("res://.git/packed-refs")
	for line in packed.split("\n"):
		var text: String = line.strip_edges()
		if text.is_empty() or text.begins_with("#") or text.begins_with("^"):
			continue
		var parts: PackedStringArray = text.split(" ", false)
		if parts.size() >= 2 and parts[1] == ref_path:
			return parts[0]
	return "unknown"


static func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


## Godot has no first-class "release vs debug template" flag for a headless
## script run, so the report states what is actually knowable: whether debug
## features and asserts are compiled in. Calibration numbers from a debug build
## are not comparable with release ones, and the field says which you have.
static func _build_mode() -> String:
	if OS.is_debug_build():
		return "editor-debug (asserts active)"
	return "release (asserts stripped)"
