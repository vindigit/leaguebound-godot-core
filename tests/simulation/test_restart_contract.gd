class_name TestRestartContract
extends GdUnitTestSuite

## The restart contract `simulation-v14` establishes (`PROJECT_STATUS.md` §5.31).
##
## §5.30 shipped a boolean, `MatchSession._clock_stopped`, derived as
## `end_reason != MADE_SCORE`. `PossessionEndReason.MADE_SCORE` is returned for a
## made field goal *and* for a made final free throw, so that derivation could
## not tell the two apart and §5.30 recorded the conflation as a known
## conservatism. This suite is the evidence that the conservatism is gone and
## that nothing was traded for it.
##
## Three separable facts, kept separable here:
##
## 1. **`RestartCause`** — why the next possession begins. Named by
##    `PossessionEngine._terminate` at every terminal path, carried on
##    `PossessionRecord`, and overridden by `MatchSession` only for the two
##    dead-ball events that happen after a possession ends: a charged timeout and
##    a period transition.
## 2. **`RestartClockMode`** — what the rules make of that cause.
##    `RestartClockPolicy` is the only thing that decides it.
## 3. **The made-basket rule** — the one part a competition owns, held on
##    `CompetitionRuleProfile` and read through the policy.
##
## Every fixture is written so that undoing the thing it stands for fails it, and
## the six mutations the §5.31 brief names are called out on the tests that catch
## them. A suite that passes both before and after a correction is evidence of
## nothing.

## A clock far outside every profile's made-basket window, so a made field goal
## there is unambiguously a running-clock restart.
const OPEN_PLAY_CLOCK_MS: int = 250000
const MATCH_SEEDS: int = 6
const AUDIT_BASE_SEED: int = 990001


# --- 1. a stopped-clock throw-in consumes no game clock ------------------------

## **Mutation: forcing every restart to `CLOCK_ALREADY_RUNNING` fails here.**
##
## Each of these causes is a whistle. The throw-in that follows emits at the
## possession's own starting clock and costs nothing, so any charged draw moves
## the timestamp and fails the equality.
func test_every_whistle_restart_emits_its_throw_in_at_the_starting_clock() -> void:
	for cause: int in [
		RestartCause.Value.PERIOD_START,
		RestartCause.Value.MADE_FREE_THROW,
		RestartCause.Value.FOUL,
		RestartCause.Value.TIMEOUT,
		RestartCause.Value.VIOLATION,
		RestartCause.Value.OUT_OF_BOUNDS,
	]:
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(input, 1, OPEN_PLAY_CLOCK_MS)
		var possession: PossessionResult = _possession(input, snapshot, 4101, cause)
		var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
		assert_object(inbound).override_failure_message(
			"a %s restart must emit INBOUND" % RestartCause.id_of(cause)).is_not_null()
		assert_int(inbound.clock_ms).override_failure_message(
			"a %s restart is a stopped clock and must consume nothing"
			% RestartCause.id_of(cause)
		).is_equal(OPEN_PLAY_CLOCK_MS)


## And the cause travels onto the event, so the ledger records why the throw-in
## was free instead of leaving a reader to infer it from timestamps.
func test_the_inbound_event_records_the_restart_cause_it_was_opened_under() -> void:
	for cause: int in RestartCause.all():
		if cause == RestartCause.Value.LIVE_BALL:
			continue
		var input: MatchInput = _fixture_input()
		var snapshot: MatchSnapshot = _snapshot_at(input, 1, OPEN_PLAY_CLOCK_MS)
		var possession: PossessionResult = _possession(input, snapshot, 4102, cause)
		var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
		assert_str(String(inbound.detail_id)).override_failure_message(
			"INBOUND must carry the cause it opened under").is_equal(
			String(RestartCause.id_of(cause)))


# --- 2. a running-clock restart still costs what it always cost ---------------

## **Mutation: forcing every restart to `STARTS_ON_LEGAL_TOUCH` fails here.**
##
## The made field goal in open play is the one restart the clock never stopped
## for, and it must still be charged. This is the guard against "free the
## throw-in" becoming "free every throw-in", which §5.30 measured as worth about
## three and a half minutes of game time per game.
func test_a_made_field_goal_in_open_play_still_charges_its_throw_in() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, OPEN_PLAY_CLOCK_MS)
	var possession: PossessionResult = _possession(
		input, snapshot, 4103, RestartCause.Value.MADE_FIELD_GOAL)

	var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
	assert_object(inbound).is_not_null()
	assert_int(inbound.clock_ms).override_failure_message(
		"the clock never stopped, so the throw-in is live time and must cost"
	).is_less(OPEN_PLAY_CLOCK_MS)
	# And it costs the band the balance profile declares, not an arbitrary amount.
	var spent: int = OPEN_PLAY_CLOCK_MS - inbound.clock_ms
	assert_int(spent).is_greater_equal(input.balance_profile.inbound_seconds_min * 1000)
	assert_int(spent).is_less_equal(input.balance_profile.inbound_seconds_max * 1000)


## The advance and half-court set after it are untouched by any of this: a
## running-clock restart runs the ordinary opening and pays for all three stages.
func test_a_running_clock_restart_still_runs_the_ordinary_opening() -> void:
	var input: MatchInput = _fixture_input()
	var snapshot: MatchSnapshot = _snapshot_at(input, 1, OPEN_PLAY_CLOCK_MS)
	var possession: PossessionResult = _possession(
		input, snapshot, 4104, RestartCause.Value.MADE_FIELD_GOAL)
	var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
	var advance: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.ADVANCE)
	var entered: MatchDomainEvent = _first_of(
		possession.events, MatchDomainEvent.HALF_COURT_ENTERED)
	assert_object(advance).is_not_null()
	assert_object(entered).is_not_null()
	assert_int(advance.clock_ms).is_less(inbound.clock_ms)
	assert_int(entered.clock_ms).is_less(advance.clock_ms)


# --- 3. a made field goal and a made free throw restart differently -----------

## **Mutation: collapsing `MADE_FIELD_GOAL` and `MADE_FREE_THROW` fails here.**
##
## This is the §5.30 conservatism stated as a number. Same fixture, same seed,
## same clock, same everything except which kind of made basket ended the
## previous possession — and the two throw-ins land at different times.
func test_a_made_free_throw_and_a_made_field_goal_do_not_restart_alike() -> void:
	var input: MatchInput = _fixture_input()
	var field_goal: PossessionResult = _possession(
		input, _snapshot_at(input, 1, OPEN_PLAY_CLOCK_MS), 4105,
		RestartCause.Value.MADE_FIELD_GOAL)
	var free_throw: PossessionResult = _possession(
		input, _snapshot_at(input, 1, OPEN_PLAY_CLOCK_MS), 4105,
		RestartCause.Value.MADE_FREE_THROW)

	var fg_inbound: MatchDomainEvent = _first_of(field_goal.events, MatchDomainEvent.INBOUND)
	var ft_inbound: MatchDomainEvent = _first_of(free_throw.events, MatchDomainEvent.INBOUND)
	assert_int(ft_inbound.clock_ms).override_failure_message(
		"a made free throw is dead-ball time; its throw-in must not be charged"
	).is_equal(OPEN_PLAY_CLOCK_MS)
	assert_int(fg_inbound.clock_ms).override_failure_message(
		"a made field goal in open play must still be charged"
	).is_less(OPEN_PLAY_CLOCK_MS)


## The same statement at the policy, where the decision is actually made, so the
## collapse is caught even if no possession is simulated at all.
func test_the_policy_separates_the_two_made_basket_causes() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		var open_play_ms: int = rules.period_seconds * 1000
		assert_int(RestartClockPolicy.mode_for(
			RestartCause.Value.MADE_FIELD_GOAL, rules, 1, open_play_ms)
		).override_failure_message(
			"%s: a made field goal in open play leaves the clock running" % rules.profile_id
		).is_equal(RestartClockMode.Value.CLOCK_ALREADY_RUNNING)
		assert_int(RestartClockPolicy.mode_for(
			RestartCause.Value.MADE_FREE_THROW, rules, 1, open_play_ms)
		).override_failure_message(
			"%s: a made free throw stops the clock in every ruleset" % rules.profile_id
		).is_equal(RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH)


# --- 4. the owner-ruled made-field-goal timing matrix -------------------------

## The ruling itself, written out rather than read from the profiles.
##
## A test that asked each profile what it declares and then checked that it
## declares it would pass under every mutation of the profile data. So the ruling
## is stated here, independently, and the shipped profiles are checked against
## it. Milliseconds of game clock remaining, by `PeriodCategory`; zero means a
## made field goal never independently stops that competition's clock in that
## kind of period.
##
## **Mutation: ignoring competition-specific configuration fails here.** Any
## single window applied to all five competitions contradicts at least two rows.
func test_every_launch_profile_declares_the_owner_ruled_timing_matrix() -> void:
	var checked: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		var rule: MadeFieldGoalClockRule = rules.made_field_goal_clock_rule
		var expected: PackedInt32Array = _owner_ruling(rules.profile_id)
		assert_int(rule.non_final_regulation_ms).override_failure_message(
			"%s non-final-regulation window" % rules.profile_id
		).is_equal(expected[PeriodCategory.Value.NON_FINAL_REGULATION])
		assert_int(rule.final_regulation_ms).override_failure_message(
			"%s final-regulation window" % rules.profile_id
		).is_equal(expected[PeriodCategory.Value.FINAL_REGULATION])
		assert_int(rule.overtime_ms).override_failure_message(
			"%s overtime window" % rules.profile_id
		).is_equal(expected[PeriodCategory.Value.OVERTIME])
		checked += 1
	assert_int(checked).override_failure_message(
		"no competition was checked against the ruling").is_equal(5)


## The table above is indexed by `PeriodCategory.Value`, so its ordering is
## load-bearing. Pinned rather than assumed.
func test_the_period_category_ordering_the_ruling_table_relies_on() -> void:
	assert_int(PeriodCategory.Value.NON_FINAL_REGULATION).is_equal(0)
	assert_int(PeriodCategory.Value.FINAL_REGULATION).is_equal(1)
	assert_int(PeriodCategory.Value.OVERTIME).is_equal(2)
	assert_int(PeriodCategory.COUNT).is_equal(3)


## Every nonzero window in the shipped matrix, proved on all three sides of its
## boundary in a period of the category it governs.
##
## **Mutation: making the inclusive boundary exclusive fails here** — the
## "exactly at the window" row is the one that changes.
## **Mutation: forcing every made-field-goal restart to `CLOCK_ALREADY_RUNNING`
## fails here** on the two inside rows.
func test_every_nonzero_window_stops_the_clock_exactly_at_its_inclusive_boundary() -> void:
	var proved: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		for category: int in PeriodCategory.all():
			var window: int = rules.made_field_goal_clock_rule.window_ms_for(category)
			if window <= 0:
				continue
			var period: int = _period_of_category(rules, category)
			_assert_made_basket_mode(
				rules, period, window + 1, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
				"one millisecond above the %s window" % PeriodCategory.id_of(category))
			_assert_made_basket_mode(
				rules, period, window, RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH,
				"exactly at the %s window" % PeriodCategory.id_of(category))
			_assert_made_basket_mode(
				rules, period, window - 1, RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH,
				"one millisecond below the %s window" % PeriodCategory.id_of(category))
			proved += 1
	# college 2, development 3, overseas 2, top domestic 3; high school declares
	# none. A matrix that lost a window would fail this count before it reached a
	# boundary.
	assert_int(proved).override_failure_message(
		"the shipped matrix no longer contains ten nonzero windows").is_equal(10)


## And every zero window leaves the clock running however little time is left,
## including at the extremes.
##
## **Mutation: forcing every made-field-goal restart to `STARTS_ON_LEGAL_TOUCH`
## fails here.**
func test_every_zero_window_leaves_the_clock_running_at_every_remaining_time() -> void:
	var proved: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		for category: int in PeriodCategory.all():
			if rules.made_field_goal_clock_rule.window_ms_for(category) > 0:
				continue
			var period: int = _period_of_category(rules, category)
			for remaining: int in [0, 1, 4999, 60000, 120000, 120001]:
				_assert_made_basket_mode(
					rules, period, remaining, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
					"a zero %s window" % PeriodCategory.id_of(category))
			proved += 1
	assert_int(proved).override_failure_message(
		"the shipped matrix no longer contains five zero windows").is_equal(5)


## The final regulation period and the ones before it are different periods with
## different rules, in the three competitions whose windows differ.
##
## **Mutation: treating non-final and final regulation periods identically fails
## here.** At 120,000ms remaining, development and top domestic stop in the final
## period and run in an earlier one; college and overseas stop in the final
## period and run in an earlier one at their own window too.
func test_a_non_final_regulation_period_does_not_borrow_the_final_period_window() -> void:
	var proved: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		var rule: MadeFieldGoalClockRule = rules.made_field_goal_clock_rule
		if rule.final_regulation_ms <= rule.non_final_regulation_ms:
			continue
		# A clock reading that is inside the final-period window but outside the
		# ordinary-period one. It must separate the two categories.
		var between: int = rule.final_regulation_ms
		_assert_made_basket_mode(
			rules, rules.regulation_periods, between,
			RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH,
			"the final regulation period at its own window")
		_assert_made_basket_mode(
			rules, 1, between, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
			"an ordinary regulation period at the final period's window")
		proved += 1
	assert_int(proved).override_failure_message(
		"no competition distinguishes its final regulation period any more"
	).is_equal(4)


## Overtime reads the overtime window, not a regulation one.
##
## **Mutation: giving overtime the wrong window fails here.** Every competition
## with a nonzero overtime window has a *smaller* non-final-regulation window
## (60,000ms at development and top domestic, zero at college and overseas), so
## an overtime that consulted the ordinary-regulation figure would leave the
## clock running at the overtime boundary.
func test_overtime_reads_the_overtime_window_and_not_a_regulation_one() -> void:
	var proved: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		var rule: MadeFieldGoalClockRule = rules.made_field_goal_clock_rule
		if rule.overtime_ms <= 0:
			continue
		assert_int(rule.overtime_ms).override_failure_message(
			"%s: this fixture only discriminates while overtime's window exceeds "
			% rules.profile_id + "the ordinary regulation one"
		).is_greater(rule.non_final_regulation_ms)
		for overtime_period: int in [
			rules.regulation_periods + 1,
			rules.regulation_periods + 2,
			rules.regulation_periods + 5,
		]:
			_assert_made_basket_mode(
				rules, overtime_period, rule.overtime_ms,
				RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH,
				"overtime at its own window")
			_assert_made_basket_mode(
				rules, overtime_period, rule.overtime_ms + 1,
				RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
				"overtime one millisecond above its window")
		proved += 1
	assert_int(proved).override_failure_message(
		"no competition declares an overtime window").is_equal(4)


## The representation routes three genuinely different windows to three
## different period categories.
##
## Every shipped profile gives overtime and the final regulation period the same
## length, so a policy that confused those two would be invisible in production
## data. This constructed profile makes all three distinct, which is the only
## way to prove each category reads its own field rather than a neighbour's.
func test_a_constructed_profile_routes_each_period_category_to_its_own_window() -> void:
	var rules: CompetitionRuleProfile = _distinct_window_profile()
	var expected: Dictionary = {
		PeriodCategory.Value.NON_FINAL_REGULATION: 30000,
		PeriodCategory.Value.FINAL_REGULATION: 90000,
		PeriodCategory.Value.OVERTIME: 150000,
	}
	for category: int in PeriodCategory.all():
		var window: int = rules.made_field_goal_clock_rule.window_ms_for(category)
		assert_int(window).override_failure_message(
			"the fixture no longer declares three distinct windows"
		).is_equal(expected[category] as int)
		var period: int = _period_of_category(rules, category)
		_assert_made_basket_mode(
			rules, period, window + 1, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
			"above the %s window" % PeriodCategory.id_of(category))
		_assert_made_basket_mode(
			rules, period, window, RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH,
			"exactly at the %s window" % PeriodCategory.id_of(category))
		_assert_made_basket_mode(
			rules, period, window - 1, RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH,
			"below the %s window" % PeriodCategory.id_of(category))
		# And no other category's window governs this one.
		for other: int in PeriodCategory.all():
			if other == category:
				continue
			var foreign: int = rules.made_field_goal_clock_rule.window_ms_for(other)
			if foreign <= window:
				continue
			_assert_made_basket_mode(
				rules, period, foreign, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
				"a %s period must not borrow the %s window" % [
					PeriodCategory.id_of(category), PeriodCategory.id_of(other)])


## Middle school and high school: a made field goal never stops the clock, late
## in regulation or in overtime.
##
## §1.1 gives the middle-school prologue no `CompetitionRuleProfile` of its own,
## and inventing one would mean inventing a period length, a shot clock and a
## §14.1 band that no source states. Its ruling is identical to high school's —
## no made-field-goal stoppage in any period — and is exactly the value
## `MadeFieldGoalClockRule.none()` carries, so it is proved on that value and on
## the high-school profile that ships it.
func test_the_middle_school_and_high_school_ruling_is_no_made_field_goal_stoppage() -> void:
	var high_school: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.HIGH_SCHOOL)
	assert_bool(high_school.made_field_goal_clock_rule.stops_clock_anywhere())		.override_failure_message(
			"high school declares a made-field-goal window; the ruling says it has none")		.is_false()
	assert_str(str(high_school.made_field_goal_clock_rule)).override_failure_message(
		"the middle-school and high-school ruling are the same value"
	).is_equal(str(MadeFieldGoalClockRule.none()))

	# Late in the final regulation period, and deep into overtime, at every
	# clock reading either competition could present.
	for period: int in [
		1,
		high_school.regulation_periods - 1,
		high_school.regulation_periods,
		high_school.regulation_periods + 1,
		high_school.regulation_periods + 3,
	]:
		for remaining: int in [0, 1, 1000, 5000, 60000, 120000, 240000]:
			_assert_made_basket_mode(
				high_school, period, remaining,
				RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
				"a competition with no made-field-goal window")


## And where a made field goal does not stop the clock, every other dead-ball
## cause still does. The ruling is about made field goals and nothing else.
func test_other_dead_ball_causes_still_stop_the_clock_where_a_made_field_goal_does_not() -> void:
	var high_school: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.HIGH_SCHOOL)
	for cause: int in [
		RestartCause.Value.PERIOD_START,
		RestartCause.Value.MADE_FREE_THROW,
		RestartCause.Value.FOUL,
		RestartCause.Value.TIMEOUT,
		RestartCause.Value.VIOLATION,
		RestartCause.Value.OUT_OF_BOUNDS,
	]:
		for period: int in [1, high_school.regulation_periods, high_school.regulation_periods + 1]:
			assert_int(RestartClockPolicy.mode_for(cause, high_school, period, 1000))				.override_failure_message(
					"a %s restart is a stopped clock in every competition"
					% RestartCause.id_of(cause))				.is_equal(RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH)


## A made final free throw stays a dead-ball restart in every competition, at
## every clock reading, whatever that competition's made-field-goal matrix says.
##
## **Mutation: collapsing `MADE_FIELD_GOAL` and `MADE_FREE_THROW` fails here** —
## the two causes are asked the same question at the same clock and are required
## to answer differently wherever the field-goal window is closed.
func test_a_made_free_throw_stays_distinct_from_a_made_field_goal_everywhere() -> void:
	var separated: int = 0
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		for category: int in PeriodCategory.all():
			var period: int = _period_of_category(rules, category)
			var window: int = rules.made_field_goal_clock_rule.window_ms_for(category)
			# Outside the window — or anywhere at all, where there is none — the
			# two causes must disagree.
			var outside: int = window + 1
			assert_int(RestartClockPolicy.mode_for(
				RestartCause.Value.MADE_FIELD_GOAL, rules, period, outside)
			).override_failure_message(
				"%s %s: a made field goal outside the window runs"
				% [rules.profile_id, PeriodCategory.id_of(category)]
			).is_equal(RestartClockMode.Value.CLOCK_ALREADY_RUNNING)
			assert_int(RestartClockPolicy.mode_for(
				RestartCause.Value.MADE_FREE_THROW, rules, period, outside)
			).override_failure_message(
				"%s %s: a made free throw stops the clock in every ruleset"
				% [rules.profile_id, PeriodCategory.id_of(category)]
			).is_equal(RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH)
			separated += 1
	assert_int(separated).override_failure_message(
		"no competition/category pair separated the two made-basket causes"
	).is_equal(15)


## Inside a window the throw-in costs nothing and the clock then runs from the
## legal touch — proved on a simulated possession rather than on the policy.
##
## Two facts, and they are different: `INBOUND` emitting at the possession's own
## starting clock is "no throw-in time is charged before the legal touch"; the
## next clock-consuming event arriving strictly later is "the clock is running
## once the ball is touched". A restart that stopped the clock and then left it
## stopped would pass the first and fail the second.
func test_a_stopped_made_field_goal_restart_charges_nothing_then_runs_on_the_touch() -> void:
	var input: MatchInput = _competition_input(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, AUDIT_BASE_SEED)
	var rules: CompetitionRuleProfile = input.rule_profile
	var window: int = rules.made_field_goal_clock_rule.final_regulation_ms
	assert_int(window).override_failure_message(
		"top domestic must declare a final-regulation window for this fixture"
	).is_greater(0)
	var snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, window)
	var possession: PossessionResult = _possession(
		input, snapshot, 4107, RestartCause.Value.MADE_FIELD_GOAL)

	var inbound: MatchDomainEvent = _first_of(possession.events, MatchDomainEvent.INBOUND)
	assert_object(inbound).override_failure_message(
		"a stopped made-field-goal restart still administers a throw-in").is_not_null()
	assert_int(inbound.clock_ms).override_failure_message(
		"no game clock may be charged before the legal touch").is_equal(window)

	var after_touch: int = -1
	for event: MatchDomainEvent in possession.events:
		if event.clock_ms < window:
			after_touch = event.clock_ms
			break
	assert_int(after_touch).override_failure_message(
		"the clock never ran after the legal touch, so it did not restart"
	).is_between(0, window - 1)


## The boundary reaches a whole simulated possession, not just the policy: at the
## same seed and the same cause, one millisecond either side of the window
## produces a charged and an uncharged throw-in.
func test_the_window_boundary_changes_a_simulated_possession() -> void:
	var input: MatchInput = _competition_input(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, AUDIT_BASE_SEED)
	var rules: CompetitionRuleProfile = input.rule_profile
	var window: int = rules.made_field_goal_clock_rule.final_regulation_ms
	var period: int = rules.regulation_periods
	var outside: PossessionResult = _possession(
		input, _snapshot_at(input, period, window + 1000), 4106,
		RestartCause.Value.MADE_FIELD_GOAL)
	var inside: PossessionResult = _possession(
		input, _snapshot_at(input, period, window), 4106,
		RestartCause.Value.MADE_FIELD_GOAL)

	assert_int(_first_of(outside.events, MatchDomainEvent.INBOUND).clock_ms)\
		.override_failure_message("outside the window the throw-in is charged")\
		.is_less(window + 1000)
	assert_int(_first_of(inside.events, MatchDomainEvent.INBOUND).clock_ms)\
		.override_failure_message("inside the window it is not")\
		.is_equal(window)


## A profile with no window at all never stops the clock for a made basket, at
## any clock. Zero is the disabling value and it has to actually disable.
func test_a_profile_with_no_window_never_stops_the_clock_for_a_made_basket() -> void:
	var rules := CompetitionRuleProfile.new(
		&"no_window_fixture", &"v1", 4, 600, 300, 24, 6, 14, 8,
		5, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false,
		&"standard_arc", &"standard_restricted", &"standard_pace",
		&"standard_officiating", &"standard_roster", 1.0, 6, false,
		MadeFieldGoalClockRule.none())
	for remaining: int in [600000, 5000, 1000, 1, 0]:
		_assert_made_basket_mode(
			rules, 4, remaining, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
			"a profile with no declared window")
	# And a made free throw is still stopped there, because that is basketball
	# rather than a competition rule.
	assert_int(RestartClockPolicy.mode_for(
		RestartCause.Value.MADE_FREE_THROW, rules, 4, 600000)
	).is_equal(RestartClockMode.Value.STARTS_ON_LEGAL_TOUCH)


## An omitted rule means no stoppage, not an inherited one. Every fixture profile
## in the repository takes this path.
func test_a_profile_that_declares_no_rule_at_all_gets_no_stoppage() -> void:
	var rules := CompetitionRuleProfile.new(&"defaulted_fixture", &"v1", 2, 180, 120, 24, 6)
	assert_bool(rules.made_field_goal_clock_rule.stops_clock_anywhere())\
		.override_failure_message(
			"the constructor default declares a window; a fixture that never "
			+ "mentions the rule must not silently acquire one")\
		.is_false()
	for period: int in [1, 2, 3]:
		for remaining: int in [0, 1, 5000, 120000]:
			_assert_made_basket_mode(
				rules, period, remaining, RestartClockMode.Value.CLOCK_ALREADY_RUNNING,
				"a profile that declares no made-field-goal rule")


# --- 4b. the representation refuses what it cannot mean -----------------------

## A negative window is rejected, per category.
func test_a_negative_window_is_rejected() -> void:
	await assert_error(func() -> void:
		var _rule := MadeFieldGoalClockRule.new(-1, 0, 0)
	).is_runtime_error(
		"Assertion failed: a non-final-regulation made-field-goal window is never negative")
	await assert_error(func() -> void:
		var _rule := MadeFieldGoalClockRule.new(0, -1, 0)
	).is_runtime_error(
		"Assertion failed: a final-regulation made-field-goal window is never negative")
	await assert_error(func() -> void:
		var _rule := MadeFieldGoalClockRule.new(0, 0, -1)
	).is_runtime_error(
		"Assertion failed: an overtime made-field-goal window is never negative")


## An ordinary regulation period cannot stop the clock for longer than the final
## one, and cannot stop it where the final one does not stop at all. Both are far
## more likely to be arguments passed in the wrong order than a real rule.
func test_a_contradictory_regulation_shape_is_rejected() -> void:
	await assert_error(func() -> void:
		var _rule := MadeFieldGoalClockRule.new(120000, 60000, 60000)
	).is_runtime_error(
		"Assertion failed: a non-final regulation window cannot exceed the final "
		+ "regulation window")
	await assert_error(func() -> void:
		var _rule := MadeFieldGoalClockRule.new(60000, 0, 60000)
	).is_runtime_error(
		"Assertion failed: a competition that stops the clock in an ordinary period "
		+ "must also stop it in the final one")


## A window that outlasts the period it is drawn against is rejected by the
## profile, which is the only object that knows how long a period is. Each
## category is checked against the period kind it actually governs, so an
## overtime window is judged against the overtime length and not the regulation
## one.
func test_a_window_longer_than_its_own_period_is_rejected() -> void:
	await assert_error(func() -> void:
		var _rules := CompetitionRuleProfile.new(
			&"too_long_regulation", &"v1", 4, 60, 300, 24, 6, 14, 8,
			5, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false,
			&"standard_arc", &"standard_restricted", &"standard_pace",
			&"standard_officiating", &"standard_roster", 1.0, 6, false,
			MadeFieldGoalClockRule.new(0, 120000, 0))
	).is_runtime_error(
		"Assertion failed: a final-regulation made-field-goal window cannot outlast "
		+ "a regulation period")
	await assert_error(func() -> void:
		var _rules := CompetitionRuleProfile.new(
			&"too_long_overtime", &"v1", 4, 720, 60, 24, 6, 14, 8,
			5, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false,
			&"standard_arc", &"standard_restricted", &"standard_pace",
			&"standard_officiating", &"standard_roster", 1.0, 6, false,
			MadeFieldGoalClockRule.new(0, 120000, 120000))
	).is_runtime_error(
		"Assertion failed: an overtime made-field-goal window cannot outlast an "
		+ "overtime period")


## A competition that plays a single regulation period has no non-final
## regulation period, so a window scoped to that category could never activate.
## Dead configuration is rejected rather than carried.
func test_a_single_regulation_period_competition_cannot_scope_a_non_final_window() -> void:
	await assert_error(func() -> void:
		var _rules := CompetitionRuleProfile.new(
			&"one_period", &"v1", 1, 720, 300, 24, 6, 14, 8,
			5, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false,
			&"standard_arc", &"standard_restricted", &"standard_pace",
			&"standard_officiating", &"standard_roster", 1.0, 6, false,
			MadeFieldGoalClockRule.new(60000, 120000, 120000))
	).is_runtime_error(
		"Assertion failed: a single-regulation-period competition has no non-final "
		+ "regulation period to scope a window to")


# --- 5. one writer, and the readers the contract declares ---------------------

## The cause on every throw-in is reconstructible from the ledger that precedes
## it, over whole games. That is the operational form of "one writer": if
## anything other than `MatchSession` were setting the cause, or setting it from
## anything but the committed record and the two dead-ball overrides, some
## throw-in would disagree with what the events before it say.
func test_every_throw_in_carries_the_cause_the_preceding_ledger_implies() -> void:
	var checked: int = 0
	for seed_value in range(MATCH_SEEDS):
		var input: MatchInput = _competition_input(
			CalibrationTargets.Competition.COLLEGE, AUDIT_BASE_SEED + seed_value)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(AUDIT_BASE_SEED + seed_value + 1)
		).run_to_completion()
		checked += _assert_causes_match_the_ledger(output)
	assert_int(checked).override_failure_message(
		"no throw-in was audited, so this test proved nothing").is_greater(0)


## The record and the event agree, possession by possession. The engine writes
## the cause once and it reaches both places unchanged.
func test_the_possession_record_and_the_inbound_event_never_disagree() -> void:
	var input: MatchInput = _competition_input(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, AUDIT_BASE_SEED)
	var output: MatchSimulationOutput = MatchSession.new(
		input, SeededRandomSource.new(AUDIT_BASE_SEED + 1)).run_to_completion()
	var live_records: int = 0
	for record: PossessionRecord in output.possessions:
		assert_bool(RestartCause.is_valid(record.restart_cause)).is_true()
		assert_bool(record.live_transfer).override_failure_message(
			"a record's live_transfer and its LIVE_BALL cause are the same fact"
		).is_equal(record.restart_cause == RestartCause.Value.LIVE_BALL)
		if record.live_transfer:
			live_records += 1
	assert_int(live_records).override_failure_message(
		"a whole game with no live transfer is not exercising the live branch"
	).is_greater(0)


# --- 6. the legacy inference is gone -----------------------------------------

## `PossessionEndReason.MADE_SCORE` no longer determines anything about the
## clock. Both kinds of made basket carry it, and within one real game they
## produce both clock modes — which is only possible because nothing reads the
## end reason to decide.
func test_one_end_reason_produces_both_restart_causes_in_a_single_game() -> void:
	var input: MatchInput = _competition_input(
		CalibrationTargets.Competition.COLLEGE, AUDIT_BASE_SEED)
	var output: MatchSimulationOutput = MatchSession.new(
		input, SeededRandomSource.new(AUDIT_BASE_SEED + 1)).run_to_completion()
	var field_goals: int = 0
	var free_throws: int = 0
	for record: PossessionRecord in output.possessions:
		if record.end_reason != PossessionEndReason.Value.MADE_SCORE:
			continue
		if record.restart_cause == RestartCause.Value.MADE_FIELD_GOAL:
			field_goals += 1
		elif record.restart_cause == RestartCause.Value.MADE_FREE_THROW:
			free_throws += 1
		else:
			assert_str(String(RestartCause.id_of(record.restart_cause)))\
				.override_failure_message(
					"a MADE_SCORE possession restarted as something that is not a "
					+ "made basket")\
				.is_equal("made_field_goal")
	assert_int(field_goals).override_failure_message(
		"no made field goal in the sample").is_greater(0)
	assert_int(free_throws).override_failure_message(
		"no made free throw in the sample, so the separation is untested here"
	).is_greater(0)


## And the two are charged differently in that same game: made-field-goal
## throw-ins outside the window cost time, made-free-throw throw-ins never do.
func test_made_free_throw_throw_ins_are_never_charged_and_field_goal_ones_usually_are() -> void:
	var input: MatchInput = _competition_input(
		CalibrationTargets.Competition.COLLEGE, AUDIT_BASE_SEED)
	var output: MatchSimulationOutput = MatchSession.new(
		input, SeededRandomSource.new(AUDIT_BASE_SEED + 1)).run_to_completion()
	var counts: Dictionary = _charge_counts(output)
	var free_throw_charged: int = counts.get("made_free_throw/charged", 0)
	var field_goal_charged: int = counts.get("made_field_goal/charged", 0)
	assert_int(free_throw_charged).override_failure_message(
		"a made free throw's throw-in was charged game clock"
	).is_equal(0)
	assert_int(field_goal_charged).override_failure_message(
		"no made field goal was charged, so the running-clock branch is unreached"
	).is_greater(0)
	assert_int(counts.get("made_free_throw/free", 0)).override_failure_message(
		"no made free throw reached a restart, so this test proved nothing"
	).is_greater(0)


## A charged timeout stops the clock whatever ended the possession before it.
## This is the second defect §5.31 closes: `_consider_timeout` used to clear
## `_live_start` and leave the clock flag alone, so a made basket answered by a
## run-stopping timeout still charged the throw-in. The run trigger fires only
## after a scoring run, so that case was not rare — it was every time.
func test_a_timeout_restart_is_never_charged_even_after_a_made_basket() -> void:
	var audited: int = 0
	for seed_value in range(MATCH_SEEDS):
		var input: MatchInput = _competition_input(
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO, AUDIT_BASE_SEED + seed_value)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(AUDIT_BASE_SEED + seed_value + 1)
		).run_to_completion()
		var counts: Dictionary = _charge_counts(output)
		assert_int(counts.get("timeout/charged", 0)).override_failure_message(
			"a timeout restart was charged game clock").is_equal(0)
		audited += counts.get("timeout/free", 0) as int
	assert_int(audited).override_failure_message(
		"no timeout restart occurred in the sample, so this test proved nothing"
	).is_greater(0)


# --- 7. period and overtime transitions clear the transient state -------------

## Whatever ended the period before it, the first possession of the next one is a
## `PERIOD_START` restart on a stopped clock, and carries neither a leftover live
## transfer nor a leftover timeout advance.
func test_every_period_opens_on_a_period_start_restart_at_the_full_clock() -> void:
	var overtimes: int = 0
	var periods: int = 0
	for seed_value in range(MATCH_SEEDS):
		var input: MatchInput = _competition_input(
			CalibrationTargets.Competition.COLLEGE, AUDIT_BASE_SEED + seed_value)
		var output: MatchSimulationOutput = MatchSession.new(
			input, SeededRandomSource.new(AUDIT_BASE_SEED + seed_value + 1)
		).run_to_completion()
		var opened: int = _assert_period_openings(output, input.rule_profile)
		periods += opened
		overtimes += maxi(0, output.final_result.overtime_periods)
	assert_int(periods).override_failure_message(
		"no period opening was audited").is_greater(0)


## The overtime half of the same rule, on a fixture that reaches overtime by
## construction rather than by luck.
func test_an_overtime_period_opens_on_a_stopped_clock_like_any_other() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.OVERTIME)
	var input: MatchInput = GoldenScenarios.input_for(GoldenScenarios.OVERTIME)
	assert_int(output.final_result.overtime_periods).override_failure_message(
		"the overtime fixture no longer reaches overtime").is_greater(0)
	var opened: int = _assert_period_openings(output, input.rule_profile)
	assert_int(opened).is_greater(input.rule_profile.regulation_periods)


# --- 8. determinism and mode parity under the new contract --------------------

## Identical seed and input reproduce identically, records and events alike. The
## restart cause is part of the possession signature, so a cause that drifted
## would fail here even if every timestamp matched.
func test_identical_seed_and_input_reproduce_the_same_restarts() -> void:
	var first: MatchSimulationOutput = MatchSession.new(
		_competition_input(CalibrationTargets.Competition.OVERSEAS, AUDIT_BASE_SEED),
		SeededRandomSource.new(AUDIT_BASE_SEED + 1)).run_to_completion()
	var second: MatchSimulationOutput = MatchSession.new(
		_competition_input(CalibrationTargets.Competition.OVERSEAS, AUDIT_BASE_SEED),
		SeededRandomSource.new(AUDIT_BASE_SEED + 1)).run_to_completion()
	assert_str(first.signature()).is_equal(second.signature())
	assert_int(first.possessions.size()).is_equal(second.possessions.size())
	for index in range(first.possessions.size()):
		assert_int(first.possessions[index].restart_cause).is_equal(
			second.possessions[index].restart_cause)


## Stepping and running straight through produce the same restarts. `MatchSession`
## is the single writer of the session's restart cause and Play, Sim and Skip all
## drive the same session, so this is structural — the fixture exists so that a
## future change which made it accidental fails loudly.
func test_stepped_and_full_runs_agree_on_every_restart() -> void:
	var input: MatchInput = _competition_input(
		CalibrationTargets.Competition.HIGH_SCHOOL, AUDIT_BASE_SEED)
	var full: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(AUDIT_BASE_SEED + 1))

	var session := MatchSession.new(
		_competition_input(CalibrationTargets.Competition.HIGH_SCHOOL, AUDIT_BASE_SEED),
		SeededRandomSource.new(AUDIT_BASE_SEED + 1))
	session.open()
	while not session.is_complete():
		session.advance_possession()
	var stepped: MatchSimulationOutput = session.build_output()

	assert_str(stepped.signature()).is_equal(full.signature())
	var stepped_causes: PackedStringArray = _cause_sequence(stepped)
	var full_causes: PackedStringArray = _cause_sequence(full)
	assert_int(stepped_causes.size()).is_equal(full_causes.size())
	assert_str("|".join(stepped_causes)).is_equal("|".join(full_causes))


# --- 9. every launch profile validates its new fields ------------------------

func test_every_launch_profile_declares_a_credible_made_basket_window() -> void:
	for competition: int in CalibrationTargets.all_competitions():
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		var rule: MadeFieldGoalClockRule = rules.made_field_goal_clock_rule
		assert_object(rule).override_failure_message(
			"%s carries no made-field-goal clock rule" % rules.profile_id).is_not_null()
		for category: int in PeriodCategory.all():
			assert_int(rule.window_ms_for(category)).override_failure_message(
				"%s declares a negative %s window"
				% [rules.profile_id, PeriodCategory.id_of(category)]
			).is_greater_equal(0)
		# Each window against the period kind it actually governs. A regulation
		# window judged against the overtime length, or the reverse, would let a
		# window through that outlasts its own period.
		assert_int(rule.non_final_regulation_ms).override_failure_message(
			"%s: a non-final-regulation window outlasts a regulation period"
			% rules.profile_id
		).is_less_equal(rules.period_seconds * 1000)
		assert_int(rule.final_regulation_ms).override_failure_message(
			"%s: a final-regulation window outlasts a regulation period" % rules.profile_id
		).is_less_equal(rules.period_seconds * 1000)
		assert_int(rule.overtime_ms).override_failure_message(
			"%s: an overtime window outlasts an overtime period" % rules.profile_id
		).is_less_equal(rules.overtime_seconds * 1000)
		# A competition that stops the clock in an ordinary regulation period
		# must stop it in the final one, and never for longer.
		if rule.non_final_regulation_ms > 0:
			assert_int(rule.final_regulation_ms).override_failure_message(
				"%s stops the clock in an ordinary period but not in the final one"
				% rules.profile_id
			).is_greater_equal(rule.non_final_regulation_ms)
		# Every competition that plays more than one regulation period may scope
		# a non-final window; one that does not, may not.
		if rules.regulation_periods == 1:
			assert_int(rule.non_final_regulation_ms).override_failure_message(
				"%s has no non-final regulation period to scope a window to"
				% rules.profile_id
			).is_equal(0)
		# All five launch profiles reach the free-throw branch, so
		# `PossessionEngine`'s dead-ball free-throw termination is unreachable
		# in production and its `FOUL` restart cause is a fixture-only path.
		assert_bool(rules.final_free_throw_reboundable).override_failure_message(
			"%s no longer makes a missed final free throw live; §5.31's claim "
			% rules.profile_id + "that no launch profile reaches that branch is stale"
		).is_true()


## The cause-to-restart mapping for turnovers is total and agrees with the steal
## attribution it is derived from.
func test_every_turnover_cause_maps_to_a_restart_that_matches_its_steal_credit() -> void:
	for cause: int in TurnoverCause.all():
		var with_defender := TurnoverOutcome.new(true, cause, &"offender", &"defender")
		var without := TurnoverOutcome.new(true, cause, &"offender", &"")
		assert_bool(RestartCause.is_valid(RestartCause.for_turnover(with_defender))).is_true()
		assert_bool(RestartCause.is_valid(RestartCause.for_turnover(without))).is_true()
		assert_bool(
			RestartCause.for_turnover(with_defender) == RestartCause.Value.LIVE_BALL
		).override_failure_message(
			"a %s restart must be live exactly when it credits a steal"
			% TurnoverCause.id_of(cause)
		).is_equal(with_defender.credits_steal())
		assert_bool(
			RestartCause.for_turnover(without) == RestartCause.Value.LIVE_BALL
		).is_equal(without.credits_steal())


# --- fixtures ----------------------------------------------------------------

func _fixture_input() -> MatchInput:
	return MatchFixtureFactory.standard_match()


func _competition_input(competition: int, variation: int) -> MatchInput:
	return CompetitionCatalog.match_for(competition, variation, 0.5)


## The owner ruling for one competition, by `PeriodCategory` index, in
## milliseconds of game clock remaining.
##
## Stated independently of the profiles it checks. If this ever needs to be
## edited to make a test pass, the ruling has changed and that is an owner
## decision, not a test repair.
func _owner_ruling(profile_id: StringName) -> PackedInt32Array:
	match String(profile_id):
		"high_school":
			return PackedInt32Array([0, 0, 0])
		"college":
			return PackedInt32Array([0, 60000, 60000])
		"domestic_development":
			return PackedInt32Array([60000, 120000, 120000])
		"overseas":
			return PackedInt32Array([0, 120000, 120000])
		"top_domestic_pro":
			return PackedInt32Array([60000, 120000, 120000])
	assert_bool(false).override_failure_message(
		"no owner ruling is recorded for '%s'" % profile_id).is_true()
	return PackedInt32Array([0, 0, 0])


## A period number of the given category, in the given competition.
##
## No literal period number appears in the fixtures: college plays two halves and
## the rest play four quarters, so "the final regulation period" is period 2 in
## one and period 4 in the others, and a fixture that wrote either would silently
## test the wrong period in the other.
func _period_of_category(rules: CompetitionRuleProfile, category: int) -> int:
	match category:
		PeriodCategory.Value.NON_FINAL_REGULATION:
			assert_int(rules.regulation_periods).override_failure_message(
				"%s plays one regulation period and has no non-final one"
				% rules.profile_id).is_greater(1)
			return 1
		PeriodCategory.Value.FINAL_REGULATION:
			return rules.regulation_periods
		_:
			return rules.regulation_periods + 1


## A constructed profile whose three windows are all different, so that each
## period category can be proved to read its own field. No shipped competition
## separates overtime from the final regulation period, so nothing in production
## data can prove that routing.
func _distinct_window_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"distinct_window_fixture", &"v1", 4, 720, 300, 24, 6, 14, 8,
		5, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false,
		&"standard_arc", &"standard_restricted", &"standard_pace",
		&"standard_officiating", &"standard_roster", 1.0, 6, false,
		MadeFieldGoalClockRule.new(30000, 90000, 150000))


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
	restart_cause: int,
) -> PossessionResult:
	return PossessionEngine.new(input).simulate(
		snapshot, input, SeededRandomSource.new(seed_value),
		restart_cause == RestartCause.Value.LIVE_BALL, false, restart_cause)


func _assert_made_basket_mode(
	rules: CompetitionRuleProfile,
	period: int,
	remaining_ms: int,
	expected: int,
	label: String,
) -> void:
	assert_int(RestartClockPolicy.mode_for(
		RestartCause.Value.MADE_FIELD_GOAL, rules, period, remaining_ms)
	).override_failure_message(
		"%s period %d at %dms (%s): expected %s" % [
			rules.profile_id, period, remaining_ms, label,
			RestartClockMode.id_of(expected)]
	).is_equal(expected)


# --- ledger helpers -----------------------------------------------------------

## Replays a committed ledger and re-derives, from the events alone, the cause
## each throw-in should carry: a period start, a charged timeout since the last
## possession ended, or the terminal shape of that possession.
func _assert_causes_match_the_ledger(output: MatchSimulationOutput) -> int:
	var expected: StringName = RestartCause.id_of(RestartCause.Value.PERIOD_START)
	var last_made_was_free_throw: bool = false
	var last_turnover_cause: StringName = &""
	var last_turnover_stolen: bool = false
	var checked: int = 0
	for event: MatchDomainEvent in output.events:
		match event.event_type:
			MatchDomainEvent.PERIOD_STARTED:
				expected = RestartCause.id_of(RestartCause.Value.PERIOD_START)
			MatchDomainEvent.TIMEOUT:
				expected = RestartCause.id_of(RestartCause.Value.TIMEOUT)
			MatchDomainEvent.FREE_THROW_MADE:
				last_made_was_free_throw = true
			MatchDomainEvent.FIELD_GOAL_MADE:
				last_made_was_free_throw = false
			MatchDomainEvent.TURNOVER:
				last_turnover_cause = event.detail_id
				last_turnover_stolen = false
			MatchDomainEvent.STEAL:
				last_turnover_stolen = true
			MatchDomainEvent.INBOUND:
				assert_str(String(event.detail_id)).override_failure_message(
					"the throw-in at sequence %d carries '%s'; the ledger before it implies '%s'"
					% [event.sequence, event.detail_id, expected]
				).is_equal(String(expected))
				checked += 1
			MatchDomainEvent.POSSESSION_ENDED:
				expected = _cause_after_possession_end(
					event, last_made_was_free_throw, last_turnover_cause, last_turnover_stolen)
				last_made_was_free_throw = false
				last_turnover_cause = &""
				last_turnover_stolen = false
	return checked


## What a possession's terminal event implies about the next restart, derived
## only from the ledger and never from the engine's own answer.
##
## `made_score` is the ambiguous reason this whole contract exists for, and it is
## resolved here the way basketball resolves it: by which kind of basket was the
## last one scored. A turnover is resolved from the `TURNOVER` event's own §11.2
## cause and from whether a `STEAL` was credited against it.
func _cause_after_possession_end(
	event: MatchDomainEvent,
	last_made_was_free_throw: bool,
	turnover_cause: StringName,
	turnover_stolen: bool,
) -> StringName:
	var reason: StringName = event.detail_id
	if reason == PossessionEndReason.id_of(PossessionEndReason.Value.MADE_SCORE):
		return RestartCause.id_of(
			RestartCause.Value.MADE_FREE_THROW if last_made_was_free_throw
			else RestartCause.Value.MADE_FIELD_GOAL)
	if reason == PossessionEndReason.id_of(PossessionEndReason.Value.PERIOD_EXPIRED):
		return RestartCause.id_of(RestartCause.Value.PERIOD_START)
	if reason == PossessionEndReason.id_of(PossessionEndReason.Value.DEFENSIVE_REBOUND):
		# Live in every launch profile; the dead-ball variant needs a profile
		# where a missed final free throw is not reboundable, which
		# `test_every_launch_profile_declares_a_credible_made_basket_window`
		# asserts none of them is.
		return RestartCause.id_of(RestartCause.Value.LIVE_BALL)
	if turnover_stolen:
		return RestartCause.id_of(RestartCause.Value.LIVE_BALL)
	if turnover_cause == TurnoverCause.id_of(TurnoverCause.Value.OFFENSIVE_FOUL):
		return RestartCause.id_of(RestartCause.Value.FOUL)
	if (
		turnover_cause == TurnoverCause.id_of(TurnoverCause.Value.SHOT_CLOCK)
		or turnover_cause == TurnoverCause.id_of(TurnoverCause.Value.TRAVEL_OR_VIOLATION)
	):
		return RestartCause.id_of(RestartCause.Value.VIOLATION)
	return RestartCause.id_of(RestartCause.Value.OUT_OF_BOUNDS)


## Every throw-in in a committed ledger, keyed by cause and by whether it cost
## game clock. The possession's own `POSSESSION_STARTED` supplies the reference
## clock, so "charged" is read from the ledger rather than assumed.
func _charge_counts(output: MatchSimulationOutput) -> Dictionary:
	var counts: Dictionary = {}
	var started_clock: int = -1
	for event: MatchDomainEvent in output.events:
		if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
			started_clock = event.clock_ms
			continue
		if event.event_type != MatchDomainEvent.INBOUND:
			continue
		var key: String = "%s/%s" % [
			event.detail_id, "charged" if event.clock_ms < started_clock else "free"]
		counts[key] = counts.get(key, 0) + 1
	return counts


## Each period opens on its full clock. A logged timeout before the first
## throw-in supersedes PERIOD_START as its cause, without consuming time.
func _assert_period_openings(
	output: MatchSimulationOutput,
	rules: CompetitionRuleProfile,
) -> int:
	var awaiting: bool = false
	var period: int = 0
	var opened: int = 0
	var expected_cause: int = RestartCause.Value.PERIOD_START
	for event: MatchDomainEvent in output.events:
		if event.event_type == MatchDomainEvent.PERIOD_STARTED:
			awaiting = true
			period = event.period
			expected_cause = RestartCause.Value.PERIOD_START
			continue
		if awaiting and event.event_type == MatchDomainEvent.TIMEOUT:
			expected_cause = RestartCause.Value.TIMEOUT
			assert_int(event.clock_ms).is_equal(rules.period_length_ms(period))
		if not awaiting or event.event_type != MatchDomainEvent.INBOUND:
			continue
		awaiting = false
		opened += 1
		assert_str(String(event.detail_id)).override_failure_message(
			"period %d opened on a %s restart" % [period, event.detail_id]
		).is_equal(String(RestartCause.id_of(expected_cause)))
		assert_int(event.clock_ms).override_failure_message(
			"period %d's opening throw-in consumed game clock" % period
		).is_equal(rules.period_length_ms(period))
	return opened


func _cause_sequence(output: MatchSimulationOutput) -> PackedStringArray:
	var causes := PackedStringArray()
	for record: PossessionRecord in output.possessions:
		causes.append(String(record.restart_cause_id()))
	return causes


func _first_of(events: Array[MatchDomainEvent], event_type: StringName) -> MatchDomainEvent:
	for event in events:
		if event.event_type == event_type:
			return event
	return null
