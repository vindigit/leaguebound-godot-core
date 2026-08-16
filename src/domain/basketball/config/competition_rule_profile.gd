class_name CompetitionRuleProfile
extends RefCounted

## One immutable competition rule profile (`SIMULATION_SPEC.md` §4).
##
## "Rules are phase-appropriate and recognizable without using licensed league
## names. Period length, foul bonus, line distance, pace environment, and roster
## rules are configurable data. The engine does not infer rules from a generic
## `PRO` flag."
##
## §4 also fixes the boundary: a rule profile changes spacing, expected pace,
## shot-location difficulty, officiating, and substitution patterns. It "cannot
## secretly rewrite stored player ratings", and nothing here is allowed to reach
## a capability.

## Bonus behaviour on a non-shooting defensive foul once the team-foul
## threshold is reached.
enum BonusKind {
	NONE,        ## no bonus tier configured
	ONE_AND_ONE, ## first attempt earns the second
	TWO_SHOT,    ## both attempts awarded outright
}

var profile_id: StringName
var version: StringName
var regulation_periods: int
var period_seconds: int
var overtime_seconds: int
var shot_clock_seconds: int
## §9.4: "Offensive rebounds use the rule profile's reset behavior."
var offensive_rebound_reset_seconds: int
var frontcourt_seconds: int
var personal_foul_limit: int
## Team fouls in the current period at which the bonus begins.
var team_foul_bonus_threshold: int
var bonus_kind: int
## Team fouls at which the double bonus begins; -1 disables the tier.
var team_foul_double_bonus_threshold: int
var double_bonus_free_throws: int
## §5.1 permits a rules-profile exception, but every launch profile resets team
## fouls each period.
var team_fouls_reset_each_period: bool
## §13.2 / §14: a missed final free throw is live where the rules say so.
var final_free_throw_reboundable: bool
var possession_arrow_enabled: bool
var three_point_profile_id: StringName
var restricted_area_profile_id: StringName
var pace_environment_id: StringName
var officiating_profile_id: StringName
var roster_rule_profile_id: StringName


func _init(
	p_profile_id: StringName = &"five_on_five_baseline",
	p_version: StringName = &"v1",
	p_regulation_periods: int = 4,
	p_period_seconds: int = 480,
	p_overtime_seconds: int = 300,
	p_shot_clock_seconds: int = 24,
	p_personal_foul_limit: int = 5,
	p_offensive_rebound_reset_seconds: int = 14,
	p_frontcourt_seconds: int = 8,
	p_team_foul_bonus_threshold: int = 5,
	p_bonus_kind: int = BonusKind.TWO_SHOT,
	p_team_foul_double_bonus_threshold: int = -1,
	p_double_bonus_free_throws: int = 2,
	p_team_fouls_reset_each_period: bool = true,
	p_final_free_throw_reboundable: bool = true,
	p_possession_arrow_enabled: bool = false,
	p_three_point_profile_id: StringName = &"standard_arc",
	p_restricted_area_profile_id: StringName = &"standard_restricted",
	p_pace_environment_id: StringName = &"standard_pace",
	p_officiating_profile_id: StringName = &"standard_officiating",
	p_roster_rule_profile_id: StringName = &"standard_roster",
) -> void:
	assert(not p_profile_id.is_empty() and not p_version.is_empty(),
		"rule profile identity and version are required")
	assert(p_regulation_periods > 0, "regulation period count must be positive")
	assert(p_period_seconds > 0 and p_overtime_seconds > 0, "period durations must be positive")
	assert(p_shot_clock_seconds > 0, "shot clock must be positive")
	assert(
		p_offensive_rebound_reset_seconds > 0
		and p_offensive_rebound_reset_seconds <= p_shot_clock_seconds,
		"the offensive-rebound reset cannot exceed a full shot clock"
	)
	assert(p_frontcourt_seconds > 0, "frontcourt time must be positive")
	assert(p_personal_foul_limit > 0, "personal foul limit must be positive")
	assert(p_team_foul_bonus_threshold > 0, "the bonus threshold must be positive")
	assert(p_bonus_kind >= 0 and p_bonus_kind <= BonusKind.TWO_SHOT, "unknown bonus kind")
	assert(
		p_team_foul_double_bonus_threshold < 0
		or p_team_foul_double_bonus_threshold >= p_team_foul_bonus_threshold,
		"a double bonus cannot begin before the ordinary bonus"
	)
	assert(p_double_bonus_free_throws > 0, "the double bonus must award at least one attempt")
	profile_id = p_profile_id
	version = p_version
	regulation_periods = p_regulation_periods
	period_seconds = p_period_seconds
	overtime_seconds = p_overtime_seconds
	shot_clock_seconds = p_shot_clock_seconds
	personal_foul_limit = p_personal_foul_limit
	offensive_rebound_reset_seconds = p_offensive_rebound_reset_seconds
	frontcourt_seconds = p_frontcourt_seconds
	team_foul_bonus_threshold = p_team_foul_bonus_threshold
	bonus_kind = p_bonus_kind
	team_foul_double_bonus_threshold = p_team_foul_double_bonus_threshold
	double_bonus_free_throws = p_double_bonus_free_throws
	team_fouls_reset_each_period = p_team_fouls_reset_each_period
	final_free_throw_reboundable = p_final_free_throw_reboundable
	possession_arrow_enabled = p_possession_arrow_enabled
	three_point_profile_id = p_three_point_profile_id
	restricted_area_profile_id = p_restricted_area_profile_id
	pace_environment_id = p_pace_environment_id
	officiating_profile_id = p_officiating_profile_id
	roster_rule_profile_id = p_roster_rule_profile_id


func period_length_ms(period: int) -> int:
	assert(period > 0, "periods are one-based")
	return (period_seconds if period <= regulation_periods else overtime_seconds) * 1000


## The **maximum** free throws a non-shooting defensive foul awards, given the
## fouling team's team-foul count *after* the foul is recorded.
##
## A one-and-one awards two: the first is guaranteed and the second is earned by
## making it. Returning one here and adding the second elsewhere would put half
## the rule in the rule profile and half in the engine, and the earned attempt
## went missing entirely the first time it was modelled that way. `is_one_and_one`
## tells the caller which of the two attempts is conditional.
func bonus_free_throws_for(team_fouls_after_foul: int) -> int:
	if (
		team_foul_double_bonus_threshold >= 0
		and team_fouls_after_foul >= team_foul_double_bonus_threshold
	):
		return double_bonus_free_throws
	if team_fouls_after_foul < team_foul_bonus_threshold:
		return 0
	match bonus_kind:
		BonusKind.NONE:
			return 0
		BonusKind.ONE_AND_ONE:
			return 2
		BonusKind.TWO_SHOT:
			return 2
		_:
			assert(false, "unknown bonus kind")
	return 0


## In a one-and-one the second attempt exists only if the first is made, and
## only while the double bonus has not yet been reached.
func is_one_and_one(team_fouls_after_foul: int) -> bool:
	if (
		team_foul_double_bonus_threshold >= 0
		and team_fouls_after_foul >= team_foul_double_bonus_threshold
	):
		return false
	return bonus_kind == BonusKind.ONE_AND_ONE and team_fouls_after_foul >= team_foul_bonus_threshold


## A high-school-shaped profile: eight-minute quarters, one-and-one at seven
## team fouls, double bonus at ten. Used by fixtures and by the bonus tests.
static func school_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"school_baseline", &"v1", 4, 480, 240, 30, 5, 20, 10,
		7, BonusKind.ONE_AND_ONE, 10, 2, true, true, true)


## A top-domestic-shaped profile: twelve-minute quarters, two shots at five
## team fouls, no separate double bonus tier.
static func professional_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"professional_baseline", &"v1", 4, 720, 300, 24, 6, 14, 8,
		5, BonusKind.TWO_SHOT, -1, 2, true, true, false)
