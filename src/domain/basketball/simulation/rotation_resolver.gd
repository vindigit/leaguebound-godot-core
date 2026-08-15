class_name RotationResolver
extends RefCounted


func apply_and_validate(snapshot: MatchSnapshot, input: MatchInput) -> void:
	_apply_required_substitutions(snapshot.home, input.home, input.rule_profile.personal_foul_limit)
	_apply_required_substitutions(snapshot.away, input.away, input.rule_profile.personal_foul_limit)
	_validate_team(snapshot.home, input.home, input.rule_profile.personal_foul_limit)
	_validate_team(snapshot.away, input.away, input.rule_profile.personal_foul_limit)


func _apply_required_substitutions(state: TeamMatchState, profile: TeamMatchProfile, foul_limit: int) -> void:
	for outgoing in state.runtimes:
		if not outgoing.on_court:
			continue
		if outgoing.medically_available and outgoing.foul_count < foul_limit:
			continue
		var replacement: PlayerMatchRuntime = null
		for candidate in state.runtimes:
			if candidate.on_court or not candidate.medically_available or candidate.foul_count >= foul_limit:
				continue
			if not profile.player_by_id(candidate.player_id).is_available():
				continue
			replacement = candidate
			break
		assert(replacement != null, "no eligible replacement exists for a required substitution")
		outgoing.on_court = false
		replacement.on_court = true


func _validate_team(state: TeamMatchState, profile: TeamMatchProfile, foul_limit: int) -> void:
	var on_court_count := 0
	for runtime in state.runtimes:
		if runtime.on_court:
			on_court_count += 1
			assert(runtime.medically_available, "a medically unavailable player cannot remain on court")
			assert(runtime.foul_count < foul_limit, "a player at the foul limit cannot remain on court")
			assert(profile.player_by_id(runtime.player_id).is_available(), "an unavailable player cannot be on court")
	assert(on_court_count == 5, "exactly five eligible players per team must be on court")
