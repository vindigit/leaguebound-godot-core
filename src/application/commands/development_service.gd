class_name DevelopmentService
extends RefCounted

## Application service for development (`GODOT_TDD.md` §5.8).
##
## "Grants AP-equivalent opportunity, applies allocation, enforces career-year
## receipts, writes the source ledger."
##
## One service serves all three executors. §9.7 permits exactly one development
## contract, and the way that is kept true here is that the *manual* path, the
## full-detail allocator, and the aggregate executor all call these same
## methods — they differ only in who decides where the points go. An allocator
## cannot reach past this service to write a rating, and it has no cheaper cost
## table to reach for.

var _profiles: BalanceProfileSet


func _init(p_profiles: BalanceProfileSet = null) -> void:
	_profiles = p_profiles if p_profiles != null else BalanceProfileSet.default_set()


func profiles() -> BalanceProfileSet:
	return _profiles


## Grant one season's AP-equivalent opportunity.
##
## Drawn from the §9.5 seasonal band for the phase, scaled by the §7.2 prospect
## growth-availability multiplier. §7.2 is explicit that profile multipliers
## "change the number and quality of opportunities generated, not the AP cost of
## a rating" — so the multiplier lands here, on the grant, and never on the cost
## table.
##
## Returns the granted amount, or 0.0 when the career year's generic offseason
## development has already resolved.
func grant_seasonal_opportunity(
	state: PlayerDevelopmentState,
	career_year: int,
	phase: int,
	executor: int,
	source_stream: RandomSource,
) -> float:
	assert(CareerPhase.is_valid(phase), "unknown career phase")
	assert(DevelopmentExecutor.is_valid(executor), "unknown development executor")

	# §9.5: one career year permits one generic offseason-development phase.
	# Changing levels, assignment, recall, release, or a second offseason entry
	# cannot rerun it.
	if not state.receipts.claim(
			career_year, CareerYearReceipts.Resolution.GENERIC_OFFSEASON_DEVELOPMENT):
		return 0.0

	var progression: ProgressionProfile = _profiles.progression
	var low: int = progression.seasonal_ap_minimum[phase]
	var high: int = progression.seasonal_ap_maximum[phase]
	var base: float = RandomDraw.float_in(source_stream, float(low), float(high))

	var growth_phase: int = CareerPhase.growth_phase_of(phase)
	var availability: float = progression.growth_availability_for(state.prospect, growth_phase)
	var granted: float = base * availability

	state.point_ledger.grant(
		career_year,
		AttributePointSource.Value.OFFSEASON,
		executor,
		granted,
		state.balance_version,
		"phase=%s" % CareerPhase.id_of(phase)
	)
	return granted


## Grant opportunity from a named source without the offseason receipt, for
## training and game participation which occur many times per season.
func grant_opportunity(
	state: PlayerDevelopmentState,
	career_year: int,
	source: int,
	executor: int,
	amount: float,
	note: String = "",
) -> void:
	state.point_ledger.grant(
		career_year, source, executor, amount, state.balance_version, note)


## Grant §9.6 game-participation development, bounded by its seasonal cap.
##
## §9.6 sets the cap at 12 AP-equivalent in high school, 16 in college and the
## alternative routes, and 20 in top domestic professional basketball, and
## "played and simulated games share the same pool and formula" — so the cap is
## per player-season, not per game and not per executor.
##
## Returns the amount actually credited, which is the requested amount trimmed
## to whatever the season has left. The trim is silent by design: a season that
## offered more development than games can carry has not committed a violation,
## it has simply produced opportunity that has to arrive from a source that can
## account for it. The caller decides where the remainder goes, and the ledger
## records both halves separately so the split is inspectable.
func grant_game_development(
	state: PlayerDevelopmentState,
	career_year: int,
	phase: int,
	executor: int,
	amount: float,
	note: String = "",
) -> float:
	assert(CareerPhase.is_valid(phase), "unknown career phase")
	assert(DevelopmentExecutor.is_valid(executor), "unknown development executor")
	assert(amount >= 0.0, "game participation cannot remove development")

	var cap: float = float(_profiles.progression.game_development_cap[phase])
	var already: float = state.point_ledger.granted_from(
		career_year, AttributePointSource.Value.GAME)
	var granted: float = minf(amount, maxf(0.0, cap - already))
	if granted <= 0.0:
		return 0.0
	state.point_ledger.grant(
		career_year, AttributePointSource.Value.GAME, executor, granted,
		state.balance_version, note)
	return granted


## AP-equivalent granted in one career year against the §9.5 seasonal band.
func seasonal_granted_total(state: PlayerDevelopmentState, career_year: int) -> float:
	return state.point_ledger.granted_in_year(career_year)


## Whether the season's granted total has passed the §9.5 upper guardrail.
##
## "The upper guardrail is not a hard currency cap. It triggers a balance
## warning and requires the source ledger to explain why the season was
## exceptional." So this reports; it does not block.
func exceeds_seasonal_guardrail(
	state: PlayerDevelopmentState,
	career_year: int,
	phase: int,
) -> bool:
	return (seasonal_granted_total(state, career_year)
		> float(_profiles.progression.seasonal_ap_guardrail[phase]))


## Whether the source ledger explains an exceptional season (§9.5).
##
## The generic offseason grant explains nothing. It is what every season of that
## phase receives and its note names only the phase, so a season that passed its
## guardrail on the strength of the offseason phase alone would be "explained"
## by a note that says nothing about why it was exceptional. A breach is only
## explained when some grant that is *not* the generic offseason phase carries a
## note naming what produced it.
##
## An ordinary season is vacuously explained: there is nothing to justify.
func seasonal_guardrail_is_explained(
	state: PlayerDevelopmentState,
	career_year: int,
	phase: int,
) -> bool:
	if not exceeds_seasonal_guardrail(state, career_year, phase):
		return true
	for entry in state.point_ledger.entries():
		if entry.career_year != career_year or not entry.is_grant():
			continue
		if entry.source == AttributePointSource.Value.OFFSEASON:
			continue
		if entry.source == AttributePointSource.Value.AT_CAP_CONVERSION:
			continue
		if not entry.note.is_empty():
			return true
	return false


## The §9.5 balance warning for one season, or an empty string when the season
## was ordinary.
##
## §9.5 requires the guardrail to "trigger a balance warning" and the ledger to
## "explain why the season was exceptional". Returning the explanation inside
## the warning is what makes those one thing rather than two: a caller cannot
## surface the warning without also surfacing what the ledger said, and a breach
## the ledger cannot account for says so in the text rather than passing
## silently.
func seasonal_guardrail_warning(
	state: PlayerDevelopmentState,
	career_year: int,
	phase: int,
) -> String:
	if not exceeds_seasonal_guardrail(state, career_year, phase):
		return ""

	var granted: float = seasonal_granted_total(state, career_year)
	var guardrail: int = _profiles.progression.seasonal_ap_guardrail[phase]
	var reasons: PackedStringArray = []
	for entry in state.point_ledger.entries():
		if entry.career_year != career_year or not entry.is_grant():
			continue
		if entry.source == AttributePointSource.Value.OFFSEASON:
			continue
		if entry.source == AttributePointSource.Value.AT_CAP_CONVERSION:
			continue
		if entry.note.is_empty() or reasons.has(entry.note):
			continue
		reasons.append("%s: %s" % [AttributePointSource.id_of(entry.source), entry.note])

	var head: String = (
		"career year %d in %s granted %.1f AP-equivalent against the §9.5 guardrail of %d"
			% [career_year, CareerPhase.id_of(phase), granted, guardrail])
	if reasons.is_empty():
		return "%s with no source-ledger explanation" % head
	return "%s: %s" % [head, "; ".join(reasons)]


## Spend general AP to raise one attribute by `points` whole ratings.
##
## Caps are checked before currency is consumed (§9.1). Allocation is permanent
## — there is no attribute respec — so nothing here can reverse it.
## Returns the number of whole points actually applied.
func spend_general_ap(
	state: PlayerDevelopmentState,
	attribute: int,
	points: int,
	career_year: int,
	executor: int,
) -> int:
	assert(points >= 0, "a spend raises an attribute")
	var progression: ProgressionProfile = _profiles.progression
	var applied: int = 0

	for _step in range(points):
		var current: int = state.attributes.get_rating(attribute)
		if not state.caps.has_room(attribute, current) or current >= Rating.MAXIMUM:
			break
		var cost: int = AttributeCostTable.cost_of_next_point(current, progression)
		if float(cost) > state.point_ledger.balance():
			break
		state.point_ledger.spend(
			career_year, executor, attribute, cost, state.balance_version)
		state.attributes.set_rating(attribute, current + 1)
		applied += 1

	return applied


## Apply focused direct progress to one attribute (§9.2).
##
## "One direct-progress unit fills one AP of the current upgrade cost. When the
## bar reaches the required cost, the rating increases by one and surplus
## progress carries into the next eligible point."
##
## At cap, unresolved direct progress converts to general AP at 50% efficiency,
## "rounded down only at the end of the event". That prevents a cap from
## deleting an earned reward without making focused training identical to
## general AP.
func apply_direct_progress(
	state: PlayerDevelopmentState,
	attribute: int,
	units: float,
	career_year: int,
	executor: int,
) -> int:
	assert(units >= 0.0, "direct progress cannot be negative")
	var progression: ProgressionProfile = _profiles.progression

	state.progress.add_units(attribute, units)
	var gained: int = 0

	while true:
		var current: int = state.attributes.get_rating(attribute)
		if not state.caps.has_room(attribute, current) or current >= Rating.MAXIMUM:
			break
		var required: int = AttributeCostTable.cost_of_next_point(current, progression)
		if state.progress.units_for(attribute) + 0.000001 < float(required):
			break
		# Surplus stays on the accumulator and carries into the next point.
		state.progress.consume_units(attribute, float(required))
		state.attributes.set_rating(attribute, current + 1)
		gained += 1
		state.point_ledger.debit(
			career_year,
			AttributePointSource.Value.TRAINING,
			executor,
			float(required),
			state.balance_version,
			attribute,
			"direct progress resolved"
		)

	var at_cap: bool = (
		not state.caps.has_room(attribute, state.attributes.get_rating(attribute))
		or state.attributes.get_rating(attribute) >= Rating.MAXIMUM
	)
	if at_cap:
		var stranded: float = state.progress.units_for(attribute)
		if stranded > 0.0:
			# Round down only at the end of the event (§9.2).
			var converted: int = int(floorf(
				stranded * progression.at_cap_conversion_efficiency))
			state.progress.clear(attribute)
			if converted > 0:
				state.point_ledger.grant(
					career_year,
					AttributePointSource.Value.AT_CAP_CONVERSION,
					executor,
					float(converted),
					state.balance_version,
					"direct progress converted at cap"
				)

	return gained


## Resolve the once-per-career-year natural development or decline step.
## Delegates to `AgingResolver`, which owns the §10.2/§10.3 curves and the
## shared receipt.
func resolve_natural_annual(
	state: PlayerDevelopmentState,
	career_year: int,
	executor: int,
	mileage_multiplier: float = 1.0,
) -> bool:
	return AgingResolver.resolve_annual(
		state, career_year, executor, mileage_multiplier, _profiles.progression)


## Advance the player's age exactly once for a career year (§9.5).
func advance_age(state: PlayerDevelopmentState, career_year: int) -> bool:
	if not state.receipts.claim(career_year, CareerYearReceipts.Resolution.AGE_INCREASE):
		return false
	state.age += 1
	return true
