class_name ActionCandidateGenerator
extends RefCounted

## Generates and weights the legal next actions (`SIMULATION_SPEC.md` §10.2,
## §10.3).
##
## Two rules shape everything here:
##
## - **Validity first.** "An impossible action receives no weight. The engine
##   does not allow a tendency slider to create an invalid dunk, pass target, or
##   on-court touch." Validity is the only factor permitted to reach zero.
## - **Weight second.** `ActionWeight = Validity × RoleOpportunity ×
##   PlayerTendency × CoachInstruction × TacticalFit × MatchupOpportunity ×
##   ScoreClockContext × CapabilityConfidence × FatigueAvailability`, each factor
##   clamped to its §12.2 band and the product clamped to 0.15-3.50 times the
##   family base.
##
## The §12.3 split is applied as exponents: the player's tendency multiplier is
## raised to the player share and the coach's to the coach share, so a strict
## coach moves behaviour without either factor leaving its own band.

var _capability: CapabilityCalculator
var _body: BodyEffects
var _balance: SimulationBalanceProfile
var _participants: ParticipantSelector

## Per-call scratch. Lineup spacing and the team usage budget are properties of
## the *possession state*, not of an individual candidate, so they are resolved
## once per `generate` and read by every candidate built from it. Computing them
## inside `_build` made both O(lineup) per candidate and turned candidate
## generation into the slowest part of the engine by an order of magnitude.
var _frame_spacing: float = 0.5
var _frame_usage: Dictionary = {}


func _init(
	p_capability: CapabilityCalculator,
	p_body: BodyEffects,
	p_balance: SimulationBalanceProfile,
	p_participants: ParticipantSelector,
) -> void:
	_capability = p_capability
	_body = p_body
	_balance = p_balance
	_participants = p_participants


func generate(context: PossessionContext) -> Array[ActionCandidate]:
	var handler_id: StringName = context.ball_handler_id
	assert(not handler_id.is_empty(), "action generation requires a ball handler")
	assert(context.state.clock_ms > 0, "an action cannot begin after period expiration")
	_begin_frame(context)
	var candidates: Array[ActionCandidate] = []
	var handler: PlayerMatchProfile = context.offense_profile(handler_id)
	var handler_runtime: PlayerMatchRuntime = context.offense_runtime(handler_id)
	var desperate: bool = context.state.shot_clock_ms <= _balance.desperation_clock_ms

	# --- shot families for the ball handler ---------------------------------
	for zone in ShotZone.all():
		if not _shot_zone_is_valid(context, handler, handler_runtime, zone):
			continue
		candidates.append(_shot_candidate(context, handler_id, zone))

	# --- attacking families --------------------------------------------------
	if _drive_is_valid(context, handler, handler_runtime):
		candidates.append(_build(context, handler_id, ActionFamily.Value.DRIVE, &"", -1))
	if _post_is_valid(context, handler, handler_runtime):
		candidates.append(_build(context, handler_id, ActionFamily.Value.POST_ACTION, &"", -1))
	if context.in_transition:
		candidates.append(_build(context, handler_id, ActionFamily.Value.TRANSITION_ATTACK, &"", -1))

	if not desperate:
		var screener_id: StringName = _participants.select_screener(context, handler_id)
		if not screener_id.is_empty():
			candidates.append(
				_build(context, handler_id, ActionFamily.Value.PICK_ACTION, screener_id, -1))
		for teammate_id in context.offense_on_court():
			if teammate_id == handler_id:
				continue
			candidates.append(
				_build(context, handler_id, ActionFamily.Value.PASS_SWING, teammate_id, -1))
			candidates.append(
				_build(context, handler_id, ActionFamily.Value.HANDOFF, teammate_id, -1))
			candidates.append(
				_build(context, teammate_id, ActionFamily.Value.OFF_BALL_CUT, handler_id, -1))
			candidates.append(
				_build(context, teammate_id, ActionFamily.Value.RELOCATION, handler_id, -1))
			candidates.append(
				_build(context, teammate_id, ActionFamily.Value.SCREEN, handler_id, -1))
	if context.state.shot_clock_ms > _balance.reset_block_clock_ms:
		candidates.append(_build(context, handler_id, ActionFamily.Value.RESET, &"", -1))

	assert(not candidates.is_empty(), "a live possession must retain at least one legal action")
	return candidates


## Resolves the possession-level facts every candidate shares.
func _begin_frame(context: PossessionContext) -> void:
	var on_court: Array[StringName] = context.offense_on_court()
	_frame_usage = _participants.usage_damping_table(context)
	if on_court.is_empty():
		_frame_spacing = 0.5
		return
	var spacers: int = 0
	for player_id in on_court:
		var player: PlayerMatchProfile = context.offense_profile(player_id)
		var runtime: PlayerMatchRuntime = context.offense_runtime(player_id)
		var three: float = _capability.capability_of(
			CapabilityKey.Value.THREE_POINT_SHOTMAKING, player, runtime)
		if three >= _balance.spacer_capability_threshold:
			spacers += 1
	_frame_spacing = float(spacers) / float(on_court.size())


func _usage_of(player_id: StringName) -> float:
	if not _frame_usage.has(player_id):
		return 1.0
	var damping: float = _frame_usage[player_id]
	return damping


## The putback branch after an offensive rebound is a one-player decision, so it
## is generated separately from the ordinary half-court candidate set (§14.4).
func putback_candidate(context: PossessionContext, rebounder_id: StringName) -> ActionCandidate:
	var zone: int = ShotZone.Value.RESTRICTED_RIM
	var player: PlayerMatchProfile = context.offense_profile(rebounder_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(rebounder_id)
	var dunk: bool = _dunk_is_valid(context, player, runtime, zone)
	return ActionCandidate.new(
		ActionFamily.Value.PUTBACK, rebounder_id,
		_balance.action_base_weight(ActionFamily.Value.PUTBACK),
		&"", zone, dunk, "putback")


# --- validity ---------------------------------------------------------------

func _shot_zone_is_valid(
	context: PossessionContext,
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	zone: int,
) -> bool:
	# A stationary pull-up from the restricted area is not a distinct action:
	# rim attempts arrive through drives, cuts, posts, and putbacks.
	if zone == ShotZone.Value.RESTRICTED_RIM:
		return false
	var capability: float = _capability.shot_capability(player, runtime, zone)
	match zone:
		ShotZone.Value.DEEP_THREE:
			return capability >= _balance.deep_three_capability_threshold
		ShotZone.Value.STANDARD_THREE:
			return capability >= _balance.pull_up_three_capability_threshold
		_:
			return true


func _drive_is_valid(
	context: PossessionContext,
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
) -> bool:
	# A drive needs a live dribble; nothing else gates it. §10.6.2 forbids a
	# role from making one illegal.
	return _capability.capability_of(CapabilityKey.Value.HANDLE_CREATION, player, runtime) > 0.0


func _post_is_valid(
	context: PossessionContext,
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
) -> bool:
	var defender_id: StringName = context.defender_of(player.player_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var interior: float = _capability.capability_of(
		CapabilityKey.Value.RIM_TOUCH_FINISH, player, runtime)
	var leverage: float = _body.size_mismatch(player.body, defender.body)
	return interior + leverage >= _balance.post_action_capability_threshold


## §6.1 action validity, and the §10.2 rule that no slider can invent it.
func _dunk_is_valid(
	context: PossessionContext,
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	zone: int,
) -> bool:
	if zone != ShotZone.Value.RESTRICTED_RIM:
		return false
	if not _body.dunk_is_available(player.body, player.attributes.vertical):
		return false
	return _capability.capability_of(CapabilityKey.Value.DUNK_THREAT, player, runtime) > 0.0


# --- weight construction ----------------------------------------------------

func _shot_candidate(
	context: PossessionContext,
	actor_id: StringName,
	zone: int,
) -> ActionCandidate:
	return _build(context, actor_id, ActionFamily.Value.PULL_UP, &"", zone)


func _build(
	context: PossessionContext,
	actor_id: StringName,
	family: int,
	target_id: StringName,
	zone: int,
) -> ActionCandidate:
	var actor: PlayerMatchProfile = context.offense_profile(actor_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(actor_id)
	var base: float = _balance.action_base_weight(family)

	var role_opportunity: float = _balance.role_opportunity(actor.tactical_role.role, family)
	var tendency: float = pow(
		_tendency_multiplier(actor, family, zone), _balance.player_preference_share)
	var coach: float = clampf(
		pow(_coach_multiplier(context.offense.game_plan, family, zone),
			context.offense.game_plan.coach_share_for(context.offense.game_plan.trust)),
		_balance.coach_instruction_min,
		_balance.coach_instruction_max)
	var tactical_fit: float = _tactical_fit(context, actor, runtime, family, zone)
	var matchup: float = _matchup_opportunity(context, actor, runtime, family, zone)
	var score_clock: float = _score_clock(context, family, zone)
	var confidence: float = _capability_confidence(context, actor, runtime, family, zone)
	var fatigue: float = _participants.fatigue_availability(runtime)
	var usage: float = 1.0
	if _consumes_usage(family):
		usage = _usage_of(actor_id)
	elif family == ActionFamily.Value.PASS_SWING or family == ActionFamily.Value.HANDOFF:
		# A pass is weighted by the *receiver's* claim on the budget, which is
		# what makes usage a team constraint rather than a per-player one.
		usage = _usage_of(target_id)

	var weight: float = (
		base * role_opportunity * tendency * coach * tactical_fit
		* matchup * score_clock * confidence * fatigue * usage
	)
	var trace: String = "role=%.2f tend=%.2f coach=%.2f fit=%.2f match=%.2f clock=%.2f conf=%.2f fat=%.2f use=%.2f" % [
		role_opportunity, tendency, coach, tactical_fit, matchup,
		score_clock, confidence, fatigue, usage,
	]
	var dunk: bool = _dunk_is_valid(context, actor, runtime, zone)
	return ActionCandidate.new(
		family, actor_id, _balance.clamp_candidate_weight(weight, base),
		target_id, zone, dunk, trace)


func _consumes_usage(family: int) -> bool:
	return (
		family == ActionFamily.Value.PULL_UP
		or family == ActionFamily.Value.DRIVE
		or family == ActionFamily.Value.POST_ACTION
		or family == ActionFamily.Value.TRANSITION_ATTACK
		or family == ActionFamily.Value.PICK_ACTION
	)


## §10.4 slider effects, combined as a geometric mean so two aligned sliders
## cannot push the factor past the §12.2 band the table fixes.
func _tendency_multiplier(actor: PlayerMatchProfile, family: int, zone: int) -> float:
	var product: float = 1.0
	var count: int = 0
	var tendencies: PlayerTendencies = actor.tendencies

	match family:
		ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF:
			product *= _low_pole(tendencies, TendencySlider.Value.PASS_FIRST_SCORE_FIRST)
			count += 1
		ActionFamily.Value.PULL_UP, ActionFamily.Value.DRIVE, ActionFamily.Value.POST_ACTION:
			product *= _high_pole(tendencies, TendencySlider.Value.PASS_FIRST_SCORE_FIRST)
			product *= _low_pole(tendencies, TendencySlider.Value.CREATE_OWN_SHOT_OFF_BALL)
			count += 2
		ActionFamily.Value.OFF_BALL_CUT, ActionFamily.Value.RELOCATION, ActionFamily.Value.SCREEN:
			product *= _high_pole(tendencies, TendencySlider.Value.CREATE_OWN_SHOT_OFF_BALL)
			count += 1
		ActionFamily.Value.TRANSITION_ATTACK:
			product *= _low_pole(tendencies, TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO)
			count += 1
		ActionFamily.Value.RESET:
			product *= _high_pole(tendencies, TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO)
			product *= _low_pole(tendencies, TendencySlider.Value.PATIENT_AGGRESSIVE)
			count += 2
		_:
			pass

	if zone >= 0:
		if ShotZone.is_three(zone):
			product *= _low_pole(tendencies, TendencySlider.Value.PERIMETER_INTERIOR)
		elif ShotZone.is_paint(zone):
			product *= _high_pole(tendencies, TendencySlider.Value.PERIMETER_INTERIOR)
		count += 1
	elif family == ActionFamily.Value.DRIVE or family == ActionFamily.Value.POST_ACTION:
		product *= _high_pole(tendencies, TendencySlider.Value.PERIMETER_INTERIOR)
		count += 1

	if count <= 1:
		return product
	return pow(product, 1.0 / float(count))


func _high_pole(tendencies: PlayerTendencies, slider: int) -> float:
	return _balance.tendency_multiplier(tendencies.at(slider))


func _low_pole(tendencies: PlayerTendencies, slider: int) -> float:
	return _balance.opposing_tendency_multiplier(tendencies.at(slider))


## §10.5 coach authority, expressed through the same five-position dials.
func _coach_multiplier(plan: TeamGamePlan, family: int, zone: int) -> float:
	var product: float = 1.0
	var count: int = 0
	match family:
		ActionFamily.Value.TRANSITION_ATTACK:
			product *= _balance.tendency_multiplier(plan.tempo_instruction)
			count += 1
		ActionFamily.Value.RESET:
			product *= _balance.opposing_tendency_multiplier(plan.tempo_instruction)
			count += 1
		ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF, ActionFamily.Value.RELOCATION:
			product *= _balance.tendency_multiplier(plan.ball_movement_instruction)
			count += 1
		ActionFamily.Value.DRIVE, ActionFamily.Value.POST_ACTION:
			product *= _balance.tendency_multiplier(plan.shot_profile_instruction)
			product *= _balance.opposing_tendency_multiplier(plan.ball_movement_instruction)
			count += 2
		ActionFamily.Value.PULL_UP:
			product *= _balance.opposing_tendency_multiplier(plan.ball_movement_instruction)
			count += 1
		_:
			pass
	if zone >= 0:
		if ShotZone.is_three(zone):
			product *= _balance.opposing_tendency_multiplier(plan.shot_profile_instruction)
		elif ShotZone.is_paint(zone):
			product *= _balance.tendency_multiplier(plan.shot_profile_instruction)
		count += 1
	if count <= 1:
		return product
	return pow(product, 1.0 / float(count))


## How well the action fits the lineup currently on the floor: spacing for
## interior attacks, and the actor's own physical suitability for a post seal.
func _tactical_fit(
	context: PossessionContext,
	actor: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	family: int,
	zone: int,
) -> float:
	var spacing: float = _frame_spacing
	var value: float = 1.0
	match family:
		ActionFamily.Value.DRIVE, ActionFamily.Value.OFF_BALL_CUT:
			value = lerpf(0.80, 1.25, spacing)
		ActionFamily.Value.POST_ACTION:
			value = lerpf(1.15, 0.85, spacing)
		ActionFamily.Value.PICK_ACTION:
			value = lerpf(0.90, 1.15, spacing)
		ActionFamily.Value.RELOCATION:
			value = lerpf(0.85, 1.20, spacing)
		_:
			value = 1.0
	if zone >= 0 and ShotZone.is_three(zone):
		value *= lerpf(0.90, 1.10, spacing)
	if not context.advantage.beneficiary_id.is_empty() and context.advantage.beneficiary_id == actor.player_id:
		value *= lerpf(1.0, 1.20, context.advantage.quality_share())
	return clampf(value, _balance.tactical_fit_min, _balance.tactical_fit_max)


## §10.3 matchup opportunity: the actor's edge over his current assignment,
## including the §6.1 size channel. Bounded by the §12.2 band.
func _matchup_opportunity(
	context: PossessionContext,
	actor: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	family: int,
	zone: int,
) -> float:
	var defender_id: StringName = context.defender_of(actor.player_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)
	var attack: float = 0.0
	var resist: float = 0.0
	match family:
		ActionFamily.Value.DRIVE, ActionFamily.Value.TRANSITION_ATTACK, ActionFamily.Value.PICK_ACTION:
			attack = _capability.capability_of(CapabilityKey.Value.HANDLE_CREATION, actor, runtime)
			resist = _capability.capability_of(
				CapabilityKey.Value.POINT_OF_ATTACK_CONTAINMENT, defender, defender_runtime)
		ActionFamily.Value.POST_ACTION:
			attack = _capability.capability_of(CapabilityKey.Value.RIM_TOUCH_FINISH, actor, runtime)
			resist = _capability.capability_of(
				CapabilityKey.Value.INTERIOR_POSITIONING, defender, defender_runtime)
			attack += _body.leverage_edge(
				actor.body,
				_capability.capability_of(CapabilityKey.Value.CONTACT_FORCE, actor, runtime),
				defender.body,
				_capability.capability_of(CapabilityKey.Value.CONTACT_FORCE, defender, defender_runtime))
		ActionFamily.Value.PULL_UP:
			attack = _capability.shot_capability(actor, runtime, maxi(zone, 0))
			resist = _capability.capability_of(
				CapabilityKey.Value.PERIMETER_CONTEST, defender, defender_runtime)
		_:
			attack = _capability.capability_of(CapabilityKey.Value.OFF_BALL_TIMING, actor, runtime)
			resist = _capability.capability_of(
				CapabilityKey.Value.HELP_RECOGNITION, defender, defender_runtime,
				_assignment_execution(context, defender_runtime))
	var edge: float = clampf(attack - resist, -1.0, 1.0)
	var midpoint: float = (_balance.matchup_opportunity_min + _balance.matchup_opportunity_max) * 0.5
	var half_span: float = (_balance.matchup_opportunity_max - _balance.matchup_opportunity_min) * 0.5
	return clampf(
		midpoint + edge * half_span,
		_balance.matchup_opportunity_min,
		_balance.matchup_opportunity_max)


## §5.2 assignment-execution context: how well a defender is executing his live
## assignment, from team coordination and current freshness. Not an identity.
func _assignment_execution(context: PossessionContext, runtime: PlayerMatchRuntime) -> float:
	return clampf(context.defense.chemistry * 0.5 + runtime.current_energy() * 0.5, 0.0, 1.0)


## §10.3 score and clock context, using the wider §12.2 late-clock band when the
## shot clock forces the issue.
func _score_clock(context: PossessionContext, family: int, zone: int) -> float:
	var value: float = 1.0
	var shot_clock_share: float = clampf(
		float(context.state.shot_clock_ms) / float(context.input.rule_profile.shot_clock_seconds * 1000),
		0.0,
		1.0)
	var late: bool = context.is_late_clock()
	if late:
		if ActionFamily.is_direct_shot(family) or family == ActionFamily.Value.DRIVE:
			value = lerpf(_balance.late_clock_max, 1.0, shot_clock_share)
		elif family == ActionFamily.Value.RESET or family == ActionFamily.Value.RELOCATION:
			value = _balance.late_clock_min
		else:
			value = lerpf(0.85, 1.0, shot_clock_share)
		return clampf(value, _balance.late_clock_min, _balance.late_clock_max)

	if family == ActionFamily.Value.RESET:
		value = lerpf(0.75, 1.25, shot_clock_share)
	elif ActionFamily.is_direct_shot(family):
		value = lerpf(1.20, 0.85, shot_clock_share)

	# Late-game score context: a trailing team hunts threes, a leading team
	# takes time. §20.3 keeps this a decision effect and never a make bonus.
	if context.is_late_game():
		var margin: int = context.offense_margin()
		if margin < 0 and zone >= 0 and ShotZone.is_three(zone):
			value *= 1.25
		elif margin > 0 and family == ActionFamily.Value.RESET:
			value *= 1.20
	return clampf(value, _balance.score_clock_min, _balance.score_clock_max)


## §10.3 capability confidence: a player attempts what he can actually do a
## little more often. Bounded to 0.80-1.20 so it never becomes a second
## capability check.
func _capability_confidence(
	context: PossessionContext,
	actor: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	family: int,
	zone: int,
) -> float:
	var capability: float = 0.0
	if zone >= 0:
		capability = _capability.shot_selection(actor, runtime, zone)
	else:
		match family:
			ActionFamily.Value.PASS_SWING, ActionFamily.Value.HANDOFF:
				capability = _capability.capability_of(
					CapabilityKey.Value.PASS_READ_QUALITY, actor, runtime)
			ActionFamily.Value.DRIVE, ActionFamily.Value.PICK_ACTION, ActionFamily.Value.TRANSITION_ATTACK:
				capability = _capability.capability_of(
					CapabilityKey.Value.HANDLE_CREATION, actor, runtime)
			ActionFamily.Value.POST_ACTION:
				capability = _capability.capability_of(
					CapabilityKey.Value.RIM_TOUCH_FINISH, actor, runtime)
			ActionFamily.Value.SCREEN:
				capability = _capability.capability_of(
					CapabilityKey.Value.CONTACT_FORCE, actor, runtime)
			_:
				capability = _capability.capability_of(
					CapabilityKey.Value.OFF_BALL_TIMING, actor, runtime)
	return lerpf(
		_balance.capability_confidence_min,
		_balance.capability_confidence_max,
		clampf(capability, 0.0, 1.0))
