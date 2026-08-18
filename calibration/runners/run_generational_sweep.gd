extends SceneTree

## Two-lever sweep for the §8.4 rare-generational band (`BALANCE_SPEC.md` §8.4,
## §8.1, §9.5).
##
## The root-cause diagnostics identify exactly two levers that can move the
## rare-generational peak, and rule the others out with measurements rather than
## with argument:
##
##   - **Lifetime opportunity.** The cohort spends what it is granted and stops
##     about three Overall short of its own ceiling. The §9.1 cost table prices
##     each further Overall point near 160 AP at this altitude, so the shortfall
##     converts directly into a required grant.
##   - **Ceiling selection pressure (§8.1).** About a quarter of the cohort
##     draws a ceiling whose Maximum Potential sits below the band it is
##     supposed to reach. Those careers fill every cap, strand hundreds of AP,
##     and peak in the mid-eighties. More opportunity buys them nothing.
##
## Allocation is not a third lever: the Overall-maximising bound beats the
## realized career by well under one Overall point, so no reordering of spending
## can close a three-point gap.
##
## This runner measures a grid of the two together on one deterministic seed
## range, because they interact — opportunity is wasted without ceiling, and
## ceiling is unreachable without opportunity — and a one-at-a-time sweep would
## report the wrong optimum for each.
##
## It sweeps through `CareerSimulator`'s diagnostic override rows and never
## edits a committed constant, so the tuning range stays a tuning range.
##
## Run:
##   godot --headless --path . --script res://calibration/runners/run_generational_sweep.gd -- \
##       [--careers=N] [--shard=I] [--opportunity=1.42,1.70] [--pools=2,3] [--path=4]

const DEFAULT_CAREERS: int = 250


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = CalibrationCli.parse(OS.get_cmdline_user_args())
	var careers: int = CalibrationCli.int_option(options, &"careers", DEFAULT_CAREERS)
	var shard: int = CalibrationCli.int_option(options, &"shard", 0)
	var path: int = CalibrationCli.int_option(
		options, &"path", CareerSimulator.Path.GENERATIONAL)
	var opportunities: PackedFloat64Array = _floats(
		CalibrationCli.string_option(options, &"opportunity", "1.42"))
	var pools: PackedInt32Array = _ints(
		CalibrationCli.string_option(options, &"pools", "2"))

	var profiles: BalanceProfileSet = BalanceProfileSet.default_set()
	var base: int = shard * careers
	var band: CalibrationBand = CalibrationTargets.career_peak_overall(path)

	print("")
	print("=== S8.4 two-lever sweep: %s ===" % CareerSimulator.path_id(path))
	print("  seeds=%d..%d careers-per-cell=%d band=%.0f..%.0f"
		% [base + 1, base + careers, careers, band.minimum, band.maximum])
	print("")
	print("  opp   pool     p10    p50    p90    max   >95     AP    attain  atCap  grdSea")

	for pool in pools:
		for opportunity in opportunities:
			_measure_cell(profiles, path, base, careers, opportunity, pool)

	print("")
	quit(0)


func _measure_cell(
	profiles: BalanceProfileSet,
	path: int,
	base: int,
	careers: int,
	opportunity: float,
	pool: int,
) -> void:
	var simulator := CareerSimulator.new(profiles)
	simulator.capture_diagnostics = true
	simulator.path_opportunity_override = _opportunity_row(path, opportunity)
	simulator.path_ceiling_pool_override = _pool_row(path, pool)

	var peaks := PackedFloat64Array()
	var granted: float = 0.0
	var attainment: float = 0.0
	var at_cap: float = 0.0
	var guardrail: float = 0.0
	var above_95: int = 0
	for index in range(careers):
		var career: CareerSimulator.CareerResult = simulator.simulate(
			base + index + 1, DevelopmentExecutor.Value.MANUAL, path)
		peaks.append(float(career.peak_overall))
		granted += career.total_ap_granted
		attainment += career.peak_cap_attainment
		at_cap += float(career.attributes_at_cap_at_peak)
		guardrail += float(career.guardrail_seasons)
		if career.peak_overall > 95:
			above_95 += 1

	peaks.sort()
	var sample: float = float(maxi(1, careers))
	print("  %.2f  %d      %6.1f %6.1f %6.1f %6.1f %5d %7.0f  %6.3f %6.2f %7.2f" % [
		opportunity, pool,
		CalibrationStatistics.percentile(peaks, 0.10),
		CalibrationStatistics.percentile(peaks, 0.50),
		CalibrationStatistics.percentile(peaks, 0.90),
		peaks[peaks.size() - 1],
		above_95,
		granted / sample,
		attainment / sample,
		at_cap / sample,
		guardrail / sample])
	print("      peak histogram 86..96: %s" % _histogram(peaks, 86, 96))


## A full override row that changes only the swept path, so every other cohort
## in the run keeps the committed constant.
static func _opportunity_row(path: int, value: float) -> PackedFloat64Array:
	var row := PackedFloat64Array()
	for index in range(CareerSimulator.PATH_COUNT):
		row.append(CareerSimulator.PATH_OPPORTUNITY[index])
	row[path] = value
	return row


static func _pool_row(path: int, value: int) -> PackedInt32Array:
	var row := PackedInt32Array()
	for index in range(CareerSimulator.PATH_COUNT):
		row.append(CareerSimulator.PATH_CEILING_SELECTION_POOL[index])
	row[path] = value
	return row


static func _floats(raw: String) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for token in raw.split(",", false):
		var text: String = token.strip_edges()
		if text.is_valid_float():
			values.append(text.to_float())
	if values.is_empty():
		values.append(1.42)
	return values


static func _ints(raw: String) -> PackedInt32Array:
	var values := PackedInt32Array()
	for token in raw.split(",", false):
		var text: String = token.strip_edges()
		if text.is_valid_int():
			values.append(text.to_int())
	if values.is_empty():
		values.append(1)
	return values


## A compact count of realized peaks per Overall point.
##
## §8.4 forbids a spike as firmly as it forbids a miss: a cohort whose peaks all
## land on one value has been clamped rather than developed, and a median alone
## cannot show that. The histogram is printed beside every swept cell so the
## shape is visible while the lever is being chosen, not afterwards.
static func _histogram(sorted_peaks: PackedFloat64Array, low: int, high: int) -> String:
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(high - low + 2)
	for value in sorted_peaks:
		var index: int = int(value) - low
		if index < 0:
			continue
		counts[mini(index, counts.size() - 1)] += 1
	var parts: PackedStringArray = []
	for index in range(counts.size()):
		if index == counts.size() - 1:
			parts.append(">%d:%d" % [high, counts[index]])
		else:
			parts.append("%d:%d" % [low + index, counts[index]])
	return " ".join(parts)
