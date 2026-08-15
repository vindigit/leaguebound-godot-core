class_name BodyMaturationPlanner
extends RefCounted

## Deterministic body growth (`BALANCE_SPEC.md` §7.4, `SIMULATION_SPEC.md` §6.3).
##
## Three separable jobs:
##
##   1. `project_adult_range` computes the bounded projected adult range the
##      Builder displays and stores at confirmation (§7.4.2);
##   2. `draw_adult_body` draws the exact adult body from the versioned career
##      seed, once, at creation — it stays hidden until each increment resolves;
##   3. `plan_trajectory` schedules that growth across the career-year
##      milestones according to the maturity timing profile.
##
## ## Determinism
##
## §7.4.3 rule 1: growth is a function of the versioned career seed, career-year
## identity, and stored body state. "Reloading, changing simulation detail,
## Play/Sim choice, or device cannot reroll it." The whole trajectory is
## therefore drawn once from a labelled child stream and replayed, rather than
## being sampled afresh at each milestone.
##
## ## Timing is a schedule, not a budget
##
## `GDD.md` §6.5: "Early maturity means more of the growth arrives during high
## school; Late maturity means more of it arrives afterward. Neither timing is
## strictly better." Total growth is drawn *before* the timing profile is
## consulted and is identical across Early, Average, and Late. Only the share
## delivered by the high-school milestones differs. Giving Late a larger total
## would make it strictly better and would break that rule.
##
## ## Growth is never free Overall
##
## §7.4.3 rule 4: a body increment may not alter any of the twenty public
## ratings as a side effect. Nothing in this class touches a rating — it returns
## bodies. Where design intends a rating consequence it resolves separately,
## visibly, and through the ordinary progression rules.

const TRAJECTORY_STREAM_LABEL: StringName = &"player_system:body_maturation"


## The bounded projected adult range shown in the Builder and stored at
## confirmation. Depends only on the confirmed freshman body and the versioned
## widths — not on the seed — so the displayed range is honest about what the
## player can see rather than being a narrow window around a hidden draw.
static func project_adult_range(
	freshman: BodyProfile,
	profile: BuilderProfile,
) -> BodyRange:
	var height_low: int = freshman.height_inches + profile.growth_height_minimum
	var height_high: int = freshman.height_inches + profile.growth_height_maximum
	var wingspan_low: int = freshman.wingspan_inches + profile.growth_wingspan_minimum
	var wingspan_high: int = freshman.wingspan_inches + profile.growth_wingspan_maximum

	# Standing reach is derived from height and wingspan, and the derivation is
	# monotone in both. Deriving the reach bounds from the corner cases of the
	# height/wingspan box therefore makes reach containment exact: any legal
	# (height, wingspan) pair produces a reach inside these bounds.
	return BodyRange.new(
		height_low,
		height_high,
		freshman.weight_pounds + profile.growth_weight_minimum,
		freshman.weight_pounds + profile.growth_weight_maximum,
		wingspan_low,
		wingspan_high,
		BodyProfile.derive_standing_reach(height_low, wingspan_low),
		BodyProfile.derive_standing_reach(height_high, wingspan_high)
	)


## Draw the exact adult body, once, from the versioned career seed.
##
## §7.4.2 structural invariant: "The exact adult body is drawn deterministically
## from the versioned career seed at creation and remains hidden until each
## increment resolves."
static func draw_adult_body(
	freshman: BodyProfile,
	projected: BodyRange,
	career_source: RandomSource,
) -> BodyProfile:
	var stream: RandomSource = career_source.derive(TRAJECTORY_STREAM_LABEL)
	var height: int = RandomDraw.integer_in(
		stream, projected.height_minimum, projected.height_maximum)
	var wingspan: int = RandomDraw.integer_in(
		stream, projected.wingspan_minimum, projected.wingspan_maximum)
	var weight: int = RandomDraw.integer_in(
		stream, projected.weight_minimum, projected.weight_maximum)
	var adult: BodyProfile = BodyProfile.new(
		height, weight, wingspan, BodyProfile.derive_standing_reach(height, wingspan))
	assert(projected.contains_body(adult),
		"the drawn adult body must lie inside the range that produced it")
	assert(adult.height_inches >= freshman.height_inches,
		"skeletal growth cannot be negative")
	return adult


## Schedule the drawn adult body across the growth milestones.
##
## Returns one body per milestone, cumulative, ending exactly at `adult`. The
## final element is the adult body itself, so the §7.4.2 containment invariant
## holds by construction rather than by clamping after the fact.
static func plan_trajectory(
	freshman: BodyProfile,
	adult: BodyProfile,
	maturity: int,
	profile: BuilderProfile,
) -> Array[BodyProfile]:
	assert(MaturityProfile.is_valid(maturity), "unknown maturity profile")

	var high_school_share: float = profile.high_school_growth_share_for(maturity)
	var shares: Array[float] = _milestone_shares(high_school_share, profile)

	var trajectory: Array[BodyProfile] = []
	for milestone in range(profile.TOTAL_GROWTH_MILESTONES):
		var cumulative: float = 0.0
		for index in range(milestone + 1):
			cumulative += shares[index]
		if milestone == profile.TOTAL_GROWTH_MILESTONES - 1:
			# End exactly on the drawn adult body; never on a rounded
			# approximation of it.
			trajectory.append(adult.duplicate_body())
			continue
		var height: int = _interpolate(
			freshman.height_inches, adult.height_inches, cumulative)
		var wingspan: int = _interpolate(
			freshman.wingspan_inches, adult.wingspan_inches, cumulative)
		var weight: int = _interpolate(
			freshman.weight_pounds, adult.weight_pounds, cumulative)
		trajectory.append(BodyProfile.new(
			height, weight, wingspan, BodyProfile.derive_standing_reach(height, wingspan)))
	return trajectory


## The share of total growth delivered at each milestone.
##
## The high-school share is spread evenly across the high-school milestones and
## the remainder evenly across the post-high-school ones. The shares always sum
## to 1.0, which is what keeps the total identical across timing profiles.
static func _milestone_shares(
	high_school_share: float,
	profile: BuilderProfile,
) -> Array[float]:
	var high_school_count: int = profile.HIGH_SCHOOL_GROWTH_MILESTONES
	var later_count: int = profile.TOTAL_GROWTH_MILESTONES - high_school_count
	assert(high_school_count > 0 and later_count > 0,
		"growth must be scheduled across both high-school and later milestones")

	var shares: Array[float] = []
	for milestone in range(profile.TOTAL_GROWTH_MILESTONES):
		if milestone < high_school_count:
			shares.append(high_school_share / float(high_school_count))
		else:
			shares.append((1.0 - high_school_share) / float(later_count))
	return shares


static func _interpolate(from_value: int, to_value: int, share: float) -> int:
	return int(roundf(float(from_value) + float(to_value - from_value) * clampf(share, 0.0, 1.0)))


## Build the increment for one milestone, given the body the player currently
## has and the planned body for that milestone.
static func increment_for(
	career_year: int,
	current_body: BodyProfile,
	planned_body: BodyProfile,
) -> GrowthIncrement:
	return GrowthIncrement.new(
		career_year,
		planned_body.height_inches - current_body.height_inches,
		planned_body.weight_pounds - current_body.weight_pounds,
		planned_body.wingspan_inches - current_body.wingspan_inches,
		planned_body.standing_reach_inches - current_body.standing_reach_inches,
		planned_body.duplicate_body()
	)
