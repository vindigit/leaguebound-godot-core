class_name BoxScoreProjector
extends RefCounted

## Projects the ordered ledger into the box score (`SIMULATION_SPEC.md` §24.3).
##
## "Every official statistic derives from an ordered domain event with unique
## sequence ID." That includes the two statistics engines usually smuggle in
## through a side channel:
##
## - **Minutes played** are reconstructed from `CHECK_IN` / `CHECK_OUT` pairs
##   and the events' own timestamps, not from a counter the reducer maintains.
## - **Plus/minus** is reconstructed from who was on court when each scoring
##   event was applied.
##
## If a substitution never reached the ledger, the minutes are wrong here, and
## the reconciliation tests fail. That is the point.

var _absolute_period_offsets: Array[int] = []


func project(
	input: MatchInput,
	events: Array[MatchDomainEvent],
	possessions: Array[PossessionRecord] = [],
) -> MatchStatistics:
	var player_lines: Array[PlayerStatLine] = []
	for player in input.home.players:
		player_lines.append(PlayerStatLine.new(player.player_id, input.home.team_id))
	for player in input.away.players:
		player_lines.append(PlayerStatLine.new(player.player_id, input.away.team_id))
	var team_lines: Array[TeamStatLine] = [
		TeamStatLine.new(input.home.team_id),
		TeamStatLine.new(input.away.team_id),
	]
	var statistics := MatchStatistics.new(player_lines, team_lines)

	# Live projection state. `on_court` maps a player to the absolute
	# millisecond at which his current stint began.
	var on_court: Dictionary = {}
	var team_of: Dictionary = {}
	for player in input.home.players:
		team_of[player.player_id] = input.home.team_id
	for player in input.away.players:
		team_of[player.player_id] = input.away.team_id
	var period_team_fouls: Dictionary = {
		input.home.team_id: 0,
		input.away.team_id: 0,
	}
	var bonus_reached: Dictionary = {
		input.home.team_id: false,
		input.away.team_id: false,
	}
	var running_score: Dictionary = {
		input.home.team_id: 0,
		input.away.team_id: 0,
	}
	var last_leader: StringName = &""
	var offensive_rebounds_in_possession: int = 0

	for event in events:
		var absolute_ms: int = _absolute_ms(input, event.period, event.clock_ms)
		match event.event_type:
			MatchDomainEvent.PERIOD_STARTED:
				_ensure_period(statistics, input, event.period)
				if input.rule_profile.team_fouls_reset_each_period:
					period_team_fouls[input.home.team_id] = 0
					period_team_fouls[input.away.team_id] = 0
					bonus_reached[input.home.team_id] = false
					bonus_reached[input.away.team_id] = false
			MatchDomainEvent.CHECK_IN:
				on_court[event.primary_player_id] = absolute_ms
				if event.period == 1 and event.clock_ms == input.rule_profile.period_length_ms(1):
					statistics.player_line(event.primary_player_id).started = true
			MatchDomainEvent.CHECK_OUT:
				_close_stint(statistics, on_court, event.primary_player_id, absolute_ms)
			MatchDomainEvent.MATCH_ENDED:
				for player_id: StringName in on_court.keys():
					_close_stint_at(statistics, on_court, player_id, absolute_ms)
				on_court.clear()
			MatchDomainEvent.POSSESSION_STARTED:
				offensive_rebounds_in_possession = 0
				if not event.primary_player_id.is_empty():
					statistics.player_line(event.primary_player_id).touches += 1
			MatchDomainEvent.POSSESSION_ENDED:
				statistics.team_line(event.team_id).engine_possessions += 1
			MatchDomainEvent.PASS_COMPLETED:
				statistics.player_line(event.primary_player_id).passes_completed += 1
				if not event.secondary_player_id.is_empty():
					statistics.player_line(event.secondary_player_id).touches += 1
			MatchDomainEvent.SCREEN_SET:
				var screener: PlayerStatLine = statistics.player_line(event.primary_player_id)
				screener.screens_set += 1
				if event.detail_id != AdvantageLevel.id_of(AdvantageLevel.Value.NONE):
					screener.screen_advantages_created += 1
			MatchDomainEvent.OFF_BALL_ACTION:
				statistics.player_line(event.primary_player_id).off_ball_actions += 1
			MatchDomainEvent.ADVANTAGE_CREATED:
				statistics.player_line(event.primary_player_id).advantages_created += 1
			MatchDomainEvent.FIELD_GOAL_ATTEMPT:
				_apply_attempt(statistics, event)
			MatchDomainEvent.FIELD_GOAL_MADE:
				_apply_make(statistics, event, offensive_rebounds_in_possession)
				_apply_score(
					statistics, on_court, team_of, running_score, event.team_id, event.points)
				last_leader = _apply_lead_tracking(
					statistics, input, running_score, last_leader)
			MatchDomainEvent.FIELD_GOAL_MISSED:
				pass
			MatchDomainEvent.BLOCK:
				statistics.player_line(event.primary_player_id).blocks += 1
				statistics.team_line(event.team_id).blocks += 1
			MatchDomainEvent.ASSIST:
				statistics.player_line(event.primary_player_id).assists += 1
				statistics.team_line(event.team_id).assists += 1
			MatchDomainEvent.TURNOVER:
				statistics.player_line(event.primary_player_id).turnovers += 1
				statistics.team_line(event.team_id).turnovers += 1
			MatchDomainEvent.STEAL:
				statistics.player_line(event.primary_player_id).steals += 1
				statistics.team_line(event.team_id).steals += 1
			MatchDomainEvent.FOUL:
				_apply_foul(
					statistics, input, event, period_team_fouls, bonus_reached)
			MatchDomainEvent.FOUL_OUT:
				statistics.player_line(event.primary_player_id).fouled_out = true
			MatchDomainEvent.FREE_THROW_AWARDED:
				pass
			MatchDomainEvent.FREE_THROW_MADE:
				var made_line: PlayerStatLine = statistics.player_line(event.primary_player_id)
				made_line.free_throws_made += 1
				made_line.free_throws_attempted += 1
				made_line.points += 1
				var made_team: TeamStatLine = statistics.team_line(event.team_id)
				made_team.free_throws_made += 1
				made_team.free_throws_attempted += 1
				made_team.points += 1
				_add_period_score(statistics, event.team_id, event.period, 1)
				_apply_score(statistics, on_court, team_of, running_score, event.team_id, 1)
				last_leader = _apply_lead_tracking(
					statistics, input, running_score, last_leader)
			MatchDomainEvent.FREE_THROW_MISSED:
				statistics.player_line(event.primary_player_id).free_throws_attempted += 1
				statistics.team_line(event.team_id).free_throws_attempted += 1
			MatchDomainEvent.REBOUND:
				var rebound_line: PlayerStatLine = statistics.player_line(event.primary_player_id)
				var rebound_team: TeamStatLine = statistics.team_line(event.team_id)
				if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
					rebound_line.offensive_rebounds += 1
					rebound_team.offensive_rebounds += 1
					offensive_rebounds_in_possession += 1
				else:
					rebound_line.defensive_rebounds += 1
					rebound_team.defensive_rebounds += 1
			_:
				pass

	_finalize(statistics, input, possessions)
	return statistics


# --- event application ------------------------------------------------------

func _apply_attempt(statistics: MatchStatistics, event: MatchDomainEvent) -> void:
	var line: PlayerStatLine = statistics.player_line(event.primary_player_id)
	var team: TeamStatLine = statistics.team_line(event.team_id)
	line.field_goals_attempted += 1
	team.field_goals_attempted += 1
	var zone: int = ShotZone.from_id(event.zone_id)
	if ShotZone.is_three(zone):
		line.three_pointers_attempted += 1
		team.three_pointers_attempted += 1
	if ShotZone.is_paint(zone):
		line.paint_attempts += 1
		team.paint_attempts += 1
	if event.amount == 1:
		line.dunk_attempts += 1


func _apply_make(
	statistics: MatchStatistics,
	event: MatchDomainEvent,
	offensive_rebounds_in_possession: int,
) -> void:
	var line: PlayerStatLine = statistics.player_line(event.primary_player_id)
	var team: TeamStatLine = statistics.team_line(event.team_id)
	var zone: int = ShotZone.from_id(event.zone_id)
	# §11.3: the creator the attempt was made with, recorded on the event. This
	# is the §14.3 conditional's denominator and it is projected here so the box
	# score carries it; an assist is only ever credited against one of these.
	if not event.tertiary_player_id.is_empty():
		team.assisted_field_goals_made += 1
		statistics.player_line(event.tertiary_player_id).created_field_goals_made += 1
		line.assisted_field_goals_made += 1
	line.field_goals_made += 1
	line.points += event.points
	team.field_goals_made += 1
	team.points += event.points
	if ShotZone.is_three(zone):
		line.three_pointers_made += 1
		team.three_pointers_made += 1
	if ShotZone.is_paint(zone):
		line.paint_points += event.points
		team.paint_points += event.points
	if event.amount == 1:
		line.dunks_made += 1
	if event.action_id == ActionFamily.id_of(ActionFamily.Value.TRANSITION_ATTACK):
		team.transition_points += event.points
	if offensive_rebounds_in_possession > 0:
		team.second_chance_points += event.points
	_add_period_score(statistics, event.team_id, event.period, event.points)


func _apply_foul(
	statistics: MatchStatistics,
	input: MatchInput,
	event: MatchDomainEvent,
	period_team_fouls: Dictionary,
	bonus_reached: Dictionary,
) -> void:
	statistics.player_line(event.primary_player_id).personal_fouls += 1
	var team: TeamStatLine = statistics.team_line(event.team_id)
	team.personal_fouls += 1
	if not FoulType.advances_team_fouls(FoulType.from_id(event.detail_id)):
		return
	team.team_fouls += 1
	var running: int = period_team_fouls[event.team_id]
	running += 1
	period_team_fouls[event.team_id] = running
	var already: bool = bonus_reached[event.team_id]
	if not already and running >= input.rule_profile.team_foul_bonus_threshold:
		bonus_reached[event.team_id] = true
		team.periods_in_bonus += 1


func _apply_score(
	statistics: MatchStatistics,
	on_court: Dictionary,
	team_of: Dictionary,
	running_score: Dictionary,
	team_id: StringName,
	points: int,
) -> void:
	var current: int = running_score[team_id]
	running_score[team_id] = current + points
	for player_id: StringName in on_court.keys():
		var line: PlayerStatLine = statistics.player_line(player_id)
		var owner_id: StringName = team_of[player_id]
		line.plus_minus += points if owner_id == team_id else -points


## §24.2 lead changes, ties, and largest lead.
func _apply_lead_tracking(
	statistics: MatchStatistics,
	input: MatchInput,
	running_score: Dictionary,
	last_leader: StringName,
) -> StringName:
	var home_points: int = running_score[input.home.team_id]
	var away_points: int = running_score[input.away.team_id]
	var home_line: TeamStatLine = statistics.team_line(input.home.team_id)
	var away_line: TeamStatLine = statistics.team_line(input.away.team_id)
	home_line.largest_lead = maxi(home_line.largest_lead, home_points - away_points)
	away_line.largest_lead = maxi(away_line.largest_lead, away_points - home_points)
	var leader: StringName = &""
	if home_points > away_points:
		leader = input.home.team_id
	elif away_points > home_points:
		leader = input.away.team_id
	if leader.is_empty():
		if not last_leader.is_empty():
			home_line.ties += 1
			away_line.ties += 1
		return leader
	if not last_leader.is_empty() and leader != last_leader:
		home_line.lead_changes += 1
		away_line.lead_changes += 1
	return leader


# --- minutes ----------------------------------------------------------------

func _close_stint(
	statistics: MatchStatistics,
	on_court: Dictionary,
	player_id: StringName,
	absolute_ms: int,
) -> void:
	_close_stint_at(statistics, on_court, player_id, absolute_ms)
	on_court.erase(player_id)


func _close_stint_at(
	statistics: MatchStatistics,
	on_court: Dictionary,
	player_id: StringName,
	absolute_ms: int,
) -> void:
	if not on_court.has(player_id):
		return
	var entered_ms: int = on_court[player_id]
	var line: PlayerStatLine = statistics.player_line(player_id)
	line.seconds_played += maxi(0, absolute_ms - entered_ms) / 1000


## Absolute elapsed milliseconds for a `(period, clock)` pair. Overtime periods
## use their own length, which is why this reads the rule profile rather than
## multiplying by a single period constant.
func _absolute_ms(input: MatchInput, period: int, clock_ms: int) -> int:
	var total: int = 0
	for index in range(1, period):
		total += input.rule_profile.period_length_ms(index)
	return total + (input.rule_profile.period_length_ms(period) - clock_ms)


# --- finalization -----------------------------------------------------------

func _ensure_period(statistics: MatchStatistics, input: MatchInput, period: int) -> void:
	for team in statistics.teams:
		while team.period_scores.size() < period:
			team.period_scores.append(0)


func _add_period_score(
	statistics: MatchStatistics,
	team_id: StringName,
	period: int,
	points: int,
) -> void:
	var team: TeamStatLine = statistics.team_line(team_id)
	while team.period_scores.size() < period:
		team.period_scores.append(0)
	team.period_scores[period - 1] += points


func _finalize(
	statistics: MatchStatistics,
	input: MatchInput,
	possessions: Array[PossessionRecord],
) -> void:
	var weight: float = input.balance_profile.possession_estimate_free_throw_weight
	for team in statistics.teams:
		team.possession_estimate = (
			float(team.field_goals_attempted)
			+ weight * float(team.free_throws_attempted)
			- float(team.offensive_rebounds)
			+ float(team.turnovers)
		)
		team.bonus_free_throws_awarded = team.free_throws_attempted
	if possessions.is_empty():
		return
	# When the terminal records are supplied they are the authority; the count
	# derived from `POSSESSION_ENDED` events must agree with them exactly.
	var counted: Dictionary = {}
	for record in possessions:
		var current: int = counted.get(record.offense_team_id, 0)
		counted[record.offense_team_id] = current + 1
	for team in statistics.teams:
		var expected: int = counted.get(team.team_id, 0)
		assert(team.engine_possessions == expected,
			"engine possessions must agree with the terminal possession records")
