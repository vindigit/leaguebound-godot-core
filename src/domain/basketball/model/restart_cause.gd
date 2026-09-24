class_name RestartCause
extends RefCounted

## Why the next team possession begins where it begins (`SIMULATION_SPEC.md`
## §9.2, §9.4; `PROJECT_STATUS.md` §5.31).
##
## This is a **restart** fact, not a **termination** fact, and the two are
## deliberately different types. `PossessionEndReason` answers "why did that
## possession stop" and has exactly four values, because the Stage 3 possession
## contract wants a small closed set of real basketball results. It cannot
## answer "how does the next one start": `MADE_SCORE` covers a made field goal
## and a made free throw alike, and those two restart differently in every
## ruleset this engine models. Inferring the restart from the end reason is the
## ambiguity §5.30 recorded as a known conservatism and §5.31 removes.
##
## Every possession produces exactly one restart cause, including the live ones:
## `LIVE_BALL` is the honest name for "there is no throw-in at all", and having
## it keeps the fact total, so "one writer, one value, always" is a property that
## can be asserted rather than a convention that can drift.
##
## The cause says nothing about the clock. `RestartClockPolicy` is the only
## thing that turns a cause into a clock mode, and the competition rule profile
## is the only thing that can make the same cause behave differently in two
## competitions.


enum Value {
	## A period began — the opening tip, a quarter or half, or an overtime.
	PERIOD_START,
	## A field goal went in and the possession ended on it.
	MADE_FIELD_GOAL,
	## The last free throw of a trip went in and the possession ended on it.
	## An and-one's single attempt reaches here too, which is correct: the
	## restart after it is a free-throw restart, not a field-goal restart.
	MADE_FREE_THROW,
	## A foul ended the possession — an offensive foul, or a free-throw trip
	## whose final attempt was missed under a ruleset that does not make it
	## live.
	FOUL,
	## A charged timeout was called in the gap before this possession.
	TIMEOUT,
	## A shot-clock violation, a travelling call, or another whistle that is
	## neither a foul nor a ball out of bounds.
	VIOLATION,
	## The ball went out of bounds — a bad pass nobody intercepted, or a lost
	## handle that left the floor.
	OUT_OF_BOUNDS,
	## The ball never went dead: a steal or a defensive rebound. There is no
	## throw-in, so nothing administers a restart at all.
	LIVE_BALL,
}

const COUNT: int = 8
const IDS: PackedStringArray = [
	"period_start",
	"made_field_goal",
	"made_free_throw",
	"foul",
	"timeout",
	"violation",
	"out_of_bounds",
	"live_ball",
]


static func all() -> Array[int]:
	var values: Array[int] = []
	for value in range(COUNT):
		values.append(value)
	return values


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown restart cause")
	return StringName(IDS[value])


static func from_id(id_value: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id_value:
			return value
	assert(false, "unknown restart cause id")
	return Value.PERIOD_START


## Whether the next possession begins with a throw-in that has to be
## administered at all. Only `LIVE_BALL` does not.
##
## This is the same question `PossessionRecord.live_transfer` answers from the
## other side, and the two are required to agree — `TestRestartContract` asserts
## it over whole matches rather than trusting the coincidence.
static func requires_throw_in(value: int) -> bool:
	assert(is_valid(value), "unknown restart cause")
	return value != Value.LIVE_BALL


## The restart a turnover produces, from the §11.2 outcome already attributed to
## it.
##
## The mapping lives here, beside the causes, so that `PossessionEngine` names a
## restart cause at every terminal site and invents one nowhere. It is taken
## from `credits_steal()` rather than from the bare cause because that is the
## same predicate `PossessionRecord.live_transfer` is built from, and the two
## have to agree: a steal with no attributable defender is not a live transfer,
## whatever its cause says, so it must not report a live restart either.
##
## A bad pass or a lost handle is a dead ball in this engine precisely because
## the ball left the floor; a shot-clock or travelling call is a whistle of its
## own kind; an offensive foul is a foul.
static func for_turnover(turnover: TurnoverOutcome) -> int:
	assert(turnover != null, "a turnover restart needs the outcome it came from")
	if turnover.credits_steal():
		return Value.LIVE_BALL
	match turnover.cause:
		TurnoverCause.Value.SHOT_CLOCK, TurnoverCause.Value.TRAVEL_OR_VIOLATION:
			return Value.VIOLATION
		TurnoverCause.Value.OFFENSIVE_FOUL:
			return Value.FOUL
		_:
			# A bad pass, a lost handle, a ball out of bounds — and an
			# interception or strip that credited no steal, which can only mean
			# the ball was not cleanly taken. All of them end with the ball off
			# the floor and the other team throwing it in.
			return Value.OUT_OF_BOUNDS
