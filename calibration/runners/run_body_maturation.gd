extends SceneTree

## Body maturation report (`BALANCE_SPEC.md` §31 report 15, §7.4 OD-C, Gate B3).
##
## Gate B3 states the requirement exactly: "every realized adult body falls
## inside its stored projected range, growth is reproducible from the career
## seed, no body increment alters a rating as a side effect, and Early/Average/
## Late produce materially different realized high-school bodies".
##
## Three of those four are **structural invariants** (§7.4.2, §7.4.3), not bands
## with tolerances, so they are measured as shares that must be exactly 1.0. A
## single violation anywhere in the sample fails the report.
##
## ## Why the timing comparison is paired
##
## §7.4.2 asks whether the *maturity choice* changes the realized high-school
## body. Comparing an Early cohort against a Late cohort answers a weaker
## question, because the two cohorts also differ in every other drawn quantity.
## Each seed here therefore builds the same prospect three times — identical
## family, prospect profile, freshman body, caps, and drawn adult body — varying
## only the timing profile. The difference is then a per-seed paired observation,
## which isolates the timing effect and, being one number per unit, pools across
## shards exactly as a mean. An unpaired difference of two cohort means does not
## pool: summing shard numerators and denominators does not reconstruct it.
##
## The pairing also makes "neither timing is strictly better" (`GDD.md` §6.5)
## checkable as an exact identity rather than a tolerance, because the three
## runs share a drawn adult body and must therefore end on it.
##
## ## Why this is affordable at scale
##
## Body maturation resolves six increments and simulates no matches and no
## attribute allocation, so it runs far faster than the progression report. The
## §27.1 progression sample is a realistic target here even though it is not for
## the career report.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_body_maturation.gd -- \
##       [--careers=N] [--shard=I --shards=N] [--label=NAME]

const DEFAULT_CAREERS: int = 20000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var shards: int = maxi(1, CalibrationCli.int_option(options, &"shards", 1))
	var label: String = CalibrationCli.string_option(options, &"label", "body")

	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var configuration: PackedStringArray = profiles.validate()
	var context := ReportContext.create(
		&"body_maturation",
		"Body maturation report (report 15)",
		null, null, SeededRandomSource.new(1).get_version())
	context.balance_profile_id = &"builder"
	context.balance_profile_version = profiles.builder.version
	context.sample_count = careers
	context.sample_unit = "matched maturity triples"
	context.set_shard(shard, shards, shard * careers + 1, shard * careers + careers)
	context.require_certification_sample(
		CalibrationTargets.REQUIRED_CAREERS, CalibrationTargets.sample_size_source())
	context.notes.append((
		"§27.1 names no separate body sample. Report 15 is a Gate B3 progression "
		+ "report, so it is held to the progression requirement of %d; this run "
		+ "used %d triples (%d individual maturations)."
	) % [CalibrationTargets.REQUIRED_CAREERS, careers,
		careers * MaturityProfile.COUNT])
	context.notes.append(
		"Containment, determinism, and the absence of rating, cap, and currency "
		+ "side effects are structural invariants (§7.4.2, §7.4.3). Their target "
		+ "is exactly 1.0, so one violation in the sample fails the report.")
	context.notes.append(
		"Each triple varies only the maturity profile; family, prospect profile, "
		+ "freshman body, caps, and the drawn adult body are held identical.")

	var report := CalibrationReport.new(context)
	report.add_metric(CalibrationMetric.boolean(
		&"configuration.valid",
		"Gate B0: the balance profile set validates offline.",
		configuration.is_empty(), "BALANCE_SPEC.md §30 Gate B0"))
	report.add_metric(CalibrationMetric.boolean(
		&"sample.meets_certification_size",
		"Whether this run reached the §27.1 sample size for a certifying report.",
		careers >= CalibrationTargets.REQUIRED_CAREERS,
		CalibrationTargets.sample_size_source(), careers))

	_measure(report, profiles, careers, shard)
	report.finish()
	quit(ReportWriter.publish(report, "body_maturation_%s" % label))


## One maturity profile's or one position family's accumulated observations.
class Group extends RefCounted:
	var count: int = 0
	var high_school_share := PackedFloat64Array()
	var freshman_height := PackedFloat64Array()
	var adult_height := PackedFloat64Array()
	var adult_weight := PackedFloat64Array()
	var adult_wingspan := PackedFloat64Array()
	var adult_reach := PackedFloat64Array()
	var total_height_growth := PackedFloat64Array()

	func observe(
		share: float,
		freshman: BodyProfile,
		adult: BodyProfile,
	) -> void:
		count += 1
		high_school_share.append(share)
		freshman_height.append(float(freshman.height_inches))
		adult_height.append(float(adult.height_inches))
		adult_weight.append(float(adult.weight_pounds))
		adult_wingspan.append(float(adult.wingspan_inches))
		adult_reach.append(float(adult.standing_reach_inches))
		total_height_growth.append(float(adult.height_inches - freshman.height_inches))


## Everything one resolved maturation contributes.
class Maturation extends RefCounted:
	var adult: BodyProfile
	var freshman: BodyProfile
	var high_school_share: float = 0.0
	var contained: bool = false
	var intermediate_legal: bool = false
	var monotone: bool = false
	var deterministic: bool = false
	var idempotent: bool = false
	var increments_exact: bool = false
	var ratings_unchanged: bool = false
	var caps_unchanged: bool = false
	var currency_unchanged: bool = false
	var plausible: bool = false
	var range_matches_profile: bool = false


func _measure(
	report: CalibrationReport,
	profiles: BalanceProfileSet,
	careers: int,
	shard: int,
) -> void:
	var builder := BuilderService.new(profiles)
	var body_service := BodyMaturationService.new(profiles)
	var milestones: Array[int] = body_service.milestone_career_years()

	var invariants: Dictionary = {
		"body.adult_containment": 0, "body.intermediate_legality": 0,
		"body.skeletal_monotonicity": 0, "body.growth_determinism": 0,
		"body.increment_idempotency": 0, "body.increment_count_exact": 0,
		"body.no_rating_side_effect": 0, "body.no_cap_side_effect": 0,
		"body.no_currency_side_effect": 0, "body.position_plausibility": 0,
		"body.stored_range_matches_profile": 0,
	}
	var maturations: int = 0
	var timing_is_schedule: int = 0
	var separation := PackedFloat64Array()

	var by_maturity: Array[Group] = []
	for _index in range(MaturityProfile.COUNT):
		by_maturity.append(Group.new())
	var by_family: Array[Group] = []
	for _index in range(PositionFamily.COUNT):
		by_family.append(Group.new())

	var base: int = shard * careers
	for index in range(careers):
		var seed_value: int = base + index + 1
		var family: int = seed_value % PositionFamily.COUNT
		var prospect: int = (seed_value / PositionFamily.COUNT) % ProspectProfile.COUNT

		var triple: Array[Maturation] = []
		for maturity in range(MaturityProfile.COUNT):
			var resolved: Maturation = _resolve_one(
				builder, body_service, profiles, milestones,
				family, prospect, maturity, seed_value)
			triple.append(resolved)
			maturations += 1
			if resolved.contained:
				invariants["body.adult_containment"] += 1
			if resolved.intermediate_legal:
				invariants["body.intermediate_legality"] += 1
			if resolved.monotone:
				invariants["body.skeletal_monotonicity"] += 1
			if resolved.deterministic:
				invariants["body.growth_determinism"] += 1
			if resolved.idempotent:
				invariants["body.increment_idempotency"] += 1
			if resolved.increments_exact:
				invariants["body.increment_count_exact"] += 1
			if resolved.ratings_unchanged:
				invariants["body.no_rating_side_effect"] += 1
			if resolved.caps_unchanged:
				invariants["body.no_cap_side_effect"] += 1
			if resolved.currency_unchanged:
				invariants["body.no_currency_side_effect"] += 1
			if resolved.plausible:
				invariants["body.position_plausibility"] += 1
			if resolved.range_matches_profile:
				invariants["body.stored_range_matches_profile"] += 1

			by_maturity[maturity].observe(
				resolved.high_school_share, resolved.freshman, resolved.adult)
			by_family[family].observe(
				resolved.high_school_share, resolved.freshman, resolved.adult)

		# `GDD.md` §6.5: timing is a schedule, not a budget. The three runs share
		# a drawn adult body, so equality here is exact rather than approximate.
		var early_body: BodyProfile = triple[MaturityProfile.Value.EARLY].adult
		var same: bool = true
		for maturation in triple:
			if maturation.adult.signature() != early_body.signature():
				same = false
		if same:
			timing_is_schedule += 1

		separation.append(
			triple[MaturityProfile.Value.EARLY].high_school_share
			- triple[MaturityProfile.Value.LATE].high_school_share)

	# --- structural invariants -----------------------------------------------
	var definitions: Dictionary = {
		"body.adult_containment":
			"Share of maturations whose realized adult body falls inside the "
			+ "projected adult range stored at confirmation, on every dimension.",
		"body.intermediate_legality":
			"Share in which no intermediate body left the stored range above or "
			+ "fell below the confirmed freshman skeleton.",
		"body.skeletal_monotonicity":
			"Share in which height, wingspan, and standing reach never decreased "
			+ "across an increment.",
		"body.growth_determinism":
			"Share whose complete body history reproduced exactly when rebuilt "
			+ "from the same versioned career seed (§7.4.3 rule 1).",
		"body.increment_idempotency":
			"Share in which replaying an already-resolved milestone was refused "
			+ "and left the body unchanged (§6.3).",
		"body.increment_count_exact":
			"Share that resolved exactly the scheduled number of increments — no "
			+ "skipped and no duplicated milestone.",
		"body.no_rating_side_effect":
			"Share in which no increment altered any of the twenty public ratings "
			+ "as a side effect (§7.4.3 rule 4, §28).",
		"body.no_cap_side_effect":
			"Share in which no increment altered a per-attribute cap (§7.4.3 rule 3).",
		"body.no_currency_side_effect":
			"Share in which no increment granted, spent, or refunded an "
			+ "AP-equivalent unit (§7.4.3 rule 3).",
		"body.position_plausibility":
			"Share of realized adult bodies inside the credible height, weight, "
			+ "wingspan, and standing-reach domain of the body model.",
		"body.stored_range_matches_profile":
			"Share whose stored projected range is exactly the versioned growth "
			+ "widths applied to the confirmed freshman body. The range is a "
			+ "binding contract and may not be narrowed around a hidden draw.",
	}
	for metric_id: Variant in definitions.keys():
		var key: String = str(metric_id)
		var successes: int = invariants[key]
		report.add_metric(CalibrationMetric.banded(
			StringName(key), str(definitions[key]), "individual body maturations", 0.0,
			CalibrationTargets.structural_invariant_share(), maturations)
			.with_aggregation(MetricAggregation.proportion(successes, maturations)))

	report.add_metric(CalibrationMetric.banded(
		&"body.timing_is_schedule_not_budget",
		"Share of matched triples whose realized adult body is identical across "
		+ "Early, Average, and Late. `GDD.md` §6.5 forbids a timing profile from "
		+ "delivering more total growth than another.",
		"matched maturity triples", 0.0,
		CalibrationTargets.structural_invariant_share(), careers)
		.with_aggregation(MetricAggregation.proportion(timing_is_schedule, careers)))

	# --- timing separation ----------------------------------------------------
	report.add_metric(CalibrationMetric.banded(
		&"body.timing_separation",
		"Mean per-prospect difference between the share of total height growth "
		+ "delivered by the end of high school under Early maturity and under "
		+ "Late, holding every other drawn quantity identical. §7.4.2 requires "
		+ "the timing profiles to produce materially different high-school bodies.",
		"matched maturity triples", 0.0,
		CalibrationTargets.body_timing_separation(), careers)
		.with_aggregation(MetricAggregation.mean_of(separation)))

	for maturity in range(MaturityProfile.COUNT):
		var group: Group = by_maturity[maturity]
		if group.count == 0:
			continue
		var configured: float = profiles.builder.high_school_growth_share_for(maturity)
		report.add_metric(CalibrationMetric.banded(
			StringName("body.high_school_share.%s" % MaturityProfile.id_of(maturity)),
			"Realized share of total height growth delivered by the end of high "
			+ "school under %s maturity, against the configured schedule of %.2f."
				% [MaturityProfile.id_of(maturity), configured],
			"individual body maturations", 0.0,
			CalibrationBand.new(
				configured - CalibrationTargets.BODY_TIMING_SHARE_TOLERANCE,
				configured + CalibrationTargets.BODY_TIMING_SHARE_TOLERANCE,
				CalibrationTargets.body_timing_share_source()),
			group.count)
			.with_aggregation(MetricAggregation.mean_of(group.high_school_share)))
		report.add_metric(CalibrationMetric.raw(
			StringName("body.total_height_growth.%s" % MaturityProfile.id_of(maturity)),
			"Mean total height growth in inches from the confirmed freshman body "
			+ "to the realized adult body.",
			"individual body maturations",
			CalibrationStatistics.mean(group.total_height_growth), group.count)
			.with_aggregation(MetricAggregation.mean_of(group.total_height_growth)))

	report.add_section(&"body_by_maturity", _rows(by_maturity, MaturityProfile.COUNT, true))
	report.add_section(&"body_by_position_family", _rows(by_family, PositionFamily.COUNT, false))


func _resolve_one(
	builder: BuilderService,
	body_service: BodyMaturationService,
	profiles: BalanceProfileSet,
	milestones: Array[int],
	family: int,
	prospect: int,
	maturity: int,
	seed_value: int,
) -> Maturation:
	var result := Maturation.new()
	var state: PlayerDevelopmentState = _confirmed(
		builder, family, prospect, maturity, seed_value)
	var body_state: BodyMaturationState = state.body_state
	var freshman: BodyProfile = body_state.confirmed_freshman_body.duplicate_body()
	var stored: BodyRange = body_state.projected_range.duplicate_range()

	result.freshman = freshman
	result.range_matches_profile = (
		BodyMaturationPlanner.project_adult_range(freshman, profiles.builder).signature()
		== stored.signature())

	var ratings_before: String = state.attributes.signature()
	var caps_before: String = state.caps.signature()
	var ledger_before: int = state.point_ledger.entry_count()

	result.intermediate_legal = true
	result.monotone = true
	var previous: BodyProfile = freshman
	var height_after_high_school: int = freshman.height_inches

	for milestone_index in range(milestones.size()):
		body_service.resolve_increment(
			state, milestones[milestone_index], SeededRandomSource.new(seed_value))
		var current: BodyProfile = body_state.realized_body
		if not stored.permits_intermediate(
				current, freshman, body_state.weight_health_floor()):
			result.intermediate_legal = false
		if (current.height_inches < previous.height_inches
				or current.wingspan_inches < previous.wingspan_inches
				or current.standing_reach_inches < previous.standing_reach_inches):
			result.monotone = false
		if milestone_index == BuilderProfile.HIGH_SCHOOL_GROWTH_MILESTONES - 1:
			height_after_high_school = current.height_inches
		previous = current

	var adult: BodyProfile = body_state.realized_body.duplicate_body()
	result.adult = adult
	result.contained = stored.containment_failures(adult).is_empty()
	result.increments_exact = (
		body_state.resolved_count() == BuilderProfile.TOTAL_GROWTH_MILESTONES)
	result.ratings_unchanged = state.attributes.signature() == ratings_before
	result.caps_unchanged = state.caps.signature() == caps_before
	result.currency_unchanged = state.point_ledger.entry_count() == ledger_before
	result.plausible = _is_plausible(adult)

	var total_growth: int = adult.height_inches - freshman.height_inches
	result.high_school_share = (
		float(height_after_high_school - freshman.height_inches) / float(total_growth)
		if total_growth > 0
		else profiles.builder.high_school_growth_share_for(maturity))

	# §6.3 idempotency: a replayed milestone must refuse and change nothing.
	var signature: String = body_state.signature()
	var replayed: bool = body_service.resolve_increment(
		state, milestones[0], SeededRandomSource.new(seed_value))
	result.idempotent = not replayed and body_state.signature() == signature

	# §7.4.3 rule 1: rebuilding from the same seed reproduces the history exactly.
	var replica: PlayerDevelopmentState = _confirmed(
		builder, family, prospect, maturity, seed_value)
	for year in milestones:
		body_service.resolve_increment(replica, year, SeededRandomSource.new(seed_value))
	result.deterministic = replica.body_state.signature() == signature

	return result


func _confirmed(
	builder: BuilderService,
	family: int,
	prospect: int,
	maturity: int,
	seed_value: int,
) -> PlayerDevelopmentState:
	var source := SeededRandomSource.new(seed_value)
	var build: BuilderState = builder.begin_build(
		family, prospect, maturity, builder.default_body_for_family(family), source)
	build.fill_remaining_anywhere()
	return builder.confirm(
		build, &"body_calibration_player", seed_value, SeededRandomSource.new(seed_value))


## Whether a realized adult body sits inside the credible domain of the body
## model itself. A body outside it is impossible rather than merely unusual.
func _is_plausible(body: BodyProfile) -> bool:
	return (
		body.height_inches >= BodyProfile.MINIMUM_HEIGHT_INCHES
		and body.height_inches <= BodyProfile.MAXIMUM_HEIGHT_INCHES
		and body.weight_pounds >= BodyProfile.MINIMUM_WEIGHT_POUNDS
		and body.weight_pounds <= BodyProfile.MAXIMUM_WEIGHT_POUNDS
		and body.wingspan_inches > 0
		and body.standing_reach_inches > body.height_inches)


func _rows(groups: Array[Group], count: int, by_maturity: bool) -> Array:
	var rows: Array = []
	for index in range(count):
		var group: Group = groups[index]
		if group.count == 0:
			continue
		var adult_height: PackedFloat64Array = group.adult_height.duplicate()
		adult_height.sort()
		var adult_weight: PackedFloat64Array = group.adult_weight.duplicate()
		adult_weight.sort()
		var adult_wingspan: PackedFloat64Array = group.adult_wingspan.duplicate()
		adult_wingspan.sort()
		var adult_reach: PackedFloat64Array = group.adult_reach.duplicate()
		adult_reach.sort()
		rows.append({
			"group": String(
				MaturityProfile.id_of(index) if by_maturity else PositionFamily.id_of(index)),
			"maturations": group.count,
			"mean_freshman_height": CalibrationStatistics.mean(group.freshman_height),
			"mean_adult_height": CalibrationStatistics.mean(group.adult_height),
			"adult_height_p10": CalibrationStatistics.percentile(adult_height, 0.10),
			"adult_height_p90": CalibrationStatistics.percentile(adult_height, 0.90),
			"mean_adult_weight": CalibrationStatistics.mean(group.adult_weight),
			"adult_weight_p10": CalibrationStatistics.percentile(adult_weight, 0.10),
			"adult_weight_p90": CalibrationStatistics.percentile(adult_weight, 0.90),
			"mean_adult_wingspan": CalibrationStatistics.mean(group.adult_wingspan),
			"adult_wingspan_p10": CalibrationStatistics.percentile(adult_wingspan, 0.10),
			"adult_wingspan_p90": CalibrationStatistics.percentile(adult_wingspan, 0.90),
			"mean_adult_standing_reach": CalibrationStatistics.mean(group.adult_reach),
			"mean_total_height_growth": CalibrationStatistics.mean(group.total_height_growth),
			"mean_high_school_share": CalibrationStatistics.mean(group.high_school_share),
		})
	return rows
