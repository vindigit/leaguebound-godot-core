class_name CapabilityCalculator
extends RefCounted


static func shot_capability(player: PlayerMatchProfile, action_id: StringName, fatigue: float) -> float:
	var technical_rating: int
	match action_id:
		&"shot_short": technical_rating = player.attributes.short_range
		&"shot_mid": technical_rating = player.attributes.mid_range
		&"shot_three": technical_rating = player.attributes.three_point
		_: assert(false, "unsupported shot action")
	var technical := Rating.normalized(technical_rating)
	var selection := Rating.normalized(player.attributes.offensive_iq)
	var condition_factor := player.condition * (1.0 - clampf(fatigue, 0.0, 1.0) * 0.35)
	return clampf((technical * 0.82 + selection * 0.18) * condition_factor, 0.0, 1.0)


static func creation_capability(player: PlayerMatchProfile, fatigue: float) -> float:
	var handle_component := Rating.normalized(player.attributes.handle)
	var speed_component := Rating.normalized(player.attributes.speed)
	var iq_component := Rating.normalized(player.attributes.offensive_iq)
	return clampf(
		(handle_component * 0.50 + speed_component * 0.30 + iq_component * 0.20)
		* (1.0 - clampf(fatigue, 0.0, 1.0) * 0.25),
		0.0,
		1.0
	)


static func containment_capability(player: PlayerMatchProfile, fatigue: float) -> float:
	var defense_component := Rating.normalized(player.attributes.perimeter_defense)
	var speed_component := Rating.normalized(player.attributes.speed)
	var iq_component := Rating.normalized(player.attributes.defensive_iq)
	return clampf(
		(defense_component * 0.55 + speed_component * 0.25 + iq_component * 0.20)
		* (1.0 - clampf(fatigue, 0.0, 1.0) * 0.25),
		0.0,
		1.0
	)
