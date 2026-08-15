class_name OverallRange
extends RefCounted

## An inclusive integer Overall range.
##
## Projected Peak "is always a range and never a single number" (`BALANCE_SPEC.md`
## §6.3 rule 2), and §28 lists displaying it as a single value as a release
## blocker. Giving it a dedicated type means presentation cannot accidentally
## render it as a scalar: there is no single number to reach for.


var low: int
var high: int


func _init(p_low: int, p_high: int) -> void:
	assert(p_low <= p_high, "an Overall range cannot be inverted")
	low = p_low
	high = p_high


func width() -> int:
	return high - low


func contains(value: int) -> bool:
	return value >= low and value <= high


func midpoint() -> float:
	return float(low + high) / 2.0


## The required display form. Kept here so no screen invents its own.
func to_display_string() -> String:
	return "%d-%d" % [low, high]


func signature() -> String:
	return "%d..%d" % [low, high]
