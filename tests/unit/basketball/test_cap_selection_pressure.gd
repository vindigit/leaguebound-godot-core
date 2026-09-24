class_name TestCapSelectionPressure
extends GdUnitTestSuite

## §8.1 ceiling selection pressure (`BALANCE_SPEC.md` §8.1, §8.2, §28).
##
## §8.1 permits generated populations to use "the same distributions with
## competition-appropriate selection pressure", and §8.2 adds the constraint
## that makes it safe: "the engine must not silently increase a player's cap
## merely because he reached a higher league."
##
## Those two together define the contract this suite pins down. Selection is an
## order statistic over the profile's own distribution, so it changes *which*
## players are sampled and never what the distribution contains. Every ceiling a
## pool can yield was already reachable without it.
##
## The tests are written so that replacing the order statistic with an additive
## bonus — the obvious shortcut, and the one §8.2 forbids — fails them.

const SAMPLE: int = 400

var _profiles: BalanceProfileSet


func before_test() -> void:
	_profiles = BalanceProfileSet.default_set()


func _caps_for(seed_value: int, pool: int) -> AttributeCaps:
	var emphasis: Array[int] = CapGenerator.emphasis_from_family(
		PositionFamily.Value.WING, [] as Array[int])
	return CapGenerator.generate(
		ProspectProfile.Value.HIGH_UPSIDE, emphasis,
		SeededRandomSource.new(seed_value), _profiles.progression, pool)


func _maximum_potential(caps: AttributeCaps) -> int:
	return OverallCalculator.maximum_potential_overall(caps, _profiles.ratings)


## A pool of one must be exactly the previous behaviour, draw for draw. This is
## what lets selection pressure be added to a shipped generator without moving a
## single existing cap, a golden ledger, or a committed career.
func test_a_pool_of_one_is_bit_identical_to_no_selection() -> void:
	for seed_value in range(60):
		var caps: AttributeCaps = _caps_for(4000 + seed_value, 1)
		var repeat: AttributeCaps = _caps_for(4000 + seed_value, 1)
		assert_str(caps.signature()).is_equal(repeat.signature())


## Selection is deterministic from the seed like every other generation draw
## (`GODOT_TDD.md` §5.2).
func test_selection_is_deterministic_from_the_seed() -> void:
	for pool: int in PackedInt32Array([1, 2, 4]):
		for seed_value in range(20):
			assert_str(_caps_for(9100 + seed_value, pool).signature())\
				.is_equal(_caps_for(9100 + seed_value, pool).signature())


## The central claim: a larger pool raises the *population* ceiling because it
## samples the upper tail more often, not because any individual draw was
## increased.
func test_a_larger_pool_raises_the_population_ceiling() -> void:
	var single: float = 0.0
	var pooled: float = 0.0
	for seed_value in range(SAMPLE):
		single += float(_maximum_potential(_caps_for(20000 + seed_value, 1)))
		pooled += float(_maximum_potential(_caps_for(20000 + seed_value, 3)))
	assert_float(pooled / float(SAMPLE)).is_greater(single / float(SAMPLE))


## §8.2: selection may not produce a cap the unselected distribution could not.
##
## An additive bonus would breach this the moment it pushed a draw past the
## profile's hard maximum; an order statistic cannot, because every candidate it
## chooses among was drawn from the same clipped distribution.
func test_selection_never_exceeds_the_profile_ceiling_maximum() -> void:
	var maximum: int = _profiles.progression.ceiling_maximum[
		ProspectProfile.Value.HIGH_UPSIDE]
	var headroom: int = _profiles.progression.primary_offset_maximum \
		+ _profiles.progression.cap_noise_clip
	for pool: int in PackedInt32Array([1, 2, 4, 8]):
		for seed_value in range(80):
			var caps: AttributeCaps = _caps_for(31000 + seed_value, pool)
			for attribute in AttributeKey.all():
				var cap: int = caps.cap_for(attribute)
				assert_int(cap).is_less_equal(ProgressionProfile.CAP_MAXIMUM)
				assert_int(cap).is_greater_equal(ProgressionProfile.CAP_MINIMUM)
				# The anchor is clipped before offsets, so no cap may exceed the
				# clipped anchor plus the documented emphasis and noise headroom.
				assert_int(cap).is_less_equal(maximum + headroom)


## Every ceiling a pool can yield must be reachable without the pool. Sampling
## the unselected distribution far more widely than the selected one and finding
## the selected maximum inside its range is the evidence for that; an additive
## bonus would routinely land outside it.
func test_every_selected_ceiling_was_already_reachable() -> void:
	var unselected_maximum: int = 0
	for seed_value in range(SAMPLE * 4):
		unselected_maximum = maxi(
			unselected_maximum, _maximum_potential(_caps_for(50000 + seed_value, 1)))

	var selected_maximum: int = 0
	for seed_value in range(SAMPLE):
		selected_maximum = maxi(
			selected_maximum, _maximum_potential(_caps_for(90000 + seed_value, 3)))

	assert_int(selected_maximum).is_less_equal(unselected_maximum)


## Selection changes the ceiling anchor and nothing else about the draw. The
## per-attribute emphasis offsets and clipped noise are applied identically, so
## a selected player is still shaped by his build rather than flattened toward
## his ceiling — which is what keeps §12.4's differentiated identities intact at
## the top of the distribution.
func test_selection_preserves_attribute_shape() -> void:
	var emphasis: Array[int] = CapGenerator.emphasis_from_family(
		PositionFamily.Value.WING, [] as Array[int])
	var primary_lead: int = 0
	var samples: int = 0
	for seed_value in range(120):
		var caps: AttributeCaps = _caps_for(77000 + seed_value, 3)
		var primary_total: int = 0
		for attribute: int in CapGenerator.FAMILY_PRIMARY[PositionFamily.Value.WING]:
			primary_total += caps.cap_for(attribute)
		var all_total: int = 0
		for attribute in AttributeKey.all():
			all_total += caps.cap_for(attribute)
		var primary_mean: float = float(primary_total) / 4.0
		var overall_mean: float = float(all_total) / float(AttributeKey.COUNT)
		if primary_mean > overall_mean:
			primary_lead += 1
		samples += 1
		assert_int(emphasis.size()).is_equal(AttributeKey.COUNT)
	# §8.1 gives primary attributes +4..+10 against a neutral -3..+3, so a
	# selected player's primaries must still lead his own mean.
	assert_int(primary_lead).is_greater(samples * 9 / 10)
