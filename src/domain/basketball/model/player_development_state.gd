class_name PlayerDevelopmentState
extends RefCounted

## Every stored player-system career fact in one record (`GODOT_TDD.md` §5.7).
##
## This is the unit of detail-promotion invariance. §9.7.4 states the rule
## plainly: "Changing a player's simulation detail level must not change the
## player." Promotion or demotion may add or drop *evidence resolution*; it may
## never alter current ratings, caps, body, maturity state, accumulated
## development, or committed history. `invariant_signature` is the exact
## comparison that Gate B3 requires, and it deliberately excludes ledger
## granularity — which is evidence — while including everything that is state.
##
## Derived and never stored as authority (§5.7): Current Overall, Maximum
## Potential Overall, Projected Peak, derived archetype, derived position
## labels. None of them appear as fields here.

const SCHEMA_VERSION: int = 1

var player_id: StringName
var attributes: PlayerAttributes
var caps: AttributeCaps
var progress: AttributeProgress
## Fractional decline accrued but not yet resolved into a whole point.
## `BALANCE_SPEC.md` §10.3: "Fractional decline accumulates invisibly until a
## whole point resolves." Stored, like fractional progress, because §29.3
## requires hidden fractional state to survive migrations.
var decline_debt: AttributeProgress
var body_state: BodyMaturationState
var prospect: int
var position_family: int
var rotation_role: int
var tactical_role: TacticalRole
var tendencies: PlayerTendencies
var creation_budget: CreationBudget
var point_ledger: AttributePointLedger
var cap_ledger: CapChangeLedger
var receipts: CareerYearReceipts
var age: int
var career_year: int
## The versioned career seed. Growth and cap generation are functions of this
## seed, career-year identity, and stored state (§7.4.3 rule 1), so reloading,
## changing simulation detail, Play/Sim choice, or device cannot reroll them.
var career_seed: int
var balance_version: String
var detail_level: int


func _init(
	p_player_id: StringName,
	p_attributes: PlayerAttributes,
	p_caps: AttributeCaps,
	p_body_state: BodyMaturationState,
	p_prospect: int,
	p_position_family: int,
	p_career_seed: int,
	p_balance_version: String,
	p_age: int = 14,
	p_career_year: int = 1,
	p_progress: AttributeProgress = null,
	p_rotation_role: int = RotationRole.Value.DEVELOPMENTAL,
	p_tactical_role: TacticalRole = null,
	p_tendencies: PlayerTendencies = null,
	p_creation_budget: CreationBudget = null,
	p_point_ledger: AttributePointLedger = null,
	p_cap_ledger: CapChangeLedger = null,
	p_receipts: CareerYearReceipts = null,
	p_detail_level: int = SimulationDetailLevel.Value.FULL,
	p_decline_debt: AttributeProgress = null,
) -> void:
	assert(not p_player_id.is_empty(), "player identity is required")
	assert(p_attributes != null and p_caps != null and p_body_state != null,
		"ratings, caps, and body state are all stored career facts and are all required")
	assert(ProspectProfile.is_valid(p_prospect), "unknown prospect profile")
	assert(PositionFamily.is_valid(p_position_family), "unknown position family")
	assert(RotationRole.is_valid(p_rotation_role), "unknown rotation role")
	assert(SimulationDetailLevel.is_valid(p_detail_level), "unknown simulation detail level")
	assert(not p_balance_version.is_empty(), "a career is pinned to a balance-profile version")
	assert(p_career_year > 0, "career years are one-based")

	player_id = p_player_id
	attributes = p_attributes
	caps = p_caps
	body_state = p_body_state
	prospect = p_prospect
	position_family = p_position_family
	career_seed = p_career_seed
	balance_version = p_balance_version
	age = p_age
	career_year = p_career_year
	progress = p_progress if p_progress != null else AttributeProgress.new()
	decline_debt = p_decline_debt if p_decline_debt != null else AttributeProgress.new()
	detail_level = p_detail_level
	rotation_role = p_rotation_role
	tactical_role = p_tactical_role if p_tactical_role != null else TacticalRole.new()
	tendencies = p_tendencies if p_tendencies != null else PlayerTendencies.new()
	creation_budget = p_creation_budget
	point_ledger = p_point_ledger if p_point_ledger != null else AttributePointLedger.new()
	cap_ledger = p_cap_ledger if p_cap_ledger != null else CapChangeLedger.new()
	receipts = p_receipts if p_receipts != null else CareerYearReceipts.new()


func body() -> BodyProfile:
	return body_state.realized_body


## The exact comparison required by `BALANCE_SPEC.md` §9.7.4 and Gate B3.
##
## Includes: ratings, caps, body and maturity state, hidden fractional progress,
## receipts, and the identity layers. Excludes: ledger *granularity*, because
## §9.7.3 explicitly permits an aggregate executor to write coarser entries than
## the full-detail allocator. Totals are included; entry counts are not.
func invariant_signature() -> String:
	var parts: PackedStringArray = []
	parts.append("id=%s" % player_id)
	parts.append("age=%d" % age)
	parts.append("year=%d" % career_year)
	parts.append("ratings[%s]" % attributes.signature())
	parts.append("caps[%s]" % caps.signature())
	parts.append("body[%s]" % body_state.signature())
	parts.append("prospect=%s" % ProspectProfile.id_of(prospect))
	parts.append("family=%s" % PositionFamily.id_of(position_family))
	parts.append("rotation=%s" % RotationRole.id_of(rotation_role))
	parts.append("tactical=%s" % tactical_role.id())
	parts.append("receipts[%s]" % receipts.signature())
	var progress_parts: PackedStringArray = []
	for attribute in AttributeKey.all():
		progress_parts.append("%.6f" % progress.units_for(attribute))
	parts.append("progress[%s]" % ",".join(progress_parts))
	var decline_parts: PackedStringArray = []
	for attribute in AttributeKey.all():
		decline_parts.append("%.6f" % decline_debt.units_for(attribute))
	parts.append("decline[%s]" % ",".join(decline_parts))
	parts.append("wallet=%.6f" % point_ledger.balance())
	parts.append("granted=%.6f" % point_ledger.total_granted())
	parts.append("spent=%.6f" % point_ledger.total_spent())
	return "|".join(parts)


func duplicate_state() -> PlayerDevelopmentState:
	return PlayerDevelopmentState.new(
		player_id,
		attributes.duplicate_attributes(),
		caps.duplicate_caps(),
		body_state.duplicate_state(),
		prospect,
		position_family,
		career_seed,
		balance_version,
		age,
		career_year,
		progress.duplicate_progress(),
		rotation_role,
		TacticalRole.new(tactical_role.role),
		PlayerTendencies.new(tendencies.values.duplicate()),
		creation_budget.duplicate_budget() if creation_budget != null else null,
		point_ledger.duplicate_ledger(),
		cap_ledger.duplicate_ledger(),
		receipts.duplicate_receipts(),
		detail_level,
		decline_debt.duplicate_progress()
	)
