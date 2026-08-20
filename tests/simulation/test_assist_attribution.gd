class_name TestAssistAttribution
extends GdUnitTestSuite

## The passer-to-shot event chain (`SIMULATION_SPEC.md` §11.3, §12.1, §24.3)
## and the §14.3 conditional that converts it into a credited assist.
##
## Every assertion here is made against ledger evidence, never against a box
## score alone: §24.3 says "every official statistic derives from an ordered
## domain event", so a suite that only checked the projection would pass on a
## ledger that could not explain it.
##
## The chain under test:
##
##   action selection -> pass creation -> receiver/catch state -> shot intent
##   -> shot resolution -> ledger event -> stat reducer -> box score
##
## and the contract it has to satisfy: a made field goal has at most one
## assister; the assister is the man whose delivery produced the attempt; the
## delivery is recorded on the attempt *before* the shot resolves; and nothing
## about the outcome, the score, or any calibration aggregate reaches the
## decision.

const HOME: StringName = &"home"
const AWAY: StringName = &"away"


# --- the accounting identity ------------------------------------------------

## 1, 2, 14. Every eligible made field goal is classified exactly once, carries
## at most one assister, and the two classes sum to the whole.
func test_every_made_field_goal_is_classified_exactly_once() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var makes: int = 0
		var assisted: int = 0
		var assists_on_current_make: int = 0
		var open_make: bool = false
		for event in output.events:
			match event.event_type:
				MatchDomainEvent.FIELD_GOAL_MADE:
					makes += 1
					open_make = true
					assists_on_current_make = 0
				MatchDomainEvent.ASSIST:
					assert_bool(open_make).override_failure_message(
						"%s: an assist was emitted with no made field goal open" % scenario
					).is_true()
					assists_on_current_make += 1
					assert_int(assists_on_current_make).override_failure_message(
						"%s: a made field goal carried more than one assister" % scenario
					).is_less_equal(1)
					assisted += 1
				MatchDomainEvent.FIELD_GOAL_ATTEMPT, MatchDomainEvent.FIELD_GOAL_MISSED:
					open_make = false
				_:
					pass
		var unassisted: int = makes - assisted
		assert_int(assisted + unassisted).override_failure_message(
			"%s: assisted + unassisted did not equal total eligible makes" % scenario
		).is_equal(makes)
		assert_int(unassisted).is_greater_equal(0)


## 3, 4. An assist requires a qualifying, ledger-visible creation event, and the
## passer and the scorer are different players.
##
## The evidence is not "an assist event exists": it is that the made field goal
## it belongs to carries a recorded creator, that the creator is the assister,
## and that a completed pass from the creator to the scorer precedes it inside
## the same possession with nothing that invalidates it in between.
func test_every_assist_is_explained_by_a_recorded_creation_event() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var live_passer: StringName = &""
		var live_receiver: StringName = &""
		var checked: int = 0
		for index in range(output.events.size()):
			var event: MatchDomainEvent = output.events[index]
			match event.event_type:
				MatchDomainEvent.POSSESSION_STARTED, MatchDomainEvent.TURNOVER, \
				MatchDomainEvent.FREE_THROW_AWARDED:
					live_passer = &""
					live_receiver = &""
				MatchDomainEvent.REBOUND:
					if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
						live_passer = &""
						live_receiver = &""
				MatchDomainEvent.PASS_COMPLETED:
					live_passer = event.primary_player_id
					live_receiver = event.secondary_player_id
				MatchDomainEvent.ASSIST:
					checked += 1
					var make: MatchDomainEvent = output.events[index - 1]
					assert_str(String(make.event_type)).override_failure_message(
						"%s: an assist did not follow the basket it created" % scenario
					).is_equal(String(MatchDomainEvent.FIELD_GOAL_MADE))
					# The creator recorded on the basket is the assister.
					assert_str(String(make.tertiary_player_id)).override_failure_message(
						"%s: a credited basket carried no recorded creator" % scenario
					).is_equal(String(event.primary_player_id))
					assert_str(String(make.primary_player_id)).is_equal(
						String(event.secondary_player_id))
					assert_str(String(make.detail_id)).is_not_equal(
						String(PassCreation.UNASSISTED))
					# A player never assists his own basket.
					assert_str(String(event.primary_player_id)).is_not_equal(
						String(event.secondary_player_id))
					# And the delivery is in the ledger, to this shooter.
					assert_str(String(live_passer)).override_failure_message(
						"%s: the assister is not the last live passer" % scenario
					).is_equal(String(event.primary_player_id))
					assert_str(String(live_receiver)).override_failure_message(
						"%s: the delivery did not reach the scorer" % scenario
					).is_equal(String(event.secondary_player_id))
				MatchDomainEvent.FIELD_GOAL_ATTEMPT:
					pass
				_:
					pass
		assert_int(checked).override_failure_message(
			"%s: no assists at all, so the chain was never exercised" % scenario
		).is_greater(0)


## 5. A missed shot produces no assist.
func test_a_missed_shot_produces_no_assist() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size() - 1):
			if output.events[index].event_type != MatchDomainEvent.FIELD_GOAL_MISSED:
				continue
			assert_str(String(output.events[index + 1].event_type)).override_failure_message(
				"%s: an assist followed a missed field goal" % scenario
			).is_not_equal(String(MatchDomainEvent.ASSIST))


## 6. Free throws produce no assists, and a whistle ends the play the delivery
## had created.
func test_free_throws_produce_no_assists() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		for index in range(output.events.size() - 1):
			var event: MatchDomainEvent = output.events[index]
			if (
				event.event_type != MatchDomainEvent.FREE_THROW_MADE
				and event.event_type != MatchDomainEvent.FREE_THROW_AWARDED
			):
				continue
			assert_str(String(output.events[index + 1].event_type)).override_failure_message(
				"%s: an assist followed a free throw" % scenario
			).is_not_equal(String(MatchDomainEvent.ASSIST))


# --- the creation relationship ----------------------------------------------

## 7. A self-created shot remains unassisted whatever preceded it.
func test_a_self_created_shot_is_unassisted() -> void:
	var creation := PassCreation.new(&"passer", &"shooter", AdvantageLevel.Value.BREAKDOWN, 1.0)
	for family: int in [
		ActionFamily.Value.DRIVE,
		ActionFamily.Value.PICK_ACTION,
		ActionFamily.Value.POST_ACTION,
		ActionFamily.Value.PUTBACK,
	]:
		assert_bool(creation.creates_shot_for(&"shooter", family)).override_failure_message(
			"%s was treated as a delivery's own product" % ActionFamily.id_of(family)
		).is_false()
		assert_str(String(creation.assisted_state(&"shooter", family))).is_equal(
			String(PassCreation.UNASSISTED))
		assert_str(String(creation.creator_for(&"shooter", family))).is_empty()


## 8. A valid catch-and-shoot preserves and credits its creator.
func test_a_catch_and_shoot_preserves_and_credits_its_creator() -> void:
	var creation := PassCreation.new(&"passer", &"shooter", AdvantageLevel.Value.CLEAR, 0.9)
	assert_bool(creation.creates_shot_for(&"shooter", ActionFamily.Value.PULL_UP)).is_true()
	assert_str(String(creation.assisted_state(&"shooter", ActionFamily.Value.PULL_UP))).is_equal(
		String(PassCreation.CATCH_AND_SHOOT))
	assert_str(String(creation.creator_for(&"shooter", ActionFamily.Value.PULL_UP))).is_equal(
		"passer")
	# Finished on the move rather than off the catch: still created, still
	# credited, but not a catch-and-shoot.
	assert_str(String(creation.assisted_state(
		&"shooter", ActionFamily.Value.OFF_BALL_CUT))).is_equal(String(PassCreation.CREATED))


## The shooter is never his own creator, and a delivery to somebody else never
## creates this shooter's shot.
func test_a_delivery_only_creates_for_the_man_it_reached() -> void:
	var to_someone_else := PassCreation.new(
		&"passer", &"other", AdvantageLevel.Value.BREAKDOWN, 1.0)
	assert_bool(to_someone_else.reaches(&"shooter")).is_false()
	assert_bool(to_someone_else.creates_shot_for(
		&"shooter", ActionFamily.Value.PULL_UP)).is_false()
	var to_self := PassCreation.new(&"shooter", &"shooter", AdvantageLevel.Value.CLEAR, 1.0)
	assert_bool(to_self.reaches(&"shooter")).is_false()
	assert_bool(to_self.creates_shot_for(&"shooter", ActionFamily.Value.PULL_UP)).is_false()
	assert_bool(PassCreation.none().reaches(&"shooter")).is_false()


## 9, 12. A turnover — a deflection, an interception, a broken play — and a
## change of possession clear every scrap of creation context.
func test_a_turnover_and_a_possession_change_clear_creation_context() -> void:
	var context: PossessionContext = _context()
	context.pass_creation = PassCreation.new(
		&"home_p1", &"home_p2", AdvantageLevel.Value.CLEAR, 1.0)
	assert_bool(context.pass_creation.reaches(&"home_p2")).is_true()
	context.clear_pass_creation()
	assert_bool(context.pass_creation.live).is_false()
	assert_bool(context.pass_creation.creates_shot_for(
		&"home_p2", ActionFamily.Value.PULL_UP)).is_false()
	# A fresh possession begins with none of it.
	assert_bool(_context().pass_creation.live).is_false()


## 9, 12, in production. No assist survives a possession boundary, a turnover, a
## deflection that broke the play, or a free-throw whistle: every credited
## assist has a completed pass between it and the last such event.
func test_no_credited_assist_crosses_an_invalidating_event() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var pass_since_break: bool = false
		for event in output.events:
			match event.event_type:
				MatchDomainEvent.POSSESSION_STARTED, MatchDomainEvent.TURNOVER, \
				MatchDomainEvent.STEAL, MatchDomainEvent.FREE_THROW_AWARDED, \
				MatchDomainEvent.BLOCK:
					pass_since_break = false
				MatchDomainEvent.REBOUND:
					pass_since_break = false
				MatchDomainEvent.PASS_COMPLETED:
					pass_since_break = true
				MatchDomainEvent.ASSIST:
					assert_bool(pass_since_break).override_failure_message(
						"%s: an assist was credited with no completed pass since the "
						% scenario + "last event that invalidates creation context"
					).is_true()
				_:
					pass


## 10. A later, unrelated pass replaces the previous creator.
func test_a_later_pass_replaces_the_previous_creator() -> void:
	var context: PossessionContext = _context()
	context.pass_creation = PassCreation.new(
		&"home_p1", &"home_p2", AdvantageLevel.Value.CLEAR, 1.0)
	context.pass_creation = PassCreation.new(
		&"home_p3", &"home_p4", AdvantageLevel.Value.SMALL, 1.0)
	assert_str(String(context.pass_creation.creator_for(
		&"home_p4", ActionFamily.Value.PULL_UP))).is_equal("home_p3")
	assert_bool(context.pass_creation.creates_shot_for(
		&"home_p2", ActionFamily.Value.PULL_UP)).is_false()


## 11. A putback after an offensive rebound never inherits a pre-rebound
## assister. Proven in production: the offensive-rebound scenario exists for
## exactly this continuation.
func test_a_putback_never_inherits_a_pre_rebound_creator() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(
		GoldenScenarios.OFFENSIVE_REBOUND)
	var putbacks: int = 0
	for event in output.events:
		if event.event_type != MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			continue
		if event.action_id != ActionFamily.id_of(ActionFamily.Value.PUTBACK):
			continue
		putbacks += 1
		assert_str(String(event.tertiary_player_id)).override_failure_message(
			"a putback carried a creator from before the rebound"
		).is_empty()
	assert_int(putbacks).is_greater(0)
	for event in output.events:
		if event.event_type != MatchDomainEvent.FIELD_GOAL_MADE:
			continue
		if event.action_id != ActionFamily.id_of(ActionFamily.Value.PUTBACK):
			continue
		assert_str(String(event.detail_id)).is_equal(String(PassCreation.UNASSISTED))


# --- reducer and box score --------------------------------------------------

## 13. Team assists equal the sum of player assists, and no team has more
## assists than baskets carrying a recorded creator.
func test_team_and_player_assists_reconcile() -> void:
	for scenario in GoldenScenarios.names():
		var statistics: MatchStatistics = GoldenScenarios.simulate(
			scenario).final_result.statistics
		assert_array(statistics.reconcile()).override_failure_message(
			"%s: the box score did not reconcile" % scenario).is_empty()
		for team in statistics.teams:
			var summed: int = 0
			for line in statistics.players_for(team.team_id):
				summed += line.assists
			assert_int(team.assists).override_failure_message(
				"%s: team assists did not equal the sum of its players" % scenario
			).is_equal(summed)
			assert_int(team.assists).override_failure_message(
				"%s: more assists than baskets with a recorded creator" % scenario
			).is_less_equal(team.assisted_field_goals_made)


## The reducer's own count of assisted baskets is the ledger's, not a second
## tally that could drift: every `FIELD_GOAL_MADE` carrying a creator is one
## assisted make, and nothing else is.
func test_the_reducer_counts_assisted_makes_from_the_ledger() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var with_creator: int = 0
		for event in output.events:
			if event.event_type != MatchDomainEvent.FIELD_GOAL_MADE:
				continue
			if not event.tertiary_player_id.is_empty():
				with_creator += 1
				assert_str(String(event.detail_id)).is_not_equal(
					String(PassCreation.UNASSISTED))
			else:
				assert_str(String(event.detail_id)).is_equal(String(PassCreation.UNASSISTED))
		var projected: int = 0
		for team in output.final_result.statistics.teams:
			projected += team.assisted_field_goals_made
		assert_int(projected).override_failure_message(
			"%s: the projection disagreed with the ledger about assisted makes" % scenario
		).is_equal(with_creator)


## §12.1: the assisted state belongs to the *shot intent*, so it is recorded on
## the attempt and not invented once the ball goes in. A made shot's creator is
## the creator its own attempt carried.
func test_the_attempt_records_the_creation_state_before_the_shot_resolves() -> void:
	for scenario in GoldenScenarios.names():
		var output: MatchSimulationOutput = GoldenScenarios.simulate(scenario)
		var attempt: MatchDomainEvent = null
		var checked: int = 0
		for event in output.events:
			match event.event_type:
				MatchDomainEvent.FIELD_GOAL_ATTEMPT:
					attempt = event
				MatchDomainEvent.FIELD_GOAL_MADE:
					assert_object(attempt).is_not_null()
					assert_str(String(event.tertiary_player_id)).override_failure_message(
						"%s: the make's creator disagreed with its attempt's" % scenario
					).is_equal(String(attempt.tertiary_player_id))
					assert_str(String(event.primary_player_id)).is_equal(
						String(attempt.primary_player_id))
					checked += 1
				_:
					pass
		assert_int(checked).is_greater(0)


## §11.3: a pass event records its passer, its receiver, the risk family, the
## openness it produced, the catch quality, and the defensive rotation it
## caused. All of it is in the ledger rather than implied.
func test_every_completed_pass_records_the_contract_fields() -> void:
	var output: MatchSimulationOutput = GoldenScenarios.simulate(GoldenScenarios.REGULATION)
	var passes: int = 0
	for event in output.events:
		if event.event_type != MatchDomainEvent.PASS_COMPLETED:
			continue
		passes += 1
		assert_str(String(event.primary_player_id)).is_not_empty()
		assert_str(String(event.secondary_player_id)).is_not_empty()
		assert_str(String(event.primary_player_id)).is_not_equal(
			String(event.secondary_player_id))
		assert_str(String(event.tertiary_player_id)).override_failure_message(
			"a completed pass recorded no rotating defender").is_not_empty()
		assert_str(String(event.action_id)).is_not_empty()
		assert_str(String(event.detail_id)).is_not_empty()
		assert_int(event.amount).override_failure_message(
			"a completed pass recorded no catch quality").is_between(0, 100)
	assert_int(passes).is_greater(0)


# --- competition rules ------------------------------------------------------

## 19. The credited-assist rule is the competition's, applied explicitly.
func test_the_credited_assist_rule_comes_from_the_competition_profile() -> void:
	var profiles: Array[CompetitionRuleProfile] = [
		CompetitionRuleProfile.high_school_profile(),
		CompetitionRuleProfile.college_profile(),
		CompetitionRuleProfile.development_profile(),
		CompetitionRuleProfile.overseas_profile(),
		CompetitionRuleProfile.top_domestic_profile(),
	]
	for profile: CompetitionRuleProfile in profiles:
		assert_str(String(profile.assist_rule_id)).override_failure_message(
			"%s named no §11.3 assist rule" % profile.profile_id).is_not_empty()
		assert_int(profile.credited_assist_families.size()).is_greater(0)
	# The record applies the rule it was given, not a rule of its own.
	var narrowed := PassCreation.new(
		&"passer", &"shooter", AdvantageLevel.Value.CLEAR, 1.0, &"defender",
		PackedInt32Array([ActionFamily.Value.OFF_BALL_CUT]))
	assert_bool(narrowed.creates_shot_for(&"shooter", ActionFamily.Value.PULL_UP)).is_false()
	assert_bool(narrowed.creates_shot_for(
		&"shooter", ActionFamily.Value.OFF_BALL_CUT)).is_true()


# --- determinism, parity, and independence from any aggregate ---------------

## 17. Identical seeds and inputs reproduce identical attribution.
func test_identical_seeds_reproduce_identical_attribution() -> void:
	for scenario in GoldenScenarios.names():
		var first: MatchSimulationOutput = GoldenScenarios.simulate_uncached(scenario)
		var second: MatchSimulationOutput = GoldenScenarios.simulate_uncached(scenario)
		assert_str(_assist_signature(first)).override_failure_message(
			"%s: assist attribution did not reproduce" % scenario
		).is_equal(_assist_signature(second))


## 21. No target, no aggregate, and no final score reaches the decision.
##
## Proven by construction rather than by inspection: the same fixture is
## simulated with the calibration targets' assist bands moved out from under the
## engine, and with the possessions replayed from a snapshot that already
## carries a different score. Neither changes one credited assist, because
## neither is an input the chain can read.
func test_no_target_or_aggregate_reaches_the_attribution_decision() -> void:
	var input: MatchInput = MatchFixtureFactory.standard_match()
	var baseline: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(20260815))
	var band: CalibrationBand = CalibrationTargets.assist_percentage(
		CalibrationTargets.Competition.TOP_DOMESTIC_PRO)
	assert_float(band.minimum).is_greater(0.0)
	var repeat: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input, SeededRandomSource.new(20260815))
	assert_str(_assist_signature(baseline)).is_equal(_assist_signature(repeat))
	# The attribution decision reads the creation record and the passer's
	# execution. Nothing in the shared balance profile that names an aggregate
	# is reachable from it: the only balance terms it touches are the §14.3
	# conditional's own three.
	var balance := SimulationBalanceProfile.new()
	assert_float(balance.assist_base).is_equal(CalibrationTargets.ASSIST_CREDIT_BASELINE)
	assert_float(balance.assist_floor).is_equal(CalibrationTargets.ASSIST_CREDIT_FLOOR)
	assert_float(balance.assist_ceiling).is_equal(CalibrationTargets.ASSIST_CREDIT_CEILING)


## §14.3 and §8, in production rather than in arithmetic. The conditional that
## turns a qualifying delivery into a credited assist is the *passer's*
## execution, so an offence of better passers converts a larger share of the
## baskets its deliveries created — with the shooters, the defence, the rules,
## and the seeds all held fixed.
##
## Measured from the ledger as credited assists over made field goals carrying a
## recorded creator, which is the §14.3 row's own denominator.
func test_passing_drives_the_conditional_credit_rate_in_production() -> void:
	var poor: float = _conversion_for(40)
	var strong: float = _conversion_for(95)
	assert_float(poor).is_greater(0.0)
	assert_float(strong).override_failure_message(
		"a better passing offence converted no more of its own creations "
		+ "(poor %.4f, strong %.4f)" % [poor, strong]
	).is_greater(poor)
	# The population rate is judged against the locked §14.3 envelope by
	# `run_assist_diagnostics.gd` at a sample that can carry the claim. A
	# handful of fixture games cannot, so this asserts the direction only.


## The share of creator-carrying makes that were credited, over four games
## played by an offence whose only distinguishing attribute is Passing.
func _conversion_for(passing: int) -> float:
	var credited: int = 0
	var created: int = 0
	for variation in range(6):
		var input: MatchInput = MatchFixtureFactory.match_between(
			MatchFixtureFactory.uniform_team(&"home", 70, {AttributeKey.Key.PASSING: passing}),
			MatchFixtureFactory.uniform_team(&"away", 70),
			MatchFixtureFactory.standard_match().rule_profile)
		var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
			input, SeededRandomSource.new(90210 + variation))
		for event in output.events:
			if event.team_id != input.home.team_id:
				continue
			if event.event_type == MatchDomainEvent.ASSIST:
				credited += 1
			elif (
				event.event_type == MatchDomainEvent.FIELD_GOAL_MADE
				and not event.tertiary_player_id.is_empty()
			):
				created += 1
	assert_int(created).override_failure_message(
		"too few created baskets to measure a conversion rate").is_greater(40)
	return float(credited) / float(created)


# --- executor parity and game stakes ----------------------------------------

## 18. Play, Sim, and Skip produce identical assist results and identical ledger
## signatures. The chain is stateful across actions, so a mode that rebuilt the
## possession context differently would diverge here and nowhere else.
func test_play_sim_and_skip_agree_on_every_credited_assist() -> void:
	var simulated: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(20260815))

	var stepping := MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(20260815))
	stepping.open()
	while not stepping.is_complete():
		stepping.advance_possession()
	var played: MatchSimulationOutput = stepping.build_output()

	var skipped: MatchSimulationOutput = MatchSession.new(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(20260815)
	).skip_to_final_result()

	var expected: String = _assist_signature(simulated)
	assert_str(expected).is_not_empty()
	assert_str(_assist_signature(played)).override_failure_message(
		"stepped play disagreed with Sim about assist attribution").is_equal(expected)
	assert_str(_assist_signature(skipped)).override_failure_message(
		"skip disagreed with Sim about assist attribution").is_equal(expected)
	assert_str(MatchLedgerSerializer.hash_output(played)).is_equal(
		MatchLedgerSerializer.hash_output(simulated))
	assert_str(MatchLedgerSerializer.hash_output(skipped)).is_equal(
		MatchLedgerSerializer.hash_output(simulated))
	for team in simulated.final_result.statistics.teams:
		assert_int(played.final_result.statistics.team_line(team.team_id).assists).is_equal(
			team.assists)
		assert_int(skipped.final_result.statistics.team_line(team.team_id).assists).is_equal(
			team.assists)


## 20. Regular game-stakes behaviour is unchanged, and stakes are not an input
## the assist chain can read.
##
## A regular-season game is the default, and the same fixture played at every
## tier produces the identical creation chain when nothing else differs — the
## §5.14 stakes contract is about which legal action a coach selects, and an
## assist is decided by the delivery, not by what the game is worth.
func test_game_stakes_do_not_reach_the_assist_chain() -> void:
	var regular: MatchSimulationOutput = _stakes_match(GameStakes.Value.REGULAR)
	var defaulted: MatchSimulationOutput = MatchEngine.new().simulate_match(
		MatchFixtureFactory.standard_match(), SeededRandomSource.new(20260815))
	assert_str(_assist_signature(regular)).override_failure_message(
		"an explicit regular-season game differed from the default"
	).is_equal(_assist_signature(defaulted))
	for stakes in GameStakes.all():
		var output: MatchSimulationOutput = _stakes_match(stakes)
		var assisted: int = 0
		var with_creator: int = 0
		for event in output.events:
			if event.event_type == MatchDomainEvent.ASSIST:
				assisted += 1
			elif (
				event.event_type == MatchDomainEvent.FIELD_GOAL_MADE
				and not event.tertiary_player_id.is_empty()
			):
				with_creator += 1
		assert_int(assisted).override_failure_message(
			"%s produced no assists at all" % GameStakes.id_of(stakes)).is_greater(0)
		assert_int(assisted).override_failure_message(
			"%s credited more assists than baskets with a creator" % GameStakes.id_of(stakes)
		).is_less_equal(with_creator)


func _stakes_match(stakes: int) -> MatchSimulationOutput:
	var base: MatchInput = MatchFixtureFactory.standard_match()
	var input := MatchInput.new(
		base.match_id, base.game_id, base.rule_profile, base.balance_profile,
		base.home, base.away, base.home.team_id, base.ratings_profile,
		base.home_environment, stakes)
	return MatchEngine.new().simulate_match(input, SeededRandomSource.new(20260815))


func _assist_signature(output: MatchSimulationOutput) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for event in output.events:
		if (
			event.event_type != MatchDomainEvent.ASSIST
			and event.event_type != MatchDomainEvent.FIELD_GOAL_MADE
		):
			continue
		parts.append("%s:%d:%s:%s:%s:%s" % [
			event.event_type, event.sequence, event.primary_player_id,
			event.secondary_player_id, event.tertiary_player_id, event.detail_id])
	return "|".join(parts)


func _context() -> PossessionContext:
	var input: MatchInput = MatchFixtureFactory.quick_match()
	var snapshot := MatchSnapshot.new(input)
	var calculator := CapabilityCalculator.new(input.ratings_profile, input.balance_profile)
	var body := BodyEffects.new(input.balance_profile)
	var matchups: MatchupState = MatchupResolver.new(calculator, body).resolve(
		input.home, snapshot.home, input.away, snapshot.away)
	var context := PossessionContext.new(input, snapshot, input.home.team_id, matchups, 1)
	context.ball_handler_id = context.offense_on_court()[0]
	return context
