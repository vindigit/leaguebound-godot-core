class_name MatchFixtureFactory
extends RefCounted


static func standard_match() -> MatchInput:
	var home := _team(&"home", 72)
	var away := _team(&"away", 70)
	return MatchInput.new(
		&"fixture_match_001",
		&"fixture_game_001",
		CompetitionRuleProfile.new(&"fixture_rules", &"v1", 4, 120, 60, 24, 6),
		SimulationBalanceProfile.new(&"fixture_balance", &"v1"),
		home,
		away,
		home.team_id,
	)


static func standard_snapshot() -> MatchSnapshot:
	return MatchSnapshot.new(standard_match())


static func _team(team_id: StringName, base_rating: int) -> TeamMatchProfile:
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(8):
		var player_id := StringName("%s_p%d" % [team_id, index + 1])
		var offset := (index % 3) - 1
		var rating := clampi(base_rating + offset, Rating.ACTIVE_MINIMUM, Rating.MAXIMUM)
		var attributes := PlayerAttributes.new(
			rating, rating, rating, rating, rating,
			rating, rating, rating, rating, rating,
			rating, rating, rating, rating, rating,
			rating, rating, rating, rating, rating,
		)
		var role: int = RotationRole.Value.STARTER if index < 5 else RotationRole.Value.ROTATION
		var tactical: int = TacticalRole.all()[index % TacticalRole.COUNT]
		players.append(PlayerMatchProfile.new(
			player_id,
			PositionProfile.new(StringName("P%d" % [index % 5 + 1])),
			BodyProfile.new(73 + index, 185 + index * 6, 75 + index, 0),
			attributes,
			[],
			PlayerTendencies.new(),
			role,
			TacticalRole.new(tactical),
			1.0,
			[],
			&"average",
		))
		if index < 5:
			starters.append(player_id)
	return TeamMatchProfile.new(team_id, players, starters, 0.5)
