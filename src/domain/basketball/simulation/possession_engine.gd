class_name PossessionEngine
extends RefCounted


var _candidate_generator := ActionCandidateGenerator.new()
var _action_selector := ActionSelector.new()
var _advantage_resolver := AdvantageResolver.new()
var _turnover_resolver := TurnoverResolver.new()
var _shot_resolver := ShotResolver.new()
var _foul_resolver := FoulResolver.new()
var _rebound_resolver := ReboundResolver.new()


func simulate(snapshot: MatchSnapshot, input: MatchInput, random_source: RandomSource) -> PossessionResult:
	assert(not snapshot.completed, "a completed match cannot resolve another possession")
	assert(snapshot.clock_ms > 0, "a possession cannot begin after period expiration")
	var offense := input.home if snapshot.possession_team_id == input.home.team_id else input.away
	var defense := input.away if offense.team_id == input.home.team_id else input.home
	var offense_state := snapshot.home if offense.team_id == input.home.team_id else snapshot.away
	var defense_state := snapshot.away if defense.team_id == input.away.team_id else snapshot.home
	var participants_stream := random_source.derive(&"participants")
	var offense_players := offense.on_court_profiles()
	var defense_players := defense.on_court_profiles()
	var offensive_player := offense_players[participants_stream.range_int(0, offense_players.size() - 1)]
	var defensive_player := defense_players[participants_stream.range_int(0, defense_players.size() - 1)]
	var offensive_runtime := offense_state.runtime_by_id(offensive_player.player_id)
	var defensive_runtime := defense_state.runtime_by_id(defensive_player.player_id)
	var max_elapsed_seconds := mini(input.rule_profile.shot_clock_seconds, maxi(1, snapshot.clock_ms / 1000))
	var elapsed_seconds := random_source.derive(&"time").range_int(mini(4, max_elapsed_seconds), max_elapsed_seconds)
	var elapsed_ms := mini(snapshot.clock_ms, elapsed_seconds * 1000)
	var event_clock := maxi(0, snapshot.clock_ms - elapsed_ms)
	var events: Array[MatchDomainEvent] = []
	var sequence := snapshot.event_sequence

	sequence += 1
	events.append(MatchDomainEvent.new(
		input.match_id, sequence, snapshot.period, snapshot.clock_ms,
		MatchDomainEvent.POSSESSION_STARTED, offense.team_id, offensive_player.player_id
	))
	var candidates := _candidate_generator.generate(offensive_player, snapshot.clock_ms)
	var selected := _action_selector.select(candidates, random_source.derive(&"action_selection"))
	sequence += 1
	events.append(MatchDomainEvent.new(
		input.match_id, sequence, snapshot.period, snapshot.clock_ms,
		MatchDomainEvent.ACTION_SELECTED, offense.team_id, offensive_player.player_id,
		defensive_player.player_id, selected.action_id
	))
	var advantage := _advantage_resolver.resolve(
		offensive_player, defensive_player, offensive_runtime.acute_fatigue,
		defensive_runtime.acute_fatigue, random_source.derive(&"advantage")
	)
	var turnover := _turnover_resolver.resolve(
		offensive_player, defensive_player, advantage, offensive_runtime.acute_fatigue,
		input.balance_profile, random_source.derive(&"turnover")
	)
	if turnover:
		sequence += 1
		events.append(MatchDomainEvent.new(
			input.match_id, sequence, snapshot.period, event_clock,
			MatchDomainEvent.TURNOVER, offense.team_id, offensive_player.player_id,
			defensive_player.player_id, &"live_ball"
		))
	else:
		var foul := _foul_resolver.resolve(
			offensive_player, defensive_player, advantage, input.balance_profile,
			random_source.derive(&"foul")
		)
		if foul:
			sequence += 1
			events.append(MatchDomainEvent.new(
				input.match_id, sequence, snapshot.period, event_clock,
				MatchDomainEvent.FOUL, defense.team_id, defensive_player.player_id,
				offensive_player.player_id, &"defensive"
			))
		var shot := _shot_resolver.resolve(
			offensive_player, defensive_player, selected.action_id, advantage,
			offensive_runtime.acute_fatigue, defensive_runtime.acute_fatigue,
			input.balance_profile, random_source.derive(&"shot")
		)
		sequence += 1
		events.append(MatchDomainEvent.new(
			input.match_id, sequence, snapshot.period, event_clock,
			MatchDomainEvent.FIELD_GOAL_ATTEMPT, offense.team_id,
			offensive_player.player_id, defensive_player.player_id, selected.action_id
		))
		sequence += 1
		if shot.made:
			events.append(MatchDomainEvent.new(
				input.match_id, sequence, snapshot.period, event_clock,
				MatchDomainEvent.FIELD_GOAL_MADE, offense.team_id,
				offensive_player.player_id, defensive_player.player_id,
				selected.action_id, shot.points
			))
		else:
			events.append(MatchDomainEvent.new(
				input.match_id, sequence, snapshot.period, event_clock,
				MatchDomainEvent.FIELD_GOAL_MISSED, offense.team_id,
				offensive_player.player_id, defensive_player.player_id, selected.action_id
			))
			var rebounder := _rebound_resolver.select_defensive_rebounder(
				defense, random_source.derive(&"rebound")
			)
			sequence += 1
			events.append(MatchDomainEvent.new(
				input.match_id, sequence, snapshot.period, event_clock,
				MatchDomainEvent.REBOUND, defense.team_id, rebounder.player_id,
				offensive_player.player_id, &"defensive"
			))
	sequence += 1
	events.append(MatchDomainEvent.new(
		input.match_id, sequence, snapshot.period, event_clock,
		MatchDomainEvent.POSSESSION_ENDED, defense.team_id
	))
	return PossessionResult.new(events, elapsed_ms, defense.team_id)
