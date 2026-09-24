class_name OvertimeDecomposition
extends RefCounted

## The offline causal decomposition of the §14.2 overtime shortfall.
##
## `PROJECT_STATUS.md` §5.28 measured college at 0.0310 and top domestic at
## 0.0223 against a locked 0.0400-0.0800 band, and §5.29-§5.33 then corrected
## the endgame repertoire, the restart contract, the made-field-goal clock
## matrix and the pace environment without moving either number. This class is
## the instrument that says *where* the missing regulation-tie mass goes, so
## that the next decision is taken on evidence rather than on a sixth late-game
## behaviour.
##
## **It is a reader, not a participant.** Every figure below is derived from the
## committed ledger and the terminal possession records of a game that has
## already finished. Nothing here is called during simulation, nothing here
## consumes a random source, and nothing here writes to production state — so
## the instrument provably cannot change what a seed produces. The runner
## asserts that by simulating the same seed twice and comparing signatures.
##
## **Counters, not estimates.** A `Tally` is a bag of integer counts and
## three-term moments (count, sum, sum of squares). Both merge by addition, so a
## sharded run recombines exactly rather than by averaging shard rates, which is
## the same rule `MetricAggregation` enforces for the metrics themselves.

## Where a mechanism's activation is read from.
##
## `ACTION_SELECTED.detail_id` carries `EndgameStrategy.active_tag`, which is
## **priority-ordered**: it reports the highest-priority decision that holds and
## silently drops every other one that also holds. Counting activations from it
## therefore undercounts two-for-one, hold, and quick-two by construction. This
## class re-evaluates the production predicates against the replayed state
## instead, and reports the ledger tag beside them so the size of the
## undercount is visible rather than assumed.
const MECHANISMS: PackedStringArray = [
	"two_for_one",
	"hold_for_final_shot",
	"quick_two",
	"designed_play",
	"tying_three_preferred",
	"leading_by_three_foul",
	"intentional_final_free_throw_miss",
	"timeout_to_advance",
]

## Regulation-remaining checkpoints, in milliseconds. `final_period` and
## `final_possession` are captured by name because they are not fixed clocks:
## college plays two halves, so its final regulation period opens at 1,200,000ms
## remaining and everybody else's at 720,000 or 600,000.
const CHECKPOINT_MS: PackedInt32Array = [300000, 120000, 60000, 30000, 10000]
const CHECKPOINT_NAMES: PackedStringArray = [
	"final_period", "300s", "120s", "60s", "30s", "10s",
	"final_possession", "regulation_end",
]

## The late-game windows the opportunity counts are broken out inside, in
## milliseconds of regulation remaining.
const OPPORTUNITY_WINDOW_MS: PackedInt32Array = [120000, 60000, 30000, 10000]
const OPPORTUNITY_WINDOW_NAMES: PackedStringArray = ["120s", "60s", "30s", "10s"]

## The offence score states the conditional-outcome table is cut on. `far` and
## `far_up` exist so `margin_bucket` is total over every margin, and are reported
## rather than dropped.
const REPORTED_BUCKETS: PackedStringArray = [
	"tied", "down1", "down2", "down3", "down4_6",
	"up1", "up2", "up3", "up4_6", "far", "far_up",
]

## The signed density reported around zero, inclusive both ways.
const DENSITY_BOUND: int = 10

## The largest deficit a single possession can erase. Above it a possession is
## not a tying opportunity however the offence plays it.
const TIEABLE_DEFICIT: int = 3

## The funnel `PROJECT_STATUS.md` reports, in the order the Stage 4 brief lists
## it. Each stage is an **unconditional** per-game indicator; the conjunction
## with the previous stage is counted alongside it so a transition rate is a
## real conditional and never a ratio of two unconditional rates. Stages 5 and 6
## are genuinely not nested — a game can be tied inside the final minute without
## a trailing team ever holding the ball there — which is why the conjunctions
## are counted rather than assumed.
##
## Stage 5 is "the score was level at some moment of the final minute" and stage
## 8 is "a team that was **behind** during the final minute levelled it". Those
## are different questions, and writing stage 8 as "the score reached level"
## made them the same event: every level score in the window satisfies both, so
## the transition between them was identically one and reported nothing.
const FUNNEL_STAGES: PackedStringArray = [
	"f01_reached_final_period",
	"f02_within_six_at_5min",
	"f03_within_three_at_2min",
	"f04_within_three_at_1min",
	"f05_tied_in_final_minute",
	"f06_tieable_possession",
	"f07_plausible_tying_action",
	"f08_tie_achieved_in_final_minute",
	"f09_tied_at_horn",
	"f10_entered_overtime",
]


## One shard's accumulated counters. Integer counts and three-term moments, both
## of which combine by addition.
class Tally:
	extends RefCounted

	var counts: Dictionary = {}
	## key -> PackedFloat64Array of [count, sum, sum_of_squares].
	var moments: Dictionary = {}

	func add(key: StringName, amount: int = 1) -> void:
		var current: int = counts[key] if counts.has(key) else 0
		counts[key] = current + amount

	func count_of(key: StringName) -> int:
		return counts[key] if counts.has(key) else 0

	func observe(key: StringName, value: float) -> void:
		var terms: PackedFloat64Array = (
			moments[key] if moments.has(key) else PackedFloat64Array([0.0, 0.0, 0.0]))
		terms[0] += 1.0
		terms[1] += value
		terms[2] += value * value
		moments[key] = terms

	func moment_of(key: StringName) -> PackedFloat64Array:
		if not moments.has(key):
			return PackedFloat64Array([0.0, 0.0, 0.0])
		var terms: PackedFloat64Array = moments[key]
		return terms

	func mean_of(key: StringName) -> float:
		var terms: PackedFloat64Array = moment_of(key)
		return 0.0 if terms[0] <= 0.0 else terms[1] / terms[0]

	## Population standard deviation of the observations behind one moment.
	func deviation_of(key: StringName) -> float:
		var terms: PackedFloat64Array = moment_of(key)
		if terms[0] <= 1.0:
			return 0.0
		var mean: float = terms[1] / terms[0]
		var variance: float = maxf(0.0, terms[2] / terms[0] - mean * mean)
		return sqrt(variance)

	func merge(other: Tally) -> void:
		for key: StringName in other.counts.keys():
			var amount: int = other.counts[key]
			add(key, amount)
		for key: StringName in other.moments.keys():
			var terms: PackedFloat64Array = other.moments[key]
			var own: PackedFloat64Array = (
				moments[key] if moments.has(key) else PackedFloat64Array([0.0, 0.0, 0.0]))
			own[0] += terms[0]
			own[1] += terms[1]
			own[2] += terms[2]
			moments[key] = own

	## Canonical ordering so two runs of the same shard write byte-identical
	## JSON and a diff of two reports is a diff of the measurement.
	func to_dictionary() -> Dictionary:
		var count_payload: Dictionary = {}
		var count_keys: Array = counts.keys()
		count_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		for key: Variant in count_keys:
			count_payload[str(key)] = counts[key]
		var moment_payload: Dictionary = {}
		var moment_keys: Array = moments.keys()
		moment_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		for key: Variant in moment_keys:
			var terms: PackedFloat64Array = moments[key]
			moment_payload[str(key)] = [terms[0], terms[1], terms[2]]
		return {"counts": count_payload, "moments": moment_payload}

	static func from_dictionary(payload: Dictionary) -> Tally:
		var tally := Tally.new()
		var count_payload: Dictionary = JsonRead.dictionary_at(payload, "counts")
		for key: Variant in count_payload.keys():
			var amount: float = count_payload[key]
			tally.counts[StringName(str(key))] = int(amount)
		var moment_payload: Dictionary = JsonRead.dictionary_at(payload, "moments")
		for key: Variant in moment_payload.keys():
			var terms: Array = moment_payload[key]
			var first: float = terms[0]
			var second: float = terms[1]
			var third: float = terms[2]
			tally.moments[StringName(str(key))] = PackedFloat64Array([first, second, third])
		return tally


## The live state of one possession while its outcomes are being read off the
## ledger. Nothing here is fed back into anything: it exists so a possession's
## opening margin and its result can be reported as one row.
class PossessionWindow:
	extends RefCounted

	var possession_id: int = 0
	var offense_id: StringName = &""
	var start_margin: int = 0
	var start_remaining_ms: int = 0
	var bucket: StringName = &""
	var windows: PackedStringArray = PackedStringArray()
	## Whether the possession produced any attempt at all. A possession that
	## ended without one is the loss `PROJECT_STATUS.md` §5.29 localized, and it
	## is counted separately from a possession that attempted and missed.
	var field_goal_attempts: int = 0
	var free_throw_attempts: int = 0
	var points: int = 0
	var plausible_tying_action: bool = false


## Reads one finished game into the tally.
##
## `input` and `output` must be the pair a single `MatchSession` produced. The
## ledger is replayed through the same `MatchStateReducer` production used, so
## every margin, clock and lineup this reads is the state the engine decided
## from rather than a reconstruction of it.
static func measure(tally: Tally, input: MatchInput, output: MatchSimulationOutput) -> void:
	var rules: CompetitionRuleProfile = input.rule_profile
	var balance: SimulationBalanceProfile = input.balance_profile
	var home_id: StringName = input.home.team_id
	var result: MatchFinalResult = output.final_result

	tally.add(&"games")
	_measure_population(tally, input)

	var state := MatchSnapshot.new(input)
	var reducer := MatchStateReducer.new(input)

	# --- regulation replay ----------------------------------------------------
	var checkpoints_seen: Dictionary = {}
	var checkpoint_margins: Dictionary = {}
	var open_windows: Dictionary = {}
	var regulation_possessions: int = 0
	var possessions_before_checkpoint: Dictionary = {}
	var regulation_margin: int = 0
	var regulation_seen: bool = false
	var tied_in_final_minute: bool = false
	var tie_achieved_in_final_minute: bool = false
	## Whether the final minute has been seen at an unlevel score. Funnel stage 8
	## is "a trailing team **levelled** the game", which is a different question
	## from stage 5's "the game was level at some point in the final minute" — a
	## game already tied when the last minute opened satisfies the second and not
	## the first. Without this the two stages count the same event and the
	## transition between them is identically one, which reports nothing.
	var seen_unlevel_in_final_minute: bool = false
	var tieable_possession: bool = false
	var plausible_tying_action: bool = false
	var previous_clock_ms: int = rules.period_length_ms(1)
	var previous_period: int = 1
	var last_regulation_window: PossessionWindow = null
	var final_possession_captured: bool = false

	for event: MatchDomainEvent in output.events:
		var in_regulation: bool = state.period <= rules.regulation_periods
		if in_regulation:
			var remaining_before: int = GarbageTimeRule.remaining_regulation_ms(
				state.period, state.clock_ms, rules)
			var remaining_after: int = GarbageTimeRule.remaining_regulation_ms(
				event.period, event.clock_ms, rules)

			# The final regulation period opens where the competition says it
			# does, never at an assumed quarter boundary.
			if event.event_type == MatchDomainEvent.PERIOD_STARTED \
					and event.period == rules.regulation_periods:
				checkpoint_margins[&"final_period"] = _capture_checkpoint(
					tally, state, home_id, &"final_period")
				checkpoints_seen[&"final_period"] = true
				possessions_before_checkpoint[&"final_period"] = regulation_possessions

			for index in range(CHECKPOINT_MS.size()):
				var threshold: int = CHECKPOINT_MS[index]
				var name_value := StringName(CHECKPOINT_NAMES[index + 1])
				if checkpoints_seen.has(name_value):
					continue
				if remaining_before > threshold and remaining_after <= threshold:
					checkpoints_seen[name_value] = true
					possessions_before_checkpoint[name_value] = regulation_possessions
					checkpoint_margins[name_value] = _capture_checkpoint(
						tally, state, home_id, name_value)

			if remaining_before <= 60000:
				if state.home.score == state.away.score:
					tied_in_final_minute = true
				else:
					seen_unlevel_in_final_minute = true

			_accumulate_phase_clock(tally, state, event, previous_clock_ms, previous_period)
			_accumulate_session_event(tally, event)

			if event.event_type == MatchDomainEvent.POSSESSION_STARTED:
				regulation_possessions += 1
				var window: PossessionWindow = _open_window(
					tally, input, state, event, remaining_before, balance)
				open_windows[event.possession_id] = window
				last_regulation_window = window
				if window.start_margin < 0 and window.start_margin >= -TIEABLE_DEFICIT \
						and remaining_before <= 60000:
					tieable_possession = true
			var live_window: PossessionWindow = (
				open_windows[event.possession_id] if open_windows.has(event.possession_id)
				else null)
			if live_window != null:
				_accumulate_window_event(tally, state, event, live_window)
				if live_window.plausible_tying_action and live_window.start_remaining_ms <= 60000:
					plausible_tying_action = true
			if event.event_type == MatchDomainEvent.POSSESSION_ENDED \
					and open_windows.has(event.possession_id):
				var closing: PossessionWindow = open_windows[event.possession_id]
				_close_window(tally, state, closing, remaining_after)
				open_windows.erase(event.possession_id)

			if event.event_type == MatchDomainEvent.PERIOD_ENDED \
					and event.period == rules.regulation_periods:
				regulation_margin = state.margin_for(home_id)
				regulation_seen = true
				checkpoint_margins[&"regulation_end"] = _capture_checkpoint(
					tally, state, home_id, &"regulation_end")
				possessions_before_checkpoint[&"regulation_end"] = regulation_possessions

		previous_clock_ms = event.clock_ms
		previous_period = event.period
		reducer.apply_event(state, event)

		if in_regulation and state.period <= rules.regulation_periods:
			var settled: int = GarbageTimeRule.remaining_regulation_ms(
				state.period, state.clock_ms, rules)
			if settled <= 60000:
				if state.home.score == state.away.score:
					tied_in_final_minute = true
					if seen_unlevel_in_final_minute:
						tie_achieved_in_final_minute = true
				else:
					seen_unlevel_in_final_minute = true

	# The final completed regulation possession, captured by identity rather
	# than by clock so a competition's own period structure decides it.
	if last_regulation_window != null:
		final_possession_captured = true
		checkpoints_seen[&"final_possession"] = true
		# One possession still to be played at the moment it opens: itself.
		possessions_before_checkpoint[&"final_possession"] = regulation_possessions - 1
		checkpoints_seen[&"regulation_end"] = true
		tally.observe(&"cp.final_possession.margin", float(
			last_regulation_window.start_margin
			if last_regulation_window.offense_id == home_id
			else -last_regulation_window.start_margin))
		tally.observe(&"cp.final_possession.abs_margin", float(
			absi(last_regulation_window.start_margin)))
		tally.add(StringName(
			"cp.final_possession.possession.%s"
			% ("home" if last_regulation_window.offense_id == home_id else "away")))
		_observe_density(tally, &"cp.final_possession", (
			last_regulation_window.start_margin
			if last_regulation_window.offense_id == home_id
			else -last_regulation_window.start_margin))
	if not final_possession_captured:
		tally.add(&"anomaly.no_regulation_possession")

	for name_value: StringName in checkpoints_seen.keys():
		var before: int = possessions_before_checkpoint.get(name_value, 0)
		tally.observe(
			StringName("cp.%s.possessions_remaining" % name_value),
			float(regulation_possessions - before))

	# --- game-level results ---------------------------------------------------
	if not regulation_seen:
		tally.add(&"anomaly.regulation_end_not_observed")
		regulation_margin = result.home_score - result.away_score

	var entered_overtime: bool = result.overtime_periods > 0
	var tied_at_horn: bool = regulation_margin == 0

	tally.add(&"regulation_ties", 1 if tied_at_horn else 0)
	tally.add(&"overtime_entries", 1 if entered_overtime else 0)
	if tied_at_horn != entered_overtime:
		tally.add(&"invariant.tie_overtime_mismatch")
		tally.add(StringName(
			"invariant.tie_without_overtime" if tied_at_horn
			else "invariant.overtime_without_tie"))
	if entered_overtime:
		tally.add(&"overtime_single" if result.overtime_periods == 1 else &"overtime_multiple")
		tally.add(StringName("overtime_periods.%d" % result.overtime_periods))
	if result.home_score == result.away_score:
		tally.add(&"anomaly.final_score_level")
	if result.home_score < 0 or result.away_score < 0:
		tally.add(&"anomaly.negative_score")

	tally.observe(&"regulation_margin_signed", float(regulation_margin))
	tally.observe(&"regulation_margin_abs", float(absi(regulation_margin)))
	_observe_density(tally, &"regulation_margin", regulation_margin)
	var final_margin: int = absi(result.home_score - result.away_score)
	tally.observe(&"final_margin_abs", float(final_margin))
	if absi(regulation_margin) <= 5:
		tally.add(&"close_game")
	if absi(regulation_margin) >= 20:
		tally.add(&"blowout")
	tally.observe(&"overtime_periods", float(result.overtime_periods))

	_record_funnel(
		tally,
		[
			true,
			_within_at(checkpoint_margins, &"300s", 6),
			_within_at(checkpoint_margins, &"120s", 3),
			_within_at(checkpoint_margins, &"60s", 3),
			tied_in_final_minute,
			tieable_possession,
			plausible_tying_action,
			tie_achieved_in_final_minute,
			tied_at_horn,
			entered_overtime,
		])
	_record_stratified(tally, input, tied_at_horn, entered_overtime, absi(regulation_margin))


# --- checkpoints --------------------------------------------------------------

## The signed home margin, its magnitude, its density near zero, and who has the
## ball, at one named moment of regulation.
static func _capture_checkpoint(
	tally: Tally,
	state: MatchSnapshot,
	home_id: StringName,
	name_value: StringName,
) -> int:
	var margin: int = state.margin_for(home_id)
	tally.add(StringName("cp.%s.games" % name_value))
	tally.observe(StringName("cp.%s.margin" % name_value), float(margin))
	tally.observe(StringName("cp.%s.abs_margin" % name_value), float(absi(margin)))
	_observe_density(tally, StringName("cp.%s" % name_value), margin)
	for threshold: int in [1, 2, 3, 4, 5, 6, 8, 10, 15, 20]:
		if absi(margin) <= threshold:
			tally.add(StringName("cp.%s.within.%d" % [name_value, threshold]))
	var owner_id: StringName = state.possession_team_id
	if not owner_id.is_empty():
		tally.add(StringName(
			"cp.%s.possession.%s" % [name_value, "home" if owner_id == home_id else "away"]))
	# Score parity: whether the two team totals share a parity, which is the
	# term `Hypothesis C` asks for beside the increment distribution.
	tally.add(StringName("cp.%s.parity.%s" % [
		name_value, "same" if (state.home.score - state.away.score) % 2 == 0 else "different"]))
	return margin


static func _observe_density(tally: Tally, prefix: StringName, margin: int) -> void:
	if margin < -DENSITY_BOUND or margin > DENSITY_BOUND:
		tally.add(StringName("%s.density.out" % prefix))
		return
	tally.add(StringName("%s.density.%d" % [prefix, margin]))


## Whether this one game was inside `threshold` at a named checkpoint.
##
## A game that never reached the checkpoint — which cannot happen for the fixed
## regulation clocks, but is expressible — is reported as not inside it rather
## than as inside it by default.
static func _within_at(margins: Dictionary, checkpoint: StringName, threshold: int) -> bool:
	if not margins.has(checkpoint):
		return false
	var margin: int = margins[checkpoint]
	return absi(margin) <= threshold


# --- possessions --------------------------------------------------------------

static func _open_window(
	tally: Tally,
	input: MatchInput,
	state: MatchSnapshot,
	event: MatchDomainEvent,
	remaining_ms: int,
	balance: SimulationBalanceProfile,
) -> PossessionWindow:
	var window := PossessionWindow.new()
	window.possession_id = event.possession_id
	window.offense_id = event.team_id
	window.start_margin = state.margin_for(event.team_id)
	window.start_remaining_ms = remaining_ms
	window.bucket = margin_bucket(window.start_margin)
	for index in range(OPPORTUNITY_WINDOW_MS.size()):
		if remaining_ms <= OPPORTUNITY_WINDOW_MS[index]:
			var window_name := StringName(OPPORTUNITY_WINDOW_NAMES[index])
			window.windows.append(String(window_name))
			tally.add(StringName("opp.%s.%s" % [window_name, window.bucket]))
			tally.add(StringName("opp.%s.total" % window_name))
	_record_mechanisms(tally, input, state, event.team_id, remaining_ms, balance, window)
	return window


## Every mechanism's activation, evaluated from the production predicate against
## the replayed state rather than from the priority-ordered ledger tag.
static func _record_mechanisms(
	tally: Tally,
	input: MatchInput,
	state: MatchSnapshot,
	offense_id: StringName,
	remaining_ms: int,
	balance: SimulationBalanceProfile,
	window: PossessionWindow,
) -> void:
	if remaining_ms > OPPORTUNITY_WINDOW_MS[0]:
		return
	var context := PossessionContext.new(input, state, offense_id, MatchupState.new(), 0)
	var active := PackedStringArray()
	if EndgameStrategy.two_for_one_active(context, balance):
		active.append("two_for_one")
	if EndgameStrategy.hold_for_final_shot_active(context, balance):
		active.append("hold_for_final_shot")
	if EndgameStrategy.quick_two_preferred(context, balance):
		active.append("quick_two")
	if EndgameStrategy.designed_play_active(context, balance):
		active.append("designed_play")
	var deficit: int = -context.offense_margin()
	if deficit >= GameManagement.TIE_SEEKING_MINIMUM_DEFICIT \
			and deficit <= GameManagement.TIE_SEEKING_MAXIMUM_DEFICIT \
			and remaining_ms <= StakesPolicy.endgame_window_ms(balance, input.stakes):
		active.append("tying_three_preferred" if deficit == 3 else "tying_two_preferred")
	if EndgameStrategy.timeout_advance_eligible(
		state, input.rule_profile, balance, offense_id, false, false
	):
		active.append("timeout_to_advance")
	for name_value in active:
		tally.add(StringName("mech.%s.activations" % name_value))
		tally.add(StringName("mech.%s.at.%s" % [name_value, window.bucket]))


## Events that belong to the game rather than to one possession.
##
## `MatchSession` emits a charged timeout through its own `MatchEventWriter`,
## whose `possession_id` is zero, so these never appear inside a possession
## window. Reading them there reported timeout-to-advance as never firing, which
## is the opposite of true in the one competition that has the rule.
##
## The `ACTION_SELECTED` tag is recorded here **beside** the recomputed
## predicates, never instead of them: `EndgameStrategy.active_tag` is
## priority-ordered and reports only the highest-priority decision in force, so
## the gap between this count and `mech.*.activations` is the size of the
## undercount rather than a disagreement.
static func _accumulate_session_event(tally: Tally, event: MatchDomainEvent) -> void:
	if event.event_type == MatchDomainEvent.TIMEOUT:
		tally.add(StringName("timeout_charged.%s" % (
			event.detail_id if not event.detail_id.is_empty() else &"unlabelled")))
		if event.detail_id == &"advance":
			tally.add(&"mech.timeout_to_advance.charged")
		return
	if event.event_type == MatchDomainEvent.ACTION_SELECTED \
			and not event.detail_id.is_empty():
		tally.add(StringName("ledger_tag.%s" % event.detail_id))


## Every outcome one possession produced, recorded against the score state it
## opened in.
##
## Two kinds of row live here and the report must not mix them. `no_attempt`,
## `points_*`, `tied_afterward` and the rest of `_close_window`'s rows are
## written **once per possession** and are therefore probabilities. The rows
## below are written **once per matching event**, so an offensive rebound can
## give one possession two attempts and a per-possession figure above one is a
## count rather than a broken probability.
static func _accumulate_window_event(
	tally: Tally,
	state: MatchSnapshot,
	event: MatchDomainEvent,
	window: PossessionWindow,
) -> void:
	var deficit: int = -window.start_margin
	match event.event_type:
		MatchDomainEvent.FIELD_GOAL_ATTEMPT:
			window.field_goal_attempts += 1
			var zone: int = ShotZone.from_id(event.zone_id)
			var value: int = 3 if ShotZone.is_three(zone) else 2
			_window_outcome(tally, window, StringName("attempt_%d" % value))
			# A plausible tying action is one whose value can actually erase the
			# deficit the possession opened at. A two down three cannot, and is
			# not counted as one however well it is executed.
			if deficit > 0 and value >= deficit:
				window.plausible_tying_action = true
			# The same attempt judged against the *live* margin rather than the
			# opening one, so an attempt that would tie the game as it stands is
			# separable from one that merely could have at the tip-off of the
			# possession.
			if state.margin_for(event.team_id) == -value:
				_window_outcome(tally, window, &"tying_attempt")
		MatchDomainEvent.FIELD_GOAL_MADE:
			window.points += event.points
			_window_outcome(tally, window, StringName("made_%d" % event.points))
		MatchDomainEvent.TURNOVER:
			_window_outcome(tally, window, &"turnover")
		MatchDomainEvent.FREE_THROW_AWARDED:
			_window_outcome(tally, window, &"free_throw_trip")
			if deficit > 0 and event.amount >= deficit:
				window.plausible_tying_action = true
		MatchDomainEvent.FREE_THROW_MADE:
			window.free_throw_attempts += 1
			window.points += 1
			_window_outcome(tally, window, &"free_throw_made")
		MatchDomainEvent.FREE_THROW_MISSED:
			window.free_throw_attempts += 1
			_window_outcome(tally, window, &"free_throw_missed")
			if event.detail_id == &"intentional":
				tally.add(&"mech.intentional_final_free_throw_miss.activations")
		MatchDomainEvent.REBOUND:
			if event.detail_id == MatchDomainEvent.REBOUND_OFFENSIVE:
				_window_outcome(tally, window, &"offensive_rebound")
			else:
				_window_outcome(tally, window, &"defensive_rebound")
		MatchDomainEvent.FOUL:
			match FoulType.from_id(event.detail_id):
				FoulType.Value.SHOOTING:
					_window_outcome(tally, window, &"shooting_foul")
				FoulType.Value.INTENTIONAL:
					_window_outcome(tally, window, &"intentional_foul")
					tally.add(&"cycle.intentional_foul")
				FoulType.Value.LEADING_PROTECT:
					_window_outcome(tally, window, &"leading_protect_foul")
					tally.add(&"mech.leading_by_three_foul.activations")
				_:
					_window_outcome(tally, window, &"non_shooting_foul")
		_:
			pass


static func _close_window(
	tally: Tally,
	state: MatchSnapshot,
	window: PossessionWindow,
	remaining_after_ms: int,
) -> void:
	var attempted: bool = window.field_goal_attempts > 0 or window.free_throw_attempts > 0
	if not attempted:
		_window_outcome(tally, window, &"no_attempt")
	_window_outcome(tally, window, StringName("points_%s" % (
		"4plus" if window.points >= 4 else str(window.points))))
	if window.points == 0:
		_window_outcome(tally, window, &"score_unchanged")
	var margin_after: int = state.margin_for(window.offense_id)
	if margin_after == 0:
		_window_outcome(tally, window, &"tied_afterward")
	# Which deficit a level score was actually closed from, inside the final
	# minute. `cond.*.tied_afterward` counts the same event by window and bucket;
	# this is the flat count the funnel's stage 8 is read against.
	if window.start_margin < 0 and margin_after == 0 and window.start_remaining_ms <= 60000:
		tally.add(StringName("levelled_from.%s" % window.bucket))
	if window.start_margin < 0 and margin_after > 0:
		_window_outcome(tally, window, &"lead_changed")
	elif window.start_margin > 0 and margin_after < 0:
		_window_outcome(tally, window, &"lead_changed")
	if remaining_after_ms <= 0:
		_window_outcome(tally, window, &"regulation_ended_afterward")
		if not attempted:
			_window_outcome(tally, window, &"expired_without_attempt")
	# Score-increment distribution for the granularity hypothesis, over every
	# regulation possession rather than only the late ones.
	tally.add(StringName("increment.%s" % ("4plus" if window.points >= 4 else str(window.points))))
	tally.add(&"increment.total")
	# The signed margin transition this possession produced, from the offence's
	# point of view, for the -3..+3 transition matrix.
	if absi(window.start_margin) <= 3 and window.start_remaining_ms <= 120000:
		tally.add(StringName("transition.%d.to.%s" % [
			window.start_margin,
			str(margin_after) if absi(margin_after) <= 3 else "out"]))
		tally.add(StringName("transition.%d.total" % window.start_margin))


static func _window_outcome(tally: Tally, window: PossessionWindow, outcome: StringName) -> void:
	for window_name in window.windows:
		tally.add(StringName("cond.%s.%s.%s" % [window_name, window.bucket, outcome]))


## The offence's own score state at the moment a possession begins.
static func margin_bucket(margin: int) -> StringName:
	if margin == 0:
		return &"tied"
	if margin == -1:
		return &"down1"
	if margin == -2:
		return &"down2"
	if margin == -3:
		return &"down3"
	if margin >= -6 and margin <= -4:
		return &"down4_6"
	if margin == 1:
		return &"up1"
	if margin == 2:
		return &"up2"
	if margin == 3:
		return &"up3"
	if margin >= 4 and margin <= 6:
		return &"up4_6"
	return &"far" if margin < 0 else &"far_up"


# --- clock accounting ---------------------------------------------------------

## Attributes the clock a possession spent to the phase that spent it. Time only
## leaves through `PossessionEngine._consume`, and every consuming phase emits
## its own event immediately afterwards, so the drop preceding an event is that
## event's phase cost.
static func _accumulate_phase_clock(
	tally: Tally,
	state: MatchSnapshot,
	event: MatchDomainEvent,
	previous_clock_ms: int,
	previous_period: int,
) -> void:
	if event.period != previous_period or event.period != state.period:
		return
	var elapsed: int = previous_clock_ms - event.clock_ms
	if elapsed <= 0:
		return
	match event.event_type:
		MatchDomainEvent.INBOUND:
			tally.add(&"phase_ms.inbound", elapsed)
		MatchDomainEvent.ADVANCE:
			tally.add(&"phase_ms.advance", elapsed)
		MatchDomainEvent.HALF_COURT_ENTERED:
			tally.add(&"phase_ms.half_court", elapsed)
		MatchDomainEvent.ACTION_SELECTED:
			tally.add(&"phase_ms.action", elapsed)
		MatchDomainEvent.FREE_THROW_MADE, MatchDomainEvent.FREE_THROW_MISSED:
			tally.add(&"phase_ms.free_throw", elapsed)
		MatchDomainEvent.REBOUND:
			tally.add(&"phase_ms.rebound", elapsed)
		_:
			tally.add(&"phase_ms.other", elapsed)
	tally.add(&"phase_ms.total", elapsed)


# --- population ---------------------------------------------------------------

static func _measure_population(tally: Tally, input: MatchInput) -> void:
	var home: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.home, input.ratings_profile, input.balance_profile)
	var away: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.away, input.ratings_profile, input.balance_profile)
	tally.observe(&"population.expected_gap", TeamStrengthIndex.expected_gap(home, away))
	tally.observe(&"population.abs_expected_gap",
		absf(TeamStrengthIndex.expected_gap(home, away)))
	tally.observe(&"population.overall_gap", home.overall - away.overall)
	tally.observe(&"population.starter_gap", home.starters - away.starters)
	tally.observe(&"population.bench_gap", home.bench - away.bench)
	tally.observe(&"population.offense_gap", home.offense - away.offense)
	tally.observe(&"population.home_environment", input.home_environment)


static func _record_stratified(
	tally: Tally,
	input: MatchInput,
	tied_at_horn: bool,
	entered_overtime: bool,
	regulation_margin: int,
) -> void:
	var home: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.home, input.ratings_profile, input.balance_profile)
	var away: TeamStrengthIndex = TeamStrengthIndex.of_team(
		input.away, input.ratings_profile, input.balance_profile)
	var strata: Dictionary = {
		&"expected_gap": _gap_bucket(absf(TeamStrengthIndex.expected_gap(home, away))),
		&"starter_gap": _gap_bucket(absf(home.starters - away.starters)),
		&"bench_gap": _gap_bucket(absf(home.bench - away.bench)),
		&"overall_gap": _gap_bucket(absf(home.overall - away.overall)),
		&"offense_gap": _gap_bucket(absf(home.offense - away.offense)),
		&"advantage": StringName("home" if home.overall >= away.overall else "away"),
		&"stakes": GameStakes.id_of(input.stakes),
	}
	for dimension: StringName in strata.keys():
		var bucket: StringName = strata[dimension]
		tally.add(StringName("strata.%s.%s.games" % [dimension, bucket]))
		if tied_at_horn:
			tally.add(StringName("strata.%s.%s.zero_margin" % [dimension, bucket]))
		if entered_overtime:
			tally.add(StringName("strata.%s.%s.overtime" % [dimension, bucket]))
		if regulation_margin <= 5:
			tally.add(StringName("strata.%s.%s.close" % [dimension, bucket]))
		if regulation_margin >= 20:
			tally.add(StringName("strata.%s.%s.blowout" % [dimension, bucket]))


static func _gap_bucket(gap: float) -> StringName:
	if gap < 1.0:
		return &"0-1"
	if gap < 2.0:
		return &"1-2"
	if gap < 3.0:
		return &"2-3"
	if gap < 5.0:
		return &"3-5"
	return &"5plus"


# --- funnel -------------------------------------------------------------------

static func _record_funnel(tally: Tally, stages: Array) -> void:
	var previous: bool = true
	for index in range(FUNNEL_STAGES.size()):
		var reached: bool = stages[index]
		if reached:
			tally.add(StringName("funnel.%s" % FUNNEL_STAGES[index]))
		if index > 0:
			if previous:
				tally.add(StringName("funnel.%s.given_previous_trials" % FUNNEL_STAGES[index]))
				if reached:
					tally.add(
						StringName("funnel.%s.given_previous_hits" % FUNNEL_STAGES[index]))
		previous = reached
