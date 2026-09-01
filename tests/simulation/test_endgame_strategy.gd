class_name TestEndgameStrategy
extends GdUnitTestSuite

## The end-of-regulation strategy subsystem `PROJECT_STATUS.md` §5.13 named as
## missing: two-for-one clock management, holding for the final shot,
## quick-two-vs-tying-three past `GameManagement`'s own window, a designed
## final-possession play, fouling while leading by three, an intentional
## final free-throw miss, and timeout-to-advance.
##
## Every contract `GameManagement`'s own suite holds itself to applies here
## too, proven the same way: off through ordinary basketball, on only inside
## its own narrow window, and never a channel to a shot, free-throw, or
## contact probability. Each decision is additionally proven reachable in a
## real simulated game at least once, which is the "cannot be requested and
## then silently never fire" half of the contract.

const ORDINARY_MARGINS: PackedInt32Array = [0, 2, 4, 6, 8, 10]


# --- two-for-one --------------------------------------------------------------

## Off through ordinary basketball: any period before the last, or a margin
## where the offence is comfortably ahead.
func test_two_for_one_is_off_outside_its_window() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	for period in range(1, rules.regulation_periods):
		var early: PossessionContext = _context(
			input, _snapshot_at(input, period, 40000, -4), input.home.team_id)
		assert_bool(EndgameStrategy.two_for_one_active(early, balance))\
			.override_failure_message("period %d" % period).is_false()
	var leading: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 40000, 4), input.home.team_id)
	assert_bool(EndgameStrategy.two_for_one_active(leading, balance)).is_false()


## On for the team that does not have the game comfortably won, with enough
## time left for two possessions but not so much that hurrying buys nothing.
func test_two_for_one_is_on_for_a_trailing_or_tied_team_with_a_second_possession_to_win() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var shot_clock_ms: int = rules.shot_clock_seconds * 1000
	for margin: int in [0, -3, -10]:
		var inside: PossessionContext = _context(
			input,
			_snapshot_at(input, rules.regulation_periods, shot_clock_ms + 5000, margin),
			input.home.team_id)
		assert_bool(EndgameStrategy.two_for_one_active(inside, balance))\
			.override_failure_message("margin %d" % margin).is_true()

	var too_little_time: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, shot_clock_ms, -3), input.home.team_id)
	assert_bool(EndgameStrategy.two_for_one_active(too_little_time, balance)).is_false()

	var too_much_time: PossessionContext = _context(
		input,
		_snapshot_at(
			input, rules.regulation_periods, shot_clock_ms * 2 + balance.two_for_one_window_ms + 1000, -3),
		input.home.team_id)
	assert_bool(EndgameStrategy.two_for_one_active(too_much_time, balance)).is_false()


# --- hold for the final shot ---------------------------------------------------

func test_hold_is_off_outside_its_window() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	# Not with time for a real possession left, whatever the margin.
	var too_early: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.hold_for_final_shot_window_ms + 5000, 4),
		input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(too_early, balance)).is_false()
	# Not for a trailing or exactly tied team: holding gives away the extra
	# possession two-for-one describes.
	for margin: int in [0, -1, -6]:
		var not_leading: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, 20000, margin), input.home.team_id)
		assert_bool(EndgameStrategy.hold_for_final_shot_active(not_leading, balance))\
			.override_failure_message("margin %d" % margin).is_false()


func test_hold_is_on_for_a_leading_team_with_the_game_in_hand() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 15000, 3), input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(context, balance)).is_true()


## Two-for-one and hold partition every margin exactly: never both at once, at
## any clock, in the final period.
func test_two_for_one_and_hold_are_mutually_exclusive() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in [-12, -3, 0, 3, 12]:
		for clock: int in [8000, 20000, 26000, 40000, 58000]:
			var context: PossessionContext = _context(
				input, _snapshot_at(input, rules.regulation_periods, clock, margin), input.home.team_id)
			var both: bool = (
				EndgameStrategy.two_for_one_active(context, balance)
				and EndgameStrategy.hold_for_final_shot_active(context, balance))
			assert_bool(both)\
				.override_failure_message("margin %d clock %d" % [margin, clock]).is_false()


# --- quick two vs. a timeout-backed tying three --------------------------------

func test_quick_two_needs_the_exact_deficit_a_timeout_and_the_outer_window() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var window: int = balance.endgame_possession_ms + 5000

	var eligible: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, window, -3), input.home.team_id)
	assert_bool(EndgameStrategy.quick_two_preferred(eligible, balance)).is_true()

	# Not down two or four: only the exact three-point deficit qualifies.
	for margin: int in [-2, -4]:
		var wrong_deficit: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, window, margin), input.home.team_id)
		assert_bool(EndgameStrategy.quick_two_preferred(wrong_deficit, balance))\
			.override_failure_message("margin %d" % margin).is_false()

	# Not inside GameManagement's own tie-seeking window: that rule already
	# owns the last possession by itself.
	var too_late: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.endgame_possession_ms - 2000, -3),
		input.home.team_id)
	assert_bool(EndgameStrategy.quick_two_preferred(too_late, balance)).is_false()

	# Not with no timeout in reserve: the plan needs one to survive.
	var no_timeout_snapshot: MatchSnapshot = _snapshot_at(
		input, rules.regulation_periods, window, -3)
	no_timeout_snapshot.home.timeouts_remaining = 0
	var no_timeout: PossessionContext = _context(input, no_timeout_snapshot, input.home.team_id)
	assert_bool(EndgameStrategy.quick_two_preferred(no_timeout, balance)).is_false()


# --- the designed final possession ---------------------------------------------

func test_designed_play_is_on_only_for_the_truly_final_possession() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in ORDINARY_MARGINS + PackedInt32Array([-4, -8]):
		var inside: PossessionContext = _context(
			input,
			_snapshot_at(input, rules.regulation_periods, balance.designed_play_window_ms - 2000, margin),
			input.home.team_id)
		assert_bool(EndgameStrategy.designed_play_active(inside, balance))\
			.override_failure_message("margin %d" % margin).is_true()
	var outside: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.designed_play_window_ms + 2000, -4),
		input.home.team_id)
	assert_bool(EndgameStrategy.designed_play_active(outside, balance)).is_false()


## The designated closer is a read of one existing capability, not a new
## tactical model: the higher `SHOT_SELECTION` rating wins, ties break on
## player id so the choice is a deterministic function of the roster.
func test_designated_closer_is_the_best_shot_selection_rating_on_the_floor() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var context: PossessionContext = _context(
		input,
		_snapshot_at(input, input.rule_profile.regulation_periods, 10000, 0),
		input.home.team_id)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var closer_id: StringName = EndgameStrategy.designated_closer_id(context, capability)
	assert_str(String(closer_id)).is_not_empty()
	assert_bool(context.offense_on_court().has(closer_id)).is_true()

	var best_value: float = -1.0
	for player_id in context.offense_on_court():
		var value: float = capability.capability_of(
			CapabilityKey.Value.SHOT_SELECTION,
			context.offense_profile(player_id), context.offense_runtime(player_id))
		best_value = maxf(best_value, value)
	var closer_value: float = capability.capability_of(
		CapabilityKey.Value.SHOT_SELECTION,
		context.offense_profile(closer_id), context.offense_runtime(closer_id))
	assert_float(closer_value).is_equal_approx(best_value, 0.0001)


# --- the combined action multiplier: nothing outside the window, bounded inside --

func test_action_multiplier_is_the_identity_through_ordinary_basketball() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	for period in range(1, input.rule_profile.regulation_periods):
		for margin: int in ORDINARY_MARGINS:
			var context: PossessionContext = _context(
				input, _snapshot_at(input, period, 40000, margin), input.home.team_id)
			var value: float = EndgameStrategy.action_multiplier(
				context, balance, ActionFamily.Value.RESET, -1, input.home.starters()[0], &"")
			assert_float(value)\
				.override_failure_message("period %d margin %d" % [period, margin]).is_equal(1.0)


## Two-for-one takes weight off a reset and adds it to a direct shot, at the
## tunable's declared share — the same "one bounded number" shape every other
## `GameManagement`-adjacent mechanism uses.
func test_two_for_one_reweights_reset_versus_a_direct_shot() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, rules.shot_clock_seconds * 1000 + 5000, -4),
		input.home.team_id)
	var actor: StringName = input.home.starters()[0]
	var urgency: float = balance.two_for_one_urgency
	var reset: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.RESET, -1, actor, &"")
	var pull_up: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.MIDRANGE, actor, &"")
	assert_float(reset).is_equal_approx(1.0 - urgency, 0.0001)
	assert_float(pull_up).is_equal_approx(1.0 + urgency, 0.0001)


## Holding adds weight to a reset while the shot clock still has time to spend,
## and stops the moment it does not — a hold that never shot would be a
## possession that ends on a shot-clock violation, not a strategy.
func test_hold_stops_boosting_the_reset_once_the_shot_clock_is_late() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 15000, 3)
	var actor: StringName = input.home.starters()[0]

	snapshot.shot_clock_ms = 20000
	var with_time: PossessionContext = _context(input, snapshot, input.home.team_id)
	var boosted: float = EndgameStrategy.action_multiplier(
		with_time, balance, ActionFamily.Value.RESET, -1, actor, &"")
	assert_float(boosted).is_equal_approx(1.0 + balance.hold_reset_gain, 0.0001)

	snapshot.shot_clock_ms = 4000
	var late_clock: PossessionContext = _context(input, snapshot, input.home.team_id)
	var unboosted: float = EndgameStrategy.action_multiplier(
		late_clock, balance, ActionFamily.Value.RESET, -1, actor, &"")
	assert_float(unboosted).is_equal(1.0)


## Quick-two swings weight toward a two and off a three, symmetrically, only
## when its own gate holds.
func test_quick_two_swings_two_point_weight_against_three_point_weight() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.endgame_possession_ms + 5000, -3),
		input.home.team_id)
	var actor: StringName = input.home.starters()[0]
	var preference: float = balance.quick_two_preference
	var two: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.MIDRANGE, actor, &"")
	var three: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.STANDARD_THREE, actor, &"")
	assert_float(two).is_equal_approx(1.0 + preference, 0.0001)
	assert_float(three).is_equal_approx(1.0 - preference, 0.0001)


## The designed play boosts only its own designated actor's candidates, never
## a teammate's — the whole point is that it names one player.
func test_designed_play_boosts_only_the_designated_actor() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 10000, 0), input.home.team_id)
	var closer: StringName = input.home.starters()[0]
	var teammate: StringName = input.home.starters()[1]
	var boosted: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.MIDRANGE, closer, closer)
	var unboosted: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.MIDRANGE, teammate, closer)
	assert_float(boosted).is_equal_approx(1.0 + balance.designed_play_actor_gain, 0.0001)
	assert_float(unboosted).is_equal(1.0)


# --- the intentional final free-throw miss --------------------------------------

func test_intentional_miss_applies_only_to_the_final_attempt_of_a_close_lead() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile

	for margin: int in [1, 2, 3]:
		var eligible: PossessionContext = _context(
			input,
			_snapshot_at(input, rules.regulation_periods, 2000, margin),
			input.home.team_id)
		var expected: bool = margin == 2 or margin == 3
		assert_bool(
			EndgameStrategy.should_intentionally_miss_final_free_throw(eligible, balance, 1, 2)
		).override_failure_message("margin %d" % margin).is_equal(expected)

	var context: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 2000, 2), input.home.team_id)
	# Not the first attempt of a trip — only the last one is ever missed on
	# purpose.
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(context, balance, 0, 2)
	).is_false()
	# Not outside the narrow clock window: too much time still left to matter,
	# or none left at all to matter for.
	var too_early: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.intentional_miss_clock_ms + 3000, 2),
		input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(too_early, balance, 1, 2)
	).is_false()
	# Not before the last period.
	var early_period: PossessionContext = _context(
		input, _snapshot_at(input, 1, 2000, 2), input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(early_period, balance, 1, 2)
	).is_false()


## The decision never reaches the make-probability table: `FreeThrowResolver`
## returns the identical probability whether or not the intentional-miss
## condition holds, because nothing about `EndgameStrategy`'s decision and
## `FreeThrowResolver.probability` share any state at all. This is the direct
## statement that a "miss" here is a choice not to attempt the shot, never an
## engineered failure of the shot itself.
func test_intentional_miss_never_touches_free_throw_probability() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := FreeThrowResolver.new(capability, input.balance_profile)
	var shooter: StringName = input.home.starters()[0]

	var eligible_snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 2000, 2)
	var ineligible_snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 2000, 20)
	var eligible: float = resolver.probability(_context(input, eligible_snapshot, input.home.team_id), shooter)
	var ineligible: float = resolver.probability(
		_context(input, ineligible_snapshot, input.home.team_id), shooter)
	# The margins differ by enough to move the intentional-miss decision but not
	# enough to move §20.1's own absolute-margin pressure term, which is already
	# saturated at both points — so any difference here would be new, not §20.1's.
	assert_float(eligible).is_equal(ineligible)


# --- timeout to advance ---------------------------------------------------------

func test_timeout_advance_needs_the_rule_flag_a_trailing_margin_a_timeout_and_the_window() -> void:
	var balance := SimulationBalanceProfile.new()
	var permitted: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.COLLEGE)
	var not_permitted: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.DEVELOPMENT)
	assert_bool(permitted.timeout_advance_permitted).is_true()
	assert_bool(not_permitted.timeout_advance_permitted).is_false()

	var snapshot := MatchSnapshot.new(
		MatchFixtureFactory.match_between(
			MatchFixtureFactory.uniform_team(&"home", 70),
			MatchFixtureFactory.uniform_team(&"away", 70),
			permitted, balance))
	snapshot.period = permitted.regulation_periods
	snapshot.clock_ms = balance.timeout_advance_window_ms - 5000
	snapshot.home.score = 60
	snapshot.away.score = 64
	assert_bool(
		EndgameStrategy.timeout_advance_eligible(snapshot, permitted, balance, &"home")
	).is_true()

	# The flag is what a competition's own rule profile controls; the same
	# state under a profile that does not grant it is never eligible.
	assert_bool(
		EndgameStrategy.timeout_advance_eligible(snapshot, not_permitted, balance, &"home")
	).is_false()

	# Not while leading: the rule exists to help a team get back in position,
	# not to spot a comfortable one an extra timeout's worth of rest.
	snapshot.home.score = 70
	snapshot.away.score = 60
	assert_bool(
		EndgameStrategy.timeout_advance_eligible(snapshot, permitted, balance, &"home")
	).is_false()
	snapshot.home.score = 60
	snapshot.away.score = 64

	# Not with no timeout left to call.
	snapshot.home.timeouts_remaining = 0
	assert_bool(
		EndgameStrategy.timeout_advance_eligible(snapshot, permitted, balance, &"home")
	).is_false()
	snapshot.home.timeouts_remaining = permitted.timeouts_per_team

	# Not outside the final window.
	snapshot.clock_ms = balance.timeout_advance_window_ms + 5000
	assert_bool(
		EndgameStrategy.timeout_advance_eligible(snapshot, permitted, balance, &"home")
	).is_false()


## A timeout-advance possession still emits exactly one `ADVANCE` event — the
## possession's shape is unchanged — but the backcourt walk it would otherwise
## draw clock for is skipped, and the event carries the cause.
func test_a_timeout_advance_possession_skips_the_backcourt_walk() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var engine := PossessionEngine.new(input)
	var snapshot: MatchSnapshot = MatchFixtureFactory.standard_snapshot()
	snapshot.possession_team_id = input.home.team_id

	var advanced: PossessionResult = engine.simulate(
		snapshot, input, SeededRandomSource.new(5150), false, true)
	var direct: PossessionResult = engine.simulate(
		snapshot, input, SeededRandomSource.new(5150), false, false)

	var advance_events: Array[MatchDomainEvent] = advanced.events.filter(
		func(event: MatchDomainEvent) -> bool: return event.event_type == MatchDomainEvent.ADVANCE)
	assert_int(advance_events.size()).is_equal(1)
	assert_str(String(advance_events[0].detail_id)).is_equal("timeout_advanced")
	# Compare the clock at HALF_COURT_ENTERED specifically — the end of the
	# opening sequence the advance draw belongs to — rather than the
	# possession's last event, whose downstream random draws are not what this
	# test is about and would make the comparison noisy.
	var advanced_entry_clock: int = _half_court_entered_clock(advanced.events)
	var direct_entry_clock: int = _half_court_entered_clock(direct.events)
	assert_int(direct_entry_clock).is_less_equal(advanced_entry_clock)


# --- the leading-by-three foul ---------------------------------------------------

## Eligible only up exactly three, in the final period, inside its own (short)
## clock window — deliberately narrower than the trailing team's desperation
## foul, because this is the last meaningful possession rather than the last
## few of a close game.
func test_leading_by_three_foul_fires_only_when_eligible() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := FoulResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)

	# The share is pinned to certainty so eligibility is what the test proves,
	# not the coin flip on top of it.
	input.balance_profile.leading_foul_share = 1.0
	var eligible: PossessionContext = _foul_context(
		input, rules.regulation_periods, input.balance_profile.leading_foul_clock_ms - 1000, -3)
	var call: FoulCall = resolver.resolve_leading_by_three_foul(eligible, SeededRandomSource.new(1))
	assert_bool(call.occurred).is_true()
	assert_str(String(FoulType.id_of(call.foul_type))).is_equal("leading_protect")
	assert_str(String(call.drawn_by_id)).is_equal(String(eligible.ball_handler_id))


func test_leading_by_three_foul_refuses_when_ineligible() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := FoulResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)
	input.balance_profile.leading_foul_share = 1.0
	var window: int = input.balance_profile.leading_foul_clock_ms

	# Not down two or four: only exactly three qualifies.
	for margin: int in [-2, -4]:
		var wrong_deficit: PossessionContext = _foul_context(
			input, rules.regulation_periods, window - 1000, margin)
		var call: FoulCall = resolver.resolve_leading_by_three_foul(
			wrong_deficit, SeededRandomSource.new(1))
		assert_bool(call.occurred).override_failure_message("margin %d" % margin).is_false()

	# Not outside the window.
	var too_early: PossessionContext = _foul_context(
		input, rules.regulation_periods, window + 5000, -3)
	assert_bool(
		resolver.resolve_leading_by_three_foul(too_early, SeededRandomSource.new(1)).occurred
	).is_false()

	# Not before the final period.
	var early_period: PossessionContext = _foul_context(input, 1, window - 1000, -3)
	assert_bool(
		resolver.resolve_leading_by_three_foul(early_period, SeededRandomSource.new(1)).occurred
	).is_false()

	# And never when the share is zero, whatever the state — the "optional" of
	# the production brief.
	input.balance_profile.leading_foul_share = 0.0
	var eligible: PossessionContext = _foul_context(
		input, rules.regulation_periods, window - 1000, -3)
	assert_bool(
		resolver.resolve_leading_by_three_foul(eligible, SeededRandomSource.new(1)).occurred
	).is_false()


# --- reachability in a real simulated game ---------------------------------------

## Every strategy above is provably reachable through the public `MatchSession`
## path, not only through a hand-built context — the same standard the
## existing timeout suite holds `_consider_timeout` to.
func test_two_for_one_and_designed_play_are_reachable_in_real_games() -> void:
	var found_two_for_one: int = 0
	var found_designed_play: int = 0
	for variation in range(902000, 902040):
		var input: MatchInput = CompetitionCatalog.match_for(
			CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, 0.5)
		var session := MatchSession.new(input, SeededRandomSource.new(variation + 1))
		var output: MatchSimulationOutput = session.run_to_completion()
		for event in output.events:
			if event.event_type != MatchDomainEvent.ACTION_SELECTED:
				continue
			if event.detail_id == EndgameStrategy.TAG_TWO_FOR_ONE:
				found_two_for_one += 1
			elif event.detail_id == EndgameStrategy.TAG_DESIGNED_PLAY:
				found_designed_play += 1
	assert_int(found_two_for_one)\
		.override_failure_message("two-for-one never fired in 40 games").is_greater(0)
	assert_int(found_designed_play)\
		.override_failure_message("the designed play never fired in 40 games").is_greater(0)


# --- helpers -----------------------------------------------------------------

## A snapshot at a stated period, clock and home-minus-away margin, with a
## realized pace already on the board so `GameManagement.remaining_ms`-derived
## reads have something consistent to work from. Mirrors
## `TestGameManagement._snapshot_at`.
func _snapshot_at(
	input: MatchInput,
	period: int,
	clock_ms: int,
	margin: int,
) -> MatchSnapshot:
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot := MatchSnapshot.new(input)
	snapshot.period = period
	snapshot.clock_ms = clock_ms
	snapshot.shot_clock_ms = mini(rules.shot_clock_seconds * 1000, clock_ms)
	var elapsed: int = GameManagement.elapsed_ms(snapshot, rules)
	snapshot.possession_sequence = maxi(1, int(roundf(float(elapsed) / 7150.0)))
	snapshot.home.score = 80 + maxi(margin, 0)
	snapshot.away.score = 80 + maxi(-margin, 0)
	return snapshot


func _context(
	input: MatchInput,
	snapshot: MatchSnapshot,
	team_id: StringName,
) -> PossessionContext:
	return PossessionContext.new(input, snapshot, team_id, MatchupState.new({}), 1)


func _half_court_entered_clock(events: Array[MatchDomainEvent]) -> int:
	for event in events:
		if event.event_type == MatchDomainEvent.HALF_COURT_ENTERED:
			return event.clock_ms
	assert(false, "a dead-ball possession always reaches HALF_COURT_ENTERED")
	return -1


## A context built the way `FoulResolver` needs one: a ball handler on the
## floor and a defence with foul headroom to commit the whistle, at a stated
## period, clock and home-minus-away margin. The offense is the team down by
## `-margin`, i.e. the team the leading-by-three foul is committed against.
func _foul_context(
	input: MatchInput,
	period: int,
	clock_ms: int,
	margin: int,
) -> PossessionContext:
	var snapshot: MatchSnapshot = _snapshot_at(input, period, clock_ms, margin)
	var context: PossessionContext = _context(input, snapshot, input.home.team_id)
	context.ball_handler_id = input.home.starters()[0]
	return context
