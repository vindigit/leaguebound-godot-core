# Stage 4 — clock-contract and external-evidence review

Reviewed 2026-09-15 against `4037a74c75fbf2eaff6c39f80f4bb503df20ef74`.
Scope: verify handoff/CI, correct diagnostic overclaims, audit FT timing,
independently recount comparable real-game overtime. No production behaviour,
target, tolerance, ruleset, golden, or pace change; no certification.

## 1. Repository and CI

PR #1 was verified **open, draft, unmerged**, head `4037a74`; Actions
[run 34520937141](https://github.com/vindigit/leaguebound-godot-core/actions/runs/34520937141)
was completed/success. Both jobs (`simulation`, `test-report.xml`) succeeded.
That verifies the previously pending CI statement. It does not turn a
structural fast gate into statistical certification.

Work was isolated on `codex/stage4-clock-evidence-review`. Existing uncommitted
changes in the older checkout were inspected as evidence and left untouched.
Nine raw snapshots below already existed. Only the damaged college 2024 file
was re-downloaded during this review; originals were preserved.

## 2. Which §5.34 conclusions survive review?

| Claim | Supported replacement |
| --- | --- |
| “Neither competition has a defect” | No trigger anomaly was reported in the tested fixtures/games; this does not exhaust engine defects |
| Equal tie-creation rates | No statistically detected difference in this sample; equality/equivalence not established |
| Possession availability is the cause | More remaining possessions and lower tie survival are observed together; cross-competition comparison changes other variables too |
| Mirror experiment rules out population | No detected OT effect of that specific intervention; not a test of all roster distributions |
| Variance cannot affect overtime | Width changed while an OT response was unresolved at these sample sizes |
| No top-domestic spike because below Gaussian density | Descriptive comparison to a chosen approximation; not a causal or adequacy test |
| Candidate FT/desperation changes cannot close the gap | No controlled counterfactual proves closure or impossibility; arithmetic scenarios are not upper bounds |
| External target has no usable evidence | External schedule snapshots are available and support retaining the band for the two proxies below |

For the reported mirror comparison, independent-binomial approximate 95%
intervals for **mirror minus generated** are college −1.27 to +0.89 percentage
points (47/1,600 versus 75/2,400), and top domestic −0.88 to +0.92 points
(33/1,600 versus 49/2,400). Those are illustrative sampling intervals, not a
paired test: no game-level pairing covariance was supplied for this calculation.
They allow material effects; p=.73/.96 is not evidence of exact equivalence.

Tie survival 69/145 versus 46/140 is an observed conditional association. Its
nominal p=.010 is not multiplicity-adjusted across all explored hypotheses and
windows; the state mixes and timing of entering that conditioning set can differ.

An integer margin has **probability mass** at zero. A Gaussian has a density;
the corresponding reference mass integrates over [−0.5,+0.5] and depends on
both its mean and SD. `1/(SD*sqrt(2*pi))` assumes mean zero and is a small-bin
approximation, not a fitted null validated by the report. Local ratios and
Gaussian ratios use different references and can differ without contradiction.
No independent real regulation-margin distribution was supplied to substantiate
the earlier assertion that real basketball has “twice” its smooth density.

This review does not rerun the 12,800-game experiment or certify its raw shard
outputs. It reviews the visible methodology and reported counts. Historical
tables in §5.34 are retained with a conspicuous supersession notice.

## 3. Free-throw clock audit

### End-to-end ownership and consequences

| Stage | Current behaviour |
| --- | --- |
| `SimulationBalanceProfile.free_throw_event_seconds` | 2 seconds, registered range 0–10 |
| `ClockResolver.free_throw_ms()` | Converts seconds to milliseconds |
| `PossessionEngine._resolve_free_throws()` | Calls `_advance_dead_ball` before each attempted FT |
| `_advance_dead_ball()` | Writer consumes `min(duration, max(clock−1,0))`; protects the award from premature termination |
| `MatchEventWriter.consume()` | Decrements the same game-clock timestamp used for all emitted events |
| `MatchStateReducer.apply_event()` | Calls `_advance_clock` before interpreting the FT event |
| `_advance_clock()` | Decrements game and shot clock; sends elapsed time to `FatigueResolver` |
| `FatigueResolver.apply_elapsed()` | Adds on-court played/stint time and fatigue; advances bench rest/recovery |
| Made final FT | Terminates with `MADE_FREE_THROW`; next inbound is correctly stopped-clock |
| Missed live final FT | Enters the ordinary rebound resolver, whose time can expire the remaining 1 ms |

There is no separate FT event-time field in this chain. The 1-ms clamp protects
award attribution; it does not stop game time. It can leave no useful rebound
time. Shot-clock resets after the trip can mask an intermediate decrement, but
the reducer still consumes shot-clock time contrary to the stated §9.4 rationale.

One additional ordering dependency matters for a future correction:
`should_intentionally_miss_final_free_throw` runs after writer consumption but
before the FT outcome event is reduced. It reads the snapshot clock from the
previous emitted event, not the writer's just-decremented timestamp. Review
that decision/stamp distinction explicitly instead of assuming both clocks
already agree at the decision point.

### Production-ledger replay, not only a source scan

`tools/audit_free_throw_clock.gd` runs one fixed-seed game per launch profile and
replays every event through the production reducer. The table sums changes
specifically when FT-made/missed events are applied. It is a diagnostic sample,
not a population estimate. All five profiles had attempts (seed 991001,
catalog variation 0).

| Profile | FTA | Game-clock ms charged | Shot-clock ms charged | Summed player-played ms charged |
| --- | ---: | ---: | ---: | ---: |
| High school | 34 | 68,000 | 64,000 | 680,000 |
| College | 33 | 66,000 | 66,000 | 660,000 |
| Development | 38 | 76,000 | 70,000 | 760,000 |
| Overseas | 33 | 66,000 | 56,349 | 660,000 |
| Top domestic | 21 | 42,000 | 42,000 | 420,000 |

Ten on-court players explain the last column's factor of ten. Actual shot-clock
charges can be smaller because the reducer clamps at zero. The nominal
`attempts * 2 seconds` computation in §5.34 is not generally an exact sum of
game-clock consumption either: the end-period clamp must be accounted for.

### Contract finding and action boundary

The current restart policy itself says the clock is stopped from the whistle
until the legal touch after a made FT. §9.4 explicitly disallows incorrect
shot-clock consumption. The FT path is inconsistent with those explanations.
External fidelity is also clear for the NBA proxy: its timing rule stops the
clock on a whistle and resumes a live missed FT on legal player touch.
[NBA Rule 5, sections V and VIII](https://official.nba.com/rule-no-5-scoring-and-timing/).

**Recommended contract:** FT administration and attempts consume neither game
nor shot clock. Preserve awarded points at period end. Resume clock consumption
only with eligible live play. Do not represent dead-ball duration by advancing
the game timestamp, and do not manufacture a 1-ms remainder to finish awards.

**Not enacted here:** item 22 explicitly says neither consumption-path nor
desperation changes may occur without an owner ruling. “Do the audit” is not
treated as choosing that reserved semantics. No global constant was set to zero,
no probability changed, and no compensating pace adjustment was made.

If approved, implement the narrow consumption-path correction separately and
test 1/2/3-shot trips, one-and-one, and-one, made/missed final FT, dead/live
rebounds, late/horn awards, every competition, replay and Play/Sim/Skip parity.
Assert no clock or played-minutes decrement across FT events; ensure live
rebound/putback time still counts. Review the intentional-miss window's existing
derivation: its 7-second rationale includes a four-second opponent FT trip and
must not survive unchanged without re-evaluation. Re-measure all five profiles
before deciding whether pace needs re-derivation. Ruleset/golden changes must
be explained from actual first divergence, not predicted or reseeded to pass.
Removing incorrectly charged active time can also change fatigue and therefore
later effective capabilities. “No direct probability formula edits” must not
be reported as “no outcome probability can change.”

## 4. Independent external recount

### Sources, provenance and admissibility

Source snapshots: SportsDataverse's ESPN-derived men's college and NBA
schedules, season-ending years 2022–2026. The publisher describes its scrape →
processing → release pipeline in its
[repository](https://github.com/sportsdataverse/sportsdataverse-data).
Release collections:
[college](https://github.com/sportsdataverse/sportsdataverse-data/releases/tag/espn_mens_college_basketball_schedules)
and [NBA](https://github.com/sportsdataverse/sportsdataverse-data/releases/tag/espn_nba_schedules).

This is an **independent computation**, not an independent provider or a fresh
upstream census. Nine existing schedule hashes match the earlier saved profile.
The original college-2024 file does not; its rejection is retained in
`analysis/overtime_reference/snapshot_audit.json`. A fresh publisher download on
2026-09-15 restored the complete file and matches the earlier full-file hash
`d0ff9be08e6f9fb3eda550fd2e3fcf73c1113e1493deb322d90e82a9d4e417c4`.
All final hashes and asset URLs are in `analysis/overtime_reference/recount.json`.

The earlier report labelled the data CC BY 4.0; this review did not confirm that
grant for these assets. The currently accessible repository
[LICENSE](https://github.com/sportsdataverse/sportsdataverse-data/blob/main/LICENSE)
is MIT for software/documentation, not proof of rights to redistribute ESPN
data. Only our analysis code, hashes and aggregate counts are committed. Raw
data and real player/team content are not shipped with the game.

### Definition and quality checks

- One distinct completed game, with valid final non-tied scores and final period
  at least regulation length; overtime means **final period > regulation**.
  Multiple OTs count as one overtime game.
- No box-score availability join: a completed schedule game need not have a
  team-box export to contribute to this outcome rate.
- NBA: regular season and playoffs separate; play-ins separately. Exclude
  `ALLSTAR` and `CC` (Cup championship); retain other Cup games. Cup finals do
  not count toward regular standings.
  [NBA Cup explainer](https://www.nba.com/news/nba-cup-101).
- Each NBA season reconciles to **1,230 regular-season games**. Every retained
  NBA game also has reconciling period scores and regulation-tie/OT flags.
- College type 2 includes conference tournaments; type 3 means the provider's
  postseason, not solely NCAA tournament. Conference flags are a peer-play
  proxy, not an equal-strength sample. The all-games pool can include
  non-Division-I opponents; no strict D-I-only census is claimed.
- College 2023–24 file ends in a partial row: 716 rows versus 6,249 recorded in
  the prior profile. Reject the **whole season**. Do not silently treat the
  March-only fragment as a complete season or import the old totals. The final
  recount uses the newly recovered complete snapshot, independently processed.
- College game `401711727` is flagged OT but its first two period scores are
  65–67. Quarantine it rather than choose which provider field to trust.
  A second record, `401604426`, reports period 3 but has four line-score entries
  (the extra entry is zero for both teams); it is also quarantined. Including
  both as provider-flagged OT games would move the final pooled result from
  1,677/31,021 to 1,679/31,023, approximately +0.006 pp. No manual correction
  is silently incorporated.
- All 2021–22 college line scores are absent in this schema; those games rely
  on final-period classification. All retained later college games pass the
  available line-score checks. Missing verification is not labelled a pass.
- Conflicting duplicates or malformed season files fail closed. Incomplete,
  nonstandard, forfeit and contradictory rows are recorded as exclusions.

### Results

Both final populations use five seasons, 2021–22 through 2025–26. The initial
four-season college snapshot audit is preserved separately. Percentages are pooled from counts,
not unweighted averages of season percentages.

| Population | OT / games | Rate | 95% Wilson interval |
| --- | ---: | ---: | ---: |
| College, all retained types 2+3 | 1,677 / 31,021 | 5.41% | 5.16–5.66% |
| College, conference flag | 1,155 / 17,957 | 6.43% | 6.08–6.80% |
| College, provider type 2 | 1,637 / 30,430 | 5.38% | 5.13–5.64% |
| College, provider type 3 | 40 / 591 | 6.77% | 5.01–9.09% |
| NBA, regular season | 310 / 6,150 | 5.04% | 4.52–5.62% |
| NBA, playoffs | 18 / 422 | 4.27% | 2.71–6.64% |
| NBA, play-in (separate) | 3 / 30 | 10.00% | 3.46–25.62% |
| NBA, regular + playoffs | 328 / 6,572 | 4.99% | 4.49–5.54% |

| Season | College conference OT / games | NBA regular OT / games |
| --- | ---: | ---: |
| 2021–22 | 214 / 3,498 (6.12%) | 58 / 1,230 (4.72%) |
| 2022–23 | 251 / 3,593 (6.99%) | 79 / 1,230 (6.42%) |
| 2023–24 | 230 / 3,561 (6.46%; recovered file) | 59 / 1,230 (4.80%) |
| 2024–25 | 230 / 3,645 (6.31%) | 60 / 1,230 (4.88%) |
| 2025–26 | 230 / 3,660 (6.28%) | 54 / 1,230 (4.39%) |

Wilson intervals are descriptive binomial sampling intervals, **not** clustered
by team or season, not coverage-error bounds, and not simulation certification.
The schedules themselves describe historical outcomes, not an IID randomized
experiment. The season table makes heterogeneity visible. Small postseason
subsamples do not establish the band for each competition phase independently.

**Recommendation:** keep 4–8% for college and top domestic. Both external pools
provide substantive support; they do not prove exactly 4% and 8% are uniquely
correct endpoints. Do not lower the band to fit current engine output. NBA is a
proxy for fictional UBL, not authority over its design. No claim extends to
high school, Development or overseas from these two datasets.

## 5. Reproduction and verification

```bash
python -m unittest discover -s analysis/overtime_reference -v
python analysis/overtime_reference/recount.py --raw-root /path/to/raw_snapshots
GODOT_BIN=/path/to/verified/godot tools/run_checks.sh
/path/to/verified/godot --headless --path . --script res://tools/audit_free_throw_clock.gd
```

Raw layout: `mbb_schedule/mbb_schedule_{2022..2026}.csv` and
`nba_schedule/nba_schedule_{2022..2026}.csv`. For exact reproduction compare
hashes with the manifest; upstream release assets are mutable. The separately
preserved damaged-snapshot audit records the original exclusion, while the
final recount explicitly records the restored source.

The independent Python suite passed **18/18**. A separate pandas calculation
(not importing the recount helper) agreed on all **26** checked phase/season
and pooled-conference cells. Both JSON artifacts regenerated byte-identically.
The five-profile replay passed its coverage guard. Baseline import, parse
(258/0) and acceptance passed with the checksum-verified pinned engine.

**Final local gate: exit 0**, run with the added diagnostic on the verified
Godot 4.7.1-stable binary:

| Check | Result |
| --- | --- |
| Import | PASS |
| Parse | 259 scripts, 0 failures |
| Project acceptance / six golden ledgers | PASS, goldens unchanged |
| Simulation smoke | Invariants PASS |
| Builder smoke | PASS |
| Attribute sensitivity | 80/80 judged, 0 failures |
| Calibration smoke | 15/15 judged, 0 failures |
| GdUnit4 | 672/672 cases, 52/52 suites, 0 errors/failures/flaky/skipped/orphans |

GdUnit execution time was 16m 11.947s. The extra GDScript is a standalone
diagnostic, so the production regression case count remains 672. The Python
18-case suite is separate and is not claimed as part of existing GitHub CI.
`git diff --check` passes. No files under `src/`, `tests/`, or `.github/`, no
`BALANCE_SPEC.md`, and no `SIMULATION_SPEC.md` changed relative to the reviewed
baseline. No calibration or home-court run was repeated as if production had
changed. No §27.1 certification was run or claimed.

The review is committed locally on `codex/stage4-clock-evidence-review`; no
remote push, PR-body edit, merge or history rewrite was performed. The CI
success in §1 belongs to the reviewed upstream head, not these local commits.
