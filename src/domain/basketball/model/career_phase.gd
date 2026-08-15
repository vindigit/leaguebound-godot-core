class_name CareerPhase
extends RefCounted

## The eight seasonal availability phases from the `BALANCE_SPEC.md` §9.5 table,
## plus the three coarse growth-timing phases from the §7.2 prospect table.
##
## These are two different groupings of the same career and are kept distinct on
## purpose: §9.5 splits top domestic professional basketball into three age
## bands because availability falls with age, while §7.2 uses a single "pro"
## bucket because the prospect timing multiplier does not vary inside it.


## §9.5 seasonal AP-equivalent availability phases.
enum Value {
	HIGH_SCHOOL,
	SUMMER_CIRCUIT,
	COLLEGE,
	DOMESTIC_DEVELOPMENT,
	OVERSEAS,
	PRO_EARLY,
	PRO_PRIME,
	PRO_LATE,
}

const COUNT: int = 8
const IDS: PackedStringArray = [
	"high_school",
	"summer_circuit",
	"college",
	"domestic_development",
	"overseas",
	"pro_early",
	"pro_prime",
	"pro_late",
]

## §7.2 growth-timing phases.
enum GrowthPhase { HIGH_SCHOOL, COLLEGE, PRO }

const GROWTH_PHASE_COUNT: int = 3

## Age boundaries used to select a professional availability band when the
## career domain has not supplied an explicit phase.
const PRO_PRIME_FLOOR_AGE: int = 25
const PRO_LATE_FLOOR_AGE: int = 30


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown career phase")
	return StringName(IDS[value])


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown career phase id")
	return Value.HIGH_SCHOOL


## Map a §9.5 availability phase onto its §7.2 growth-timing phase.
static func growth_phase_of(phase: int) -> int:
	match phase:
		Value.HIGH_SCHOOL, Value.SUMMER_CIRCUIT:
			return GrowthPhase.HIGH_SCHOOL
		Value.COLLEGE:
			return GrowthPhase.COLLEGE
		Value.DOMESTIC_DEVELOPMENT, Value.OVERSEAS, \
		Value.PRO_EARLY, Value.PRO_PRIME, Value.PRO_LATE:
			return GrowthPhase.PRO
		_:
			assert(false, "unknown career phase")
	return GrowthPhase.PRO


## A default phase for an age, used by projection code that must reason about a
## career the career/world domain has not yet been asked about. The career
## domain remains the authority whenever it supplies a phase explicitly; this is
## a projection convenience, never a career-state decision.
static func default_phase_for_age(age: int) -> int:
	if age < 18:
		return Value.HIGH_SCHOOL
	if age < 22:
		return Value.COLLEGE
	if age < PRO_PRIME_FLOOR_AGE:
		return Value.PRO_EARLY
	if age < PRO_LATE_FLOOR_AGE:
		return Value.PRO_PRIME
	return Value.PRO_LATE
