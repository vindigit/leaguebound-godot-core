class_name RotationResolver
extends RefCounted

## Planned rotation plus bounded contextual adjustment (`SIMULATION_SPEC.md`
## §18.1, §18.2).
##
## The plan is stable by design. §18.2: "The engine does not recalculate optimal
## rotations from scratch every possession. Stability is part of coaching
## identity." Only the six listed pressures move it — foul trouble, acute
## fatigue, injury, score and time, matchup and tactical need, and overtime.
##
## Two invariants are enforced rather than assumed:
##
## - Exactly five eligible players per team are on court (§5.1).
## - A player who has fouled out, been ejected, or become medically unavailable
##   cannot re-enter (§5.1). His rotation role is untouched: §10.6.1 is explicit
##   that "A Starter who does not play remains a Starter."

var _balance: SimulationBalanceProfile


func _init(p_balance: SimulationBalanceProfile) -> void:
	_balance = p_balance


## The substitutions this team needs right now, mandatory ones first.
func plan(
	state: MatchSnapshot,
	input: MatchInput,
	team_id: StringName,
) -> Array[SubstitutionOrder]:
	var profile: TeamMatchProfile = input.team_profile(team_id)
	var team_state: TeamMatchState = state.state_for(team_id)
	var orders: Array[SubstitutionOrder] = []
	var claimed: Array[StringName] = []
	var leaving: Array[StringName] = []

	for player_id in team_state.on_court_ids():
		var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player_id)
		var reason: int = _departure_reason(state, input, profile, team_state, runtime)
		if reason < 0:
			continue
		var incoming_id: StringName = _select_incoming(
			state, input, profile, team_state, claimed, reason)
		if incoming_id.is_empty():
			# No legal replacement exists. A mandatory departure still has to
			# happen — the lineup validity assertion will surface a roster that
			# upstream services should never have supplied.
			assert(
				reason != SubstitutionOrder.Reason.FOULED_OUT
				and reason != SubstitutionOrder.Reason.UNAVAILABLE,
				"no eligible replacement exists for a mandatory substitution"
			)
			continue
		claimed.append(incoming_id)
		leaving.append(player_id)
		orders.append(SubstitutionOrder.new(player_id, incoming_id, reason))
	return orders


## Validates the §5.1 lineup invariants after the orders have been applied.
func validate(state: MatchSnapshot, input: MatchInput) -> void:
	_validate_team(state.home, input.home, input.rule_profile)
	_validate_team(state.away, input.away, input.rule_profile)


func _validate_team(
	team_state: TeamMatchState,
	profile: TeamMatchProfile,
	rules: CompetitionRuleProfile,
) -> void:
	var on_court: int = 0
	for runtime in team_state.runtimes:
		if not runtime.on_court:
			continue
		on_court += 1
		assert(runtime.is_eligible_to_play(),
			"a fouled-out, ejected, or unavailable player cannot remain on court")
		assert(runtime.foul_count < rules.personal_foul_limit,
			"a player at the personal foul limit cannot remain on court")
		assert(profile.player_by_id(runtime.player_id).is_available(),
			"an unavailable player cannot be on court")
	assert(on_court == 5, "exactly five eligible players per team must be on court")


## Why this player comes off, or -1 to leave him in. Ordered by force: the two
## mandatory reasons are checked before any coaching preference.
func _departure_reason(
	state: MatchSnapshot,
	input: MatchInput,
	profile: TeamMatchProfile,
	team_state: TeamMatchState,
	runtime: PlayerMatchRuntime,
) -> int:
	var player: PlayerMatchProfile = profile.player_by_id(runtime.player_id)
	if runtime.fouled_out or runtime.ejected:
		return SubstitutionOrder.Reason.FOULED_OUT
	if not runtime.medically_available or not player.is_available():
		return SubstitutionOrder.Reason.UNAVAILABLE
	if not _has_available_bench(team_state):
		return -1

	var rules: CompetitionRuleProfile = input.rule_profile
	# §18.2 foul trouble. A coach stops protecting a player once the game is in
	# its closing period; the relief is a rule profile fact, not a hunch.
	var protection_period: int = rules.regulation_periods - _balance.foul_protection_final_period_relief
	if (
		state.period <= protection_period
		and runtime.foul_count >= rules.personal_foul_limit - _balance.foul_trouble_margin
	):
		return SubstitutionOrder.Reason.FOUL_TROUBLE
	# §18.2 acute fatigue.
	if (
		runtime.acute_fatigue >= _balance.fatigue_substitution_threshold
		and runtime.stint_ms >= _balance.substitution_stint_seconds * 1000
	):
		return SubstitutionOrder.Reason.FATIGUE
	# §18.1 planned minutes: a stint that has run past plan yields to the bench.
	if runtime.stint_ms >= _balance.substitution_stint_seconds * 1000:
		if _minute_pressure(state, input, profile, runtime) > 1.0:
			return SubstitutionOrder.Reason.PLANNED_MINUTES
	return -1


## Realized share divided by planned share. Above one means the player has
## already had more of the plan than the coach intended.
func _minute_pressure(
	state: MatchSnapshot,
	input: MatchInput,
	profile: TeamMatchProfile,
	runtime: PlayerMatchRuntime,
) -> float:
	var planned: float = profile.rotation_plan.share_for(runtime.player_id)
	if planned <= 0.0:
		return INF
	var elapsed_ms: int = _elapsed_ms(state, input)
	if elapsed_ms <= 0:
		return 0.0
	var realized: float = float(runtime.played_ms) / float(elapsed_ms)
	return realized / planned


func _elapsed_ms(state: MatchSnapshot, input: MatchInput) -> int:
	var total: int = 0
	for period in range(1, state.period):
		total += input.rule_profile.period_length_ms(period)
	total += input.rule_profile.period_length_ms(state.period) - state.clock_ms
	return maxi(total, 0)


func _has_available_bench(team_state: TeamMatchState) -> bool:
	return not team_state.available_bench_ids().is_empty()


## Who checks in. Ordered by the deficit against the plan, then by rest, then by
## substitution priority, then by stable id — canonical before any draw.
func _select_incoming(
	state: MatchSnapshot,
	input: MatchInput,
	profile: TeamMatchProfile,
	team_state: TeamMatchState,
	claimed: Array[StringName],
	reason: int,
) -> StringName:
	var closing: bool = _is_closing_time(state, input)
	var best_id: StringName = &""
	var best_score: float = -INF
	var order: Array[StringName] = profile.rotation_plan.substitution_order
	for player_id in team_state.available_bench_ids():
		if claimed.has(player_id):
			continue
		var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player_id)
		if runtime.acute_fatigue >= _balance.fatigue_substitution_threshold:
			continue
		var planned: float = profile.rotation_plan.share_for(player_id)
		var elapsed_ms: int = _elapsed_ms(state, input)
		var realized: float = (
			0.0 if elapsed_ms <= 0 else float(runtime.played_ms) / float(elapsed_ms))
		var score: float = (planned - realized) * 2.0
		score += clampf(float(runtime.rest_ms) / float(
			maxi(_balance.substitution_rest_seconds * 1000, 1)), 0.0, 1.0) * 0.5
		var priority: int = order.find(player_id)
		if priority >= 0:
			score -= float(priority) * 0.01
		if closing and profile.rotation_plan.closing_lineup.has(player_id):
			score += 1.0
		if score > best_score + 0.000001 or (
			absf(score - best_score) <= 0.000001 and String(player_id) < String(best_id)
		):
			best_score = score
			best_id = player_id
	if best_id.is_empty():
		# Fatigue filters are a preference, not a rule. A mandatory departure
		# takes the freshest legal body available.
		for player_id in team_state.available_bench_ids():
			if claimed.has(player_id):
				continue
			var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player_id)
			if best_id.is_empty() or runtime.acute_fatigue < team_state.runtime_by_id(best_id).acute_fatigue:
				best_id = player_id
	return best_id


## §18.2 score and time: the closing stretch of the final period, or any
## overtime.
func _is_closing_time(state: MatchSnapshot, input: MatchInput) -> bool:
	if state.period > input.rule_profile.regulation_periods:
		return true
	return (
		state.period == input.rule_profile.regulation_periods
		and state.clock_ms <= input.rule_profile.period_length_ms(state.period) / 4
	)
