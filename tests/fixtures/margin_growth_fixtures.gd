class_name MarginGrowthFixtures
extends RefCounted

## A hand-authored accounting ledger, not a simulated calibration observation.
## Regulation ends 6-6, overtime ends 6-8. It deliberately contains every
## accounting channel, a blocked three, an offensive-rebound continuation, and
## a possession crossing the final-120-second boundary.
static func known_ledger() -> Dictionary:
	var input: MatchInput = CompetitionCatalog.match_for(CompetitionCatalog.Profile.TOP_DOMESTIC_PRO, 0, 0.0)
	var events: Array[MatchDomainEvent] = []
	var records: Array[PossessionRecord] = []
	var probes: Array[Dictionary] = []
	var home: StringName = input.home.team_id
	var away: StringName = input.away.team_id
	_start(events, home, 1, 1, 610000)
	_shot(events, probes, home, 1, 1, 600000, ShotZone.Value.RESTRICTED_RIM, 0.5, true)
	_end(events, records, home, away, 1, 1, 610000, 600000, 2, 0)
	_start(events, away, 2, 2, 420000)
	_shot(events, probes, away, 2, 2, 415000, ShotZone.Value.STANDARD_THREE, 0.0, false, home)
	_event(events, MatchDomainEvent.REBOUND, away, 2, 2, 414000, &"", 0, 0, &"offensive")
	_shot(events, probes, away, 2, 2, 400000, ShotZone.Value.STANDARD_THREE, 0.4, true)
	_end(events, records, away, home, 2, 2, 420000, 400000, 3, 1)
	_start(events, home, 3, 3, 420000)
	_shot(events, probes, home, 3, 3, 415000, ShotZone.Value.MIDRANGE, 0.3, false)
	_event(events, MatchDomainEvent.REBOUND, home, 3, 3, 414000, &"", 0, 0, &"offensive")
	_shot(events, probes, home, 3, 3, 400000, ShotZone.Value.STANDARD_THREE, 0.25, true)
	_end(events, records, home, away, 3, 3, 420000, 400000, 3, 1)
	_start(events, away, 4, 3, 310000)
	_shot(events, probes, away, 4, 3, 300000, ShotZone.Value.STANDARD_THREE, 0.7, true)
	_end(events, records, away, home, 4, 3, 310000, 300000, 3, 0)
	_start(events, away, 5, 4, 130000)
	_event(events, MatchDomainEvent.TURNOVER, away, 5, 4, 119000)
	_end(events, records, away, home, 5, 4, 130000, 119000, 0, 0)
	_start(events, home, 6, 4, 118500)
	_event(events, MatchDomainEvent.FOUL, away, 6, 4, 118000, &"", 0, 0, &"intentional")
	_event(events, MatchDomainEvent.FREE_THROW_AWARDED, home, 6, 4, 118000, &"", 0, 2)
	_event(events, MatchDomainEvent.FREE_THROW_MADE, home, 6, 4, 118000, &"", 0, 1)
	_event(events, MatchDomainEvent.FREE_THROW_MISSED, home, 6, 4, 118000, &"", 0, 2)
	_event(events, MatchDomainEvent.REBOUND, away, 6, 4, 117000, &"", 0, 0, &"defensive")
	_end(events, records, home, away, 6, 4, 118500, 117000, 1, 0)
	_start(events, away, 7, 5, 300000)
	_shot(events, probes, away, 7, 5, 290000, ShotZone.Value.MIDRANGE, 0.2, true)
	_end(events, records, away, home, 7, 5, 300000, 290000, 2, 0)
	var h := TeamStatLine.new(home)
	h.points = 6
	h.field_goals_attempted = 3
	h.field_goals_made = 2
	h.three_pointers_attempted = 1
	h.three_pointers_made = 1
	h.free_throws_attempted = 2
	h.free_throws_made = 1
	h.offensive_rebounds = 1
	h.blocks = 1
	h.engine_possessions = 3
	h.period_scores = [2, 0, 3, 1, 0]
	var a := TeamStatLine.new(away)
	a.points = 8
	a.field_goals_attempted = 4
	a.field_goals_made = 3
	a.three_pointers_attempted = 3
	a.three_pointers_made = 2
	a.offensive_rebounds = 1
	a.defensive_rebounds = 1
	a.turnovers = 1
	a.team_fouls = 1
	a.personal_fouls = 1
	a.engine_possessions = 4
	a.period_scores = [0, 3, 3, 0, 2]
	var statistics := MatchStatistics.new([], [h, a])
	var result := MatchFinalResult.new(input.match_id, &"synthetic", &"synthetic", &"fixture-v1", &"synthetic", &"fixture-v1", home, away, 6, 8, 1, statistics, events.size())
	return {"input": input, "output": MatchSimulationOutput.new(result, events, records), "probes": probes}


static func observer_for(fixture: Dictionary) -> MarginGrowthAudit:
	var audit := MarginGrowthAudit.new()
	for payload: Dictionary in fixture["probes"]:
		audit.record(payload)
	return audit


static func _event(events: Array[MatchDomainEvent], kind: StringName, team: StringName,
		id: int, period: int, clock_ms: int, zone: StringName = &"", points: int = 0,
		amount: int = 0, detail: StringName = &"") -> void:
	events.append(MatchDomainEvent.new(&"synthetic", events.size() + 1, period, clock_ms,
		kind, team, id, 1, &"", &"", &"", &"", detail, zone, points, amount))


static func _start(events: Array[MatchDomainEvent], team: StringName, id: int,
		period: int, clock_ms: int) -> void:
	_event(events, MatchDomainEvent.POSSESSION_STARTED, team, id, period, clock_ms)


static func _end(events: Array[MatchDomainEvent], records: Array[PossessionRecord],
		team: StringName, other: StringName, id: int, period: int, start_ms: int,
		end_ms: int, points: int, rebounds: int) -> void:
	_event(events, MatchDomainEvent.POSSESSION_ENDED, team, id, period, end_ms)
	records.append(PossessionRecord.new(id, team, period, start_ms, period, end_ms,
		PossessionEndReason.Value.MADE_SCORE if points > 0 else PossessionEndReason.Value.TURNOVER,
		points, 1, rebounds, other))


static func _shot(events: Array[MatchDomainEvent], probes: Array[Dictionary], team: StringName,
		id: int, period: int, clock_ms: int, zone: int, probability: float, made: bool,
		blocker_team: StringName = &"") -> void:
	var zone_id: StringName = ShotZone.id_of(zone)
	_event(events, MatchDomainEvent.FIELD_GOAL_ATTEMPT, team, id, period, clock_ms, zone_id)
	probes.append({"kind": &"contest", "zone": zone})
	if not blocker_team.is_empty():
		_event(events, MatchDomainEvent.BLOCK, blocker_team, id, period, clock_ms, zone_id)
	else:
		probes.append({"kind": &"shot", "zone": zone, "probability": probability, "made": made})
	_event(events, MatchDomainEvent.FIELD_GOAL_MADE if made else MatchDomainEvent.FIELD_GOAL_MISSED,
		team, id, period, clock_ms, zone_id, ShotZone.points_for(zone) if made else 0)
