class_name CoverageFamily
extends RefCounted

## `SIMULATION_SPEC.md` §15.2 launch coverage abstractions.
##
## "Coverage changes candidate actions, spacing, matchup responsibilities, and
## help timing. It does not apply one flat team defense multiplier." Every
## consumer of this enum must therefore change a *specific* term — switch
## probability, help arrival, or containment share — never a global scalar.


enum Value {
	MAN_STAY_HOME,
	SWITCH,
	DROP,
	HEDGE_RECOVER,
	TRAP_BLITZ,
	ZONE,
	HELP_HEAVY,
	PRESSURE,
}

const COUNT: int = 8
const IDS: PackedStringArray = [
	"man_stay_home",
	"switch",
	"drop",
	"hedge_recover",
	"trap_blitz",
	"zone",
	"help_heavy",
	"pressure",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown coverage family")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown coverage family id")
	return Value.MAN_STAY_HOME


## How readily a screen action produces a switched matchup.
static func switch_share(value: int) -> float:
	match value:
		Value.SWITCH:
			return 0.85
		Value.MAN_STAY_HOME:
			return 0.10
		Value.DROP:
			return 0.05
		Value.HEDGE_RECOVER:
			return 0.15
		Value.TRAP_BLITZ:
			return 0.20
		Value.ZONE:
			return 0.40
		Value.HELP_HEAVY:
			return 0.30
		Value.PRESSURE:
			return 0.25
		_:
			assert(false, "unknown coverage family")
	return 0.0


## How much weak-side help arrives on an interior attempt.
static func help_share(value: int) -> float:
	match value:
		Value.SWITCH:
			return 0.35
		Value.MAN_STAY_HOME:
			return 0.20
		Value.DROP:
			return 0.65
		Value.HEDGE_RECOVER:
			return 0.45
		Value.TRAP_BLITZ:
			return 0.55
		Value.ZONE:
			return 0.60
		Value.HELP_HEAVY:
			return 0.80
		Value.PRESSURE:
			return 0.30
		_:
			assert(false, "unknown coverage family")
	return 0.0


## How much on-ball pressure the coverage applies, raising both live-ball
## turnover exposure and the defense's own foul exposure.
static func ball_pressure_share(value: int) -> float:
	match value:
		Value.SWITCH:
			return 0.45
		Value.MAN_STAY_HOME:
			return 0.45
		Value.DROP:
			return 0.25
		Value.HEDGE_RECOVER:
			return 0.55
		Value.TRAP_BLITZ:
			return 0.90
		Value.ZONE:
			return 0.30
		Value.HELP_HEAVY:
			return 0.40
		Value.PRESSURE:
			return 0.85
		_:
			assert(false, "unknown coverage family")
	return 0.0
