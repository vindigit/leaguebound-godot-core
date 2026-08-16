class_name CapabilityKey
extends RefCounted

## The derived basketball capabilities defined by `SIMULATION_SPEC.md` §7 and
## weighted by `BALANCE_SPEC.md` §5.2.
##
## A capability is "a pure, versioned function of current ratings, body, active
## badges, and match context" (§7). Resolvers consume capabilities; they never
## re-derive rating weights of their own. That single rule is what keeps the
## twenty public ratings honest — one owning module, one weight table, one
## version.


enum Value {
	# §7.1 offensive
	BALL_SECURITY,
	HANDLE_CREATION,
	PASS_ACCURACY,
	PASS_READ_QUALITY,
	SHOT_SELECTION,
	RIM_TOUCH_FINISH,
	DUNK_THREAT,
	MIDRANGE_SHOTMAKING,
	THREE_POINT_SHOTMAKING,
	FREE_THROW_SHOTMAKING,
	OFF_BALL_TIMING,
	OFFENSIVE_REBOUND_POSITIONING,
	# §7.2 defensive
	POINT_OF_ATTACK_CONTAINMENT,
	PERIMETER_CONTEST,
	INTERIOR_POSITIONING,
	RIM_PROTECTION,
	PASSING_LANE_DEFENSE,
	ON_BALL_DISRUPTION,
	HELP_RECOGNITION,
	DEFENSIVE_REBOUND_POSITIONING,
	# §7.3 physical
	COURT_SPEED,
	CONTACT_FORCE,
	BURST_REACH,
	WORK_CAPACITY,
}

const COUNT: int = 24
const IDS: PackedStringArray = [
	"ball_security",
	"handle_creation",
	"pass_accuracy",
	"pass_read_quality",
	"shot_selection",
	"rim_touch_finish",
	"dunk_threat",
	"midrange_shotmaking",
	"three_point_shotmaking",
	"free_throw_shotmaking",
	"off_ball_timing",
	"offensive_rebound_positioning",
	"point_of_attack_containment",
	"perimeter_contest",
	"interior_positioning",
	"rim_protection",
	"passing_lane_defense",
	"on_ball_disruption",
	"help_recognition",
	"defensive_rebound_positioning",
	"court_speed",
	"contact_force",
	"burst_reach",
	"work_capacity",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown capability key")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown capability id")
	return Value.WORK_CAPACITY


## The shot capability that resolves an attempt from a given zone.
static func shotmaking_for_zone(zone: int) -> int:
	match zone:
		ShotZone.Value.RESTRICTED_RIM, ShotZone.Value.CLOSE_NON_RIM:
			return Value.RIM_TOUCH_FINISH
		ShotZone.Value.MIDRANGE:
			return Value.MIDRANGE_SHOTMAKING
		ShotZone.Value.STANDARD_THREE, ShotZone.Value.DEEP_THREE:
			return Value.THREE_POINT_SHOTMAKING
		_:
			assert(false, "unknown shot zone")
	return Value.MIDRANGE_SHOTMAKING
