class_name PeriodController
extends RefCounted

## Period, overtime, and match completion (`SIMULATION_SPEC.md` §3.1, §5.1).
##
## The controller decides; it does not mutate. `MatchEngine` turns each decision
## into `PERIOD_ENDED`, `PERIOD_STARTED`, and `MATCH_ENDED` events, and the
## reducer applies them — which is what keeps team-foul resets, overtime
## counting, and match completion inside the "state changes only through domain
## events" rule.

const OVERTIME_SAFETY_BOUND: int = 20


func period_has_expired(snapshot: MatchSnapshot) -> bool:
	return snapshot.clock_ms <= 0


## A match is over when regulation (or a completed overtime) has expired and
## the score is not level.
func match_is_complete(snapshot: MatchSnapshot, rules: CompetitionRuleProfile) -> bool:
	if snapshot.clock_ms > 0:
		return false
	if snapshot.period < rules.regulation_periods:
		return false
	return snapshot.home.score != snapshot.away.score


func next_period(snapshot: MatchSnapshot) -> int:
	return snapshot.period + 1


func next_period_length_ms(snapshot: MatchSnapshot, rules: CompetitionRuleProfile) -> int:
	return rules.period_length_ms(next_period(snapshot))


## Guards the pathological case where a tie never resolves. An unbounded
## overtime loop is a defect, and a silent infinite loop is the worst way to
## discover it.
func assert_overtime_within_bounds(snapshot: MatchSnapshot) -> void:
	assert(snapshot.overtime_periods <= OVERTIME_SAFETY_BOUND,
		"match exceeded the overtime safety bound")
