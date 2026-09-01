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
## the smallest extension that builds them, reusing every existing seam:
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
##   gated by `CompetitionRuleProfile.timeout_advance_permitted` because it is
##   a genuine rule difference between competitions, not a coaching tendency —
##   `SIMULATION_SPEC.md` §4 is what fixes that boundary.
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


## Leading, with little enough regulation left that the game's last possession
## is the one in hand. Tied is deliberately excluded from holding: a tied team
## wants the extra possession two-for-one describes, not to give one away.
static func hold_for_final_shot_active(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> bool:
	if not _in_final_period(context):
		return false
	if context.offense_margin() <= 0:
		return false
	return _remaining_ms(context) <= balance.hold_for_final_shot_window_ms


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


## The single truly final possession of regulation: too little time left for
## a second one to matter to anybody, whatever the margin. Narrower than every
## window above on purpose — this is the possession itself.
static func designed_play_active(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> bool:
	if not _in_final_period(context):
		return false
	return _remaining_ms(context) <= balance.designed_play_window_ms


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


## The intentional final-free-throw miss: mathematically necessary rather than
## optional, so this is a plain condition rather than a probability roll. A
## leading team's last attempt of a free-throw trip is deliberately missed
## when a make would still leave the trailing team a single-shot answer and a
## miss the shooting team controls denies it one entirely.
##
## The caller never consults `FreeThrowResolver` for this attempt — the shot
## is not attempted for real, so there is no probability to touch.
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
	if context.state.clock_ms <= 0 or context.state.clock_ms > balance.intentional_miss_clock_ms:
		return false
	var margin: int = context.offense_margin()
	return (
		margin >= GameManagement.TIE_SEEKING_MINIMUM_DEFICIT
		and margin <= GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT)


## Whether the offence gained this possession through a timeout its rule
## profile grants ball-advancement for, so `PossessionEngine` can skip the
## backcourt-to-frontcourt walk for the one possession it applies to.
static func timeout_advance_eligible(
	state: MatchSnapshot,
	rules: CompetitionRuleProfile,
	balance: SimulationBalanceProfile,
	team_id: StringName,
) -> bool:
	if not rules.timeout_advance_permitted:
		return false
	if state.margin_for(team_id) > 0:
		return false
	if state.state_for(team_id).timeouts_remaining <= 0:
		return false
	return GameManagement.remaining_ms(state, rules) <= balance.timeout_advance_window_ms
