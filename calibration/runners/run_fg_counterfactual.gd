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
## - `sweep` holds one competition's rules and moves the **roster level** by a
##   whole number of rating points. This is the engine's field-goal response to
##   roster strength, measured rather than assumed, and it is what decides
##   whether a level's shortfall is the size its rating gap explains.
##
## Neither mode changes a production value, and this runner tunes nothing.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_fg_counterfactual.gd -- \
##       [--mode=cross|sweep] [--games=N] [--base=SEED_BASE] \
##       [--rules=college] [--rosters=development] [--offsets=0,2,4,6] [--label=NAME]

const DEFAULT_GAMES: int = 200
const DEFAULT_BASE: int = 930000
const PROGRESS_EVERY: int = 50


class Cell:
	extends RefCounted

	var name: String
	var rules_competition: int
	var roster_competition: int
	var level_offset: float

	func _init(
		p_name: String,
		p_rules: int,
		p_rosters: int,
		p_offset: float = 0.0,
	) -> void:
		name = p_name
		rules_competition = p_rules
		roster_competition = p_rosters
		level_offset = p_offset


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

	var cells: Array[Cell] = (
		_cross_cells(_competition(rules_name), _competition(rosters_name))
		if mode == "cross"
		else _sweep_cells(_competition(rules_name), offsets))

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
		print("  %s: FG%% %.4f ±%.4f, capability %.4f, PPP %.4f, poss/game %.2f%s" % [
			cell.name, totals.field_goal_percentage(), half_width,
			terms.mean_shooter_capability(), totals.points_per_possession(),
			totals.possessions_per_game(),
			"" if decomposition.is_reconciled() else "  UNRECONCILED"])

	report.add_section(&"cells", rows)
	report.finish()
	quit(ReportWriter.publish(report, "fg_counterfactual_%s" % label))


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
		var home: TeamMatchProfile = CompetitionCatalog.team_for(
			cell.roster_competition, &"home", variation * 2, balance, cell.level_offset)
		var away: TeamMatchProfile = CompetitionCatalog.team_for(
			cell.roster_competition, &"away", variation * 2 + 1, balance, cell.level_offset)
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
