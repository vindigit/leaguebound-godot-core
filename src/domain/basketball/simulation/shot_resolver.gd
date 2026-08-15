class_name ShotResolver
extends RefCounted


func resolve(
	shooter: PlayerMatchProfile,
	defender: PlayerMatchProfile,
	action_id: StringName,
	advantage: float,
	shooter_fatigue: float,
	defender_fatigue: float,
	balance: SimulationBalanceProfile,
	random_source: RandomSource,
) -> ShotOutcome:
	var capability := CapabilityCalculator.shot_capability(shooter, action_id, shooter_fatigue)
	var contest_rating := defender.attributes.interior_defense if action_id == &"shot_short" else defender.attributes.perimeter_defense
	var contest := (
		Rating.normalized(contest_rating) * 0.70
		+ Rating.normalized(defender.attributes.defensive_iq) * 0.20
		+ Rating.normalized(defender.attributes.vertical) * 0.10
	) * (1.0 - clampf(defender_fatigue, 0.0, 1.0) * 0.25)
	var environment_adjustment := -0.04 if action_id == &"shot_three" else 0.02
	var raw_probability := 0.30 + capability * 0.48 - contest * 0.24 + advantage * 0.30 + environment_adjustment
	var probability := clampf(raw_probability, balance.shot_probability_floor, balance.shot_probability_ceiling)
	var points := 3 if action_id == &"shot_three" else 2
	return ShotOutcome.new(random_source.next_float() < probability, points, probability)
