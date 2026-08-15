class_name GrowthIncrement
extends RefCounted

## One resolved body growth increment (`SIMULATION_SPEC.md` §6.3
## `RESOLVE_GROWTH_INCREMENT`).
##
## Ledger entries are the evidence that an increment resolved *exactly once* for
## a career year. §6.3 makes growth idempotent per career year under the shared
## completion-receipt rules: reloading, changing level, or changing simulation
## tier cannot re-resolve or skip an increment.
##
## An increment records the resulting body, never a rating. §7.4.3 rule 4 is
## explicit that "a body increment may not alter any of the 20 public ratings as
## a side effect"; where design intends a rating consequence it resolves as a
## separate, visible, ledgered progression effect.


var career_year: int
var height_delta: int
var weight_delta: int
var wingspan_delta: int
var standing_reach_delta: int
var resulting_body: BodyProfile


func _init(
	p_career_year: int,
	p_height_delta: int,
	p_weight_delta: int,
	p_wingspan_delta: int,
	p_standing_reach_delta: int,
	p_resulting_body: BodyProfile,
) -> void:
	assert(p_career_year > 0, "a growth increment belongs to a real career year")
	assert(p_resulting_body != null, "a growth increment records the body it produced")
	career_year = p_career_year
	height_delta = p_height_delta
	weight_delta = p_weight_delta
	wingspan_delta = p_wingspan_delta
	standing_reach_delta = p_standing_reach_delta
	resulting_body = p_resulting_body


func signature() -> String:
	return "year=%d;dh=%d;dw=%d;dws=%d;dsr=%d;%s" % [
		career_year,
		height_delta,
		weight_delta,
		wingspan_delta,
		standing_reach_delta,
		resulting_body.signature(),
	]
