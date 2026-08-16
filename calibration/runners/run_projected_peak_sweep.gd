extends SceneTree

## Projected Peak parameter sweep (`BALANCE_SPEC.md` §6.3, §32 report 7).
##
## The diagnostic runner establishes that the projected-peak miss is entirely a
## budget defect: the model's AP-to-Overall conversion predicts the realized peak
## with a median error of zero once it is given the true lifetime opportunity,
## and the whole reported bias comes from crediting roughly half the opportunity
## a career actually receives.
##
## Fixing that is a calibration, not a guess, so this runner measures the whole
## trade-off surface instead of proposing one value. For each career it evaluates
## the model's own conversion across a grid of opportunity multipliers, then
## scores every candidate `[low, high]` pair on the three §6.3 acceptance
## measures at once:
##
##   - coverage of the realized peak by the displayed range;
##   - median displayed range width;
##   - median signed error between realized peak and range midpoint.
##
## Those three pull against each other — widening the range buys coverage and
## spends the width guardrail — so a pair is only a candidate when it satisfies
## all three simultaneously. Reporting the surface rather than the winner is what
## makes the accepted value auditable and shows whether the bands are reachable
## at all.
##
## `--validate-seed-base` re-scores the accepted pair on an independent seed
## range. A parameter fitted and judged on the same careers has been fitted to
## noise; the held-out score is the one that means anything.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_projected_peak_sweep.gd -- \
##       [--careers=N] [--seed-base=N] [--validate-seed-base=N]

const DEFAULT_CAREERS: int = 800

## Opportunity multipliers evaluated, as a share of the horizon's expected
## seasonal grant. The grid brackets both the current model (about 0.35 of the
## expected grant at the low bound) and full realization.
## The upper end runs well past full realization on purpose. Once the high bound
## saturates against Maximum Potential the range stops widening while coverage
## keeps rising, so the coverage-versus-width trade is not monotone and a grid
## that stops at 1.0 would hide the part of the surface that matters.
const MULTIPLIER_MINIMUM: float = 0.25
const MULTIPLIER_MAXIMUM: float = 3.00
const MULTIPLIER_STEP: float = 0.05


## Width of the Maximum Potential bucket used to group careers that share their
## creation-time information, in Overall points.
const MAX_POTENTIAL_BUCKET: int = 2

## Smallest group the irreducible-width estimate is taken from. Below this a
## narrowest-window estimate is dominated by sampling noise and would understate
## the true width.
const MINIMUM_GROUP: int = 30


## A mutable holder for one group's realized peaks.
##
## `PackedFloat64Array` is a value type, so fetching one out of a Dictionary and
## appending to it modifies a copy and leaves the stored array empty. Wrapping it
## in a RefCounted is what makes the accumulation actually accumulate.
class Bucket extends RefCounted:
	var peaks := PackedFloat64Array()


## One candidate pair's score against the three §6.3 measures.
class Score extends RefCounted:
	var low: float = 0.0
	var high: float = 0.0
	var coverage: float = 0.0
	var median_width: float = 0.0
	var median_bias: float = 0.0
	## Distance from the nearest band edge, normalised per measure, so the
	## accepted pair is not perched where sampling noise would flip its verdict.
	var margin: float = 0.0


## One career reduced to what the sweep needs: the realized outcome, and the
## model's predicted Overall at every multiplier on the grid.
class Sample extends RefCounted:
	var prospect: int
	var path: int
	var realized_peak: int
	var realized_peak_age: int
	var current_overall: int
	var maximum_potential: int
	var predicted: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var seed_base: int = CalibrationCli.int_option(options, &"seed-base", 0)
	var validate_base: int = CalibrationCli.int_option(options, &"validate-seed-base", -1)

	# The parameter surface costs one full model evaluation per career per grid
	# point and dominates the run. The irreducible-width analysis needs none of
	# them — only the realized outcome — so it can be asked for on its own at a
	# far larger sample, which is the sample that question deserves.
	var with_surface: bool = CalibrationCli.bool_option(options, &"surface", true)

	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var multipliers: PackedFloat64Array = _grid() if with_surface else PackedFloat64Array()

	print("Collecting %d fitting careers from seed %d..." % [careers, seed_base + 1])
	var fit: Array[Sample] = _collect(profiles, careers, seed_base, multipliers)
	_report_peak_ages(fit, profiles)
	_report_irreducible_width(fit)
	if with_surface:
		_report_surface(fit, multipliers, "FITTING")

	if validate_base >= 0:
		print("")
		print("Collecting %d validation careers from seed %d..." % [careers, validate_base + 1])
		var validation: Array[Sample] = _collect(
			profiles, careers, validate_base, multipliers)
		_report_irreducible_width(validation)
		if with_surface:
			_report_surface(validation, multipliers, "VALIDATION")

	quit(0)


func _grid() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	var value: float = MULTIPLIER_MINIMUM
	while value <= MULTIPLIER_MAXIMUM + 0.0001:
		values.append(value)
		value += MULTIPLIER_STEP
	return values


func _collect(
	profiles: BalanceProfileSet,
	careers: int,
	seed_base: int,
	multipliers: PackedFloat64Array,
) -> Array[Sample]:
	var simulator := CareerSimulator.new(profiles)
	simulator.capture_diagnostics = true
	var samples: Array[Sample] = []

	for index in range(careers):
		var career: CareerSimulator.CareerResult = simulator.simulate(
			seed_base + index + 1, DevelopmentExecutor.Value.MANUAL)
		var sample := Sample.new()
		sample.prospect = career.prospect
		sample.path = career.path
		sample.realized_peak = career.peak_overall
		sample.realized_peak_age = career.peak_age
		sample.current_overall = career.starting_overall
		sample.maximum_potential = career.maximum_potential

		var base_ap: float = _expected_horizon_ap(career.prospect, profiles.progression)
		for multiplier in multipliers:
			sample.predicted.append(ProjectedPeakCalculator.overall_after_spending(
				career.starting_values, career.starting_caps,
				int(floorf(base_ap * multiplier)), profiles.ratings, profiles.progression))
		samples.append(sample)

	return samples


## The opportunity the horizon is *expected* to deliver: the midpoint of each
## season's §9.5 band, scaled by the §7.2 growth-availability multiplier. The
## sweep multiplies this, so a multiplier of 1.0 means "this career realizes
## exactly the expected seasonal grant for every season to its peak age".
func _expected_horizon_ap(prospect: int, progression: ProgressionProfile) -> float:
	var total: float = 0.0
	for season_age in range(BuilderService.FRESHMAN_AGE, progression.expected_peak_age[prospect]):
		var phase: int = CareerPhase.default_phase_for_age(season_age)
		var growth_phase: int = CareerPhase.growth_phase_of(phase)
		var availability: float = progression.growth_availability_for(prospect, growth_phase)
		total += (float(progression.seasonal_ap_minimum[phase])
			+ float(progression.seasonal_ap_maximum[phase])) / 2.0 * availability
	return total


## Realized peak age against the model's expected peak age. The model stops
## accruing opportunity at the expected age, so a systematic gap here is
## opportunity the horizon never counted.
func _report_peak_ages(samples: Array[Sample], profiles: BalanceProfileSet) -> void:
	print("")
	print("  --- realized peak age by prospect profile ---")
	for prospect in range(ProspectProfile.COUNT):
		var ages := PackedFloat64Array()
		for sample in samples:
			if sample.prospect == prospect:
				ages.append(float(sample.realized_peak_age))
		if ages.is_empty():
			continue
		ages.sort()
		print("  %-14s n=%-5d expected=%d  realized p25=%.0f median=%.0f p75=%.0f" % [
			ProspectProfile.id_of(prospect), ages.size(),
			profiles.progression.expected_peak_age[prospect],
			CalibrationStatistics.percentile(ages, 0.25),
			CalibrationStatistics.percentile(ages, 0.50),
			CalibrationStatistics.percentile(ages, 0.75)])


## The narrowest range any creation-time model could display and still reach the
## §6.3 coverage floor.
##
## The sweep searches one model's parameters. This searches no model at all: it
## conditions careers on everything knowable when the range is displayed — the
## prospect profile and the exact Maximum Potential, which together fix the caps
## the projection reads — and then asks, inside each such group, how wide the
## narrowest window containing 70% of the *realized* peaks has to be.
##
## That width is a property of the realized distribution, not of any projection.
## No forecast built from creation-time inputs can be narrower and still cover
## 70%, because within one group the forecast cannot distinguish the careers. If
## the sample-weighted median of those widths exceeds the §6.3 guardrail, then
## the coverage band and the width guardrail cannot both be satisfied by any
## model, and the conflict is between §6.3 and the §8.4 outcome spread rather
## than a defect in `ProjectedPeakCalculator`.
func _report_irreducible_width(samples: Array[Sample]) -> void:
	var coverage_floor: float = CalibrationTargets.projected_peak_coverage().minimum
	var groups: Dictionary = {}
	for sample in samples:
		# Maximum Potential is bucketed rather than exact. Conditioning on the
		# exact integer splits the sample into groups too small to estimate a
		# 70% window from, and a bucket two Overall points wide is still a group
		# the projection cannot tell apart in any way that matters.
		var key: String = "%s|maxpot=%d" % [
			ProspectProfile.id_of(sample.prospect),
			(sample.maximum_potential / MAX_POTENTIAL_BUCKET) * MAX_POTENTIAL_BUCKET]
		if not groups.has(key):
			groups[key] = Bucket.new()
		var bucket: Bucket = groups[key]
		bucket.peaks.append(float(sample.realized_peak))

	# A group too small to estimate a 70% window from would report a spuriously
	# narrow one, so it is excluded and its exclusion is reported.
	var widths := PackedFloat64Array()
	var weights := PackedFloat64Array()
	var covered_careers: int = 0
	var excluded: int = 0

	for key: Variant in groups.keys():
		var group: Bucket = groups[key]
		var peaks: PackedFloat64Array = group.peaks
		if peaks.size() < MINIMUM_GROUP:
			excluded += peaks.size()
			continue
		peaks.sort()
		var needed: int = int(ceilf(coverage_floor * float(peaks.size())))
		needed = clampi(needed, 1, peaks.size())
		var best: float = INF
		for start in range(peaks.size() - needed + 1):
			best = minf(best, peaks[start + needed - 1] - peaks[start])
		widths.append(best)
		weights.append(float(peaks.size()))
		covered_careers += peaks.size()

	print("")
	print("  --- irreducible range width at the %.0f%% coverage floor ---" % (
		coverage_floor * 100.0))
	if widths.is_empty():
		print("  no group reached the minimum size; sample too small to judge.")
		return

	# Sample-weighted median: the width the median *career* would need, which is
	# what the §6.3 guardrail is stated on.
	var order: Array[int] = []
	for index in range(widths.size()):
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return widths[a] < widths[b])
	var half: float = float(covered_careers) / 2.0
	var running: float = 0.0
	var weighted_median: float = widths[order[order.size() - 1]]
	for index in order:
		running += weights[index]
		if running >= half:
			weighted_median = widths[index]
			break

	var plain: PackedFloat64Array = widths.duplicate()
	plain.sort()
	print("  groups=%d  careers=%d  excluded_small_groups=%d" % [
		widths.size(), covered_careers, excluded])
	print("  irreducible width: weighted median=%.1f  p25=%.1f  p50=%.1f  p75=%.1f  max=%.1f" % [
		weighted_median,
		CalibrationStatistics.percentile(plain, 0.25),
		CalibrationStatistics.percentile(plain, 0.50),
		CalibrationStatistics.percentile(plain, 0.75),
		plain[plain.size() - 1]])
	print("  §6.3 median-width guardrail is %.0f-%.0f Overall points." % [
		CalibrationTargets.projected_peak_median_width().minimum,
		CalibrationTargets.projected_peak_median_width().maximum])
	if weighted_median > CalibrationTargets.projected_peak_median_width().maximum:
		print("  => UNREACHABLE: no creation-time model can hold median width inside the")
		print("     guardrail and still reach the coverage floor on this population.")
	else:
		print("  => reachable in principle; the gap is the model, not the requirement.")


## Score every ordered multiplier pair and print those that satisfy all three
## §6.3 measures, plus the best near-misses so an unreachable band is visible as
## unreachable rather than as an empty table.
func _report_surface(
	samples: Array[Sample],
	multipliers: PackedFloat64Array,
	title: String,
) -> void:
	var coverage_band: CalibrationBand = CalibrationTargets.projected_peak_coverage()
	var width_band: CalibrationBand = CalibrationTargets.projected_peak_median_width()
	var bias_band: CalibrationBand = CalibrationTargets.projected_peak_signed_bias()

	print("")
	print("  === %s surface: %d careers ===" % [title, samples.size()])
	print("  %-6s %-6s %-9s %-9s %-9s %s" % [
		"low", "high", "coverage", "width", "bias", "verdict"])

	var accepted: Array[Score] = []
	var width_and_bias_ok: Array[Score] = []
	for low_index in range(multipliers.size()):
		for high_index in range(low_index, multipliers.size()):
			var score: Score = _score(samples, low_index, high_index)
			score.low = multipliers[low_index]
			score.high = multipliers[high_index]
			var width_ok: bool = width_band.contains(score.median_width)
			var bias_ok: bool = bias_band.contains(score.median_bias)
			if width_ok and bias_ok:
				width_and_bias_ok.append(score)
			if not (width_ok and bias_ok and coverage_band.contains(score.coverage)):
				continue
			score.margin = minf(
				minf(score.coverage - coverage_band.minimum,
					coverage_band.maximum - score.coverage),
				minf((bias_band.maximum - absf(score.median_bias)) / 2.0,
					minf(score.median_width - width_band.minimum,
						width_band.maximum - score.median_width) / 6.0))
			accepted.append(score)

	accepted.sort_custom(func(a: Score, b: Score) -> bool: return a.margin > b.margin)

	if accepted.is_empty():
		print("  NO PAIR SATISFIES ALL THREE BANDS.")
		print("  Best pairs with width and bias in band, ranked by coverage:")
		width_and_bias_ok.sort_custom(
			func(a: Score, b: Score) -> bool: return a.coverage > b.coverage)
		for index in range(mini(10, width_and_bias_ok.size())):
			var near: Score = width_and_bias_ok[index]
			print("  %-6.2f %-6.2f %-9.4f %-9.2f %+-9.2f  coverage %s of band" % [
				near.low, near.high, near.coverage, near.median_width, near.median_bias,
				"below" if near.coverage < coverage_band.minimum else "above"])
		if width_and_bias_ok.is_empty():
			print("  no pair satisfies width and bias together either.")
		return

	for index in range(mini(12, accepted.size())):
		var row: Score = accepted[index]
		print("  %-6.2f %-6.2f %-9.4f %-9.2f %+-9.2f PASS (margin %.4f)" % [
			row.low, row.high, row.coverage, row.median_width, row.median_bias, row.margin])
	print("  %d of %d pairs satisfy coverage, width, and bias simultaneously." % [
		accepted.size(), multipliers.size() * (multipliers.size() + 1) / 2])


func _score(samples: Array[Sample], low_index: int, high_index: int) -> Score:
	var covered: int = 0
	var widths := PackedFloat64Array()
	var biases := PackedFloat64Array()

	for sample in samples:
		var low: int = sample.predicted[low_index]
		var high: int = sample.predicted[high_index]
		# The displayed range obeys the §6.3 rule 4 ordering bounds, so the sweep
		# scores the range a player would actually be shown rather than a raw
		# model output that the ordering rules would have moved.
		low = clampi(low, sample.current_overall, sample.maximum_potential)
		high = clampi(maxi(high, low), sample.current_overall, sample.maximum_potential)
		if sample.realized_peak >= low and sample.realized_peak <= high:
			covered += 1
		widths.append(float(high - low))
		biases.append(float(sample.realized_peak) - float(low + high) / 2.0)

	widths.sort()
	biases.sort()
	var score := Score.new()
	score.coverage = float(covered) / float(maxi(1, samples.size()))
	score.median_width = CalibrationStatistics.percentile(widths, 0.50)
	score.median_bias = CalibrationStatistics.percentile(biases, 0.50)
	return score
