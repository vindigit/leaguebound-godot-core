class_name AttributeAllocator
extends RefCounted

## The full-detail NPC allocation strategy (`GODOT_TDD.md` §5.8,
## `BALANCE_SPEC.md` §9.7).
##
## "Bound by the same costs and caps as the user."
##
## ## What this deliberately is not
##
## §9.7.2 rejects one specific shortcut by name: "An allocator implemented as
## 'assign a target rating and interpolate' violates this contract even when its
## aggregate output looks correct." This allocator therefore spends AP one whole
## point at a time through `DevelopmentService`, paying the §9.1 destination
## cost for each. It cannot write a rating, and it cannot reach a rating it
## could not afford.
##
## ## What it considers
##
## Current archetype, tactical and rotation role, exact caps, deficiencies, age,
## coach and development context, and diminishing room. All of these steer
## *priority*. None of them changes the price of a point or the size of the
## grant, because a cheaper point for an NPC would be a discount unavailable to
## the user (§9.7).
##
## ## Diminishing room
##
## §9.6 defines `DevelopmentRoom` as declining from 1.00 below 70 rating to 0.25
## at 95+. The same shape is used here as a priority weight, so an allocator
## naturally stops pouring points into an attribute that is nearly maxed while
## an obvious weakness sits at 40.

const ROOM_FULL_CEILING: int = 70
const ROOM_MINIMUM_FLOOR: int = 95
const ROOM_MINIMUM_VALUE: float = 0.25


## Allocate a player's available AP.
##
## Spends through `service`, so every point pays the shared cost table, respects
## the exact caps, and lands in the shared source ledger with the allocator's
## executor recorded.
static func allocate(
	state: PlayerDevelopmentState,
	career_year: int,
	context: DevelopmentContext,
	service: DevelopmentService,
	executor: int = DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR,
) -> int:
	var progression: ProgressionProfile = service.profiles().progression
	var weights: Array[float] = priority_weights(state, context, progression)
	var applied: int = 0

	var guard: int = AttributeKey.COUNT * 400
	while guard > 0:
		guard -= 1
		var best_attribute: int = -1
		var best_score: float = 0.0
		for attribute in AttributeKey.all():
			var current: int = state.attributes.get_rating(attribute)
			if not state.caps.has_room(attribute, current) or current >= Rating.MAXIMUM:
				continue
			var cost: int = AttributeCostTable.cost_of_next_point(current, progression)
			if float(cost) > state.point_ledger.balance():
				continue
			# Priority per AP, so an expensive band does not silently absorb the
			# whole grant.
			var score: float = weights[attribute] / float(cost)
			if best_attribute == -1 or score > best_score \
					or (is_equal_approx(score, best_score) and attribute < best_attribute):
				best_attribute = attribute
				best_score = score
		if best_attribute == -1:
			break
		if service.spend_general_ap(state, best_attribute, 1, career_year, executor) == 0:
			break
		applied += 1

	return applied


## Per-attribute allocation priority.
##
## Deliberately exposed as a pure function so the parity tests can compare the
## allocator's intent against the aggregate executor's without running a career.
static func priority_weights(
	state: PlayerDevelopmentState,
	context: DevelopmentContext,
	progression: ProgressionProfile,
) -> Array[float]:
	var archetype_weights: Array[float] = _role_weights(state)
	var weights: Array[float] = []

	var mean_rating: float = 0.0
	for attribute in AttributeKey.all():
		mean_rating += float(state.attributes.get_rating(attribute))
	mean_rating /= float(AttributeKey.COUNT)

	for attribute in AttributeKey.all():
		var current: int = state.attributes.get_rating(attribute)
		var cap: int = state.caps.cap_for(attribute)

		# Room left against the exact cap: an attribute one point from its cap
		# is a poor investment however central it is to the role.
		var cap_room: float = clampf(float(cap - current) / 20.0, 0.0, 1.0)
		var room: float = development_room(current) * cap_room

		# Deficiency repair versus specialization, set by coaching context.
		var deficiency: float = clampf((mean_rating - float(current)) / 20.0, 0.0, 1.0)
		var role_priority: float = archetype_weights[attribute]
		var blended: float = (
			role_priority * (1.0 - context.deficiency_focus)
			+ deficiency * context.deficiency_focus
		)

		# Age steers toward the categories that still grow (§10.2). An attribute
		# already past its growth window is a worse investment.
		var category: int = AttributeCategory.of_attribute(attribute)
		var age_factor: float = _age_factor(state.age, category, context, progression)

		weights.append(maxf(0.0001, blended * room * age_factor))

	return weights


## §9.6 `DevelopmentRoom`: 1.00 below 70 rating, declining to 0.25 at 95+.
static func development_room(current_rating: int) -> float:
	if current_rating < ROOM_FULL_CEILING:
		return 1.0
	if current_rating >= ROOM_MINIMUM_FLOOR:
		return ROOM_MINIMUM_VALUE
	var span: float = float(ROOM_MINIMUM_FLOOR - ROOM_FULL_CEILING)
	var travelled: float = float(current_rating - ROOM_FULL_CEILING) / span
	return lerpf(1.0, ROOM_MINIMUM_VALUE, travelled)


## Role-derived priority.
##
## This reads the tactical role to decide *where opportunity is best spent*,
## which §12.4 permits — tactical role affects `RoleOpportunity` and planned
## usage. It is not a capability input and never reaches a success probability.
static func _role_weights(state: PlayerDevelopmentState) -> Array[float]:
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(BASE_ROLE_WEIGHT)

	for attribute: int in CapGenerator.FAMILY_PRIMARY[state.position_family]:
		weights[attribute] = PRIMARY_ROLE_WEIGHT
	for attribute: int in CapGenerator.FAMILY_SECONDARY[state.position_family]:
		weights[attribute] = maxf(weights[attribute], SECONDARY_ROLE_WEIGHT)

	for attribute in _tactical_role_attributes(state.tactical_role.role):
		weights[attribute] = maxf(weights[attribute], PRIMARY_ROLE_WEIGHT)

	return weights


static func _tactical_role_attributes(role: int) -> Array[int]:
	match role:
		TacticalRole.Value.PRIMARY_CREATOR:
			return [AttributeKey.Key.HANDLE, AttributeKey.Key.PASSING,
				AttributeKey.Key.VISION, AttributeKey.Key.OFFENSIVE_IQ]
		TacticalRole.Value.SECONDARY_CREATOR:
			return [AttributeKey.Key.HANDLE, AttributeKey.Key.SHORT_RANGE,
				AttributeKey.Key.OFFENSIVE_IQ]
		TacticalRole.Value.SHOOTER:
			return [AttributeKey.Key.THREE_POINT, AttributeKey.Key.MID_RANGE,
				AttributeKey.Key.FREE_THROW]
		TacticalRole.Value.SLASHER:
			return [AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.SPEED,
				AttributeKey.Key.DUNKING]
		TacticalRole.Value.CONNECTOR:
			return [AttributeKey.Key.PASSING, AttributeKey.Key.VISION,
				AttributeKey.Key.OFFENSIVE_IQ]
		TacticalRole.Value.POST_OPTION:
			return [AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.STRENGTH,
				AttributeKey.Key.OFFENSIVE_REBOUNDING]
		TacticalRole.Value.ROLL_POP_BIG:
			return [AttributeKey.Key.DUNKING, AttributeKey.Key.STRENGTH,
				AttributeKey.Key.MID_RANGE]
		TacticalRole.Value.PERIMETER_STOPPER:
			return [AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.SPEED,
				AttributeKey.Key.DEFENSIVE_IQ]
		TacticalRole.Value.INTERIOR_ANCHOR:
			return [AttributeKey.Key.INTERIOR_DEFENSE, AttributeKey.Key.BLOCKING,
				AttributeKey.Key.DEFENSIVE_IQ]
		TacticalRole.Value.REBOUNDER:
			return [AttributeKey.Key.DEFENSIVE_REBOUNDING,
				AttributeKey.Key.OFFENSIVE_REBOUNDING, AttributeKey.Key.STRENGTH]
		_:
			return [AttributeKey.Key.STAMINA, AttributeKey.Key.DEFENSIVE_IQ,
				AttributeKey.Key.SPEED]


## Attributes whose growth window has closed are worse investments, but never
## worthless.
##
## §10.2 gives each category three ages: growth-dominant through `growth_end`,
## then a plateau, then decline. A 30-year-old investing in Speed — a category
## that peaked at 23 and began declining at 28 — is spending against the curve,
## while the same points into Defensive IQ are still growth-dominant until 31.
## Coaching quality lifts the floor without ever reaching a discount: it changes
## how well the allocator picks, not what a point costs.
static func _age_factor(
	age: int,
	category: int,
	context: DevelopmentContext,
	progression: ProgressionProfile,
) -> float:
	var coaching: float = lerpf(AGE_FACTOR_COACHING_FLOOR, 1.0, context.coaching_quality)

	var stage: float = AGE_FACTOR_DECLINING
	if age <= progression.growth_end_age[category]:
		stage = AGE_FACTOR_GROWING
	elif age <= progression.plateau_end_age[category]:
		stage = AGE_FACTOR_PLATEAU
	elif age < progression.decline_start_age[category]:
		stage = AGE_FACTOR_LATE_PLATEAU

	return stage * coaching


const BASE_ROLE_WEIGHT: float = 0.30
const SECONDARY_ROLE_WEIGHT: float = 0.65
const PRIMARY_ROLE_WEIGHT: float = 1.00
const AGE_FACTOR_COACHING_FLOOR: float = 0.80
const AGE_FACTOR_GROWING: float = 1.00
const AGE_FACTOR_PLATEAU: float = 0.70
const AGE_FACTOR_LATE_PLATEAU: float = 0.50
const AGE_FACTOR_DECLINING: float = 0.30
