class_name GarbageTimeRule
extends RefCounted

## When a coach stops playing the game and starts managing the roster
## (`SIMULATION_SPEC.md` §18.2 score and time, owner ruling of 2026-08-20).
##
## The previous rule was one universal raw margin inside a share of the final
## period: twenty points with five minutes left, applied to the *absolute*
## margin so both benches emptied on the identical condition. That is symmetric
## and it is also not basketball. A coach twenty ahead with nine minutes to play
## has already won and starts protecting people; a coach twenty behind with
## three minutes to play has not conceded and keeps his rotation on the floor.
## Both of them are reading the same scoreboard and reaching different
## decisions, because the decision they face is different.
##
## **The policy is symmetric; the roles are not.** Both teams compute one shared
## safety number from public state, and the sign of a team's own margin selects
## which threshold applies to it. Put the same roster on the other side of the
## same scoreboard and it behaves the other way. Nothing here reads a rating, an
## intended winner, or a target final margin, and nothing here touches a
## probability: the whole of its effect is *who is on the floor*, which
## §10.6.1 names as the entire numeric privilege of a rotation role.
##
## ## The safety number
##
## A lead is safe when it is large against the dispersion of what is left to
## play, not when it exceeds a fixed number of points:
##
## ```text
## safety = |margin| / (swing_points_per_pair * sqrt(possession_pairs_left))
## ```
##
## The margin of a game left to play is a sum over the remaining possession
## pairs, so its standard deviation grows with the *square root* of them —
## which is why one constant covers a thirty-two-minute school game and a
## forty-eight-minute professional one without a per-competition table, and why
## twenty points at nine minutes and thirty points at twenty minutes are the
## same decision. `possession_pairs_left` is read from the pace the game has
## actually played at, so a slow competition buys fewer of them from the same
## clock and reaches the same safety sooner.
##
## Two guards keep it away from competitive basketball. A margin below
## `settled_minimum_margin` never qualifies whatever the clock says, and a game
## with less than one possession pair left cannot newly enter the state, because
## there is nothing left to rest anyone for.
##
## ## Leaving again
##
## The state is not a latch and it is not a ratchet. If the trailing team
## actually closes the gap, the safety number falls and both coaches go back to
## their rotations — which is a *consequence* of the score and grants nothing:
## the trailing team earned the points first. Release uses a lower threshold
## than entry so a game sitting exactly on the boundary does not alternate every
## possession.

enum Mode {
	NONE, ## the ordinary rotation
	LEADING, ## protecting a lead that is safe
	TRAILING, ## conceding a deficit that is no longer realistically recoverable
}

const MODE_COUNT: int = 3
const MODE_IDS: PackedStringArray = ["none", "leading", "trailing"]


static func is_valid_mode(value: int) -> bool:
	return value >= 0 and value < MODE_COUNT


static func mode_id(value: int) -> StringName:
	assert(is_valid_mode(value), "unknown garbage-time mode")
	return StringName(MODE_IDS[value])


static func mode_from_id(value: StringName) -> int:
	for index in range(MODE_COUNT):
		if StringName(MODE_IDS[index]) == value:
			return index
	assert(false, "unknown garbage-time mode id")
	return Mode.NONE


## How safe the current margin is, in standard deviations of the margin still to
## be played. Identical for both teams: it is a property of the game, not of a
## side.
static func safety(
	state: MatchSnapshot,
	input: MatchInput,
	balance: SimulationBalanceProfile,
) -> float:
	var margin: int = absi(state.margin_for(input.home.team_id))
	if margin <= 0:
		return 0.0
	var pairs: float = maxf(GameManagement.possession_pairs_left(state, input), 0.25)
	var dispersion: float = maxf(balance.settled_swing_points_per_pair, 0.1) * sqrt(pairs)
	return float(margin) / maxf(dispersion, 0.0001)


## Regulation time left at a stated period and clock, without a snapshot.
##
## `GameManagement.remaining_ms` answers the same question from live state; a
## report walking a finished ledger has a period and a clock and no state, and
## restating the arithmetic in the report is how the two drift apart.
static func remaining_regulation_ms(
	period: int,
	clock_ms: int,
	rules: CompetitionRuleProfile,
) -> int:
	var total: int = clock_ms
	for future in range(period + 1, rules.regulation_periods + 1):
		total += rules.period_length_ms(future)
	return total


## Which side of the scoreboard this team is on. `NONE` when the game is level.
static func role_for(state: MatchSnapshot, team_id: StringName) -> int:
	var margin: int = state.margin_for(team_id)
	if margin > 0:
		return Mode.LEADING
	if margin < 0:
		return Mode.TRAILING
	return Mode.NONE


## The safety a team in this role needs before its coach changes rotation.
##
## The leading threshold is the lower of the two, and that asymmetry is the
## whole of the correction: a coach who has won the game rests people before a
## coach who has lost it gives up on winning.
static func entry_threshold(balance: SimulationBalanceProfile, role: int) -> float:
	if role == Mode.LEADING:
		return maxf(balance.settled_leading_safety, 0.0)
	if role == Mode.TRAILING:
		return maxf(balance.settled_trailing_safety, 0.0)
	return INF


## Whether this team's coach should move into the settled rotation now.
static func should_enter(
	state: MatchSnapshot,
	input: MatchInput,
	balance: SimulationBalanceProfile,
	team_id: StringName,
) -> bool:
	var role: int = role_for(state, team_id)
	if role == Mode.NONE:
		return false
	if absi(state.margin_for(team_id)) < balance.settled_minimum_margin:
		return false
	# With less than a possession pair to play there is no rest left to give.
	if GameManagement.possession_pairs_left(state, input) < balance.settled_minimum_pairs_left:
		return false
	return safety(state, input, balance) >= entry_threshold(balance, role)


## Whether a team already in the settled rotation should return to its
## competitive one. Released below a share of the threshold it entered on, so a
## game balanced on the boundary does not alternate every possession.
static func should_leave(
	state: MatchSnapshot,
	input: MatchInput,
	balance: SimulationBalanceProfile,
	team_id: StringName,
) -> bool:
	var mode: int = state.state_for(team_id).settled_mode
	if mode == Mode.NONE:
		return false
	# The coaching floor releases on the same hysteresis as the safety does. A
	# state that entered at eighteen points and released at seventeen would
	# alternate every time a settled game traded baskets around the boundary,
	# and the substitutions that churn are real minutes for real players.
	var release_margin: float = float(balance.settled_minimum_margin) * clampf(
		balance.settled_release_share, 0.0, 1.0)
	if float(absi(state.margin_for(team_id))) < release_margin:
		return true
	if role_for(state, team_id) != mode:
		# The lead changed hands. Whatever this coach was doing, he is not doing
		# it any more.
		return true
	var release: float = entry_threshold(balance, mode) * clampf(
		balance.settled_release_share, 0.0, 1.0)
	return safety(state, input, balance) < release


## The mode this team should be in after the check above, for the ledger.
static func resolved_mode(
	state: MatchSnapshot,
	input: MatchInput,
	balance: SimulationBalanceProfile,
	team_id: StringName,
) -> int:
	var current: int = state.state_for(team_id).settled_mode
	if current == Mode.NONE:
		return role_for(state, team_id) if should_enter(state, input, balance, team_id) else Mode.NONE
	return Mode.NONE if should_leave(state, input, balance, team_id) else current
