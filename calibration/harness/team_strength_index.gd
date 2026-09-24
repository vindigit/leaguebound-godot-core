class_name TeamStrengthIndex
extends RefCounted

## The pregame strength of one roster, built only from what the simulation
## actually consumes.
##
## `BALANCE_SPEC.md` §6.2 and the Stage 4 brief both forbid Overall as a
## simulation input, and a diagnostic that explained final margins in terms of
## Overall would be explaining them with a number the engine never reads. So the
## index is a planned-minute-weighted mean of `CapabilityCalculator` values —
## the same §5.2 weighted means the resolvers ask for — and Overall never
## appears.
##
## Two properties matter for the margin decomposition:
##
## - It is **pregame**. Every term is a function of immutable match input, so
##   the index cannot absorb any of the variance it is being used to explain.
##   `CapabilityCalculator.base_capability` is the context-free §5.2 mean;
##   fatigue, matchup, and live context are deliberately excluded.
## - It is **minute-weighted**. A roster's tenth player is not a tenth of its
##   strength. The weights are the §18 planned rotation shares from
##   `SimulationBalanceProfile`, which is where the engine's own minute plan
##   comes from, so the index weights players the way the game will.

## §7.1 offensive capabilities. Physical capabilities are excluded from both
## sides: they are already the ratings feeding these weighted means, and adding
## them again would be the double count this diagnostic exists to detect.
const OFFENSIVE: PackedInt32Array = [
	CapabilityKey.Value.BALL_SECURITY,
	CapabilityKey.Value.HANDLE_CREATION,
	CapabilityKey.Value.PASS_ACCURACY,
	CapabilityKey.Value.PASS_READ_QUALITY,
	CapabilityKey.Value.SHOT_SELECTION,
	CapabilityKey.Value.RIM_TOUCH_FINISH,
	CapabilityKey.Value.DUNK_THREAT,
	CapabilityKey.Value.MIDRANGE_SHOTMAKING,
	CapabilityKey.Value.THREE_POINT_SHOTMAKING,
	CapabilityKey.Value.FREE_THROW_SHOTMAKING,
	CapabilityKey.Value.OFF_BALL_TIMING,
	CapabilityKey.Value.OFFENSIVE_REBOUND_POSITIONING,
]

## §7.2 defensive capabilities.
const DEFENSIVE: PackedInt32Array = [
	CapabilityKey.Value.POINT_OF_ATTACK_CONTAINMENT,
	CapabilityKey.Value.PERIMETER_CONTEST,
	CapabilityKey.Value.INTERIOR_POSITIONING,
	CapabilityKey.Value.RIM_PROTECTION,
	CapabilityKey.Value.PASSING_LANE_DEFENSE,
	CapabilityKey.Value.ON_BALL_DISRUPTION,
	CapabilityKey.Value.HELP_RECOGNITION,
	CapabilityKey.Value.DEFENSIVE_REBOUND_POSITIONING,
]

## Capability units are on the unit interval. Reporting them at that scale puts
## every interesting difference in the third decimal place, so the index is
## published in centi-capability points: one point is 0.01 of capability.
const SCALE: float = 100.0

var offense: float = 0.0
var defense: float = 0.0
## Minute-weighted mean over both lists, which is the single number a matchup
## band is cut on.
var overall: float = 0.0
## The same means restricted to the five starters and to the bench, so a
## rotation asymmetry is visible rather than averaged away.
var starters: float = 0.0
var bench: float = 0.0
## Total planned minute weight. Two rosters with different totals are not being
## given the same rotation, which is itself a finding.
var minute_weight: float = 0.0


## Builds the index for one roster.
static func of_team(
	team: TeamMatchProfile,
	ratings: RatingsProfile,
	balance: SimulationBalanceProfile,
) -> TeamStrengthIndex:
	var calculator := CapabilityCalculator.new(ratings, balance)
	var index := TeamStrengthIndex.new()

	var weighted_offense: float = 0.0
	var weighted_defense: float = 0.0
	var weighted_all: float = 0.0
	var total_weight: float = 0.0
	var starter_sum: float = 0.0
	var starter_weight: float = 0.0
	var bench_sum: float = 0.0
	var bench_weight: float = 0.0
	var starter_ids: Array[StringName] = team.starters()

	for player: PlayerMatchProfile in team.players:
		var weight: float = balance.rotation_minute_share(player.rotation_role)
		var own_offense: float = _mean_of(calculator, OFFENSIVE, player)
		var own_defense: float = _mean_of(calculator, DEFENSIVE, player)
		var own_all: float = (
			own_offense * float(OFFENSIVE.size()) + own_defense * float(DEFENSIVE.size())
		) / float(OFFENSIVE.size() + DEFENSIVE.size())
		weighted_offense += own_offense * weight
		weighted_defense += own_defense * weight
		weighted_all += own_all * weight
		total_weight += weight
		if starter_ids.has(player.player_id):
			starter_sum += own_all * weight
			starter_weight += weight
		else:
			bench_sum += own_all * weight
			bench_weight += weight

	assert(total_weight > 0.0, "a roster must carry planned minutes to have a strength index")
	index.offense = SCALE * weighted_offense / total_weight
	index.defense = SCALE * weighted_defense / total_weight
	index.overall = SCALE * weighted_all / total_weight
	index.starters = SCALE * starter_sum / starter_weight if starter_weight > 0.0 else 0.0
	index.bench = SCALE * bench_sum / bench_weight if bench_weight > 0.0 else 0.0
	index.minute_weight = total_weight
	return index


## The pregame gap one side is expected to enjoy: its offence against the
## other's defence, both ways. This is the regressor the decomposition uses, and
## it is the only place the two indices are combined.
static func expected_gap(home: TeamStrengthIndex, away: TeamStrengthIndex) -> float:
	return (home.offense - away.defense) - (away.offense - home.defense)


static func _mean_of(
	calculator: CapabilityCalculator,
	keys: PackedInt32Array,
	player: PlayerMatchProfile,
) -> float:
	var total: float = 0.0
	for key in keys:
		total += calculator.base_capability(key, player.attributes)
	return total / float(keys.size())
