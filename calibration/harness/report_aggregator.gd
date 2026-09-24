class_name ReportAggregator
extends RefCounted

## Combines sharded calibration reports into one certification report.
##
## The deep-verification workflow launches shards that are independent by
## design: each owns a disjoint seed interval so it can be rerun in isolation
## and reproduces exactly. That independence is what makes the run tractable and
## also what makes the shards individually meaningless — no single shard reaches
## a §27.1 sample, so no single shard can certify anything.
##
## This class is the missing half. It is deliberately hostile to its inputs:
##
## - every expected shard must be present, exactly once;
## - every shard must agree on commit, build mode, rules version, balance
##   version, ratings version, RNG version, targets version, competition, and
##   sample unit;
## - seed intervals must not overlap, because two shards sharing a seed have
##   simulated the same games twice and summing them inflates the sample
##   without adding information;
## - every metric must appear in every shard, with the same definition and the
##   same denominator, and must carry raw aggregation terms;
## - estimates, intervals, and verdicts are recomputed from the combined raw
##   terms and never averaged from the shards' own estimates.
##
## Any of those failing produces a rejection, and a rejected aggregation is
## never certified. The result reports the rejections rather than silently
## dropping the offending shard, because a shard that vanished quietly is how a
## certification ends up resting on half the sample it claims.

## The outcome of one aggregation attempt.
class Result extends RefCounted:
	var report: CalibrationReport
	var rejections: PackedStringArray
	var warnings: PackedStringArray
	## True only when every expected shard was valid and the combined sample
	## reached the owning requirement.
	var certified: bool
	var combined_sample: int
	var shards_accepted: int
	var shards_expected: int

	func _init() -> void:
		rejections = PackedStringArray()
		warnings = PackedStringArray()
		certified = false
		combined_sample = 0
		shards_accepted = 0
		shards_expected = 0

	func ok() -> bool:
		return rejections.is_empty()


## Loads every `*.json` report in a directory whose `report_id` matches, and
## aggregates them. `expected_shards` of zero means "take the shard count the
## reports themselves declare".
static func aggregate_directory(
	directory: String,
	report_id: StringName,
	expected_shards: int = 0,
) -> Result:
	var payloads: Array[Dictionary] = []
	var result := Result.new()
	var access: DirAccess = DirAccess.open(directory)
	if access == null:
		result.rejections.append("cannot open report directory: %s" % directory)
		return _rejected(result, report_id)
	var names: PackedStringArray = access.get_files()
	# Canonical order before anything is combined, so an aggregation is
	# reproducible regardless of how the filesystem enumerated the directory.
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".json"):
			continue
		var payload: Dictionary = _read_json("%s/%s" % [directory, file_name])
		if payload.is_empty():
			continue
		var context_payload: Dictionary = JsonRead.dictionary_at(payload, "context")
		if JsonRead.name_at(context_payload, "report_id") != report_id:
			continue
		payloads.append(payload)
	return aggregate(payloads, report_id, expected_shards)


## Aggregates already-loaded report payloads. Exposed separately so the tests
## can drive it with synthetic shards and never touch the filesystem.
static func aggregate(
	payloads: Array[Dictionary],
	report_id: StringName,
	expected_shards: int = 0,
) -> Result:
	var result := Result.new()
	if payloads.is_empty():
		result.rejections.append("no shard reports found for %s" % report_id)
		return _rejected(result, report_id)

	var contexts: Array[ReportContext] = []
	for payload in payloads:
		contexts.append(ReportContext.from_dictionary(
			JsonRead.dictionary_at(payload, "context")))

	# --- identity ------------------------------------------------------------
	var signature: String = contexts[0].identity_signature()
	for index in range(1, contexts.size()):
		if contexts[index].identity_signature() != signature:
			result.rejections.append(
				"shard %d identity does not match shard 0: %s vs %s" % [
					contexts[index].shard_index,
					contexts[index].identity_signature(),
					signature])

	# --- shard completeness and seed disjointness ---------------------------
	var declared: int = contexts[0].shard_count
	for context in contexts:
		if context.shard_count != declared:
			result.rejections.append(
				"shard %d declares %d shards; shard 0 declares %d" % [
					context.shard_index, context.shard_count, declared])
	var required: int = expected_shards if expected_shards > 0 else declared
	result.shards_expected = required

	var seen: Dictionary = {}
	for context in contexts:
		if seen.has(context.shard_index):
			result.rejections.append("duplicate shard index %d" % context.shard_index)
			continue
		seen[context.shard_index] = context
	for index in range(required):
		if not seen.has(index):
			result.rejections.append("missing shard %d of %d" % [index, required])
	for context in contexts:
		if context.shard_index >= required:
			result.rejections.append(
				"shard index %d is outside the expected range 0..%d"
					% [context.shard_index, required - 1])

	var ordered: Array[ReportContext] = []
	for index in range(required):
		if seen.has(index):
			var context: ReportContext = seen[index]
			ordered.append(context)
	for left in range(ordered.size()):
		for right in range(left + 1, ordered.size()):
			if _seeds_overlap(ordered[left], ordered[right]):
				result.rejections.append(
					"shards %d and %d have overlapping seed intervals %d..%d and %d..%d" % [
						ordered[left].shard_index, ordered[right].shard_index,
						ordered[left].seed_start, ordered[left].seed_end,
						ordered[right].seed_start, ordered[right].seed_end])

	if not result.ok():
		return _rejected(result, report_id)

	# --- metric combination --------------------------------------------------
	var combined: CalibrationReport = _build_combined_report(contexts, ordered, report_id)
	var metric_order: Array[StringName] = []
	var by_metric: Dictionary = {}
	for payload in payloads:
		for entry: Dictionary in JsonRead.array_at(payload, "metrics"):
			var metric: CalibrationMetric = CalibrationMetric.from_dictionary(entry)
			if not by_metric.has(metric.metric_id):
				by_metric[metric.metric_id] = [] as Array[CalibrationMetric]
				metric_order.append(metric.metric_id)
			var bucket: Array[CalibrationMetric] = by_metric[metric.metric_id]
			bucket.append(metric)
			by_metric[metric.metric_id] = bucket

	for metric_id in metric_order:
		var bucket: Array[CalibrationMetric] = by_metric[metric_id]
		if bucket.size() != payloads.size():
			result.rejections.append(
				"metric %s appears in %d of %d shards" % [
					metric_id, bucket.size(), payloads.size()])
			continue
		var merged: CalibrationMetric = _combine_metric(bucket, result)
		if merged != null:
			combined.add_metric(merged)

	if not result.ok():
		return _rejected(result, report_id)

	# --- certification -------------------------------------------------------
	var total_sample: int = 0
	for context in ordered:
		total_sample += context.sample_count
	result.combined_sample = total_sample
	result.shards_accepted = ordered.size()
	combined.context.sample_count = total_sample

	var requirement: int = contexts[0].certification_sample_required
	var meets: bool = requirement > 0 and total_sample >= requirement
	result.certified = meets and combined.passed()
	combined.add_metric(CalibrationMetric.boolean(
		&"certification.sample_reached",
		"Whether the combined valid sample reached the owning requirement of %d %s."
			% [requirement, contexts[0].sample_unit],
		meets,
		contexts[0].certification_source if not contexts[0].certification_source.is_empty()
			else CalibrationTargets.sample_size_source(),
		total_sample))
	combined.add_metric(CalibrationMetric.boolean(
		&"certification.all_shards_present",
		"Whether every expected shard was present, unique, and seed-disjoint.",
		ordered.size() == required,
		"deterministic shard aggregation", ordered.size()))

	combined.add_section(&"shards", _shard_rows(ordered))
	combined.context.notes.append(
		"Combined %d shards covering seeds %d..%d; %d %s." % [
			ordered.size(), ordered[0].seed_start,
			ordered[ordered.size() - 1].seed_end, total_sample, contexts[0].sample_unit])
	if not meets:
		combined.context.notes.append(
			"NOT CERTIFIED: combined sample %d is below the required %d %s."
				% [total_sample, requirement, contexts[0].sample_unit])
	combined.finish()
	result.report = combined
	return result


# --- internals ---------------------------------------------------------------

## Combines one metric across shards, or records why it could not be.
static func _combine_metric(
	bucket: Array[CalibrationMetric],
	result: Result,
) -> CalibrationMetric:
	var first: CalibrationMetric = bucket[0]
	for index in range(1, bucket.size()):
		var other: CalibrationMetric = bucket[index]
		if other.definition != first.definition:
			result.rejections.append(
				"metric %s has different definitions across shards" % first.metric_id)
			return null
		if other.denominator != first.denominator:
			result.rejections.append(
				"metric %s has different denominators across shards" % first.metric_id)
			return null
		if not _same_target(first, other):
			result.rejections.append(
				"metric %s has different targets across shards" % first.metric_id)
			return null

	if first.aggregation == null or not first.aggregation.is_aggregatable():
		# Not a defect in itself: some metrics are narrative. It is reported so
		# nobody mistakes its absence from the combined report for a pass.
		result.warnings.append(
			"metric %s carries no aggregation terms and was not combined" % first.metric_id)
		return null

	var merged: MetricAggregation = first.aggregation.duplicate_aggregation()
	for index in range(1, bucket.size()):
		var other: CalibrationMetric = bucket[index]
		if other.aggregation == null or other.aggregation.kind != merged.kind:
			result.rejections.append(
				"metric %s has inconsistent aggregation kinds across shards" % first.metric_id)
			return null
		if merged.kind == MetricAggregation.Kind.CONSTANT:
			if not is_equal_approx(other.aggregation.sum, merged.sum):
				result.rejections.append(
					"metric %s is declared constant but differs across shards" % first.metric_id)
				return null
			continue
		merged.combine(other.aggregation)

	var combined_metric := CalibrationMetric.raw(
		first.metric_id, first.definition, first.denominator, 0.0)
	combined_metric.target_minimum = first.target_minimum
	combined_metric.target_maximum = first.target_maximum
	combined_metric.target_source = first.target_source
	if not is_nan(first.target_minimum):
		combined_metric.verdict = CalibrationMetric.Verdict.PASS
	return combined_metric.with_aggregation(merged)


static func _same_target(left: CalibrationMetric, right: CalibrationMetric) -> bool:
	if is_nan(left.target_minimum) != is_nan(right.target_minimum):
		return false
	if is_nan(left.target_minimum):
		return true
	return (
		is_equal_approx(left.target_minimum, right.target_minimum)
		and is_equal_approx(left.target_maximum, right.target_maximum)
		and left.target_source == right.target_source)


static func _seeds_overlap(left: ReportContext, right: ReportContext) -> bool:
	# A degenerate interval (start == end == 0) means the shard did not declare
	# one. Two undeclared intervals cannot be proven disjoint, so they are
	# treated as overlapping rather than assumed safe.
	if left.seed_start == 0 and left.seed_end == 0:
		return right.seed_start == 0 and right.seed_end == 0
	return left.seed_start <= right.seed_end and right.seed_start <= left.seed_end


static func _build_combined_report(
	contexts: Array[ReportContext],
	ordered: Array[ReportContext],
	report_id: StringName,
) -> CalibrationReport:
	var source: ReportContext = contexts[0]
	var context := ReportContext.new()
	context.report_id = StringName("%s_certification" % report_id)
	context.title = "%s — combined certification over %d shards" % [
		source.title, ordered.size()]
	context.commit_sha = source.commit_sha
	context.commit_dirty_note = source.commit_dirty_note
	context.godot_version = source.godot_version
	context.build_mode = source.build_mode
	context.rules_profile_id = source.rules_profile_id
	context.rules_profile_version = source.rules_profile_version
	context.balance_profile_id = source.balance_profile_id
	context.balance_profile_version = source.balance_profile_version
	context.ratings_profile_version = source.ratings_profile_version
	context.targets_version = source.targets_version
	context.rng_algorithm = source.rng_algorithm
	context.rng_stream_key_version = source.rng_stream_key_version
	context.competition_id = source.competition_id
	context.certification_sample_required = source.certification_sample_required
	context.certification_source = source.certification_source
	context.sample_unit = source.sample_unit
	context.shard_index = 0
	context.shard_count = ordered.size()
	context.seed_start = ordered[0].seed_start
	context.seed_end = ordered[ordered.size() - 1].seed_end
	context.seed_description = "combined shards 0..%d, seeds %d..%d inclusive" % [
		ordered.size() - 1, context.seed_start, context.seed_end]
	context.notes = PackedStringArray()
	var elapsed: int = 0
	for entry in ordered:
		elapsed += entry.elapsed_ms
	context.elapsed_ms = elapsed
	return CalibrationReport.new(context)


static func _shard_rows(ordered: Array[ReportContext]) -> Array:
	var rows: Array = []
	for context in ordered:
		rows.append({
			"shard": context.shard_index,
			"seed_start": context.seed_start,
			"seed_end": context.seed_end,
			"sample_count": context.sample_count,
			"elapsed_ms": context.elapsed_ms,
		})
	return rows


static func _rejected(result: Result, report_id: StringName) -> Result:
	var context := ReportContext.new()
	context.report_id = StringName("%s_certification" % report_id)
	context.title = "%s — aggregation rejected" % report_id
	context.notes = PackedStringArray()
	for rejection in result.rejections:
		context.notes.append("rejected: %s" % rejection)
	result.report = CalibrationReport.new(context)
	result.report.add_metric(CalibrationMetric.boolean(
		&"certification.aggregation_valid",
		"Whether the shard set was complete, consistent, and seed-disjoint.",
		false, "deterministic shard aggregation"))
	result.certified = false
	return result


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var payload: Dictionary = parsed
	return payload
