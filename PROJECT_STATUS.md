# LeagueBound Godot Core — Project Status

| Field | Value |
| --- | --- |
| Snapshot date | August 16, 2026 |
| Repository | `vindigit/leaguebound-godot-core` |
| Runtime | Godot 4.7.1-stable; typed GDScript |
| Default branch baseline | `main` at `c38bd2257d27ebce86beb61439fcac524acca0ef` |
| Active work branch | `stage4-calibration`; contains unmerged Stage 4 implementation and status-documentation commits |
| Current internal milestone | Builder, ratings, development, and match-core calibration |
| Current PRD delivery gate | **Gate 0 — Godot foundation** |
| Gate 0 status | **Not met** |
| Current technical authority | `GODOT_TDD.md` |
| Basketball-resolution authority | `SIMULATION_SPEC.md` |
| Numeric and calibration authority | `BALANCE_SPEC.md` |

## 1. Executive status

LeagueBound is a new Godot 4.x implementation. The React Native/Expo application and its TypeScript, Zustand, IndexedDB, AsyncStorage, Jest, npm, Ink bridge, and component architecture are archived reference material only. They are not part of the live runtime, build, test, or migration target.

The current Godot repository contains a substantial pure-domain foundation:

- One canonical 20-attribute player model.
- A deterministic Builder and player-development domain.
- Role-neutral Current Overall, Maximum Potential Overall, and Projected Peak as separate values.
- Deterministic exact caps and bounded body maturation.
- A seeded multi-action possession-to-full-game match engine.
- Ordered match events, one authoritative state reducer, and box-score reconciliation.
- Structural foul, free-throw, rebound, substitution, fatigue, regulation, overtime, and Play/Sim/Skip contracts.
- Committed deterministic golden-ledger scenarios.
- A Stage 4 calibration harness and layered CI design on the active branch.

This is meaningful implementation progress, but it is not a completed Gate 0 and not a complete simulation certification. Persistence, three save slots, minimal application flow, the 22-scenario transition runner, and Android/iOS export-save-resume evidence remain outside the implemented foundation. Stage 4 also records unresolved calibration failures and missing reports.

No Personal Hub, career calendar, recruiting, contracts, world simulation, content runtime, narrative system, monetization, or other product-surface expansion is authorized by this status. The immediate priority remains making the player and basketball foundation trustworthy.

## 2. Authority and evidence rules

This file reports implementation evidence. It does not define gameplay, change design authority, approve a provisional balance value, or waive an acceptance requirement.

When sources conflict, use the hierarchy in `GODOT_TDD.md`. In summary: explicit owner rulings and the applicable locked level-specific documents outrank the general design and product documents; technical implementation follows the current Godot TDD; numeric tuning and evidence follow the Balance Specification.

Status labels used here:

- **Verified structural foundation:** Implemented in the Godot repository with focused deterministic or invariant coverage recorded in repository evidence.
- **Measured, not certified:** A harness produced results below the required certification sample or without a completed aggregate report.
- **Partial:** Meaningful implementation exists, but one or more owning contracts or required reports remain open.
- **Not started:** No current Godot end-to-end implementation evidence exists.
- **Blocked:** A failed or missing prerequisite prevents acceptance.

Commit messages, README claims, and documentation notes are not equivalent to an independently archived CI result. When a result has not been preserved as a committed report or completed check, this file describes it as reported or measured rather than certified.

## 3. Repository state

### 3.1 Default branch baseline

The recorded `main` baseline is commit `c38bd2257d27ebce86beb61439fcac524acca0ef`, titled `feat: rebuild deterministic multi-action match engine`.

The commit reports:

- 208 tests passing under warnings-as-errors.
- One multi-action possession state machine over the eleven action families.
- `MatchStateReducer` as the only match-state writer.
- Runtime lineups as participation authority.
- Offensive-rebound continuation under one possession identity.
- Structural fouls, bonus tiers, free throws, foul-outs, rebounds, putbacks, substitutions, minutes, and plus/minus.
- `MatchSession` as the shared stepped path for Play, Sim, and Skip.
- Named, versioned match tunables with units and safe ranges.
- Six committed golden-ledger scenarios.

The same commit explicitly records free-throw rate, three-point percentage, and assist rate as outside their Balance Specification bands at that stage. Stage 3 established basketball processes before final tuning; it did not certify the distributions.

### 3.2 Active Stage 4 branch

At this snapshot, `stage4-calibration` contains unmerged Stage 4 work plus the current and archived status documents, and it has no open pull request. The Stage 4 implementation adds or changes:

- Competition-specific calibration targets and rule profiles.
- Attribute-sensitivity, competition, career-progression, and performance runners.
- Machine-readable report types and provenance.
- Deterministic sharded-report aggregation, with structured seed intervals, shard identity, and raw aggregation terms on every metric (§6.1).
- Pull-request, nightly, and deep-verification workflow definitions, including nightly summary and deep certification aggregation jobs.
- Additional simulation and progression tuning.
- A Stage 4 evidence record in `BALANCE_SPEC.md`.
- Implementation-status synchronization in `SIMULATION_SPEC.md` §30.2, with no change to its basketball contracts.

Because the fast workflow triggers on pushes to `main` and on pull requests, an ordinary direct push to `stage4-calibration` does not by itself establish that the branch passed the pull-request gate. A PR or an explicitly dispatched equivalent run is still required.

## 4. Implemented Godot foundations

### 4.1 Canonical ratings and Builder

Status: **Verified structural foundation; calibration still provisional.**

Implemented evidence includes:

- Exactly 20 canonical public attributes on the active-player 25–99 domain.
- One role-neutral Overall calculator using the documented blend.
- Overall, Maximum Potential, Projected Peak, and derived archetype excluded from match resolution.
- One universal destination-rating cost table.
- Creation AP isolated from the career Attribute Point wallet.
- Builder confirmation blocked until the creation budget is exhausted.
- Weak, ordinary, specialist, and unusual legal builds supported by the domain.
- Stable rotation-role and tactical-role catalogs with separate responsibilities.
- Deterministic cap generation from versioned seed inputs.
- Detail-promotion invariance for committed player-development state.

The currently implemented creation budget, bases, and profile modifiers remain provisional until their required reports pass. Builder reachability at fixed seeds is not full build-diversity or dominance certification.

### 4.2 Development and body state

Status: **Partial.**

Implemented evidence includes:

- Current Overall, Maximum Potential Overall, and Projected Peak as distinct values.
- Exact per-attribute caps.
- Deterministic body range and maturity planning.
- Once-per-career-year body resolution through shared completion receipts.
- Body growth containment inside the stored projected range.
- No silent rating mutation from body growth.
- Shared user, full-detail NPC, and aggregate-executor development contracts.

Open evidence includes projected-peak calibration, body-maturation report 15, full OVR truthfulness report 1, and complete large-sample development distributions.

### 4.3 Match engine

Status: **Verified structural foundation; statistical certification open.**

Implemented evidence includes:

- Immutable match input and seeded explicit randomness.
- Regulation and overtime full-game execution without a scene tree.
- Inbound, transition/advance, half-court entry, action selection, advantage, turnover, foul, shot, free throw, rebound, putback, and possession-end states.
- Eleven action families.
- One authoritative reducer for score, clock, lineups, fouls, and match statistics.
- Exactly one start and one terminal end per possession.
- Offensive rebounds continuing the same possession with the competition shot-clock reset.
- Runtime lineups, substitutions, and foul-outs affecting eligibility to participate.
- Structural rotation, fatigue, foul, free-throw, rebound, turnover, shot, assist, steal, and block paths.
- Event-ledger and box-score reconciliation.
- Play/Sim/Skip structural parity through one match session.

This status does not certify all competition distributions, player-role distributions, attribute-to-game sensitivity, Tier A/Tier B parity, manual perfect-window behavior, injury output, badge behavior, or large-sample performance.

### 4.4 Determinism and golden evidence

Status: **Verified structural foundation.**

Committed golden hashes cover:

- Regulation.
- Overtime.
- Offensive-rebound continuation.
- Fouls and free throws.
- Substitution and foul-out.
- Late-game behavior.

Each scenario has a behavioral assertion so a hash cannot continue passing after its named behavior stops occurring. Golden changes require an intentional engine or balance version change and review.

### 4.5 Calibration tooling

Status: **Partial; measured, not certified.**

The active branch contains:

- One target registry with owning document references.
- Per-competition team and player metric accumulation.
- Attribute-sensitivity analysis.
- Career-progression simulation.
- Performance profiling.
- JSON reports with rules, balance, RNG, seed, sample, duration, and denominator provenance.
- Raw aggregation terms on every poolable metric, so a sharded run recombines exactly instead of averaging shard estimates.
- A deterministic shard combiner with provenance, completeness, and seed-disjointness validation (§6.1).
- Separate fast, nightly, and deep workflow layers, with aggregation jobs in the latter two.

The harness is real foundation work. It does not become certification until the required samples are completed, combined correctly, archived, and judged by the owning tolerances. Combining correctly is now implemented; completing the required samples is not.

## 5. Current Stage 4 findings

### 5.1 Reported passing at the sample sizes run

The active branch records the following as passing at the samples actually executed:

- All 20 attributes monotonic and directionally meaningful from 50 to 80 at the isolated-boundary sample.
- No IQ attribute substituting for the named primary skill in those tests.
- Four of five career-peak outcome bands: poor/injury-hit, ordinary, strong, and exceptional.
- No measured population peak above 95 Overall in the run.
- Continuity across the designed 72–74 transition region.
- Equivalent mean peak Overall for manual, full-detail allocator, and aggregate-executor progression under equivalent opportunity.
- Builder completed-build bands remaining inside their current locked target envelopes after the progression change.
- Deterministic golden-ledger reproduction after an explicit versioned change.

These findings remain subject to the sample sizes and limitations recorded by the reports. Only attribute sensitivity is recorded as reaching its applicable full isolated-boundary sample.

### 5.2 Known failures or unmeasured requirements

The figures below are now taken from the **pooled** three-shard progression run (1,200 careers over seeds 1–1200), which supersedes the earlier single-shard 400-career figures. Pooling moved two of them slightly; none of them passes.

| Requirement | Current recorded status |
| --- | --- |
| Rare-generational peak band | **Fail:** pooled median 90 against target 92–95 (was 91 single-shard) |
| Projected-peak coverage | **Fail:** 29.2% pooled coverage against 70–85% (was 33% single-shard) |
| Projected-peak signed error | **Fail:** pooled median +10.0 against ±2; systematic under-prediction after progression tuning (was +9.5 single-shard) |
| Competition §14.1 bands | Substantially converged, not certified; approximately ten recorded misses remain |
| Assist percentage | Still low in development, overseas, and top domestic profiles (48.2% top domestic against 52–72%) |
| §14.2 game-shape targets | Not assessable at the samples run |
| Builder dominance tournament | Not implemented/run |
| OVR truthfulness report 1 | Not implemented/run |
| Body maturation report 15 | Not implemented/run |
| Play/Sim/Skip large-sample report | Structural byte parity exists; required scale report not run |
| Tier A/Tier B parity | Not implemented/run at the required scale |
| §27.1 competition certification | Not reached |

The projected-peak coverage and signed-error failures are a direct consequence of the Stage 4 progression change rather than an independent defect: `ProjectedPeakCalculator` was calibrated against the pre-Stage-4 seasonal AP bands, and raising those bands to reach the §8.4 curve left the projection systematically pessimistic. It must be recalibrated against the current bands.

## 6. Certification and workflow blockers

### 6.1 Sharded-report aggregation

Status: **Resolved as implementation; certification still gated on sample size.**

The combiner now exists: `calibration/harness/report_aggregator.gd`, driven by `calibration/runners/run_report_aggregation.gd`, with aggregation jobs added to the nightly workflow (summary, `--allow-uncertified`) and to deep verification (certification, per competition and for progression).

Each of the six minimum requirements above is met:

1. **Every expected shard required.** A missing index, a duplicate index, or an index outside the declared range is a rejection.
2. **Provenance verified.** Commit SHA, Godot build mode, rules profile and version, balance profile and version, ratings version, RNG algorithm and stream-key version, target version, competition, and sample unit must all agree. Metric definition, denominator, and target must agree per metric.
3. **Seed disjointness enforced structurally.** Reports now carry a `seed_range` interval and a shard index rather than a sentence describing them, so overlap is checkable. Two shards that declare no interval are treated as overlapping rather than assumed safe.
4. **Raw terms combined, never rounded rates.** This required a schema change: reports previously carried only an estimate and a sample count, so combining them would necessarily have averaged shard estimates. Metrics now carry numerator, denominator, count, sum, and sum-of-squares. Percentile metrics — including the locked career-peak medians, which cannot be recovered from summed moments — carry the full bounded-integer histogram, which pools by addition and yields the exact combined percentile.
5. **Intervals and verdicts recomputed.** Wilson for proportions, moment-based for means, and every verdict re-evaluated against its band from the pooled estimate. `MetricAggregation.estimate()` is the only place a sharded estimate is produced, so "never average shard means" holds by construction rather than by review.
6. **One immutable aggregate report; job fails when incomplete.** Any rejection fails the job. An aggregation that is valid but short of its required sample also fails unless `--allow-uncertified` is passed, which the nightly summary uses because nightly samples cannot reach the requirement.

Metrics that genuinely cannot be pooled — a 99th percentile with no histogram — are reported as un-aggregatable rather than silently combined.

Verification, recorded so this entry is not merely a claim:

- Ten synthetic-shard cases run in the fast acceptance suite, including one whose shard denominators differ by an order of magnitude so that pooling (0.8960) and averaging (0.70) give visibly different answers.
- End-to-end on real three-shard competition and career-progression runs.
- **Mutation testing.** Returning the first shard's estimate instead of the pooled one failed 6 cases; disabling seed-overlap detection failed 1; disabling missing-shard detection failed 2; restoring the code returned the suite to PASS.

The aggregator found one real defect on first contact with live data: the executor-parity metric derived its tolerance from each shard's own sample mean, so every shard declared a different target and the shards could not legitimately be combined. A target that moves with the sample is not a target. It now reports the relative difference against the fixed ±2% tolerance the Balance Specification states, which is also exactly poolable for matched cohorts.

**What this does not do** is certify anything. It removes the blocker; the required samples still have to be run. No nightly or deep workflow run has executed.

### 6.2 Pull-request evidence

Status: **Blocked.**

At this snapshot, the active branch has no open pull request. Its fast workflow therefore has not been established through the repository's normal PR path. Open a PR or execute and archive an equivalent branch-specific run before merge.

### 6.3 Performance risk

Status: **Measured risk; architecture decision not yet approved.**

Stage 4 records an improvement from approximately 5,496 ms to 1,345 ms per complete reference game with byte-identical ledgers after removing eager assert-message work, memoizing immutable capability inputs, and avoiding candidate string construction.

At the measured rate, the required complete-game calibration samples are expensive. The branch proposes a compiled extension as the path to the aspirational 10 ms calibration goal, but native adoption is not approved by this status file.

Before an ADR selects GDExtension or another native path, evidence must distinguish:

- Debug versus release-template performance.
- Calibration-throughput needs versus actual mobile runtime budgets.
- Safe process-level parallelism and report aggregation.
- Remaining allocation, dispatch, and algorithmic hotspots.
- The smallest isolated interface that could move native without changing deterministic results.
- Golden-ledger and distribution parity across implementations.

## 7. Gate 0 assessment

Gate 0 is evidence-based and remains **not met**.

| Gate 0 outcome | Status | Current evidence or blocker |
| --- | --- | --- |
| Pinned Godot 4.x project imports and runs headlessly | **Reported foundation** | Godot 4.7.1 and headless commands are committed; clean-checkout PR evidence remains pending for Stage 4 |
| Typed GDScript and complete foundation suite pass | **Reported foundation** | `main` commit records warnings-as-errors and 208 tests; active-branch PR check not yet established |
| Pure seeded match fixture reproduces without a scene tree | **Verified structural foundation** | Full-game signatures and golden ledgers |
| Dependency checks prevent domain imports of presentation/infrastructure/platform/autoloads | **Partial** | Current domain is isolated; complete automated dependency-enforcement evidence must remain in the clean suite |
| SQLite opens, migrates, writes, backs up, restores, and reopens a slot | **Not started** | No persistence adapter or database proof |
| Exactly three isolated local career slots pass lifecycle and contamination tests | **Not started** | No slot persistence implementation |
| Minimal scene creates/resumes a slot, renders a projection, and commits one deterministic command | **Not started** | Presentation/application flow outside the current milestone |
| Android and iOS install/launch/save/resume/reopen proof | **Not started** | No release-equivalent mobile evidence |
| 22-scenario transition runner exists and records all eleven axes | **Not started** | Transition harness absent from the current Godot foundation |
| Archived React Native/Expo runtime is absent from the live dependency graph | **Verified structural foundation** | New Godot repository and pipeline contain no live React Native runtime dependency |

Gate 0 cannot be marked complete from match-engine progress alone.

## 8. Explicit scope boundary

The following are outside the current implementation milestone:

- Personal Hub and production UI.
- Career calendar and weekly loop.
- Recruiting, offers, eligibility, transfers, declaration, contracts, rights, assignments, imports, trades, and endings.
- Tier B and Tier C world simulation executors.
- SQLite persistence and save slots until the simulation foundation is stable enough to advance Gate 0 deliberately.
- Narrative runtime and content ingestion.
- Social, relationships, NIL, agents, finances, assets, and investment.
- Ads, purchases, analytics, platform SDKs, and store compliance.
- React Native, Expo, Zustand, IndexedDB, AsyncStorage, npm, Jest, and the archived application shell.

Level-specific and career documents remain authoritative constraints. Their existence does not authorize their implementation during the current match-core milestone.

## 9. Immediate work queue

Work should proceed in this order unless new evidence changes a dependency:

1. Open a pull request from `stage4-calibration` and run the fast branch gate.
2. ~~Add deterministic aggregation for sharded competition and progression reports.~~ **Done** (§6.1). Remaining dependency: execute a nightly or deep run, which has never happened, and confirm the `chickensoft-games/setup-godot@v2` action referenced by both new workflows actually resolves on this project's runner — it was written from convention, not verified.
3. ~~Synchronize the implementation-status portions of `SIMULATION_SPEC.md` with completed Godot work without changing its contracts.~~ **Done.** Nine §30.2 items that described completed Godot work as outstanding are marked complete; `TacticalLocation` is correctly left outstanding, because the type exists but no resolver reads it.
4. Recalibrate `ProjectedPeakCalculator` against the current progression bands and close the coverage/bias failure. This is now the highest-value open item: it is a known-cause failure with a known fix direction.
5. Resolve the rare-generational 92–95 peak miss without distorting ordinary and exceptional careers.
6. Resolve the remaining competition-process misses, beginning with assist creation and attribution, then marginal shooting and points-per-possession edges.
7. Implement and run the Builder dominance tournament, OVR truthfulness report, and body maturation report.
8. Complete the required game-shape and parity reports at usable samples.
9. Measure release-build and mobile-relevant performance before approving a native-extension ADR.
10. Merge Stage 4 only when its reports and CI evidence support every claim made at merge time.
11. After simulation readiness, resume the remaining Godot Foundation Gate work: SQLite, three slots, minimal application flow, transition harness, and Android/iOS proof.

Do not begin Personal Hub, full career systems, recruiting, or content-runtime expansion while simulation readiness remains open.

## 10. Status maintenance rules

- Update this file only from current Godot code, committed reports, CI checks, and explicit owner decisions.
- Keep branch evidence separate from merged `main` evidence.
- Record exact commit, engine, rules, balance, RNG, target, seed, sample, build-mode, and command provenance for statistical claims.
- Never label a sharded run certified without a validated aggregate report.
- Never describe a provisional balance value as approved merely because one sample passed.
- Do not copy implementation status from the archived React Native report.
- Do not count a type, fixture, mock, README claim, or roadmap item as end-to-end implementation.
- Do not weaken tolerances, delete tests, or regenerate golden hashes solely to obtain a pass.
- Mark Gate 0 complete only when every Gate 0 outcome has current evidence.
- Link detailed reports and issues rather than turning this file into another design specification.

## 11. Archived predecessor status

The July 22, 2026 React Native/Expo status report is retained only at:

`docs/archive/PROJECT_STATUS_REACT_NATIVE_2026-07-22.md`

It is historical evidence and must never be used as current implementation authority.
