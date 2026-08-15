class_name TestPlayerAttributes
extends GdUnitTestSuite


func test_canonical_model_has_exactly_twenty_attributes() -> void:
	var attributes := PlayerAttributes.new()
	assert_int(AttributeKey.COUNT).is_equal(20)
	assert_array(attributes.canonical_values()).has_size(20)


func test_default_active_ratings_are_in_domain() -> void:
	for value in PlayerAttributes.new().canonical_values():
		assert_bool(Rating.is_valid_active(value)).is_true()
