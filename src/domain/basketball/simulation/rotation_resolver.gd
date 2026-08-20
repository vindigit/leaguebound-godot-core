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
##
## "Mandatory first" is an ordering over *bench claims*, not a comment. §5.1
## forbids a fouled-out, ejected, or medically unavailable player from staying
## on the floor at all, so those departures take the bench before any coaching
## preference does. Planning them in on-court order instead was latent until the
## §18.2 settled-game rule arrived: that rule can move four players at once, and
## it emptied the bench in front of a foul-out that then had nobody to check in.
func plan(
	state: MatchSnapshot,
	input: MatchInput,
	team_id: StringName,
) -> Array[SubstitutionOrder]:
	var profile: TeamMatchProfile = input.team_profile(team_id)
	var team_state: TeamMatchState = state.state_for(team_id)
	var orders: Array[SubstitutionOrder] = []
	var claimed: Array[StringName] = []
	_plan_departures(state, input, profile, team_state, orders, claimed, true)
	_plan_departures(state, input, profile, team_state, orders, claimed, false)
	return orders


## One pass over the lineup, taking either the mandatory departures or the
## discretionary ones. `claimed` carries between passes, so the second pass can
## only offer bench players the first did not need.
func _plan_departures(
	state: MatchSnapshot,
	input: MatchInput,
	profile: TeamMatchProfile,
	team_state: TeamMatchState,
	orders: Array[SubstitutionOrder],
	claimed: Array[StringName],
	mandatory: bool,
) -> void:
	for player_id in team_state.on_court_ids():
		var runtime: PlayerMatchRuntime = team_state.runtime_by_id(player_id)
		var reason: int = _departure_reason(state, input, profile, team_state, runtime)
		if reason < 0:
			continue
		if _is_mandatory_reason(reason) != mandatory:
			continue
		var incoming_id: StringName = _select_incoming(
			state, input, profile, team_state, claimed, reason)
		if incoming_id.is_empty():
			# No legal replacement exists. A mandatory departure still has to
			# happen — the lineup validity assertion will surface a roster that
			# upstream services should never have supplied.
			assert(not mandatory,
				"no eligible replacement exists for a mandatory substitution")
			continue
		claimed.append(incoming_id)
		orders.append(SubstitutionOrder.new(player_id, incoming_id, reason))


func _is_mandatory_reason(reason: int) -> bool:
	return (
		reason == SubstitutionOrder.Reason.FOULED_OUT
		or reason == SubstitutionOrder.Reason.UNAVAILABLE
	)


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
	# §18.2 score and time. The settled mode is `GarbageTimeRule`'s decision,
	# reduced onto this team's state from a `GARBAGE_TIME` event, so a rotation
	# reads exactly what the ledger explains. Which of the two coaches reaches it
	# first is the whole of the asymmetry, and it is an asymmetry of situation:
	# put this roster on the other side of the same scoreboard and it gets the
	# other threshold.
	if (
		team_state.settled_mode != GarbageTimeRule.Mode.NONE
		and _has_deeper_bench(profile, team_state, runtime.player_id)
	):
		return SubstitutionOrder.Reason.DECIDED_GAME
	# §18.1 planned minutes: a stint that has run past plan yields to the bench.
	if runtime.stint_ms >= _balance.substitution_stint_seconds * 1000:
		if _minute_pressure(state, input, profile, runtime) > 1.0:
			return SubstitutionOrder.Reason.PLANNED_MINUTES
	return -1


## Whether this team is in its settled rotation right now.
##
## Public because the rotation contract is worth asserting directly: a test that
## can only observe this through a whole simulated game cannot tell "the rule
## did not fire" from "the game never got there". The *decision* lives in
## `GarbageTimeRule` and the *state* lives on `TeamMatchState`; this is only the
## reader, which is what keeps the rule out of the substitution loop.
func is_settled(team_state: TeamMatchState) -> bool:
	return team_state.settled_mode != GarbageTimeRule.Mode.NONE


## Whether a settled game still has someone deeper to give these minutes to.
##
## The rule is "rest the players you need next game", so it fires only while a
## *less* used player is available to replace this one. Testing planned share
## against a fixed threshold instead looked equivalent and was not: a lineup can
## be required to keep one starter-tier player on the floor when the bench runs
## out, and a threshold kept ordering him off on every possession, which
## produced fourteen settled-game check-ins a game and churned minutes that no
## coach moved.
func _has_deeper_bench(
	profile: TeamMatchProfile,
	team_state: TeamMatchState,
	player_id: StringName,
) -> bool:
	var own_share: float = profile.rotation_plan.share_for(player_id)
	for bench_id in team_state.available_bench_ids():
		if profile.rotation_plan.share_for(bench_id) < own_share - 0.000001:
			return true
	return false


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
	var closing: bool = _is_closing_time(state, input, team_state)
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
		# A settled game empties the bench from the bottom: the coach is looking
		# for the player with the *smallest* plan, not the one furthest behind
		# it. Ranking by the deficit here would send the eighth man in for the
		# seventh and leave the end of the roster where it started.
		var score: float = (
			-planned * 2.0
			if reason == SubstitutionOrder.Reason.DECIDED_GAME
			else (planned - realized) * 2.0
		)
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
func _is_closing_time(
	state: MatchSnapshot,
	input: MatchInput,
	team_state: TeamMatchState,
) -> bool:
	# A settled game has no closing lineup. Preferring the best five into a
	# twenty-point game would undo the substitution that just took them off.
	# Checked before the overtime branch: a team that has conceded does not want
	# its closers back on the floor because the period changed.
	if is_settled(team_state):
		return false
	if state.period > input.rule_profile.regulation_periods:
		return true
	return (
		state.period == input.rule_profile.regulation_periods
		and state.clock_ms <= input.rule_profile.period_length_ms(state.period) / 4
	)
