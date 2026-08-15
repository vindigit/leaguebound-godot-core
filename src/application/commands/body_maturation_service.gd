class_name BodyMaturationService
extends RefCounted

## Resolves scheduled growth increments deterministically and idempotently
## (`GODOT_TDD.md` §5.8, `SIMULATION_SPEC.md` §6.3).
##
## The whole trajectory is replanned from the career seed on every call and the
## milestone for the requested career year is read off it. That is what makes
## growth immune to reloads, detail-level changes, Play/Sim choice, and device
## (§7.4.3 rule 1): nothing is sampled at resolution time, so there is nothing
## to reroll.
##
## Idempotency is enforced twice over, deliberately. The shared
## `CareerYearReceipts` book stops the career-year milestone running twice, and
## `BodyMaturationState.has_resolved` stops a duplicate increment even if a
## caller bypassed the receipt. §6.3 requires that "reloading, changing level,
## or changing simulation tier cannot re-resolve or skip an increment", and one
## guard is easier to route around than two.

var _profiles: BalanceProfileSet


func _init(p_profiles: BalanceProfileSet = null) -> void:
	_profiles = p_profiles if p_profiles != null else BalanceProfileSet.default_set()


## Career years at which growth resolves, measured from the confirmed freshman
## year.
func milestone_career_years() -> Array[int]:
	var years: Array[int] = []
	for milestone in range(BuilderProfile.TOTAL_GROWTH_MILESTONES):
		years.append(milestone + 2)
	return years


func is_growth_milestone(career_year: int) -> bool:
	return milestone_career_years().has(career_year)


## Resolve the increment for one career year.
##
## Returns `true` when an increment resolved, `false` when the year is not a
## milestone, the receipt was already claimed, or the body is already final.
func resolve_increment(
	state: PlayerDevelopmentState,
	career_year: int,
	career_source: RandomSource,
) -> bool:
	if not is_growth_milestone(career_year):
		return false

	var body_state: BodyMaturationState = state.body_state
	if body_state.is_final(BuilderProfile.TOTAL_GROWTH_MILESTONES):
		return false
	if body_state.has_resolved(career_year):
		return false
	if not state.receipts.claim(
			career_year, CareerYearReceipts.Resolution.BODY_GROWTH_INCREMENT):
		return false

	var trajectory: Array[BodyProfile] = _trajectory_for(state, career_source)
	var milestone_index: int = milestone_career_years().find(career_year)
	assert(milestone_index >= 0 and milestone_index < trajectory.size(),
		"growth milestone fell outside the planned trajectory")

	var increment: GrowthIncrement = BodyMaturationPlanner.increment_for(
		career_year, body_state.realized_body, trajectory[milestone_index])

	# §7.4.3 rule 4 / §6.3: an increment writes a body and never a rating. The
	# ratings on `state` are deliberately untouched here; a rating consequence
	# of growth is a separate, visible, ledgered progression effect.
	body_state.resolve(increment, BuilderProfile.TOTAL_GROWTH_MILESTONES)
	return true


## Replan the full trajectory from the career seed. Pure and repeatable.
func _trajectory_for(
	state: PlayerDevelopmentState,
	career_source: RandomSource,
) -> Array[BodyProfile]:
	var body_state: BodyMaturationState = state.body_state
	var adult: BodyProfile = BodyMaturationPlanner.draw_adult_body(
		body_state.confirmed_freshman_body, body_state.projected_range, career_source)
	return BodyMaturationPlanner.plan_trajectory(
		body_state.confirmed_freshman_body, adult, body_state.maturity, _profiles.builder)


## Apply deliberate weight change from conditioning and training.
##
## §7.4 requires weight evolution and training to be "modeled separately from
## height growth" and to "remain within credible health/body bounds". This is
## that separate path: it moves weight only, is bounded by the stored projected
## maximum above and the health floor below, and — like every body change —
## writes no rating.
func apply_weight_training(state: PlayerDevelopmentState, pounds_delta: int) -> int:
	var body_state: BodyMaturationState = state.body_state
	var current: BodyProfile = body_state.realized_body
	var floor_weight: int = body_state.weight_health_floor()
	var ceiling_weight: int = body_state.projected_range.weight_maximum

	var target: int = clampi(current.weight_pounds + pounds_delta, floor_weight, ceiling_weight)
	if target == current.weight_pounds:
		return 0

	body_state.realized_body = BodyProfile.new(
		current.height_inches,
		target,
		current.wingspan_inches,
		current.standing_reach_inches
	)
	return target - current.weight_pounds
