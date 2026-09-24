class_name HomeEnvironmentContext
extends RefCounted

## The §19.4 home environment, as the channels §19.4 permits and nothing else
## (`SIMULATION_SPEC.md` §9.3, §19.4; `BALANCE_SPEC.md` §17.4).
##
## §19.4: "Home advantage can affect bounded officiating, communication,
## composure, and familiarity factors. Its aggregate effect is calibrated as a
## small win-rate edge for otherwise even teams. It never guarantees an outcome."
##
## §9.3 names this type in `PossessionContext`. Before it existed the home
## environment was a bare `float` on `MatchInput`, read at three unrelated call
## sites, with nothing anywhere that summed the channels, compared the sum with
## §17.4's +2.5 points per 100 possessions, or bounded any single one against
## §17.4's four absolute probability points. Both caps were satisfied only
## because the effects were far too small to reach either, which is not the same
## thing as being enforced.
##
## What this type is for is that every home-environment effect in the engine has
## to come through it, be named as one of §19.4's channels, and be counted.
##
## **It reads one number.** Strength, normalized, where zero is a neutral court.
## There is no score, no clock, no margin, no team identity, no expected winner,
## no result and no setter: a context is built once from the venue strength and
## the balance profile, and asked. A comeback mechanism cannot be written
## through this API, because the API cannot see anything to come back from.

## §17.4: "No single home modifier may exceed four absolute probability points."
##
## Enforced by clamping rather than by asserting, so a balance profile that asks
## for more gets the cap instead of the number it asked for, and the test that
## proves it does not depend on assertions being compiled in.
const MAX_SINGLE_MODIFIER: float = 0.04

## §17.4: "Combined environment contributions are capped at +2.5 points per 100
## possessions."
##
## That cap is in points and this type deals in probabilities, so it is enforced
## in two halves that meet in the middle. Structurally, the sum of the channel
## modifiers is bounded here, which is exact and testable and needs no
## calibration constant to be true. Empirically,
## `run_home_court_diagnostics.gd` measures the realized points per 100
## possessions on paired fixtures and judges *that* against 2.5. Neither half is
## sufficient alone: a modifier bound cannot know what a possession is worth,
## and a cohort measurement cannot prove an individual game stayed inside it.
##
## The value is the modifier budget the measured +2.5 corresponds to, with room
## left over. It is deliberately not derived from a points-per-possession
## conversion: such a conversion would be a fitted constant pretending to be a
## bound.
const MAX_COMBINED_MODIFIER: float = 0.09

## §19.4's channels, as the three this engine implements.
##
## Familiarity is **not** a separate channel. §19.4 lists it beside
## communication, and in this engine both act on the same mechanism — how well a
## delivery and its catch are coordinated — so implementing them twice would be
## two names for one effect and would make the combined cap harder to read, not
## easier. The brief's instruction is to use the fewest channels necessary.
enum Channel { OFFICIATING, COMMUNICATION, COMPOSURE }

const CHANNEL_COUNT: int = 3
const CHANNEL_IDS: PackedStringArray = ["officiating", "communication", "composure"]

## Venue strength in `0.0..1.0`. Zero is a neutral court and is the only value
## that provably contributes nothing on every channel, because every channel is
## multiplied by it.
var strength: float

var _modifiers: PackedFloat64Array


func _init(
	p_strength: float = 0.0,
	p_officiating: float = 0.0,
	p_communication: float = 0.0,
	p_composure: float = 0.0,
) -> void:
	assert(p_strength >= 0.0 and p_strength <= 1.0,
		"home environment strength must be normalized")
	strength = p_strength
	_modifiers = PackedFloat64Array([
		_bounded(p_officiating), _bounded(p_communication), _bounded(p_composure)])
	assert(total_modifier() <= MAX_COMBINED_MODIFIER + 1e-9,
		"combined home-environment modifiers exceed the §17.4 budget")


## A neutral court. Every channel is exactly zero, and `is_neutral` is true.
static func neutral() -> HomeEnvironmentContext:
	return HomeEnvironmentContext.new(0.0, 0.0, 0.0, 0.0)


## The environment a competition's balance profile describes, at one venue
## strength. This is the only constructor production uses.
static func from_profile(
	p_strength: float,
	balance: SimulationBalanceProfile,
) -> HomeEnvironmentContext:
	assert(balance != null, "a home environment needs its balance profile")
	if p_strength <= 0.0:
		return HomeEnvironmentContext.neutral()
	return HomeEnvironmentContext.new(
		p_strength,
		balance.home_officiating_modifier * p_strength,
		balance.home_communication_modifier * p_strength,
		balance.home_composure_modifier * p_strength)


## Whether this is a neutral court. True when the strength is zero, and
## therefore true exactly when every channel contributes nothing.
func is_neutral() -> bool:
	return strength <= 0.0


## One channel's contribution, in absolute probability points, always positive
## and always at or below `MAX_SINGLE_MODIFIER`. The *sign* belongs to the
## caller, because it is the caller that knows which side of the venue
## relationship it is resolving.
func modifier(channel: int) -> float:
	assert(channel >= 0 and channel < CHANNEL_COUNT, "unknown home-environment channel")
	return _modifiers[channel]


## §19.4 officiating: a home crowd's influence on a genuinely ambiguous
## illegal-contact decision. It never creates a foul without a valid foul
## opportunity, because the only consumer applies it to the conversion of an
## opportunity that already exists.
func officiating() -> float:
	return _modifiers[Channel.OFFICIATING]


## §19.4 communication, and the familiarity that is the same mechanism: a home
## side's deliveries and catches are marginally better coordinated, so marginally
## fewer of them are thrown away. It moves the unforced pass error and nothing
## else — never a make probability, and never a defender's steal, either of
## which would be a flat home bonus with a communication label on it.
func communication() -> float:
	return _modifiers[Channel.COMMUNICATION]


## §19.4 composure, inside §17.4's pressure envelope: a visiting side carries
## marginally more execution noise. It applies to every legitimate context
## rather than to close games, because a modifier that appeared only when the
## game was close would be a comeback mechanism wearing a different name.
func composure() -> float:
	return _modifiers[Channel.COMPOSURE]


## The sum of every channel, which is the quantity `MAX_COMBINED_MODIFIER`
## bounds. Published so a report can show the aggregation rather than assert it.
func total_modifier() -> float:
	var total: float = 0.0
	for value in _modifiers:
		total += value
	return total


func channel_id(channel: int) -> StringName:
	assert(channel >= 0 and channel < CHANNEL_COUNT, "unknown home-environment channel")
	return StringName(CHANNEL_IDS[channel])


## Every channel's contribution, for the ledger and the diagnostic report. §17.4
## requires the environment to be auditable, and a number nobody can see is not.
func to_dictionary() -> Dictionary:
	var payload: Dictionary = {"strength": strength, "total_modifier": total_modifier()}
	for channel in range(CHANNEL_COUNT):
		payload[CHANNEL_IDS[channel]] = _modifiers[channel]
	return payload


func _bounded(value: float) -> float:
	assert(value >= 0.0, "a home-environment channel is a magnitude, not a direction")
	return clampf(value, 0.0, MAX_SINGLE_MODIFIER)
