extends SceneTree

## One hash over many complete ledgers, for mutation evidence.
##
## A mutation is killed when a test fails and is *equivalent* when it provably
## cannot change any observable. "No test failed" does not prove the second
## thing — the suite might simply not look where the mutation lives — so this
## tool supplies the direct evidence instead: it replays a fixed set of complete
## matches, serializes every ledger with `MatchLedgerSerializer`, and reduces the
## whole set to one fingerprint. §24.3 makes the ordered ledger the authority for
## every official statistic, so two runs with the same fingerprint produced the
## same events in the same order and therefore the same everything.
##
## An equivalent mutant leaves the fingerprint byte-identical. A mutant that
## changes the fingerprint is live, whatever the suite said, and the count of
## differing scenarios says how reachable it is.
##
## The venue arms are included because the §19.4 environment is read on three
## different production paths and a home-only mutation is invisible to a sample
## that never plays a neutral court.
##
## `--dump` prints one scenario's whole serialized ledger instead of the
## fingerprint, so a differing fingerprint can be reduced to its *first*
## divergent event rather than reported as "something moved".
##
## Run:
##   godot --headless --path . --script res://tools/mutation_fingerprint.gd -- \
##       [--games=N] [--competition=all|<id>] [--base=N] [--dump=<id>|<arm>|<variation>]

const DEFAULT_GAMES: int = 12
const DEFAULT_BASE: int = 900000

## The venue arms. `neutral` is the environment switched off, which is the only
## value that provably contributes nothing on any of the three §19.4 paths.
const ARMS: PackedFloat64Array = [0.5, 0.0, 0.5]
const ARM_IDS: PackedStringArray = ["home", "neutral", "reversed"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var base: int = CalibrationCli.int_option(options, &"base", DEFAULT_BASE)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var dump: String = CalibrationCli.string_option(options, &"dump", "")
	if not dump.is_empty():
		_dump(dump)
		return

	var competitions: Array[int] = []
	if selection == "all":
		competitions = CalibrationTargets.all_competitions()
	else:
		for competition in CalibrationTargets.all_competitions():
			if String(CalibrationTargets.competition_id(competition)) == selection:
				competitions.append(competition)
	if competitions.is_empty():
		printerr("unknown competition '%s'" % selection)
		quit(2)
		return

	var lines := PackedStringArray()
	var assists: int = 0
	var points: int = 0
	var fouls: int = 0
	var free_throws: int = 0
	var scenarios: int = 0
	for competition in competitions:
		for arm in range(ARM_IDS.size()):
			for index in range(games):
				var variation: int = base + index
				var input: MatchInput = _input(competition, variation, arm)
				var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
					input, SeededRandomSource.new(variation + 1))
				lines.append("%s|%s|%d|%s" % [
					CalibrationTargets.competition_id(competition),
					ARM_IDS[arm], variation,
					MatchLedgerSerializer.hash_output(output)])
				scenarios += 1
				for team_id: StringName in [input.home.team_id, input.away.team_id]:
					var line: TeamStatLine = output.final_result.statistics.team_line(team_id)
					assists += line.assists
					points += line.points
					fouls += line.personal_fouls
					free_throws += line.free_throws_attempted

	# The per-scenario hashes stay in the output so a differing fingerprint can be
	# localized to the first scenario that moved rather than only reported as
	# "something changed".
	print("scenarios=%d" % scenarios)
	print("assists=%d points=%d fouls=%d free_throw_attempts=%d" % [
		assists, points, fouls, free_throws])
	print("fingerprint=%s" % MatchLedgerSerializer.hash_text("\n".join(lines)))
	for line in lines:
		print("  %s" % line)
	quit(0)


## One scenario's complete ledger, one event per line, for a first-divergence
## diff against the same scenario from an unmutated tree.
func _dump(descriptor: String) -> void:
	var parts: PackedStringArray = descriptor.split("|")
	if parts.size() != 3:
		printerr("--dump wants <competition>|<arm>|<variation>")
		quit(2)
		return
	var competition: int = -1
	for candidate in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(candidate)) == parts[0]:
			competition = candidate
	var arm: int = ARM_IDS.find(parts[1])
	if competition < 0 or arm < 0:
		printerr("unknown competition or arm in '%s'" % descriptor)
		quit(2)
		return
	var variation: int = int(parts[2])
	var input: MatchInput = _input(competition, variation, arm)
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(variation + 1))
	print(MatchLedgerSerializer.serialize_output(output))
	quit(0)


## The same venue construction the home-court diagnostic uses, so a mutation
## measured here and a metric measured there are describing one fixture.
func _input(competition: int, variation: int, arm: int) -> MatchInput:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var first: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", variation * 2, balance, 0.0)
	var second: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", variation * 2, balance, 0.0)
	var reversed: bool = ARM_IDS[arm] == "reversed"
	return MatchInput.new(
		StringName("mutation_%s_%d" % [
			CalibrationTargets.competition_id(competition), variation]),
		StringName("mutation_game_%d" % variation),
		CompetitionCatalog.rules_for(competition),
		balance,
		second if reversed else first,
		first if reversed else second,
		first.team_id if variation % 2 == 0 else second.team_id,
		CompetitionCatalog.ratings_profile(),
		ARMS[arm])
