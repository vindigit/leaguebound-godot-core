class_name BodyEffects
extends RefCounted

## The only place body dimensions become basketball (`SIMULATION_SPEC.md` §6.1).
##
## §6.1 lists exactly four channels, and every function here belongs to one:
##
## 1. **Action validity** — `dunk_is_available`.
## 2. **Reach** — `reach_edge`, `rebound_reach_share`.
## 3. **Positioning and leverage** — `leverage_edge`, in combination with
##    Contact Force.
## 4. **Matchups** — `size_mismatch`.
##
## "Body must never contribute a general bonus to unrelated outcomes, and it
## must never be read as a proxy for Overall." There is deliberately no
## `body_quality()` here; a single scalar is precisely how body becomes that
## proxy. Callers must ask for the specific channel they mean.
##
## The engine consumes the realized current body only. Maturity profile,
## projected adult range, and growth resolution live in the career domain, and
## the match engine "cannot resolve, advance, or observe growth" (§6.1, §6.3).

var _balance: SimulationBalanceProfile


func _init(p_balance: SimulationBalanceProfile) -> void:
	assert(p_balance != null, "body effects require a versioned balance profile")
	_balance = p_balance


## Standing reach plus the leap the Vertical rating buys, in inches.
func maximum_reach_inches(body: BodyProfile, vertical_rating: int) -> float:
	var leap: float = lerpf(
		_balance.vertical_min_inches,
		_balance.vertical_max_inches,
		Rating.normalized(vertical_rating))
	return float(body.standing_reach_inches) + leap


## §6.1 action validity: whether a dunk is physically available at all.
##
## This is a hard gate, not a weight. §10.2: "The engine does not allow a
## tendency slider to create an invalid dunk". A 99 Dunking rating on a player
## who cannot reach the rim still cannot dunk, which is exactly what §27.4
## means by "a 99 rating produces exceptional capability but not impossible
## action access".
func dunk_is_available(body: BodyProfile, vertical_rating: int) -> bool:
	return maximum_reach_inches(body, vertical_rating) >= (
		_balance.rim_height_inches + _balance.dunk_clearance_inches)


## §6.1 reach: contest arrival quality, block access, rebound access, passing-
## lane coverage, and finish access over a defender. Positive when the first
## body out-reaches the second. Bounded by `body.reach_effect_max`.
func reach_edge(body: BodyProfile, opposing_body: BodyProfile) -> float:
	var difference: float = float(body.standing_reach_inches - opposing_body.standing_reach_inches)
	var share: float = clampf(difference / _balance.reach_scale_inches, -1.0, 1.0)
	return share * _balance.reach_effect_max


## §6.1 positioning and leverage: post resistance, box-out results, screen
## quality, and drive absorption, "in combination with Strength". The Contact
## Force capability is therefore a required argument, not optional context.
func leverage_edge(
	body: BodyProfile,
	contact_force: float,
	opposing_body: BodyProfile,
	opposing_contact_force: float,
) -> float:
	var weight_share: float = clampf(
		float(body.weight_pounds - opposing_body.weight_pounds) / _balance.weight_scale_pounds,
		-1.0,
		1.0)
	var strength_share: float = clampf(contact_force - opposing_contact_force, -1.0, 1.0)
	var combined: float = clampf(weight_share * 0.5 + strength_share * 0.5, -1.0, 1.0)
	return combined * _balance.body_effect_max


## §6.1 matchups: the size and speed mismatch term in advantage resolution.
## Positive when the first player is the larger of the pair.
func size_mismatch(body: BodyProfile, opposing_body: BodyProfile) -> float:
	var height_share: float = clampf(
		float(body.height_inches - opposing_body.height_inches) / _balance.height_scale_inches,
		-1.0,
		1.0)
	return height_share * _balance.body_effect_max


## §6.1 reach applied to the glass: how much of the rebound reach window a body
## occupies, on the unit interval.
func rebound_reach_share(body: BodyProfile, vertical_rating: int) -> float:
	var reach: float = maximum_reach_inches(body, vertical_rating)
	var span: float = _balance.rebound_reach_max_inches - _balance.rebound_reach_min_inches
	assert(span > 0.0, "the rebound reach window must be positive")
	return clampf((reach - _balance.rebound_reach_min_inches) / span, 0.0, 1.0)
