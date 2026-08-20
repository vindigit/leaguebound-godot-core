extends SceneTree

## Does a stakes tier change how the game is coached? (`BALANCE_SPEC.md` §14.2,
## Stage 4, bounded diagnostic.)
##
## This is **not** a calibration campaign and its output is **not** a §27.1
## certification. It runs one competition at three stakes tiers over the
## *identical* fixtures and the *identical* seeds, and reports the difference.
## Matched pairing is the whole design: the three tiers are not three samples of
## a population, they are one sample of games played three ways, so a difference
## between two columns is the stakes tier and cannot be sampling noise in the
## rosters.
##
## The product hypothesis under test is directional and deliberately weak:
##
## ```text
## overtime(CHAMPIONSHIP_OR_ELIMINATION) > overtime(POSTSEASON) > overtime(REGULAR)
## ```
##
## Nothing in the engine implements it. There is no overtime modifier, no tie
## bias, and no closeness governor; the only mechanisms a tier touches are four
## coaching thresholds. If the ordering appears it is a consequence of coaching,
## and if it does not appear the honest report is that it does not — which is why
## every row below is `raw` and none of them is `banded`. **This runner cannot
## fail on the hypothesis, by construction.**
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_stakes_diagnostics.gd -- \
##       [--games=N] [--competition=college|top_domestic_pro] [--range=development|validation]
##       [--label=NAME]

const DEFAULT_GAMES: int = 300

## The two seed ranges this section owns. Neither appears in §5.7 through §5.12.
##
## Development is where the implementation was looked at; validation is untouched
## until the implementation is frozen and is never tuned against. They are
## disjoint by construction: 470,000 plus 300 games can never reach 480,000.
const DEVELOPMENT_BASE: int = 470000
const VALIDATION_BASE: int = 480000

## Margin bands, matching every other Stage 4 report so the columns are
## comparable with §14.1 and §14.2 without restating a boundary.
const CLOSE_MARGIN: float = 5.0
const BLOWOUT_MARGIN: float = 20.0

## The window a tie-seeking decision is *observed* over, in milliseconds of
## regulation remaining.
##
## Fixed at the widest window any tier opens, rather than at each tier's own
## window, so the denominator is the same set of game situations in all three
## columns. Measuring each tier inside its own window would compare a rate over
## sixty-four seconds with a rate over thirty-two and call the difference
## behaviour.
const TIE_SEEKING_OBSERVATION_MS: int = 64000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "college")
	var range_name: String = CalibrationCli.string_option(options, &"range", "development")
	var label: String = CalibrationCli.string_option(options, &"label", "stakes")
	var competition: int = _competition(selection)
	var base: int = VALIDATION_BASE if range_name == "validation" else DEVELOPMENT_BASE

	var context := ReportContext.create(
		&"stakes_diagnostics",
		"Matched game-stakes diagnostic",
		CompetitionCatalog.rules_for(competition),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per tier"
	context.sample_count = games
	context.competition_id = CalibrationTargets.competition_id(competition)
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"BELOW CERTIFICATION REQUIREMENT. %d games per tier against the §27.1 "
		% games + "requirement; this is directional evidence and judges no band.")
	context.notes.append(
		"Matched design: the three tiers play the identical fixtures at the identical "
		+ "seeds. A column difference is the stakes tier by construction.")
	context.notes.append(
		"Seed range: %s, variations %d-%d, RNG seeds %d-%d."
		% [range_name, base, base + games - 1, base + 1, base + games])
	context.notes.append(
		"The overtime ordering is a product hypothesis under measurement, not a "
		+ "target. No metric here is judged against it and no tunable was fitted to it.")

	var report := CalibrationReport.new(context)
	var samples: Array[TierSample] = []
	var rows: Array[Dictionary] = []
	for stakes in GameStakes.all():
		var sample: TierSample = _simulate(competition, games, base, stakes)
		samples.append(sample)
		rows.append(sample.to_dictionary())
		_report_tier(report, sample)
	_report_ordering(report, samples)
	report.add_section(&"matched_tiers", rows)
	report.finish()
	quit(ReportWriter.publish(report, "stakes_diagnostics_%s" % label))


func _competition(selection: String) -> int:
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return competition
	printerr("unknown competition '%s'; using college" % selection)
	return CalibrationTargets.Competition.COLLEGE


# --- sampling ------------------------------------------------------------------

## One tier's matched sample. A typed class rather than a Dictionary because the
## project compiles under warnings-as-errors and a `Variant` arithmetic chain is
## exactly the kind of thing that stops being checked.
class TierSample:
	extends RefCounted

	var stakes: int = GameStakes.DEFAULT
	var games: int = 0
	var margins := PackedFloat64Array()
	var overtimes: int = 0
	var points: float = 0.0
	var possessions: float = 0.0
	var timeouts: int = 0
	var intentional_fouls: int = 0
	var garbage_entries: int = 0
	var garbage_releases: int = 0
	var garbage_games: int = 0
	var comebacks: int = 0
	var starter_ms: float = 0.0
	var all_ms: float = 0.0
	var top_player_ms: float = 0.0
	var tie_seeking_attempts: int = 0
	var tie_seeking_levelling: int = 0

	func denominator() -> float:
		return float(maxi(games, 1))

	func value_of(key: StringName) -> float:
		match key:
			&"overtime_rate":
				return float(overtimes) / denominator()
			&"close_game_rate":
				return _share_within(CLOSE_MARGIN)
			&"blowout_rate":
				return _share_at_or_above(BLOWOUT_MARGIN)
			&"margin_standard_deviation":
				return sqrt(maxf(ScoringCovariance.variance(margins), 0.0))
			&"mean_absolute_margin":
				return _mean_absolute()
			&"points_per_possession":
				return points / maxf(possessions, 1.0)
			&"possessions_per_team_game":
				return possessions / (denominator() * 2.0)
			&"timeouts_per_game":
				return float(timeouts) / denominator()
			&"intentional_fouls_per_game":
				return float(intentional_fouls) / denominator()
			&"garbage_activation_rate":
				return float(garbage_games) / denominator()
			&"garbage_entries_per_game":
				return float(garbage_entries) / denominator()
			&"garbage_releases_per_game":
				return float(garbage_releases) / denominator()
			&"comeback_share_after_activation":
				return float(comebacks) / maxf(float(garbage_games), 1.0)
			&"starter_minute_share":
				return starter_ms / maxf(all_ms, 0.0001)
			&"top_player_minutes":
				return top_player_ms / (denominator() * 2.0)
			&"tie_seeking_opportunities_per_game":
				return float(tie_seeking_attempts) / denominator()
			&"tie_seeking_levelling_share":
				return float(tie_seeking_levelling) / maxf(float(tie_seeking_attempts), 1.0)
			_:
				assert(false, "unknown stakes diagnostic metric")
		return 0.0

	func to_dictionary() -> Dictionary:
		var payload: Dictionary = {
			"stakes": String(GameStakes.id_of(stakes)),
			"tier": GameStakes.tier(stakes),
			"games": games,
			"tie_seeking_sample": tie_seeking_attempts,
			"garbage_sample": garbage_games,
		}
		for key in METRIC_KEYS:
			payload[String(key)] = value_of(StringName(key))
		return payload

	func _share_within(threshold: float) -> float:
		if margins.is_empty():
			return 0.0
		var count: int = 0
		for value in margins:
			if absf(value) <= threshold:
				count += 1
		return float(count) / float(margins.size())

	func _share_at_or_above(threshold: float) -> float:
		if margins.is_empty():
			return 0.0
		var count: int = 0
		for value in margins:
			if absf(value) >= threshold:
				count += 1
		return float(count) / float(margins.size())

	func _mean_absolute() -> float:
		if margins.is_empty():
			return 0.0
		var total: float = 0.0
		for value in margins:
			total += absf(value)
		return total / float(margins.size())


func _simulate(competition: int, games: int, base: int, stakes: int) -> TierSample:
	var sample := TierSample.new()
	sample.stakes = stakes
	sample.games = games
	for index in range(games):
		var variation: int = base + index
		var input: MatchInput = CompetitionCatalog.match_for(
			competition, variation, 0.5).with_stakes(stakes)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		_accumulate(sample, input, output)
	return sample


func _accumulate(
	sample: TierSample,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	var result: MatchFinalResult = output.final_result
	sample.margins.append(float(result.home_score - result.away_score))
	if result.overtime_periods > 0:
		sample.overtimes += 1
	sample.points += float(result.home_score + result.away_score)
	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		sample.possessions += float(
			result.statistics.team_line(team_id).engine_possessions)

	var starters: Dictionary = {}
	for team: TeamMatchProfile in [input.home, input.away]:
		for starter_id in team.starters():
			starters[starter_id] = true
	for team: TeamMatchProfile in [input.home, input.away]:
		var best: float = 0.0
		for line: PlayerStatLine in result.statistics.players_for(team.team_id):
			var minutes: float = line.minutes_played()
			sample.all_ms += minutes
			if starters.has(line.player_id):
				sample.starter_ms += minutes
			best = maxf(best, minutes)
		sample.top_player_ms += best

	_walk_ledger(sample, input, output)


## One pass over the ledger, reconstructing the running score so the situational
## counters have a scoreboard to read.
##
## The score is rebuilt rather than carried on the event because the event schema
## is the serialization order the golden hashes are taken over, and a diagnostic
## is not a reason to move it.
func _walk_ledger(
	sample: TierSample,
	input: MatchInput,
	output: MatchSimulationOutput,
) -> void:
	var rules: CompetitionRuleProfile = input.rule_profile
	var home_id: StringName = input.home.team_id
	var home_score: int = 0
	var away_score: int = 0
	var entered: bool = false
	var activation_home_leading: bool = false
	for event: MatchDomainEvent in output.events:
		match event.event_type:
			MatchDomainEvent.TIMEOUT:
				sample.timeouts += 1
			MatchDomainEvent.FOUL:
				if event.detail_id == FoulType.id_of(FoulType.Value.INTENTIONAL):
					sample.intentional_fouls += 1
			MatchDomainEvent.GARBAGE_TIME:
				if event.detail_id == &"entered":
					sample.garbage_entries += 1
					if not entered:
						entered = true
						activation_home_leading = home_score > away_score
				else:
					sample.garbage_releases += 1
			MatchDomainEvent.FIELD_GOAL_ATTEMPT:
				_count_tie_seeking(sample, event, rules, home_id, home_score, away_score)
		if event.points > 0:
			if event.team_id == home_id:
				home_score += event.points
			else:
				away_score += event.points
	if not entered:
		return
	sample.garbage_games += 1
	var final_home_leads: bool = (
		output.final_result.home_score > output.final_result.away_score)
	if output.final_result.home_score != output.final_result.away_score \
			and final_home_leads != activation_home_leading:
		sample.comebacks += 1


## A tie-seeking *opportunity* is a field-goal attempt taken inside the observed
## end-of-regulation window by a team trailing by two or three. The decision is
## whether the attempt was the shot that levels the game.
##
## Attempts, not makes. The rule this measures selects a shot; whether it falls
## is a different question and one a stakes tier is forbidden to touch.
func _count_tie_seeking(
	sample: TierSample,
	event: MatchDomainEvent,
	rules: CompetitionRuleProfile,
	home_id: StringName,
	home_score: int,
	away_score: int,
) -> void:
	if event.period != rules.regulation_periods:
		return
	if GarbageTimeRule.remaining_regulation_ms(
		event.period, event.clock_ms, rules
	) > TIE_SEEKING_OBSERVATION_MS:
		return
	var margin: int = (
		home_score - away_score if event.team_id == home_id else away_score - home_score)
	var deficit: int = -margin
	if deficit < GameManagement.TIE_SEEKING_MINIMUM_DEFICIT \
			or deficit > GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT:
		return
	sample.tie_seeking_attempts += 1
	var three: bool = ShotZone.is_three(ShotZone.from_id(event.zone_id))
	if three == (deficit == GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT):
		sample.tie_seeking_levelling += 1


# --- reporting -----------------------------------------------------------------

const METRIC_KEYS: PackedStringArray = [
	"overtime_rate",
	"close_game_rate",
	"blowout_rate",
	"margin_standard_deviation",
	"mean_absolute_margin",
	"points_per_possession",
	"possessions_per_team_game",
	"timeouts_per_game",
	"intentional_fouls_per_game",
	"garbage_activation_rate",
	"garbage_entries_per_game",
	"garbage_releases_per_game",
	"comeback_share_after_activation",
	"starter_minute_share",
	"top_player_minutes",
	"tie_seeking_opportunities_per_game",
	"tie_seeking_levelling_share",
]

const METRIC_DEFINITIONS: PackedStringArray = [
	"Games decided in overtime",
	"Games finishing inside five points",
	"Games finishing at or beyond twenty points",
	"Standard deviation of the final margin",
	"Mean absolute final margin",
	"Points per engine possession, both teams",
	"Engine possessions per team-game",
	"Coaching timeouts recorded in the ledger",
	"Deliberate late-game fouls recorded in the ledger",
	"Games in which either coach entered the settled rotation",
	"Entries into the settled rotation, both teams",
	"Returns to the competitive rotation, both teams",
	"Activated games won by the side behind when the state began",
	"Share of on-court player-time taken by starters",
	"Minutes played by each team's most-used player",
	"Trailing-by-two-or-three attempts in the last 64s of regulation",
	"Share of those attempts that were the levelling shot",
]


func _report_tier(report: CalibrationReport, sample: TierSample) -> void:
	var stakes: String = String(GameStakes.id_of(sample.stakes))
	for index in range(METRIC_KEYS.size()):
		var key: String = METRIC_KEYS[index]
		var count: int = sample.games
		if key == "tie_seeking_levelling_share":
			count = sample.tie_seeking_attempts
		elif key == "comeback_share_after_activation":
			count = sample.garbage_games
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s" % [stakes, key]),
			METRIC_DEFINITIONS[index],
			"games",
			sample.value_of(StringName(key)),
			count))


## The hypothesis, stated as three numbers and a verdict that judges nothing.
##
## Reported as informational metrics rather than bands so a run cannot pass or
## fail on it. `1.0` means the ordering appeared in this sample; `0.0` means it
## did not, and that is a result rather than a defect.
func _report_ordering(report: CalibrationReport, samples: Array[TierSample]) -> void:
	var regular: float = samples[GameStakes.Value.REGULAR].value_of(&"overtime_rate")
	var postseason: float = samples[GameStakes.Value.POSTSEASON].value_of(&"overtime_rate")
	var championship: float = samples[
		GameStakes.Value.CHAMPIONSHIP_OR_ELIMINATION].value_of(&"overtime_rate")
	var strict: bool = championship > postseason and postseason > regular
	var weak: bool = championship > regular
	var games: int = samples[0].games
	report.add_metric(CalibrationMetric.raw(
		&"hypothesis.overtime_strict_ordering",
		"championship > postseason > regular overtime rate in this matched sample. "
		+ "INFORMATIONAL: a product hypothesis under measurement, never a target.",
		"boolean", 1.0 if strict else 0.0, games))
	report.add_metric(CalibrationMetric.raw(
		&"hypothesis.overtime_weak_ordering",
		"championship > regular overtime rate in this matched sample. INFORMATIONAL.",
		"boolean", 1.0 if weak else 0.0, games))
	report.add_metric(CalibrationMetric.raw(
		&"hypothesis.overtime_spread",
		"championship overtime rate minus regular overtime rate. INFORMATIONAL.",
		"games", championship - regular, games))
