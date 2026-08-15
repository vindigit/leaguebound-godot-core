class_name TestPossessionStateMachine
extends GdUnitTestSuite


func test_declares_all_authoritative_nodes() -> void:
	assert_int(PossessionNode.Value.size()).is_equal(14)
	assert_int(PossessionNode.Value.DEAD_BALL).is_equal(0)
	assert_int(PossessionNode.Value.POSSESSION_END).is_equal(13)
