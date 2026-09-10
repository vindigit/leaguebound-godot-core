class_name TestOvertimeTrigger
extends GdUnitTestSuite

## The complete path from "regulation ended" to "overtime began"
## (`PROJECT_STATUS.md` §5.34, `SIMULATION_SPEC.md` §3.1, §5.1).
##
## §14.2's overtime rate has failed at every competition on every range measured
## since §5.28, and four corrections in a row have moved it by nothing. Before a
## fifth late-game behaviour is proposed, the *trigger* has to be eliminated as a
## cause — and eliminated by fixtures rather than by reading the code and finding
## it convincing.
##
## The claims this suite makes, each on evidence that fails if the claim stops
## being true:
##
## 1. A level score at the end of regulation is the **only** state that opens an
##    extra period, at every competition, at every margin from −3 to +3.
## 2. **No competition profile can disable, shorten away or bypass overtime.**
##    Every launch profile declares a positive overtime length and answers
##    `OVERTIME` for every period past its own regulation count — college
##    included, whose final regulation period is period 2.
## 3. Over a full-game sweep, **every replayed regulation tie entered overtime
##    and every overtime entry followed a replayed regulation tie.** The
##    regulation score is recomputed from the ledger rather than read from the
##    result, so the two sides of the identity come from different places.
## 4. **The horn cannot delete a score and cannot invent one.** No event carries a
##    negative clock, nothing is emitted after a possession terminates, and a
##    possession's points equal the sum of its own scoring events.
## 5. **A free-throw trip drawn before the horn is shot in full after it.** Every
##    awarded attempt is taken, at a clock of at least one millisecond, and its
##    makes are on the scoreboard the overtime decision reads.
## 6. **Play, Sim and Skip agree about regulation ties**, ledger for ledger.
##
## Every sweep asserts that the branch it is about was actually reached. A
## fixture that silently stops producing ties would otherwise pass while covering
## nothing, which is the failure mode `GoldenScenarios` already documents for the
## overtime golden seed.

## Seeds are swept rather than pinned. A pinned seed that stops finishing level
## is a fixture that stops testing the trigger, and this suite has to survive a
## balance change without a maintainer noticing it went quiet — so it sweeps a
## bounded range and asserts what it found.
const TIE_SWEEP_SEEDS: int = 120
const HORN_SWEEP_SEEDS: int = 160
## Parity is checked on at least this many seeds, and then on as many more as it
## takes to see both a regulation tie and a decided game — capped, so a fixture
## that stopped producing ties fails loudly instead of running forever. Three
## complete games per seed is the most expensive thing in this suite, so it stops
## as soon as it has the evidence rather than sweeping a fixed block.
const PARITY_MINIMUM_SEEDS: int = 8
const PARITY_SEED_CAP: int = 96

## Clocks used by the possession-level horn fixtures, in milliseconds. The first
## is inside `desperation_opening_clock_ms` and the second is not, so both the
## desperation opening and the ordinary one are exercised.
const HORN_CLOCKS_MS: PackedInt32Array = [1200, 3500, 9000]

## A margin no single possession can erase, used to show that the tie decision
## is about the score and not about the clock.
const UNREACHABLE_MARGIN: int = 9


# --- 1. the decision itself ---------------------------------------------------

## **Mutation: comparing scores with `>=`, `<=`, or `!=` inverted fails here.**
##
## The whole trigger is one comparison in `PeriodController.match_is_complete`.
## This drives it across every launch profile and every margin a close game
## actually finishes on, and counts the branches it reached so a profile list
## that quietly shrank cannot pass.
func test_only_a_level_score_leaves_regulation_incomplete() -> void:
	var profiles_checked: int = 0
	var level_states: int = 0
	var decided_states: int = 0
	for competition: int in _launch_competitions():
		var rules: CompetitionRuleProfile = _rules_for(competition)
		var input: MatchInput = _profile_input(competition)
		profiles_checked += 1
		for margin: int in [-3, -2, -1, 0, 1, 2, 3]:
			var snapshot: MatchSnapshot = _expired_regulation(input, margin)
			var complete: bool = PeriodController.new().match_is_complete(snapshot, rules)
			if margin == 0:
				level_states += 1
				assert_bool(complete).override_failure_message(
					"%s: a level score at the end of regulation must not complete the match"
					% rules.profile_id).is_false()
			else:
				decided_states += 1
				assert_bool(complete).override_failure_message(
					"%s: a %d-point margin at the end of regulation must complete the match"
					% [rules.profile_id, margin]).is_true()
	assert_int(profiles_checked).override_failure_message(
		"every launch profile must be checked").is_equal(5)
	assert_int(level_states).is_equal(5)
	assert_int(decided_states).is_equal(30)


## A period that has not expired never completes a match, whatever the score —
## so the trigger cannot fire early and hand a decided game an extra period.
func test_a_running_clock_never_completes_a_match() -> void:
	var checked: int = 0
	for competition: int in _launch_competitions():
		var rules: CompetitionRuleProfile = _rules_for(competition)
		var input: MatchInput = _profile_input(competition)
		for margin: int in [0, 1, UNREACHABLE_MARGIN]:
			var snapshot: MatchSnapshot = _expired_regulation(input, margin)
			snapshot.clock_ms = 1
			checked += 1
			assert_bool(PeriodController.new().match_is_complete(snapshot, rules)
			).override_failure_message(
				"%s: one millisecond of clock is still a live period" % rules.profile_id
			).is_false()
	assert_int(checked).is_equal(15)


## An earlier period ending level is an ordinary period break, not an overtime.
## College is the case that makes this worth asserting: its regulation is two
## halves, so "period 2" is a final period for college and a mid-game break for
## everybody else.
func test_a_level_score_before_the_final_period_is_not_overtime() -> void:
	var checked: int = 0
	for competition: int in _launch_competitions():
		var rules: CompetitionRuleProfile = _rules_for(competition)
		if rules.regulation_periods < 2:
			continue
		var snapshot: MatchSnapshot = _expired_regulation(_profile_input(competition), 0)
		snapshot.period = rules.regulation_periods - 1
		checked += 1
		assert_bool(PeriodController.new().match_is_complete(snapshot, rules)
		).override_failure_message(
			"%s: a level score at a mid-game break must not complete the match"
			% rules.profile_id).is_false()
		assert_int(rules.period_category(snapshot.period)).override_failure_message(
			"%s: period %d is not the final regulation period"
			% [rules.profile_id, snapshot.period]
		).is_not_equal(PeriodCategory.Value.FINAL_REGULATION)
	assert_int(checked).is_equal(5)


# --- 2. no profile can disable, shorten away or bypass overtime ----------------

## **Mutation: a zero or negative overtime length, or a profile answering
## `FINAL_REGULATION` past its own regulation count, fails here.**
func test_no_competition_profile_can_bypass_or_shorten_away_overtime() -> void:
	var profiles_checked: int = 0
	var overtime_periods_checked: int = 0
	for competition: int in _launch_competitions():
		var rules: CompetitionRuleProfile = _rules_for(competition)
		var input: MatchInput = _profile_input(competition)
		profiles_checked += 1
		assert_int(rules.overtime_seconds).override_failure_message(
			"%s: an overtime period must have positive length" % rules.profile_id
		).is_greater(0)
		for extra: int in [1, 2, 3]:
			var period: int = rules.regulation_periods + extra
			overtime_periods_checked += 1
			assert_int(rules.period_length_ms(period)).override_failure_message(
				"%s: overtime period %d must be one overtime long"
				% [rules.profile_id, period]
			).is_equal(rules.overtime_seconds * 1000)
			assert_int(rules.period_category(period)).override_failure_message(
				"%s: period %d is past regulation and must be an overtime period"
				% [rules.profile_id, period]
			).is_equal(PeriodCategory.Value.OVERTIME)
			var snapshot: MatchSnapshot = _expired_regulation(input, 0)
			snapshot.period = period
			assert_bool(PeriodController.new().match_is_complete(snapshot, rules)
			).override_failure_message(
				"%s: a level overtime must open another one" % rules.profile_id).is_false()
	assert_int(profiles_checked).is_equal(5)
	assert_int(overtime_periods_checked).is_equal(15)


## The counter the result publishes is the period number and nothing else, so a
## reader cannot be told a game went to overtime that did not, or told it went
## to one when it went to three.
func test_the_overtime_counter_is_the_period_number_past_regulation() -> void:
	var checked: int = 0
	for competition: int in _launch_competitions():
		var rules: CompetitionRuleProfile = _rules_for(competition)
		var input: MatchInput = _profile_input(competition)
		var reducer := MatchStateReducer.new(input)
		var state := MatchSnapshot.new(input)
		# Walked one period at a time rather than jumped, so the state the
		# reducer folds each transition onto is the state a real game reaches.
		for period: int in range(2, rules.regulation_periods + 4):
			var writer := MatchEventWriter.new(
				input.match_id, state.event_sequence, period, rules.period_length_ms(period))
			writer.emit(
				MatchDomainEvent.PERIOD_STARTED, &"", &"", &"", &"", &"", &"", &"", 0, period)
			for event in writer.events:
				reducer.apply_event(state, event)
			var expected: int = maxi(0, period - rules.regulation_periods)
			checked += 1
			assert_int(state.overtime_periods).override_failure_message(
				"%s: period %d must read as overtime number %d"
				% [rules.profile_id, period, expected]).is_equal(expected)
			assert_int(state.clock_ms).override_failure_message(
				"%s: period %d must open at its own length" % [rules.profile_id, period]
			).is_equal(rules.period_length_ms(period))
	assert_int(checked).override_failure_message(
		"every competition must be walked from period 2 through its third overtime"
	).is_greater_equal(15)


# --- 3. regulation ties and overtime entries reconcile ------------------------

## **The Hypothesis A invariant, on whole games.**
##
## The left side is recomputed from the ledger — the score reduced immediately
## before the final regulation `PERIOD_ENDED` — and the right side is the count
## the result publishes. They come from different places on purpose: a single
## derivation could be wrong in both directions at once and still agree with
## itself.
func test_every_replayed_regulation_tie_entered_overtime_and_no_other_game_did() -> void:
	var ties: int = 0
	var overtimes: int = 0
	var decided: int = 0
	for index in range(TIE_SWEEP_SEEDS):
		var input: MatchInput = MatchFixtureFactory.even_match()
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(index + 1)).run_to_completion()
		var margin: int = _regulation_margin(input, output)
		var entered: bool = output.final_result.overtime_periods > 0
		if margin == 0:
			ties += 1
		else:
			decided += 1
		if entered:
			overtimes += 1
		assert_bool(entered).override_failure_message(
			"seed %d: regulation margin %d and overtime_periods %d disagree"
			% [index + 1, margin, output.final_result.overtime_periods]
		).is_equal(margin == 0)
		assert_int(output.final_result.home_score).override_failure_message(
			"seed %d finished level, which no completed match may do" % [index + 1]
		).is_not_equal(output.final_result.away_score)
	assert_int(ties).override_failure_message(
		"the fixture stopped producing regulation ties and is no longer testing the trigger"
	).is_greater(0)
	assert_int(decided).override_failure_message(
		"the fixture stopped producing decided games").is_greater(0)
	assert_int(overtimes).is_equal(ties)


## Multiple overtimes, on a fixture whose overtime period is short enough that a
## second one is reached inside a bounded sweep. Each extra period is one
## overtime long, and the published count is the number of them.
func test_a_level_overtime_opens_another_one() -> void:
	var input: MatchInput = _multi_overtime_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var multiples: int = 0
	var singles: int = 0
	for index in range(TIE_SWEEP_SEEDS):
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(index + 1)).run_to_completion()
		var periods: int = output.final_result.overtime_periods
		if periods == 0:
			continue
		if periods > 1:
			multiples += 1
		else:
			singles += 1
		var highest: int = 0
		for event in output.events:
			if event.event_type == MatchDomainEvent.PERIOD_STARTED:
				highest = maxi(highest, event.period)
				if event.period > rules.regulation_periods:
					assert_int(event.clock_ms).override_failure_message(
						"seed %d: overtime period %d must open at one overtime"
						% [index + 1, event.period]
					).is_equal(rules.overtime_seconds * 1000)
		assert_int(periods).override_failure_message(
			"seed %d: the published overtime count must be the last period past regulation"
			% [index + 1]).is_equal(highest - rules.regulation_periods)
	assert_int(singles).override_failure_message(
		"the multi-overtime fixture reached no single overtime").is_greater(0)
	assert_int(multiples).override_failure_message(
		"the multi-overtime fixture reached no second overtime and is not testing "
		+ "repeated overtime").is_greater(0)


# --- 4. the horn ---------------------------------------------------------------

## **Mutation: emitting the selected action before consuming its time, or
## allowing an event past the horn, fails here.**
##
## Two things have to be true at once and they pull against each other: a shot
## released before the horn counts, and one that would be released after it does
## not exist at all. The sweep asserts that both actually happened — a fixture
## where every possession expires, or none does, proves neither.
func test_no_score_is_committed_after_the_horn_and_none_before_it_is_lost() -> void:
	var released_before_horn: int = 0
	var expired_without_release: int = 0
	for clock_ms: int in HORN_CLOCKS_MS:
		for index in range(HORN_SWEEP_SEEDS / HORN_CLOCKS_MS.size()):
			var input: MatchInput = MatchFixtureFactory.standard_match()
			var rules: CompetitionRuleProfile = input.rule_profile
			var snapshot: MatchSnapshot = _expired_regulation(input, -2)
			snapshot.period = rules.regulation_periods
			snapshot.clock_ms = clock_ms
			snapshot.shot_clock_ms = mini(rules.shot_clock_seconds * 1000, clock_ms)
			snapshot.possession_team_id = input.home.team_id
			var possession: PossessionResult = PossessionEngine.new(input).simulate(
				snapshot, input, SeededRandomSource.new(9000 + index), false, false,
				RestartCause.Value.PERIOD_START)
			var attempts: int = 0
			var points_from_events: int = 0
			for event in possession.events:
				assert_int(event.clock_ms).override_failure_message(
					"a %s event was stamped at a negative clock" % event.event_type
				).is_greater_equal(0)
				if event.event_type == MatchDomainEvent.FIELD_GOAL_ATTEMPT:
					attempts += 1
				elif event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
					points_from_events += event.points
				elif event.event_type == MatchDomainEvent.FREE_THROW_MADE:
					points_from_events += 1
			assert_str(String(possession.events[possession.events.size() - 1].event_type)
			).override_failure_message(
				"a terminated possession emitted an event after its own end"
			).is_equal(String(MatchDomainEvent.POSSESSION_ENDED))
			assert_int(possession.record.points_scored).override_failure_message(
				"the possession's points must be the sum of its own scoring events"
			).is_equal(points_from_events)
			if attempts > 0:
				released_before_horn += 1
			elif possession.record.end_reason == PossessionEndReason.Value.PERIOD_EXPIRED:
				expired_without_release += 1
				assert_int(possession.record.points_scored).override_failure_message(
					"a possession that never released a shot cannot have scored"
				).is_equal(0)
	assert_int(released_before_horn).override_failure_message(
		"no possession released a shot before the horn; the fixture proves nothing"
	).is_greater(0)
	assert_int(expired_without_release).override_failure_message(
		"no possession expired before releasing; the after-the-horn case is untested"
	).is_greater(0)


## A period ends on the horn and not before it: the terminal record of an expired
## possession carries a clock of exactly zero, so no game time is lost or
## invented at the boundary the tie decision is taken on.
func test_an_expired_possession_ends_at_exactly_zero() -> void:
	var expired: int = 0
	for index in range(HORN_SWEEP_SEEDS):
		var input: MatchInput = MatchFixtureFactory.standard_match()
		var rules: CompetitionRuleProfile = input.rule_profile
		var snapshot: MatchSnapshot = _expired_regulation(input, 0)
		snapshot.period = rules.regulation_periods
		snapshot.clock_ms = 900
		snapshot.shot_clock_ms = 900
		snapshot.possession_team_id = input.home.team_id
		var possession: PossessionResult = PossessionEngine.new(input).simulate(
			snapshot, input, SeededRandomSource.new(4400 + index), false, false,
			RestartCause.Value.PERIOD_START)
		if possession.record.end_reason != PossessionEndReason.Value.PERIOD_EXPIRED:
			continue
		expired += 1
		assert_int(possession.record.end_clock_ms).override_failure_message(
			"an expired possession must end at exactly zero").is_equal(0)
	assert_int(expired).override_failure_message(
		"no possession expired; the boundary is untested").is_greater(0)


# --- 5. free throws that outlast the horn --------------------------------------

## **Mutation: routing free-throw event time through `_consume` fails here.**
##
## A foul drawn before the horn is shot after it. Every awarded attempt is taken,
## at a clock the period has not yet expired on, and every make is on the
## scoreboard — because the scoreboard is what the overtime decision reads.
func test_a_free_throw_trip_drawn_before_the_horn_is_shot_in_full() -> void:
	var trips: int = 0
	var attempts_taken: int = 0
	for index in range(HORN_SWEEP_SEEDS):
		var input: MatchInput = MatchFixtureFactory.bonus_match()
		var rules: CompetitionRuleProfile = input.rule_profile
		var snapshot: MatchSnapshot = _expired_regulation(input, -1)
		snapshot.period = rules.regulation_periods
		snapshot.clock_ms = 1500
		snapshot.shot_clock_ms = 1500
		snapshot.possession_team_id = input.home.team_id
		var possession: PossessionResult = PossessionEngine.new(input).simulate(
			snapshot, input, SeededRandomSource.new(6100 + index), false, false,
			RestartCause.Value.PERIOD_START)
		var awarded: int = 0
		var taken: int = 0
		var makes: int = 0
		for event in possession.events:
			if event.event_type == MatchDomainEvent.FREE_THROW_AWARDED:
				awarded += event.amount
			elif event.event_type == MatchDomainEvent.FREE_THROW_MADE:
				taken += 1
				makes += 1
				assert_int(event.clock_ms).override_failure_message(
					"a free throw was shot after the period expired").is_greater(0)
			elif event.event_type == MatchDomainEvent.FREE_THROW_MISSED:
				taken += 1
				assert_int(event.clock_ms).override_failure_message(
					"a free throw was shot after the period expired").is_greater(0)
		if awarded == 0:
			continue
		trips += 1
		attempts_taken += taken
		assert_int(taken).override_failure_message(
			"seed %d: %d attempts were awarded and %d were taken; §13.2 attributes "
			% [6100 + index, awarded, taken] + "each exactly once, and zero is not once"
		).is_greater(0)
		var free_throw_points: int = makes
		var field_goal_points: int = 0
		for event in possession.events:
			if event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
				field_goal_points += event.points
		assert_int(possession.record.points_scored).override_failure_message(
			"free-throw makes must reach the scoreboard the tie decision reads"
		).is_equal(free_throw_points + field_goal_points)
	assert_int(trips).override_failure_message(
		"no free-throw trip was drawn inside the horn window; the case is untested"
	).is_greater(0)
	assert_int(attempts_taken).is_greater_equal(trips)


## A missed last attempt is a live ball where the rules make it one, so it is
## followed by a rebound — or by the period expiring on the rebound itself.
## Never by nothing, which would be a possession that ended without a result.
func test_a_missed_final_free_throw_is_rebounded_or_expires() -> void:
	var misses: int = 0
	for index in range(HORN_SWEEP_SEEDS):
		var input: MatchInput = MatchFixtureFactory.bonus_match()
		var rules: CompetitionRuleProfile = input.rule_profile
		var snapshot: MatchSnapshot = _expired_regulation(input, -1)
		snapshot.period = rules.regulation_periods
		snapshot.clock_ms = 4000
		snapshot.shot_clock_ms = 4000
		snapshot.possession_team_id = input.home.team_id
		var possession: PossessionResult = PossessionEngine.new(input).simulate(
			snapshot, input, SeededRandomSource.new(7700 + index), false, false,
			RestartCause.Value.PERIOD_START)
		var last_free_throw: int = -1
		var rebound_after: bool = false
		for position in range(possession.events.size()):
			var event: MatchDomainEvent = possession.events[position]
			if event.event_type == MatchDomainEvent.FREE_THROW_MADE \
					or event.event_type == MatchDomainEvent.FREE_THROW_MISSED:
				last_free_throw = position
				rebound_after = false
			elif event.event_type == MatchDomainEvent.REBOUND and last_free_throw >= 0:
				rebound_after = true
		if last_free_throw < 0:
			continue
		var final_attempt: MatchDomainEvent = possession.events[last_free_throw]
		if final_attempt.event_type != MatchDomainEvent.FREE_THROW_MISSED:
			continue
		if not rules.final_free_throw_reboundable:
			continue
		misses += 1
		assert_bool(
			rebound_after
			or possession.record.end_reason == PossessionEndReason.Value.PERIOD_EXPIRED
		).override_failure_message(
			"seed %d: a live missed final free throw must be rebounded or expire"
			% [7700 + index]).is_true()
	assert_int(misses).override_failure_message(
		"no final free throw was missed; the live-rebound case is untested"
	).is_greater(0)


# --- 6. ordering: the last score is committed before the decision -------------

## **Mutation: taking the overtime decision before the final possession's events
## are reduced fails here.**
##
## The end of regulation is a `PERIOD_ENDED` event, and every scoring event of
## that period carries a lower sequence number than it. The score the decision
## reads is therefore the score after the last basket, not before it — and the
## sweep asserts that at least one game's last regulation score landed inside
## the final five seconds, so the ordering is exercised where it matters.
func test_the_final_regulation_score_is_committed_before_the_period_ends() -> void:
	var late_scores: int = 0
	var games: int = 0
	for index in range(TIE_SWEEP_SEEDS):
		var input: MatchInput = MatchFixtureFactory.even_match()
		var rules: CompetitionRuleProfile = input.rule_profile
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(index + 1)).run_to_completion()
		games += 1
		var boundary: int = -1
		var last_score_sequence: int = -1
		var last_score_clock: int = -1
		var home_points: int = 0
		var away_points: int = 0
		for event in output.events:
			if event.period > rules.regulation_periods:
				break
			if event.event_type == MatchDomainEvent.PERIOD_ENDED \
					and event.period == rules.regulation_periods:
				boundary = event.sequence
				break
			var scored: int = 0
			if event.event_type == MatchDomainEvent.FIELD_GOAL_MADE:
				scored = event.points
			elif event.event_type == MatchDomainEvent.FREE_THROW_MADE:
				scored = 1
			if scored <= 0:
				continue
			last_score_sequence = event.sequence
			last_score_clock = event.clock_ms
			if event.team_id == input.home.team_id:
				home_points += scored
			else:
				away_points += scored
		assert_int(boundary).override_failure_message(
			"seed %d: regulation never ended in its own ledger" % [index + 1]
		).is_greater(0)
		assert_int(last_score_sequence).override_failure_message(
			"seed %d: the last regulation score must precede the end of regulation"
			% [index + 1]).is_less(boundary)
		var replayed: int = _regulation_margin(input, output)
		assert_int(home_points - away_points).override_failure_message(
			"seed %d: the reduced regulation margin must equal the sum of scoring events"
			% [index + 1]).is_equal(replayed)
		assert_int(home_points).override_failure_message(
			"a team cannot score negative points").is_greater_equal(0)
		assert_int(away_points).is_greater_equal(0)
		if last_score_clock >= 0 and last_score_clock <= 5000:
			late_scores += 1
	assert_int(games).is_equal(TIE_SWEEP_SEEDS)
	assert_int(late_scores).override_failure_message(
		"no game scored inside the last five seconds of regulation; the ordering "
		+ "this test is about was never exercised").is_greater(0)


# --- 7. play, sim and skip agree ----------------------------------------------

## §23 and §27.5: one session type, one `advance_possession`, and three callers
## that differ only in when they stop calling it. The regulation-tie decision is
## therefore the same decision in all three, and this proves it on the ledger
## rather than on the final score alone.
func test_play_sim_and_skip_agree_about_regulation_ties() -> void:
	var ties: int = 0
	var decided: int = 0
	var checked: int = 0
	for index in range(PARITY_SEED_CAP):
		if checked >= PARITY_MINIMUM_SEEDS and ties > 0 and decided > 0:
			break
		checked += 1
		var seed_value: int = index + 1
		var play_input: MatchInput = MatchFixtureFactory.even_match()
		var play := MatchSession.new(play_input, SeededRandomSource.new(seed_value))
		while not play.is_complete():
			play.advance_possession()
		var stepped: MatchSimulationOutput = play.build_output()

		var sim_input: MatchInput = MatchFixtureFactory.even_match()
		var sim: MatchSimulationOutput = MatchSession.new(
			sim_input, SeededRandomSource.new(seed_value)).run_to_completion()

		var skip_input: MatchInput = MatchFixtureFactory.even_match()
		var skipped: MatchSimulationOutput = MatchSession.new(
			skip_input, SeededRandomSource.new(seed_value)).skip_to_final_result()

		assert_str(sim.signature()).override_failure_message(
			"seed %d: Play and Sim produced different ledgers" % seed_value
		).is_equal(stepped.signature())
		assert_str(skipped.signature()).override_failure_message(
			"seed %d: Skip and Sim produced different ledgers" % seed_value
		).is_equal(sim.signature())

		var play_margin: int = _regulation_margin(play_input, stepped)
		var sim_margin: int = _regulation_margin(sim_input, sim)
		var skip_margin: int = _regulation_margin(skip_input, skipped)
		assert_int(sim_margin).override_failure_message(
			"seed %d: Play and Sim disagree about the regulation margin" % seed_value
		).is_equal(play_margin)
		assert_int(skip_margin).override_failure_message(
			"seed %d: Skip and Sim disagree about the regulation margin" % seed_value
		).is_equal(sim_margin)
		assert_int(sim.final_result.overtime_periods).is_equal(
			stepped.final_result.overtime_periods)
		assert_int(skipped.final_result.overtime_periods).is_equal(
			sim.final_result.overtime_periods)
		if sim_margin == 0:
			ties += 1
		else:
			decided += 1
	assert_int(checked).override_failure_message(
		"parity must be checked on at least %d seeds" % PARITY_MINIMUM_SEEDS
	).is_greater_equal(PARITY_MINIMUM_SEEDS)
	assert_int(decided).override_failure_message(
		"no parity seed produced a decided game").is_greater(0)
	assert_int(ties).override_failure_message(
		"no regulation tie in %d parity seeds; the agreement is untested where it "
		% PARITY_SEED_CAP + "matters, and the fixture is no longer producing ties"
	).is_greater(0)


# --- helpers ------------------------------------------------------------------

## The five shipping competitions, taken through the calibration catalog so the
## rules and the population a competition is measured with stay together.
func _launch_competitions() -> Array[int]:
	return CalibrationTargets.all_competitions()


func _rules_for(competition: int) -> CompetitionRuleProfile:
	return CompetitionCatalog.rules_for(competition)


## A state at the end of regulation, at a chosen home-minus-away margin. The
## base score is deliberately high so a margin is a margin rather than an
## artifact of one team having scored nothing.
func _expired_regulation(input: MatchInput, margin: int) -> MatchSnapshot:
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot := MatchSnapshot.new(input)
	snapshot.period = rules.regulation_periods
	snapshot.clock_ms = 0
	snapshot.shot_clock_ms = 0
	snapshot.home.score = 70 + margin
	snapshot.away.score = 70
	return snapshot


func _profile_input(competition: int) -> MatchInput:
	return CompetitionCatalog.match_for(competition, 0, 0.5)


## Two even teams over a short regulation with a twenty-second overtime, so a
## second overtime is reached inside a bounded sweep rather than by luck.
func _multi_overtime_match() -> MatchInput:
	var even: MatchInput = MatchFixtureFactory.even_match()
	return MatchFixtureFactory.match_between(
		even.home, even.away,
		CompetitionRuleProfile.new(&"fixture_multi_overtime", &"v1", 2, 150, 20, 24, 6))


## The home-minus-away margin at the moment regulation ended, reduced from the
## ledger rather than read from the result.
func _regulation_margin(input: MatchInput, output: MatchSimulationOutput) -> int:
	var rules: CompetitionRuleProfile = input.rule_profile
	var state := MatchSnapshot.new(input)
	var reducer := MatchStateReducer.new(input)
	for event in output.events:
		if event.event_type == MatchDomainEvent.PERIOD_ENDED \
				and event.period == rules.regulation_periods:
			return state.margin_for(input.home.team_id)
		reducer.apply_event(state, event)
	return state.margin_for(input.home.team_id)
