class_name ReboundResolver
extends RefCounted


func select_defensive_rebounder(defense: TeamMatchProfile, random_source: RandomSource) -> PlayerMatchProfile:
	var on_court := defense.on_court_profiles()
	var total_weight := 0.0
	var weights: Array[float] = []
	for player in on_court:
		var weight := (
			float(player.attributes.defensive_rebounding) * 0.55
			+ float(player.attributes.strength) * 0.20
			+ float(player.attributes.vertical) * 0.15
			+ float(player.attributes.defensive_iq) * 0.10
		)
		weights.append(weight)
		total_weight += weight
	var draw := random_source.next_float() * total_weight
	var cumulative := 0.0
	for index in range(on_court.size()):
		cumulative += weights[index]
		if draw <= cumulative:
			return on_court[index]
	return on_court[on_court.size() - 1]
