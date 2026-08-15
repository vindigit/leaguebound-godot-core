class_name ActionCandidateGenerator
extends RefCounted


func generate(player: PlayerMatchProfile, clock_ms: int) -> Array[ActionCandidate]:
	assert(player != null, "action generation requires a player")
	assert(clock_ms > 0, "an action cannot begin after period expiration")
	var aggression := float(player.tendencies.at(1) - 1) / 4.0
	var perimeter_preference := 1.0 - float(player.tendencies.at(2) - 1) / 4.0
	var late_clock_multiplier := 1.35 if clock_ms <= 5000 else 1.0
	var result: Array[ActionCandidate] = []
	result.append(ActionCandidate.new(
		&"shot_short",
		float(player.attributes.short_range + player.attributes.dunking) * 0.5 * (0.75 + aggression * 0.5)
	))
	result.append(ActionCandidate.new(
		&"shot_mid",
		float(player.attributes.mid_range) * (0.85 + aggression * 0.3) * late_clock_multiplier
	))
	result.append(ActionCandidate.new(
		&"shot_three",
		float(player.attributes.three_point) * (0.65 + perimeter_preference * 0.7) * late_clock_multiplier
	))
	return result
