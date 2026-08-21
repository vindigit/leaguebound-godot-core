extends SceneTree

## What is home court actually worth in this engine? (`SIMULATION_SPEC.md` §19.4,
## `BALANCE_SPEC.md` §14.2 and §17.4, Stage 4 diagnostic.)
##
## The §14.2 row asks for a 53-56% home win rate between *even* teams, centred on
## 54.5%, and §17.4 caps what may produce it: no single modifier above four
## absolute probability points, and no more than +2.5 points per 100 possessions
## from the environment in aggregate. Measuring that against a population sample
## cannot work — a population has a strength spread, and a strength spread both
## hides a missing home edge and imitates one that is not there. So the fixture
## here is a **mirror**: both benches are built from the same variation, so every
## rating, body, tactical role, rotation role and game plan is identical and the
## pregame gap is exactly zero. Whatever separates the two columns was produced
## by the venue.
##
## Three arms, played over the identical fixtures at the identical seeds:
##
## ```text
## home      home = A, away = B, environment = E
## neutral   home = A, away = B, environment = 0
## reversed  home = B, away = A, environment = E
## ```
##
## Common random numbers are the whole design. `home` and `neutral` differ in
## exactly one float, so their difference is the environment and cannot be
## sampling noise in the rosters; `reversed` swaps which bench the venue belongs
## to and nothing else, so the effect must appear with its sign flipped. A
## neutral arm that does not centre on 50% and a reversal that does not mirror
## are both defects, and both are reported here rather than inferred.
##
## Initial possession alternates on variation parity and is held identical
## across the three arms. `CompetitionCatalog` hands the opening inbound to the
## home team, which is worth a measurable margin on its own; leaving that in
## would put a first-possession edge inside the neutral control and make "is the
## venue worth anything" unreadable. Alternating balances it over the sample
## while keeping every matched triple exact.
##
## This is a diagnostic and judges §14.2 on the mirror fixture only where the
## row is about even teams. It is **not** a §27.1 certification at any sample
## this runner is given.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_home_court_diagnostics.gd -- \
##       [--games=N] [--competition=high_school|college|development|overseas|top_domestic_pro|all] \
##       [--range=diagnosis|tuning|tuning_second|validation_a|validation_b] \
##       [--environment=0.5] \
##       [--mode=mirror|population] [--label=NAME]

const DEFAULT_GAMES: int = 200

## The seed ranges this section owns, disjoint from every range §5.7-§5.16 used
## and from each other.
##
## Diagnosis is where the implementation was looked at. Tuning is where the
## correction was fitted — twice, and the second range says so: 730,000 was
## opened as a validation range and then a channel value was changed after
## reading it, which makes it a tuning range whatever it was called. Renaming it
## honestly is cheaper than pretending a fitted range validated anything.
##
## The two validation ranges below were opened only after the channel values
## were frozen, and nothing was changed after reading them.
const DIAGNOSIS_BASE: int = 710000
const TUNING_BASE: int = 720000
const TUNING_SECOND_BASE: int = 730000
const VALIDATION_A_BASE: int = 780000
const VALIDATION_B_BASE: int = 790000

const MODE_MIRROR: String = "mirror"
const MODE_POPULATION: String = "population"

const ARM_HOME: StringName = &"home"
const ARM_NEUTRAL: StringName = &"neutral"
const ARM_REVERSED: StringName = &"reversed"

## The environment strength a neutral court supplies. Zero is the documented
## "no venue" value: every §19.4 consumer multiplies by it, so zero is the only
## value that provably contributes nothing.
const NEUTRAL_ENVIRONMENT: float = 0.0

const CLOSE_MARGIN: float = 5.0
const BLOWOUT_MARGIN: float = 20.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var range_name: String = CalibrationCli.string_option(options, &"range", "diagnosis")
	var mode: String = CalibrationCli.string_option(options, &"mode", MODE_MIRROR)
	var environment: float = CalibrationCli.float_option(options, &"environment", 0.5)
	var label: String = CalibrationCli.string_option(options, &"label", "home_court")
	if mode != MODE_MIRROR and mode != MODE_POPULATION:
		printerr("unknown mode '%s'; using %s" % [mode, MODE_MIRROR])
		mode = MODE_MIRROR
	var base: int = _range_base(range_name)
	var competitions: Array[int] = _competitions(selection)

	var context := ReportContext.create(
		&"home_court_diagnostics",
		"Home-court advantage diagnostic",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per arm per competition"
	context.sample_count = games
	context.competition_id = (
		CalibrationTargets.competition_id(competitions[0]) if competitions.size() == 1
		else &"all")
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"BELOW CERTIFICATION REQUIREMENT. %d games per arm against the §27.1 " % games
		+ "requirement; this is directional evidence and certifies nothing.")
	context.notes.append(
		"Matched design: the three arms play the identical fixtures at the identical "
		+ "seeds. A column difference is the venue by construction.")
	context.notes.append(
		"Seed range: %s, variations %d-%d, RNG seeds %d-%d."
		% [range_name, base, base + games - 1, base + 1, base + games])
	context.notes.append(
		"Fixture mode: %s; home environment %.3f; neutral environment %.3f."
		% [mode, environment, NEUTRAL_ENVIRONMENT])
	context.notes.append(
		"Initial possession alternates on variation parity and is identical across "
		+ "the three arms, so the opening inbound is balanced over the sample and "
		+ "constant within every matched triple.")
	if mode == MODE_MIRROR:
		context.notes.append(
			"Mirror matches are played between two identical rosters, so the pregame "
			+ "strength gap is exactly zero. §14.2's even-team home win rate is the one "
			+ "game-shape row this fixture is the correct measurement for.")

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	for competition in competitions:
		var arms: Dictionary = _simulate(competition, games, base, mode, environment)
		var home_arm: ArmSample = arms[ARM_HOME]
		var neutral_arm: ArmSample = arms[ARM_NEUTRAL]
		var reversed_arm: ArmSample = arms[ARM_REVERSED]
		for arm_id: StringName in [ARM_HOME, ARM_NEUTRAL, ARM_REVERSED]:
			rows.append((arms[arm_id] as ArmSample).to_dictionary())
		_report_competition(report, competition, home_arm, neutral_arm, reversed_arm, mode)
	report.add_section(&"matched_arms", rows)
	report.finish()
	quit(ReportWriter.publish(report, "home_court_diagnostics_%s" % label))


func _range_base(range_name: String) -> int:
	match range_name:
		"tuning":
			return TUNING_BASE
		"tuning_second":
			return TUNING_SECOND_BASE
		"validation_a":
			return VALIDATION_A_BASE
		"validation_b":
			return VALIDATION_B_BASE
		"diagnosis":
			return DIAGNOSIS_BASE
		_:
			printerr("unknown range '%s'; using diagnosis" % range_name)
			return DIAGNOSIS_BASE


func _competitions(selection: String) -> Array[int]:
	if selection == "all":
		return CalibrationTargets.all_competitions()
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == selection:
			return [competition] as Array[int]
	printerr("unknown competition '%s'; running all" % selection)
	return CalibrationTargets.all_competitions()


# --- sampling ---------------------------------------------------------------

## One side of one arm: the §14.1 numerators and denominators for every game
## played at that end of the venue relationship.
##
## Typed rather than a Dictionary because the project compiles under
## warnings-as-errors, and a Variant arithmetic chain is exactly the thing that
## stops being checked.
class SideTotals:
	extends RefCounted

	var team_games: int = 0
	var points: int = 0
	var possessions: int = 0
	var field_goals_made: int = 0
	var field_goals_attempted: int = 0
	var three_pointers_made: int = 0
	var three_pointers_attempted: int = 0
	var free_throws_made: int = 0
	var free_throws_attempted: int = 0
	var offensive_rebounds: int = 0
	var defensive_rebounds: int = 0
	var offensive_rebound_chances: int = 0
	var assists: int = 0
	var assisted_field_goals_made: int = 0
	var steals: int = 0
	var blocks: int = 0
	var turnovers: int = 0
	var personal_fouls: int = 0
	var timeouts: int = 0
	var substitutions: int = 0
	var actions_by_family := PackedInt32Array()
	var attempts_by_zone := PackedInt32Array()

	func _init() -> void:
		actions_by_family.resize(ActionFamily.COUNT)
		actions_by_family.fill(0)
		attempts_by_zone.resize(ShotZone.COUNT)
		attempts_by_zone.fill(0)

	func add_line(line: TeamStatLine, opponent: TeamStatLine) -> void:
		team_games += 1
		points += line.points
		possessions += line.engine_possessions
		field_goals_made += line.field_goals_made
		field_goals_attempted += line.field_goals_attempted
		three_pointers_made += line.three_pointers_made
		three_pointers_attempted += line.three_pointers_attempted
		free_throws_made += line.free_throws_made
		free_throws_attempted += line.free_throws_attempted
		offensive_rebounds += line.offensive_rebounds
		defensive_rebounds += line.defensive_rebounds
		offensive_rebound_chances += line.offensive_rebounds + opponent.defensive_rebounds
		assists += line.assists
		assisted_field_goals_made += line.assisted_field_goals_made
		steals += line.steals
		blocks += line.blocks
		turnovers += line.turnovers
		personal_fouls += line.personal_fouls

	func points_per_possession() -> float:
		return _ratio(float(points), float(possessions))

	func possessions_per_game() -> float:
		return _ratio(float(possessions), float(team_games))

	func field_goal_percentage() -> float:
		return _ratio(float(field_goals_made), float(field_goals_attempted))

	func two_point_percentage() -> float:
		return _ratio(
			float(field_goals_made - three_pointers_made),
			float(field_goals_attempted - three_pointers_attempted))

	func three_point_percentage() -> float:
		return _ratio(float(three_pointers_made), float(three_pointers_attempted))

	func three_point_attempt_rate() -> float:
		return _ratio(float(three_pointers_attempted), float(field_goals_attempted))

	func free_throw_percentage() -> float:
		return _ratio(float(free_throws_made), float(free_throws_attempted))

	func free_throw_attempt_rate() -> float:
		return _ratio(float(free_throws_attempted), float(field_goals_attempted))

	func turnovers_per_100() -> float:
		return 100.0 * _ratio(float(turnovers), float(possessions))

	func offensive_rebound_percentage() -> float:
		return _ratio(float(offensive_rebounds), float(offensive_rebound_chances))

	func assist_percentage() -> float:
		return _ratio(float(assists), float(field_goals_made))

	func conditional_assist_rate() -> float:
		return _ratio(float(assists), float(assisted_field_goals_made))

	func fouls_per_game() -> float:
		return _ratio(float(personal_fouls), float(team_games))

	func steals_per_game() -> float:
		return _ratio(float(steals), float(team_games))

	func blocks_per_game() -> float:
		return _ratio(float(blocks), float(team_games))

	func timeouts_per_game() -> float:
		return _ratio(float(timeouts), float(team_games))

	func substitutions_per_game() -> float:
		return _ratio(float(substitutions), float(team_games))

	func action_share(family: int) -> float:
		var total: int = 0
		for count in actions_by_family:
			total += count
		return _ratio(float(actions_by_family[family]), float(total))

	func zone_share(zone: int) -> float:
		var total: int = 0
		for count in attempts_by_zone:
			total += count
		return _ratio(float(attempts_by_zone[zone]), float(total))

	func _ratio(numerator: float, denominator: float) -> float:
		return 0.0 if denominator <= 0.0 else numerator / denominator


## One arm's matched sample: the venue side, the visiting side, and the game
## shape they produced together.
class ArmSample:
	extends RefCounted

	var arm_id: StringName = &"arm"
	var competition: int = 0
	var games: int = 0
	var decided_games: int = 0
	var venue_wins: int = 0
	var overtimes: int = 0
	var margins := PackedFloat64Array()
	var venue := SideTotals.new()
	var visitor := SideTotals.new()

	func denominator() -> float:
		return float(maxi(games, 1))

	## Home win rate over *decided* games, matching `MatchMetricAccumulator`, so
	## the figure here and the figure in the competition report mean the same
	## thing. A regulation tie enters overtime, so in practice this is every game.
	func venue_win_rate() -> float:
		return 0.0 if decided_games == 0 else float(venue_wins) / float(decided_games)

	func mean_margin() -> float:
		if margins.is_empty():
			return 0.0
		var total: float = 0.0
		for value in margins:
			total += value
		return total / float(margins.size())

	func median_margin() -> float:
		if margins.is_empty():
			return 0.0
		var sorted := PackedFloat64Array(margins)
		sorted.sort()
		var count: int = sorted.size()
		if count % 2 == 1:
			return sorted[count / 2]
		return 0.5 * (sorted[count / 2 - 1] + sorted[count / 2])

	func margin_standard_deviation() -> float:
		return sqrt(maxf(ScoringCovariance.variance(margins), 0.0))

	## The half-width of the mean margin's 95% interval. The margins are paired
	## across arms but independent within one, so the ordinary standard error is
	## the right one for a single column.
	func mean_margin_half_width() -> float:
		if margins.size() < 2:
			return 0.0
		return 1.96 * margin_standard_deviation() / sqrt(float(margins.size()))

	func overtime_rate() -> float:
		return float(overtimes) / denominator()

	func close_game_rate() -> float:
		return _share(CLOSE_MARGIN, true)

	func blowout_rate() -> float:
		return _share(BLOWOUT_MARGIN, false)

	## What the venue is worth in points per 100 possessions, as the two sides'
	## scoring efficiency gap. §17.4 caps the *environment's* contribution at
	## +2.5, and that cap is enforced against this figure minus the neutral arm's.
	func points_per_100_gap() -> float:
		return 100.0 * (venue.points_per_possession() - visitor.points_per_possession())

	func to_dictionary() -> Dictionary:
		return {
			"arm": String(arm_id),
			"competition": String(CalibrationTargets.competition_id(competition)),
			"games": games,
			"venue_win_rate": venue_win_rate(),
			"mean_margin": mean_margin(),
			"median_margin": median_margin(),
			"margin_standard_deviation": margin_standard_deviation(),
			"overtime_rate": overtime_rate(),
			"close_game_rate": close_game_rate(),
			"blowout_rate": blowout_rate(),
			"points_per_100_gap": points_per_100_gap(),
			"venue_points_per_possession": venue.points_per_possession(),
			"visitor_points_per_possession": visitor.points_per_possession(),
			"venue_possessions_per_game": venue.possessions_per_game(),
			"visitor_possessions_per_game": visitor.possessions_per_game(),
			"venue_field_goal_percentage": venue.field_goal_percentage(),
			"visitor_field_goal_percentage": visitor.field_goal_percentage(),
			"venue_two_point_percentage": venue.two_point_percentage(),
			"visitor_two_point_percentage": visitor.two_point_percentage(),
			"venue_three_point_percentage": venue.three_point_percentage(),
			"visitor_three_point_percentage": visitor.three_point_percentage(),
			"venue_three_point_attempt_rate": venue.three_point_attempt_rate(),
			"visitor_three_point_attempt_rate": visitor.three_point_attempt_rate(),
			"venue_free_throw_percentage": venue.free_throw_percentage(),
			"visitor_free_throw_percentage": visitor.free_throw_percentage(),
			"venue_free_throw_attempt_rate": venue.free_throw_attempt_rate(),
			"visitor_free_throw_attempt_rate": visitor.free_throw_attempt_rate(),
			"venue_turnovers_per_100": venue.turnovers_per_100(),
			"visitor_turnovers_per_100": visitor.turnovers_per_100(),
			"venue_offensive_rebound_percentage": venue.offensive_rebound_percentage(),
			"visitor_offensive_rebound_percentage": visitor.offensive_rebound_percentage(),
			"venue_assist_percentage": venue.assist_percentage(),
			"visitor_assist_percentage": visitor.assist_percentage(),
			"venue_conditional_assist_rate": venue.conditional_assist_rate(),
			"visitor_conditional_assist_rate": visitor.conditional_assist_rate(),
			"venue_fouls_per_game": venue.fouls_per_game(),
			"visitor_fouls_per_game": visitor.fouls_per_game(),
			"venue_steals_per_game": venue.steals_per_game(),
			"visitor_steals_per_game": visitor.steals_per_game(),
			"venue_blocks_per_game": venue.blocks_per_game(),
			"visitor_blocks_per_game": visitor.blocks_per_game(),
			"venue_timeouts_per_game": venue.timeouts_per_game(),
			"visitor_timeouts_per_game": visitor.timeouts_per_game(),
			"venue_substitutions_per_game": venue.substitutions_per_game(),
			"visitor_substitutions_per_game": visitor.substitutions_per_game(),
			"venue_action_mix": _family_shares(venue),
			"visitor_action_mix": _family_shares(visitor),
			"venue_zone_mix": _zone_shares(venue),
			"visitor_zone_mix": _zone_shares(visitor),
		}

	func _family_shares(side: SideTotals) -> Dictionary:
		var payload: Dictionary = {}
		for family in range(ActionFamily.COUNT):
			payload[String(ActionFamily.id_of(family))] = side.action_share(family)
		return payload

	func _zone_shares(side: SideTotals) -> Dictionary:
		var payload: Dictionary = {}
		for zone in range(ShotZone.COUNT):
			payload[String(ShotZone.id_of(zone))] = side.zone_share(zone)
		return payload

	func _share(threshold: float, within: bool) -> float:
		if margins.is_empty():
			return 0.0
		var count: int = 0
		for value in margins:
			if (absf(value) <= threshold) == within:
				count += 1
		return float(count) / float(margins.size())


## The three arms for one competition, played over one shared set of fixtures.
func _simulate(
	competition: int,
	games: int,
	base: int,
	mode: String,
	environment: float,
) -> Dictionary:
	var arms: Dictionary = {}
	for arm_id: StringName in [ARM_HOME, ARM_NEUTRAL, ARM_REVERSED]:
		var sample := ArmSample.new()
		sample.arm_id = arm_id
		sample.competition = competition
		arms[arm_id] = sample
	for index in range(games):
		var variation: int = base + index
		for arm_id: StringName in [ARM_HOME, ARM_NEUTRAL, ARM_REVERSED]:
			var input: MatchInput = _venue_input(
				competition, variation, mode,
				NEUTRAL_ENVIRONMENT if arm_id == ARM_NEUTRAL else environment,
				arm_id == ARM_REVERSED)
			# The same seed in all three arms. That is what makes the columns a
			# matched triple rather than three samples.
			var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
				input, SeededRandomSource.new(variation + 1))
			_accumulate(arms[arm_id] as ArmSample, input, output)
	return arms


## One match, built so that the only thing an arm changes is the venue.
##
## `reversed` swaps which roster the venue belongs to while leaving the rosters,
## the seed and the opening inbound exactly where they were. Initial possession
## alternates on variation parity rather than always falling to the home bench,
## because the opening inbound is worth a measurable margin and leaving it on
## one side would put it inside the neutral control.
func _venue_input(
	competition: int,
	variation: int,
	mode: String,
	environment: float,
	reversed: bool,
) -> MatchInput:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var first: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", variation * 2, balance, 0.0)
	var second: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away",
		variation * 2 if mode == MODE_MIRROR else variation * 2 + 1, balance, 0.0)
	var venue_side: TeamMatchProfile = second if reversed else first
	var visiting_side: TeamMatchProfile = first if reversed else second
	var opener: StringName = first.team_id if variation % 2 == 0 else second.team_id
	return MatchInput.new(
		StringName("home_court_%s_%d" % [
			CalibrationTargets.competition_id(competition), variation]),
		StringName("home_court_game_%d" % variation),
		CompetitionCatalog.rules_for(competition),
		balance,
		venue_side,
		visiting_side,
		opener,
		CompetitionCatalog.ratings_profile(),
		environment)


func _accumulate(sample: ArmSample, input: MatchInput, output: MatchSimulationOutput) -> void:
	var result: MatchFinalResult = output.final_result
	var statistics: MatchStatistics = result.statistics
	sample.games += 1
	if result.overtime_periods > 0:
		sample.overtimes += 1
	# Signed from the venue's point of view, so a positive mean is a home
	# advantage in every arm including the reversed one.
	var margin: int = result.home_score - result.away_score
	sample.margins.append(float(margin))
	if margin != 0:
		sample.decided_games += 1
		if margin > 0:
			sample.venue_wins += 1

	var venue_line: TeamStatLine = statistics.team_line(input.home.team_id)
	var visitor_line: TeamStatLine = statistics.team_line(input.away.team_id)
	sample.venue.add_line(venue_line, visitor_line)
	sample.visitor.add_line(visitor_line, venue_line)

	# Action family, shot zone, timeout and substitution counts come from the
	# ledger rather than the box score: the box score has no action mix in it,
	# and §24.3 makes the ordered events the authority for everything else here
	# anyway.
	for event in output.events:
		if event.team_id != input.home.team_id and event.team_id != input.away.team_id:
			continue
		var side: SideTotals = (
			sample.venue if event.team_id == input.home.team_id else sample.visitor)
		match event.event_type:
			MatchDomainEvent.ACTION_SELECTED:
				side.actions_by_family[ActionFamily.from_id(event.action_id)] += 1
			MatchDomainEvent.FIELD_GOAL_ATTEMPT:
				side.attempts_by_zone[ShotZone.from_id(event.zone_id)] += 1
			MatchDomainEvent.TIMEOUT:
				side.timeouts += 1
			MatchDomainEvent.CHECK_IN:
				side.substitutions += 1


# --- reporting --------------------------------------------------------------

func _report_competition(
	report: CalibrationReport,
	competition: int,
	home_arm: ArmSample,
	neutral_arm: ArmSample,
	reversed_arm: ArmSample,
	mode: String,
) -> void:
	var id: String = String(CalibrationTargets.competition_id(competition))
	var accumulator := MatchMetricAccumulator.new()

	# §14.2's even-team home win rate. Judged on the mirror fixture, which is the
	# only fixture where "even" is exactly true; on a population fixture the row
	# is reported without a verdict because the teams are not even.
	var win_rate: float = home_arm.venue_win_rate()
	var win_interval: float = accumulator.proportion_half_width(
		home_arm.venue_wins, home_arm.decided_games)
	if mode == MODE_MIRROR:
		report.add_metric(CalibrationMetric.banded(
			StringName("%s.home.win_rate" % id),
			"Share of decided games won by the team playing at its own venue, "
			+ "between two identical rosters at the production home environment.",
			"decided games",
			win_rate,
			CalibrationTargets.home_win_rate(),
			home_arm.decided_games,
			win_interval))
	else:
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.home.win_rate" % id),
			"Share of decided games won by the home team on the population "
			+ "fixture. Reported without a verdict: §14.2's row is about even "
			+ "teams and this fixture has a strength spread.",
			"decided games",
			win_rate,
			home_arm.decided_games).with_interval(win_interval))

	# The neutral control. With the environment at zero and the opening inbound
	# balanced, nothing left in the engine knows which bench is which, so this
	# should sit on 50% and on a zero mean margin. It is the measurement that
	# tells a missing home effect apart from a contaminated fixture.
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.neutral.win_rate" % id),
		"Share of decided games won by the nominal home team with the §19.4 "
		+ "environment at zero. The control: it should centre on 0.50.",
		"decided games",
		neutral_arm.venue_win_rate(),
		neutral_arm.decided_games).with_interval(accumulator.proportion_half_width(
			neutral_arm.venue_wins, neutral_arm.decided_games)))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.neutral.mean_margin" % id),
		"Mean venue-minus-visitor final margin with the environment at zero.",
		"complete games",
		neutral_arm.mean_margin(),
		neutral_arm.games).with_interval(neutral_arm.mean_margin_half_width()))

	report.add_metric(CalibrationMetric.raw(
		StringName("%s.home.mean_margin" % id),
		"Mean venue-minus-visitor final margin at the production environment.",
		"complete games",
		home_arm.mean_margin(),
		home_arm.games).with_interval(home_arm.mean_margin_half_width()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.home.median_margin" % id),
		"Median venue-minus-visitor final margin at the production environment.",
		"complete games",
		home_arm.median_margin(),
		home_arm.games))

	# The venue reversal. Swapping which bench owns the arena must reproduce the
	# same edge for the other roster; a reversal that does not mirror means the
	# effect is attached to a team rather than to a venue.
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.reversed.win_rate" % id),
		"Share of decided games won by the venue side after home and away are "
		+ "swapped. It must reproduce the home arm, not the neutral arm.",
		"decided games",
		reversed_arm.venue_win_rate(),
		reversed_arm.decided_games).with_interval(accumulator.proportion_half_width(
			reversed_arm.venue_wins, reversed_arm.decided_games)))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.reversed.mean_margin" % id),
		"Mean venue-minus-visitor final margin after the venue is swapped.",
		"complete games",
		reversed_arm.mean_margin(),
		reversed_arm.games).with_interval(reversed_arm.mean_margin_half_width()))

	# §17.4's combined cap, measured rather than asserted. The environment's
	# contribution is the venue-minus-visitor efficiency gap at the production
	# environment *net of* the same gap on a neutral court, so whatever the
	# fixture is worth on its own is subtracted rather than charged to §19.4.
	var contribution: float = home_arm.points_per_100_gap() - neutral_arm.points_per_100_gap()
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.home.points_per_100_contribution" % id),
		"Venue-minus-visitor points per 100 possessions at the production "
		+ "environment, net of the neutral arm. §17.4 caps this at +2.5.",
		"points per 100 possessions",
		contribution,
		home_arm.games))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.home.combined_cap_respected" % id),
		"The measured environment contribution is at or below the §17.4 "
		+ "combined cap of +2.5 points per 100 possessions.",
		contribution <= 2.5,
		"BALANCE_SPEC.md §17.4",
		home_arm.games))

	_report_paired(report, id, home_arm, neutral_arm, reversed_arm)

	for arm: ArmSample in [home_arm, neutral_arm, reversed_arm] as Array[ArmSample]:
		_report_arm_statistics(report, id, arm)


## The measurement the marginal columns cannot make.
##
## The three arms play the identical fixtures at the identical seeds, so the
## per-game *difference* between two arms is the venue with the roster, the
## matchup and the seed all cancelled. Differencing two column means instead
## throws that away and leaves a standard error several times larger: at 250
## games the marginal home win rate carries an interval of six points, which
## cannot resolve an effect worth one and a half.
##
## Two independent estimates of the same quantity are reported, and §19.4
## requires them to agree:
##
## ```text
## effect on A =  margin_home[i]     - margin_neutral[i]
## effect on B =  margin_reversed[i] + margin_neutral[i]
## ```
##
## The second is the venue reversal. `margin_reversed` is signed from B's end of
## the building, and B's neutral margin is `-margin_neutral`, so adding them is
## the same subtraction performed on the other bench. An effect attached to a
## roster rather than to a venue produces two numbers of opposite sign here and
## is caught nowhere else.
func _report_paired(
	report: CalibrationReport,
	competition_id: String,
	home_arm: ArmSample,
	neutral_arm: ArmSample,
	reversed_arm: ArmSample,
) -> void:
	var venue_gain := PackedFloat64Array()
	var reversed_gain := PackedFloat64Array()
	var venue_win_gain := PackedFloat64Array()
	var reversed_win_gain := PackedFloat64Array()
	var count: int = mini(
		home_arm.margins.size(), mini(neutral_arm.margins.size(), reversed_arm.margins.size()))
	for index in range(count):
		var neutral_margin: float = neutral_arm.margins[index]
		venue_gain.append(home_arm.margins[index] - neutral_margin)
		reversed_gain.append(reversed_arm.margins[index] + neutral_margin)
		venue_win_gain.append(
			_win_value(home_arm.margins[index]) - _win_value(neutral_margin))
		reversed_win_gain.append(
			_win_value(reversed_arm.margins[index]) - _win_value(-neutral_margin))

	_add_paired(report, competition_id, &"home.environment_margin_gain",
		"Mean per-game venue-minus-neutral final margin for the same roster at the "
		+ "same seed. The §19.4 environment with everything else cancelled.",
		venue_gain)
	_add_paired(report, competition_id, &"reversed.environment_margin_gain",
		"The same quantity measured from the other bench after the venue is "
		+ "swapped. It must agree with the home arm in sign and size.",
		reversed_gain)
	_add_paired(report, competition_id, &"home.environment_win_gain",
		"Mean per-game change in the venue side's win/draw value from playing at "
		+ "home rather than neutral. Add 0.50 to read it as a home win rate.",
		venue_win_gain)
	_add_paired(report, competition_id, &"reversed.environment_win_gain",
		"The same quantity after the venue is swapped.", reversed_win_gain)

	# §17.4's combined cap, on the paired difference rather than on two column
	# means, and expressed per 100 possessions rather than per game so the levels
	# are comparable and the cap is read in its own units.
	var possessions: float = maxf(home_arm.venue.possessions_per_game(), 1.0)
	var per_100: float = 100.0 * _mean(venue_gain) / possessions
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.home.paired_points_per_100" % competition_id),
		"Paired venue-minus-neutral margin per 100 venue possessions. This is the "
		+ "figure §17.4 caps at +2.5.",
		"points per 100 possessions", per_100, count).with_interval(
			100.0 * _half_width(venue_gain) / possessions))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.home.paired_combined_cap_respected" % competition_id),
		"The paired environment contribution is at or below the §17.4 combined "
		+ "cap of +2.5 points per 100 possessions.",
		per_100 <= 2.5, "BALANCE_SPEC.md §17.4", count))
	# The venue reversal has to reproduce the effect, not merely fail to
	# contradict it: two estimates of one quantity whose intervals do not even
	# overlap mean the effect is attached to a roster and not to a building.
	var home_gain: float = _mean(venue_gain)
	var away_gain: float = _mean(reversed_gain)
	var reach: float = _half_width(venue_gain) + _half_width(reversed_gain)
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.venue_reversal_agrees" % competition_id),
		"The home arm and the venue-reversed arm estimate the same environment "
		+ "effect within their combined intervals.",
		absf(home_gain - away_gain) <= reach, "SIMULATION_SPEC.md §19.4", count))


func _add_paired(
	report: CalibrationReport,
	competition_id: String,
	key: StringName,
	definition: String,
	values: PackedFloat64Array,
) -> void:
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.%s" % [competition_id, key]), definition,
		"matched pairs", _mean(values), values.size()
	).with_interval(_half_width(values)))


## A win is 1, a draw 0.5, a loss 0. Regulation ties enter overtime, so the draw
## case does not arise in a completed game; it is here so the statistic is
## defined on any margin rather than silently scoring a tie as a loss.
func _win_value(margin: float) -> float:
	if margin > 0.0:
		return 1.0
	return 0.0 if margin < 0.0 else 0.5


func _mean(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _half_width(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	return 1.96 * sqrt(maxf(ScoringCovariance.variance(values), 0.0)) / sqrt(float(values.size()))


## Both sides' §14.1 statistics and game shape for one arm. Reported raw: a
## §14.1 band describes a league, and one venue side of a mirror fixture is
## neither a league nor half of one.
func _report_arm_statistics(
	report: CalibrationReport,
	competition_id: String,
	arm: ArmSample,
) -> void:
	var prefix: String = "%s.%s" % [competition_id, arm.arm_id]
	var pairs: Array = [
		[&"points_per_possession", "Points per engine possession.",
			arm.venue.points_per_possession(), arm.visitor.points_per_possession()],
		[&"possessions_per_game", "Engine possessions per team game.",
			arm.venue.possessions_per_game(), arm.visitor.possessions_per_game()],
		[&"field_goal_percentage", "Field goals made over attempted.",
			arm.venue.field_goal_percentage(), arm.visitor.field_goal_percentage()],
		[&"two_point_percentage", "Two-point makes over two-point attempts.",
			arm.venue.two_point_percentage(), arm.visitor.two_point_percentage()],
		[&"three_point_percentage", "Three-point makes over three-point attempts.",
			arm.venue.three_point_percentage(), arm.visitor.three_point_percentage()],
		[&"three_point_attempt_rate", "Three-point attempts over field-goal attempts.",
			arm.venue.three_point_attempt_rate(), arm.visitor.three_point_attempt_rate()],
		[&"free_throw_percentage", "Free throws made over attempted.",
			arm.venue.free_throw_percentage(), arm.visitor.free_throw_percentage()],
		[&"free_throw_attempt_rate", "Free-throw attempts over field-goal attempts.",
			arm.venue.free_throw_attempt_rate(), arm.visitor.free_throw_attempt_rate()],
		[&"turnovers_per_100", "Turnovers per 100 engine possessions.",
			arm.venue.turnovers_per_100(), arm.visitor.turnovers_per_100()],
		[&"offensive_rebound_percentage", "Offensive rebounds over available chances.",
			arm.venue.offensive_rebound_percentage(),
			arm.visitor.offensive_rebound_percentage()],
		[&"assist_percentage", "Credited assists over made field goals.",
			arm.venue.assist_percentage(), arm.visitor.assist_percentage()],
		[&"conditional_assist_rate",
			"Credited assists over made field goals that carried a recorded creator.",
			arm.venue.conditional_assist_rate(), arm.visitor.conditional_assist_rate()],
		[&"fouls_per_game", "Personal fouls per team game.",
			arm.venue.fouls_per_game(), arm.visitor.fouls_per_game()],
		[&"steals_per_game", "Steals per team game.",
			arm.venue.steals_per_game(), arm.visitor.steals_per_game()],
		[&"blocks_per_game", "Blocks per team game.",
			arm.venue.blocks_per_game(), arm.visitor.blocks_per_game()],
		[&"timeouts_per_game", "Timeouts called per team game.",
			arm.venue.timeouts_per_game(), arm.visitor.timeouts_per_game()],
		[&"substitutions_per_game", "Check-ins per team game.",
			arm.venue.substitutions_per_game(), arm.visitor.substitutions_per_game()],
	]
	for pair: Array in pairs:
		var key: StringName = pair[0]
		var definition: String = pair[1]
		var venue_value: float = pair[2]
		var visitor_value: float = pair[3]
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.venue.%s" % [prefix, key]), definition,
			"venue side", venue_value, arm.venue.team_games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.visitor.%s" % [prefix, key]), definition,
			"visiting side", visitor_value, arm.visitor.team_games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.delta.%s" % [prefix, key]),
			definition + " Venue minus visitor.",
			"paired difference", venue_value - visitor_value, arm.games))

	report.add_metric(CalibrationMetric.raw(
		StringName("%s.overtime_rate" % prefix),
		"Share of games reaching overtime.", "complete games",
		arm.overtime_rate(), arm.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.close_game_rate" % prefix),
		"Share of games decided by five points or fewer.", "complete games",
		arm.close_game_rate(), arm.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.blowout_rate" % prefix),
		"Share of games decided by twenty points or more.", "complete games",
		arm.blowout_rate(), arm.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.margin_standard_deviation" % prefix),
		"Standard deviation of the venue-minus-visitor final margin.",
		"complete games", arm.margin_standard_deviation(), arm.games))
