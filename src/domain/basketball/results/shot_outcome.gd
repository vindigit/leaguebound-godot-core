class_name ShotOutcome
extends RefCounted

## The resolved result of one field-goal attempt (`SIMULATION_SPEC.md` §12.6,
## §12.7).
##
## Block evaluation runs *before* ordinary make resolution when the defender has
## a valid block opportunity (§12.7), so a blocked attempt is a distinct state
## rather than a miss with a flag bolted on afterwards. "A block is credited
## only when it produces a blocked-shot event."

var made: bool
var blocked: bool
var points: int
var probability: float
var zone: int
var dunk: bool
var blocker_id: StringName
var contest: ShotContest


func _init(
	p_made: bool = false,
	p_points: int = 2,
	p_probability: float = 0.0,
	p_zone: int = ShotZone.Value.MIDRANGE,
	p_dunk: bool = false,
	p_blocked: bool = false,
	p_blocker_id: StringName = &"",
	p_contest: ShotContest = null,
) -> void:
	assert(p_points == 2 or p_points == 3, "field goals must be worth two or three points")
	assert(p_probability >= 0.0 and p_probability <= 1.0, "shot probability is invalid")
	assert(ShotZone.is_valid(p_zone), "unknown shot zone")
	assert(not (p_made and p_blocked), "a blocked attempt cannot also be a make")
	made = p_made
	points = p_points
	probability = p_probability
	zone = p_zone
	dunk = p_dunk
	blocked = p_blocked
	blocker_id = p_blocker_id
	contest = p_contest if p_contest != null else ShotContest.new()


## A missed attempt is reboundable unless the shooting foul made it dead. The
## possession engine owns that distinction; this is the ordinary case.
func is_reboundable_miss() -> bool:
	return not made
