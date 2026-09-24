class_name FoulType
extends RefCounted

## `SIMULATION_SPEC.md` §13.1: "The engine distinguishes shooting,
## non-shooting, offensive, loose-ball, and intentional fouls at the
## abstraction needed for rules and statistics."
##
## The distinction is not cosmetic. It decides whether free throws are awarded,
## whether the bonus applies, whether the possession transfers, and which team's
## team-foul counter advances.


enum Value {
	SHOOTING,
	NON_SHOOTING_DEFENSIVE,
	OFFENSIVE,
	LOOSE_BALL,
	INTENTIONAL,
	## §13.1 deliberate late-game strategy, the leading side: a defence up
	## exactly three fouls before the tying three can be attempted. Distinct
	## from `INTENTIONAL`, which is the trailing side stopping the clock; the
	## two are never eligible at the same moment, but the ledger keeps them
	## separate rather than let one label carry two different decisions.
	LEADING_PROTECT,
}

const COUNT: int = 6
const IDS: PackedStringArray = [
	"shooting",
	"non_shooting_defensive",
	"offensive",
	"loose_ball",
	"intentional",
	"leading_protect",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown foul type")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown foul type id")
	return Value.NON_SHOOTING_DEFENSIVE


## An offensive foul is charged to the offense and ends the possession as a
## turnover (§11.2 `OFFENSIVE_FOUL`); every other type is charged to the
## defense.
static func is_charged_to_offense(value: int) -> bool:
	return value == Value.OFFENSIVE


## Only defensive fouls advance the team-foul counter that drives the bonus.
static func advances_team_fouls(value: int) -> bool:
	return not is_charged_to_offense(value)
