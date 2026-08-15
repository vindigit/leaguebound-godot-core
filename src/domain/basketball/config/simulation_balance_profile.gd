class_name SimulationBalanceProfile
extends RefCounted


var profile_id: StringName
var version: StringName
var shot_probability_floor: float
var shot_probability_ceiling: float
var turnover_probability_floor: float
var turnover_probability_ceiling: float
var base_foul_probability: float
var fatigue_per_second: float


func _init(
	p_profile_id: StringName = &"scaffold_baseline",
	p_version: StringName = &"v1",
	p_shot_probability_floor: float = 0.08,
	p_shot_probability_ceiling: float = 0.82,
	p_turnover_probability_floor: float = 0.04,
	p_turnover_probability_ceiling: float = 0.30,
	p_base_foul_probability: float = 0.08,
	p_fatigue_per_second: float = 0.00008,
) -> void:
	assert(not p_profile_id.is_empty() and not p_version.is_empty(), "balance identity and version are required")
	assert(p_shot_probability_floor >= 0.0 and p_shot_probability_ceiling <= 1.0, "shot bounds must be probabilities")
	assert(p_shot_probability_floor <= p_shot_probability_ceiling, "shot bounds are inverted")
	assert(p_turnover_probability_floor >= 0.0 and p_turnover_probability_ceiling <= 1.0, "turnover bounds must be probabilities")
	assert(p_turnover_probability_floor <= p_turnover_probability_ceiling, "turnover bounds are inverted")
	assert(p_base_foul_probability >= 0.0 and p_base_foul_probability <= 1.0, "foul probability is invalid")
	assert(p_fatigue_per_second >= 0.0, "fatigue rate cannot be negative")
	profile_id = p_profile_id
	version = p_version
	shot_probability_floor = p_shot_probability_floor
	shot_probability_ceiling = p_shot_probability_ceiling
	turnover_probability_floor = p_turnover_probability_floor
	turnover_probability_ceiling = p_turnover_probability_ceiling
	base_foul_probability = p_base_foul_probability
	fatigue_per_second = p_fatigue_per_second
