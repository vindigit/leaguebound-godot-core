class_name SimulationBalanceProfile
extends RefCounted

## The versioned owner of every match-resolution tuning constant.
##
## `BALANCE_SPEC.md` Â§4: "Every production tuning constant belongs to a named
## balance profile. Anonymous numeric literals are prohibited inside resolution
## code." `SIMULATION_SPEC.md` Â§30.2 lists "Move the anonymous numeric literals
## in shot resolution into the versioned simulation balance profile" as
## outstanding work; this type closes it.
##
## Values here are **Baselines** in the Â§2 sense. They are calibrated targets
## drawn from Â§12â€“Â§15, not proven values, and they become ship-approved only
## after the Â§31 reports pass. Nothing in this file may be cited as evidence.
##
## Every scalar is published through `describe_tunables()` with a name, unit,
## and safe range so the Gate B0 configuration-integrity check can assert those
## facts without reflection.

## Â§13.1 anchors the open, balanced make baselines at these five ratings.
const SHOT_BASELINE_ANCHOR_RATINGS: PackedFloat64Array = [40.0, 55.0, 70.0, 85.0, 99.0]

## Â§15.1 acute fatigue is a hidden 0-100 value; the capability penalty is
## expressed in rating points at these band edges.
const FATIGUE_PENALTY_ANCHORS: PackedFloat64Array = [0.0, 24.0, 44.0, 64.0, 79.0, 100.0]
const FATIGUE_PENALTY_POINTS: PackedFloat64Array = [0.0, 0.0, 2.0, 6.0, 10.0, 16.0]

## Â§12.1 five-position tendency mapping.
const TENDENCY_MULTIPLIERS: PackedFloat64Array = [0.82, 0.91, 1.00, 1.10, 1.22]

## Â§17.1 action intensity, as a share of the Â§15.1 per-action load range.
## Indexed by `ActionFamily.Value`. "Transition sprint, repeated creation,
## full-pressure defense, contact finishes, and aggressive rebounding cost
## more" â€” the ordering here is that sentence.
const ACTION_INTENSITY_SHARES: PackedFloat64Array = [
	0.00, # pass_swing
	0.75, # drive
	0.25, # pull_up
	0.62, # post_action
	0.48, # pick_action
	0.10, # handoff
	0.55, # off_ball_cut
	0.18, # relocation
	0.40, # screen
	0.05, # reset
	1.00, # transition_attack
	0.70, # putback
]

var profile_id: StringName
var version: StringName

# --- Â§13.1 open, balanced simulated make baselines -------------------------
var baseline_close_non_dunk: PackedFloat64Array = [0.40, 0.50, 0.60, 0.69, 0.78]
var baseline_dunk: PackedFloat64Array = [0.62, 0.72, 0.82, 0.90, 0.96]
var baseline_midrange: PackedFloat64Array = [0.25, 0.34, 0.43, 0.51, 0.58]
var baseline_three: PackedFloat64Array = [0.20, 0.29, 0.37, 0.44, 0.50]
var baseline_free_throw: PackedFloat64Array = [0.50, 0.64, 0.76, 0.86, 0.94]
## A close non-rim attempt is the same touch from further out than the
## restricted area, so it sits under the Â§13.1 close baseline.
var close_non_rim_penalty: float = 0.06
## Â§13.2 lists deep three separately with a lower ceiling; the same distance
## penalty applies to its baseline.
var deep_three_penalty: float = 0.06

# --- Â§13.2 probability floors and ceilings ---------------------------------
var floor_close_non_dunk: float = 0.02
var ceiling_close_non_dunk: float = 0.88
var floor_dunk: float = 0.05
var ceiling_dunk: float = 0.98
var floor_midrange: float = 0.01
var ceiling_midrange: float = 0.72
var floor_standard_three: float = 0.01
var ceiling_standard_three: float = 0.62
var floor_deep_three: float = 0.005
var ceiling_deep_three: float = 0.48
var floor_free_throw: float = 0.35
var ceiling_free_throw: float = 0.97

# --- Â§13.3 contest and context penalties -----------------------------------
var contest_penalty_open: float = 0.0
var contest_penalty_light: float = 0.04
var contest_penalty_moderate: float = 0.10
var contest_penalty_heavy: float = 0.20
var contest_penalty_smothered: float = 0.365
var movement_penalty_max: float = 0.08
var catch_quality_penalty_max: float = 0.07
var fatigue_shot_penalty_max: float = 0.10
var clock_desperation_penalty_max: float = 0.12
## Â§12.6 lists advantage and pass quality as a positive make-quality term.
var advantage_shot_bonus_max: float = 0.10

# --- Â§12.3 contest construction ---------------------------------------------
## Contest pressure is centred rather than read straight off the defender's
## capability. An average defender on an average shooter with no advantage is a
## light-to-moderate contest, not a smothering one; without the centre, every
## uncontested-looking jumper resolved as `HEAVY` and league three-point
## percentage collapsed.
var contest_base_pressure: float = 0.38
var contest_capability_span: float = 0.35
var contest_advantage_relief: float = 0.55
var contest_help_weight: float = 0.55

# --- Â§13.1 contact load ------------------------------------------------------
## How much illegal-contact opportunity a shot in each area generates, before
## the Â§14.3 conversion rate turns opportunity into a whistle.
var interior_contact_base: float = 0.76
var interior_contact_pressure_share: float = 0.70
var perimeter_contact_base: float = 0.14
var perimeter_contact_pressure_share: float = 0.25
## A block opportunity is not simply proportional to contest pressure: a
## defender in the area has some chance at the ball even on a light contest.
var block_opportunity_base_share: float = 0.40
var block_opportunity_pressure_share: float = 0.80
## A completed ordinary pass is a clean catch. Reading catch quality straight
## off Pass Accuracy made every catch-and-shoot attempt carry a penalty, which
## is not what Â§12.2 means by "catch/pass quality".
var catch_quality_floor: float = 0.70

# --- Â§11.2 steal opportunity -------------------------------------------------
## Â§14.3's 28% is the rate at which a *valid strip or interception* converts,
## not the share of turnovers that happen to be steals. The opportunity itself
## therefore has its own rate, driven by coverage pressure and the defender's
## Disciplined â†” Gamble slider.
##
## **Raised in ruleset `simulation-v3-margin` from 0.175 and 0.14.** The §14.1
## points-per-possession overshoot decomposes to field-goal attempts per
## possession: 0.967 measured against roughly 0.90 for a league at the band's
## midpoint. Only two processes remove an attempt from a possession without
## adding points — a turnover and a shorter possession — and `turnover_base` is
## not one of them in practice: it feeds the *unforced* mistake only, which is
## about half a turnover per hundred possessions, so moving it from 0.050 to
## 0.058 changed the measured rate by 0.03 per hundred and was reverted. The
## disruption opportunity is the term that actually sets the rate.
##
## Units: share of ball-handling actions (respectively completed passes) that
## produce a valid strip or interception attempt. Safe range 0.05-0.40.
var steal_opportunity_on_ball: float = 0.200
var steal_opportunity_pass: float = 0.160

# --- Â§14.3 opposed event curves --------------------------------------------
## An ordinary ten-point capability edge changes a qualifying-event probability
## by roughly this relative share; a twenty-five-point edge compounds to the
## 40-70% band Â§14.3 requires.
var opposed_relative_sensitivity: float = 0.20
var turnover_base: float = 0.050
var turnover_floor: float = 0.01
var turnover_ceiling: float = 0.35
## How much absolute ball-handling skill reduces the unforced-mistake rate, on
## top of the §14.3 differential response.
##
## The opposed-event model is differential-neutral by design: a strong handler
## against a strong defender sits where a weak handler against a weak defender
## does. That is correct for *contested* outcomes, but §14.1 steps the turnover
## band down as competition rises — 15-24 at high school to 11-16 at top
## domestic — which is a statement about absolute skill, not about the matchup.
## Without this term the engine produced its *highest* turnover rate in its
## strongest competition, exactly inverting the table. The differential response
## is untouched; only the base rate an unforced mistake starts from moves.
var turnover_absolute_skill_relief: float = 0.95
var steal_conversion_base: float = 0.28
var steal_conversion_floor: float = 0.05
var steal_conversion_ceiling: float = 0.65
var block_conversion_base: float = 0.18
var block_conversion_floor: float = 0.03
var block_conversion_ceiling: float = 0.55
var foul_conversion_base: float = 0.27
var foul_conversion_floor: float = 0.03
var foul_conversion_ceiling: float = 0.58
var advantage_base: float = 0.24
var advantage_floor: float = 0.05
var advantage_ceiling: float = 0.70
## The §14.3 conditional "Qualifying pass becomes credited assist if shot
## scores": baseline 74%, floor 55%, ceiling 95%.
##
## **Restored to the locked baseline.** `fbc8b63` raised it from 0.74 to 0.94,
## which converted very nearly every qualifying delivery and held assist
## percentage near 48% by crediting harder rather than by creating shots. The
## §14.3 row is locked, the engine is not allowed to disagree with it, and the
## deficit it was covering was a creation defect: the openness a pass produced
## was computed and discarded, so a pass could not create a shot at all.
##
## Driven by Pass Accuracy, because §8 assigns "assist conversion support" to
## Passing and "open-target recognition" to Vision, and §11.3 puts execution on
## Passing. Vision earns the opportunity; Passing is what turns the opportunity
## into the basket's credited creator.
var assist_base: float = 0.74
var assist_floor: float = 0.55
var assist_ceiling: float = 0.95
## Lowered from 0.28 to 0.25 in ruleset v2, toward the centre of the §14.1
## top-domestic offensive-rebound band (0.20-0.31) rather than its upper half.
## At 0.28 the engine turned 15.6 misses per 100 possessions into second
## chances against a real-basketball 10-11, and those continuations were the
## largest single term in the points-per-possession overshoot. Safe range
## 0.12-0.48.
var offensive_rebound_base: float = 0.25
var offensive_rebound_floor: float = 0.12
var offensive_rebound_ceiling: float = 0.48
var putback_base: float = 0.23
var putback_floor: float = 0.08
var putback_ceiling: float = 0.48

# --- Â§12.2 action-weight factor guardrails ---------------------------------
var role_opportunity_min: float = 0.60
var role_opportunity_max: float = 1.50
var coach_instruction_min: float = 0.88
var coach_instruction_max: float = 1.15
var tactical_fit_min: float = 0.75
var tactical_fit_max: float = 1.30
var matchup_opportunity_min: float = 0.80
var matchup_opportunity_max: float = 1.25
var score_clock_min: float = 0.70
var score_clock_max: float = 1.45
var late_clock_min: float = 0.40
var late_clock_max: float = 2.00
var capability_confidence_min: float = 0.80
var capability_confidence_max: float = 1.20
var fatigue_availability_min: float = 0.75
var fatigue_availability_floor: float = 0.55
var candidate_weight_min: float = 0.15
var candidate_weight_max: float = 3.50

# --- Â§10.1 action family base weights --------------------------------------
## The base rate at which each family is considered before any Â§10.3 factor.
## These set the shape of an offence â€” how often it swings the ball, how often
## it attacks â€” and are the primary lever for pace and shot mix.
var base_weight_pass_swing: float = 1.20
var base_weight_drive: float = 0.72
## **Lowered from 0.86 to 0.50 in ruleset v6.**
##
## The constant above says it is the rate at which a *family* is considered.
## The pull-up family is not enumerated once: `ActionCandidateGenerator`
## produces one candidate per legal shot zone, so a stated 0.86 reached the
## candidate pool as 2.6-3.4 and the zone enumeration, not the stated rate,
## set the shot mix. Measured at `7b1bfe3`, pull-up jump shots were 77% of every
## field-goal attempt and 41% of all attempts followed no completed pass at all,
## which is a ceiling on assist percentage no attribution rule can lift.
##
## 0.50 across three ordinarily-legal zones is a realised family rate of about
## 1.5, beside `base_weight_pass_swing`'s 1.20 — an offence that moves the ball
## about as often as it rises into a jumper, rather than twice as often the
## other way. This is the §14.1 assist band's creation half; the attribution
## half is `assist_base` and the §11.3 event chain.
##
## It is also what pays for the two §11.3 continuations: a catch-and-shoot ends
## a possession in the action the pass arrives, which shortens possessions and
## raises pace. Restoring the ball-movement share puts the actions back.
## Measured together on the tuning range, pace returns to 101.9 from 107.7 and
## turnovers to 14.5 per 100 from 11.3.
##
## Safe range 0.05-3.0 (Gate B0).
var base_weight_pull_up: float = 0.50
var base_weight_post_action: float = 0.30
var base_weight_pick_action: float = 0.60
var base_weight_handoff: float = 0.22
var base_weight_off_ball_cut: float = 0.34
var base_weight_relocation: float = 0.32
var base_weight_screen: float = 0.34
var base_weight_reset: float = 0.30
var base_weight_transition_attack: float = 0.95
var base_weight_putback: float = 1.00

# --- Â§11.1 advantage continuations ------------------------------------------
## How often an attacking action finishes at the rim rather than continuing as
## a kick-out or reset when no clear advantage was created. A clear or
## breakdown advantage always finishes; these govern the ambiguous case, and
## they are the primary lever on how many actions a possession contains.
var drive_finish_share: float = 0.55
var post_finish_share: float = 0.70
var pick_finish_share: float = 0.35
var cut_finish_share: float = 0.85

## Â§11.1 advantage continuation, kick-out branch.
##
## An attack that collapses the defence does not always finish at the rim. The
## help it drew leaves someone open, and the pass out to that player is both the
## dominant source of catch-and-shoot three-point attempts and the dominant
## source of assists in modern basketball. Without this branch a material
## advantage always ended at the rim, which suppressed the three-point attempt
## rate and the assist rate together â€” the Â§14.1 bands for both were unreachable
## by construction rather than by tuning.
var drive_kick_out_share: float = 0.92
var pick_kick_out_share: float = 0.82
var post_kick_out_share: float = 0.55
## The share of a pick action's material advantage that resolves as the screener
## rolling and finishing off the handler's pass, rather than the handler
## shooting. This is the other half of the same missing branch: the roll finish
## is an assisted basket and the handler's pull-up is not.
var roll_finish_share: float = 0.80
## A kicked-out pass only exists if someone is actually spaced for it; a
## team-mate below this three-point capability is not a kick-out target.
var kick_out_spacer_threshold: float = 0.30

## §11.3 pass continuation, catch-and-shoot branch.
##
## The share of completed passes the receiver shoots off the catch rather than
## holding for a separate action, **scaled by the openness the delivery
## produced**. A catch-and-shoot jumper does not need the defence broken down
## the way a cut finish or a drive kick-out does; it needs a beat of space, and
## the §11.1 advantage quality is exactly how much space the delivery bought. A
## pass that created nothing is never shot off the catch, and a breakdown almost
## always is.
##
## Every other creating family in the engine already has its continuation: the
## drive kicks out, the pick action rolls, the post kicks out, the cut is fed
## and finished. The pass, which is the most frequent action in basketball, had
## none — a delivery that broke the defence down simply handed the ball over,
## and the opening it created was gone by the next independent action draw.
## That is why half of every pull-up in the engine followed no pass at all and
## why assist percentage sat flat near 48% at every competition while the §14.1
## bands rise with level.
##
## This is the branch that makes the catch-and-shoot a play rather than a
## coincidence, and it is what §12.1's `CATCH_AND_SHOOT` assisted state was
## always describing. It fires only on a material advantage, so it is earned by
## the passer's Vision against the defence rather than granted; it is not
## reachable late in the shot clock, where the offence has no time to relocate
## into the catch.
##
## Safe range 0.0-0.85. At zero the engine is the pre-fix engine.
var pass_catch_and_shoot_share: float = 0.85

## §10.1 relocation continuation, spot-up branch.
##
## The share of relocations the ball finds, scaled by the separation the
## relocation actually produced. §10.1 names the family "Relocation or spot-up", and a
## spot-up whose ball never arrives is not a basketball action. This family
## emitted an event and changed no state at all, which is why a quarter of the
## engine's off-ball work could not produce a shot and why so many possessions
## reached a shot without a single completed pass.
##
## Safe range 0.0-0.85. At zero the family is inert again.
var relocation_spot_up_share: float = 0.80

# --- Â§10.2 candidate validity thresholds ------------------------------------
## "An impossible action receives no weight." These are the capability and
## clock gates that decide whether a candidate exists at all â€” the only place a
## factor is allowed to reach zero (Â§10.3).
var deep_three_capability_threshold: float = 0.55
var post_action_capability_threshold: float = 0.42
var pull_up_three_capability_threshold: float = 0.18
## Below this shot clock the offence may no longer reset.
var reset_block_clock_ms: int = 6000
## Below this shot clock only a shot attempt remains legal.
var desperation_clock_ms: int = 2500
## Spacing: the three-point capability at which a player counts as a spacer.
var spacer_capability_threshold: float = 0.45

# --- Â§12.3 player and coach priority ---------------------------------------
var player_preference_share: float = 0.75
var coach_preference_share: float = 0.25

# --- usage as a constrained team budget ------------------------------------
## How hard realized usage is pulled back toward the opportunity share implied
## by role, tendencies, and capability. Zero would let one player take every
## touch; one would force exact shares and erase star usage.
var usage_elasticity: float = 0.55
var usage_damping_min: float = 0.55
var usage_damping_max: float = 1.60

# --- Â§15.1 fatigue, condition, and recovery --------------------------------
var base_fatigue_per_active_minute: float = 1.20
var stamina_fatigue_relief: float = 0.42
var action_load_min: float = 0.15
var action_load_max: float = 0.80
var bench_recovery_per_minute: float = 1.50
var recovery_stamina_min_multiplier: float = 0.85
var recovery_stamina_max_multiplier: float = 1.20

# --- Â§6.1 body effects ------------------------------------------------------
## Body affects action validity, reach, positioning/leverage, and matchups, and
## nothing else. Every constant here belongs to one of those four channels, and
## none of them is allowed to become a general bonus.
var rim_height_inches: float = 120.0
var dunk_clearance_inches: float = 4.0
var vertical_min_inches: float = 18.0
var vertical_max_inches: float = 44.0
## Reach difference, in inches, that produces the full reach effect.
var reach_scale_inches: float = 12.0
var reach_effect_max: float = 0.12
## Weight and height differences, in their own units, that produce the full
## leverage and matchup effects.
var weight_scale_pounds: float = 60.0
var height_scale_inches: float = 10.0
var body_effect_max: float = 0.15
var rebound_reach_min_inches: float = 96.0
var rebound_reach_max_inches: float = 156.0
## How much an active injury limitation can suppress capability, on top of
## pregame condition. Â§17.3 keeps this an availability and execution effect,
## never a rating rewrite.
var injury_capability_share: float = 0.35

# --- Â§18 planned rotation ---------------------------------------------------
## Planned share of a player's team's available on-court seconds, by rotation
## role. Â§10.6.1: rotation role "affects planned minutes, substitution
## priority, and closing-lineup consideration. It does not affect capability or
## success probability." These shares are the whole of that privilege.
var minute_share_star: float = 0.75
var minute_share_starter: float = 0.70
var minute_share_sixth_player: float = 0.55
var minute_share_rotation: float = 0.42
var minute_share_bench: float = 0.25
var minute_share_reserve: float = 0.10
var minute_share_developmental: float = 0.04
## Â§18.2: rotations adjust for fatigue, foul trouble, injury, score, matchup,
## and overtime â€” they are not recomputed from scratch every possession.
var substitution_stint_seconds: int = 300
var substitution_rest_seconds: int = 150
var fatigue_substitution_threshold: float = 68.0
## Personal fouls remaining at which a coach protects a player before the limit.
var foul_trouble_margin: int = 1
## The period from which foul-trouble protection stops (a coach stops hiding a
## starter in the closing period).
var foul_protection_final_period_relief: int = 1

## §18.2 score and time: the margin below which a game is never settled,
## whatever the clock says.
##
## The safety calculation below is a statement about dispersion and it is
## correct at any margin; this is the coaching floor on top of it. Twelve points
## with ninety seconds left is arithmetically safe and no coach on earth empties
## his bench into it, because a three and a stop turn it into a game. Eighteen
## is the smallest margin at which resting the players you need next week is a
## recognisable decision rather than a forfeit.
##
## **Replaced `decided_game_margin` in ruleset `simulation-v5-garbage-time`.**
## That constant was the *entire* rule — twenty points inside a share of the
## final period — and it is now one of three guards on a possession-based
## safety measure.
##
## Units: points. Safe range 8-40.
var settled_minimum_margin: int = 18
## Points of margin dispersion one possession pair contributes.
##
## The margin of the game still to be played is a sum over the remaining pairs,
## so its standard deviation is this times the square root of them. Measured
## rather than chosen: the pooled within-team-game variance of one possession's
## points is about 1.57 across the five competitions, and two possessions per
## pair puts the pair's standard deviation at sqrt(2 * 1.57) = 1.77.
##
## Units: points per square-root possession pair. Safe range 1.0-3.0.
var settled_swing_points_per_pair: float = 1.77
## How safe a lead has to be before the coach holding it starts resting people,
## in standard deviations of the margin still to be played.
##
## 2.6 is a win probability around 99.5%. **This is the lower of the two
## thresholds and the asymmetry is the correction the owner authorised**: a
## coach who has won the game reaches this point before a coach who has lost it
## reaches his.
##
## Units: standard deviations. Safe range 1.5-6.0.
var settled_leading_safety: float = 2.6
## How hopeless a deficit has to be before the coach facing it concedes and goes
## to his bench.
##
## 4.2 standard deviations is a win probability near one in fifty thousand.
## Trailing coaches concede late and reluctantly, and the gap between this and
## `settled_leading_safety` is the window in which a leading bench plays a
## trailing rotation — which is what real garbage time is.
##
## Units: standard deviations. Safe range 2.0-10.0.
var settled_trailing_safety: float = 4.2
## The share of its entry threshold at which a team returns to its competitive
## rotation.
##
## Below one so a game sitting exactly on the boundary does not alternate every
## possession. The state is not a latch: a trailing team that actually closes
## the gap gets both rotations back, which is a consequence of the points it
## scored and not a bonus for having been behind.
##
## Units: share of the entry threshold. Safe range 0.50-1.00.
var settled_release_share: float = 0.85
## The fewest possession pairs that may remain for a team to *newly* enter the
## settled rotation. Below one pair there is no rest left to give and a
## substitution is churn.
##
## Units: possession pairs. Safe range 0.0-6.0.
var settled_minimum_pairs_left: float = 1.0

# --- Â§9.4 time consumption --------------------------------------------------
var inbound_seconds_min: int = 2
var inbound_seconds_max: int = 4
var advance_seconds_min: int = 2
var advance_seconds_max: int = 5
var half_court_entry_seconds_min: int = 2
var half_court_entry_seconds_max: int = 4
var action_seconds_min: int = 1
var action_seconds_max: int = 4
var reset_seconds_min: int = 3
var reset_seconds_max: int = 6
var post_action_seconds_min: int = 3
var post_action_seconds_max: int = 6
var transition_seconds_min: int = 2
var transition_seconds_max: int = 4
var rebound_seconds_min: int = 1
var rebound_seconds_max: int = 2
## Â§9.4: "Dead-ball fouls and free throws use separate event time without
## incorrectly consuming shot-clock time."
var free_throw_event_seconds: int = 2
var dead_ball_event_seconds: int = 1

# --- transition, crash, and coverage shares ---------------------------------
var transition_share_base: float = 0.22
var transition_share_after_turnover: float = 0.38
var transition_share_min: float = 0.04
var transition_share_max: float = 0.62
var crash_share_base: float = 0.42
var crash_share_min: float = 0.05
var crash_share_max: float = 0.80
## A player who retreats instead of crashing still recovers a long carom
## occasionally; zero would make the offensive glass a pure function of who
## crashed.
var crash_retreat_intent_share: float = 0.30
## The raw candidate-score share an ordinary lineup produces. The Â§14.3 base
## rate is defined *at* this reference, so lineup quality moves the rate around
## its calibration target instead of dragging it to a bound.
var offensive_rebound_reference_share: float = 0.34
var offensive_rebound_spread: float = 1.20

# --- Â§17 chemistry and home environment (bounded, never a flat bonus) -------
var chemistry_pass_bonus_max: float = 0.04
var chemistry_help_bonus_max: float = 0.04
## §19.4's three implemented channels, each in **absolute probability points**
## at full venue strength, each individually bounded by
## `HomeEnvironmentContext.MAX_SINGLE_MODIFIER` (§17.4's four points) and
## jointly by `MAX_COMBINED_MODIFIER`.
##
## They replace `home_environment_shot_bonus`, which added a term to the make
## probability of every home field-goal attempt regardless of who was shooting,
## from where, or against what contest. §19.4 authorizes bounded officiating,
## communication, composure and familiarity; a flat make bonus is none of them,
## and §19.2 rules out the identical thing for Coach Trust in the same breath —
## "it does not increase the probability that an identical physical shot goes
## in". It was also carrying most of the home advantage, which is why removing
## it and replacing it is a correction rather than a deletion.
##
## Fitted on the §5.17 tuning range and validated on two untouched ranges.
var home_officiating_modifier: float = 0.013
var home_communication_modifier: float = 0.018
var home_composure_modifier: float = 0.011

# --- §10.2/§10.3/§18.2 score-and-clock game management -----------------------
## How much of a deficit a trailing team takes back in one pair of possessions
## it wins outright: it scores about one and a sixth, and stopping the other
## side is worth about as much again.
##
## This is the denominator that turns a margin into "how many possessions do I
## need", which is the quantity a coach actually manages against. It is not a
## probability and it never reaches a resolver.
##
## Units: points per possession pair. Safe range 1.0-6.0.
var management_swing_points: float = 2.4
## The share of the remaining game a deficit has to consume before either coach
## changes anything.
##
## This floor is what keeps ordinary basketball ordinary. A ten-point margin
## with a half to play needs about a tenth of the remaining possessions and sits
## far below it, so the §14.1 possession, efficiency and shot-mix bands are
## measured on exactly the basketball they were measured on before this existed.
##
## Units: share of remaining possession pairs. Safe range 0.0-0.60.
var management_pressure_floor: float = 0.20
## Extra clock a team protecting a lead consumes per possession, at full
## pressure. Units: share of the possession's time draw. Safe range 0.0-0.40.
var protect_pace_gain: float = 0.22
## Clock a chasing team saves per possession, at full pressure. Smaller than the
## protecting gain because a possession has a physical floor.
## Units: share of the possession's time draw. Safe range 0.0-0.30.
var chase_pace_relief: float = 0.12
## Weight a protecting team adds to a reset, at full pressure.
## Units: share of the §10.3 score-and-clock factor. Safe range 0.0-0.60.
var protect_reset_gain: float = 0.35
## Weight a protecting team takes off a three, at full pressure.
## Units: share of the §10.3 score-and-clock factor. Safe range 0.0-0.50.
var protect_three_relief: float = 0.25
## Weight a chasing team adds to a three and takes off a reset, at full
## pressure. Units: share of the §10.3 score-and-clock factor. Safe range
## 0.0-0.60.
var chase_three_gain: float = 0.30
## How much of its offensive-glass crashing a team protecting a lead gives up,
## at full pressure, in exchange for transition defence.
## Units: share of the crash rate. Safe range 0.0-0.60.
var protect_crash_relief: float = 0.45
## How much more a chasing team crashes, at full pressure. Smaller than the
## protecting relief: there are only so many players to send.
## Units: share of the crash rate. Safe range 0.0-0.60.
var chase_crash_gain: float = 0.25
## How much regulation has to be left for the last-possession rule to apply.
## About one possession plus the stop that would follow it.
## Units: milliseconds of regulation remaining. Safe range 8000-60000.
var endgame_possession_ms: int = 32000
## Weight added to the shot value that levels the game on the last possession of
## regulation. Units: share of the §10.3 score-and-clock factor. Safe range
## 0.0-0.80.
var endgame_tie_gain: float = 0.40
## Weight taken off the shot value that does not level it.
## Units: share of the §10.3 score-and-clock factor. Safe range 0.0-0.70.
var endgame_tie_relief: float = 0.35

# --- §4/§5 coaching timeouts -------------------------------------------------
## Unanswered points by the opponent at which a coach stops the run.
## Units: points. Safe range 4-15.
var timeout_run_points: int = 8
## Acute fatigue every player on the floor recovers over a timeout, both teams.
## A timeout is a rest, which is the whole of its effect here; it grants no
## probability to anybody. Units: fatigue points. Safe range 0-20.
var timeout_recovery_points: float = 6.0
## Below this much regulation time a coach holds his remaining timeouts for the
## endgame rather than spending one to stop a run.
## Units: milliseconds of regulation remaining. Safe range 0-180000.
var timeout_run_reserve_ms: int = 90000

# --- deliberate late-game fouling (Â§13.1 "deliberate late-game strategy") ---
var intentional_foul_max_margin: int = 6
var intentional_foul_clock_ms: int = 40000
var intentional_foul_share: float = 0.55

# --- §18.2 game stakes ------------------------------------------------------
## How much further past his planned share a coach lets a player run, per stakes
## tier above regular season.
##
## Two tiers at 0.10 is a twenty per cent tolerance: a starter planned for 34
## minutes of a 40-minute game rides to about 41% of it before the bench takes
## the minutes back. That is a tighter rotation, not a different roster, and
## foul trouble, fatigue, injury and the settled rotation all still take
## precedence over it.
##
## Units: share of the planned minute share, per tier. Safe range 0.0-0.35.
var stakes_rotation_tightness_step: float = 0.10
## How much earlier a coach starts holding his timeouts for the endgame, per
## stakes tier.
##
## Two tiers at 0.35 turns a 90-second reserve into 153 seconds: a championship
## coach stops spending timeouts on the opponent's run about a minute sooner
## than a regular-season one, and arrives at the last possession holding more of
## them.
##
## Units: share of `timeout_run_reserve_ms`, per tier. Safe range 0.0-0.60.
var stakes_timeout_reserve_step: float = 0.35
## How many more standard deviations of safety a coach demands before entering
## the settled rotation, per stakes tier.
##
## Two tiers at 0.15 raises the leading threshold from 2.6 to 3.38 and the
## trailing one from 4.2 to 5.46. Both remain finite, and the safety number they
## are compared against grows without bound as the clock runs out, so a
## genuinely decided championship game still reaches garbage time — later, and
## still with the eighteen-point coaching floor and the one-possession-pair
## guard underneath it.
##
## Units: share of the entry threshold, per tier. Safe range 0.0-0.30.
var stakes_settled_patience_step: float = 0.15
## How much earlier the end-of-regulation tie-seeking window opens, per stakes
## tier.
##
## Two tiers at 0.50 opens it at 64 seconds rather than 32. It is the largest
## step here because it is the one whose unit is time rather than preference:
## the rule itself is unchanged, it simply applies to the last two possessions
## of a Final instead of the last one.
##
## Units: share of `endgame_possession_ms`, per tier. Safe range 0.0-1.00.
var stakes_endgame_window_step: float = 0.50
## How much more firmly the tie-seeking preference is held, per stakes tier.
##
## Two tiers at 0.25 takes the levelling-shot gain from 0.40 to 0.60 and the
## relief on the other shot from 0.35 to 0.525, both still inside the clamps the
## base values already lived under.
##
## Units: share of the tie-seeking weights, per tier. Safe range 0.0-0.50.
var stakes_endgame_conviction_step: float = 0.25

# --- Â§24.2 possessions estimate --------------------------------------------
## The classic estimator's free-throw weight. Engine possessions come from
## terminal possession records; this is only the published estimate beside them.
var possession_estimate_free_throw_weight: float = 0.44

# --- safety bounds ----------------------------------------------------------
var max_actions_per_possession: int = 24

## Tactical role's whole numeric privilege (Â§12.4), owned by this profile so it
## is versioned with everything else it competes against.
var _role_opportunity_table: RoleOpportunityTable


func _init(
	p_profile_id: StringName = &"simulation_baseline",
	p_version: StringName = &"simulation-v7-home-environment",
) -> void:
	assert(not p_profile_id.is_empty() and not p_version.is_empty(),
		"balance identity and version are required")
	profile_id = p_profile_id
	version = p_version
	_role_opportunity_table = RoleOpportunityTable.new()


## Â§10.1 base consideration rate for an action family.
func action_base_weight(action_family: int) -> float:
	match action_family:
		ActionFamily.Value.PASS_SWING:
			return base_weight_pass_swing
		ActionFamily.Value.DRIVE:
			return base_weight_drive
		ActionFamily.Value.PULL_UP:
			return base_weight_pull_up
		ActionFamily.Value.POST_ACTION:
			return base_weight_post_action
		ActionFamily.Value.PICK_ACTION:
			return base_weight_pick_action
		ActionFamily.Value.HANDOFF:
			return base_weight_handoff
		ActionFamily.Value.OFF_BALL_CUT:
			return base_weight_off_ball_cut
		ActionFamily.Value.RELOCATION:
			return base_weight_relocation
		ActionFamily.Value.SCREEN:
			return base_weight_screen
		ActionFamily.Value.RESET:
			return base_weight_reset
		ActionFamily.Value.TRANSITION_ATTACK:
			return base_weight_transition_attack
		ActionFamily.Value.PUTBACK:
			return base_weight_putback
		_:
			assert(false, "unknown action family")
	return base_weight_reset


## Â§12.2/Â§12.4 role opportunity, clamped to the ordinary band unless the table
## deliberately reaches into the exceptional one.
func role_opportunity(tactical_role: int, action_family: int) -> float:
	var raw: float = _role_opportunity_table.opportunity(tactical_role, action_family)
	return clampf(raw, RoleOpportunityTable.EXCEPTIONAL_MINIMUM, RoleOpportunityTable.EXCEPTIONAL_MAXIMUM)


# --- shot profile access ----------------------------------------------------

## The Â§13.1 open, balanced baseline for a zone, given the shooter's relevant
## shot capability on the unit interval.
func shot_baseline(zone: int, capability: float, dunk: bool) -> float:
	var rating: float = Rating.ACTIVE_MINIMUM + clampf(capability, 0.0, 1.0) * float(
		Rating.MAXIMUM - Rating.ACTIVE_MINIMUM)
	if dunk:
		return _interpolate(baseline_dunk, rating)
	match zone:
		ShotZone.Value.RESTRICTED_RIM:
			return _interpolate(baseline_close_non_dunk, rating)
		ShotZone.Value.CLOSE_NON_RIM:
			return _interpolate(baseline_close_non_dunk, rating) - close_non_rim_penalty
		ShotZone.Value.MIDRANGE:
			return _interpolate(baseline_midrange, rating)
		ShotZone.Value.STANDARD_THREE:
			return _interpolate(baseline_three, rating)
		ShotZone.Value.DEEP_THREE:
			return _interpolate(baseline_three, rating) - deep_three_penalty
		_:
			assert(false, "unknown shot zone")
	return 0.0


func free_throw_baseline(capability: float) -> float:
	var rating: float = Rating.ACTIVE_MINIMUM + clampf(capability, 0.0, 1.0) * float(
		Rating.MAXIMUM - Rating.ACTIVE_MINIMUM)
	return _interpolate(baseline_free_throw, rating)


func shot_floor(zone: int, dunk: bool) -> float:
	if dunk:
		return floor_dunk
	match zone:
		ShotZone.Value.RESTRICTED_RIM, ShotZone.Value.CLOSE_NON_RIM:
			return floor_close_non_dunk
		ShotZone.Value.MIDRANGE:
			return floor_midrange
		ShotZone.Value.STANDARD_THREE:
			return floor_standard_three
		ShotZone.Value.DEEP_THREE:
			return floor_deep_three
		_:
			assert(false, "unknown shot zone")
	return 0.0


func shot_ceiling(zone: int, dunk: bool) -> float:
	if dunk:
		return ceiling_dunk
	match zone:
		ShotZone.Value.RESTRICTED_RIM, ShotZone.Value.CLOSE_NON_RIM:
			return ceiling_close_non_dunk
		ShotZone.Value.MIDRANGE:
			return ceiling_midrange
		ShotZone.Value.STANDARD_THREE:
			return ceiling_standard_three
		ShotZone.Value.DEEP_THREE:
			return ceiling_deep_three
		_:
			assert(false, "unknown shot zone")
	return 1.0


func contest_penalty(band: int) -> float:
	match band:
		ContestBand.Value.OPEN:
			return contest_penalty_open
		ContestBand.Value.LIGHT:
			return contest_penalty_light
		ContestBand.Value.MODERATE:
			return contest_penalty_moderate
		ContestBand.Value.HEAVY:
			return contest_penalty_heavy
		ContestBand.Value.SMOTHERED:
			return contest_penalty_smothered
		_:
			assert(false, "unknown contest band")
	return 0.0


# --- opposed event resolution ----------------------------------------------

## Â§14.3: a conditional event rate, shifted by a capability differential
## expressed in Â§5.1 `RatingDifferential` units, then clamped to the event's
## own floor and ceiling. This is the only place an opposed rate is built, so
## the 15-25% relative response to a ten-point edge holds everywhere.
func opposed_probability(
	base: float,
	differential_units: float,
	event_floor: float,
	event_ceiling: float,
) -> float:
	var scaled: float = base * pow(1.0 + opposed_relative_sensitivity, differential_units)
	return clampf(scaled, event_floor, event_ceiling)


## The unforced-mistake base for a ball handler of a given absolute security,
## before the §14.3 differential response is applied on top.
func unforced_turnover_base(absolute_security: float) -> float:
	return turnover_base * (
		1.0 - turnover_absolute_skill_relief * clampf(absolute_security, 0.0, 1.0))


# --- Â§12.1 tendency and Â§12.2 clamps ---------------------------------------

## The multiplier a slider position contributes toward its selected pole.
func tendency_multiplier(position: int) -> float:
	assert(position >= PlayerTendencies.MINIMUM and position <= PlayerTendencies.MAXIMUM,
		"tendency positions run from one through five")
	return TENDENCY_MULTIPLIERS[position - 1]


## The reciprocal multiplier the opposing action family receives (Â§12.1).
func opposing_tendency_multiplier(position: int) -> float:
	return 1.0 / tendency_multiplier(position)


func clamp_candidate_weight(weight: float, base: float) -> float:
	return clampf(weight, candidate_weight_min * base, candidate_weight_max * base)


# --- Â§15.1 fatigue ----------------------------------------------------------

## Acute fatigue added per active minute, before per-action load.
func fatigue_per_active_minute(stamina: int) -> float:
	return base_fatigue_per_active_minute * (
		1.0 - stamina_fatigue_relief * Rating.normalized(stamina))


## Â§15.1 additional load for one high-intensity action, in fatigue points.
func action_load(action_family: int) -> float:
	assert(ActionFamily.is_valid(action_family), "unknown action family")
	return lerpf(
		action_load_min, action_load_max, ACTION_INTENSITY_SHARES[action_family])


## The planned share of team on-court seconds for a rotation role (Â§18.1).
func rotation_minute_share(rotation_role: int) -> float:
	match rotation_role:
		RotationRole.Value.STAR:
			return minute_share_star
		RotationRole.Value.STARTER:
			return minute_share_starter
		RotationRole.Value.SIXTH_PLAYER:
			return minute_share_sixth_player
		RotationRole.Value.ROTATION:
			return minute_share_rotation
		RotationRole.Value.BENCH:
			return minute_share_bench
		RotationRole.Value.RESERVE:
			return minute_share_reserve
		RotationRole.Value.DEVELOPMENTAL:
			return minute_share_developmental
		_:
			assert(false, "unknown rotation role")
	return minute_share_rotation


func recovery_per_bench_minute(stamina: int) -> float:
	var multiplier: float = lerpf(
		recovery_stamina_min_multiplier,
		recovery_stamina_max_multiplier,
		Rating.normalized(stamina))
	return bench_recovery_per_minute * multiplier


## The Â§15.1 capability penalty, in rating points, for an acute fatigue value.
func fatigue_penalty_points(acute_fatigue: float) -> float:
	var bounded: float = clampf(acute_fatigue, 0.0, 100.0)
	for index in range(1, FATIGUE_PENALTY_ANCHORS.size()):
		if bounded <= FATIGUE_PENALTY_ANCHORS[index]:
			var span: float = FATIGUE_PENALTY_ANCHORS[index] - FATIGUE_PENALTY_ANCHORS[index - 1]
			var share: float = 0.0 if span <= 0.0 else (bounded - FATIGUE_PENALTY_ANCHORS[index - 1]) / span
			return lerpf(FATIGUE_PENALTY_POINTS[index - 1], FATIGUE_PENALTY_POINTS[index], share)
	return FATIGUE_PENALTY_POINTS[FATIGUE_PENALTY_POINTS.size() - 1]


## The same penalty expressed on the unit capability interval, so a resolver
## never converts rating points itself.
func fatigue_capability_penalty(acute_fatigue: float) -> float:
	return fatigue_penalty_points(acute_fatigue) / float(Rating.MAXIMUM - Rating.ACTIVE_MINIMUM)


# --- Gate B0 ----------------------------------------------------------------

func describe_tunables() -> Array[BalanceTunable]:
	var tunables: Array[BalanceTunable] = []
	_add(tunables, &"shot.close_non_rim_penalty", &"probability", close_non_rim_penalty, 0.0, 0.20)
	_add(tunables, &"shot.deep_three_penalty", &"probability", deep_three_penalty, 0.0, 0.20)
	_add(tunables, &"shot.floor_close_non_dunk", &"probability", floor_close_non_dunk, 0.0, 0.20)
	_add(tunables, &"shot.ceiling_close_non_dunk", &"probability", ceiling_close_non_dunk, 0.50, 1.0)
	_add(tunables, &"shot.floor_dunk", &"probability", floor_dunk, 0.0, 0.20)
	_add(tunables, &"shot.ceiling_dunk", &"probability", ceiling_dunk, 0.50, 1.0)
	_add(tunables, &"shot.floor_midrange", &"probability", floor_midrange, 0.0, 0.20)
	_add(tunables, &"shot.ceiling_midrange", &"probability", ceiling_midrange, 0.40, 1.0)
	_add(tunables, &"shot.floor_standard_three", &"probability", floor_standard_three, 0.0, 0.20)
	_add(tunables, &"shot.ceiling_standard_three", &"probability", ceiling_standard_three, 0.35, 1.0)
	_add(tunables, &"shot.floor_deep_three", &"probability", floor_deep_three, 0.0, 0.20)
	_add(tunables, &"shot.ceiling_deep_three", &"probability", ceiling_deep_three, 0.25, 1.0)
	_add(tunables, &"free_throw.floor", &"probability", floor_free_throw, 0.10, 0.60)
	_add(tunables, &"free_throw.ceiling", &"probability", ceiling_free_throw, 0.80, 1.0)
	_add(tunables, &"contest.penalty_light", &"probability", contest_penalty_light, 0.0, 0.15)
	_add(tunables, &"contest.penalty_moderate", &"probability", contest_penalty_moderate, 0.03, 0.25)
	_add(tunables, &"contest.penalty_heavy", &"probability", contest_penalty_heavy, 0.08, 0.35)
	_add(tunables, &"contest.penalty_smothered", &"probability", contest_penalty_smothered, 0.20, 0.60)
	_add(tunables, &"context.movement_penalty_max", &"probability", movement_penalty_max, 0.0, 0.20)
	_add(tunables, &"context.catch_quality_penalty_max", &"probability", catch_quality_penalty_max, 0.0, 0.20)
	_add(tunables, &"context.fatigue_shot_penalty_max", &"probability", fatigue_shot_penalty_max, 0.0, 0.20)
	_add(tunables, &"context.clock_desperation_penalty_max", &"probability", clock_desperation_penalty_max, 0.0, 0.25)
	_add(tunables, &"context.advantage_shot_bonus_max", &"probability", advantage_shot_bonus_max, 0.0, 0.25)
	_add(tunables, &"contest.base_pressure", &"pressure", contest_base_pressure, 0.10, 0.70)
	_add(tunables, &"contest.capability_span", &"pressure", contest_capability_span, 0.05, 0.90)
	_add(tunables, &"contest.advantage_relief", &"pressure", contest_advantage_relief, 0.10, 1.0)
	_add(tunables, &"contest.help_weight", &"pressure", contest_help_weight, 0.0, 1.0)
	_add(tunables, &"contact.interior_base", &"share", interior_contact_base, 0.0, 0.80)
	_add(tunables, &"contact.interior_pressure_share", &"share", interior_contact_pressure_share, 0.0, 1.0)
	_add(tunables, &"contact.perimeter_base", &"share", perimeter_contact_base, 0.0, 0.50)
	_add(tunables, &"contact.perimeter_pressure_share", &"share", perimeter_contact_pressure_share, 0.0, 1.0)
	_add(tunables, &"block.opportunity_base_share", &"share", block_opportunity_base_share, 0.0, 1.0)
	_add(tunables, &"block.opportunity_pressure_share", &"share", block_opportunity_pressure_share, 0.0, 1.5)
	_add(tunables, &"shot.catch_quality_floor", &"share", catch_quality_floor, 0.0, 1.0)
	_add(tunables, &"steal.opportunity_on_ball", &"probability", steal_opportunity_on_ball, 0.02, 0.60)
	_add(tunables, &"steal.opportunity_pass", &"probability", steal_opportunity_pass, 0.02, 0.60)
	_add(tunables, &"rebound.retreat_intent_share", &"share", crash_retreat_intent_share, 0.0, 0.80)
	_add(tunables, &"rebound.reference_share", &"share", offensive_rebound_reference_share, 0.10, 0.70)
	_add(tunables, &"rebound.spread", &"multiplier", offensive_rebound_spread, 0.10, 3.0)
	_add(tunables, &"opposed.relative_sensitivity", &"relative_share", opposed_relative_sensitivity, 0.05, 0.45)
	_add(tunables, &"opposed.turnover_base", &"probability", turnover_base, 0.01, 0.35)
	_add(tunables, &"opposed.turnover_absolute_skill_relief", &"share", turnover_absolute_skill_relief, 0.0, 0.95)
	_add(tunables, &"opposed.steal_conversion_base", &"probability", steal_conversion_base, 0.05, 0.65)
	_add(tunables, &"opposed.block_conversion_base", &"probability", block_conversion_base, 0.03, 0.55)
	_add(tunables, &"opposed.foul_conversion_base", &"probability", foul_conversion_base, 0.03, 0.58)
	_add(tunables, &"opposed.advantage_base", &"probability", advantage_base, 0.05, 0.70)
	_add(tunables, &"opposed.assist_base", &"probability", assist_base, 0.55, 0.95)
	_add(tunables, &"continuation.pass_catch_and_shoot_share", &"share",
		pass_catch_and_shoot_share, 0.0, 0.85)
	_add(tunables, &"continuation.relocation_spot_up_share", &"share",
		relocation_spot_up_share, 0.0, 0.85)
	_add(tunables, &"opposed.offensive_rebound_base", &"probability", offensive_rebound_base, 0.12, 0.48)
	_add(tunables, &"opposed.putback_base", &"probability", putback_base, 0.08, 0.48)
	_add(tunables, &"weight.role_opportunity_min", &"multiplier", role_opportunity_min, 0.35, 1.0)
	_add(tunables, &"weight.role_opportunity_max", &"multiplier", role_opportunity_max, 1.0, 1.80)
	_add(tunables, &"weight.coach_instruction_min", &"multiplier", coach_instruction_min, 0.80, 1.0)
	_add(tunables, &"weight.coach_instruction_max", &"multiplier", coach_instruction_max, 1.0, 1.25)
	_add(tunables, &"weight.tactical_fit_min", &"multiplier", tactical_fit_min, 0.60, 1.0)
	_add(tunables, &"weight.tactical_fit_max", &"multiplier", tactical_fit_max, 1.0, 1.45)
	_add(tunables, &"weight.matchup_opportunity_min", &"multiplier", matchup_opportunity_min, 0.65, 1.0)
	_add(tunables, &"weight.matchup_opportunity_max", &"multiplier", matchup_opportunity_max, 1.0, 1.50)
	_add(tunables, &"weight.score_clock_min", &"multiplier", score_clock_min, 0.40, 1.0)
	_add(tunables, &"weight.score_clock_max", &"multiplier", score_clock_max, 1.0, 2.00)
	_add(tunables, &"weight.capability_confidence_min", &"multiplier", capability_confidence_min, 0.70, 1.0)
	_add(tunables, &"weight.capability_confidence_max", &"multiplier", capability_confidence_max, 1.0, 1.30)
	_add(tunables, &"weight.fatigue_availability_min", &"multiplier", fatigue_availability_min, 0.55, 1.0)
	_add(tunables, &"weight.candidate_weight_min", &"multiplier", candidate_weight_min, 0.05, 0.50)
	_add(tunables, &"weight.candidate_weight_max", &"multiplier", candidate_weight_max, 1.50, 5.0)
	_add(tunables, &"continuation.drive_finish_share", &"probability", drive_finish_share, 0.10, 0.95)
	_add(tunables, &"continuation.post_finish_share", &"probability", post_finish_share, 0.10, 0.98)
	_add(tunables, &"continuation.pick_finish_share", &"probability", pick_finish_share, 0.05, 0.90)
	_add(tunables, &"continuation.cut_finish_share", &"probability", cut_finish_share, 0.20, 0.99)
	_add(tunables, &"continuation.drive_kick_out_share", &"probability", drive_kick_out_share, 0.0, 0.95)
	_add(tunables, &"continuation.pick_kick_out_share", &"probability", pick_kick_out_share, 0.0, 0.95)
	_add(tunables, &"continuation.post_kick_out_share", &"probability", post_kick_out_share, 0.0, 0.95)
	_add(tunables, &"continuation.roll_finish_share", &"probability", roll_finish_share, 0.0, 0.90)
	_add(tunables, &"continuation.kick_out_spacer_threshold", &"capability", kick_out_spacer_threshold, 0.0, 1.0)
	_add(tunables, &"validity.deep_three_capability_threshold", &"capability", deep_three_capability_threshold, 0.0, 1.0)
	_add(tunables, &"validity.post_action_capability_threshold", &"capability", post_action_capability_threshold, 0.0, 1.0)
	_add(tunables, &"validity.pull_up_three_capability_threshold", &"capability", pull_up_three_capability_threshold, 0.0, 1.0)
	_add(tunables, &"validity.reset_block_clock_ms", &"milliseconds", float(reset_block_clock_ms), 0.0, 15000.0)
	_add(tunables, &"validity.desperation_clock_ms", &"milliseconds", float(desperation_clock_ms), 0.0, 10000.0)
	_add(tunables, &"validity.spacer_capability_threshold", &"capability", spacer_capability_threshold, 0.0, 1.0)
	_add(tunables, &"action.base_weight_pass_swing", &"weight", base_weight_pass_swing, 0.10, 3.0)
	_add(tunables, &"action.base_weight_drive", &"weight", base_weight_drive, 0.05, 3.0)
	_add(tunables, &"action.base_weight_pull_up", &"weight", base_weight_pull_up, 0.05, 3.0)
	_add(tunables, &"action.base_weight_post_action", &"weight", base_weight_post_action, 0.01, 3.0)
	_add(tunables, &"action.base_weight_pick_action", &"weight", base_weight_pick_action, 0.01, 3.0)
	_add(tunables, &"action.base_weight_handoff", &"weight", base_weight_handoff, 0.01, 3.0)
	_add(tunables, &"action.base_weight_off_ball_cut", &"weight", base_weight_off_ball_cut, 0.01, 3.0)
	_add(tunables, &"action.base_weight_relocation", &"weight", base_weight_relocation, 0.01, 3.0)
	_add(tunables, &"action.base_weight_screen", &"weight", base_weight_screen, 0.01, 3.0)
	_add(tunables, &"action.base_weight_reset", &"weight", base_weight_reset, 0.01, 3.0)
	_add(tunables, &"action.base_weight_transition_attack", &"weight", base_weight_transition_attack, 0.05, 3.0)
	_add(tunables, &"action.base_weight_putback", &"weight", base_weight_putback, 0.05, 3.0)
	_add(tunables, &"priority.player_share", &"share", player_preference_share, 0.60, 0.90)
	_add(tunables, &"priority.coach_share", &"share", coach_preference_share, 0.10, 0.40)
	_add(tunables, &"usage.elasticity", &"exponent", usage_elasticity, 0.10, 1.0)
	_add(tunables, &"usage.damping_min", &"multiplier", usage_damping_min, 0.30, 1.0)
	_add(tunables, &"usage.damping_max", &"multiplier", usage_damping_max, 1.0, 2.50)
	_add(tunables, &"fatigue.base_per_active_minute", &"fatigue_points", base_fatigue_per_active_minute, 0.50, 2.50)
	_add(tunables, &"fatigue.stamina_relief", &"share", stamina_fatigue_relief, 0.10, 0.70)
	_add(tunables, &"fatigue.action_load_min", &"fatigue_points", action_load_min, 0.05, 0.50)
	_add(tunables, &"fatigue.action_load_max", &"fatigue_points", action_load_max, 0.30, 1.50)
	_add(tunables, &"fatigue.bench_recovery_per_minute", &"fatigue_points", bench_recovery_per_minute, 0.50, 4.0)
	_add(tunables, &"body.rim_height_inches", &"inches", rim_height_inches, 100.0, 130.0)
	_add(tunables, &"body.dunk_clearance_inches", &"inches", dunk_clearance_inches, 0.0, 12.0)
	_add(tunables, &"body.vertical_min_inches", &"inches", vertical_min_inches, 8.0, 30.0)
	_add(tunables, &"body.vertical_max_inches", &"inches", vertical_max_inches, 30.0, 55.0)
	_add(tunables, &"body.reach_scale_inches", &"inches", reach_scale_inches, 4.0, 30.0)
	_add(tunables, &"body.reach_effect_max", &"capability", reach_effect_max, 0.0, 0.30)
	_add(tunables, &"body.weight_scale_pounds", &"pounds", weight_scale_pounds, 20.0, 150.0)
	_add(tunables, &"body.height_scale_inches", &"inches", height_scale_inches, 4.0, 24.0)
	_add(tunables, &"body.effect_max", &"capability", body_effect_max, 0.0, 0.30)
	_add(tunables, &"body.rebound_reach_min_inches", &"inches", rebound_reach_min_inches, 80.0, 120.0)
	_add(tunables, &"body.rebound_reach_max_inches", &"inches", rebound_reach_max_inches, 120.0, 180.0)
	_add(tunables, &"health.injury_capability_share", &"share", injury_capability_share, 0.0, 0.80)
	_add(tunables, &"rotation.minute_share_star", &"share", minute_share_star, 0.40, 0.95)
	_add(tunables, &"rotation.minute_share_starter", &"share", minute_share_starter, 0.35, 0.90)
	_add(tunables, &"rotation.minute_share_sixth_player", &"share", minute_share_sixth_player, 0.25, 0.80)
	_add(tunables, &"rotation.minute_share_rotation", &"share", minute_share_rotation, 0.15, 0.70)
	_add(tunables, &"rotation.minute_share_bench", &"share", minute_share_bench, 0.05, 0.55)
	_add(tunables, &"rotation.minute_share_reserve", &"share", minute_share_reserve, 0.0, 0.40)
	_add(tunables, &"rotation.minute_share_developmental", &"share", minute_share_developmental, 0.0, 0.30)
	_add(tunables, &"rotation.substitution_stint_seconds", &"seconds", float(substitution_stint_seconds), 60.0, 900.0)
	_add(tunables, &"rotation.substitution_rest_seconds", &"seconds", float(substitution_rest_seconds), 30.0, 600.0)
	_add(tunables, &"rotation.fatigue_substitution_threshold", &"fatigue_points", fatigue_substitution_threshold, 30.0, 95.0)
	_add(tunables, &"rotation.foul_trouble_margin", &"fouls", float(foul_trouble_margin), 0.0, 3.0)
	_add(tunables, &"rotation.settled_minimum_margin", &"points", float(settled_minimum_margin), 8.0, 40.0)
	_add(tunables, &"rotation.settled_swing_points_per_pair", &"points", settled_swing_points_per_pair, 1.0, 3.0)
	_add(tunables, &"rotation.settled_leading_safety", &"standard_deviations", settled_leading_safety, 1.5, 6.0)
	_add(tunables, &"rotation.settled_trailing_safety", &"standard_deviations", settled_trailing_safety, 2.0, 10.0)
	_add(tunables, &"rotation.settled_release_share", &"share", settled_release_share, 0.50, 1.0)
	_add(tunables, &"rotation.settled_minimum_pairs_left", &"possession_pairs", settled_minimum_pairs_left, 0.0, 6.0)
	_add(tunables, &"time.inbound_seconds_min", &"seconds", float(inbound_seconds_min), 1.0, 8.0)
	_add(tunables, &"time.inbound_seconds_max", &"seconds", float(inbound_seconds_max), 1.0, 10.0)
	_add(tunables, &"time.advance_seconds_min", &"seconds", float(advance_seconds_min), 1.0, 10.0)
	_add(tunables, &"time.advance_seconds_max", &"seconds", float(advance_seconds_max), 1.0, 12.0)
	_add(tunables, &"time.half_court_entry_seconds_min", &"seconds", float(half_court_entry_seconds_min), 1.0, 8.0)
	_add(tunables, &"time.half_court_entry_seconds_max", &"seconds", float(half_court_entry_seconds_max), 1.0, 10.0)
	_add(tunables, &"time.action_seconds_min", &"seconds", float(action_seconds_min), 1.0, 6.0)
	_add(tunables, &"time.action_seconds_max", &"seconds", float(action_seconds_max), 1.0, 10.0)
	_add(tunables, &"time.reset_seconds_min", &"seconds", float(reset_seconds_min), 1.0, 10.0)
	_add(tunables, &"time.reset_seconds_max", &"seconds", float(reset_seconds_max), 1.0, 14.0)
	_add(tunables, &"time.post_action_seconds_min", &"seconds", float(post_action_seconds_min), 1.0, 10.0)
	_add(tunables, &"time.post_action_seconds_max", &"seconds", float(post_action_seconds_max), 1.0, 14.0)
	_add(tunables, &"time.transition_seconds_min", &"seconds", float(transition_seconds_min), 1.0, 8.0)
	_add(tunables, &"time.transition_seconds_max", &"seconds", float(transition_seconds_max), 1.0, 10.0)
	_add(tunables, &"time.rebound_seconds_min", &"seconds", float(rebound_seconds_min), 0.0, 5.0)
	_add(tunables, &"time.rebound_seconds_max", &"seconds", float(rebound_seconds_max), 1.0, 6.0)
	_add(tunables, &"time.free_throw_event_seconds", &"seconds", float(free_throw_event_seconds), 0.0, 10.0)
	_add(tunables, &"time.dead_ball_event_seconds", &"seconds", float(dead_ball_event_seconds), 0.0, 8.0)
	_add(tunables, &"transition.share_base", &"probability", transition_share_base, 0.02, 0.60)
	_add(tunables, &"transition.share_after_turnover", &"probability", transition_share_after_turnover, 0.05, 0.80)
	_add(tunables, &"rebound.crash_share_base", &"probability", crash_share_base, 0.05, 0.80)
	_add(tunables, &"chemistry.pass_bonus_max", &"probability", chemistry_pass_bonus_max, 0.0, 0.10)
	_add(tunables, &"chemistry.help_bonus_max", &"probability", chemistry_help_bonus_max, 0.0, 0.10)
	_add(tunables, &"home.officiating_modifier", &"probability",
		home_officiating_modifier, 0.0, HomeEnvironmentContext.MAX_SINGLE_MODIFIER)
	_add(tunables, &"home.communication_modifier", &"probability",
		home_communication_modifier, 0.0, HomeEnvironmentContext.MAX_SINGLE_MODIFIER)
	_add(tunables, &"home.composure_modifier", &"probability",
		home_composure_modifier, 0.0, HomeEnvironmentContext.MAX_SINGLE_MODIFIER)
	_add(tunables, &"management.swing_points", &"points", management_swing_points, 1.0, 6.0)
	_add(tunables, &"management.pressure_floor", &"share", management_pressure_floor, 0.0, 0.60)
	_add(tunables, &"management.protect_pace_gain", &"share", protect_pace_gain, 0.0, 0.40)
	_add(tunables, &"management.chase_pace_relief", &"share", chase_pace_relief, 0.0, 0.30)
	_add(tunables, &"management.protect_reset_gain", &"share", protect_reset_gain, 0.0, 0.60)
	_add(tunables, &"management.protect_three_relief", &"share", protect_three_relief, 0.0, 0.50)
	_add(tunables, &"management.chase_three_gain", &"share", chase_three_gain, 0.0, 0.60)
	_add(tunables, &"management.protect_crash_relief", &"share", protect_crash_relief, 0.0, 0.60)
	_add(tunables, &"management.chase_crash_gain", &"share", chase_crash_gain, 0.0, 0.60)
	_add(tunables, &"management.endgame_possession_ms", &"milliseconds", float(endgame_possession_ms), 8000.0, 60000.0)
	_add(tunables, &"management.endgame_tie_gain", &"share", endgame_tie_gain, 0.0, 0.80)
	_add(tunables, &"management.endgame_tie_relief", &"share", endgame_tie_relief, 0.0, 0.70)
	_add(tunables, &"timeout.run_points", &"points", float(timeout_run_points), 4.0, 15.0)
	_add(tunables, &"timeout.recovery_points", &"fatigue_points", timeout_recovery_points, 0.0, 20.0)
	_add(tunables, &"timeout.run_reserve_ms", &"milliseconds", float(timeout_run_reserve_ms), 0.0, 180000.0)
	_add(tunables, &"late_game.intentional_foul_max_margin", &"points", float(intentional_foul_max_margin), 1.0, 15.0)
	_add(tunables, &"late_game.intentional_foul_clock_ms", &"milliseconds", float(intentional_foul_clock_ms), 5000.0, 120000.0)
	_add(tunables, &"late_game.intentional_foul_share", &"probability", intentional_foul_share, 0.0, 1.0)
	_add(tunables, &"stakes.rotation_tightness_step", &"share", stakes_rotation_tightness_step, 0.0, 0.35)
	_add(tunables, &"stakes.timeout_reserve_step", &"share", stakes_timeout_reserve_step, 0.0, 0.60)
	_add(tunables, &"stakes.settled_patience_step", &"share", stakes_settled_patience_step, 0.0, 0.30)
	_add(tunables, &"stakes.endgame_window_step", &"share", stakes_endgame_window_step, 0.0, 1.0)
	_add(tunables, &"stakes.endgame_conviction_step", &"share", stakes_endgame_conviction_step, 0.0, 0.50)
	_add(tunables, &"statistics.possession_estimate_free_throw_weight", &"weight", possession_estimate_free_throw_weight, 0.30, 0.60)
	_add(tunables, &"safety.max_actions_per_possession", &"actions", float(max_actions_per_possession), 4.0, 64.0)
	return tunables


## Gate B0 for the simulation half of the balance bundle: every tunable sits
## inside its declared safe range, every floor is under its ceiling, and every
## baseline table is monotonically non-decreasing in the rating it is keyed by.
func validate() -> PackedStringArray:
	var failures: PackedStringArray = []
	var seen: Dictionary = {}
	for tunable in describe_tunables():
		if seen.has(tunable.tunable_name):
			failures.append("duplicate tunable name: %s" % tunable.tunable_name)
		seen[tunable.tunable_name] = true
		if not tunable.is_inside_safe_range():
			failures.append("outside safe range: %s" % tunable.describe())
	if version.is_empty() or profile_id.is_empty():
		failures.append("the simulation balance profile must carry an identity and version")
	_require_ordered(failures, &"close_non_dunk", floor_close_non_dunk, ceiling_close_non_dunk)
	_require_ordered(failures, &"dunk", floor_dunk, ceiling_dunk)
	_require_ordered(failures, &"midrange", floor_midrange, ceiling_midrange)
	_require_ordered(failures, &"standard_three", floor_standard_three, ceiling_standard_three)
	_require_ordered(failures, &"deep_three", floor_deep_three, ceiling_deep_three)
	_require_ordered(failures, &"free_throw", floor_free_throw, ceiling_free_throw)
	_require_ordered(failures, &"turnover", turnover_floor, turnover_ceiling)
	_require_ordered(failures, &"steal", steal_conversion_floor, steal_conversion_ceiling)
	_require_ordered(failures, &"block", block_conversion_floor, block_conversion_ceiling)
	_require_ordered(failures, &"foul", foul_conversion_floor, foul_conversion_ceiling)
	_require_ordered(failures, &"advantage", advantage_floor, advantage_ceiling)
	_require_ordered(failures, &"assist", assist_floor, assist_ceiling)
	_require_ordered(failures, &"offensive_rebound", offensive_rebound_floor, offensive_rebound_ceiling)
	_require_ordered(failures, &"putback", putback_floor, putback_ceiling)
	_require_monotonic(failures, &"baseline_close_non_dunk", baseline_close_non_dunk)
	_require_monotonic(failures, &"baseline_dunk", baseline_dunk)
	_require_monotonic(failures, &"baseline_midrange", baseline_midrange)
	_require_monotonic(failures, &"baseline_three", baseline_three)
	_require_monotonic(failures, &"baseline_free_throw", baseline_free_throw)
	if absf(player_preference_share + coach_preference_share - 1.0) > 0.000001:
		failures.append("the Â§12.3 player and coach shares must sum to 1.0")
	failures.append_array(_role_opportunity_table.validate())
	return failures


func _require_ordered(
	failures: PackedStringArray,
	family: StringName,
	low: float,
	high: float,
) -> void:
	if low > high:
		failures.append("%s floor exceeds its ceiling" % family)


func _require_monotonic(
	failures: PackedStringArray,
	table_name: StringName,
	table: PackedFloat64Array,
) -> void:
	if table.size() != SHOT_BASELINE_ANCHOR_RATINGS.size():
		failures.append("%s must supply one value per Â§13.1 anchor rating" % table_name)
		return
	for index in range(1, table.size()):
		if table[index] < table[index - 1]:
			failures.append("%s is not monotonic in the rating it is keyed by" % table_name)
			return


func _add(
	tunables: Array[BalanceTunable],
	tunable_name: StringName,
	unit: StringName,
	value: float,
	safe_minimum: float,
	safe_maximum: float,
) -> void:
	tunables.append(BalanceTunable.new(tunable_name, unit, value, safe_minimum, safe_maximum))


## Linear interpolation across the Â§13.1 anchor ratings, extended linearly
## below the lowest anchor so a 25-rated shooter is still worse than a 40-rated
## one. The Â§13.2 floors clamp the result afterwards.
func _interpolate(table: PackedFloat64Array, rating: float) -> float:
	var anchors: PackedFloat64Array = SHOT_BASELINE_ANCHOR_RATINGS
	if rating <= anchors[0]:
		var low_span: float = anchors[1] - anchors[0]
		var low_slope: float = (table[1] - table[0]) / low_span
		return table[0] + (rating - anchors[0]) * low_slope
	for index in range(1, anchors.size()):
		if rating <= anchors[index]:
			var span: float = anchors[index] - anchors[index - 1]
			var share: float = (rating - anchors[index - 1]) / span
			return lerpf(table[index - 1], table[index], share)
	return table[table.size() - 1]
