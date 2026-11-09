class_name RestartClockMode
extends RefCounted

## Whether the game clock is already running as the next possession begins, or
## whether it is stopped and starts on the throw-in's legal touch
## (`SIMULATION_SPEC.md` §9.4, `PROJECT_STATUS.md` §5.30, §5.31).
##
## Two values, because the basketball question has two answers. It is a separate
## type from `RestartCause` on purpose: the cause is what happened, the mode is
## what the rules make of it, and the same cause produces different modes in
## different competitions. Folding them together would put a competition rule
## inside a description of an event.
##
## Nothing writes a mode into state. It is derived where it is needed, by
## `RestartClockPolicy` and by nothing else, so there is no second clock system
## to keep in step with the one `ClockResolver` and `MatchEventWriter` already
## own.


enum Value {
	## The clock never stopped, so the seconds spent taking the ball out are
	## seconds the offence genuinely loses. `ClockResolver.running_clock_inbound_ms`
	## is what they cost.
	CLOCK_ALREADY_RUNNING,
	## The clock is stopped and restarts on the legal touch, so retrieving the
	## ball, the official's administration, and the throw-in itself cost the
	## offence nothing and `INBOUND` emits at the possession's starting clock.
	STARTS_ON_LEGAL_TOUCH,
}

const COUNT: int = 2
const IDS: PackedStringArray = [
	"clock_already_running",
	"starts_on_legal_touch",
]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown restart clock mode")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown restart clock mode id")
	return Value.STARTS_ON_LEGAL_TOUCH


## Whether the throw-in costs live game clock under this mode.
static func charges_game_clock(value: int) -> bool:
	assert(is_valid(value), "unknown restart clock mode")
	return value == Value.CLOCK_ALREADY_RUNNING
