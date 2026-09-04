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

## **v3 counterbalanced the opening inbound.** v1 and v2 handed it to the home
## team in every fixture they ever built. See `OPENING_COUNTERBALANCED` below
## for why that was a fixture artifact rather than a rule, and what it was
## sitting inside.
##
## Note this constant is descriptive: nothing currently reads it, so it does not
## invalidate a cached report on its own.
const VERSION: StringName = &"competition-catalog-v3"

## Who receives the opening inbound, per fixture.
##
## **The engine does not decide this and never has.**
## `MatchInput.initial_possession_team_id` has no default and is asserted to
## name one of the two supplied teams; `MatchEngine` consumes a `MatchInput` and
## never constructs one; and nothing under `src/` constructs one either. The
## opening inbound is a property of the *fixture*, and every caller chooses it.
##
## This catalog chose `home.team_id`, unconditionally, in `match_for` and
## `mirrored_match_for` alike, for every game it has ever built. That is not a
## modelled basketball rule: nothing in `SIMULATION_SPEC.md`, `BALANCE_SPEC.md`,
## `GDD.md` or `PRD.md` describes a jump ball, a possession arrow or an
## alternating-possession rule, and `CompetitionRuleProfile`'s
## `possession_arrow_enabled` field is declared and never read by anything.
##
## It mattered because of where it sat. `run_competition_calibration` publishes
## `home_win_rate` as a **banded** §14.2 metric judged against 53-56%, over
## fixtures where the home team also received every opening possession — while
## its own comment asserted that "the measured home win rate is the environment
## effect and nothing else". It was the environment plus the inbound.
##
## The default is now counterbalanced: the home side opens on even variations
## and the away side on odd ones. This is a **fixture** counterbalance and not a
## production change, because there is no production behaviour here to change.
## It is deterministic — a function of the variation, consuming no random
## source — so two runs at the same seed still build byte-identical inputs.
##
## `OPENING_HOME` and `OPENING_AWAY` exist so a diagnostic can hold the inbound
## fixed on purpose; `run_opening_possession.gd` uses them to measure what it is
## worth.
const OPENING_COUNTERBALANCED: int = 0
const OPENING_HOME: int = 1
const OPENING_AWAY: int = 2

## Half-width of the deterministic team-strength tilt, in rating points.
##
## `team_for` walks a 13-step ladder from `-TEAM_LEVEL_TILT` to
## `+TEAM_LEVEL_TILT`, so this constant is the whole of the between-team spread
## the calibration population contains. Two independently tilted rosters differ
## in mean rating with a standard deviation of `TEAM_LEVEL_TILT * 0.882`.
##
## **v2 lowered it from 3.0 to 2.1, and the runners stopped adding a second
## tilt of their own.** The v1 population put 66% of its games in the
## large-mismatch band and only 11% in the near-even band, and the pregame
## strength gap explained 28.8% of final-margin variance — a spread no §14
## target asks for and one that produced blowouts by construction. At 2.1 the
## pregame gap carries an expected-margin standard deviation of about 6.5
## points, which is the between-team spread a settled top-level league shows.
## `PROJECT_STATUS.md` §5.10 carries the measurement and the derivation.
##
## Safe range: 0.0-4.0 rating points. Zero is a league of identical teams, which
## is a diagnostic fixture (`mirrored_match_for`) and not a population.
const TEAM_LEVEL_TILT: float = 2.1

## The ladder the tilt walks. Thirteen steps keeps the population from
## collapsing onto a handful of distinct team strengths.
const TEAM_LEVEL_STEPS: int = 13

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
	opening: int = OPENING_COUNTERBALANCED,
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
		opening_team_id(opening, variation, home, away),
		ratings_profile(),
		home_environment)


## Resolves an opening-inbound policy against one fixture.
##
## Deterministic in the variation and nothing else: no random source is touched,
## so the counterbalance cannot change what a seed reproduces.
static func opening_team_id(
	opening: int,
	variation: int,
	home: TeamMatchProfile,
	away: TeamMatchProfile,
) -> StringName:
	match opening:
		OPENING_HOME:
			return home.team_id
		OPENING_AWAY:
			return away.team_id
		_:
			return home.team_id if variation % 2 == 0 else away.team_id


## A match between two identical rosters at one competition.
##
## Both teams are built from the same `variation`, so every rating, body,
## tactical role, rotation role, and game plan is the same on both benches and
## the pregame strength gap is exactly zero. That makes it the only way to
## observe the engine's own dispersion with the population's spread removed: any
## margin a mirror match produces was invented during the game.
##
## It is a diagnostic fixture, not a population sample. A game-shape band must
## never be judged against mirror matches — a league of identical teams is not
## the league §14.2 describes — so the runners that use it report it beside the
## population result and never in place of it.
static func mirrored_match_for(
	competition: int,
	variation: int = 0,
	home_environment: float = 0.5,
	opening: int = OPENING_COUNTERBALANCED,
) -> MatchInput:
	var balance: SimulationBalanceProfile = balance_profile()
	var home: TeamMatchProfile = team_for(competition, &"home", variation * 2, balance, 0.0)
	var away: TeamMatchProfile = team_for(competition, &"away", variation * 2, balance, 0.0)
	return MatchInput.new(
		StringName("mirror_%s_%d" % [CalibrationTargets.competition_id(competition), variation]),
		StringName("mirror_game_%d" % variation),
		rules_for(competition),
		balance,
		home,
		away,
		opening_team_id(opening, variation, home, away),
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
	# The deterministic team-strength tilt, so a population contains strong and
	# weak teams rather than one repeated club. This is the *only* place a team
	# level moves: a caller that adds a second tilt of its own is stacking two
	# spreads and gets a mismatch distribution nobody chose.
	var step: float = 2.0 * TEAM_LEVEL_TILT / float(TEAM_LEVEL_STEPS - 1)
	centre += float(
		(variation * 37) % TEAM_LEVEL_STEPS - (TEAM_LEVEL_STEPS - 1) / 2) * step
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
