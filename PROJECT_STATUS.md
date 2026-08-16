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

**Stage 4 is not complete.** Three locked metrics are measured and failing — projected-peak coverage, projected-peak signed error, and the §8.4 rare-generational band — and two mandatory reports remain unimplemented. Both progression failures now have a measured root cause rather than an assumed one (§5.3), which is a prerequisite for fixing them and is not a fix. No Stage 4 result is certified, and §6.4 explains why none can be produced without CI hardware. The full gate inventory is §5.5.

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

At this snapshot, `stage4-calibration` contains unmerged Stage 4 work plus the current and archived status documents. **Pull request #1 is open as a draft into `main`, and its Pull request gate passed at commit `00567d4`.** The Stage 4 implementation adds or changes:

- Competition-specific calibration targets and rule profiles.
- Attribute-sensitivity, competition, career-progression, and performance runners.
- Machine-readable report types and provenance.
- Deterministic sharded-report aggregation, with structured seed intervals, shard identity, and raw aggregation terms on every metric (§6.1).
- Pull-request, nightly, and deep-verification workflow definitions, including nightly summary and deep certification aggregation jobs.
- Additional simulation and progression tuning.
- A Stage 4 evidence record in `BALANCE_SPEC.md`.
- Implementation-status synchronization in `SIMULATION_SPEC.md` §30.2, with no change to its basketball contracts.
- A free-throw accounting correction (`00567d4`), described in §4.4.
- The body maturation report (§31 report 15) and its nightly and deep workflow jobs.
- Projected-peak and career-peak diagnostic runners, and §8.1 ceiling selection pressure.

Because the fast workflow triggers on pushes to `main` and on pull requests, an ordinary direct push to `stage4-calibration` does not by itself establish that the branch passed the pull-request gate. Commits pushed after `00567d4` have not been through the gate at the time of this snapshot; the PR's current head must be green before the draft is lifted.

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

**One golden hash was deliberately regenerated during Stage 4, at `00567d4`.** Any earlier wording — in this file, in the pull request, or in a commit message — suggesting that Stage 4 regenerated no golden hash is superseded by this entry.

| Fact | Value |
| --- | --- |
| Scenario regenerated | `foul_free_throw` |
| Scenarios byte-identical | The other five |
| Ruleset version | Bumped to `simulation-calibrated-v3` |
| Regression coverage added | Yes — see below |

The reason is a genuine simulation-rule correction, not a convenience. The committed `foul_free_throw` ledger encoded an **invalid awarded-without-attempted free-throw sequence**: a shooting foul with 1.0 s left in period 1 awarded two free throws, then free-throw event time expired the period and the possession terminated before a single attempt was emitted. The ledger therefore contained a `FREE_THROW_AWARDED` that nothing ever took. `SIMULATION_SPEC.md` §13.2 requires an attempt to be attributed exactly once, and zero is not once; in basketball the horn does not cancel free throws already awarded.

No correct engine can reproduce that ledger, so the hash had to move. The blast radius is proven by the five unchanged hashes: the correction is confined to the scenario that actually contained the defect. Free-throw event time now advances through the dead-ball path, which consumes clock but cannot take a period to zero, so the period still ends — the next live action finds a one-millisecond clock and expires it — but it ends after the sequence is attributed rather than in the middle of it.

Regression coverage was added rather than adjusted. `test_one_and_one_second_attempt_must_be_earned` had been applying the one-and-one forfeiture rule to every award in its fixture, including shooting fouls, which award their attempts outright; the forfeiture branch was consequently never reached. It now separates bonus awards from shooting fouls by the causing whistle and asserts both rules, on a fixture that produces three forfeits and three earned second attempts. `test_team_fouls_reset_each_period_and_personal_fouls_do_not` now replays the ordered ledger at every period boundary instead of sampling between possessions. Both are strictly more coverage than before.

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
| Body maturation report 15 | **Implemented and measured** — see §5.3 |
| Play/Sim/Skip large-sample report | Structural byte parity exists; required scale report not run |
| Tier A/Tier B parity | Not implemented/run at the required scale |
| §27.1 competition certification | Not reached |

### 5.3 Diagnosis of the two progression failures

Both failures above were carried with an assumed cause. Both assumptions were measured and both were wrong in a way that changes the fix. The measurements come from `calibration/runners/run_projected_peak_diagnostics.gd` at 3,000 careers over seeds 1–3000; the error decomposition reproduces at 600 careers and the subgroup pattern reproduces at 600 and 1,500.

**Projected peak is entirely a budget defect, not a conversion defect.** The recorded cause — that `ProjectedPeakCalculator` was calibrated against the pre-Stage-4 bands — is right about the direction and gives no idea of the size. Splitting the signed error into the model's two independent halves:

| Component | Median |
| --- | ---: |
| Total signed error | +10.0 |
| Attributable to the credited opportunity budget | +10.0 |
| Attributable to the AP-to-Overall conversion | **0.0** |

The conversion is exact: given the true lifetime AP, the model predicts the realized peak with a median error of zero. The model credits a mean of 603 AP against 1,198 actually granted, and realized opportunity runs at **1.39× the projection's own upper bound**. By outcome class the displayed range brackets only poorly-managed careers:

| Outcome class | Coverage | Median signed error |
| --- | ---: | ---: |
| Poor / injury-hit | 1.000 | −1.0 |
| Ordinary successful | 0.046 | +9.5 |
| Strong, well managed | 0.042 | +15.0 |
| Exceptional | 0.033 | +19.5 |
| Rare generational | 0.000 | +22.5 |

What the model calls "ordinary opportunity" is poor-career opportunity. This is a severe hidden subgroup failure that the pooled 29.2% coverage figure conceals.

**Rare generational is cap-bound *and* opportunity-bound.** The recorded cause — that cap generation at the high-upside tail "needs a further pass" — is half the answer. Those careers reach 96–98% cap attainment on 2,200–2,600 lifetime AP, so opportunity is saturated and more AP buys nothing; but their Maximum Potential median was 92 against exceptional's 90, two points apart where the §8.4 bands are six apart. That is a mismatch between the label and the generated talent.

`CapGenerator.generate` now takes §8.1's "competition-appropriate selection pressure" as an explicit parameter: the ceiling is the highest of a small pool of draws from the same distribution. This is selection rather than a bonus — every ceiling it can produce was already reachable, which is what §8.2's prohibition on silently increasing a cap requires — and a pool of one consumes exactly one normal draw, so every existing generation path is bit-identical and no golden hash moves.

Applying a pool of two to the generational class raised its Maximum Potential median from 92 to 94 and **left its realized peak at 90**, with attainment falling from 0.976 to 0.965. That is reported rather than tuned around: the ceiling alone does not close the band, because those careers then run out of AP before filling the headroom. Reaching a peak of 93 needs roughly 2,900 lifetime AP against the 2,620 currently granted. Both levers are required and the second is not yet applied — see §6.4 for why applying it is not straightforward.

### 5.4 Body maturation report 15

Status: **Measured below requirement.** Implemented in `calibration/runners/run_body_maturation.gd`, wired into the nightly and deep workflows, and verified to aggregate through the existing shard pipeline.

Measured at 2,000 matched maturity triples (6,000 individual maturations) over seeds 1–2000:

| Metric | Value | Target |
| --- | ---: | ---: |
| Adult containment in the stored range | 1.0000 | 1.0 |
| Intermediate legality | 1.0000 | 1.0 |
| Skeletal monotonicity | 1.0000 | 1.0 |
| Growth determinism from the career seed | 1.0000 | 1.0 |
| Increment idempotency | 1.0000 | 1.0 |
| Exact increment count | 1.0000 | 1.0 |
| No rating side effect | 1.0000 | 1.0 |
| No cap side effect | 1.0000 | 1.0 |
| No currency side effect | 1.0000 | 1.0 |
| Body plausibility | 1.0000 | 1.0 |
| Stored range matches the versioned widths | 1.0000 | 1.0 |
| Timing is a schedule, not a budget | 1.0000 | 1.0 |
| Early-minus-Late high-school growth share | 0.4797 | ≥ 0.20 |
| High-school share, early / average / late | 0.785 / 0.547 / 0.306 | 0.75 / 0.50 / 0.25 ± 0.08 |

Every judged metric passes except `sample.meets_certification_size`, which fails correctly: 2,000 triples is not the §27.1 progression sample of 1,000,000. Three shards over seeds 1–1200 were aggregated end to end; the aggregator accepted all three, validated provenance and seed-disjointness, pooled the raw terms, and refused to certify the short sample.

The timing comparison is paired: each seed builds the same prospect three times, holding family, prospect profile, freshman body, caps, and the drawn adult body identical and varying only the timing profile. That isolates the timing effect and, being one number per unit, pools across shards exactly as a mean — an unpaired difference of two cohort means does not pool at all.

### 5.5 Stage 4 gate inventory

Every Stage 4 gate, classified. The categories are kept distinct on purpose: a structural proof and an undersized statistical sample are different kinds of evidence, and collapsing them is how an undersized sample comes to be described as certified.

- **Structural** — an invariant or contract proven by deterministic tests. No statistical sample applies.
- **Measured below requirement** — a real measurement at a sample smaller than §27.1 requires.
- **Measured at requirement** — a real measurement at the §27.1 sample, not yet combined into a validated certification report.
- **Certified** — aggregated from complete, seed-disjoint, provenance-matched shards at or above the §27.1 sample, every metric passing.
- **Failed** — measured, and outside its target band.
- **Blocked** — a missing prerequisite prevents the measurement.
- **Not implemented** — no runner exists. This is outside the five evidence categories because those presuppose a report; it is listed rather than folded into "Blocked", which would imply the work is merely waiting on something.

| Gate | Classification | Evidence |
| --- | --- | --- |
| GdUnit4 suite | **Structural** | 209 cases, 26 suites, 0 failures |
| `tests/run_all.gd` acceptance | **Structural** | PASS |
| Parse check under warnings-as-errors | **Structural** | 186 scripts, 0 failures |
| Simulation smoke diagnostics | **Structural** | Invariants PASS at `00567d4` |
| Golden ledgers and determinism | **Structural** | Six scenarios; one deliberately regenerated (§4.4) |
| Event/stat reconciliation | **Structural** | In the acceptance suite |
| Play/Sim/Skip parity | **Structural** | Byte-identical ledgers. The §27.1 50,000-triplet distributional report is **not run** |
| Detail-promotion invariance | **Structural** | `PlayerDevelopmentState.invariant_signature` |
| Creation-budget exhaustion | **Structural** | Builder suite |
| Overall-exclusion dependency check | **Structural** | Dependency test |
| Shard aggregation and provenance validation | **Structural** | Ten synthetic cases plus mutation testing; verified on real body-maturation shards |
| Attribute sensitivity | **Measured at requirement** | 100,000 resolutions per test point; 80/80 pass. Not aggregated into a certification report |
| Builder completed-build bands | **Measured below requirement** | 810 builds at fixed seeds |
| Body maturation (report 15) | **Measured below requirement** | 2,000 triples; all 13 invariants at 1.0000, timing separation 0.4797 |
| Career progression, four of five §8.4 bands | **Measured below requirement** | 3,000 careers; poor 66, ordinary 77, strong 82, exceptional 87 |
| Population share peaking above 95 OVR | **Measured below requirement** | 0.0000 at 3,000 careers |
| §8.4 continuity across the 72–74 gap | **Measured below requirement** | 0.017 share at 3,000 careers, against a 0.01–0.20 band |
| Executor parity (manual / full-detail / aggregate) | **Measured below requirement** | Relative peak difference 0.0000 at 3,000 careers |
| Performance profile | **Measured below requirement** | 1,345 ms/game debug; no release-template measurement |
| Competition §14.1 bands | **Measured below requirement, and stale** | ~10 misses recorded before `00567d4`; the free-throw correction changes scoring and possession outcomes, so every competition figure predates its own engine |
| **§8.4 rare-generational band** | **Failed** | Median 90 against 92–95, at 3,000 careers. Diagnosed (§5.3); fix incomplete |
| **§6.3 projected-peak coverage** | **Failed** | 0.283 against 0.70–0.85, at 3,000 careers. Diagnosed (§5.3); fix incomplete |
| **§6.3 projected-peak signed error** | **Failed** | +10.0 against ±2, at 3,000 careers. Diagnosed (§5.3); fix incomplete |
| §6.3 projected-peak median width | **Measured below requirement** | 11.0 against 6–12; passing, but only because the range is wrongly placed |
| §14.2 game-shape targets | **Blocked** | Confidence intervals span ±25 points at reachable samples |
| §27.1 certification, every report | **Blocked** | See §6.4; the samples are not reachable on developer hardware |
| Nightly workflow | **Blocked** | Never executed. `chickensoft-games/setup-godot@v2` remains unverified on this project's runner |
| Deep-verification workflow | **Blocked** | Never executed |
| Builder dominance tournament (report 3) | **Not implemented** | — |
| OVR truthfulness (report 1) | **Not implemented** | — |
| Tier A/Tier B parity | **Not implemented** | — |

Nothing in this table is **Certified**.

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

Status: **Partially resolved.**

Pull request #1 is open as a draft from `stage4-calibration` into `main`, and its Pull request gate passed at commit `00567d4`. The branch has therefore been through the repository's normal PR path at least once.

What remains open is that commits after `00567d4` have not yet been through that gate at the time of this snapshot. The gate must be green on the pull request's **current head**, not on an ancestor, before the draft is lifted.

### 6.4 Certification sample sizes are not reachable on a developer machine

Status: **Blocked on infrastructure, not on implementation.**

This is the constraint that governs every remaining Stage 4 statistical claim, and it is arithmetic rather than opinion. Measured throughput on the reference development machine (8 logical cores, debug build with asserts active):

| Report | Measured rate | §27.1 requirement | Single-process time |
| --- | ---: | ---: | ---: |
| Career progression | 9.1 careers/s | 1,000,000 careers | ≈ 31 hours |
| Body maturation | 12.3 triples/s | 1,000,000 triples | ≈ 23 hours |
| Competition calibration | ≈ 1.3 s/game | 100,000 games × 5 competitions | ≈ 180 hours |

Process-level sharding divides these by the number of cores, not below them. No developer-machine session produces a certified result for any of the three, and none should claim one. The nightly and deep workflows exist precisely because this work belongs on CI hardware across many parallel runners; neither has ever executed.

The practical consequence for reading this document: where a metric below is marked **measured**, it was measured at the stated sample and that sample is stated because it is short of the requirement. Nothing in Stage 4 is currently **certified**.

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

1. ~~Open a pull request from `stage4-calibration` and run the fast branch gate.~~ **Done.** PR #1 is open as a draft and its gate passed at `00567d4`. It must be re-run on the pull request's current head before the draft is lifted.
2. ~~Add deterministic aggregation for sharded competition and progression reports.~~ **Done** (§6.1). Remaining dependency: execute a nightly or deep run, which has never happened, and confirm the `chickensoft-games/setup-godot@v2` action referenced by both new workflows actually resolves on this project's runner — it was written from convention, not verified.
3. ~~Synchronize the implementation-status portions of `SIMULATION_SPEC.md` with completed Godot work without changing its contracts.~~ **Done.** Nine §30.2 items that described completed Godot work as outstanding are marked complete; `TacticalLocation` is correctly left outstanding, because the type exists but no resolver reads it.
4. **Settle whether the §6.3 coverage band and width guardrail are jointly satisfiable**, then either recalibrate the projected-peak opportunity model or raise a contradiction for an owner decision. The cause is now measured rather than assumed (§5.3): the conversion is exact and the whole error is the credited budget. What is not yet established is whether a range narrow enough to satisfy the width guardrail can cover 70% of realized peaks at all, given that the §8.4 outcome classes span roughly 25 Overall points and the outcome is unknowable at career start. `calibration/runners/run_projected_peak_sweep.gd` measures both the parameter surface and the irreducible width that bounds any creation-time model.
5. Resolve the rare-generational 92–95 peak miss. Selection pressure has moved Maximum Potential to 94 and is not sufficient alone; those careers also need roughly 280 more lifetime AP-equivalent, and §9.5's guardrails and §9.6's game-development caps both constrain how that may be supplied (§5.3).
6. **Re-measure every competition metric before tuning any of it.** The recorded §14.1 misses, including the 48.2% top-domestic assist percentage, all predate the `00567d4` free-throw correction, which changes scoring and possession outcomes. Tuning against a stale measurement would be tuning against the wrong engine. Re-measure first, then diagnose assist creation versus attribution, then the marginal shooting and points-per-possession edges. The 1.186 points-per-possession figure was taken at 80 games and is not a valid basis for any tuning decision.
7. Implement and run the Builder dominance tournament and the OVR truthfulness report. ~~Body maturation report 15~~ **is implemented** (§5.4) and awaits only its sample.
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
