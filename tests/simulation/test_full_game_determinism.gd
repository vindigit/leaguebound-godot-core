class_name TestFullGameDeterminism
extends GdUnitTestSuite


func test_same_seed_reproduces_complete_result_and_ledger() -> void:
	var input := MatchFixtureFactory.standard_match()
	var first := MatchEngine.new().simulate_match(input, SeededRandomSource.new(7001))
	var second := MatchEngine.new().simulate_match(input, SeededRandomSource.new(7001))
	assert_str(first.signature()).is_equal(second.signature())


func test_different_seed_changes_complete_result_or_ledger() -> void:
	var input := MatchFixtureFactory.standard_match()
	var first := MatchEngine.new().simulate_match(input, SeededRandomSource.new(7001))
	var second := MatchEngine.new().simulate_match(input, SeededRandomSource.new(7002))
	assert_str(first.signature()).is_not_equal(second.signature())
