class_name MarginGrowthAudit
extends RefCounted

## Observation-only signed margin accounting. No production random source is
## consumed. The existing ShotResolver probe is paired with ledger attempts in
## order; every pairing is checked against zone, make outcome, and block status.
##
## Conditional expected shooting treats an observed block as zero expected
## points. Its innovation is therefore make-roll variation conditional on the
## shot reaching make resolution, not all uncertainty in creating a shot.
## Components are accounting/covariance allocations, not identified causes.
## `live_ms` is retained as a short column name but means charged game-clock
## milliseconds between possession-record start and end, including charged
## inbound time. It is not a measurement of time with the ball physically live.

const VERSION: String = "margin-growth-v1"
const LATE_MS: int = 120000
const COUNT_KEYS: PackedStringArray = [
	"points", "field_points", "field_goals_attempted", "field_goals_made",
	"three_pointers_attempted", "three_pointers_made", "free_throws_attempted",
	"free_throws_made", "free_throws_awarded", "offensive_rebounds",
	"defensive_rebounds", "turnovers", "fouls", "intentional_fouls", "blocks",
	"possessions", "live_ms", "decided_check_ins", "garbage_events",
	"unblocked_attempts", "blocked_attempts", "expected_field_points",
	"conditional_shot_variance",
]
const REQUIRED_COVERAGE: PackedStringArray = [
	"two_point_attempts", "three_point_attempts", "unblocked_attempts", "blocked_attempts",
	"turnovers", "offensive_rebounds", "defensive_rebounds", "fouls",
	"free_throws_made", "free_throws_missed", "intentional_fouls",
	"late_regulation_possessions", "overtime_possessions",
]

var _probes: Array[Dictionary] = []
var _probe_errors: PackedStringArray = []


func attach() -> void:
	assert(not ShotResolver.probe.is_valid(), "another shot observer is already attached")
	_probes.clear()
	_probe_errors.clear()
	ShotResolver.probe = Callable(self, "record")


func detach() -> void:
	ShotResolver.detach_probe()


func record(payload: Dictionary) -> void:
	if payload.get("kind", &"") == &"contest":
		_probes.append({"zone": (payload["zone"] as int), "shot": {}})
	elif payload.get("kind", &"") == &"shot":
		if _probes.is_empty() or not (_probes[-1]["shot"] as Dictionary).is_empty():
			_probe_errors.append("shot probe has no unique preceding contest")
		else:
			_probes[-1]["shot"] = payload.duplicate(true)


static func blank_side() -> Dictionary:
	var values: Dictionary = {}
	for key in COUNT_KEYS:
		values[key] = 0.0 if key in ["expected_field_points", "conditional_shot_variance"] else 0
	return values


static func blank_segment() -> Dictionary:
	return {"home": blank_side(), "away": blank_side()}


## Four equal elapsed-time regulation bins make college halves comparable with
## pro quarters. Events exactly on a boundary belong to the elapsed bin ending
## there; a new possession starting on it belongs to the next bin.
static func quarter_for(rules: CompetitionRuleProfile, period: int, clock_ms: int,
		is_start: bool = false) -> int:
	if period > rules.regulation_periods:
		return -1
	var duration: int = rules.period_seconds * 1000
	var elapsed: int = (period - 1) * duration + duration - clock_ms
	var adjusted: int = elapsed if is_start else maxi(0, elapsed - 1)
	return mini(3, (adjusted * 4 / (duration * rules.regulation_periods) as int))


static func window_for(rules: CompetitionRuleProfile, period: int, clock_ms: int) -> String:
	if period > rules.regulation_periods:
		return "overtime"
	if period == rules.regulation_periods and clock_ms <= LATE_MS:
		return "late_regulation"
	return "early_regulation"


## Exact symmetric field-points identity plus free throws. With expected=true,
## seven terms close after adding the signed make-roll innovation.
static func components(home: Dictionary, away: Dictionary, expected: bool = false) -> Dictionary:
	var field_key: String = "expected_field_points" if expected else "field_points"
	var hf: float = (home["field_goals_attempted"] as float)
	var af: float = (away["field_goals_attempted"] as float)
	var he: float = (home[field_key] as float) / (2.0 * hf) if hf > 0.0 else 0.0
	var ae: float = (away[field_key] as float) / (2.0 * af) if af > 0.0 else 0.0
	var efficiency_sum: float = he + ae
	var possession_delta: float = (home["possessions"] as float) - (away["possessions"] as float)
	var rebound_delta: float = (home["offensive_rebounds"] as float) - (away["offensive_rebounds"] as float)
	var turnover_delta: float = (home["turnovers"] as float) - (away["turnovers"] as float)
	var result: Dictionary = {
		"shooting_efficiency": (hf + af) * (he - ae),
		"possession_imbalance": efficiency_sum * possession_delta,
		"offensive_rebounds": efficiency_sum * rebound_delta,
		"turnovers": -efficiency_sum * turnover_delta,
		"shot_volume_residual": efficiency_sum * (hf - af - possession_delta - rebound_delta + turnover_delta),
		"free_throws": (home["free_throws_made"] as float) - (away["free_throws_made"] as float),
	}
	if expected:
		result["shooting_innovation"] = ((home["field_points"] as float) - (home["expected_field_points"] as float)) - ((away["field_points"] as float) - (away["expected_field_points"] as float))
	return result


static func finish_segment(segment: Dictionary) -> Dictionary:
	var result: Dictionary = segment.duplicate(true)
	result["margin"] = (result["home"]["points"] as int) - (result["away"]["points"] as int)
	result["components"] = components(result["home"] as Dictionary, result["away"] as Dictionary)
	result["conditional_components"] = components(result["home"] as Dictionary, result["away"] as Dictionary, true)
	var realized_sum: float = 0.0
	for value: float in (result["components"] as Dictionary).values():
		realized_sum += value
	var conditional_sum: float = 0.0
	for value: float in (result["conditional_components"] as Dictionary).values():
		conditional_sum += value
	result["identity_error"] = absf(realized_sum - (result["margin"] as float))
	result["conditional_identity_error"] = absf(conditional_sum - (result["margin"] as float))
	return result


static func coverage_errors(coverage: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key in REQUIRED_COVERAGE:
		if (coverage.get(key, 0) as int) <= 0:
			errors.append("unwitnessed channel: " + key)
	return errors


func measure(input: MatchInput, output: MatchSimulationOutput) -> Dictionary:
	var rules: CompetitionRuleProfile = input.rule_profile
	var periods: Array[Dictionary] = []
	for _index in range(rules.regulation_periods + output.final_result.overtime_periods):
		periods.append(blank_segment())
	var quarters: Array[Dictionary] = []
	for _index in range(4):
		quarters.append(blank_segment())
	var windows: Dictionary = {"early_regulation": blank_segment(), "late_regulation": blank_segment(), "overtime": blank_segment()}
	var total: Dictionary = blank_segment()
	var errors: PackedStringArray = _probe_errors.duplicate()
	var coverage: Dictionary = {}
	for key in REQUIRED_COVERAGE:
		coverage[key] = 0
	coverage["straddled_late_boundary"] = 0
	var possession_points: Dictionary = {}
	var starts: Dictionary = {}
	var ends: Dictionary = {}
	var record_ids: Dictionary = {}
	var attempts: Array[MatchDomainEvent] = []
	var outcomes: Array[MatchDomainEvent] = []
	var blocked_attempts: Dictionary = {}
	var pending_attempt: int = -1
	var expected_sequence: int = 1
	for event in output.events:
		if event.sequence != expected_sequence:
			errors.append("event sequence mismatch at %d" % expected_sequence)
		expected_sequence += 1
		if event.period < 1 or event.period > periods.size():
			errors.append("event period outside completed game")
			continue
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			if starts.has(event.possession_id):
				errors.append("duplicate possession start")
			starts[event.possession_id] = event
		elif event.event_type == MatchDomainEvent.POSSESSION_ENDED:
			if ends.has(event.possession_id):
				errors.append("duplicate possession end")
			ends[event.possession_id] = event
		if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			if pending_attempt >= 0:
				errors.append("attempt missing terminal outcome")
			pending_attempt = attempts.size()
			attempts.append(event)
		elif event.event_type == MatchDomainEvent.BLOCK:
			if pending_attempt < 0:
				errors.append("block without attempt")
			else:
				blocked_attempts[pending_attempt] = true
		elif event.event_type in [MatchDomainEvent.FIELD_GOAL_MADE, MatchDomainEvent.FIELD_GOAL_MISSED]:
			if pending_attempt < 0:
				errors.append("field outcome without attempt")
			outcomes.append(event)
			pending_attempt = -1
		var side: String = _side(input, event.team_id)
		var changes: Dictionary = _event_changes(event)
		if not changes.is_empty():
			if side.is_empty():
				errors.append("counted event has unknown team")
				continue
			_apply(total, side, changes)
			_apply(periods[event.period - 1], side, changes)
			_apply(windows[window_for(rules, event.period, event.clock_ms)] as Dictionary, side, changes)
			var quarter: int = quarter_for(rules, event.period, event.clock_ms)
			if quarter >= 0:
				_apply(quarters[quarter], side, changes)
		if event.event_type in [MatchDomainEvent.FIELD_GOAL_MADE, MatchDomainEvent.FREE_THROW_MADE]:
			var score_key: String = "%d:%s" % [event.possession_id, side]
			var score_points: int = 1 if event.event_type == MatchDomainEvent.FREE_THROW_MADE else event.points
			possession_points[score_key] = (possession_points.get(score_key, 0) as int) + score_points
		if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			var category: String = "three_point_attempts" if event.zone_id in [&"standard_three", &"deep_three"] else "two_point_attempts"
			coverage[category] += 1
		elif event.event_type == MatchDomainEvent.FREE_THROW_MISSED:
			coverage["free_throws_missed"] += 1
	if pending_attempt >= 0:
		errors.append("last attempt missing terminal outcome")
	if attempts.size() != _probes.size() or outcomes.size() != attempts.size():
		errors.append("shot probe/attempt/outcome count mismatch")
	for index in range(mini(attempts.size(), mini(_probes.size(), outcomes.size()))):
		var attempt: MatchDomainEvent = attempts[index]
		var outcome: MatchDomainEvent = outcomes[index]
		var probe: Dictionary = _probes[index]
		var shot: Dictionary = probe["shot"]
		var blocked: bool = blocked_attempts.has(index)
		var made: bool = outcome.event_type == MatchDomainEvent.FIELD_GOAL_MADE
		if attempt.team_id != outcome.team_id or attempt.possession_id != outcome.possession_id or attempt.zone_id != outcome.zone_id or attempt.primary_player_id != outcome.primary_player_id or attempt.period != outcome.period or attempt.clock_ms != outcome.clock_ms:
			errors.append("attempt/outcome ownership mismatch")
		if ShotZone.id_of((probe["zone"] as int)) != attempt.zone_id:
			errors.append("probe zone disagrees with ledger")
		if blocked != shot.is_empty() or (blocked and made):
			errors.append("probe block coverage disagrees with ledger")
		var probability: float = 0.0
		if not shot.is_empty():
			probability = (shot["probability"] as float)
			if (shot["made"] as bool) != made or (shot["zone"] as int) != (probe["zone"] as int):
				errors.append("probe make outcome disagrees with ledger")
			if not is_finite(probability) or probability < 0.0 or probability > 1.0:
				errors.append("shot probability outside unit interval")
		var value: int = ShotZone.points_for(ShotZone.from_id(attempt.zone_id))
		var changes: Dictionary = {"expected_field_points": (value as float) * probability,
			"conditional_shot_variance": (value * value as float) * probability * (1.0 - probability),
			"blocked_attempts" if blocked else "unblocked_attempts": 1}
		var side: String = _side(input, attempt.team_id)
		if side.is_empty():
			continue
		_apply(total, side, changes)
		_apply(periods[attempt.period - 1], side, changes)
		_apply(windows[window_for(rules, attempt.period, attempt.clock_ms)] as Dictionary, side, changes)
		var quarter: int = quarter_for(rules, attempt.period, attempt.clock_ms)
		if quarter >= 0:
			_apply(quarters[quarter], side, changes)
	for record in output.possessions:
		if record_ids.has(record.possession_id):
			errors.append("duplicate terminal possession record")
		record_ids[record.possession_id] = true
		var side: String = _side(input, record.offense_team_id)
		if side.is_empty() or record.start_period < 1 or record.start_period > periods.size():
			errors.append("possession ownership or period invalid")
			continue
		if record.start_period != record.end_period or record.start_clock_ms < record.end_clock_ms:
			errors.append("possession clock/period invalid")
		var score_key: String = "%d:%s" % [record.possession_id, side]
		if (possession_points.get(score_key, 0) as int) != record.points_scored:
			errors.append("possession points disagree with scoring events")
		var other: String = "away" if side == "home" else "home"
		if (possession_points.get("%d:%s" % [record.possession_id, other], 0) as int) != 0:
			errors.append("opponent scored inside possession")
		if not starts.has(record.possession_id) or not ends.has(record.possession_id):
			errors.append("possession missing lifecycle event")
		else:
			var start_event: MatchDomainEvent = starts[record.possession_id]
			var end_event: MatchDomainEvent = ends[record.possession_id]
			if start_event.team_id != record.offense_team_id or end_event.team_id != record.offense_team_id:
				errors.append("possession lifecycle ownership mismatch")
			if start_event.period != record.start_period or end_event.period != record.end_period or start_event.clock_ms != record.start_clock_ms or end_event.clock_ms != record.end_clock_ms:
				errors.append("possession lifecycle clock mismatch")
		var changes: Dictionary = {"possessions": 1, "live_ms": record.start_clock_ms - record.end_clock_ms}
		_apply(total, side, changes)
		_apply(periods[record.start_period - 1], side, changes)
		var start_window: String = window_for(rules, record.start_period, record.start_clock_ms)
		_apply(windows[start_window] as Dictionary, side, {"possessions": 1})
		if start_window != "early_regulation":
			coverage[start_window + "_possessions"] += 1
		if record.start_period == rules.regulation_periods and record.start_clock_ms > LATE_MS and record.end_clock_ms < LATE_MS:
			coverage["straddled_late_boundary"] += 1
			_apply(windows["early_regulation"] as Dictionary, side, {"live_ms": record.start_clock_ms - LATE_MS})
			_apply(windows["late_regulation"] as Dictionary, side, {"live_ms": LATE_MS - record.end_clock_ms})
		else:
			_apply(windows[start_window] as Dictionary, side, {"live_ms": changes["live_ms"]})
		var quarter: int = quarter_for(rules, record.start_period, record.start_clock_ms, true)
		if quarter >= 0:
			_apply(quarters[quarter], side, {"possessions": 1})
			_add_quarter_time(quarters, side, rules, record)
	if starts.size() != output.possessions.size() or ends.size() != output.possessions.size():
		errors.append("possession lifecycle/record count mismatch")
	for key: String in ["unblocked_attempts", "blocked_attempts", "turnovers", "offensive_rebounds", "defensive_rebounds", "fouls", "free_throws_made", "intentional_fouls"]:
		coverage[key] = (total["home"][key] as int) + (total["away"][key] as int)
	_reconcile_final(input, output, total, errors)
	var cumulative_margin: int = 0
	for index in range(periods.size()):
		periods[index] = finish_segment(periods[index])
		cumulative_margin += (periods[index]["margin"] as int)
		periods[index]["cumulative_margin"] = cumulative_margin
		for side: String in ["home", "away"]:
			var team_id: StringName = input.home.team_id if side == "home" else input.away.team_id
			var scores: Array[int] = output.final_result.statistics.team_line(team_id).period_scores
			if index >= scores.size() or scores[index] != (periods[index][side]["points"] as int):
				errors.append("period score disagrees with events: %s.%d" % [side, index + 1])
	for index in range(quarters.size()):
		quarters[index] = finish_segment(quarters[index])
	for key: String in windows:
		windows[key] = finish_segment(windows[key] as Dictionary)
	var final: Dictionary = finish_segment(total)
	for segment: Dictionary in periods + quarters + windows.values() + [final]:
		if (segment["identity_error"] as float) > 0.000001 or (segment["conditional_identity_error"] as float) > 0.000001:
			errors.append("signed margin identity does not close")
	_reconcile_partitions(total, periods, quarters, windows, errors)
	var pre_late_margin: int = windows["early_regulation"]["margin"]
	var late_increment: int = windows["late_regulation"]["margin"]
	var regulation_margin: int = pre_late_margin + late_increment
	if (regulation_margin == 0) != (output.final_result.overtime_periods > 0):
		errors.append("regulation tie and overtime disagree")
	return {"version": VERSION, "periods": periods, "quarters": quarters, "windows": windows,
		"final": final, "errors": errors, "coverage": coverage,
		"regulation_margin": (windows["early_regulation"]["margin"] as int) + (windows["late_regulation"]["margin"] as int),
		"pre_late_margin": (windows["early_regulation"]["margin"] as int),
		"late_margin_increment": (windows["late_regulation"]["margin"] as int),
		"late_absolute_expansion": absi(regulation_margin) - absi(pre_late_margin),
		"late_leader_aligned_increment": signi(pre_late_margin) * late_increment,
		"pre_late_tied": pre_late_margin == 0,
		"pre_late_close": absi(pre_late_margin) <= 5,
		"regulation_close": absi(regulation_margin) <= 5,
		"close_to_nonclose": absi(pre_late_margin) <= 5 and absi(regulation_margin) > 5,
		"nonclose_to_close": absi(pre_late_margin) > 5 and absi(regulation_margin) <= 5}


static func _event_changes(event: MatchDomainEvent) -> Dictionary:
	match event.event_type:
		MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			return {"field_goals_attempted": 1, "three_pointers_attempted": 1 if event.zone_id in [&"standard_three", &"deep_three"] else 0}
		MatchDomainEvent.FIELD_GOAL_MADE:
			return {"points": event.points, "field_points": event.points, "field_goals_made": 1, "three_pointers_made": 1 if event.points == 3 else 0}
		MatchDomainEvent.FREE_THROW_MADE:
			return {"points": 1, "free_throws_made": 1, "free_throws_attempted": 1}
		MatchDomainEvent.FREE_THROW_MISSED:
			return {"free_throws_attempted": 1}
		MatchDomainEvent.FREE_THROW_AWARDED:
			return {"free_throws_awarded": event.amount}
		MatchDomainEvent.TURNOVER:
			return {"turnovers": 1}
		MatchDomainEvent.REBOUND:
			return {"offensive_rebounds" if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE else "defensive_rebounds": 1}
		MatchDomainEvent.FOUL:
			return {"fouls": 1, "intentional_fouls": 1 if event.detail_id == &"intentional" else 0}
		MatchDomainEvent.BLOCK:
			return {"blocks": 1}
		MatchDomainEvent.CHECK_IN:
			return {"decided_check_ins": 1 if event.detail_id == &"decided_game" else 0}
		MatchDomainEvent.GARBAGE_TIME:
			return {"garbage_events": 1}
	return {}


static func _apply(segment: Dictionary, side: String, changes: Dictionary) -> void:
	for key: String in changes:
		segment[side][key] += changes[key]


static func _side(input: MatchInput, team_id: StringName) -> String:
	if team_id == input.home.team_id:
		return "home"
	if team_id == input.away.team_id:
		return "away"
	return ""


static func _add_quarter_time(quarters: Array[Dictionary], side: String,
		rules: CompetitionRuleProfile, record: PossessionRecord) -> void:
	var period_ms: int = rules.period_seconds * 1000
	var elapsed_start: int = (record.start_period - 1) * period_ms + period_ms - record.start_clock_ms
	var elapsed_end: int = (record.end_period - 1) * period_ms + period_ms - record.end_clock_ms
	var quarter_ms: int = (period_ms * rules.regulation_periods / 4 as int)
	for index in range(4):
		var overlap: int = maxi(0, mini(elapsed_end, (index + 1) * quarter_ms) - maxi(elapsed_start, index * quarter_ms))
		_apply(quarters[index], side, {"live_ms": overlap})


static func _reconcile_final(input: MatchInput, output: MatchSimulationOutput,
		total: Dictionary, errors: PackedStringArray) -> void:
	if (total["home"]["points"] as int) != output.final_result.home_score or (total["away"]["points"] as int) != output.final_result.away_score:
		errors.append("final score disagrees with scoring events")
	for side: String in ["home", "away"]:
		var team_id: StringName = input.home.team_id if side == "home" else input.away.team_id
		var line: TeamStatLine = output.final_result.statistics.team_line(team_id)
		for key: String in ["points", "field_goals_attempted", "field_goals_made", "three_pointers_attempted", "three_pointers_made", "free_throws_attempted", "free_throws_made", "offensive_rebounds", "defensive_rebounds", "turnovers", "blocks"]:
			if (total[side][key] as int) != (line.get(key) as int):
				errors.append("box score disagrees with events: %s.%s" % [side, key])
		if (total[side]["possessions"] as int) != line.engine_possessions:
			errors.append("engine possession denominator mismatch")
		if (total[side]["fouls"] as int) != line.personal_fouls:
			errors.append("foul count disagrees with box score")


static func _reconcile_partitions(total: Dictionary, periods: Array[Dictionary],
		quarters: Array[Dictionary], windows: Dictionary, errors: PackedStringArray) -> void:
	for side: String in ["home", "away"]:
		for key in COUNT_KEYS:
			var period_sum: float = 0.0
			var quarter_sum: float = 0.0
			var window_sum: float = 0.0
			for segment: Dictionary in periods:
				period_sum += segment[side][key] as float
			for segment: Dictionary in quarters:
				quarter_sum += segment[side][key] as float
			for segment: Dictionary in windows.values():
				window_sum += segment[side][key] as float
			var all_value: float = total[side][key]
			var overtime_value: float = windows["overtime"][side][key]
			if absf(period_sum - all_value) > 0.000001 or absf(window_sum - all_value) > 0.000001 or absf(quarter_sum + overtime_value - all_value) > 0.000001:
				errors.append("partition count/time conservation failed: %s.%s" % [side, key])
