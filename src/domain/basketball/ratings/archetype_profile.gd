class_name ArchetypeProfile
extends RefCounted

## Display-only configuration for the derived-archetype classifier
## (`SIMULATION_SPEC.md` §10.6.3).
##
## ## Why this is not part of `BalanceProfileSet`
##
## `BALANCE_SPEC.md` §12.4 states that "a balance profile containing an
## archetype-keyed coefficient is invalid". That rule targets coefficients
## looked up *by* archetype — a path from a label back into resolution. The
## thresholds here run the other way: they are inputs that *produce* a label and
## are never read by anything that resolves basketball.
##
## Keeping them in a separate type that the gameplay `BalanceProfileSet` does
## not contain makes that distinction structural and testable, rather than a
## claim in a comment. A test asserts that no gameplay profile exposes archetype
## data at all.


var version: StringName

## How far above the player's own mean cluster score a cluster must sit to earn
## a descriptor. Expressed relative to the player rather than absolutely, so a
## weak player still receives a meaningful description of his shape.
var descriptor_threshold: float
## A second cluster within this distance of the leading one is also named, which
## is how hybrid builds receive sensible composite descriptors instead of being
## forced into one exclusive template (§10.6.3: archetype is not exclusive).
var secondary_descriptor_tolerance: float
## Offence/defence gap below which a player is described as two-way.
var two_way_tolerance: float

## Height boundaries for the position-family noun, in inches.
var guard_height_ceiling: int
var wing_height_ceiling: int


func _init(
	p_version: StringName = &"archetype-v1",
	p_descriptor_threshold: float = 4.0,
	p_secondary_descriptor_tolerance: float = 3.0,
	p_two_way_tolerance: float = 4.0,
	p_guard_height_ceiling: int = 76,
	p_wing_height_ceiling: int = 80,
) -> void:
	assert(not p_version.is_empty(), "an archetype profile requires a version")
	assert(p_descriptor_threshold >= 0.0, "descriptor threshold cannot be negative")
	assert(p_secondary_descriptor_tolerance >= 0.0, "descriptor tolerance cannot be negative")
	assert(p_two_way_tolerance >= 0.0, "two-way tolerance cannot be negative")
	assert(p_guard_height_ceiling < p_wing_height_ceiling,
		"position-family height boundaries must increase")
	version = p_version
	descriptor_threshold = p_descriptor_threshold
	secondary_descriptor_tolerance = p_secondary_descriptor_tolerance
	two_way_tolerance = p_two_way_tolerance
	guard_height_ceiling = p_guard_height_ceiling
	wing_height_ceiling = p_wing_height_ceiling


static func default_profile() -> ArchetypeProfile:
	return ArchetypeProfile.new()
