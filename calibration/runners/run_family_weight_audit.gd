extends SceneTree

## The family-to-attribute allocation contract, published per family.
##
## `CareerSimulator` turns a starting position family into the creation-time
## allocation weights a generated career spends its budget through. That
## translation is the only place the §8.1 family catalog reaches attribute
## *spending* rather than attribute *caps*, and until the §5.24 repair it was
## wrong in a way no diagnostic looked at: it read `AttributeEmphasis` levels as
## if they were `AttributeKey` indices, so every family emphasized whatever
## attributes happened to sit at canonical indices 0-2.
##
## This runner exists so that translation is measured rather than assumed. For
## every declared family it publishes what the catalog *declares*, what the
## weight vector *is*, and what an otherwise identical player actually becomes
## when built through it against a controlled neutral comparison.
##
## It judges no band, tunes nothing, consumes no match random stream, and
## changes no production value. Run it before and after any change to the family
## catalog or to the weight mapping.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_family_weight_audit.gd -- \
##       [--base=SEED_BASE] [--cells=N] [--label=NAME] [--json=1]

## A seed base disjoint from every diagnosis, tuning and validation range
## recorded in `PROJECT_STATUS.md`. This runner owns 1,310,000-1,319,999.
const DEFAULT_BASE: int = 1310001

## Controlled cells per family: prospect × maturity, one seed each. Small on
## purpose — this is a *contract* audit, not a distribution measurement, and the
## distribution work lives in `run_builder_family_distribution.gd`.
const DEFAULT_CELLS: int = 9

const PROGRESS_EVERY: int = 3


## One family's controlled build arm, reduced to the numbers both arms are
## described by.
class CellSummary extends RefCounted:
	var cells: int = 0
	var attribute_mean: Array[float] = []
	var cap_mean: Array[float] = []
	var overall_mean: float = 0.0
	var maximum_mean: float = 0.0
	var peak_low_mean: float = 0.0
	var peak_high_mean: float = 0.0
	var ap_spent_mean: float = 0.0
	var confirmable: int = 0
	var cap_breaches: int = 0
	var illegal_values: int = 0
	var signature: String = ""


class FamilyRecord extends RefCounted:
	var family: int = 0
	var family_id: String = ""
	var declared_primary: Array[int] = []
	var declared_secondary: Array[int] = []
	var weights: Array[float] = []
	var non_zero: Array[int] = []
	var above_baseline: Array[int] = []
	var top_three: Array[int] = []
	var weight_sum: float = 0.0
	var duplicates: Array[int] = []
	var invalid_keys: Array[int] = []
	var neutral_for_family: Array[int] = []
	var built: CellSummary = null
	var control: CellSummary = null
	var attribute_delta: Array[float] = []
	var overall_delta: float = 0.0
	var peak_low_delta: float = 0.0
	var peak_high_delta: float = 0.0
	var determinism: bool = false

	func declared() -> Array[int]:
		var all: Array[int] = []
		all.append_array(declared_primary)
		all.append_array(declared_secondary)
		return all


class Coverage extends RefCounted:
	var covered: Array[int] = []
	var neutral: Array[int] = []
	var undocumented: Array[int] = []
	var overdeclared: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var base: int = CalibrationCli.int_option(options, &"base", DEFAULT_BASE)
	var cells: int = CalibrationCli.int_option(options, &"cells", DEFAULT_CELLS)
	var label: String = CalibrationCli.string_option(options, &"label", "audit")
	var want_json: bool = CalibrationCli.bool_option(options, &"json", false)

	var version_info: Dictionary = Engine.get_version_info()
	var version: String = version_info["string"]
	print("=== family weight audit (%s) ===" % label)
	print("godot=%s families=%d attributes=%d seeds=%d..%d" % [
		version, PositionFamily.COUNT, AttributeKey.COUNT,
		base, base + PositionFamily.COUNT * cells - 1])
	print("")

	var records: Array[FamilyRecord] = []
	var fingerprint_lines := PackedStringArray()

	for family in PositionFamily.all():
		print("family %d/%d: %s ..." % [
			family + 1, PositionFamily.COUNT, PositionFamily.id_of(family)])
		var record: FamilyRecord = _audit_family(family, base + family * cells, cells)
		records.append(record)
		fingerprint_lines.append("%s|%s|%s|%.4f" % [
			record.family_id, _names(record.above_baseline),
			record.built.signature, record.weight_sum])
		_print_family(record)
		print("")

	var fingerprint: String = MatchLedgerSerializer.hash_text("\n".join(fingerprint_lines))
	var coverage: Coverage = _coverage()
	print("=== canonical attribute coverage ===")
	_print_coverage(coverage)
	print("")
	print("audit_fingerprint=%s" % fingerprint)

	var failures: PackedStringArray = _contract_failures(records, coverage)
	if want_json:
		_write_json(label, records, coverage, fingerprint, failures)
	if failures.is_empty():
		print("family weight audit: PASS")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("family weight audit: %d failure(s)" % failures.size())
	quit(1)


# --- per-family audit ---------------------------------------------------------


func _audit_family(family: int, base: int, cells: int) -> FamilyRecord:
	var record := FamilyRecord.new()
	record.family = family
	record.family_id = String(PositionFamily.id_of(family))
	record.declared_primary = _declared(CapGenerator.FAMILY_PRIMARY[family])
	record.declared_secondary = _declared(CapGenerator.FAMILY_SECONDARY[family])
	record.weights = CareerSimulator.family_allocation_weights(family)

	for attribute in AttributeKey.all():
		var weight: float = record.weights[attribute]
		record.weight_sum += weight
		if weight > 0.0:
			record.non_zero.append(attribute)
		if weight > CareerSimulator.NEUTRAL_WEIGHT:
			record.above_baseline.append(attribute)

	record.top_three = _top_weighted(record.weights, 3)
	record.duplicates = _duplicate_declarations(record.declared())
	record.invalid_keys = _invalid_declarations(record.declared())
	record.neutral_for_family = _undeclared_attributes(record.declared())

	record.built = _build_cells(family, base, cells, record.weights)
	record.control = _build_cells(family, base, cells, _neutral_weights())
	record.attribute_delta = _delta(
		record.built.attribute_mean, record.control.attribute_mean)
	record.overall_delta = record.built.overall_mean - record.control.overall_mean
	record.peak_low_delta = record.built.peak_low_mean - record.control.peak_low_mean
	record.peak_high_delta = record.built.peak_high_mean - record.control.peak_high_mean

	var repeat: CellSummary = _build_cells(family, base, mini(cells, 3), record.weights)
	var truncated: CellSummary = _build_cells(family, base, mini(cells, 3), record.weights)
	record.determinism = repeat.signature == truncated.signature
	return record


## One controlled build per prospect × maturity cell, at a fixed seed and the
## family's own default body, so the only thing that varies between the measured
## arm and the control arm is the weight vector itself.
func _build_cells(family: int, base: int, cells: int, weights: Array[float]) -> CellSummary:
	var service := BuilderService.new()
	var query := DevelopmentProjectionQuery.new()
	var body: BodyProfile = service.default_body_for_family(family)

	var summary := CellSummary.new()
	summary.cells = cells
	var attribute_totals: Array[float] = []
	var cap_totals: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		attribute_totals.append(0.0)
		cap_totals.append(0.0)
	var overall_total: float = 0.0
	var peak_low_total: float = 0.0
	var peak_high_total: float = 0.0
	var maximum_total: float = 0.0
	var ap_spent_total: float = 0.0
	var signatures := PackedStringArray()

	for index in range(cells):
		var seed_value: int = base + index
		var prospect: int = index % ProspectProfile.COUNT
		var maturity: int = (index / ProspectProfile.COUNT) % MaturityProfile.COUNT
		var state: BuilderState = service.begin_build(
			family, prospect, maturity, body, SeededRandomSource.new(seed_value))
		state.spend_remaining_weighted(weights)
		state.fill_remaining_anywhere()
		var view: BuilderConfirmationView = query.builder_confirmation_view(state)

		var values: Array[int] = state.values()
		var caps: Array[int] = state.caps.values()
		for attribute in AttributeKey.all():
			attribute_totals[attribute] += float(values[attribute])
			cap_totals[attribute] += float(caps[attribute])
			if values[attribute] > caps[attribute]:
				summary.cap_breaches += 1
			if not Rating.is_valid_active(values[attribute]):
				summary.illegal_values += 1
		overall_total += float(view.projection.current_overall)
		maximum_total += float(view.projection.maximum_potential)
		peak_low_total += float(view.projection.projected_peak.low)
		peak_high_total += float(view.projection.projected_peak.high)
		ap_spent_total += float(state.budget.spent)
		if state.can_confirm():
			summary.confirmable += 1
		signatures.append("%d|%s|%s" % [
			seed_value, state.attributes().signature(), state.caps.signature()])
		if cells > PROGRESS_EVERY and (index + 1) % PROGRESS_EVERY == 0:
			print("    cell %d/%d (seed %d)" % [index + 1, cells, seed_value])

	var divisor: float = float(maxi(cells, 1))
	for attribute in AttributeKey.all():
		summary.attribute_mean.append(attribute_totals[attribute] / divisor)
		summary.cap_mean.append(cap_totals[attribute] / divisor)
	summary.overall_mean = overall_total / divisor
	summary.maximum_mean = maximum_total / divisor
	summary.peak_low_mean = peak_low_total / divisor
	summary.peak_high_mean = peak_high_total / divisor
	summary.ap_spent_mean = ap_spent_total / divisor
	summary.signature = MatchLedgerSerializer.hash_text("\n".join(signatures))
	return summary


# --- catalog helpers ----------------------------------------------------------


func _declared(raw: Array) -> Array[int]:
	var declared: Array[int] = []
	for entry: int in raw:
		declared.append(entry)
	return declared


func _neutral_weights() -> Array[float]:
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(CareerSimulator.NEUTRAL_WEIGHT)
	return weights


## Highest weights first, canonical index breaking ties so the answer is stable
## whatever order the catalog declared its attributes in.
func _top_weighted(weights: Array[float], count: int) -> Array[int]:
	var ordered: Array[int] = AttributeKey.all()
	ordered.sort_custom(func(left: int, right: int) -> bool:
		if is_equal_approx(weights[left], weights[right]):
			return left < right
		return weights[left] > weights[right])
	var top: Array[int] = []
	for index in range(mini(count, ordered.size())):
		top.append(ordered[index])
	return top


func _duplicate_declarations(declared: Array[int]) -> Array[int]:
	var seen: Dictionary = {}
	var duplicates: Array[int] = []
	for attribute in declared:
		if seen.has(attribute):
			if not duplicates.has(attribute):
				duplicates.append(attribute)
			continue
		seen[attribute] = true
	duplicates.sort()
	return duplicates


func _invalid_declarations(declared: Array[int]) -> Array[int]:
	var invalid: Array[int] = []
	for attribute in declared:
		if attribute < 0 or attribute >= AttributeKey.COUNT:
			invalid.append(attribute)
	return invalid


func _undeclared_attributes(declared: Array[int]) -> Array[int]:
	var seen: Dictionary = {}
	for attribute in declared:
		seen[attribute] = true
	var missing: Array[int] = []
	for attribute in AttributeKey.all():
		if not seen.has(attribute):
			missing.append(attribute)
	return missing


func _delta(left: Array[float], right: Array[float]) -> Array[float]:
	var delta: Array[float] = []
	for index in range(left.size()):
		delta.append(left[index] - right[index])
	return delta


# --- coverage -----------------------------------------------------------------


## Every canonical attribute is either emphasized by an approved family or is
## explicitly declared family-neutral. No family is invented to close the gap:
## the neutral set is a declared property of the catalog, published here so it
## cannot drift silently.
func _coverage() -> Coverage:
	var emphasized: Dictionary = {}
	for family in PositionFamily.all():
		for attribute: int in CapGenerator.FAMILY_PRIMARY[family]:
			emphasized[attribute] = true
		for attribute: int in CapGenerator.FAMILY_SECONDARY[family]:
			emphasized[attribute] = true

	var coverage := Coverage.new()
	for attribute in AttributeKey.all():
		if emphasized.has(attribute):
			coverage.covered.append(attribute)
		else:
			coverage.neutral.append(attribute)
	for attribute in coverage.neutral:
		if not CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES.has(attribute):
			coverage.undocumented.append(attribute)
	for attribute: int in CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES:
		if emphasized.has(attribute):
			coverage.overdeclared.append(attribute)
	return coverage


# --- contract checks ----------------------------------------------------------


func _contract_failures(
	records: Array[FamilyRecord],
	coverage: Coverage,
) -> PackedStringArray:
	var failures := PackedStringArray()
	for record in records:
		for attribute in record.declared_primary:
			if not is_equal_approx(record.weights[attribute], CareerSimulator.PRIMARY_WEIGHT):
				failures.append("%s: declared primary %s carries weight %.4f, expected %.4f" % [
					record.family_id, AttributeKey.name_of(attribute),
					record.weights[attribute], CareerSimulator.PRIMARY_WEIGHT])
		for attribute in record.declared_secondary:
			if not is_equal_approx(record.weights[attribute], CareerSimulator.SECONDARY_WEIGHT):
				failures.append("%s: declared secondary %s carries weight %.4f, expected %.4f" % [
					record.family_id, AttributeKey.name_of(attribute),
					record.weights[attribute], CareerSimulator.SECONDARY_WEIGHT])
		for attribute in record.neutral_for_family:
			if not is_equal_approx(record.weights[attribute], CareerSimulator.NEUTRAL_WEIGHT):
				failures.append("%s: undeclared %s carries family weight %.4f" % [
					record.family_id, AttributeKey.name_of(attribute),
					record.weights[attribute]])

		var declared_count: int = record.declared().size()
		if record.above_baseline.size() != declared_count:
			failures.append("%s: %d attributes above baseline, %d declared" % [
				record.family_id, record.above_baseline.size(), declared_count])
		for attribute in record.top_three:
			if not record.declared_primary.has(attribute):
				failures.append("%s: top-weighted %s is not a declared primary" % [
					record.family_id, AttributeKey.name_of(attribute)])
		if not record.duplicates.is_empty():
			failures.append("%s: duplicate declarations %s" % [
				record.family_id, _names(record.duplicates)])
		if not record.invalid_keys.is_empty():
			failures.append("%s: invalid attribute keys %s" % [
				record.family_id, _names(record.invalid_keys)])
		if not record.determinism:
			failures.append("%s: builder output was not reproducible at a fixed seed"
				% record.family_id)
		if record.built.cap_breaches > 0:
			failures.append("%s: %d per-attribute cap breaches" % [
				record.family_id, record.built.cap_breaches])
		if record.built.illegal_values > 0:
			failures.append("%s: %d ratings outside the legal active band" % [
				record.family_id, record.built.illegal_values])
		if record.built.confirmable != record.built.cells:
			failures.append("%s: %d of %d builds were not confirmable" % [
				record.family_id, record.built.confirmable, record.built.cells])

	if not coverage.undocumented.is_empty():
		failures.append(
			"emphasized by no family and not declared family-neutral: %s"
			% _names(coverage.undocumented))
	if not coverage.overdeclared.is_empty():
		failures.append(
			"declared family-neutral but emphasized by a family: %s"
			% _names(coverage.overdeclared))

	# Two families that declare differently must build differently.
	for left in range(records.size()):
		for right in range(left + 1, records.size()):
			var first: FamilyRecord = records[left]
			var second: FamilyRecord = records[right]
			if (first.declared_primary == second.declared_primary
					and first.declared_secondary == second.declared_secondary):
				continue
			if first.weights == second.weights:
				failures.append("%s and %s declare differently but weight identically" % [
					first.family_id, second.family_id])
	return failures


# --- output -------------------------------------------------------------------


func _names(attributes: Array[int]) -> String:
	var names := PackedStringArray()
	for attribute in attributes:
		if attribute < 0 or attribute >= AttributeKey.COUNT:
			names.append("<invalid %d>" % attribute)
			continue
		names.append(String(AttributeKey.name_of(attribute)))
	if names.is_empty():
		return "(none)"
	return ", ".join(names)


func _print_family(record: FamilyRecord) -> void:
	print("  --- %s ---" % record.family_id)
	print("  declared primary   : %s" % _names(record.declared_primary))
	print("  declared secondary : %s" % _names(record.declared_secondary))
	print("  above baseline     : %s" % _names(record.above_baseline))
	print("  top three weights  : %s" % _names(record.top_three))
	print("  non-zero weights   : %d of %d" % [record.non_zero.size(), AttributeKey.COUNT])
	print("  weight sum         : %.4f" % record.weight_sum)
	print("  duplicates         : %s" % _names(record.duplicates))
	print("  invalid keys       : %s" % _names(record.invalid_keys))
	print("  family-neutral here: %d attributes" % record.neutral_for_family.size())
	print("  determinism        : %s" % (
		"byte-identical" if record.determinism else "DIVERGED"))
	print("  overall            : %.2f (control %.2f, lift %+.2f)" % [
		record.built.overall_mean, record.control.overall_mean, record.overall_delta])
	print("  maximum potential  : %.2f (control %.2f)" % [
		record.built.maximum_mean, record.control.maximum_mean])
	print("  projected peak     : %.2f-%.2f (control %.2f-%.2f, lift %+.2f/%+.2f)" % [
		record.built.peak_low_mean, record.built.peak_high_mean,
		record.control.peak_low_mean, record.control.peak_high_mean,
		record.peak_low_delta, record.peak_high_delta])
	print("  ap spent           : %.1f (control %.1f)" % [
		record.built.ap_spent_mean, record.control.ap_spent_mean])
	print("  cap breaches       : %d   illegal ratings: %d   confirmable: %d/%d" % [
		record.built.cap_breaches, record.built.illegal_values,
		record.built.confirmable, record.built.cells])
	print("  builder signature  : %s" % record.built.signature)
	print("  per-attribute mean (weight | built | control | lift | cap):")
	for attribute in AttributeKey.all():
		print("    %-22s %5.2f | %6.2f | %6.2f | %+6.2f | %6.2f   %s" % [
			AttributeKey.name_of(attribute), record.weights[attribute],
			record.built.attribute_mean[attribute],
			record.control.attribute_mean[attribute],
			record.attribute_delta[attribute],
			record.built.cap_mean[attribute],
			_tier_label(record, attribute)])


func _tier_label(record: FamilyRecord, attribute: int) -> String:
	if record.declared_primary.has(attribute):
		return "PRIMARY"
	if record.declared_secondary.has(attribute):
		return "secondary"
	return ""


func _print_coverage(coverage: Coverage) -> void:
	print("  emphasized by at least one family (%d): %s" % [
		coverage.covered.size(), _names(coverage.covered)])
	print("  declared intentionally family-neutral (%d): %s" % [
		coverage.neutral.size(), _names(coverage.neutral)])
	print("  undocumented gaps: %s" % _names(coverage.undocumented))
	print("  over-declared neutrals: %s" % _names(coverage.overdeclared))


func _write_json(
	label: String,
	records: Array[FamilyRecord],
	coverage: Coverage,
	fingerprint: String,
	failures: PackedStringArray,
) -> void:
	var families: Array = []
	for record in records:
		families.append({
			"family_id": record.family_id,
			"declared_primary": record.declared_primary,
			"declared_secondary": record.declared_secondary,
			"weights": record.weights,
			"above_baseline": record.above_baseline,
			"top_three": record.top_three,
			"weight_sum": record.weight_sum,
			"determinism": record.determinism,
			"attribute_mean": record.built.attribute_mean,
			"control_mean": record.control.attribute_mean,
			"attribute_delta": record.attribute_delta,
			"cap_mean": record.built.cap_mean,
			"overall_mean": record.built.overall_mean,
			"control_overall_mean": record.control.overall_mean,
			"peak_low_mean": record.built.peak_low_mean,
			"peak_high_mean": record.built.peak_high_mean,
			"ap_spent_mean": record.built.ap_spent_mean,
			"signature": record.built.signature,
		})
	var payload: Dictionary = {
		"label": label,
		"fingerprint": fingerprint,
		"coverage": {
			"covered": coverage.covered,
			"neutral": coverage.neutral,
			"undocumented": coverage.undocumented,
			"overdeclared": coverage.overdeclared,
		},
		"failures": failures,
		"families": families,
	}
	DirAccess.make_dir_recursive_absolute("res://reports")
	var path: String = "res://reports/family_weight_audit_%s.json" % label
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("could not write %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t", true))
	file.close()
	print("wrote %s" % path)
