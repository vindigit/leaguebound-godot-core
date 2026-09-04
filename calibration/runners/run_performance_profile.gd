extends SceneTree

## Performance profile of the match engine ("profile before changing
## algorithms").
##
## The report separates two things that are easy to conflate:
##
## 1. **Cost per complete game**, measured end to end, which is the number the
##    10 ms calibration goal and the 5 ms stretch goal are stated against.
## 2. **Cost per primitive**, measured in isolation and multiplied by the rate
##    the profiled game actually invokes it, so the report says *where* the time
##    goes rather than asserting a hunch.
##
## The primitives are the ones the Stage 4 brief names: RNG stream derivation,
## event allocation and serialization, projector lookup, candidate generation,
## state copying, and capability calculation.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_performance_profile.gd -- \
##       [--games=N] [--label=NAME]

const DEFAULT_GAMES: int = 20
const WARMUP_GAMES: int = 3
const MICRO_ITERATIONS: int = 20000

## One measured primitive and how often a game invokes it.
class Primitive extends RefCounted:
	var name_value: StringName
	var us_per_call: float
	var calls_per_game: float

	func _init(p_name: StringName, p_us: float, p_calls: float) -> void:
		name_value = p_name
		us_per_call = p_us
		calls_per_game = p_calls

	func us_per_game() -> float:
		return us_per_call * calls_per_game

	func share_of(game_ms: float) -> float:
		if game_ms <= 0.0:
			return 0.0
		return us_per_game() / (game_ms * 1000.0)


## Whole-game measurements.
class GameProfile extends RefCounted:
	var ms_per_game: float = 0.0
	var games_per_second: float = 0.0
	var possessions_per_second: float = 0.0
	var events_per_game: float = 0.0
	var possessions_per_game: float = 0.0
	var derives_per_game: float = 0.0
	var draws_per_game: float = 0.0
	var derives_per_possession: float = 0.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var label: String = CalibrationCli.string_option(options, &"label", "baseline")

	var context := ReportContext.create(
		&"performance_profile",
		"Match-engine performance profile (%s)" % label,
		CompetitionCatalog.rules_for(CalibrationTargets.Competition.TOP_DOMESTIC_PRO),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_count = games
	context.sample_unit = "complete reference games"
	context.seed_description = "1..%d" % games
	context.notes.append("reference game: top domestic professional profile, ten-player rosters")
	context.notes.append(
		"microbenchmarks: %d iterations per primitive, measured in isolation" % MICRO_ITERATIONS)

	var game: GameProfile = _profile_games(games)
	var primitives: Array[Primitive] = _profile_primitives(game)

	var report := CalibrationReport.new(context)
	report.add_metric(CalibrationMetric.raw(
		&"performance.ms_per_game",
		"Wall-clock milliseconds for one complete reference game, end to end, headless.",
		"complete reference games", game.ms_per_game, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.games_per_second",
		"Complete reference games resolved per wall-clock second, single process.",
		"complete reference games", game.games_per_second, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.possessions_per_second",
		"Team possessions resolved per wall-clock second, single process.",
		"team possessions", game.possessions_per_second, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.events_per_game",
		"Domain events written to the ledger per complete game.",
		"complete reference games", game.events_per_game, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.possessions_per_game",
		"Terminal possession records per complete game, both teams.",
		"complete reference games", game.possessions_per_game, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.stream_derivations_per_game",
		"Calls to RandomSource.derive per complete game.",
		"complete reference games", game.derives_per_game, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.stream_derivations_per_possession",
		"Calls to RandomSource.derive per team possession.",
		"team possessions", game.derives_per_possession, games))
	report.add_metric(CalibrationMetric.raw(
		&"performance.random_draws_per_game",
		"Calls to next_float, next_u32, and range_int per complete game.",
		"complete reference games", game.draws_per_game, games))

	var rows: Array = []
	for primitive in primitives:
		report.add_metric(CalibrationMetric.raw(
			StringName("primitive.%s.us_per_call" % primitive.name_value),
			"Microseconds per call, measured in isolation.",
			"isolated invocations", primitive.us_per_call, MICRO_ITERATIONS))
		report.add_metric(CalibrationMetric.raw(
			StringName("primitive.%s.share_of_game" % primitive.name_value),
			"Isolated cost per call times the calls one game makes, over game wall clock.",
			"complete reference games", primitive.share_of(game.ms_per_game), games))
		rows.append({
			"primitive": String(primitive.name_value),
			"us_per_call": primitive.us_per_call,
			"calls_per_game": primitive.calls_per_game,
			"us_per_game": primitive.us_per_game(),
			"share_of_game": primitive.share_of(game.ms_per_game),
		})
	report.add_section(&"primitives", rows)

	# The performance goals are reported as goals, never as gates: the brief is
	# explicit that 10 ms is "the initial practical calibration goal" and not an
	# unqualified product requirement.
	report.add_metric(CalibrationMetric.raw(
		&"performance.goal_ms_per_game",
		"Stage 4 calibration goal, reported for comparison only; never a gate. %s"
			% CalibrationTargets.performance_goal_source(),
		"complete reference games", CalibrationTargets.PERFORMANCE_GOAL_MS_PER_GAME))
	report.add_metric(CalibrationMetric.raw(
		&"performance.stretch_ms_per_game",
		"Stage 4 stretch goal, reported for comparison only; never a gate.",
		"complete reference games", CalibrationTargets.PERFORMANCE_STRETCH_MS_PER_GAME))

	report.finish()
	var path: String = ReportWriter.write(report, "performance_profile_%s" % label)
	_print_summary(label, game, primitives, path)
	quit(0)


# --- whole-game measurement --------------------------------------------------

func _profile_games(games: int) -> GameProfile:
	# Warm up so script compilation and first-touch allocation do not land in
	# the measured window.
	for index in range(WARMUP_GAMES):
		MatchEngine.new().simulate_match(
			CompetitionCatalog.reference_match(), SeededRandomSource.new(900000 + index))

	var counters: Dictionary = CountingRandomSource.counters()
	var events: int = 0
	var possessions: int = 0
	var started: int = Time.get_ticks_usec()
	for index in range(games):
		var input: MatchInput = CompetitionCatalog.reference_match()
		var source := CountingRandomSource.new(SeededRandomSource.new(index + 1), counters)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(input, source)
		events += output.events.size()
		possessions += output.possessions.size()
	var elapsed_us: int = Time.get_ticks_usec() - started

	var profile := GameProfile.new()
	profile.ms_per_game = float(elapsed_us) / 1000.0 / float(games)
	profile.games_per_second = (
		0.0 if profile.ms_per_game <= 0.0 else 1000.0 / profile.ms_per_game)
	profile.possessions_per_second = (
		0.0 if elapsed_us <= 0 else float(possessions) * 1000000.0 / float(elapsed_us))
	profile.events_per_game = float(events) / float(games)
	profile.possessions_per_game = float(possessions) / float(games)
	profile.derives_per_game = float(_counter(counters, &"derive")) / float(games)
	profile.draws_per_game = float(
		_counter(counters, &"next_float")
		+ _counter(counters, &"next_u32")
		+ _counter(counters, &"range_int")) / float(games)
	profile.derives_per_possession = (
		0.0 if possessions == 0 else float(_counter(counters, &"derive")) / float(possessions))
	return profile


func _counter(counters: Dictionary, key: StringName) -> int:
	var value: int = counters[key]
	return value


# --- primitive measurement ---------------------------------------------------

func _profile_primitives(game: GameProfile) -> Array[Primitive]:
	var primitives: Array[Primitive] = []
	primitives.append(Primitive.new(
		&"stream_derivation", _time_stream_derivation(), game.derives_per_game))
	primitives.append(Primitive.new(
		&"random_draw", _time_random_draw(), game.draws_per_game))
	primitives.append(Primitive.new(
		&"event_allocation", _time_event_allocation(), game.events_per_game))
	primitives.append(Primitive.new(
		&"event_serialization", _time_event_serialization(), 0.0))
	primitives.append(Primitive.new(
		&"reducer_apply", _time_reducer_apply(), game.events_per_game * 2.0))
	primitives.append(Primitive.new(
		&"snapshot_copy", _time_snapshot_copy(), game.possessions_per_game))
	primitives.append(Primitive.new(
		&"candidate_generation", _time_candidate_generation(), game.possessions_per_game * 2.5))
	primitives.append(Primitive.new(
		&"capability_calculation", _time_capability_calculation(), game.events_per_game * 3.0))
	primitives.append(Primitive.new(
		&"usage_damping_table", _time_usage_damping_table(), game.possessions_per_game * 2.5))
	primitives.append(Primitive.new(
		&"on_court_ids", _time_on_court_ids(), 0.0))
	primitives.append(Primitive.new(
		&"player_by_id", _time_player_by_id(), 0.0))
	primitives.append(Primitive.new(
		&"rating_normalization", _time_rating_normalization(), 0.0))
	primitives.append(Primitive.new(
		&"raw_normalization", _time_raw_normalization(), 0.0))
	primitives.append(Primitive.new(
		&"projector_projection", _time_projector(), 1.0))
	return primitives


## `Rating.normalized` against the same arithmetic with no validation, so the
## report can attribute the difference to the validation rather than assume it.
func _time_rating_normalization() -> float:
	var total: float = 0.0
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		total += Rating.normalized(70)
	var elapsed: float = float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)
	assert(total > 0.0, "the accumulator keeps the loop from being optimized away")
	return elapsed


func _time_raw_normalization() -> float:
	var total: float = 0.0
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		total += float(70 - 25) / 74.0
	var elapsed: float = float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)
	assert(total > 0.0, "the accumulator keeps the loop from being optimized away")
	return elapsed


func _time_stream_derivation() -> float:
	var source := SeededRandomSource.new(12345)
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		source.derive(&"profile_label")
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


func _time_random_draw() -> float:
	var source := SeededRandomSource.new(12345)
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		source.next_float()
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


func _time_event_allocation() -> float:
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		MatchDomainEvent.new(
			&"match", index + 1, 1, 600000, MatchDomainEvent.FIELD_GOAL_MADE, &"home",
			1, 1, &"home_p1", &"away_p1", &"", &"drive", &"open", &"restricted_rim", 2, 0, &"")
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


func _time_event_serialization() -> float:
	var event := MatchDomainEvent.new(
		&"match", 1, 1, 600000, MatchDomainEvent.FIELD_GOAL_MADE, &"home",
		1, 1, &"home_p1", &"away_p1", &"", &"drive", &"open", &"restricted_rim", 2, 0, &"")
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		event.signature()
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


## The reducer refuses an out-of-sequence event, so the events are built up
## front and only the fold is timed. Building them inside the loop would have
## charged the reducer for the allocation measured separately above.
func _time_reducer_apply() -> float:
	var input: MatchInput = CompetitionCatalog.reference_match()
	var reducer := MatchStateReducer.new(input)
	var snapshot := MatchSnapshot.new(input)
	var iterations: int = MICRO_ITERATIONS / 4
	var events: Array[MatchDomainEvent] = []
	for index in range(iterations):
		events.append(MatchDomainEvent.new(
			input.match_id, index + 1, 1, 600000, MatchDomainEvent.PASS_COMPLETED,
			input.home.team_id, 1, 1, input.home.players[0].player_id,
			input.home.players[1].player_id, &"", &"pass_swing", &"", &"", 0, 0, &""))
	var started: int = Time.get_ticks_usec()
	for event in events:
		reducer.apply_event(snapshot, event)
	return float(Time.get_ticks_usec() - started) / float(iterations)


func _time_snapshot_copy() -> float:
	var snapshot := MatchSnapshot.new(CompetitionCatalog.reference_match())
	var iterations: int = MICRO_ITERATIONS / 10
	var started: int = Time.get_ticks_usec()
	for index in range(iterations):
		snapshot.copy()
	return float(Time.get_ticks_usec() - started) / float(iterations)


func _time_candidate_generation() -> float:
	var input: MatchInput = CompetitionCatalog.reference_match()
	var snapshot := MatchSnapshot.new(input)
	var balance: SimulationBalanceProfile = input.balance_profile
	var capability := CapabilityCalculator.new(input.ratings_profile, balance)
	var body := BodyEffects.new(balance)
	var participants := ParticipantSelector.new(capability, balance)
	var generator := ActionCandidateGenerator.new(capability, body, balance, participants)
	var matchups: MatchupState = MatchupResolver.new(capability, body).resolve(
		input.home, snapshot.home, input.away, snapshot.away)
	var context := PossessionContext.new(input, snapshot, input.home.team_id, matchups, 1)
	context.ball_handler_id = snapshot.home.on_court_ids()[0]
	var iterations: int = MICRO_ITERATIONS / 20
	var started: int = Time.get_ticks_usec()
	for index in range(iterations):
		generator.generate(context)
	return float(Time.get_ticks_usec() - started) / float(iterations)


## The possession-level usage budget, which candidate generation resolves once
## per action before it builds any candidate.
func _time_usage_damping_table() -> float:
	var context: PossessionContext = _sample_context()
	var input: MatchInput = context.input
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var participants := ParticipantSelector.new(capability, input.balance_profile)
	var iterations: int = MICRO_ITERATIONS / 20
	var started: int = Time.get_ticks_usec()
	for index in range(iterations):
		participants.usage_damping_table(context)
	return float(Time.get_ticks_usec() - started) / float(iterations)


func _time_on_court_ids() -> float:
	var snapshot := MatchSnapshot.new(CompetitionCatalog.reference_match())
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		snapshot.home.on_court_ids()
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


func _time_player_by_id() -> float:
	var input: MatchInput = CompetitionCatalog.reference_match()
	var player_id: StringName = input.home.players[3].player_id
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		input.home.player_by_id(player_id)
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


func _sample_context() -> PossessionContext:
	var input: MatchInput = CompetitionCatalog.reference_match()
	var snapshot := MatchSnapshot.new(input)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var body := BodyEffects.new(input.balance_profile)
	var matchups: MatchupState = MatchupResolver.new(capability, body).resolve(
		input.home, snapshot.home, input.away, snapshot.away)
	var context := PossessionContext.new(input, snapshot, input.home.team_id, matchups, 1)
	context.ball_handler_id = snapshot.home.on_court_ids()[0]
	return context


func _time_capability_calculation() -> float:
	var input: MatchInput = CompetitionCatalog.reference_match()
	var calculator := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var player: PlayerMatchProfile = input.home.players[0]
	var runtime := PlayerMatchRuntime.new(player.player_id)
	var started: int = Time.get_ticks_usec()
	for index in range(MICRO_ITERATIONS):
		calculator.capability_of(CapabilityKey.Value.THREE_POINT_SHOTMAKING, player, runtime)
	return float(Time.get_ticks_usec() - started) / float(MICRO_ITERATIONS)


func _time_projector() -> float:
	var input: MatchInput = CompetitionCatalog.reference_match()
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(4242))
	var projector := BoxScoreProjector.new()
	var iterations: int = 20
	var started: int = Time.get_ticks_usec()
	for index in range(iterations):
		projector.project(input, output.events, output.possessions)
	return float(Time.get_ticks_usec() - started) / float(iterations)


func _print_summary(
	label: String,
	game: GameProfile,
	primitives: Array[Primitive],
	path: String,
) -> void:
	print("")
	print("LeagueBound performance profile (%s)" % label)
	print("  ms per complete reference game: %.3f" % game.ms_per_game)
	print("  games/second: %.1f    possessions/second: %.0f" % [
		game.games_per_second, game.possessions_per_second])
	print("  events/game: %.0f    possessions/game: %.1f" % [
		game.events_per_game, game.possessions_per_game])
	print("  stream derivations/game: %.0f  (%.1f per possession)" % [
		game.derives_per_game, game.derives_per_possession])
	print("  random draws/game: %.0f" % game.draws_per_game)
	print("")
	print("  %-24s %12s %14s %14s %10s" % [
		"primitive", "us/call", "calls/game", "us/game", "share"])
	for primitive in primitives:
		print("  %-24s %12.4f %14.0f %14.1f %9.1f%%" % [
			String(primitive.name_value), primitive.us_per_call, primitive.calls_per_game,
			primitive.us_per_game(), primitive.share_of(game.ms_per_game) * 100.0])
	print("")
	if not path.is_empty():
		print("  report: %s" % path)
