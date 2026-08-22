class_name PppDecomposition
extends RefCounted

## Where a competition's points per possession actually come from
## (`BALANCE_SPEC.md` §14.1, Stage 4 diagnostic).
##
## Top-domestic points per possession sits at 1.1847 ±0.0037 against a 1.08-1.18
## ceiling — a genuine failure of about +0.0047, small enough that no aggregate
## can locate it. A number that misses by four ten-thousandths of a point per
## possession cannot be diagnosed by looking at points per possession; it has to
## be taken apart into terms that each have their own §14.1 band or their own
## basketball meaning, so the excess can be attributed rather than guessed at.
##
## Everything here is read from the **ordered ledger** and the possession
## records, never from the box score. §24.3 makes the events the authority, and
## a decomposition that trusted a projection would be checking the projection.
##
## **The identities are enforced, not assumed.** Three of them:
##
## ```text
## 2PT points + 3PT points + FT points   == ledger points
## sum(possession_record.points_scored)  == ledger points
## count(POSSESSION_ENDED)               == count(possession records)
## ```
##
## and every field-goal result must be preceded by an attempt in the same
## possession. A violation is recorded and published rather than smoothed over:
## an accounting that silently absorbs unexplained points is worse than no
## accounting, because it produces a decomposition that adds up and is wrong.

## §14.1's ceiling for top domestic, carried here so the report can state the
## excess rather than leaving the reader to subtract.
const TOP_DOMESTIC_PPP_CEILING: float = 1.18

## What a made free throw is worth. The ledger encodes this by event type, not
## in the event's `points` field — `FREE_THROW_MADE` carries `points = 0` and
## uses `amount` for the attempt index.
const FREE_THROW_POINTS: int = 1


class Totals:
	extends RefCounted

	var games: int = 0
	var possessions: int = 0
	var points: int = 0

	# --- scoring terms, which must sum to `points` -------------------------
	var two_point_made: int = 0
	var two_point_attempted: int = 0
	var three_point_made: int = 0
	var three_point_attempted: int = 0
	var free_throws_made: int = 0
	var free_throws_attempted: int = 0

	# --- possession-consuming and possession-extending events --------------
	var turnovers: int = 0
	var offensive_rebounds: int = 0
	var defensive_rebounds: int = 0
	## Possessions carrying at least one offensive rebound: the extensions.
	var extended_possessions: int = 0
	var transition_possessions: int = 0
	var transition_points: int = 0
	var garbage_time_possessions: int = 0
	var garbage_time_points: int = 0

	# --- creation and continuation -----------------------------------------
	var assisted_makes: int = 0
	var catch_and_shoot_makes: int = 0
	var unassisted_makes: int = 0
	var putback_attempts: int = 0
	var putback_makes: int = 0
	var second_chance_points: int = 0
	## Possessions whose free throws came from a foul rather than a shot.
	var foul_generated_trips: int = 0
	var shooting_fouls: int = 0

	# --- distributions ------------------------------------------------------
	## `[zone]` attempts and makes.
	var zone_attempts := PackedInt32Array()
	var zone_makes := PackedInt32Array()
	## `[contest band]` attempts and makes — the ledger's shot-quality axis.
	var contest_attempts := PackedInt32Array()
	var contest_makes := PackedInt32Array()

	func _init() -> void:
		zone_attempts.resize(ShotZone.COUNT); zone_attempts.fill(0)
		zone_makes.resize(ShotZone.COUNT); zone_makes.fill(0)
		contest_attempts.resize(ContestBand.COUNT); contest_attempts.fill(0)
		contest_makes.resize(ContestBand.COUNT); contest_makes.fill(0)

	func field_goals_attempted() -> int:
		return two_point_attempted + three_point_attempted

	func field_goals_made() -> int:
		return two_point_made + three_point_made

	func two_point_points() -> int:
		return 2 * two_point_made

	func three_point_points() -> int:
		return 3 * three_point_made

	func free_throw_points() -> int:
		return free_throws_made

	## The accounting identity's left-hand side.
	func accounted_points() -> int:
		return two_point_points() + three_point_points() + free_throw_points()

	func points_per_possession() -> float:
		return 0.0 if possessions == 0 else float(points) / float(possessions)

	func possessions_per_game() -> float:
		return 0.0 if games == 0 else float(possessions) / float(games)

	## Each scoring term's contribution to points per possession. These sum to
	## `points_per_possession()` exactly, which is what makes the decomposition
	## an attribution rather than a list of correlated statistics.
	func two_point_ppp() -> float:
		return 0.0 if possessions == 0 else float(two_point_points()) / float(possessions)

	func three_point_ppp() -> float:
		return 0.0 if possessions == 0 else float(three_point_points()) / float(possessions)

	func free_throw_ppp() -> float:
		return 0.0 if possessions == 0 else float(free_throw_points()) / float(possessions)

	func two_point_percentage() -> float:
		return _ratio(two_point_made, two_point_attempted)

	func three_point_percentage() -> float:
		return _ratio(three_point_made, three_point_attempted)

	func free_throw_percentage() -> float:
		return _ratio(free_throws_made, free_throws_attempted)

	func three_point_attempt_rate() -> float:
		return _ratio(three_point_attempted, field_goals_attempted())

	func free_throw_rate() -> float:
		return _ratio(free_throws_attempted, field_goals_attempted())

	func turnover_rate() -> float:
		return _ratio(turnovers, possessions)

	func offensive_rebound_rate() -> float:
		return _ratio(offensive_rebounds, offensive_rebounds + defensive_rebounds)

	func extension_rate() -> float:
		return _ratio(extended_possessions, possessions)

	func transition_share() -> float:
		return _ratio(transition_possessions, possessions)

	func transition_ppp() -> float:
		return _ratio(transition_points, transition_possessions)

	func assisted_share() -> float:
		return _ratio(assisted_makes + catch_and_shoot_makes, field_goals_made())

	func putback_percentage() -> float:
		return _ratio(putback_makes, putback_attempts)

	func second_chance_ppp() -> float:
		return 0.0 if possessions == 0 else float(second_chance_points) / float(possessions)

	func zone_share(zone: int) -> float:
		return _ratio(zone_attempts[zone], field_goals_attempted())

	func zone_percentage(zone: int) -> float:
		return _ratio(zone_makes[zone], zone_attempts[zone])

	func contest_share(band: int) -> float:
		return _ratio(contest_attempts[band], field_goals_attempted())

	func contest_percentage(band: int) -> float:
		return _ratio(contest_makes[band], contest_attempts[band])

	func _ratio(numerator: int, denominator: int) -> float:
		return 0.0 if denominator <= 0 else float(numerator) / float(denominator)

	func to_dictionary() -> Dictionary:
		var payload: Dictionary = {
			"games": games,
			"possessions": possessions,
			"points": points,
			"points_per_possession": points_per_possession(),
			"possessions_per_game": possessions_per_game(),
			"two_point_made": two_point_made,
			"two_point_attempted": two_point_attempted,
			"two_point_percentage": two_point_percentage(),
			"two_point_points": two_point_points(),
			"two_point_ppp": two_point_ppp(),
			"three_point_made": three_point_made,
			"three_point_attempted": three_point_attempted,
			"three_point_percentage": three_point_percentage(),
			"three_point_points": three_point_points(),
			"three_point_ppp": three_point_ppp(),
			"three_point_attempt_rate": three_point_attempt_rate(),
			"free_throws_made": free_throws_made,
			"free_throws_attempted": free_throws_attempted,
			"free_throw_percentage": free_throw_percentage(),
			"free_throw_points": free_throw_points(),
			"free_throw_ppp": free_throw_ppp(),
			"free_throw_rate": free_throw_rate(),
			"turnovers": turnovers,
			"turnover_rate": turnover_rate(),
			"offensive_rebounds": offensive_rebounds,
			"defensive_rebounds": defensive_rebounds,
			"offensive_rebound_rate": offensive_rebound_rate(),
			"extended_possessions": extended_possessions,
			"extension_rate": extension_rate(),
			"transition_possessions": transition_possessions,
			"transition_points": transition_points,
			"transition_share": transition_share(),
			"transition_ppp": transition_ppp(),
			"garbage_time_possessions": garbage_time_possessions,
			"garbage_time_points": garbage_time_points,
			"assisted_makes": assisted_makes,
			"catch_and_shoot_makes": catch_and_shoot_makes,
			"unassisted_makes": unassisted_makes,
			"assisted_share": assisted_share(),
			"putback_attempts": putback_attempts,
			"putback_makes": putback_makes,
			"putback_percentage": putback_percentage(),
			"second_chance_points": second_chance_points,
			"second_chance_ppp": second_chance_ppp(),
			"foul_generated_trips": foul_generated_trips,
			"shooting_fouls": shooting_fouls,
			"accounted_points": accounted_points(),
		}
		for zone in range(ShotZone.COUNT):
			var zone_name: String = ShotZone.IDS[zone]
			payload["zone.%s.attempts" % zone_name] = zone_attempts[zone]
			payload["zone.%s.share" % zone_name] = zone_share(zone)
			payload["zone.%s.percentage" % zone_name] = zone_percentage(zone)
		for band in range(ContestBand.COUNT):
			var band_name: String = ContestBand.IDS[band]
			payload["contest.%s.attempts" % band_name] = contest_attempts[band]
			payload["contest.%s.share" % band_name] = contest_share(band)
			payload["contest.%s.percentage" % band_name] = contest_percentage(band)
		return payload


var totals := Totals.new()
## Every reconciliation breach, in the order found. Published verbatim.
var violations: PackedStringArray = PackedStringArray()


## Walks one finished game.
##
## The possession lifecycle is read from `POSSESSION_ENDED`, which §24.3 makes
## authoritative, and cross-checked against the possession records. Both are
## kept because they are produced by different code paths: if the reducer and
## the record writer ever disagree, the disagreement is the finding.
func accumulate(input: MatchInput, output: MatchSimulationOutput) -> void:
	totals.games += 1

	var ledger_points: int = 0
	var possession_ended: int = 0
	var seen_possessions: Dictionary = {}
	# Attempts open in the current possession, so a result without an attempt
	# can be named rather than merely counted.
	var open_attempts: int = 0
	var attempt_zone: int = -1
	## Carried from the attempt, because the contest band exists **only** on
	## `FIELD_GOAL_ATTEMPT`. On `FIELD_GOAL_MADE` the same `detail_id` field
	## holds the assisted state instead, so reading the band off the make
	## silently attributed every made shot to no band at all and left every
	## contest accuracy reading 0.0000.
	var attempt_band: int = -1
	var attempt_is_putback: bool = false
	var possession_had_offensive_rebound: bool = false
	var possession_points_after_rebound: int = 0
	var possession_in_transition: bool = false
	var possession_points: int = 0
	var possession_free_throws_from_foul: bool = false
	var possession_had_shot: bool = false
	var in_garbage_time: bool = false
	var garbage_points_this_possession: int = 0

	for event: MatchDomainEvent in output.events:
		match event.event_type:
			MatchDomainEvent.GARBAGE_TIME:
				in_garbage_time = true
			MatchDomainEvent.POSSESSION_STARTED:
				possession_had_offensive_rebound = false
				possession_points_after_rebound = 0
				possession_in_transition = false
				possession_points = 0
				possession_free_throws_from_foul = false
				possession_had_shot = false
				garbage_points_this_possession = 0
				open_attempts = 0
			MatchDomainEvent.TRANSITION_ENTERED:
				possession_in_transition = true
			MatchDomainEvent.FIELD_GOAL_ATTEMPT:
				open_attempts += 1
				attempt_zone = ShotZone.from_id(event.zone_id)
				# A putback is an attempt taken after this possession already
				# collected an offensive rebound and before it ended.
				attempt_is_putback = possession_had_offensive_rebound
				if attempt_is_putback:
					totals.putback_attempts += 1
				totals.zone_attempts[attempt_zone] += 1
				attempt_band = ContestBand.from_id(event.detail_id)
				if attempt_band >= 0 and attempt_band < ContestBand.COUNT:
					totals.contest_attempts[attempt_band] += 1
				if ShotZone.is_three(attempt_zone):
					totals.three_point_attempted += 1
				else:
					totals.two_point_attempted += 1
				possession_had_shot = true
			MatchDomainEvent.FIELD_GOAL_MADE:
				if open_attempts <= 0:
					violations.append(
						"%s: field_goal_made at sequence %d with no open attempt"
						% [input.match_id, event.sequence])
				open_attempts = maxi(open_attempts - 1, 0)
				var made_zone: int = ShotZone.from_id(event.zone_id)
				totals.zone_makes[made_zone] += 1
				if attempt_band >= 0 and attempt_band < ContestBand.COUNT:
					totals.contest_makes[attempt_band] += 1
				if ShotZone.is_three(made_zone):
					totals.three_point_made += 1
				else:
					totals.two_point_made += 1
				match event.detail_id:
					PassCreation.CATCH_AND_SHOOT:
						totals.catch_and_shoot_makes += 1
					PassCreation.UNASSISTED:
						totals.unassisted_makes += 1
					_:
						totals.assisted_makes += 1
				if attempt_is_putback:
					totals.putback_makes += 1
				ledger_points += event.points
				possession_points += event.points
				if possession_had_offensive_rebound:
					possession_points_after_rebound += event.points
				if in_garbage_time:
					garbage_points_this_possession += event.points
			MatchDomainEvent.FIELD_GOAL_MISSED:
				open_attempts = maxi(open_attempts - 1, 0)
			MatchDomainEvent.FREE_THROW_AWARDED:
				# Free throws awarded without a shot in this possession came
				# from a non-shooting foul: a foul-generated trip.
				if not possession_had_shot:
					possession_free_throws_from_foul = true
			MatchDomainEvent.FREE_THROW_MADE:
				# A made free throw is worth exactly one point, and the ledger
				# says so by event type rather than in the `points` field: the
				# emission passes `points = 0` and uses `amount` for the attempt
				# index. Reading `event.points` here silently dropped every
				# free-throw point — about 30 a game — and the reconciliation
				# caught it on the first ten games rather than after a
				# decomposition had been built on top of it.
				totals.free_throws_attempted += 1
				totals.free_throws_made += 1
				ledger_points += FREE_THROW_POINTS
				possession_points += FREE_THROW_POINTS
				if possession_had_offensive_rebound:
					possession_points_after_rebound += FREE_THROW_POINTS
				if in_garbage_time:
					garbage_points_this_possession += FREE_THROW_POINTS
			MatchDomainEvent.FREE_THROW_MISSED:
				totals.free_throws_attempted += 1
			MatchDomainEvent.TURNOVER:
				totals.turnovers += 1
			MatchDomainEvent.FOUL:
				if event.detail_id == &"shooting":
					totals.shooting_fouls += 1
			MatchDomainEvent.REBOUND:
				if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
					totals.offensive_rebounds += 1
					possession_had_offensive_rebound = true
				else:
					totals.defensive_rebounds += 1
			MatchDomainEvent.POSSESSION_ENDED:
				possession_ended += 1
				if seen_possessions.has(event.possession_id):
					violations.append(
						"%s: possession %d ended twice"
						% [input.match_id, event.possession_id])
				seen_possessions[event.possession_id] = true
				if open_attempts != 0:
					violations.append(
						"%s: possession %d ended with %d unresolved attempt(s)"
						% [input.match_id, event.possession_id, open_attempts])
				if possession_had_offensive_rebound:
					totals.extended_possessions += 1
					totals.second_chance_points += possession_points_after_rebound
				if possession_in_transition:
					totals.transition_possessions += 1
					totals.transition_points += possession_points
				if possession_free_throws_from_foul:
					totals.foul_generated_trips += 1
				if in_garbage_time:
					totals.garbage_time_possessions += 1
					totals.garbage_time_points += garbage_points_this_possession
			_:
				pass

	totals.points += ledger_points
	totals.possessions += possession_ended

	# --- the reconciliations ------------------------------------------------
	var record_points: int = 0
	for record: PossessionRecord in output.possessions:
		record_points += record.points_scored
	if record_points != ledger_points:
		violations.append(
			"%s: possession records total %d points, the ledger totals %d"
			% [input.match_id, record_points, ledger_points])
	if output.possessions.size() != possession_ended:
		violations.append(
			"%s: %d possession records against %d POSSESSION_ENDED events"
			% [input.match_id, output.possessions.size(), possession_ended])

	var result: MatchFinalResult = output.final_result
	var box_points: int = result.home_score + result.away_score
	if box_points != ledger_points:
		violations.append(
			"%s: box score totals %d points, the ledger totals %d"
			% [input.match_id, box_points, ledger_points])


## The accounting identity, checked over everything accumulated so far.
func identity_holds() -> bool:
	return totals.accounted_points() == totals.points


func unexplained_points() -> int:
	return totals.points - totals.accounted_points()


## True when every identity closed and nothing was orphaned or duplicated.
func is_reconciled() -> bool:
	return violations.is_empty() and identity_holds()


func to_dictionary() -> Dictionary:
	var payload: Dictionary = totals.to_dictionary()
	payload["identity_holds"] = identity_holds()
	payload["unexplained_points"] = unexplained_points()
	payload["violations"] = violations.size()
	payload["reconciled"] = is_reconciled()
	return payload
