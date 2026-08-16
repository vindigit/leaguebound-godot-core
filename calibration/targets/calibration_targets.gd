class_name CalibrationTargets
extends RefCounted

## The single versioned source of truth for every calibration acceptance band.
##
## The Stage 4 brief: "Targets must load from one versioned source of truth. Do
## not duplicate provisional ranges inside a script." Every band below is a
## transcription of an owning document section, and every one names that section
## so a report can print where its verdict came from.
##
## This file holds **targets**, never tunables. A tunable that misses a target
## moves; the target does not. Where a document marks a value provisional
## (`BALANCE_SPEC.md` §32) the band is still the acceptance target — provisional
## describes the *tunable* that has to reach it, not the target itself.

const VERSION: StringName = &"calibration-targets-v1"

enum Competition {
	HIGH_SCHOOL,
	COLLEGE,
	DEVELOPMENT,
	OVERSEAS,
	TOP_DOMESTIC_PRO,
}

const COMPETITION_COUNT: int = 5
const COMPETITION_IDS: PackedStringArray = [
	"high_school", "college", "development", "overseas", "top_domestic_pro",
]

enum ProspectProfile {
	HIGH_UPSIDE,
	BALANCED,
	READY_NOW,
}

const PROSPECT_IDS: PackedStringArray = ["high_upside", "balanced", "ready_now"]

enum CareerOutcome {
	POOR,
	ORDINARY,
	STRONG,
	EXCEPTIONAL,
	GENERATIONAL,
}

const CAREER_OUTCOME_IDS: PackedStringArray = [
	"poor_or_injury_hit", "ordinary_successful", "strong_well_managed",
	"exceptional", "rare_generational",
]


static func competition_id(competition: int) -> StringName:
	assert(competition >= 0 and competition < COMPETITION_COUNT, "unknown competition")
	return StringName(COMPETITION_IDS[competition])


static func all_competitions() -> Array[int]:
	var values: Array[int] = []
	for index in range(COMPETITION_COUNT):
		values.append(index)
	return values


# --- §14.1 team statistical targets -----------------------------------------
#
# Column order is the enum order above. Every row is transcribed from the
# `BALANCE_SPEC.md` §14.1 table and nothing may be authored here that is not in
# that table.

const _SECTION_14_1: String = "BALANCE_SPEC.md §14.1"

## Engine possessions per team per game. The brief requires engine possessions
## and the classic estimate to be reported separately; this band judges engine
## possessions, and the estimate is reported beside it as informational.
static func possessions_per_game(competition: int) -> CalibrationBand:
	return _row(competition, [61.0, 64.0, 88.0, 70.0, 96.0], [72.0, 73.0, 101.0, 82.0, 103.0],
		_SECTION_14_1)


static func points_per_possession(competition: int) -> CalibrationBand:
	return _row(competition, [0.91, 0.98, 1.00, 1.00, 1.08], [1.05, 1.10, 1.12, 1.13, 1.18],
		_SECTION_14_1)


static func field_goal_percentage(competition: int) -> CalibrationBand:
	return _row(competition, [0.39, 0.42, 0.43, 0.43, 0.45], [0.47, 0.49, 0.50, 0.51, 0.51],
		_SECTION_14_1)


static func three_point_percentage(competition: int) -> CalibrationBand:
	return _row(competition, [0.28, 0.31, 0.31, 0.32, 0.34], [0.36, 0.38, 0.38, 0.39, 0.40],
		_SECTION_14_1)


static func three_point_attempt_rate(competition: int) -> CalibrationBand:
	return _row(competition, [0.24, 0.32, 0.32, 0.30, 0.36], [0.39, 0.46, 0.47, 0.46, 0.49],
		_SECTION_14_1)


static func free_throw_percentage(competition: int) -> CalibrationBand:
	return _row(competition, [0.62, 0.67, 0.68, 0.69, 0.73], [0.76, 0.79, 0.80, 0.82, 0.83],
		_SECTION_14_1)


## Turnovers per 100 **engine** possessions. §14.1 states the metric per 100
## possessions; the brief fixes the denominator as engine possessions.
static func turnovers_per_100(competition: int) -> CalibrationBand:
	return _row(competition, [15.0, 15.0, 14.0, 13.0, 11.0], [24.0, 21.0, 20.0, 19.0, 16.0],
		_SECTION_14_1)


## Offensive rebound percentage, defined by §14 and the brief as
## `ORB / (ORB + opponent DREB)`. Possession count is never the denominator.
static func offensive_rebound_percentage(competition: int) -> CalibrationBand:
	return _row(competition, [0.25, 0.24, 0.23, 0.23, 0.20], [0.38, 0.34, 0.33, 0.34, 0.31],
		_SECTION_14_1)


static func free_throw_attempt_rate(competition: int) -> CalibrationBand:
	return _row(competition, [0.18, 0.20, 0.18, 0.20, 0.18], [0.38, 0.38, 0.36, 0.39, 0.34],
		_SECTION_14_1)


## Assist percentage: assists as a share of the team's own made field goals.
static func assist_percentage(competition: int) -> CalibrationBand:
	return _row(competition, [0.42, 0.48, 0.48, 0.50, 0.52], [0.66, 0.68, 0.69, 0.72, 0.72],
		_SECTION_14_1)


# --- §14.2 game-shape targets ------------------------------------------------

const _SECTION_14_2: String = "BALANCE_SPEC.md §14.2"


static func home_win_rate() -> CalibrationBand:
	return CalibrationBand.new(0.53, 0.56, _SECTION_14_2)


static func overtime_frequency() -> CalibrationBand:
	return CalibrationBand.new(0.04, 0.08, _SECTION_14_2)


static func close_game_share() -> CalibrationBand:
	return CalibrationBand.new(0.22, 0.34, _SECTION_14_2)


static func blowout_share() -> CalibrationBand:
	return CalibrationBand.new(0.08, 0.18, _SECTION_14_2)


## §14.2: "Top domestic rotation players average 12-36 minutes depending on
## role; ordinary starters cluster at 27-35."
static func starter_minutes() -> CalibrationBand:
	return CalibrationBand.new(27.0, 35.0, _SECTION_14_2)


static func rotation_minutes_envelope() -> CalibrationBand:
	return CalibrationBand.new(12.0, 36.0, _SECTION_14_2)


# --- §7.3.2 completed Builder bands (Locked, OD-B) --------------------------

const _SECTION_7_3_2: String = "BALANCE_SPEC.md §7.3.2 (Locked, OD-B)"

## Tolerance an extreme specialist may sit outside its profile band, in Overall
## points. §7.3.2: "approximately two OVR outside its profile band".
const SPECIALIST_TOLERANCE: float = 2.0

## §7.3.2: "An ordinary completed build must not exceed approximately 54 current
## OVR." Gate B1 fails above this.
const COMPLETED_BUILD_CEILING: float = 54.0

## §7.3.1: the empty pre-allocation preview, which is a preview and never a
## completed build.
static func empty_preview_overall() -> CalibrationBand:
	return CalibrationBand.new(37.0, 39.0, "BALANCE_SPEC.md §7.3.1 (Locked, OD-B)")


static func completed_build_overall(prospect: int) -> CalibrationBand:
	match prospect:
		ProspectProfile.HIGH_UPSIDE:
			return CalibrationBand.new(44.0, 48.0, _SECTION_7_3_2)
		ProspectProfile.BALANCED:
			return CalibrationBand.new(46.0, 50.0, _SECTION_7_3_2)
		ProspectProfile.READY_NOW:
			return CalibrationBand.new(48.0, 52.0, _SECTION_7_3_2)
		_:
			assert(false, "unknown prospect profile")
	return CalibrationBand.new(46.0, 50.0, _SECTION_7_3_2)


static func specialist_build_overall(prospect: int) -> CalibrationBand:
	var ordinary: CalibrationBand = completed_build_overall(prospect)
	return CalibrationBand.new(
		ordinary.minimum - SPECIALIST_TOLERANCE,
		ordinary.maximum + SPECIALIST_TOLERANCE,
		_SECTION_7_3_2)


# --- §8.4 career peak distribution (Locked, OD-A) ---------------------------

const _SECTION_8_4: String = "BALANCE_SPEC.md §8.4 (Locked, OD-A)"


static func career_peak_overall(outcome: int) -> CalibrationBand:
	match outcome:
		CareerOutcome.POOR:
			# "Below 72". The floor is the 25-per-attribute minimum.
			return CalibrationBand.new(25.0, 71.0, _SECTION_8_4)
		CareerOutcome.ORDINARY:
			return CalibrationBand.new(74.0, 79.0, _SECTION_8_4)
		CareerOutcome.STRONG:
			return CalibrationBand.new(80.0, 85.0, _SECTION_8_4)
		CareerOutcome.EXCEPTIONAL:
			return CalibrationBand.new(86.0, 91.0, _SECTION_8_4)
		CareerOutcome.GENERATIONAL:
			return CalibrationBand.new(92.0, 95.0, _SECTION_8_4)
		_:
			assert(false, "unknown career outcome")
	return CalibrationBand.new(74.0, 79.0, _SECTION_8_4)


## §8.4 / §6.2: "A current Overall of 96 or above is practically nonexistent."
## Expressed as a population share so a report can measure it.
static func share_above_95_overall() -> CalibrationBand:
	return CalibrationBand.new(0.0, 0.0001, _SECTION_8_4)


## §6.2: "Fewer than 0.1% of top-domestic active players should reach 95+".
static func top_domestic_share_at_95_plus() -> CalibrationBand:
	return CalibrationBand.new(0.0, 0.001, "BALANCE_SPEC.md §6.2")


## §8.4 requires a *continuous* distribution across the deliberate 72-74 gap
## rather than a spike. Measured as the share of careers peaking at 72 or 73.
static func transition_band_share() -> CalibrationBand:
	return CalibrationBand.new(0.01, 0.20, _SECTION_8_4)


# --- §6.3 projected-peak honesty --------------------------------------------

const _SECTION_6_3: String = "BALANCE_SPEC.md §6.3"


static func projected_peak_coverage() -> CalibrationBand:
	return CalibrationBand.new(0.70, 0.85, _SECTION_6_3)


static func projected_peak_median_width() -> CalibrationBand:
	return CalibrationBand.new(6.0, 12.0, _SECTION_6_3)


## Median signed error between realized peak and range midpoint, in Overall
## points. §6.3: "must not exceed ±2 Overall points".
static func projected_peak_signed_bias() -> CalibrationBand:
	return CalibrationBand.new(-2.0, 2.0, _SECTION_6_3)


# --- §7.4 body maturation (report 15) ---------------------------------------

const _SECTION_7_4: String = "BALANCE_SPEC.md §7.4 (Structural invariant, OD-C)"

## A structural invariant is not a band with a tolerance. Every one of these
## must hold in every career, so the target is exactly 1.0 and a single
## violation in a million careers is a failure rather than a rounding artifact.
static func structural_invariant_share() -> CalibrationBand:
	return CalibrationBand.new(1.0, 1.0, _SECTION_7_4)


## §7.4.2 requires report 15 to show "that Early, Average, and Late produce
## materially different realized high-school bodies". "Materially different"
## needs a number before a report can fail on it; this is the harness's reading,
## expressed as the minimum gap between the Early and Late shares of total
## growth delivered by the end of high school. The configured shares are 0.75
## and 0.25, so a model that keeps even half that separation still passes, and
## one that has quietly collapsed the maturity choice does not.
static func body_timing_separation() -> CalibrationBand:
	return CalibrationBand.new(0.20, 1.0, "BALANCE_SPEC.md §7.4.2 (report 15)")


## How far the realized high-school growth share may sit from the share the
## Builder profile configures. Growth is delivered in whole inches and pounds,
## so rounding alone moves the realized share; this bounds that drift without
## permitting the schedule to be quietly re-shaped.
const BODY_TIMING_SHARE_TOLERANCE: float = 0.08


static func body_timing_share_source() -> String:
	return "BALANCE_SPEC.md §7.4.2 (Baseline pending report 15)"


# --- §8.2 population distribution targets -----------------------------------

const _SECTION_8_2: String = "BALANCE_SPEC.md §8.2"


static func incoming_freshman_max_potential_median() -> CalibrationBand:
	return CalibrationBand.new(58.0, 63.0, _SECTION_8_2)


static func incoming_freshman_max_potential_p90() -> CalibrationBand:
	return CalibrationBand.new(70.0, 75.0, _SECTION_8_2)


static func incoming_freshman_max_potential_p99() -> CalibrationBand:
	return CalibrationBand.new(82.0, 88.0, _SECTION_8_2)


static func top_domestic_current_median() -> CalibrationBand:
	return CalibrationBand.new(77.0, 81.0, _SECTION_8_2)


static func top_domestic_current_p90() -> CalibrationBand:
	return CalibrationBand.new(87.0, 90.0, _SECTION_8_2)


static func top_domestic_current_p99() -> CalibrationBand:
	return CalibrationBand.new(92.0, 95.0, _SECTION_8_2)


# --- §14.3 opposed event sensitivity ----------------------------------------

const _SECTION_14_3: String = "BALANCE_SPEC.md §14.3"


## Relative change in a qualifying-event probability from a ten-point capability
## edge.
static func ten_point_edge_relative_change() -> CalibrationBand:
	return CalibrationBand.new(0.15, 0.25, _SECTION_14_3)


static func twenty_five_point_edge_relative_change() -> CalibrationBand:
	return CalibrationBand.new(0.40, 0.70, _SECTION_14_3)


# --- attribute sensitivity ---------------------------------------------------

const _SECTION_27_2: String = "BALANCE_SPEC.md §27.2"

## §27.2: the 95% interval "must show the correct direction and at least the
## documented minimum practical effect from rating 50 to 80". The documented
## minimum is expressed as a relative change in the attribute's required
## observable, because the observables have incompatible units.
const MIN_RELATIVE_EFFECT_50_TO_80: float = 0.10

## An amplifier (IQ) must not move a primary skill's own observable by more than
## this share of what the primary skill itself moves it. §5.2: "IQ improves the
## circumstances in which a skill is used and cannot replace the named primary
## skill."
const MAX_AMPLIFIER_SHARE_OF_PRIMARY: float = 0.60


static func attribute_effect_direction_source() -> String:
	return _SECTION_27_2


# --- §27.2 parity tolerances -------------------------------------------------

## Team shooting percentages between equivalent execution tiers, absolute.
const PARITY_SHOOTING_ABSOLUTE: float = 0.005
## Possessions and points between Tier A and Tier B, relative.
const PARITY_POSSESSION_RELATIVE: float = 0.015
## Turnover, rebound, assist, foul, steal, block rates, relative.
const PARITY_EVENT_RELATIVE: float = 0.020
## The absolute alternative when the event is rare.
const PARITY_RARE_EVENT_ABSOLUTE: float = 0.0035
## Rotation-role mean minutes between equivalent tiers.
const PARITY_ROTATION_MINUTES: float = 0.75


static func parity_source() -> String:
	return _SECTION_27_2


# --- §27.1 required sample sizes ---------------------------------------------
#
# These are the sizes a *certifying* run must reach. A runner reports the size
# it actually used against the requirement so a smoke run can never be mistaken
# for a certification.

const _SECTION_27_1: String = "BALANCE_SPEC.md §27.1"

const REQUIRED_PROBABILITY_BOUNDARY_RESOLUTIONS: int = 100000
const REQUIRED_SENSITIVITY_RESOLUTIONS_PER_STEP: int = 50000
const REQUIRED_COMPETITION_GAMES: int = 100000
const REQUIRED_PLAY_SIM_SKIP_TRIPLETS: int = 50000
const REQUIRED_TIER_PARITY_PAIRS: int = 250000
const REQUIRED_CAREERS: int = 1000000


static func sample_size_source() -> String:
	return _SECTION_27_1


# --- §12.4 dominance rejection ----------------------------------------------

## A build is universally dominant when it is better on every major observable
## against every ordinary context. §12.4 requires rejection; the harness needs a
## numeric definition of "better", and this is it: an advantage smaller than
## this share of the observable's own spread is not counted as better.
const DOMINANCE_NOISE_SHARE: float = 0.10


static func dominance_source() -> String:
	return "BALANCE_SPEC.md §12.4, §28"


# --- performance goals -------------------------------------------------------
#
# The brief is explicit that these are calibration goals on the documented
# reference environment, not unqualified product requirements, so they are
# reported as goals and never gate a release.

const PERFORMANCE_GOAL_MS_PER_GAME: float = 10.0
const PERFORMANCE_STRETCH_MS_PER_GAME: float = 5.0


static func performance_goal_source() -> String:
	return "Stage 4 brief §8 (calibration goal, not a product requirement)"


# --- helpers -----------------------------------------------------------------

static func _row(
	competition: int,
	minimums: PackedFloat64Array,
	maximums: PackedFloat64Array,
	source: String,
) -> CalibrationBand:
	assert(competition >= 0 and competition < COMPETITION_COUNT, "unknown competition")
	return CalibrationBand.new(minimums[competition], maximums[competition], source)
