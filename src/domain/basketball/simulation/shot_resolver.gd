class_name ShotResolver
extends RefCounted

## Contest construction, block evaluation, and make resolution
## (`SIMULATION_SPEC.md` §12).
##
## The order matters and is fixed by the spec:
##
## 1. §12.3 builds the contest "from actual defensive positioning and
##    capabilities", never as flavour chosen after the probability is known.
## 2. §12.7 evaluates the block *before* ordinary make resolution when the
##    defender has a valid block opportunity.
## 3. §12.6 then resolves make quality and maps it to a probability inside the
##    §13.2 floors and ceilings for that shot family.
##
## Every magnitude is read from `SimulationBalanceProfile`. §30.2 lists moving
## the anonymous literals out of shot resolution as outstanding work; the shape
## of the model lives here and the numbers live there.

## Optional diagnostic sink for the decomposed terms of a contest and a make
## (`BALANCE_SPEC.md` §14.1 accounting decomposition).
##
## **Observation only, and structurally so.** The probe is null by default, so
## an ordinary simulation never allocates or calls anything here. When a
## calibration runner attaches one, it is invoked *after* every term and the
## draw are already decided, it is passed values that have already been used,
## and its return value is discarded — there is no branch anywhere below whose
## outcome depends on whether a probe is attached. That is what lets a
## diagnostic publish "mean shooter capability" and "mean movement penalty"
## without those numbers being reconstructed by a second, drifting copy of this
## arithmetic, and without a calibration target acquiring a path into
## production probability code.
##
## `build_contest` fires once per field-goal attempt; `resolve` fires once per
## attempt that was *not* blocked, because §12.7 evaluates the block first. A
## consumer that wants per-attempt denominators must use the contest record.
##
## It is `static` so that attaching one costs production nothing: the resolver
## is constructed deep inside `PossessionEngine`, and threading a diagnostic
## argument through `MatchEngine`, `MatchSession` and `PossessionEngine` would
## put a calibration concern into three production signatures to serve a
## measurement. A runner sets it, runs, and clears it in the same function;
## `detach_probe` exists so that clearing it is not spelled differently in
## different places. Nothing in `src/` ever sets it.
static var probe: Callable = Callable()


## Clears the diagnostic probe. Always safe, and idempotent.
static func detach_probe() -> void:
	probe = Callable()

var _capability: CapabilityCalculator
var _body: BodyEffects
var _balance: SimulationBalanceProfile


func _init(
	p_capability: CapabilityCalculator,
	p_body: BodyEffects,
	p_balance: SimulationBalanceProfile,
) -> void:
	_capability = p_capability
	_body = p_body
	_balance = p_balance


func build_contest(
	context: PossessionContext,
	shooter_id: StringName,
	zone: int,
	advantage: AdvantageResult,
) -> ShotContest:
	var shooter: PlayerMatchProfile = context.offense_profile(shooter_id)
	var defender_id: StringName = context.defender_of(shooter_id)
	var defender: PlayerMatchProfile = context.defense_profile(defender_id)
	var defender_runtime: PlayerMatchRuntime = context.defense_runtime(defender_id)

	var interior: bool = ShotZone.is_paint(zone)
	var contest_capability: float = (
		_capability.capability_of(CapabilityKey.Value.INTERIOR_POSITIONING, defender, defender_runtime)
		if interior
		else _capability.capability_of(CapabilityKey.Value.PERIMETER_CONTEST, defender, defender_runtime)
	)
	# §6.1 reach: contest arrival quality and finish access over a defender.
	var reach: float = _body.reach_edge(defender.body, shooter.body)

	var helper_id: StringName = &""
	var help_pressure: float = 0.0
	if interior:
		var help_share: float = CoverageFamily.help_share(context.defense.game_plan.coverage_family)
		var best: float = 0.0
		for candidate_id in context.defense_on_court():
			if candidate_id == defender_id:
				continue
			var helper: PlayerMatchProfile = context.defense_profile(candidate_id)
			var helper_runtime: PlayerMatchRuntime = context.defense_runtime(candidate_id)
			var protection: float = _capability.capability_of(
				CapabilityKey.Value.RIM_PROTECTION, helper, helper_runtime)
			if protection > best:
				best = protection
				helper_id = candidate_id
		help_pressure = best * help_share
		if help_pressure <= 0.0:
			helper_id = &""

	# Pressure is centred on `contest_base_pressure` and moved by how much the
	# defender's contest capability differs from the middle of the scale. Read
	# raw, an ordinary defender's capability sits near 0.6, which would band
	# every ordinary jumper as `HEAVY` — the centring is what keeps an average
	# contest average. The advantage the offence built is what relieves it.
	var pressure: float = clampf(
		_balance.contest_base_pressure
		+ (contest_capability - 0.5) * _balance.contest_capability_span
		+ reach
		+ help_pressure * _balance.contest_help_weight
		- advantage.quality_share() * _balance.contest_advantage_relief,
		0.0,
		1.0)
	var band: int = ContestBand.from_pressure(pressure)
	# §12.7 evaluates a block only when the defender has a *valid* block
	# opportunity. Proximity is that validity: an unpressured attempt has no
	# defender close enough to reach it.
	var block_eligible: bool = (
		(interior and band >= ContestBand.Value.LIGHT)
		or band >= ContestBand.Value.HEAVY
	)
	var legal_contact: float = clampf(
		(_balance.interior_contact_base + pressure * _balance.interior_contact_pressure_share)
		if interior
		else (_balance.perimeter_contact_base + pressure * _balance.perimeter_contact_pressure_share),
		0.0,
		1.0)
	if not probe.is_null():
		probe.call({
			"kind": &"contest",
			"zone": zone,
			"interior": interior,
			"band": band,
			"pressure": pressure,
			"defender_capability": contest_capability,
			"reach": reach,
			"help_pressure": help_pressure * _balance.contest_help_weight,
			"advantage_relief": advantage.quality_share() * _balance.contest_advantage_relief,
			"contest_penalty": _balance.contest_penalty(band),
			"legal_contact": legal_contact,
			"block_eligible": block_eligible,
		})
	return ShotContest.new(
		band, defender_id, helper_id, block_eligible,
		band >= ContestBand.Value.MODERATE, pressure, legal_contact)


## §12.7. "Blocking is primary. Interior or Perimeter Defense selects
## positioning quality by shot area. Vertical and reach/body profile affect
## access. Shooter separation, release type, height, strength, and dunk force
## resist the block."
func resolve_block(
	context: PossessionContext,
	shooter_id: StringName,
	zone: int,
	dunk: bool,
	contest: ShotContest,
	advantage: AdvantageResult,
	random_source: RandomSource,
) -> StringName:
	if not contest.block_eligible:
		return &""
	var blocker_id: StringName = (
		contest.helper_id if not contest.helper_id.is_empty() else contest.primary_defender_id)
	if blocker_id.is_empty():
		return &""
	var shooter: PlayerMatchProfile = context.offense_profile(shooter_id)
	var shooter_runtime: PlayerMatchRuntime = context.offense_runtime(shooter_id)
	var blocker: PlayerMatchProfile = context.defense_profile(blocker_id)
	var blocker_runtime: PlayerMatchRuntime = context.defense_runtime(blocker_id)

	var protection: float = _capability.capability_of(
		CapabilityKey.Value.RIM_PROTECTION, blocker, blocker_runtime)
	var access: float = _body.reach_edge(blocker.body, shooter.body)
	var resistance: float = _capability.shot_capability(shooter, shooter_runtime, zone) * 0.5
	if dunk:
		resistance += _capability.capability_of(
			CapabilityKey.Value.DUNK_THREAT, shooter, shooter_runtime) * 0.5
	else:
		resistance += _capability.capability_of(
			CapabilityKey.Value.BURST_REACH, shooter, shooter_runtime) * 0.3
	resistance += advantage.quality_share() * 0.35

	# The conversion rate is conditional on a valid opportunity, so the strength
	# of that opportunity — how close the contest actually was — scales it.
	var units: float = _capability.differential_units(protection + access, resistance)
	var opportunity: float = clampf(
		_balance.block_opportunity_base_share
		+ contest.pressure * _balance.block_opportunity_pressure_share,
		0.0,
		1.0)
	var probability: float = _balance.opposed_probability(
		_balance.block_conversion_base * opportunity,
		units,
		_balance.block_conversion_floor,
		_balance.block_conversion_ceiling)
	if random_source.next_float() < probability:
		return blocker_id
	return &""


## §12.6 make resolution. `catch_quality` and `movement_load` are the §12.2
## context terms the possession supplies from what actually happened.
func resolve(
	context: PossessionContext,
	shooter_id: StringName,
	zone: int,
	dunk: bool,
	contest: ShotContest,
	advantage: AdvantageResult,
	catch_quality: float,
	movement_load: float,
	random_source: RandomSource,
) -> ShotOutcome:
	var shooter: PlayerMatchProfile = context.offense_profile(shooter_id)
	var runtime: PlayerMatchRuntime = context.offense_runtime(shooter_id)
	var capability: float = _capability.shot_capability(shooter, runtime, zone)
	if dunk:
		capability = _capability.capability_of(CapabilityKey.Value.DUNK_THREAT, shooter, runtime)

	var baseline: float = _balance.shot_baseline(zone, capability, dunk)
	var contest_penalty: float = _balance.contest_penalty(contest.band)
	var advantage_bonus: float = advantage.quality_share() * _balance.advantage_shot_bonus_max
	var catch_penalty: float = (
		clampf(1.0 - catch_quality, 0.0, 1.0) * _balance.catch_quality_penalty_max)
	var movement_penalty: float = (
		clampf(movement_load, 0.0, 1.0) * _balance.movement_penalty_max)
	var fatigue_penalty: float = (
		clampf(runtime.acute_fatigue / 100.0, 0.0, 1.0) * _balance.fatigue_shot_penalty_max)
	var clock_penalty: float = (
		_clock_desperation(context) * _balance.clock_desperation_penalty_max)
	# §12.2 shot selection: Offensive IQ improves the circumstances of the
	# attempt. Bounded by the advantage bonus so it cannot replace the shot.
	var selection: float = _capability.shot_selection(shooter, runtime, zone)
	var selection_bonus: float = (selection - 0.5) * _balance.advantage_shot_bonus_max * 0.5
	var probability: float = (
		baseline
		- contest_penalty
		+ advantage_bonus
		- catch_penalty
		- movement_penalty
		- fatigue_penalty
		- clock_penalty
		+ selection_bonus)
	# §19.4 deliberately contributes nothing here. A term added to the make
	# probability of every home attempt is not officiating, communication,
	# composure or familiarity — it is the flat shooting bonus §19.2 rules out
	# for Coach Trust in the same breath, and an identical physical shot must go
	# in at the same rate in both buildings. The venue reaches a shot only
	# through §12.2 catch quality, which is a property of the delivery and is
	# already in `catch_quality` above.

	var unclamped: float = probability
	probability = clampf(
		probability, _balance.shot_floor(zone, dunk), _balance.shot_ceiling(zone, dunk))
	var made: bool = random_source.next_float() < probability
	if not probe.is_null():
		probe.call({
			"kind": &"shot",
			"zone": zone,
			"dunk": dunk,
			"band": contest.band,
			"made": made,
			"shooter_capability": capability,
			"baseline": baseline,
			"contest_penalty": contest_penalty,
			"advantage_bonus": advantage_bonus,
			"catch_penalty": catch_penalty,
			"movement_penalty": movement_penalty,
			"fatigue_penalty": fatigue_penalty,
			"clock_penalty": clock_penalty,
			"selection_bonus": selection_bonus,
			"unclamped_probability": unclamped,
			"probability": probability,
			"clamped": not is_equal_approx(unclamped, probability),
		})
	return ShotOutcome.new(
		made, ShotZone.points_for(zone), probability, zone, dunk, false, &"", contest)


func _clock_desperation(context: PossessionContext) -> float:
	var threshold: float = float(_balance.desperation_clock_ms)
	if threshold <= 0.0:
		return 0.0
	var remaining: float = float(context.state.shot_clock_ms)
	if remaining >= threshold:
		return 0.0
	return clampf(1.0 - remaining / threshold, 0.0, 1.0)
