class_name PlayerMatchProfile
extends RefCounted


var player_id: StringName
var positions: PositionProfile
var body: BodyProfile
var attributes: PlayerAttributes
var badges: Array[ActiveBadgeView]
var tendencies: PlayerTendencies
var rotation_role: RotationRole.Value
var tactical_role: TacticalRole
var condition: float
var injury_limitations: Array[InjuryLimitation]
var qualitative_durability_band: StringName


func _init(
	p_player_id: StringName = &"player",
	p_positions: PositionProfile = null,
	p_body: BodyProfile = null,
	p_attributes: PlayerAttributes = null,
	p_badges: Array[ActiveBadgeView] = [],
	p_tendencies: PlayerTendencies = null,
	p_rotation_role: RotationRole.Value = RotationRole.Value.ROTATION,
	p_tactical_role: TacticalRole = null,
	p_condition: float = 1.0,
	p_injury_limitations: Array[InjuryLimitation] = [],
	p_qualitative_durability_band: StringName = &"average",
) -> void:
	assert(not p_player_id.is_empty(), "player identity is required")
	assert(p_condition >= 0.0 and p_condition <= 1.0, "condition must be normalized")
	player_id = p_player_id
	positions = p_positions if p_positions != null else PositionProfile.new()
	body = p_body if p_body != null else BodyProfile.new()
	attributes = p_attributes if p_attributes != null else PlayerAttributes.new()
	badges = p_badges.duplicate()
	tendencies = p_tendencies if p_tendencies != null else PlayerTendencies.new()
	rotation_role = p_rotation_role
	tactical_role = p_tactical_role if p_tactical_role != null else TacticalRole.new()
	condition = p_condition
	injury_limitations = p_injury_limitations.duplicate()
	qualitative_durability_band = p_qualitative_durability_band


func is_available() -> bool:
	for limitation in injury_limitations:
		if limitation.unavailable:
			return false
	return condition > 0.0
