class_name ActionSelector
extends RefCounted


func select(candidates: Array[ActionCandidate], random_source: RandomSource) -> ActionCandidate:
	assert(not candidates.is_empty(), "at least one valid action candidate is required")
	assert(random_source != null, "action selection requires an injected random source")
	var total_weight := 0.0
	for candidate in candidates:
		total_weight += candidate.weight
	assert(total_weight > 0.0, "valid action candidates must retain positive total weight")
	var draw := random_source.next_float() * total_weight
	var cumulative := 0.0
	for candidate in candidates:
		cumulative += candidate.weight
		if draw <= cumulative:
			return candidate
	return candidates[candidates.size() - 1]
