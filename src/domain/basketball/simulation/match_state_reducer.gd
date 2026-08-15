class_name MatchStateReducer
extends RefCounted


var _fatigue_resolver := FatigueResolver.new()


func apply(snapshot: MatchSnapshot, input: MatchInput, possession: PossessionResult) -> MatchSnapshot:
	var next := snapshot.copy()
	next.clock_ms = maxi(0, next.clock_ms - possession.elapsed_ms)
	next.possession_sequence += 1
	next.possession_team_id = possession.next_possession_team_id
	for event in possession.events:
		assert(event.sequence == next.event_sequence + 1, "event application must be exactly once and ordered")
		next.event_sequence = event.sequence
		if event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
			if event.team_id == next.home.team_id:
				next.home.score += event.points
			else:
				assert(event.team_id == next.away.team_id, "score event belongs to neither team")
				next.away.score += event.points
		elif event.event_type == MatchDomainEvent.FOUL:
			var team_state := next.home if event.team_id == next.home.team_id else next.away
			team_state.team_fouls += 1
			team_state.runtime_by_id(event.primary_player_id).foul_count += 1
		elif event.event_type == MatchDomainEvent.TURNOVER:
			var turnover_state := next.home if event.team_id == next.home.team_id else next.away
			turnover_state.runtime_by_id(event.primary_player_id).usage_events += 1
	_fatigue_resolver.apply(next, input, possession.elapsed_ms)
	return next
