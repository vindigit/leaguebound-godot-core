# v16 timing follow-up: stopped administration and live rebound feasibility

The follow-up starts from verified `origin/stage4-calibration` head
`15225e8cab5fca2bca9dc2ea4757e2f9e74bbc87`. Behavioral corrections advance the
simulation version to `simulation-v17-stopped-foul-clock-and-live-rebound`.
This document derives timing semantics; measurement and final gate evidence
are recorded separately. It makes no §27.1 certification claim.

## Authority and the non-bonus administration defect

`SIMULATION_SPEC.md` §9.4 says stopped-clock foul administration and the throw-in
before legal touch do not consume game time. Its owner-approved free-throw
contract also stops both clocks through administration and awarded attempts,
including awards at the horn. Live play after administration consumes time
normally. §13.2 requires eligible attempts and possession continuation to be
attributed exactly once.

Before this correction, the non-bonus defensive-foul branch called
`_consume(_clock.dead_ball_ms())` after recording the foul and any mandatory
foul-out substitutions, but before its shot-clock reset. The default charge was
1000ms. `MatchEventWriter.consume` lowered the game timestamp; the next event
reduced elapsed time into the snapshot, including the shot clock and playing
time. At or below the charge, `_consume` terminated the possession at the horn
and the reset never happened. This was stopped administration, not a live
action. It violated the same clock contract already used for the foul restart
and awarded free throws.

The correction removes that charge and its now-unused resolver and tuning
field. The existing rule-profile shot-clock reset remains at the whistle
timestamp. A reset may legitimately change the shot clock: the requirement is
zero elapsed administration, not an unchanged reset value. Live action before
the whistle and after the reset is unchanged. No free-throw probability, foul
probability, bonus threshold or shot-clock reset rule changes.

## Re-derivation from the actual final-free-throw sequence

The engine's sequence is:

1. Emit `FREE_THROW_AWARDED` at the foul timestamp.
2. Resolve eligible attempts at that same timestamp. Reduce each make before
   considering the next attempt, so the last-attempt deficit is the live score.
   A missed first one-and-one attempt ends the trip before any second attempt.
3. A missed final eligible attempt under a reboundable profile enters
   `_resolve_rebound`. Its sole pre-rebound time draw is
   `round(rebound_seconds * 1000 * competition.pace_multiplier)`.
4. `_consume` ends the possession if that draw reaches or crosses zero game
   time, before a rebound is selected or emitted.
5. A surviving offensive rebound emits its shot-clock reset. The ordinary
   resolver decides whether to attempt a direct putback. If selected, the
   putback emits `ACTION_SELECTED` and calls `_resolve_shot` directly at the
   rebound timestamp. There is **no additional `action_ms` draw** for that
   direct putback. If no putback is selected, subsequent ordinary actions
   consume their ordinary time.

Therefore the conservative all-draw rebound-survival floor is:

```text
floor_ms = max(0, round(rebound_seconds_max * 1000 * active_pace_multiplier)) + 1
```

The extra millisecond follows from the actual strict horn comparison, not a
free-throw clock floor. At reference pace 1.0 and the default 2-second maximum,
the result is 2001ms, replacing the unsupported unscaled 3000ms formula
`rebound_seconds_max + action_seconds_min`. Runtime eligibility reads the
active competition profile, so subsequent pace calibration automatically
changes this floor consistently with the actual live rebound draw. The
balance-only validation uses reference pace 1.0 and accepts equality; it does
not purport to validate every possible competition/balance combination.

This is a conservative coaching guard, **not the earliest time any rebound
can survive**. A smaller rebound draw can survive below the bound. It does not
guarantee an offensive rebound, a putback, or a score. Those remain ordinary
contested outcomes.

## Why no replacement numeric upper cutoff is proved

The historical 7000ms arithmetic charged a 2-second stopped inbound, two
2-second free throws and a 1-second action. Those charges do not describe the
current event sequence. Simply subtracting the abolished terms and substituting
1000ms would still be wrong:

- A made final free throw terminates with `MADE_FREE_THROW`; the next inbound
  starts at the same game time.
- Inside the existing desperation opening, an advance that would reach or
  cross the horn is skipped and the ball remains in the backcourt. A legal
  timeout advance can also bypass the backcourt walk.
- `_run_action_loop` checks the trailing defense's intentional foul before
  selecting or charging an action. That foul can occur at the current time.
- Non-bonus administration now consumes zero, as do awarded bonus free throws.
- The returning offense can use the existing desperation opening and final
  release path. That path can release with only milliseconds left; it is not
  bounded below by the nominal whole-second action band.

Consequently the actual engine does not prove any unique positive universal
clock cutoff below which make/foul/return is impossible. That alternative is
also conditional on fouls, bonus, attempts and possession outcomes. A clock-only
constant cannot establish its relative basketball value.

The existing **7000ms upper coaching cap is preserved**, explicitly as authored
policy, without the false necessity or elapsed-time proof. Likewise the
existing down-exactly-two, final-attempt, final-regulation-or-overtime and
reboundable-profile eligibility gates remain. Down two permits a rebound and
two-point putback to tie; this does not imply larger deficits could never be
tied by other plays. Changing the cap or deficit policy would require a new
strategy justification and is not a proven timing correction.

The timing builder and independent timing critic reached these conclusions
separately from the contracts and production call sequence. No shooting,
overtime, scoring, target or tolerance value was changed to obtain them.

## Required validation and interpretation

Deterministic tests must cover floor-minus-one, floor, the 7000ms cap and
cap-plus-one; active pace scaling and rounding; live-score eligibility; final
attempt and one-and-one prerequisites; nonfinal periods versus final regulation
and overtime; live and non-live final misses; ordinary contested rebound and
direct-putback timestamps; non-bonus clock, playing-time and reset behavior;
and horn/period transitions. Mutants restoring administration consumption,
ignoring pace or changing the strict boundary must be rejected by those tests.

These are required checks, not results claimed by this derivation. The final
execution evidence and any unresolved limitations belong in `PROJECT_STATUS.md`
and the retained verification artifacts after the complete gate runs.

## Focused execution evidence

The separate tests builder and harsh tests critic verified seven focused cases
across five competitions and 35 existing endgame cases, all passing. The actual
isolated mutation run rejected all nine executable mutants with assertion
failures (exit 100), not parse errors: horn equality, ignored competition pace,
wrong deficit, wrong final-attempt eligibility, nonbonus clock consumption,
awarded-FT clock consumption, free live rebounds, invented putback action time,
and truncation instead of rebound rounding. Reproduce with
`tools/run_timing_mutations.ps1`; retained results and source hashes are in
`analysis/stopped_clock_followup/mutations/results.json`.

The golden review retains five original seeds. The old overtime seed 7919 no
longer reaches overtime; the canonical deterministic scenario search first
finds 190056. Both the golden and parity fixture now use it. Four same-seed
ledgers first differ at the corrected nonbonus shot-clock reset, exactly
1000ms higher; foul/free-throw and late-game event ledgers are unchanged.
Supplementary replay inspection confirms seven actual one-and-one trips and
seven foul-out/check-out links. Raw comparisons and the reproducible inspection
are in `analysis/timing_pace_followup/golden_review.json` and
`review_goldens.py`. This fixture replacement preserves overtime coverage and
is not overtime-rate tuning. Final full-gate evidence follows pace calibration.
