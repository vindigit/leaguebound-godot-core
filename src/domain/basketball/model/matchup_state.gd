class_name MatchupState
extends RefCounted

## Live defensive assignments (`SIMULATION_SPEC.md` §15.1).
##
## "Defensive assignments derive from positions, tactical roles, lineup
## capability, coach plan, switches, and game context. The engine can
## temporarily reassign after transition or screening actions without
## permanently changing the plan."
##
## The known defect this closes is blunt: defenders used to be drawn uniformly
## at random, so a Perimeter Stopper guarded the opposing centre one possession
## in five. Assignments now come from the plan, and a switch is a recorded event
## with a cause, not a fresh draw.

var _defender_by_offense: Dictionary
var _offense_by_defender: Dictionary


func _init(
	p_defender_by_offense: Dictionary = {},
) -> void:
	_defender_by_offense = p_defender_by_offense.duplicate()
	_offense_by_defender = {}
	for offense_id: StringName in _defender_by_offense.keys():
		var defender_id: StringName = _defender_by_offense[offense_id]
		_offense_by_defender[defender_id] = offense_id


func has_assignment(offense_player_id: StringName) -> bool:
	return _defender_by_offense.has(offense_player_id)


func defender_for(offense_player_id: StringName) -> StringName:
	if not _defender_by_offense.has(offense_player_id):
		return &""
	var defender_id: StringName = _defender_by_offense[offense_player_id]
	return defender_id


func assignment_of(defender_id: StringName) -> StringName:
	if not _offense_by_defender.has(defender_id):
		return &""
	var offense_id: StringName = _offense_by_defender[defender_id]
	return offense_id


## A temporary reassignment after a screen or transition. §15.1 permits this
## without changing the coach's plan, so the switch mutates live state only.
func switch(first_offense_id: StringName, second_offense_id: StringName) -> void:
	if not has_assignment(first_offense_id) or not has_assignment(second_offense_id):
		return
	var first_defender: StringName = defender_for(first_offense_id)
	var second_defender: StringName = defender_for(second_offense_id)
	_defender_by_offense[first_offense_id] = second_defender
	_defender_by_offense[second_offense_id] = first_defender
	_offense_by_defender[second_defender] = first_offense_id
	_offense_by_defender[first_defender] = second_offense_id


func copy() -> MatchupState:
	return MatchupState.new(_defender_by_offense)


## Canonical text for traces and for the assignment tests.
func signature() -> String:
	var keys: Array[StringName] = []
	for offense_id: StringName in _defender_by_offense.keys():
		keys.append(offense_id)
	keys.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right))
	var parts: PackedStringArray = []
	for offense_id in keys:
		parts.append("%s>%s" % [offense_id, defender_for(offense_id)])
	return ",".join(parts)
