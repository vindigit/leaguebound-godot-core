class_name SimulationDetailLevel
extends RefCounted

## How much of a player the world currently simulates
## (`BALANCE_SPEC.md` §9.7, `SIMULATION_SPEC.md` §26).
##
## Detail level selects an executor. It is **not** a property of the player and
## carries no gameplay privilege: §9.7.4 requires that changing it never changes
## ratings, caps, body, maturity state, accumulated development, or committed
## history. §28 lists "a player who improves because the user is about to face
## him" as a release blocker.


enum Value {
	FULL,       ## named player, full-detail allocator
	REDUCED,    ## background population, aggregate executor
}

const COUNT: int = 2
const IDS: PackedStringArray = ["full", "reduced"]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown simulation detail level")
	return StringName(IDS[value])


static func executor_for(detail_level: int) -> int:
	match detail_level:
		Value.FULL:
			return DevelopmentExecutor.Value.FULL_DETAIL_ALLOCATOR
		Value.REDUCED:
			return DevelopmentExecutor.Value.AGGREGATE
		_:
			assert(false, "unknown simulation detail level")
	return DevelopmentExecutor.Value.AGGREGATE
