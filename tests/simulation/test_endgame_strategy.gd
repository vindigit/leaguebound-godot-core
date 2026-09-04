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
	# Never for a trailing team, at any clock: a team that has to score cannot
	# also be running time off.
	for margin: int in [-1, -3, -6]:
		var trailing: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, 20000, margin), input.home.team_id)
		assert_bool(EndgameStrategy.hold_for_final_shot_active(trailing, balance))\
			.override_failure_message("margin %d" % margin).is_false()


func test_hold_is_on_for_a_leading_team_with_the_game_in_hand() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 15000, 3), input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(context, balance)).is_true()


## Holding for the last shot of a tied game is the most ordinary
## end-of-regulation decision there is, and the first version of this rule
## refused it outright. It is admitted now, but only where the two clocks make
## it a real plan: the shot clock has to outlast the game clock, or the hold
## ends in a shot-clock violation rather than at the horn.
func test_a_tied_team_may_hold_when_the_shot_clock_outlasts_the_game_clock() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile

	var snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 14000, 0)
	snapshot.shot_clock_ms = 20000
	var can_hold: PossessionContext = _context(input, snapshot, input.home.team_id)
	assert_int(GameManagement.remaining_ms(snapshot, rules)).is_less_equal(snapshot.shot_clock_ms)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(can_hold, balance)).is_true()

	# The same tie and the same game clock, with a shot clock that will expire
	# first: holding would hand the ball back, so the rule refuses and
	# two-for-one's extra possession is what the team wants instead.
	snapshot.shot_clock_ms = 9000
	var would_violate: PossessionContext = _context(input, snapshot, input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(would_violate, balance)).is_false()


## The shot-clock condition binds only the tied case. A leading team holds on
## the game clock alone — it is content to shoot late, or to shoot poorly, and
## a shot-clock violation still leaves the opponent less time than an early
## made basket would have.
func test_the_shot_clock_condition_binds_only_the_tied_team() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 20000, 4)
	snapshot.shot_clock_ms = 6000
	var leading: PossessionContext = _context(input, snapshot, input.home.team_id)
	assert_bool(EndgameStrategy.hold_for_final_shot_active(leading, balance)).is_true()


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


# --- quick two vs. a tying three ------------------------------------------------

func test_quick_two_needs_the_exact_deficit_and_the_outer_window() -> void:
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

	# Timeout inventory is irrelevant: the plan after a make is to foul the
	# opponent, and the engine has no quick-two timeout expenditure.
	var no_timeout_snapshot: MatchSnapshot = _snapshot_at(
		input, rules.regulation_periods, window, -3)
	no_timeout_snapshot.home.timeouts_remaining = 0
	var no_timeout: PossessionContext = _context(input, no_timeout_snapshot, input.home.team_id)
	assert_bool(EndgameStrategy.quick_two_preferred(no_timeout, balance)).is_true()


# --- the designed final possession ---------------------------------------------

## Inside the window, for a tie and for a deficit the possession can still
## close — and outside it for nobody.
func test_designed_play_is_on_only_for_the_truly_final_possession() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var inside_clock: int = balance.designed_play_window_ms - 2000
	var recoverable: int = EndgameStrategy.recoverable_deficit(inside_clock, balance)
	for margin: int in [0, -1, -recoverable]:
		var inside: PossessionContext = _context(
			input,
			_snapshot_at(input, rules.regulation_periods, inside_clock, margin),
			input.home.team_id)
		assert_bool(EndgameStrategy.designed_play_active(inside, balance))\
			.override_failure_message("margin %d" % margin).is_true()
	var outside: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.designed_play_window_ms + 2000, -1),
		input.home.team_id)
	assert_bool(EndgameStrategy.designed_play_active(outside, balance)).is_false()


## A team with a safe lead wants the clock, not its closer's best look. The
## first version of this rule boosted the closer at every margin, which pushed
## a winning team toward an early shot in the games it had already won.
func test_designed_play_refuses_a_leading_team_at_every_lead() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in [1, 2, 6, 14]:
		var leading: PossessionContext = _context(
			input,
			_snapshot_at(input, rules.regulation_periods, balance.designed_play_window_ms - 2000, margin),
			input.home.team_id)
		assert_bool(EndgameStrategy.designed_play_active(leading, balance))\
			.override_failure_message("lead %d" % margin).is_false()


## And it refuses a deficit the clock cannot close, which is the other half of
## "realistically recoverable".
func test_designed_play_refuses_a_deficit_the_clock_cannot_close() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var clock: int = balance.designed_play_window_ms - 2000
	var recoverable: int = EndgameStrategy.recoverable_deficit(clock, balance)
	var unreachable: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, clock, -(recoverable + 1)),
		input.home.team_id)
	assert_bool(EndgameStrategy.designed_play_active(unreachable, balance)).is_false()


## Once a legal designed-play action has been selected inside the desperation
## threshold, its bounded duration cannot erase the action before it reaches
## the ledger. The release is scheduled one millisecond before the horn; the
## shot/contact resolvers remain completely untouched.
func test_selected_designed_play_action_releases_before_the_horn() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, 500, -2),
		input.home.team_id)
	assert_bool(EndgameStrategy.final_release_due(
		context, balance, balance.desperation_clock_ms)).is_true()
	var elapsed: int = ClockResolver.new(balance, rules).action_ms(
		context, ActionFamily.Value.PULL_UP, SeededRandomSource.new(4242))
	assert_int(elapsed).is_equal(499)


## The deadline is not a universal clock compression rule. A leading team has
## no designed play to save the game, so the same draw retains its ordinary
## minimum duration and is allowed to expire naturally.
func test_final_release_deadline_is_scoped_to_a_tieable_designed_play() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, 500, 2),
		input.home.team_id)
	assert_bool(EndgameStrategy.final_release_due(
		context, balance, balance.desperation_clock_ms)).is_false()
	var elapsed: int = ClockResolver.new(balance, rules).action_ms(
		context, ActionFamily.Value.PULL_UP, SeededRandomSource.new(4242))
	assert_int(elapsed).is_greater_equal(balance.action_seconds_min * 1000)


## The recoverable deficit is the possession in hand plus one per further
## `endgame_possession_ms`, each worth at most a three — arithmetic, not a
## tuning knob, and monotone in the time left.
func test_recoverable_deficit_grows_one_possession_at_a_time() -> void:
	var balance := SimulationBalanceProfile.new()
	var swing: int = EndgameStrategy.MAXIMUM_PLANNED_POSSESSION_SWING
	assert_int(EndgameStrategy.recoverable_deficit(0, balance)).is_equal(0)
	assert_int(EndgameStrategy.recoverable_deficit(1000, balance)).is_equal(swing)
	assert_int(EndgameStrategy.recoverable_deficit(
		balance.endgame_possession_ms, balance)).is_equal(2 * swing)
	assert_int(EndgameStrategy.recoverable_deficit(
		balance.endgame_possession_ms * 3, balance)).is_equal(4 * swing)


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
## The window quick-two applies in is, by construction, also inside
## two-for-one's — both key off "trailing or tied", and quick-two's window
## (past `endgame_possession_ms`) sits inside two-for-one's (past one shot
## clock). Two-for-one boosts a direct shot symmetrically, whichever zone it
## is, so its contribution cancels out of the two-versus-three *ratio* even
## though it does not cancel out of either absolute value — which is what
## this test asserts against, rather than an absolute value that would be
## coupled to a strategy this test is not about.
func test_quick_two_swings_two_point_weight_against_three_point_weight() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.endgame_possession_ms + 5000, -3),
		input.home.team_id)
	assert_bool(EndgameStrategy.two_for_one_active(context, balance)).is_true()
	assert_bool(EndgameStrategy.quick_two_preferred(context, balance)).is_true()
	var actor: StringName = input.home.starters()[0]
	var preference: float = balance.quick_two_preference
	var two: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.MIDRANGE, actor, &"")
	var three: float = EndgameStrategy.action_multiplier(
		context, balance, ActionFamily.Value.PULL_UP, ShotZone.Value.STANDARD_THREE, actor, &"")
	assert_float(two / three).is_equal_approx((1.0 + preference) / (1.0 - preference), 0.0001)


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

## The one state the tactic exists for: the offence trailing by exactly two
## immediately before the last attempt of a trip, where the point cannot tie
## and a live rebound can. Every neighbouring margin refuses.
func test_intentional_miss_applies_only_to_a_two_point_deficit_before_the_final_attempt() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile

	# Margins here are the possession's *starting* margin with no points yet
	# scored in it, so the margin before the attempt is the margin itself.
	for margin: int in [-4, -3, -2, -1, 0, 1, 2, 3]:
		var context: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, 5000, margin), input.home.team_id)
		assert_bool(
			EndgameStrategy.should_intentionally_miss_final_free_throw(context, balance, 1, 2)
		).override_failure_message("margin %d" % margin).is_equal(margin == -2)

	var eligible: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 5000, -2), input.home.team_id)
	# Not the first attempt of a trip — only the last one is ever missed on
	# purpose.
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(eligible, balance, 0, 2)
	).is_false()
	# Not outside the narrow clock window: too much time still left to matter,
	# or none left at all to matter for.
	var too_early: PossessionContext = _context(
		input,
		_snapshot_at(input, rules.regulation_periods, balance.intentional_miss_clock_ms + 3000, -2),
		input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(too_early, balance, 1, 2)
	).is_false()
	# Not before the final period.
	var early_period: PossessionContext = _context(
		input, _snapshot_at(input, 1, 5000, -2), input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(early_period, balance, 1, 2)
	).is_false()


## The canonical trip: down three, awarded two, first one made. The margin the
## rule has to read is the one after that make — down two — and it gets it
## without being told, because `PossessionEngine._emit` reduces each attempt
## into the possession's own snapshot as it is written. The state the rule sees
## at the second attempt is the live scoreboard, not the possession's opening
## one.
func test_intentional_miss_reads_the_margin_the_earlier_makes_of_the_trip_produced() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile

	# The first attempt of the pair, down three: a point is worth having, and
	# it is not the last attempt anyway.
	var down_three: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 5000, -3), input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(down_three, balance, 0, 2)
	).is_false()
	# That one missed: still down three with one to shoot, and the point is
	# still worth having.
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(down_three, balance, 1, 2)
	).is_false()
	# That one went in, so the board now reads down two with one to shoot.
	# This is the state the rule exists for.
	var down_two: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 5000, -2), input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(down_two, balance, 1, 2)
	).is_true()


## A leading team never misses on purpose, at any lead, clock, or attempt
## index. The first version of this rule fired for a team ahead by two or
## three, which inverted the tactic: a leading team wants every point it can
## add, and a deliberate miss hands a live ball to the only side that needs one.
func test_a_leading_team_never_intentionally_misses() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	for margin: int in [1, 2, 3, 4, 8]:
		for attempts: int in [1, 2, 3]:
			# Clocks inside the eligible band, so a refusal here is the margin
			# gate doing the work rather than the window floor doing it.
			for clock: int in [3000, 4000, 5500, 7000]:
				var context: PossessionContext = _context(
					input, _snapshot_at(input, rules.regulation_periods, clock, margin),
					input.home.team_id)
				assert_bool(
					EndgameStrategy.should_intentionally_miss_final_free_throw(
						context, balance, attempts - 1, attempts)
				).override_failure_message(
					"lead %d, %d attempts, clock %d" % [margin, attempts, clock]).is_false()


## The plan is the rebound, so a rule profile where a missed final attempt is
## dead kills the plan rather than merely changing what follows it. Under such
## a profile the miss is a plain surrender of the ball — strictly worse than
## the point — and the rule must refuse.
func test_intentional_miss_refuses_where_the_final_attempt_is_not_reboundable() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var context: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, 5000, -2), input.home.team_id)
	assert_bool(rules.final_free_throw_reboundable).is_true()
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(context, balance, 1, 2)
	).is_true()

	rules.final_free_throw_reboundable = false
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(context, balance, 1, 2)
	).is_false()


## The window has a floor as well as a ceiling, and the floor is what makes the
## rule about a plan rather than about a gesture. A miss buys a rebound and the
## shot after it; below the clock those two will actually be charged, it buys
## neither, and the free point is worth more.
func test_intentional_miss_refuses_below_the_clock_the_rebound_and_shot_need() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var rules: CompetitionRuleProfile = input.rule_profile
	var floor_ms: int = EndgameStrategy.minimum_miss_window_ms(balance)
	assert_int(floor_ms).is_equal(
		(balance.rebound_seconds_max + balance.action_seconds_min) * 1000)

	# At the floor exactly, the plan still fits.
	var at_floor: PossessionContext = _context(
		input, _snapshot_at(input, rules.regulation_periods, floor_ms, -2), input.home.team_id)
	assert_bool(
		EndgameStrategy.should_intentionally_miss_final_free_throw(at_floor, balance, 1, 2)
	).is_true()

	# One millisecond under it, and at the millisecond a free-throw trip
	# actually leaves on the clock, it does not.
	for clock: int in [floor_ms - 1, 1]:
		var too_late: PossessionContext = _context(
			input, _snapshot_at(input, rules.regulation_periods, clock, -2), input.home.team_id)
		assert_bool(
			EndgameStrategy.should_intentionally_miss_final_free_throw(too_late, balance, 1, 2)
		).override_failure_message("clock %d" % clock).is_false()


## And the profile refuses to ship a window that cannot contain that floor,
## which is how the rule shipped at v9 once the floor was known: an eligible
## band half a second wide is a rule that never fires.
func test_the_shipped_profile_keeps_the_miss_window_above_its_own_floor() -> void:
	var balance := SimulationBalanceProfile.new()
	assert_int(balance.intentional_miss_clock_ms).is_greater(
		EndgameStrategy.minimum_miss_window_ms(balance))
	assert_array(balance.validate()).is_empty()

	# And the validation is real: a window at the floor is rejected by name.
	balance.intentional_miss_clock_ms = EndgameStrategy.minimum_miss_window_ms(balance)
	var failures: PackedStringArray = balance.validate()
	assert_int(failures.size()).is_equal(1)
	assert_str(failures[0]).contains("intentional-miss window")


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

	var eligible_snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 5000, -2)
	# Margin -5, not -20: the comparison point has to sit inside §20.1's own
	# `|margin| <= 5.0` pressure window too, or the two probabilities would
	# differ for a reason that has nothing to do with the intentional miss.
	# -5 is outside EndgameStrategy's own single eligible deficit while staying
	# inside §20.1's window, which is what isolates the one term this test is
	# actually about.
	var ineligible_snapshot: MatchSnapshot = _snapshot_at(input, rules.regulation_periods, 5000, -5)
	assert_bool(EndgameStrategy.should_intentionally_miss_final_free_throw(
		_context(input, eligible_snapshot, input.home.team_id), input.balance_profile, 1, 2)
	).is_true()
	assert_bool(EndgameStrategy.should_intentionally_miss_final_free_throw(
		_context(input, ineligible_snapshot, input.home.team_id), input.balance_profile, 1, 2)
	).is_false()
	var eligible: float = resolver.probability(_context(input, eligible_snapshot, input.home.team_id), shooter)
	var ineligible: float = resolver.probability(
		_context(input, ineligible_snapshot, input.home.team_id), shooter)
	assert_float(eligible).is_equal(ineligible)


# --- timeout to advance ---------------------------------------------------------

## The rule flag is a §4 fact about the competition. Exactly one profile grants
## it, and the state that is eligible under that profile is ineligible under
## every other one — including college, which had the grant and should not have
## (see `CompetitionRuleProfile.timeout_advance_permitted`).
func test_timeout_advance_needs_the_rule_flag_a_trailing_margin_a_timeout_and_the_window() -> void:
	var balance := SimulationBalanceProfile.new()
	var permitted: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO)
	assert_bool(permitted.timeout_advance_permitted).is_true()
	for competition: int in CalibrationTargets.all_competitions():
		if competition == CalibrationTargets.Competition.TOP_DOMESTIC_PRO:
			continue
		var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
		assert_bool(rules.timeout_advance_permitted).override_failure_message(
			"%s grants timeout-advance" % CalibrationTargets.competition_id(competition)
		).is_false()

	var snapshot: MatchSnapshot = _advance_snapshot(permitted, balance)
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, permitted, balance, &"home", false, false)).is_true()

	# The same state under a profile that does not grant the rule.
	var not_permitted: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.DEVELOPMENT)
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, not_permitted, balance, &"home", false, false)).is_false()

	# Not while leading: the rule exists to help a team get back in position,
	# not to spot a comfortable one an extra timeout's worth of rest.
	snapshot.home.score = 70
	snapshot.away.score = 60
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, permitted, balance, &"home", false, false)).is_false()

	# Not with no timeout left to call.
	snapshot = _advance_snapshot(permitted, balance)
	snapshot.home.timeouts_remaining = 0
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, permitted, balance, &"home", false, false)).is_false()

	# Not outside the final window.
	snapshot = _advance_snapshot(permitted, balance)
	snapshot.clock_ms = balance.timeout_advance_window_ms + 5000
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		snapshot, permitted, balance, &"home", false, false)).is_false()


## The four conditions that turned the advance from an expenditure into a
## decision, each proven to refuse on its own with everything else eligible.
func test_timeout_advance_is_a_decision_rather_than_an_automatic_expenditure() -> void:
	var balance := SimulationBalanceProfile.new()
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO)

	# There is no ball to inbound after a live transfer, so there is no
	# frontcourt advance to buy — only a break to interrupt.
	var live: MatchSnapshot = _advance_snapshot(rules, balance)
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		live, rules, balance, &"home", true, false)).is_false()

	# One possession is advanced at most once.
	var repeat: MatchSnapshot = _advance_snapshot(rules, balance)
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		repeat, rules, balance, &"home", false, true)).is_false()

	# A deficit the clock cannot close is not worth an allowance.
	var buried: MatchSnapshot = _advance_snapshot(rules, balance)
	var recoverable: int = EndgameStrategy.recoverable_deficit(buried.clock_ms, balance)
	buried.away.score = buried.home.score + recoverable + 1
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		buried, rules, balance, &"home", false, false)).is_false()
	buried.away.score = buried.home.score + recoverable
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		buried, rules, balance, &"home", false, false)).is_true()

	# A coach keeps allowances in hand. At exactly the reserve he declines; one
	# above it he calls.
	var reserve: int = balance.timeout_advance_reserve_timeouts
	assert_int(reserve).is_greater(0)
	var thin: MatchSnapshot = _advance_snapshot(rules, balance)
	thin.home.timeouts_remaining = reserve
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		thin, rules, balance, &"home", false, false)).is_false()
	thin.home.timeouts_remaining = reserve + 1
	assert_bool(EndgameStrategy.timeout_advance_eligible(
		thin, rules, balance, &"home", false, false)).is_true()


## The window is derived rather than picked: skipping the backcourt walk only
## decides anything while the game clock, not the shot clock, is what limits
## the possession. That is one shot clock plus about one walk, and the window
## has to stay inside it for the profile that grants the rule.
func test_the_timeout_advance_window_is_no_wider_than_the_benefit_it_buys() -> void:
	var balance := SimulationBalanceProfile.new()
	var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO)
	var one_walk_ms: int = 5000
	assert_int(balance.timeout_advance_window_ms).is_less_equal(
		rules.shot_clock_seconds * 1000 + one_walk_ms)
	assert_int(balance.timeout_advance_window_ms).is_greater(rules.shot_clock_seconds * 1000)


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


## The tactic is "send them to the line for two". Below the team-foul
## threshold the whistle awards nothing: the offence keeps the ball, inbounds
## with a fresh shot clock, and can still shoot the three the foul was meant to
## prevent. The defence would have paid a team foul for the opposite of what it
## wanted, so the decision refuses outside the bonus.
func test_leading_by_three_foul_refuses_outside_the_bonus() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var rules: CompetitionRuleProfile = input.rule_profile
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var resolver := FoulResolver.new(
		capability, BodyEffects.new(input.balance_profile), input.balance_profile)
	input.balance_profile.leading_foul_share = 1.0
	var window: int = input.balance_profile.leading_foul_clock_ms

	var context: PossessionContext = _foul_context(
		input, rules.regulation_periods, window - 1000, -3)
	# `_foul_context` puts the defence in the bonus, which is why the eligible
	# case above fires at all.
	assert_int(rules.bonus_free_throws_for(context.defense_state().team_fouls)).is_greater(0)

	for team_fouls: int in range(0, rules.team_foul_bonus_threshold):
		context.defense_state().team_fouls = team_fouls
		assert_int(rules.bonus_free_throws_for(team_fouls)).is_equal(0)
		assert_bool(
			resolver.resolve_leading_by_three_foul(context, SeededRandomSource.new(1)).occurred
		).override_failure_message("team fouls %d" % team_fouls).is_false()


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


## A snapshot in which every timeout-advance condition holds: the final period,
## inside the window, trailing by a deficit the clock can still close, and with
## allowances above the reserve. Each test then breaks exactly one of them.
func _advance_snapshot(
	rules: CompetitionRuleProfile,
	balance: SimulationBalanceProfile,
) -> MatchSnapshot:
	var snapshot := MatchSnapshot.new(
		MatchFixtureFactory.match_between(
			MatchFixtureFactory.uniform_team(&"home", 70),
			MatchFixtureFactory.uniform_team(&"away", 70),
			rules, balance))
	snapshot.period = rules.regulation_periods
	snapshot.clock_ms = balance.timeout_advance_window_ms - 5000
	snapshot.shot_clock_ms = rules.shot_clock_seconds * 1000
	snapshot.home.score = 60
	snapshot.away.score = 62
	snapshot.home.timeouts_remaining = rules.timeouts_per_team
	snapshot.away.timeouts_remaining = rules.timeouts_per_team
	return snapshot


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
	# The defence is in the bonus, because "send them to the line for two" is
	# the tactic and a whistle that awards nothing is not it. A late-period
	# team-foul count is the ordinary state for this decision anyway.
	snapshot.away.team_fouls = input.rule_profile.team_foul_bonus_threshold
	var context: PossessionContext = _context(input, snapshot, input.home.team_id)
	context.ball_handler_id = input.home.starters()[0]
	return context
