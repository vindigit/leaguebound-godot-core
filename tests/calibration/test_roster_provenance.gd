class_name TestRosterProvenance
extends GdUnitTestSuite

## The contracts the Stage 4 owner-decision roster audit rests on.
##
## §5.22 ruled the college §14.1 field-goal shortfall a *fixture roster
## construction* matter and left an owner decision open. Answering it needed two
## populations described in the same terms — the calibration fixture, and what
## the production creation and development contract actually produces at college
## age — and the second needed a snapshot the career model did not previously
## take.
##
## Three kinds of assertion live here:
##
## - **The instrumentation contract.** The college snapshot is a measurement of
##   the career, and a measurement that changes the career is worthless. It must
##   be off by default, must consume no random draw, and a career must run
##   identically whether or not it is taken.
## - **The reconciliation contract.** The snapshot must agree with the record the
##   career already kept, and must land on the §9.5 COLLEGE seasons rather than
##   on whichever seasons happened to be captured.
## - **The structural finding.** Nothing under `src/` constructs a roster. That
##   is the load-bearing fact behind the whole ruling — it is why the fixture has
##   no production counterpart to be representative *of* — and it is pinned here
##   so it cannot stop being true without a test saying so.

## A seed range this suite owns, disjoint from every diagnosis, tuning and
## validation range recorded in `PROJECT_STATUS.md`.
const SUITE_SEED: int = 1250001

## Enough careers that the snapshot is exercised across several career paths
## without making the suite slow. Every one of them runs the full season loop.
const CAREER_SAMPLE: int = 12

const TOLERANCE: float = 0.0001


func _simulate(seed_value: int, diagnostics: bool) -> CareerSimulator.CareerResult:
	var simulator := CareerSimulator.new()
	simulator.capture_diagnostics = diagnostics
	return simulator.simulate(
		seed_value, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)


# --- 1. the instrumentation contract -----------------------------------------

## The snapshot is off unless a caller asks for it.
##
## `CareerSimulator.capture_diagnostics` gates every other diagnostic capture and
## now gates this one too. The certification run holds a million results in
## memory; a per-season attribute vector that recorded itself unasked would be
## twenty integers times three college seasons times a million careers of pure
## waste, and would do it silently.
func test_the_college_snapshot_is_not_taken_by_default() -> void:
	var simulator := CareerSimulator.new()
	assert_bool(simulator.capture_diagnostics).override_failure_message(
		"CareerSimulator must not capture diagnostics unless asked"
	).is_false()
	var result: CareerSimulator.CareerResult = simulator.simulate(
		SUITE_SEED, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)
	assert_int(result.college_values_by_class.size()).is_equal(0)
	assert_int(result.college_overall_by_class.size()).is_equal(0)
	assert_int(result.college_age_by_class.size()).is_equal(0)


## Taking the snapshot cannot change the career that was measured.
##
## This is the RNG assertion as well as the output one, and it is strictly
## stronger than counting draws. A career is a chain of seeded draws through
## seventeen to twenty-three seasons: one extra draw taken with diagnostics on
## would desynchronize the entire remainder of the stream, and every quantity
## below would move. That they are all identical at a fixed seed, across twelve
## careers covering several §8.4 paths, is what proves the snapshot consumes
## nothing and writes nothing back.
func test_taking_the_college_snapshot_changes_no_career_outcome() -> void:
	for index in range(CAREER_SAMPLE):
		var seed_value: int = SUITE_SEED + index
		var bare: CareerSimulator.CareerResult = _simulate(seed_value, false)
		var measured: CareerSimulator.CareerResult = _simulate(seed_value, true)
		var where: String = "career seed %d" % seed_value

		assert_int(measured.path).override_failure_message(where).is_equal(bare.path)
		assert_int(measured.seasons).override_failure_message(where).is_equal(bare.seasons)
		assert_int(measured.starting_overall).override_failure_message(
			where).is_equal(bare.starting_overall)
		assert_int(measured.peak_overall).override_failure_message(
			where).is_equal(bare.peak_overall)
		assert_int(measured.peak_age).override_failure_message(
			where).is_equal(bare.peak_age)
		assert_int(measured.final_overall).override_failure_message(
			where).is_equal(bare.final_overall)
		assert_int(measured.total_rating_points_gained).override_failure_message(
			where).is_equal(bare.total_rating_points_gained)
		assert_int(measured.guardrail_seasons).override_failure_message(
			where).is_equal(bare.guardrail_seasons)
		assert_float(measured.total_ap_granted).override_failure_message(
			where).is_equal_approx(bare.total_ap_granted, TOLERANCE)
		assert_float(measured.total_ap_spent).override_failure_message(
			where).is_equal_approx(bare.total_ap_spent, TOLERANCE)
		assert_float(measured.total_ap_unspent).override_failure_message(
			where).is_equal_approx(bare.total_ap_unspent, TOLERANCE)
		assert_float(measured.cap_attainment).override_failure_message(
			where).is_equal_approx(bare.cap_attainment, TOLERANCE)


## The snapshot is reproducible, which a measurement that captured live state by
## reference would not be.
##
## `canonical_values()` returns a copy. If it did not — if the snapshot held the
## player's own array — every class year would end up holding the *final*
## season's ratings, all three entries would be identical, and the college
## population would silently become a population of seniors.
func test_each_college_class_year_holds_its_own_ratings() -> void:
	var result: CareerSimulator.CareerResult = _simulate(SUITE_SEED, true)
	assert_int(result.college_values_by_class.size()).is_greater(1)
	var first: Array = result.college_values_by_class[0]
	var last: Array = result.college_values_by_class[
		result.college_values_by_class.size() - 1]
	var moved: bool = false
	for key in range(AttributeKey.COUNT):
		var early: int = first[key]
		var late: int = last[key]
		if early != late:
			moved = true
	assert_bool(moved).override_failure_message(
		"every college class year holds an identical rating vector; the snapshot "
		+ "is aliasing live player state instead of copying it"
	).is_true()


# --- 2. the reconciliation contract ------------------------------------------

## The snapshot lands on the §9.5 COLLEGE seasons and on no others.
##
## The career phase table is what decides which seasons are college seasons, so
## the count is asserted against that table rather than against a remembered
## number. A path shorter than the college block contributes fewer class years,
## which is why this counts rather than assuming three.
func test_the_snapshot_covers_exactly_the_college_seasons() -> void:
	for index in range(CAREER_SAMPLE):
		var seed_value: int = SUITE_SEED + index
		var result: CareerSimulator.CareerResult = _simulate(seed_value, true)
		var expected: int = 0
		for season in range(result.seasons):
			var phase: int = CareerSimulator.PHASE_BY_SEASON[
				mini(season, CareerSimulator.PHASE_BY_SEASON.size() - 1)]
			if phase == CareerPhase.Value.COLLEGE:
				expected += 1
		assert_int(result.college_overall_by_class.size()).override_failure_message(
			"career seed %d captured %d college class years against %d §9.5 "
				% [seed_value, result.college_overall_by_class.size(), expected]
			+ "COLLEGE seasons"
		).is_equal(expected)
		assert_int(result.college_values_by_class.size()).is_equal(expected)
		assert_int(result.college_age_by_class.size()).is_equal(expected)


## The snapshot agrees with the record the career already kept.
##
## `overall_by_season` is written on a different line from a different variable,
## so this is a real cross-check rather than a restatement: the college Overall
## at class year `c` must equal the season Overall at the season that class year
## occupies, and it must equal the Overall the captured rating vector computes
## to. Three independent arms, all required to agree.
func test_the_college_snapshot_reconciles_with_the_season_record() -> void:
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	for index in range(CAREER_SAMPLE):
		var seed_value: int = SUITE_SEED + index
		var result: CareerSimulator.CareerResult = _simulate(seed_value, true)
		var class_year: int = 0
		for season in range(result.seasons):
			var phase: int = CareerSimulator.PHASE_BY_SEASON[
				mini(season, CareerSimulator.PHASE_BY_SEASON.size() - 1)]
			if phase != CareerPhase.Value.COLLEGE:
				continue
			var where: String = "career seed %d, college class year %d" % [
				seed_value, class_year]
			assert_int(result.college_overall_by_class[class_year]).override_failure_message(
				where + ": snapshot Overall disagrees with overall_by_season"
			).is_equal(result.overall_by_season[season])
			assert_int(result.college_age_by_class[class_year]).override_failure_message(
				where + ": snapshot age disagrees with age_by_season"
			).is_equal(result.age_by_season[season])

			var raw: Array = result.college_values_by_class[class_year]
			var values: Array[int] = []
			for slot in range(raw.size()):
				var value: int = raw[slot]
				values.append(value)
			assert_int(OverallCalculator.current_overall(
				PlayerAttributes.from_values(values), ratings)
			).override_failure_message(
				where + ": the captured rating vector does not compute to the "
				+ "Overall recorded beside it"
			).is_equal(result.overall_by_season[season])
			class_year += 1


# --- 3. the structural finding -----------------------------------------------

## Nothing under `src/` builds a roster or a player profile.
##
## This is the fact the whole owner decision turns on. The production system
## *consumes* a `MatchInput` and never constructs one: there is no roster
## generator, no team assembly, and no college tier system, so the calibration
## fixture is not an approximation of a production roster — it is the only
## college roster that exists.
##
## Pinned as a test rather than left as a sentence in a document because the
## ruling stops being true the moment somebody adds a generator, and the owner
## package would then be quoting a fact the codebase had moved past.
func test_production_constructs_no_roster_and_no_player_profile() -> void:
	var offences := PackedStringArray()
	_scan("res://src", offences)
	assert_int(offences.size()).override_failure_message(
		"src/ now constructs a roster or player profile at:\n  %s\n"
			% "\n  ".join(offences)
		+ "The Stage 4 owner-decision package rules on the basis that production "
		+ "generates no rosters. If that has changed, the fixture now has a "
		+ "production counterpart and the representativeness question must be "
		+ "re-measured against it rather than re-asserted."
	).is_equal(0)


## The fixture ladder is a single scalar per player fanned out through a fixed
## per-slot offset table, and every college player's ratings are that scalar.
##
## This is what "hard-coded linear ladder" means as a measurable claim rather
## than a description: move one player's level by one point and every one of his
## twenty ratings moves by exactly one point. A fixture with archetype variance,
## correlated attributes, or a distribution of any kind would fail this.
func test_the_fixture_roster_is_one_scalar_per_player() -> void:
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var competition: int = CalibrationTargets.Competition.COLLEGE
	var base: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"probe", 0, balance, 0.0)
	var lifted: TeamMatchProfile = CompetitionCatalog.team_for(
		competition, &"probe", 0, balance, 1.0)
	assert_int(base.players.size()).is_equal(lifted.players.size())
	for index in range(base.players.size()):
		for key in range(AttributeKey.COUNT):
			var before: int = base.players[index].attributes.get_rating(key)
			var after: int = lifted.players[index].attributes.get_rating(key)
			# Clamped ratings are permitted to move less; nothing else is.
			if before <= Rating.ACTIVE_MINIMUM or after >= Rating.MAXIMUM:
				continue
			assert_int(after - before).override_failure_message(
				"player %d rating %s moved by %d for a +1 roster level; the "
					% [index, AttributeKey.name_of(key), after - before]
				+ "fixture is meant to be one scalar per player"
			).is_equal(1)


func _scan(path: String, offences: PackedStringArray) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var full: String = "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_scan(full, offences)
		elif entry.ends_with(".gd"):
			_inspect(full, offences)
		entry = directory.get_next()
	directory.list_dir_end()


func _inspect(path: String, offences: PackedStringArray) -> void:
	var source: String = FileAccess.get_file_as_string(path)
	var lines: PackedStringArray = source.split("\n")
	for index in range(lines.size()):
		var trimmed: String = lines[index].strip_edges()
		# A comment may discuss rosters; only construction counts.
		if trimmed.begins_with("#"):
			continue
		for symbol: String in ["TeamMatchProfile.new(", "PlayerMatchProfile.new("]:
			if trimmed.contains(symbol):
				offences.append("%s:%d: %s" % [path, index + 1, trimmed])
