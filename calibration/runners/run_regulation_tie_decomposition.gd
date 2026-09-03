extends SceneTree

## Causal decomposition of the regulation-tie shortfall established in
## `PROJECT_STATUS.md` §5.28. This runner does not tune or resolve anything.
## It separates games that never reach a tieable state from games that do but
## fail to convert the opportunity, and stratifies both by competition and
## pregame roster-strength gap.
##
## Run:
##   godot --headless --path . --script \
##     res://calibration/runners/run_regulation_tie_decomposition.gd -- \
##     [--games=N] [--competition=college|top_domestic_pro|all] \
##     [--shard=I --shards=N]

const DEFAULT_GAMES: int = 500
const BASE_SEED: int = 990000
const CHECKPOINTS_MS: PackedInt32Array = [120000, 60000, 30000]
const FINAL_WINDOW_MS: int = 30000


class PossessionWindow:
	extends RefCounted

	var offense_id: StringName = &""
	var start_margin: int = 0
	var start_clock_ms: int = 0
	var field_goal_attempted: bool = false
	var free_throw_attempted: bool = false


class Tally:
	extends RefCounted

	var games: int = 0
	var overtime: int = 0
	var checkpoint_buckets: Dictionary = {}
	var checkpoint_to_final: Dictionary = {}
	var final_opportunities: int = 0
	var final_opportunities_tied: int = 0
	var final_opportunities_trailing: int = 0
	var tying_field_goal_attempts: int = 0
	var tying_field_goal_makes: int = 0
	var tying_free_throw_attempts: int = 0
	var tying_free_throw_makes: int = 0
	var tie_attempt_clock_buckets: Dictionary = {}
	var opportunity_no_attempt: int = 0
	var opportunity_expired_no_attempt: int = 0
	var tied_no_attempt: int = 0
	var trailing_no_attempt: int = 0
	var tied_expired_no_attempt: int = 0
	var trailing_expired_no_attempt: int = 0
	var no_attempt_start_clock_buckets: Dictionary = {}
	var no_attempt_end_reasons: Dictionary = {}
	var strength_buckets: Dictionary = {}
	var mechanism_tags: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = CalibrationCli.int_option(options, &"shards", 1)
	assert(games > 0, "games must be positive")
	assert(shards > 0 and shard >= 0 and shard < shards, "invalid shard")
	var base: int = BASE_SEED + shard * games

	print("=== Regulation tie decomposition ===")
	print("  games=%d shard=%d/%d seeds=%d..%d" % [
		games, shard + 1, shards, base + 1, base + games])
	print("  DIAGNOSTIC ONLY. Changes no target and certifies nothing.")
	for competition in _competitions(selection):
		var tally := Tally.new()
		for index in range(games):
			var variation: int = base + index
			var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
			var output: MatchSimulationOutput = MatchSession.new(
				input, SeededRandomSource.new(variation + 1)).run_to_completion()
			_measure_game(tally, input, output)
			if games > 250 and (index + 1) % 250 == 0:
				print("  %s: %d/%d" % [
					CalibrationTargets.competition_id(competition), index + 1, games])
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


func _measure_game(
	tally: Tally,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	tally.games += 1
	var reached_overtime: bool = output.final_result.overtime_periods > 0
	if reached_overtime:
		tally.overtime += 1
	var final_margin: int = (
		0 if reached_overtime
		else absi(output.final_result.home_score - output.final_result.away_score))
	var strength_bucket: StringName = _strength_gap_bucket(input)
	_increment_nested(tally.strength_buckets, strength_bucket, &"games")
	if reached_overtime:
		_increment_nested(tally.strength_buckets, strength_bucket, &"overtime")

	var state := MatchSnapshot.new(input)
	var reducer := MatchStateReducer.new(input)
	var checkpoints_seen: Dictionary = {}
	var windows: Dictionary = {}
	for event in output.events:
		if state.period == input.rule_profile.regulation_periods:
			_capture_checkpoints(
				tally, checkpoints_seen, state, event.clock_ms, input.home.team_id, final_margin)
			if event.event_type == MatchDomainEvent.POSSESSION_STARTED \
					and state.clock_ms <= FINAL_WINDOW_MS:
				var window := PossessionWindow.new()
				window.offense_id = event.team_id
				window.start_margin = state.margin_for(event.team_id)
				window.start_clock_ms = state.clock_ms
				windows[event.possession_id] = window
				if window.start_margin <= 0 and window.start_margin >= -3:
					tally.final_opportunities += 1
					if window.start_margin == 0:
						tally.final_opportunities_tied += 1
					else:
						tally.final_opportunities_trailing += 1
			_measure_event(tally, state, event, windows)
		reducer.apply_event(state, event)


func _capture_checkpoints(
	tally: Tally,
	seen: Dictionary,
	state: MatchSnapshot,
	next_clock_ms: int,
	home_id: StringName,
	final_margin: int,
) -> void:
	for checkpoint in CHECKPOINTS_MS:
		if seen.has(checkpoint):
			continue
		if state.clock_ms > checkpoint and next_clock_ms <= checkpoint:
			seen[checkpoint] = true
			var start_bucket: StringName = _margin_bucket(absi(state.margin_for(home_id)))
			_increment_nested(tally.checkpoint_buckets, StringName(str(checkpoint)), start_bucket)
			var transition: StringName = StringName(
				"%s->%s" % [start_bucket, _margin_bucket(final_margin)])
			_increment_nested(
				tally.checkpoint_to_final, StringName(str(checkpoint)), transition)


func _measure_event(
	tally: Tally,
	state: MatchSnapshot,
	event: MatchDomainEvent,
	windows: Dictionary,
) -> void:
	if event.event_type == MatchDomainEvent.ACTION_SELECTED and not event.detail_id.is_empty():
		_increment(tally.mechanism_tags, event.detail_id)
	elif event.event_type == MatchDomainEvent.TIMEOUT:
		_increment(tally.mechanism_tags, StringName("timeout_%s" % event.detail_id))
	elif event.event_type == MatchDomainEvent.FOUL \
			and event.detail_id == FoulType.id_of(FoulType.Value.LEADING_PROTECT):
		_increment(tally.mechanism_tags, &"leading_protect")
	elif event.event_type == MatchDomainEvent.FREE_THROW_MISSED \
			and event.detail_id == &"intentional":
		_increment(tally.mechanism_tags, &"intentional_miss")

	var window: PossessionWindow = windows.get(event.possession_id, null)
	if window == null:
		return
	if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT:
		window.field_goal_attempted = true
		var value: int = 3 if ShotZone.is_three(ShotZone.from_id(event.zone_id)) else 2
		if state.margin_for(event.team_id) == -value:
			tally.tying_field_goal_attempts += 1
			_increment(tally.tie_attempt_clock_buckets, _clock_bucket(state.clock_ms))
	elif event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
		if state.margin_for(event.team_id) == -event.points:
			tally.tying_field_goal_makes += 1
	elif event.event_type in [
		MatchDomainEvent.FREE_THROW_MADE,
		MatchDomainEvent.FREE_THROW_MISSED,
	]:
		window.free_throw_attempted = true
		if state.margin_for(event.team_id) == -1:
			tally.tying_free_throw_attempts += 1
			if event.event_type == MatchDomainEvent.FREE_THROW_MADE:
				tally.tying_free_throw_makes += 1
	elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
		if window.start_margin <= 0 and window.start_margin >= -3 \
				and not window.field_goal_attempted and not window.free_throw_attempted:
			tally.opportunity_no_attempt += 1
			_increment(tally.no_attempt_start_clock_buckets, _clock_bucket(window.start_clock_ms))
			_increment(
				tally.no_attempt_end_reasons,
				event.detail_id if not event.detail_id.is_empty() else &"unlabelled")
			if window.start_margin == 0:
				tally.tied_no_attempt += 1
			else:
				tally.trailing_no_attempt += 1
			if event.clock_ms == 0:
				tally.opportunity_expired_no_attempt += 1
				if window.start_margin == 0:
					tally.tied_expired_no_attempt += 1
				else:
					tally.trailing_expired_no_attempt += 1


func _strength_gap_bucket(input: MatchInput) -> StringName:
	var home: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.home, input.ratings_profile, input.balance_profile)
	var away: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.away, input.ratings_profile, input.balance_profile)
	var gap: float = absf(TeamStrengthIndex.expected_gap(home, away))
	if gap < 1.5:
		return &"0-1"
	if gap < 3.5:
		return &"2-3"
	return &"4+"


func _margin_bucket(margin: int) -> StringName:
	if margin == 0:
		return &"0"
	if margin <= 3:
		return &"1-3"
	if margin <= 5:
		return &"4-5"
	if margin <= 9:
		return &"6-9"
	if margin <= 19:
		return &"10-19"
	return &"20+"


func _clock_bucket(clock_ms: int) -> StringName:
	if clock_ms <= 5000:
		return &"0-5s"
	if clock_ms <= 15000:
		return &"5-15s"
	return &"15-30s"


func _increment(target: Dictionary, key: StringName) -> void:
	var current: int = target[key] if target.has(key) else 0
	target[key] = current + 1


func _increment_nested(target: Dictionary, outer: StringName, inner: StringName) -> void:
	var values: Dictionary = target.get(outer, {})
	var current: int = values[inner] if values.has(inner) else 0
	values[inner] = current + 1
	target[outer] = values


func _report(competition_id: StringName, tally: Tally) -> void:
	print("\n--- %s (%d games) ---" % [competition_id, tally.games])
	print("  regulation ties: %d (%.4f)" % [
		tally.overtime, _rate(tally.overtime, tally.games)])
	for checkpoint in CHECKPOINTS_MS:
		var key: StringName = StringName(str(checkpoint))
		var checkpoint_values: Dictionary = tally.checkpoint_buckets.get(key, {})
		var transition_values: Dictionary = tally.checkpoint_to_final.get(key, {})
		print("  checkpoint %ds margin buckets: %s" % [
			checkpoint / 1000, _ordered_dictionary(checkpoint_values)])
		print("  checkpoint %ds -> final transitions: %s" % [
			checkpoint / 1000, _ordered_dictionary(transition_values)])
	print("  final-30s opportunities: %d (tied=%d trailing=%d)" % [
		tally.final_opportunities, tally.final_opportunities_tied,
		tally.final_opportunities_trailing])
	print("  tying field goals: %d/%d (%.4f); clock=%s" % [
		tally.tying_field_goal_makes, tally.tying_field_goal_attempts,
		_rate(tally.tying_field_goal_makes, tally.tying_field_goal_attempts),
		_ordered_dictionary(tally.tie_attempt_clock_buckets)])
	print("  tying free throws: %d/%d (%.4f)" % [
		tally.tying_free_throw_makes, tally.tying_free_throw_attempts,
		_rate(tally.tying_free_throw_makes, tally.tying_free_throw_attempts)])
	print("  tieable possessions without attempt: %d (tied=%d trailing=%d)" % [
		tally.opportunity_no_attempt, tally.tied_no_attempt, tally.trailing_no_attempt])
	print("    expired without attempt: %d (tied=%d trailing=%d)" % [
		tally.opportunity_expired_no_attempt, tally.tied_expired_no_attempt,
		tally.trailing_expired_no_attempt])
	print("    no-attempt start clocks: %s" % _ordered_dictionary(
		tally.no_attempt_start_clock_buckets))
	print("    no-attempt end reasons: %s" % _ordered_dictionary(
		tally.no_attempt_end_reasons))
	print("  by pregame capability-strength gap: %s" % _ordered_dictionary(tally.strength_buckets))
	print("  endgame mechanism tags: %s" % _ordered_dictionary(tally.mechanism_tags))


func _rate(numerator: int, denominator: int) -> float:
	return 0.0 if denominator == 0 else float(numerator) / float(denominator)


func _ordered_dictionary(values: Dictionary) -> String:
	var keys: Array = values.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
	var parts := PackedStringArray()
	for key: Variant in keys:
		parts.append("%s=%s" % [key, values[key]])
	return "{" + ", ".join(parts) + "}"
