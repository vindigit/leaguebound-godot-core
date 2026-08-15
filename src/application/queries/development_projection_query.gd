class_name DevelopmentProjectionQuery
extends RefCounted

## The single read path supplying the three development values and the archetype
## to presentation (`GODOT_TDD.md` §5.8).
##
## Presentation receives an immutable view model and renders it as received.
## §6.2 makes a Builder or development screen that recomputes Overall, an
## archetype, a cost table, caps, remaining budget, or a projected body range a
## dependency violation and a release blocker — "even when its arithmetic
## happens to agree".
##
## ## Caching
##
## `GODOT_TDD.md` §5.5 rule 1 permits a cached copy for query performance,
## "invalidated on any rating, cap, or body change", and never the value a rule
## reads. The cache here is keyed on a signature of exactly those inputs, so a
## stale entry cannot be served: if any of them moved, the key moved with it.

var _profiles: BalanceProfileSet
var _archetype_profile: ArchetypeProfile
var _cache: Dictionary


func _init(
	p_profiles: BalanceProfileSet = null,
	p_archetype_profile: ArchetypeProfile = null,
) -> void:
	_profiles = p_profiles if p_profiles != null else BalanceProfileSet.default_set()
	_archetype_profile = (
		p_archetype_profile if p_archetype_profile != null
		else ArchetypeProfile.default_profile()
	)
	_cache = {}


func projection_for(
	state: PlayerDevelopmentState,
	opportunity_scale: float = 1.0,
	historical_peak_overall: int = -1,
) -> DevelopmentProjection:
	var key: String = _cache_key(state, opportunity_scale, historical_peak_overall)
	if _cache.has(key):
		return _cache[key] as DevelopmentProjection
	var projection: DevelopmentProjection = DevelopmentProjection.of_state(
		state, _profiles.ratings, _profiles.progression,
		opportunity_scale, historical_peak_overall)
	_cache[key] = projection
	return projection


func archetype_for(state: PlayerDevelopmentState) -> DerivedArchetype:
	return DerivedArchetype.classify(
		state.attributes, state.body(), state.position_family, _archetype_profile)


## The complete Builder confirmation view model (`BALANCE_SPEC.md` §7.3.2).
##
## "The confirmation screen reports Current Overall, Maximum Potential,
## Projected Peak, all exact caps, the projected adult body range, archetype
## description, likely behavioral profile, and all allocations, using the
## distinct labels required by §6.3. It does not label a legal build as bad."
func builder_confirmation_view(
	state: BuilderState,
	age: int = BuilderService.FRESHMAN_AGE,
) -> BuilderConfirmationView:
	var attributes: PlayerAttributes = state.attributes()
	var projection: DevelopmentProjection = DevelopmentProjection.of_player(
		attributes, state.caps, state.prospect, age,
		_profiles.ratings, _profiles.progression)
	var archetype: DerivedArchetype = DerivedArchetype.classify(
		attributes, state.body, state.family, _archetype_profile)

	return BuilderConfirmationView.new(
		projection,
		archetype,
		state.caps.duplicate_caps(),
		state.projected_range.duplicate_range(),
		attributes,
		state.budget.duplicate_budget(),
		archetype.position_noun,
		_opportunity_notes(state),
		state.can_confirm(),
		state.confirmation_failures()
	)


## Informational opportunity notes.
##
## §7.3.2 and `GDD.md` §6.1 forbid labelling a legal build good or bad, and the
## Stage 2 brief permits exactly one kind of note: "Informational notes such as
## rare rim-protection opportunities at a given body are allowed." These
## describe what the *world* will offer, never what the build is worth.
func _opportunity_notes(state: BuilderState) -> PackedStringArray:
	var notes: PackedStringArray = []
	var incompatible: Array[int] = CapGenerator.incompatible_attributes_for_body(
		state.body, _archetype_profile)
	for attribute in incompatible:
		match attribute:
			AttributeKey.Key.BLOCKING:
				notes.append(
					"Rim-protection opportunities are rare at this height;"
					+ " shot-blocking chances will arrive less often than for a taller player.")
			AttributeKey.Key.INTERIOR_DEFENSE:
				notes.append(
					"Interior assignments are less common at this height;"
					+ " expect more perimeter matchups.")
			AttributeKey.Key.HANDLE:
				notes.append(
					"On-ball creation opportunities are less common at this height;"
					+ " expect fewer primary-handler possessions.")
			_:
				pass
	return notes


func invalidate() -> void:
	_cache.clear()


## The cache key covers exactly what §5.5 rule 1 requires invalidation on —
## ratings, caps, and body — plus the projection inputs that can move
## independently of them.
##
## Body is included even though the projected-peak model does not currently read
## it, because §5.5 names body as an invalidation trigger. Keying on it costs
## nothing and means a later change that does consult body cannot silently start
## serving stale projections.
func _cache_key(
	state: PlayerDevelopmentState,
	opportunity_scale: float,
	historical_peak_overall: int,
) -> String:
	return "%s|%s|%s|%s|%d|%d|%.4f|%d" % [
		state.player_id,
		state.attributes.signature(),
		state.caps.signature(),
		state.body().signature(),
		state.age,
		state.prospect,
		opportunity_scale,
		historical_peak_overall,
	]
