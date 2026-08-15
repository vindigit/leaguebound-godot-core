class_name TestPossessionDeterminism
extends GdUnitTestSuite


func test_same_fixture_and_seed_reproduce_possession() -> void:
	var input := MatchFixtureFactory.standard_match()
	var first := PossessionEngine.new().simulate(MatchSnapshot.new(input), input, SeededRandomSource.new(1234))
	var second := PossessionEngine.new().simulate(MatchSnapshot.new(input), input, SeededRandomSource.new(1234))
	assert_int(first.elapsed_ms).is_equal(second.elapsed_ms)
	assert_int(first.events.size()).is_equal(second.events.size())
	for index in range(first.events.size()):
		assert_str(first.events[index].signature()).is_equal(second.events[index].signature())
