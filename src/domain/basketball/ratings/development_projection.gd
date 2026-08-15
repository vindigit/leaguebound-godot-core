class_name DevelopmentProjection
extends RefCounted

## The three distinct development values, together with their required labels
## (`BALANCE_SPEC.md` §6.3, OD-D; `GODOT_TDD.md` §5.5; PRD BUILD-007).
##
## | Value | Required UI label | Type |
## | --- | --- | --- |
## | Current Overall | **Current Overall** | exact integer |
## | Maximum Potential Overall | **Maximum Potential** | exact integer |
## | Projected Peak | **Projected Peak** | inclusive integer **range** |
##
## §6.3: "They are computed differently, carry different certainty, and each
## requires its own UI label. Presenting any one of them as another is a
## defect." The labels are constants here so presentation renders them as
## received rather than inventing its own wording.
##
## This type is the **only supported source** of these three values
## (`GODOT_TDD.md` §5.5). A cached copy may exist for query performance but is
## invalidated on any rating, cap, or body change and is never the value a rule
## reads — and none of the three may be used as a simulation input (§6.2).

const CURRENT_OVERALL_LABEL: String = "Current Overall"
const MAXIMUM_POTENTIAL_LABEL: String = "Maximum Potential"
const PROJECTED_PEAK_LABEL: String = "Projected Peak"

var current_overall: int
var maximum_potential: int
var projected_peak: OverallRange


func _init(
	p_current_overall: int,
	p_maximum_potential: int,
	p_projected_peak: OverallRange,
) -> void:
	assert(p_projected_peak != null, "Projected Peak is always a range (§6.3 rule 2)")
	# §6.3 rule 4. These are invariants of the model, not display preferences,
	# so they are checked where the three values are assembled rather than left
	# to whichever screen happens to render them.
	assert(p_current_overall <= p_maximum_potential,
		"CurrentOverall <= MaximumPotentialOverall must always hold (§6.3 rule 4)")
	assert(p_projected_peak.high <= p_maximum_potential,
		"the Projected Peak range must lie at or below Maximum Potential (§6.3 rule 4)")
	current_overall = p_current_overall
	maximum_potential = p_maximum_potential
	projected_peak = p_projected_peak


static func of_player(
	attributes: PlayerAttributes,
	caps: AttributeCaps,
	prospect: int,
	age: int,
	ratings: RatingsProfile,
	progression: ProgressionProfile,
	opportunity_scale: float = 1.0,
	historical_peak_overall: int = -1,
) -> DevelopmentProjection:
	return DevelopmentProjection.new(
		OverallCalculator.current_overall(attributes, ratings),
		OverallCalculator.maximum_potential_overall(caps, ratings),
		ProjectedPeakCalculator.project(
			attributes, caps, prospect, age, ratings, progression,
			opportunity_scale, historical_peak_overall
		)
	)


static func of_state(
	state: PlayerDevelopmentState,
	ratings: RatingsProfile,
	progression: ProgressionProfile,
	opportunity_scale: float = 1.0,
	historical_peak_overall: int = -1,
) -> DevelopmentProjection:
	return of_player(
		state.attributes, state.caps, state.prospect, state.age,
		ratings, progression, opportunity_scale, historical_peak_overall
	)


func signature() -> String:
	return "current=%d;max=%d;peak=%s" % [
		current_overall, maximum_potential, projected_peak.signature(),
	]
