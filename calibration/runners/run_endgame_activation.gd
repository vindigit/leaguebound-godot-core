extends SceneTree

## How often does each end-of-regulation decision actually fire, and to whom?
## (`PROJECT_STATUS.md` §5.25, §5.26.)
##
## `EndgameStrategy` shipped seven coaching decisions whose eligibility gates
## are proven by unit tests. A gate that is *correct* and a decision that is
## *sane in a played game* are different claims, and §5.25's measurement round
## reported the second one as a bare count with nothing to compare it against.
## Two of those counts were the visible symptom of the defects §5.26 corrects —
## timeout-to-advance at 491 activations per 200 college games and 836 per 200
## top domestic is not a coaching decision, it is an allowance being drained —
## and the count alone did not say so, because nothing stated what the number
## should look like.
##
## So this runner reports two things per decision rather than one:
##
## - **the count**, so a decision that has stopped firing altogether is visible
##   (a narrowed gate that silently reaches nothing is its own defect), and
## - **the shape**: activations per game, and for the decisions where the
##   correction is about *who* makes them, the margin state of the team that
##   did. A leading team that intentionally misses a free throw, or a team with
##   a safe lead running a designed play for its closer, is a defect this
##   report names rather than a number a reader has to interpret.
##
## Four invariants are judged rather than printed, because they are the
## §5.26 corrections stated as properties of played games:
##
## ```text
## no_leading_team_intentionally_missed   every intentional miss was a trailing team's
## no_repeated_leading_foul               no possession committed two leading-by-three fouls
## no_advance_below_reserve               every advance timeout left the reserve intact
## no_unpermitted_advance                 no advance timeout under a profile that forbids it
## ```
##
## This is a diagnostic. It certifies nothing at any sample it is given, and it
## judges no calibration band — the §14 bands are `run_competition_calibration`'s
## business and this runner does not touch a target.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_endgame_activation.gd -- \
##       [--games=N] [--competition=college|top_domestic_pro|all] [--range=audit|audit_second] \
##       [--label=NAME]

const DEFAULT_GAMES: int = 200

## Seed ranges owned by this runner, disjoint from every range any other
## section uses. Audit ranges: nothing here was read before a value was chosen,
## because this runner fits nothing.
const AUDIT_BASE: int = 950000
const AUDIT_SECOND_BASE: int = 955000

const TIMEOUT_ADVANCE: StringName = &"advance"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var range_name: String = CalibrationCli.string_option(options, &"range", "audit")
	var label: String = CalibrationCli.string_option(options, &"label", "endgame_activation")
	var base: int = _range_base(range_name)
	var competitions: Array[int] = _competitions(selection)

	var context := ReportContext.create(
		&"endgame_activation_audit",
		"End-of-regulation decision activation audit",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per competition"
	context.sample_count = games
	context.competition_id = (
		CalibrationTargets.competition_id(competitions[0]) if competitions.size() == 1
		else &"all")
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"BELOW CERTIFICATION REQUIREMENT. %d games per competition against the " % games
		+ "§27.1 requirement; this is directional evidence and certifies nothing.")
	context.notes.append(
		"Seed range: %s, variations %d-%d, RNG seeds %d-%d."
		% [range_name, base, base + games - 1, base + 1, base + games])
	context.notes.append(
		"Counts are reported beside per-game rates and beside the margin state of "
		+ "the deciding team, because a bare count did not distinguish a coaching "
		+ "decision from a drained allowance (§5.26).")

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	for competition in competitions:
		var tally: Tally = _simulate(competition, games, base)
		rows.append(tally.to_dictionary())
		_judge(report, tally)
	report.add_section(&"activations", rows)
	report.finish()
	quit(ReportWriter.publish(report, "endgame_activation_%s" % label))


func _range_base(range_name: String) -> int:
	match range_name:
		"audit":
			return AUDIT_BASE
		"audit_second":
			return AUDIT_SECOND_BASE
		_:
			printerr("unknown range '%s'; using audit" % range_name)
			return AUDIT_BASE


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


# --- sampling -----------------------------------------------------------------

## One competition's activation sample.
class Tally:
	extends RefCounted

	var competition: int = 0
	var games: int = 0
	var advance_permitted: bool = false

	var two_for_one: int = 0
	var hold: int = 0
	var quick_two: int = 0
	var designed_play: int = 0
	var leading_foul: int = 0
	var intentional_miss: int = 0
	var timeout_advance: int = 0

	## The shape checks. Each counts an occurrence the correction forbids, so
	## every one of them is zero in a corrected engine.
	var leading_team_intentional_misses: int = 0
	var repeated_leading_fouls: int = 0
	var advances_below_reserve: int = 0
	var unpermitted_advances: int = 0

	## Rebounds that followed an intentional miss, split by who won the board,
	## and the misses whose possession ended on the horn before the board was
	## resolved. The three together account for every intentional miss: the
	## decision is taken inside the last few seconds of regulation, so a period
	## that expires during the rebound draw is an ordinary outcome and not a
	## missing rebound — the same buzzer that ends any other late scramble.
	var miss_rebounds_offensive: int = 0
	var miss_rebounds_defensive: int = 0
	var miss_ended_on_the_horn: int = 0

	## The largest number of advance timeouts any one team spent in any one
	## game, which is the statistic the drained-allowance defect showed up in.
	var most_advances_by_one_team: int = 0

	func per_game(count: int) -> float:
		return 0.0 if games == 0 else float(count) / float(games)

	func to_dictionary() -> Dictionary:
		return {
			"competition": String(CalibrationTargets.competition_id(competition)),
			"games": games,
			"advance_permitted": advance_permitted,
			"two_for_one": two_for_one,
			"hold": hold,
			"quick_two": quick_two,
			"designed_play": designed_play,
			"leading_foul": leading_foul,
			"intentional_miss": intentional_miss,
			"timeout_advance": timeout_advance,
			"timeout_advance_per_game": per_game(timeout_advance),
			"most_advances_by_one_team": most_advances_by_one_team,
			"miss_rebounds_offensive": miss_rebounds_offensive,
			"miss_rebounds_defensive": miss_rebounds_defensive,
			"miss_ended_on_the_horn": miss_ended_on_the_horn,
			"leading_team_intentional_misses": leading_team_intentional_misses,
			"repeated_leading_fouls": repeated_leading_fouls,
			"advances_below_reserve": advances_below_reserve,
			"unpermitted_advances": unpermitted_advances,
		}


func _simulate(competition: int, games: int, base: int) -> Tally:
	var tally := Tally.new()
	tally.competition = competition
	tally.games = games
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	tally.advance_permitted = rules.timeout_advance_permitted
	var reserve: int = balance.timeout_advance_reserve_timeouts

	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		var session := MatchSession.new(input, SeededRandomSource.new(variation + 1))
		var output: MatchSimulationOutput = session.run_to_completion()
		_accumulate(tally, output, input, rules, reserve)
		if games > 50 and (index + 1) % 50 == 0:
			print("  %s: %d/%d games" % [
				CalibrationTargets.competition_id(competition), index + 1, games])
	return tally


func _accumulate(
	tally: Tally,
	output: MatchSimulationOutput,
	input: MatchInput,
	rules: CompetitionRuleProfile,
	reserve: int,
) -> void:
	# Timeout allowances are tracked forward through the ledger so "did this
	# call leave the reserve intact" is answered from what the game actually
	# did rather than from the final state, which cannot see the order.
	var remaining: Dictionary[StringName, int] = {
		input.home.team_id: rules.timeouts_per_team,
		input.away.team_id: rules.timeouts_per_team,
	}
	var advances: Dictionary[StringName, int] = {
		input.home.team_id: 0, input.away.team_id: 0,
	}
	var leading_fouls_by_possession: Dictionary[int, int] = {}
	var pending_miss_possession: int = -1

	for event in output.events:
		match event.event_type:
			MatchDomainEvent.ACTION_SELECTED:
				match event.detail_id:
					EndgameStrategy.TAG_TWO_FOR_ONE:
						tally.two_for_one += 1
					EndgameStrategy.TAG_HOLD:
						tally.hold += 1
					EndgameStrategy.TAG_QUICK_TWO:
						tally.quick_two += 1
					EndgameStrategy.TAG_DESIGNED_PLAY:
						tally.designed_play += 1
			MatchDomainEvent.TIMEOUT:
				var before: int = remaining[event.team_id]
				remaining[event.team_id] = before - 1
				if event.detail_id != TIMEOUT_ADVANCE:
					continue
				tally.timeout_advance += 1
				advances[event.team_id] = advances[event.team_id] + 1
				tally.most_advances_by_one_team = maxi(
					tally.most_advances_by_one_team, advances[event.team_id])
				if not rules.timeout_advance_permitted:
					tally.unpermitted_advances += 1
				# The call is only legitimate if the allowance it was drawn
				# from left the reserve standing behind it.
				if before - 1 < reserve:
					tally.advances_below_reserve += 1
			MatchDomainEvent.FOUL:
				if event.detail_id != FoulType.id_of(FoulType.Value.LEADING_PROTECT):
					continue
				tally.leading_foul += 1
				var count: int = leading_fouls_by_possession.get(event.possession_id, 0) + 1
				leading_fouls_by_possession[event.possession_id] = count
				if count > 1:
					tally.repeated_leading_fouls += 1
			MatchDomainEvent.FREE_THROW_MISSED:
				if event.detail_id != &"intentional":
					continue
				tally.intentional_miss += 1
				pending_miss_possession = event.possession_id
			MatchDomainEvent.REBOUND:
				if pending_miss_possession != event.possession_id:
					continue
				pending_miss_possession = -1
				if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
					tally.miss_rebounds_offensive += 1
				else:
					tally.miss_rebounds_defensive += 1
			MatchDomainEvent.POSSESSION_ENDED:
				if pending_miss_possession != event.possession_id:
					continue
				# The possession that took the miss ended without a rebound
				# event, which at this point on the clock means the horn.
				pending_miss_possession = -1
				tally.miss_ended_on_the_horn += 1

	# Who was ahead when each intentional miss was taken. The ledger carries no
	# running score, so it is reconstructed from the points already attributed
	# — the same arithmetic the box score reconciles from.
	tally.leading_team_intentional_misses += _leading_team_misses(output, input)


## Every intentional miss in this game that was taken by a team that was not
## trailing by exactly two at the moment it was taken. That is the state
## `EndgameStrategy.INTENTIONAL_MISS_DEFICIT` names, and any other one is the
## §5.26 defect — most sharply a *leading* team missing on purpose.
##
## The running score is reconstructed the same way `MatchStateReducer` builds
## it, and that means both point-scoring events rather than only the obvious
## one: `FIELD_GOAL_MADE` carries its value in `points`, and `FREE_THROW_MADE`
## carries **`points = 0`** and is worth one by virtue of being a made free
## throw. Summing `points` alone silently drops every free throw in the game,
## which for a rule about the margin *inside a free-throw trip* is the one
## error that would make this check report the opposite of the truth.
func _leading_team_misses(output: MatchSimulationOutput, input: MatchInput) -> int:
	var score: Dictionary[StringName, int] = {
		input.home.team_id: 0, input.away.team_id: 0,
	}
	var wrong: int = 0
	for event in output.events:
		if (
			event.event_type == MatchDomainEvent.FREE_THROW_MISSED
			and event.detail_id == &"intentional"
		):
			var opponent: StringName = input.opposing_team_id(event.team_id)
			var margin: int = score[event.team_id] - score[opponent]
			if margin != -EndgameStrategy.INTENTIONAL_MISS_DEFICIT:
				wrong += 1
		match event.event_type:
			MatchDomainEvent.FIELD_GOAL_MADE:
				score[event.team_id] = score[event.team_id] + event.points
			MatchDomainEvent.FREE_THROW_MADE:
				score[event.team_id] = score[event.team_id] + 1
	return wrong


# --- reporting ----------------------------------------------------------------

func _judge(report: CalibrationReport, tally: Tally) -> void:
	var competition_id: StringName = CalibrationTargets.competition_id(tally.competition)
	for entry: Array in [
		[&"two_for_one", tally.two_for_one],
		[&"hold", tally.hold],
		[&"quick_two", tally.quick_two],
		[&"designed_play", tally.designed_play],
		[&"leading_foul", tally.leading_foul],
		[&"intentional_miss", tally.intentional_miss],
		[&"timeout_advance", tally.timeout_advance],
	]:
		var decision: StringName = entry[0]
		var count: int = entry[1]
		report.add_metric(CalibrationMetric.raw(
			StringName("activation.%s.%s" % [competition_id, decision]),
			"Times the %s decision fired, per game." % decision,
			"complete games",
			tally.per_game(count),
			tally.games))

	report.add_metric(CalibrationMetric.boolean(
		StringName("shape.%s.no_leading_team_intentionally_missed" % competition_id),
		"Every intentional final free-throw miss was taken by a team trailing by "
		+ "exactly two, which is the only state the decision exists for.",
		tally.leading_team_intentional_misses == 0,
		"PROJECT_STATUS.md §5.26",
		tally.intentional_miss))
	report.add_metric(CalibrationMetric.boolean(
		StringName("shape.%s.no_repeated_leading_foul" % competition_id),
		"No possession committed a second leading-by-three foul.",
		tally.repeated_leading_fouls == 0,
		"PROJECT_STATUS.md §5.26",
		tally.leading_foul))
	report.add_metric(CalibrationMetric.boolean(
		StringName("shape.%s.no_advance_below_reserve" % competition_id),
		"Every timeout-to-advance left the coach's reserve allowance standing.",
		tally.advances_below_reserve == 0,
		"PROJECT_STATUS.md §5.26",
		tally.timeout_advance))
	report.add_metric(CalibrationMetric.boolean(
		StringName("shape.%s.no_unpermitted_advance" % competition_id),
		"No timeout-to-advance was called under a rule profile that forbids it.",
		tally.unpermitted_advances == 0,
		"SIMULATION_SPEC.md §4",
		tally.timeout_advance))
