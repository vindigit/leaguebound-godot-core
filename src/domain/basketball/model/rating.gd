class_name Rating
extends RefCounted


const ACTIVE_MINIMUM: int = 25
const MAXIMUM: int = 99


static func is_valid_active(value: int) -> bool:
	return value >= ACTIVE_MINIMUM and value <= MAXIMUM


static func require_active(value: int, attribute_name: StringName = &"rating") -> int:
	assert(
		is_valid_active(value),
		"%s must be a whole-number active-player rating from %d through %d" % [
			attribute_name,
			ACTIVE_MINIMUM,
			MAXIMUM,
		]
	)
	return value


static func normalized(value: int) -> float:
	require_active(value)
	return float(value - ACTIVE_MINIMUM) / float(MAXIMUM - ACTIVE_MINIMUM)
