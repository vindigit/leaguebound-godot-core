class_name BuilderService
extends RefCounted

## Application service for player creation (`GODOT_TDD.md` §5.8).
##
## "Validates allocation against caps, costs, and starting maxima; enforces
## budget exhaustion; commits the confirmed build in one transaction."
##
## It owns orchestration only. Every formula it needs lives in the domain —
## `BuilderRules`, `AttributeCostTable`, `CapGenerator`, `BodyMaturationPlanner`,
## `OverallCalculator`, `DevelopmentProjection`, `DerivedArchetype` — so the
## Builder screen, this service, the match engine, and NPC generation all read
## the same implementations.

const CAREER_STREAM_LABEL: StringName = &"player_system:career_generation"

var _profiles: BalanceProfileSet
var _archetype_profile: ArchetypeProfile


func _init(
	p_profiles: BalanceProfileSet = null,
	p_archetype_profile: ArchetypeProfile = null,
) -> void:
	_profiles = p_profiles if p_profiles != null else BalanceProfileSet.default_set()
	_archetype_profile = (
		p_archetype_profile if p_archetype_profile != null
		else ArchetypeProfile.default_profile()
	)


func profiles() -> BalanceProfileSet:
	return _profiles


func archetype_profile() -> ArchetypeProfile:
	return _archetype_profile


## Build the default freshman body for a family, used as the Builder's opening
## selection. The user may move every dimension inside the credible limits.
func default_body_for_family(family: int) -> BodyProfile:
	var builder: BuilderProfile = _profiles.builder
	var bounds: Array[int] = BuilderRules.height_bounds_for_family(family, builder)
	var height: int = (bounds[0] + bounds[1]) / 2
	var weight: int = BuilderRules.reference_weight_for_height(height, builder)
	var wingspan: int = height + (builder.wingspan_delta_minimum
		+ builder.wingspan_delta_maximum) / 2
	return BodyProfile.new(
		height, weight, wingspan, BodyProfile.derive_standing_reach(height, wingspan))


## Begin a build. Caps and the projected adult range are drawn here, once, from
## the career seed, and are then immutable and displayable for the whole of
## allocation.
## `ceiling_selection_pool` carries §8.1's selection pressure through to the cap
## draw. The user's own Builder always uses one — a career is not pre-selected —
## and generated populations pass the pool their competition implies.
func begin_build(
	family: int,
	prospect: int,
	maturity: int,
	body: BodyProfile,
	career_source: RandomSource,
	ceiling_selection_pool: int = 1,
) -> BuilderState:
	var failures: PackedStringArray = BuilderRules.body_selection_failures(
		body, family, _profiles.builder)
	assert(failures.is_empty(), "illegal freshman body: %s" % ", ".join(failures))

	var stream: RandomSource = career_source.derive(CAREER_STREAM_LABEL)
	var incompatible: Array[int] = CapGenerator.incompatible_attributes_for_body(
		body, _archetype_profile)
	var emphasis: Array[int] = CapGenerator.emphasis_from_family(family, incompatible)
	var caps: AttributeCaps = CapGenerator.generate(
		prospect, emphasis, stream, _profiles.progression, ceiling_selection_pool)

	var bases: Array[int] = BuilderRules.body_adjusted_bases(body, family, _profiles.builder)
	caps = _raise_caps_to_permit_bases(caps, bases)

	return BuilderState.new(
		family,
		prospect,
		maturity,
		body,
		caps,
		BodyMaturationPlanner.project_adult_range(body, _profiles.builder),
		_profiles.builder,
		_profiles.progression
	)


## A cap drawn below the body-adjusted starting base would make an attribute
## unimprovable before the user spends a single point, which §8 does not intend
## at creation. Raising the cap to the base is the conservative correction: it
## never lowers a cap, and it never grants headroom beyond the starting value
## the body already produced.
func _raise_caps_to_permit_bases(caps: AttributeCaps, bases: Array[int]) -> AttributeCaps:
	var adjusted: AttributeCaps = caps
	for attribute in AttributeKey.all():
		if adjusted.cap_for(attribute) < bases[attribute]:
			adjusted = adjusted.with_cap(attribute, bases[attribute])
	return adjusted


## Confirm the build in one transaction.
##
## Refuses while any creation AP remains (§7.1, OD-B, PRD BUILD-006). The
## returned state carries the *final spend record* of the creation budget as
## history; the career wallet starts empty, and `AttributePointLedger` rejects
## creation-sourced grants outright, so there is no route by which creation
## currency becomes career currency (§28).
func confirm(
	state: BuilderState,
	player_id: StringName,
	career_seed: int,
	career_source: RandomSource,
) -> PlayerDevelopmentState:
	var failures: PackedStringArray = state.confirmation_failures()
	assert(
		failures.is_empty(),
		"the build cannot be confirmed: %s" % ", ".join(failures)
	)

	var freshman_body: BodyProfile = state.body.duplicate_body()
	var maturation: BodyMaturationState = BodyMaturationState.new(
		freshman_body,
		state.maturity,
		state.projected_range,
		freshman_body.duplicate_body()
	)

	var confirmed: PlayerDevelopmentState = PlayerDevelopmentState.new(
		player_id,
		state.attributes(),
		state.caps.duplicate_caps(),
		maturation,
		state.prospect,
		state.family,
		career_seed,
		_profiles.version_signature(),
		FRESHMAN_AGE,
		1,
		AttributeProgress.new(),
		RotationRole.Value.DEVELOPMENTAL,
		TacticalRole.new(_default_tactical_role_for_family(state.family)),
		PlayerTendencies.new(state.tendencies.values.duplicate()),
		state.budget.duplicate_budget(),
		AttributePointLedger.new(),
		CapChangeLedger.new(),
		CareerYearReceipts.new(),
		SimulationDetailLevel.Value.FULL
	)

	for attribute in AttributeKey.all():
		confirmed.cap_ledger.record(
			1,
			attribute,
			confirmed.caps.cap_for(attribute),
			confirmed.caps.cap_for(attribute),
			CapChangeLedger.Reason.GENERATION,
			confirmed.balance_version
		)

	# §7.4.2: the exact adult body is drawn deterministically from the versioned
	# career seed at creation and stays hidden until each increment resolves.
	#
	# The drawn value is deliberately not stored. `BodyMaturationService` redraws
	# it from the same seed whenever it resolves a milestone, which is what makes
	# growth immune to reloads, detail changes, and Play/Sim choice — there is no
	# stored copy to diverge from the seed. Drawing here confirms, at the moment
	# the range becomes binding, that the range can actually produce a legal
	# body; `draw_adult_body` asserts containment.
	var _adult_body_is_reachable: BodyProfile = BodyMaturationPlanner.draw_adult_body(
		freshman_body, state.projected_range, career_source)

	return confirmed


## An opening tactical role for the family. It is a starting assignment, not an
## identity: §10.6.2 fixes exactly one active role per game and permits it to
## change between games, and the role affects opportunity only (§12.4).
func _default_tactical_role_for_family(family: int) -> int:
	match family:
		PositionFamily.Value.GUARD:
			return TacticalRole.Value.PRIMARY_CREATOR
		PositionFamily.Value.WING:
			return TacticalRole.Value.SLASHER
		_:
			return TacticalRole.Value.INTERIOR_ANCHOR


## The age at which the Builder begins: the freshman year of high school
## (`BALANCE_SPEC.md` §7.1).
const FRESHMAN_AGE: int = 14
