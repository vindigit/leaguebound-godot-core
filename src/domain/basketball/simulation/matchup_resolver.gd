class_name MatchupResolver
extends RefCounted

## Builds defensive assignments from the plan, not from a draw
## (`SIMULATION_SPEC.md` §15.1).
##
## Assignments derive from "positions, tactical roles, lineup capability, coach
## plan, switches, and game context". Tactical role is legitimate here — §10.6.2
## grants it "planned minutes and assignment in §18" alongside role opportunity
## — but it reaches only *who guards whom*, never how well the guarding goes.
##
## The resolution is fully deterministic. Assignment is a coaching decision, and
## a coach who reassigns his stopper at random every trip is not modelling
## anything. Randomness enters later, in whether the assignment holds.

var _capability: CapabilityCalculator
var _body: BodyEffects


func _init(p_capability: CapabilityCalculator, p_body: BodyEffects) -> void:
	_capability = p_capability
	_body = p_body


func resolve(
	offense: TeamMatchProfile,
	offense_state: TeamMatchState,
	defense: TeamMatchProfile,
	defense_state: TeamMatchState,
) -> MatchupState:
	var offense_ids: Array[StringName] = offense_state.on_court_ids()
	var defense_ids: Array[StringName] = defense_state.on_court_ids()
	assert(not offense_ids.is_empty() and not defense_ids.is_empty(),
		"assignments require both lineups on court")

	# Rank offensive players by the threat a defence actually plans around, then
	# hand the toughest assignment out first.
	var ranked: Array[StringName] = offense_ids.duplicate()
	var threats: Dictionary = {}
	for player_id in offense_ids:
		threats[player_id] = _offensive_threat(offense, offense_state, player_id)
	ranked.sort_custom(func(left: StringName, right: StringName) -> bool:
		var left_threat: float = threats[left]
		var right_threat: float = threats[right]
		if absf(left_threat - right_threat) > 0.000001:
			return left_threat > right_threat
		return String(left) < String(right))

	var remaining: Array[StringName] = defense_ids.duplicate()
	var assignments: Dictionary = {}
	for offense_id in ranked:
		var best_index: int = -1
		var best_score: float = -INF
		var threat: float = threats[offense_id]
		for index in range(remaining.size()):
			var score: float = _assignment_fit(
				offense, offense_state, offense_id,
				defense, defense_state, remaining[index],
				threat)
			if score > best_score + 0.000001:
				best_score = score
				best_index = index
			elif absf(score - best_score) <= 0.000001 and best_index >= 0:
				if String(remaining[index]) < String(remaining[best_index]):
					best_index = index
		assert(best_index >= 0, "every offensive player must receive an assignment")
		assignments[offense_id] = remaining[best_index]
		remaining.remove_at(best_index)
	return MatchupState.new(assignments)


## How much of a problem this offensive player is, as a defence would rank it:
## his best scoring capability, his creation, and his size.
func _offensive_threat(
	offense: TeamMatchProfile,
	offense_state: TeamMatchState,
	player_id: StringName,
) -> float:
	var player: PlayerMatchProfile = offense.player_by_id(player_id)
	var runtime: PlayerMatchRuntime = offense_state.runtime_by_id(player_id)
	var best_shot: float = 0.0
	for zone in ShotZone.all():
		best_shot = maxf(best_shot, _capability.shot_capability(player, runtime, zone))
	var creation: float = _capability.capability_of(
		CapabilityKey.Value.HANDLE_CREATION, player, runtime)
	var interior: float = _capability.capability_of(
		CapabilityKey.Value.RIM_TOUCH_FINISH, player, runtime)
	return best_shot * 0.45 + creation * 0.35 + interior * 0.20


## Fit of one defender for one assignment. Positive terms are containment,
## contest, size parity, and the coach's stated coverage intent; the size term
## is the §6.1 matchup channel and nothing else.
func _assignment_fit(
	offense: TeamMatchProfile,
	offense_state: TeamMatchState,
	offense_id: StringName,
	defense: TeamMatchProfile,
	defense_state: TeamMatchState,
	defender_id: StringName,
	threat: float,
) -> float:
	var attacker: PlayerMatchProfile = offense.player_by_id(offense_id)
	var defender: PlayerMatchProfile = defense.player_by_id(defender_id)
	var defender_runtime: PlayerMatchRuntime = defense_state.runtime_by_id(defender_id)
	var attacker_runtime: PlayerMatchRuntime = offense_state.runtime_by_id(offense_id)

	var interior_attacker: float = _capability.capability_of(
		CapabilityKey.Value.RIM_TOUCH_FINISH, attacker, attacker_runtime)
	var perimeter_share: float = clampf(1.0 - interior_attacker, 0.0, 1.0)
	var containment: float = _capability.capability_of(
		CapabilityKey.Value.POINT_OF_ATTACK_CONTAINMENT, defender, defender_runtime)
	var interior_defense: float = _capability.capability_of(
		CapabilityKey.Value.INTERIOR_POSITIONING, defender, defender_runtime)
	var coverage: float = containment * perimeter_share + interior_defense * (1.0 - perimeter_share)

	# Size parity: a defence prefers assignments where neither player is badly
	# out-sized. The absolute gap is the penalty, in either direction.
	var gap: float = absf(_body.size_mismatch(attacker.body, defender.body))
	var role_preference: float = _coverage_preference(defender.tactical_role.role, perimeter_share)
	return coverage * (0.55 + threat * 0.45) + role_preference * 0.20 - gap * 1.20


## The coverage the coach assigned this defender, expressed as a preference for
## perimeter or interior work. §10.6.2 permits role to shape assignment; the
## returned value never leaves this function to touch a probability.
func _coverage_preference(tactical_role: int, perimeter_share: float) -> float:
	match tactical_role:
		TacticalRole.Value.PERIMETER_STOPPER:
			return perimeter_share
		TacticalRole.Value.INTERIOR_ANCHOR:
			return 1.0 - perimeter_share
		TacticalRole.Value.UTILITY_ENERGY:
			return 0.25
		TacticalRole.Value.REBOUNDER:
			return (1.0 - perimeter_share) * 0.5
		_:
			return 0.0
