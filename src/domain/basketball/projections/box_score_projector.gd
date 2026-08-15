class_name BoxScoreProjector
extends RefCounted


func project(input: MatchInput, events: Array[MatchDomainEvent]) -> MatchStatistics:
	var player_lines: Array[PlayerStatLine] = []
	var team_lines: Array[TeamStatLine] = [
		TeamStatLine.new(input.home.team_id),
		TeamStatLine.new(input.away.team_id),
	]
	for player in input.home.players:
		player_lines.append(PlayerStatLine.new(player.player_id, input.home.team_id))
	for player in input.away.players:
		player_lines.append(PlayerStatLine.new(player.player_id, input.away.team_id))
	var statistics := MatchStatistics.new(player_lines, team_lines)
	for event in events:
		var player_line: PlayerStatLine
		var team_line: TeamStatLine
		if not event.primary_player_id.is_empty():
			player_line = statistics.player_line(event.primary_player_id)
		if not event.team_id.is_empty():
			team_line = statistics.team_line(event.team_id)
		match event.event_type:
			MatchDomainEvent.FIELD_GOAL_ATTEMPT:
				player_line.field_goals_attempted += 1
				team_line.field_goals_attempted += 1
				if event.action_id == &"shot_three":
					player_line.three_pointers_attempted += 1
					team_line.three_pointers_attempted += 1
			MatchDomainEvent.FIELD_GOAL_MADE:
				player_line.points += event.points
				player_line.field_goals_made += 1
				team_line.points += event.points
				team_line.field_goals_made += 1
				if event.action_id == &"shot_three":
					player_line.three_pointers_made += 1
					team_line.three_pointers_made += 1
			MatchDomainEvent.TURNOVER:
				player_line.turnovers += 1
				team_line.turnovers += 1
			MatchDomainEvent.REBOUND:
				if event.action_id == &"defensive":
					player_line.defensive_rebounds += 1
					team_line.defensive_rebounds += 1
				else:
					player_line.offensive_rebounds += 1
					team_line.offensive_rebounds += 1
			MatchDomainEvent.FOUL:
				player_line.personal_fouls += 1
	return statistics
