extends SceneTree

## Attribute marginal-value and sensitivity suite (`BALANCE_SPEC.md` Â§31 report
## 2, Â§27.2; `SIMULATION_SPEC.md` Â§8; Gate B1).
##
## `BALANCE_SPEC.md` Â§29.2 item 3 records the gap this closes: "Attribute
## monotonicity tests are explicitly deferred in
## `tests/simulation/test_attribute_contracts.gd`. Only addressability is
## currently verified."
##
## Two layers are measured, and the report keeps them apart because they answer
## different questions and carry different uncertainty.
##
## **Capability layer.** The Â§5.2 weighted mean is an exact function of the
## twenty ratings, so raising one rating with every other input held constant
## produces an exact movement, not an estimate. Monotonic direction and the
## 50-to-80 effect are therefore reported without a confidence interval â€” there
## is nothing to be uncertain about â€” and any non-monotonicity is a defect
## rather than noise.
##
## **Probability layer.** Where a capability reaches a resolved outcome the
## suite samples the real resolver at the Â§27.1 isolated-boundary sample size,
## so the reported make, turnover, steal, block, and rebound movements carry
## Wilson intervals.
##
## Two guardrails from Â§5.2 are checked directly:
##
## - a secondary amplifier (Offensive or Defensive IQ) must not move a
##   capability more than `MAX_AMPLIFIER_SHARE_OF_PRIMARY` of what that
##   capability's own named primary skill moves it;
## - an infrequent skill must retain a real effect in its own context.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_attribute_sensitivity.gd -- \
##       [--resolutions=N] [--label=NAME]

## Â§27.1: "One isolated probability/function boundary | 100,000 resolutions per
## test point".
const DEFAULT_RESOLUTIONS: int = 100000

## The matched rating steps. 50 and 80 are the pair Â§27.2 names; the others make
## the monotonicity check a real curve rather than a two-point line.
const STEPS: PackedInt32Array = [40, 50, 65, 80, 90]
const LOW_STEP: int = 50
const HIGH_STEP: int = 80

## The context every probe holds constant.
const HELD_RATING: int = 65


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var resolutions: int = CalibrationCli.int_option(options, &"resolutions", DEFAULT_RESOLUTIONS)
	var label: String = CalibrationCli.string_option(options, &"label", "sensitivity")

	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var ratings: RatingsProfile = CompetitionCatalog.ratings_profile()
	var calculator := CapabilityCalculator.new(ratings, balance)

	var context := ReportContext.create(
		&"attribute_sensitivity",
		"Attribute marginal-value and sensitivity",
		CompetitionCatalog.rules_for(CalibrationTargets.Competition.TOP_DOMESTIC_PRO),
		balance, SeededRandomSource.new(1).get_version(), ratings)
	context.sample_count = resolutions
	context.sample_unit = "resolutions per probability test point"
	context.seed_description = "1..%d per test point" % resolutions
	context.notes.append(
		"Â§27.1 isolated-boundary sample is %d resolutions per test point; this run used %d."
			% [CalibrationTargets.REQUIRED_PROBABILITY_BOUNDARY_RESOLUTIONS, resolutions])
	context.notes.append(
		"Capability movements are exact functions of the ratings and carry no interval. "
		+ "Probability movements are sampled and carry Wilson intervals.")
	context.notes.append(
		"Box-score, role-relative, team-impact, and fatigue/availability observables are "
		+ "NOT covered by this run; they require the match-level suite.")

	var report := CalibrationReport.new(context)
	report.add_metric(CalibrationMetric.boolean(
		&"sample.meets_certification_size",
		"Whether this run reached the Â§27.1 isolated-boundary sample size.",
		resolutions >= CalibrationTargets.REQUIRED_PROBABILITY_BOUNDARY_RESOLUTIONS,
		CalibrationTargets.sample_size_source(), resolutions))

	var rows: Array = []
	for attribute in range(AttributeKey.COUNT):
		rows.append(_judge_attribute(report, calculator, ratings, attribute))
	report.add_section(&"attribute_rows", rows)
	_judge_amplifiers(report, calculator, ratings)
	_judge_shot_probabilities(report, balance, ratings, resolutions)

	report.finish()
	_print_table(rows)
	quit(ReportWriter.publish(report, "attribute_sensitivity_%s" % label))


## Every capability that names this attribute as its primary skill, plus every
## capability that merely weights it. The first set is where the attribute must
## move things strongly; the second is where it may move things a little.
func _judge_attribute(
	report: CalibrationReport,
	calculator: CapabilityCalculator,
	ratings: RatingsProfile,
	attribute: int,
) -> Dictionary:
	var name_value: StringName = AttributeKey.name_of(attribute)
	var primary: Array[int] = _capabilities_with_primary(ratings, attribute)
	var weighted: Array[int] = _capabilities_weighting(ratings, attribute)

	# The addressability half of the contract: every attribute must reach at
	# least one capability at all. Â§5.2 gives all twenty a home.
	report.add_metric(CalibrationMetric.boolean(
		StringName("attribute.%s.is_addressed" % name_value),
		"The attribute is weighted by at least one Â§5.2 capability.",
		not weighted.is_empty(), "BALANCE_SPEC.md Â§5.2"))
	if weighted.is_empty():
		return {"attribute": String(name_value), "addressed": false}

	# Direction and effect are measured on the capability this attribute moves
	# most, which is its own primary where it has one.
	var probe: int = weighted[0] if primary.is_empty() else primary[0]
	var curve: PackedFloat64Array = _capability_curve(calculator, ratings, attribute, probe)
	var monotonic: bool = _is_non_decreasing(curve)
	var low: float = _capability_at(calculator, ratings, attribute, probe, LOW_STEP)
	var high: float = _capability_at(calculator, ratings, attribute, probe, HIGH_STEP)
	var relative: float = 0.0 if low <= 0.0 else (high - low) / low

	report.add_metric(CalibrationMetric.boolean(
		StringName("attribute.%s.monotonic" % name_value),
		"Raising the attribute across %s never lowers %s."
			% [str(STEPS), CapabilityKey.id_of(probe)],
		monotonic, CalibrationTargets.attribute_effect_direction_source()))
	report.add_metric(CalibrationMetric.banded(
		StringName("attribute.%s.effect_50_to_80" % name_value),
		"Relative increase in %s from rating 50 to rating 80, every other rating "
			% CapabilityKey.id_of(probe)
			+ "held at %d. Exact: the Â§5.2 mean is a deterministic function." % HELD_RATING,
		"capability evaluations", relative,
		CalibrationBand.new(
			CalibrationTargets.MIN_RELATIVE_EFFECT_50_TO_80, 100.0,
			CalibrationTargets.attribute_effect_direction_source()),
		STEPS.size()))

	return {
		"attribute": String(name_value),
		"addressed": true,
		"primary_capabilities": _ids(primary),
		"weighted_capabilities": _ids(weighted),
		"probe_capability": String(CapabilityKey.id_of(probe)),
		"curve": curve,
		"relative_effect_50_to_80": relative,
		"monotonic": monotonic,
	}


## Â§5.2: "IQ improves the circumstances in which a skill is used and cannot
## replace the named primary skill." Measured directly: for every capability
## that weights an IQ rating alongside a different primary, the IQ movement must
## stay under its share of the primary's movement.
func _judge_amplifiers(
	report: CalibrationReport,
	calculator: CapabilityCalculator,
	ratings: RatingsProfile,
) -> void:
	for capability in range(CapabilityKey.COUNT):
		var weights: CapabilityWeightSet = ratings.capability_weights(capability)
		for amplifier: int in [AttributeKey.Key.OFFENSIVE_IQ, AttributeKey.Key.DEFENSIVE_IQ]:
			if not weights.attribute_keys.has(amplifier):
				continue
			if weights.primary_attribute == amplifier:
				continue
			var amplifier_effect: float = (
				_capability_at(calculator, ratings, amplifier, capability, HIGH_STEP)
				- _capability_at(calculator, ratings, amplifier, capability, LOW_STEP))
			var primary_effect: float = (
				_capability_at(
					calculator, ratings, weights.primary_attribute, capability, HIGH_STEP)
				- _capability_at(
					calculator, ratings, weights.primary_attribute, capability, LOW_STEP))
			var share: float = 0.0 if primary_effect <= 0.0 else amplifier_effect / primary_effect
			report.add_metric(CalibrationMetric.banded(
				StringName("amplifier.%s.in.%s" % [
					AttributeKey.name_of(amplifier), CapabilityKey.id_of(capability)]),
				"Movement in %s from raising %s 50 to 80, as a share of the movement "
					% [CapabilityKey.id_of(capability), AttributeKey.name_of(amplifier)]
					+ "from raising its named primary skill %s over the same range."
					% AttributeKey.name_of(weights.primary_attribute),
				"capability evaluations", share,
				CalibrationBand.new(
					0.0, CalibrationTargets.MAX_AMPLIFIER_SHARE_OF_PRIMARY,
					"BALANCE_SPEC.md Â§5.2"),
				2))


## The sampled layer: the five shooting ratings against the real make model, at
## the Â§27.1 isolated-boundary sample size.
func _judge_shot_probabilities(
	report: CalibrationReport,
	balance: SimulationBalanceProfile,
	ratings: RatingsProfile,
	resolutions: int,
) -> void:
	var zones: PackedInt32Array = [
		ShotZone.Value.CLOSE_NON_RIM, ShotZone.Value.MIDRANGE, ShotZone.Value.STANDARD_THREE]
	var attributes: PackedInt32Array = [
		AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.MID_RANGE, AttributeKey.Key.THREE_POINT]
	for index in range(zones.size()):
		var zone: int = zones[index]
		var attribute: int = attributes[index]
		var low: int = _sample_makes(balance, ratings, attribute, zone, LOW_STEP, resolutions)
		var high: int = _sample_makes(balance, ratings, attribute, zone, HIGH_STEP, resolutions)
		var low_rate: float = float(low) / float(resolutions)
		var high_rate: float = float(high) / float(resolutions)
		var relative: float = 0.0 if low_rate <= 0.0 else (high_rate - low_rate) / low_rate
		report.add_metric(CalibrationMetric.banded(
			StringName("shot.%s.%s.effect_50_to_80" % [
				AttributeKey.name_of(attribute), ShotZone.id_of(zone)]),
			"Relative increase in realized make rate from %s at 50 to %s at 80, "
				% [AttributeKey.name_of(attribute), AttributeKey.name_of(attribute)]
				+ "sampled from the open, balanced Â§13.1 baseline.",
			"sampled attempts", relative,
			CalibrationBand.new(
				CalibrationTargets.MIN_RELATIVE_EFFECT_50_TO_80, 100.0,
				CalibrationTargets.attribute_effect_direction_source()),
			resolutions * 2,
			CalibrationStatistics.proportion_difference_half_width(
				low, resolutions, high, resolutions)))


## Draws `resolutions` attempts at the Â§13.1 open baseline for one rating value.
func _sample_makes(
	balance: SimulationBalanceProfile,
	ratings: RatingsProfile,
	attribute: int,
	zone: int,
	rating: int,
	resolutions: int,
) -> int:
	var attributes: PlayerAttributes = _attributes_with(attribute, rating)
	var capability: float = ratings.capability_weights(
		CapabilityKey.shotmaking_for_zone(zone)).evaluate(attributes, 0.0)
	var probability: float = clampf(
		balance.shot_baseline(zone, capability, false),
		balance.shot_floor(zone, false),
		balance.shot_ceiling(zone, false))
	var source := SeededRandomSource.new(9000 + rating * 31 + zone)
	var makes: int = 0
	for index in range(resolutions):
		if source.next_float() < probability:
			makes += 1
	return makes


# --- helpers -----------------------------------------------------------------

func _capability_curve(
	calculator: CapabilityCalculator,
	ratings: RatingsProfile,
	attribute: int,
	capability: int,
) -> PackedFloat64Array:
	var curve := PackedFloat64Array()
	for step in STEPS:
		curve.append(_capability_at(calculator, ratings, attribute, capability, step))
	return curve


func _capability_at(
	calculator: CapabilityCalculator,
	ratings: RatingsProfile,
	attribute: int,
	capability: int,
	rating: int,
) -> float:
	return ratings.capability_weights(capability).evaluate(
		_attributes_with(attribute, rating), 0.0)


## Every rating held at `HELD_RATING` except the one under test. This is the
## "hold the complete match context constant" requirement, applied to the pure
## capability function.
func _attributes_with(attribute: int, rating: int) -> PlayerAttributes:
	var values: Array[int] = []
	for index in range(AttributeKey.COUNT):
		values.append(rating if index == attribute else HELD_RATING)
	return PlayerAttributes.from_values(values)


func _capabilities_with_primary(ratings: RatingsProfile, attribute: int) -> Array[int]:
	var matching: Array[int] = []
	for capability in range(CapabilityKey.COUNT):
		if ratings.capability_weights(capability).primary_attribute == attribute:
			matching.append(capability)
	return matching


func _capabilities_weighting(ratings: RatingsProfile, attribute: int) -> Array[int]:
	var matching: Array[int] = []
	for capability in range(CapabilityKey.COUNT):
		if ratings.capability_weights(capability).attribute_keys.has(attribute):
			matching.append(capability)
	return matching


func _ids(capabilities: Array[int]) -> Array:
	var names: Array = []
	for capability in capabilities:
		names.append(String(CapabilityKey.id_of(capability)))
	return names


func _is_non_decreasing(curve: PackedFloat64Array) -> bool:
	for index in range(1, curve.size()):
		if curve[index] < curve[index - 1] - 0.000001:
			return false
	return true


func _flag(row: Dictionary, key: String) -> bool:
	var value: bool = row[key]
	return value


func _number(row: Dictionary, key: String) -> float:
	var value: float = row[key]
	return value


func _print_table(rows: Array) -> void:
	print("")
	print("  %-24s %8s %10s %-30s" % ["attribute", "monotone", "50->80", "probe capability"])
	for entry: Dictionary in rows:
		var row: Dictionary = entry
		var addressed: bool = row["addressed"]
		if not addressed:
			print("  %-24s %8s %10s %-30s" % [row["attribute"], "n/a", "n/a", "UNADDRESSED"])
			continue
		print("  %-24s %8s %9.1f%% %-30s" % [
			row["attribute"],
			"yes" if _flag(row, "monotonic") else "NO",
			100.0 * _number(row, "relative_effect_50_to_80"),
			row["probe_capability"],
		])
