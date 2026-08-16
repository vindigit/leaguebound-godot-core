class_name CapGenerator
extends RefCounted

## Deterministic generation of exact per-attribute caps
## (`BALANCE_SPEC.md` §8, §8.1).
##
## "Each attribute receives an exact cap between 40 and 99 from a correlated
## player ceiling, build/body constraints, prospect profile, and bounded
## per-attribute noise."
##
## The correlation matters: every attribute's cap is anchored to one drawn
## player ceiling, so a player is broadly good or broadly limited rather than
## twenty independent lotteries. Emphasis offsets and clipped noise then shape
## the individual caps around that anchor.
##
## §8.1 is explicit that "the ceiling center is not Potential Overall", and
## §8.4 adds that the mapping from ceiling centre through Maximum Potential to
## realized Projected Peak "is not currently defined numerically" and must be
## *reported* by Stage 4 rather than assumed. Nothing here converts between
## them, and no code may state that a player peaks near his ceiling centre.
##
## The user's builder and generated NPCs use the same distributions (§8.1) —
## this one function serves both, so there is no NPC-only cap path.

const STREAM_LABEL: StringName = &"player_system:cap_generation"


## Generate caps for one player.
##
## `emphasis` carries one `AttributeEmphasis` value per canonical attribute.
## `random_source` must already be derived for this player's career-generation
## stream; the function derives one further child so cap draws cannot be
## disturbed by unrelated draws on the same parent (`GODOT_TDD.md` §5.2).
##
## `selection_pool` applies §8.1's "competition-appropriate selection pressure":
## the ceiling is the highest of that many draws from the profile's own
## distribution, so a selected population is the top of a wider pool rather than
## a different distribution. A pool of one is no selection and consumes exactly
## one normal draw, which is what every ordinary generation path uses.
##
## This is deliberately *not* a bonus added to a ceiling. §8.2 states that
## "Selection creates later-phase distributions" and that "the engine must not
## silently increase a player's cap merely because he reached a higher league" —
## an order statistic over the same distribution honours both, because every
## ceiling it can produce was already reachable without it.
static func generate(
	prospect: int,
	emphasis: Array[int],
	random_source: RandomSource,
	profile: ProgressionProfile,
	selection_pool: int = 1,
) -> AttributeCaps:
	assert(ProspectProfile.is_valid(prospect), "unknown prospect profile")
	assert(emphasis.size() == AttributeKey.COUNT,
		"one emphasis value per canonical attribute is required")
	assert(selection_pool >= 1, "a selection pool is at least the one player drawn")

	var stream: RandomSource = random_source.derive(STREAM_LABEL)

	# One correlated player ceiling anchors every attribute.
	var centre: float = float(profile.ceiling_center[prospect])
	var best: float = 0.0
	for candidate in range(selection_pool):
		var draw: float = (
			centre + RandomDraw.standard_normal(stream) * profile.ceiling_deviation[prospect])
		if candidate == 0 or draw > best:
			best = draw
	var ceiling: float = clampf(
		best,
		float(profile.ceiling_minimum[prospect]),
		float(profile.ceiling_maximum[prospect])
	)

	var caps: Array[int] = []
	for attribute in AttributeKey.all():
		var bounds: Array[int] = AttributeEmphasis.offset_bounds(emphasis[attribute], profile)
		var offset: int = RandomDraw.integer_in(stream, bounds[0], bounds[1])
		var noise: float = RandomDraw.clipped_normal(
			stream, 0.0, profile.cap_noise_deviation, float(profile.cap_noise_clip))
		var cap: int = int(roundf(ceiling + float(offset) + noise))
		caps.append(clampi(cap, ProgressionProfile.CAP_MINIMUM, ProgressionProfile.CAP_MAXIMUM))

	return AttributeCaps.new(caps)


## Derive emphasis from a confirmed build.
##
## Emphasis follows where the build actually invested, measured as the rating
## gain above the starting base. Deriving it from the build rather than from a
## declared role is what keeps §12.4 intact: no identity layer feeds the cap
## draw, so a tactical role cannot buy a higher ceiling.
##
## `incompatible` names attributes the selected body makes an unlikely
## specialism — §8.1's "incompatible physical or specialist tradeoffs".
static func emphasis_from_build(
	final_values: Array[int],
	base_values: Array[int],
	incompatible: Array[int],
	primary_count: int = 4,
	secondary_count: int = 4,
) -> Array[int]:
	assert(final_values.size() == AttributeKey.COUNT, "expected twenty final ratings")
	assert(base_values.size() == AttributeKey.COUNT, "expected twenty base ratings")
	assert(primary_count >= 0 and secondary_count >= 0, "emphasis counts cannot be negative")
	assert(primary_count + secondary_count <= AttributeKey.COUNT,
		"emphasis counts cannot exceed the attribute count")

	var ordered: Array[int] = AttributeKey.all()
	ordered.sort_custom(func(left: int, right: int) -> bool:
		var left_gain: int = final_values[left] - base_values[left]
		var right_gain: int = final_values[right] - base_values[right]
		if left_gain == right_gain:
			# Canonical index breaks ties so the result is reproducible.
			return left < right
		return left_gain > right_gain
	)

	var emphasis: Array[int] = []
	emphasis.resize(AttributeKey.COUNT)
	for index in range(AttributeKey.COUNT):
		var attribute: int = ordered[index]
		var gain: int = final_values[attribute] - base_values[attribute]
		if index < primary_count and gain > 0:
			emphasis[attribute] = AttributeEmphasis.Value.PRIMARY
		elif index < primary_count + secondary_count and gain > 0:
			emphasis[attribute] = AttributeEmphasis.Value.SECONDARY
		else:
			emphasis[attribute] = AttributeEmphasis.Value.NEUTRAL

	# An investment the body contradicts is still a real investment, so an
	# incompatible attribute keeps its tradeoff rather than being promoted.
	for attribute in incompatible:
		emphasis[attribute] = AttributeEmphasis.Value.INCOMPATIBLE

	return emphasis


## Characteristic attributes of each starting family, used to derive emphasis
## before attribute allocation has happened.
##
## ## Why the Builder uses this instead of `emphasis_from_build`
##
## Caps must be exact and visible *while* the user allocates: PRD BUILD-002
## requires allocation to use "exact per-attribute potential caps", and
## `GODOT_TDD.md` §6.2 forbids a screen from deriving them itself. But
## allocation-derived emphasis is only knowable once allocation is finished, and
## caps that shifted with every point spent would be neither exact nor
## displayable.
##
## So the user's caps are drawn once, from the family and body — §8.1's
## "build/body constraints" — at the moment those are confirmed, and are then
## immutable. NPC generation knows the whole build up front and uses
## `emphasis_from_build`. Both routes go through `generate`, so there is no
## NPC-only cap path and no user-only one.
##
## The family is a *starting* family and never a lock (`GDD.md` §6.1): it shapes
## the one-time cap draw and nothing afterwards. A Guard who invests entirely in
## interior defence is legal, and his caps there are ordinary rather than
## punished.
const FAMILY_PRIMARY: Array[Array] = [
	[
		AttributeKey.Key.HANDLE, AttributeKey.Key.SPEED,
		AttributeKey.Key.THREE_POINT, AttributeKey.Key.PASSING,
	],
	[
		AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.THREE_POINT,
		AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.SPEED,
	],
	[
		AttributeKey.Key.INTERIOR_DEFENSE, AttributeKey.Key.BLOCKING,
		AttributeKey.Key.DEFENSIVE_REBOUNDING, AttributeKey.Key.STRENGTH,
	],
]

const FAMILY_SECONDARY: Array[Array] = [
	[
		AttributeKey.Key.VISION, AttributeKey.Key.OFFENSIVE_IQ,
		AttributeKey.Key.PERIMETER_DEFENSE, AttributeKey.Key.STEALING,
	],
	[
		AttributeKey.Key.MID_RANGE, AttributeKey.Key.HANDLE,
		AttributeKey.Key.DEFENSIVE_REBOUNDING, AttributeKey.Key.VERTICAL,
	],
	[
		AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.DUNKING,
		AttributeKey.Key.OFFENSIVE_REBOUNDING, AttributeKey.Key.VERTICAL,
	],
]


static func emphasis_from_family(family: int, incompatible: Array[int]) -> Array[int]:
	assert(PositionFamily.is_valid(family), "unknown position family")
	var emphasis: Array[int] = []
	for _attribute in range(AttributeKey.COUNT):
		emphasis.append(AttributeEmphasis.Value.NEUTRAL)
	for attribute: int in FAMILY_SECONDARY[family]:
		emphasis[attribute] = AttributeEmphasis.Value.SECONDARY
	for attribute: int in FAMILY_PRIMARY[family]:
		emphasis[attribute] = AttributeEmphasis.Value.PRIMARY
	for attribute in incompatible:
		emphasis[attribute] = AttributeEmphasis.Value.INCOMPATIBLE
	return emphasis


## Attributes the selected body makes an unlikely specialism.
##
## `SIMULATION_SPEC.md` §6.1 permits body to affect action validity, reach,
## positioning, and matchups. A short player is not forbidden from investing in
## rim protection — §12.4 and `GDD.md` §6.1 keep every legal build legal — but
## his realistic *ceiling* there is lower, which is exactly what an §8.1
## incompatible tradeoff expresses. The Builder surfaces this as an
## informational opportunity note, never as a warning that the build is bad.
static func incompatible_attributes_for_body(
	body: BodyProfile,
	archetype_profile: ArchetypeProfile,
) -> Array[int]:
	var incompatible: Array[int] = []
	if body.height_inches <= archetype_profile.guard_height_ceiling:
		incompatible.append(AttributeKey.Key.BLOCKING)
		incompatible.append(AttributeKey.Key.INTERIOR_DEFENSE)
	if body.height_inches > archetype_profile.wing_height_ceiling:
		incompatible.append(AttributeKey.Key.HANDLE)
	return incompatible
