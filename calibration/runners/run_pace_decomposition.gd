extends SceneTree

## Where a competition's possessions per game actually come from, and what
## `pace_multiplier` still controls under the `simulation-v14` restart contract
## (`PROJECT_STATUS.md` §5.31, work-queue item 19).
##
## Diagnostic only. It reads no `BALANCE_SPEC.md` target, judges nothing, writes
## no profile, and certifies nothing. Its whole purpose is to answer three
## questions with numbers rather than with an offset:
##
## 1. **What is a possession made of?** Total game time is divided among
##    possessions; each possession's duration is divided among the stages that
##    consume it. A possession count is that division, not a free parameter.
## 2. **What did the restart contract change?** Every throw-in is classified by
##    its `RestartCause` and by whether it cost live game clock, so the seconds
##    §5.30 and §5.31 stopped charging are counted rather than inferred.
## 3. **Is `pace_multiplier` still the surface?** `--pace-scale` reruns the same
##    seeds against a scaled pace environment, which measures the elasticity of
##    possessions with respect to the parameter instead of assuming it.
##
## Run:
##   godot --headless --path . --script \
##     res://calibration/runners/run_pace_decomposition.gd -- \
##     [--games=N] [--competition=all|<id>] [--shard=I] [--pace-scale=X]

const DEFAULT_GAMES: int = 120
const PROGRESS_EVERY: int = 50


class Tally:
	extends RefCounted

	var games: int = 0
	var possessions: int = 0
	var regulation_possessions: int = 0
	var overtime_possessions: int = 0
	var overtime_games: int = 0
	var overtime_periods: int = 0
	var regulation_ms: int = 0
	var overtime_ms: int = 0
	var possession_ms: int = 0
	## Terminal shape of each possession.
	var made_field_goal: int = 0
	var made_free_throw: int = 0
	var turnovers: int = 0
	var live_transfers: int = 0
	var period_expired: int = 0
	var offensive_rebounds: int = 0
	var free_throw_trips: int = 0
	var free_throw_attempts: int = 0
	## Restart accounting, keyed by `RestartCause` id.
	var restarts_free: Dictionary = {}
	var restarts_charged: Dictionary = {}
	var throw_in_ms_charged: int = 0
	## Stage accounting inside a possession, in milliseconds of game clock.
	var advance_ms: int = 0
	var half_court_ms: int = 0
	var action_ms: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var pace_scale: float = CalibrationCli.float_option(options, &"pace-scale", 1.0)
	assert(games > 0, "games must be positive")
	assert(pace_scale > 0.0, "a pace scale must be positive")

	var base: int = shard * games
	print("=== Pace decomposition ===")
	print("  games=%d per competition, variations %d-%d, pace-scale=%.4f"
		% [games, base, base + games - 1, pace_scale])
	print("  DIAGNOSTIC ONLY. Reads no target, judges nothing, writes nothing.")
	for competition: int in _competitions(selection):
		var rules: CompetitionRuleProfile = _scaled_rules(competition, pace_scale)
		var tally := Tally.new()
		for index in range(games):
			var variation: int = base + index
			var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
			input.rule_profile = rules
			var output: MatchSimulationOutput = MatchSession.new(
				input, SeededRandomSource.new(variation + 1)).run_to_completion()
			_measure(tally, output, rules)
			if games > PROGRESS_EVERY and (index + 1) % PROGRESS_EVERY == 0:
				print("  %s: %d/%d games" % [
					CalibrationTargets.competition_id(competition), index + 1, games])
		_report(CalibrationTargets.competition_id(competition), rules, tally)
	quit(0)


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition: int in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	assert(false, "unknown competition '%s'" % selection)
	return []


## A copy of a launch profile with its pace environment scaled.
##
## Rebuilt field by field rather than mutated, because `CompetitionRuleProfile`
## is declared immutable and a diagnostic is not a licence to make it less so.
## Every field is then compared against the source, so a profile that grows a
## member this runner does not carry fails here instead of being silently
## dropped from the measurement.
func _scaled_rules(competition: int, pace_scale: float) -> CompetitionRuleProfile:
	var source: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
	if is_equal_approx(pace_scale, 1.0):
		return source
	var copy := CompetitionRuleProfile.new(
		source.profile_id, source.version, source.regulation_periods,
		source.period_seconds, source.overtime_seconds, source.shot_clock_seconds,
		source.personal_foul_limit, source.offensive_rebound_reset_seconds,
		source.frontcourt_seconds, source.team_foul_bonus_threshold, source.bonus_kind,
		source.team_foul_double_bonus_threshold, source.double_bonus_free_throws,
		source.team_fouls_reset_each_period, source.final_free_throw_reboundable,
		source.possession_arrow_enabled, source.three_point_profile_id,
		source.restricted_area_profile_id, source.pace_environment_id,
		source.officiating_profile_id, source.roster_rule_profile_id,
		source.pace_multiplier * pace_scale, source.timeouts_per_team,
		source.timeout_advance_permitted, source.made_basket_clock_stop_ms,
		source.made_basket_clock_stop_late_periods_only)
	for property: Dictionary in source.get_property_list():
		var name: String = str(property["name"])
		var usage: int = property["usage"] as int
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if name == "pace_multiplier" or name.begins_with("_"):
			continue
		assert(str(copy.get(name)) == str(source.get(name)),
			"the pace-scaled copy dropped '%s'; add it to _scaled_rules" % name)
	return copy


func _measure(
	tally: Tally,
	output: MatchSimulationOutput,
	rules: CompetitionRuleProfile,
) -> void:
	tally.games += 1
	var overtime_periods: int = output.final_result.overtime_periods
	tally.overtime_periods += overtime_periods
	if overtime_periods > 0:
		tally.overtime_games += 1
	tally.regulation_ms += rules.regulation_periods * rules.period_seconds * 1000
	tally.overtime_ms += overtime_periods * rules.overtime_seconds * 1000

	for record: PossessionRecord in output.possessions:
		tally.possessions += 1
		if record.start_period > rules.regulation_periods:
			tally.overtime_possessions += 1
		else:
			tally.regulation_possessions += 1
		tally.possession_ms += maxi(0, record.start_clock_ms - record.end_clock_ms)
		tally.offensive_rebounds += record.offensive_rebounds
		if record.live_transfer:
			tally.live_transfers += 1
		match record.restart_cause:
			RestartCause.Value.MADE_FIELD_GOAL:
				tally.made_field_goal += 1
			RestartCause.Value.MADE_FREE_THROW:
				tally.made_free_throw += 1
			_:
				pass
		if record.end_reason == PossessionEndReason.Value.TURNOVER:
			tally.turnovers += 1
		elif record.end_reason == PossessionEndReason.Value.PERIOD_EXPIRED:
			tally.period_expired += 1

	_measure_events(tally, output)


## Restart and stage accounting, read from the committed ledger. The reference
## clock for "did this throw-in cost anything" is the possession's own
## `POSSESSION_STARTED`, so the answer comes from the events rather than from a
## reconstruction of what the engine should have done.
func _measure_events(tally: Tally, output: MatchSimulationOutput) -> void:
	var possession_clock: int = -1
	var stage_clock: int = -1
	for event: MatchDomainEvent in output.events:
		match event.event_type:
			MatchDomainEvent.POSSESSION_STARTED:
				possession_clock = event.clock_ms
				stage_clock = event.clock_ms
			MatchDomainEvent.INBOUND:
				var cause: String = String(event.detail_id)
				var spent: int = maxi(0, possession_clock - event.clock_ms)
				if spent > 0:
					tally.restarts_charged[cause] = tally.restarts_charged.get(cause, 0) + 1
					tally.throw_in_ms_charged += spent
				else:
					tally.restarts_free[cause] = tally.restarts_free.get(cause, 0) + 1
				stage_clock = event.clock_ms
			MatchDomainEvent.ADVANCE:
				tally.advance_ms += maxi(0, stage_clock - event.clock_ms)
				stage_clock = event.clock_ms
			MatchDomainEvent.HALF_COURT_ENTERED:
				tally.half_court_ms += maxi(0, stage_clock - event.clock_ms)
				stage_clock = event.clock_ms
			MatchDomainEvent.ACTION_SELECTED:
				tally.action_ms += maxi(0, stage_clock - event.clock_ms)
				stage_clock = event.clock_ms
			MatchDomainEvent.FREE_THROW_AWARDED:
				tally.free_throw_trips += 1
				tally.free_throw_attempts += event.amount
			_:
				if event.clock_ms < stage_clock:
					stage_clock = event.clock_ms


func _report(id: StringName, rules: CompetitionRuleProfile, tally: Tally) -> void:
	var games: float = float(maxi(1, tally.games))
	var possessions: float = float(maxi(1, tally.possessions))
	var per_team: float = float(tally.possessions) / games / 2.0
	var game_ms: float = float(tally.regulation_ms + tally.overtime_ms) / games

	print("")
	print("--- %s (%d games) ---" % [id, tally.games])
	print("  nominal pace input")
	print("    pace_multiplier                    %.4f" % rules.pace_multiplier)
	print("    period structure                   %d x %ds + OT %ds"
		% [rules.regulation_periods, rules.period_seconds, rules.overtime_seconds])
	print("    made-basket clock stop             %dms%s" % [
		rules.made_basket_clock_stop_ms,
		", late periods only" if rules.made_basket_clock_stop_late_periods_only else ""])
	print("  possession count")
	print("    possessions per team per game      %.4f" % per_team)
	print("    possessions per game (both teams)  %.4f" % (float(tally.possessions) / games))
	print("    game milliseconds per game         %.1f" % game_ms)
	print("    mean possession duration (ms)      %.1f"
		% (float(tally.possession_ms) / possessions))
	print("    implied duration from game clock   %.1f"
		% (game_ms / (float(tally.possessions) / games)))
	print("  possession duration decomposition (mean ms per possession)")
	print("    throw-in charged                   %.2f"
		% (float(tally.throw_in_ms_charged) / possessions))
	print("    advance                            %.2f" % (float(tally.advance_ms) / possessions))
	print("    half-court entry                   %.2f"
		% (float(tally.half_court_ms) / possessions))
	print("    actions                            %.2f" % (float(tally.action_ms) / possessions))
	print("    residual (rebounds, dead ball, FT) %.2f" % (
		float(tally.possession_ms - tally.throw_in_ms_charged - tally.advance_ms
			- tally.half_court_ms - tally.action_ms) / possessions))
	print("  restart mix (per game)")
	_print_restarts(tally, games)
	print("  possession-creating processes (per game)")
	print("    turnovers                          %.3f" % (float(tally.turnovers) / games))
	print("    offensive rebounds                 %.3f"
		% (float(tally.offensive_rebounds) / games))
	print("    free-throw trips                   %.3f"
		% (float(tally.free_throw_trips) / games))
	print("    free-throw attempts                %.3f"
		% (float(tally.free_throw_attempts) / games))
	print("    live transfers                     %.3f" % (float(tally.live_transfers) / games))
	print("    possessions ending on the horn     %.3f" % (float(tally.period_expired) / games))
	print("  overtime contribution")
	print("    games reaching overtime            %d (%.4f)"
		% [tally.overtime_games, float(tally.overtime_games) / games])
	print("    overtime possessions               %.3f per game (%.2f%% of all)" % [
		float(tally.overtime_possessions) / games,
		100.0 * float(tally.overtime_possessions) / possessions])
	print("    regulation-only possessions/team   %.4f" % (
		float(tally.regulation_possessions) / games / 2.0))


func _print_restarts(tally: Tally, games: float) -> void:
	var causes: Array[String] = []
	for key: String in tally.restarts_free.keys():
		if not causes.has(key):
			causes.append(key)
	for key: String in tally.restarts_charged.keys():
		if not causes.has(key):
			causes.append(key)
	causes.sort()
	var total_free: int = 0
	var total_charged: int = 0
	for cause: String in causes:
		var free_count: int = tally.restarts_free.get(cause, 0)
		var charged: int = tally.restarts_charged.get(cause, 0)
		total_free += free_count
		total_charged += charged
		print("    %-22s free %7.3f   charged %7.3f"
			% [cause, float(free_count) / games, float(charged) / games])
	print("    %-22s free %7.3f   charged %7.3f"
		% ["ALL", float(total_free) / games, float(total_charged) / games])
	print("    throw-in ms charged per game       %.1f"
		% (float(tally.throw_in_ms_charged) / games))
