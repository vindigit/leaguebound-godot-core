class_name MatchSession
extends RefCounted

## One stepped match, shared by Play, Sim, and Skip (`SIMULATION_SPEC.md` §23,
## `GODOT_TDD.md` §5.4).
##
## §2.1: "For a user-controlled game, Play and Sim consume the same" ratings,
## lineups, plan, tendencies, fatigue, rules, possession resolution, and
## attribution. That is enforced structurally here — there is one session type
## and one `advance_possession`, and Play, Sim, and Skip differ only in *when*
## they stop calling it. There is no second resolution path to drift.
##
## Because every possession derives its random stream from the match identity
## and the possession sequence rather than from the caller's consumption order,
## stepping possession-by-possession and running straight to the end produce the
## identical ledger. §27.5 requires that parity; deriving by label is what makes
## it true rather than merely tested.

var _input: MatchInput
var _random_source: RandomSource
var _snapshot: MatchSnapshot
var _ledger: EventLedger
var _reducer: MatchStateReducer
var _possession_engine: PossessionEngine
var _period_controller: PeriodController
var _rotation: RotationResolver
var _projector: BoxScoreProjector
var _possessions: Array[PossessionRecord]
var _live_start: bool
var _opened: bool
## §4/§5 timeouts: the team currently on a scoring run and how many unanswered
## points it has. Read from the possession records as they are appended, so the
## trigger is a function of the committed ledger like everything else.
var _run_team_id: StringName
var _run_points: int

const MAX_POSSESSIONS: int = 2000


func _init(input: MatchInput, random_source: RandomSource) -> void:
	assert(input != null, "match input is required")
	assert(random_source != null, "an injected random source is required")
	_input = input
	_random_source = random_source
	_snapshot = MatchSnapshot.new(input)
	_ledger = EventLedger.new()
	_reducer = MatchStateReducer.new(input)
	_possession_engine = PossessionEngine.new(input)
	_period_controller = PeriodController.new()
	_rotation = RotationResolver.new(input.balance_profile)
	_projector = BoxScoreProjector.new()
	_possessions = []
	_live_start = false
	_opened = false
	_run_team_id = &""
	_run_points = 0


func snapshot() -> MatchSnapshot:
	return _snapshot


func events() -> Array[MatchDomainEvent]:
	return _ledger.events.duplicate()


func possession_records() -> Array[PossessionRecord]:
	return _possessions.duplicate()


func is_complete() -> bool:
	return _snapshot.completed


## Opens the match: the first period and the starting lineups. Emitting
## `CHECK_IN` for each starter is what lets minutes and starts reconcile from
## the ledger (§24.3) instead of from the roster.
func open() -> void:
	if _opened:
		return
	_opened = true
	var writer := _writer()
	writer.emit(
		MatchDomainEvent.PERIOD_STARTED, &"", &"", &"", &"", &"", &"", &"", 0, 1)
	for team_profile: TeamMatchProfile in [_input.home, _input.away]:
		for starter_id in _snapshot.state_for(team_profile.team_id).on_court_ids():
			writer.emit(
				MatchDomainEvent.CHECK_IN, team_profile.team_id, starter_id,
				&"", &"", &"", &"starting_lineup")
	_commit(writer)


## Advances exactly one team possession, including any period transition that
## has to happen first. Returns the possession that was resolved, or null when
## the match is already over.
func advance_possession() -> PossessionResult:
	open()
	if _snapshot.completed:
		return null
	while _period_controller.period_has_expired(_snapshot):
		_advance_period()
		if _snapshot.completed:
			return null
	assert(_snapshot.possession_sequence < MAX_POSSESSIONS,
		"match exceeded the possession safety bound")
	_consider_timeout()
	_apply_substitutions()
	_rotation.validate(_snapshot, _input)

	var stream_label := StringName("match:%s:possession:%d" % [
		_input.match_id,
		_snapshot.possession_sequence,
	])
	var possession: PossessionResult = _possession_engine.simulate(
		_snapshot, _input, _random_source.derive(stream_label), _live_start)
	_ledger.append_all(possession.events)
	_snapshot = _reducer.apply_events(_snapshot, possession.events)
	_possessions.append(possession.record)
	_live_start = possession.record.live_transfer
	_record_run(possession.record)
	return possession


## §23.2 Sim: runs the remaining possessions to the final result.
func run_to_completion() -> MatchSimulationOutput:
	open()
	while not _snapshot.completed:
		advance_possession()
	return build_output()


## §23.3 Skip to next appearance: advances until the named player is on court,
## or until the match ends. Returns true when the player is on court.
func skip_until_on_court(player_id: StringName) -> bool:
	open()
	while not _snapshot.completed:
		if _is_on_court(player_id):
			return true
		advance_possession()
	return _is_on_court(player_id)


## §23.4 Skip to final result.
func skip_to_final_result() -> MatchSimulationOutput:
	return run_to_completion()


func build_output() -> MatchSimulationOutput:
	assert(_snapshot.completed, "the final result is only available once the match has ended")
	var statistics: MatchStatistics = _projector.project(_input, _ledger.events, _possessions)
	var reconciliation: PackedStringArray = statistics.reconcile()
	assert(reconciliation.is_empty(),
		"the box score must reconcile from events: %s" % ", ".join(reconciliation))
	assert(statistics.team_line(_input.home.team_id).points == _snapshot.home.score,
		"home box score does not reconcile with reduced state")
	assert(statistics.team_line(_input.away.team_id).points == _snapshot.away.score,
		"away box score does not reconcile with reduced state")
	var result := MatchFinalResult.new(
		_input.match_id,
		_input.game_id,
		_input.rule_profile.profile_id,
		_input.rule_profile.version,
		_input.balance_profile.profile_id,
		_input.balance_profile.version,
		_input.home.team_id,
		_input.away.team_id,
		_snapshot.home.score,
		_snapshot.away.score,
		_snapshot.overtime_periods,
		statistics,
		_snapshot.event_sequence,
		_input.ratings_profile.version,
	)
	return MatchSimulationOutput.new(result, _ledger.events, _possessions)


# --- internals --------------------------------------------------------------

func _advance_period() -> void:
	var writer := _writer()
	writer.emit(MatchDomainEvent.PERIOD_ENDED, &"", &"", &"", &"", &"", &"", &"", 0,
		_snapshot.period)
	if _period_controller.match_is_complete(_snapshot, _input.rule_profile):
		writer.emit(MatchDomainEvent.MATCH_ENDED, &"", &"", &"", &"", &"", &"", &"", 0,
			_snapshot.period)
		_commit(writer)
		return
	_period_controller.assert_overtime_within_bounds(_snapshot)
	var next_period: int = _period_controller.next_period(_snapshot)
	var length_ms: int = _input.rule_profile.period_length_ms(next_period)
	writer.period = next_period
	writer.clock_ms = length_ms
	writer.emit(
		MatchDomainEvent.PERIOD_STARTED, &"", &"", &"", &"", &"", &"", &"", 0, next_period)
	_commit(writer)
	# A new period starts from a dead ball, so the next possession is never a
	# transition opportunity.
	_live_start = false


## §18.2 contextual adjustment, the timeout half: a coach stops the other side's
## run.
##
## The rule is symmetric and reads only public state — who is on a run, how many
## points it has reached, how many timeouts the team has left, and how much
## regulation is still to play. Either coach calls it on exactly the same
## condition, and its whole effect is the rest `MatchStateReducer` applies to
## everybody on the floor. It changes no probability and moves no possession.
func _consider_timeout() -> void:
	var team_id: StringName = _snapshot.possession_team_id
	if team_id.is_empty() or _run_team_id.is_empty() or _run_team_id == team_id:
		return
	var balance: SimulationBalanceProfile = _input.balance_profile
	if _run_points < balance.timeout_run_points:
		return
	if _snapshot.state_for(team_id).timeouts_remaining <= 0:
		return
	if GameManagement.remaining_ms(_snapshot, _input.rule_profile) < balance.timeout_run_reserve_ms:
		return
	var writer := _writer()
	writer.emit(MatchDomainEvent.TIMEOUT, team_id, &"", &"", &"", &"", &"run", &"", 0, _run_points)
	_commit(writer)
	# The run is answered whether or not the next possession scores: a coach who
	# has spent a timeout on it does not spend a second one on the same run.
	_run_points = 0
	_run_team_id = &""
	# A timeout is a dead ball, so the possession that follows it is never a
	# transition opportunity.
	_live_start = false


func _record_run(record: PossessionRecord) -> void:
	if record.points_scored <= 0:
		return
	if record.offense_team_id == _run_team_id:
		_run_points += record.points_scored
		return
	_run_team_id = record.offense_team_id
	_run_points = record.points_scored


func _apply_substitutions() -> void:
	var writer := _writer()
	for team_profile: TeamMatchProfile in [_input.home, _input.away]:
		for order in _rotation.plan(_snapshot, _input, team_profile.team_id):
			writer.emit(
				MatchDomainEvent.CHECK_OUT, team_profile.team_id, order.outgoing_id,
				&"", &"", &"", order.reason_id())
			writer.emit(
				MatchDomainEvent.CHECK_IN, team_profile.team_id, order.incoming_id,
				&"", &"", &"", order.reason_id())
	if writer.events.is_empty():
		return
	_commit(writer)


func _writer() -> MatchEventWriter:
	return MatchEventWriter.new(
		_input.match_id, _snapshot.event_sequence, _snapshot.period, _snapshot.clock_ms)


func _commit(writer: MatchEventWriter) -> void:
	_ledger.append_all(writer.events)
	_snapshot = _reducer.apply_events(_snapshot, writer.events)


func _is_on_court(player_id: StringName) -> bool:
	if _snapshot.home.has_player(player_id):
		return _snapshot.home.is_on_court(player_id)
	if _snapshot.away.has_player(player_id):
		return _snapshot.away.is_on_court(player_id)
	return false
