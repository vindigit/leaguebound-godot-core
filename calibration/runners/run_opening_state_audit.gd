extends SceneTree

## What the opening states actually produce, per competition
## (`PROJECT_STATUS.md` §5.30). Diagnostic only: it tunes nothing, reads no
## target, and certifies nothing.
##
## The opening a possession ran is reconstructible from its own events, which is
## the property that makes the desperation path auditable without a new ledger
## field:
##
## - ordinary       — `INBOUND`, then `ADVANCE`, then `HALF_COURT_ENTERED`
## - desperation/deep    — `INBOUND` and `ADVANCE`, no `HALF_COURT_ENTERED`
## - desperation/backcourt — `INBOUND` alone; the offence never crossed
## - live            — no `INBOUND` at all
##
## A transition possession also has no `HALF_COURT_ENTERED`, so the live openings
## are separated out first and the desperation counts are taken only from
## possessions that began with a throw-in.
##
## Run:
##   godot --headless --path . --script \
##     res://calibration/runners/run_opening_state_audit.gd -- \
##     [--games=N] [--competition=college|top_domestic_pro|all]

const DEFAULT_GAMES: int = 100
const BASE_SEED: int = 990000


class Tally:
	extends RefCounted

	var games: int = 0
	var possessions: int = 0
	var live_openings: int = 0
	var ordinary_openings: int = 0
	var desperation_deep: int = 0
	var desperation_backcourt: int = 0
	var desperation_attempts: int = 0
	var desperation_makes: int = 0
	var desperation_turnovers: int = 0
	var desperation_expired: int = 0
	var field_goal_attempts: int = 0
	var inbound_charged: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	assert(games > 0, "games must be positive")

	print("=== Opening state audit ===")
	print("  games=%d seeds=%d..%d" % [games, BASE_SEED + 1, BASE_SEED + games])
	print("  DIAGNOSTIC ONLY. Changes no target and certifies nothing.")
	for competition in _competitions(selection):
		var tally := Tally.new()
		for index in range(games):
			var variation: int = BASE_SEED + index
			var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
			var output: MatchSimulationOutput = MatchSession.new(
				input, SeededRandomSource.new(variation + 1)).run_to_completion()
			_measure_game(tally, output)
		_report(CalibrationTargets.competition_id(competition), tally)
	quit(0)


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return [
			CalibrationTargets.Competition.COLLEGE,
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO,
		] as Array[int]
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	assert(false, "unknown competition '%s'" % selection)
	return [] as Array[int]


func _measure_game(tally: Tally, output: MatchSimulationOutput) -> void:
	tally.games += 1
	var grouped: Dictionary = {}
	for event in output.events:
		if event.possession_id <= 0:
			continue
		if not grouped.has(event.possession_id):
			grouped[event.possession_id] = ([] as Array[MatchDomainEvent])
		(grouped[event.possession_id] as Array[MatchDomainEvent]).append(event)

	for possession_id: int in grouped:
		var events: Array[MatchDomainEvent] = []
		events.assign(grouped[possession_id] as Array)
		tally.possessions += 1
		var inbound: MatchDomainEvent = _first(events, MatchDomainEvent.INBOUND)
		var started: MatchDomainEvent = _first(events, MatchDomainEvent.POSSESSION_STARTED)
		var advance: MatchDomainEvent = _first(events, MatchDomainEvent.ADVANCE)
		var entered: MatchDomainEvent = _first(events, MatchDomainEvent.HALF_COURT_ENTERED)
		var attempts: int = _count(events, MatchDomainEvent.FIELD_GOAL_ATTEMPT)
		tally.field_goal_attempts += attempts

		if inbound == null:
			tally.live_openings += 1
			continue
		# The inbound charged the game clock exactly when its timestamp is behind
		# the possession's own start, which is the v13 contract read off the
		# ledger rather than asserted about it.
		if started != null and inbound.clock_ms < started.clock_ms:
			tally.inbound_charged += 1
		if entered != null:
			tally.ordinary_openings += 1
			continue
		if advance == null:
			tally.desperation_backcourt += 1
		else:
			tally.desperation_deep += 1
		tally.desperation_attempts += attempts
		tally.desperation_makes += _count(events, MatchDomainEvent.FIELD_GOAL_MADE)
		tally.desperation_turnovers += _count(events, MatchDomainEvent.TURNOVER)
		var ended: MatchDomainEvent = _first(events, MatchDomainEvent.POSSESSION_ENDED)
		if ended != null and ended.detail_id == PossessionEndReason.id_of(
			PossessionEndReason.Value.PERIOD_EXPIRED
		):
			tally.desperation_expired += 1


func _report(competition: StringName, tally: Tally) -> void:
	var desperation: int = tally.desperation_deep + tally.desperation_backcourt
	print("\n--- %s (%d games) ---" % [competition, tally.games])
	print("  possessions: %d (%.2f per game)" % [
		tally.possessions, float(tally.possessions) / maxf(float(tally.games), 1.0)])
	print("  openings: live=%d ordinary=%d desperation=%d" % [
		tally.live_openings, tally.ordinary_openings, desperation])
	print("  inbounds charged game clock: %d of %d dead-ball openings (%.4f)" % [
		tally.inbound_charged,
		tally.ordinary_openings + desperation,
		_share(tally.inbound_charged, tally.ordinary_openings + desperation)])
	print("  desperation openings per game: %.3f (deep=%d backcourt=%d)" % [
		float(desperation) / maxf(float(tally.games), 1.0),
		tally.desperation_deep, tally.desperation_backcourt])
	print("  desperation share of all possessions: %.5f" % _share(
		desperation, tally.possessions))
	print("  desperation attempts: %d (%.4f of the %d field-goal attempts)" % [
		tally.desperation_attempts, _share(tally.desperation_attempts,
		tally.field_goal_attempts), tally.field_goal_attempts])
	print("  desperation makes: %d of %d attempts (%.4f)" % [
		tally.desperation_makes, tally.desperation_attempts,
		_share(tally.desperation_makes, tally.desperation_attempts)])
	print("  desperation turnovers: %d; expired without terminal transfer: %d" % [
		tally.desperation_turnovers, tally.desperation_expired])


func _share(numerator: int, denominator: int) -> float:
	if denominator <= 0:
		return 0.0
	return float(numerator) / float(denominator)


func _first(events: Array[MatchDomainEvent], event_type: StringName) -> MatchDomainEvent:
	for event: MatchDomainEvent in events:
		if event.event_type == event_type:
			return event
	return null


func _count(events: Array[MatchDomainEvent], event_type: StringName) -> int:
	var total: int = 0
	for event: MatchDomainEvent in events:
		if event.event_type == event_type:
			total += 1
	return total
