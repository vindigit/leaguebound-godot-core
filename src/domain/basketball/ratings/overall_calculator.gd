class_name OverallCalculator
extends RefCounted

## The one canonical role-neutral Overall formula (`BALANCE_SPEC.md` §6.1,
## `GODOT_TDD.md` §5.5).
##
## ```text
## OverallRaw = 0.65 x M20 + 0.25 x T8 + 0.10 x B6
## DisplayedOverall = round(clamp(OverallRaw, 25, 99))
## ```
##
## where `M20` is the mean of all twenty current attributes, `T8` the mean of
## the eight highest, and `B6` the mean of the six lowest. The blend is
## role-neutral, gives specialized strengths some credit, and still makes
## serious weaknesses matter. No attribute receives a permanent position-based
## weight.
##
## This class is the *only* implementation. `GODOT_TDD.md` §6.2 makes a scene
## that recomputes Overall from displayed ratings a release blocker "even when
## its arithmetic happens to agree", on the grounds that two implementations of
## one formula is one formula too many and the copy is the one that drifts when
## a balance profile changes.
##
## ## Monotonicity
##
## §6.2 requires that raising any one rating while all others stay fixed cannot
## reduce Overall. That holds structurally here, not by tuning: all three
## coefficients are non-negative (asserted by `RatingsProfile`), and raising one
## element weakly increases every order statistic of the multiset — the mean,
## the sum of the eight largest, and the sum of the six smallest alike. The
## guardrail therefore survives any coefficient retuning that keeps the weights
## non-negative.
##
## ## Not a simulation input
##
## §6.2 and `SIMULATION_SPEC.md` §6: no resolution path may read Current
## Overall, Maximum Potential, or Projected Peak. They are display projections
## derived from ratings. `tests/unit/basketball/test_overall_exclusion.gd`
## enforces this by inspecting the simulation sources directly.


## Raw, unrounded Overall. Exposed so the calibration harness can report the
## fractional value and reason about the one-point rounding boundary §6.2
## tolerates, without re-deriving the blend.
static func raw_overall(values: Array[int], profile: RatingsProfile) -> float:
	assert(values.size() == AttributeKey.COUNT,
		"Overall is a function of exactly the twenty canonical attributes")
	var sorted: Array[int] = values.duplicate()
	sorted.sort()

	var total: int = 0
	for value in sorted:
		total += value
	var mean_all: float = float(total) / float(AttributeKey.COUNT)

	var bottom_total: int = 0
	for index in range(RatingsProfile.BOTTOM_COUNT):
		bottom_total += sorted[index]
	var mean_bottom: float = float(bottom_total) / float(RatingsProfile.BOTTOM_COUNT)

	var top_total: int = 0
	for index in range(AttributeKey.COUNT - RatingsProfile.TOP_COUNT, AttributeKey.COUNT):
		top_total += sorted[index]
	var mean_top: float = float(top_total) / float(RatingsProfile.TOP_COUNT)

	return (
		profile.mean_weight * mean_all
		+ profile.top_weight * mean_top
		+ profile.bottom_weight * mean_bottom
	)


static func overall_from_values(values: Array[int], profile: RatingsProfile) -> int:
	return int(roundf(clampf(
		raw_overall(values, profile),
		float(Rating.ACTIVE_MINIMUM),
		float(Rating.MAXIMUM)
	)))


## Current Overall: the §6.1 formula applied to current ratings. Exact, public,
## and calculated identically for users and NPCs (§6).
static func current_overall(attributes: PlayerAttributes, profile: RatingsProfile) -> int:
	return overall_from_values(attributes.canonical_values(), profile)


## Maximum Potential Overall: the same §6.1 formula applied to the player's
## exact per-attribute caps (§6.3).
##
## It is a physical and skill ceiling, not a promise. It assumes every cap is
## filled, which effectively no career achieves, and §6.3 rule 1 forbids
## labelling it "potential rating", "future Overall", or anything implying
## attainment.
static func maximum_potential_overall(caps: AttributeCaps, profile: RatingsProfile) -> int:
	var cap_values: Array[int] = caps.values()
	for index in range(cap_values.size()):
		cap_values[index] = clampi(cap_values[index], Rating.ACTIVE_MINIMUM, Rating.MAXIMUM)
	return overall_from_values(cap_values, profile)
