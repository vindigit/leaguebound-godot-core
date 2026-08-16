class_name MatchFixtureFactory
extends RefCounted

## Deterministic match fixtures for the simulation suites.
##
## The Stage 3 gate requires named scenarios — regulation, overtime, offensive
## rebound continuation, foul and free throw, substitution and foul-out, and
## late game — to be reachable from a fixed seed. They are built here rather
## than inside each test so a golden hash and the behaviour test that explains
## it are looking at the same match.

const DEFAULT_ROSTER_SIZE: int = 10


static func standard_match() -> MatchInput:
	return match_between(_team(&"home", 72), _team(&"away", 70), _standard_rules())


static func standard_snapshot() -> MatchSnapshot:
	return MatchSnapshot.new(standard_match())


## A shorter game for suites that run many matches. Same contracts, less clock.
static func quick_match() -> MatchInput:
	return match_between(
		_team(&"home", 72), _team(&"away", 70),
		CompetitionRuleProfile.new(&"fixture_quick", &"v1", 2, 180, 120, 24, 6))


## School rules: one-and-one at seven team fouls, double bonus at ten. Used by
## the bonus and free-throw suites.
static func school_rules_match() -> MatchInput:
	return match_between(
		_team(&"home", 70), _team(&"away", 70), CompetitionRuleProfile.school_profile())


## A tight personal-foul limit against a deep bench, so foul-outs and forced
## substitutions occur without exhausting the roster.
##
## The bench depth is the point. A short roster under a tight limit runs out of
## legal players, which is a real basketball situation but an *upstream* one:
## §5 requires career services to supply an authorized replacement before the
## match exists, and the engine is forbidden from inventing one. A fixture that
## triggered it would be testing the assertion, not the rotation.
static func foul_out_match() -> MatchInput:
	var rules := CompetitionRuleProfile.new(
		&"fixture_foul_out", &"v1", 4, 240, 120, 24, 2, 14, 8,
		2, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false)
	var home: TeamMatchProfile = _team(&"home", 70, 14, _aggressive_tendencies())
	var away: TeamMatchProfile = _team(&"away", 70, 14, _aggressive_tendencies())
	return match_between(home, away, rules)


## A profile whose bonus begins at the first team foul, so non-shooting fouls
## reliably produce free throws inside a small deterministic fixture. Real
## competition thresholds are reached only over a full game; a contract test
## should not depend on a whole game's foul accumulation to exercise one branch.
static func bonus_match() -> MatchInput:
	var rules := CompetitionRuleProfile.new(
		&"fixture_bonus", &"v1", 2, 240, 120, 24, 6, 14, 8,
		1, CompetitionRuleProfile.BonusKind.TWO_SHOT, -1, 2, true, true, false)
	return match_between(
		_team(&"home", 70, DEFAULT_ROSTER_SIZE, _aggressive_tendencies()),
		_team(&"away", 70, DEFAULT_ROSTER_SIZE, _aggressive_tendencies()),
		rules)


## The same, with a one-and-one first tier so the earned-second-attempt branch
## is reachable.
static func one_and_one_match() -> MatchInput:
	var rules := CompetitionRuleProfile.new(
		&"fixture_one_and_one", &"v1", 2, 240, 120, 24, 6, 14, 8,
		1, CompetitionRuleProfile.BonusKind.ONE_AND_ONE, 40, 2, true, true, false)
	return match_between(
		_team(&"home", 70, DEFAULT_ROSTER_SIZE, _aggressive_tendencies()),
		_team(&"away", 70, DEFAULT_ROSTER_SIZE, _aggressive_tendencies()),
		rules)


## Two evenly matched teams over a short game, which reaches overtime often
## enough for a fixed seed to find it.
static func even_match() -> MatchInput:
	return match_between(
		_team(&"home", 70), _team(&"away", 70),
		CompetitionRuleProfile.new(&"fixture_even", &"v1", 2, 180, 120, 24, 6))


## A crash-heavy offence against a chase-happy defence, so offensive rebounds
## and putbacks appear in a small number of possessions.
static func offensive_rebound_match() -> MatchInput:
	var crashers: PlayerTendencies = _tendencies_with(
		TendencySlider.Value.BOX_OUT_CHASE_REBOUNDS, 5)
	var chasers: PlayerTendencies = _tendencies_with(
		TendencySlider.Value.BOX_OUT_CHASE_REBOUNDS, 5)
	var home: TeamMatchProfile = _team(
		&"home", 74, DEFAULT_ROSTER_SIZE, crashers, _crash_plan())
	var away: TeamMatchProfile = _team(&"away", 66, DEFAULT_ROSTER_SIZE, chasers)
	return match_between(home, away, _standard_rules())


static func match_between(
	home: TeamMatchProfile,
	away: TeamMatchProfile,
	rules: CompetitionRuleProfile,
	balance: SimulationBalanceProfile = null,
) -> MatchInput:
	var profile: SimulationBalanceProfile = (
		balance if balance != null else SimulationBalanceProfile.new(&"fixture_balance", &"v1"))
	return MatchInput.new(
		&"fixture_match_001",
		&"fixture_game_001",
		rules,
		profile,
		home,
		away,
		home.team_id,
		RatingsProfile.default_profile(),
		0.5,
	)


## A roster whose every player is identical except for one attribute, used by
## the attribute-contract suite to isolate a single rating.
static func uniform_team(
	team_id: StringName,
	rating: int,
	overrides: Dictionary = {},
	roster_size: int = DEFAULT_ROSTER_SIZE,
) -> TeamMatchProfile:
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(roster_size):
		var player_id := StringName("%s_p%d" % [team_id, index + 1])
		var values: Array[int] = []
		for key in AttributeKey.all():
			var value: int = rating
			if overrides.has(key):
				var override_value: int = overrides[key]
				value = override_value
			values.append(clampi(value, Rating.ACTIVE_MINIMUM, Rating.MAXIMUM))
		players.append(PlayerMatchProfile.new(
			player_id,
			PositionProfile.new(StringName("P%d" % [index % 5 + 1])),
			BodyProfile.new(76, 205, 78, 0),
			PlayerAttributes.from_values(values),
			[],
			PlayerTendencies.new(),
			RotationRole.Value.STARTER if index < 5 else RotationRole.Value.ROTATION,
			TacticalRole.new(TacticalRole.Value.UTILITY_ENERGY),
			1.0,
			[],
			&"average",
		))
		if index < 5:
			starters.append(player_id)
	return TeamMatchProfile.new(team_id, players, starters, 0.5)


static func _standard_rules() -> CompetitionRuleProfile:
	return CompetitionRuleProfile.new(&"fixture_rules", &"v1", 4, 300, 150, 24, 6)


static func _team(
	team_id: StringName,
	base_rating: int,
	roster_size: int = DEFAULT_ROSTER_SIZE,
	tendencies: PlayerTendencies = null,
	game_plan: TeamGamePlan = null,
) -> TeamMatchProfile:
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(roster_size):
		var player_id := StringName("%s_p%d" % [team_id, index + 1])
		var offset: int = (index % 3) - 1
		var rating: int = clampi(
			base_rating + offset, Rating.ACTIVE_MINIMUM, Rating.MAXIMUM)
		var slot: int = index % 5
		players.append(PlayerMatchProfile.new(
			player_id,
			PositionProfile.new(StringName("P%d" % [slot + 1])),
			_body_for_slot(slot),
			_attributes_for_slot(rating, slot),
			[],
			tendencies if tendencies != null else PlayerTendencies.new(),
			RotationRole.Value.STARTER if index < 5 else RotationRole.Value.ROTATION,
			TacticalRole.new(_tactical_role_for_slot(slot)),
			1.0,
			[],
			&"average",
		))
		if index < 5:
			starters.append(player_id)
	return TeamMatchProfile.new(team_id, players, starters, 0.5, game_plan)


## Bodies scale from a point guard to a centre so the §6.1 body channels —
## dunk validity, reach, leverage, and matchups — have something to read.
static func _body_for_slot(slot: int) -> BodyProfile:
	var heights: PackedInt32Array = [73, 76, 79, 81, 84]
	var weights: PackedInt32Array = [180, 195, 215, 235, 255]
	var wingspans: PackedInt32Array = [75, 79, 82, 85, 88]
	return BodyProfile.new(heights[slot], weights[slot], wingspans[slot], 0)


## A guard shoots and handles; a centre finishes, protects the rim, and
## rebounds. Ratings stay inside a narrow band of the team's base so the
## fixtures compare teams, not archetypes.
static func _attributes_for_slot(base: int, slot: int) -> PlayerAttributes:
	var values: Array[int] = []
	for key in AttributeKey.all():
		values.append(base)
	var perimeter: float = 1.0 - float(slot) / 4.0
	_adjust(values, AttributeKey.Key.THREE_POINT, int(roundf(lerpf(-10.0, 8.0, perimeter))))
	_adjust(values, AttributeKey.Key.MID_RANGE, int(roundf(lerpf(-6.0, 6.0, perimeter))))
	_adjust(values, AttributeKey.Key.HANDLE, int(roundf(lerpf(-14.0, 10.0, perimeter))))
	_adjust(values, AttributeKey.Key.PASSING, int(roundf(lerpf(-8.0, 8.0, perimeter))))
	_adjust(values, AttributeKey.Key.VISION, int(roundf(lerpf(-8.0, 8.0, perimeter))))
	_adjust(values, AttributeKey.Key.SPEED, int(roundf(lerpf(-10.0, 8.0, perimeter))))
	_adjust(values, AttributeKey.Key.PERIMETER_DEFENSE, int(roundf(lerpf(-10.0, 8.0, perimeter))))
	_adjust(values, AttributeKey.Key.SHORT_RANGE, int(roundf(lerpf(8.0, -4.0, perimeter))))
	_adjust(values, AttributeKey.Key.DUNKING, int(roundf(lerpf(10.0, -8.0, perimeter))))
	_adjust(values, AttributeKey.Key.INTERIOR_DEFENSE, int(roundf(lerpf(10.0, -10.0, perimeter))))
	_adjust(values, AttributeKey.Key.BLOCKING, int(roundf(lerpf(12.0, -12.0, perimeter))))
	_adjust(values, AttributeKey.Key.STRENGTH, int(roundf(lerpf(10.0, -8.0, perimeter))))
	_adjust(values, AttributeKey.Key.OFFENSIVE_REBOUNDING, int(roundf(lerpf(10.0, -10.0, perimeter))))
	_adjust(values, AttributeKey.Key.DEFENSIVE_REBOUNDING, int(roundf(lerpf(12.0, -10.0, perimeter))))
	_adjust(values, AttributeKey.Key.STEALING, int(roundf(lerpf(-8.0, 6.0, perimeter))))
	return PlayerAttributes.from_values(values)


static func _adjust(values: Array[int], key: int, delta: int) -> void:
	values[key] = clampi(values[key] + delta, Rating.ACTIVE_MINIMUM, Rating.MAXIMUM)


static func _tactical_role_for_slot(slot: int) -> int:
	match slot:
		0:
			return TacticalRole.Value.PRIMARY_CREATOR
		1:
			return TacticalRole.Value.SHOOTER
		2:
			return TacticalRole.Value.SLASHER
		3:
			return TacticalRole.Value.ROLL_POP_BIG
		_:
			return TacticalRole.Value.INTERIOR_ANCHOR


static func _tendencies_with(slider: int, position: int) -> PlayerTendencies:
	var values: Array[int] = []
	for index in range(PlayerTendencies.SLIDER_COUNT):
		values.append(TendencySlider.NEUTRAL_POSITION)
	values[slider] = position
	return PlayerTendencies.new(values)


static func _aggressive_tendencies() -> PlayerTendencies:
	var values: Array[int] = []
	for index in range(PlayerTendencies.SLIDER_COUNT):
		values.append(TendencySlider.NEUTRAL_POSITION)
	values[TendencySlider.Value.PATIENT_AGGRESSIVE] = 5
	values[TendencySlider.Value.DISCIPLINED_GAMBLE] = 5
	values[TendencySlider.Value.PERIMETER_INTERIOR] = 5
	return PlayerTendencies.new(values)


static func _crash_plan() -> TeamGamePlan:
	return TeamGamePlan.new(
		CoverageFamily.Value.MAN_STAY_HOME,
		TeamGamePlan.NEUTRAL_POSITION,
		5,
		TeamGamePlan.NEUTRAL_POSITION,
		TeamGamePlan.NEUTRAL_POSITION,
		5,
		TeamGamePlan.NEUTRAL_POSITION,
		0.25,
		0.5,
	)
