class_name ShotContest
extends RefCounted

## `SIMULATION_SPEC.md` §12.3.
##
## "Contest is created from actual defensive positioning and capabilities. It is
## not selected as independent random flavor after shot probability is known."
## The band therefore arrives with the defender who produced it, and the
## pressure that produced the band is retained so a trace can explain it.

var band: int
var primary_defender_id: StringName
var helper_id: StringName
var block_eligible: bool
var altered: bool
var pressure: float
## Bounded legal contact, which feeds the §13.1 foul opportunity rather than
## the make probability.
var legal_contact: float


func _init(
	p_band: int = ContestBand.Value.OPEN,
	p_primary_defender_id: StringName = &"",
	p_helper_id: StringName = &"",
	p_block_eligible: bool = false,
	p_altered: bool = false,
	p_pressure: float = 0.0,
	p_legal_contact: float = 0.0,
) -> void:
	assert(ContestBand.is_valid(p_band), "unknown contest band")
	assert(p_pressure >= 0.0 and p_pressure <= 1.0, "contest pressure must be normalized")
	assert(p_legal_contact >= 0.0 and p_legal_contact <= 1.0, "legal contact must be normalized")
	band = p_band
	primary_defender_id = p_primary_defender_id
	helper_id = p_helper_id
	block_eligible = p_block_eligible
	altered = p_altered
	pressure = p_pressure
	legal_contact = p_legal_contact


func band_id() -> StringName:
	return ContestBand.id_of(band)
