class_name AdvantageResolver
extends RefCounted


func resolve(
	offensive_player: PlayerMatchProfile,
	defensive_player: PlayerMatchProfile,
	offensive_fatigue: float,
	defensive_fatigue: float,
	random_source: RandomSource,
) -> float:
	var creation := CapabilityCalculator.creation_capability(offensive_player, offensive_fatigue)
	var containment := CapabilityCalculator.containment_capability(defensive_player, defensive_fatigue)
	var bounded_variation := (random_source.next_float() - 0.5) * 0.18
	return clampf((creation - containment) * 0.55 + bounded_variation, -0.35, 0.35)
