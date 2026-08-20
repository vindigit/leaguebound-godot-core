class_name GameManagement
extends RefCounted

## Score-and-clock coaching (`SIMULATION_SPEC.md` §10.2, §10.3, §18.2, §20.2).
##
## §10.2 lists "Clock and score" among the inputs to candidate generation and
## §10.3 gives `ScoreClockContext` its own factor in the weight product. Until
## this class existed the engine read the *shot* clock everywhere and the score
## only inside the last forty seconds of the final period, so a team twenty-five
## points ahead in the fourth quarter played exactly the same basketball as a
## team in a tie game: the measured seconds per possession, actions per
## possession, and three-point attempt share were identical to three decimal
## places across every score state. That is not a calibration gap, it is a
## missing mechanism, and it is the mechanism the §14.2 game-shape targets are
## about.
##
## Everything here is one number:
##
## ```text
## pressure = (possession_pairs_needed / possession_pairs_left - floor) / (1 - floor)
## ```
##
## `possession_pairs_needed` is the margin divided by how much a trailing team
## takes back in one pair of possessions it wins outright; `possession_pairs_left`
## is the remaining regulation time divided by the pace *this game* has actually
## played at, which is why one constant works for a thirty-two-minute school game
## and a forty-eight-minute professional one. Below the floor nothing happens at
## all, which is what keeps ordinary basketball — and therefore every §14.1
## band — untouched.
##
## **This is not rubber-banding and the difference is structural.** Both coaches
## compute the same `pressure` from the same public state. The team that is
## ahead protects the lead and the team that is behind chases it, exactly as the
## sign of their own margin says; swap the two rosters and the two behaviours
## swap with them. Nothing here reads a rating, a target margin, or an intended
## winner, and nothing here changes the probability that a shot goes in: the
## whole of the effect is how long a possession takes and which action a coach
## prefers, which §10.3 names as the two things `ScoreClockContext` is for.
##
## The bounds matter as much as the rule. Every factor is clamped to a named
## tunable with a documented safe range, and the products are then clamped again
## by the §12.2 guardrails the rest of the weight product already lives under, so
## no amount of pressure can turn a coach's preference into a certainty.


## Whether score-and-clock management applies at all, and how hard.
##
## Zero for almost the whole of an ordinary game. One when a trailing team needs
## every remaining possession.
static func pressure(context: PossessionContext) -> float:
	return pressure_for(
		context.state, context.input, context.offense.team_id, context.input.balance_profile)


## The same quantity from raw state, so a test can ask for it at a score and a
## clock without simulating a game to arrive there.
static func pressure_for(
	state: MatchSnapshot,
	input: MatchInput,
	team_id: StringName,
	balance: SimulationBalanceProfile,
) -> float:
	var margin: int = absi(state.margin_for(team_id))
	if margin <= 0:
		return 0.0
	var pairs_left: float = possession_pairs_left(state, input)
	if pairs_left <= 0.0:
		return 1.0
	var pairs_needed: float = float(margin) / maxf(balance.management_swing_points, 0.1)
	var ratio: float = pairs_needed / pairs_left
	var floor_share: float = clampf(balance.management_pressure_floor, 0.0, 0.95)
	return clampf((ratio - floor_share) / (1.0 - floor_share), 0.0, 1.0)


## Remaining regulation time divided by the pace this game has actually played
## at. Reading the realized pace rather than a constant is what makes one set of
## tunables correct for five competitions with three period lengths and two shot
## clocks between them.
static func possession_pairs_left(state: MatchSnapshot, input: MatchInput) -> float:
	var rules: CompetitionRuleProfile = input.rule_profile
	var remaining: float = float(remaining_ms(state, rules))
	if remaining <= 0.0:
		return 0.0
	var elapsed: float = float(elapsed_ms(state, rules))
	var possessions: float = float(state.possession_sequence)
	if elapsed <= 0.0 or possessions <= 0.0:
		# Before the first possession ends there is no realized pace to read, and
		# no margin either, so the value never reaches a decision.
		return remaining / float(maxi(rules.shot_clock_seconds, 1) * 2000)
	var pair_ms: float = 2.0 * elapsed / possessions
	return remaining / maxf(pair_ms, 1.0)


## Time left in regulation, or in the current overtime period once regulation
## is over. An overtime period is its own game as far as this is concerned:
## nobody manages the clock against a period that may not be played.
static func remaining_ms(state: MatchSnapshot, rules: CompetitionRuleProfile) -> int:
	return GarbageTimeRule.remaining_regulation_ms(state.period, state.clock_ms, rules)


static func elapsed_ms(state: MatchSnapshot, rules: CompetitionRuleProfile) -> int:
	var total: int = 0
	for period in range(1, state.period):
		total += rules.period_length_ms(period)
	return total + rules.period_length_ms(state.period) - state.clock_ms


## Whether the team with the ball is the one protecting a lead.
static func is_protecting(context: PossessionContext) -> bool:
	return context.offense_margin() > 0


## Multiplier on every clock draw the offence makes.
##
## A team protecting a lead uses the clock and a team chasing saves it. The two
## gains are deliberately different sizes: a possession has a physical floor —
## the ball still has to be advanced and a shot still has to be taken — so the
## chasing side can save far less time than the protecting side can spend. That
## asymmetry is the whole of the mechanism's effect on possession count, and it
## is a fact about basketball rather than a tuning convenience.
static func pace_multiplier(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> float:
	var intensity: float = pressure(context)
	if intensity <= 0.0:
		return 1.0
	if is_protecting(context):
		return 1.0 + clampf(balance.protect_pace_gain, 0.0, 0.40) * intensity
	return 1.0 - clampf(balance.chase_pace_relief, 0.0, 0.30) * intensity


## Multiplier on one action candidate's §10.3 score-and-clock factor.
##
## The protecting side prefers the actions that consume the clock and refuses
## the shot with the widest outcome; the chasing side does the reverse. Both are
## preferences over *which legal action is selected* and neither touches whether
## the selected action succeeds.
static func action_multiplier(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
	action_family: int,
	zone: int,
) -> float:
	return action_multiplier_at(
		context, balance, action_family, zone, pressure(context))


## The same, with `pressure` supplied by the caller.
##
## Candidate generation asks for this once per candidate and a possession can
## generate forty of them, all from one state — so the pressure is identical for
## every candidate in the call, and recomputing it forty times cost eleven per
## cent of the engine's running time for an answer that could not change. The
## caller memoizes it once per `generate` and passes it in. The arithmetic is
## the same arithmetic in the same order, which is why no ledger moves.
static func action_multiplier_at(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
	action_family: int,
	zone: int,
	intensity: float,
) -> float:
	var value: float = endgame_multiplier(context, balance, action_family, zone)
	if intensity <= 0.0:
		return value
	var three: bool = zone >= 0 and ShotZone.is_three(zone)
	if is_protecting(context):
		if action_family == ActionFamily.Value.RESET:
			value *= 1.0 + clampf(balance.protect_reset_gain, 0.0, 0.60) * intensity
		elif three:
			value *= 1.0 - clampf(balance.protect_three_relief, 0.0, 0.50) * intensity
		return value
	if three:
		value *= 1.0 + clampf(balance.chase_three_gain, 0.0, 0.60) * intensity
	elif action_family == ActionFamily.Value.RESET:
		value *= 1.0 - clampf(balance.chase_three_gain, 0.0, 0.60) * intensity
	return value


## Multiplier on how often an offensive player crashes the glass.
##
## Sending a player to the offensive glass is a bet: it buys second chances and
## it costs transition defence. A team protecting a lead stops taking the bet
## and a team chasing one takes it more often, which is one of the most visible
## things a coach changes late in a decided game. Like everything else here it
## moves *where five players stand*; the rebounding contest itself is untouched,
## and a player who does crash wins the ball exactly as often as before.
static func crash_multiplier(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
) -> float:
	var intensity: float = pressure(context)
	if intensity <= 0.0:
		return 1.0
	if is_protecting(context):
		return 1.0 - clampf(balance.protect_crash_relief, 0.0, 0.60) * intensity
	return 1.0 + clampf(balance.chase_crash_gain, 0.0, 0.60) * intensity


## End-of-regulation possession strategy: the shot that ties.
##
## With one possession left in regulation a trailing team does not want the
## *best* shot, it wants the shot whose value erases the deficit. Down three
## that is a three; down two it is a two, and the general chasing preference
## above — which hunts threes whenever a team is behind — is actively wrong
## there, because the two ties the game and the three has to be made to win it.
##
## This is `SIMULATION_SPEC.md` §20.2 clutch behaviour stated as an action
## preference. It changes which shot is attempted and nothing about whether it
## goes in, and it is symmetric: it is the deficit that selects the shot value,
## and either team can hold it.
static func endgame_multiplier(
	context: PossessionContext,
	balance: SimulationBalanceProfile,
	_action_family: int,
	zone: int,
) -> float:
	if zone < 0:
		return 1.0
	if context.state.period < context.input.rule_profile.regulation_periods:
		return 1.0
	if remaining_ms(context.state, context.input.rule_profile) > balance.endgame_possession_ms:
		return 1.0
	var deficit: int = -context.offense_margin()
	if deficit < TIE_SEEKING_MINIMUM_DEFICIT or deficit > TIE_SEEKING_MAXIMUM_DEFICIT:
		return 1.0
	var three: bool = ShotZone.is_three(zone)
	var tying_shot_is_a_three: bool = deficit == TIE_SEEKING_MAXIMUM_DEFICIT
	if three == tying_shot_is_a_three:
		return 1.0 + clampf(balance.endgame_tie_gain, 0.0, 0.80)
	return 1.0 - clampf(balance.endgame_tie_relief, 0.0, 0.70)


## The deficits a single shot can level. Down one, every made shot wins and none
## of them ties, so the rule has nothing to say about it.
const TIE_SEEKING_MINIMUM_DEFICIT: int = 2
const TIE_SEEKING_MAXIMUM_DEFICIT: int = 3
