class_name RoleOpportunityTable
extends RefCounted

## Tactical role's entire numeric privilege (`BALANCE_SPEC.md` §12.4).
##
## §12.4: "`RoleOpportunity` stays inside its existing 0.60-1.50 ordinary and
## 0.35-1.80 exceptional bounds. Tactical role is the primary contributor to
## that factor and gains no separate multiplier elsewhere in the resolution
## chain. Role therefore changes how often a player attempts something, never
## how well it goes."
##
## This table is the one place tactical role becomes a number. Every entry is an
## opportunity emphasis for one (role, action family) pair, and the rows follow
## the "Primary opportunity effect" column of `SIMULATION_SPEC.md` §10.6.2. A
## pair with no entry is neutral at 1.0, which is why the table is sparse rather
## than an eleven-by-twelve grid of mostly-ones.
##
## Two rules are enforced structurally rather than by review:
##
## - No entry may leave the §12.2 exceptional band, so no role can silently
##   become a hard gate. §10.6.2: "A tactical role never gates action validity.
##   A `shooter` may drive and a `roll_pop_big` may pass."
## - Nothing outside this table may read a tactical role while resolving a
##   capability, probability, contest, rebound score, turnover, or foul.

const NEUTRAL: float = 1.0
const EXCEPTIONAL_MINIMUM: float = 0.35
const EXCEPTIONAL_MAXIMUM: float = 1.80

## Rows are `[tactical role, action family, opportunity multiplier]`.
const EMPHASIS: Array = [
	# Primary Creator — on-ball initiation, pick-and-roll handling, late-clock creation.
	[TacticalRole.Value.PRIMARY_CREATOR, ActionFamily.Value.PICK_ACTION, 1.45],
	[TacticalRole.Value.PRIMARY_CREATOR, ActionFamily.Value.DRIVE, 1.30],
	[TacticalRole.Value.PRIMARY_CREATOR, ActionFamily.Value.PULL_UP, 1.22],
	[TacticalRole.Value.PRIMARY_CREATOR, ActionFamily.Value.PASS_SWING, 1.12],
	[TacticalRole.Value.PRIMARY_CREATOR, ActionFamily.Value.RELOCATION, 0.80],
	[TacticalRole.Value.PRIMARY_CREATOR, ActionFamily.Value.SCREEN, 0.75],
	# Secondary Creator — secondary initiation, attacking closeouts, advantage continuation.
	[TacticalRole.Value.SECONDARY_CREATOR, ActionFamily.Value.DRIVE, 1.32],
	[TacticalRole.Value.SECONDARY_CREATOR, ActionFamily.Value.PICK_ACTION, 1.15],
	[TacticalRole.Value.SECONDARY_CREATOR, ActionFamily.Value.PULL_UP, 1.12],
	[TacticalRole.Value.SECONDARY_CREATOR, ActionFamily.Value.PASS_SWING, 1.10],
	[TacticalRole.Value.SECONDARY_CREATOR, ActionFamily.Value.SCREEN, 0.85],
	# Shooter — spot-up and relocation volume, off-screen usage.
	[TacticalRole.Value.SHOOTER, ActionFamily.Value.RELOCATION, 1.45],
	[TacticalRole.Value.SHOOTER, ActionFamily.Value.PULL_UP, 1.30],
	[TacticalRole.Value.SHOOTER, ActionFamily.Value.OFF_BALL_CUT, 1.05],
	[TacticalRole.Value.SHOOTER, ActionFamily.Value.DRIVE, 0.88],
	[TacticalRole.Value.SHOOTER, ActionFamily.Value.POST_ACTION, 0.70],
	# Slasher — cutting, driving lanes, rim attempts off advantage.
	[TacticalRole.Value.SLASHER, ActionFamily.Value.OFF_BALL_CUT, 1.48],
	[TacticalRole.Value.SLASHER, ActionFamily.Value.DRIVE, 1.38],
	[TacticalRole.Value.SLASHER, ActionFamily.Value.TRANSITION_ATTACK, 1.25],
	[TacticalRole.Value.SLASHER, ActionFamily.Value.PULL_UP, 0.80],
	# Connector — swing passing, short-roll reads, ball-movement continuity.
	[TacticalRole.Value.CONNECTOR, ActionFamily.Value.PASS_SWING, 1.42],
	[TacticalRole.Value.CONNECTOR, ActionFamily.Value.HANDOFF, 1.32],
	[TacticalRole.Value.CONNECTOR, ActionFamily.Value.RELOCATION, 1.10],
	[TacticalRole.Value.CONNECTOR, ActionFamily.Value.PULL_UP, 0.86],
	# Post Option — post entries, seals, interior attempts.
	[TacticalRole.Value.POST_OPTION, ActionFamily.Value.POST_ACTION, 1.50],
	[TacticalRole.Value.POST_OPTION, ActionFamily.Value.SCREEN, 1.05],
	[TacticalRole.Value.POST_OPTION, ActionFamily.Value.PULL_UP, 0.82],
	[TacticalRole.Value.POST_OPTION, ActionFamily.Value.DRIVE, 0.86],
	# Roll/Pop Big — screen setting, roll and pop continuations.
	[TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.SCREEN, 1.48],
	[TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.PICK_ACTION, 1.34],
	[TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.RELOCATION, 1.08],
	[TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.DRIVE, 0.76],
	[TacticalRole.Value.ROLL_POP_BIG, ActionFamily.Value.PASS_SWING, 0.86],
	# Perimeter Stopper — a defensive assignment; offensive opportunity is modest.
	[TacticalRole.Value.PERIMETER_STOPPER, ActionFamily.Value.RELOCATION, 1.08],
	[TacticalRole.Value.PERIMETER_STOPPER, ActionFamily.Value.PICK_ACTION, 0.82],
	[TacticalRole.Value.PERIMETER_STOPPER, ActionFamily.Value.PULL_UP, 0.88],
	[TacticalRole.Value.PERIMETER_STOPPER, ActionFamily.Value.POST_ACTION, 0.80],
	# Interior Anchor — rim protection responsibility, help positioning priority.
	[TacticalRole.Value.INTERIOR_ANCHOR, ActionFamily.Value.SCREEN, 1.22],
	[TacticalRole.Value.INTERIOR_ANCHOR, ActionFamily.Value.POST_ACTION, 1.06],
	[TacticalRole.Value.INTERIOR_ANCHOR, ActionFamily.Value.PULL_UP, 0.70],
	[TacticalRole.Value.INTERIOR_ANCHOR, ActionFamily.Value.DRIVE, 0.72],
	# Rebounder — crash and box-out priority on both glasses.
	[TacticalRole.Value.REBOUNDER, ActionFamily.Value.PUTBACK, 1.35],
	[TacticalRole.Value.REBOUNDER, ActionFamily.Value.SCREEN, 1.12],
	[TacticalRole.Value.REBOUNDER, ActionFamily.Value.OFF_BALL_CUT, 1.06],
	[TacticalRole.Value.REBOUNDER, ActionFamily.Value.PULL_UP, 0.76],
	# Utility/Energy — flexible assignment, effort actions, matchup coverage.
	[TacticalRole.Value.UTILITY_ENERGY, ActionFamily.Value.OFF_BALL_CUT, 1.10],
	[TacticalRole.Value.UTILITY_ENERGY, ActionFamily.Value.SCREEN, 1.08],
]

var _table: PackedFloat64Array


func _init() -> void:
	_table = PackedFloat64Array()
	_table.resize(TacticalRole.COUNT * ActionFamily.COUNT)
	_table.fill(NEUTRAL)
	for row: Array in EMPHASIS:
		var role: int = row[0]
		var family: int = row[1]
		var value: float = row[2]
		assert(TacticalRole.is_valid(role), "unknown tactical role in the opportunity table")
		assert(ActionFamily.is_valid(family), "unknown action family in the opportunity table")
		assert(value >= EXCEPTIONAL_MINIMUM and value <= EXCEPTIONAL_MAXIMUM,
			"BALANCE_SPEC §12.2 bounds role opportunity at 0.35-1.80 even exceptionally")
		_table[_offset(role, family)] = value


func opportunity(tactical_role: int, action_family: int) -> float:
	assert(TacticalRole.is_valid(tactical_role), "unknown tactical role")
	assert(ActionFamily.is_valid(action_family), "unknown action family")
	return _table[_offset(tactical_role, action_family)]


## Every role must retain a non-zero, non-gating opportunity for every family:
## a role changes how often, never whether.
func validate() -> PackedStringArray:
	var failures: PackedStringArray = []
	for role in TacticalRole.all():
		for family in ActionFamily.all():
			var value: float = opportunity(role, family)
			if value < EXCEPTIONAL_MINIMUM or value > EXCEPTIONAL_MAXIMUM:
				failures.append("role opportunity out of bounds for %s/%s" % [
					TacticalRole.id_of(role), ActionFamily.id_of(family)])
	return failures


func _offset(tactical_role: int, action_family: int) -> int:
	return tactical_role * ActionFamily.COUNT + action_family
