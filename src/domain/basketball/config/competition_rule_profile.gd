class_name CompetitionRuleProfile
extends RefCounted

## One immutable competition rule profile (`SIMULATION_SPEC.md` Â§4).
##
## "Rules are phase-appropriate and recognizable without using licensed league
## names. Period length, foul bonus, line distance, pace environment, and roster
## rules are configurable data. The engine does not infer rules from a generic
## `PRO` flag."
##
## Â§4 also fixes the boundary: a rule profile changes spacing, expected pace,
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
## Â§9.4: "Offensive rebounds use the rule profile's reset behavior."
var offensive_rebound_reset_seconds: int
var frontcourt_seconds: int
var personal_foul_limit: int
## Team fouls in the current period at which the bonus begins.
var team_foul_bonus_threshold: int
var bonus_kind: int
## Team fouls at which the double bonus begins; -1 disables the tier.
var team_foul_double_bonus_threshold: int
var double_bonus_free_throws: int
## Â§5.1 permits a rules-profile exception, but every launch profile resets team
## fouls each period.
var team_fouls_reset_each_period: bool
## Â§13.2 / Â§14: a missed final free throw is live where the rules say so.
var final_free_throw_reboundable: bool
var possession_arrow_enabled: bool
var three_point_profile_id: StringName
var restricted_area_profile_id: StringName
var pace_environment_id: StringName
## The numeric half of the pace environment: a multiplier on every clock draw,
## below one for a quicker competition and above one for a more deliberate one.
##
## `SIMULATION_SPEC.md` Â§4 lists pace environment among the things a rule profile
## configures, but the profile previously carried only an id that nothing read,
## so every competition consumed the clock at the same rate and possessions per
## game were a pure function of period length. Â§14.1 states a different
## possessions band for each competition, and this is the knob that reaches
## them without moving the shared time bands underneath all five.
var pace_multiplier: float
var officiating_profile_id: StringName
var roster_rule_profile_id: StringName
## §4 `timeoutRule`: charged timeouts each team may call in the match.
##
## The Simulation Specification has always listed a timeout rule among the
## things a competition profile configures; nothing read it, and the engine had
## no timeout at all. Overtime does not grant more here — a coach who has spent
## them has spent them, which is what makes the allowance a decision rather
## than an unlimited privilege.
var timeouts_per_team: int


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
	p_pace_multiplier: float = 1.0,
	p_timeouts_per_team: int = 6,
) -> void:
	assert(p_timeouts_per_team >= 0 and p_timeouts_per_team <= 12,
		"a timeout allowance must be a small non-negative count")
	assert(p_pace_multiplier >= 0.60 and p_pace_multiplier <= 1.60,
		"the pace environment multiplier stays inside a credible competition band")
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
	pace_multiplier = p_pace_multiplier
	officiating_profile_id = p_officiating_profile_id
	roster_rule_profile_id = p_roster_rule_profile_id
	timeouts_per_team = p_timeouts_per_team


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


# --- the five calibrated competition profiles -------------------------------
#
# `SIMULATION_SPEC.md` Â§4 makes period length, foul bonus, shot clock, and
# roster rules configurable data rather than something inferred from a `PRO`
# flag, and Â§3 names the competitions. `BALANCE_SPEC.md` Â§14.1 then states a
# possessions-per-game band for each. Those two facts together fix the clock:
# the period length has to be the one under which the Â§14.1 band corresponds to
# a credible seconds-per-possession figure, because possessions per *game* is a
# rate against game length. Each profile below records that arithmetic.
#
# These are the profiles the competition calibration report certifies. They are
# versioned with the engine, not with the calibration harness, because they are
# shipping rules rather than test scaffolding.


## High school: eight-minute quarters (32 minutes), 30-second shot clock,
## one-and-one at seven team fouls and a double bonus at ten, five personal
## fouls. Â§14.1 asks for 61-72 possessions per team, which over 32 minutes is
## 13.3-15.7 seconds per possession.
static func high_school_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"high_school", &"competition-v1", 4, 480, 240, 30, 5, 20, 10,
		7, BonusKind.ONE_AND_ONE, 10, 2, true, true, true,
		&"standard_arc", &"standard_restricted", &"school_pace",
		&"standard_officiating", &"standard_roster", 0.80, 5)


## College: twenty-minute halves (40 minutes), 30-second shot clock, two shots
## from the fifth team foul of the half, five personal fouls. Â§14.1 asks for
## 64-73 possessions, which over 40 minutes is 16.4-18.8 seconds per possession.
static func college_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"college", &"competition-v1", 2, 1200, 300, 30, 5, 20, 10,
		5, BonusKind.TWO_SHOT, -1, 2, true, true, true,
		&"standard_arc", &"standard_restricted", &"college_pace",
		&"standard_officiating", &"standard_roster", 1.00, 4)


## Domestic development: twelve-minute quarters (48 minutes), 24-second shot
## clock, deliberately the fastest environment in the game. Â§14.1 asks for
## 88-101 possessions, which over 48 minutes is 14.3-16.4 seconds per
## possession.
static func development_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"domestic_development", &"competition-v1", 4, 720, 300, 24, 6, 14, 8,
		5, BonusKind.TWO_SHOT, -1, 2, true, true, false,
		&"standard_arc", &"standard_restricted", &"development_pace",
		&"standard_officiating", &"standard_roster", 0.915, 7)


## Overseas: ten-minute quarters (40 minutes), 24-second shot clock, two shots
## from the fifth team foul of the quarter, five personal fouls. Â§14.1 asks for
## 70-82 possessions, which over 40 minutes is 14.6-17.1 seconds per possession.
static func overseas_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"overseas", &"competition-v1", 4, 600, 300, 24, 5, 14, 8,
		4, BonusKind.TWO_SHOT, -1, 2, true, true, true,
		&"standard_arc", &"standard_restricted", &"overseas_pace",
		&"standard_officiating", &"standard_roster", 0.985, 5)


## Top domestic professional: twelve-minute quarters (48 minutes), 24-second
## shot clock, two shots from the fifth team foul of the quarter, six personal
## fouls. Â§14.1 asks for 96-103 possessions, which over 48 minutes is 14.0-15.0
## seconds per possession.
static func top_domestic_profile() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(
		&"top_domestic_pro", &"competition-v1", 4, 720, 300, 24, 6, 14, 8,
		5, BonusKind.TWO_SHOT, -1, 2, true, true, false,
		&"standard_arc", &"standard_restricted", &"top_domestic_pace",
		&"standard_officiating", &"standard_roster", 0.855, 7)
