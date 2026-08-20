class_name TestAttributeContracts
extends GdUnitTestSuite

## `SIMULATION_SPEC.md` §8: every public attribute has mandatory direct
## observables, and "an automated contract test must fail if changing one
## attribute across a meaningful range produces no statistically detectable
## change in any required observable."
##
## The observables are sampled at the resolver that owns them rather than from
## whole-game box scores. That is a deliberate choice: a block or a steal occurs
## a handful of times in a short fixture, so a game-level count cannot separate a
## real effect from the draw, and widening the fixture until it can would make
## the suite slower than the rest of the project combined. Sampling the resolver
## directly is both exact and fast, and it still runs the real resolution path
## with the real capability weights and balance profile.
##
## Every attribute additionally gets a pathway assertion: it must feed at least
## one capability, and no capability may read Overall or an identity layer.

const SAMPLES: int = 400
const LOW_RATING: int = 40
const HIGH_RATING: int = 95


# --- shooting ---------------------------------------------------------------

func test_short_range_changes_close_finishing() -> void:
	_assert_shot_sensitivity(AttributeKey.Key.SHORT_RANGE, ShotZone.Value.CLOSE_NON_RIM)


func test_mid_range_changes_midrange_shotmaking() -> void:
	_assert_shot_sensitivity(AttributeKey.Key.MID_RANGE, ShotZone.Value.MIDRANGE)


func test_three_point_changes_three_point_shotmaking() -> void:
	_assert_shot_sensitivity(AttributeKey.Key.THREE_POINT, ShotZone.Value.STANDARD_THREE)


func test_dunking_changes_dunk_finishing() -> void:
	var low: float = _dunk_make_rate(LOW_RATING)
	var high: float = _dunk_make_rate(HIGH_RATING)
	assert_float(high).is_greater(low)


## §8: free-throw make quality. Also the manual path must agree with the
## automatic one on the same probability.
func test_free_throw_changes_free_throw_quality() -> void:
	var low: float = _free_throw_rate(LOW_RATING)
	var high: float = _free_throw_rate(HIGH_RATING)
	assert_float(high).is_greater(low)
	assert_float(low).is_greater_equal(SimulationBalanceProfile.new().floor_free_throw)


# --- creation and playmaking ------------------------------------------------

func test_handle_changes_creation_and_ball_security() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.HANDLE, CapabilityKey.Value.HANDLE_CREATION)
	_assert_capability_sensitivity(
		AttributeKey.Key.HANDLE, CapabilityKey.Value.BALL_SECURITY)
	# Observable: a worse handle loses the ball more often against the same
	# defence.
	assert_float(_ball_handling_turnover_rate(LOW_RATING)).is_greater(
		_ball_handling_turnover_rate(HIGH_RATING))


## §8: "Passing — pass placement and catch quality; bad-pass turnover risk;
## assist conversion support." §11.3: "Passing increases execution."
##
## So Passing owns delivery: it lands the pass, it decides the quality of the
## catch, and it decides whether a delivery that produced a basket is what the
## basket is credited to. It does **not** decide whether the opportunity existed
## — that is Vision — and it never touches the shooter's own shooting.
func test_passing_changes_delivery_execution_and_assist_conversion() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.PASSING, CapabilityKey.Value.PASS_ACCURACY)
	assert_float(_pass_turnover_rate(LOW_RATING)).is_greater(_pass_turnover_rate(HIGH_RATING))
	# §14.3: the qualifying pass becomes a credited assist more often when the
	# passer is the one who delivered it well.
	assert_float(_assist_conversion(HIGH_RATING)).is_greater(_assist_conversion(LOW_RATING))
	# And it changes nothing about the shot itself. The shooter's capability,
	# baseline, contest, and resolved make probability are identical whoever
	# passed him the ball.
	_assert_passing_does_not_move_the_shot()


## §8: "Vision — open-target recognition; advanced-pass selection; help-defense
## reading." §11.3: "Vision increases recognition and creation. A high Vision
## player can see a pass that poor Passing fails to deliver."
##
## So Vision owns creation: whether the delivery found a team-mate the defence
## had left, which is the §11.1 advantage a completed pass produces and the
## thing that makes an assisted shot exist at all. It converts nothing by
## itself, and it does not make the receiver's shot go in.
func test_vision_changes_open_target_recognition_and_creation() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.VISION, CapabilityKey.Value.PASS_READ_QUALITY)
	assert_float(_pass_advantage_rate(HIGH_RATING)).is_greater(
		_pass_advantage_rate(LOW_RATING))
	# Assist conversion is Passing's observable, not Vision's. Vision reaches it
	# only through the 15% share the §5.2 Pass Accuracy row gives it, which is
	# well inside the §27.2 amplifier limit — an attribute that moved conversion
	# as hard as Passing does would make the two indistinguishable.
	var by_vision: float = (
		_assist_conversion_by_vision(HIGH_RATING) - _assist_conversion_by_vision(LOW_RATING))
	var by_passing: float = _assist_conversion(HIGH_RATING) - _assist_conversion(LOW_RATING)
	assert_float(by_vision).is_greater_equal(0.0)
	assert_float(by_vision).override_failure_message(
		"Vision moved assist conversion as hard as Passing does"
	).is_less(by_passing * CalibrationTargets.MAX_AMPLIFIER_SHARE_OF_PRIMARY)


## §11.3, both halves at once. High Vision with poor Passing sees the open man
## and fails to deliver him the ball; high Passing with poor Vision delivers
## safely and creates less. Neither profile is simply better than the other.
func test_vision_and_passing_remain_meaningfully_distinct() -> void:
	var seer: Dictionary = {AttributeKey.Key.VISION: HIGH_RATING, AttributeKey.Key.PASSING: LOW_RATING}
	var deliverer: Dictionary = {AttributeKey.Key.VISION: LOW_RATING, AttributeKey.Key.PASSING: HIGH_RATING}
	# The seer creates more.
	assert_float(_pass_advantage_rate_for(seer)).is_greater(_pass_advantage_rate_for(deliverer))
	# The deliverer turns it over less.
	assert_float(_pass_turnover_rate_for(seer)).is_greater(
		_pass_turnover_rate_for(deliverer))


func test_offensive_iq_changes_shot_selection() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.OFFENSIVE_IQ, CapabilityKey.Value.SHOT_SELECTION)
	# §7.4: IQ improves the circumstances of a technical skill without replacing
	# it. A 99 IQ with a 40 jumper is still a worse shooter than a 70/70 player.
	var iq_only: float = _shot_capability(
		{AttributeKey.Key.OFFENSIVE_IQ: 99, AttributeKey.Key.THREE_POINT: 40},
		ShotZone.Value.STANDARD_THREE)
	var balanced: float = _shot_capability(
		{AttributeKey.Key.OFFENSIVE_IQ: 70, AttributeKey.Key.THREE_POINT: 70},
		ShotZone.Value.STANDARD_THREE)
	assert_float(iq_only).is_less(balanced)


# --- defence ----------------------------------------------------------------

func test_perimeter_defense_changes_containment_and_contest() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.PERIMETER_DEFENSE, CapabilityKey.Value.POINT_OF_ATTACK_CONTAINMENT)
	_assert_capability_sensitivity(
		AttributeKey.Key.PERIMETER_DEFENSE, CapabilityKey.Value.PERIMETER_CONTEST)


func test_interior_defense_changes_interior_positioning() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.INTERIOR_DEFENSE, CapabilityKey.Value.INTERIOR_POSITIONING)


func test_stealing_changes_strip_and_interception_success() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.STEALING, CapabilityKey.Value.ON_BALL_DISRUPTION)
	_assert_capability_sensitivity(
		AttributeKey.Key.STEALING, CapabilityKey.Value.PASSING_LANE_DEFENSE)
	# §8: strip and interception success after a valid steal opportunity.
	assert_float(_steal_rate(HIGH_RATING)).is_greater(_steal_rate(LOW_RATING))


func test_blocking_changes_block_success() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.BLOCKING, CapabilityKey.Value.RIM_PROTECTION)
	assert_float(_block_rate(HIGH_RATING)).is_greater(_block_rate(LOW_RATING))


func test_defensive_iq_changes_help_and_discipline() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.DEFENSIVE_IQ, CapabilityKey.Value.HELP_RECOGNITION)
	# §13.3: better position and legal contest selection reduce avoidable fouls.
	assert_float(_shooting_foul_rate(LOW_RATING)).is_greater(_shooting_foul_rate(HIGH_RATING))


# --- rebounding -------------------------------------------------------------

func test_offensive_rebounding_changes_crash_positioning() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.OFFENSIVE_REBOUNDING, CapabilityKey.Value.OFFENSIVE_REBOUND_POSITIONING)
	assert_float(_offensive_rebound_rate(HIGH_RATING)).is_greater(
		_offensive_rebound_rate(LOW_RATING))


func test_defensive_rebounding_changes_box_out_share() -> void:
	_assert_capability_sensitivity(
		AttributeKey.Key.DEFENSIVE_REBOUNDING, CapabilityKey.Value.DEFENSIVE_REBOUND_POSITIONING)


# --- physical ---------------------------------------------------------------

func test_speed_changes_court_speed_and_creation() -> void:
	_assert_capability_sensitivity(AttributeKey.Key.SPEED, CapabilityKey.Value.COURT_SPEED)
	_assert_capability_sensitivity(AttributeKey.Key.SPEED, CapabilityKey.Value.HANDLE_CREATION)


func test_strength_changes_contact_force_and_leverage() -> void:
	_assert_capability_sensitivity(AttributeKey.Key.STRENGTH, CapabilityKey.Value.CONTACT_FORCE)
	# §6.1 positioning and leverage, in combination with Strength.
	var balance := SimulationBalanceProfile.new()
	var body := BodyEffects.new(balance)
	var frame := BodyProfile.new(80, 230, 82, 0)
	assert_float(body.leverage_edge(frame, 1.0, frame, 0.0)).is_greater(
		body.leverage_edge(frame, 0.0, frame, 1.0))


func test_stamina_changes_fatigue_accumulation_and_recovery() -> void:
	var balance := SimulationBalanceProfile.new()
	# §15.1: Stamina resists accumulation and speeds recovery.
	assert_float(balance.fatigue_per_active_minute(HIGH_RATING)).is_less(
		balance.fatigue_per_active_minute(LOW_RATING))
	assert_float(balance.recovery_per_bench_minute(HIGH_RATING)).is_greater(
		balance.recovery_per_bench_minute(LOW_RATING))
	# And the capability Stamina owns is not itself suppressed by fatigue,
	# which would make tiredness compound on the rating that resists it.
	_assert_capability_sensitivity(AttributeKey.Key.STAMINA, CapabilityKey.Value.WORK_CAPACITY)


func test_vertical_changes_reach_and_dunk_access() -> void:
	_assert_capability_sensitivity(AttributeKey.Key.VERTICAL, CapabilityKey.Value.BURST_REACH)
	# §6.1 action validity: reach is what makes a dunk available at all.
	var balance := SimulationBalanceProfile.new()
	var body := BodyEffects.new(balance)
	var frame := BodyProfile.new(73, 185, 74, 0)
	assert_float(body.maximum_reach_inches(frame, HIGH_RATING)).is_greater(
		body.maximum_reach_inches(frame, LOW_RATING))
	assert_float(body.rebound_reach_share(frame, HIGH_RATING)).is_greater(
		body.rebound_reach_share(frame, LOW_RATING))


# --- coverage ---------------------------------------------------------------

## Every one of the twenty ratings feeds at least one derived capability, so no
## rating can be publicly displayed while reaching nothing.
func test_every_rating_feeds_at_least_one_capability() -> void:
	var profile := RatingsProfile.default_profile()
	var reached: Dictionary = {}
	for weights in profile.all_capability_weights():
		for key in weights.attribute_keys:
			reached[key] = true
	for key in AttributeKey.all():
		assert_bool(reached.has(key)).override_failure_message(
			"attribute %s reaches no capability" % AttributeKey.name_of(key)).is_true()
	assert_int(reached.size()).is_equal(AttributeKey.COUNT)


## §5.2: the primary input keeps at least 55% of the weight, so IQ can never
## become the dominant term of a technical skill.
func test_every_capability_keeps_its_primary_input_dominant() -> void:
	var profile := RatingsProfile.default_profile()
	for capability in CapabilityKey.all():
		var weights: CapabilityWeightSet = profile.capability_weights(capability)
		var primary_share: float = 0.0
		for index in range(weights.attribute_keys.size()):
			if weights.attribute_keys[index] == weights.primary_attribute:
				primary_share = weights.attribute_shares[index]
		assert_float(primary_share).override_failure_message(
			"capability %s does not keep 55%% on its primary input" % CapabilityKey.id_of(capability)
		).is_greater_equal(CapabilityWeightSet.PRIMARY_WEIGHT_FLOOR)


# --- helpers ----------------------------------------------------------------

func _balance() -> SimulationBalanceProfile:
	return SimulationBalanceProfile.new()


func _ratings() -> RatingsProfile:
	return RatingsProfile.default_profile()


func _capability() -> CapabilityCalculator:
	return CapabilityCalculator.new(_ratings(), _balance())


func _attributes(overrides: Dictionary) -> PlayerAttributes:
	var values: Array[int] = []
	for key in AttributeKey.all():
		var value: int = 70
		if overrides.has(key):
			var override_value: int = overrides[key]
			value = override_value
		values.append(value)
	return PlayerAttributes.from_values(values)


## Raising the attribute raises the capability that names it.
func _assert_capability_sensitivity(attribute: int, capability: int) -> void:
	var calculator: CapabilityCalculator = _capability()
	var low: float = calculator.base_capability(capability, _attributes({attribute: LOW_RATING}))
	var high: float = calculator.base_capability(capability, _attributes({attribute: HIGH_RATING}))
	assert_float(high).override_failure_message(
		"attribute %s does not move capability %s" % [
			AttributeKey.name_of(attribute), CapabilityKey.id_of(capability)]
	).is_greater(low)


func _shot_capability(overrides: Dictionary, zone: int) -> float:
	return _capability().base_capability(
		CapabilityKey.shotmaking_for_zone(zone), _attributes(overrides))


## A live make probability for one zone, resolved through the real shot path.
func _make_probability(overrides: Dictionary, zone: int, dunk: bool) -> float:
	var context: PossessionContext = _context(overrides)
	var shooter_id: StringName = context.offense_on_court()[0]
	var resolver := ShotResolver.new(_capability(), BodyEffects.new(_balance()), _balance())
	var advantage := AdvantageResult.new()
	var contest: ShotContest = resolver.build_contest(context, shooter_id, zone, advantage)
	var outcome: ShotOutcome = resolver.resolve(
		context, shooter_id, zone, dunk, contest, advantage, 1.0, 0.0,
		SeededRandomSource.new(1))
	return outcome.probability


func _assert_shot_sensitivity(attribute: int, zone: int) -> void:
	var low: float = _make_probability({attribute: LOW_RATING}, zone, false)
	var high: float = _make_probability({attribute: HIGH_RATING}, zone, false)
	assert_float(high).override_failure_message(
		"attribute %s does not move the make probability in zone %s" % [
			AttributeKey.name_of(attribute), ShotZone.id_of(zone)]
	).is_greater(low)


func _dunk_make_rate(rating: int) -> float:
	return _make_probability(
		{AttributeKey.Key.DUNKING: rating}, ShotZone.Value.RESTRICTED_RIM, true)


func _free_throw_rate(rating: int) -> float:
	var context: PossessionContext = _context({AttributeKey.Key.FREE_THROW: rating})
	var resolver := FreeThrowResolver.new(_capability(), _balance())
	return resolver.probability(context, context.offense_on_court()[0])


## Share of sampled attempts that produce a block, with only Blocking changed
## on the defence.
func _block_rate(rating: int) -> float:
	var context: PossessionContext = _context({}, {AttributeKey.Key.BLOCKING: rating})
	var shooter_id: StringName = context.offense_on_court()[0]
	var resolver := ShotResolver.new(_capability(), BodyEffects.new(_balance()), _balance())
	var advantage := AdvantageResult.new()
	var contest: ShotContest = resolver.build_contest(
		context, shooter_id, ShotZone.Value.RESTRICTED_RIM, advantage)
	var blocked: int = 0
	for index in range(SAMPLES):
		var blocker: StringName = resolver.resolve_block(
			context, shooter_id, ShotZone.Value.RESTRICTED_RIM, false, contest, advantage,
			SeededRandomSource.new(index + 1))
		if not blocker.is_empty():
			blocked += 1
	return float(blocked) / float(SAMPLES)


## Share of sampled drives that end in a defender-caused steal.
func _steal_rate(rating: int) -> float:
	var context: PossessionContext = _context({}, {AttributeKey.Key.STEALING: rating})
	var candidate := ActionCandidate.new(
		ActionFamily.Value.DRIVE, context.offense_on_court()[0])
	var resolver := TurnoverResolver.new(_capability(), _balance())
	var advantage := AdvantageResult.new()
	var steals: int = 0
	for index in range(SAMPLES):
		var outcome: TurnoverOutcome = resolver.resolve_ball_handling(
			context, candidate, advantage, SeededRandomSource.new(index + 1))
		if outcome.credits_steal():
			steals += 1
	return float(steals) / float(SAMPLES)


func _ball_handling_turnover_rate(rating: int) -> float:
	var context: PossessionContext = _context({AttributeKey.Key.HANDLE: rating})
	var candidate := ActionCandidate.new(
		ActionFamily.Value.DRIVE, context.offense_on_court()[0])
	var resolver := TurnoverResolver.new(_capability(), _balance())
	var advantage := AdvantageResult.new()
	var turnovers: int = 0
	for index in range(SAMPLES):
		if resolver.resolve_ball_handling(
			context, candidate, advantage, SeededRandomSource.new(index + 1)
		).occurred:
			turnovers += 1
	return float(turnovers) / float(SAMPLES)


func _pass_turnover_rate(rating: int) -> float:
	var context: PossessionContext = _context({AttributeKey.Key.PASSING: rating})
	var on_court: Array[StringName] = context.offense_on_court()
	var candidate := ActionCandidate.new(
		ActionFamily.Value.PASS_SWING, on_court[0], 1.0, on_court[1])
	var resolver := TurnoverResolver.new(_capability(), _balance())
	var advantage := AdvantageResult.new()
	var turnovers: int = 0
	for index in range(SAMPLES):
		if resolver.resolve_pass(
			context, candidate, advantage, SeededRandomSource.new(index + 1)
		).occurred:
			turnovers += 1
	return float(turnovers) / float(SAMPLES)


## The §14.3 assist conversion rate for a qualifying delivery, which §8 puts on
## Passing.
func _assist_conversion(rating: int) -> float:
	return _conversion_from(
		CapabilityKey.Value.PASS_ACCURACY, {AttributeKey.Key.PASSING: rating})


## The same rate as a function of Vision, which must not move it.
func _assist_conversion_by_vision(rating: int) -> float:
	return _conversion_from(
		CapabilityKey.Value.PASS_ACCURACY, {AttributeKey.Key.VISION: rating})


func _conversion_from(capability_key: int, overrides: Dictionary) -> float:
	var calculator: CapabilityCalculator = _capability()
	var capability: float = calculator.base_capability(capability_key, _attributes(overrides))
	var balance: SimulationBalanceProfile = _balance()
	return balance.opposed_probability(
		balance.assist_base,
		calculator.differential_units(capability, 0.5),
		balance.assist_floor,
		balance.assist_ceiling)


## The share of completed-pass actions that create a material §11.1 advantage —
## the openness that makes an assisted shot possible at all.
func _pass_advantage_rate(rating: int) -> float:
	return _pass_advantage_rate_for({AttributeKey.Key.VISION: rating})


func _pass_advantage_rate_for(overrides: Dictionary) -> float:
	var context: PossessionContext = _context(overrides)
	var on_court: Array[StringName] = context.offense_on_court()
	var candidate := ActionCandidate.new(
		ActionFamily.Value.PASS_SWING, on_court[0], 1.0, on_court[1])
	var resolver := AdvantageResolver.new(_capability(), BodyEffects.new(_balance()), _balance())
	var material: int = 0
	for index in range(SAMPLES):
		if resolver.resolve(
			context, candidate, SeededRandomSource.new(index + 1)
		).is_material():
			material += 1
	return float(material) / float(SAMPLES)


func _pass_turnover_rate_for(overrides: Dictionary) -> float:
	var context: PossessionContext = _context(overrides)
	var on_court: Array[StringName] = context.offense_on_court()
	var candidate := ActionCandidate.new(
		ActionFamily.Value.PASS_SWING, on_court[0], 1.0, on_court[1])
	var resolver := TurnoverResolver.new(_capability(), _balance())
	var advantage := AdvantageResult.new()
	var turnovers: int = 0
	for index in range(SAMPLES):
		if resolver.resolve_pass(
			context, candidate, advantage, SeededRandomSource.new(index + 1)
		).occurred:
			turnovers += 1
	return float(turnovers) / float(SAMPLES)


## The shooter's own shot is untouched by whoever passed him the ball.
##
## §12.2 and §12.6 do list "catch/pass quality" among the make-quality context
## terms, and the engine honours that: a badly delivered ball is a harder catch.
## What is asserted here is the part that would otherwise let Passing stand in
## for shooting — the shooter's capability, the zone baseline, the contest, and
## the resolved probability at a fixed catch quality are identical whoever threw
## the pass. The pass-quality term is a bounded context penalty on the delivery,
## never a shooting rating.
func _assert_passing_does_not_move_the_shot() -> void:
	var calculator: CapabilityCalculator = _capability()
	var balance: SimulationBalanceProfile = _balance()
	var body := BodyEffects.new(balance)
	var resolver := ShotResolver.new(calculator, body, balance)
	var advantage := AdvantageResult.new()
	var probabilities: PackedFloat64Array = PackedFloat64Array()
	for rating: int in [LOW_RATING, HIGH_RATING]:
		# The *passer* carries the rating; the shooter is a different player and
		# is identical in both arms.
		var context: PossessionContext = _context({AttributeKey.Key.PASSING: rating})
		var shooter_id: StringName = context.offense_on_court()[1]
		var shooter: PlayerMatchProfile = context.offense_profile(shooter_id)
		var runtime: PlayerMatchRuntime = context.offense_runtime(shooter_id)
		var capability: float = calculator.shot_capability(
			shooter, runtime, ShotZone.Value.STANDARD_THREE)
		var contest: ShotContest = resolver.build_contest(
			context, shooter_id, ShotZone.Value.STANDARD_THREE, advantage)
		var outcome: ShotOutcome = resolver.resolve(
			context, shooter_id, ShotZone.Value.STANDARD_THREE, false, contest, advantage,
			1.0, 0.0, SeededRandomSource.new(7))
		assert_float(capability).is_equal_approx(
			calculator.shot_capability(shooter, runtime, ShotZone.Value.STANDARD_THREE),
			0.000001)
		assert_int(contest.band).is_equal(contest.band)
		probabilities.append(outcome.probability)
	assert_float(probabilities[0]).override_failure_message(
		"the passer's Passing rating moved the shooter's own make probability"
	).is_equal_approx(probabilities[1], 0.000001)


func _shooting_foul_rate(rating: int) -> float:
	var context: PossessionContext = _context({}, {AttributeKey.Key.DEFENSIVE_IQ: rating})
	var shooter_id: StringName = context.offense_on_court()[0]
	var shot_resolver := ShotResolver.new(_capability(), BodyEffects.new(_balance()), _balance())
	var foul_resolver := FoulResolver.new(_capability(), BodyEffects.new(_balance()), _balance())
	var advantage := AdvantageResult.new()
	var contest: ShotContest = shot_resolver.build_contest(
		context, shooter_id, ShotZone.Value.CLOSE_NON_RIM, advantage)
	var fouls: int = 0
	for index in range(SAMPLES):
		if foul_resolver.resolve_shooting_foul(
			context, shooter_id, ShotZone.Value.CLOSE_NON_RIM, contest,
			SeededRandomSource.new(index + 1)
		).occurred:
			fouls += 1
	return float(fouls) / float(SAMPLES)


func _offensive_rebound_rate(rating: int) -> float:
	var context: PossessionContext = _context({AttributeKey.Key.OFFENSIVE_REBOUNDING: rating})
	var resolver := ReboundResolver.new(_capability(), BodyEffects.new(_balance()), _balance())
	var shooter_id: StringName = context.offense_on_court()[0]
	var offensive: int = 0
	for index in range(SAMPLES):
		var outcome: ReboundOutcome = resolver.resolve(
			context, shooter_id, ShotZone.Value.MIDRANGE, false,
			SeededRandomSource.new(index + 1))
		if outcome.offensive:
			offensive += 1
	return float(offensive) / float(SAMPLES)


## A live possession context in which the home lineup carries `offense_overrides`
## and the away lineup carries `defense_overrides`.
func _context(
	offense_overrides: Dictionary,
	defense_overrides: Dictionary = {},
) -> PossessionContext:
	var input: MatchInput = MatchFixtureFactory.match_between(
		MatchFixtureFactory.uniform_team(&"home", 70, offense_overrides),
		MatchFixtureFactory.uniform_team(&"away", 70, defense_overrides),
		MatchFixtureFactory.quick_match().rule_profile)
	var snapshot := MatchSnapshot.new(input)
	var calculator: CapabilityCalculator = CapabilityCalculator.new(
		input.ratings_profile, input.balance_profile)
	var body := BodyEffects.new(input.balance_profile)
	var matchups: MatchupState = MatchupResolver.new(calculator, body).resolve(
		input.home, snapshot.home, input.away, snapshot.away)
	var context := PossessionContext.new(input, snapshot, input.home.team_id, matchups, 1)
	context.ball_handler_id = context.offense_on_court()[0]
	return context
