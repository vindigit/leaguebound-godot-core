class_name TestAttributeContracts
extends GdUnitTestSuite


func test_all_twenty_attributes_are_addressable_for_future_sensitivity_sweeps() -> void:
	var attributes := PlayerAttributes.new()
	for key in AttributeKey.all():
		assert_int(attributes.get_rating(key)).is_between(Rating.ACTIVE_MINIMUM, Rating.MAXIMUM)


# Statistical monotonicity cases remain explicit future work. They require approved
# BALANCE_SPEC sample sizes and tolerances and must not be converted into false-green tests.
