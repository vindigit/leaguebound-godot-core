class_name AssistChainAudit
extends RefCounted

## An independent reconstruction of the passer-to-shot relationship, built from
## the ordered ledger alone (`SIMULATION_SPEC.md` §24.3).
##
## This deliberately does **not** ask the engine what it decided. It replays the
## events in sequence, rebuilds the creation chain from `PASS_COMPLETED`,
## `FIELD_GOAL_ATTEMPT`, `REBOUND`, `TURNOVER`, and possession boundaries, and
## then compares its own reconstruction with the `ASSIST` events the engine
## actually emitted. A disagreement between the two is the §24.3 property that
## matters: "every official statistic derives from an ordered domain event", so
## an assist the ledger cannot explain, or a qualifying chain the ledger
## dropped, is a defect rather than a rounding difference.
##
## The audit answers the Stage 4 assist decomposition directly: how many made
## field goals carried a live qualifying pass, how many of those were credited,
## and where the chains that did not survive were broken.

## The families whose made field goal a delivery creates rather than the shooter
## creating it for himself. Spelled as ledger action ids and mirrored here
## rather than imported from the engine, because the audit has to be able to
## disagree with the engine.
const CREATED_FAMILIES: PackedStringArray = [
	"pull_up", "off_ball_cut", "post_action", "transition_attack",
]

## Why a live creation chain stopped being available to the next shot.
enum Break {
	POSSESSION_CHANGE,
	OFFENSIVE_REBOUND,
	TURNOVER,
	SELF_CREATED_MOVE,
	REPLACED_BY_LATER_PASS,
	FREE_THROWS,
	SHOT_MISSED,
}

const BREAK_IDS: PackedStringArray = [
	"possession_change",
	"offensive_rebound",
	"turnover",
	"self_created_move",
	"replaced_by_later_pass",
	"free_throws",
	"shot_missed",
]

const UNDERSAMPLED_BELOW: int = 200

# --- headline decomposition -------------------------------------------------
var made_field_goals: int = 0
var assisted_field_goals: int = 0
var unassisted_field_goals: int = 0
var made_with_qualifying_prior_pass: int = 0
var made_with_recorded_direct_creator: int = 0
var attempts: int = 0
var pass_created_attempts: int = 0
var catch_and_shoot_attempts: int = 0
var self_created_attempts: int = 0
var qualifying_passes: int = 0
var qualifying_passes_whose_shot_scored: int = 0
var qualifying_made_shots_credited: int = 0

# --- chain health -----------------------------------------------------------
var broken_chains: Dictionary[String, int] = {}
var passes_completed: int = 0
var pass_turnovers: int = 0
var turnovers: int = 0
var assists: int = 0
var free_throws_made: int = 0

# --- reconciliation ---------------------------------------------------------
## An `ASSIST` the reconstruction cannot explain from ledger evidence.
var unexplained_assists: int = 0
## An `ASSIST` whose passer and shooter are the same player.
var self_assists: int = 0
## An `ASSIST` not immediately attached to a made field goal.
var orphan_assists: int = 0
## A made field goal carrying more than one `ASSIST`.
var duplicate_assists: int = 0
## A made field goal whose recorded assisted state disagrees with the chain the
## ledger actually contains.
var state_disagreements: int = 0
## An `ASSIST` credited to a player who is not on the scoring team.
var cross_team_assists: int = 0
## A qualifying made field goal that received no assist credit at all.
var uncredited_qualifying_makes: int = 0

# --- subgroup tables --------------------------------------------------------
var made_by_family: Dictionary[String, int] = {}
var assisted_by_family: Dictionary[String, int] = {}
var made_by_zone: Dictionary[String, int] = {}
var assisted_by_zone: Dictionary[String, int] = {}
var made_by_phase: Dictionary[String, int] = {}
var assisted_by_phase: Dictionary[String, int] = {}
var made_by_scorer_role: Dictionary[String, int] = {}
var assisted_by_scorer_role: Dictionary[String, int] = {}
var made_by_scorer_archetype: Dictionary[String, int] = {}
var assisted_by_scorer_archetype: Dictionary[String, int] = {}
var assists_by_passer_role: Dictionary[String, int] = {}
var assists_by_passer_archetype: Dictionary[String, int] = {}
var attempts_by_family: Dictionary[String, int] = {}
var pass_created_attempts_by_family: Dictionary[String, int] = {}

# --- reconciliation of team and player assists ------------------------------
var team_assist_total: int = 0
var player_assist_total: int = 0
var reconciliation_failures: int = 0
var games: int = 0

# --- live chain state (one match at a time) ---------------------------------
var _creator_id: StringName = &""
var _receiver_id: StringName = &""
var _creator_live: bool = false
var _in_transition: bool = false
var _open_make: bool = false
var _open_qualified: bool = false
var _open_credited: bool = false
var _open_family: String = ""
var _open_zone: String = ""
var _open_phase: String = ""
var _open_creator: StringName = &""
var _open_team: StringName = &""
var _role_of: Dictionary[StringName, StringName] = {}
var _archetype_of: Dictionary[StringName, StringName] = {}
var _team_of: Dictionary[StringName, StringName] = {}


func _init() -> void:
	for id_value: String in BREAK_IDS:
		broken_chains[id_value] = 0


## Replays one match's ledger and folds it into the running totals.
func accumulate(input: MatchInput, output: MatchSimulationOutput) -> void:
	games += 1
	_role_of.clear()
	_archetype_of.clear()
	_team_of.clear()
	var rosters: Array[TeamMatchProfile] = [input.home, input.away]
	for team: TeamMatchProfile in rosters:
		for player: PlayerMatchProfile in team.players:
			_role_of[player.player_id] = TacticalRole.id_of(player.tactical_role.role)
			_archetype_of[player.player_id] = RotationRole.id_of(player.rotation_role)
			_team_of[player.player_id] = team.team_id

	_reset_chain()
	_close_make()

	for event in output.events:
		_apply(event)
	_close_make()

	unassisted_field_goals = made_field_goals - assisted_field_goals

	var statistics: MatchStatistics = output.final_result.statistics
	var team_total: int = 0
	var player_total: int = 0
	for team: TeamStatLine in statistics.teams:
		team_total += team.assists
	for player: PlayerStatLine in statistics.players:
		player_total += player.assists
	team_assist_total += team_total
	player_assist_total += player_total
	if team_total != player_total:
		reconciliation_failures += 1


func _apply(event: MatchDomainEvent) -> void:
	match event.event_type:
		MatchDomainEvent.POSSESSION_STARTED:
			_close_make()
			if _creator_live:
				_break(Break.POSSESSION_CHANGE)
			_reset_chain()
		MatchDomainEvent.TRANSITION_ENTERED:
			_in_transition = true
		MatchDomainEvent.PASS_COMPLETED:
			passes_completed += 1
			if _creator_live:
				_break(Break.REPLACED_BY_LATER_PASS)
			_creator_id = event.primary_player_id
			_receiver_id = event.secondary_player_id
			_creator_live = true
		MatchDomainEvent.TURNOVER:
			if _creator_live:
				_break(Break.TURNOVER)
			_creator_live = false
			turnovers += 1
			if (
				event.detail_id == TurnoverCause.id_of(TurnoverCause.Value.BAD_PASS)
				or event.detail_id == TurnoverCause.id_of(TurnoverCause.Value.INTERCEPTION)
			):
				pass_turnovers += 1
		MatchDomainEvent.REBOUND:
			if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
				if _creator_live:
					_break(Break.OFFENSIVE_REBOUND)
				_creator_live = false
		MatchDomainEvent.FREE_THROW_AWARDED:
			if _creator_live:
				_break(Break.FREE_THROWS)
			_creator_live = false
		MatchDomainEvent.FREE_THROW_MADE:
			free_throws_made += 1
		MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			attempts += 1
			_bump(attempts_by_family, String(event.action_id))
			if _qualifies(event.primary_player_id, event.action_id):
				pass_created_attempts += 1
				qualifying_passes += 1
				_bump(pass_created_attempts_by_family, String(event.action_id))
				if event.action_id == &"pull_up":
					catch_and_shoot_attempts += 1
			else:
				self_created_attempts += 1
				if _creator_live and _receiver_id == event.primary_player_id:
					_break(Break.SELF_CREATED_MOVE)
		MatchDomainEvent.FIELD_GOAL_MADE:
			_close_make()
			made_field_goals += 1
			_open_make = true
			_open_credited = false
			_open_family = String(event.action_id)
			_open_zone = String(event.zone_id)
			_open_phase = "transition" if _in_transition else "half_court"
			_open_team = event.team_id
			_open_creator = _creator_id if _creator_live else &""
			_open_qualified = _qualifies(event.primary_player_id, event.action_id)
			if _open_qualified:
				made_with_qualifying_prior_pass += 1
				qualifying_passes_whose_shot_scored += 1
			if event.detail_id != &"unassisted":
				made_with_recorded_direct_creator += 1
			_bump(made_by_family, _open_family)
			_bump(made_by_zone, _open_zone)
			_bump(made_by_phase, _open_phase)
			_bump(made_by_scorer_role, _role(event.primary_player_id))
			_bump(made_by_scorer_archetype, _archetype(event.primary_player_id))
			_open_scorer = event.primary_player_id
		MatchDomainEvent.FIELD_GOAL_MISSED:
			if _creator_live:
				_break(Break.SHOT_MISSED)
			_creator_live = false
		MatchDomainEvent.ASSIST:
			assists += 1
			if not _open_make:
				orphan_assists += 1
				return
			if _open_credited:
				duplicate_assists += 1
				return
			_open_credited = true
			assisted_field_goals += 1
			_bump(assisted_by_family, _open_family)
			_bump(assisted_by_zone, _open_zone)
			_bump(assisted_by_phase, _open_phase)
			_bump(assisted_by_scorer_role, _role(event.secondary_player_id))
			_bump(assisted_by_scorer_archetype, _archetype(event.secondary_player_id))
			_bump(assists_by_passer_role, _role(event.primary_player_id))
			_bump(assists_by_passer_archetype, _archetype(event.primary_player_id))
			if event.primary_player_id == event.secondary_player_id:
				self_assists += 1
			if event.secondary_player_id != _open_scorer:
				orphan_assists += 1
			var passer_team: StringName = _team_of.get(event.primary_player_id, &"")
			if passer_team != _open_team:
				cross_team_assists += 1
			if not _open_qualified or event.primary_player_id != _open_creator:
				unexplained_assists += 1
		_:
			pass


var _open_scorer: StringName = &""


func _reset_chain() -> void:
	_creator_id = &""
	_receiver_id = &""
	_creator_live = false
	_in_transition = false


## A chain qualifies when a live pass reached this shooter, the shooter is not
## the passer, and the shot's own family is one the delivery created rather than
## one the shooter created for himself.
func _qualifies(shooter_id: StringName, family_id: StringName) -> bool:
	if not _creator_live or _creator_id.is_empty():
		return false
	if _creator_id == shooter_id:
		return false
	if _receiver_id != shooter_id:
		return false
	return CREATED_FAMILIES.has(String(family_id))


func _close_make() -> void:
	if not _open_make:
		return
	if _open_qualified:
		if _open_credited:
			qualifying_made_shots_credited += 1
		else:
			uncredited_qualifying_makes += 1
	if _open_qualified != _open_credited:
		state_disagreements += 1
	_open_make = false
	_open_credited = false
	_open_qualified = false
	_open_scorer = &""


func _break(reason: int) -> void:
	var key: String = BREAK_IDS[reason]
	var current: int = broken_chains.get(key, 0)
	broken_chains[key] = current + 1


func _role(player_id: StringName) -> String:
	var id_value: StringName = _role_of.get(player_id, &"unknown")
	return String(id_value)


func _archetype(player_id: StringName) -> String:
	var id_value: StringName = _archetype_of.get(player_id, &"unknown")
	return String(id_value)


static func _bump(table: Dictionary[String, int], key: String) -> void:
	var current: int = table.get(key, 0)
	table[key] = current + 1


# --- derived ----------------------------------------------------------------

func assist_percentage() -> float:
	return _ratio(float(assists), float(made_field_goals))


## The §14.3 conditional: of the qualifying passes whose shot scored, the share
## that became a credited assist.
func credit_conversion() -> float:
	return _ratio(
		float(qualifying_made_shots_credited), float(qualifying_passes_whose_shot_scored))


func pass_created_attempt_share() -> float:
	return _ratio(float(pass_created_attempts), float(attempts))


func catch_and_shoot_share() -> float:
	return _ratio(float(catch_and_shoot_attempts), float(attempts))


func self_created_share() -> float:
	return _ratio(float(self_created_attempts), float(attempts))


func pass_turnover_rate() -> float:
	return _ratio(float(pass_turnovers), float(passes_completed + pass_turnovers))


func assist_to_turnover() -> float:
	return _ratio(float(assists), float(turnovers))


func identity_holds() -> bool:
	return assisted_field_goals + unassisted_field_goals == made_field_goals


func total_broken_chains() -> int:
	var total: int = 0
	for key: String in BREAK_IDS:
		var count: int = broken_chains.get(key, 0)
		total += count
	return total


func rate_rows(made: Dictionary[String, int], assisted: Dictionary[String, int]) -> Array:
	var keys: Array = made.keys()
	keys.sort()
	var rows: Array = []
	for key: String in keys:
		var total: int = made.get(key, 0)
		var credited: int = assisted.get(key, 0)
		rows.append({
			"group": key,
			"made_field_goals": total,
			"assisted": credited,
			"assisted_rate": _ratio(float(credited), float(total)),
			"undersampled": total < UNDERSAMPLED_BELOW,
		})
	return rows


func share_rows(table: Dictionary[String, int]) -> Array:
	var keys: Array = table.keys()
	keys.sort()
	var rows: Array = []
	var total: int = 0
	for key: String in keys:
		var count: int = table.get(key, 0)
		total += count
	for key: String in keys:
		var count: int = table.get(key, 0)
		rows.append({
			"group": key,
			"count": count,
			"share": _ratio(float(count), float(total)),
			"undersampled": count < UNDERSAMPLED_BELOW,
		})
	return rows


func break_rows() -> Array:
	var rows: Array = []
	for id_value: String in BREAK_IDS:
		var count: int = broken_chains.get(id_value, 0)
		rows.append({"reason": id_value, "count": count})
	return rows


static func _ratio(numerator: float, denominator: float) -> float:
	return 0.0 if denominator <= 0.0 else numerator / denominator
