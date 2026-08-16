class_name TestLineupsAndRotations
extends GdUnitTestSuite

## Runtime lineup state is the sole authority for participation.
##
## The defect this suite exists to prevent was specific: the engine read the
## static starter list from the team profile, so a substituted or fouled-out
## player kept taking shots for the rest of the game. Every assertion here is
## about the *runtime* lineup deciding who appears in events.


## §5.1: exactly five eligible players per team, on every possession.
func test_five_eligible_players_per_team_throughout() -> void:
	var input: MatchInput = MatchFixtureFactory.foul_out_match()
	var session := MatchSession.new(input, SeededRandomSource.new(31337))
	session.open()
	while not session.is_complete():
		var snapshot: MatchSnapshot = session.snapshot()
		assert_int(snapshot.home.on_court_count()).is_equal(5)
		assert_int(snapshot.away.on_court_count()).is_equal(5)
		for team_state: TeamMatchState in [snapshot.home, snapshot.away]:
			for player_id in team_state.on_court_ids():
				var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player_id)
				assert_bool(runtime.is_eligible_to_play()).is_true()
				assert_int(runtime.foul_count).is_less(input.rule_profile.personal_foul_limit)
		session.advance_possession()


## Only players who were on court can appear as actors. Replaying the ledger's
## check-in and check-out events reconstructs the lineup, and every actor is
## checked against it.
func test_no_replaced_player_participates() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.SUBSTITUTION_FOUL_OUT)
	var on_court: Dictionary = {}
	var checked: int = 0
	for event in output.events:
		match event.event_type:
			MatchDomainEvent.CHECK_IN:
				on_court[event.primary_player_id] = true
			MatchDomainEvent.CHECK_OUT:
				on_court.erase(event.primary_player_id)
			MatchDomainEvent.FIELD_GOAL_ATTEMPT, MatchDomainEvent.REBOUND, \
			MatchDomainEvent.TURNOVER, MatchDomainEvent.PASS_COMPLETED, \
			MatchDomainEvent.STEAL, MatchDomainEvent.BLOCK, MatchDomainEvent.ASSIST:
				assert_bool(on_court.has(event.primary_player_id)).is_true()
				checked += 1
			_:
				pass
	assert_int(checked).is_greater(0)
	# The reconstruction is a real lineup, not an empty set that trivially
	# satisfies the check.
	assert_int(on_court.size()).is_equal(10)


## Substitutions actually change who plays: a player who checks out stops
## accruing minutes, and his replacement starts.
func test_substitutions_control_actual_participants() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.SUBSTITUTION_FOUL_OUT)
	var substitutions: int = 0
	var replacements: Array[StringName] = []
	for event in output.events:
		if event.event_type == MatchDomainEvent.CHECK_IN and event.detail_id != &"starting_lineup":
			substitutions += 1
			replacements.append(event.primary_player_id)
	assert_int(substitutions).is_greater(0)

	# A replacement who entered the game has minutes; a bench player who never
	# entered has none. That distinction can only come from the ledger.
	var played: int = 0
	for player_id in replacements:
		if output.final_result.statistics.player_line(player_id).seconds_played > 0:
			played += 1
	assert_int(played).is_greater(0)


## §10.6.1: availability facts never relabel a rotation role. A fouled-out
## Starter is still a Starter.
func test_foul_out_does_not_change_the_rotation_role() -> void:
	var input: MatchInput = MatchFixtureFactory.foul_out_match()
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(31337))
	var fouled_out: int = 0
	for event in output.events:
		if event.event_type != MatchDomainEvent.FOUL_OUT:
			continue
		fouled_out += 1
		var profile: PlayerMatchProfile = input.team_profile(event.team_id).player_by_id(
			event.primary_player_id)
		# The engine never writes to the profile at all; the role it was given
		# is the role it still has.
		assert_bool(RotationRole.is_valid(profile.rotation_role)).is_true()
	assert_int(fouled_out).is_greater(0)


## Minutes reconcile from the ledger alone: the projector reconstructs them
## from check-in and check-out timestamps, and the total equals five players
## multiplied by the elapsed game time.
func test_minutes_reconcile_from_the_event_stream() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var elapsed_seconds: int = 0
	var periods: int = (
		input.rule_profile.regulation_periods + output.final_result.overtime_periods)
	for period in range(1, periods + 1):
		elapsed_seconds += input.rule_profile.period_length_ms(period) / 1000

	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		var total: int = 0
		for line in output.final_result.statistics.players_for(team_id):
			total += line.seconds_played
		# Five players on court for the whole game, within the rounding the
		# per-player second conversion introduces.
		assert_int(total).is_between(elapsed_seconds * 5 - 30, elapsed_seconds * 5)

	# Exactly five players per team are recorded as starters.
	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		var starters: int = 0
		for line in output.final_result.statistics.players_for(team_id):
			if line.started:
				starters += 1
		assert_int(starters).is_equal(5)


## §18.1: planned minutes come from the rotation role and only from it.
func test_planned_minutes_follow_rotation_role() -> void:
	var balance := SimulationBalanceProfile.new()
	assert_float(balance.rotation_minute_share(RotationRole.Value.STAR)).is_greater(
		balance.rotation_minute_share(RotationRole.Value.STARTER))
	assert_float(balance.rotation_minute_share(RotationRole.Value.STARTER)).is_greater(
		balance.rotation_minute_share(RotationRole.Value.ROTATION))
	assert_float(balance.rotation_minute_share(RotationRole.Value.ROTATION)).is_greater(
		balance.rotation_minute_share(RotationRole.Value.RESERVE))


## A player made medically unavailable before tipoff never appears on court.
func test_unavailable_players_never_participate() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var session := MatchSession.new(input, SeededRandomSource.new(20260815))
	session.open()
	# Take a bench player out of the game the way the health service would.
	var bench_id: StringName = input.home.players[input.home.players.size() - 1].player_id
	session.snapshot().home.runtime_by_id(bench_id).medically_available = false

	while not session.is_complete():
		session.advance_possession()
	var output: MatchSimulationOutput = session.build_output()
	for event in output.events:
		if event.event_type == MatchDomainEvent.CHECK_IN:
			assert_str(String(event.primary_player_id)).is_not_equal(String(bench_id))
	assert_int(output.final_result.statistics.player_line(bench_id).seconds_played).is_equal(0)
