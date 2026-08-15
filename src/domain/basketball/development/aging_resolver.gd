class_name AgingResolver
extends RefCounted

## Natural age- and mileage-driven development and decline
## (`BALANCE_SPEC.md` §10.2, §10.3).
##
## §10.2: "Natural age- and mileage-based development or decline resolves once
## at the shared career-year offseason milestone... **There is no invisible
## weekly erosion.**" The once-only guarantee is enforced through the shared
## `CareerYearReceipts`, not through a private flag, so it holds across every
## executor — the same receipt that stops the user's decline running twice stops
## an NPC's.
##
## §10.3: decline values are expected *total rating points removed from a
## category*, distributed toward the most exposed attributes, and fractional
## decline accumulates invisibly until a whole point resolves. Natural decline
## cannot remove more than five whole points from one attribute in one offseason
## without a major injury or extraordinary circumstance.

const STREAM_LABEL: StringName = &"player_system:aging"


## Resolve the once-per-career-year natural development-or-decline step.
##
## Returns `true` when it resolved and `false` when the receipt was already
## claimed. A duplicate attempt is an ordinary event — a reload, a level change,
## a recall — so it is declined quietly rather than treated as a crash.
static func resolve_annual(
	state: PlayerDevelopmentState,
	career_year: int,
	executor: int,
	mileage_multiplier: float,
	progression: ProgressionProfile,
) -> bool:
	assert(DevelopmentExecutor.is_valid(executor), "unknown development executor")
	assert(mileage_multiplier > 0.0, "mileage multiplier must be positive")

	if not state.receipts.claim(
			career_year, CareerYearReceipts.Resolution.NATURAL_DEVELOPMENT_OR_DECLINE):
		return false

	var band: int = progression.decline_band_index_for_age(state.age)
	if band < 0:
		# Below the first decline band there is nothing to remove. Natural
		# *growth* arrives as granted opportunity through the development
		# service, not as a silent rating write here.
		return true

	_accumulate_decline(state, band, mileage_multiplier, progression)
	_resolve_whole_points(state, career_year, executor, progression)
	return true


## Spread each decline family's expected annual total across its attributes,
## weighted toward the most exposed — §10.3 "distributed toward the most exposed
## attributes". A high rating has more to lose and loses it first.
static func _accumulate_decline(
	state: PlayerDevelopmentState,
	band: int,
	mileage_multiplier: float,
	progression: ProgressionProfile,
) -> void:
	for family in range(3):
		var family_total: float = _family_total(family, band, progression)
		if family_total <= 0.0:
			continue
		# §10.3: mileage modifies physical decline only.
		if family == AttributeCategory.DeclineFamily.PHYSICAL:
			family_total *= mileage_multiplier

		var members: Array[int] = []
		var exposure_total: float = 0.0
		for attribute in AttributeKey.all():
			var category: int = AttributeCategory.of_attribute(attribute)
			if AttributeCategory.decline_family_of(category) != family:
				continue
			if state.age < progression.decline_start_age[category]:
				continue
			members.append(attribute)
			exposure_total += float(state.attributes.get_rating(attribute))

		if members.is_empty() or exposure_total <= 0.0:
			continue
		for attribute in members:
			var share: float = float(state.attributes.get_rating(attribute)) / exposure_total
			state.decline_debt.add_units(attribute, family_total * share)


static func _family_total(family: int, band: int, progression: ProgressionProfile) -> float:
	match family:
		AttributeCategory.DeclineFamily.PHYSICAL:
			return (
				progression.decline_physical_minimum[band]
				+ progression.decline_physical_maximum[band]
			) / 2.0
		AttributeCategory.DeclineFamily.TECHNICAL:
			return (
				progression.decline_technical_minimum[band]
				+ progression.decline_technical_maximum[band]
			) / 2.0
		AttributeCategory.DeclineFamily.IQ:
			# The §10.3 IQ column is non-negative in the early bands: IQ still
			# improves while the body declines. Positive movement is granted
			# opportunity, not a silent write, so nothing is removed here.
			return maxf(0.0, (
				progression.decline_iq_minimum[band] + progression.decline_iq_maximum[band]
			) / 2.0)
		_:
			assert(false, "unknown decline family")
	return 0.0


## Convert accumulated fractional debt into whole rating points.
##
## Each resolved point is ledgered. The rating floor is the active-player
## minimum: decline can make a player a liability but never removes him from the
## active domain (`BALANCE_SPEC.md` §5).
static func _resolve_whole_points(
	state: PlayerDevelopmentState,
	career_year: int,
	executor: int,
	progression: ProgressionProfile,
) -> void:
	for attribute in AttributeKey.all():
		var debt: float = state.decline_debt.units_for(attribute)
		if debt < 1.0:
			continue
		var whole: int = int(floorf(debt))
		whole = mini(whole, progression.maximum_natural_decline_per_offseason)

		var current: int = state.attributes.get_rating(attribute)
		var reduced: int = maxi(Rating.ACTIVE_MINIMUM, current - whole)
		var applied: int = current - reduced
		if applied <= 0:
			continue

		state.attributes.set_rating(attribute, reduced)
		state.decline_debt.consume_units(attribute, float(applied))
		state.point_ledger.debit(
			career_year,
			AttributePointSource.Value.DECLINE,
			executor,
			float(applied),
			state.balance_version,
			attribute,
			"natural decline"
		)
