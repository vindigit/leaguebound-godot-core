class_name BuilderState
extends RefCounted

## Mutable Builder working state.
##
## Holds the selections and the in-progress allocation. It owns no formula:
## costs come from `AttributeCostTable`, caps from `CapGenerator`, bases and
## redistribution from `BuilderRules`, and the three development values from
## `DevelopmentProjection`. Presentation renders what this exposes and computes
## nothing (`GODOT_TDD.md` §6.2).
##
## The state is created only once the family, body, maturity, and prospect
## profile are chosen, because those four determine the caps and the
## body-adjusted bases the allocation is validated against — and the caps must
## be exact and visible while the user allocates (PRD BUILD-002).

const RANDOMIZE_STREAM_LABEL: StringName = &"player_system:builder_randomize"

var family: int
var prospect: int
var maturity: int
var body: BodyProfile
var caps: AttributeCaps
var projected_range: BodyRange
var budget: CreationBudget
var tendencies: PlayerTendencies

var _bases: Array[int]
var _values: Array[int]
var _builder_profile: BuilderProfile
var _progression: ProgressionProfile


func _init(
	p_family: int,
	p_prospect: int,
	p_maturity: int,
	p_body: BodyProfile,
	p_caps: AttributeCaps,
	p_projected_range: BodyRange,
	p_builder_profile: BuilderProfile,
	p_progression: ProgressionProfile,
) -> void:
	assert(PositionFamily.is_valid(p_family), "unknown position family")
	assert(ProspectProfile.is_valid(p_prospect), "unknown prospect profile")
	assert(MaturityProfile.is_valid(p_maturity), "unknown maturity profile")
	family = p_family
	prospect = p_prospect
	maturity = p_maturity
	body = p_body
	caps = p_caps
	projected_range = p_projected_range
	_builder_profile = p_builder_profile
	_progression = p_progression
	_bases = BuilderRules.body_adjusted_bases(p_body, p_family, p_builder_profile)
	_values = _bases.duplicate()
	budget = CreationBudget.new(p_builder_profile.creation_budget_for(p_prospect))
	tendencies = PlayerTendencies.new()


func bases() -> Array[int]:
	return _bases.duplicate()


func values() -> Array[int]:
	return _values.duplicate()


func rating_for(attribute: int) -> int:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	return _values[attribute]


func attributes() -> PlayerAttributes:
	return PlayerAttributes.from_values(_values)


## The AP cost of the next point in an attribute, or -1 when no next point is
## legal. Presentation displays this; it never derives it.
func next_point_cost(attribute: int) -> int:
	var current: int = _values[attribute]
	if not can_raise(attribute):
		return -1
	return AttributeCostTable.cost_of_next_point(current, _progression)


## Whether one more point is legal: inside the absolute starting maximum,
## inside the exact cap, and affordable. §9.1: "Caps are checked before currency
## is consumed."
func can_raise(attribute: int) -> bool:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	var current: int = _values[attribute]
	if current >= _builder_profile.starting_absolute_maximum:
		return false
	if current >= caps.cap_for(attribute) or current >= Rating.MAXIMUM:
		return false
	return budget.can_afford(AttributeCostTable.cost_of_next_point(current, _progression))


## Whether the attribute has passed the soft starting maximum. This is
## informational only — §7.1 defines a soft and an absolute maximum, and only
## the absolute one blocks. The Builder "does not label a legal build as bad"
## (§7.3.2), so exceeding the soft maximum is reported, not prevented.
func is_above_soft_maximum(attribute: int) -> bool:
	return _values[attribute] > _builder_profile.starting_soft_maximum


func raise_attribute(attribute: int) -> bool:
	if not can_raise(attribute):
		return false
	var cost: int = AttributeCostTable.cost_of_next_point(_values[attribute], _progression)
	budget.spend(cost)
	_values[attribute] += 1
	return true


## Undo one point. This refunds *within the Builder only* — the AP returns to
## the same creation budget it came from and cannot leave it (§7.1).
func lower_attribute(attribute: int) -> bool:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	if _values[attribute] <= _bases[attribute]:
		return false
	var refund: int = AttributeCostTable.cost_of_next_point(_values[attribute] - 1, _progression)
	_values[attribute] -= 1
	budget.refund_within_builder(refund)
	return true


func reset() -> void:
	_values = _bases.duplicate()
	budget = CreationBudget.new(_builder_profile.creation_budget_for(prospect))
	tendencies = PlayerTendencies.new()


func spent() -> int:
	return budget.spent


func remaining() -> int:
	return budget.remaining()


## §7.1 / OD-B: confirmation is blocked while any creation AP remains.
func can_confirm() -> bool:
	return budget.is_exhausted() and confirmation_failures().is_empty()


func confirmation_failures() -> PackedStringArray:
	return BuilderRules.allocation_failures(
		_values, _bases, caps, budget, _builder_profile, _progression)


## Spend the remaining budget across a weighted set of attributes.
##
## Used by presets and by randomization. Weights bias the choice; they never
## bypass the cost table, the caps, or the starting maxima, so anything this
## produces is a build the user could have made by hand.
func spend_remaining_weighted(weights: Array[float]) -> void:
	assert(weights.size() == AttributeKey.COUNT, "one weight per canonical attribute is required")
	var guard: int = budget.granted * 4
	while budget.remaining() > 0 and guard > 0:
		guard -= 1
		var best_attribute: int = -1
		var best_score: float = 0.0
		for attribute in AttributeKey.all():
			if weights[attribute] <= 0.0 or not can_raise(attribute):
				continue
			var cost: int = AttributeCostTable.cost_of_next_point(_values[attribute], _progression)
			# Value per AP, so a weighted attribute in an expensive band does not
			# silently soak the whole budget.
			var score: float = weights[attribute] / float(cost)
			if best_attribute == -1 or score > best_score \
					or (is_equal_approx(score, best_score) and attribute < best_attribute):
				best_attribute = attribute
				best_score = score
		if best_attribute == -1:
			break
		if not raise_attribute(best_attribute):
			break


## Fill any residual budget anywhere legal.
##
## Weighted spending can strand a few AP when every weighted attribute has hit
## a cap or an expensive band. The budget must still reach zero for the build to
## be confirmable (§7.1), so this takes the cheapest legal point repeatedly.
## It is the mechanical equivalent of a user spending his last points wherever
## they fit, which is exactly the situation §7.1 intends to force.
func fill_remaining_anywhere() -> void:
	var guard: int = budget.granted * 4
	while budget.remaining() > 0 and guard > 0:
		guard -= 1
		var best_attribute: int = -1
		var best_cost: int = 0
		for attribute in AttributeKey.all():
			if not can_raise(attribute):
				continue
			var cost: int = AttributeCostTable.cost_of_next_point(_values[attribute], _progression)
			if best_attribute == -1 or cost < best_cost:
				best_attribute = attribute
				best_cost = cost
		if best_attribute == -1:
			# Nothing legal remains. The caller must surface this rather than
			# silently confirming a build with unspent creation AP.
			return
		if not raise_attribute(best_attribute):
			return


## Deterministic randomization from an injected source (`GODOT_TDD.md` §5.2).
func randomize_allocation(source: RandomSource) -> void:
	reset()
	var stream: RandomSource = source.derive(RANDOMIZE_STREAM_LABEL)
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(RandomDraw.float_in(stream, 0.05, 1.0))
	spend_remaining_weighted(weights)
	fill_remaining_anywhere()
