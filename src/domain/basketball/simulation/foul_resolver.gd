class_name FoulResolver
extends RefCounted

## Illegal-contact opportunities and their resolution (`SIMULATION_SPEC.md`
## §13.1, §13.3).
##
## Fouls emerge "from contact actions, defender position and discipline,
## offensive aggression, strength and speed mismatch, help timing, contest type,
## fatigue, officiating profile, and deliberate late-game strategy". Every entry
## point here takes a real action and its real defensive context; there is no
## once-per-possession foul roll, which the Stage 3 contract forbids explicitly.
##
## §13.3: Defensive IQ and Interior/Perimeter Defense reduce avoidable foul risk
## through better position and legal contest selection. Discipline is therefore
## the *defender's* capability term in every check, not a flat modifier.

var _capability: CapabilityCalculator
var _body: BodyEffects
var _balance: SimulationBalanceProfile


func _init(
	p_capability: CapabilityCalculator,
	p_body: BodyEffects,
	p_balance: SimulationBalanceProfile,
) -> void:
	_capability = p_capability
	_body = p_body
	_balance = p_balance


## Contact on a shot attempt. Returns a shooting foul, with `and_one` set by the
## caller once the make is known.
func resolve_shooting_foul(
	context: PossessionContext,
	shooter_id: StringName,
	zone: int,
	contest: ShotContest,
	random_source: RandomSource,
) -> FoulCall:
	if contest.primary_defender_id.is_empty():
		return FoulCall.none()
	var defender_id: StringName = (
		contest.helper_id
		if not contest.helper_id.is_empty() and ShotZone.is_paint(zone)
		else contest.primary_defender_id
	)
	var probability: float = _contact_probability(
		context, shooter_id, defender_id, contest.legal_contact)
	if random_source.next_float() >= probability:
		return FoulCall.none()
	var attempts: int = 3 if ShotZone.is_three(zone) else 2
	return FoulCall.new(
		true, FoulType.Value.SHOOTING, defender_id, shooter_id, attempts, false, false, zone)


## Contact on a live non-shooting action: a drive stopped short, a post bump, a
## cut chased through. The caller resolves the bonus consequences.
func resolve_non_shooting_foul(
	context: PossessionContext,
	candidate: ActionCandidate,
	advantage: AdvantageResult,
	random_source: RandomSource,
) -> FoulCall:
	var defender_id: StringName = context.defender_of(candidate.actor_id)
	var probability: float = _contact_probability(
		context, candidate.actor_id, defender_id, advantage.foul_pressure)
	if random_source.next_float() >= probability:
		return FoulCall.none()
	return FoulCall.new(
		true, FoulType.Value.NON_SHOOTING_DEFENSIVE, defender_id, candidate.actor_id, 0)


## Offensive fouls: a charge taken on a drive, or an illegal screen. §11.2
## records the result as a turnover with cause `OFFENSIVE_FOUL`.
func resolve_offensive_foul(
	context: PossessionContext,
	candidate: ActionCandidate,
	random_source: RandomSource,
) -> FoulCall:
	if (
		candidate.action_family != ActionFamily.Value.DRIVE
		and candidate.action_family != ActionFamily.Value.SCREEN
		and candidate.action_family != ActionFamily.Value.POST_ACTION
		and candidate.action_family != ActionFamily.Value.TRANSITION_ATTACK
	):
		return FoulCall.none()
	var actor: PlayerMatchProfile = context.offense_profile(candidate.actor_id)
	var actor_runtime: PlayerMatchRuntime = context.offense_runtime(candidate.actor_id)
	var defender_id: StringName = context.defender_of(
		candidate.target_id if candidate.action_family == ActionFamily.Value.SCREEN
		else candidate.actor_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)

	# The offensive player's decision quality is what avoids the charge; the
	# defender's positioning is what draws it.
	var decision: float = _capability.capability_of(
		CapabilityKey.Value.SHOT_SELECTION, actor, actor_runtime,
		_capability.capability_of(CapabilityKey.Value.RIM_TOUCH_FINISH, actor, actor_runtime))
	var positioning: float = _capability.capability_of(
		CapabilityKey.Value.INTERIOR_POSITIONING, defender, defender_runtime)
	var units: float = _capability.differential_units(positioning, decision)
	var probability: float = _balance.opposed_probability(
		_balance.foul_conversion_base * 0.30,
		units,
		_balance.foul_conversion_floor,
		_balance.foul_conversion_ceiling)
	if random_source.next_float() >= probability:
		return FoulCall.none()
	return FoulCall.new(
		true, FoulType.Value.OFFENSIVE, candidate.actor_id, defender_id, 0)


## Contact while the ball is loose on the glass (§13.1 loose-ball foul).
func resolve_loose_ball_foul(
	context: PossessionContext,
	offensive_candidate_id: StringName,
	defensive_candidate_id: StringName,
	random_source: RandomSource,
) -> FoulCall:
	if offensive_candidate_id.is_empty() or defensive_candidate_id.is_empty():
		return FoulCall.none()
	var offensive: PlayerMatchProfile = context.offense_profile(offensive_candidate_id)
	var offensive_runtime: PlayerMatchRuntime = context.offense_runtime(offensive_candidate_id)
	var defensive: PlayerMatchProfile = context.defense_profile(defensive_candidate_id)
	var defensive_runtime: PlayerMatchRuntime = context.defense_runtime(defensive_candidate_id)

	var offensive_force: float = _capability.capability_of(
		CapabilityKey.Value.CONTACT_FORCE, offensive, offensive_runtime)
	var defensive_discipline: float = _capability.capability_of(
		CapabilityKey.Value.INTERIOR_POSITIONING, defensive, defensive_runtime)
	var units: float = _capability.differential_units(offensive_force, defensive_discipline)
	var probability: float = _balance.opposed_probability(
		_balance.foul_conversion_base * 0.22,
		units,
		_balance.foul_conversion_floor,
		_balance.foul_conversion_ceiling)
	if random_source.next_float() >= probability:
		return FoulCall.none()
	# The more disciplined player is the one who did not commit it.
	if random_source.next_float() < 0.5:
		return FoulCall.new(
			true, FoulType.Value.LOOSE_BALL, defensive_candidate_id, offensive_candidate_id, 0)
	return FoulCall.new(
		true, FoulType.Value.OFFENSIVE, offensive_candidate_id, defensive_candidate_id, 0)


## §13.1 deliberate late-game strategy: a trailing team fouls to stop the clock.
## This is a coaching decision, so it is gated by score and clock rather than
## drawn from a general foul rate.
func resolve_intentional_foul(
	context: PossessionContext,
	random_source: RandomSource,
) -> FoulCall:
	if not context.is_late_game():
		return FoulCall.none()
	var defense_margin: int = -context.offense_margin()
	if defense_margin >= 0 or defense_margin < -_balance.intentional_foul_max_margin:
		return FoulCall.none()
	if random_source.next_float() >= _balance.intentional_foul_share:
		return FoulCall.none()
	# The defence fouls whoever has the ball, using its least valuable defender.
	var fouler_id: StringName = _least_protected_defender(context)
	if fouler_id.is_empty() or context.ball_handler_id.is_empty():
		return FoulCall.none()
	return FoulCall.new(
		true, FoulType.Value.INTENTIONAL, fouler_id, context.ball_handler_id, 0)


## `EndgameStrategy`'s leading-by-three foul: the mirror image of the
## intentional foul above, for the side that is *ahead*. A defence up exactly
## three with little time left may prefer sending the offence to the line for
## two over letting them attempt the tying three at all. Real coaching staffs
## disagree about this one, which is why it is a probability
## (`leading_foul_share`) rather than a certainty the way the desperation foul
## above effectively is inside its own window — this is the "optional" of the
## production brief, not the "necessary" of the intentional free-throw miss.
func resolve_leading_by_three_foul(
	context: PossessionContext,
	random_source: RandomSource,
) -> FoulCall:
	if context.state.period < context.input.rule_profile.regulation_periods:
		return FoulCall.none()
	if context.state.clock_ms > _balance.leading_foul_clock_ms:
		return FoulCall.none()
	var defense_margin: int = -context.offense_margin()
	if defense_margin != GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT:
		return FoulCall.none()
	if random_source.next_float() >= _balance.leading_foul_share:
		return FoulCall.none()
	var fouler_id: StringName = _least_protected_defender(context)
	if fouler_id.is_empty() or context.ball_handler_id.is_empty():
		return FoulCall.none()
	return FoulCall.new(
		true, FoulType.Value.LEADING_PROTECT, fouler_id, context.ball_handler_id, 0)


## The shared contact model. §14.3's 20% is the rate at which a *valid*
## illegal-contact opportunity becomes a whistle, so `contact_load` — how much
## contact the action actually generated — is the opportunity term and the base
## rate is the conversion term. A defender's discipline and position reduce it;
## an attacker's contact-seeking aggression and size raise it; the officiating
## and home environment shift it inside their bounded envelope.
func _contact_probability(
	context: PossessionContext,
	attacker_id: StringName,
	defender_id: StringName,
	contact_load: float,
) -> float:
	var attacker: PlayerMatchProfile = context.offense_profile(attacker_id)
	var attacker_runtime: PlayerMatchRuntime = context.offense_runtime(attacker_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)

	var force: float = _capability.capability_of(
		CapabilityKey.Value.CONTACT_FORCE, attacker, attacker_runtime)
	var aggression: float = _balance.tendency_multiplier(
		attacker.tendencies.at(TendencySlider.Value.PATIENT_AGGRESSIVE))
	var discipline: float = (
		_capability.capability_of(CapabilityKey.Value.INTERIOR_POSITIONING, defender, defender_runtime) * 0.5
		+ _capability.capability_of(CapabilityKey.Value.PERIMETER_CONTEST, defender, defender_runtime) * 0.5
	)
	# A defender who gambles fouls more; §13.3 makes that a tendency, not a
	# property of the Stealing rating.
	var gamble: float = _balance.tendency_multiplier(
		defender.tendencies.at(TendencySlider.Value.DISCIPLINED_GAMBLE))
	var leverage: float = _body.leverage_edge(
		attacker.body, force, defender.body,
		_capability.capability_of(CapabilityKey.Value.CONTACT_FORCE, defender, defender_runtime))

	var units: float = _capability.differential_units(force + leverage, discipline)
	var base: float = (
		_balance.foul_conversion_base * clampf(contact_load, 0.0, 1.0) * aggression * gamble)
	var probability: float = _balance.opposed_probability(
		base, units, _balance.foul_conversion_floor, _balance.foul_conversion_ceiling)
	# §19.4 officiating. The whistle is nudged, never invented: this runs only
	# after a real action produced real contact, so the opportunity exists
	# whatever the venue says, and the shift is applied to its conversion.
	#
	# It reads the venue and nothing else — not the score, not the clock, not
	# the margin, not who is expected to win — so it cannot rescue a trailing
	# home team, and it is symmetric: the same magnitude that makes the visiting
	# defence marginally likelier to be whistled makes the home defence
	# marginally less so.
	var officiating: float = context.input.home_environment_context.officiating()
	if officiating > 0.0:
		var direction: float = (
			1.0 if context.input.is_home(context.offense.team_id) else -1.0)
		probability = clampf(
			probability + direction * officiating,
			_balance.foul_conversion_floor, _balance.foul_conversion_ceiling)
	return probability


func _least_protected_defender(context: PossessionContext) -> StringName:
	var best_id: StringName = &""
	var best_fouls: int = -1
	for defender_id in context.defense_on_court():
		var runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)
		var remaining: int = context.input.rule_profile.personal_foul_limit - runtime.foul_count
		if remaining <= 1:
			continue
		if runtime.foul_count > best_fouls or (
			runtime.foul_count == best_fouls and String(defender_id) < String(best_id)
		):
			best_fouls = runtime.foul_count
			best_id = defender_id
	return best_id
