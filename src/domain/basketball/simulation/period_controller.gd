class_name PeriodController
extends RefCounted


func advance_if_needed(snapshot: MatchSnapshot, rules: CompetitionRuleProfile) -> MatchSnapshot:
	if snapshot.clock_ms > 0 or snapshot.completed:
		return snapshot
	var next := snapshot.copy()
	if next.period < rules.regulation_periods:
		next.period += 1
		next.clock_ms = rules.period_seconds * 1000
		return next
	if next.home.score == next.away.score:
		next.period += 1
		next.overtime_periods += 1
		next.clock_ms = rules.overtime_seconds * 1000
		assert(next.overtime_periods <= 20, "match exceeded the overtime safety bound")
		return next
	next.completed = true
	return next
