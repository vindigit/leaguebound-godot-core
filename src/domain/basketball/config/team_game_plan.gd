class_name TeamGamePlan
extends RefCounted

## The coach's game plan (`SIMULATION_SPEC.md` §9.3 `TeamGamePlan`, §10.5, §15).
##
## §10.5: coach instructions modify automatic behaviour, weighted by strictness,
## role, trust, standing, professionalism, and game state. §12.3 caps the coach
## at 25% of ordinary behavioural preference by default, rising to 40% for a
## low-trust young player under a strict coach and falling to 10% for a trusted
## veteran leader.
##
## §10.5 is also explicit about the limit: "The player's saved tendencies remain
## the behavioral baseline. Coaching can substantially shape role and
## opportunity but cannot permanently rewrite those sliders." Nothing here
## writes to `PlayerTendencies`.
##
## Instruction dials use the same five-position scale as the player sliders so
## the two combine through one multiplier table (`BALANCE_SPEC.md` §12.1).

const MINIMUM_POSITION: int = 1
const MAXIMUM_POSITION: int = 5
const NEUTRAL_POSITION: int = 3

var coverage_family: int
## Control tempo (1) through push transition (5).
var tempo_instruction: int
## Perimeter emphasis (1) through interior emphasis (5).
var shot_profile_instruction: int
## Isolation tolerance (1) through ball-movement emphasis (5).
var ball_movement_instruction: int
## Stay home (1) through help aggressively (5).
var help_instruction: int
## Retreat in transition (1) through crash the offensive glass (5).
var crash_instruction: int
## Disciplined (1) through gamble for steals (5).
var gamble_instruction: int
## How much of the behavioural blend the coach commands, before per-player
## trust adjustment. §12.3 bounds it at 0.10-0.40.
var strictness: float
## Coach trust in the roster as a whole (§19.2). Trust changes authority and
## tolerance; it "does not increase the probability that an identical physical
## shot goes in."
var trust: float


func _init(
	p_coverage_family: int = CoverageFamily.Value.MAN_STAY_HOME,
	p_tempo_instruction: int = NEUTRAL_POSITION,
	p_shot_profile_instruction: int = NEUTRAL_POSITION,
	p_ball_movement_instruction: int = NEUTRAL_POSITION,
	p_help_instruction: int = NEUTRAL_POSITION,
	p_crash_instruction: int = NEUTRAL_POSITION,
	p_gamble_instruction: int = NEUTRAL_POSITION,
	p_strictness: float = 0.25,
	p_trust: float = 0.5,
) -> void:
	assert(CoverageFamily.is_valid(p_coverage_family), "unknown coverage family")
	_require_position(p_tempo_instruction)
	_require_position(p_shot_profile_instruction)
	_require_position(p_ball_movement_instruction)
	_require_position(p_help_instruction)
	_require_position(p_crash_instruction)
	_require_position(p_gamble_instruction)
	assert(p_strictness >= 0.10 and p_strictness <= 0.40,
		"BALANCE_SPEC §12.3 bounds coach authority between 10% and 40%")
	assert(p_trust >= 0.0 and p_trust <= 1.0, "coach trust must be normalized")
	coverage_family = p_coverage_family
	tempo_instruction = p_tempo_instruction
	shot_profile_instruction = p_shot_profile_instruction
	ball_movement_instruction = p_ball_movement_instruction
	help_instruction = p_help_instruction
	crash_instruction = p_crash_instruction
	gamble_instruction = p_gamble_instruction
	strictness = p_strictness
	trust = p_trust


## The coach's share of the behavioural blend for one player. A trusted player
## keeps more of his own preference; a strict coach claims more of it. The
## result stays inside the §12.3 band whatever the inputs.
func coach_share_for(player_trust: float) -> float:
	var relief: float = clampf(player_trust, 0.0, 1.0) * 0.15
	return clampf(strictness - relief, 0.10, 0.40)


func _require_position(position: int) -> void:
	assert(
		position >= MINIMUM_POSITION and position <= MAXIMUM_POSITION,
		"coach instruction dials use the same five positions as the player sliders"
	)


static func balanced_plan() -> TeamGamePlan:
	return TeamGamePlan.new()
