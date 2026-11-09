class_name StakesPolicy
extends RefCounted

## The only place a `GameStakes` tier becomes a number
## (`SIMULATION_SPEC.md` §18.2 contextual adjustment).
##
## Four coaching decisions read the stakes tier, and they are the four the
## contract names: how long a coach rides his rotation, how long he holds a
## timeout for the endgame, how certain he has to be before he empties his
## bench, and how early he starts managing the last possession of regulation.
## Nothing else in the engine may read a tier, and keeping the arithmetic in one
## class is what makes that claim checkable rather than asserted.
##
## ## The shape of every effect
##
## ```text
## effect = base * (1 + step * tier)
## ```
##
## `tier` is 0, 1, or 2. A `REGULAR` game multiplies every base by exactly
## `1.0`, so the default path is not "approximately unchanged" — it is the same
## floating-point arithmetic in the same order, which is why every committed
## golden ledger is byte-identical after this change. Each `step` is a named
## tunable with a documented unit and safe range, and each product is then
## clamped by the same bound the base already lived under.
##
## ## What this is not
##
## It is not a difficulty setting, a momentum system, or a closeness governor.
## Every quantity below is a *decision threshold* and none of them is a
## probability. A tier cannot change a rating, a capability, a shot, a
## turnover, a foul or a rebound; it cannot read which team is which, which team
## is favoured, or how the game ends; and it applies to both teams identically,
## because it is a property of the occasion and not of a side. The two coaches
## in a Final are both more deliberate; neither of them is helped.

## The largest multiplier any stakes effect may reach, whatever the tunables
## say. Two tiers at a step of 0.50 is 2.0; nothing here is allowed past it,
## because a coaching preference that doubles is at the edge of a preference and
## anything beyond it is a different mechanism wearing this one's name.
const MAXIMUM_FACTOR: float = 2.0


## `1 + step * tier`, clamped. The single arithmetic form the whole class uses.
static func factor(step: float, stakes: int) -> float:
	var tier: int = GameStakes.tier(stakes)
	if tier <= 0:
		# Exactly one, by construction rather than by rounding: this is the
		# branch every regular-season game and every committed golden takes.
		return 1.0
	return clampf(1.0 + maxf(step, 0.0) * float(tier), 1.0, MAXIMUM_FACTOR)


## §18.1 planned minutes: how far past his planned share a coach lets a player
## run before the bench takes the minutes.
##
## `RotationResolver` compares realized share against planned share and
## substitutes above one. A higher tier raises that tolerance, so the players a
## coach most wants on the floor stay on it longer and the rotation tightens.
## The bench is not closed — foul trouble, acute fatigue, injury and the settled
## rotation are all untouched — it is only asked for fewer discretionary
## minutes.
static func minute_tolerance(balance: SimulationBalanceProfile, stakes: int) -> float:
	return factor(balance.stakes_rotation_tightness_step, stakes)


## §4/§5 timeouts: how much regulation must remain for a coach to spend one
## stopping the opponent's run rather than saving it for the endgame.
##
## A higher tier reserves earlier, which is the whole of "more deliberate": the
## same timeout, held for the moment it is worth more. The allowance itself is a
## rule-profile fact and is not touched, and a timeout's effect — rest for
## everybody on the floor, both teams — is not touched either.
static func timeout_reserve_ms(balance: SimulationBalanceProfile, stakes: int) -> int:
	return roundi(float(balance.timeout_run_reserve_ms) * factor(
		balance.stakes_timeout_reserve_step, stakes))


## §18.2 score and time: how safe a lead has to be before this coach stops
## playing the game.
##
## The safety *number* is untouched — it is still `|margin|` over the dispersion
## of the game left to play, still computed identically for both teams, and
## still the only thing that decides whether a game is mathematically over. What
## a tier moves is how many standard deviations of it a coach demands before he
## acts on it. A championship coach waits longer; he does not wait forever,
## because safety grows without bound as the clock runs out and the multiplier
## does not.
static func settled_entry_threshold(
	balance: SimulationBalanceProfile,
	base_threshold: float,
	stakes: int,
) -> float:
	if is_inf(base_threshold):
		return base_threshold
	return base_threshold * factor(balance.stakes_settled_patience_step, stakes)


## §20.2 last possession: how much regulation may remain for the tie-seeking
## rule to apply.
##
## Down two or three with the ball and the game ending, a coach hunts the shot
## that levels it rather than the best shot available. A higher tier opens that
## window earlier, so a Final's last minute is played as a last minute rather
## than as ordinary basketball that happens to be ending. It selects *which
## legal shot is attempted* and touches nothing about whether it falls.
static func endgame_window_ms(balance: SimulationBalanceProfile, stakes: int) -> int:
	return roundi(float(balance.endgame_possession_ms) * factor(
		balance.stakes_endgame_window_step, stakes))


## §20.2 last possession: how strongly the tie-seeking preference is held.
##
## The same preference, more firmly. Both the weight added to the levelling shot
## and the weight taken off the other one scale together, so the rule stays a
## preference between two legal actions and never becomes a certainty: the §12.2
## guardrails the whole weight product lives under still bound the result.
static func endgame_conviction(balance: SimulationBalanceProfile, stakes: int) -> float:
	return factor(balance.stakes_endgame_conviction_step, stakes)
