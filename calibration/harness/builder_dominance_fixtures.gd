class_name BuilderDominanceFixtures
extends RefCounted

## Observation-only legal freshman fixtures. Allocation always passes through
## BuilderState.raise_attribute; confirmation always uses BuilderService.
const VERSION: String = "builder-dominance-fixtures-v1"
const PRIMARY_COUNT: int = 18
const FAMILY_HEIGHTS: Array[int] = [70, 74, 78]
const BASES: Array[int] = [35,35,35,35,35,35,35,35,38,35,35,35,35,38,35,35,45,45,45,45]


static func portfolio() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var definitions: Array[Array] = [
		["balanced_flat", "flat", []],
		["perimeter_offense", "weighted", [2,3,4,8]],
		["finishing_offense", "weighted", [0,1,16,19]],
		["creation", "weighted", [5,6,7,8]],
		["perimeter_defense", "weighted", [9,11,13,16]],
		["rim_defense", "weighted", [10,12,13,17]],
		["rebounding", "weighted", [14,15,17,19]],
		["speed_physical", "weighted", [16,18,19]],
		["strength_physical", "weighted", [17,18,19]],
		["three_and_defense", "weighted", [3,9,11,13]],
		["creator_defender", "weighted", [5,6,7,9,13]],
		["exploit_three_handle", "weighted", [3,5,16]],
		["exploit_iq_only", "weighted", [8,13]],
		["exploit_low_cost", "cheap", []],
		["body_small", "flat", []],
		["body_large", "flat", []],
		["tendency_score", "flat", []],
		["tendency_defense", "flat", []],
	]
	for definition: Array in definitions:
		var id: String = definition[0]
		var spec: Dictionary = {"id": id, "strategy": definition[1],
			"focus": definition[2], "family": PositionFamily.Value.WING,
			"prospect": ProspectProfile.Value.BALANCED, "body_variant": 1,
			"tendencies": [3,3,3,3,3,3,3,3,3,3], "primary": true}
		if id == "body_small":
			spec["body_variant"] = 0
		elif id == "body_large":
			spec["body_variant"] = 2
		elif id == "tendency_score":
			spec["tendencies"] = [5,5,1,1,5,5,5,1,5,5]
		elif id == "tendency_defense":
			spec["tendencies"] = [1,1,5,5,1,1,1,5,1,1]
		result.append(spec)
	for prospect: int in [ProspectProfile.Value.READY_NOW, ProspectProfile.Value.HIGH_UPSIDE]:
		var spec: Dictionary = result[0].duplicate(true)
		spec["id"] = "profile_%s" % ProspectProfile.id_of(prospect)
		spec["prospect"] = prospect
		spec["primary"] = false
		result.append(spec)
	for family: int in [PositionFamily.Value.GUARD, PositionFamily.Value.BIG]:
		var spec: Dictionary = result[0].duplicate(true)
		spec["id"] = "family_%s" % PositionFamily.id_of(family)
		spec["family"] = family
		spec["primary"] = false
		result.append(spec)
	return result


static func body_for(family: int, variant: int) -> BodyProfile:
	var height: int = FAMILY_HEIGHTS[family] + (variant - 1) * 4
	var reference: int = int(roundf(160.0 + float(height - 72) * 4.6))
	var weight: int = reference + (variant - 1) * 22
	var span: int = height + [-2,2,7][variant]
	return BodyProfile.new(height, weight, span, BodyProfile.derive_standing_reach(height, span))


static func construct(spec: Dictionary, seed_value: int, player_id: StringName) -> Dictionary:
	var service := BuilderService.new()
	var source := SeededRandomSource.new(seed_value)
	var state: BuilderState = service.begin_build(spec["family"] as int, spec["prospect"] as int,
		MaturityProfile.Value.AVERAGE, body_for(spec["family"] as int, spec["body_variant"] as int), source)
	var bases: Array[int] = state.bases()
	var initial_caps: Array[int] = state.caps.values()
	var preview_confirmable: bool = state.can_confirm()
	var strategy: String = spec["strategy"]
	if strategy == "weighted":
		var weights: Array[float] = []
		for attribute in range(AttributeKey.COUNT):
			weights.append(1.0 if attribute in spec["focus"] else 0.0)
		state.spend_remaining_weighted(weights)
		state.fill_remaining_anywhere()
	else:
		while state.remaining() > 0:
			var best: int = -1
			var best_value: int = 10000
			for attribute in range(AttributeKey.COUNT):
				if not state.can_raise(attribute):
					continue
				var priority: int = state.rating_for(attribute) - bases[attribute]
				if strategy == "cheap":
					priority = state.next_point_cost(attribute) * 100 + state.rating_for(attribute)
				if best == -1 or priority < best_value:
					best = attribute
					best_value = priority
			assert(best >= 0, "legal allocation exhausted headroom before AP")
			assert(state.raise_attribute(best), "legal allocation failed")
	var sliders: Array[int] = []
	for value: int in spec["tendencies"]:
		sliders.append(value)
	state.tendencies = PlayerTendencies.new(sliders)
	assert(state.can_confirm(), "every experimental player must confirm")
	var confirmed: PlayerDevelopmentState = service.confirm(state, player_id, seed_value, source)
	var record: Dictionary = {"build_id": spec["id"], "primary": spec["primary"],
		"strategy": strategy, "focus": spec["focus"], "family": spec["family"],
		"prospect": spec["prospect"], "maturity": MaturityProfile.Value.AVERAGE,
		"seed": seed_value, "body_variant": spec["body_variant"],
		"body": [confirmed.body().height_inches,confirmed.body().weight_pounds,
			confirmed.body().wingspan_inches,confirmed.body().standing_reach_inches],
		"bases": bases, "ratings": confirmed.attributes.canonical_values(),
		"caps": confirmed.caps.values(), "initial_caps": initial_caps,
		"tendencies": confirmed.tendencies.values, "ap_granted": confirmed.creation_budget.granted,
		"ap_spent": confirmed.creation_budget.spent, "ap_remaining": confirmed.creation_budget.remaining(),
		"preview_confirmable": preview_confirmable, "current_overall": OverallCalculator.current_overall(
			confirmed.attributes, RatingsProfile.default_profile()),
		"maximum_potential": OverallCalculator.maximum_potential_overall(confirmed.caps, RatingsProfile.default_profile()),
		"balance_versions": confirmed.balance_version, "confirmed": true}
	var failures: PackedStringArray = independent_legality(record)
	assert(failures.is_empty(), "independent fixture legality: %s" % ", ".join(failures))
	return {"state": confirmed, "record": record}


## Separate arithmetic and literal locked limits: no BuilderRules or cost-table
## validator is called here. Exact seeded caps are replayed independently by the
## tests; this routine verifies the archived immutable cap vector and spend.
static func independent_legality(record: Dictionary) -> PackedStringArray:
	var failures: PackedStringArray = []
	var family: int = record["family"]
	var prospect: int = record["prospect"]
	if family < 0 or family > 2 or prospect < 0 or prospect > 2 or record["maturity"] != 1:
		failures.append("family/prospect/maturity domain")
		return failures
	var body: Array = record["body"]
	var values: Array = record["ratings"]
	var bases: Array = record["bases"]
	var caps: Array = record["caps"]
	var granted: int = [235,195,155][prospect]
	if values.size() != 20 or bases.size() != 20 or caps.size() != 20 \
			or body.size() != 4 or (record["tendencies"] as Array).size() != 10:
		failures.append("canonical vector count")
		return failures
	if body[0] < FAMILY_HEIGHTS[family] - 4 or body[0] > FAMILY_HEIGHTS[family] + 4:
		failures.append("freshman family height")
	var weight_reference: int = int(roundf(160.0 + float((body[0] as int) - 72) * 4.6))
	if absi((body[1] as int) - weight_reference) > 22:
		failures.append("freshman weight")
	if (body[2] as int) < (body[0] as int) - 2 or (body[2] as int) > (body[0] as int) + 7:
		failures.append("freshman wingspan")
	if body[3] != int(roundf(float(body[0] as int) * 0.585 + float(body[2] as int) * 0.720)):
		failures.append("derived standing reach")
	if not failures.is_empty():
		return failures
	var cost: int = 0
	var body_sum: int = 0
	var body_absolute: int = 0
	for attribute in range(20):
		var value: int = values[attribute]
		var base: int = bases[attribute]
		var cap: int = caps[attribute]
		var adjustment: int = base - BASES[attribute]
		body_sum += adjustment
		body_absolute += absi(adjustment)
		if absi(adjustment) > 4:
			failures.append("body per-attribute adjustment")
		if value < base or value < 25 or value > 75 or value > cap:
			failures.append("rating/base/cap/starting maximum")
		if cap < 40 or cap > 99:
			failures.append("exact cap domain")
		for destination in range(base + 1, value + 1):
			cost += 1 if destination <= 59 else (2 if destination <= 69 else 3)
	if absi(body_sum) > 1 or body_absolute > 18:
		failures.append("body redistribution total/zero sum")
	if caps != record["initial_caps"]:
		failures.append("caps changed during allocation")
	# Independently reconstruct immutable seeded facts without running allocation
	# or its validator. Bounds/cost checks above use literal locked constraints.
	var replay: BuilderState = BuilderService.new().begin_build(family, prospect,
		record["maturity"] as int, BodyProfile.new(body[0] as int,body[1] as int,body[2] as int,body[3] as int),
		SeededRandomSource.new(record["seed"] as int))
	if replay.bases() != bases or replay.caps.values() != caps:
		failures.append("seeded base/cap reconstruction")
	if cost != granted or record["ap_granted"] != granted or record["ap_spent"] != cost \
			or record["ap_remaining"] != 0:
		failures.append("independent AP reconciliation/exhaustion")
	if record["preview_confirmable"] or not record["confirmed"]:
		failures.append("preview/confirmation gate")
	for slider: int in record["tendencies"]:
		if slider < 1 or slider > 5:
			failures.append("tendency domain")
	return failures


static func as_match_player(state: PlayerDevelopmentState, rotation: int,
		role: int, position: StringName) -> PlayerMatchProfile:
	return PlayerMatchProfile.new(state.player_id, PositionProfile.new(position),
		state.body().duplicate_body(), PlayerAttributes.from_values(state.attributes.canonical_values()),
		[], PlayerTendencies.new(state.tendencies.values), rotation, TacticalRole.new(role))


static func context(cell: int) -> Dictionary:
	assert(cell >= 0 and cell < 8, "context cell")
	return {"cell": cell, "role": TacticalRole.Value.UTILITY_ENERGY if cell < 4 else TacticalRole.Value.SHOOTER,
		"lineup": "balanced" if (cell % 4) < 2 else "spacing",
		"opponent": "perimeter" if cell % 2 == 0 else "rim"}


static func experiment_cells(primary: bool, cells: Array[int]) -> Array[int]:
	if primary:
		return cells.duplicate()
	var selected: Array[int] = [0]
	return selected


static func match_for(spec: Dictionary, variation: int, cell: int) -> Dictionary:
	var phase: int = variation % 4
	var identities: PackedInt32Array = CompetitionCatalog.population_roster_variations(variation - phase)
	var ctx: Dictionary = context(cell)
	var subject_team: Dictionary = _team(&"subject", identities[0], ctx["lineup"] as String, spec, ctx["role"] as int)
	var opponent_team: Dictionary = _team(&"opponent", identities[1], ctx["opponent"] as String, {}, 0)
	var subject: TeamMatchProfile = subject_team["team"]
	var opponent: TeamMatchProfile = opponent_team["team"]
	var home_subject: bool = phase == 0 or phase == 3
	var opener: StringName = subject.team_id if phase < 2 else opponent.team_id
	var input := MatchInput.new(StringName("builder_%d_%d" % [variation,cell]),
		StringName("builder_game_%d_%d" % [variation,cell]),
		CompetitionRuleProfile.high_school_profile(), SimulationBalanceProfile.new(),
		subject if home_subject else opponent, opponent if home_subject else subject,
		opener, RatingsProfile.default_profile(), 0.5)
	return {"input": input, "subject_id": subject_team["subject_id"],
		"build_record": subject_team["build_record"], "subject_roster": identities[0],
		"opponent_roster": identities[1], "context": ctx,
		"teammate_signature": subject_team["teammate_signature"],
		"opponent_signature": opponent_team["teammate_signature"]}


static func _team(team_id: StringName, roster_identity: int, composition: String,
		subject_spec: Dictionary, subject_role: int) -> Dictionary:
	var profiles: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	var roles: Array[int] = [0,2,3,6,8,1,4,7,5,9]
	var positions: Array[StringName] = [&"PG",&"SG",&"SF",&"PF",&"C",&"PG",&"SG",&"SF",&"PF",&"C"]
	var families: Array[int] = [0,0,1,1,2,0,0,1,1,2]
	var subject_slot: int = -1
	if not subject_spec.is_empty():
		subject_slot = [0,2,4][subject_spec["family"]]
	var record: Dictionary = {}
	var signatures: PackedStringArray = []
	var subject_id: StringName = &""
	for slot in range(10):
		var spec: Dictionary = portfolio()[0].duplicate(true)
		spec["family"] = families[slot]
		# Composition changes investment/assignment through the same Builder.
		if composition == "spacing" and slot != 0 and slot != 5:
			spec["strategy"] = "weighted"
			spec["focus"] = [3,6,9,18]
		elif composition == "perimeter":
			spec["strategy"] = "weighted"
			spec["focus"] = [9,11,13,16] if slot % 5 < 3 else [10,15,17]
		elif composition == "rim":
			spec["strategy"] = "weighted"
			spec["focus"] = [10,12,13,15] if slot % 5 >= 2 else [5,6,9]
		var role: int = roles[slot]
		if slot == subject_slot:
			spec = subject_spec
			role = subject_role
		var id_value: StringName = StringName("%s_p%d" % [team_id,slot])
		var seed_value: int = 910000 + roster_identity * 101 + slot * 1009
		var constructed: Dictionary = construct(spec, seed_value, id_value)
		var state: PlayerDevelopmentState = constructed["state"]
		profiles.append(as_match_player(state,
			RotationRole.Value.STARTER if slot < 5 else RotationRole.Value.ROTATION,
			role, positions[slot]))
		if slot < 5:
			starters.append(id_value)
		if slot == subject_slot:
			record = constructed["record"]
			subject_id = id_value
		else:
			signatures.append("%s:%s:%s:%d" % [id_value,state.attributes.signature(),state.body().signature(),role])
	return {"team": TeamMatchProfile.new(team_id,profiles,starters,0.5),
		"build_record": record, "subject_id": subject_id,
		"teammate_signature": "|".join(signatures).sha256_text()}
