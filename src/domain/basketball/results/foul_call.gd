class_name FoulCall
extends RefCounted

## One resolved illegal-contact call (`SIMULATION_SPEC.md` §13).
##
## §13.1 requires the engine to distinguish shooting, non-shooting, offensive,
## loose-ball, and intentional fouls "at the abstraction needed for rules and
## statistics", because those five branch differently: only some award free
## throws, only some transfer the possession, and an offensive foul charges the
## other team's counter.
##
## The Stage 3 contract also forbids the shortcut this type exists to prevent:
## "Do not tune a generic once-per-possession foul probability upward to
## manufacture the desired total." A `FoulCall` is only ever constructed from a
## valid contact opportunity produced by a real action.

var occurred: bool
var foul_type: int
var fouler_id: StringName
var drawn_by_id: StringName
## Free throws awarded by this call, before any one-and-one branch.
var free_throws: int
## Whether the second attempt of a one-and-one still has to be earned.
var one_and_one: bool
## True when the foul happened on a made field goal (§13 and-one).
var and_one: bool
## The zone of the fouled attempt, used for the three-shot case.
var shooting_zone: int


func _init(
	p_occurred: bool = false,
	p_foul_type: int = FoulType.Value.NON_SHOOTING_DEFENSIVE,
	p_fouler_id: StringName = &"",
	p_drawn_by_id: StringName = &"",
	p_free_throws: int = 0,
	p_one_and_one: bool = false,
	p_and_one: bool = false,
	p_shooting_zone: int = -1,
) -> void:
	assert(FoulType.is_valid(p_foul_type), "unknown foul type")
	assert(p_free_throws >= 0 and p_free_throws <= 3, "a single call awards at most three attempts")
	assert(p_shooting_zone == -1 or ShotZone.is_valid(p_shooting_zone), "unknown shot zone")
	occurred = p_occurred
	foul_type = p_foul_type
	fouler_id = p_fouler_id
	drawn_by_id = p_drawn_by_id
	free_throws = p_free_throws
	one_and_one = p_one_and_one
	and_one = p_and_one
	shooting_zone = p_shooting_zone


func type_id() -> StringName:
	return FoulType.id_of(foul_type)


static func none() -> FoulCall:
	return FoulCall.new()
