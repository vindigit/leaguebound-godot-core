extends SceneTree

## Root-cause measurement for the §8.4 rare-generational career-peak band
## (`BALANCE_SPEC.md` §8.4 OD-A, §9.1, §9.5, §9.6, §10.2, §10.3).
##
## The pooled career-progression run reports one number per outcome band. A
## median of 90 against a locked 92-95 does not say *why*, and §8.4's own list of
## corrections — "seasonal AP availability, the cost curve, cap distributions,
## aging, or decline" — has five entries with five different fixes. Choosing
## between them by trying each and watching the median move is curve fitting;
## this runner measures the mechanism instead.
##
## ## What it decomposes
##
## For each outcome path it separates the peak Overall a career reached from the
## peak it *could* have reached, along three independent axes:
##
##   - **Ceiling.** Maximum Potential Overall is the §6.1 formula applied to the
##     player's own caps. `max_potential - peak` is the headroom the career left
##     on the table; a cohort whose Maximum Potential sits below its own band is
##     cap-bound, and no amount of opportunity can fix it.
##   - **Opportunity.** Lifetime AP granted, spent, left unspent, and removed by
##     decline, split by career phase and by ledger source. A cohort that
##     converts everything it is given and still falls short is opportunity-bound.
##   - **Allocation.** The same lifetime AP replayed through the projection's own
##     ordinary cheapest-first conversion, from the same starting build against
##     the same caps. That counterfactual never sees decline or allocation order,
##     so the gap between it and the realized peak is what those two cost.
##
## ## Timing
##
## Opportunity that arrives after the peak cannot raise it. The runner therefore
## reports the share of lifetime AP granted before the peak season, the peak
## season and age, and the seasons in which the §9.5 upper guardrail was passed.
##
## ## Why it forces the path
##
## The generational cohort is two percent of the population, so a natural run
## needs fifty careers to observe one. `CareerSimulator.simulate` accepts a
## diagnostic path override that still consumes the population draw, and for the
## top two paths the override is bit-identical to the natural career: `path_for`
## consumes one draw whatever it returns, and every path at or above
## `EXCEPTIONAL` takes the same prospect branch. Forcing the path therefore
## measures precisely the careers the population produces, at fifty times the
## sample per unit of compute, rather than a different cohort that resembles
## them. `--verify-forced` proves that property on the run's own seeds instead of
## asserting it.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_generational_diagnostics.gd -- \
##       [--careers=N] [--shard=I] [--paths=4,3] [--verify-forced=true] [--label=NAME]

const DEFAULT_CAREERS: int = 600


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var label: String = CalibrationCli.string_option(options, &"label", "diagnostic")
	var verify: bool = CalibrationCli.bool_option(options, &"verify-forced", false)
	var paths: Array[int] = _parse_paths(
		CalibrationCli.string_option(options, &"paths", "4"))

	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var simulator := CareerSimulator.new(profiles)
	simulator.capture_diagnostics = true

	var base: int = shard * careers
	print("")
	print("=== S8.4 rare-generational root-cause diagnostics (%s) ===" % label)
	print("  balance=%s ratings=%s seeds=%d..%d careers-per-path=%d" % [
		profiles.progression.version, profiles.ratings.version,
		base + 1, base + careers, careers])

	if verify:
		_verify_forced_equivalence(simulator, base, careers)

	for path in paths:
		_report_path(simulator, profiles, path, base, careers)

	print("")
	quit(0)


static func _parse_paths(raw: String) -> Array[int]:
	var paths: Array[int] = []
	for token in raw.split(",", false):
		var text: String = token.strip_edges()
		if text.is_valid_int():
			var value: int = text.to_int()
			if value >= 0 and value < CareerSimulator.PATH_COUNT:
				paths.append(value)
	if paths.is_empty():
		paths.append(CareerSimulator.Path.GENERATIONAL)
	return paths


## Prove the forced-path cohort is the population's own cohort.
##
## For every seed in the range whose natural draw already selected the top path,
## the forced career must be identical in every measured outcome. A mismatch
## would mean the override shifted the stream, and the whole diagnostic would be
## measuring careers the population never produces.
func _verify_forced_equivalence(
	simulator: CareerSimulator, base: int, careers: int
) -> void:
	var checked: int = 0
	var mismatched: int = 0
	for index in range(careers):
		var seed_value: int = base + index + 1
		var natural: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL)
		if natural.path != CareerSimulator.Path.GENERATIONAL:
			continue
		var forced: CareerSimulator.CareerResult = simulator.simulate(
			seed_value, DevelopmentExecutor.Value.MANUAL,
			CareerSimulator.Path.GENERATIONAL)
		checked += 1
		if forced.peak_overall != natural.peak_overall \
				or forced.maximum_potential != natural.maximum_potential \
				or forced.starting_overall != natural.starting_overall \
				or not is_equal_approx(forced.total_ap_granted, natural.total_ap_granted):
			mismatched += 1
	print("")
	print("  forced-path equivalence: %d natural generational seed(s) checked, %d mismatched"
		% [checked, mismatched])
	if mismatched > 0:
		printerr("  forced-path override is NOT stream-identical; diagnostics are unsound")


func _report_path(
	simulator: CareerSimulator,
	profiles: BalanceProfileSet,
	path: int,
	base: int,
	careers: int,
) -> void:
	var results: Array[CareerSimulator.CareerResult] = []
	for index in range(careers):
		results.append(simulator.simulate(
			base + index + 1, DevelopmentExecutor.Value.MANUAL, path))

	var starts := PackedFloat64Array()
	var potentials := PackedFloat64Array()
	var peaks := PackedFloat64Array()
	var finals := PackedFloat64Array()
	var headroom := PackedFloat64Array()
	var granted := PackedFloat64Array()
	var spent := PackedFloat64Array()
	var rating_points := PackedFloat64Array()
	var reconciliation := PackedFloat64Array()
	var unspent := PackedFloat64Array()
	var declined := PackedFloat64Array()
	var unrealized := PackedFloat64Array()
	var attainment_end := PackedFloat64Array()
	var attainment_peak := PackedFloat64Array()
	var at_cap := PackedFloat64Array()
	var peak_age := PackedFloat64Array()
	var peak_season := PackedFloat64Array()
	var before_peak_share := PackedFloat64Array()
	var guardrail_seasons := PackedFloat64Array()
	var guardrail_excess := PackedFloat64Array()
	var ideal_peaks := PackedFloat64Array()
	var allocation_loss := PackedFloat64Array()
	var above_95: int = 0
	var granted_phase := PackedFloat64Array()
	var spent_phase := PackedFloat64Array()
	var granted_source := PackedFloat64Array()
	granted_phase.resize(CareerPhase.COUNT)
	spent_phase.resize(CareerPhase.COUNT)
	granted_source.resize(AttributePointSource.COUNT)
	var cost_band_points := PackedFloat64Array()
	var cost_band_ap := PackedFloat64Array()
	cost_band_points.resize(profiles.progression.cost_band_costs.size())
	cost_band_ap.resize(profiles.progression.cost_band_costs.size())

	for career in results:
		starts.append(float(career.starting_overall))
		potentials.append(float(career.maximum_potential))
		peaks.append(float(career.peak_overall))
		finals.append(float(career.final_overall))
		headroom.append(float(career.maximum_potential - career.peak_overall))
		granted.append(career.total_ap_granted)
		spent.append(career.total_ap_spent)
		rating_points.append(float(career.total_rating_points_gained))
		unspent.append(career.total_ap_unspent)
		reconciliation.append(career.total_ap_granted_by_ledger - career.total_ap_spent
			- career.total_ap_debited_without_purchase - career.total_ap_unspent)
		declined.append(career.ap_debited_by_source[AttributePointSource.Value.DECLINE])
		unrealized.append(career.ap_debited_by_source[AttributePointSource.Value.GAME])
		attainment_end.append(career.cap_attainment)
		attainment_peak.append(career.peak_cap_attainment)
		at_cap.append(float(career.attributes_at_cap_at_peak))
		peak_age.append(float(career.peak_age))
		peak_season.append(float(career.peak_season))
		guardrail_seasons.append(float(career.guardrail_seasons))
		guardrail_excess.append(career.guardrail_excess)
		if career.total_ap_granted > 0.0:
			before_peak_share.append(career.granted_before_peak / career.total_ap_granted)
		if career.peak_overall > 95:
			above_95 += 1

		# The counterfactual: the projection's own ordinary conversion, given the
		# lifetime opportunity the career actually received. It never sees
		# decline or allocation order, so the gap isolates them.
		var ideal: int = ProjectedPeakCalculator.overall_after_spending(
			career.starting_values, career.starting_caps,
			int(floorf(career.total_ap_granted)), profiles.ratings,
			profiles.progression)
		ideal_peaks.append(float(ideal))
		allocation_loss.append(float(ideal - career.peak_overall))

		for phase in range(CareerPhase.COUNT):
			granted_phase[phase] += career.ap_granted_by_phase[phase]
			spent_phase[phase] += career.ap_spent_by_phase[phase]
		for source in range(AttributePointSource.COUNT):
			granted_source[source] += career.ap_granted_by_source[source]

		for attribute in range(AttributeKey.COUNT):
			var from_rating: int = career.starting_values[attribute]
			var to_rating: int = career.peak_values[attribute]
			for destination in range(from_rating + 1, to_rating + 1):
				var band: int = _band_of(destination, profiles.progression)
				cost_band_points[band] += 1.0
				cost_band_ap[band] += float(
					profiles.progression.upgrade_cost_for_destination(destination))

	var sample: float = float(maxi(1, results.size()))
	print("")
	print("--- %s (n=%d) ---" % [CareerSimulator.path_id(path), results.size()])
	print("  locked band                %s" % _band_text(path))
	_print_distribution("starting Overall", starts)
	_print_distribution("Maximum Potential", potentials)
	_print_distribution("realized peak", peaks)
	_print_distribution("final Overall", finals)
	_print_distribution("headroom MaxPot-peak", headroom)
	print("  peak above 95              %d career(s), share %.4f"
		% [above_95, float(above_95) / sample])
	print("")
	_print_distribution("lifetime AP granted", granted)
	_print_distribution("lifetime AP spent", spent)
	_print_distribution("rating points gained", rating_points)
	_print_distribution("granted-spent-other-left", reconciliation)
	_print_distribution("AP unspent at end", unspent)
	_print_distribution("AP removed by decline", declined)
	_print_distribution("AP never realized", unrealized)
	_print_distribution("cap attainment at peak", attainment_peak)
	_print_distribution("cap attainment at end", attainment_end)
	_print_distribution("attributes at cap", at_cap)
	print("")
	_print_distribution("peak age", peak_age)
	_print_distribution("peak season", peak_season)
	_print_distribution("AP share before peak", before_peak_share)
	_print_distribution("guardrail seasons", guardrail_seasons)
	_print_distribution("guardrail excess AP", guardrail_excess)
	print("")
	_print_distribution("ideal peak, same AP", ideal_peaks)
	_print_distribution("allocation loss", allocation_loss)

	_report_conversion_curve(results, profiles)
	_report_allocation_optimality(results, profiles)

	print("")
	print("  AP granted / spent by career phase, mean per career:")
	for phase in range(CareerPhase.COUNT):
		if granted_phase[phase] <= 0.0 and spent_phase[phase] <= 0.0:
			continue
		print("    %-22s granted %8.1f  spent %8.1f  guardrail %d" % [
			CareerPhase.id_of(phase),
			granted_phase[phase] / sample,
			spent_phase[phase] / sample,
			profiles.progression.seasonal_ap_guardrail[phase]])
	print("  AP granted by ledger source, mean per career:")
	for source in range(AttributePointSource.COUNT):
		if granted_source[source] <= 0.0:
			continue
		print("    %-22s %8.1f" % [
			AttributePointSource.id_of(source), granted_source[source] / sample])
	print("  rating points bought by cost band, mean per career:")
	for band in range(cost_band_points.size()):
		if cost_band_points[band] <= 0.0:
			continue
		print("    to %-3d at %2d AP        %7.2f points  %8.1f AP" % [
			profiles.progression.cost_band_ceilings[band],
			profiles.progression.cost_band_costs[band],
			cost_band_points[band] / sample,
			cost_band_ap[band] / sample])


static func _band_of(destination: int, progression: ProgressionProfile) -> int:
	for index in range(progression.cost_band_ceilings.size()):
		if destination <= progression.cost_band_ceilings[index]:
			return index
	return progression.cost_band_ceilings.size() - 1


static func _band_text(path: int) -> String:
	var band: CalibrationBand = CalibrationTargets.career_peak_overall(path)
	return "%.0f..%.0f (%s)" % [band.minimum, band.maximum, band.source]


static func _print_distribution(name: String, values: PackedFloat64Array) -> void:
	if values.is_empty():
		print("  %-26s (no observations)" % name)
		return
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	print("  %-26s mean %8.2f  p10 %7.2f  p50 %7.2f  p90 %7.2f  min %7.2f  max %7.2f" % [
		name, CalibrationStatistics.mean(values),
		CalibrationStatistics.percentile(sorted, 0.10),
		CalibrationStatistics.percentile(sorted, 0.50),
		CalibrationStatistics.percentile(sorted, 0.90),
		sorted[0], sorted[sorted.size() - 1]])


## How much Overall each additional unit of opportunity buys.
##
## §9.1 costs escalate with the destination rating, so "how much more AP would
## close the band" has no single answer that can be reasoned about from the
## table alone: it depends on where in the cost curve the cohort has stopped.
## Replaying each career's own starting build and caps through the projection's
## ordinary conversion at multiples of its real budget measures the slope
## directly. The uncapped column repeats the exercise against a cap vector of
## all 99s, which separates "this career ran out of opportunity" from "this
## career ran out of ceiling": where the two columns agree, the ceiling is not
## binding.
func _report_conversion_curve(
	results: Array[CareerSimulator.CareerResult],
	profiles: BalanceProfileSet,
) -> void:
	var multiples: PackedFloat64Array = PackedFloat64Array(
		[0.8, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.75, 2.0])
	var uncapped := AttributeCaps.new()
	print("")
	print("  opportunity-to-Overall conversion, ordinary cheapest-first allocation:")
	print("    budget      AP median   capped p50   uncapped p50")
	for multiple in multiples:
		var capped_peaks := PackedFloat64Array()
		var uncapped_peaks := PackedFloat64Array()
		var budgets := PackedFloat64Array()
		for career in results:
			var budget: int = int(floorf(career.total_ap_granted * multiple))
			budgets.append(float(budget))
			capped_peaks.append(float(ProjectedPeakCalculator.overall_after_spending(
				career.starting_values, career.starting_caps, budget,
				profiles.ratings, profiles.progression)))
			uncapped_peaks.append(float(ProjectedPeakCalculator.overall_after_spending(
				career.starting_values, uncapped, budget,
				profiles.ratings, profiles.progression)))
		capped_peaks.sort()
		uncapped_peaks.sort()
		budgets.sort()
		print("    x%-5.2f    %9.0f    %9.1f      %9.1f" % [
			multiple,
			CalibrationStatistics.percentile(budgets, 0.50),
			CalibrationStatistics.percentile(capped_peaks, 0.50),
			CalibrationStatistics.percentile(uncapped_peaks, 0.50)])


## Bound the cost of allocation order.
##
## The ordinary cheapest-first pattern is not the Overall-maximising one, so a
## comparison against it alone cannot rule allocation out as a cause. This
## replays the same budget under a pattern that buys the single most Overall per
## AP at every step — a bound no legal allocator can beat, because it is the
## §6.1 blend maximised subject to the §9.1 costs and the player's own caps.
## Anything the realized career leaves on the table relative to this is the most
## that better allocation could ever be worth.
##
## It is deliberately expensive and therefore samples the cohort rather than
## exhausting it.
func _report_allocation_optimality(
	results: Array[CareerSimulator.CareerResult],
	profiles: BalanceProfileSet,
) -> void:
	var sample: int = mini(results.size(), 120)
	var optimal := PackedFloat64Array()
	var cheapest := PackedFloat64Array()
	var realized := PackedFloat64Array()
	for index in range(sample):
		var career: CareerSimulator.CareerResult = results[index]
		var budget: int = int(floorf(career.total_ap_granted))
		optimal.append(float(_overall_greedy(
			career.starting_values, career.starting_caps, budget,
			profiles.ratings, profiles.progression)))
		cheapest.append(float(ProjectedPeakCalculator.overall_after_spending(
			career.starting_values, career.starting_caps, budget,
			profiles.ratings, profiles.progression)))
		realized.append(float(career.peak_overall))
	print("")
	print("  allocation bound on %d career(s):" % sample)
	_print_distribution("  realized peak", realized)
	_print_distribution("  cheapest-first", cheapest)
	_print_distribution("  Overall-greedy bound", optimal)


## The Overall-maximising spend of `available_ap`, respecting caps and costs.
##
## Diagnostic only. Nothing in the domain may allocate this way: §9.7.2 binds an
## allocator to the same costs and caps but says nothing about giving it perfect
## foresight, and a career that always bought the single best point would not be
## a career. It exists to bound what allocation could contribute.
static func _overall_greedy(
	values: Array[int],
	caps: AttributeCaps,
	available_ap: int,
	ratings: RatingsProfile,
	progression: ProgressionProfile,
) -> int:
	var current: Array[int] = values.duplicate()
	var remaining: int = available_ap
	var base: float = OverallCalculator.raw_overall(current, ratings)
	while remaining > 0:
		var best_attribute: int = -1
		var best_gain: float = 0.0
		var best_cost: int = 0
		for attribute in AttributeKey.all():
			var rating: int = current[attribute]
			if not caps.has_room(attribute, rating) or rating >= Rating.MAXIMUM:
				continue
			var cost: int = AttributeCostTable.cost_of_next_point(rating, progression)
			if cost > remaining:
				continue
			current[attribute] = rating + 1
			var gain: float = (OverallCalculator.raw_overall(current, ratings) - base)
			current[attribute] = rating
			var rate: float = gain / float(cost)
			if best_attribute == -1 or rate > best_gain:
				best_attribute = attribute
				best_gain = rate
				best_cost = cost
		if best_attribute == -1:
			break
		current[best_attribute] += 1
		remaining -= best_cost
		base = OverallCalculator.raw_overall(current, ratings)
	return OverallCalculator.overall_from_values(current, ratings)
