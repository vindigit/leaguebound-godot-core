class_name TacticalLocation
extends RefCounted

## `SIMULATION_SPEC.md` §16.1: "The domain tracks normalized court location and
## role state, not animation pixels."
##
## Version 1.0 keeps this deliberately coarse. Location exists so rebound
## positioning, contest arrival, help distance, and action validity have a real
## spatial input rather than a hidden constant. Presentation interpolates smooth
## motion between these authoritative frames (§16.2); nothing here is a
## rendering concern.


enum Lane { LEFT, CENTER, RIGHT }

enum Depth {
	RIM,
	PAINT,
	SHORT_MIDRANGE,
	LONG_MIDRANGE,
	ARC,
	DEEP,
	BACKCOURT,
}

const LANE_IDS: PackedStringArray = ["left", "center", "right"]
const DEPTH_IDS: PackedStringArray = [
	"rim",
	"paint",
	"short_midrange",
	"long_midrange",
	"arc",
	"deep",
	"backcourt",
]

var lane: int
var depth: int
var movement_intent: int


func _init(
	p_lane: int = Lane.CENTER,
	p_depth: int = Depth.ARC,
	p_movement_intent: int = MovementIntent.Value.RELOCATE,
) -> void:
	assert(p_lane >= 0 and p_lane < LANE_IDS.size(), "unknown lane")
	assert(p_depth >= 0 and p_depth < DEPTH_IDS.size(), "unknown depth")
	assert(MovementIntent.is_valid(p_movement_intent), "unknown movement intent")
	lane = p_lane
	depth = p_depth
	movement_intent = p_movement_intent


func lane_id() -> StringName:
	return StringName(LANE_IDS[lane])


func depth_id() -> StringName:
	return StringName(DEPTH_IDS[depth])


## Normalized distance from the rim, used by rebound positioning and contest
## arrival. Zero is at the rim; one is the far edge of live offensive space.
func rim_distance() -> float:
	return rim_distance_for_depth(depth)


## The same ladder, addressable without building a location. `ShotResolver`
## compares an attempt's actual location against the distance its own zone
## implies, and needs the second of those two without a frame to hang it on.
static func rim_distance_for_depth(depth_value: int) -> float:
	match depth_value:
		Depth.RIM:
			return 0.0
		Depth.PAINT:
			return 0.15
		Depth.SHORT_MIDRANGE:
			return 0.35
		Depth.LONG_MIDRANGE:
			return 0.52
		Depth.ARC:
			return 0.70
		Depth.DEEP:
			return 0.85
		Depth.BACKCOURT:
			return 1.0
		_:
			assert(false, "unknown depth")
	return 1.0


static func depth_for_zone(zone: int) -> int:
	match zone:
		ShotZone.Value.RESTRICTED_RIM:
			return Depth.RIM
		ShotZone.Value.CLOSE_NON_RIM:
			return Depth.PAINT
		ShotZone.Value.MIDRANGE:
			return Depth.LONG_MIDRANGE
		ShotZone.Value.STANDARD_THREE:
			return Depth.ARC
		ShotZone.Value.DEEP_THREE:
			return Depth.DEEP
		_:
			assert(false, "unknown shot zone")
	return Depth.ARC


func signature() -> String:
	return "%s/%s/%s" % [lane_id(), depth_id(), MovementIntent.id_of(movement_intent)]
