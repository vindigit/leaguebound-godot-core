class_name ClockResolver
extends RefCounted

## Time consumption per state transition (`SIMULATION_SPEC.md` §9.4).
##
## "Each state transition consumes time from a bounded distribution defined by
## action, pace, game plan, pressure, and rules. Time is never negative and the
## engine cannot begin a new action after the period expires."
##
## Pace is a real input rather than a constant: the offence's tempo instruction
## and its ball handler's Push Transition ↔ Control Tempo slider stretch or
## compress the band, which is what makes a patient team consume more clock per
## possession without changing anyone's ratings.

var _balance: SimulationBalanceProfile


func _init(p_balance: SimulationBalanceProfile) -> void:
	_balance = p_balance


func inbound_ms(random_source: RandomSource) -> int:
	return _draw(_balance.inbound_seconds_min, _balance.inbound_seconds_max, 1.0, random_source)


func advance_ms(context: PossessionContext, random_source: RandomSource) -> int:
	return _draw(
		_balance.advance_seconds_min, _balance.advance_seconds_max,
		_pace(context), random_source)


func transition_ms(context: PossessionContext, random_source: RandomSource) -> int:
	return _draw(
		_balance.transition_seconds_min, _balance.transition_seconds_max,
		_pace(context), random_source)


func half_court_entry_ms(context: PossessionContext, random_source: RandomSource) -> int:
	return _draw(
		_balance.half_court_entry_seconds_min, _balance.half_court_entry_seconds_max,
		_pace(context), random_source)


func action_ms(context: PossessionContext, action_family: int, random_source: RandomSource) -> int:
	match action_family:
		ActionFamily.Value.RESET:
			return _draw(
				_balance.reset_seconds_min, _balance.reset_seconds_max,
				_pace(context), random_source)
		ActionFamily.Value.POST_ACTION:
			return _draw(
				_balance.post_action_seconds_min, _balance.post_action_seconds_max,
				_pace(context), random_source)
		ActionFamily.Value.TRANSITION_ATTACK:
			return _draw(
				_balance.transition_seconds_min, _balance.transition_seconds_max,
				_pace(context), random_source)
		_:
			return _draw(
				_balance.action_seconds_min, _balance.action_seconds_max,
				_pace(context), random_source)


func rebound_ms(random_source: RandomSource) -> int:
	return _draw(_balance.rebound_seconds_min, _balance.rebound_seconds_max, 1.0, random_source)


## §9.4: "Dead-ball fouls and free throws use separate event time without
## incorrectly consuming shot-clock time." The possession engine restores the
## shot clock explicitly around these.
func free_throw_ms() -> int:
	return _balance.free_throw_event_seconds * 1000


func dead_ball_ms() -> int:
	return _balance.dead_ball_event_seconds * 1000


## A pace multiplier around 1.0: below one is quicker, above one is slower.
func _pace(context: PossessionContext) -> float:
	var coach: float = _balance.opposing_tendency_multiplier(
		context.offense.game_plan.tempo_instruction)
	var player: float = 1.0
	if not context.ball_handler_id.is_empty():
		var handler: PlayerMatchProfile = context.offense_profile(context.ball_handler_id)
		player = _balance.tendency_multiplier(
			handler.tendencies.at(TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO))
	return clampf(
		pow(coach, _balance.coach_preference_share) * pow(player, _balance.player_preference_share),
		0.70,
		1.40)


func _draw(
	minimum_seconds: int,
	maximum_seconds: int,
	pace: float,
	random_source: RandomSource,
) -> int:
	assert(minimum_seconds >= 0 and maximum_seconds >= minimum_seconds,
		"a time band must be non-negative and ordered")
	var seconds: int = random_source.range_int(minimum_seconds, maximum_seconds)
	return maxi(0, int(roundf(float(seconds) * 1000.0 * pace)))
