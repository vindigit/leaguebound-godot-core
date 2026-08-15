class_name BodyProfile
extends RefCounted


var height_inches: int
var weight_pounds: int
var wingspan_inches: int


func _init(p_height_inches: int = 76, p_weight_pounds: int = 200, p_wingspan_inches: int = 78) -> void:
	assert(p_height_inches > 0, "height must be positive")
	assert(p_weight_pounds > 0, "weight must be positive")
	assert(p_wingspan_inches > 0, "wingspan must be positive")
	height_inches = p_height_inches
	weight_pounds = p_weight_pounds
	wingspan_inches = p_wingspan_inches
