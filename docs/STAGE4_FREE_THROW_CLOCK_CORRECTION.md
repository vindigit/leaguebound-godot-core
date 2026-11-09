# Stopped free-throw clocks — approved correction

Owner approval: 2026-09-15, after review of the gameplay effects. Baseline:
`5a8c4a4` (the reviewed code at upstream `4037a74` plus diagnostics/docs).
Ruleset: `simulation-v16-stopped-free-throw-clock`.

## Contract and implementation

Free-throw administration and every eligible awarded attempt preserve the game
and shot clocks. Each outcome is emitted at its award's timestamp and reduced
normally, so points, one-and-one eligibility and the intentional-miss decision
see the updated score. No invented one-millisecond floor is needed. Subsequent
live rebounds and action still consume their normal time. An award at zero can
finish; a new possession still cannot start at zero.

The change removes the `_advance_dead_ball` consumption path. The unused
`ClockResolver.free_throw_ms` method, `free_throw_event_seconds` setting and its
calibration registration are removed rather than leaving a misleading no-op
simulation knob. There was no other production consumer. This does not add a
presentation scheduler: a UI can take time to show a free throw without charging
that duration to simulation clocks.

The reducer, shot/contact/free-throw probability formulas, restart clock matrix,
pace multipliers, targets and tolerances are unchanged. Effective outcomes may
still change through restored live time, fatigue, lineups and event sequencing.
Free-throw events no longer accrue playing time or the corresponding active
fatigue/bench recovery. No assertion of unchanged field-goal percentage is made.

## Strategy coupling deliberately exposed

The intentional-miss threshold remains 7,000ms. Its historical derivation charged
inbound and free-throw time and is no longer valid under the corrected clocks.
The source now calls this out. The rebound/putback minimum-time floor remains
useful because those are live actions. Choosing a new coaching threshold is
separate work; this implementation does not invent one or tune overtime.

The previous ordering advanced the event writer before consulting the strategy,
while the strategy still read the prior reduced snapshot. With stopped clocks,
both now refer to the same award timestamp; earlier makes are still reduced
before the next decision.

## Focused verification

The new suite checks production-ledger replay across all five launch profiles:
FT outcomes charge zero game time, shot time and summed player playing time,
with actual attempt coverage required for each profile. At seed 991001 the
corrected counts were 29/31/38/32/21 attempts respectively; every charge was zero.

Direct awarded-trip fixtures cover 1/2/3 shots at 0, 1, 1500 and 8000ms;
one-and-one first makes and misses; and an intentional miss at 6000ms followed
by a real rebound at a lower clock. The pre-existing near-horn production-path
sweep now requires each outcome timestamp to equal its award timestamp.

The four new tests pass on the correction. Copied unchanged onto the baseline,
the suite reports 15 failed assertions and exits 100. This proves it rejects the
shipped defect; it is not a claim that every possible mutation was tested.
The earlier combined run of the replay test and 13 overtime-trigger tests also
passed (14 cases). Full execution and affected-suite rerun results are recorded below.

## Golden-ledger review

All six hashes change. Five retain their original seeds; their first changed
production event is a free-throw outcome exactly 2000ms later on the remaining
clock (the two seconds are no longer subtracted):

| Scenario | Event sequence | Before clock | Corrected clock |
| --- | ---: | ---: | ---: |
| regulation | 37 | 274000 | 276000 |
| offensive_rebound | 61 | 245000 | 247000 |
| foul_free_throw | 64 | 180000 | 182000 |
| substitution_foul_out | 45 | 198000 | 200000 |
| late_game | 23 | 223000 | 225000 |

The overtime fixture at seed 71271 no longer produces overtime. The existing
`find_scenario_seeds.gd --scenario=overtime --limit=100` search finds 7919 as
its first candidate satisfying the scenario. Only this seed changes, in both
the golden fixture and Play/Sim/Skip parity fixture. Because the seed changes,
the regenerated overtime ledger first differs at possession-start participant
selection; it is not described as a like-for-like FT-event comparison.

## Measurement design and scope

The existing pace-decomposition runner is run before and after with the same
rosters/seeds: `--games=30 --competition=all`, then the disjoint `--shard=1`
range. Range 1 uses variations 0–29/seeds 1–30; range 2 uses variations
30–59/seeds 31–60. Five competitions × two ranges × two arms × 30 games =
600 games. These are exploratory timing/regression measurements, not an
independent holdout after fitting, a rare-event conclusion, or certification.
No pace fitting is performed. Per-game raw observations are not emitted by this
runner, so its printed means do not establish paired confidence intervals.

The canonical home-court diagnostic is also rerun with `--games=200` per
competition because production behavior changed. Five separate jobs use
`--competition=<id> --emit-pairs=true --label=ft_<id>`; the initial sequential
job was superseded and contributes no observations. `analysis/free_throw_clock/pool_venue.gd`
reconstructs each source estimator, verifies its published figures, and merges
the 1000 unique matched fixtures through `VenueEffectEstimator`. Its result and the complete fast gate are recorded
below. A green structural gate does not certify statistical balance.

## Matched pace results

Possessions per team per game; 30 games per cell.

| Competition | Range 1 before → after | Range 2 before → after |
| --- | ---: | ---: |
| high_school | 70.5833 → 72.7000 | 71.3833 → 73.5333 |
| college | 72.5667 → 74.6500 | 71.2667 → 72.7833 |
| development | 96.1500 → 98.7000 | 96.0833 → 99.3167 |
| overseas | 74.1500 → 76.4167 | 74.8167 → 76.4833 |
| top_domestic_pro | 102.4500 → 106.0333 | 102.3167 → 105.7833 |

Raw runner output and machine-readable counts are retained in `analysis/free_throw_clock/`. Both ranges show an increase in every profile. These samples do not certify any band or resolve overtime.

## Remaining scope boundary found during review

The non-bonus defensive-foul branch still calls `dead_ball_ms()` before its
shot-clock reset. That branch awards no free throws and is unchanged here.
Its time semantics deserve a separate review against the whistle-stopped
contract; removing the FT path does not establish that every dead-ball path in
the engine is correct.

## Regression-fixture repairs exposed by the full run

The initial full run failed existing tests as well as validating the new code.
The repairs change test setup/predicates, not production outcomes or balance
limits:

- The timeout validity sweep assumed every timeout occurred in regulation.
  Both existing policies also operate in overtime. It now replays the ledger
  and checks available allowances and the actual remaining-time eligibility
  window, retaining its run-size, team-identity and activation checks.
- The home-venue test demanded a negative raw turnover-count difference in
  both 100-game samples. Counts also depend on possession availability and
  random game trajectories. It now compares production pass-turnover resolver
  outcomes on identical physical contexts/draws while swapping venue identity,
  requiring strict home benefit and exact identity symmetry. Full-game venue
  effects are still measured by the canonical paired diagnostic below.
- The stakes suite's separate forty-game seed block stopped producing overtime.
  It now uses the maintained named overtime fixture, verifies regular stakes,
  and still requires actual overtime. This avoids a second seed search.
- The bonus test depended on a particular golden game happening to contain a
  non-shooting foul. It now sets the foul counter immediately below the bonus
  threshold, submits a non-shooting defensive foul through the engine's normal
  foul path, and checks the resulting award and recipient.
- An overtime opening contained a logged timeout before its first inbound.
  The restart test now derives its expected cause from that actual event while
  still requiring a full period clock for both timeout and opening inbound.

No statistical calibration target or tolerance was loosened by these repairs.
The changes are separately committed so their test-contract decisions can be
reviewed apart from the FT clock fix.

## Completed venue recheck

| Competition | Paired home-win estimate ± 95% half-width | Paired points/100 | Reported failed checks |
| --- | ---: | ---: | --- |
| college | 0.5350 ± 0.0315 | 1.7583 | None |
| development | 0.5675 ± 0.0331 | 1.6679 | `development.venue.attributable_home_win_rate` |
| high_school | 0.5150 ± 0.0347 | 0.5193 | `high_school.venue.attributable_home_win_rate` |
| overseas | 0.5425 ± 0.0332 | 2.1918 | `overseas.home.combined_cap_respected` |
| top_domestic_pro | 0.5475 ± 0.0337 | 2.0062 | None |

Pooling all 1000 unique matched fixtures (3000 games), using the canonical
estimator, gives **0.5415 ± 0.0149** venue-attributable home win rate and
**1.6664 ± 0.3654** points per 100 possessions. The pooled point estimate is in
its 53–56% band; its interval is not wholly inside that band. The paired cap and
venue-reversal checks pass. All five source estimates reproduce to 1e-9;
there are no incomplete, duplicated or overlapping fixtures.

The per-profile report failures are not erased by pooling. High school is
below its home-win band and development above it. Overseas' legacy
`home.combined_cap_respected` fails: that code judges a venue-minus-neutral
single-arm contribution, while its paired estimator reports 2.1918 points/100
and passes its own cap. Both readings are retained. No matched pre-change
venue run was made here, so these results are not described as newly caused
regressions or proved sampling artifacts. The three affected diagnostic jobs
exit 1 for their judged failures; college/top-domestic exit 0. All five completed
and supplied valid paired observations. Nothing is certified.

## Final verification and repository state

Verified engine: `4.7.1.stable.official.a13da4feb`, installed with the repository's
published-checksum verification. Implementation commit `dfb0989`; test-contract
repairs `fb4de07`; fixed diagnostic pins `5744490`.

The fixed 24-game college diagnostic also changed its turnover rate
0.1465→0.1534, offensive-rebound share 0.2376→0.2418 and possessions (both teams)
144.17→148.83. Those three expected fixture values are refreshed; the 0.004
channel tolerance and 2.0 possession tolerance are unchanged. No corresponding
production parameter or statistical target is adjusted. This is a regression
snapshot of approved behavior, not proof that those channels are calibrated.

| Verification | Result |
| --- | --- |
| Import and final parse | Pass; 260 scripts, 0 failures |
| Final acceptance | Pass; all six regenerated golden scenarios retain required coverage |
| Simulation smoke | Invariants pass |
| Builder smoke | Pass |
| Attribute sensitivity | 80/80 judged, 0 failures |
| Calibration smoke | 15/15 judged, 0 failures |
| GdUnit, full execution plus affected-suite reruns | 676 distinct passing cases, 53 suites; no unresolved failures or skips |
| Canonical venue recombination | 5/5 source estimates reproduce; 1000 unique matched fixtures |
| Independent Python venue arithmetic | Rate and interval agree to 1e-12 |
| Diff whitespace check | Clean |

**The initial full gate was not green:** GdUnit exited 100 with 15 failed
assertions in six cases, and suite aborts meant 648 cases executed. After the
fixture repairs, every affected suite was rerun completely: 16 timeout cases,
35 restart cases, 54 home/stakes/foul cases and 22 FG-decomposition cases, each
with exit 0. XML evidence verifies coverage of all 676 declared cases across the
full execution and reruns. The exact evidence and report hashes are retained in
`analysis/free_throw_clock/test_verification.json` and `test_reports/`. This is
not represented as a second single green full-gate execution. Final parse and
acceptance were rerun after the last edit and both passed.

The new analysis-only pooling script is outside the standard parse gate's
source roots; its direct execution compiled and completed with exit 0. It
replays committed venue reports, so it can be reproduced without resimulating
3000 games.

Work is committed locally on `codex/stage4-clock-evidence-review`. No remote
push, PR edit, merge, force push or history rewrite was performed. Upstream CI
success previously recorded for `4037a74` is not claimed for these local commits.
The temporary baseline worktree was removed; pre-existing worktrees/edits were
preserved. No certification was run or claimed. Pace and per-profile venue
failures remain explicit follow-up work.
