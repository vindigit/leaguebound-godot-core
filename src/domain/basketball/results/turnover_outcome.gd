class_name TurnoverOutcome
extends RefCounted

## `SIMULATION_SPEC.md` §11.2: "Turnovers require a cause and actor
## attribution."
##
## The defender is recorded even when no steal is credited, because a bad pass
## forced by pressure and a bad pass thrown into an empty gym are different
## events for role evaluation — but only `TurnoverCause.credits_steal` turns
## that defender into a steal in the box score.

var occurred: bool
var cause: int
var offender_id: StringName
var defender_id: StringName


func _init(
	p_occurred: bool = false,
	p_cause: int = TurnoverCause.Value.LOST_HANDLE,
	p_offender_id: StringName = &"",
	p_defender_id: StringName = &"",
) -> void:
	assert(TurnoverCause.is_valid(p_cause), "unknown turnover cause")
	occurred = p_occurred
	cause = p_cause
	offender_id = p_offender_id
	defender_id = p_defender_id


func cause_id() -> StringName:
	return TurnoverCause.id_of(cause)


## A steal is credited "only when a defender caused a qualifying live-ball
## turnover" (§11.2), so both conditions are checked here rather than at each
## call site.
func credits_steal() -> bool:
	return occurred and TurnoverCause.credits_steal(cause) and not defender_id.is_empty()


static func none() -> TurnoverOutcome:
	return TurnoverOutcome.new()
