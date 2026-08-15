class_name ShotOutcome
extends RefCounted


var made: bool
var points: int
var probability: float


func _init(p_made: bool = false, p_points: int = 2, p_probability: float = 0.0) -> void:
	assert(p_points == 2 or p_points == 3, "field goals must be worth two or three points")
	assert(p_probability >= 0.0 and p_probability <= 1.0, "shot probability is invalid")
	made = p_made
	points = p_points
	probability = p_probability
