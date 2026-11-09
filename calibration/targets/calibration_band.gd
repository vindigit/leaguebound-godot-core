class_name CalibrationBand
extends RefCounted

## One authoritative acceptance band, with the document section that owns it.
##
## Bands are constructed only by `CalibrationTargets`. A runner that wants to
## judge a number has to ask for the band by name, which is what keeps the brief
## rule — "targets must load from one versioned source of truth, do not
## duplicate provisional ranges inside a script" — mechanically true rather than
## a convention people remember.

var minimum: float
var maximum: float
## The owning document and section, e.g. "BALANCE_SPEC.md §14.1".
var source: String


func _init(p_minimum: float = 0.0, p_maximum: float = 0.0, p_source: String = "") -> void:
	assert(p_minimum <= p_maximum, "a calibration band must be ordered")
	assert(not p_source.is_empty(), "a calibration band must name its owning section")
	minimum = p_minimum
	maximum = p_maximum
	source = p_source


func contains(value: float) -> bool:
	return value >= minimum and value <= maximum


func midpoint() -> float:
	return (minimum + maximum) / 2.0


func describe() -> String:
	return "[%.4f, %.4f] (%s)" % [minimum, maximum, source]
