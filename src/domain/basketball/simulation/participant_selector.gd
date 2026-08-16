class_name ParticipantSelector
extends RefCounted

## Chooses who is involved, under a constrained team usage budget.
##
## The Stage 3 contract is specific: "Treat usage/opportunity as a constrained
## team budget. High-capability players can earn more opportunity, but no rating
## alone forces every touch."
##
## That is implemented as a target share and a damping term. The target comes
## from `SIMULATION_SPEC.md` §10.6.4's separation — tactical role sets the
## opportunity, tendencies set the preference, capability and context set the
## quality — and realized usage is pulled back toward it with a bounded
## elasticity. Raising a player's opportunity inputs always raises his share
## (monotonic), but no combination of inputs lets one player consume the whole
## budget.

var _capability: CapabilityCalculator
var _balance: SimulationBalanceProfile

## The on-ball families whose role opportunity defines an initiator's claim to
## the ball. Off-ball families deliberately do not count: a Shooter's high
## relocation opportunity should not make him the primary ball handler.
const INITIATOR_FAMILIES: Array[int] = [
	ActionFamily.Value.PICK_ACTION,
	ActionFamily.Value.DRIVE,
	ActionFamily.Value.PULL_UP,
	ActionFamily.Value.PASS_SWING,
]


func _init(p_capability: CapabilityCalculator, p_balance: SimulationBalanceProfile) -> void:
	_capability = p_capability
	_balance = p_balance


## The opportunity claim of one offensive player, before usage damping. Every
## term is one of the §10.6.4 layers, and none of them is a capability shortcut.
func opportunity_index(context: PossessionContext, player_id: StringName) -> float:
	var player: PlayerMatchProfile = context.offense_profile(player_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(player_id)
	var role_share: float = 0.0
	for family in INITIATOR_FAMILIES:
		role_share += _balance.role_opportunity(player.tactical_role.role, family)
	role_share /= float(INITIATOR_FAMILIES.size())

	# Tendency: a score-first, create-own-shot player asks for the ball more.
	var score_first: float = _balance.tendency_multiplier(
		player.tendencies.at(TendencySlider.Value.PASS_FIRST_SCORE_FIRST))
	var create_own: float = _balance.opposing_tendency_multiplier(
		player.tendencies.at(TendencySlider.Value.CREATE_OWN_SHOT_OFF_BALL))
	var preference: float = pow(
		sqrt(score_first * create_own), _balance.player_preference_share)

	var creation: float = _capability.capability_of(
		CapabilityKey.Value.HANDLE_CREATION, player, runtime)
	var security: float = _capability.capability_of(
		CapabilityKey.Value.BALL_SECURITY, player, runtime)
	var confidence: float = lerpf(
		_balance.capability_confidence_min,
		_balance.capability_confidence_max,
		clampf(creation * 0.6 + security * 0.4, 0.0, 1.0))
	return role_share * preference * confidence * fatigue_availability(runtime)


## §12.2 fatigue availability. Bounded below at 0.55 "when still medically
## available", so exhaustion suppresses involvement without erasing it.
func fatigue_availability(runtime: PlayerMatchRuntime) -> float:
	var energy: float = runtime.current_energy()
	var value: float = lerpf(_balance.fatigue_availability_floor, 1.0, energy)
	return clampf(value, _balance.fatigue_availability_floor, 1.0)


## The whole lineup's opportunity indices, resolved once.
##
## The budget is a team-level quantity — every player's damping depends on every
## other player's claim — so resolving it per player made it quadratic in the
## lineup and made candidate generation the slowest thing in the engine.
func opportunity_table(context: PossessionContext) -> Dictionary:
	var table: Dictionary = {}
	for player_id in context.offense_on_court():
		table[player_id] = opportunity_index(context, player_id)
	return table


## The constrained-budget term for every player on court. Above-target usage
## damps a player down; below-target usage lifts him up; the bounds keep both
## finite, so no rating combination lets one player consume the whole budget.
func usage_damping_table(context: PossessionContext) -> Dictionary:
	var opportunities: Dictionary = opportunity_table(context)
	var on_court: Array[StringName] = context.offense_on_court()
	var total_opportunity: float = 0.0
	var total_usage: int = 0
	for player_id in on_court:
		var opportunity: float = opportunities[player_id]
		total_opportunity += opportunity
		total_usage += context.offense_runtime(player_id).usage_events
	var damping: Dictionary = {}
	if total_opportunity <= 0.0:
		for player_id in on_court:
			damping[player_id] = 1.0
		return damping
	# The smoothing term keeps the first few touches of a game from swinging the
	# ratio wildly; it decays as real usage accumulates.
	var smoothing: float = float(on_court.size())
	for player_id in on_court:
		var opportunity: float = opportunities[player_id]
		var target_share: float = opportunity / total_opportunity
		var realized_share: float = (
			(float(context.offense_runtime(player_id).usage_events) + smoothing * target_share)
			/ (float(total_usage) + smoothing)
		)
		if realized_share <= 0.0:
			damping[player_id] = _balance.usage_damping_max
			continue
		damping[player_id] = clampf(
			pow(target_share / realized_share, _balance.usage_elasticity),
			_balance.usage_damping_min,
			_balance.usage_damping_max)
	return damping


## Who brings the ball into the action. Weighted, not deterministic: §18.3
## expects a low-role game to be possible, and a fixed initiator would make
## every possession identical.
func select_initiator(context: PossessionContext, random_source: RandomSource) -> StringName:
	var on_court: Array[StringName] = context.offense_on_court()
	assert(not on_court.is_empty(), "a possession requires offensive players on court")
	var opportunities: Dictionary = opportunity_table(context)
	var damping: Dictionary = usage_damping_table(context)
	var weights: Array[float] = []
	for player_id in on_court:
		var opportunity: float = opportunities[player_id]
		var usage: float = damping[player_id]
		weights.append(maxf(opportunity * usage, 0.0001))
	return _weighted_pick(on_court, weights, random_source)


## The screener for a pick action: the teammate whose screening opportunity and
## contact force best serve the handler.
func select_screener(context: PossessionContext, handler_id: StringName) -> StringName:
	var best_id: StringName = &""
	var best_score: float = -INF
	for player_id in context.offense_on_court():
		if player_id == handler_id:
			continue
		var player: PlayerMatchProfile = context.offense_profile(player_id)
		var runtime: PlayerMatchRuntime = context.offense_runtime(player_id)
		var score: float = (
			_balance.role_opportunity(player.tactical_role.role, ActionFamily.Value.SCREEN)
			+ _capability.capability_of(CapabilityKey.Value.CONTACT_FORCE, player, runtime)
		)
		if score > best_score + 0.000001 or (
			absf(score - best_score) <= 0.000001 and String(player_id) < String(best_id)
		):
			best_score = score
			best_id = player_id
	return best_id


func _weighted_pick(
	ids: Array[StringName],
	weights: Array[float],
	random_source: RandomSource,
) -> StringName:
	var total: float = 0.0
	for weight in weights:
		total += weight
	assert(total > 0.0, "a weighted selection requires positive total weight")
	var draw: float = random_source.next_float() * total
	var cumulative: float = 0.0
	for index in range(ids.size()):
		cumulative += weights[index]
		if draw <= cumulative:
			return ids[index]
	return ids[ids.size() - 1]
