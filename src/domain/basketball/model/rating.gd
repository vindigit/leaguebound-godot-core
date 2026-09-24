class_name Rating
extends RefCounted


const ACTIVE_MINIMUM: int = 25
const MAXIMUM: int = 99

## The active-rating domain message, held as a constant rather than formatted at
## the call site.
##
## GDScript evaluates an `assert` *message* eagerly in a debug build, before it
## checks the condition. The previous form built a three-argument formatted
## string on every call, which the Stage 4 performance profile measured at
## 3.92 us against 0.026 us for the arithmetic the function exists to do — a
## 151x penalty paid on the single hottest call in the engine, since every
## capability normalizes every attribute it weights. The condition below is
## unchanged; only the cost of *not* failing it is.
const ACTIVE_DOMAIN_MESSAGE: String = (
	"a rating must be a whole-number active-player rating from 25 through 99")

## The normalization denominator, precomputed so the hot path does not repeat
## the integer subtraction and float conversion.
const _NORMALIZATION_SPAN: float = 74.0


static func is_valid_active(value: int) -> bool:
	return value >= ACTIVE_MINIMUM and value <= MAXIMUM


## Validates a rating at a domain boundary and returns it.
##
## The detailed, attribute-named message is worth its cost when a rating is
## actually invalid, so it is built inside the failure branch instead of on
## every call. In a release build the assert is stripped and the branch is a
## single comparison, exactly as before.
static func require_active(value: int, attribute_name: StringName = &"rating") -> int:
	if not is_valid_active(value):
		assert(
			false,
			"%s must be a whole-number active-player rating from %d through %d" % [
				attribute_name,
				ACTIVE_MINIMUM,
				MAXIMUM,
			]
		)
	return value


static func normalized(value: int) -> float:
	assert(is_valid_active(value), ACTIVE_DOMAIN_MESSAGE)
	return float(value - ACTIVE_MINIMUM) / _NORMALIZATION_SPAN
