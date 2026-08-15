class_name TurnoverResolver
extends RefCounted


func resolve(
	offensive_player: PlayerMatchProfile,
	defensive_player: PlayerMatchProfile,
	advantage: float,
	fatigue: float,
	balance: SimulationBalanceProfile,
	random_source: RandomSource,
) -> bool:
	var security := (
		Rating.normalized(offensive_player.attributes.handle) * 0.65
		+ Rating.normalized(offensive_player.attributes.offensive_iq) * 0.20
		+ Rating.normalized(offensive_player.attributes.strength) * 0.15
	)
	var disruption := (
		Rating.normalized(defensive_player.attributes.stealing) * 0.55
		+ Rating.normalized(defensive_player.attributes.perimeter_defense) * 0.30
		+ Rating.normalized(defensive_player.attributes.defensive_iq) * 0.15
	)
	var raw_probability := 0.16 + (disruption - security) * 0.16 - advantage * 0.12 + fatigue * 0.08
	var probability := clampf(
		raw_probability,
		balance.turnover_probability_floor,
		balance.turnover_probability_ceiling
	)
	return random_source.next_float() < probability
