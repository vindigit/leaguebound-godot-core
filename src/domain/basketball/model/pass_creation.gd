class_name PassCreation
extends RefCounted

## The live passer-to-shot relationship inside one possession
## (`SIMULATION_SPEC.md` §11.3).
##
## §11.3 requires a pass event to record its passer and receiver, its risk
## family, the openness it produced, the catch quality, the defensive rotation
## it caused, and **whether it directly created the eventual shot**. The last of
## those is not a property of the pass alone: it is settled when the shot
## resolves, by asking whether the man who caught the ball is the man who shot
## it and whether he shot what the delivery gave him or something he made for
## himself.
##
## This record is that relationship while it is still live. It exists for
## exactly as long as it is true:
##
## - a shot consumes it, made or missed;
## - a later pass replaces it;
## - a possession change, a turnover, an offensive rebound, a reset, or a
##   free-throw sequence ends it;
## - a receiver who creates his own shot ends it by doing so.
##
## Nothing here decides an assist by itself. `creates_shot_for` states the
## relationship; the engine still has to resolve the §14.3 conditional against
## the passer's execution before any credit is emitted.

## The families whose attempt is the *delivery's* product rather than the
## shooter's own creation.
##
## A pull-up off a catch is the catch-and-shoot. An off-ball cut or a roll is
## finished on the move off the feed that sprang it. A transition attack by the
## man who just caught a pass ahead is the outlet finishing. A drive, a pick
## action, a post move, or a putback is the shooter creating for himself, and
## the pass that preceded it created a touch rather than a shot.
const DELIVERED_FAMILIES: PackedInt32Array = [
	ActionFamily.Value.PULL_UP,
	ActionFamily.Value.OFF_BALL_CUT,
	ActionFamily.Value.TRANSITION_ATTACK,
]

## Assisted states, matching `SIMULATION_SPEC.md` §12.1 `ShotIntent`.
const UNASSISTED: StringName = &"unassisted"
const CREATED: StringName = &"created"
const CATCH_AND_SHOOT: StringName = &"catch_and_shoot"

var live: bool
var passer_id: StringName
var receiver_id: StringName
## The §11.1 advantage the delivery produced: this is the receiver's openness
## after the catch.
var advantage_level: int
## §12.2 catch/pass quality, settled at delivery from the passer's execution.
var catch_quality: float
## The defender the delivery moved, recorded so §11.3's "defensive rotation
## caused" is in the ledger rather than implied.
var rotated_defender_id: StringName
## The competition's own §11.3 credited-assist rule, carried on the record so
## the engine cannot apply a rule the rule profile did not give it.
var credited_families: PackedInt32Array


func _init(
	p_passer_id: StringName = &"",
	p_receiver_id: StringName = &"",
	p_advantage_level: int = AdvantageLevel.Value.NONE,
	p_catch_quality: float = 1.0,
	p_rotated_defender_id: StringName = &"",
	p_credited_families: PackedInt32Array = DELIVERED_FAMILIES,
) -> void:
	live = not p_passer_id.is_empty()
	passer_id = p_passer_id
	receiver_id = p_receiver_id
	advantage_level = p_advantage_level
	catch_quality = p_catch_quality
	rotated_defender_id = p_rotated_defender_id
	credited_families = p_credited_families


static func none() -> PassCreation:
	return PassCreation.new()


## Whether the delivery is still the thing that would produce this shooter's
## attempt. Three conditions, all of them ledger-visible:
##
## - the record is live — nothing has invalidated the play;
## - the ball reached *this* shooter, not a team-mate two passes ago;
## - the passer and the shooter are different players.
func reaches(shooter_id: StringName) -> bool:
	return (
		live
		and not passer_id.is_empty()
		and passer_id != shooter_id
		and receiver_id == shooter_id
	)


## Whether this delivery directly created the attempt about to be taken.
func creates_shot_for(shooter_id: StringName, action_family: int) -> bool:
	return reaches(shooter_id) and credited_families.has(action_family)


## §12.1 `ShotIntent.assistedState`.
##
## `CATCH_AND_SHOOT` is a shot taken off the catch; `CREATED` is one the
## delivery produced but the shooter finished on the move; `UNASSISTED` covers
## everything the shooter made for himself, including a shot he created after
## catching an ordinary pass.
func assisted_state(shooter_id: StringName, action_family: int) -> StringName:
	if not creates_shot_for(shooter_id, action_family):
		return UNASSISTED
	if action_family == ActionFamily.Value.PULL_UP:
		return CATCH_AND_SHOOT
	return CREATED


## The creator recorded on the shot event, or empty when the shooter created the
## attempt himself.
func creator_for(shooter_id: StringName, action_family: int) -> StringName:
	return passer_id if creates_shot_for(shooter_id, action_family) else &""


## The openness the delivery produced, as the §11.1 quality share.
func openness() -> float:
	return AdvantageLevel.quality_share(advantage_level) if live else 0.0


func is_material() -> bool:
	return live and advantage_level >= AdvantageLevel.Value.CLEAR
