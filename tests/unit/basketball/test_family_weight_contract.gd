class_name TestFamilyWeightContract
extends GdUnitTestSuite

## The family-to-attribute allocation contract, proved for every declared
## family rather than for a representative one.
##
## §5.24 repaired `CareerSimulator._family_weights`, which iterated
## `AttributeEmphasis` *values* as if they were `AttributeKey` *indices*. The
## levels are PRIMARY 0, SECONDARY 1 and NEUTRAL 2, so every family weighted
## canonical indices 0, 1 and 2 — `short_range`, `dunking`, `mid_range` — at 1.0
## and left everything it actually declared at the neutral baseline. Three
## families produced one weight vector between them.
##
## The defect survived because nothing asserted the *identity* half of the
## contract: that a family emphasizes the attributes it declares and no others.
## This suite asserts it exhaustively — every family, every canonical
## attribute — so the same class of mistake cannot return silently.
##
## Nothing here simulates a match, consumes a match random stream, or reads a
## competition. The allocation contract is competition-independent by
## construction and `test_the_repair_introduces_no_competition_specific_behaviour`
## pins that.

## This suite owns 1,320,001-1,320,999, disjoint from every diagnosis, tuning
## and validation range recorded in `PROJECT_STATUS.md`.
const SUITE_SEED: int = 1320001

const TOLERANCE: float = 0.000001

## The trio the defect collapsed every family onto. Named so the regression test
## below can say what it is guarding against.
const DEFECT_TRIO: Array[int] = [
	AttributeKey.Key.SHORT_RANGE, AttributeKey.Key.DUNKING, AttributeKey.Key.MID_RANGE,
]


func _declared_primary(family: int) -> Array[int]:
	var declared: Array[int] = []
	for attribute: int in CapGenerator.FAMILY_PRIMARY[family]:
		declared.append(attribute)
	return declared


func _declared_secondary(family: int) -> Array[int]:
	var declared: Array[int] = []
	for attribute: int in CapGenerator.FAMILY_SECONDARY[family]:
		declared.append(attribute)
	return declared


func _declared(family: int) -> Array[int]:
	var declared: Array[int] = _declared_primary(family)
	declared.append_array(_declared_secondary(family))
	return declared


func _where(family: int) -> String:
	return "family %s" % PositionFamily.id_of(family)


# --- 1. every declared attribute receives its intended weight -----------------


## Each family's declared primaries carry the primary weight and its declared
## secondaries carry the secondary weight — for every family, not a sample.
func test_every_declared_attribute_receives_its_declared_tier_weight() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		for attribute in _declared_primary(family):
			assert_float(weights[attribute]).override_failure_message(
				"%s: primary %s" % [_where(family), AttributeKey.name_of(attribute)]
			).is_equal_approx(CareerSimulator.PRIMARY_WEIGHT, TOLERANCE)
		for attribute in _declared_secondary(family):
			assert_float(weights[attribute]).override_failure_message(
				"%s: secondary %s" % [_where(family), AttributeKey.name_of(attribute)]
			).is_equal_approx(CareerSimulator.SECONDARY_WEIGHT, TOLERANCE)


## The tiers are strictly ordered, so "primary" outranks "secondary" outranks
## "neutral" rather than three names for the same number.
func test_the_three_tiers_are_strictly_ordered() -> void:
	assert_float(CareerSimulator.PRIMARY_WEIGHT).is_greater(CareerSimulator.SECONDARY_WEIGHT)
	assert_float(CareerSimulator.SECONDARY_WEIGHT).is_greater(CareerSimulator.NEUTRAL_WEIGHT)
	assert_float(CareerSimulator.NEUTRAL_WEIGHT).is_greater(0.0)


# --- 2. no undeclared attribute receives a family-specific weight -------------


## Everything a family does not declare sits at the neutral baseline. This is
## the assertion the defect would have failed: it is what says `dunking` cannot
## be weighted for a Guard.
func test_no_undeclared_attribute_receives_a_family_specific_weight() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		var declared: Array[int] = _declared(family)
		for attribute in AttributeKey.all():
			if declared.has(attribute):
				continue
			assert_float(weights[attribute]).override_failure_message(
				"%s: undeclared %s carries a family weight"
				% [_where(family), AttributeKey.name_of(attribute)]
			).is_equal_approx(CareerSimulator.NEUTRAL_WEIGHT, TOLERANCE)


## Exactly as many attributes sit above the baseline as the family declared.
func test_the_number_of_emphasized_attributes_matches_the_declaration() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		var above: int = 0
		for attribute in AttributeKey.all():
			if weights[attribute] > CareerSimulator.NEUTRAL_WEIGHT:
				above += 1
		assert_int(above).override_failure_message(_where(family)) \
			.is_equal(_declared(family).size())


# --- 3. the top-weighted attributes match the family definition ---------------


## The heaviest weights in a family's vector are exactly its declared primaries.
func test_the_top_weighted_attributes_are_exactly_the_declared_primaries() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		var primary: Array[int] = _declared_primary(family)
		var top: Array[int] = _top_weighted(weights, primary.size())
		top.sort()
		var expected: Array[int] = primary.duplicate()
		expected.sort()
		assert_array(top).override_failure_message(
			"%s: top %d weights" % [_where(family), primary.size()]).is_equal(expected)


# --- 4. weight totals normalize correctly ------------------------------------


## The vector's total is exactly what the declaration implies: four primaries,
## four secondaries, and the rest at the baseline. A tier that silently changed
## magnitude, or an attribute counted twice, moves this.
func test_the_weight_total_is_exactly_what_the_declaration_implies() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		var primary_count: int = _declared_primary(family).size()
		var secondary_count: int = _declared_secondary(family).size()
		var neutral_count: int = AttributeKey.COUNT - primary_count - secondary_count
		var expected: float = (
			float(primary_count) * CareerSimulator.PRIMARY_WEIGHT
			+ float(secondary_count) * CareerSimulator.SECONDARY_WEIGHT
			+ float(neutral_count) * CareerSimulator.NEUTRAL_WEIGHT)
		var total: float = 0.0
		for attribute in AttributeKey.all():
			total += weights[attribute]
		assert_float(total).override_failure_message(_where(family)) \
			.is_equal_approx(expected, TOLERANCE)


## One weight per canonical attribute, every one of them positive. A zero weight
## would make an attribute unreachable by weighted spending rather than merely
## unemphasized.
func test_every_family_produces_one_positive_weight_per_canonical_attribute() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		assert_int(weights.size()).override_failure_message(_where(family)) \
			.is_equal(AttributeKey.COUNT)
		for attribute in AttributeKey.all():
			assert_float(weights[attribute]).override_failure_message(
				"%s: %s" % [_where(family), AttributeKey.name_of(attribute)]
			).is_greater(0.0)


# --- 5. canonical keys resolve to the correct index ---------------------------


## The emphasis vector and the weight vector are both indexed by canonical
## attribute, and entry *i* of one governs entry *i* of the other. This is the
## exact identity the defect broke, asserted position by position.
func test_each_canonical_index_maps_its_own_emphasis_to_its_own_weight() -> void:
	for family in PositionFamily.all():
		var emphasis: Array[int] = CapGenerator.emphasis_from_family(
			family, [] as Array[int])
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		assert_int(emphasis.size()).is_equal(AttributeKey.COUNT)
		for attribute in AttributeKey.all():
			var expected: float = _expected_weight_for(emphasis[attribute])
			assert_float(weights[attribute]).override_failure_message(
				"%s: canonical index %d (%s) carries emphasis %s"
				% [_where(family), attribute, AttributeKey.name_of(attribute),
					AttributeEmphasis.id_of(emphasis[attribute])]
			).is_equal_approx(expected, TOLERANCE)


## An emphasis vector built by hand resolves the attribute it names and no
## neighbour. Proved on a single-attribute vector so a one-index shift, which is
## precisely how the defect read, cannot pass.
func test_a_single_emphasized_attribute_moves_only_its_own_weight() -> void:
	for attribute in AttributeKey.all():
		var emphasis: Array[int] = _all_neutral()
		emphasis[attribute] = AttributeEmphasis.Value.PRIMARY
		var weights: Array[float] = CareerSimulator.weights_for_emphasis(emphasis)
		for other in AttributeKey.all():
			var expected: float = (
				CareerSimulator.PRIMARY_WEIGHT if other == attribute
				else CareerSimulator.NEUTRAL_WEIGHT)
			assert_float(weights[other]).override_failure_message(
				"emphasizing %s moved %s" % [
					AttributeKey.name_of(attribute), AttributeKey.name_of(other)]
			).is_equal_approx(expected, TOLERANCE)


## An emphasis *level* is not an attribute index. Feeding a vector whose only
## PRIMARY sits at a high canonical index must weight that index — the defect
## would have weighted index 0 instead, because 0 is what PRIMARY equals.
func test_an_emphasis_level_is_never_read_as_an_attribute_index() -> void:
	var emphasis: Array[int] = _all_neutral()
	emphasis[AttributeKey.Key.VERTICAL] = AttributeEmphasis.Value.PRIMARY
	var weights: Array[float] = CareerSimulator.weights_for_emphasis(emphasis)
	assert_float(weights[AttributeKey.Key.VERTICAL]) \
		.is_equal_approx(CareerSimulator.PRIMARY_WEIGHT, TOLERANCE)
	# PRIMARY is 0 and SHORT_RANGE is 0. They are not the same thing.
	assert_int(AttributeEmphasis.Value.PRIMARY).is_equal(int(AttributeKey.Key.SHORT_RANGE))
	assert_float(weights[AttributeKey.Key.SHORT_RANGE]) \
		.is_equal_approx(CareerSimulator.NEUTRAL_WEIGHT, TOLERANCE)


# --- 6/7. declaration and insertion order cannot reach the output -------------


## Reversing the order a family declares its attributes in changes no weight.
## Ownership is by canonical key, so declaration order is presentation only.
func test_declaration_order_does_not_change_semantic_ownership() -> void:
	for family in PositionFamily.all():
		var expected: Array[float] = CareerSimulator.family_allocation_weights(family)
		var emphasis: Array[int] = _all_neutral()
		var primary: Array[int] = _declared_primary(family)
		var secondary: Array[int] = _declared_secondary(family)
		primary.reverse()
		secondary.reverse()
		# Secondary first, then primary, mirroring the catalog's own precedence.
		for attribute in secondary:
			emphasis[attribute] = AttributeEmphasis.Value.SECONDARY
		for attribute in primary:
			emphasis[attribute] = AttributeEmphasis.Value.PRIMARY
		assert_array(CareerSimulator.weights_for_emphasis(emphasis)) \
			.override_failure_message(_where(family)).is_equal(expected)


## Routing the same declaration through a Dictionary, inserted in reverse
## canonical order, produces the same vector. Godot dictionaries preserve
## insertion order, so this would differ if any part of the resolution walked a
## collection instead of the canonical index.
func test_dictionary_insertion_order_does_not_change_the_output() -> void:
	for family in PositionFamily.all():
		var expected: Array[float] = CareerSimulator.family_allocation_weights(family)
		var reversed_declaration: Dictionary = {}
		var declared: Array[int] = _declared(family)
		declared.reverse()
		for attribute in declared:
			reversed_declaration[attribute] = (
				AttributeEmphasis.Value.PRIMARY
				if _declared_primary(family).has(attribute)
				else AttributeEmphasis.Value.SECONDARY)
		var emphasis: Array[int] = _all_neutral()
		for key: int in reversed_declaration:
			var level: int = reversed_declaration[key]
			emphasis[key] = level
		assert_array(CareerSimulator.weights_for_emphasis(emphasis)) \
			.override_failure_message(_where(family)).is_equal(expected)


# --- 8/9/10. malformed catalogs and vectors fail loudly ----------------------


## The committed catalog is well-formed. Everything below deliberately breaks a
## copy of it, so this establishes the baseline the breakages move away from.
func test_the_committed_family_catalog_is_well_formed() -> void:
	assert_array(CapGenerator.family_catalog_failures()).is_empty()


## A family that declares the same attribute in both tiers is reported by name.
## Without this the secondary declaration is silently overwritten by the primary
## one and the family quietly emphasizes seven attributes instead of eight.
func test_a_duplicate_family_declaration_fails_loudly() -> void:
	var primary: Array[Array] = _copy_catalog(CapGenerator.FAMILY_PRIMARY)
	var secondary: Array[Array] = _copy_catalog(CapGenerator.FAMILY_SECONDARY)
	# The Guard already declares HANDLE primary; declare it secondary as well.
	secondary[PositionFamily.Value.GUARD][0] = AttributeKey.Key.HANDLE
	var failures: PackedStringArray = CapGenerator.family_catalog_failures(
		primary, secondary, CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES)
	assert_array(failures).is_not_empty()
	assert_str("\n".join(failures)).contains("declares handle more than once")


## An attribute key outside the canonical range is reported rather than used to
## index a weight vector.
func test_an_unknown_attribute_key_fails_loudly() -> void:
	var primary: Array[Array] = _copy_catalog(CapGenerator.FAMILY_PRIMARY)
	var secondary: Array[Array] = _copy_catalog(CapGenerator.FAMILY_SECONDARY)
	primary[PositionFamily.Value.WING][0] = AttributeKey.COUNT + 7
	var failures: PackedStringArray = CapGenerator.family_catalog_failures(
		primary, secondary, CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES)
	assert_array(failures).is_not_empty()
	assert_str("\n".join(failures)).contains("unknown attribute key %d" % (AttributeKey.COUNT + 7))


## An attribute that falls out of every family without being declared neutral is
## reported. This is the check that stops a silent coverage regression.
func test_an_undeclared_coverage_gap_fails_loudly() -> void:
	var primary: Array[Array] = _copy_catalog(CapGenerator.FAMILY_PRIMARY)
	var secondary: Array[Array] = _copy_catalog(CapGenerator.FAMILY_SECONDARY)
	# STEALING is emphasized only by the Guard's secondary tier. Drop it.
	secondary[PositionFamily.Value.GUARD][3] = AttributeKey.Key.PASSING
	var failures: PackedStringArray = CapGenerator.family_catalog_failures(
		primary, secondary, CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES)
	assert_array(failures).is_not_empty()
	assert_str("\n".join(failures)).contains(
		"stealing is emphasized by no family and is not declared family-neutral")


## An attribute declared family-neutral while a family still emphasizes it is
## reported, so the neutral list cannot drift out of agreement with the catalog.
func test_a_neutral_declaration_that_contradicts_the_catalog_fails_loudly() -> void:
	var neutral: Array[int] = CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES.duplicate()
	neutral.append(AttributeKey.Key.BLOCKING)
	var failures: PackedStringArray = CapGenerator.family_catalog_failures(
		CapGenerator.FAMILY_PRIMARY, CapGenerator.FAMILY_SECONDARY, neutral)
	assert_array(failures).is_not_empty()
	assert_str("\n".join(failures)).contains(
		"blocking is declared family-neutral but is emphasized by a family")


## A malformed emphasis vector — one that carries a level with no defined
## allocation weight — halts rather than resolving to something plausible.
## INCOMPATIBLE is the reachable case: it is a real §8.1 level that the cap draw
## uses and that creation-time spending deliberately has no weight for.
func test_an_emphasis_level_with_no_defined_weight_fails_loudly() -> void:
	var emphasis: Array[int] = _all_neutral()
	emphasis[AttributeKey.Key.BLOCKING] = AttributeEmphasis.Value.INCOMPATIBLE
	await assert_error(func() -> void:
		CareerSimulator.weights_for_emphasis(emphasis)
	).is_runtime_error(
		"Assertion failed: no creation-time allocation weight is defined for emphasis %d"
		% AttributeEmphasis.Value.INCOMPATIBLE)


## A vector of the wrong length halts rather than being padded or truncated.
func test_a_wrongly_sized_emphasis_vector_fails_loudly() -> void:
	var emphasis: Array[int] = _all_neutral()
	emphasis.remove_at(0)
	await assert_error(func() -> void:
		CareerSimulator.weights_for_emphasis(emphasis)
	).is_runtime_error(
		"Assertion failed: one emphasis value per canonical attribute is required")


## An unknown family halts rather than indexing past the catalog.
func test_an_unknown_family_fails_loudly() -> void:
	await assert_error(func() -> void:
		CareerSimulator.family_allocation_weights(PositionFamily.COUNT)
	).is_runtime_error("Assertion failed: unknown position family")


# --- 11. determinism ----------------------------------------------------------


## The weight vector is a pure function of the family.
func test_the_weight_vector_is_a_pure_function_of_the_family() -> void:
	for family in PositionFamily.all():
		var first: Array[float] = CareerSimulator.family_allocation_weights(family)
		var second: Array[float] = CareerSimulator.family_allocation_weights(family)
		assert_array(second).override_failure_message(_where(family)).is_equal(first)


## The same seed and the same family produce byte-identical builder output.
func test_the_same_seed_and_family_reproduce_the_builder_exactly() -> void:
	for family in PositionFamily.all():
		var first: BuilderState = _build(family, SUITE_SEED + family)
		var second: BuilderState = _build(family, SUITE_SEED + family)
		assert_str(second.attributes().signature()).override_failure_message(
			_where(family)).is_equal(first.attributes().signature())
		assert_str(second.caps.signature()).override_failure_message(
			_where(family)).is_equal(first.caps.signature())


# --- 12. families with different declarations build differently ---------------


## No two families share a weight vector, and each family invests most heavily
## in its own declared primaries. Under the defect all three vectors were
## identical, so this is the assertion that would have caught it first.
func test_families_that_declare_differently_weight_and_build_differently() -> void:
	var vectors: Array[Array] = []
	for family in PositionFamily.all():
		vectors.append(CareerSimulator.family_allocation_weights(family))
	for left in range(PositionFamily.COUNT):
		for right in range(left + 1, PositionFamily.COUNT):
			assert_array(vectors[left]).override_failure_message(
				"%s and %s produced the same weight vector" % [
					PositionFamily.id_of(left), PositionFamily.id_of(right)]
			).is_not_equal(vectors[right])


## A family's own declared primaries end up meaningfully higher than the same
## attributes do in a family that does not declare them. This is the behavioural
## half of the contract: the weights reach the built player, not just the array.
func test_a_families_primaries_outrank_the_same_attributes_elsewhere() -> void:
	var built: Array[Array] = []
	for family in PositionFamily.all():
		built.append(_build(family, SUITE_SEED + 100 + family).values())
	for family in PositionFamily.all():
		var mine: Array = built[family]
		for attribute in _declared_primary(family):
			for other in PositionFamily.all():
				if other == family or _declared(other).has(attribute):
					continue
				var theirs: Array = built[other]
				var mine_value: int = mine[attribute]
				var theirs_value: int = theirs[attribute]
				assert_int(mine_value).override_failure_message(
					"%s declares %s primary but built it to %d, against %d for %s"
					% [PositionFamily.id_of(family), AttributeKey.name_of(attribute),
						mine_value, theirs_value, PositionFamily.id_of(other)]
				).is_greater(theirs_value)


# --- 13. the defect cannot return ---------------------------------------------


## No family may weight the old universal trio above its baseline unless it
## actually declares those attributes. The Wing declares `short_range` primary
## and `mid_range` secondary and the Big declares `short_range` and `dunking`
## secondary, so this is not "the trio is always neutral" — it is "the trio is
## emphasized exactly where it is declared and nowhere else".
func test_no_family_collapses_onto_the_old_universal_trio() -> void:
	for family in PositionFamily.all():
		var weights: Array[float] = CareerSimulator.family_allocation_weights(family)
		var declared: Array[int] = _declared(family)
		var emphasized_trio: int = 0
		for attribute in DEFECT_TRIO:
			if weights[attribute] > CareerSimulator.NEUTRAL_WEIGHT:
				emphasized_trio += 1
				assert_bool(declared.has(attribute)).override_failure_message(
					"%s emphasizes %s without declaring it"
					% [_where(family), AttributeKey.name_of(attribute)]
				).is_true()
		assert_int(emphasized_trio).override_failure_message(
			"%s emphasizes the whole defect trio" % _where(family)
		).is_less(DEFECT_TRIO.size())


## The Guard is the sharpest witness: under the defect it weighted all three of
## the trio at 1.0 and its own four primaries at the baseline. It declares none
## of the trio, so all three must sit at the baseline now.
func test_the_guard_emphasizes_none_of_the_defect_trio() -> void:
	var weights: Array[float] = CareerSimulator.family_allocation_weights(
		PositionFamily.Value.GUARD)
	for attribute in DEFECT_TRIO:
		assert_float(weights[attribute]).override_failure_message(
			"guard weights %s" % AttributeKey.name_of(attribute)
		).is_equal_approx(CareerSimulator.NEUTRAL_WEIGHT, TOLERANCE)
	assert_float(weights[AttributeKey.Key.THREE_POINT]) \
		.is_equal_approx(CareerSimulator.PRIMARY_WEIGHT, TOLERANCE)


# --- global coverage ----------------------------------------------------------


## Every canonical attribute is either emphasized by at least one family or is
## declared intentionally family-neutral. The catalog validator owns the rule;
## this states the resulting partition so a reader can see what it is.
func test_every_canonical_attribute_is_emphasized_or_declared_neutral() -> void:
	var emphasized: Dictionary = {}
	for family in PositionFamily.all():
		for attribute in _declared(family):
			emphasized[attribute] = true
	for attribute in AttributeKey.all():
		var is_emphasized: bool = emphasized.has(attribute)
		var is_neutral: bool = CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES.has(attribute)
		assert_bool(is_emphasized or is_neutral).override_failure_message(
			"%s is neither emphasized by a family nor declared family-neutral"
			% AttributeKey.name_of(attribute)).is_true()
		assert_bool(is_emphasized and is_neutral).override_failure_message(
			"%s is both emphasized and declared family-neutral"
			% AttributeKey.name_of(attribute)).is_false()


## The declared-neutral set is exactly the three attributes §8.1 leaves to every
## build. Pinned by name so growing it is a deliberate edit with a review, not a
## side effect of moving an attribute out of a family.
func test_the_declared_neutral_set_is_exactly_the_documented_three() -> void:
	var expected: Array[int] = [
		AttributeKey.Key.FREE_THROW, AttributeKey.Key.DEFENSIVE_IQ, AttributeKey.Key.STAMINA,
	]
	var actual: Array[int] = CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES.duplicate()
	actual.sort()
	expected.sort()
	assert_array(actual).is_equal(expected)


# --- scope --------------------------------------------------------------------


## The allocation weights are a function of the family catalog alone.
##
## Asserted against a vector rebuilt here from `FAMILY_PRIMARY` and
## `FAMILY_SECONDARY` directly, so any term the production function adds from
## anywhere else — a competition, a rule profile, a venue, a balance profile —
## makes the two disagree. Each competition's rule and balance profiles are
## resolved between the calls so that competition state is genuinely live when
## the weights are taken, rather than merely named in a loop.
func test_the_repair_introduces_no_competition_specific_behaviour() -> void:
	for family in PositionFamily.all():
		var expected: Array[float] = _weights_from_catalog(family)
		assert_array(CareerSimulator.family_allocation_weights(family)) \
			.override_failure_message(
				"%s does not match a vector rebuilt from the catalog alone" % _where(family)
			).is_equal(expected)
		for competition in CalibrationTargets.all_competitions():
			var rules: CompetitionRuleProfile = CompetitionCatalog.rules_for(competition)
			var balance: SimulationBalanceProfile = CompetitionCatalog.balance_profile()
			assert_bool(rules != null and balance != null).override_failure_message(
				"competition %s did not resolve"
				% CalibrationTargets.competition_id(competition)).is_true()
			assert_array(CareerSimulator.family_allocation_weights(family)) \
				.override_failure_message(
					"%s moved under competition %s"
					% [_where(family), CalibrationTargets.competition_id(competition)]
				).is_equal(expected)


## The weight vector the committed catalog implies, rebuilt from the two tier
## constants without going through the production resolution at all.
func _weights_from_catalog(family: int) -> Array[float]:
	var weights: Array[float] = []
	for _attribute in range(AttributeKey.COUNT):
		weights.append(CareerSimulator.NEUTRAL_WEIGHT)
	for attribute in _declared_secondary(family):
		weights[attribute] = CareerSimulator.SECONDARY_WEIGHT
	for attribute in _declared_primary(family):
		weights[attribute] = CareerSimulator.PRIMARY_WEIGHT
	return weights


## Weighted spending never breaches a cap, never leaves the legal rating band,
## and always exhausts the creation budget — for every family.
func test_weighted_allocation_stays_legal_for_every_family() -> void:
	for family in PositionFamily.all():
		var state: BuilderState = _build(family, SUITE_SEED + 200 + family)
		var values: Array[int] = state.values()
		var caps: Array[int] = state.caps.values()
		for attribute in AttributeKey.all():
			assert_int(values[attribute]).override_failure_message(
				"%s: %s exceeds its cap" % [_where(family), AttributeKey.name_of(attribute)]
			).is_less_equal(caps[attribute])
			assert_bool(Rating.is_valid_active(values[attribute])).override_failure_message(
				"%s: %s is outside the legal active band"
				% [_where(family), AttributeKey.name_of(attribute)]).is_true()
		assert_int(state.budget.remaining()).override_failure_message(
			_where(family)).is_equal(0)
		assert_bool(state.can_confirm()).override_failure_message(_where(family)).is_true()


# --- helpers ------------------------------------------------------------------


func _all_neutral() -> Array[int]:
	var emphasis: Array[int] = []
	for _attribute in range(AttributeKey.COUNT):
		emphasis.append(AttributeEmphasis.Value.NEUTRAL)
	return emphasis


func _expected_weight_for(emphasis: int) -> float:
	match emphasis:
		AttributeEmphasis.Value.PRIMARY:
			return CareerSimulator.PRIMARY_WEIGHT
		AttributeEmphasis.Value.SECONDARY:
			return CareerSimulator.SECONDARY_WEIGHT
		_:
			return CareerSimulator.NEUTRAL_WEIGHT


func _top_weighted(weights: Array[float], count: int) -> Array[int]:
	var ordered: Array[int] = AttributeKey.all()
	ordered.sort_custom(func(left: int, right: int) -> bool:
		if is_equal_approx(weights[left], weights[right]):
			return left < right
		return weights[left] > weights[right])
	var top: Array[int] = []
	for index in range(mini(count, ordered.size())):
		top.append(ordered[index])
	return top


func _copy_catalog(catalog: Array[Array]) -> Array[Array]:
	var copy: Array[Array] = []
	for row: Array in catalog:
		copy.append(row.duplicate())
	return copy


## One player built through the family's own allocation weights, at a fixed
## seed and the family's default body.
func _build(family: int, seed_value: int) -> BuilderState:
	var service := BuilderService.new()
	var state: BuilderState = service.begin_build(
		family,
		ProspectProfile.Value.BALANCED,
		MaturityProfile.Value.AVERAGE,
		service.default_body_for_family(family),
		SeededRandomSource.new(seed_value))
	state.spend_remaining_weighted(CareerSimulator.family_allocation_weights(family))
	state.fill_remaining_anywhere()
	return state
