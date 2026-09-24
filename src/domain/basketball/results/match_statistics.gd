class_name MatchStatistics
extends RefCounted

## The materialized box-score projection (`SIMULATION_SPEC.md` §24.3).
##
## "The box score is a materialized projection of events and is reconciled at
## match completion."
##
## Lookup is through explicit indexed maps rather than a linear scan: a full
## game reaches five figures of event applications, and a scan per event turns
## projection into the slowest part of the engine. The ordered ledger remains
## the authority; these maps are a read index over it and are built once.

var players: Array[PlayerStatLine]
var teams: Array[TeamStatLine]
var _player_index: Dictionary
var _team_index: Dictionary


func _init(p_players: Array[PlayerStatLine] = [], p_teams: Array[TeamStatLine] = []) -> void:
	players = p_players.duplicate()
	teams = p_teams.duplicate()
	_player_index = {}
	_team_index = {}
	for line in players:
		_player_index[line.player_id] = line
	for line in teams:
		_team_index[line.team_id] = line


func player_line(player_id: StringName) -> PlayerStatLine:
	assert(_player_index.has(player_id), "missing player stat line")
	var line: PlayerStatLine = _player_index[player_id]
	return line


func has_player(player_id: StringName) -> bool:
	return _player_index.has(player_id)


func team_line(team_id: StringName) -> TeamStatLine:
	assert(_team_index.has(team_id), "missing team stat line")
	var line: TeamStatLine = _team_index[team_id]
	return line


func has_team(team_id: StringName) -> bool:
	return _team_index.has(team_id)


func players_for(team_id: StringName) -> Array[PlayerStatLine]:
	var result: Array[PlayerStatLine] = []
	for line in players:
		if line.team_id == team_id:
			result.append(line)
	return result


## Reconciliation: every team total is the sum of its players' lines, and every
## line's points equal the shots that produced them. §14.2 sets the shipping
## tolerance for an unreconciled box score at zero, so this returns the
## failures rather than a bare bool.
func reconcile() -> PackedStringArray:
	var failures: PackedStringArray = []
	for line in players:
		if not line.points_reconcile():
			failures.append("player %s points do not match his shots" % line.player_id)
	for team in teams:
		if not team.points_reconcile():
			failures.append("team %s points do not match its shots" % team.team_id)
		var totals := TeamStatLine.new(team.team_id)
		for line in players_for(team.team_id):
			totals.points += line.points
			totals.field_goals_made += line.field_goals_made
			totals.field_goals_attempted += line.field_goals_attempted
			totals.three_pointers_made += line.three_pointers_made
			totals.three_pointers_attempted += line.three_pointers_attempted
			totals.free_throws_made += line.free_throws_made
			totals.free_throws_attempted += line.free_throws_attempted
			totals.offensive_rebounds += line.offensive_rebounds
			totals.defensive_rebounds += line.defensive_rebounds
			totals.assists += line.assists
			totals.assisted_field_goals_made += line.assisted_field_goals_made
			totals.steals += line.steals
			totals.blocks += line.blocks
			totals.turnovers += line.turnovers
			totals.personal_fouls += line.personal_fouls
		_require(failures, team.team_id, "points", team.points, totals.points)
		_require(failures, team.team_id, "field goals made", team.field_goals_made, totals.field_goals_made)
		_require(failures, team.team_id, "field goals attempted", team.field_goals_attempted, totals.field_goals_attempted)
		_require(failures, team.team_id, "three pointers made", team.three_pointers_made, totals.three_pointers_made)
		_require(failures, team.team_id, "three pointers attempted", team.three_pointers_attempted, totals.three_pointers_attempted)
		_require(failures, team.team_id, "free throws made", team.free_throws_made, totals.free_throws_made)
		_require(failures, team.team_id, "free throws attempted", team.free_throws_attempted, totals.free_throws_attempted)
		_require(failures, team.team_id, "offensive rebounds", team.offensive_rebounds, totals.offensive_rebounds)
		_require(failures, team.team_id, "defensive rebounds", team.defensive_rebounds, totals.defensive_rebounds)
		_require(failures, team.team_id, "assists", team.assists, totals.assists)
		_require(failures, team.team_id, "assisted field goals made",
			team.assisted_field_goals_made, totals.assisted_field_goals_made)
		# §11.3: a made field goal has at most one assister, and only a make
		# carrying a recorded creator can have one at all.
		if team.assists > team.assisted_field_goals_made:
			failures.append(
				"team %s has %d assists against %d made field goals with a recorded creator"
					% [team.team_id, team.assists, team.assisted_field_goals_made])
		_require(failures, team.team_id, "steals", team.steals, totals.steals)
		_require(failures, team.team_id, "blocks", team.blocks, totals.blocks)
		_require(failures, team.team_id, "turnovers", team.turnovers, totals.turnovers)
		_require(failures, team.team_id, "personal fouls", team.personal_fouls, totals.personal_fouls)
	return failures


func _require(
	failures: PackedStringArray,
	team_id: StringName,
	label: String,
	team_total: int,
	player_total: int,
) -> void:
	if team_total != player_total:
		failures.append("team %s %s (%d) does not equal its players (%d)" % [
			team_id, label, team_total, player_total])


func signature() -> String:
	var parts: PackedStringArray = []
	for team in teams:
		parts.append(team.signature())
	for player in players:
		parts.append(player.signature())
	return "|".join(parts)
