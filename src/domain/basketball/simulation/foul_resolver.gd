class_name FoulResolver
extends RefCounted


func resolve(
	offensive_player: PlayerMatchProfile,
	defensive_player: PlayerMatchProfile,
	advantage: float,
	balance: SimulationBalanceProfile,
	random_source: RandomSource,
) -> bool:
	var aggression := float(offensive_player.tendencies.at(1) - 1) / 4.0
	var discipline := Rating.normalized(defensive_player.attributes.defensive_iq)
	var probability := clampf(
		balance.base_foul_probability + aggression * 0.04 + maxf(advantage, 0.0) * 0.05 - discipline * 0.035,
		0.01,
		0.20
	)
	return random_source.next_float() < probability
