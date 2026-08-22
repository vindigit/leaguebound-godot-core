class_name VenueEffectEstimator
extends RefCounted

## The paired, two-arm venue contribution (`SIMULATION_SPEC.md` §19.4,
## `BALANCE_SPEC.md` §14.2 and §17.4).
##
## §17.4 caps what the home environment may be worth at +2.5 points per 100
## possessions. Judging that cap needs an estimate of *the environment*, and a
## single column of games is not one: a column carries the fixture, the rosters
## and the seeds along with the venue, and at any sample a diagnostic can afford
## those dominate. This class exists because the figure that was published
## against the cap was formed from one arm, and one arm cannot separate them.
##
## Three arms play the identical fixtures at the identical seeds:
##
## ```text
## home      venue = A, visitor = B, environment = E
## neutral   venue = A, visitor = B, environment = 0
## reversed  venue = B, visitor = A, environment = E
## ```
##
## Every margin is signed venue-minus-visitor, so a positive number is an
## advantage to whoever owns the building in that arm. The two venue arms give
## two independent estimates of one quantity:
##
## ```text
## effect on A = margin_home[i]     - margin_neutral[i]
## effect on B = margin_reversed[i] + margin_neutral[i]
## ```
##
## `margin_reversed` is signed from B's end of the building and B's neutral
## margin is `-margin_neutral`, so the second line is the same subtraction
## performed on the other bench. The published estimate is their mean.
##
## **The neutral arm cancels out of that mean, and that is the point rather than
## an accident.** `0.5 * ((h - n) + (r + n)) = 0.5 * (h + r)`: the control enters
## the two estimates with opposite signs and leaves. So the venue contribution
## cannot be biased by a biased control, which is precisely what makes the
## control usable as an independent check — a neutral arm that does not centre
## on 0.50 and a zero margin is evidence about the *fixture*, and it says so
## without having already been folded into the answer. The same cancellation
## holds for the win-rate form, because `win_value(n) + win_value(-n) = 1` for
## every margin including a tie.
##
## The neutral arm is still **required**: a fixture missing any of the three
## arms is not a matched triple and is refused rather than estimated from what
## survived.
##
## Nothing here reads a rating, a team identity, or a competition. It is handed
## finished games and does arithmetic on them.

## The three arms a complete matched fixture must carry.
const ARM_HOME: StringName = &"home"
const ARM_NEUTRAL: StringName = &"neutral"
const ARM_REVERSED: StringName = &"reversed"

## §17.4's combined cap on the environment's contribution.
const CAP_POINTS_PER_100: float = 2.5

## §14.2's even-team home win rate baseline. The venue-attributable win rate is
## reported as this plus the paired gain, so "no venue effect" reads as 0.500.
const NEUTRAL_WIN_BASELINE: float = 0.5


## One arm of one fixture. Margins are signed venue-minus-visitor; possessions
## are the venue side's engine possessions for that game.
class Observation:
	extends RefCounted

	var margin: float = 0.0
	var venue_possessions: float = 0.0

	func _init(p_margin: float = 0.0, p_venue_possessions: float = 0.0) -> void:
		margin = p_margin
		venue_possessions = p_venue_possessions


## `fixture_key -> { arm_id -> Observation }`.
##
## The fixture key is the identity of one matched triple — competition, seed
## range and variation. Two shards that disagree about a key are pooling the
## same game twice and are refused.
var _fixtures: Dictionary = {}

## Every `(fixture, arm)` that was offered more than once, in the order the
## duplicates arrived. A duplicated observation is the failure mode this
## estimator is least able to notice from its own totals, so it is recorded
## explicitly rather than left to a count.
var _duplicate_attempts: PackedStringArray = PackedStringArray()

## Fixture keys refused by `merge` because another shard already owned them.
var _overlapping_keys: PackedStringArray = PackedStringArray()


## Records one arm of one fixture.
##
## Returns `false` — and changes nothing — when this `(fixture, arm)` has
## already been recorded. Silently accepting the second copy is how a
## duplicated sample comes to be counted as independent evidence, so the caller
## is told and the attempt is kept.
func observe(
	fixture_key: StringName,
	arm_id: StringName,
	margin: float,
	venue_possessions: float,
) -> bool:
	if not _fixtures.has(fixture_key):
		_fixtures[fixture_key] = {}
	var arms: Dictionary = _fixtures[fixture_key]
	if arms.has(arm_id):
		_duplicate_attempts.append("%s/%s" % [fixture_key, arm_id])
		return false
	arms[arm_id] = Observation.new(margin, venue_possessions)
	return true


## Pools another shard into this one.
##
## Fixture keys are global identities, so a key present on both sides is the
## same matched triple arriving twice. It is refused rather than merged: pooling
## it would double its weight and report a sample twice the size of the evidence.
func merge(other: VenueEffectEstimator) -> bool:
	var accepted: bool = true
	for key: StringName in other.fixture_keys():
		if _fixtures.has(key):
			_overlapping_keys.append(String(key))
			accepted = false
			continue
		var source: Dictionary = other._fixtures[key]
		var copied: Dictionary = {}
		for arm_id: StringName in source.keys():
			var observation: Observation = source[arm_id]
			copied[arm_id] = Observation.new(
				observation.margin, observation.venue_possessions)
		_fixtures[key] = copied
	for attempt in other._duplicate_attempts:
		_duplicate_attempts.append(attempt)
	for key in other._overlapping_keys:
		_overlapping_keys.append(key)
	return accepted


## Every fixture key, in lexicographic order.
##
## Sorted as `String` and not as `StringName` on purpose. Godot's `StringName`
## comparison operators order by internal pointer rather than alphabetically, so
## `Array[StringName].sort()` produces an order that depends on which names the
## engine happened to intern first — reproducible within a run and not across
## them. The published means are order-independent, but the per-fixture series
## this returns are written into the report, and a series whose order changes
## between two runs of the same seed range is not a reproducible artifact.
func fixture_keys() -> Array[StringName]:
	var sortable := PackedStringArray()
	for key: StringName in _fixtures.keys():
		sortable.append(String(key))
	sortable.sort()
	var keys: Array[StringName] = []
	for key in sortable:
		keys.append(StringName(key))
	return keys


## The keys carrying all three arms, in a stable order so two runs that observed
## the same fixtures in different orders produce the identical sequence.
func complete_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in fixture_keys():
		if _is_complete(key):
			keys.append(key)
	return keys


## The keys missing at least one arm. These contribute to nothing.
func incomplete_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in fixture_keys():
		if not _is_complete(key):
			keys.append(key)
	return keys


func _is_complete(key: StringName) -> bool:
	var arms: Dictionary = _fixtures[key]
	return arms.has(ARM_HOME) and arms.has(ARM_NEUTRAL) and arms.has(ARM_REVERSED)


## Matched triples that survived. This is the estimator's sample size — the
## number of *independent paired fixtures*, not the number of simulations.
func pair_count() -> int:
	return complete_keys().size()


## Complete games that contributed, which is three per surviving triple: the
## same fixture was played once in each arm. Reported separately from
## `pair_count` because they are different numbers and conflating them is how a
## sample comes to be described as larger than it is.
func unique_games() -> int:
	return pair_count() * 3


## `(fixture, arm)` observations offered twice and refused.
func duplicate_attempts() -> PackedStringArray:
	return _duplicate_attempts.duplicate()


## Fixture keys refused by `merge` because they were already present.
func overlapping_keys() -> PackedStringArray:
	return _overlapping_keys.duplicate()


## True when every fixture offered carries all three arms and nothing was
## duplicated or double-pooled. A report that publishes an estimate from an
## estimator where this is false is publishing an unknown sample.
func is_well_formed() -> bool:
	return (
		incomplete_keys().is_empty()
		and _duplicate_attempts.is_empty()
		and _overlapping_keys.is_empty())


# --- the paired series ------------------------------------------------------

## Per-fixture venue effect on final margin, estimated from the home arm alone
## against the neutral control. Published beside the pooled figure, never as the
## cap metric: it is one of two estimates of the same quantity and the noisier
## reading of the pair.
func home_arm_margin_gain() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for key in complete_keys():
		var arms: Dictionary = _fixtures[key]
		values.append(
			(arms[ARM_HOME] as Observation).margin
			- (arms[ARM_NEUTRAL] as Observation).margin)
	return values


## The same quantity measured from the other bench after the venue is swapped.
func reversed_arm_margin_gain() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for key in complete_keys():
		var arms: Dictionary = _fixtures[key]
		values.append(
			(arms[ARM_REVERSED] as Observation).margin
			+ (arms[ARM_NEUTRAL] as Observation).margin)
	return values


## The published venue effect on margin: the mean of the two arm estimates,
## per fixture. Symmetric in the two venue arms by construction, so which arm
## the caller happened to record first cannot move it.
func paired_margin_gain() -> PackedFloat64Array:
	var home_values: PackedFloat64Array = home_arm_margin_gain()
	var reversed_values: PackedFloat64Array = reversed_arm_margin_gain()
	var values := PackedFloat64Array()
	for index in range(home_values.size()):
		values.append(0.5 * (home_values[index] + reversed_values[index]))
	return values


## Per-fixture venue effect on the win/draw value, pooled over the two venue
## arms. Add `NEUTRAL_WIN_BASELINE` to read it as a home win rate.
func paired_win_gain() -> PackedFloat64Array:
	var values := PackedFloat64Array()
	for key in complete_keys():
		var arms: Dictionary = _fixtures[key]
		var neutral: float = (arms[ARM_NEUTRAL] as Observation).margin
		var home_gain: float = (
			win_value((arms[ARM_HOME] as Observation).margin) - win_value(neutral))
		var reversed_gain: float = (
			win_value((arms[ARM_REVERSED] as Observation).margin) - win_value(-neutral))
		values.append(0.5 * (home_gain + reversed_gain))
	return values


## A win is 1, a loss 0, a tie 0.5. A regulation tie enters overtime so a
## completed game is never a tie; the case is defined so the statistic is total
## rather than silently scoring a tie as a loss.
static func win_value(margin: float) -> float:
	if margin > 0.0:
		return 1.0
	return 0.0 if margin < 0.0 else 0.5


# --- published estimates ----------------------------------------------------

## Share of decided games won by the venue side in one arm, over the complete
## triples only, so every published rate describes the same set of fixtures.
func arm_win_rate(arm_id: StringName) -> float:
	var decided: int = 0
	var wins: int = 0
	for key in complete_keys():
		var margin: float = ((_fixtures[key] as Dictionary)[arm_id] as Observation).margin
		if margin == 0.0:
			continue
		decided += 1
		if margin > 0.0:
			wins += 1
	return 0.0 if decided == 0 else float(wins) / float(decided)


func arm_mean_margin(arm_id: StringName) -> float:
	var values := PackedFloat64Array()
	for key in complete_keys():
		values.append(((_fixtures[key] as Dictionary)[arm_id] as Observation).margin)
	return mean(values)


## The venue side's possessions per game, averaged over all three arms of every
## complete triple.
##
## The scale the cap is expressed in. Taken across the arms rather than from the
## home arm because the numerator is a difference *between* arms, and a
## denominator drawn from one of them makes the published figure depend on which
## one.
func possession_base() -> float:
	var total: float = 0.0
	var count: int = 0
	for key in complete_keys():
		var arms: Dictionary = _fixtures[key]
		for arm_id: StringName in [ARM_HOME, ARM_NEUTRAL, ARM_REVERSED]:
			total += (arms[arm_id] as Observation).venue_possessions
			count += 1
	if count == 0:
		return 0.0
	return total / float(count)


## The raw home win rate: the venue side's share at the production environment,
## with nothing subtracted.
func raw_home_win_rate() -> float:
	return arm_win_rate(ARM_HOME)


## The control: the same fixtures with the environment at zero. It should centre
## on 0.500, and it is not subtracted from the raw figure to manufacture one.
func neutral_home_win_rate() -> float:
	return arm_win_rate(ARM_NEUTRAL)


## **The judged §14.2 estimator.** The venue-attributable home win rate.
##
## The owner ruling defines the canonical quantity as
##
## ```text
## 0.5 * [ P(designated venue side wins when the environment favours it)
##       + P(opposite venue side wins when the environment is reversed) ]
## ```
##
## and this returns the pair-level form of exactly that. The published contract,
## in full, because a verdict metric whose definition lives only in a commit
## message is a metric nobody can check:
##
## - **Formula.** `NEUTRAL_WIN_BASELINE + mean_i(paired_win_gain[i])`, where
##   `paired_win_gain[i] = 0.5 * ((wv(h_i) - wv(n_i)) + (wv(r_i) - wv(-n_i)))`.
##   `wv(n) + wv(-n) = 1` for every margin including zero, so this reduces
##   algebraically to `0.5 * (mean_i wv(h_i) + mean_i wv(r_i))` — the canonical
##   form above, with no approximation. `canonical_venue_win_rate` computes that
##   reduced form directly and the two are asserted equal by test.
## - **Denominator.** Matched fixtures carrying all three arms. Not simulations:
##   one fixture is three complete games and one observation. Fixtures missing an
##   arm contribute to nothing.
## - **Arm construction.** `home` = venue A at strength E; `neutral` = the same
##   fixture at strength 0; `reversed` = venue B at strength E. Identical
##   rosters, identical seeds, opening inbound counterbalanced and held constant
##   across the three arms.
## - **Ties.** A win is 1, a loss 0, a tie 0.5. A regulation tie enters overtime
##   so a completed game is never a tie; the case is defined for totality, and
##   defining it this way is what makes the reduction above exact rather than
##   approximate.
## - **Weighting.** Every matched pair carries weight 1. Levels are not
##   reweighted by size, and reports are not weighted by report count.
## - **Interval.** 1.96 x the standard error of the per-fixture paired series,
##   `sd(paired_win_gain) / sqrt(n)`. Paired, so it carries the
##   common-random-number variance reduction rather than a marginal proportion's.
## - **Pooling.** Union of fixture keys across shards, then the same unweighted
##   mean over the pooled series. Keys carry the competition, so two levels at
##   one variation cannot merge, and an overlapping key is refused rather than
##   double-counted.
func venue_attributable_win_rate() -> float:
	return NEUTRAL_WIN_BASELINE + mean(paired_win_gain())


## The canonical form written out directly, for comparison against the paired
## form above. Identical by algebra, and pinned identical by test: if the two
## ever disagree the paired implementation has stopped computing what the ruling
## says it computes.
func canonical_venue_win_rate() -> float:
	return 0.5 * (arm_win_value_mean(ARM_HOME) + arm_win_value_mean(ARM_REVERSED))


## Mean win value for one arm over the complete matched pairs.
##
## Distinct from `arm_win_rate`, which divides by *decided* games. They coincide
## whenever no game ends level — which the engine guarantees, because a
## regulation tie plays overtime — and this form is the one the canonical
## reduction needs, because it keeps one denominator across all three arms.
func arm_win_value_mean(arm_id: StringName) -> float:
	var values := PackedFloat64Array()
	for key in complete_keys():
		values.append(
			win_value(((_fixtures[key] as Dictionary)[arm_id] as Observation).margin))
	return mean(values)


func venue_attributable_win_rate_half_width() -> float:
	return half_width(paired_win_gain())


## Raw margin difference: the home arm's mean margin, unadjusted.
func raw_margin_difference() -> float:
	return arm_mean_margin(ARM_HOME)


## Paired margin difference: the venue's effect on final margin with the roster,
## the matchup and the seed cancelled, pooled over both venue arms.
func paired_margin_difference() -> float:
	return mean(paired_margin_gain())


func paired_margin_half_width() -> float:
	return half_width(paired_margin_gain())


## §17.4's figure: the paired two-arm venue contribution in points per 100
## venue possessions. **This is the number the cap judges.**
func points_per_100() -> float:
	var base: float = possession_base()
	if base <= 0.0:
		return 0.0
	return 100.0 * paired_margin_difference() / base


func points_per_100_half_width() -> float:
	var base: float = possession_base()
	if base <= 0.0:
		return 0.0
	return 100.0 * paired_margin_half_width() / base


func points_per_100_standard_error() -> float:
	var base: float = possession_base()
	if base <= 0.0:
		return 0.0
	return 100.0 * standard_error(paired_margin_gain()) / base


## The single-arm reading, published for comparison so the difference between
## the old metric and the corrected one is visible rather than asserted.
func home_arm_points_per_100() -> float:
	var base: float = possession_base()
	if base <= 0.0:
		return 0.0
	return 100.0 * mean(home_arm_margin_gain()) / base


func cap_respected() -> bool:
	return points_per_100() <= CAP_POINTS_PER_100


## The two venue arms must estimate the same quantity. Intervals that do not
## overlap mean the effect is attached to a roster rather than to a building.
func venue_reversal_agrees() -> bool:
	var home_values: PackedFloat64Array = home_arm_margin_gain()
	var reversed_values: PackedFloat64Array = reversed_arm_margin_gain()
	var reach: float = half_width(home_values) + half_width(reversed_values)
	return absf(mean(home_values) - mean(reversed_values)) <= reach


# --- statistics -------------------------------------------------------------

static func mean(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


static func standard_error(values: PackedFloat64Array) -> float:
	if values.size() < 2:
		return 0.0
	return sqrt(maxf(ScoringCovariance.variance(values), 0.0)) / sqrt(float(values.size()))


static func half_width(values: PackedFloat64Array) -> float:
	return 1.96 * standard_error(values)


func to_dictionary() -> Dictionary:
	return {
		"pairs": pair_count(),
		"unique_games": unique_games(),
		"incomplete_fixtures": incomplete_keys().size(),
		"duplicate_attempts": _duplicate_attempts.size(),
		"overlapping_keys": _overlapping_keys.size(),
		"well_formed": is_well_formed(),
		"raw_home_win_rate": raw_home_win_rate(),
		"neutral_home_win_rate": neutral_home_win_rate(),
		"venue_attributable_win_rate": venue_attributable_win_rate(),
		"venue_attributable_win_rate_half_width": venue_attributable_win_rate_half_width(),
		"raw_margin_difference": raw_margin_difference(),
		"paired_margin_difference": paired_margin_difference(),
		"paired_margin_half_width": paired_margin_half_width(),
		"points_per_100": points_per_100(),
		"points_per_100_half_width": points_per_100_half_width(),
		"points_per_100_standard_error": points_per_100_standard_error(),
		"home_arm_points_per_100": home_arm_points_per_100(),
		"possession_base": possession_base(),
		"cap_respected": cap_respected(),
		"venue_reversal_agrees": venue_reversal_agrees(),
	}
