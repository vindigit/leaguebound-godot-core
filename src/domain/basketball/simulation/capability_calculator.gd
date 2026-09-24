class_name CapabilityCalculator
extends RefCounted

## The single owner of derived basketball capability (`SIMULATION_SPEC.md` §7).
##
## "A capability is a pure, versioned function of current ratings, body, active
## badges, and match context." Every resolver in this package asks this class;
## none of them re-derives a rating weight. That is what keeps one weight table,
## one version, and one place to change when the §31 sensitivity report lands.
##
## Weights come from `RatingsProfile` (`GODOT_TDD.md` §5.6). Fatigue conversion,
## injury share, and every other magnitude come from `SimulationBalanceProfile`.
## Nothing numeric is authored here.
##
## §7.4: Offensive and Defensive IQ "are not generic hidden bonuses added to
## every probability". They appear only where the §5.2 table places them, and
## never exceed the 45% non-primary share the table allows, so IQ improves the
## circumstances in which a technical rating is used and cannot substitute for
## it.
##
## Identity layers are absent by construction. `BALANCE_SPEC.md` §12.4:
## "Identity layers reach opportunity, never capability."

## Sentinel for an unfilled cache slot. Capabilities are on the unit interval,
## so a negative value cannot collide with a real one.
const _UNCACHED: float = -1.0

var _ratings: RatingsProfile
var _balance: SimulationBalanceProfile

## Per-player memo of the parts of a capability that cannot change during a
## match, keyed by player id.
##
## Two things are memoized and no others:
##
## - the §5.2 weighted mean, which is a pure function of the twenty stored
##   ratings, and those are immutable match input (§6.1: the engine consumes the
##   realized body and ratings; growth resolves outside match sessions);
## - the availability factor, a function of pregame condition and the injury
##   limitations supplied at match start.
##
## **Fatigue, matchup, injury *events*, and per-action context are deliberately
## not cached.** They are recomputed on every call below, because caching a
## context-dependent value as if it were permanent is precisely the defect the
## Stage 4 brief forbids. The two rows that take a live context argument —
## Shot Selection and Help Recognition, the only rows with a non-zero
## `contextual_share` — bypass the memo entirely.
##
## The memo lives on the calculator, and a calculator is constructed per match
## from one immutable `MatchInput`, so it cannot outlive the facts it caches.
var _base_by_player: Dictionary = {}
var _availability_by_player: Dictionary = {}


func _init(p_ratings: RatingsProfile, p_balance: SimulationBalanceProfile) -> void:
	assert(p_ratings != null and p_balance != null,
		"capability resolution requires a versioned ratings and balance profile")
	_ratings = p_ratings
	_balance = p_balance


## The §5.2 weighted mean, before any match context. Public so contract tests
## can assert monotonicity on the pure function.
func base_capability(capability: int, attributes: PlayerAttributes, context: float = 0.0) -> float:
	return _ratings.capability_weights(capability).evaluate(attributes, context)


## The live capability: §5.2 base, then pregame condition, active injury
## limitation, and the §15.1 acute-fatigue band penalty scaled by the
## capability's own declared sensitivity.
func capability_of(
	capability: int,
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	context: float = 0.0,
) -> float:
	var weights: CapabilityWeightSet = _ratings.capability_weights(capability)
	var base: float = (
		base_capability(capability, player.attributes, context)
		if weights.contextual_share > 0.0
		else _memoized_base(capability, player)
	)
	var penalty: float = (
		_balance.fatigue_capability_penalty(runtime.acute_fatigue) * weights.fatigue_sensitivity)
	return clampf(base * availability_factor(player) - penalty, 0.0, 1.0)


## Pregame condition and injury limitation, as a multiplicative availability
## factor. §17.3 keeps injuries an availability and execution effect; nothing
## here rewrites a stored rating.
func availability_factor(player: PlayerMatchProfile) -> float:
	if _availability_by_player.has(player.player_id):
		var cached: float = _availability_by_player[player.player_id]
		return cached
	var worst: float = 0.0
	for limitation in player.injury_limitations:
		worst = maxf(worst, limitation.severity)
	var value: float = clampf(
		player.condition * (1.0 - worst * _balance.injury_capability_share), 0.0, 1.0)
	_availability_by_player[player.player_id] = value
	return value


## The context-free §5.2 mean for one player and capability, computed once.
func _memoized_base(capability: int, player: PlayerMatchProfile) -> float:
	var row: PackedFloat64Array
	if _base_by_player.has(player.player_id):
		row = _base_by_player[player.player_id]
	else:
		row = PackedFloat64Array()
		row.resize(CapabilityKey.COUNT)
		row.fill(_UNCACHED)
		_base_by_player[player.player_id] = row
	var cached: float = row[capability]
	if cached >= 0.0:
		return cached
	var value: float = base_capability(capability, player.attributes, 0.0)
	row[capability] = value
	_base_by_player[player.player_id] = row
	return value


## A capability differential in §5.1 `RatingDifferential` units, which is what
## `SimulationBalanceProfile.opposed_probability` expects. One unit is a
## ten-point edge on the 25-99 scale.
func differential_units(attacker: float, defender: float) -> float:
	return (attacker - defender) * float(Rating.MAXIMUM - Rating.ACTIVE_MINIMUM) / 10.0


## The shot capability for a zone, with Shot Selection's contextual term
## supplied from the same relevant shooting rating §5.2 names.
func shot_capability(
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	zone: int,
) -> float:
	return capability_of(CapabilityKey.shotmaking_for_zone(zone), player, runtime)


## Shot Selection, whose tenth share is the relevant shooting rating for the
## attempt actually being considered.
func shot_selection(
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	zone: int,
) -> float:
	var relevant: float = base_capability(
		CapabilityKey.shotmaking_for_zone(zone), player.attributes)
	return capability_of(CapabilityKey.Value.SHOT_SELECTION, player, runtime, relevant)


## Help Recognition, whose tenth share is live assignment-execution quality.
## §5.2: that term "is not the tactical role identity, and it must not be
## implemented by reading" an identity id. The caller supplies execution
## quality built from chemistry, discipline, and current workload.
func help_recognition(
	player: PlayerMatchProfile,
	runtime: PlayerMatchRuntime,
	assignment_execution: float,
) -> float:
	return capability_of(
		CapabilityKey.Value.HELP_RECOGNITION, player, runtime, assignment_execution)
