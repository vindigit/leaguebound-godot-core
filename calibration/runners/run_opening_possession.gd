extends SceneTree

## What is the opening possession worth, and is it inside the home-court number?
## (`SIMULATION_SPEC.md` §19.4, `BALANCE_SPEC.md` §14.2, Stage 4 diagnostic.)
##
## The engine does not decide who opens. `MatchInput.initial_possession_team_id`
## has no default and is asserted to name one of the two supplied teams, so the
## opening inbound is a property of the *fixture* and every caller chooses it.
## `CompetitionCatalog.match_for` and `mirrored_match_for` chose `home.team_id`,
## unconditionally, for every game they have ever built. Nothing in
## `SIMULATION_SPEC.md`, `BALANCE_SPEC.md`, `GDD.md` or `PRD.md` describes a jump
## ball, a possession arrow or an alternating-possession rule, and
## `CompetitionRuleProfile.possession_arrow_enabled` is declared and never read.
## So this is a calibration-fixture artifact and not a modelled basketball rule,
## and the question this runner answers is what it was worth.
##
## Six cells over one shared set of mirror fixtures at one shared set of seeds:
##
## ```text
##                        environment   opening inbound
## env_on_venue_opens          E        the venue side
## env_off_venue_opens         0        the venue side
## env_on_visitor_opens        E        the visiting side
## env_off_visitor_opens       0        the visiting side
## env_on_counterbalanced      E        alternates on variation parity
## env_off_counterbalanced     0        alternates on variation parity
## ```
##
## Common random numbers throughout: every cell plays fixture `i` at seed
## `i + 1`, so a per-fixture difference between two cells is the one field that
## differs between them and cannot be roster or sampling noise. The fixture is a
## **mirror** — both benches built from the same variation — so the pregame
## strength gap is exactly zero and whatever separates the columns was produced
## by the venue, the inbound, or the game.
##
## The contrasts the cells support, each a paired per-fixture difference:
##
## ```text
## opening value, neutral court   env_off_venue_opens - env_off_visitor_opens
## opening value, at the venue    env_on_venue_opens  - env_on_visitor_opens
## venue value, venue opens       env_on_venue_opens  - env_off_venue_opens
## venue value, visitor opens     env_on_visitor_opens - env_off_visitor_opens
## venue value, counterbalanced   env_on_counterbalanced - env_off_counterbalanced
## interaction                    (venue | venue opens) - (venue | visitor opens)
## ```
##
## The first line is the measurement this runner exists for: the value of the
## opening possession with the environment switched off entirely, so it is the
## inbound and nothing else. The last is the check that the two effects are
## separable — an interaction indistinguishable from zero means the opening
## possession and the environment add, and that counterbalancing the inbound
## removes it from a venue estimate without disturbing the venue estimate.
##
## The counterbalanced cells are a deterministic half-and-half mixture of the
## two fixed cells at the same seeds, so their mean must equal the mean of the
## two, and the runner checks that rather than assuming it.
##
## This is a diagnostic. It certifies nothing at any sample it is given.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_opening_possession.gd -- \
##       [--games=N] [--competition=high_school|college|development|overseas|top_domestic_pro|all] \
##       [--range=audit|audit_second] [--environment=0.5] [--label=NAME]

const DEFAULT_GAMES: int = 250

## Seed ranges owned by this runner, disjoint from every range any other section
## uses. They are audit ranges: this runner measures an artifact, it does not
## fit anything, so there is no tuning range and nothing here was read before a
## value was chosen.
const AUDIT_BASE: int = 800000
const AUDIT_SECOND_BASE: int = 805000

const CELL_ON_VENUE: StringName = &"env_on_venue_opens"
const CELL_OFF_VENUE: StringName = &"env_off_venue_opens"
const CELL_ON_VISITOR: StringName = &"env_on_visitor_opens"
const CELL_OFF_VISITOR: StringName = &"env_off_visitor_opens"
const CELL_ON_COUNTER: StringName = &"env_on_counterbalanced"
const CELL_OFF_COUNTER: StringName = &"env_off_counterbalanced"

const NEUTRAL_ENVIRONMENT: float = 0.0

## Who opens, per cell. `OPENER_VENUE` and `OPENER_VISITOR` are fixed;
## `OPENER_ALTERNATE` is the counterbalance under test.
const OPENER_VENUE: int = 0
const OPENER_VISITOR: int = 1
const OPENER_ALTERNATE: int = 2


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var selection: String = CalibrationCli.string_option(options, &"competition", "all")
	var range_name: String = CalibrationCli.string_option(options, &"range", "audit")
	var environment: float = CalibrationCli.float_option(options, &"environment", 0.5)
	var label: String = CalibrationCli.string_option(options, &"label", "opening_possession")
	var base: int = _range_base(range_name)
	var competitions: Array[int] = _competitions(selection)

	var context := ReportContext.create(
		&"opening_possession_audit",
		"Opening-possession audit",
		CompetitionCatalog.rules_for(competitions[0]),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per cell per competition"
	context.sample_count = games
	context.competition_id = (
		CalibrationTargets.competition_id(competitions[0]) if competitions.size() == 1
		else &"all")
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"BELOW CERTIFICATION REQUIREMENT. %d games per cell against the §27.1 " % games
		+ "requirement; this is directional evidence and certifies nothing.")
	context.notes.append(
		"Six cells play the identical mirror fixtures at the identical seeds. A "
		+ "per-fixture difference between two cells is the one field that differs.")
	context.notes.append(
		"Seed range: %s, variations %d-%d, RNG seeds %d-%d."
		% [range_name, base, base + games - 1, base + 1, base + games])
	context.notes.append(
		"The engine has no tip-off: MatchInput.initial_possession_team_id is a "
		+ "required input with no default and src/ never constructs one. The "
		+ "opening inbound is chosen by the fixture, which is what this audits.")

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	for competition in competitions:
		var cells: Dictionary = _simulate(competition, games, base, environment)
		for cell_id: StringName in _cell_order():
			rows.append((cells[cell_id] as Cell).to_dictionary())
		_report_competition(report, competition, cells)
	report.add_section(&"cells", rows)
	report.finish()
	quit(ReportWriter.publish(report, "opening_possession_%s" % label))


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


static func _cell_order() -> Array[StringName]:
	return [
		CELL_ON_VENUE, CELL_OFF_VENUE,
		CELL_ON_VISITOR, CELL_OFF_VISITOR,
		CELL_ON_COUNTER, CELL_OFF_COUNTER,
	] as Array[StringName]


# --- sampling ---------------------------------------------------------------

## One cell's sample. Margins are signed venue-minus-visitor throughout, so a
## positive mean is an advantage to whoever owns the building.
class Cell:
	extends RefCounted

	var cell_id: StringName = &"cell"
	var competition: int = 0
	var games: int = 0
	var decided_games: int = 0
	var venue_wins: int = 0
	var margins := PackedFloat64Array()
	var venue_points: int = 0
	var visitor_points: int = 0
	var venue_possessions: int = 0
	var visitor_possessions: int = 0
	## Games in which the venue side actually received the opening inbound.
	## Reported so a counterbalanced cell can be shown to be balanced rather
	## than asserted to be.
	var venue_opened: int = 0

	func venue_win_rate() -> float:
		return 0.0 if decided_games == 0 else float(venue_wins) / float(decided_games)

	func mean_margin() -> float:
		return VenueEffectEstimator.mean(margins)

	func mean_margin_half_width() -> float:
		return VenueEffectEstimator.half_width(margins)

	func venue_possessions_per_game() -> float:
		return 0.0 if games == 0 else float(venue_possessions) / float(games)

	func visitor_possessions_per_game() -> float:
		return 0.0 if games == 0 else float(visitor_possessions) / float(games)

	## Pooled over both sides, which is the league figure §14.1 bands describe.
	func points_per_possession() -> float:
		var total: int = venue_possessions + visitor_possessions
		return 0.0 if total == 0 else float(venue_points + visitor_points) / float(total)

	func venue_points_per_possession() -> float:
		return 0.0 if venue_possessions == 0 else float(venue_points) / float(venue_possessions)

	func visitor_points_per_possession() -> float:
		return (
			0.0 if visitor_possessions == 0
			else float(visitor_points) / float(visitor_possessions))

	func venue_open_share() -> float:
		return 0.0 if games == 0 else float(venue_opened) / float(games)

	func to_dictionary() -> Dictionary:
		return {
			"cell": String(cell_id),
			"competition": String(CalibrationTargets.competition_id(competition)),
			"games": games,
			"venue_win_rate": venue_win_rate(),
			"mean_margin": mean_margin(),
			"mean_margin_half_width": mean_margin_half_width(),
			"venue_possessions_per_game": venue_possessions_per_game(),
			"visitor_possessions_per_game": visitor_possessions_per_game(),
			"points_per_possession": points_per_possession(),
			"venue_points_per_possession": venue_points_per_possession(),
			"visitor_points_per_possession": visitor_points_per_possession(),
			"venue_open_share": venue_open_share(),
		}


func _simulate(competition: int, games: int, base: int, environment: float) -> Dictionary:
	var cells: Dictionary = {}
	for cell_id: StringName in _cell_order():
		var cell := Cell.new()
		cell.cell_id = cell_id
		cell.competition = competition
		cells[cell_id] = cell
	for index in range(games):
		var variation: int = base + index
		for cell_id: StringName in _cell_order():
			var input: MatchInput = _cell_input(competition, variation, cell_id, environment)
			# The same seed in every cell. That is what makes the columns a
			# matched set rather than six independent samples.
			var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
				input, SeededRandomSource.new(variation + 1))
			_accumulate(cells[cell_id] as Cell, input, output)
	return cells


static func _cell_environment(cell_id: StringName, environment: float) -> float:
	match cell_id:
		CELL_ON_VENUE, CELL_ON_VISITOR, CELL_ON_COUNTER:
			return environment
		_:
			return NEUTRAL_ENVIRONMENT


static func _cell_opener(cell_id: StringName) -> int:
	match cell_id:
		CELL_ON_VENUE, CELL_OFF_VENUE:
			return OPENER_VENUE
		CELL_ON_VISITOR, CELL_OFF_VISITOR:
			return OPENER_VISITOR
		_:
			return OPENER_ALTERNATE


## One match. The venue side and the visiting side are the same two rosters in
## every cell; only the environment strength and the opening inbound move.
func _cell_input(
	competition: int,
	variation: int,
	cell_id: StringName,
	environment: float,
) -> MatchInput:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	# A mirror fixture: both benches from the same variation, so the pregame
	# strength gap is exactly zero and nothing but the venue and the inbound can
	# separate them.
	var venue_side: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"home", variation * 2, balance, 0.0)
	var visiting_side: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"away", variation * 2, balance, 0.0)
	var opener_kind: int = _cell_opener(cell_id)
	var venue_opens: bool = (
		opener_kind == OPENER_VENUE
		or (opener_kind == OPENER_ALTERNATE and variation % 2 == 0))
	return MatchInput.new(
		StringName("opening_%s_%s_%d" % [
			CalibrationTargets.competition_id(competition), cell_id, variation]),
		StringName("opening_game_%d" % variation),
		CompetitionCatalog.rules_for(competition),
		balance,
		venue_side,
		visiting_side,
		venue_side.team_id if venue_opens else visiting_side.team_id,
		CompetitionCatalog.ratings_profile(),
		_cell_environment(cell_id, environment))


func _accumulate(cell: Cell, input: MatchInput, output: MatchSimulationOutput) -> void:
	var result: MatchFinalResult = output.final_result
	var statistics: MatchStatistics = result.statistics
	cell.games += 1
	if input.initial_possession_team_id == input.home.team_id:
		cell.venue_opened += 1
	var margin: int = result.home_score - result.away_score
	cell.margins.append(float(margin))
	if margin != 0:
		cell.decided_games += 1
		if margin > 0:
			cell.venue_wins += 1
	var venue_line: TeamStatLine = statistics.team_line(input.home.team_id)
	var visitor_line: TeamStatLine = statistics.team_line(input.away.team_id)
	cell.venue_points += venue_line.points
	cell.visitor_points += visitor_line.points
	cell.venue_possessions += venue_line.engine_possessions
	cell.visitor_possessions += visitor_line.engine_possessions


# --- reporting --------------------------------------------------------------

func _report_competition(
	report: CalibrationReport,
	competition: int,
	cells: Dictionary,
) -> void:
	var id: String = String(CalibrationTargets.competition_id(competition))

	for cell_id: StringName in _cell_order():
		var cell: Cell = cells[cell_id]
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s.win_rate" % [id, cell_id]),
			"Share of decided games won by the venue side in this cell.",
			"decided games", cell.venue_win_rate(), cell.decided_games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s.mean_margin" % [id, cell_id]),
			"Mean venue-minus-visitor final margin in this cell.",
			"complete games", cell.mean_margin(), cell.games
		).with_interval(cell.mean_margin_half_width()))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s.venue_possessions_per_game" % [id, cell_id]),
			"Venue-side engine possessions per game in this cell.",
			"complete games", cell.venue_possessions_per_game(), cell.games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s.points_per_possession" % [id, cell_id]),
			"Points per engine possession pooled over both sides in this cell.",
			"engine possessions", cell.points_per_possession(),
			cell.venue_possessions + cell.visitor_possessions))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.%s.venue_open_share" % [id, cell_id]),
			"Share of games in which the venue side received the opening inbound.",
			"complete games", cell.venue_open_share(), cell.games))

	# --- the paired contrasts ------------------------------------------------
	var on_venue: Cell = cells[CELL_ON_VENUE]
	var off_venue: Cell = cells[CELL_OFF_VENUE]
	var on_visitor: Cell = cells[CELL_ON_VISITOR]
	var off_visitor: Cell = cells[CELL_OFF_VISITOR]
	var on_counter: Cell = cells[CELL_ON_COUNTER]
	var off_counter: Cell = cells[CELL_OFF_COUNTER]

	_paired(report, id, &"opening_value.neutral_court",
		"Mean per-fixture venue-minus-visitor margin gained by receiving the "
		+ "opening inbound, with the §19.4 environment switched off entirely. "
		+ "This is what the opening possession is worth on its own.",
		off_venue, off_visitor)
	_paired(report, id, &"opening_value.at_the_venue",
		"The same quantity with the environment at its production strength.",
		on_venue, on_visitor)
	_paired(report, id, &"venue_value.venue_opens",
		"Mean per-fixture margin gained from the environment when the venue "
		+ "side always receives the opening inbound.",
		on_venue, off_venue)
	_paired(report, id, &"venue_value.visitor_opens",
		"Mean per-fixture margin gained from the environment when the visiting "
		+ "side always receives the opening inbound.",
		on_visitor, off_visitor)
	_paired(report, id, &"venue_value.counterbalanced",
		"Mean per-fixture margin gained from the environment with the opening "
		+ "inbound alternating on variation parity. The estimate a "
		+ "counterbalanced fixture produces.",
		on_counter, off_counter)

	# The separability check. If the environment is worth the same whether or
	# not the venue side opened, the two effects add and counterbalancing the
	# inbound removes it from a venue estimate without disturbing that estimate.
	var venue_when_venue_opens: PackedFloat64Array = _difference(on_venue, off_venue)
	var venue_when_visitor_opens: PackedFloat64Array = _difference(on_visitor, off_visitor)
	var interaction := PackedFloat64Array()
	for index in range(mini(
		venue_when_venue_opens.size(), venue_when_visitor_opens.size())):
		interaction.append(venue_when_venue_opens[index] - venue_when_visitor_opens[index])
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.interaction.opening_by_environment" % id),
		"Environment effect when the venue opens minus the environment effect "
		+ "when the visitor opens. Zero means the two effects add and the "
		+ "opening inbound can be counterbalanced away without disturbing the "
		+ "venue estimate.",
		"matched pairs", VenueEffectEstimator.mean(interaction), interaction.size()
	).with_interval(VenueEffectEstimator.half_width(interaction)))
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.interaction.indistinguishable_from_zero" % id),
		"The opening-by-environment interaction's interval covers zero, so the "
		+ "two effects are separable at this sample.",
		absf(VenueEffectEstimator.mean(interaction))
			<= VenueEffectEstimator.half_width(interaction),
		"SIMULATION_SPEC.md §19.4", interaction.size()))

	# The counterbalanced cells are a deterministic half-and-half mixture of the
	# two fixed cells at the same seeds, so their means must agree with the
	# average of the two. Checked rather than assumed: a counterbalance that
	# silently stopped alternating would still produce a plausible number.
	var counter_on: Cell = on_counter
	var expected_share: float = 0.5
	report.add_metric(CalibrationMetric.boolean(
		StringName("%s.counterbalance.is_balanced" % id),
		"The counterbalanced cell gave the venue side the opening inbound in "
		+ "half its games, to within one game.",
		absf(counter_on.venue_open_share() - expected_share)
			<= 1.0 / float(maxi(counter_on.games, 1)),
		"calibration fixture contract", counter_on.games))


func _difference(left: Cell, right: Cell) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for index in range(mini(left.margins.size(), right.margins.size())):
		values.append(left.margins[index] - right.margins[index])
	return values


func _paired(
	report: CalibrationReport,
	competition_id: String,
	key: StringName,
	definition: String,
	left: Cell,
	right: Cell,
) -> void:
	var margin_gain: PackedFloat64Array = _difference(left, right)
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.%s.margin" % [competition_id, key]), definition,
		"matched pairs", VenueEffectEstimator.mean(margin_gain), margin_gain.size()
	).with_interval(VenueEffectEstimator.half_width(margin_gain)))

	var win_gain := PackedFloat64Array()
	var possession_gain := PackedFloat64Array()
	for index in range(mini(left.margins.size(), right.margins.size())):
		win_gain.append(
			VenueEffectEstimator.win_value(left.margins[index])
			- VenueEffectEstimator.win_value(right.margins[index]))
	# Possessions are a per-cell total rather than a per-game series here, so the
	# gain is the difference of the two cells' per-game figures.
	possession_gain.append(
		left.venue_possessions_per_game() - right.venue_possessions_per_game())
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.%s.win_rate_change" % [competition_id, key]),
		"The same contrast on the win/draw value. Add 0.50 to read it as a "
		+ "venue-side win rate.",
		"matched pairs", VenueEffectEstimator.mean(win_gain), win_gain.size()
	).with_interval(VenueEffectEstimator.half_width(win_gain)))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.%s.venue_possessions_change" % [competition_id, key]),
		"Difference in venue-side engine possessions per game across the "
		+ "contrast.",
		"complete games",
		left.venue_possessions_per_game() - right.venue_possessions_per_game(),
		left.games))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.%s.points_per_possession_change" % [competition_id, key]),
		"Difference in pooled points per engine possession across the contrast.",
		"complete games",
		left.points_per_possession() - right.points_per_possession(),
		left.games))
