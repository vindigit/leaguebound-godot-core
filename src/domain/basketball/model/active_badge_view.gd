class_name ActiveBadgeView
extends RefCounted


enum Tier { BRONZE, SILVER, GOLD, HALL_OF_FAME }

var badge_id: StringName
var tier: Tier


func _init(p_badge_id: StringName = &"", p_tier: Tier = Tier.BRONZE) -> void:
	badge_id = p_badge_id
	tier = p_tier
