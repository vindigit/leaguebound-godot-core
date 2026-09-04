class_name TestFgDecomposition
extends GdUnitTestSuite

## The field-goal accounting identities, and the contracts the §14.1
## field-goal-percentage diagnosis rests on.
##
## `test_ppp_decomposition.gd` owns the *points* identity. This suite owns the
## *field-goal* one, which is a different and independently breakable thing: a
## decomposition can attribute every point correctly and still lose a shot off
## the zone axis, or off the contest axis, or off the box-score arm — and when
## it does, every share and every accuracy built on that axis is wrong while
## still summing to one and still looking like basketball.
##
## Three kinds of assertion live here:
##
## - **The identities**, which must be exact, and which must be able to *fail*.
##   A gate that cannot report a breach is not a gate.
## - **The capability contracts** — that a shooter's rating reaches make
##   probability, that a defender's rating reaches contest pressure, and that
##   the rating ladder the fixture builds is the ladder it intends. These are
##   what separate "this level shoots worse because its players are worse",
##   which is the model working, from a normalization defect, which is not.
## - **The instrumentation contract**: the diagnostic probe that reads the
##   decomposed terms out of `ShotResolver` must be incapable of changing what
##   the engine does. A measurement that perturbs what it measures is worse than
##   no measurement, and this is the one addition in this work that touches a
##   production file at all.

const TOLERANCE: float = 0.000001

## Enough games to exercise the identities across overtime, foul-outs,
## offensive rebounds and garbage time without making the suite slow.
const IDENTITY_GAMES: int = 6

## Enough attempts that a contest band's accuracy is a rate and not a rumour.
## Raised rather than lowered when a band was thin: the tolerance below is the
## threshold, and the fixture is what gets bigger.
const DISTRIBUTION_GAMES: int = 24

## A band needs at least this many attempts before its accuracy is judged for
## ordering. Below it the band is reported and skipped, because a handful of
## attempts can invert by chance without anything being wrong.
const MINIMUM_BAND_ATTEMPTS: int = 200

## Contest-band accuracy must fall as pressure rises, but two adjacent bands may
## overlap slightly at a finite sample. This is the allowance, in absolute
## percentage points.
const BAND_ORDER_TOLERANCE: float = 0.02

## A range this suite owns, disjoint from every calibration and diagnosis range.
const SUITE_BASE: int = 905000

## How far a §14.1 compensation channel may drift on a fixed, fully
## deterministic fixture before the pin below fires.
##
## The fixture consumes fixed seeds, so the honest tolerance is zero; this is
## small enough to catch a compensation-sized move — the mutations that motivated
## the pin were +0.05 and +0.04 — and non-zero only so that an unrelated,
## explained change does not have to be re-pinned to the sixth decimal.
const CHANNEL_TOLERANCE: float = 0.004


## Detaches the diagnostic probe after every test, whatever the test did.
##
## `ShotResolver.probe` is static, so it outlives the accumulator that attached
## it and outlives this suite. Every attach below is paired with a detach on its
## own happy path, but a failed assertion aborts the test between the two, and
## the field would then survive into another suite bound to a freed object. The
## production guard makes that harmless; this makes it not happen.
func after_test() -> void:
	ShotResolver.detach_probe()


func _decompose(competition: int, games: int) -> PppDecomposition:
	var decomposition := PppDecomposition.new()
	for index in range(games):
		var variation: int = SUITE_BASE + index
		var input: MatchInput = CompetitionCatalog.match_for(competition, variation, 0.5)
		decomposition.accumulate(
			input, MatchEngine.new().simulate_match(
				input, SeededRandomSource.new(variation + 1)))
	return decomposition


# --- 1. the field-goal identities -------------------------------------------

## Every way of counting a field goal reaches the same number.
##
## Four axes count the same shots — zone, contest band, assisted state, and the
## box score, which is produced by a different code path from the ledger — and
## all four must total the ledger's own count. This is the check that would have
## caught a contest band read off the wrong event, which is a defect this
## project has already made once and absorbed silently.
func test_the_field_goal_identities_close_on_every_axis() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.COLLEGE, IDENTITY_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	assert_bool(decomposition.field_goal_identities_hold()).override_failure_message(
		"field-goal identities did not close: %s"
		% ", ".join(decomposition.field_goal_identity_breaches())).is_true()
	assert_int(totals.zone_attempts_total()).is_equal(totals.field_goals_attempted())
	assert_int(totals.contest_attempts_total()).is_equal(totals.field_goals_attempted())
	assert_int(totals.zone_makes_total()).is_equal(totals.field_goals_made())
	assert_int(totals.contest_makes_total()).is_equal(totals.field_goals_made())
	assert_int(totals.created_attempts + totals.uncreated_attempts).is_equal(
		totals.field_goals_attempted())
	assert_int(totals.created_makes + totals.uncreated_makes).is_equal(
		totals.field_goals_made())


## Field goals are exactly two-pointers and three-pointers, and the points they
## produce are exactly what the scoring identity says.
func test_made_field_goals_are_exactly_the_two_and_three_pointers() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.HIGH_SCHOOL, IDENTITY_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	assert_int(totals.field_goals_made()).is_equal(
		totals.two_point_made + totals.three_point_made)
	assert_int(totals.field_goals_attempted()).is_equal(
		totals.two_point_attempted + totals.three_point_attempted)
	assert_int(
		2 * totals.two_point_made + 3 * totals.three_point_made + totals.free_throws_made
	).is_equal(totals.points)
	assert_int(totals.field_goals_made()).is_less_equal(totals.field_goals_attempted())


## The ledger, the possession records and the box score agree about field goals.
##
## The box score is a projection built by `BoxScoreProjector` from the same
## events, so this is two independent walks over one game reaching one answer —
## which is the only reason the box score is worth reconciling against at all.
func test_the_ledger_and_the_box_score_agree_about_field_goals() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, IDENTITY_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	assert_array(decomposition.violations).override_failure_message(
		"per-game reconciliation breaches: %s"
		% ", ".join(decomposition.violations)).is_empty()
	assert_int(totals.box_field_goals_made).is_equal(totals.field_goals_made())
	assert_int(totals.box_field_goals_attempted).is_equal(totals.field_goals_attempted())
	assert_bool(decomposition.is_reconciled()).is_true()


## The gate can fail.
##
## Every identity above is worthless if a breach is absorbed rather than
## reported, so the breach is manufactured here and the gate is required to
## notice each axis independently. This test exists because the failure mode it
## guards against is invisible: a decomposition that quietly drops a shot still
## adds up.
func test_the_field_goal_gate_reports_a_breach_rather_than_absorbing_it() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.COLLEGE, 2)
	assert_bool(decomposition.field_goal_identities_hold()).is_true()

	decomposition.totals.zone_attempts[ShotZone.Value.MIDRANGE] += 1
	assert_bool(decomposition.field_goal_identities_hold()).override_failure_message(
		"a lost zone attempt did not register as a breach").is_false()
	assert_bool(decomposition.is_reconciled()).is_false()
	decomposition.totals.zone_attempts[ShotZone.Value.MIDRANGE] -= 1
	assert_bool(decomposition.field_goal_identities_hold()).is_true()

	decomposition.totals.contest_makes[ContestBand.Value.OPEN] += 1
	assert_bool(decomposition.field_goal_identities_hold()).override_failure_message(
		"a phantom contest-band make did not register as a breach").is_false()
	decomposition.totals.contest_makes[ContestBand.Value.OPEN] -= 1

	decomposition.totals.box_field_goals_attempted += 1
	assert_bool(decomposition.field_goal_identities_hold()).override_failure_message(
		"a box-score disagreement did not register as a breach").is_false()
	decomposition.totals.box_field_goals_attempted -= 1

	decomposition.totals.created_attempts += 1
	assert_bool(decomposition.field_goal_identities_hold()).override_failure_message(
		"an assisted-state disagreement did not register as a breach").is_false()
	decomposition.totals.created_attempts -= 1
	assert_bool(decomposition.field_goal_identities_hold()).is_true()


# --- 2. the distributions ----------------------------------------------------

## Accuracy falls as the contest tightens, in every band the fixture actually
## uses.
##
## A band with too few attempts is reported and skipped rather than judged on
## noise — but the skip is on *sample size*, never on the band being
## inconvenient, and the fixture is sized so the bands that carry the shots are
## all judged.
func test_contest_band_accuracy_is_monotone_in_the_bands_the_fixture_uses() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.COLLEGE, DISTRIBUTION_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	var judged: Array[int] = []
	for band in range(ContestBand.COUNT):
		if totals.contest_attempts[band] >= MINIMUM_BAND_ATTEMPTS:
			judged.append(band)
	assert_int(judged.size()).override_failure_message(
		"fewer than three contest bands reached %d attempts, so this test would "
		% MINIMUM_BAND_ATTEMPTS
		+ "pass without checking an ordering").is_greater_equal(3)

	for index in range(1, judged.size()):
		var tighter: int = judged[index]
		var looser: int = judged[index - 1]
		assert_float(totals.contest_percentage(tighter)).override_failure_message(
			"%s accuracy %.4f is not at or below %s accuracy %.4f" % [
				ContestBand.IDS[tighter], totals.contest_percentage(tighter),
				ContestBand.IDS[looser], totals.contest_percentage(looser)]
		).is_less_equal(totals.contest_percentage(looser) + BAND_ORDER_TOLERANCE)


## Every attempt lands in exactly one zone and exactly one band, so the shares
## on each axis sum to one.
func test_the_zone_and_contest_shares_each_sum_to_one() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.DEVELOPMENT, IDENTITY_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	var zone_share: float = 0.0
	for zone in range(ShotZone.COUNT):
		zone_share += totals.zone_share(zone)
	var contest_share: float = 0.0
	for band in range(ContestBand.COUNT):
		contest_share += totals.contest_share(band)
	assert_float(zone_share).is_equal_approx(1.0, TOLERANCE)
	assert_float(contest_share).is_equal_approx(1.0, TOLERANCE)


# --- 3. the capability contracts --------------------------------------------

## A better shooter makes more shots, with everything else held identical.
##
## Measured on the production path rather than asserted about the baseline
## table: two rosters identical except for the three shooting ratings, the same
## seeds, the same opponent shape. If this ever fails, no §14.1 field-goal
## verdict means anything, because the rating is not reaching the shot.
func test_shooter_capability_moves_make_probability() -> void:
	var weak: float = _uniform_field_goal_percentage(60, 40)
	var strong: float = _uniform_field_goal_percentage(60, 85)
	assert_float(strong).override_failure_message(
		"shooting ratings 40 and 85 produced %.4f and %.4f: the shooter's rating "
		% [weak, strong] + "is not reaching make resolution").is_greater(weak + 0.05)


## A better defender produces a tighter contest, with everything else identical.
##
## `SIMULATION_SPEC.md` §12.3 requires the contest to be built "from actual
## defensive positioning and capabilities". This measures the pressure the
## engine actually produced, through the diagnostic probe, rather than
## re-deriving the formula here — a second copy of the arithmetic would agree
## with itself and prove nothing.
func test_defender_capability_moves_contest_pressure() -> void:
	var weak: ShotTermAccumulator = _uniform_terms(60, {
		AttributeKey.Key.PERIMETER_DEFENSE: 40,
		AttributeKey.Key.INTERIOR_DEFENSE: 40,
	})
	var strong: ShotTermAccumulator = _uniform_terms(60, {
		AttributeKey.Key.PERIMETER_DEFENSE: 90,
		AttributeKey.Key.INTERIOR_DEFENSE: 90,
	})
	assert_float(strong.mean_defender_capability()).is_greater(
		weak.mean_defender_capability() + 0.05)
	assert_float(strong.mean_pressure()).override_failure_message(
		"defender ratings 40 and 90 produced mean contest pressure %.4f and %.4f"
		% [weak.mean_pressure(), strong.mean_pressure()]
	).is_greater(weak.mean_pressure() + 0.05)
	assert_float(strong.mean_contest_penalty()).is_greater(weak.mean_contest_penalty())


## The rating a capability describes survives the round trip into the §13.1
## baseline curve.
##
## `shot_baseline` takes a capability on the unit interval and maps it back to a
## rating with `ACTIVE_MINIMUM + capability * span`, which is the exact inverse
## of `Rating.normalized`. A drift between those two is a normalization defect
## that would show up as every low-rated population shooting at the wrong rate —
## one of the hypotheses the §14.1 field-goal diagnosis had to rule out, and the
## reason it is pinned here rather than left to inspection.
func test_rating_normalization_round_trips_through_the_baseline_curve() -> void:
	var balance := SimulationBalanceProfile.new()
	for rating: int in [Rating.ACTIVE_MINIMUM, 40, 55, 60, 66, 72, 78, 85, Rating.MAXIMUM]:
		var normalized: float = Rating.normalized(rating)
		var recovered: float = (
			float(Rating.ACTIVE_MINIMUM)
			+ normalized * float(Rating.MAXIMUM - Rating.ACTIVE_MINIMUM))
		assert_float(recovered).override_failure_message(
			"rating %d normalized to %.6f and recovered as %.6f"
			% [rating, normalized, recovered]).is_equal_approx(float(rating), 0.0001)

	# And the curve it feeds is monotone in that rating, in every zone.
	for zone in range(ShotZone.COUNT):
		var previous: float = -1.0
		for rating: int in [30, 45, 60, 75, 90, 99]:
			var baseline: float = balance.shot_baseline(
				zone, Rating.normalized(rating), false)
			assert_float(baseline).override_failure_message(
				"zone %s is not monotone in rating at %d" % [ShotZone.IDS[zone], rating]
			).is_greater_equal(previous)
			previous = baseline


## The calibration fixture builds the level ladder it says it builds.
##
## The §14.1 bands are certified against a population, and that population's
## shape is the roster ladder in `CompetitionCatalog`. A field-goal diagnosis
## that blames the shot model when the ladder has quietly moved would be
## chasing the wrong thing, so the ladder is pinned: five competitions, strictly
## increasing, at the documented spacing.
func test_the_roster_ladder_preserves_the_intended_rating_gap_between_levels() -> void:
	var previous: float = -1.0
	var means: PackedFloat64Array = PackedFloat64Array()
	for competition in CalibrationTargets.all_competitions():
		var team: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"home", 0, SimulationBalanceProfile.new(), 0.0)
		var total: float = 0.0
		var count: int = 0
		for player: PlayerMatchProfile in team.players:
			for key in range(AttributeKey.COUNT):
				total += float(player.attributes.get_rating(key))
				count += 1
		var mean: float = total / float(count)
		means.append(mean)
		assert_float(mean).override_failure_message(
			"competition %s has mean rating %.2f, which does not exceed the "
			% [CalibrationTargets.competition_id(competition), mean]
			+ "level below it").is_greater(previous)
		previous = mean
	assert_int(means.size()).is_equal(5)
	# The top-domestic end is the one §8.2 pins as a current-OVR median.
	assert_float(means[4]).is_between(74.0, 82.0)


# --- 4. the instrumentation contract ----------------------------------------

## The diagnostic probe cannot change what the engine does.
##
## This is the whole licence for reading the decomposed terms out of production
## rather than rebuilding them: the same seed must produce a byte-identical
## ledger whether a probe is attached or not. The comparison is the same
## canonical signature the golden fixtures use, so it covers the result, every
## event and every possession record.
func test_the_shot_probe_cannot_change_the_ledger() -> void:
	var input: MatchInput = CompetitionCatalog.match_for(
		CalibrationTargets.Competition.COLLEGE, SUITE_BASE, 0.5)

	ShotResolver.detach_probe()
	var without: String = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(SUITE_BASE + 1)).signature()

	var terms := ShotTermAccumulator.new()
	terms.attach()
	var with_probe: String = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(SUITE_BASE + 1)).signature()
	ShotResolver.detach_probe()

	assert_str(with_probe).override_failure_message(
		"attaching the diagnostic probe changed the ledger").is_equal(without)
	assert_int(terms.shots).override_failure_message(
		"the probe recorded no shots, so this test proved nothing").is_greater(0)
	assert_int(terms.contests).is_greater_equal(terms.shots)


## Production leaves the probe detached, and detaching is idempotent.
func test_the_probe_is_detached_by_default() -> void:
	ShotResolver.detach_probe()
	assert_bool(ShotResolver.probe.is_null()).is_true()
	ShotResolver.detach_probe()
	assert_bool(ShotResolver.probe.is_null()).is_true()


## A leaked probe is a no-op, not an error storm.
##
## The static field can outlive its attacher — a test aborted between attaching
## and detaching leaves it holding a `Callable` bound to an object that is then
## freed. `is_null` is false for such a `Callable`, so a guard written that way
## would call into freed memory on every shot in the process. This pins the
## `is_valid` guard instead: after the attacher is gone, a full game simulates
## cleanly and produces the identical ledger it produces with no probe at all.
func test_a_probe_whose_owner_was_freed_is_ignored() -> void:
	var input: MatchInput = CompetitionCatalog.match_for(
		CalibrationTargets.Competition.COLLEGE, SUITE_BASE, 0.5)

	ShotResolver.detach_probe()
	var clean: String = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(SUITE_BASE + 1)).signature()

	var doomed := ShotTermAccumulator.new()
	doomed.attach()
	assert_bool(ShotResolver.probe.is_null()).is_false()
	# Drop the only reference. The accumulator is RefCounted, so it is freed
	# here, and the static field is left holding a Callable bound to nothing.
	doomed = null
	assert_bool(ShotResolver.probe.is_null()).override_failure_message(
		"the leaked Callable reported itself as null, so this test would pass "
		+ "without exercising the guard it exists for").is_false()
	assert_bool(ShotResolver.probe.is_valid()).override_failure_message(
		"a Callable bound to a freed object still reports valid").is_false()

	var after_leak: String = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(SUITE_BASE + 1)).signature()
	assert_str(after_leak).override_failure_message(
		"a leaked probe changed the ledger").is_equal(clean)


## The published terms are the arithmetic the engine actually performed.
##
## The terms are reported as an attribution — they are meant to *sum* to the
## make probability — so the sum is checked rather than trusted. The only
## permitted difference is the §13.2 clamp, which the accumulator reports
## separately as a residual instead of hiding inside a plausible total.
func test_the_probe_terms_sum_to_the_probability_they_describe() -> void:
	var terms: ShotTermAccumulator = _uniform_terms(70, {})
	assert_int(terms.shots).is_greater(0)

	var summed: float = 0.0
	for value: float in terms.term_means().values():
		summed += value
	assert_float(summed + terms.term_residual()).override_failure_message(
		"terms summed to %.6f with residual %.6f against a mean probability of %.6f"
		% [summed, terms.term_residual(), terms.mean_probability()]
	).is_equal_approx(terms.mean_probability(), 0.0001)
	# On a fixture with no clamping the residual is not merely small, it is zero.
	if terms.clamped_share_value() == 0.0:
		assert_float(terms.term_residual()).is_equal_approx(0.0, 0.0001)


# --- 5. the interval a §14.1 field-goal verdict is read against --------------

## Field-goal percentage is published with a clustered ratio interval, not a
## binomial one.
##
## The two differ by enough to change a verdict's reading: attempts inside one
## team-game share a roster, an opponent and a fatigue path, so they are not
## independent trials. This pins the estimator against a hand-computed value on
## a series whose answer is known by construction, so a future simplification
## back to a binomial cannot pass quietly.
func test_the_field_goal_interval_is_a_ratio_estimator() -> void:
	var made := PackedFloat64Array([10.0, 20.0, 30.0, 40.0])
	var attempted := PackedFloat64Array([20.0, 40.0, 60.0, 80.0])
	# Every cluster has exactly the same ratio, so the ratio estimator's
	# residuals are all zero and the interval must collapse — a binomial
	# interval over 200 attempts could not.
	assert_float(MatchMetricAccumulator.ratio_half_width(made, attempted, 0.5)
		).override_failure_message(
			"a series with identical per-cluster ratios did not produce a zero "
			+ "half-width, so this is not a ratio estimator").is_equal_approx(
			0.0, TOLERANCE)

	# A series with spread produces the linearized ratio variance.
	var spread_made := PackedFloat64Array([5.0, 20.0, 35.0, 40.0])
	var estimate: float = 100.0 / 200.0
	var expected: float = _hand_computed_ratio_half_width(
		spread_made, attempted, estimate)
	assert_float(MatchMetricAccumulator.ratio_half_width(
		spread_made, attempted, estimate)).is_equal_approx(expected, TOLERANCE)
	assert_float(expected).is_greater(0.0)


## The interval the *report* publishes is the ratio estimator, not merely the
## helper next to it.
##
## The previous version of this suite tested `ratio_half_width` directly and a
## mutation replaced the body of `field_goal_percentage_half_width` with a
## binomial formula — the helper's own tests still passed, because nothing
## asserted that the published interval went through it. This builds an
## accumulator whose per-team-game ratios are identical by construction, where
## the ratio estimator must return exactly zero and a binomial interval over the
## same attempts cannot.
func test_the_published_field_goal_interval_goes_through_the_ratio_estimator() -> void:
	var accumulator := MatchMetricAccumulator.new()
	accumulator.field_goals_made = 100
	accumulator.field_goals_attempted = 200
	accumulator.team_game_field_goals_made = PackedFloat64Array([10.0, 20.0, 30.0, 40.0])
	accumulator.team_game_field_goals_attempted = PackedFloat64Array(
		[20.0, 40.0, 60.0, 80.0])

	var binomial: float = 1.96 * sqrt(0.5 * 0.5 / 200.0)
	assert_float(binomial).is_greater(0.05)
	assert_float(accumulator.field_goal_percentage_half_width()).override_failure_message(
		"the published field-goal interval is %.6f on a series whose per-team-game "
		% accumulator.field_goal_percentage_half_width()
		+ "ratios are all identical; a ratio estimator returns zero here and a "
		+ "binomial interval returns %.6f" % binomial).is_equal_approx(0.0, TOLERANCE)


## The estimator refuses a series it cannot form an interval from, rather than
## returning a confident-looking zero on one observation.
func test_the_ratio_estimator_refuses_an_unusable_series() -> void:
	assert_float(MatchMetricAccumulator.ratio_half_width(
		PackedFloat64Array([1.0]), PackedFloat64Array([2.0]), 0.5)).is_equal(0.0)
	assert_float(MatchMetricAccumulator.ratio_half_width(
		PackedFloat64Array([1.0, 2.0]), PackedFloat64Array([0.0, 0.0]), 0.5)).is_equal(0.0)
	assert_float(MatchMetricAccumulator.ratio_half_width(
		PackedFloat64Array([1.0, 2.0]), PackedFloat64Array([2.0]), 0.5)).is_equal(0.0)


# --- 6. compensation channels ------------------------------------------------

## Shot resolution reaches make probability through shooting terms only.
##
## §14.1's field-goal row must not be reachable by moving turnovers, rebounds,
## assists or pace: those are separate bands, and a field-goal percentage
## "corrected" by trading against them would pass one row by breaking the
## meaning of four others. The contest and make paths are read here and required
## to contain no such term.
func test_shot_resolution_has_no_compensation_channel() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://src/domain/basketball/simulation/shot_resolver.gd")
	assert_str(source).is_not_empty()
	var body: String = source.to_lower()
	for forbidden: String in [
		"turnover", "rebound", "assist", "pace_multiplier",
		"home_score", "away_score", "score_margin", "competition",
	]:
		assert_bool(body.contains(forbidden)).override_failure_message(
			"shot resolution mentions '%s'; a shooting probability must not be "
			% forbidden + "reachable through a compensation channel"
		).is_false()


## Shot resolution cannot name a competition, by identity or by rule profile.
##
## Kept separate from the compensation guard above because it fails for a
## different reason, and because the token list is the whole test: a mutation
## battery put a high-school-only and a college-only scoring bonus into
## `resolve`, and both survived a guard that searched for `competition_id` and
## `CalibrationTargets` while the mutant reached the same place through
## `context.input.rule_profile.profile_id`. Every route to a per-league branch
## is named here, including each competition's own id string, because the point
## is not that one spelling is forbidden — it is that shot resolution has no
## business knowing which league it is in at all.
func test_shot_resolution_cannot_name_a_competition() -> void:
	var body: String = FileAccess.get_file_as_string(
		"res://src/domain/basketball/simulation/shot_resolver.gd").to_lower()
	assert_str(body).is_not_empty()
	for forbidden: String in [
		"rule_profile", "profile_id", "calibrationtargets", "competitioncatalog",
		"high_school", "college", "domestic_development", "overseas",
		"top_domestic",
	]:
		assert_bool(body.contains(forbidden)).override_failure_message(
			"shot resolution mentions '%s'; §12 shot resolution is shared by "
			% forbidden
			+ "every competition and must not be able to tell them apart"
		).is_false()


## No part of shot resolution can see the score.
##
## `test_ppp_decomposition.gd` already forbids the scoreboard inside
## `build_contest`. This covers the *whole* file, make resolution included, and
## it covers the route rather than one spelling of it: a mutation reached the
## score as `context.state.home.score`, which contains neither `home_score` nor
## `away_score` and walked past a scan looking for those two tokens. The team
## states are the route, so the team states are what is banned.
##
## A make probability that could see the score is a comeback mechanism, whatever
## it is called in the diff.
func test_make_resolution_cannot_see_the_scoreboard() -> void:
	var body: String = FileAccess.get_file_as_string(
		"res://src/domain/basketball/simulation/shot_resolver.gd").to_lower()
	assert_str(body).is_not_empty()
	for forbidden: String in [
		"home_score", "away_score", "score_margin", "margin",
		"state.home", "state.away", ".score",
	]:
		assert_bool(body.contains(forbidden)).override_failure_message(
			"shot resolution mentions '%s'; §12 make resolution must be blind to "
			% forbidden + "the scoreboard"
		).is_false()


## The §13.1 shot profile every competition shoots against is one shared object.
##
## The source scan above catches the spellings it knows; this catches the shape
## whatever the spelling. `SimulationBalanceProfile.shot_baseline` takes a zone,
## a capability and a dunk flag — there is no argument through which a
## competition could reach it — and every competition is handed the *same*
## profile instance's values. So a fixed (zone, capability) pair has exactly one
## baseline in this engine, and a fixed contest band has exactly one penalty.
##
## Deliberately *not* written as "the mean baseline is equal across
## competitions". It is not, and it should not be: rule profiles set period
## length, shot clock and pace, so different competitions take different shots
## and average over a different set. An earlier version of this test asserted
## that equality, and the 0.005 spread it found was the shot mix doing exactly
## what §4 says a rule profile may do — a false alarm dressed as a defect.
func test_every_competition_shoots_against_one_shared_shot_profile() -> void:
	var profiles: Array[SimulationBalanceProfile] = []
	for competition in CalibrationTargets.all_competitions():
		var input: MatchInput = CompetitionCatalog.match_for(competition, SUITE_BASE, 0.5)
		profiles.append(input.balance_profile)
		assert_str(String(input.rule_profile.profile_id)).is_equal(
			String(CompetitionCatalog.rules_for(competition).profile_id))

	assert_int(profiles.size()).is_equal(5)
	for index in range(1, profiles.size()):
		assert_str(String(profiles[index].profile_id)).override_failure_message(
			"competitions do not share one balance profile identity"
		).is_equal(String(profiles[0].profile_id))
		for zone in range(ShotZone.COUNT):
			for capability: float in [0.2, 0.5, 0.8]:
				assert_float(profiles[index].shot_baseline(zone, capability, false)
					).override_failure_message(
						"zone %s at capability %.1f has a different §13.1 baseline "
						% [ShotZone.IDS[zone], capability]
						+ "in one competition than another"
					).is_equal_approx(
						profiles[0].shot_baseline(zone, capability, false), TOLERANCE)
		for band in range(ContestBand.COUNT):
			assert_float(profiles[index].contest_penalty(band)).override_failure_message(
				"contest band %s carries a different penalty in one competition"
				% ContestBand.IDS[band]
			).is_equal_approx(profiles[0].contest_penalty(band), TOLERANCE)


# --- 7. the compensation channels are pinned --------------------------------

## Turnovers, offensive rebounding, assists and pace are pinned on a fixed
## fixture.
##
## §14.1 gives each of these its own band, and a field-goal or points change
## paid for by quietly moving one of them would pass the row it was aimed at
## while making four others mean something different. A band assertion is too
## loose to catch that — a mutation battery lifted the unforced-turnover base by
## 0.05 and the offensive-rebound base by 0.04 and both stayed inside their
## §14.1 bands — so these are pinned to the values this fixture actually
## produces, at a tolerance far tighter than any band.
##
## This test is *supposed* to fail when one of these channels moves. That is
## not a reason to widen the tolerance: it is a reason to say in the change
## which channel moved and why it was not compensation.
func test_the_compensation_channels_are_pinned_on_a_fixed_fixture() -> void:
	var decomposition: PppDecomposition = _decompose(
		CalibrationTargets.Competition.COLLEGE, DISTRIBUTION_GAMES)
	var totals: PppDecomposition.Totals = decomposition.totals

	assert_float(totals.turnover_rate()).override_failure_message(
		"turnover rate moved to %.4f on a fixed fixture" % totals.turnover_rate()
	).is_equal_approx(0.1465, CHANNEL_TOLERANCE)
	assert_float(totals.extension_rate()).override_failure_message(
		"offensive-rebound extension rate moved to %.4f on a fixed fixture"
		% totals.extension_rate()).is_equal_approx(0.1179, CHANNEL_TOLERANCE)
	assert_float(totals.offensive_rebound_rate()).override_failure_message(
		"offensive-rebound share moved to %.4f on a fixed fixture"
		% totals.offensive_rebound_rate()).is_equal_approx(0.2376, CHANNEL_TOLERANCE)
	# **Four of the five pins move under `simulation-v14-restart-contract` and
	# §5.32's pace re-derivation, and they are re-pinned rather than absorbed into
	# a wider tolerance — which is what this test is for.**
	#
	# Assisted share: 0.6387 -> 0.6571 (v13) -> 0.6642 (v14) -> **0.6449** (pace).
	# Turnover rate 0.1510 -> 0.1465, offensive-rebound share 0.2445 -> 0.2376,
	# possessions per game 144.58 -> 148.33 -> 144.17. Only the offensive-rebound
	# *extension* rate is unmoved.
	#
	# The cause is one thing, and it is not compensation. Every one of these
	# channels is a function of the action mix, and the action mix reads the game
	# clock through §10.3's score-and-clock factor
	# (`GameManagement.remaining_ms`) and the shot clock. The clock contracts
	# changed what a possession begins on and the pace re-derivation made a
	# possession about 4% longer, so the mix shifts. **No turnover, rebound or
	# assist parameter was touched** — the only production values §5.32 writes are
	# the five `pace_multiplier` numbers.
	#
	# The population measurement is the check that this is a fixture-scale shift
	# rather than a channel being paid off: on the matched 200-game cell across
	# all five competitions, turnover rate, offensive-rebound percentage and
	# assist percentage every one stay **inside their §14.1 bands** and move by
	# about one interval half-width or less (`PROJECT_STATUS.md` §5.32).
	assert_float(totals.assisted_share()).override_failure_message(
		"assisted share moved to %.4f on a fixed fixture" % totals.assisted_share()
	).is_equal_approx(0.6449, CHANNEL_TOLERANCE)
	assert_float(totals.possessions_per_game()).override_failure_message(
		"possessions per game moved to %.2f on a fixed fixture"
		% totals.possessions_per_game()).is_equal_approx(144.17, 2.0)


# --- helpers -----------------------------------------------------------------

## Field-goal percentage for two identical rosters at one base rating, with the
## three shooting ratings overridden on both benches.
func _uniform_field_goal_percentage(base_rating: int, shooting: int) -> float:
	var terms: ShotTermAccumulator = _uniform_terms(base_rating, {
		AttributeKey.Key.SHORT_RANGE: shooting,
		AttributeKey.Key.MID_RANGE: shooting,
		AttributeKey.Key.THREE_POINT: shooting,
	})
	return terms.realized_percentage()


## Runs a small uniform-roster fixture with the probe attached and returns the
## terms. Both benches carry the overrides, so the manipulated rating is the
## only thing that differs between two calls.
func _uniform_terms(base_rating: int, overrides: Dictionary) -> ShotTermAccumulator:
	return _uniform_terms_under(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO, base_rating, overrides)


## The same uniform fixture under a named competition's rule profile.
##
## The match id deliberately does not carry the competition, because
## `MatchSession` derives each possession's random stream from it: a per-league
## match id would give each competition a different draw sequence and would make
## the cross-competition comparison above compare seeds rather than rules.
func _uniform_terms_under(
	competition: int,
	base_rating: int,
	overrides: Dictionary,
) -> ShotTermAccumulator:
	var terms := ShotTermAccumulator.new()
	terms.attach()
	for index in range(4):
		var variation: int = SUITE_BASE + 500 + index
		var balance := SimulationBalanceProfile.new()
		var home: TeamMatchProfile = CompetitionCatalog.uniform_team(
			&"home", base_rating, overrides, balance)
		var away: TeamMatchProfile = CompetitionCatalog.uniform_team(
			&"away", base_rating, overrides, balance)
		var input := MatchInput.new(
			StringName("fg_uniform_%d" % variation),
			StringName("fg_uniform_game_%d" % variation),
			CompetitionCatalog.rules_for(competition),
			balance, home, away, home.team_id,
			CompetitionCatalog.ratings_profile(), 0.5)
		MatchEngine.new().simulate_match(input, SeededRandomSource.new(variation + 1))
	ShotResolver.detach_probe()
	return terms


## The linearized ratio half-width, written out longhand so the assertion above
## is checked against arithmetic and not against the implementation it is
## testing.
func _hand_computed_ratio_half_width(
	numerators: PackedFloat64Array,
	denominators: PackedFloat64Array,
	estimate: float,
) -> float:
	var count: int = denominators.size()
	var mean_denominator: float = 0.0
	for value in denominators:
		mean_denominator += value
	mean_denominator /= float(count)
	var residual_sum: float = 0.0
	for index in range(count):
		var residual: float = numerators[index] - estimate * denominators[index]
		residual_sum += residual * residual
	var variance: float = residual_sum / float(count - 1)
	return 1.96 * sqrt(variance / float(count)) / mean_denominator
