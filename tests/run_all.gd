extends SceneTree


var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_random_reproduction()
	_test_attribute_contract()
	_test_possession_reproduction()
	_test_full_game_reproduction()
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
	var first := PossessionEngine.new().simulate(MatchSnapshot.new(input), input, SeededRandomSource.new(1234))
	var second := PossessionEngine.new().simulate(MatchSnapshot.new(input), input, SeededRandomSource.new(1234))
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
