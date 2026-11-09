extends SceneTree

## What the production player builder actually produces, per family and per
## position, after the §5.24 family-weight repair.
##
## The repair changed which attributes a generated career invests in, so every
## builder distribution measured through `CareerSimulator` before it describes a
## population that no longer exists. This runner re-measures the creation-time
## contract at a sample large enough to describe a distribution rather than a
## point, on seed ranges that no earlier diagnosis, tuning or validation run has
## touched.
##
## Two arms are built for every cell so the family's contribution is separable
## from the position's, the talent level's and the body's:
##
## - `family` — the build allocated through the family's own §8.1 weights, which
##   is what a generated career uses.
## - `neutral` — the identical build, identical seed, identical body and
##   identical caps, allocated through a flat weight vector. Every difference
##   between the arms is the family emphasis and nothing else.
##
## It judges no band, tunes nothing, consumes no match random stream, and
## changes no production value.
##
## Run:
##   godot --headless --path . --script \
##       res://calibration/runners/run_builder_family_distribution.gd -- \
##       [--players=N] [--base=SEED_BASE] [--label=NAME] [--json=1]

## Players per family. 1,000 per family is the §5.24 validation sample.
const DEFAULT_PLAYERS: int = 1000

## Fresh and disjoint from every range recorded in `PROJECT_STATUS.md`. This
## runner owns 1,330,000-1,339,999.
const DEFAULT_BASE: int = 1330001

const PROGRESS_EVERY: int = 100

## Body variants per family: the short/light end, the family midpoint, and the
## tall/long end of the legal freshman range, so the report can say whether
## family identity survives the physical profile.
const BODY_VARIANTS: int = 3
const BODY_VARIANT_IDS: PackedStringArray = ["minimum", "median", "maximum"]


class Sample extends RefCounted:
	var label: String = ""
	var count: int = 0
	var attribute_values: Array[PackedFloat64Array] = []
	var overall := PackedFloat64Array()
	var maximum_potential := PackedFloat64Array()
	var peak_low := PackedFloat64Array()
	var peak_high := PackedFloat64Array()
	var caps: Array[PackedFloat64Array] = []
	var ap_spent := PackedFloat64Array()
	var heights := PackedFloat64Array()
	var weights := PackedFloat64Array()
	var wingspans := PackedFloat64Array()
	var archetypes: Dictionary = {}
	var cap_breaches: int = 0
	var illegal_values: int = 0
	var unconfirmable: int = 0

	func _init(p_label: String) -> void:
		label = p_label
		for _attribute in range(AttributeKey.COUNT):
			attribute_values.append(PackedFloat64Array())
			caps.append(PackedFloat64Array())


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var players: int = CalibrationCli.int_option(options, &"players", DEFAULT_PLAYERS)
	var base: int = CalibrationCli.int_option(options, &"base", DEFAULT_BASE)
	var label: String = CalibrationCli.string_option(options, &"label", "validation")
	var want_json: bool = CalibrationCli.bool_option(options, &"json", false)

	var version_info: Dictionary = Engine.get_version_info()
	var version: String = version_info["string"]
	print("=== builder family distribution (%s) ===" % label)
	print("godot=%s families=%d players_per_family=%d" % [
		version, PositionFamily.COUNT, players])
	print("seed ledger: %d..%d (fresh; disjoint from every recorded range)" % [
		base, base + PositionFamily.COUNT * players - 1])
	print("arms: family (its own §8.1 weights) vs neutral (flat control, same seed and body)")
	print("")

	var family_samples: Array[Sample] = []
	var neutral_samples: Array[Sample] = []
	var determinism_ok: bool = true
	var fingerprints := PackedStringArray()

	for family in PositionFamily.all():
		var id: String = String(PositionFamily.id_of(family))
		print("family %d/%d: %s (%d players)" % [
			family + 1, PositionFamily.COUNT, id, players])
		var arms: Array[Sample] = _measure_family(family, base + family * players, players)
		family_samples.append(arms[0])
		neutral_samples.append(arms[1])
		fingerprints.append("%s|%s" % [id, _signature_of(family, base + family * players)])
		print("")

	# Determinism: the whole family arm rebuilt from the same seeds must produce
	# the same signature. Checked on a bounded slice so the answer is exact
	# without doubling the run.
	for family in PositionFamily.all():
		var repeated: String = _signature_of(family, base + family * players)
		if repeated != String(fingerprints[family]).split("|")[1]:
			determinism_ok = false

	for family in PositionFamily.all():
		_print_family(family, family_samples[family], neutral_samples[family])
		print("")

	_print_cross_family(family_samples, neutral_samples)
	print("")
	var fingerprint: String = MatchLedgerSerializer.hash_text("\n".join(fingerprints))
	print("determinism        : %s" % (
		"byte-identical on rebuild" if determinism_ok else "DIVERGED"))
	print("distribution_fingerprint=%s" % fingerprint)

	var failures: PackedStringArray = _failures(
		family_samples, neutral_samples, determinism_ok)
	if want_json:
		_write_json(label, base, players, family_samples, neutral_samples,
			fingerprint, failures)
	if failures.is_empty():
		print("builder family distribution: PASS")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("builder family distribution: %d failure(s)" % failures.size())
	quit(1)


# --- measurement --------------------------------------------------------------


## Returns `[family_arm, neutral_arm]` for one family.
func _measure_family(family: int, base: int, players: int) -> Array[Sample]:
	var service := BuilderService.new()
	var query := DevelopmentProjectionQuery.new()
	var archetypes: ArchetypeProfile = service.archetype_profile()
	var family_arm := Sample.new("family")
	var neutral_arm := Sample.new("neutral")
	var family_weights: Array[float] = CareerSimulator.family_allocation_weights(family)
	var flat: Array[float] = _flat_weights()

	for index in range(players):
		var seed_value: int = base + index
		# Talent level, maturity and physical profile all vary across the sample
		# so no single cell can dominate the distribution.
		var prospect: int = index % ProspectProfile.COUNT
		var maturity: int = (index / ProspectProfile.COUNT) % MaturityProfile.COUNT
		var variant: int = (index / (ProspectProfile.COUNT * MaturityProfile.COUNT)) \
			% BODY_VARIANTS
		var body: BodyProfile = _body_for(family, variant, service)

		_record(family_arm, service, query, archetypes,
			family, prospect, maturity, body, seed_value, family_weights)
		_record(neutral_arm, service, query, archetypes,
			family, prospect, maturity, body, seed_value, flat)

		if players > PROGRESS_EVERY and (index + 1) % PROGRESS_EVERY == 0:
			print("  %d/%d players (seed %d)" % [index + 1, players, seed_value])

	return [family_arm, neutral_arm]


func _record(
	sample: Sample,
	service: BuilderService,
	query: DevelopmentProjectionQuery,
	archetypes: ArchetypeProfile,
	family: int,
	prospect: int,
	maturity: int,
	body: BodyProfile,
	seed_value: int,
	weights: Array[float],
) -> void:
	var state: BuilderState = service.begin_build(
		family, prospect, maturity, body, SeededRandomSource.new(seed_value))
	state.spend_remaining_weighted(weights)
	state.fill_remaining_anywhere()
	var view: BuilderConfirmationView = query.builder_confirmation_view(state)

	var values: Array[int] = state.values()
	var caps: Array[int] = state.caps.values()
	for attribute in AttributeKey.all():
		sample.attribute_values[attribute].append(float(values[attribute]))
		sample.caps[attribute].append(float(caps[attribute]))
		if values[attribute] > caps[attribute]:
			sample.cap_breaches += 1
		if not Rating.is_valid_active(values[attribute]):
			sample.illegal_values += 1
	sample.overall.append(float(view.projection.current_overall))
	sample.maximum_potential.append(float(view.projection.maximum_potential))
	sample.peak_low.append(float(view.projection.projected_peak.low))
	sample.peak_high.append(float(view.projection.projected_peak.high))
	sample.ap_spent.append(float(state.budget.spent))
	sample.heights.append(float(body.height_inches))
	sample.weights.append(float(body.weight_pounds))
	sample.wingspans.append(float(body.wingspan_inches))
	if not state.can_confirm():
		sample.unconfirmable += 1
	var archetype: String = String(view.archetype.label())
	var seen: int = sample.archetypes[archetype] if sample.archetypes.has(archetype) else 0
	sample.archetypes[archetype] = seen + 1
	sample.count += 1


## A bounded signature over the family arm, for the determinism check.
func _signature_of(family: int, base: int) -> String:
	var service := BuilderService.new()
	var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
	var lines := PackedStringArray()
	for index in range(16):
		var seed_value: int = base + index
		var state: BuilderState = service.begin_build(
			family, index % ProspectProfile.COUNT,
			(index / ProspectProfile.COUNT) % MaturityProfile.COUNT,
			_body_for(family, index % BODY_VARIANTS, service),
			SeededRandomSource.new(seed_value))
		state.spend_remaining_weighted(weights)
		state.fill_remaining_anywhere()
		lines.append("%d|%s|%s" % [
			seed_value, state.attributes().signature(), state.caps.signature()])
	return MatchLedgerSerializer.hash_text("\n".join(lines))


func _body_for(family: int, variant: int, service: BuilderService) -> BodyProfile:
	var builder: BuilderProfile = service.profiles().builder
	var height_bounds: Array[int] = BuilderRules.height_bounds_for_family(family, builder)
	var height: int = _pick(height_bounds, variant)
	var weight_bounds: Array[int] = BuilderRules.weight_bounds_for_height(height, builder)
	var weight: int = _pick(weight_bounds, variant)
	var wingspan_bounds: Array[int] = BuilderRules.wingspan_bounds_for_height(height, builder)
	var wingspan: int = _pick(wingspan_bounds, variant)
	return BodyProfile.new(
		height, weight, wingspan, BodyProfile.derive_standing_reach(height, wingspan))


func _pick(bounds: Array[int], variant: int) -> int:
	match variant:
		1:
			return (bounds[0] + bounds[1]) / 2
		2:
			return bounds[1]
		_:
			return bounds[0]


func _flat_weights() -> Array[float]:
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(CareerSimulator.NEUTRAL_WEIGHT)
	return weights


# --- reporting ----------------------------------------------------------------


func _sorted(values: PackedFloat64Array) -> PackedFloat64Array:
	var copy := PackedFloat64Array(values)
	copy.sort()
	return copy


func _quantiles(values: PackedFloat64Array) -> PackedFloat64Array:
	var sorted: PackedFloat64Array = _sorted(values)
	return PackedFloat64Array([
		CalibrationStatistics.percentile(sorted, 0.05),
		CalibrationStatistics.percentile(sorted, 0.25),
		CalibrationStatistics.percentile(sorted, 0.50),
		CalibrationStatistics.percentile(sorted, 0.75),
		CalibrationStatistics.percentile(sorted, 0.95),
	])


func _declared_primary(family: int) -> Array[int]:
	var declared: Array[int] = []
	for attribute: int in CapGenerator.FAMILY_PRIMARY[family]:
		declared.append(attribute)
	return declared


func _declared(family: int) -> Array[int]:
	var declared: Array[int] = _declared_primary(family)
	for attribute: int in CapGenerator.FAMILY_SECONDARY[family]:
		declared.append(attribute)
	return declared


func _tier(family: int, attribute: int) -> String:
	if _declared_primary(family).has(attribute):
		return "PRIMARY"
	for entry: int in CapGenerator.FAMILY_SECONDARY[family]:
		if entry == attribute:
			return "secondary"
	return ""


func _print_family(family: int, arm: Sample, control: Sample) -> void:
	var id: String = String(PositionFamily.id_of(family))
	print("=== %s (n=%d) ===" % [id, arm.count])
	print("  position family    : %s (%s)" % [
		PositionFamily.label_of(family), id])
	print("  overall            : mean %.2f sd %.2f  %s" % [
		CalibrationStatistics.mean(arm.overall),
		CalibrationStatistics.standard_deviation(arm.overall),
		_quantile_text(arm.overall)])
	print("  neutral control    : mean %.2f sd %.2f (family lift %+.2f)" % [
		CalibrationStatistics.mean(control.overall),
		CalibrationStatistics.standard_deviation(control.overall),
		CalibrationStatistics.mean(arm.overall) - CalibrationStatistics.mean(control.overall)])
	print("  maximum potential  : mean %.2f sd %.2f  %s" % [
		CalibrationStatistics.mean(arm.maximum_potential),
		CalibrationStatistics.standard_deviation(arm.maximum_potential),
		_quantile_text(arm.maximum_potential)])
	print("  projected peak low : mean %.2f sd %.2f  %s" % [
		CalibrationStatistics.mean(arm.peak_low),
		CalibrationStatistics.standard_deviation(arm.peak_low),
		_quantile_text(arm.peak_low)])
	print("  projected peak high: mean %.2f sd %.2f  %s" % [
		CalibrationStatistics.mean(arm.peak_high),
		CalibrationStatistics.standard_deviation(arm.peak_high),
		_quantile_text(arm.peak_high)])
	print("  ap spent           : mean %.1f (control %.1f)" % [
		CalibrationStatistics.mean(arm.ap_spent),
		CalibrationStatistics.mean(control.ap_spent)])
	print("  body               : height %.1f in, weight %.1f lb, wingspan %.1f in" % [
		CalibrationStatistics.mean(arm.heights),
		CalibrationStatistics.mean(arm.weights),
		CalibrationStatistics.mean(arm.wingspans)])
	print("  physical profiles  : %s" % _body_profile_text(arm))
	print("  archetypes         : %s" % _archetype_text(arm))
	print("  legality           : %d cap breaches, %d illegal ratings, %d unconfirmable" % [
		arm.cap_breaches, arm.illegal_values, arm.unconfirmable])
	print("  attribute distribution (tier | mean | sd | P5 | P25 | P50 | P75 | P95"
		+ " | cap mean | lift):")
	for attribute in AttributeKey.all():
		var values: PackedFloat64Array = arm.attribute_values[attribute]
		var quantiles: PackedFloat64Array = _quantiles(values)
		var lift: float = (
			CalibrationStatistics.mean(values)
			- CalibrationStatistics.mean(control.attribute_values[attribute]))
		print(("    %-22s %-9s %6.2f %5.2f  %5.1f %5.1f %5.1f %5.1f %5.1f"
			+ "   %6.2f  %+6.2f") % [
			AttributeKey.name_of(attribute), _tier(family, attribute),
			CalibrationStatistics.mean(values),
			CalibrationStatistics.standard_deviation(values),
			quantiles[0], quantiles[1], quantiles[2], quantiles[3], quantiles[4],
			CalibrationStatistics.mean(arm.caps[attribute]), lift])


func _quantile_text(values: PackedFloat64Array) -> String:
	var quantiles: PackedFloat64Array = _quantiles(values)
	return "P5/P25/P50/P75/P95 %.1f/%.1f/%.1f/%.1f/%.1f" % [
		quantiles[0], quantiles[1], quantiles[2], quantiles[3], quantiles[4]]


func _body_profile_text(arm: Sample) -> String:
	var counts: Dictionary = {}
	var sorted_heights: PackedFloat64Array = _sorted(arm.heights)
	for height in sorted_heights:
		var seen: int = counts[height] if counts.has(height) else 0
		counts[height] = seen + 1
	var parts := PackedStringArray()
	var keys: Array = counts.keys()
	keys.sort()
	for key: float in keys:
		var count: int = counts[key]
		parts.append("%.0fin x%d" % [key, count])
	return ", ".join(parts)


func _archetype_text(arm: Sample) -> String:
	var keys: Array = arm.archetypes.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key: String in keys:
		var count: int = arm.archetypes[key]
		parts.append("%s x%d" % [key, count])
	return ", ".join(parts)


## The separability report: how much of each family's own primaries is family
## emphasis, and how far unrelated attributes moved.
func _print_cross_family(family_samples: Array[Sample], neutral_samples: Array[Sample]) -> void:
	print("=== family separability ===")
	print("  each family's declared primaries against the same attribute in the")
	print("  families that do not declare it, and against its own neutral control")
	for family in PositionFamily.all():
		var id: String = String(PositionFamily.id_of(family))
		var arm: Sample = family_samples[family]
		var control: Sample = neutral_samples[family]
		for attribute in _declared_primary(family):
			var mine: float = CalibrationStatistics.mean(arm.attribute_values[attribute])
			var mine_control: float = CalibrationStatistics.mean(
				control.attribute_values[attribute])
			var others := PackedStringArray()
			for other in PositionFamily.all():
				if other == family:
					continue
				var theirs: float = CalibrationStatistics.mean(
					family_samples[other].attribute_values[attribute])
				others.append("%s %.2f" % [PositionFamily.id_of(other), theirs])
			print("    %-6s %-22s %6.2f (control %6.2f, lift %+6.2f) vs %s" % [
				id, AttributeKey.name_of(attribute), mine, mine_control,
				mine - mine_control, ", ".join(others)])

	print("  unrelated-attribute movement (attributes this family does not declare):")
	for family in PositionFamily.all():
		var arm: Sample = family_samples[family]
		var control: Sample = neutral_samples[family]
		var declared: Array[int] = _declared(family)
		var largest: float = 0.0
		var largest_attribute: int = 0
		for attribute in AttributeKey.all():
			if declared.has(attribute):
				continue
			var movement: float = absf(
				CalibrationStatistics.mean(arm.attribute_values[attribute])
				- CalibrationStatistics.mean(control.attribute_values[attribute]))
			if movement > largest:
				largest = movement
				largest_attribute = attribute
		print("    %-6s largest undeclared movement: %s %+.2f" % [
			PositionFamily.id_of(family), AttributeKey.name_of(largest_attribute),
			CalibrationStatistics.mean(arm.attribute_values[largest_attribute])
			- CalibrationStatistics.mean(control.attribute_values[largest_attribute])])


# --- contract checks ----------------------------------------------------------


func _failures(
	family_samples: Array[Sample],
	neutral_samples: Array[Sample],
	determinism_ok: bool,
) -> PackedStringArray:
	var failures := PackedStringArray()
	if not determinism_ok:
		failures.append("the builder did not reproduce byte-identically from the same seeds")

	for family in PositionFamily.all():
		var id: String = String(PositionFamily.id_of(family))
		var arm: Sample = family_samples[family]
		var control: Sample = neutral_samples[family]
		if arm.cap_breaches > 0:
			failures.append("%s: %d per-attribute cap breaches" % [id, arm.cap_breaches])
		if arm.illegal_values > 0:
			failures.append("%s: %d ratings outside the legal active band" % [
				id, arm.illegal_values])
		if arm.unconfirmable > 0:
			failures.append("%s: %d builds could not be confirmed" % [id, arm.unconfirmable])

		# Every declared primary must sit meaningfully above its own neutral
		# control: the emphasis has to reach the player, not just the array.
		for attribute in _declared_primary(family):
			var lift: float = (
				CalibrationStatistics.mean(arm.attribute_values[attribute])
				- CalibrationStatistics.mean(control.attribute_values[attribute]))
			if lift <= 0.0:
				failures.append("%s: declared primary %s did not rise above its control (%+.2f)"
					% [id, AttributeKey.name_of(attribute), lift])

		# No family may take a hidden total-OVR advantage: the arms spend the
		# same budget, so the family arm buys a different player, not a better
		# one. A whole Overall point of separation would be an advantage.
		var overall_lift: float = (
			CalibrationStatistics.mean(arm.overall)
			- CalibrationStatistics.mean(control.overall))
		if absf(overall_lift) >= 1.0:
			failures.append("%s: family emphasis moved mean Overall by %+.2f against its control"
				% [id, overall_lift])

		# Projected Peak is drawn from the caps, which the weights never touch.
		var peak_lift: float = (
			CalibrationStatistics.mean(arm.peak_low)
			- CalibrationStatistics.mean(control.peak_low))
		if absf(peak_lift) > 0.0001:
			failures.append("%s: family emphasis moved Projected Peak by %+.4f" % [
				id, peak_lift])

		# Families overlap rather than partition: a family's own primary must not
		# be so far above another family's that the two populations separate.
		if arm.count > 0 and CalibrationStatistics.standard_deviation(arm.overall) <= 0.0:
			failures.append("%s: the Overall distribution collapsed to a point" % id)

	# Distinctness: no two families may produce the same attribute centre vector.
	for left in range(PositionFamily.COUNT):
		for right in range(left + 1, PositionFamily.COUNT):
			var separation: float = 0.0
			for attribute in AttributeKey.all():
				separation += absf(
					CalibrationStatistics.mean(family_samples[left].attribute_values[attribute])
					- CalibrationStatistics.mean(family_samples[right].attribute_values[attribute]))
			if separation < 1.0:
				failures.append("%s and %s produced indistinguishable attribute centres" % [
					PositionFamily.id_of(left), PositionFamily.id_of(right)])
	return failures


func _write_json(
	label: String,
	base: int,
	players: int,
	family_samples: Array[Sample],
	neutral_samples: Array[Sample],
	fingerprint: String,
	failures: PackedStringArray,
) -> void:
	var families: Array = []
	for family in PositionFamily.all():
		var arm: Sample = family_samples[family]
		var control: Sample = neutral_samples[family]
		var attributes: Array = []
		for attribute in AttributeKey.all():
			var values: PackedFloat64Array = arm.attribute_values[attribute]
			var quantiles: PackedFloat64Array = _quantiles(values)
			attributes.append({
				"key": String(AttributeKey.name_of(attribute)),
				"tier": _tier(family, attribute),
				"mean": CalibrationStatistics.mean(values),
				"sd": CalibrationStatistics.standard_deviation(values),
				"p5": quantiles[0], "p25": quantiles[1], "p50": quantiles[2],
				"p75": quantiles[3], "p95": quantiles[4],
				"cap_mean": CalibrationStatistics.mean(arm.caps[attribute]),
				"control_mean": CalibrationStatistics.mean(
					control.attribute_values[attribute]),
			})
		families.append({
			"family_id": String(PositionFamily.id_of(family)),
			"count": arm.count,
			"overall_mean": CalibrationStatistics.mean(arm.overall),
			"overall_sd": CalibrationStatistics.standard_deviation(arm.overall),
			"control_overall_mean": CalibrationStatistics.mean(control.overall),
			"maximum_potential_mean": CalibrationStatistics.mean(arm.maximum_potential),
			"peak_low_mean": CalibrationStatistics.mean(arm.peak_low),
			"peak_high_mean": CalibrationStatistics.mean(arm.peak_high),
			"archetypes": arm.archetypes,
			"attributes": attributes,
		})
	var payload: Dictionary = {
		"label": label,
		"seed_base": base,
		"players_per_family": players,
		"fingerprint": fingerprint,
		"failures": failures,
		"families": families,
	}
	DirAccess.make_dir_recursive_absolute("res://reports")
	var path: String = "res://reports/builder_family_distribution_%s.json" % label
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("could not write %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t", true))
	file.close()
	print("wrote %s" % path)
