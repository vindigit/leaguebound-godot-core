class_name MatchEngine
extends RefCounted


const MAX_POSSESSIONS: int = 2000

var _possession_engine := PossessionEngine.new()
var _state_reducer := MatchStateReducer.new()
var _period_controller := PeriodController.new()
var _rotation_resolver := RotationResolver.new()
var _box_score_projector := BoxScoreProjector.new()


func simulate_match(input: MatchInput, random_source: RandomSource) -> MatchSimulationOutput:
	assert(input != null, "match input is required")
	assert(random_source != null, "an injected random source is required")
	var snapshot := MatchSnapshot.new(input)
	var ledger := EventLedger.new()
	while not snapshot.completed:
		_rotation_resolver.apply_and_validate(snapshot, input)
		if snapshot.clock_ms <= 0:
			snapshot = _period_controller.advance_if_needed(snapshot, input.rule_profile)
			continue
		assert(snapshot.possession_sequence < MAX_POSSESSIONS, "match exceeded the possession safety bound")
		var stream_label := StringName("match:%s:possession:%d" % [
			input.match_id,
			snapshot.possession_sequence,
		])
		var possession := _possession_engine.simulate(
			snapshot,
			input,
			random_source.derive(stream_label)
		)
		ledger.append_all(possession.events)
		snapshot = _state_reducer.apply(snapshot, input, possession)
		snapshot = _period_controller.advance_if_needed(snapshot, input.rule_profile)
	var statistics := _box_score_projector.project(input, ledger.events)
	assert(statistics.team_line(input.home.team_id).points == snapshot.home.score, "home box score does not reconcile")
	assert(statistics.team_line(input.away.team_id).points == snapshot.away.score, "away box score does not reconcile")
	var result := MatchFinalResult.new(
		input.match_id,
		input.game_id,
		input.rule_profile.profile_id,
		input.rule_profile.version,
		input.balance_profile.profile_id,
		input.balance_profile.version,
		input.home.team_id,
		input.away.team_id,
		snapshot.home.score,
		snapshot.away.score,
		snapshot.overtime_periods,
		statistics,
		snapshot.event_sequence,
	)
	return MatchSimulationOutput.new(result, ledger.events)
