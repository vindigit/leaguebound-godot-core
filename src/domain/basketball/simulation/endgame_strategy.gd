class_name EndgameStrategy
extends RefCounted

## The end-of-regulation possession and coaching decisions `GameManagement`
## does not yet cover (`SIMULATION_SPEC.md` §10.2, §10.3, §13.1, §13.2).
##
## `PROJECT_STATUS.md` §5.13 names four legitimate, specified coaching
## decisions that were still missing after `GameManagement` and `TimeoutState`
## shipped: two-for-one possession management, fouling while leading by three,
## timeout-to-advance, and a designed final-possession play. The 2026-09-01
## owner ruling treats college and top domestic's measured overtime rates
## (1.00% and 1.75%) as evidence of that missing repertoire rather than of an
## unreachable §14.2 band, and directs that these four be built. This class is
## the smallest extension that builds them, reusing every existing seam.
##
## That ruling is about how to *read a measurement*. It decides nothing about
## any competition's rules and grants no competition a rule it does not have
## (see `CompetitionRuleProfile.timeout_advance_permitted`), and it is not
## satisfied by a decision that fires more often — only by one that fires when
## a coach would actually make it. Every gate below is therefore written from
## the basketball reason the decision exists, and refuses whenever that reason
## does not hold, however much doing so reduces how often it fires:
##
## - Two-for-one, hold-for-the-final-shot, quick-two-vs-tying-three, and the
##   designed final possession all fold into the same §10.3 score-and-clock
##   factor `GameManagement.action_multiplier_at` already owns a share of —
##   they change which legal action or actor is preferred, never whether a
##   shot goes in.
## - The leading-by-three foul rides the same whistle the trailing team's
##   intentional foul already uses (`FoulResolver`, `FoulType`), distinguished
##   by its own `FoulType.Value.LEADING_PROTECT` so the ledger never confuses
##   the two decisions.
## - Timeout-to-advance rides the existing `TIMEOUT` event with a new cause,
##   gated first by `CompetitionRuleProfile.timeout_advance_permitted` because
##   the frontcourt inbound is a genuine rule difference between competitions
##   (`SIMULATION_SPEC.md` §4 is what fixes that boundary), and then by the
##   coaching conditions under which spending an allowance on it is actually
##   the better of the two things a coach can do with it.
## - The intentional final free-throw miss is a possession-engine decision
##   that skips `FreeThrowResolver` entirely for the one attempt it applies
##   to, so the make-probability table is never consulted for it.
##
## None of the above reads a rating differential, a strength index, an
## intended winner, or a target margin. `designated_closer_id` reads one
## capability — the same way every other resolver reads one — to decide which
## of the offence's own players a designed play is drawn up for; it is not a
## comparison against the defence and it does not touch a probability.


## Ledger tags. Every one rides an existing event's `detail_id`/`action_id`
## slot rather than a new `MatchDomainEvent` type — this is a *cause*, the
## same role `detail_id` already plays for a foul type or a rebound side.
const TAG_NONE: StringName = &""
const TAG_TWO_FOR_ONE: StringName = &"endgame_two_for_one"
const TAG_HOLD: StringName = &"endgame_hold"
const TAG_QUICK_TWO: StringName = &"endgame_quick_two"
const TAG_DESIGNED_PLAY: StringName = &"endgame_designed_play"


static func _in_final_period(context: PossessionContext) -> bool:
	return context.state.period >= context.input.rule_profile.regulation_periods


static func _remaining_ms(context: PossessionContext) -> int:
	return GameManagement.remaining_ms(context.state, context.input.rule_profile)


## The most points a single possession can be worth to a team planning around
## it: a three. A four-point play exists, but no coach plans a comeback on one,
## and planning on one would make every window below wider than the basketball
## reason it is drawn from.
const MAXIMUM_PLANNED_POSSESSION_SWING: int = 3


## The largest deficit still worth playing a possession *for*, at the time
## left: the possession in hand, plus one more for every further
## `endgame_possession_ms` (one possession and the stop that would have to
## follow it) of regulation on the clock, each worth at most a three.
##
## This is what separates "trailing and it can still be fixed" from "trailing
## and the game is over": down four with eight seconds and the ball, the
## arithmetic does not close whatever the offence runs, and the decisions that
## consult this refuse rather than dressing a lost possession up as a plan.
static func recoverable_deficit(
	remaining_ms: int,
	balance: SimulationBalanceProfile,
) -> int:
	if remaining_ms <= 0:
		return 0
	var possession_ms: int = maxi(balance.endgame_possession_ms, 1)
	var possessions: int = 1 + remaining_ms / possession_ms
	return possessions * MAXIMUM_PLANNED_POSSESSION_SWING


## Trailing or tied, with enough regulation left for two separate possessions
## if the offence hurries but only one if it plays a possession of ordinary
## length. Leading is excluded: a team protecting a lead wants the opposite of
## an extra possession changing hands.
static func two_for_one_active(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> bool:
	if not _in_final_period(context):
		return false
	if context.offense_margin() > 0:
		return false
	var remaining: int = _remaining_ms(context)
	var shot_clock_ms: int = context.input.rule_profile.shot_clock_seconds * 1000
	return (
		remaining > shot_clock_ms
		and remaining <= shot_clock_ms * 2 + maxi(balance.two_for_one_window_ms, 0))


## Holding the ball for the last shot of the game.
##
## A **leading** team holds on the game clock alone: every second it burns is a
## second the opponent does not get, and it is content to shoot late or not at
## all.
##
## A **tied** team is the case this originally refused, and refusing it was
## wrong. Holding for the last shot of a tied game is the most ordinary
## end-of-regulation decision in basketball — shoot at the buzzer, and the
## opponent never touches the ball again. What makes it *valid* is the pair of
## clocks, which is the condition that was missing rather than the whole
## decision: the offence can only hold to the horn if the shot clock will not
## expire first. Once regulation left is inside the shot clock on the board,
## the two run out together, the possession is the game's last whoever wins it,
## and holding costs the offence nothing. Outside that, a tied team holding
## would hand the ball back on a shot-clock violation, so it wants the extra
## possession `two_for_one_active` describes instead — which is exactly the
## complementary window, so the two never both apply.
##
## Trailing is still excluded at every clock: a team that must score cannot
## also be running time off.
static func hold_for_final_shot_active(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> bool:
	if not _in_final_period(context):
		return false
	var margin: int = context.offense_margin()
	if margin < 0:
		return false
	var remaining: int = _remaining_ms(context)
	if remaining > balance.hold_for_final_shot_window_ms:
		return false
	if margin == 0:
		return remaining <= context.state.shot_clock_ms
	return true


## Down exactly three, outside the plain tie-seeking window
## `GameManagement.endgame_multiplier` already owns but still with regulation
## time for a second possession, and a timeout in reserve to stop the clock
## after a made two before fouling. The timeout is the ingredient that makes a
## quick-two-then-foul plan realistic this far out; without one, a made two
## still leaves the clock running against the team that just used it.
static func quick_two_preferred(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> bool:
	if not _in_final_period(context):
		return false
	if -context.offense_margin() != GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT:
		return false
	var remaining: int = _remaining_ms(context)
	if remaining <= balance.endgame_possession_ms or remaining > balance.quick_two_timeout_window_ms:
		return false
	return context.offense_state().timeouts_remaining > 0


## The single truly final possession of regulation, for a team a designed play
## can still win or save the game for. Narrower than every window above on
## purpose — this is the possession itself.
##
## The margin gate is the correction. A designed final possession is a play
## drawn up to get one specific player one specific look because the result
## turns on it. That is true of a tied game and of a deficit the possession can
## still close. It is not true of a team with a safe lead, which wants the
## opposite thing entirely: run the clock out, take a shot if one is there and
## nothing if it is not, and above all do not hurry into an early attempt that
## hands the ball back. Boosting a leading team's closer was pushing that team
## toward a shot it did not want to take, and it was doing so most strongly in
## exactly the games it had already won.
##
## `recoverable_deficit` draws the trailing boundary from the clock rather than
## from a fixed number, so a team down three with eight seconds gets its play
## and a team down nine with the same eight seconds does not.
static func designed_play_active(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> bool:
	if not _in_final_period(context):
		return false
	var margin: int = context.offense_margin()
	if margin > 0:
		return false
	var remaining: int = _remaining_ms(context)
	if remaining > balance.designed_play_window_ms:
		return false
	return -margin <= recoverable_deficit(remaining, balance)


## The offence's own best shot-creator on the floor, read the same way every
## other resolver reads a capability. Ties break on player id so the choice is
## a deterministic function of the roster rather than of dictionary order.
static func designated_closer_id(
	context: PossessionContext,
	capability: CapabilityCalculator,
) -> StringName:
	var best_id: StringName = &""
	var best_value: float = -1.0
	for player_id in context.offense_on_court():
		var value: float = capability.capability_of(
			CapabilityKey.Value.SHOT_SELECTION,
			context.offense_profile(player_id),
			context.offense_runtime(player_id))
		if value > best_value or (value == best_value and String(player_id) < String(best_id)):
			best_value = value
			best_id = player_id
	return best_id


## Which decision is in force right now, for ledger tagging. Priority is for
## the label only — the numeric effect below applies every condition that
## holds, independently of which one is reported here.
static func active_tag(context: PossessionContext, balance: SimulationBalanceProfile) -> StringName:
	if designed_play_active(context, balance):
		return TAG_DESIGNED_PLAY
	if quick_two_preferred(context, balance):
		return TAG_QUICK_TWO
	if hold_for_final_shot_active(context, balance):
		return TAG_HOLD
	if two_for_one_active(context, balance):
		return TAG_TWO_FOR_ONE
	return TAG_NONE


## One multiplier on a candidate's §10.3 score-and-clock factor, combining
## every decision above that currently applies. The caller folds this beside
## `GameManagement.action_multiplier_at` inside the same §12.2-guarded factor:
## this changes which legal action or actor is preferred, never whether the
## selected one succeeds.
static func action_multiplier(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
	action_family: int,
	zone: int,
	actor_id: StringName,
	designated_closer: StringName,
) -> float:
	var value: float = 1.0
	var three: bool = zone >= 0 and ShotZone.is_three(zone)

	if two_for_one_active(context, balance):
		var urgency: float = clampf(balance.two_for_one_urgency, 0.0, 0.60)
		if action_family == ActionFamily.Value.RESET:
			value *= 1.0 - urgency
		elif ActionFamily.is_direct_shot(action_family):
			value *= 1.0 + urgency

	if action_family == ActionFamily.Value.RESET and not context.is_late_clock() \
			and hold_for_final_shot_active(context, balance):
		value *= 1.0 + clampf(balance.hold_reset_gain, 0.0, 0.60)

	if zone >= 0 and quick_two_preferred(context, balance):
		var preference: float = clampf(balance.quick_two_preference, 0.0, 0.60)
		value *= (1.0 - preference) if three else (1.0 + preference)

	if (
		not designated_closer.is_empty()
		and actor_id == designated_closer
		and designed_play_active(context, balance)
	):
		value *= 1.0 + clampf(balance.designed_play_actor_gain, 0.0, 0.60)

	return value


## The deficit, immediately before the final attempt of a trip, at which
## missing it on purpose is better than making it.
##
## Down exactly two: the attempt is worth one point, so a make leaves the
## offence down one with the ball dead and the opponent inbounding — the game
## is over and lost. A miss is the only thing left that can still tie or win
## it, because a miss is *live*: the offence can rebound it and shoot a two to
## tie or a three to win. Down one, a make ties and there is nothing to miss
## for. Down three or more, a make and a miss are both insufficient on their
## own and the offence wants the point. Two, and only two, is the state where
## the free throw cannot tie and the rebound can.
const INTENTIONAL_MISS_DEFICIT: int = 2


## The least regulation time in which a deliberately missed free throw can
## still become a shot, derived from the clock model that will actually charge
## for it rather than picked: `rebound_ms` draws up to `rebound_seconds_max`
## for the board, and the putback that follows draws at least
## `action_seconds_min`. Below their sum the offence cannot get the attempt the
## miss exists to create.
static func minimum_miss_window_ms(balance: SimulationBalanceProfile) -> int:
	return (maxi(balance.rebound_seconds_max, 0) + maxi(balance.action_seconds_min, 0)) * 1000


## The intentional final-free-throw miss: mathematically necessary rather than
## optional, so this is a plain condition rather than a probability roll.
##
## **This is a trailing team's decision, and previously it was a leading
## team's.** The rule as first written fired for a shooting team *ahead* by two
## or three, which inverted the whole tactic: a leading team at the line in the
## last seconds wants to make the free throw — every point it adds is one more
## the opponent has to answer — and missing on purpose hands a live ball to a
## team that needs one. The version below fires only for the offence trailing
## by exactly two before the attempt in hand, which is the single state where
## the arithmetic says the point is worthless and the rebound is not (see
## `INTENTIONAL_MISS_DEFICIT`). A leading team never reaches it at any margin,
## clock, or attempt index.
##
## "Before its final attempt" is the *live* margin, and `context.offense_margin()`
## is exactly that: `PossessionEngine._emit` reduces every event into the
## possession's own snapshot as it is written, so a free throw already made in
## this trip is already on the scoreboard the rule reads. The canonical case
## depends on it: down three, awarded two, first one made — the margin is -2
## when the second attempt comes up, which is the state this rule is for.
##
## Three further conditions are load-bearing rather than decorative:
##
## - `final_free_throw_reboundable`. The whole plan is the rebound. Under a
##   rule profile where a missed last free throw is not live, missing is a
##   plain surrender of the ball, strictly worse than the point, and the rule
##   must not fire.
## - The emergency clock window. With time for another possession, a made point
##   plus a stop is the better plan and the offence takes the point.
## - **Enough clock left for the plan to happen at all** (`minimum_miss_window_ms`).
##   This is the floor the first version of the rule had no equivalent of, and
##   without it the decision fired in states where it could not possibly work:
##   a free-throw trip charges `free_throw_event_seconds` of event time per
##   attempt, so a trip that begins inside a 3.5-second window routinely
##   arrives at its last attempt with a millisecond on the clock. Missing there
##   buys a rebound the horn will interrupt, while making it is a free point.
##   "A miss and an offensive rebound *can* tie it" has to be true of the clock
##   as well as of the arithmetic.
##
## The caller never consults `FreeThrowResolver` for this attempt — the shot is
## not attempted for real, so there is no probability to touch — and the miss
## it produces goes into the ordinary live-ball rebound the rules already
## define for a missed final attempt. It is a choice not to shoot, never an
## engineered failure of a shot, and never an award of the ball to anybody.
static func should_intentionally_miss_final_free_throw(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
	attempt_index: int,
	attempts: int,
) -> bool:
	if attempt_index != attempts - 1:
		return false
	if not _in_final_period(context):
		return false
	if not context.input.rule_profile.final_free_throw_reboundable:
		return false
	if context.state.clock_ms > balance.intentional_miss_clock_ms:
		return false
	if context.state.clock_ms < minimum_miss_window_ms(balance):
		return false
	return context.offense_margin() == -INTENTIONAL_MISS_DEFICIT


## Whether a coach should spend one of his remaining allowances to gain the
## ball in the frontcourt for the possession about to start.
##
## **This is a decision, and previously it was an expenditure.** The rule as
## first written asked only whether the competition permits the advance, the
## team is not ahead, it has any timeout at all, and there is under two minutes
## left. Every one of those holds on *every* possession of a close last two
## minutes, so the answer was yes every time and the team simply spent its
## allowance down to zero — which is not what "a coach may advance the ball" is
## a model of, and left him with nothing for the possession that needed one. It
## fired 491 times per 200 college games and 836 per 200 top domestic; a coach
## calls it once or twice a game if he calls it at all.
##
## Five conditions now stand between the rule and the whistle, and each is a
## reason a coach declines rather than a tuning knob:
##
## 1. **A dead-ball origin.** The advance is a rule about where a team inbounds
##    the ball. There is nothing to inbound after a live transfer — the offence
##    already has it and is running — so a timeout there does not advance
##    anything; it stops a break the team is already winning. `live_start` is
##    the same flag `MatchSession` already carries for exactly this
##    distinction.
## 2. **An actionable margin.** Trailing or tied, and by a deficit the time
##    left can still close (`recoverable_deficit`). Down fifteen with a minute
##    to go, the four seconds the advance saves change nothing.
## 3. **A meaningful clock benefit.** The advance is worth an allowance only
##    when the *game* clock is what limits the possession rather than the shot
##    clock — i.e. inside `timeout_advance_window_ms`, which is drawn as one
##    shot clock plus one backcourt walk rather than picked. Outside it the
##    offence can walk the ball up and still run a full possession, and has
##    bought nothing.
## 4. **A reserve.** A coach keeps `timeout_advance_reserve_timeouts` in hand
##    after making the call. Spending the last one to save four seconds costs
##    him the ability to stop the clock, advance again, or set up the shot on
##    the possession that follows.
## 5. **Not twice for the same possession.** Enforced by the caller, which
##    passes `already_advanced_this_possession`; one possession can be advanced
##    once, and a second timeout would buy a walk that has already been skipped.
static func timeout_advance_eligible(
	state: MatchSnapshot,
	rules: CompetitionRuleProfile,
	balance: SimulationBalanceProfile,
	team_id: StringName,
	live_start: bool,
	already_advanced_this_possession: bool,
) -> bool:
	if not rules.timeout_advance_permitted:
		return false
	if live_start or already_advanced_this_possession:
		return false
	var margin: int = state.margin_for(team_id)
	if margin > 0:
		return false
	var remaining: int = GameManagement.remaining_ms(state, rules)
	if remaining <= 0 or remaining > balance.timeout_advance_window_ms:
		return false
	if -margin > recoverable_deficit(remaining, balance):
		return false
	return (
		state.state_for(team_id).timeouts_remaining
		> maxi(balance.timeout_advance_reserve_timeouts, 0))
