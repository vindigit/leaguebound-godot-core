extends GdUnitTestSuite

## §9.4: administration never advances either clock. These fixtures enter at
## the award/whistle so the live action preceding it cannot hide an admin charge.
func test_nonbonus_whistle_preserves_clock_minutes_and_resets_without_expiry() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		for remaining: int in [0, 1, 999, 1000, 1001, 17000]:
			var engine: PossessionEngine = _at_whistle(competition, remaining)
			# Nonzero fatigue on court and bench catches both load and recovery.
			for team: TeamMatchState in [engine._state.home, engine._state.away]:
				for runtime: PlayerMatchRuntime in team.runtimes:
					runtime.acute_fatigue = 25.0
			var before_shot: int = engine._state.shot_clock_ms
			var before_fatigue: Array[float] = _fatigue(engine._state)
			var replay: MatchSnapshot = engine._state.copy()
			var call := FoulCall.new(true, FoulType.Value.NON_SHOOTING_DEFENSIVE,
				engine._context.defense_on_court()[0], engine._context.offense_on_court()[0], 0)
			engine._resolve_defensive_foul(call, SeededRandomSource.new(481))
			assert_int(engine._state.clock_ms).is_equal(remaining)
			assert_int(_played_ms(engine._state)).is_equal(0)
			assert_array(_fatigue(engine._state)).is_equal(before_fatigue)
			assert_bool(engine._terminated).is_false()
			assert_int(engine._state.away.team_fouls).is_equal(1)
			assert_int(engine._writer.events.size()).is_equal(2)
			var reducer := MatchStateReducer.new(engine._input)
			for event: MatchDomainEvent in engine._writer.events:
				assert_int(event.clock_ms).is_equal(remaining)
				reducer.apply_event(replay, event)
				assert_array(_fatigue(replay)).is_equal(before_fatigue)
				if event.event_type == MatchDomainEvent.FOUL:
					assert_int(replay.shot_clock_ms).is_equal(before_shot)
				else:
					assert_str(String(event.event_type)).is_equal(String(MatchDomainEvent.SHOT_CLOCK_RESET))
					assert_int(replay.shot_clock_ms).is_equal(mini(remaining, engine._rules.offensive_rebound_reset_seconds * 1000))


func test_intentional_miss_paced_rebound_boundary_and_eligibility() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var fixture: PossessionEngine = _at_whistle(competition, 5000)
		# Independent expectation from ClockResolver's rounded rebound draw and
		# _consume's <=0 horn. The direct putback has no action-time draw.
		var longest: int = roundi(fixture._balance.rebound_seconds_max * 1000.0 * fixture._rules.pace_multiplier)
		for remaining: int in [0, longest - 1, longest, longest + 1,
			fixture._balance.intentional_miss_clock_ms, fixture._balance.intentional_miss_clock_ms + 1]:
			fixture._state.clock_ms = remaining
			fixture._state.away.score = 2
			var expected: bool = remaining > longest and remaining <= fixture._balance.intentional_miss_clock_ms
			assert_bool(_miss(fixture, 1, 2)).override_failure_message(
				"%s clock=%d max_rebound=%d" % [fixture._rules.profile_id, remaining, longest]).is_equal(expected)
		fixture._state.clock_ms = longest + 1
		for margin: int in [-3, -2, -1, 0, 1, 2]:
			fixture._state.home.score = 10 + margin
			fixture._state.away.score = 10
			assert_bool(_miss(fixture, 0, 1)).is_equal(margin == -2)
		fixture._state.home.score = 8
		assert_bool(_miss(fixture, 0, 2)).is_false()
		assert_bool(_miss(fixture, 1, 3)).is_false()
		assert_bool(_miss(fixture, 2, 3)).is_true()
		fixture._state.period -= 1
		assert_bool(_miss(fixture, 1, 2)).is_false()
		fixture._state.period += 2
		assert_bool(_miss(fixture, 1, 2)).is_true()
		fixture._rules.final_free_throw_reboundable = false
		assert_bool(_miss(fixture, 1, 2)).is_false()


func test_boundary_intentional_miss_has_live_contested_board_and_same_timestamp_putback() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var offensive: int = 0
		var defensive: int = 0
		var putbacks: int = 0
		for seed_value: int in range(1, 41):
			var engine: PossessionEngine = _at_whistle(competition, 5000)
			var remaining: int = roundi(engine._balance.rebound_seconds_max * 1000.0 * engine._rules.pace_multiplier) + 1
			engine._state.clock_ms = remaining
			engine._writer.clock_ms = remaining
			engine._state.away.score = 2
			engine._resolve_free_throws(&"", 1, false, SeededRandomSource.new(seed_value))
			var rebound_clock: int = -1
			var intentional: int = 0
			var putback_actor: StringName = &""
			for event: MatchDomainEvent in engine._writer.events:
				if event.event_type == MatchDomainEvent.FREE_THROW_MISSED and event.detail_id == &"intentional":
					intentional += 1
					assert_int(event.clock_ms).is_equal(remaining)
				if event.event_type == MatchDomainEvent.REBOUND and rebound_clock < 0:
					rebound_clock = event.clock_ms
					assert_int(event.clock_ms).is_greater(0)
					assert_int(event.clock_ms).is_less(remaining)
					if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
						offensive += 1
					else:
						defensive += 1
				if event.event_type == MatchDomainEvent.ACTION_SELECTED and event.action_id == ActionFamily.id_of(ActionFamily.Value.PUTBACK):
					putback_actor = event.primary_player_id
					assert_int(event.clock_ms).is_equal(rebound_clock)
				if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT and not putback_actor.is_empty():
					putbacks += 1
					assert_str(String(event.primary_player_id)).is_equal(String(putback_actor))
					assert_int(event.clock_ms).is_equal(rebound_clock)
					break
			assert_int(intentional).is_equal(1)
			assert_int(rebound_clock).is_greater(0)
		assert_int(offensive).is_greater(0)
		assert_int(defensive).is_greater(0)
		assert_int(putbacks).is_greater(0)


func test_maximum_rebound_draw_expires_at_equality_and_survives_one_ms_above() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		for pace_override: float in [-1.0, 0.73426]:
			for extra_ms: int in [0, 1]:
				var engine: PossessionEngine = _at_whistle(competition, 5000)
				if pace_override > 0.0:
					engine._rules.pace_multiplier = pace_override
					engine._clock = ClockResolver.new(engine._balance, engine._rules)
				var duration: int = roundi(engine._balance.rebound_seconds_max * 1000.0 * engine._rules.pace_multiplier)
				engine._state.clock_ms = duration + extra_ms
				engine._writer.clock_ms = engine._state.clock_ms
				engine._state.away.score = 2
				assert_bool(_miss(engine, 0, 1)).is_equal(extra_ms == 1)
				# Down one forces an ordinary missed FT, independent of the tactic.
				engine._state.away.score = 1
				engine._resolve_free_throws(&"", 1, false, FixedDraw.new(0.999999))
				var rebounds: int = 0
				for event: MatchDomainEvent in engine._writer.events:
					if event.event_type == MatchDomainEvent.REBOUND:
						rebounds += 1
						assert_int(event.clock_ms).is_equal(1)
				assert_int(rebounds).is_equal(extra_ms)
				assert_int(engine._state.clock_ms).is_equal(extra_ms)


func test_awarded_pairs_read_first_make_at_same_timestamp_before_intentional_final_miss() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		for one_and_one: bool in [false, true]:
			var engine: PossessionEngine = _at_whistle(competition, 5000)
			var remaining: int = roundi(engine._balance.rebound_seconds_max * 1000.0 * engine._rules.pace_multiplier) + 1
			engine._state.clock_ms = remaining
			engine._writer.clock_ms = remaining
			engine._state.away.score = 3
			engine._resolve_free_throws(&"", 2, one_and_one, FixedDraw.new(0.0))
			var attempts: Array[MatchDomainEvent] = []
			for event: MatchDomainEvent in engine._writer.events:
				if event.event_type in [MatchDomainEvent.FREE_THROW_MADE, MatchDomainEvent.FREE_THROW_MISSED]:
					attempts.append(event)
				if event.event_type == MatchDomainEvent.REBOUND:
					break
			assert_int(attempts.size()).is_equal(2)
			assert_str(String(attempts[0].event_type)).is_equal(String(MatchDomainEvent.FREE_THROW_MADE))
			assert_str(String(attempts[1].detail_id)).is_equal("intentional")
			assert_int(attempts[0].clock_ms).is_equal(remaining)
			assert_int(attempts[1].clock_ms).is_equal(remaining)


func test_live_action_after_nonbonus_administration_still_consumes_clock() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var engine: PossessionEngine = _at_whistle(competition, 17000)
		var call := FoulCall.new(true, FoulType.Value.NON_SHOOTING_DEFENSIVE,
			engine._context.defense_on_court()[0], engine._context.offense_on_court()[0], 0)
		engine._resolve_defensive_foul(call, SeededRandomSource.new(481))
		engine._context.ball_handler_id = engine._context.offense_on_court()[0]
		engine._run_action_loop(SeededRandomSource.new(82))
		assert_int(engine._state.clock_ms).is_less(17000)
		assert_int(_played_ms(engine._state)).is_equal((17000 - engine._state.clock_ms) * 10)


func test_horn_awards_finish_before_regulation_and_overtime_transition() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		for extra_period: int in [0, 1]:
			for deficit: int in [1, 2]:
				var engine: PossessionEngine = _at_whistle(competition, 0)
				engine._state.period += extra_period
				engine._writer.period = engine._state.period
				engine._state.away.score = deficit
				var session := MatchSession.new(engine._input, SeededRandomSource.new(24))
				session._snapshot = engine._state.copy()
				engine._resolve_free_throws(&"", 2, false, MadeFreeThrows.new())
				session._commit(engine._writer)
				assert_int(session._snapshot.home.score).is_equal(2)
				assert_int(session._snapshot.clock_ms).is_equal(0)
				assert_int(_played_ms(session._snapshot)).is_equal(0)
				session._advance_period()
				assert_bool(session.is_complete()).is_equal(deficit == 1)
				if deficit == 2:
					assert_int(session._snapshot.period).is_equal(engine._state.period + 1)
					assert_int(session._snapshot.clock_ms).is_equal(engine._rules.overtime_seconds * 1000)
				var attempts: int = 0
				for event: MatchDomainEvent in session.events():
					if event.event_type == MatchDomainEvent.FREE_THROW_MADE:
						attempts += 1
						assert_int(event.clock_ms).is_equal(0)
					if event.event_type == MatchDomainEvent.PERIOD_ENDED:
						assert_int(attempts).is_equal(2)


class MadeFreeThrows extends RandomSource:
	func next_float() -> float:
		return 0.0
	func derive(_label: StringName) -> RandomSource:
		return self


class FixedDraw extends RandomSource:
	var value: float
	func _init(p_value: float) -> void:
		value = p_value
	func next_float() -> float:
		return value
	func range_int(_minimum: int, maximum: int) -> int:
		return maximum
	func derive(_label: StringName) -> RandomSource:
		return self


func _miss(engine: PossessionEngine, index: int, count: int) -> bool:
	return EndgameStrategy.should_intentionally_miss_final_free_throw(engine._context, engine._balance, index, count)


func _at_whistle(competition: int, remaining: int) -> PossessionEngine:
	var input: MatchInput = CompetitionCatalog.match_for(competition, 0, 0.5)
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


func _played_ms(state: MatchSnapshot) -> int:
	var total: int = 0
	for team: TeamMatchState in [state.home, state.away]:
		for runtime: PlayerMatchRuntime in team.runtimes:
			total += runtime.played_ms
	return total


func _fatigue(state: MatchSnapshot) -> Array[float]:
	var result: Array[float] = []
	for team: TeamMatchState in [state.home, state.away]:
		for runtime: PlayerMatchRuntime in team.runtimes:
			result.append(runtime.acute_fatigue)
	return result
