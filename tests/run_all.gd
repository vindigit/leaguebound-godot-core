extends SceneTree


var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_random_reproduction()
	_test_attribute_contract()
	_test_possession_reproduction()
	_test_full_game_reproduction()
	_test_possession_contract()
	_test_golden_ledgers()
	_test_play_sim_parity()
	_test_balance_configuration_integrity()
	_test_simulation_balance_integrity()
	_test_builder_budget_exhaustion()
	_test_development_values_are_ordered()
	_test_detail_promotion_invariance()
	_test_growth_determinism()
	if _failures.is_empty():
		print("LeagueBound headless acceptance: PASS")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("LeagueBound headless acceptance: %d failure(s)" % _failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_random_reproduction() -> void:
	var first := SeededRandomSource.new(8675309)
	var second := SeededRandomSource.new(8675309)
	for index in range(32):
		_check(first.next_u32() == second.next_u32(), "random draw %d did not reproduce" % index)
	var parent := SeededRandomSource.new(42)
	var expected_child := parent.derive(&"possession:7")
	parent.next_u32()
	parent.next_u32()
	var actual_child := parent.derive(&"possession:7")
	_check(actual_child.next_u32() == expected_child.next_u32(), "child stream depended on parent call order")


func _test_attribute_contract() -> void:
	var attributes := PlayerAttributes.new()
	_check(AttributeKey.COUNT == 20, "attribute key count is not 20")
	_check(attributes.canonical_values().size() == 20, "player model does not contain 20 values")
	for key in AttributeKey.all():
		_check(Rating.is_valid_active(attributes.get_rating(key)), "attribute %s is outside 25-99" % AttributeKey.name_of(key))


func _test_possession_reproduction() -> void:
	var input := MatchFixtureFactory.standard_match()
	var first := PossessionEngine.new(input).simulate(
		MatchSnapshot.new(input), input, SeededRandomSource.new(1234))
	var second := PossessionEngine.new(input).simulate(
		MatchSnapshot.new(input), input, SeededRandomSource.new(1234))
	_check(first.elapsed_ms == second.elapsed_ms, "possession elapsed time did not reproduce")
	_check(first.events.size() == second.events.size(), "possession event count did not reproduce")
	for index in range(mini(first.events.size(), second.events.size())):
		_check(first.events[index].signature() == second.events[index].signature(), "possession event %d did not reproduce" % index)


func _test_full_game_reproduction() -> void:
	var input := MatchFixtureFactory.standard_match()
	var first := MatchEngine.new().simulate_match(input, SeededRandomSource.new(20260814))
	var second := MatchEngine.new().simulate_match(input, SeededRandomSource.new(20260814))
	_check(first.signature() == second.signature(), "full-game output did not reproduce")
	_check(first.final_result.home_score != first.final_result.away_score, "completed match remained tied")
	_check(first.final_result.final_event_sequence == first.events.size(), "final event sequence did not reconcile")
	_check(
		first.final_result.statistics.team_line(input.home.team_id).points == first.final_result.home_score,
		"home box score did not reconcile"
	)
	_check(
		first.final_result.statistics.team_line(input.away.team_id).points == first.final_result.away_score,
		"away box score did not reconcile"
	)
	for index in range(first.events.size()):
		_check(first.events[index].sequence == index + 1, "event ledger contains a sequence gap at %d" % index)


## The Stage 3 possession contract: one start and one terminal end per
## possession, stable identity, and an offensive rebound that continues the
## possession it belongs to rather than starting a new one.
func _test_possession_contract() -> void:
	var output := MatchEngine.new().simulate_match(
		MatchFixtureFactory.offensive_rebound_match(), SeededRandomSource.new(7001))
	var starts: Dictionary = {}
	var ends: Dictionary = {}
	for event in output.events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			starts[event.possession_id] = _possession_count(starts, event.possession_id) + 1
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			ends[event.possession_id] = _possession_count(ends, event.possession_id) + 1
			_check(
				not event.next_team_id.is_empty(),
				"possession %d ended without naming the next team" % event.possession_id)
	var continued := 0
	for record in output.possessions:
		_check(_possession_count(starts, record.possession_id) == 1,
			"possession %d does not have exactly one start" % record.possession_id)
		_check(_possession_count(ends, record.possession_id) == 1,
			"possession %d does not have exactly one end" % record.possession_id)
		continued += record.offensive_rebounds
	_check(continued > 0, "no offensive rebound continued a possession")
	for team_id: StringName in [
		output.final_result.home_team_id, output.final_result.away_team_id
	]:
		_check(
			output.final_result.statistics.team_line(team_id).engine_possessions
			== output.engine_possessions(team_id),
			"engine possessions disagree with the terminal records for %s" % team_id)
	var failures := output.final_result.statistics.reconcile()
	_check(failures.is_empty(), "box score did not reconcile: %s" % ", ".join(failures))


func _possession_count(counts: Dictionary, possession_id: int) -> int:
	if not counts.has(possession_id):
		return 0
	var value: int = counts[possession_id]
	return value


## Committed golden ledgers for the six required scenarios.
func _test_golden_ledgers() -> void:
	var file := FileAccess.open(GoldenScenarios.HASH_PATH, FileAccess.READ)
	if file == null:
		_failures.append("missing committed golden hashes at %s" % GoldenScenarios.HASH_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_failures.append("committed golden hashes are not a JSON object")
		return
	var document: Dictionary = parsed
	var scenarios: Dictionary = document["scenarios"]
	for scenario in GoldenScenarios.names():
		if not scenarios.has(String(scenario)):
			_failures.append("no committed golden hash for scenario %s" % scenario)
			continue
		var entry: Dictionary = scenarios[String(scenario)]
		var expected: String = entry["hash"]
		var output := GoldenScenarios.simulate_uncached(scenario)
		_check(
			MatchLedgerSerializer.hash_output(output) == expected,
			"golden ledger changed for scenario %s" % scenario)
		_check(
			GoldenScenarios.meets_requirement(scenario, output),
			"scenario %s no longer produces %s" % [
				scenario, GoldenScenarios.describe_requirement(scenario)])


## §23 / §27.5: Play, Sim, and Skip resolve through one authoritative path.
func _test_play_sim_parity() -> void:
	var simulated := MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(20260815))
	var session := MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(20260815))
	session.open()
	while not session.is_complete():
		session.advance_possession()
	_check(
		session.build_output().signature() == simulated.signature(),
		"stepped play diverged from a full simulation")


## Gate B0 for the simulation profile: every match tunable is named, has a
## unit and safe range, and sits inside it.
func _test_simulation_balance_integrity() -> void:
	var profile := SimulationBalanceProfile.new()
	var failures := profile.validate()
	_check(failures.is_empty(), "simulation balance invalid: %s" % ", ".join(failures))
	for tunable in profile.describe_tunables():
		_check(
			not tunable.tunable_name.is_empty() and not tunable.unit.is_empty(),
			"a simulation tunable is missing its name or unit")


## Gate B0: one validated profile loads offline and every tuneable has a name,
## unit, safe range, and version (`BALANCE_SPEC.md` §30, `GODOT_TDD.md` §5.6).
func _test_balance_configuration_integrity() -> void:
	var profiles := BalanceProfileSet.default_set()
	var failures := profiles.validate()
	_check(failures.is_empty(), "balance configuration invalid: %s" % ", ".join(failures))
	_check(not profiles.version_signature().is_empty(), "balance profile set is unversioned")


## §7.1 / OD-B: confirmation is blocked while creation AP remains, and creation
## currency never enters the career wallet.
func _test_builder_budget_exhaustion() -> void:
	var service := BuilderService.new()
	var family := PositionFamily.Value.WING
	var state := service.begin_build(
		family,
		ProspectProfile.Value.BALANCED,
		MaturityProfile.Value.AVERAGE,
		service.default_body_for_family(family),
		SeededRandomSource.new(20260815)
	)
	_check(not state.can_confirm(), "an unspent creation budget was confirmable")
	state.fill_remaining_anywhere()
	_check(state.remaining() == 0, "creation budget did not reach zero")
	_check(state.can_confirm(), "an exhausted budget was not confirmable")

	var confirmed := service.confirm(
		state, &"acceptance_user", 20260815, SeededRandomSource.new(20260815))
	_check(
		confirmed.point_ledger.balance() == 0.0,
		"creation Attribute Points leaked into the career wallet"
	)


## §6.3 / OD-D: the three development values are distinct and correctly ordered.
func _test_development_values_are_ordered() -> void:
	var service := BuilderService.new()
	var query := DevelopmentProjectionQuery.new(service.profiles())
	var family := PositionFamily.Value.GUARD
	var state := service.begin_build(
		family,
		ProspectProfile.Value.HIGH_UPSIDE,
		MaturityProfile.Value.LATE,
		service.default_body_for_family(family),
		SeededRandomSource.new(4242)
	)
	state.fill_remaining_anywhere()
	var view := query.builder_confirmation_view(state)

	_check(
		view.projection.current_overall <= view.projection.maximum_potential,
		"Current Overall exceeded Maximum Potential"
	)
	_check(
		view.projection.projected_peak.high <= view.projection.maximum_potential,
		"Projected Peak exceeded Maximum Potential"
	)
	_check(
		view.projection.projected_peak.low >= view.projection.current_overall,
		"Projected Peak fell below Current Overall"
	)


## §9.7.4 / OD-E: changing simulation detail level does not change the player.
func _test_detail_promotion_invariance() -> void:
	var service := BuilderService.new()
	var full := _acceptance_player(service, SimulationDetailLevel.Value.FULL)
	var reduced := _acceptance_player(service, SimulationDetailLevel.Value.REDUCED)
	_check(
		full.invariant_signature() == reduced.invariant_signature(),
		"detail level changed the player"
	)

	var before := reduced.invariant_signature()
	reduced.detail_level = SimulationDetailLevel.Value.FULL
	_check(
		reduced.invariant_signature() == before,
		"promotion to full detail changed committed state"
	)


## §7.4.3 rule 1 / OD-C: growth reproduces exactly from the versioned career
## seed, and never writes a rating.
func _test_growth_determinism() -> void:
	var service := BuilderService.new()
	var body_service := BodyMaturationService.new(service.profiles())

	var first := _acceptance_player(service, SimulationDetailLevel.Value.FULL)
	var second := _acceptance_player(service, SimulationDetailLevel.Value.FULL)
	var ratings_before := first.attributes.signature()

	for career_year in body_service.milestone_career_years():
		body_service.resolve_increment(first, career_year, SeededRandomSource.new(31337))
		body_service.resolve_increment(second, career_year, SeededRandomSource.new(31337))

	_check(
		first.body_state.signature() == second.body_state.signature(),
		"body growth did not reproduce from the career seed"
	)
	_check(
		first.attributes.signature() == ratings_before,
		"a body increment changed a public rating"
	)
	_check(
		first.body_state.projected_range.contains_body(first.body_state.realized_body),
		"the realized adult body left its stored projected range"
	)


func _acceptance_player(
	service: BuilderService,
	detail_level: int,
) -> PlayerDevelopmentState:
	var family := PositionFamily.Value.BIG
	var state := service.begin_build(
		family,
		ProspectProfile.Value.BALANCED,
		MaturityProfile.Value.AVERAGE,
		service.default_body_for_family(family),
		SeededRandomSource.new(31337)
	)
	state.fill_remaining_anywhere()
	var player := service.confirm(
		state, &"acceptance_npc", 31337, SeededRandomSource.new(31337))
	player.detail_level = detail_level
	return player
