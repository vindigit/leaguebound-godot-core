class_name TestSeededRandomSource
extends GdUnitTestSuite


func test_same_seed_reproduces_draws() -> void:
	var first := SeededRandomSource.new(8675309)
	var second := SeededRandomSource.new(8675309)
	for _index in range(32):
		assert_int(first.next_u32()).is_equal(second.next_u32())


func test_child_stream_is_independent_of_parent_consumption() -> void:
	var first := SeededRandomSource.new(42)
	var expected_child := first.derive(&"possession:7")
	first.next_u32()
	first.next_u32()
	var actual_child := first.derive(&"possession:7")
	assert_int(actual_child.next_u32()).is_equal(expected_child.next_u32())
