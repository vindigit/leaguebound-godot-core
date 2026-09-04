extends SceneTree

## Counterfactual measurements separating the causes of a §14.1 field-goal
## failure (`BALANCE_SPEC.md` §14.1, Stage 4 diagnostic).
##
## The decomposition says *where* a level's field-goal percentage differs from
## an adjacent level's. It cannot say *why*, because at every level the roster,
## the competition rule profile and the shot mix change together, and a term
## that differs is consistent with any of them. Separating them needs
## measurements in which only one thing moves.
##
## Two modes, both on matched fixtures at identical seeds so a cell-to-cell
## difference is the manipulated factor with the draw sequence cancelled:
##
## - `cross` crosses **competition rule profiles** with **rosters**. Each cell
##   pairs one competition's rules with another competition's roster population.
##   If field-goal percentage follows the roster and not the rules, the rule
##   profile is exonerated on measurement rather than by reading it; if it
##   follows the rules, the rule profile is the cause and the roster is not.
##
## - `distribution` holds one competition's rules *and* its roster level, and
##   moves only a named **attribute subset**. It answers a different question
##   from `sweep`: whether a level's shortfall needs the whole ladder to move, or
##   only the part of the roster the statistic actually reads. The §14.1
##   field-goal row reads shooting ratings, not Overall.
##
## - `sweep` holds one competition's rules and moves the **roster level** by a
##   whole number of rating points. This is the engine's field-goal response to
##   roster strength, measured rather than assumed, and it is what decides
##   whether a level's shortfall is the size its rating gap explains.
##
## Neither mode changes a production value, and this runner tunes nothing.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_fg_counterfactual.gd -- \
##       [--mode=cross|sweep|distribution] [--games=N] [--base=SEED_BASE] \
##       [--rules=college] [--rosters=development] [--offsets=0,2,4,6] \
##       [--subset=shooting|shooting_and_finishing|three_point_only|all] [--label=NAME]

const DEFAULT_GAMES: int = 200
const DEFAULT_BASE: int = 930000
const PROGRESS_EVERY: int = 50


class Cell:
	extends RefCounted

	var name: String
	var rules_competition: int
	var roster_competition: int
	var level_offset: float
	## Attributes this cell shifts *after* the roster is built, and by how much.
	## Empty on every cell except a `distribution` cell. A **diagnostic transform
	## only**: it exists so the owner package can ask "what if the fixture's
	## shooting sat where the production builder puts it?" without editing the
	## fixture, and it must never reach production or the shipped catalog.
	var attribute_keys: PackedInt32Array = []
	var attribute_offset: float = 0.0

	func _init(
		p_name: String,
		p_rules: int,
		p_rosters: int,
		p_offset: float = 0.0,
		p_attribute_keys: PackedInt32Array = [],
		p_attribute_offset: float = 0.0,
	) -> void:
		name = p_name
		rules_competition = p_rules
		roster_competition = p_rosters
		level_offset = p_offset
		attribute_keys = p_attribute_keys
		attribute_offset = p_attribute_offset


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var games: int = CalibrationCli.int_option(options, &"games", DEFAULT_GAMES)
	var base: int = CalibrationCli.int_option(options, &"base", DEFAULT_BASE)
	var mode: String = CalibrationCli.string_option(options, &"mode", "cross")
	var label: String = CalibrationCli.string_option(options, &"label", mode)
	var rules_name: String = CalibrationCli.string_option(options, &"rules", "college")
	var rosters_name: String = CalibrationCli.string_option(options, &"rosters", "development")
	var offsets: PackedFloat64Array = _offsets(
		CalibrationCli.string_option(options, &"offsets", "0,2,4,6"))

	var subset: String = CalibrationCli.string_option(options, &"subset", "shooting")
	var cells: Array[Cell] = []
	match mode:
		"cross":
			cells = _cross_cells(_competition(rules_name), _competition(rosters_name))
		"distribution":
			cells = _distribution_cells(_competition(rules_name), subset, offsets)
		_:
			cells = _sweep_cells(_competition(rules_name), offsets)

	var context := ReportContext.create(
		&"fg_counterfactual",
		"Field-goal counterfactual: rules against rosters",
		CompetitionCatalog.rules_for(cells[0].rules_competition),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "complete games per cell"
	context.sample_count = games
	context.set_shard(0, 1, base + 1, base + games)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_COMPETITION_GAMES,
		CalibrationTargets.sample_size_source())
	context.notes.append(
		"DIAGNOSTIC ONLY. Counterfactual measurement; certifies nothing and "
		+ "tunes nothing. No production value is changed by this runner.")
	context.notes.append(
		"Every cell runs the identical variations and seeds, so a cell-to-cell "
		+ "difference is the manipulated factor and not the draw sequence.")
	context.notes.append(
		"Seed range: variations %d-%d, RNG seeds %d-%d."
		% [base, base + games - 1, base + 1, base + games])
	context.notes.append("Mode: %s." % mode)

	var report := CalibrationReport.new(context)
	var rows: Array[Dictionary] = []
	for cell in cells:
		print("counterfactual cell '%s': %d games..." % [cell.name, games])
		var decomposition := PppDecomposition.new()
		var terms := ShotTermAccumulator.new()
		var accumulator := MatchMetricAccumulator.new()
		_simulate(cell, games, base, decomposition, terms, accumulator)
		var totals: PppDecomposition.Totals = decomposition.totals
		var half_width: float = accumulator.field_goal_percentage_half_width()
		var mean_roster_overall: float = _mean_roster_overall(cell, games, base)
		var payload: Dictionary = {
			"cell": cell.name,
			"rules": String(CalibrationTargets.competition_id(cell.rules_competition)),
			"rosters": String(CalibrationTargets.competition_id(cell.roster_competition)),
			"level_offset": cell.level_offset,
			"games": totals.games,
			"field_goals_made": totals.field_goals_made(),
			"field_goals_attempted": totals.field_goals_attempted(),
			"field_goal_percentage": totals.field_goal_percentage(),
			"field_goal_percentage_half_width": half_width,
			"points_per_possession": totals.points_per_possession(),
			"possessions_per_game": totals.possessions_per_game(),
			"three_point_attempt_rate": totals.three_point_attempt_rate(),
			"three_point_percentage": totals.three_point_percentage(),
			"two_point_percentage": totals.two_point_percentage(),
			"free_throw_rate": totals.free_throw_rate(),
			"turnover_rate": totals.turnover_rate(),
			"offensive_rebound_extension_rate": totals.extension_rate(),
			"assisted_share": totals.assisted_share(),
			"block_rate": totals.block_rate(),
			"mean_shooter_capability": terms.mean_shooter_capability(),
			"mean_defender_capability": terms.mean_defender_capability(),
			"mean_baseline": terms.mean_baseline(),
			"mean_contest_penalty": terms.mean_contest_penalty(),
			"mean_probability": terms.mean_probability(),
			"reconciled": decomposition.is_reconciled(),
			# The §14.1 and §14.2 rows the owner decision is judged against.
			# `accumulator` has counted them since this runner was written and
			# only its interval was ever read; a decision grid that publishes
			# field-goal percentage alone cannot show which *other* locked band
			# a roster change breaks first, which is the question that decides
			# whether an option is viable at all. Pure reporting: the same games,
			# the same counts, no extra simulation and no extra draw.
			"points_per_game": accumulator.points_per_game(),
			"free_throw_percentage": accumulator.free_throw_percentage(),
			"free_throw_attempt_rate": accumulator.free_throw_attempt_rate(),
			"turnovers_per_100_possessions": accumulator.turnovers_per_100_possessions(),
			"offensive_rebound_percentage": accumulator.offensive_rebound_percentage(),
			"assist_percentage": accumulator.assist_percentage(),
			"steals_per_game": accumulator.steals_per_game(),
			"blocks_per_game": accumulator.blocks_per_game(),
			"fouls_per_game": accumulator.fouls_per_game(),
			"home_win_rate": accumulator.home_win_rate(),
			"overtime_rate": accumulator.overtime_rate(),
			"close_game_rate": accumulator.close_game_rate(),
			"blowout_rate": accumulator.blowout_rate(),
			"points_per_possession_half_width":
				accumulator.points_per_possession_half_width(),
			# The rating level the cell actually played at, read off the built
			# rosters rather than inferred from the requested offset, so a grid
			# row states its own population instead of its own intention.
			"mean_roster_overall": mean_roster_overall,
		}
		rows.append(payload)
		report.add_metric(CalibrationMetric.boolean(
			StringName("%s.reconciled" % cell.name),
			"Every accounting identity closed for this cell.",
			decomposition.is_reconciled(), "ledger accounting identity", totals.games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.field_goal_percentage" % cell.name),
			"Field-goal percentage for this cell, from the ledger.",
			"field-goal attempts", totals.field_goal_percentage(),
			totals.field_goals_attempted())
			.with_interval(half_width))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.mean_shooter_capability" % cell.name),
			"Mean shooter capability for this cell.",
			"unblocked attempts", terms.mean_shooter_capability(), terms.shots))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.points_per_possession" % cell.name),
			"Points per engine possession for this cell.",
			"engine possessions", totals.points_per_possession(), totals.possessions))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.possessions_per_game" % cell.name),
			"Engine possessions per game for this cell.",
			"games", totals.possessions_per_game(), totals.games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.mean_roster_overall" % cell.name),
			"Mean current Overall across both rosters, as built for this cell.",
			"players", mean_roster_overall, totals.games))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.assist_percentage" % cell.name),
			"Assists over the team's own made field goals.",
			"made field goals", accumulator.assist_percentage(),
			accumulator.field_goals_made))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.offensive_rebound_percentage" % cell.name),
			"ORB / (ORB + opponent DREB).", "offensive-rebound chances",
			accumulator.offensive_rebound_percentage(),
			accumulator.offensive_rebound_chances))
		report.add_metric(CalibrationMetric.raw(
			StringName("%s.blowout_rate" % cell.name),
			"Share of games decided by a §14.2 blowout margin.", "games",
			accumulator.blowout_rate(), accumulator.games))
		print("  %s: FG%% %.4f ±%.4f, capability %.4f, PPP %.4f, poss/game %.2f%s" % [
			cell.name, totals.field_goal_percentage(), half_width,
			terms.mean_shooter_capability(), totals.points_per_possession(),
			totals.possessions_per_game(),
			"" if decomposition.is_reconciled() else "  UNRECONCILED"])

	report.add_section(&"cells", rows)
	report.finish()
	quit(ReportWriter.publish(report, "fg_counterfactual_%s" % label))


## Mean current Overall of the rosters a cell plays with.
##
## Rebuilt from the same constructor and the same variations the cell simulated,
## so it describes the population that produced the cell's numbers. It consumes
## no random source and touches no match state.
func _mean_roster_overall(cell: Cell, games: int, base: int) -> float:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var ratings: RatingsProfile = CompetitionCatalog.ratings_profile()
	var total: float = 0.0
	var counted: int = 0
	for index in range(games):
		var variation: int = base + index
		var teams: Array[TeamMatchProfile] = [
			_transform(CompetitionCatalog.team_for(
				cell.roster_competition, &"home", variation * 2, balance, cell.level_offset),
				cell, balance),
			_transform(CompetitionCatalog.team_for(
				cell.roster_competition, &"away", variation * 2 + 1, balance, cell.level_offset),
				cell, balance),
		]
		for team in teams:
			for player in team.players:
				total += float(OverallCalculator.current_overall(player.attributes, ratings))
				counted += 1
	return total / float(counted) if counted > 0 else 0.0


## The four cells that separate a rule profile from a roster population.
func _cross_cells(rules: int, rosters: int) -> Array[Cell]:
	var rules_id: String = String(CalibrationTargets.competition_id(rules))
	var rosters_id: String = String(CalibrationTargets.competition_id(rosters))
	return [
		Cell.new("%s_rules_%s_rosters" % [rules_id, rules_id], rules, rules),
		Cell.new("%s_rules_%s_rosters" % [rules_id, rosters_id], rules, rosters),
		Cell.new("%s_rules_%s_rosters" % [rosters_id, rules_id], rosters, rules),
		Cell.new("%s_rules_%s_rosters" % [rosters_id, rosters_id], rosters, rosters),
	] as Array[Cell]


## Applies a cell's diagnostic attribute shift to a freshly built roster.
##
## Returns the roster unchanged when the cell asks for no shift, which is every
## cell in `cross` and `sweep` mode, so those two modes are bit-identical to what
## they measured before this option existed.
##
## Rebuilds rather than mutates. `CompetitionCatalog.team_for` hands back objects
## a later call could still be holding, and a transform that edited them in place
## would leak into whatever else touched the same roster in the same run.
##
## **Diagnostic only.** This is a sensitivity instrument for the owner decision,
## not a proposed implementation: a real distribution change belongs in whatever
## builds rosters, and today nothing does.
func _transform(
	team: TeamMatchProfile,
	cell: Cell,
	balance: SimulationBalanceProfile,
) -> TeamMatchProfile:
	if cell.attribute_keys.is_empty() or is_zero_approx(cell.attribute_offset):
		return team
	var shifted: Array[PlayerMatchProfile] = []
	for player in team.players:
		var values: Array[int] = player.attributes.canonical_values()
		for key in cell.attribute_keys:
			values[key] = clampi(
				int(roundf(float(values[key]) + cell.attribute_offset)),
				Rating.ACTIVE_MINIMUM, Rating.MAXIMUM)
		shifted.append(PlayerMatchProfile.new(
			player.player_id,
			player.positions,
			player.body,
			PlayerAttributes.from_values(values),
			player.badges,
			player.tendencies,
			player.rotation_role,
			player.tactical_role,
			player.condition,
			player.injury_limitations,
			player.qualitative_durability_band))
	return TeamMatchProfile.new(
		team.team_id, shifted, team.starters(), team.chemistry, team.game_plan, balance)


## The attribute subsets a `distribution` cell may shift, named so a report row
## says which distribution it moved rather than listing twenty indices.
static func attribute_subset(name_value: String) -> PackedInt32Array:
	match name_value:
		"shooting":
			return [
				AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.MID_RANGE,
				AttributeKey.Key.THREE_POINT,
			] as PackedInt32Array
		"shooting_and_finishing":
			return [
				AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.MID_RANGE,
				AttributeKey.Key.THREE_POINT, AttributeKey.Key.DUNKING,
			] as PackedInt32Array
		"three_point_only":
			return [AttributeKey.Key.THREE_POINT] as PackedInt32Array
		"all":
			var every := PackedInt32Array()
			for key in range(AttributeKey.COUNT):
				every.append(key)
			return every
		_:
			printerr("unknown attribute subset '%s'; using shooting" % name_value)
			return attribute_subset("shooting")


## One competition's rules, with a named attribute subset shifted and the roster
## level left exactly where the fixture puts it.
func _distribution_cells(
	competition: int,
	subset: String,
	offsets: PackedFloat64Array,
) -> Array[Cell]:
	var id: String = String(CalibrationTargets.competition_id(competition))
	var keys: PackedInt32Array = attribute_subset(subset)
	var cells: Array[Cell] = []
	for offset in offsets:
		cells.append(Cell.new(
			"%s_%s_%+d" % [id, subset, int(roundf(offset))],
			competition, competition, 0.0,
			PackedInt32Array() if is_zero_approx(offset) else keys, offset))
	return cells


## One competition's rules, with its roster level moved by whole rating points.
func _sweep_cells(competition: int, offsets: PackedFloat64Array) -> Array[Cell]:
	var id: String = String(CalibrationTargets.competition_id(competition))
	var cells: Array[Cell] = []
	for offset in offsets:
		cells.append(Cell.new(
			"%s_level_%+d" % [id, int(roundf(offset))], competition, competition, offset))
	return cells


func _offsets(raw: String) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for piece in raw.split(",", false):
		var trimmed: String = piece.strip_edges()
		if trimmed.is_valid_float():
			values.append(trimmed.to_float())
	if values.is_empty():
		values.append(0.0)
	return values


func _competition(name: String) -> int:
	for competition in CalibrationTargets.all_competitions():
		if String(CalibrationTargets.competition_id(competition)) == name:
			return competition
	printerr("unknown competition '%s'; using college" % name)
	return CalibrationTargets.Competition.COLLEGE


## Builds and runs one cell.
##
## The fixture is assembled here rather than through `CompetitionCatalog.
## match_for` because that helper deliberately couples a competition's rules to
## its own rosters, which is exactly the coupling this runner exists to break.
## Everything else — the counterbalanced opening inbound, the balance profile,
## the ratings profile, the home environment — is taken from the catalog
## unchanged, so the only difference between cells is the manipulated factor.
func _simulate(
	cell: Cell,
	games: int,
	base: int,
	decomposition: PppDecomposition,
	terms: ShotTermAccumulator,
	accumulator: MatchMetricAccumulator,
) -> void:
	terms.attach()
	for index in range(games):
		var variation: int = base + index
		var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
		var home: TeamMatchProfile = _transform(CompetitionCatalog.team_for(
			cell.roster_competition, &"home", variation * 2, balance, cell.level_offset),
			cell, balance)
		var away: TeamMatchProfile = _transform(CompetitionCatalog.team_for(
			cell.roster_competition, &"away", variation * 2 + 1, balance, cell.level_offset),
			cell, balance)
		# The match id must **not** carry the cell name.
		#
		# `MatchSession` derives each possession's random stream from
		# `"match:%s:possession:%d" % [match_id, sequence]`, so a match id that
		# varies by cell gives every cell a different draw sequence and destroys
		# the common-random-number pairing this runner exists to provide. An
		# early version of this file named the match after the cell and measured
		# two nominally identical cells 0.0018 apart on pure label noise.
		var input := MatchInput.new(
			StringName("cf_%d" % variation),
			StringName("cf_game_%d" % variation),
			CompetitionCatalog.rules_for(cell.rules_competition),
			balance, home, away,
			CompetitionCatalog.opening_team_id(
				CompetitionCatalog.OPENING_COUNTERBALANCED, variation, home, away),
			CompetitionCatalog.ratings_profile(), 0.5)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(variation + 1))
		decomposition.accumulate(input, output)
		accumulator.accumulate(input, output)
		if (index + 1) % PROGRESS_EVERY == 0:
			print("    %s: %d/%d games, FG%% so far %.4f" % [
				cell.name, index + 1, games,
				decomposition.totals.field_goal_percentage()])
	ShotResolver.detach_probe()
