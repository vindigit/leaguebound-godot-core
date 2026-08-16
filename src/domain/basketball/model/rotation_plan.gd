class_name RotationPlan
extends RefCounted

## The planned rotation a coach creates before tipoff (`SIMULATION_SPEC.md`
## §18.1): starters, planned minute shares, substitution priority, closing
## lineup, and emergency depth order.
##
## §18.2 is the reason this is a *plan* and not a per-possession optimizer:
## "The engine does not recalculate optimal rotations from scratch every
## possession. Stability is part of coaching identity." The runtime adjusts it
## for foul trouble, fatigue, injury, score, matchup, and overtime — nothing
## else.
##
## Planned minutes come from rotation role and only from rotation role
## (`BALANCE_SPEC.md` §12.4). Tactical role never appears here.

var starters: Array[StringName]
## Substitution priority order: the first available player enters first.
var substitution_order: Array[StringName]
## Players the coach prefers to finish with, in priority order.
var closing_lineup: Array[StringName]
## Planned share of team on-court seconds, keyed by player id.
var planned_minute_share: Dictionary


func _init(
	p_starters: Array[StringName] = [],
	p_substitution_order: Array[StringName] = [],
	p_closing_lineup: Array[StringName] = [],
	p_planned_minute_share: Dictionary = {},
) -> void:
	starters = p_starters.duplicate()
	substitution_order = p_substitution_order.duplicate()
	closing_lineup = p_closing_lineup.duplicate()
	planned_minute_share = p_planned_minute_share.duplicate()


func share_for(player_id: StringName) -> float:
	if not planned_minute_share.has(player_id):
		return 0.0
	var share: float = planned_minute_share[player_id]
	return share


## Builds the ordinary plan: the supplied starters, the remaining roster ordered
## by rotation-role priority then by stable player id, and role-derived minute
## shares. Ties break on player id so the plan is canonical before any
## randomness is consumed (`GODOT_TDD.md` §5.2).
static func from_roster(
	players: Array[PlayerMatchProfile],
	starters: Array[StringName],
	balance: SimulationBalanceProfile,
) -> RotationPlan:
	var shares: Dictionary = {}
	var bench: Array[PlayerMatchProfile] = []
	for player in players:
		shares[player.player_id] = balance.rotation_minute_share(player.rotation_role)
		if not starters.has(player.player_id):
			bench.append(player)
	bench.sort_custom(func(left: PlayerMatchProfile, right: PlayerMatchProfile) -> bool:
		if left.rotation_role != right.rotation_role:
			return left.rotation_role < right.rotation_role
		return String(left.player_id) < String(right.player_id))
	var order: Array[StringName] = []
	for player in bench:
		order.append(player.player_id)
	var closing: Array[StringName] = []
	var ranked: Array[PlayerMatchProfile] = players.duplicate()
	ranked.sort_custom(func(left: PlayerMatchProfile, right: PlayerMatchProfile) -> bool:
		if left.rotation_role != right.rotation_role:
			return left.rotation_role < right.rotation_role
		return String(left.player_id) < String(right.player_id))
	for index in range(mini(5, ranked.size())):
		closing.append(ranked[index].player_id)
	return RotationPlan.new(starters, order, closing, shares)
