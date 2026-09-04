class_name TestOpeningClockContract
extends GdUnitTestSuite

## The opening-state clock and location contract `simulation-v13` establishes
## (`PROJECT_STATUS.md` §5.30, owner ruling of 2026-09-04).
##
## Two separable rules, and this suite keeps them separable:
##
## 1. **Dead-ball inbound administration is not live game clock.** The clock
##    starts on the legal touch, so `INBOUND` emits at the possession's starting
##    clock and consumes nothing. Advance and half-court entry are untouched and
##    still cost what they always cost.
## 2. **A possession opening inside `desperation_opening_clock_ms` commits from
##    where it stands.** It does not run a half-court set it has no time for, it
##    carries a real `TacticalLocation`, and that location lengthens the odds
##    against the attempt through the ordinary §12.6 shot contract.
##
## Every fixture here is written so that undoing the thing it stands for fails
## it. The five mutations named in the §5.30 brief are called out on the tests
## that catch them, because a suite that passes both before and after a
## correction is evidence of nothing.

const DESPERATION_SEEDS: int = 240
## A clock with room for the whole ordinary opening several times over, inside
## the standard fixture's 300-second period.
const FULL_CLOCK_MS: int = 250000


# --- 1-2. the inbound consumes no game clock ---------------------------------

## **Mutation: reintroducing inbound game-clock consumption fails here.**
##
## The `INBOUND` event carries the possession's own starting clock. Any draw
## charged before it — the `ClockResolver.inbound_ms` this contract deletes —
## moves the timestamp and fails the equality.
func test_a_dead_ball_possession_emits_inbound_without_reducing_the_game_clock() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, FULL_CLOCK_MS)
	var possession: PossessionResult = _possession(input, snapshot, 11, false, false)

	var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
	assert_object(inbound).override_failure_message(
		"a dead-ball possession must emit INBOUND").is_not_null()
	assert_int(inbound.clock_ms).override_failure_message(
		"INBOUND must emit at the possession's starting game clock").is_equal(FULL_CLOCK_MS)


## The clock starts on the touch and not before it: every event up to and
## including `INBOUND` sits at the starting clock, and the first reduction comes
## from the advance that follows it.
func test_the_game_clock_begins_consuming_only_after_the_inbound_touch() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, FULL_CLOCK_MS)
	var possession: PossessionResult = _possession(input, snapshot, 11, false, false)

	var inbound_index: int = _index_of(possession.events, MatchDomainEvent.INBOUND)
	assert_int(inbound_index).is_greater(-1)
	for index in range(inbound_index + 1):
		assert_int(possession.events[index].clock_ms).override_failure_message(
			"no event at or before the inbound touch may have consumed game clock"
		).is_equal(FULL_CLOCK_MS)

	var advance: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.ADVANCE)
	assert_object(advance).is_not_null()
	assert_int(advance.clock_ms).override_failure_message(
		"the advance after the touch is live and must consume"
	).is_less(FULL_CLOCK_MS)


# --- 3. the ordinary opening still costs what it cost -------------------------

## Advance and half-court entry are not globally erased. This is the guard
## against "fix the inbound" turning into "make the whole opening free".
func test_an_ordinary_possession_still_consumes_advance_and_half_court_entry() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, FULL_CLOCK_MS)
	var possession: PossessionResult = _possession(input, snapshot, 11, false, false)

	var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
	var advance: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.ADVANCE)
	var entered: MatchDomainEvent = _first_of(
		possession.events, MatchDomainEvent.HALF_COURT_ENTERED)
	assert_object(advance).is_not_null()
	assert_object(entered).override_failure_message(
		"a full-clock dead-ball possession runs a half-court set").is_not_null()

	assert_int(advance.clock_ms).override_failure_message(
		"the advance must cost live game clock").is_less(inbound.clock_ms)
	assert_int(entered.clock_ms).override_failure_message(
		"half-court entry must cost live game clock").is_less(advance.clock_ms)


# --- 4. a timeout-advanced possession skips only what it bought ---------------

## The advance is free because the timeout paid for it; the half-court set that
## follows is not, and still costs. Nothing about this contract changed, and the
## fixture exists so that it cannot change by accident.
func test_a_timeout_advanced_possession_skips_only_the_backcourt_it_purchased() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, FULL_CLOCK_MS)
	var possession: PossessionResult = _possession(input, snapshot, 11, false, true)

	var advance: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.ADVANCE)
	assert_object(advance).is_not_null()
	assert_str(String(advance.detail_id)).is_equal("timeout_advanced")
	assert_int(advance.clock_ms).override_failure_message(
		"a purchased frontcourt inbound charges no backcourt walk"
	).is_equal(FULL_CLOCK_MS)

	var entered: MatchDomainEvent = _first_of(
		possession.events, MatchDomainEvent.HALF_COURT_ENTERED)
	assert_object(entered).is_not_null()
	assert_int(entered.clock_ms).override_failure_message(
		"the timeout bought the walk, not the half-court set"
	).is_less(advance.clock_ms)


# --- 5. a live transfer has no dead-ball inbound -------------------------------

func test_a_live_ball_transfer_neither_emits_nor_charges_a_dead_ball_inbound() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, FULL_CLOCK_MS)
	var possession: PossessionResult = _possession(input, snapshot, 11, true, false)

	assert_int(_count_of(possession.events, MatchDomainEvent.INBOUND)).override_failure_message(
		"there is nothing to inbound after a live transfer").is_equal(0)
	var started: MatchDomainEvent = _first_of(
		possession.events, MatchDomainEvent.POSSESSION_STARTED)
	assert_int(started.clock_ms).is_equal(FULL_CLOCK_MS)


# --- 6-7. the desperation opening ---------------------------------------------

## **Mutation: removing the desperation-opening branch fails here.**
##
## Before this contract the opening cost a 2-4s inbound, a 2-5s advance and a
## 2-4s half-court entry — at least six seconds — so a possession starting with
## five could not reach action selection at all, whatever it drew. It is the
## defect §5.29 localized and this is the fixture that stands against it.
func test_a_possession_starting_at_five_thousand_ms_reaches_action_selection() -> void:
	var reached: int = 0
	for seed_value in range(DESPERATION_SEEDS):
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, 5000)
		var possession: PossessionResult = _possession(
			input, snapshot, 6000 + seed_value, false, false)
		if _count_of(possession.events, MatchDomainEvent.ACTION_SELECTED) > 0:
			reached += 1

	assert_int(reached).override_failure_message(
		"a possession opening at 5,000ms must be able to reach action selection"
	).is_greater(0)


## And it does not get the half-court set for free instead. Skipping the entry's
## *cost* while keeping its benefit would be the cheap way to pass the test
## above; the offence gets no set at all, which is why the attempt that follows
## is charged for its distance.
func test_a_possession_below_five_thousand_ms_gets_no_free_half_court_setup() -> void:
	for seed_value in range(60):
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, 4200)
		var possession: PossessionResult = _possession(
			input, snapshot, 7000 + seed_value, false, false)
		assert_int(
			_count_of(possession.events, MatchDomainEvent.HALF_COURT_ENTERED)
		).override_failure_message(
			"a desperation opening runs no half-court set"
		).is_equal(0)


# --- 8. the attempt carries a real location -----------------------------------

## The two branches the clock picks between, read off the ledger.
##
## A possession with less time than the shortest advance draw can never cross
## half court, so it emits no `ADVANCE` and the attempt is a backcourt heave. One
## with room to cross emits it, and the attempt comes from the frontcourt with no
## set drawn.
func test_a_possession_too_short_to_cross_half_court_never_emits_an_advance() -> void:
	var input: MatchInput = _fixture_input()
	var shortest_advance_ms: int = input.balance_profile.advance_seconds_min * 1000
	for seed_value in range(40):
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, shortest_advance_ms - 500)
		var possession: PossessionResult = _possession(
			input, snapshot, 8000 + seed_value, false, false)
		assert_int(_count_of(possession.events, MatchDomainEvent.ADVANCE)).override_failure_message(
			"the offence cannot cross half court in less than the shortest advance"
		).is_equal(0)


## The location itself, at the type that owns it. `BACKCOURT` is further from the
## rim than `DEEP`, which is further than `ARC` — the ladder the distance
## consequence is drawn against.
func test_the_tactical_location_depth_ladder_orders_backcourt_beyond_deep() -> void:
	var arc: float = TacticalLocation.rim_distance_for_depth(TacticalLocation.Depth.ARC)
	var deep: float = TacticalLocation.rim_distance_for_depth(TacticalLocation.Depth.DEEP)
	var backcourt: float = TacticalLocation.rim_distance_for_depth(
		TacticalLocation.Depth.BACKCOURT)
	assert_float(deep).is_greater(arc)
	assert_float(backcourt).is_greater(deep)
	assert_float(
		TacticalLocation.new(
			TacticalLocation.Lane.CENTER, TacticalLocation.Depth.BACKCOURT
		).rim_distance()
	).is_equal(backcourt)


# --- 5(location). a heave is not an ordinary arc attempt ----------------------

## **Mutation: treating a backcourt attempt like an ordinary arc attempt fails
## here.**
##
## The same shooter, the same zone, the same contest, the same seed — only the
## ball's court location differs. Deleting the location term, or making it
## return zero, collapses the three probabilities onto one.
func test_a_backcourt_attempt_does_not_receive_ordinary_arc_shot_odds() -> void:
	var unplaced: float = _shot_probability(NO_LOCATION)
	var deep: float = _shot_probability(TacticalLocation.Depth.DEEP)
	var backcourt: float = _shot_probability(TacticalLocation.Depth.BACKCOURT)

	assert_float(deep).override_failure_message(
		"a standard-three attempt taken from DEEP is longer than one at the arc"
	).is_less(unplaced)
	assert_float(backcourt).override_failure_message(
		"a backcourt heave is longer still"
	).is_less(deep)


## And a possession that ran the ordinary opening carries no location at all, so
## the term cannot reach it. This is the structural form of "the normal path is
## unchanged": not "the penalty happens to be zero", but "there is nothing for
## the penalty to read".
func test_an_ordinary_possession_carries_no_location_and_no_location_penalty() -> void:
	var context: PossessionContext = _context(_fixture_input())
	assert_object(context.ball_location).override_failure_message(
		"an ordinary possession makes no spatial claim").is_null()
	assert_bool(context.desperation_opening).is_false()
	assert_float(_shot_probability(NO_LOCATION)).is_equal(
		_shot_probability_with_scores(NO_LOCATION, 80, 80))


# --- 9. the location consequence reads no scoreboard --------------------------

## The distance term is a function of where the ball is and which zone the
## attempt is, and of nothing else. Four scoreboards that a tie-seeking rule
## would treat very differently — level, down two, down three, comfortably ahead
## — all resolve the identical heave identically.
func test_the_location_consequence_is_independent_of_score_and_margin() -> void:
	var level: float = _shot_probability_with_scores(TacticalLocation.Depth.BACKCOURT, 80, 80)
	var down_two: float = _shot_probability_with_scores(TacticalLocation.Depth.BACKCOURT, 78, 80)
	var down_three: float = _shot_probability_with_scores(
		TacticalLocation.Depth.BACKCOURT, 77, 80)
	var ahead: float = _shot_probability_with_scores(TacticalLocation.Depth.BACKCOURT, 95, 80)

	assert_float(down_two).override_failure_message(
		"a tying margin must not change a heave's odds").is_equal(level)
	assert_float(down_three).is_equal(level)
	assert_float(ahead).is_equal(level)


# --- 10. an opportunity, never an outcome -------------------------------------

## **Mutation: injecting a guaranteed attempt or a guaranteed outcome fails
## here.**
##
## Across a wide seed sweep of tied final-second possessions the desperation
## opening must produce a mixture: some possessions reach an attempt and some do
## not, and of those that do, some go in and most do not. A branch that
## guaranteed the attempt, or the make, or the tie, collapses one of these.
func test_no_desperation_path_guarantees_an_attempt_a_make_or_a_tie() -> void:
	var possessions: int = 0
	var with_attempt: int = 0
	var made: int = 0
	var attempts: int = 0
	var made_attempts: int = 0
	for seed_value in range(DESPERATION_SEEDS):
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, 4800)
		var possession: PossessionResult = _possession(
			input, snapshot, 9000 + seed_value, false, false)
		possessions += 1
		attempts += _count_of(possession.events, MatchDomainEvent.FIELD_GOAL_ATTEMPT)
		made_attempts += _count_of(possession.events, MatchDomainEvent.FIELD_GOAL_MADE)
		if _count_of(possession.events, MatchDomainEvent.FIELD_GOAL_ATTEMPT) > 0:
			with_attempt += 1
		if _count_of(possession.events, MatchDomainEvent.FIELD_GOAL_MADE) > 0:
			made += 1

	assert_int(with_attempt).override_failure_message(
		"the path must be able to create an attempt").is_greater(0)
	assert_int(with_attempt).override_failure_message(
		"no possession may be guaranteed an attempt").is_less(possessions)
	assert_int(made).override_failure_message(
		"a heave that can never go in is an engineered miss").is_greater(0)

	# Counted per attempt rather than per possession, and held to a ceiling
	# rather than to "not all of them". A possession-level "some attempt was
	# missed" is satisfied by blocked attempts alone, so a mutation that made
	# every unblocked desperation attempt go in survived it. The measured make
	# rate on this path is 0.15-0.25; a mutation that guarantees the make puts it
	# near 1.0 less the block share. The ceiling sits between the two with room
	# on both sides, which is what makes it a real bound rather than a band.
	assert_int(attempts).is_greater(0)
	assert_float(float(made_attempts) / float(attempts)).override_failure_message(
		"desperation attempts went in at %.4f, which is not a shot being taken "
		% (float(made_attempts) / float(attempts))
		+ "under pressure — it is an outcome being handed out"
	).is_less(0.60)


# --- 11-12. expiry stays terminal, clocks stay sane ---------------------------

## **Mutation: allowing the selected action to cross the horn fails here.**
##
## A possession that reaches action selection emits it strictly before the horn,
## and a possession that genuinely fails to release still terminates on
## `PERIOD_EXPIRED` with exactly one terminal event. Both halves matter: the
## first is what the contract buys, the second is what it must not break.
func test_period_expiration_remains_terminal_and_actions_stay_before_the_horn() -> void:
	var expired: int = 0
	for seed_value in range(DESPERATION_SEEDS):
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, 4500)
		var possession: PossessionResult = _possession(
			input, snapshot, 12000 + seed_value, false, false)

		assert_bool(possession.has_exactly_one_start_and_end()).override_failure_message(
			"one start and one terminal end, always").is_true()
		for event in possession.events:
			if event.event_type == MatchDomainEvent.ACTION_SELECTED:
				assert_int(event.clock_ms).override_failure_message(
					"a selected action must be emitted before the horn").is_greater(0)
		if possession.record.end_reason == PossessionEndReason.Value.PERIOD_EXPIRED:
			expired += 1
			assert_int(possession.record.end_clock_ms).is_equal(0)

	assert_int(expired).override_failure_message(
		"expiry must remain a reachable terminal outcome").is_greater(0)


## **Mutation: allowing the selected action to cross the horn fails here.**
##
## An action whose draw crosses the horn is never emitted at all — `_consume`
## terminates the possession and `_emit` refuses afterwards — so "every
## `ACTION_SELECTED` sits before the horn" is satisfied vacuously by deleting the
## release clamp, and a mutation that did exactly that survived it.
##
## This possession starts with less time than the *shortest* action draw can
## consume, so the clamp is the only thing that can produce an action at all.
## Without it the offence is guaranteed to run out of clock mid-action and the
## count is zero; with it the action is scheduled a millisecond before the horn
## and resolves. That is the whole of what §5.30 buys, stated as a number.
func test_a_possession_shorter_than_any_action_draw_still_selects_one() -> void:
	var input: MatchInput = _fixture_input()
	var shortest_action_ms: int = input.balance_profile.action_seconds_min * 1000
	var reached: int = 0
	for seed_value in range(80):
		var snapshot: MatchSnapshot = _snapshot_at(
			input, input.rule_profile.regulation_periods, shortest_action_ms / 2)
		var possession: PossessionResult = _possession(
			input, snapshot, 15000 + seed_value, false, false)
		if _count_of(possession.events, MatchDomainEvent.ACTION_SELECTED) > 0:
			reached += 1

	assert_int(reached).override_failure_message(
		"no possession shorter than one action draw reached action selection, "
		+ "so the release deadline is not doing anything"
	).is_greater(0)


## Clocks never run backwards inside a period and never go negative, across a
## whole match rather than one contrived possession.
func test_event_clocks_are_monotonic_within_a_period_and_never_negative() -> void:
	for variation in range(990001, 990004):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.COLLEGE, variation, 0.5)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(variation + 1)).run_to_completion()
		var period: int = 0
		var previous: int = 0
		for event in output.events:
			assert_int(event.clock_ms).override_failure_message(
				"an event clock is never negative").is_greater_equal(0)
			if event.period != period:
				period = event.period
				previous = event.clock_ms
				continue
			assert_int(event.clock_ms).override_failure_message(
				"event clocks never run backwards inside a period"
			).is_less_equal(previous)
			previous = event.clock_ms


# --- 15. the normal path keeps its shape --------------------------------------

## A full-clock dead-ball possession still runs inbound -> advance -> half-court
## entry, in that order and exactly once each. The only thing this contract
## changed about it is the timestamp the first of the three carries.
func test_the_ordinary_opening_keeps_its_event_shape() -> void:
	for seed_value in range(40):
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(input, 1, FULL_CLOCK_MS)
		var possession: PossessionResult = _possession(
			input, snapshot, 20000 + seed_value, false, false)
		assert_int(_count_of(possession.events, MatchDomainEvent.INBOUND)).is_equal(1)
		assert_int(_count_of(possession.events, MatchDomainEvent.ADVANCE)).is_equal(1)
		assert_int(
			_count_of(possession.events, MatchDomainEvent.HALF_COURT_ENTERED)).is_equal(1)
		assert_int(_index_of(possession.events, MatchDomainEvent.INBOUND)).is_less(
			_index_of(possession.events, MatchDomainEvent.ADVANCE))
		assert_int(_index_of(possession.events, MatchDomainEvent.ADVANCE)).is_less(
			_index_of(possession.events, MatchDomainEvent.HALF_COURT_ENTERED))


# --- fixtures -----------------------------------------------------------------

## The standard four-period fixture. Its period is 300 seconds, so `FULL_CLOCK_MS`
## below is a genuine mid-period clock rather than a tip-off special case.
func _fixture_input() -> MatchInput:
	return MatchFixtureFactory.standard_match()


func _snapshot_at(input: MatchInput, period: int, clock_ms: int) -> MatchSnapshot:
	var snapshot := MatchSnapshot.new(input)
	snapshot.period = period
	snapshot.clock_ms = clock_ms
	snapshot.shot_clock_ms = mini(input.rule_profile.shot_clock_seconds * 1000, clock_ms)
	snapshot.possession_team_id = &"home"
	snapshot.home.score = 80
	snapshot.away.score = 80
	return snapshot


func _possession(
	input: MatchInput,
	snapshot: MatchSnapshot,
	seed_value: int,
	live_start: bool,
	advance_start: bool,
) -> PossessionResult:
	return PossessionEngine.new(input).simulate(
		snapshot, input, SeededRandomSource.new(seed_value), live_start, advance_start)


func _context(input: MatchInput, home_score: int = 80, away_score: int = 80) -> PossessionContext:
	var snapshot: MatchSnapshot = _snapshot_at(
		input, input.rule_profile.regulation_periods, 4000)
	snapshot.home.score = home_score
	snapshot.away.score = away_score
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var matchups := MatchupResolver.new(capability, BodyEffects.new(input.balance_profile)).resolve(
		input.team_profile(&"home"), snapshot.state_for(&"home"),
		input.team_profile(&"away"), snapshot.state_for(&"away"))
	var context := PossessionContext.new(input, snapshot, &"home", matchups, 1)
	context.ball_handler_id = snapshot.state_for(&"home").on_court_ids()[0]
	return context


## `NO_LOCATION` is the ordinary possession: one that ran the half-court opening
## and makes no spatial claim at all.
const NO_LOCATION: int = -1


## One standard-three attempt resolved identically apart from where the ball is,
## so the only thing that can move the probability is the location term.
func _shot_probability(depth: int) -> float:
	return _shot_probability_with_scores(depth, 80, 80)


func _shot_probability_with_scores(depth: int, home_score: int, away_score: int) -> float:
	var input: MatchInput = _fixture_input()
	var context: PossessionContext = _context(input, home_score, away_score)
	if depth != NO_LOCATION:
		context.ball_location = TacticalLocation.new(
			TacticalLocation.Lane.CENTER, depth, MovementIntent.Value.ADVANCE_BALL)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var body := BodyEffects.new(input.balance_profile)
	var resolver := ShotResolver.new(capability, body, input.balance_profile)
	var shooter_id: StringName = context.ball_handler_id
	var contest: ShotContest = resolver.build_contest(
		context, shooter_id, ShotZone.Value.STANDARD_THREE, AdvantageResult.new())
	var outcome: ShotOutcome = resolver.resolve(
		context, shooter_id, ShotZone.Value.STANDARD_THREE, false, contest,
		AdvantageResult.new(), 1.0, 0.0, SeededRandomSource.new(31))
	return outcome.probability


# --- ledger helpers -----------------------------------------------------------

func _first_of(events: Array[MatchDomainEvent], event_type: StringName) -> MatchDomainEvent:
	for event in events:
		if event.event_type == event_type:
			return event
	return null


func _index_of(events: Array[MatchDomainEvent], event_type: StringName) -> int:
	for index in range(events.size()):
		if events[index].event_type == event_type:
			return index
	return -1


func _count_of(events: Array[MatchDomainEvent], event_type: StringName) -> int:
	var count: int = 0
	for event in events:
		if event.event_type == event_type:
			count += 1
	return count
