extends SceneTree

## Roster provenance and representativeness audit (Stage 4 owner decision).
##
## §5.22 ruled the college §14.1 field-goal shortfall a *fixture roster
## construction* matter rather than an engine defect, and left an owner decision
## open between the fixture's roster ladder and §14.1's band ladder. That ruling
## rests on a claim nobody had published: that the calibration fixture is or is
## not what a production-built college roster looks like. This runner publishes
## the evidence for that claim and judges no band.
##
## Two populations are described in identical terms so they can be compared:
##
## - `fixture` — the rosters `CompetitionCatalog.team_for` builds, which is what
##   every competition, decomposition, counterfactual and smoke runner has ever
##   measured. Reported for all five competitions.
##
## - `builder` — players produced by the **production** creation and development
##   contract (`BuilderService` + `DevelopmentService`, both under `src/`), run
##   forward through the §9.5 COLLEGE seasons by `CareerSimulator` and snapshotted
##   at each college class year.
##
## The second is a **player** population and never a roster population. Nothing
## under `src/` constructs a `TeamMatchProfile` or a `PlayerMatchProfile`: the
## production system consumes rosters and does not generate them. That absence is
## itself a published finding here rather than something worked around, and it is
## why this runner does not claim to measure "production college rosters".
##
## Nothing here changes a production value, consumes a match random stream, or
## tunes anything. It reads constructors and reports what they produce.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_roster_provenance.gd -- \
##       [--mode=fixture|builder|both] [--teams=N] [--careers=N] [--base=SEED_BASE] \
##       [--label=NAME]

const DEFAULT_TEAMS: int = 200
const DEFAULT_CAREERS: int = 1000
## Fresh seed base. Every range at or below 970,399 is spoken for by an earlier
## diagnosis, tuning, validation or regression run; ranges at or above 1,000,000
## are reserved for tuning probes.
const DEFAULT_BASE: int = 1200001
const PROGRESS_EVERY: int = 50

## Attribute groups §14.1 and the owner decision actually argue about, so the
## report carries them as named rows rather than leaving a reader to average
## twenty numbers by hand.
const _SHOOTING_ZONE_KEYS: PackedInt32Array = [
	AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.MID_RANGE, AttributeKey.Key.THREE_POINT,
]
const _DEFENSIVE_KEYS: PackedInt32Array = [
	AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.INTERIOR_DEFENSE,
	AttributeKey.Key.STEALING, AttributeKey.Key.BLOCKING, AttributeKey.Key.DEFENSIVE_IQ,
]


## One player, reduced to the numbers both populations can be described by.
class Observation extends RefCounted:
	var values: Array[int]
	var overall: int
	var height: int
	var wingspan: int
	var reach: int
	var position: String
	var archetype: String
	var is_starter: bool
	var age: int
	var class_year: int


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var mode: String = CalibrationCli.string_option(options, &"mode", "both")
	var teams: int = CalibrationCli.int_option(options, &"teams", DEFAULT_TEAMS)
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var base: int = CalibrationCli.int_option(options, &"base", DEFAULT_BASE)
	var label: String = CalibrationCli.string_option(options, &"label", mode)

	var context := ReportContext.create(
		&"roster_provenance",
		"Roster provenance: what the calibration fixture is, and what the production builder makes",
		CompetitionCatalog.rules_for(CalibrationTargets.Competition.COLLEGE),
		CompetitionCatalog.balance_profile(),
		SeededRandomSource.new(1).get_version())
	context.sample_unit = "players"
	context.seed_description = "fixture variations 0..%d; career seeds %d..%d" % [
		teams * 2 - 1, base, base + careers - 1]
	context.notes.append(
		"Describes populations. Judges no §14.1 band and changes no production value.")
	context.notes.append(
		"Nothing under src/ constructs a TeamMatchProfile or a PlayerMatchProfile. "
		+ "The 'builder' population is therefore a player population, not a roster "
		+ "population, and no production college roster exists to sample.")

	var report := CalibrationReport.new(context)
	var sections: Array[Dictionary] = []

	if mode == "fixture" or mode == "both":
		for competition in CalibrationTargets.all_competitions():
			var id: String = String(CalibrationTargets.competition_id(competition))
			print("fixture %s: %d teams..." % [id, teams])
			var observations: Array[Observation] = _fixture_population(competition, teams)
			sections.append(_describe(
				"fixture.%s" % id, observations, report, _fixture_team_strength(competition, teams)))

	if mode == "builder" or mode == "both":
		print("builder college-age population: %d careers..." % careers)
		var builder_observations: Array[Observation] = _builder_population(careers, base)
		if builder_observations.is_empty():
			report.add_metric(CalibrationMetric.boolean(
				&"builder.population_reachable",
				"The production creation/development contract produced college-age players.",
				false, "careers", careers))
		else:
			sections.append(_describe(
				"builder.college", builder_observations, report, PackedFloat64Array()))
			report.add_metric(CalibrationMetric.boolean(
				&"builder.population_reachable",
				"The production creation/development contract produced college-age players.",
				true, "careers", careers))

	# The structural finding this whole report exists to record. It is a boolean
	# because it is not a matter of degree: either production can build a college
	# roster or it cannot, and today it cannot.
	# Reported rather than judged. It is a structural fact about what the codebase
	# contains, not a band a run can drift out of, and a judged metric that is
	# designed to fail reads as a regression to everyone who did not write it.
	report.add_metric(CalibrationMetric.raw(
		&"production.college_roster_constructors",
		"Paths under src/ that construct a college TeamMatchProfile or "
		+ "PlayerMatchProfile. Structural, not statistical: no roster generator, "
		+ "team assembly, or college tier system exists, so the calibration "
		+ "fixture has no production counterpart to be representative of.",
		"constructors under src/", 0.0, 0))

	report.add_section(&"populations", sections)
	report.finish()
	quit(ReportWriter.publish(report, "roster_provenance_%s" % label))


## The rosters every calibration runner has ever measured.
func _fixture_population(competition: int, teams: int) -> Array[Observation]:
	var observations: Array[Observation] = []
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var archetypes: ArchetypeProfile = ArchetypeProfile.default_profile()
	for variation in range(teams):
		var team: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"audit", variation, balance, 0.0)
		var starters: Array[StringName] = team.starters()
		for player in team.players:
			observations.append(_observe_match_profile(player, starters, archetypes))
	return observations


## Mean roster rating per fixture team, which is the between-team spread
## `TEAM_LEVEL_TILT` produces and the thing a "+N rating point" grid moves.
func _fixture_team_strength(competition: int, teams: int) -> PackedFloat64Array:
	var strengths := PackedFloat64Array()
	var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
	var ratings: RatingsProfile = CompetitionCatalog.ratings_profile()
	for variation in range(teams):
		var team: TeamMatchProfile = CompetitionCatalog.team_for(
			competition, &"audit", variation, balance, 0.0)
		var total: float = 0.0
		for player in team.players:
			total += float(OverallCalculator.current_overall(player.attributes, ratings))
		strengths.append(total / float(team.players.size()))
	return strengths


## Players the production creation and development contract actually produces,
## snapshotted at every §9.5 COLLEGE season.
func _builder_population(careers: int, base: int) -> Array[Observation]:
	var observations: Array[Observation] = []
	var simulator := CareerSimulator.new()
	simulator.capture_diagnostics = true
	var archetypes: ArchetypeProfile = ArchetypeProfile.default_profile()
	var ratings: RatingsProfile = CompetitionCatalog.ratings_profile()
	for index in range(careers):
		var seed_value: int = base + index
		var result: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR)
		for class_year in range(result.college_overall_by_class.size()):
			var raw: Array = result.college_values_by_class[class_year]
			var values: Array[int] = []
			for slot in range(raw.size()):
				var value: int = raw[slot]
				values.append(value)
			var observation := Observation.new()
			observation.values = values
			observation.overall = result.college_overall_by_class[class_year]
			observation.age = result.college_age_by_class[class_year]
			observation.class_year = class_year
			# The career model carries no match body or lineup slot: it produces a
			# player, not a roster place. Body and starter status are therefore
			# left unset rather than invented, and the report says so.
			observation.height = 0
			observation.wingspan = 0
			observation.reach = 0
			observation.position = PositionFamily.label_of(result.family)
			observation.is_starter = false
			observation.archetype = String(DerivedArchetype.classify(
				PlayerAttributes.from_values(values),
				BodyProfile.new(78, 210, 81, 0),
				result.family,
				archetypes).label())
			observations.append(observation)
		if careers > PROGRESS_EVERY and (index + 1) % PROGRESS_EVERY == 0:
			print("  builder: %d/%d careers (seeds %d-%d)" % [
				index + 1, careers, base, seed_value])
	# `ratings` is read so the two populations are known to share one profile.
	assert(ratings != null, "ratings profile must resolve")
	return observations


func _observe_match_profile(
	player: PlayerMatchProfile,
	starters: Array[StringName],
	archetypes: ArchetypeProfile,
) -> Observation:
	var observation := Observation.new()
	observation.values = player.attributes.canonical_values()
	observation.overall = OverallCalculator.current_overall(
		player.attributes, CompetitionCatalog.ratings_profile())
	observation.height = player.body.height_inches
	observation.wingspan = player.body.wingspan_inches
	observation.reach = player.body.standing_reach_inches
	observation.position = String(player.positions.primary)
	observation.is_starter = starters.has(player.player_id)
	# The fixture carries no age and no class year, which is one of the findings.
	observation.age = 0
	observation.class_year = -1
	observation.archetype = String(DerivedArchetype.classify(
		player.attributes,
		player.body,
		_family_for_slot_position(observation.position),
		archetypes).label())
	return observation


## Describes one population in the terms the owner decision needs, and adds the
## rows a reader compares directly across populations as report metrics.
func _describe(
	population_id: String,
	observations: Array[Observation],
	report: CalibrationReport,
	team_strength: PackedFloat64Array,
) -> Dictionary:
	var overalls := PackedFloat64Array()
	var starter_overalls := PackedFloat64Array()
	var bench_overalls := PackedFloat64Array()
	var heights := PackedFloat64Array()
	var reaches := PackedFloat64Array()
	var positions: Dictionary = {}
	var archetype_counts: Dictionary = {}
	var ages: Dictionary = {}
	var classes: Dictionary = {}
	for observation in observations:
		overalls.append(float(observation.overall))
		if observation.is_starter:
			starter_overalls.append(float(observation.overall))
		else:
			bench_overalls.append(float(observation.overall))
		if observation.height > 0:
			heights.append(float(observation.height))
			reaches.append(float(observation.reach))
		_bump(positions, observation.position)
		_bump(archetype_counts, observation.archetype)
		_bump(ages, observation.age)
		_bump(classes, observation.class_year)

	var attributes: Array[Dictionary] = []
	for key in range(AttributeKey.COUNT):
		var column := PackedFloat64Array()
		for observation in observations:
			column.append(float(observation.values[key]))
		attributes.append(_summary(String(AttributeKey.name_of(key)), column))

	var payload: Dictionary = {
		"population": population_id,
		"players": observations.size(),
		"overall": _summary("overall", overalls),
		"starter_overall": _summary("starter_overall", starter_overalls),
		"bench_overall": _summary("bench_overall", bench_overalls),
		"height_inches": _summary("height_inches", heights),
		"standing_reach_inches": _summary("standing_reach_inches", reaches),
		"team_strength": _summary("team_strength", team_strength),
		"shooting_by_zone": {
			"short_range": _mean_of_key(observations, AttributeKey.Key.SHORT_RANGE),
			"mid_range": _mean_of_key(observations, AttributeKey.Key.MID_RANGE),
			"three_point": _mean_of_key(observations, AttributeKey.Key.THREE_POINT),
			"free_throw": _mean_of_key(observations, AttributeKey.Key.FREE_THROW),
			"zone_mean": _mean_of_keys(observations, _SHOOTING_ZONE_KEYS),
		},
		"offensive_iq": _mean_of_key(observations, AttributeKey.Key.OFFENSIVE_IQ),
		"passing": _mean_of_key(observations, AttributeKey.Key.PASSING),
		"vision": _mean_of_key(observations, AttributeKey.Key.VISION),
		"stamina": _mean_of_key(observations, AttributeKey.Key.STAMINA),
		"defensive_mean": _mean_of_keys(observations, _DEFENSIVE_KEYS),
		"positions": positions,
		"archetypes": archetype_counts,
		"ages": ages,
		"class_years": classes,
		"attributes": attributes,
	}

	report.add_metric(CalibrationMetric.raw(
		StringName("%s.overall_mean" % population_id),
		"Mean current Overall across the population.", "players",
		CalibrationStatistics.mean(overalls), observations.size()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.overall_standard_deviation" % population_id),
		"Standard deviation of current Overall across the population.", "players",
		CalibrationStatistics.standard_deviation(overalls), observations.size()))
	report.add_metric(CalibrationMetric.raw(
		StringName("%s.shooting_zone_mean" % population_id),
		"Mean of short range, mid range and three point.", "players",
		_mean_of_keys(observations, _SHOOTING_ZONE_KEYS), observations.size()))
	print("  %s: %d players, OVR %.2f ±%.2f, shooting %.2f" % [
		population_id, observations.size(),
		CalibrationStatistics.mean(overalls),
		CalibrationStatistics.standard_deviation(overalls),
		_mean_of_keys(observations, _SHOOTING_ZONE_KEYS)])
	return payload


## The slot label the fixture stamps ("PG".."C"), mapped to the §7.1 starting
## family the archetype classifier expects. The fixture has no family of its
## own; this is a reporting convenience and nothing reads it back.
func _family_for_slot_position(position: String) -> int:
	match position:
		"PG", "SG":
			return PositionFamily.Value.GUARD
		"SF":
			return PositionFamily.Value.WING
		_:
			return PositionFamily.Value.BIG


## Counts one occurrence of `key`. A helper rather than an inline expression
## because `Dictionary.get` returns `Variant` and this project compiles under
## warnings-as-errors.
func _bump(counts: Dictionary, key: Variant) -> void:
	var current: int = counts[key] if counts.has(key) else 0
	counts[key] = current + 1


func _summary(name_value: String, values: PackedFloat64Array) -> Dictionary:
	if values.is_empty():
		return {"name": name_value, "count": 0}
	var sorted := values.duplicate()
	sorted.sort()
	return {
		"name": name_value,
		"count": values.size(),
		"mean": CalibrationStatistics.mean(values),
		"standard_deviation": CalibrationStatistics.standard_deviation(values),
		"minimum": sorted[0],
		"p10": CalibrationStatistics.percentile(sorted, 0.10),
		"p25": CalibrationStatistics.percentile(sorted, 0.25),
		"p50": CalibrationStatistics.percentile(sorted, 0.50),
		"p75": CalibrationStatistics.percentile(sorted, 0.75),
		"p90": CalibrationStatistics.percentile(sorted, 0.90),
		"maximum": sorted[sorted.size() - 1],
	}


func _mean_of_key(observations: Array[Observation], key: int) -> float:
	if observations.is_empty():
		return 0.0
	var total: float = 0.0
	for observation in observations:
		total += float(observation.values[key])
	return total / float(observations.size())


func _mean_of_keys(observations: Array[Observation], keys: PackedInt32Array) -> float:
	if observations.is_empty() or keys.is_empty():
		return 0.0
	var total: float = 0.0
	for observation in observations:
		for key in keys:
			total += float(observation.values[key])
	return total / float(observations.size() * keys.size())
