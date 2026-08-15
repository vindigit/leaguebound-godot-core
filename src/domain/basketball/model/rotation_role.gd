class_name RotationRole
extends RefCounted


enum Value { STARTER, ROTATION, LIMITED, EMERGENCY, DNP }


static func is_valid(value: int) -> bool:
	return value >= Value.STARTER and value <= Value.DNP
