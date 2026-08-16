class_name ActionSelector
extends RefCounted

## Weighted selection over the generated candidates.
##
## The candidate list arrives in a canonical order — roster order for actors,
## zone order for shots — which `GODOT_TDD.md` §5.2 requires before randomness
## is consumed. Nothing here re-sorts; a sort at this point would silently
## change every committed ledger.


func select(candidates: Array[ActionCandidate], random_source: RandomSource) -> ActionCandidate:
	assert(not candidates.is_empty(), "at least one valid action candidate is required")
	assert(random_source != null, "action selection requires an injected random source")
	var total_weight: float = 0.0
	for candidate in candidates:
		assert(candidate.weight >= 0.0, "a candidate weight cannot be negative")
		total_weight += candidate.weight
	assert(total_weight > 0.0, "valid action candidates must retain positive total weight")
	var draw: float = random_source.next_float() * total_weight
	var cumulative: float = 0.0
	for candidate in candidates:
		cumulative += candidate.weight
		if draw <= cumulative:
			return candidate
	return candidates[candidates.size() - 1]
