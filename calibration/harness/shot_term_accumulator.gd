class_name ShotTermAccumulator
extends RefCounted

## The decomposed terms of `ShotResolver`, summed over a run.
##
## `PppDecomposition` answers "what shots were taken, and did they go in" from
## the ledger. It cannot answer *why* a shot went in at the rate it did, because
## the ledger records the outcome and not the arithmetic: a shot's make
## probability is a §13.1 baseline for the shooter's capability, less the §12.3
## contest penalty, plus the advantage the offence built, less catch, movement,
## fatigue and shot-clock penalties, plus a shot-selection term.
##
## Those terms are what separates "this level shoots worse because its players
## are worse" from "this level shoots worse because something in the shared
## profile is treating it differently". The first is the model working; the
## second is a defect. Reading them off `ShotResolver` itself — rather than
## rebuilding the same arithmetic here — is what keeps this honest: a second
## copy would be free to disagree with production and would still add up.
##
## The terms arrive through `ShotResolver.probe`, which is observation-only.
## Attach with `attach()`, run, and always `ShotResolver.detach_probe()`.
##
## **Two denominators, and they are not the same.** `contests` counts every
## field-goal attempt, because §12.3 builds a contest for all of them.
## `shots` counts attempts that reached make resolution, which excludes blocked
## attempts, because §12.7 resolves the block first. Any rate published from
## this class states which one it used.

# --- contest-side terms, denominated in attempts ----------------------------
var contests: int = 0
var interior_contests: int = 0
var pressure_sum: float = 0.0
var defender_capability_sum: float = 0.0
var reach_sum: float = 0.0
var help_pressure_sum: float = 0.0
var advantage_relief_sum: float = 0.0
var contest_penalty_sum: float = 0.0
var legal_contact_sum: float = 0.0
var block_eligible: int = 0

# --- make-side terms, denominated in unblocked attempts ---------------------
var shots: int = 0
var makes: int = 0
var shooter_capability_sum: float = 0.0
var baseline_sum: float = 0.0
var make_contest_penalty_sum: float = 0.0
var advantage_bonus_sum: float = 0.0
var catch_penalty_sum: float = 0.0
var movement_penalty_sum: float = 0.0
var fatigue_penalty_sum: float = 0.0
var clock_penalty_sum: float = 0.0
var selection_bonus_sum: float = 0.0
var probability_sum: float = 0.0
var unclamped_probability_sum: float = 0.0
## Attempts whose probability was moved by the §13.2 floor or ceiling. A level
## whose shots are routinely clamped is not being modelled by the baseline curve
## any more, which is a structural finding rather than a tuning one.
var clamped: int = 0

## Per-zone shooter capability and baseline, so "worse shooters" and "harder
## shots" can be separated inside a zone rather than only across the mix.
var zone_shots: PackedInt32Array
var zone_capability_sum: PackedFloat64Array
var zone_baseline_sum: PackedFloat64Array
var zone_probability_sum: PackedFloat64Array

## Per-contest-band defender capability, so a band's *membership* can be
## distinguished from the band's own penalty.
var band_contests: PackedInt32Array
var band_defender_capability_sum: PackedFloat64Array
var band_pressure_sum: PackedFloat64Array


func _init() -> void:
	zone_shots = _blank_int(ShotZone.COUNT)
	zone_capability_sum = _blank_float(ShotZone.COUNT)
	zone_baseline_sum = _blank_float(ShotZone.COUNT)
	zone_probability_sum = _blank_float(ShotZone.COUNT)
	band_contests = _blank_int(ContestBand.COUNT)
	band_defender_capability_sum = _blank_float(ContestBand.COUNT)
	band_pressure_sum = _blank_float(ContestBand.COUNT)


## Attaches this accumulator to shot resolution. The caller owns detaching it.
func attach() -> void:
	ShotResolver.probe = Callable(self, "record")


func record(payload: Dictionary) -> void:
	var kind: StringName = payload.get("kind", &"")
	if kind == &"contest":
		_record_contest(payload)
	elif kind == &"shot":
		_record_shot(payload)


func _record_contest(payload: Dictionary) -> void:
	contests += 1
	var interior: bool = payload["interior"]
	if interior:
		interior_contests += 1
	var band: int = payload["band"]
	var pressure: float = payload["pressure"]
	var defender_capability: float = payload["defender_capability"]
	pressure_sum += pressure
	defender_capability_sum += defender_capability
	reach_sum += payload["reach"]
	help_pressure_sum += payload["help_pressure"]
	advantage_relief_sum += payload["advantage_relief"]
	contest_penalty_sum += payload["contest_penalty"]
	legal_contact_sum += payload["legal_contact"]
	if payload["block_eligible"]:
		block_eligible += 1
	band_contests[band] += 1
	band_defender_capability_sum[band] += defender_capability
	band_pressure_sum[band] += pressure


func _record_shot(payload: Dictionary) -> void:
	shots += 1
	if payload["made"]:
		makes += 1
	var zone: int = payload["zone"]
	var capability: float = payload["shooter_capability"]
	var baseline: float = payload["baseline"]
	var probability: float = payload["probability"]
	shooter_capability_sum += capability
	baseline_sum += baseline
	make_contest_penalty_sum += payload["contest_penalty"]
	advantage_bonus_sum += payload["advantage_bonus"]
	catch_penalty_sum += payload["catch_penalty"]
	movement_penalty_sum += payload["movement_penalty"]
	fatigue_penalty_sum += payload["fatigue_penalty"]
	clock_penalty_sum += payload["clock_penalty"]
	selection_bonus_sum += payload["selection_bonus"]
	probability_sum += probability
	unclamped_probability_sum += payload["unclamped_probability"]
	if payload["clamped"]:
		clamped += 1
	zone_shots[zone] += 1
	zone_capability_sum[zone] += capability
	zone_baseline_sum[zone] += baseline
	zone_probability_sum[zone] += probability


# --- means -------------------------------------------------------------------

func mean_pressure() -> float:
	return _mean(pressure_sum, contests)


func mean_defender_capability() -> float:
	return _mean(defender_capability_sum, contests)


func mean_contest_penalty() -> float:
	return _mean(contest_penalty_sum, contests)


func mean_legal_contact() -> float:
	return _mean(legal_contact_sum, contests)


func mean_shooter_capability() -> float:
	return _mean(shooter_capability_sum, shots)


func mean_baseline() -> float:
	return _mean(baseline_sum, shots)


func mean_probability() -> float:
	return _mean(probability_sum, shots)


func realized_percentage() -> float:
	return _mean(float(makes), shots)


func clamped_share_value() -> float:
	return _mean(float(clamped), shots)


## The mean of every term, in the order `ShotResolver.resolve` applies them.
##
## These sum to `mean_probability()` up to the §13.2 clamp, so the difference
## between the sum and the mean probability *is* the clamp's contribution — the
## one term that is not an addend. Publishing both is what makes this an
## attribution rather than a list.
func term_means() -> Dictionary:
	return {
		"baseline": mean_baseline(),
		"contest_penalty": -_mean(make_contest_penalty_sum, shots),
		"advantage_bonus": _mean(advantage_bonus_sum, shots),
		"catch_penalty": -_mean(catch_penalty_sum, shots),
		"movement_penalty": -_mean(movement_penalty_sum, shots),
		"fatigue_penalty": -_mean(fatigue_penalty_sum, shots),
		"clock_penalty": -_mean(clock_penalty_sum, shots),
		"selection_bonus": _mean(selection_bonus_sum, shots),
	}


## The residual between the summed terms and the realized mean probability.
## Non-zero only through the §13.2 clamp; a runner publishes it so that a term
## silently going missing cannot hide inside a plausible total.
func term_residual() -> float:
	var total: float = 0.0
	for value: float in term_means().values():
		total += value
	return mean_probability() - total


func zone_capability(zone: int) -> float:
	return _mean(zone_capability_sum[zone], zone_shots[zone])


func zone_baseline(zone: int) -> float:
	return _mean(zone_baseline_sum[zone], zone_shots[zone])


func zone_probability(zone: int) -> float:
	return _mean(zone_probability_sum[zone], zone_shots[zone])


func band_defender_capability(band: int) -> float:
	return _mean(band_defender_capability_sum[band], band_contests[band])


func band_pressure(band: int) -> float:
	return _mean(band_pressure_sum[band], band_contests[band])


func to_dictionary() -> Dictionary:
	var payload: Dictionary = {
		"contests": contests,
		"interior_share": _mean(float(interior_contests), contests),
		"mean_pressure": mean_pressure(),
		"mean_defender_capability": mean_defender_capability(),
		"mean_reach": _mean(reach_sum, contests),
		"mean_help_pressure": _mean(help_pressure_sum, contests),
		"mean_advantage_relief": _mean(advantage_relief_sum, contests),
		"mean_contest_penalty": mean_contest_penalty(),
		"mean_legal_contact": mean_legal_contact(),
		"block_eligible_share": _mean(float(block_eligible), contests),
		"shots": shots,
		"makes": makes,
		"realized_percentage": realized_percentage(),
		"mean_shooter_capability": mean_shooter_capability(),
		"mean_baseline": mean_baseline(),
		"mean_probability": mean_probability(),
		"mean_unclamped_probability": _mean(unclamped_probability_sum, shots),
		"clamped_share": _mean(float(clamped), shots),
		"term_residual": term_residual(),
	}
	var means: Dictionary = term_means()
	for key: String in means:
		var contribution: float = means[key]
		payload["term.%s" % key] = contribution
	for zone in range(ShotZone.COUNT):
		var zone_name: String = ShotZone.IDS[zone]
		payload["zone.%s.shots" % zone_name] = zone_shots[zone]
		payload["zone.%s.capability" % zone_name] = zone_capability(zone)
		payload["zone.%s.baseline" % zone_name] = zone_baseline(zone)
		payload["zone.%s.probability" % zone_name] = zone_probability(zone)
	for band in range(ContestBand.COUNT):
		var band_name: String = ContestBand.IDS[band]
		payload["band.%s.contests" % band_name] = band_contests[band]
		payload["band.%s.defender_capability" % band_name] = band_defender_capability(band)
		payload["band.%s.pressure" % band_name] = band_pressure(band)
	return payload


func _mean(total: float, count: int) -> float:
	return 0.0 if count <= 0 else total / float(count)


func _blank_int(size: int) -> PackedInt32Array:
	var values := PackedInt32Array()
	values.resize(size)
	values.fill(0)
	return values


func _blank_float(size: int) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	values.resize(size)
	values.fill(0.0)
	return values
