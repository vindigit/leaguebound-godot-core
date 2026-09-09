class_name MadeFieldGoalClockRule
extends RefCounted

## When a made **field goal** leaves the game clock stopped, as one competition's
## rule (`SIMULATION_SPEC.md` §4; `PROJECT_STATUS.md` §5.33, work-queue item 20).
##
## **The owner ruling this represents.** A made field goal does not stop the
## clock merely because it went in. Some competitions stop it anyway inside a
## window at the end of a period, and the window differs by period kind: the last
## minute of an ordinary regulation period, the last two minutes of the final
## regulation period, the last two minutes of an overtime. Three numbers say all
## of that, and nothing smaller does — a single window cannot give the final
## period a different length from the ones before it, and the boolean scope flag
## `simulation-v14` shipped could only turn the whole window on or off for late
## periods rather than give each period kind its own length.
##
## **One window per `PeriodCategory`, in milliseconds of game clock remaining.**
## A window is a *threshold*, not a duration to subtract: the rule is active when
## the clock shows that much time or less.
##
## **Zero means the clock does not stop.** It is the disabling value for a
## category, and it disables cleanly — a zero window is never "stops at exactly
## 0ms remaining", because a made field goal that leaves no time on the clock
## does not begin a next possession for the rule to govern. Middle-school and
## high-school basketball declare zero in all three categories, which is the
## ruling that a made field goal never independently stops their clock.
##
## **The boundary is inclusive.** At exactly the window the rule is active. This
## is the one place that comparison is written, so "inclusive" is a property of
## this class rather than a convention repeated at each call site.
##
## **This rule governs made field goals only.** A made final free throw is a
## dead-ball restart in every ruleset this engine models and never reaches here;
## `RestartClockPolicy` answers `MADE_FREE_THROW` without consulting a profile at
## all. Collapsing the two is the mutation `TestRestartContract` exists to catch.
##
## The object is immutable once constructed and validates itself on the way in.
## What it cannot check alone is whether a window outlasts the period it is drawn
## against, because a window does not know how long a period is;
## `CompetitionRuleProfile` owns that half of the validation and runs it against
## its own period lengths.


## The window in a regulation period that has another regulation period after
## it. Necessarily zero in a competition that plays only one regulation period,
## because such a competition has no period of this kind.
var non_final_regulation_ms: int

## The window in the last period of regulation.
var final_regulation_ms: int

## The window in every overtime period.
var overtime_ms: int


func _init(
	p_non_final_regulation_ms: int = 0,
	p_final_regulation_ms: int = 0,
	p_overtime_ms: int = 0,
) -> void:
	assert(p_non_final_regulation_ms >= 0,
		"a non-final-regulation made-field-goal window is never negative")
	assert(p_final_regulation_ms >= 0,
		"a final-regulation made-field-goal window is never negative")
	assert(p_overtime_ms >= 0,
		"an overtime made-field-goal window is never negative")
	# A competition that stops the clock for a made field goal earlier in
	# regulation than it does in the final period is not a rule this ruling
	# describes, and is far more likely to be two arguments passed the wrong way
	# round. The equal case is permitted: a competition may use one length
	# throughout regulation.
	assert(p_final_regulation_ms == 0 or p_non_final_regulation_ms <= p_final_regulation_ms,
		"a non-final regulation window cannot exceed the final regulation window")
	# A window that exists earlier in regulation but not in the final period
	# would mean the clock stops in the third quarter and not in the fourth.
	assert(p_non_final_regulation_ms == 0 or p_final_regulation_ms > 0,
		"a competition that stops the clock in an ordinary period must also stop it in the final one")
	non_final_regulation_ms = p_non_final_regulation_ms
	final_regulation_ms = p_final_regulation_ms
	overtime_ms = p_overtime_ms


## No made-field-goal stoppage at all, in any period. The middle-school and
## high-school ruling, and the default.
static func none() -> MadeFieldGoalClockRule:
	return MadeFieldGoalClockRule.new(0, 0, 0)


## A rule that stops the clock only at the end of the final regulation period and
## of every overtime, both at the same window. The college and overseas shape.
static func late_game(window_ms: int) -> MadeFieldGoalClockRule:
	return MadeFieldGoalClockRule.new(0, window_ms, window_ms)


## The window that applies to one `PeriodCategory`, in milliseconds remaining.
func window_ms_for(category: int) -> int:
	assert(PeriodCategory.is_valid(category), "unknown period category")
	match category:
		PeriodCategory.Value.NON_FINAL_REGULATION:
			return non_final_regulation_ms
		PeriodCategory.Value.FINAL_REGULATION:
			return final_regulation_ms
		_:
			return overtime_ms


## Whether a made field goal leaves the clock stopped, in a period of this
## category, with this much game clock remaining.
##
## The boundary is inclusive: at exactly the window, the rule is active.
func stops_clock(category: int, remaining_ms: int) -> bool:
	assert(remaining_ms >= 0, "a remaining game clock is never negative")
	var window: int = window_ms_for(category)
	if window <= 0:
		return false
	return remaining_ms <= window


## Whether this rule can ever stop the clock, in any period. False for `none()`.
func stops_clock_anywhere() -> bool:
	return non_final_regulation_ms > 0 or final_regulation_ms > 0 or overtime_ms > 0


## Every window, for the diagnostic report and the status record.
func to_dictionary() -> Dictionary:
	return {
		"non_final_regulation_ms": non_final_regulation_ms,
		"final_regulation_ms": final_regulation_ms,
		"overtime_ms": overtime_ms,
	}


## Rendered by value, not by object identity.
##
## `run_pace_decomposition.gd` proves a rebuilt profile carries every field of
## its source by comparing `str()` of each; with an object member that check is
## only meaningful if two equal rules stringify alike, so this is load-bearing
## rather than cosmetic.
func _to_string() -> String:
	return "MadeFieldGoalClockRule(non_final=%d, final=%d, overtime=%d)" % [
		non_final_regulation_ms, final_regulation_ms, overtime_ms]
