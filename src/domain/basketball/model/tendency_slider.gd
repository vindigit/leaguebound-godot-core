class_name TendencySlider
extends RefCounted

## Stable names for the ten five-position sliders in `SIMULATION_SPEC.md` §10.4,
## in the order that document lists them.
##
## The engine previously reached into `PlayerTendencies.at(1)` with a bare
## index, which is exactly how a slider silently becomes the wrong slider. Every
## consumer now names the behaviour it is reading.
##
## §10.4: "Slider positions map to centered bounded multipliers. They never
## modify ratings or permanent coach instructions." Position 3 is neutral, and
## the multiplier table itself belongs to `SimulationBalanceProfile` (§12.1),
## not here.


enum Value {
	PASS_FIRST_SCORE_FIRST,
	PATIENT_AGGRESSIVE,
	PERIMETER_INTERIOR,
	CREATE_OWN_SHOT_OFF_BALL,
	SAFE_CREATIVE_PASSING,
	PUSH_TRANSITION_CONTROL_TEMPO,
	DISCIPLINED_GAMBLE,
	STAY_ATTACHED_HELP,
	BOX_OUT_CHASE_REBOUNDS,
	DEFER_SEEK_CLUTCH,
}

const COUNT: int = 10
const IDS: PackedStringArray = [
	"pass_first_score_first",
	"patient_aggressive",
	"perimeter_interior",
	"create_own_shot_off_ball",
	"safe_creative_passing",
	"push_transition_control_tempo",
	"disciplined_gamble",
	"stay_attached_help",
	"box_out_chase_rebounds",
	"defer_seek_clutch",
]

const NEUTRAL_POSITION: int = 3


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown tendency slider")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown tendency slider id")
	return Value.PATIENT_AGGRESSIVE
