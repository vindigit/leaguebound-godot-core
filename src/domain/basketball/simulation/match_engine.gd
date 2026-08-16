class_name MatchEngine
extends RefCounted

## The match-engine entry point (`GODOT_TDD.md` §5.3).
##
## ```gdscript
## func simulate_match(input: MatchInput, random_source: RandomSource) -> MatchResult
## ```
##
## The engine is a thin front door onto `MatchSession`, which is the same object
## Play and Skip drive. Keeping one session behind all three is what makes §2.1
## structural instead of aspirational: there is no separate simulated-game path
## that could acquire its own rules.
##
## The engine "cannot create or change roster membership, a playing contract,
## signing rights, a professional assignment, college eligibility, import
## classification, or Out-of-Basketball state", generate a replacement player,
## finalize awards, advance a career year, or write a save. It resolves
## basketball and returns evidence.


func simulate_match(input: MatchInput, random_source: RandomSource) -> MatchSimulationOutput:
	assert(input != null, "match input is required")
	assert(random_source != null, "an injected random source is required")
	return MatchSession.new(input, random_source).run_to_completion()


## Opens a stepped session for Play or Skip. Identical inputs and seed produce
## the identical ledger whether the caller steps or runs straight through.
func open_session(input: MatchInput, random_source: RandomSource) -> MatchSession:
	assert(input != null, "match input is required")
	assert(random_source != null, "an injected random source is required")
	var session := MatchSession.new(input, random_source)
	session.open()
	return session
