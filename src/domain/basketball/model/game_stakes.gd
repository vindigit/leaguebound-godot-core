class_name GameStakes
extends RefCounted

## What one game is worth (`SIMULATION_SPEC.md` §18.2 contextual adjustment).
##
## The engine has always been handed *how* a game is played — the rules, the
## balance profile, the rosters — and never *what it is for*. A regular-season
## Tuesday and a win-or-go-home Final are the same forty minutes to it, so a
## coach in the second one manages his rotation, his timeouts and his last
## possession exactly as he does in the first. That is not a calibration gap; it
## is a missing input, and this is the input.
##
## ## The contract
##
## Three tiers, and deliberately only three. They are the coarsest partition
## that a coach's behaviour actually distinguishes, and every additional tier
## would be a place for a competition, a round, or a rivalry to acquire rules of
## its own — which is exactly what this contract exists to prevent.
##
## | Tier | Meaning |
## | --- | --- |
## | `REGULAR` | an ordinary regular-season game |
## | `POSTSEASON` | a playoff or tournament game that is not itself a championship or a win-or-go-home game |
## | `CHAMPIONSHIP_OR_ELIMINATION` | Finals games, championship games, Final Four games, and any other win-or-go-home contest |
##
## `REGULAR` is the default, and the default is load-bearing: every existing
## caller, fixture, golden ledger and calibration runner keeps the behaviour it
## had, because a `MatchInput` built without a stakes argument is a
## regular-season game and resolves through arithmetic that multiplies by
## exactly one.
##
## ## Who is supposed to fill this in
##
## Nobody yet. There is no schedule, no bracket, no postseason and no career
## layer in this repository, and this contract deliberately does not wait for
## them: it is a *value* the simulation accepts, not a lookup it performs.
##
## When those layers exist, **mapping real game metadata onto this enum is
## their responsibility, not the engine's.** The scheduling layer knows that a
## game is game 7 of a Finals series; the engine must never learn it. The engine
## is handed `CHAMPIONSHIP_OR_ELIMINATION` and knows nothing else about the
## occasion — not the competition, not the round, not the series score, not who
## is playing. That boundary is what keeps a stakes tier from becoming a place
## to hide a per-tournament exception.
##
## ## What a tier is allowed to change
##
## Bounded coaching decisions, and nothing else. `StakesPolicy` is the only
## place a tier is read into a number, and every number it produces is a
## decision threshold: how long a coach rides his rotation, how long he holds a
## timeout, how sure he has to be before he empties his bench, how early he
## starts managing the last possession. It never reaches a rating, a capability,
## a shot probability, a turnover, a foul, or a rebound; it never inspects a
## team identity or a result; and it never favours the side that is behind.
##
## Script the circumstances, never the result.

enum Value {
	REGULAR, ## an ordinary regular-season game
	POSTSEASON, ## a playoff or tournament game that is not itself decisive
	CHAMPIONSHIP_OR_ELIMINATION, ## a Final, a championship game, or any win-or-go-home contest
}

const COUNT: int = 3

## The value a `MatchInput` built without a stakes argument carries.
const DEFAULT: int = Value.REGULAR

const IDS: PackedStringArray = [
	"regular",
	"postseason",
	"championship_or_elimination",
]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown game stakes tier")
	return StringName(IDS[value])


static func from_id(value: StringName) -> int:
	for index in range(COUNT):
		if StringName(IDS[index]) == value:
			return index
	assert(false, "unknown game stakes id")
	return DEFAULT


static func all() -> Array[int]:
	var values: Array[int] = []
	for index in range(COUNT):
		values.append(index)
	return values


## How many tiers above `REGULAR` this one is: 0, 1, or 2.
##
## Every stakes effect in the engine is `base * (1 + step * tier)`, so a
## `REGULAR` game multiplies by exactly one and the existing arithmetic is
## reproduced bit for bit. That is the whole reason this returns an integer step
## count rather than a per-tier table: a table has three entries to keep
## consistent and a step has one, and only the step form makes the default path
## provably unchanged.
static func tier(value: int) -> int:
	assert(is_valid(value), "unknown game stakes tier")
	return value
