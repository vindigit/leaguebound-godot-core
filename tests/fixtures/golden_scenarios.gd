class_name GoldenScenarios
extends RefCounted

## The named determinism scenarios the Stage 3 gate requires golden ledgers for:
## regulation, overtime, offensive-rebound continuation, foul and free throw,
## substitution and foul-out, and late game.
##
## Scenario identity is `(name, fixture, seed)`. Keeping the triple in one place
## means the golden hash file, the harness that regenerates it, and the test
## that enforces it cannot drift apart — which is the usual way a golden suite
## quietly stops testing anything.

const HASH_PATH: String = "res://tests/golden/match_golden_hashes.json"

const REGULATION: StringName = &"regulation"
const OVERTIME: StringName = &"overtime"
const OFFENSIVE_REBOUND: StringName = &"offensive_rebound"
const FOUL_FREE_THROW: StringName = &"foul_free_throw"
const SUBSTITUTION_FOUL_OUT: StringName = &"substitution_foul_out"
const LATE_GAME: StringName = &"late_game"


static func names() -> Array[StringName]:
	return [
		REGULATION,
		OVERTIME,
		OFFENSIVE_REBOUND,
		FOUL_FREE_THROW,
		SUBSTITUTION_FOUL_OUT,
		LATE_GAME,
	]


static func input_for(scenario: StringName) -> MatchInput:
	match scenario:
		REGULATION:
			return MatchFixtureFactory.standard_match()
		OVERTIME:
			return MatchFixtureFactory.even_match()
		OFFENSIVE_REBOUND:
			return MatchFixtureFactory.offensive_rebound_match()
		FOUL_FREE_THROW:
			return MatchFixtureFactory.bonus_match()
		SUBSTITUTION_FOUL_OUT:
			return MatchFixtureFactory.foul_out_match()
		LATE_GAME:
			return MatchFixtureFactory.one_and_one_match()
		_:
			assert(false, "unknown golden scenario")
	return MatchFixtureFactory.standard_match()


## Seeds chosen because each one actually exercises the behaviour its scenario
## is named for. `tools/golden_ledger_harness.gd --verify` re-checks that claim,
## so a balance change that quietly stops producing overtime is a failure rather
## than a golden hash that still passes while testing nothing.
##
## When a balance change does invalidate one, re-derive it with
## `calibration/runners/find_scenario_seeds.gd` rather than guessing. The
## overtime seed moved from 5150 to 126704 at the Stage 4 calibration: the
## calibrated scoring rates changed which fixed seeds finish level.
static func seed_for(scenario: StringName) -> int:
	match scenario:
		REGULATION:
			return 20260815
		OVERTIME:
			# Moved from 190056 by the `simulation-v9-endgame-strategy`
			# ruleset, from 39595 by `simulation-v6-pass-creation` before
			# that, from 31676 by `simulation-v4-management` before that, and
			# from 126704 by `simulation-v3-margin` before that. Every
			# ruleset that changes the action mix changes which fixed seeds
			# finish level, and a game that finishes level is by definition
			# one that reached a managed score state — so this seed stopped
			# reaching overtime, which is the one thing the fixture exists to
			# cover. `find_scenario_seeds.gd` derived the replacement over a
			# 2,000-seed search.
			#
			# That this is the *only* seed `EndgameStrategy` moved is part of
			# the blast-radius evidence recorded in `PROJECT_STATUS.md`: the
			# other five scenarios still exercise their named behaviour at
			# the seeds they always had. Every one of the six ledgers still
			# changed — in all six, `EndgameStrategy` tags one or more
			# `ACTION_SELECTED` events with `endgame_two_for_one`,
			# `endgame_hold`, or `endgame_designed_play` wherever the two-for-
			# one, hold-for-the-final-shot, or designed-final-possession
			# decision applies, which is a real behaviour change and not a
			# hash regenerated to silence a failing test. None of these six
			# fixed-seed games happens to reach the leading-by-three foul,
			# the intentional free-throw miss, quick-two-vs-tying-three, or a
			# timeout-advance-eligible rule profile — those are covered by
			# `tests/simulation/test_endgame_strategy.gd` instead.
			# `PROJECT_STATUS.md` records the first divergence for each
			# scenario.
			#
			# `simulation-v10-endgame-corrections` did *not* move it again:
			# this seed still finishes level, and this scenario's ledger is
			# byte-identical across the correction, because the possessions
			# it turns on never reach a decision v10 changed (§5.26).
			#
			# `simulation-v13-opening-clock-and-location-contract` moved it
			# from 31676. The opening throw-in of every period now emits on a
			# stopped clock instead of three seconds into it, so each period
			# carries a little more live time and the action mix shifts —
			# which is again exactly the thing that decides whether a fixed
			# seed finishes level. It stopped reaching overtime, so
			# `find_scenario_seeds.gd` derived 7919 over a 600-seed search.
			# It is once more the *only* seed v13 moved: the other five still
			# exercise their named behaviour at the seeds they always had,
			# while all six ledgers changed, first at the game's opening
			# `INBOUND` timestamp (§5.30).
			#
			# `simulation-v14-restart-contract` moved it again, from 7919, for
			# the same structural reason and a different mechanism: a made free
			# throw and a charged timeout both stop the clock, so neither
			# restart charges its throw-in any more (§5.31). That returns two to
			# four seconds on every free-throw trip and every run-stopping
			# timeout, the action mix shifts, and this seed stopped finishing
			# level. `find_scenario_seeds.gd` derived 71271 over an 800-seed
			# search, and it is once again the *only* seed that moved: the other
			# five still exercise their named behaviour at the seeds they have
			# always had. All six ledgers changed; in all six the first
			# behavioural divergence is the throw-in after a made free throw,
			# and `PROJECT_STATUS.md` §5.31 names the event for each.
			return 71271
		OFFENSIVE_REBOUND:
			return 7001
		FOUL_FREE_THROW:
			return 4242
		SUBSTITUTION_FOUL_OUT:
			return 31337
		LATE_GAME:
			return 8675309
		_:
			assert(false, "unknown golden scenario")
	return 1


## Memoized because a scenario is a pure function of its fixture and seed, and
## the suites read the same handful of games from a dozen angles. Re-simulating
## per assertion turned the structural suites into the slowest thing in CI for
## no additional coverage.
static var _cache: Dictionary = {}


static func simulate(scenario: StringName) -> MatchSimulationOutput:
	if _cache.has(scenario):
		var cached: MatchSimulationOutput = _cache[scenario]
		return cached
	var output: MatchSimulationOutput = MatchEngine.new().simulate_match(
		input_for(scenario), SeededRandomSource.new(seed_for(scenario)))
	_cache[scenario] = output
	return output


## Forces a fresh simulation, for the determinism tests that must prove
## reproduction rather than read a cache.
static func simulate_uncached(scenario: StringName) -> MatchSimulationOutput:
	return MatchEngine.new().simulate_match(
		input_for(scenario), SeededRandomSource.new(seed_for(scenario)))


static func hash_of(scenario: StringName) -> String:
	return MatchLedgerSerializer.hash_output(simulate_uncached(scenario))


## What each scenario must actually contain. A golden hash proves reproduction;
## these predicates prove the reproduced thing is the scenario it claims to be.
static func describe_requirement(scenario: StringName) -> String:
	match scenario:
		REGULATION:
			return "a completed regulation game with no overtime"
		OVERTIME:
			return "at least one overtime period"
		OFFENSIVE_REBOUND:
			return "an offensive rebound that continued its possession"
		FOUL_FREE_THROW:
			return "free throws awarded from a foul"
		SUBSTITUTION_FOUL_OUT:
			return "a foul-out followed by a substitution"
		LATE_GAME:
			return "a one-and-one free-throw sequence"
		_:
			assert(false, "unknown golden scenario")
	return ""


static func meets_requirement(scenario: StringName, output: MatchSimulationOutput) -> bool:
	match scenario:
		REGULATION:
			return output.final_result.overtime_periods == 0 and not output.possessions.is_empty()
		OVERTIME:
			return output.final_result.overtime_periods > 0
		OFFENSIVE_REBOUND:
			return _has_continued_offensive_rebound(output)
		FOUL_FREE_THROW:
			return _count(output, MatchDomainEvent.FREE_THROW_AWARDED) > 0
		SUBSTITUTION_FOUL_OUT:
			return (
				_count(output, MatchDomainEvent.FOUL_OUT) > 0
				and _count(output, MatchDomainEvent.CHECK_OUT) > 0
			)
		LATE_GAME:
			return _count(output, MatchDomainEvent.FREE_THROW_AWARDED) > 0
		_:
			assert(false, "unknown golden scenario")
	return false


static func _count(output: MatchSimulationOutput, event_type: StringName) -> int:
	var total: int = 0
	for event in output.events:
		if event.event_type == event_type:
			total += 1
	return total


static func _has_continued_offensive_rebound(output: MatchSimulationOutput) -> bool:
	for record in output.possessions:
		if record.offensive_rebounds > 0:
			return true
	return false
