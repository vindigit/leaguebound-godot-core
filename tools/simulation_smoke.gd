extends SceneTree

## Fixed-seed diagnostic sweep over the Stage 3 match engine.
##
## The Stage 3 gate is explicit that statistical bands are **diagnostic only**
## at this stage: "Do not tune final scoring totals until turnover, action
## selection, fouls, free throws, rebounds, lineups, time, and possession
## counting are structurally correct." This tool therefore reports and never
## fails on a band — it fails only on an invariant violation, which is the part
## that is not negotiable.
##
## Run:
##   godot --headless --path . --script res://tools/simulation_smoke.gd

const SEEDS: PackedInt64Array = [
	20260815, 7001, 91, 1234, 4242, 31337, 8675309, 20260101, 55555, 987654,
]

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var totals: Dictionary = _blank_totals()
	var games: int = 0
	var overtime_games: int = 0
	var elapsed_start: int = Time.get_ticks_msec()
	for seed_value in SEEDS:
		var input: MatchInput = MatchFixtureFactory.standard_match()
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		_check_invariants(input, output, seed_value)
		games += 1
		if output.final_result.overtime_periods > 0:
			overtime_games += 1
		for team_id: StringName in [input.home.team_id, input.away.team_id]:
			var line: TeamStatLine = output.final_result.statistics.team_line(team_id)
			var opponent_id: StringName = input.opposing_team_id(team_id)
			var opponent: TeamStatLine = output.final_result.statistics.team_line(opponent_id)
			_accumulate(totals, line, opponent)
	var elapsed: int = Time.get_ticks_msec() - elapsed_start

	var team_games: float = float(games * 2)
	print("LeagueBound Stage 3 simulation smoke")
	print("  games: %d (%d with overtime) in %d ms" % [games, overtime_games, elapsed])
	_report("engine possessions/game", totals, "possessions", team_games)
	_report("points/game", totals, "points", team_games)
	print("  points/possession: %.3f" % _ratio(totals, "points", "possessions"))
	print("  FG%%: %.1f%%" % (100.0 * _ratio(totals, "fgm", "fga")))
	print("  3P%%: %.1f%%" % (100.0 * _ratio(totals, "3pm", "3pa")))
	print("  3PA/FGA: %.1f%%" % (100.0 * _ratio(totals, "3pa", "fga")))
	print("  FT%%: %.1f%%" % (100.0 * _ratio(totals, "ftm", "fta")))
	print("  FTA/FGA: %.1f%%" % (100.0 * _ratio(totals, "fta", "fga")))
	print("  turnovers/100 possessions: %.1f" % (100.0 * _ratio(totals, "turnovers", "possessions")))
	print("  offensive rebound %%: %.1f%%" % (100.0 * _ratio(totals, "oreb", "oreb_denominator")))
	print("  assist %% of made FG: %.1f%%" % (100.0 * _ratio(totals, "assists", "fgm")))
	print("  steals/game: %.1f" % (_value(totals, "steals") / team_games))
	print("  blocks/game: %.1f" % (_value(totals, "blocks") / team_games))
	print("  personal fouls/game: %.1f" % (_value(totals, "fouls") / team_games))
	print("  paint points/game: %.1f" % (_value(totals, "paint_points") / team_games))
	print("  second-chance points/game: %.1f" % (_value(totals, "second_chance") / team_games))
	print("  possession estimate/game: %.1f" % (_value(totals, "estimate") / team_games))

	if _failures.is_empty():
		print("Invariants: PASS")
		quit(0)
		return
	for failure in _failures:
		printerr("INVARIANT: %s" % failure)
	printerr("Invariants: %d violation(s)" % _failures.size())
	quit(1)


func _check_invariants(
	input: MatchInput,
	output: MatchSimulationOutput,
	seed_value: int,
) -> void:
	var label: String = "seed %d" % seed_value
	var statistics: MatchStatistics = output.final_result.statistics
	for failure in statistics.reconcile():
		_failures.append("%s: %s" % [label, failure])
	if output.final_result.home_score == output.final_result.away_score:
		_failures.append("%s: completed match remained tied" % label)
	if output.final_result.final_event_sequence != output.events.size():
		_failures.append("%s: final event sequence does not match the ledger" % label)

	var starts: Dictionary = {}
	var ends: Dictionary = {}
	for event in output.events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			starts[event.possession_id] = _count(starts, event.possession_id) + 1
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			ends[event.possession_id] = _count(ends, event.possession_id) + 1
	for record in output.possessions:
		if _count(starts, record.possession_id) != 1:
			_failures.append("%s: possession %d has no single start" % [label, record.possession_id])
		if _count(ends, record.possession_id) != 1:
			_failures.append("%s: possession %d has no single end" % [label, record.possession_id])
	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		var line: TeamStatLine = statistics.team_line(team_id)
		if line.engine_possessions != output.engine_possessions(team_id):
			_failures.append("%s: engine possessions disagree for %s" % [label, team_id])


func _count(counts: Dictionary, key: int) -> int:
	if not counts.has(key):
		return 0
	var value: int = counts[key]
	return value


func _blank_totals() -> Dictionary:
	return {
		"possessions": 0.0, "points": 0.0, "fgm": 0.0, "fga": 0.0,
		"3pm": 0.0, "3pa": 0.0, "ftm": 0.0, "fta": 0.0,
		"turnovers": 0.0, "oreb": 0.0, "oreb_denominator": 0.0,
		"assists": 0.0, "steals": 0.0, "blocks": 0.0, "fouls": 0.0,
		"paint_points": 0.0, "second_chance": 0.0, "estimate": 0.0,
	}


func _accumulate(totals: Dictionary, line: TeamStatLine, opponent: TeamStatLine) -> void:
	_add(totals, "possessions", float(line.engine_possessions))
	_add(totals, "points", float(line.points))
	_add(totals, "fgm", float(line.field_goals_made))
	_add(totals, "fga", float(line.field_goals_attempted))
	_add(totals, "3pm", float(line.three_pointers_made))
	_add(totals, "3pa", float(line.three_pointers_attempted))
	_add(totals, "ftm", float(line.free_throws_made))
	_add(totals, "fta", float(line.free_throws_attempted))
	_add(totals, "turnovers", float(line.turnovers))
	_add(totals, "oreb", float(line.offensive_rebounds))
	_add(totals, "oreb_denominator", float(line.offensive_rebounds + opponent.defensive_rebounds))
	_add(totals, "assists", float(line.assists))
	_add(totals, "steals", float(line.steals))
	_add(totals, "blocks", float(line.blocks))
	_add(totals, "fouls", float(line.personal_fouls))
	_add(totals, "paint_points", float(line.paint_points))
	_add(totals, "second_chance", float(line.second_chance_points))
	_add(totals, "estimate", line.possession_estimate)


func _add(totals: Dictionary, key: String, value: float) -> void:
	var current: float = totals[key]
	totals[key] = current + value


func _value(totals: Dictionary, key: String) -> float:
	var current: float = totals[key]
	return current


func _ratio(totals: Dictionary, numerator: String, denominator: String) -> float:
	var bottom: float = _value(totals, denominator)
	if bottom <= 0.0:
		return 0.0
	return _value(totals, numerator) / bottom


func _report(label: String, totals: Dictionary, key: String, team_games: float) -> void:
	print("  %s: %.1f" % [label, _value(totals, key) / team_games])
