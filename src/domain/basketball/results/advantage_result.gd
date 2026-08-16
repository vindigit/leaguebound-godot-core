class_name AdvantageResult
extends RefCounted

## `SIMULATION_SPEC.md` §11.1: "Actions create an `AdvantageResult` before a
## shot or terminal outcome."
##
## The advantage carries forward: it feeds the shot's make quality (§12.6), the
## live-ball turnover risk (§11.2), the foul pressure (§13.1), and the set of
## continuations the possession may choose next. That is what makes a possession
## a chain rather than a single roll.

var level: int
var creator_id: StringName
var beneficiary_id: StringName
## Whether the defense had to rotate, which opens skip and interior passes.
var defense_rotated: bool
## Whether a screen action produced a switched matchup.
var switch_occurred: bool
var turnover_risk: float
var foul_pressure: float


func _init(
	p_level: int = AdvantageLevel.Value.NONE,
	p_creator_id: StringName = &"",
	p_beneficiary_id: StringName = &"",
	p_defense_rotated: bool = false,
	p_switch_occurred: bool = false,
	p_turnover_risk: float = 0.0,
	p_foul_pressure: float = 0.0,
) -> void:
	assert(AdvantageLevel.is_valid(p_level), "unknown advantage level")
	assert(p_turnover_risk >= 0.0 and p_turnover_risk <= 1.0, "turnover risk must be normalized")
	assert(p_foul_pressure >= 0.0 and p_foul_pressure <= 1.0, "foul pressure must be normalized")
	level = p_level
	creator_id = p_creator_id
	beneficiary_id = p_beneficiary_id
	defense_rotated = p_defense_rotated
	switch_occurred = p_switch_occurred
	turnover_risk = p_turnover_risk
	foul_pressure = p_foul_pressure


func level_id() -> StringName:
	return AdvantageLevel.id_of(level)


func quality_share() -> float:
	return AdvantageLevel.quality_share(level)


func is_material() -> bool:
	return level >= AdvantageLevel.Value.CLEAR
