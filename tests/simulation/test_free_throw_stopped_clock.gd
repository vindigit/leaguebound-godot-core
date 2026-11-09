extends GdUnitTestSuite

func test_all_profiles_preserve_both_clocks_and_playing_time_during_attempts() -> void:
	var covered: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var input: MatchInput = CompetitionCatalog.match_for(competition, 0, 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(991001))
		var state := MatchSnapshot.new(input)
		var reducer := MatchStateReducer.new(input)
		var attempts: int = 0
		var clock_charged: int = 0
		var shot_clock_charged: int = 0
		var player_minutes_charged: int = 0
		for event: MatchDomainEvent in output.events:
			var before_clock: int = state.clock_ms
			var before_shot: int = state.shot_clock_ms
			var before_minutes: int = _played_ms(state)
			reducer.apply_event(state, event)
			if event.event_type in [MatchDomainEvent.FREE_THROW_MADE, MatchDomainEvent.FREE_THROW_MISSED]:
				attempts += 1
				clock_charged += before_clock - state.clock_ms
				shot_clock_charged += before_shot - state.shot_clock_ms
				player_minutes_charged += _played_ms(state) - before_minutes
		if attempts > 0:
			covered += 1
		assert_int(attempts).is_greater(0)
		assert_int(clock_charged).is_equal(0)
		assert_int(shot_clock_charged).is_equal(0)
		assert_int(player_minutes_charged).is_equal(0)
	assert_int(covered).is_equal(5)


func _played_ms(state: MatchSnapshot) -> int:
	var total: int = 0
	for team: TeamMatchState in [state.home, state.away]:
		for runtime: PlayerMatchRuntime in team.runtimes:
			total += runtime.played_ms
	return total


# Exercise awarded trips directly, including awards at the horn. The public
# possession entry correctly refuses to start a new possession at zero.
func test_awarded_one_two_and_three_shot_trips_preserve_the_whistle_clock() -> void:
	for remaining: int in [0, 1, 1500, 8000]:
		for count: int in [1, 2, 3]:
			var engine: PossessionEngine = _at_award(remaining, false)
			engine._resolve_free_throws(&"", count, false, SeededRandomSource.new(31))
			var taken: int = 0
			for event: MatchDomainEvent in engine._writer.events:
				if event.event_type in [MatchDomainEvent.FREE_THROW_MADE, MatchDomainEvent.FREE_THROW_MISSED]:
					taken += 1
					assert_int(event.clock_ms).is_equal(remaining)
			assert_int(taken).is_equal(count)
			assert_int(engine._state.clock_ms).is_equal(remaining)
			assert_int(_played_ms(engine._state)).is_equal(0)


func test_one_and_one_earns_second_attempt_only_after_first_make() -> void:
	var first_makes: int = 0
	var first_misses: int = 0
	for seed_value: int in range(1, 31):
		var engine: PossessionEngine = _at_award(1500, false)
		engine._resolve_free_throws(&"", 2, true, SeededRandomSource.new(seed_value))
		var attempts: Array[MatchDomainEvent] = []
		for event: MatchDomainEvent in engine._writer.events:
			if event.event_type in [MatchDomainEvent.FREE_THROW_MADE, MatchDomainEvent.FREE_THROW_MISSED]:
				attempts.append(event)
				assert_int(event.clock_ms).is_equal(1500)
		if attempts[0].event_type == MatchDomainEvent.FREE_THROW_MADE:
			first_makes += 1
			assert_int(attempts.size()).is_equal(2)
		else:
			first_misses += 1
			assert_int(attempts.size()).is_equal(1)
	assert_int(first_makes).is_greater(0)
	assert_int(first_misses).is_greater(0)


func test_intentional_miss_keeps_time_then_live_rebound_consumes_it() -> void:
	var engine: PossessionEngine = _at_award(6000, true)
	engine._state.away.score = 2
	engine._resolve_free_throws(&"", 1, false, SeededRandomSource.new(31))
	var intentional: int = 0
	var rebounds: int = 0
	for event: MatchDomainEvent in engine._writer.events:
		if event.event_type == MatchDomainEvent.FREE_THROW_MISSED and event.detail_id == &"intentional":
			intentional += 1
			assert_int(event.clock_ms).is_equal(6000)
		if event.event_type == MatchDomainEvent.REBOUND:
			rebounds += 1
			assert_int(event.clock_ms).is_less(6000)
	assert_int(intentional).is_equal(1)
	assert_int(rebounds).is_greater(0)


func _at_award(remaining: int, reboundable: bool) -> PossessionEngine:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	input.rule_profile.final_free_throw_reboundable = reboundable
	var engine := PossessionEngine.new(input)
	engine._state = MatchSnapshot.new(input)
	engine._state.period = input.rule_profile.regulation_periods
	engine._state.clock_ms = remaining
	engine._state.shot_clock_ms = 11000
	engine._state.possession_team_id = input.home.team_id
	engine._writer = MatchEventWriter.new(input.match_id, 0, engine._state.period, remaining)
	engine._writer.possession_id = 1
	engine._context = PossessionContext.new(input, engine._state, input.home.team_id,
		engine._matchup_resolver.resolve(input.home, engine._state.home, input.away, engine._state.away), 1)
	return engine
