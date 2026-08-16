class_name CompetitionCatalog
extends RefCounted

## Versioned rosters and match inputs for the calibration suites.
##
## The competition *rules* live in `CompetitionRuleProfile` because they ship
## with the game. The *rosters* live here because they are calibration
## population samples, not shipping content: they exist so a report can say
## "these bands hold for a population of this shape" and so two runs of the same
## report compare the same population.
##
## Every roster is a deterministic function of a competition and a seed. No
## randomness escapes; two runs at the same seed build byte-identical inputs.

const VERSION: StringName = &"competition-catalog-v1"

## Alias so runners can spell the competition enum through one type.
const Profile := CalibrationTargets.Competition

const ROSTER_SIZE: int = 10

## Team mean current-rating level per competition. These set the population the
## Â§14.1 bands are certified against; Â§8.2 fixes the top-domestic end (median
## current OVR 77-81) and the lower competitions step down from it.
const _TEAM_RATING_CENTRE: PackedFloat64Array = [60.0, 66.0, 72.0, 74.0, 78.0]
## Spread between the best and worst player on a roster, in rating points.
const _TEAM_RATING_SPREAD: PackedFloat64Array = [16.0, 15.0, 14.0, 14.0, 13.0]

## Per-slot attribute offsets from the player's own level, indexed
## `[attribute][slot]` with slots running point guard through centre. A roster
## built without these is twenty identical players wearing different numbers,
## which produces basketball no band was ever written for.
const _SLOT_OFFSETS: Array = [
	[-4, -2, 0, 4, 7],        # short_range
	[-12, -4, 2, 8, 10],      # dunking
	[4, 6, 2, -2, -8],        # mid_range
	[6, 9, 3, -4, -14],       # three_point
	[2, 2, 0, -6, -11],       # free_throw
	[12, 6, -1, -10, -18],    # handle
	[10, 2, 0, -4, -8],       # passing
	[10, 3, 0, -3, -7],       # vision
	[4, 1, 0, 0, 1],          # offensive_iq
	[6, 6, 3, -4, -12],       # perimeter_defense
	[-12, -8, -1, 7, 12],     # interior_defense
	[7, 5, 1, -4, -8],        # stealing
	[-14, -8, 0, 8, 14],      # blocking
	[2, 0, 0, 1, 3],          # defensive_iq
	[-12, -7, -1, 7, 12],     # offensive_rebounding
	[-10, -6, 0, 8, 13],      # defensive_rebounding
	[8, 6, 2, -4, -10],       # speed
	[-10, -5, 1, 7, 12],      # strength
	[2, 2, 0, -1, -2],        # stamina
	[2, 4, 4, 2, -1],         # vertical
]

const _SLOT_HEIGHTS: PackedInt32Array = [73, 77, 80, 82, 84]
const _SLOT_WEIGHTS: PackedInt32Array = [180, 200, 220, 240, 258]
const _SLOT_WINGSPANS: PackedInt32Array = [76, 80, 83, 86, 89]
const _SLOT_POSITIONS: PackedStringArray = ["PG", "SG", "SF", "PF", "C"]

## Starters get the five roles that define a lineup; the bench repeats the
## shape so a substitution does not change what the offence is trying to do.
const _SLOT_TACTICAL_ROLES: PackedInt32Array = [
	TacticalRole.Value.PRIMARY_CREATOR,
	TacticalRole.Value.SHOOTER,
	TacticalRole.Value.SLASHER,
	TacticalRole.Value.ROLL_POP_BIG,
	TacticalRole.Value.INTERIOR_ANCHOR,
]
const _BENCH_TACTICAL_ROLES: PackedInt32Array = [
	TacticalRole.Value.SECONDARY_CREATOR,
	TacticalRole.Value.CONNECTOR,
	TacticalRole.Value.PERIMETER_STOPPER,
	TacticalRole.Value.POST_OPTION,
	TacticalRole.Value.REBOUNDER,
]

const _ROTATION_ROLES: PackedInt32Array = [
	RotationRole.Value.STAR,
	RotationRole.Value.STARTER,
	RotationRole.Value.STARTER,
	RotationRole.Value.STARTER,
	RotationRole.Value.STARTER,
	RotationRole.Value.SIXTH_PLAYER,
	RotationRole.Value.ROTATION,
	RotationRole.Value.ROTATION,
	RotationRole.Value.BENCH,
	RotationRole.Value.RESERVE,
]


static func rules_for(competition: int) -> CompetitionRuleProfile:
	match competition:
		Profile.HIGH_SCHOOL:
			return CompetitionRuleProfile.high_school_profile()
		Profile.COLLEGE:
			return CompetitionRuleProfile.college_profile()
		Profile.DEVELOPMENT:
			return CompetitionRuleProfile.development_profile()
		Profile.OVERSEAS:
			return CompetitionRuleProfile.overseas_profile()
		Profile.TOP_DOMESTIC_PRO:
			return CompetitionRuleProfile.top_domestic_profile()
		_:
			assert(false, "unknown competition")
	return CompetitionRuleProfile.top_domestic_profile()


static func balance_profile() -> SimulationBalanceProfile:
	return SimulationBalanceProfile.new()


static func ratings_profile() -> RatingsProfile:
	return RatingsProfile.default_profile()


## The match the performance profile and the smoke suites use, so "one
## reference game" means one specific thing everywhere it is quoted.
static func reference_match() -> MatchInput:
	return match_for(Profile.TOP_DOMESTIC_PRO, 0, 0.5)


## An evenly matched game at one competition. `variation` shifts both rosters
## together so a large sample covers a population rather than replaying one
## fixture; `home_environment` is the Â§19.4 strength.
static func match_for(
	competition: int,
	variation: int = 0,
	home_environment: float = 0.5,
	home_offset: float = 0.0,
	away_offset: float = 0.0,
) -> MatchInput:
	var balance: SimulationBalanceProfile = balance_profile()
	var home: TeamMatchProfile = team_for(
		competition, &"home", variation * 2, balance, home_offset)
	var away: TeamMatchProfile = team_for(
		competition, &"away", variation * 2 + 1, balance, away_offset)
	return MatchInput.new(
		StringName("calib_%s_%d" % [CalibrationTargets.competition_id(competition), variation]),
		StringName("calib_game_%d" % variation),
		rules_for(competition),
		balance,
		home,
		away,
		home.team_id,
		ratings_profile(),
		home_environment)


## One roster. `variation` walks the population deterministically: it tilts the
## team level and the per-player noise without ever consuming a random source,
## so the same variation always rebuilds the same team.
static func team_for(
	competition: int,
	team_id: StringName,
	variation: int,
	balance: SimulationBalanceProfile = null,
	level_offset: float = 0.0,
) -> TeamMatchProfile:
	var profile_balance: SimulationBalanceProfile = (
		balance if balance != null else balance_profile())
	var centre: float = _TEAM_RATING_CENTRE[competition] + level_offset
	# A deterministic team-strength tilt of roughly Â±3 rating points, so a
	# population contains strong and weak teams rather than one repeated club.
	centre += float((variation * 37) % 13 - 6) * 0.5
	var spread: float = _TEAM_RATING_SPREAD[competition]

	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(ROSTER_SIZE):
		var slot: int = index % 5
		var player_id := StringName("%s_p%d" % [team_id, index + 1])
		# Descending player quality across the roster, so the star is the star.
		var rank_share: float = float(index) / float(ROSTER_SIZE - 1)
		var level: float = centre + spread * (0.5 - rank_share)
		# Per-player deterministic noise, Â±2 points, from index and variation.
		level += float((index * 29 + variation * 17) % 9 - 4) * 0.5
		players.append(_player(player_id, slot, index, level, profile_balance))
		if index < 5:
			starters.append(player_id)
	return TeamMatchProfile.new(
		team_id, players, starters, 0.55, TeamGamePlan.balanced_plan(), profile_balance)


## A roster whose players are identical apart from the supplied overrides, used
## by the attribute sensitivity suite to isolate one rating with the whole rest
## of the match context held constant.
static func uniform_team(
	team_id: StringName,
	rating: int,
	overrides: Dictionary = {},
	balance: SimulationBalanceProfile = null,
) -> TeamMatchProfile:
	var profile_balance: SimulationBalanceProfile = (
		balance if balance != null else balance_profile())
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(ROSTER_SIZE):
		var slot: int = index % 5
		var player_id := StringName("%s_p%d" % [team_id, index + 1])
		var values: Array[int] = []
		for key in range(AttributeKey.COUNT):
			var value: int = rating
			if overrides.has(key):
				var override_value: int = overrides[key]
				value = override_value
			values.append(clampi(value, Rating.ACTIVE_MINIMUM, Rating.MAXIMUM))
		players.append(PlayerMatchProfile.new(
			player_id,
			PositionProfile.new(StringName(_SLOT_POSITIONS[slot])),
			BodyProfile.new(76, 205, 79, 0),
			PlayerAttributes.from_values(values),
			[],
			PlayerTendencies.new(),
			_ROTATION_ROLES[index],
			TacticalRole.new(TacticalRole.Value.UTILITY_ENERGY),
			1.0,
			[],
			&"average"))
		if index < 5:
			starters.append(player_id)
	return TeamMatchProfile.new(
		team_id, players, starters, 0.5, TeamGamePlan.balanced_plan(), profile_balance)


# --- internals ---------------------------------------------------------------

static func _player(
	player_id: StringName,
	slot: int,
	index: int,
	level: float,
	balance: SimulationBalanceProfile,
) -> PlayerMatchProfile:
	var values: Array[int] = []
	for key in range(AttributeKey.COUNT):
		var offsets: Array = _SLOT_OFFSETS[key]
		var offset: int = offsets[slot]
		values.append(clampi(
			int(roundf(level + float(offset))), Rating.ACTIVE_MINIMUM, Rating.MAXIMUM))
	# Bench bodies vary a little from the starter template so matchup and reach
	# effects are not identical for every player in a slot.
	var body_shift: int = (index / 5) * 1
	return PlayerMatchProfile.new(
		player_id,
		PositionProfile.new(StringName(_SLOT_POSITIONS[slot])),
		BodyProfile.new(
			_SLOT_HEIGHTS[slot] + body_shift,
			_SLOT_WEIGHTS[slot] + body_shift * 4,
			_SLOT_WINGSPANS[slot] + body_shift,
			0),
		PlayerAttributes.from_values(values),
		[],
		PlayerTendencies.new(),
		_ROTATION_ROLES[index],
		TacticalRole.new(
			_SLOT_TACTICAL_ROLES[slot] if index < 5 else _BENCH_TACTICAL_ROLES[slot]),
		1.0,
		[],
		&"average")
