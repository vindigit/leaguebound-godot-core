class_name BuilderConfirmationView
extends RefCounted

## Immutable view model for the Builder confirmation screen
## (`BALANCE_SPEC.md` §7.3.2, PRD BUILD-007, `GODOT_TDD.md` §6.2).
##
## Presentation renders these fields and computes nothing. Every value arrives
## already derived by the domain: the three development values from
## `DevelopmentProjection`, the archetype from `DerivedArchetype`, the caps from
## the one-time draw, the body range from `BodyMaturationPlanner`.
##
## The three development values keep their required labels
## (`DevelopmentProjection.CURRENT_OVERALL_LABEL` and its siblings), and
## Projected Peak arrives as an `OverallRange` so no screen can render it as a
## single number — §28 lists that as a release blocker.
##
## `GDD.md` §6.1: the Builder "does not prevent poor decisions or provide
## aggressive warnings. A neutral confirmation screen summarizes the build
## before commitment." `blocking_failures` therefore carries only *legality*
## failures — an unspent budget, a cap breach — never a judgement that a legal
## build is weak.


var projection: DevelopmentProjection
var archetype: DerivedArchetype
var caps: AttributeCaps
var projected_body_range: BodyRange
var attributes: PlayerAttributes
var budget: CreationBudget
var derived_position: String
var opportunity_notes: PackedStringArray
var can_confirm: bool
var blocking_failures: PackedStringArray


func _init(
	p_projection: DevelopmentProjection,
	p_archetype: DerivedArchetype,
	p_caps: AttributeCaps,
	p_projected_body_range: BodyRange,
	p_attributes: PlayerAttributes,
	p_budget: CreationBudget,
	p_derived_position: String,
	p_opportunity_notes: PackedStringArray,
	p_can_confirm: bool,
	p_blocking_failures: PackedStringArray,
) -> void:
	projection = p_projection
	archetype = p_archetype
	caps = p_caps
	projected_body_range = p_projected_body_range
	attributes = p_attributes
	budget = p_budget
	derived_position = p_derived_position
	opportunity_notes = p_opportunity_notes
	can_confirm = p_can_confirm
	blocking_failures = p_blocking_failures


## The three development values with their required labels, ready to render.
func development_value_rows() -> Array[Array]:
	return [
		[DevelopmentProjection.CURRENT_OVERALL_LABEL, str(projection.current_overall)],
		[DevelopmentProjection.MAXIMUM_POTENTIAL_LABEL, str(projection.maximum_potential)],
		[DevelopmentProjection.PROJECTED_PEAK_LABEL, projection.projected_peak.to_display_string()],
	]
