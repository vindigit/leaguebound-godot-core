class_name DevelopmentContext
extends RefCounted

## The situational inputs an allocator may consider.
##
## `BALANCE_SPEC.md` §9.7.2 grants the full-detail allocator **AP-equivalent
## opportunity, not finished ratings**, and forbids it from writing a rating
## directly, exceeding a cap, spending currency it was not granted, or using a
## private cost table. Everything here is advisory: it shapes *where* the
## allocator spends, never *how much* it gets or *what* a point costs.
##
## Coach and development context can make an NPC allocate more sensibly. It can
## never make him allocate more cheaply — that would be a discount unavailable
## to the user, which §9.7 does not permit.


## How strongly the coaching and facility context pushes toward correcting
## weaknesses rather than compounding strengths. 0.0 is pure specialization,
## 1.0 is pure deficiency repair.
var deficiency_focus: float
## Development-staff quality, affecting how efficiently the allocator targets
## its own priorities. Never a cost reduction.
var coaching_quality: float
## The phase whose seasonal band supplied the opportunity.
var phase: int


func _init(
	p_deficiency_focus: float = 0.35,
	p_coaching_quality: float = 0.5,
	p_phase: int = CareerPhase.Value.HIGH_SCHOOL,
) -> void:
	assert(p_deficiency_focus >= 0.0 and p_deficiency_focus <= 1.0,
		"deficiency focus is a share")
	assert(p_coaching_quality >= 0.0 and p_coaching_quality <= 1.0,
		"coaching quality is normalized")
	assert(CareerPhase.is_valid(p_phase), "unknown career phase")
	deficiency_focus = p_deficiency_focus
	coaching_quality = p_coaching_quality
	phase = p_phase
