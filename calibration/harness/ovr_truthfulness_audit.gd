class_name OvrTruthfulnessAudit
extends RefCounted

## Independent report instrument. Never supplied to a production resolver.
const VERSION: String = "ovr-truthfulness-v1"
const STAT_KEYS: PackedStringArray = [
	"seconds_played", "points", "field_goals_made", "field_goals_attempted",
	"three_pointers_made", "three_pointers_attempted", "free_throws_made",
	"free_throws_attempted", "offensive_rebounds", "defensive_rebounds", "assists",
	"steals", "blocks", "turnovers", "personal_fouls", "plus_minus", "touches",
	"passes_completed", "screens_set", "screen_advantages_created",
	"off_ball_actions", "advantages_created", "created_field_goals_made",
]


## Exact rational oracle for the current documented coefficients, not a second
## production calculator. Numerators independently derived over denominator2400.
static func oracle_numerator(values: Array[int]) -> int:
	assert(values.size() == 20, "oracle needs all twenty canonical attributes")
	var ordered: Array[int] = values.duplicate()
	ordered.sort()
	var all_sum: int = 0
	var top_sum: int = 0
	var bottom_sum: int = 0
	for index in range(20):
		all_sum += ordered[index]
		if index >= 12:
			top_sum += ordered[index]
		if index < 6:
			bottom_sum += ordered[index]
	return 78 * all_sum + 75 * top_sum + 40 * bottom_sum


static func oracle_display(values: Array[int]) -> int:
	var bounded: int = clampi(oracle_numerator(values), 25 * 2400, 99 * 2400)
	return (bounded + 1200) / 2400


## A broad complete freshman, constructed point-by-point through the actual
## legal Builder. Lowest actual rating is chosen among affordable candidates;
## canonical index breaks ties. No array writes manufacture its ratings.
static func legal_freshman(family: int, seed_value: int, player_id: StringName) -> PlayerDevelopmentState:
	var builder := BuilderService.new()
	var source := SeededRandomSource.new(seed_value)
	var build: BuilderState = builder.begin_build(
		family, ProspectProfile.Value.BALANCED, MaturityProfile.Value.AVERAGE,
		builder.default_body_for_family(family), source.derive(&"build"))
	while build.remaining() > 0:
		var chosen: int = -1
		for key in AttributeKey.all():
			if build.can_raise(key) and (chosen < 0 or build.rating_for(key) < build.rating_for(chosen)):
				chosen = key
		assert(chosen >= 0, "legal broad allocation exhausted affordable candidates")
		assert(build.raise_attribute(chosen), "Builder rejected selected affordable point")
	assert(build.can_confirm(), "completed allocation is not confirmable")
	var state: PlayerDevelopmentState = builder.confirm(
		build, player_id, seed_value, source.derive(&"confirm"))
	assert(freshman_legality_errors(state).is_empty(), "independent legal construction audit failed")
	return state


## Independent ledger arithmetic. Deliberately does not call BuilderRules or
## AttributeCostTable to establish cost: destination bands are the locked §9.1.
static func freshman_legality_errors(state: PlayerDevelopmentState) -> PackedStringArray:
	var errors: PackedStringArray = []
	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var bases: Array[int] = BuilderRules.body_adjusted_bases(state.body_state.confirmed_freshman_body,
		state.position_family, profiles.builder)
	var spend: int = 0
	for key in AttributeKey.all():
		var value: int = state.attributes.get_rating(key)
		if value < bases[key] or value < 25 or value > 75 or value > state.caps.cap_for(key):
			errors.append("invalid freshman rating %s" % AttributeKey.name_of(key))
		for destination in range(bases[key] + 1, value + 1):
			spend += independent_point_cost(destination)
	if state.creation_budget == null:
		errors.append("missing creation budget")
	elif state.creation_budget.granted != profiles.builder.creation_budget_for(state.prospect) \
			or spend != state.creation_budget.granted or state.creation_budget.remaining() != 0:
		errors.append("creation spend does not equal legal exhausted budget")
	if not BuilderRules.body_selection_failures(state.body_state.confirmed_freshman_body,
			state.position_family, profiles.builder).is_empty():
		errors.append("illegal body")
	return errors


static func independent_point_cost(destination: int) -> int:
	if destination <= 59: return 1
	if destination <= 69: return 2
	if destination <= 79: return 3
	if destination <= 89: return 5
	if destination <= 94: return 8
	return 12


## Grants exactly the AP the bounded intervention costs, then asks the normal
## manual development service to buy every point. Caps stay exact and unchanged.
static func improve(state: PlayerDevelopmentState, scoring_only: bool) -> Dictionary:
	var service := DevelopmentService.new()
	var before: Array[int] = state.attributes.canonical_values()
	var cap_before: String = state.caps.signature()
	var targets: Array[int] = before.duplicate()
	var cost: int = 0
	for key in AttributeKey.all():
		if scoring_only and key > AttributeKey.Key.FREE_THROW:
			continue
		targets[key] = mini(before[key] + 10, state.caps.cap_for(key))
		for destination in range(before[key] + 1, targets[key] + 1):
			cost += independent_point_cost(destination)
	service.grant_opportunity(state, 1, AttributePointSource.Value.TRAINING,
		DevelopmentExecutor.Value.MANUAL, float(cost), "OVR controlled attribute intervention")
	var applied: int = 0
	for key in AttributeKey.all():
		var requested: int = targets[key] - before[key]
		var actual: int = service.spend_general_ap(state, key, requested, 1, DevelopmentExecutor.Value.MANUAL)
		assert(actual == requested, "canonical service did not purchase the frozen intervention")
		applied += actual
	assert(state.caps.signature() == cap_before, "intervention changed exact caps")
	assert(is_zero_approx(state.point_ledger.balance()), "intervention left unexplained AP")
	assert(state.attributes.canonical_values() == targets, "intervention did not match bounded target")
	return {"ap_granted": cost, "rating_points_applied": applied, "before": before,
		"after": targets, "caps_unchanged": true}


static func family_role(family: int) -> int:
	if family == PositionFamily.Value.GUARD: return TacticalRole.Value.PRIMARY_CREATOR
	if family == PositionFamily.Value.WING: return TacticalRole.Value.SLASHER
	return TacticalRole.Value.INTERIOR_ANCHOR


static func family_position(family: int) -> StringName:
	if family == PositionFamily.Value.GUARD: return &"PG"
	if family == PositionFamily.Value.WING: return &"SF"
	return &"C"


static func match_player(state: PlayerDevelopmentState, rotation: int = RotationRole.Value.STARTER) -> PlayerMatchProfile:
	return PlayerMatchProfile.new(state.player_id,
		PositionProfile.new(family_position(state.position_family)),
		state.body_state.realized_body.duplicate_body(), state.attributes.duplicate_attributes(),
		[], PlayerTendencies.new(state.tendencies.values.duplicate()), rotation,
		TacticalRole.new(family_role(state.position_family)))


## Complete 2x2 venue/opener exposure. Gameplay seeds are unique per slot and
## deliberately reused across arms of the same matched comparison.
static func schedule(cluster: int, seed_first: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for slot in range(4):
		rows.append({"cluster": cluster, "slot": slot, "seed": seed_first + cluster * 4 + slot,
			"subject_home": slot == 0 or slot == 3, "subject_opens": slot == 0 or slot == 1})
	return rows


static func schedule_errors(rows: Array[Dictionary]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seeds: Dictionary = {}
	var exposure: Dictionary = {}
	for row in rows:
		var seed_value: int = row["seed"]
		if seeds.has(seed_value): errors.append("duplicate gameplay seed")
		seeds[seed_value] = true
		var key: String = "%s/%s" % [str(row["subject_home"]), str(row["subject_opens"])]
		exposure[key] = (exposure.get(key, 0) as int) + 1
	if rows.size() != 4 or exposure.size() != 4:
		errors.append("missing home/opener exposure")
	return errors


## Event-derived opportunity denominators. On-court possessions count the
## player present at POSSESSION_STARTED, consistent with terminal-record IDs;
## mid-possession substitutions don't create another possession opportunity.
static func measure(input: MatchInput, output: MatchSimulationOutput, player: PlayerMatchProfile,
		team_id: StringName) -> Dictionary:
	var line: PlayerStatLine = output.final_result.statistics.player_line(player.player_id)
	var row: Dictionary = {}
	for key in STAT_KEYS:
		row[String(key)] = line.get(String(key))
	row["on_court_offense_possessions"] = 0
	row["on_court_defense_possessions"] = 0
	row["opponent_fga_on_court"] = 0
	row["opponent_fgm_on_court"] = 0
	row["on_court_defensive_misses"] = 0
	var on_court: bool = false
	var starts: Dictionary = {}
	var ledger_touches: int = 0
	for event in output.events:
		if event.event_type == MatchDomainEvent.CHECK_IN and event.primary_player_id == player.player_id:
			on_court = true
		elif event.event_type == MatchDomainEvent.CHECK_OUT and event.primary_player_id == player.player_id:
			on_court = false
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			assert(not starts.has(event.possession_id), "duplicate possession start")
			starts[event.possession_id] = event.team_id
			if on_court:
				var term: String = "on_court_offense_possessions" if event.team_id == team_id else "on_court_defense_possessions"
				row[term] += 1
		if on_court and event.team_id != team_id:
			if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT: row["opponent_fga_on_court"] += 1
			if event.event_type == MatchDomainEvent.FIELD_GOAL_MADE: row["opponent_fgm_on_court"] += 1
			if event.event_type == MatchDomainEvent.FIELD_GOAL_MISSED: row["on_court_defensive_misses"] += 1
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED and event.primary_player_id == player.player_id:
			ledger_touches += 1
		if event.event_type == MatchDomainEvent.PASS_COMPLETED and event.secondary_player_id == player.player_id:
			ledger_touches += 1
	assert(starts.size() == output.possessions.size(), "ledger and terminal possession counts disagree")
	for possession in output.possessions:
		assert(starts.has(possession.possession_id) and starts[possession.possession_id] == possession.offense_team_id,
			"terminal possession does not match its start event")
	row["team_possessions"] = output.engine_possessions(team_id)
	row["opponent_possessions"] = output.possessions.size() - (row["team_possessions"] as int)
	row["team_score"] = output.final_result.home_score if team_id == input.home.team_id else output.final_result.away_score
	row["opponent_score"] = output.final_result.away_score if team_id == input.home.team_id else output.final_result.home_score
	row["team_margin"] = (row["team_score"] as int) - (row["opponent_score"] as int)
	row["won"] = 1 if (row["team_margin"] as int) > 0 else 0
	row["ledger_touches"] = ledger_touches
	row["player_id"] = String(player.player_id)
	row["position"] = String(player.positions.primary)
	row["rotation_role"] = String(RotationRole.id_of(player.rotation_role))
	row["tactical_role"] = String(player.tactical_role.id())
	row["values"] = player.attributes.canonical_values()
	row["current_ovr"] = OverallCalculator.current_overall(player.attributes, input.ratings_profile)
	row["raw_ovr"] = OverallCalculator.raw_overall(player.attributes.canonical_values(), input.ratings_profile)
	row["body"] = player.body.signature()
	row["tendencies"] = player.tendencies.values.duplicate()
	row["archetype"] = String(DerivedArchetype.classify(player.attributes, player.body,
		_family_for_position(player.positions.primary), ArchetypeProfile.default_profile()).label())
	return row


static func _family_for_position(position: StringName) -> int:
	if position == &"PG" or position == &"SG": return PositionFamily.Value.GUARD
	if position == &"C" or position == &"PF": return PositionFamily.Value.BIG
	return PositionFamily.Value.WING
