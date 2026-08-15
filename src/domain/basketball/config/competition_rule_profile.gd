class_name CompetitionRuleProfile
extends RefCounted


var profile_id: StringName
var version: StringName
var regulation_periods: int
var period_seconds: int
var overtime_seconds: int
var shot_clock_seconds: int
var personal_foul_limit: int


func _init(
	p_profile_id: StringName = &"five_on_five_baseline",
	p_version: StringName = &"v1",
	p_regulation_periods: int = 4,
	p_period_seconds: int = 480,
	p_overtime_seconds: int = 300,
	p_shot_clock_seconds: int = 24,
	p_personal_foul_limit: int = 5,
) -> void:
	assert(not p_profile_id.is_empty() and not p_version.is_empty(), "rule profile identity and version are required")
	assert(p_regulation_periods > 0, "regulation period count must be positive")
	assert(p_period_seconds > 0 and p_overtime_seconds > 0, "period durations must be positive")
	assert(p_shot_clock_seconds > 0, "shot clock must be positive")
	assert(p_personal_foul_limit > 0, "personal foul limit must be positive")
	profile_id = p_profile_id
	version = p_version
	regulation_periods = p_regulation_periods
	period_seconds = p_period_seconds
	overtime_seconds = p_overtime_seconds
	shot_clock_seconds = p_shot_clock_seconds
	personal_foul_limit = p_personal_foul_limit
