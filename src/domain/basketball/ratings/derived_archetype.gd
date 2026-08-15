class_name DerivedArchetype
extends RefCounted

## A read-only, composable description of a player
## (`SIMULATION_SPEC.md` §10.6.3, `BALANCE_SPEC.md` §12.4, PRD BUILD-005).
##
## Built from three parts, exactly as §10.6.3 specifies:
##
##   1. a two-way axis descriptor, from the balance of offensive and defensive
##      capability;
##   2. one or two capability descriptors, from the dominant capability
##      clusters;
##   3. a position-family noun, from body and position evidence.
##
## Producing, for example, *Two-Way Shot-Creating Guard* or *Stretch Rim
## Protector*.
##
## ## Archetype grants nothing
##
## §12.4 gives this layer the entry "May affect: **Nothing.** It is a read-only
## description." §10.6.3 elaborates: no attribute, capability, action,
## opportunity, badge, role eligibility, or probability. §28 lists "a derived
## archetype grants any capability, opportunity, attribute, or probability" as a
## release blocker.
##
## Three properties follow, and each has a test:
##
## - **Side-effect free.** `classify` is static and takes only value objects. It
##   cannot mutate a player, and it consults no `RandomSource`.
## - **Not exclusive.** Two players may share a descriptor without sharing any
##   mechanical property, and a build is never restricted to
##   archetype-appropriate attributes. Hybrids receive composite descriptors.
## - **No memory, no lock-in.** Archetype is recomputed from current ratings and
##   body every time. It is not persisted as a gameplay fact
##   (`GODOT_TDD.md` §5.7).


## Capability clusters used for descriptors. These are rating groupings for
## description only; they are not the §5.2 derived capabilities and are never
## consumed by resolution.
enum Cluster {
	SHOOTING,
	RIM_FINISHING,
	SHOT_CREATION,
	PLAYMAKING,
	PERIMETER_DEFENSE,
	RIM_PROTECTION,
	REBOUNDING,
}

const CLUSTER_COUNT: int = 7
const CLUSTER_DESCRIPTORS: PackedStringArray = [
	"Shooting",
	"Rim-Finishing",
	"Shot-Creating",
	"Playmaking",
	"Perimeter-Stopping",
	"Rim-Protecting",
	"Rebounding",
]

const AXIS_TWO_WAY: StringName = &"two_way"
const AXIS_OFFENSIVE: StringName = &"offensive"
const AXIS_DEFENSIVE: StringName = &"defensive"

var axis: StringName
var descriptors: PackedStringArray
var position_noun: String
var cluster_scores: Array[float]


func _init(
	p_axis: StringName,
	p_descriptors: PackedStringArray,
	p_position_noun: String,
	p_cluster_scores: Array[float],
) -> void:
	axis = p_axis
	descriptors = p_descriptors
	position_noun = p_position_noun
	cluster_scores = p_cluster_scores


## The composed display label, for example "Two-Way Shot-Creating Guard".
func label() -> String:
	var parts: PackedStringArray = []
	match axis:
		AXIS_TWO_WAY:
			parts.append("Two-Way")
		AXIS_DEFENSIVE:
			parts.append("Defensive")
		_:
			pass
	for descriptor in descriptors:
		parts.append(descriptor)
	parts.append(position_noun)
	return " ".join(parts)


static func classify(
	attributes: PlayerAttributes,
	body: BodyProfile,
	position_family: int,
	profile: ArchetypeProfile,
) -> DerivedArchetype:
	var scores: Array[float] = _cluster_scores(attributes)

	var offense: float = (
		scores[Cluster.SHOOTING] + scores[Cluster.RIM_FINISHING]
		+ scores[Cluster.SHOT_CREATION] + scores[Cluster.PLAYMAKING]
	) / 4.0
	var defense: float = (
		scores[Cluster.PERIMETER_DEFENSE] + scores[Cluster.RIM_PROTECTION]
		+ scores[Cluster.REBOUNDING]
	) / 3.0

	var axis_value: StringName = AXIS_TWO_WAY
	if absf(offense - defense) > profile.two_way_tolerance:
		axis_value = AXIS_OFFENSIVE if offense > defense else AXIS_DEFENSIVE

	return DerivedArchetype.new(
		axis_value,
		_descriptors_for(scores, profile),
		_position_noun(body, position_family, scores, profile),
		scores
	)


static func _cluster_scores(attributes: PlayerAttributes) -> Array[float]:
	var scores: Array[float] = []
	scores.resize(CLUSTER_COUNT)
	scores[Cluster.SHOOTING] = _mean([
		attributes.three_point, attributes.mid_range, attributes.free_throw,
	])
	scores[Cluster.RIM_FINISHING] = _mean([
		attributes.short_range, attributes.dunking, attributes.vertical,
	])
	scores[Cluster.SHOT_CREATION] = _mean([
		attributes.handle, attributes.speed, attributes.offensive_iq,
	])
	scores[Cluster.PLAYMAKING] = _mean([
		attributes.passing, attributes.vision, attributes.offensive_iq,
	])
	scores[Cluster.PERIMETER_DEFENSE] = _mean([
		attributes.perimeter_defense, attributes.stealing, attributes.speed,
	])
	scores[Cluster.RIM_PROTECTION] = _mean([
		attributes.blocking, attributes.interior_defense, attributes.vertical,
	])
	scores[Cluster.REBOUNDING] = _mean([
		attributes.offensive_rebounding, attributes.defensive_rebounding, attributes.strength,
	])
	return scores


static func _mean(values: Array[int]) -> float:
	var total: int = 0
	for value in values:
		total += value
	return float(total) / float(values.size())


## Name the leading cluster, plus a second one when it is close enough to be a
## real part of the player's shape. This is what keeps hybrids legible: a build
## that genuinely shoots and protects the rim is described as both rather than
## being rounded to whichever is one point higher.
static func _descriptors_for(
	scores: Array[float],
	profile: ArchetypeProfile,
) -> PackedStringArray:
	var mean_score: float = 0.0
	for score in scores:
		mean_score += score
	mean_score /= float(CLUSTER_COUNT)

	var ordered: Array[int] = []
	for cluster in range(CLUSTER_COUNT):
		ordered.append(cluster)
	# Canonical order first, then a stable sort by score so equal scores resolve
	# by cluster index rather than by incidental ordering.
	ordered.sort_custom(func(left: int, right: int) -> bool:
		if absf(scores[left] - scores[right]) < 0.000001:
			return left < right
		return scores[left] > scores[right]
	)

	var descriptors: PackedStringArray = []
	var leader: int = ordered[0]
	if scores[leader] - mean_score < profile.descriptor_threshold:
		# No cluster stands out: a genuinely balanced player is described as
		# balanced rather than being given a spurious specialism.
		descriptors.append("Balanced")
		return descriptors

	descriptors.append(CLUSTER_DESCRIPTORS[leader])
	var runner_up: int = ordered[1]
	if scores[leader] - scores[runner_up] <= profile.secondary_descriptor_tolerance \
			and scores[runner_up] - mean_score >= profile.descriptor_threshold:
		descriptors.append(CLUSTER_DESCRIPTORS[runner_up])
	return descriptors


## The position noun emerges from body and demonstrated profile, not from the
## starting family. `GDD.md` §6.1: Guard, Wing, and Big are broad starting
## families and "exact primary and secondary positions emerge from physical
## dimensions, ratings, play style, and early performance". A player who starts
## in the Guard family and grows into a seven-footer is described as a Big.
static func _position_noun(
	body: BodyProfile,
	position_family: int,
	scores: Array[float],
	profile: ArchetypeProfile,
) -> String:
	var by_height: int = PositionFamily.Value.BIG
	if body.height_inches <= profile.guard_height_ceiling:
		by_height = PositionFamily.Value.GUARD
	elif body.height_inches <= profile.wing_height_ceiling:
		by_height = PositionFamily.Value.WING

	# Skill evidence can pull one family away from the pure height reading —
	# a tall primary playmaker still reads as a point forward rather than a
	# centre — but it never overrides height by more than one family.
	var perimeter_evidence: float = maxf(
		scores[Cluster.SHOT_CREATION], scores[Cluster.PLAYMAKING])
	var interior_evidence: float = maxf(
		scores[Cluster.RIM_PROTECTION], scores[Cluster.REBOUNDING])
	var evidence_gap: float = perimeter_evidence - interior_evidence

	var adjusted: int = by_height
	if evidence_gap > profile.descriptor_threshold and by_height > PositionFamily.Value.GUARD:
		adjusted = by_height - 1
	elif -evidence_gap > profile.descriptor_threshold and by_height < PositionFamily.Value.BIG:
		adjusted = by_height + 1

	# The declared starting family is evidence too, but only as a tie-break; it
	# can never lock a player into a family his body and skills contradict.
	if adjusted != by_height and position_family == by_height:
		adjusted = by_height

	return PositionFamily.label_of(adjusted)
