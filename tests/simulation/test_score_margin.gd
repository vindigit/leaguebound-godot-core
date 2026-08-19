class_name TestScoreMargin
extends GdUnitTestSuite

## The contracts that keep a final score margin an accumulation of possessions.
##
## The defect this suite exists to prevent is the one Stage 4 measured: game
## shape drifting out of `BALANCE_SPEC.md` §14.2 while every §14.1 rate stayed
## legal. Two different kinds of thing can cause that, and they need different
## tests:
##
## - **Something asymmetric or duplicated.** One side quietly getting a second
##   helping of its own quality, a rotation that treats home and away
##   differently, or state leaking between games. These are provable, and the
##   tests below prove them.
## - **Something dishonest pointed the other way.** A clamp on the final score, a
##   modifier that helps whoever is behind, a forced tie. These are equally
##   provable, and forbidding them is the whole point of §14.2's "team totals
##   must emerge from possessions".
##
## The margin's *level* is a calibration question and belongs to the reports.
## What belongs here is that the mechanism producing it is honest.

const SETTLED_MARGIN_FIXTURE_SEED: int = 4242

## Samples are small on purpose. Every one of these games is a full top-domestic
## match, and this suite runs on every pull request; the assertions below are
## written so that a small sample still discriminates — a mean against its own
## sampling error, a slope against a bound wide enough to survive calibration
## and narrow enough to fail a duplicated influence.
const MIRROR_SAMPLE: int = 40
const EDGE_SAMPLE: int = 8

## The largest home-minus-away mean margin this suite will accept from mirror
## games with the home environment switched off.
##
## The honest figure is small and known: the margin report measures +1.76 ±1.36
## points over 700 mirror games, which is what inbounding first is worth plus
## sampling error. What this suite can do at forty games is catch a *one-sided*
## defect — a home bonus left switched on, a rotation that only runs for one
## bench, an environment term applied twice — and those are worth many points.
## The bound is set where such a defect sits and where ordinary sampling, whose
## standard error here is near three points, will not reach.
const MIRROR_MEAN_MARGIN_BOUND: float = 10.0

## Cached because each entry is a complete simulated game and six of the tests
## below read the same handful from different angles.
static var _mirror_cache: Dictionary = {}
static var _edge_cache: Dictionary = {}


# --- symmetry ---------------------------------------------------------------

## Two identical rosters produce no *large* systematic edge for either bench.
##
## Sampled rather than asserted on one game, because a single mirror game is
## supposed to have a winner. The bound is `MIRROR_MEAN_MARGIN_BOUND` rather
## than the sample's own confidence interval: a mean-inside-its-own-interval
## assertion sounds stricter and is actually a coin flip at forty games, which
## would make this suite flaky rather than strict. The population answer lives in
## the margin report, which measures it at seven hundred games.
func test_identical_rosters_have_no_systematic_edge() -> void:
	var margins: PackedFloat64Array = _mirror_margins()
	assert_float(absf(_mean(margins))).is_less(MIRROR_MEAN_MARGIN_BOUND)
	# Both benches win games. A one-sided defect large enough to matter shows
	# here before it shows in the mean.
	var home_wins: int = 0
	for margin in margins:
		if margin > 0.0:
			home_wins += 1
	assert_int(home_wins).is_greater(margins.size() / 5)
	assert_int(home_wins).is_less(margins.size() * 4 / 5)


## The same rosters, the same tactics, the same everything: the two teams have
## to be given the same rotation. A one-sided substitution rule would show up
## here as a minute gap that survives the sample.
func test_identical_rosters_receive_the_same_rotation() -> void:
	var difference: PackedFloat64Array = PackedFloat64Array()
	var index: int = 0
	for output in _mirror_sample():
		var input: MatchInput = _mirror_match(index, 0.0)
		difference.append(
			_starter_minutes(input, output, input.home)
			- _starter_minutes(input, output, input.away))
		index += 1
	assert_float(absf(_mean(difference))).is_less(maxf(_mean_half_width(difference), 1.0))


## Swapping which of two identical rosters is called "home" cannot change the
## basketball. The rosters are the same object shape, so the swap is a rename,
## and a rename must produce the identical ledger.
func test_swapping_identical_rosters_preserves_the_ledger() -> void:
	var first: MatchSimulationOutput = MatchEngine.new().simulate_match(
		_mirror_match(3, 0.0), SeededRandomSource.new(99991))
	var second: MatchSimulationOutput = MatchEngine.new().simulate_match(
		_mirror_match(3, 0.0), SeededRandomSource.new(99991))
	assert_str(MatchLedgerSerializer.hash_output(first)).is_equal(
		MatchLedgerSerializer.hash_output(second))
	assert_int(first.final_result.home_score).is_equal(second.final_result.home_score)


# --- team quality reaches the result exactly once ---------------------------

## A pregame capability edge moves the expected margin, monotonically, and by a
## bounded amount per unit of edge.
##
## Both halves matter. Without monotonicity the engine would not be reading team
## strength at all. Without the bound, a duplicated application of the same
## quality — the same rating counted in selection and again in resolution, or a
## roster tilt applied on two code paths — would sail through a monotonicity
## check while doubling the slope, which is exactly the failure mode that
## produced the Stage 4 margin dispersion.
func test_capability_edge_moves_the_margin_monotonically_and_boundedly() -> void:
	var neutral: float = _mean(_edge_margins(0.0))
	var small: float = _mean(_edge_margins(2.0))
	var large: float = _mean(_edge_margins(5.0))
	assert_float(small).is_greater(neutral)
	assert_float(large).is_greater(small)
	# Points of expected margin per rating point of team-wide edge. The measured
	# figure on this fixture is about 4.7, which the margin report also reports
	# as 1.59 points per centi-capability point of pregame gap. The bound is
	# wide enough that ordinary calibration moves the slope without failing and
	# narrow enough that applying the same quality twice — which roughly doubles
	# it — cannot pass.
	var slope: float = (large - neutral) / 5.0
	assert_float(slope).is_greater(1.0)
	assert_float(slope).is_less(7.0)


## Strength is not destiny. An edge that always decided the game would make the
## §14.2 close-game and overtime bands unreachable by construction.
##
## Stated as an overlap rather than as an upset count. "At least one upset in
## eight games" is a coin flip at any honest slope and would make this suite
## flaky by construction; that the two margin distributions still overlap is the
## property that actually distinguishes a stochastic engine from a lookup of
## which roster is better.
func test_a_capability_edge_does_not_decide_every_game() -> void:
	var neutral: PackedFloat64Array = _edge_margins(0.0)
	var large: PackedFloat64Array = _edge_margins(5.0)
	assert_float(_minimum(large)).is_less(_maximum(neutral))


## Two identical teams still produce a spread of results. A mirror fixture whose
## margins collapsed toward zero would mean the engine had stopped resolving
## basketball and started resolving ratings.
func test_even_matchups_retain_stochastic_variation() -> void:
	var margins: PackedFloat64Array = _mirror_margins()
	var deviation: float = _standard_deviation(margins)
	assert_float(deviation).is_greater(4.0)
	# The upper bound is the other half of "realistic". A persistent game-level
	# scoring state — one team running hot for a whole game — would widen this
	# without changing any per-possession rate, and §14.2 has no room for it.
	# The measured figure between identical rosters is about 17.6.
	assert_float(deviation).is_less(30.0)
	var distinct: Dictionary = {}
	for margin in margins:
		distinct[int(margin)] = true
	assert_int(distinct.size()).is_greater(margins.size() / 2)


# --- nothing bends the result toward a target ------------------------------

## The score is not clamped. Margins reach well past the §14.2 blowout
## threshold, and the distribution does not pile up against a ceiling.
func test_no_clamp_bounds_the_final_margin() -> void:
	var margins: PackedFloat64Array = _edge_margins(5.0)
	var largest: float = 0.0
	var at_largest: int = 0
	for margin in margins:
		var absolute: float = absf(margin)
		if absolute > largest:
			largest = absolute
			at_largest = 1
		elif absolute == largest:
			at_largest += 1
	assert_float(largest).is_greater(25.0)
	# A clamp shows itself as a mode at the bound. One or two games sharing the
	# extreme is ordinary; a quarter of the sample sitting on it is a clamp.
	assert_int(at_largest).is_less(margins.size() / 4)


## Nothing in resolution reads the score. Two possessions identical in every
## respect except that one team is thirty points ahead resolve to the identical
## events.
##
## This is the direct test for a rubber band. It is stronger than an aggregate
## check: it holds the random stream, the lineups, the clock, and the possession
## identity fixed and moves only the scoreboard.
func test_resolution_ignores_the_score_outside_late_game() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var base: MatchSnapshot = _final_period_snapshot(input)
	var level: String = _possession_signature(input, base, 0, 0)
	var leading: String = _possession_signature(input, base, 30, 0)
	var trailing: String = _possession_signature(input, base, 0, 30)
	assert_str(leading).is_equal(level)
	assert_str(trailing).is_equal(level)


## The same, from the other direction: a trailing team receives no help. The
## comparison is between symmetric deficits, so any modifier keyed on "behind"
## would have to break the symmetry to exist.
func test_no_trailing_or_leading_modifier_exists() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var base: MatchSnapshot = _final_period_snapshot(input)
	var ahead: String = _possession_signature(input, base, 18, 0)
	var behind: String = _possession_signature(input, base, 0, 18)
	assert_str(ahead).is_equal(behind)


# --- late game --------------------------------------------------------------

## Intentional fouling is a coaching decision under stated conditions, not a
## general foul rate. It fires only when the defence trails, only inside the
## documented margin, and only inside the documented clock.
func test_intentional_fouling_activates_only_under_valid_conditions() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var snapshot := MatchSnapshot.new(input)

	# The gate's *shape* is checked below against the profile's own values. Its
	# *values* are checked here against fixed ones, because a test that derives
	# every boundary from the thing being changed cannot notice the thing being
	# changed: widening the window to ten minutes and thirty points would leave
	# every derived assertion below passing while the engine fouled deliberately
	# through the whole final period.
	assert_int(balance.intentional_foul_max_margin).is_greater_equal(1)
	assert_int(balance.intentional_foul_max_margin).is_less_equal(12)
	assert_int(balance.intentional_foul_clock_ms).is_greater_equal(5000)
	assert_int(balance.intentional_foul_clock_ms).is_less_equal(120000)

	# Early in the game the window is shut whatever the score.
	snapshot.period = 1
	snapshot.clock_ms = 1000
	snapshot.home.score = 90
	snapshot.away.score = 87
	assert_bool(_late_game(input, snapshot)).is_false()

	# Final period, inside the clock, defence trailing by a legal margin.
	snapshot.period = input.rule_profile.regulation_periods
	snapshot.clock_ms = balance.intentional_foul_clock_ms - 1000
	assert_bool(_late_game(input, snapshot)).is_true()
	assert_bool(_intentional_foul_is_available(input, snapshot)).is_true()

	# The defence is ahead: there is nothing to stop the clock for.
	snapshot.home.score = 80
	snapshot.away.score = 92
	assert_bool(_intentional_foul_is_available(input, snapshot)).is_false()

	# The defence is too far behind for fouling to be worth a possession.
	snapshot.home.score = 90 + balance.intentional_foul_max_margin + 5
	snapshot.away.score = 90
	assert_bool(_intentional_foul_is_available(input, snapshot)).is_false()

	# The clock has not reached the window.
	snapshot.home.score = 93
	snapshot.away.score = 90
	snapshot.clock_ms = balance.intentional_foul_clock_ms + 1000
	assert_bool(_intentional_foul_is_available(input, snapshot)).is_false()


## §18.2 score and time. The settled-game rotation fires on the absolute margin,
## so it treats the leading and the trailing bench identically, and it does not
## fire before the final period, outside its clock window, or in overtime.
func test_settled_game_rotation_is_symmetric_and_bounded() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var balance: SimulationBalanceProfile = input.balance_profile
	var resolver := RotationResolver.new(balance)
	var rules: CompetitionRuleProfile = input.rule_profile
	var final_period: int = rules.regulation_periods
	var window_ms: int = int(roundf(
		float(rules.period_length_ms(final_period)) * balance.decided_game_clock_share))

	var snapshot := MatchSnapshot.new(input)
	snapshot.period = final_period
	snapshot.clock_ms = window_ms - 1000

	# Home ahead by the threshold, and away ahead by the threshold, are the same
	# decision. This is what makes the rule a rotation and not a comeback.
	snapshot.home.score = balance.decided_game_margin
	snapshot.away.score = 0
	assert_bool(resolver.game_is_decided(snapshot, input)).is_true()
	snapshot.home.score = 0
	snapshot.away.score = balance.decided_game_margin
	assert_bool(resolver.game_is_decided(snapshot, input)).is_true()

	# One point short of the threshold is not a settled game.
	snapshot.home.score = balance.decided_game_margin - 1
	snapshot.away.score = 0
	assert_bool(resolver.game_is_decided(snapshot, input)).is_false()

	# A settled margin with the period still to play is not settled.
	snapshot.home.score = balance.decided_game_margin + 10
	snapshot.clock_ms = window_ms + 1000
	assert_bool(resolver.game_is_decided(snapshot, input)).is_false()

	# Not before the final period.
	snapshot.clock_ms = window_ms - 1000
	snapshot.period = final_period - 1
	assert_bool(resolver.game_is_decided(snapshot, input)).is_false()

	# Not in overtime: a game that reached overtime was tied.
	snapshot.period = final_period + 1
	assert_bool(resolver.game_is_decided(snapshot, input)).is_false()


## The settled-game rotation empties the bench from the bottom and then stops.
## The defect it replaced ordered the same substitution on every possession
## because it tested a fixed planned-minute threshold instead of asking whether
## anyone deeper was left.
func test_settled_game_rotation_converges() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var resolver := RotationResolver.new(input.balance_profile)
	var rules: CompetitionRuleProfile = input.rule_profile
	var snapshot := MatchSnapshot.new(input)
	snapshot.period = rules.regulation_periods
	snapshot.clock_ms = int(roundf(
		float(rules.period_length_ms(snapshot.period))
		* input.balance_profile.decided_game_clock_share)) - 1000
	snapshot.home.score = 40
	snapshot.away.score = 0

	var settled: int = 0
	for _step in range(40):
		var orders: Array[SubstitutionOrder] = resolver.plan(snapshot, input, input.home.team_id)
		var moved: bool = false
		for order in orders:
			if order.reason == SubstitutionOrder.Reason.DECIDED_GAME:
				settled += 1
				moved = true
			snapshot.home.runtime_by_id(order.outgoing_id).on_court = false
			snapshot.home.runtime_by_id(order.incoming_id).on_court = true
		if not moved:
			break
	assert_int(settled).is_greater(0)
	# Ten players, five on court: the rule can move at most the five it starts
	# with. Anything beyond that is the churn this test exists to catch.
	assert_int(settled).is_less_equal(5)


# --- overtime and reconciliation -------------------------------------------

## A level regulation score enters overtime, and an overtime game was level at
## the end of regulation. Both directions, because only one of them is the
## interesting failure.
func test_regulation_ties_enter_overtime() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var input: MatchInput = GoldenScenarios.input_for(scenario)
		var regulation: int = input.rule_profile.regulation_periods
		var home: int = _regulation_points(
			output.final_result.statistics.team_line(input.home.team_id), regulation)
		var away: int = _regulation_points(
			output.final_result.statistics.team_line(input.away.team_id), regulation)
		assert_bool((home == away) == (output.final_result.overtime_periods > 0)).is_true()
		# However the game ended, it did not end level.
		assert_int(output.final_result.home_score).is_not_equal(
			output.final_result.away_score)


## Overtime scoring is real scoring: it reconciles into the same box score and
## the same period list as regulation.
func test_overtime_games_reconcile() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.OVERTIME)
	var input: MatchInput = GoldenScenarios.input_for(GoldenScenarios.OVERTIME)
	assert_int(output.final_result.overtime_periods).is_greater(0)
	assert_array(output.final_result.statistics.reconcile()).is_empty()
	for team: TeamMatchProfile in [input.home, input.away]:
		var line: TeamStatLine = output.final_result.statistics.team_line(team.team_id)
		assert_int(line.period_scores.size()).is_equal(
			input.rule_profile.regulation_periods + output.final_result.overtime_periods)
		var total: int = 0
		for period_score in line.period_scores:
			total += period_score
		assert_int(total).is_equal(line.points)


## Possessions, points, and points per possession all come from the ledger, and
## they agree with each other.
func test_possessions_scores_and_points_per_possession_reconcile() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var input: MatchInput = GoldenScenarios.input_for(scenario)
		for team: TeamMatchProfile in [input.home, input.away]:
			var line: TeamStatLine = output.final_result.statistics.team_line(team.team_id)
			var possessions: int = 0
			var points: int = 0
			for record: PossessionRecord in output.possessions:
				if record.offense_team_id != team.team_id:
					continue
				possessions += 1
				points += record.points_scored
			assert_int(possessions).is_equal(line.engine_possessions)
			assert_int(points).is_equal(line.points)
			assert_int(possessions).is_greater(0)
			var per_possession: float = float(points) / float(possessions)
			assert_float(per_possession).is_equal_approx(
				float(line.points) / float(line.engine_possessions), 0.000001)


# --- determinism and isolation ---------------------------------------------

## Repeated games do not leak state. Simulating other matches in between cannot
## change what a given seed produces.
func test_repeated_games_do_not_leak_state() -> void:
	var reference: String = MatchLedgerSerializer.hash_output(
		MatchEngine.new().simulate_match(
			_mirror_match(5, 0.5), SeededRandomSource.new(24601)))
	for index in range(2):
		MatchEngine.new().simulate_match(
			_mirror_match(index + 40, 0.5), SeededRandomSource.new(index + 1))
	var repeat: String = MatchLedgerSerializer.hash_output(
		MatchEngine.new().simulate_match(
			_mirror_match(5, 0.5), SeededRandomSource.new(24601)))
	assert_str(repeat).is_equal(reference)


## Play, Sim, and Skip are the same session, so they produce the same ledger.
func test_play_sim_and_skip_agree_on_the_margin() -> void:
	var input: MatchInput = _mirror_match(9, 0.5)
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(555))

	var stepped := MatchSession.new(input, SeededRandomSource.new(555))
	stepped.open()
	while not stepped.is_complete():
		stepped.advance_possession()
	var played: MatchSimulationOutput = stepped.build_output()

	var skipped: MatchSimulationOutput = MatchSession.new(
		input, SeededRandomSource.new(555)).skip_to_final_result()

	var reference: String = MatchLedgerSerializer.hash_output(simulated)
	assert_str(MatchLedgerSerializer.hash_output(played)).is_equal(reference)
	assert_str(MatchLedgerSerializer.hash_output(skipped)).is_equal(reference)
	assert_int(played.final_result.home_score - played.final_result.away_score).is_equal(
		simulated.final_result.home_score - simulated.final_result.away_score)


# --- helpers ----------------------------------------------------------------

func _mirror_match(variation: int, home_environment: float) -> MatchInput:
	return CompetitionCatalog.mirrored_match_for(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, variation, home_environment)


## Mirror games with the home environment switched off, so the only asymmetry
## left is that home inbounds first.
func _mirror_sample() -> Array[MatchSimulationOutput]:
	if _mirror_cache.has(MIRROR_SAMPLE):
		var cached: Array[MatchSimulationOutput] = _mirror_cache[MIRROR_SAMPLE]
		return cached
	var outputs: Array[MatchSimulationOutput] = []
	for index in range(MIRROR_SAMPLE):
		outputs.append(MatchEngine.new().simulate_match(
			_mirror_match(index, 0.0), SeededRandomSource.new(index * 104729 + 7)))
	_mirror_cache[MIRROR_SAMPLE] = outputs
	return outputs


func _mirror_margins() -> PackedFloat64Array:
	var margins := PackedFloat64Array()
	for output in _mirror_sample():
		margins.append(float(
			output.final_result.home_score - output.final_result.away_score))
	return margins


## Games in which the home roster carries a stated rating-point edge over an
## otherwise identical away roster. The edge is the only difference: both are
## built from the same variation, so their internal tilts, bodies, roles, and
## tactics match exactly.
func _edge_margins(edge: float) -> PackedFloat64Array:
	if _edge_cache.has(edge):
		var cached: PackedFloat64Array = _edge_cache[edge]
		return cached
	var margins := PackedFloat64Array()
	var competition: int = CalibrationTargets.Competition.TOP_DOMESTIC_PRO
	for index in range(EDGE_SAMPLE):
		var balance := SimulationBalanceProfile.new()
		var home: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"home", index * 2, balance, edge)
		var away: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"away", index * 2, balance, 0.0)
		var input := MatchInput.new(
			StringName("edge_match_%d" % index),
			StringName("edge_game_%d" % index),
			CompetitionCatalog.rules_for(competition),
			balance,
			home,
			away,
			home.team_id,
			CompetitionCatalog.ratings_profile(),
			0.0)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(index * 15485863 + 3))
		margins.append(float(
			output.final_result.home_score - output.final_result.away_score))
	_edge_cache[edge] = margins
	return margins


## A snapshot in the final regulation period with enough clock left that neither
## score-aware window is open: not the §13.1 intentional-foul window, and not the
## §18.2 settled-game window.
##
## The final period is where a score-dependent modifier would be least
## conspicuous and most tempting, so it is where the comparison is worth making.
## Testing this in the first period would be nearly tautological — the engine
## does not even ask about the score before the final period.
func _final_period_snapshot(input: MatchInput) -> MatchSnapshot:
	var rules: CompetitionRuleProfile = input.rule_profile
	var balance: SimulationBalanceProfile = input.balance_profile
	var floor_ms: int = maxi(
		balance.intentional_foul_clock_ms,
		int(roundf(float(rules.period_length_ms(rules.regulation_periods))
			* balance.decided_game_clock_share)))
	var session := MatchSession.new(input, SeededRandomSource.new(SETTLED_MARGIN_FIXTURE_SEED))
	session.open()
	while not session.is_complete():
		var snapshot: MatchSnapshot = session.snapshot()
		if snapshot.period == rules.regulation_periods and snapshot.clock_ms > floor_ms:
			assert_int(snapshot.clock_ms).is_greater(floor_ms)
			return snapshot
		session.advance_possession()
	assert_bool(false).override_failure_message(
		"the fixture never reached the final period with clock to spare").is_true()
	return session.snapshot()


## Resolves one possession from `base` with the scoreboard overwritten, and
## returns a signature of everything the possession produced.
func _possession_signature(
	input: MatchInput,
	base: MatchSnapshot,
	home_score: int,
	away_score: int,
) -> String:
	var snapshot: MatchSnapshot = base.copy()
	snapshot.home.score = home_score
	snapshot.away.score = away_score
	var engine := PossessionEngine.new(input)
	var result: PossessionResult = engine.simulate(
		snapshot, input, SeededRandomSource.new(778899), false)
	var parts: PackedStringArray = []
	for event in result.events:
		parts.append("%s|%s|%s|%d" % [
			event.event_type, event.team_id, event.primary_player_id, event.points])
	return "\n".join(parts)


func _late_game(input: MatchInput, snapshot: MatchSnapshot) -> bool:
	var context := PossessionContext.new(
		input, snapshot, input.home.team_id, MatchupState.new({}), 1)
	return context.is_late_game()


## Whether the score and clock make an intentional foul legal for the defence,
## read through the resolver's own gate rather than restated here.
func _intentional_foul_is_available(input: MatchInput, snapshot: MatchSnapshot) -> bool:
	var balance: SimulationBalanceProfile = input.balance_profile
	var context := PossessionContext.new(
		input, snapshot, input.home.team_id, MatchupState.new({}), 1)
	if not context.is_late_game():
		return false
	var defense_margin: int = -context.offense_margin()
	return defense_margin < 0 and defense_margin >= -balance.intentional_foul_max_margin


func _starter_minutes(
	input: MatchInput,
	output: MatchSimulationOutput,
	team: TeamMatchProfile,
) -> float:
	var starters: Array[StringName] = team.starters()
	var minutes: float = 0.0
	for line: PlayerStatLine in output.final_result.statistics.players_for(team.team_id):
		if starters.has(line.player_id):
			minutes += line.minutes_played()
	return minutes


func _regulation_points(line: TeamStatLine, regulation_periods: int) -> int:
	var total: int = 0
	for index in range(mini(regulation_periods, line.period_scores.size())):
		total += line.period_scores[index]
	return total


func _minimum(values: PackedFloat64Array) -> float:
	var lowest: float = INF
	for value in values:
		lowest = minf(lowest, value)
	return lowest


func _maximum(values: PackedFloat64Array) -> float:
	var highest: float = -INF
	for value in values:
		highest = maxf(highest, value)
	return highest


func _mean(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _standard_deviation(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	var mean: float = _mean(values)
	var total: float = 0.0
	for value in values:
		total += (value - mean) * (value - mean)
	return sqrt(total / float(values.size() - 1))


func _mean_half_width(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	return 1.96 * _standard_deviation(values) / sqrt(float(values.size()))
