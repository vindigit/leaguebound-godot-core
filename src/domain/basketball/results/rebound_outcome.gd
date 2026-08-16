class_name ReboundOutcome
extends RefCounted

## One resolved rebound (`SIMULATION_SPEC.md` §14).
##
## The team outcome and the individual rebounder are resolved separately and
## both are recorded, because the offensive rebound *rate* is a team-level
## calibration target (§27.2) while the rebound *share* is a player-level one
## (§27.3). Collapsing them would make one of the two untunable.

var rebounder_id: StringName
var team_id: StringName
var offensive: bool
## The offensive-rebound probability actually used, retained for traces and for
## the ORB / (ORB + opponent DREB) denominator check.
var offensive_probability: float


func _init(
	p_rebounder_id: StringName = &"",
	p_team_id: StringName = &"",
	p_offensive: bool = false,
	p_offensive_probability: float = 0.0,
) -> void:
	assert(not p_rebounder_id.is_empty(), "a rebound requires an individual rebounder")
	assert(not p_team_id.is_empty(), "a rebound requires a team")
	assert(p_offensive_probability >= 0.0 and p_offensive_probability <= 1.0,
		"the offensive rebound probability must be normalized")
	rebounder_id = p_rebounder_id
	team_id = p_team_id
	offensive = p_offensive
	offensive_probability = p_offensive_probability


func side_id() -> StringName:
	return MatchDomainEvent.REBOUND_OFFENSIVE if offensive else MatchDomainEvent.REBOUND_DEFENSIVE
