class_name RestartClockPolicy
extends RefCounted

## The one place a `RestartCause` becomes a `RestartClockMode`
## (`PROJECT_STATUS.md` §5.31).
##
## **Ownership.** This is the authoritative policy. `PossessionEngine`'s opening
## path is its only production caller, and no other simulation class asks the
## clock-restart question or carries a copy of the answer. That is what keeps a
## competition rule from being duplicated across the engine, the session and the
## endgame strategy.
##
## Two rules, and only one of them is a competition's to change:
##
## 1. **A whistle stops the clock, and it restarts on the legal touch.** A foul,
##    a violation, a ball out of bounds, a charged timeout, the start of a
##    period — every one of them is a stopped clock in every ruleset this engine
##    models, so the mapping is universal and lives here.
## 2. **A made basket is the competition's question.** A made free throw stops
##    the clock everywhere, which is basketball rather than a competition rule
##    and is therefore also decided here. A made *field goal* is the one cause a
##    competition genuinely differs on, so it and it alone is delegated to
##    `CompetitionRuleProfile.stops_clock_after_made_basket`, which reads the
##    period and the remaining time.
##
## A `LIVE_BALL` restart has no throw-in to administer at all. It answers
## `CLOCK_ALREADY_RUNNING` because that is true — the clock did not stop — and
## the opening path never asks, because it takes the live branch first. The
## value is defined rather than left to an assertion so the function is total.


## The clock mode the next possession opens under.
##
## `period` and `remaining_ms` are the period and game clock **as the next
## possession begins**, which is what the competition rule is written against.
static func mode_for(
	cause: int,
	rules: CompetitionRuleProfile,
	period: int,
	remaining_ms: int,
) -> int:
	assert(RestartCause.is_valid(cause), "unknown restart cause")
	assert(rules != null, "the restart clock policy is a competition rule question")
	match cause:
		RestartCause.Value.LIVE_BALL:
			return RestartClockMode.Value.CLOCK_ALREADY_RUNNING
		RestartCause.Value.MADE_FIELD_GOAL:
			return (
				RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH
				if rules.stops_clock_after_made_basket(period, remaining_ms)
				else RestartClockMode.Value.CLOCK_ALREADY_RUNNING
			)
		_:
			# Every remaining cause arrived through a whistle. `MADE_FREE_THROW`
			# is deliberately in this group: the clock is dead from the moment
			# the foul was called until the throw-in is touched, whatever the
			# competition, so it is not a rule profile's decision to make.
			return RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH
