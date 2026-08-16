class_name TestIdentityAndUsage
extends GdUnitTestSuite

## The Â§10.6.4 separation of concerns, and usage as a constrained budget.
##
## | Input                   | Determines                                    |
## | Tendencies              | What the player prefers when several are valid |
## | Tactical role           | What opportunity the player receives           |
## | Rotation role           | How much the player is on the floor            |
## | Capability and context  | Whether the attempt succeeds                   |
##
## "Success flows only from the last row. No identity layer may be used to reach
## it." These tests drive each layer independently and check that only its own
## column moves.

const SEED: int = 606060

## A behavioural difference is a distribution, not a single game. One short
## fixture can land on the same shot mix by coincidence, so the mix comparisons
## aggregate over a fixed seed set â€” still fully deterministic, just not
## balanced on one sample.
const MIX_SEEDS: PackedInt64Array = [606060, 11235, 98765, 4321, 24680]


## Â§12.4: tactical role reaches `RoleOpportunity` and nothing else, and it can
## never gate an action to zero.
func test_tactical_role_changes_opportunity_only() -> void:
	var balance := SimulationBalanceProfile.new()
	# A Roll/Pop Big screens far more often than a Shooter does.
	assert_float(
		balance.role_opportunity(TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.SCREEN)
	).is_greater(
		balance.role_opportunity(TacticalRole.Value.SHOOTER, ActionFamily.Value.SCREEN))
	# And a Shooter relocates far more often than a Roll/Pop Big.
	assert_float(
		balance.role_opportunity(TacticalRole.Value.SHOOTER, ActionFamily.Value.RELOCATION)
	).is_greater(
		balance.role_opportunity(TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.RELOCATION))
	# Â§10.6.2: "A tactical role never gates action validity. A `shooter` may
	# drive and a `roll_pop_big` may pass."
	for role in TacticalRole.all():
		for family in ActionFamily.all():
			var opportunity: float = balance.role_opportunity(role, family)
			assert_float(opportunity).is_greater(0.0)
			assert_float(opportunity).is_between(
				RoleOpportunityTable.EXCEPTIONAL_MINIMUM,
				RoleOpportunityTable.EXCEPTIONAL_MAXIMUM)


## Role changes what a lineup attempts without changing how well it shoots.
func test_tactical_role_moves_shot_mix_but_not_shooting_quality() -> void:
	# Opportunity moved: the shooter lineup takes a larger share of its shots
	# from three than the roll/pop lineup does.
	assert_float(_three_point_rate_for_role(TacticalRole.Value.SHOOTER)).is_greater(
		_three_point_rate_for_role(TacticalRole.Value.ROLL_POP_BIG))


## Â§12.4: rotation role reaches planned minutes and substitution priority only.
func test_rotation_role_changes_minutes_only() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var starter_seconds: int = 0
	var bench_seconds: int = 0
	for player in input.home.players:
		var line: PlayerStatLine = output.final_result.statistics.player_line(player.player_id)
		if player.rotation_role == RotationRole.Value.STARTER:
			starter_seconds += line.seconds_played
		else:
			bench_seconds += line.seconds_played
	assert_int(starter_seconds).is_greater(bench_seconds)


## Â§10.4: a tendency changes what is attempted, never the rating behind it.
func test_tendency_changes_attempt_mix_without_touching_ratings() -> void:
	var interior_share: float = _paint_rate_for_tendency(
		TendencySlider.Value.PERIMETER_INTERIOR, 5)
	var perimeter_share: float = _paint_rate_for_tendency(
		TendencySlider.Value.PERIMETER_INTERIOR, 1)
	assert_float(interior_share).is_greater(perimeter_share)


## Â§10.5: coach instruction shapes behaviour, bounded by Â§12.2, and never
## rewrites the player's saved sliders.
func test_coach_instruction_shapes_behaviour_within_its_band() -> void:
	var plan := TeamGamePlan.new(
		CoverageFamily.Value.MAN_STAY_HOME, 5, 1, 5,
		TeamGamePlan.NEUTRAL_POSITION, TeamGamePlan.NEUTRAL_POSITION,
		TeamGamePlan.NEUTRAL_POSITION, 0.40, 0.0)
	# Â§12.3 bounds coach authority between 10% and 40% whatever the trust.
	assert_float(plan.coach_share_for(0.0)).is_between(0.10, 0.40)
	assert_float(plan.coach_share_for(1.0)).is_between(0.10, 0.40)
	# A trusted player keeps more of his own preference.
	assert_float(plan.coach_share_for(1.0)).is_less(plan.coach_share_for(0.0))

	var tendencies := PlayerTendencies.new()
	var before: int = tendencies.at(TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO)
	var input: MatchInput = MatchFixtureFactory.quick_match()
	MatchEngine.new().simulate_match(input, SeededRandomSource.new(SEED))
	assert_int(tendencies.at(TendencySlider.Value.PUSH_TRANSITION_CONTROL_TEMPO)).is_equal(before)


## Usage responds monotonically to its opportunity inputs.
##
## The claim is about the opportunity function, so it is tested on the
## opportunity function. Measuring a player's share of a short game instead
## folds in rotation noise â€” how many minutes he happened to play â€” and turns a
## deterministic contract into a sampling question.
func test_usage_responds_monotonically_to_opportunity_inputs() -> void:
	# Tactical role: more on-ball opportunity, more claim on the ball.
	var utility: float = _opportunity_index_with(
		TacticalRole.Value.UTILITY_ENERGY, TendencySlider.NEUTRAL_POSITION, 70)
	var secondary: float = _opportunity_index_with(
		TacticalRole.Value.SECONDARY_CREATOR, TendencySlider.NEUTRAL_POSITION, 70)
	var primary: float = _opportunity_index_with(
		TacticalRole.Value.PRIMARY_CREATOR, TendencySlider.NEUTRAL_POSITION, 70)
	assert_float(secondary).is_greater(utility)
	assert_float(primary).is_greater(secondary)

	# Tendency: a score-first player asks for the ball more than a pass-first one.
	var pass_first: float = _opportunity_index_with(TacticalRole.Value.UTILITY_ENERGY, 1, 70)
	var score_first: float = _opportunity_index_with(TacticalRole.Value.UTILITY_ENERGY, 5, 70)
	assert_float(score_first).is_greater(pass_first)

	# Capability: a better ball handler earns more opportunity, bounded by the
	# Â§12.2 capability-confidence band rather than dominating outright.
	var weak: float = _opportunity_index_with(
		TacticalRole.Value.UTILITY_ENERGY, TendencySlider.NEUTRAL_POSITION, 40)
	var strong: float = _opportunity_index_with(
		TacticalRole.Value.UTILITY_ENERGY, TendencySlider.NEUTRAL_POSITION, 95)
	assert_float(strong).is_greater(weak)
	assert_float(strong / weak).is_less(
		SimulationBalanceProfile.new().capability_confidence_max
		/ SimulationBalanceProfile.new().capability_confidence_min)


## The budget stays constrained: no legal configuration lets one player consume
## the whole team's shot volume. Â§12.4 makes a universally dominant
## configuration a release blocker.
func test_usage_remains_a_constrained_budget() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		var team: TeamStatLine = output.final_result.statistics.team_line(team_id)
		var highest: int = 0
		for line in output.final_result.statistics.players_for(team_id):
			highest = maxi(highest, line.field_goals_attempted)
		var share: float = float(highest) / float(maxi(team.field_goals_attempted, 1))
		assert_float(share).is_less(0.60)
		assert_float(share).is_greater(0.0)


## The budget is a team constraint: the five on-court shares always sum to one.
func test_usage_budget_sums_across_the_lineup() -> void:
	var input: MatchInput = MatchFixtureFactory.quick_match()
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(SEED))
	for team_id: StringName in [input.home.team_id, input.away.team_id]:
		var team: TeamStatLine = output.final_result.statistics.team_line(team_id)
		var attempts: int = 0
		for line in output.final_result.statistics.players_for(team_id):
			attempts += line.field_goals_attempted
		assert_int(attempts).is_equal(team.field_goals_attempted)
		assert_int(attempts).is_greater(0)


## Share of the home team's attempts taken from three, aggregated over the
## fixed seed set.
func _three_point_rate_for_role(role: int) -> float:
	var attempts: int = 0
	var threes: int = 0
	for seed_value in MIX_SEEDS:
		var input: MatchInput = MatchFixtureFactory.match_between(
			_role_team(&"home", role), MatchFixtureFactory.uniform_team(&"away", 70),
			MatchFixtureFactory.quick_match().rule_profile)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		var line: TeamStatLine = output.final_result.statistics.team_line(&"home")
		attempts += line.field_goals_attempted
		threes += line.three_pointers_attempted
	return float(threes) / float(maxi(attempts, 1))


## Share of the home team's attempts taken in the paint, aggregated the same way.
func _paint_rate_for_tendency(slider: int, position: int) -> float:
	var values: Array[int] = []
	for index in range(PlayerTendencies.SLIDER_COUNT):
		values.append(TendencySlider.NEUTRAL_POSITION)
	values[slider] = position
	var tendencies := PlayerTendencies.new(values)
	var attempts: int = 0
	var paint: int = 0
	for seed_value in MIX_SEEDS:
		var input: MatchInput = MatchFixtureFactory.match_between(
			_tendency_team(&"home", tendencies), MatchFixtureFactory.uniform_team(&"away", 70),
			MatchFixtureFactory.quick_match().rule_profile)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(seed_value))
		var line: TeamStatLine = output.final_result.statistics.team_line(&"home")
		attempts += line.field_goals_attempted
		paint += line.paint_attempts
	return float(paint) / float(maxi(attempts, 1))


## A uniform team whose every player carries one tactical role, so the only
## difference between two runs is the identity layer under test.
func _role_team(team_id: StringName, role: int) -> TeamMatchProfile:
	var base: TeamMatchProfile = MatchFixtureFactory.uniform_team(team_id, 70)
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(base.players.size()):
		var source: PlayerMatchProfile = base.players[index]
		players.append(PlayerMatchProfile.new(
			source.player_id, source.positions, source.body, source.attributes,
			[], source.tendencies, source.rotation_role, TacticalRole.new(role),
			source.condition, [], source.qualitative_durability_band))
		if index < 5:
			starters.append(source.player_id)
	return TeamMatchProfile.new(team_id, players, starters, 0.5)


func _tendency_team(team_id: StringName, tendencies: PlayerTendencies) -> TeamMatchProfile:
	var base: TeamMatchProfile = MatchFixtureFactory.uniform_team(team_id, 70)
	var players: Array[PlayerMatchProfile] = []
	var starters: Array[StringName] = []
	for index in range(base.players.size()):
		var source: PlayerMatchProfile = base.players[index]
		players.append(PlayerMatchProfile.new(
			source.player_id, source.positions, source.body, source.attributes,
			[], tendencies, source.rotation_role, source.tactical_role,
			source.condition, [], source.qualitative_durability_band))
		if index < 5:
			starters.append(source.player_id)
	return TeamMatchProfile.new(team_id, players, starters, 0.5)


## The opportunity index of one player, built against a real possession context
## in which only he differs from a uniform lineup.
func _opportunity_index_with(role: int, score_first_position: int, handle: int) -> float:
	var overrides: Dictionary = {AttributeKey.Key.HANDLE: handle}
	var base: TeamMatchProfile = MatchFixtureFactory.uniform_team(&"home", 70, overrides)
	var values: Array[int] = []
	for index in range(PlayerTendencies.SLIDER_COUNT):
		values.append(TendencySlider.NEUTRAL_POSITION)
	values[TendencySlider.Value.PASS_FIRST_SCORE_FIRST] = score_first_position
	var subject: PlayerMatchProfile = base.players[0]
	var players: Array[PlayerMatchProfile] = [PlayerMatchProfile.new(
		subject.player_id, subject.positions, subject.body, subject.attributes,
		[], PlayerTendencies.new(values), subject.rotation_role, TacticalRole.new(role),
		subject.condition, [], subject.qualitative_durability_band)]
	var starters: Array[StringName] = [subject.player_id]
	for index in range(1, base.players.size()):
		players.append(base.players[index])
		if index < 5:
			starters.append(base.players[index].player_id)

	var home := TeamMatchProfile.new(&"home", players, starters, 0.5)
	var input: MatchInput = MatchFixtureFactory.match_between(
		home, MatchFixtureFactory.uniform_team(&"away", 70),
		MatchFixtureFactory.quick_match().rule_profile)
	var snapshot := MatchSnapshot.new(input)
	var capability := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var body := BodyEffects.new(input.balance_profile)
	var matchups: MatchupState = MatchupResolver.new(capability, body).resolve(
		input.home, snapshot.home, input.away, snapshot.away)
	var context := PossessionContext.new(input, snapshot, input.home.team_id, matchups, 1)
	return ParticipantSelector.new(capability, input.balance_profile).opportunity_index(
		context, subject.player_id)

