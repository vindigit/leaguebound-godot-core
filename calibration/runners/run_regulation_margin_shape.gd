extends SceneTree

## The shape of the regulation margin distribution near zero.
##
## §14.2 judges three points on one curve: the overtime rate is the mass at
## **exactly** zero, the close-game rate is the mass within five, and the
## blowout rate is the mass at twenty or beyond. They are not three independent
## targets — a distribution that satisfies two of them constrains the third —
## and the 10,000-game diagnostic reaches a state where that matters: college's
## close-game and blowout rates are both inside their bands while its overtime
## rate is 6.6 standard errors below its own.
##
## That combination is only possible if the curve is the wrong *shape* near
## zero rather than the wrong *width*, so this measures the shape directly
## instead of inferring it from the two rates. It histograms the regulation
## margin — the margin at the end of regulation, which is zero for exactly the
## games that reached overtime — and reports the share of the close-game mass
## that sits in each bucket.
##
## A locally flat distribution puts 1 in 11 of the |margin| <= 5 mass at zero
## (9.1%). The §14.2 bands' own midpoints require 0.06/0.28 = 21.4%. Which of
## those the engine resembles is the question, and it is a question about the
## end of regulation rather than about scoring rates.
##
## This is a diagnostic. It certifies nothing and judges no band.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_regulation_margin_shape.gd -- \
##       [--games=N] [--competition=college|top_domestic_pro|all] [--shard=I --shards=N]

const DEFAULT_GAMES: int = 2000

## Disjoint from every range any other section owns.
const SHAPE_BASE: int = 970000

const CLOSE_MARGIN: int = 5
const REPORTED_BUCKETS: int = 13


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)

	print("=== Regulation margin shape near zero ===")
	print("  games=%d per competition, seeds %d.." % [games, SHAPE_BASE + shard * games + 1])
	print("  DIRECTIONAL ONLY. Certifies nothing and judges no §14 band.")
	print("")

	for competition in _competitions(selection):
		_measure(competition, games, SHAPE_BASE + shard * games)
	quit(0)


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


func _measure(competition: int, games: int, base: int) -> void:
	var histogram: PackedInt64Array = PackedInt64Array()
	histogram.resize(REPORTED_BUCKETS)
	var close: int = 0
	var blowout: int = 0
	var overtime: int = 0

	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		var result: MatchFinalResult = output.final_result
		# A game that reached overtime was tied when regulation ended, whatever
		# it finished at. Every other game ended regulation at its final margin.
		var regulation_margin: int = (
			0 if result.overtime_periods > 0
			else absi(result.home_score - result.away_score))
		if regulation_margin == 0:
			overtime += 1
		if regulation_margin <= CLOSE_MARGIN:
			close += 1
		if absi(result.home_score - result.away_score) >= 20:
			blowout += 1
		histogram[mini(regulation_margin, REPORTED_BUCKETS - 1)] += 1
		if games > 250 and (index + 1) % 250 == 0:
			print("  %s: %d/%d" % [
				CalibrationTargets.competition_id(competition), index + 1, games])

	print("--- %s (%d games) ---" % [CalibrationTargets.competition_id(competition), games])
	print("  overtime=%.4f close=%.4f blowout=%.4f" % [
		float(overtime) / float(games), float(close) / float(games),
		float(blowout) / float(games)])
	print("  regulation margin histogram (share of all games, and of the close-game mass):")
	for bucket in range(REPORTED_BUCKETS):
		var label: String = (
			"%d+" % (REPORTED_BUCKETS - 1) if bucket == REPORTED_BUCKETS - 1 else str(bucket))
		var of_all: float = float(histogram[bucket]) / float(games)
		var of_close: float = (
			0.0 if close == 0 or bucket > CLOSE_MARGIN
			else float(histogram[bucket]) / float(close))
		print("    |margin|=%-4s n=%-7d %.4f of games%s" % [
			label, histogram[bucket], of_all,
			("   %.1f%% of close-game mass" % (of_close * 100.0)) if bucket <= CLOSE_MARGIN else ""])
	# The one number the §14.2 bands constrain jointly.
	print("  zero's share of the close-game mass: %.1f%%  (locally flat = %.1f%%, §14.2 midpoints = %.1f%%)"
		% [
			0.0 if close == 0 else 100.0 * float(overtime) / float(close),
			100.0 / float(CLOSE_MARGIN * 2 + 1),
			100.0 * 0.06 / 0.28,
		])
	print("")
