class_name BuilderDominanceAudit
extends RefCounted

const VERSION: String = "builder-dominance-audit-v1"
const BOX_COUNTS: PackedStringArray = ["seconds_played","points","field_goals_made",
	"field_goals_attempted","three_pointers_made","three_pointers_attempted",
	"free_throws_made","free_throws_attempted","offensive_rebounds","defensive_rebounds",
	"assists","steals","blocks","turnovers","personal_fouls","plus_minus","touches",
	"passes_completed","screens_set","screen_advantages_created","off_ball_actions",
	"advantages_created","created_field_goals_made","paint_attempts","paint_points"]


static func measure(input: MatchInput, output: MatchSimulationOutput,
		subject_id: StringName) -> Dictionary:
	var line: PlayerStatLine = output.final_result.statistics.player_line(subject_id)
	var row: Dictionary = {}
	for key in BOX_COUNTS:
		row[key] = line.get(key)
	row["on_court_offense_possessions"] = 0
	row["on_court_defense_possessions"] = 0
	row["terminal_on_court_offense_possessions"] = 0
	row["terminal_on_court_defense_possessions"] = 0
	row["defended_attempts"] = 0
	row["defended_makes"] = 0
	row["defended_three_makes"] = 0
	row["defended_points"] = 0
	row["defended_contest_bands"] = {}
	row["offense_rebound_events_on_court"] = 0
	row["defense_rebound_events_on_court"] = 0
	var on_court: bool = false
	var starts: int = 0
	var ends: int = 0
	var observed_points: int = 0
	var observed_attempts: int = 0
	var observed_touches: int = 0
	for event in output.events:
		if event.event_type == MatchDomainEvent.CHECK_IN and event.primary_player_id == subject_id:
			on_court = true
		elif event.event_type == MatchDomainEvent.CHECK_OUT and event.primary_player_id == subject_id:
			on_court = false
		elif event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			starts += 1
			if on_court:
				var key: String = "on_court_offense_possessions" if event.team_id == line.team_id else "on_court_defense_possessions"
				row[key] += 1
			if event.primary_player_id == subject_id:
				observed_touches += 1
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			ends += 1
			if on_court:
				var key: String = "terminal_on_court_offense_possessions" if event.team_id == line.team_id else "terminal_on_court_defense_possessions"
				row[key] += 1
		elif event.event_type == MatchDomainEvent.PASS_COMPLETED and event.secondary_player_id == subject_id:
			observed_touches += 1
		elif event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			if event.primary_player_id == subject_id:
				observed_attempts += 1
			if event.secondary_player_id == subject_id:
				row["defended_attempts"] += 1
				var bands: Dictionary = row["defended_contest_bands"]
				bands[String(event.detail_id)] = (bands.get(String(event.detail_id),0) as int) + 1
		elif event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
			if event.primary_player_id == subject_id:
				observed_points += event.points
			if event.secondary_player_id == subject_id:
				row["defended_makes"] += 1
				row["defended_points"] += event.points
				if event.points == 3:
					row["defended_three_makes"] += 1
		elif event.event_type == MatchDomainEvent.FREE_THROW_MADE and event.primary_player_id == subject_id:
			observed_points += 1
		elif event.event_type == MatchDomainEvent.REBOUND and on_court:
			var rebound_team_is_subject: bool = event.team_id == line.team_id
			var offensive: bool = event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE
			var subject_was_offense: bool = rebound_team_is_subject == offensive
			var key: String = "offense_rebound_events_on_court" if subject_was_offense else "defense_rebound_events_on_court"
			row[key] += 1
	row["team_points"] = output.final_result.statistics.team_line(line.team_id).points
	row["opponent_points"] = output.final_result.statistics.team_line(input.opposing_team_id(line.team_id)).points
	row["team_possessions"] = output.engine_possessions(line.team_id)
	row["opponent_possessions"] = output.engine_possessions(input.opposing_team_id(line.team_id))
	row["team_margin"] = row["team_points"] - row["opponent_points"]
	row["team_win"] = 1 if row["team_margin"] > 0 else 0
	row["overtime_periods"] = output.final_result.overtime_periods
	row["possession_records"] = output.possessions.size()
	row["possession_starts"] = starts
	row["possession_ends"] = ends
	row["ledger_points"] = observed_points
	row["ledger_attempts"] = observed_attempts
	row["ledger_touches"] = observed_touches
	row["ledger_sha256"] = output.signature().sha256_text()
	row["reconciliation_errors"] = output.final_result.statistics.reconcile()
	row["errors"] = row_errors(row)
	return row


static func row_errors(row: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key: String in row:
		if key in ["plus_minus","team_margin"]:
			continue
		var value: Variant = row[key]
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			var numeric: float = value as float
			if not is_finite(numeric) or numeric < 0.0 or numeric != floorf(numeric):
				errors.append("nonnegative finite integer count: %s" % key)
	if not errors.is_empty():
		return errors
	if row["possession_starts"] != row["possession_records"] or row["possession_ends"] != row["possession_records"]:
		errors.append("possession denominator reconciliation")
	if row["ledger_points"] != row["points"] or row["ledger_attempts"] != row["field_goals_attempted"] \
			or row["ledger_touches"] != row["touches"]:
		errors.append("player ledger reconciliation")
	if not (row["reconciliation_errors"] as PackedStringArray).is_empty():
		errors.append("box-score reconciliation")
	if row["defended_makes"] > row["defended_attempts"] or row["defended_three_makes"] > row["defended_makes"]:
		errors.append("defended shot denominator")
	if row["on_court_offense_possessions"] > row["team_possessions"] \
			or row["on_court_defense_possessions"] > row["opponent_possessions"]:
		errors.append("on-court possession exposure")
	if row["seconds_played"] <= 0 or row["touches"] <= 0:
		errors.append("missing minutes/touches opportunity")
	if row["points"] != 2 * (row["field_goals_made"] - row["three_pointers_made"]) \
			+ 3 * row["three_pointers_made"] + row["free_throws_made"]:
		errors.append("player scoring identity")
	return errors


static func schedule_errors(rows: Array[Dictionary]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seeds: Dictionary = {}
	var phases: Dictionary = {}
	for row in rows:
		if seeds.has(row["seed"]):
			errors.append("duplicate simulation seed within build")
		seeds[row["seed"]] = true
		phases[row["phase"]] = true
		var phase: int = row["phase"]
		if row["home_subject"] != (phase == 0 or phase == 3) or row["subject_opens"] != (phase < 2):
			errors.append("venue/opener quartet balance")
	if rows.size() != 4 or phases.size() != 4:
		errors.append("incomplete quartet")
	return errors
