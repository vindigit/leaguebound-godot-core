extends SceneTree

## Per-activation causal trace of the two `EndgameStrategy` decisions the §5.26
## correction did not touch: **two-for-one** and **quick-two-vs-tying-three**
## (`PROJECT_STATUS.md` §9 item 14).
##
## §9 item 14 fixes the standard this has to meet. The two defects §5.26 found
## were "both invisible to a gate test and visible in an activation count", and
## neither of these two decisions has been read that way. `run_endgame_activation`
## reads the count; a count says how often a decision fired and nothing about
## whether the thing it fired *for* then happened. So this runner reads the
## other half: for every activation, the state that produced it, the action it
## produced, and whether the sequence the decision exists to set up was still
## available afterwards.
##
## **Method.** Nothing here is instrumented into the engine. Each game is played
## normally, then its ledger is replayed through a second `MatchStateReducer`
## from `MatchSnapshot.new(input)`. Applying events in order reproduces exactly
## the state the engine held, and the state immediately *before* an
## `ACTION_SELECTED` event is applied is the state `EndgameStrategy.active_tag`
## read when the engine tagged it — the tag is evaluated as an argument to
## `_emit`, so it runs before the reducer advances the clock for that event.
## The gates are then re-evaluated on that reconstructed state through the
## production `EndgameStrategy` itself, never a copy of its arithmetic.
##
## That reconstruction is checked rather than assumed: `tag_agreement` compares
## every recomputed tag against the one the engine wrote. Anything below 1.0
## invalidates every row this runner prints, and it is judged as a hard
## invariant for that reason.
##
## Two clocks matter and they are not the same number:
##
## ```text
## decision clock   state.clock_ms before the event applies   what the gate read
## recorded clock   event.clock_ms                            after the action's time
## ```
##
## The ledger carries the second. Every window in `EndgameStrategy` is drawn
## against the first, so every clock reported here is the decision clock, and
## `action_ms` is their difference.
##
## **A/B mode** answers the question a trace cannot: whether the multiplier
## changes anything. It replays identical seeds and identical rosters with the
## decision's own knob zeroed, which is the only difference between the arms —
## roster generation has already happened by the time the knob is overwritten,
## so the two arms differ in the decision and in nothing else.
##
## This is a diagnostic. It certifies nothing at any sample and judges no §14
## band.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_endgame_decision_trace.gd -- \
##       [--games=N] [--competition=college|top_domestic_pro|all] \
##       [--mode=trace|ab] [--range=trace|trace_second] [--rows=N]

const DEFAULT_GAMES: int = 200

## Disjoint from every range any other section owns, `run_endgame_activation`'s
## 950000/955000 audit ranges included.
const TRACE_BASE: int = 960000
const TRACE_SECOND_BASE: int = 965000

## How many individual activation rows to print per decision per competition.
## The CSV always carries all of them.
const DEFAULT_ROWS: int = 12


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var mode: String = CalibrationCli.string_option(options, &"mode", "trace")
	var range_name: String = CalibrationCli.string_option(options, &"range", "trace")
	var rows: int = CalibrationCli.int_option(options, &"rows", DEFAULT_ROWS)
	var base: int = TRACE_SECOND_BASE if range_name == "trace_second" else TRACE_BASE
	var competitions: Array[int] = _competitions(selection)

	print("=== EndgameStrategy decision trace (§9 item 14) ===")
	print("  commit=%s mode=%s games=%d range=%s seeds=%d..%d" % [
		_commit(), mode, games, range_name, base + 1, base + games])
	print("  DIRECTIONAL ONLY. Certifies nothing and judges no §14 band.")
	print("")

	if mode == "ab":
		for competition in competitions:
			_run_ab(competition, games, base)
	else:
		for competition in competitions:
			_run_trace(competition, games, base, rows)
	quit(0)


func _commit() -> String:
	var ci_sha: String = OS.get_environment("GITHUB_SHA")
	return ci_sha if not ci_sha.is_empty() else "working-tree"


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


# --- one traced activation ----------------------------------------------------

## Everything §9 item 14 asks to be reported for a single firing, plus what is
## needed to decide whether the sequence it exists for stayed available.
class Activation:
	extends RefCounted

	var decision: StringName = &""
	var game: int = 0
	var period: int = 0
	## The clock the gate read, not the clock the ledger recorded.
	var clock_ms: int = 0
	var shot_clock_ms: int = 0
	var margin: int = 0
	var action_id: StringName = &""
	var zone_id: StringName = &""
	var is_three: bool = false
	var is_shot: bool = false
	var action_ms: int = 0
	var timeouts_before: int = 0
	var timeouts_after: int = 0
	## Possession outcome, from the engine's own record.
	var possession_id: int = 0
	var end_reason: StringName = &""
	var points_scored: int = 0
	var possession_ms: int = 0
	var end_clock_ms: int = 0
	var end_period: int = 0
	## Did this team get the ball again in the same period?
	var another_possession: bool = false
	var next_own_possession_clock_ms: int = 0
	## Was the sequence the decision exists for still arithmetically available
	## when the possession ended?
	var sequence_possible: bool = false
	var sequence_note: String = ""

	func to_csv() -> String:
		return ",".join([
			String(decision), str(game), str(period), str(clock_ms), str(shot_clock_ms),
			str(margin), String(action_id), String(zone_id), str(is_three), str(is_shot),
			str(action_ms), str(timeouts_before), str(timeouts_after), str(possession_id),
			String(end_reason), str(points_scored), str(possession_ms), str(end_clock_ms),
			str(another_possession), str(next_own_possession_clock_ms),
			str(sequence_possible), sequence_note,
		])

	static func csv_header() -> String:
		return ("decision,game,period,decision_clock_ms,shot_clock_ms,margin,action,zone,"
			+ "is_three,is_shot,action_ms,timeouts_before,timeouts_after,possession_id,"
			+ "end_reason,points_scored,possession_ms,end_clock_ms,another_possession,"
			+ "next_own_possession_clock_ms,sequence_possible,sequence_note")


## Everything accumulated for one competition in trace mode.
class Trace:
	extends RefCounted

	var competition: int = 0
	var games: int = 0
	var activations: Array[Activation] = []

	## Reconstruction fidelity: recomputed tag versus the tag the engine wrote.
	var tags_compared: int = 0
	var tags_agreed: int = 0
	## `PossessionEngine` emits the offensive-rebound putback's `ACTION_SELECTED`
	## with a hardcoded empty `detail_id` rather than `active_tag`, so a putback
	## taken while a decision was in force is recorded as though none was. That
	## is a known, explained ledger gap rather than a reconstruction failure, so
	## it is counted on its own and kept out of the fidelity ratio.
	var untagged_putbacks: int = 0
	## Mismatches with no such explanation. Any of these invalidates the trace.
	var disagreements: Array[String] = []

	## Why quick-two did not fire, counted over every final-period action
	## selection. Each counter is the number of selections that cleared every
	## earlier condition and failed this one, so they partition the misses and
	## the last one is the population that fired.
	var qt_seen: int = 0
	var qt_fail_margin: int = 0
	var qt_fail_window_low: int = 0
	var qt_fail_window_high: int = 0
	var qt_passed: int = 0

	## The same census for two-for-one.
	var tfo_seen: int = 0
	var tfo_fail_margin: int = 0
	var tfo_fail_window_low: int = 0
	var tfo_fail_window_high: int = 0
	var tfo_passed: int = 0

	## Final-period possessions that were *eligible in every respect except the
	## margin* for quick-two — the deficit-3 population is what makes the
	## activation rate readable rather than merely small.
	var deficit_three_selections: int = 0
	var final_period_selections: int = 0

	func of(decision: StringName) -> Array[Activation]:
		var out: Array[Activation] = []
		for activation in activations:
			if activation.decision == decision:
				out.append(activation)
		return out


func _run_trace(competition: int, games: int, base: int, rows: int) -> void:
	var trace: Trace = _collect(competition, games, base, Callable())
	_report(trace, rows)


## Plays `games` games and reconstructs every final-period action selection.
## `balance_override` mutates the endgame knobs after roster generation, so the
## A/B arms share rosters exactly.
func _collect(
	competition: int,
	games: int,
	base: int,
	balance_override: Callable,
) -> Trace:
	var trace := Trace.new()
	trace.competition = competition
	trace.games = games
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)

	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		if balance_override.is_valid():
			balance_override.call(input.balance_profile)
		var session := MatchSession.new(input, SeededRandomSource.new(variation + 1))
		var output: MatchSimulationOutput = session.run_to_completion()
		_replay(trace, output, input, rules, variation)
		if games > 100 and (index + 1) % 100 == 0:
			print("  %s: %d/%d games" % [
				CalibrationTargets.competition_id(competition), index + 1, games])
	return trace


## Replays one game's ledger and reads every final-period action selection off
## the reconstructed state.
func _replay(
	trace: Trace,
	output: MatchSimulationOutput,
	input: MatchInput,
	rules: CompetitionRuleProfile,
	game: int,
) -> void:
	var state := MatchSnapshot.new(input)
	var reducer := MatchStateReducer.new(input)
	var balance: SimulationBalanceProfile = input.balance_profile
	var records: Dictionary[int, PossessionRecord] = {}
	for record in output.possessions:
		records[record.possession_id] = record

	for event in output.events:
		if (
			event.event_type == MatchDomainEvent.ACTION_SELECTED
			and state.period >= rules.regulation_periods
		):
			_read_selection(trace, event, state, input, balance, records, output, game)
		reducer.apply_event(state, event)


func _read_selection(
	trace: Trace,
	event: MatchDomainEvent,
	state: MatchSnapshot,
	input: MatchInput,
	balance: SimulationBalanceProfile,
	records: Dictionary,
	output: MatchSimulationOutput,
	game: int,
) -> void:
	# The gates read only state, rules, margin and timeouts; an empty matchup
	# table is sufficient and keeps the reconstruction free of a resolver whose
	# result the engine did not record.
	var context := PossessionContext.new(
		input, state, event.team_id, MatchupState.new({}), event.possession_id)

	# Fidelity: the recomputed tag must be the tag the engine wrote.
	trace.tags_compared += 1
	var recomputed: StringName = EndgameStrategy.active_tag(context, balance)
	if recomputed == event.detail_id:
		trace.tags_agreed += 1
	elif (
		event.action_id == ActionFamily.id_of(ActionFamily.Value.PUTBACK)
		and event.detail_id.is_empty()
	):
		trace.untagged_putbacks += 1
	elif trace.disagreements.size() < 12:
		trace.disagreements.append(
			"game=%d seq=%d period=%d clock=%d shot=%d margin=%d timeouts=%d action=%s engine=%s recomputed=%s"
			% [game, event.sequence, state.period, state.clock_ms, state.shot_clock_ms,
				state.margin_for(event.team_id),
				state.state_for(event.team_id).timeouts_remaining,
				String(event.action_id), String(event.detail_id), String(recomputed)])

	trace.final_period_selections += 1
	var margin: int = state.margin_for(event.team_id)
	if -margin == GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT:
		trace.deficit_three_selections += 1

	_census(trace, context, state, balance, margin)

	var two_for_one: bool = EndgameStrategy.two_for_one_active(context, balance)
	var quick_two: bool = EndgameStrategy.quick_two_preferred(context, balance)
	if not two_for_one and not quick_two:
		return

	# Quick-two takes the row when both hold, matching `active_tag`'s own
	# priority, so a firing is never double-counted.
	var decision: StringName = (
		EndgameStrategy.TAG_QUICK_TWO if quick_two else EndgameStrategy.TAG_TWO_FOR_ONE)
	trace.activations.append(
		_describe(decision, event, state, input, margin, records, output, game))


## Which condition of each gate turned this selection away. Ordered exactly as
## the gate is written, so the counters partition rather than overlap.
func _census(
	trace: Trace,
	context: PossessionContext,
	state: MatchSnapshot,
	balance: SimulationBalanceProfile,
	margin: int,
) -> void:
	var rules: CompetitionRuleProfile = context.input.rule_profile
	var remaining: int = GameManagement.remaining_ms(state, rules)

	trace.qt_seen += 1
	if -margin != GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT:
		trace.qt_fail_margin += 1
	elif remaining <= balance.endgame_possession_ms:
		trace.qt_fail_window_low += 1
	elif remaining > StakesPolicy.endgame_window_ms(balance, context.input.stakes) \
			+ EndgameStrategy.quick_two_span_ms(balance):
		trace.qt_fail_window_high += 1
	else:
		trace.qt_passed += 1

	var shot_clock_ms: int = rules.shot_clock_seconds * 1000
	trace.tfo_seen += 1
	if margin > 0:
		trace.tfo_fail_margin += 1
	elif remaining <= shot_clock_ms:
		trace.tfo_fail_window_low += 1
	elif remaining > shot_clock_ms * 2 + maxi(balance.two_for_one_window_ms, 0):
		trace.tfo_fail_window_high += 1
	else:
		trace.tfo_passed += 1


func _describe(
	decision: StringName,
	event: MatchDomainEvent,
	state: MatchSnapshot,
	input: MatchInput,
	margin: int,
	records: Dictionary,
	output: MatchSimulationOutput,
	game: int,
) -> Activation:
	var activation := Activation.new()
	activation.decision = decision
	activation.game = game
	activation.period = state.period
	activation.clock_ms = state.clock_ms
	activation.shot_clock_ms = state.shot_clock_ms
	activation.margin = margin
	activation.action_id = event.action_id
	activation.zone_id = event.zone_id
	activation.is_shot = not event.zone_id.is_empty()
	activation.is_three = (
		activation.is_shot and ShotZone.is_three(ShotZone.from_id(event.zone_id)))
	activation.action_ms = state.clock_ms - event.clock_ms
	activation.timeouts_before = state.state_for(event.team_id).timeouts_remaining
	activation.possession_id = event.possession_id

	var record: PossessionRecord = records.get(event.possession_id, null)
	if record == null:
		return activation
	activation.end_reason = PossessionEndReason.id_of(record.end_reason)
	activation.points_scored = record.points_scored
	activation.end_clock_ms = record.end_clock_ms
	activation.end_period = record.end_period
	activation.possession_ms = (
		record.start_clock_ms - record.end_clock_ms
		if record.start_period == record.end_period else record.start_clock_ms)

	_read_sequence(activation, event, record, records, output, input)
	return activation


## Whether the team got the ball back in the same period, and whether the
## sequence the decision exists for was still arithmetically available when the
## possession ended.
func _read_sequence(
	activation: Activation,
	event: MatchDomainEvent,
	record: PossessionRecord,
	records: Dictionary,
	output: MatchSimulationOutput,
	input: MatchInput,
) -> void:
	for later in output.possessions:
		if later.possession_id <= record.possession_id:
			continue
		if later.start_period != record.end_period:
			continue
		if later.offense_team_id != record.offense_team_id:
			continue
		activation.another_possession = true
		activation.next_own_possession_clock_ms = later.start_clock_ms
		break

	# Timeouts the team still held once the possession was over. The ledger is
	# the only place the order is visible, so it is counted forward.
	activation.timeouts_after = activation.timeouts_before
	for other in output.events:
		if other.event_type != MatchDomainEvent.TIMEOUT:
			continue
		if other.team_id != event.team_id:
			continue
		if other.sequence <= event.sequence:
			continue
		if other.period != record.end_period:
			continue
		if other.clock_ms < record.end_clock_ms:
			continue
		activation.timeouts_after -= 1

	var rules: CompetitionRuleProfile = input.rule_profile
	var balance: SimulationBalanceProfile = input.balance_profile
	if activation.decision == EndgameStrategy.TAG_TWO_FOR_ONE:
		# Two-for-one buys nothing unless the clock that survives the possession
		# still holds the opponent's trip *and* another of the offence's own.
		# One shot clock is the least the opponent can be made to take only if
		# it is fouled; left alone it may take the whole of one.
		var floor_ms: int = rules.shot_clock_seconds * 1000
		activation.sequence_possible = (
			activation.end_period == activation.period and activation.end_clock_ms > 0)
		activation.sequence_note = (
			"end_clock=%dms vs one shot clock=%dms" % [activation.end_clock_ms, floor_ms])
	else:
		# Quick-two's plan is a made two, the clock stopped, a foul, and the
		# ball back. The foul half is only reachable inside
		# `intentional_foul_clock_ms`.
		activation.sequence_possible = (
			activation.end_period == activation.period
			and activation.end_clock_ms > 0
			and activation.end_clock_ms <= balance.intentional_foul_clock_ms)
		activation.sequence_note = (
			"end_clock=%dms vs intentional_foul_clock=%dms"
			% [activation.end_clock_ms, balance.intentional_foul_clock_ms])


# --- reporting ----------------------------------------------------------------

func _report(trace: Trace, rows: int) -> void:
	var competition_id: StringName = CalibrationTargets.competition_id(trace.competition)
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(trace.competition)
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	print("--- %s (%d games) ---" % [competition_id, trace.games])
	var explained: int = trace.tags_agreed + trace.untagged_putbacks
	var agreement: float = (
		1.0 if trace.tags_compared == 0
		else float(explained) / float(trace.tags_compared))
	print("  reconstruction: explained=%.6f over %d final-period selections%s" % [
		agreement, trace.tags_compared,
		"" if agreement == 1.0 else "   *** RECONSTRUCTION INVALID ***"])
	print("    of which untagged putbacks (engine ledger gap): %d" % trace.untagged_putbacks)
	for line in trace.disagreements:
		print("    mismatch: %s" % line)
	print("  windows: shot_clock=%dms two_for_one=(%d,%d]ms quick_two=(%d,%d]ms" % [
		rules.shot_clock_seconds * 1000,
		rules.shot_clock_seconds * 1000,
		rules.shot_clock_seconds * 2000 + balance.two_for_one_window_ms,
		balance.endgame_possession_ms,
		StakesPolicy.endgame_window_ms(balance, GameStakes.Value.REGULAR)
			+ EndgameStrategy.quick_two_span_ms(balance)])
	print("  final-period action selections: %d (deficit-exactly-3: %d)" % [
		trace.final_period_selections, trace.deficit_three_selections])

	print("  quick_two gate census (partitioned, in gate order):")
	print("    margin != -3 .......... %d" % trace.qt_fail_margin)
	print("    remaining <= %6d ... %d" % [balance.endgame_possession_ms, trace.qt_fail_window_low])
	print("    remaining >  %6d ... %d" % [
		StakesPolicy.endgame_window_ms(balance, GameStakes.Value.REGULAR)
			+ EndgameStrategy.quick_two_span_ms(balance), trace.qt_fail_window_high])
	print("    PASSED ................ %d" % trace.qt_passed)

	print("  two_for_one gate census (partitioned, in gate order):")
	print("    margin > 0 ............ %d" % trace.tfo_fail_margin)
	print("    remaining <= shotclock  %d" % trace.tfo_fail_window_low)
	print("    remaining >  window ... %d" % trace.tfo_fail_window_high)
	print("    PASSED ................ %d" % trace.tfo_passed)

	for decision: StringName in [
		EndgameStrategy.TAG_TWO_FOR_ONE, EndgameStrategy.TAG_QUICK_TWO
	]:
		_report_decision(trace, decision, rows)
	_write_csv(trace, competition_id)
	print("")


func _report_decision(trace: Trace, decision: StringName, rows: int) -> void:
	var list: Array[Activation] = trace.of(decision)
	print("  %s: %d activations (%.4f per game)" % [
		decision, list.size(),
		0.0 if trace.games == 0 else float(list.size()) / float(trace.games)])
	if list.is_empty():
		return

	var shots: int = 0
	var threes: int = 0
	var resets: int = 0
	var another: int = 0
	var possible: int = 0
	var points: int = 0
	var action_ms: int = 0
	var possession_ms: int = 0
	var spent_timeout: int = 0
	for activation in list:
		if activation.is_shot:
			shots += 1
			if activation.is_three:
				threes += 1
		if activation.action_id == ActionFamily.id_of(ActionFamily.Value.RESET):
			resets += 1
		if activation.another_possession:
			another += 1
		if activation.sequence_possible:
			possible += 1
		if activation.timeouts_after < activation.timeouts_before:
			spent_timeout += 1
		points += activation.points_scored
		action_ms += activation.action_ms
		possession_ms += activation.possession_ms
	var count: float = float(list.size())
	print("    shots=%d (three=%d, two=%d) resets=%d" % [shots, threes, shots - threes, resets])
	print("    mean action_ms=%.0f  mean possession_ms=%.0f  points/possession=%.3f" % [
		float(action_ms) / count, float(possession_ms) / count, float(points) / count])
	print("    another possession same period: %d/%d (%.1f%%)" % [
		another, list.size(), 100.0 * float(another) / count])
	print("    sequence still possible at possession end: %d/%d (%.1f%%)" % [
		possible, list.size(), 100.0 * float(possible) / count])
	print("    spent a timeout after the decision: %d/%d" % [spent_timeout, list.size()])

	print("    first %d activations:" % mini(rows, list.size()))
	print("      %-6s %-6s %-7s %-6s %-18s %-14s %-7s %-9s %-8s %s" % [
		"game", "per", "clock", "shot", "action", "zone", "act_ms", "margin", "TOs", "outcome"])
	for index in range(mini(rows, list.size())):
		var a: Activation = list[index]
		print("      %-6d %-6d %-7d %-6d %-18s %-14s %-7d %-9d %d->%-4d %s pts=%d again=%s poss=%s" % [
			a.game, a.period, a.clock_ms, a.shot_clock_ms, String(a.action_id),
			String(a.zone_id) if a.is_shot else "-", a.action_ms, a.margin,
			a.timeouts_before, a.timeouts_after, String(a.end_reason), a.points_scored,
			"Y" if a.another_possession else "N", "Y" if a.sequence_possible else "N"])


func _write_csv(trace: Trace, competition_id: StringName) -> void:
	var lines: PackedStringArray = [Activation.csv_header()]
	for activation in trace.activations:
		lines.append(activation.to_csv())
	DirAccess.make_dir_recursive_absolute("res://reports")
	var path: String = "res://reports/endgame_trace_%s.csv" % competition_id
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("could not write %s" % path)
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("  rows: %s (%d activations)" % [path, trace.activations.size()])


# --- A/B ----------------------------------------------------------------------

## Does the decision change anything a played game can see? Identical seeds and
## identical rosters; the only difference is the decision's own knob.
func _run_ab(competition: int, games: int, base: int) -> void:
	var competition_id: StringName = CalibrationTargets.competition_id(competition)
	print("--- %s A/B (%d games per arm) ---" % [competition_id, games])

	var live: Trace = _collect(competition, games, base, Callable())
	var without_tfo: Trace = _collect(competition, games, base, _zero_two_for_one)
	var without_qt: Trace = _collect(competition, games, base, _zero_quick_two)

	_compare(live, without_tfo, EndgameStrategy.TAG_TWO_FOR_ONE, "two_for_one_urgency")
	_compare(live, without_qt, EndgameStrategy.TAG_QUICK_TWO, "quick_two_preference")
	print("")


func _zero_two_for_one(balance: SimulationBalanceProfile) -> void:
	balance.two_for_one_urgency = 0.0


func _zero_quick_two(balance: SimulationBalanceProfile) -> void:
	balance.quick_two_preference = 0.0


func _compare(live: Trace, off: Trace, decision: StringName, knob: String) -> void:
	var a: Array[Activation] = live.of(decision)
	var b: Array[Activation] = off.of(decision)
	print("  %s (%s: %.2f -> 0.00)" % [decision, knob, _knob_value(knob)])
	print("    activations:            %d -> %d" % [a.size(), b.size()])
	if a.is_empty() and b.is_empty():
		print("    no activations in either arm; the knob cannot be shown to do anything")
		return
	print("    mean action_ms:         %s -> %s" % [_mean_action(a), _mean_action(b)])
	print("    mean possession_ms:     %s -> %s" % [_mean_possession(a), _mean_possession(b)])
	print("    direct-shot share:      %s -> %s" % [_shot_share(a), _shot_share(b)])
	print("    three share of shots:   %s -> %s" % [_three_share(a), _three_share(b)])
	print("    another possession:     %s -> %s" % [_another_share(a), _another_share(b)])


func _knob_value(knob: String) -> float:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	return (
		balance.two_for_one_urgency if knob == "two_for_one_urgency"
		else balance.quick_two_preference)


func _mean_action(list: Array[Activation]) -> String:
	if list.is_empty():
		return "n/a"
	var total: int = 0
	for activation in list:
		total += activation.action_ms
	return "%.0fms" % (float(total) / float(list.size()))


func _mean_possession(list: Array[Activation]) -> String:
	if list.is_empty():
		return "n/a"
	var total: int = 0
	for activation in list:
		total += activation.possession_ms
	return "%.0fms" % (float(total) / float(list.size()))


func _shot_share(list: Array[Activation]) -> String:
	if list.is_empty():
		return "n/a"
	var shots: int = 0
	for activation in list:
		if activation.is_shot:
			shots += 1
	return "%.1f%%" % (100.0 * float(shots) / float(list.size()))


func _three_share(list: Array[Activation]) -> String:
	var shots: int = 0
	var threes: int = 0
	for activation in list:
		if not activation.is_shot:
			continue
		shots += 1
		if activation.is_three:
			threes += 1
	if shots == 0:
		return "n/a"
	return "%.1f%%" % (100.0 * float(threes) / float(shots))


func _another_share(list: Array[Activation]) -> String:
	if list.is_empty():
		return "n/a"
	var another: int = 0
	for activation in list:
		if activation.another_possession:
			another += 1
	return "%.1f%%" % (100.0 * float(another) / float(list.size()))
