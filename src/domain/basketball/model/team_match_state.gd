class_name TeamMatchState
extends RefCounted

## Authoritative mutable team state (`SIMULATION_SPEC.md` §5).
##
## The runtime lineup here is the **sole** authority for who is participating.
## Every participant selector, matchup resolver, and rebound candidate list
## reads `on_court_ids()`; none of them may read the static starter list.

var team_id: StringName
var score: int
## Team fouls in the current period, which drive the bonus (§13.2).
var team_fouls: int
## Team fouls across the whole game, for the box score.
var total_team_fouls: int
## Points scored in each period, one entry per completed or live period.
var period_scores: Array[int]
## Terminal possession records this team has completed (§24.2 engine
## possessions). Counted from possession termination, never estimated.
var possessions: int
## §5 `TimeoutState`: charged timeouts this team has left.
var timeouts_remaining: int
## §18.2 score and time: whether this coach is protecting a settled lead,
## conceding a settled deficit, or playing his ordinary rotation. Written only
## by `MatchStateReducer` from a `GARBAGE_TIME` event, so the state a rotation
## decision reads is the state the ledger explains.
var settled_mode: int
var runtimes: Array[PlayerMatchRuntime]
var _index: Dictionary


func _init(profile: TeamMatchProfile = null) -> void:
	team_id = &""
	score = 0
	team_fouls = 0
	total_team_fouls = 0
	period_scores = [0]
	possessions = 0
	timeouts_remaining = 0
	settled_mode = GarbageTimeRule.Mode.NONE
	runtimes = []
	_index = {}
	if profile == null:
		return
	team_id = profile.team_id
	var starters: Array[StringName] = profile.starters()
	for player in profile.players:
		var runtime := PlayerMatchRuntime.new(player.player_id, starters.has(player.player_id))
		runtimes.append(runtime)
		_index[player.player_id] = runtime


func copy() -> TeamMatchState:
	var result := TeamMatchState.new()
	result.team_id = team_id
	result.score = score
	result.team_fouls = team_fouls
	result.total_team_fouls = total_team_fouls
	result.period_scores = period_scores.duplicate()
	result.possessions = possessions
	result.timeouts_remaining = timeouts_remaining
	result.settled_mode = settled_mode
	result.runtimes = []
	result._index = {}
	for runtime in runtimes:
		var copied := runtime.copy()
		result.runtimes.append(copied)
		result._index[copied.player_id] = copied
	return result


func runtime_by_id(player_id: StringName) -> PlayerMatchRuntime:
	assert(_index.has(player_id), "unknown player runtime")
	var runtime: PlayerMatchRuntime = _index[player_id]
	return runtime


func has_player(player_id: StringName) -> bool:
	return _index.has(player_id)


## The live lineup, in canonical roster order.
func on_court_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for runtime in runtimes:
		if runtime.on_court:
			ids.append(runtime.player_id)
	return ids


func on_court_count() -> int:
	var count: int = 0
	for runtime in runtimes:
		if runtime.on_court:
			count += 1
	return count


func is_on_court(player_id: StringName) -> bool:
	return has_player(player_id) and runtime_by_id(player_id).on_court


## Players who may legally check in, in canonical roster order.
func available_bench_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for runtime in runtimes:
		if not runtime.on_court and runtime.is_eligible_to_play():
			ids.append(runtime.player_id)
	return ids


func add_period() -> void:
	period_scores.append(0)


func add_points(points: int) -> void:
	score += points
	period_scores[period_scores.size() - 1] += points
