class_name PlayerAttributes
extends RefCounted


var short_range: int
var dunking: int
var mid_range: int
var three_point: int
var free_throw: int
var handle: int
var passing: int
var vision: int
var offensive_iq: int
var perimeter_defense: int
var interior_defense: int
var stealing: int
var blocking: int
var defensive_iq: int
var offensive_rebounding: int
var defensive_rebounding: int
var speed: int
var strength: int
var stamina: int
var vertical: int


func _init(
	p_short_range: int = 70,
	p_dunking: int = 70,
	p_mid_range: int = 70,
	p_three_point: int = 70,
	p_free_throw: int = 70,
	p_handle: int = 70,
	p_passing: int = 70,
	p_vision: int = 70,
	p_offensive_iq: int = 70,
	p_perimeter_defense: int = 70,
	p_interior_defense: int = 70,
	p_stealing: int = 70,
	p_blocking: int = 70,
	p_defensive_iq: int = 70,
	p_offensive_rebounding: int = 70,
	p_defensive_rebounding: int = 70,
	p_speed: int = 70,
	p_strength: int = 70,
	p_stamina: int = 70,
	p_vertical: int = 70,
) -> void:
	var incoming: Array[int] = [
		p_short_range, p_dunking, p_mid_range, p_three_point, p_free_throw,
		p_handle, p_passing, p_vision, p_offensive_iq, p_perimeter_defense,
		p_interior_defense, p_stealing, p_blocking, p_defensive_iq,
		p_offensive_rebounding, p_defensive_rebounding, p_speed, p_strength,
		p_stamina, p_vertical,
	]
	for key in AttributeKey.all():
		Rating.require_active(incoming[key], AttributeKey.name_of(key))
	short_range = p_short_range
	dunking = p_dunking
	mid_range = p_mid_range
	three_point = p_three_point
	free_throw = p_free_throw
	handle = p_handle
	passing = p_passing
	vision = p_vision
	offensive_iq = p_offensive_iq
	perimeter_defense = p_perimeter_defense
	interior_defense = p_interior_defense
	stealing = p_stealing
	blocking = p_blocking
	defensive_iq = p_defensive_iq
	offensive_rebounding = p_offensive_rebounding
	defensive_rebounding = p_defensive_rebounding
	speed = p_speed
	strength = p_strength
	stamina = p_stamina
	vertical = p_vertical


func get_rating(key: int) -> int:
	match key:
		AttributeKey.Key.SHORT_RANGE: return short_range
		AttributeKey.Key.DUNKING: return dunking
		AttributeKey.Key.MID_RANGE: return mid_range
		AttributeKey.Key.THREE_POINT: return three_point
		AttributeKey.Key.FREE_THROW: return free_throw
		AttributeKey.Key.HANDLE: return handle
		AttributeKey.Key.PASSING: return passing
		AttributeKey.Key.VISION: return vision
		AttributeKey.Key.OFFENSIVE_IQ: return offensive_iq
		AttributeKey.Key.PERIMETER_DEFENSE: return perimeter_defense
		AttributeKey.Key.INTERIOR_DEFENSE: return interior_defense
		AttributeKey.Key.STEALING: return stealing
		AttributeKey.Key.BLOCKING: return blocking
		AttributeKey.Key.DEFENSIVE_IQ: return defensive_iq
		AttributeKey.Key.OFFENSIVE_REBOUNDING: return offensive_rebounding
		AttributeKey.Key.DEFENSIVE_REBOUNDING: return defensive_rebounding
		AttributeKey.Key.SPEED: return speed
		AttributeKey.Key.STRENGTH: return strength
		AttributeKey.Key.STAMINA: return stamina
		AttributeKey.Key.VERTICAL: return vertical
		_: assert(false, "unknown attribute key")
	return Rating.ACTIVE_MINIMUM


func canonical_values() -> Array[int]:
	var result: Array[int] = []
	for key in AttributeKey.all():
		result.append(get_rating(key))
	return result
