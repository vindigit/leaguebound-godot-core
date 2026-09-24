class_name ReboundResolver
extends RefCounted

## Rebound opportunity, team outcome, and individual rebounder
## (`SIMULATION_SPEC.md` §14).
##
## §14.2's candidate score is implemented term by term: positioning, the
## relevant rebound rating, box-out or crash intent, strength leverage,
## vertical and reach access, IQ timing, fatigue, and bounded random variation.
## "Defensive players receive positional advantage according to shot/rebound
## profile and box-out execution, not a universal arbitrary bonus" — the
## positional term therefore comes from the shot zone's trajectory and from
## whether each offensive player actually crashed.
##
## The known defect this replaces was blunt: every miss became a defensive
## rebound, so offensive rebounding, putbacks, and second-chance points did not
## exist at all.

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


## Whether an offensive player crashes the glass on this attempt (§14.2 crash
## intent, §15.3 the Box Out ↔ Chase Rebounds tendency, §10.5 coach authority).
func crashes(
	context: PossessionContext,
	player_id: StringName,
	shooter_id: StringName,
	random_source: RandomSource,
) -> bool:
	if player_id == shooter_id:
		# The shooter is not crashing his own attempt from the perimeter, but a
		# rim attempt leaves him in position.
		return false
	var player: PlayerMatchProfile = context.offense_profile(player_id)
	var tendency: float = _balance.tendency_multiplier(
		player.tendencies.at(TendencySlider.Value.BOX_OUT_CHASE_REBOUNDS))
	var coach: float = _balance.tendency_multiplier(
		context.offense.game_plan.crash_instruction)
	var role: float = _balance.role_opportunity(
		player.tactical_role.role, ActionFamily.Value.PUTBACK)
	# §18.2 score and time, applied to the offensive glass. A team protecting a
	# lead sends nobody to it and retreats instead; a team chasing one sends more.
	# This is a coaching decision about where five players stand, and it changes
	# no rebounding probability for anybody who does go.
	var share: float = clampf(
		_balance.crash_share_base * tendency * coach * role
		* GameManagement.crash_multiplier(context, _balance),
		_balance.crash_share_min,
		_balance.crash_share_max)
	return random_source.next_float() < share


## Resolves one reboundable miss into a team outcome and an individual
## rebounder.
func resolve(
	context: PossessionContext,
	shooter_id: StringName,
	zone: int,
	blocked: bool,
	random_source: RandomSource,
) -> ReboundOutcome:
	var offense_ids: Array[StringName] = context.offense_on_court()
	var defense_ids: Array[StringName] = context.defense_on_court()
	assert(not offense_ids.is_empty() and not defense_ids.is_empty(),
		"a rebound requires both lineups on court")

	# §14.1 trajectory abstraction: a long miss bounces long. This is what gives
	# guards offensive rebounds off threes and bigs rebounds off rim misses,
	# rather than a flat positional constant.
	var long_share: float = _long_rebound_share(zone, blocked)

	var offensive_scores: Array[float] = []
	var offensive_total: float = 0.0
	for player_id in offense_ids:
		var crashed: bool = crashes(context, player_id, shooter_id, random_source)
		var score: float = _offensive_score(context, player_id, long_share, crashed, random_source)
		offensive_scores.append(score)
		offensive_total += score

	var defensive_scores: Array[float] = []
	var defensive_total: float = 0.0
	for player_id in defense_ids:
		var score: float = _defensive_score(context, player_id, long_share, random_source)
		defensive_scores.append(score)
		defensive_total += score

	var raw_share: float = 0.0
	if offensive_total + defensive_total > 0.0:
		raw_share = offensive_total / (offensive_total + defensive_total)
	# The candidate scores set the *shape*; the §14.3 base rate sets the level.
	# The reference share is where an ordinary lineup's raw score share lands,
	# so the base rate is delivered at the reference and lineup quality moves it
	# either way. Centring on 0.5 instead would treat "the offence sent two
	# crashers against five defenders" as a deficit and pin every game at the
	# floor.
	var probability: float = clampf(
		_balance.offensive_rebound_base
		+ (raw_share - _balance.offensive_rebound_reference_share)
		* _balance.offensive_rebound_spread,
		_balance.offensive_rebound_floor,
		_balance.offensive_rebound_ceiling)

	var offensive: bool = random_source.next_float() < probability
	var rebounder_id: StringName = (
		_pick(offense_ids, offensive_scores, random_source)
		if offensive
		else _pick(defense_ids, defensive_scores, random_source)
	)
	var team_id: StringName = context.offense.team_id if offensive else context.defense.team_id
	return ReboundOutcome.new(rebounder_id, team_id, offensive, probability)


## How much of the miss carries past the paint. Threes and blocked attempts
## produce long, loose balls; rim misses stay short.
func _long_rebound_share(zone: int, blocked: bool) -> float:
	if blocked:
		return 0.45
	match zone:
		ShotZone.Value.RESTRICTED_RIM:
			return 0.10
		ShotZone.Value.CLOSE_NON_RIM:
			return 0.25
		ShotZone.Value.MIDRANGE:
			return 0.45
		ShotZone.Value.STANDARD_THREE:
			return 0.65
		ShotZone.Value.DEEP_THREE:
			return 0.75
		_:
			assert(false, "unknown shot zone")
	return 0.45


func _offensive_score(
	context: PossessionContext,
	player_id: StringName,
	long_share: float,
	crashed: bool,
	random_source: RandomSource,
) -> float:
	var player: PlayerMatchProfile = context.offense_profile(player_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(player_id)
	var positioning: float = _capability.capability_of(
		CapabilityKey.Value.OFFENSIVE_REBOUND_POSITIONING, player, runtime)
	var reach: float = _body.rebound_reach_share(player.body, player.attributes.vertical)
	var force: float = _capability.capability_of(
		CapabilityKey.Value.CONTACT_FORCE, player, runtime)
	var speed: float = _capability.capability_of(
		CapabilityKey.Value.COURT_SPEED, player, runtime)
	# A long carom rewards pursuit; a short one rewards reach and leverage.
	var access: float = lerpf(reach * 0.6 + force * 0.4, speed, long_share)
	var intent: float = 1.0 if crashed else _balance.crash_retreat_intent_share
	var variation: float = 0.85 + random_source.next_float() * 0.30
	return maxf((positioning * 0.55 + access * 0.45) * intent * variation, 0.0001)


func _defensive_score(
	context: PossessionContext,
	player_id: StringName,
	long_share: float,
	random_source: RandomSource,
) -> float:
	var player: PlayerMatchProfile = context.defense_profile(player_id)
	var runtime: PlayerMatchRuntime = context.defense_runtime(player_id)
	var positioning: float = _capability.capability_of(
		CapabilityKey.Value.DEFENSIVE_REBOUND_POSITIONING, player, runtime)
	var reach: float = _body.rebound_reach_share(player.body, player.attributes.vertical)
	var force: float = _capability.capability_of(
		CapabilityKey.Value.CONTACT_FORCE, player, runtime)
	var speed: float = _capability.capability_of(
		CapabilityKey.Value.COURT_SPEED, player, runtime)
	# Box-out execution is the defensive positional advantage §14.2 allows.
	var box_out: float = _balance.opposing_tendency_multiplier(
		player.tendencies.at(TendencySlider.Value.BOX_OUT_CHASE_REBOUNDS))
	var access: float = lerpf(reach * 0.6 + force * 0.4, speed, long_share)
	var variation: float = 0.85 + random_source.next_float() * 0.30
	return maxf((positioning * 0.55 + access * 0.45) * box_out * variation, 0.0001)


## Whether the offensive rebounder goes straight back up (§14.4, §14.3 putback
## base rate), rather than kicking the ball back out.
func attempts_putback(
	context: PossessionContext,
	rebounder_id: StringName,
	random_source: RandomSource,
) -> bool:
	var player: PlayerMatchProfile = context.offense_profile(rebounder_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(rebounder_id)
	var finish: float = _capability.capability_of(
		CapabilityKey.Value.RIM_TOUCH_FINISH, player, runtime)
	var best_defender: float = 0.0
	for defender_id in context.defense_on_court():
		var defender: PlayerMatchProfile = context.defense_profile(defender_id)
		var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)
		best_defender = maxf(best_defender, _capability.capability_of(
			CapabilityKey.Value.RIM_PROTECTION, defender, defender_runtime))
	var units: float = _capability.differential_units(finish, best_defender)
	var aggression: float = _balance.tendency_multiplier(
		player.tendencies.at(TendencySlider.Value.PATIENT_AGGRESSIVE))
	var probability: float = _balance.opposed_probability(
		_balance.putback_base * aggression,
		units,
		_balance.putback_floor,
		_balance.putback_ceiling)
	return random_source.next_float() < probability


func _pick(
	ids: Array[StringName],
	scores: Array[float],
	random_source: RandomSource,
) -> StringName:
	var total: float = 0.0
	for score in scores:
		total += score
	assert(total > 0.0, "rebound candidates must retain positive total score")
	var draw: float = random_source.next_float() * total
	var cumulative: float = 0.0
	for index in range(ids.size()):
		cumulative += scores[index]
		if draw <= cumulative:
			return ids[index]
	return ids[ids.size() - 1]
