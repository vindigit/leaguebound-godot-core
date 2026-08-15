extends SceneTree

## Headless Builder calibration harness.
##
## Sweeps every prospect profile, maturity profile, position family, body
## variant, and allocation strategy from fixed seeds, and reports the completed
## build distribution against the owner-locked bands in `BALANCE_SPEC.md`
## §7.3.2 (OD-B).
##
## ## Locked acceptance targets
##
##   High Upside          44-48 current OVR
##   Balanced             46-50
##   Ready Now            48-52
##   extreme specialists  within ~2 OVR of the applicable band
##   ordinary builds      not above ~54
##
## §7.3.3 names the tunables: "The locked bands are the acceptance target; the
## creation AP budget and the body-adjusted starting bases are the tunables."
## This harness measures; it never widens a band. §2.2: "An owner-locked target
## is never satisfied by widening its own band."
##
## Run:
##   godot --headless --path . --script res://tools/builder_calibration_harness.gd

const REPORT_DIRECTORY: String = "res://reports"
const REPORT_PATH: String = "res://reports/builder_calibration.json"

## Locked §7.3.2 bands, indexed by `ProspectProfile.Value`.
const BAND_LOW: Array[int] = [48, 46, 44]
const BAND_HIGH: Array[int] = [52, 50, 48]
## §7.3.2 "approximately two OVR outside its profile band in either direction".
const SPECIALIST_TOLERANCE: int = 2
## §7.3.2 "an ordinary completed build must not exceed approximately 54".
const ORDINARY_CEILING: int = 54

## A build touching this few attributes is classified an extreme specialist:
## "a build concentrating its budget into very few attributes while accepting
## severe weaknesses" (§7.3.2).
const EXTREME_SPECIALIST_ATTRIBUTE_LIMIT: int = 6

const RANDOM_BUILDS_PER_CELL: int = 4
const BASE_SEED: int = 20260815


## One completed build. A typed record rather than a `Dictionary` so the
## evaluation reads fields under the project's strict typing instead of casting
## Variants at every access.
class BuildRecord extends RefCounted:
	var family: int
	var prospect: int
	var maturity: int
	var body_variant: int
	var strategy: String
	var random_index: int
	var seed_value: int
	var ap_granted: int
	var ap_spent: int
	var ap_remaining: int
	var can_confirm: bool
	var blocking_failures: PackedStringArray
	var current_overall: int
	var maximum_potential: int
	var peak_low: int
	var peak_high: int
	var archetype: String
	var derived_position: String
	var touched_attributes: int
	var caps: Array[int]
	var ratings: Array[int]
	var body: BodyProfile
	var projected_range: BodyRange
	var opportunity_notes: PackedStringArray

	var specialist_limit: int

	func is_extreme_specialist() -> bool:
		return touched_attributes <= specialist_limit

	func label() -> String:
		var suffix: String = "#%d" % random_index if random_index >= 0 else ""
		return "%s/%s/%s/body%d/%s%s" % [
			PositionFamily.id_of(family),
			ProspectProfile.id_of(prospect),
			MaturityProfile.id_of(maturity),
			body_variant,
			strategy,
			suffix,
		]

	func to_dictionary() -> Dictionary:
		return {
			"family": String(PositionFamily.id_of(family)),
			"prospect": String(ProspectProfile.id_of(prospect)),
			"maturity": String(MaturityProfile.id_of(maturity)),
			"body_variant": body_variant,
			"strategy": strategy,
			"random_index": random_index,
			"seed": seed_value,
			"creation_ap_granted": ap_granted,
			"creation_ap_spent": ap_spent,
			"creation_ap_remaining": ap_remaining,
			"can_confirm": can_confirm,
			"blocking_failures": blocking_failures,
			"current_overall": current_overall,
			"maximum_potential": maximum_potential,
			"projected_peak_low": peak_low,
			"projected_peak_high": peak_high,
			"archetype": archetype,
			"derived_position": derived_position,
			"touched_attributes": touched_attributes,
			"is_extreme_specialist": is_extreme_specialist(),
			"caps": caps,
			"ratings": ratings,
			"body": {
				"height": body.height_inches,
				"weight": body.weight_pounds,
				"wingspan": body.wingspan_inches,
				"standing_reach": body.standing_reach_inches,
			},
			"projected_adult_range": {
				"height": [projected_range.height_minimum, projected_range.height_maximum],
				"weight": [projected_range.weight_minimum, projected_range.weight_maximum],
				"wingspan": [projected_range.wingspan_minimum, projected_range.wingspan_maximum],
				"standing_reach": [
					projected_range.standing_reach_minimum,
					projected_range.standing_reach_maximum,
				],
			},
			"opportunity_notes": opportunity_notes,
		}


var _service: BuilderService
var _query: DevelopmentProjectionQuery
var _profiles: BalanceProfileSet
var _records: Array[BuildRecord] = []
var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_profiles = BalanceProfileSet.default_set()
	_service = BuilderService.new(_profiles)
	_query = DevelopmentProjectionQuery.new(_profiles)

	var configuration_failures: PackedStringArray = _profiles.validate()
	if not configuration_failures.is_empty():
		for failure in configuration_failures:
			printerr("configuration: %s" % failure)
		quit(1)
		return

	_sweep()
	_evaluate()
	_write_report()
	_print_summary()

	if _failures.is_empty():
		print("Builder calibration: PASS")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("Builder calibration: %d failure(s)" % _failures.size())
	quit(1)


func _sweep() -> void:
	var strategies: Array[String] = [
		"conventional", "flat", "specialist_scoring", "specialist_defense",
		"incompatible", "extreme_specialist",
	]
	for family in PositionFamily.all():
		for prospect in ProspectProfile.all():
			for maturity in MaturityProfile.all():
				for body_variant in range(3):
					for strategy in strategies:
						_records.append(_build(
							family, prospect, maturity, body_variant, strategy, -1))
					for index in range(RANDOM_BUILDS_PER_CELL):
						_records.append(_build(
							family, prospect, maturity, body_variant, "randomized", index))


func _build(
	family: int,
	prospect: int,
	maturity: int,
	body_variant: int,
	strategy: String,
	random_index: int,
) -> BuildRecord:
	var seed_value: int = _seed_for(
		family, prospect, maturity, body_variant, strategy, random_index)
	var source: RandomSource = SeededRandomSource.new(seed_value)
	var body: BodyProfile = _body_for(family, body_variant)

	var state: BuilderState = _service.begin_build(family, prospect, maturity, body, source)
	var granted: int = state.budget.granted

	if strategy == "randomized":
		state.randomize_allocation(source.derive(StringName("build:%d" % random_index)))
	else:
		state.spend_remaining_weighted(_weights_for(strategy, family))
		state.fill_remaining_anywhere()

	var view: BuilderConfirmationView = _query.builder_confirmation_view(state)

	var record: BuildRecord = BuildRecord.new()
	record.family = family
	record.prospect = prospect
	record.maturity = maturity
	record.body_variant = body_variant
	record.strategy = strategy
	record.random_index = random_index
	record.seed_value = seed_value
	record.ap_granted = granted
	record.ap_spent = state.budget.spent
	record.ap_remaining = state.budget.remaining()
	record.can_confirm = state.can_confirm()
	record.blocking_failures = view.blocking_failures
	record.current_overall = view.projection.current_overall
	record.maximum_potential = view.projection.maximum_potential
	record.peak_low = view.projection.projected_peak.low
	record.peak_high = view.projection.projected_peak.high
	record.archetype = view.archetype.label()
	record.derived_position = view.derived_position
	record.touched_attributes = _touched_attribute_count(state)
	record.specialist_limit = EXTREME_SPECIALIST_ATTRIBUTE_LIMIT
	record.caps = state.caps.values()
	record.ratings = state.values()
	record.body = body
	record.projected_range = view.projected_body_range
	record.opportunity_notes = view.opportunity_notes
	return record


## Every build the harness produces must be confirmable and must have spent its
## whole budget. This is the §7.1 / OD-B exhaustion evidence Gate B1 requires.
func _evaluate() -> void:
	var ordinary_high_water: int = 0
	var ordinary_high_water_label: String = "none"

	for record in _records:
		var name: String = record.label()

		if record.ap_remaining != 0:
			_failures.append("%s left %d creation AP unspent" % [name, record.ap_remaining])
		if record.ap_spent != record.ap_granted:
			_failures.append("%s spend %d does not reconcile with its grant %d" % [
				name, record.ap_spent, record.ap_granted])
		if not record.can_confirm:
			_failures.append("%s is not confirmable: %s" % [
				name, ", ".join(record.blocking_failures)])

		if record.current_overall > record.maximum_potential:
			_failures.append("%s Current Overall exceeds Maximum Potential" % name)
		if record.peak_high > record.maximum_potential:
			_failures.append("%s Projected Peak exceeds Maximum Potential" % name)
		if record.peak_low < record.current_overall:
			_failures.append("%s Projected Peak falls below Current Overall" % name)

		var low: int = BAND_LOW[record.prospect]
		var high: int = BAND_HIGH[record.prospect]
		if record.is_extreme_specialist():
			low -= SPECIALIST_TOLERANCE
			high += SPECIALIST_TOLERANCE
		if record.current_overall < low or record.current_overall > high:
			_failures.append("%s landed at %d OVR, outside %d-%d" % [
				name, record.current_overall, low, high])

		if not record.is_extreme_specialist():
			if record.current_overall > ORDINARY_CEILING:
				_failures.append("%s ordinary build reached %d OVR, above the %d ceiling" % [
					name, record.current_overall, ORDINARY_CEILING])
			if record.current_overall > ordinary_high_water:
				ordinary_high_water = record.current_overall
				ordinary_high_water_label = name

	print("Ordinary completed-build high water: %d OVR (%s), ceiling %d" % [
		ordinary_high_water, ordinary_high_water_label, ORDINARY_CEILING])


func _print_summary() -> void:
	print("Builds evaluated: %d" % _records.size())
	print("")
	print("%-14s %-11s %5s %5s %5s %5s %8s" % [
		"prospect", "class", "n", "min", "med", "max", "band"])
	for prospect in ProspectProfile.all():
		for specialist_class: bool in [false, true]:
			var values: Array[int] = []
			for record in _records:
				if record.prospect != prospect:
					continue
				if record.is_extreme_specialist() != specialist_class:
					continue
				values.append(record.current_overall)
			if values.is_empty():
				continue
			values.sort()
			var low: int = BAND_LOW[prospect]
			var high: int = BAND_HIGH[prospect]
			if specialist_class:
				low -= SPECIALIST_TOLERANCE
				high += SPECIALIST_TOLERANCE
			print("%-14s %-11s %5d %5d %5d %5d %8s" % [
				ProspectProfile.id_of(prospect),
				"specialist" if specialist_class else "ordinary",
				values.size(),
				values[0],
				values[values.size() / 2],
				values[values.size() - 1],
				"%d-%d" % [low, high],
			])


func _write_report() -> void:
	if not DirAccess.dir_exists_absolute(REPORT_DIRECTORY):
		var error: Error = DirAccess.make_dir_recursive_absolute(REPORT_DIRECTORY)
		assert(error == OK, "unable to create the calibration report directory")

	var builds: Array = []
	for record in _records:
		builds.append(record.to_dictionary())

	var payload: Dictionary = {
		"generated_by": "tools/builder_calibration_harness.gd",
		"base_seed": BASE_SEED,
		"balance_versions": _profiles.version_signature(),
		"creation_ap_budget": _profiles.builder.creation_ap_budget,
		"prospect_ap_modifiers": _profiles.builder.prospect_ap_modifiers,
		"starting_bases": {
			"technical": _profiles.builder.base_technical,
			"iq": _profiles.builder.base_iq,
			"physical": _profiles.builder.base_physical,
		},
		"locked_bands": {
			"ready_now": [BAND_LOW[0], BAND_HIGH[0]],
			"balanced": [BAND_LOW[1], BAND_HIGH[1]],
			"high_upside": [BAND_LOW[2], BAND_HIGH[2]],
			"specialist_tolerance": SPECIALIST_TOLERANCE,
			"ordinary_ceiling": ORDINARY_CEILING,
		},
		"failures": _failures,
		"builds": builds,
	}

	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	assert(file != null, "unable to open the calibration report for writing")
	file.store_string(JSON.stringify(payload, "  "))
	file.close()
	print("Report written to %s" % REPORT_PATH)


func _seed_for(
	family: int,
	prospect: int,
	maturity: int,
	body_variant: int,
	strategy: String,
	random_index: int,
) -> int:
	return (
		BASE_SEED
		+ family * 1000003
		+ prospect * 100003
		+ maturity * 10007
		+ body_variant * 1009
		+ absi(strategy.hash() % 997) * 13
		+ (random_index + 1) * 7
	)


## Three body variants per family: the short/light end of the credible range,
## the median, and the tall/heavy end. This is what makes the body-driven §7.1
## redistribution visible in the distribution rather than averaged away.
func _body_for(family: int, variant: int) -> BodyProfile:
	var builder: BuilderProfile = _profiles.builder
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


func _touched_attribute_count(state: BuilderState) -> int:
	var bases: Array[int] = state.bases()
	var values: Array[int] = state.values()
	var touched: int = 0
	for attribute in AttributeKey.all():
		if values[attribute] > bases[attribute]:
			touched += 1
	return touched


func _weights_for(strategy: String, family: int) -> Array[float]:
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(0.0)

	match strategy:
		"flat":
			for attribute in AttributeKey.all():
				weights[attribute] = 1.0
		"conventional":
			for attribute in AttributeKey.all():
				weights[attribute] = 0.25
			for attribute: int in CapGenerator.FAMILY_SECONDARY[family]:
				weights[attribute] = 0.70
			for attribute: int in CapGenerator.FAMILY_PRIMARY[family]:
				weights[attribute] = 1.00
		"specialist_scoring":
			weights[AttributeKey.Key.THREE_POINT] = 1.0
			weights[AttributeKey.Key.MID_RANGE] = 0.9
			weights[AttributeKey.Key.SHORT_RANGE] = 0.8
			weights[AttributeKey.Key.FREE_THROW] = 0.6
			weights[AttributeKey.Key.OFFENSIVE_IQ] = 0.5
		"specialist_defense":
			weights[AttributeKey.Key.PERIMETER_DEFENSE] = 1.0
			weights[AttributeKey.Key.INTERIOR_DEFENSE] = 0.9
			weights[AttributeKey.Key.BLOCKING] = 0.8
			weights[AttributeKey.Key.STEALING] = 0.7
			weights[AttributeKey.Key.DEFENSIVE_IQ] = 0.6
		"incompatible":
			# Deliberately invest against the body: a Guard buying rim
			# protection, a Big buying handle. §7.3.2 and `GDD.md` §6.1 keep
			# this legal and unblocked; the harness proves it stays legal.
			match family:
				PositionFamily.Value.GUARD:
					weights[AttributeKey.Key.BLOCKING] = 1.0
					weights[AttributeKey.Key.INTERIOR_DEFENSE] = 0.9
					weights[AttributeKey.Key.OFFENSIVE_REBOUNDING] = 0.7
					weights[AttributeKey.Key.STRENGTH] = 0.6
				PositionFamily.Value.BIG:
					weights[AttributeKey.Key.HANDLE] = 1.0
					weights[AttributeKey.Key.THREE_POINT] = 0.9
					weights[AttributeKey.Key.SPEED] = 0.7
					weights[AttributeKey.Key.PASSING] = 0.6
				_:
					weights[AttributeKey.Key.BLOCKING] = 1.0
					weights[AttributeKey.Key.HANDLE] = 0.9
					weights[AttributeKey.Key.FREE_THROW] = 0.5
		"extreme_specialist":
			# The narrowest legal concentration: three attributes, everything
			# else left at its body-adjusted base.
			weights[AttributeKey.Key.THREE_POINT] = 1.0
			weights[AttributeKey.Key.HANDLE] = 0.9
			weights[AttributeKey.Key.PASSING] = 0.8
		_:
			for attribute in AttributeKey.all():
				weights[attribute] = 1.0

	return weights
