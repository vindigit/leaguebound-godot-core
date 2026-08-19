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

**Stage 4 is not complete.** All five §8.4 career-peak bands now measure inside their locked targets, and two mandatory reports remain unimplemented. The two projected-peak failures are corrected and pass with interior margin on independent validation ranges (§5.7); the §8.4 rare-generational band is corrected and passes on two further untouched ranges (§5.8); and §5.9 closes that milestone by recording the §9.5 owner ruling, enforcing its 20% bound structurally, repairing a parse gate that could not fail, and correcting an AP figure that counted rating points. No Stage 4 result is certified, and §6.4 explains why none can be produced without CI hardware. The full gate inventory is §5.6.

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
- The rare-generational root-cause and two-lever sweep runners, §9.6 game-development cap enforcement, and §9.5 upper-guardrail warnings (§5.8).
- The §9.5 elite-opportunity ruling as a persistent career condition with a structurally enforced bound, corrected Attribute-Point accounting, and a parse/compile gate that can fail (§5.9).

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

Open evidence includes full OVR truthfulness report 1 and complete large-sample development distributions. Projected-peak calibration is corrected and passing on independent validation ranges (§5.7), and body-maturation report 15 is implemented and measured (§5.4); neither is certified.

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
- All five career-peak outcome bands: poor/injury-hit, ordinary, strong, exceptional, and — since §5.8 — rare generational.
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
| Rare-generational peak band | ~~**Fail:** pooled median 90 against target 92–95~~ **Corrected (§5.8):** median 93 on the development range and on two untouched validation ranges |
| Projected-peak coverage | ~~**Fail:** 29.2% pooled~~ **Corrected (§5.7):** 0.7473 and 0.7370 on two untouched validation ranges against 70–85% |
| Projected-peak signed error | ~~**Fail:** pooled median +10.0~~ **Corrected (§5.7):** −1.0 and 0.0 on two untouched validation ranges against ±2 |
| Competition §14.1 bands | Substantially converged, not certified; see §5.5 for the post-correction re-measurement |
| Assist percentage | **Fail, and confirmed unchanged by the free-throw correction:** 48.15% top domestic at 400 games against 52–72% |
| §14.2 game-shape targets | **Now assessable, and four of five fail** — see §5.5 |
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

**The §6.3 coverage band and the width guardrail are jointly satisfiable.** This was worth establishing before any tuning, because if they were not, the correct action would have been a contradiction report rather than a model change.

`run_projected_peak_sweep.gd` measures the *irreducible* range width: careers are grouped by everything knowable when the range is displayed — prospect profile and Maximum Potential, which together fix the caps the projection reads — and inside each group it finds the narrowest window containing 70% of the realized peaks. No forecast built from creation-time inputs can be narrower and still cover 70%, because within a group the forecast cannot tell the careers apart. It is an optimistic bound, which is what makes it useful: if it exceeded the guardrail, no model could satisfy both.

| Seed range | Groups | Careers | Weighted median | p25 | p75 | Max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1–3000 | 35 | 2,831 | **8.0** | 6.0 | 11.0 | 16.0 |
| 100001–103000 | 34 | 2,800 | **8.0** | 6.3 | 10.8 | 13.0 |

Two independent seed ranges agree on 8.0, comfortably inside the 6–12 guardrail. **The requirement is reachable; the gap is the model.**

The complementary result explains why the current model cannot reach it. Sweeping every global `[low, high]` opportunity pair — one interval shape applied to every career — tops out at 0.666 coverage at a median width of 12, with a single pair reaching exactly 0.7000/12.00/−2.00, sitting on all three band edges at once and therefore fitted to noise rather than to anything real. A one-size-fits-all interval is the wrong shape: the irreducible width varies from 6 to 16 across groups, so the range has to be conditioned on the individual career's own uncertainty rather than scaled uniformly. That is the fix direction, and it is a modelling job rather than an owner decision.

**Rare generational is cap-bound *and* opportunity-bound.** The recorded cause — that cap generation at the high-upside tail "needs a further pass" — is half the answer. Those careers reach 96–98% cap attainment on 2,200–2,600 lifetime AP, so opportunity is saturated and more AP buys nothing; but their Maximum Potential median was 92 against exceptional's 90, two points apart where the §8.4 bands are six apart. That is a mismatch between the label and the generated talent.

`CapGenerator.generate` now takes §8.1's "competition-appropriate selection pressure" as an explicit parameter: the ceiling is the highest of a small pool of draws from the same distribution. This is selection rather than a bonus — every ceiling it can produce was already reachable, which is what §8.2's prohibition on silently increasing a cap requires — and a pool of one consumes exactly one normal draw, so every existing generation path is bit-identical and no golden hash moves.

Applying a pool of two to the generational class raised its Maximum Potential median from 92 to 94 and **left its realized peak at 90**, with attainment falling from 0.976 to 0.965. That is reported rather than tuned around: the ceiling alone does not close the band, because those careers then run out of AP before filling the headroom. Both levers are required and the second was not applied here.

**§5.8 supersedes the sizing in this paragraph.** The "roughly 280 more lifetime AP" figure was inferred from the ceiling result rather than measured; the direct conversion measurement puts the requirement at about 530 more, and it also corrects the "cap-bound *and* opportunity-bound" reading. The cohort's *median* career is opportunity-bound and spends everything it is granted; only its upper ceiling tail is cap-bound. §5.8 has the measurement and the correction.

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

### 5.5 Top-domestic re-measurement after the free-throw correction

Every recorded §14.1 and §14.2 figure predated `00567d4`, which changed how free throws are attributed and therefore changes scoring and possession outcomes. Tuning against those figures would have been tuning against an engine that no longer exists, so the profile was re-measured before anything was touched. 400 complete games, seeds 1–400, at commit `c57f34e`.

| Metric | Measured | Target | Verdict |
| --- | ---: | ---: | --- |
| Possessions/game | 99.64 ±0.23 | 96–103 | PASS |
| Points per possession | **1.2084** | 1.08–1.18 | **FAIL** |
| FG% | 0.4601 ±0.0035 | 0.45–0.51 | PASS |
| 3P% | 0.3741 ±0.0053 | 0.34–0.40 | PASS |
| 3PA/FGA | 0.4091 ±0.0035 | 0.36–0.49 | PASS |
| FT% | 0.8013 ±0.0061 | 0.73–0.83 | PASS |
| FTA/FGA | 0.2132 ±0.0029 | 0.18–0.34 | PASS |
| Turnovers/100 | 13.50 | 11–16 | PASS |
| Offensive rebound % | 0.2838 ±0.0044 | 0.20–0.31 | PASS |
| **Assist %** | **0.4815 ±0.0052** | 0.52–0.72 | **FAIL** |
| Home win rate | 0.5625 ±0.0484 | 0.53–0.56 | FAIL (interval spans the band) |
| **Overtime rate** | **0.0175 ±0.0136** | 0.04–0.08 | **FAIL** |
| **Close-game share** | **0.1925 ±0.0386** | 0.22–0.34 | **FAIL** |
| **Blowout share** | **0.3450 ±0.0464** | 0.08–0.18 | **FAIL** |
| Starter mean minutes | 31.07 ±0.14 | 27–35 | PASS |

Three findings change the recorded picture.

**Assist percentage is unchanged by the correction.** 0.4815 at 400 games against the 0.482 previously recorded at 80. The failure is a real property of the assist model rather than an artifact of the pre-correction engine, so the §5.2 diagnosis of creation versus attribution can proceed against the current engine.

**Points per possession did not improve, and the previous figure understated the miss.** 1.2084 at 400 games against 1.186 at 80 — five times the sample and further outside the band. It is still far short of the §27.1 100,000, but it is no longer resting on a sample too small to act on, and the direction is now clear.

**§14.2 game shape is assessable at 400 games, and it is badly wrong.** This supersedes the "not assessable at the samples run" entry, which was written when only tens of games had been run. Four of five targets fail, and they fail as one coherent pattern rather than independently: 34.5% of games are blowouts against a target of 8–18%, only 19.3% are close against 22–34%, and only 1.8% reach overtime against 4–8%. Too many decided games and too few tight ones is a single defect — the game-to-game score margin is over-dispersed — and it is very likely the same defect that puts points per possession above its band. The home win rate is nominally outside its band but its interval spans it and it should not be treated as an independent failure at this sample.

This is the largest single block of new Stage 4 evidence, and it argues that the remaining competition work is not "roughly ten marginal misses" but one structural problem in how possession outcomes accumulate into a final margin.

### 5.6 Stage 4 gate inventory

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
| Career progression, all five §8.4 bands | **Measured below requirement** | 3,000 careers; poor 66, ordinary 77, strong 82, exceptional 87, rare generational 93 (§5.8) |
| Population share peaking above 95 OVR | **Measured below requirement** | 0.0000 at 3,000 careers |
| §8.4 continuity across the 72–74 gap | **Measured below requirement** | 0.017 share at 3,000 careers, against a 0.01–0.20 band |
| Executor parity (manual / full-detail / aggregate) | **Measured below requirement** | Relative peak difference 0.0000 at 3,000 careers |
| Performance profile | **Measured below requirement** | 1,345 ms/game debug; no release-template measurement |
| Competition §14.1 bands, top domestic | **Measured below requirement** | Re-measured after `00567d4` at 400 games (§5.5). Nine of eleven pass |
| Competition §14.1 bands, other four | **Measured below requirement, and stale** | Recorded before `00567d4`; the free-throw correction changes scoring and possession outcomes, so those figures predate their own engine and must be re-measured before use |
| **§14.1 top-domestic assist percentage** | **Failed** | 0.4815 ±0.0052 against 0.52–0.72 at 400 games. Confirmed unchanged by the free-throw correction |
| **§14.1 top-domestic points per possession** | **Failed** | 1.2084 against 1.08–1.18 at 400 games, worse than the 1.186 recorded at 80 |
| **§14.2 blowout share** | **Failed** | 0.3450 ±0.0464 against 0.08–0.18 at 400 games |
| **§14.2 close-game share** | **Failed** | 0.1925 ±0.0386 against 0.22–0.34 at 400 games |
| **§14.2 overtime rate** | **Failed** | 0.0175 ±0.0136 against 0.04–0.08 at 400 games |
| §14.2 home win rate | **Measured below requirement** | 0.5625 ±0.0484 against 0.53–0.56; the interval spans the band, so not an independent failure at this sample |
| §8.4 rare-generational band | **Measured below requirement** | **Corrected (§5.8), closed (§5.9).** Median 93 against 92–95 at 3,000 careers and on two untouched 2,000-career validation ranges. Was 90 |
| §9.5 upper-guardrail warnings | **Measured below requirement** | Every guardrail-passing season carries a source-ledger explanation, 1.0000 on all three ranges |
| §9.5 elite-opportunity ruling | **Structural** | Bounded at 20% per the owner ruling of 2026-08, enforced as each season is granted so the lifetime total cannot exceed it at any setting; zero violations on all three ranges and through three-shard aggregation |
| §9.6 seasonal game-development caps | **Structural** | Enforced by `DevelopmentService.grant_game_development`; no career-season credits game participation beyond 12/16/20 |
| AP ledger reconciliation | **Structural** | `granted − attribute spend − non-purchase debits = unspent` judged on every career; zero failures on all three ranges |
| Parse/compile gate | **Structural** | Repaired (§5.9). Exits 1 on a script that does not compile in any configured root, 2 when it cannot verify itself, and self-tests its detector on every run |
| §6.3 projected-peak coverage | **Measured below requirement** | **Corrected (§5.7).** 0.7473 and 0.7370 against 0.70–0.85 on two untouched 3,000-career ranges; 0.7420 and 0.7360 on the production judged path. Was 0.283 |
| §6.3 projected-peak signed error | **Measured below requirement** | **Corrected (§5.7).** −1.0 and 0.0 against ±2 on the untouched ranges. Was +10.0 |
| §6.3 projected-peak median width | **Measured below requirement** | 11.0 against 6–12 on both untouched ranges, now with the range correctly placed |
| §6.3 projected-peak subgroup honesty | **Measured below requirement** | Zero pathological subgroups across 15–16 judged creation-time groupings per range |
| §14.2 starter and rotation minutes | **Measured below requirement** | 31.07 ±0.14 starter mean against 27–35 at 400 games |
| §27.1 certification, every report | **Blocked** | See §6.4; the samples are not reachable on developer hardware |
| Nightly workflow | **Blocked** | Never executed. `chickensoft-games/setup-godot@v2` remains unverified on this project's runner |
| Deep-verification workflow | **Blocked** | Never executed |
| Builder dominance tournament (report 3) | **Not implemented** | — |
| OVR truthfulness (report 1) | **Not implemented** | — |
| Tier A/Tier B parity | **Not implemented** | — |

Nothing in this table is **Certified**.

### 5.7 Projected Peak model correction

#### Model structure

The forecast has two halves: estimate the opportunity the remaining career will receive, then convert that opportunity into Overall against the player's own caps and the §9.1 cost table. §5.3 measured them separately and found the conversion exact — given the true lifetime opportunity it reproduces the realized peak with a median error of zero and a standard deviation near half an Overall point. The correction is therefore confined to the opportunity estimate; the conversion is untouched.

```text
ExpectedHorizonAP(prospect, age)
  = Σ over seasons from age to horizon_age[prospect] of
        midpoint(seasonal_ap_band[phase]) × growth_availability[prospect][growth_phase]

low_ap   = ExpectedHorizonAP × opportunity_low[prospect]
high_ap  = ExpectedHorizonAP × opportunity_high[prospect]

low_overall  = spend_cheapest_first(current ratings, exact caps, low_ap)
high_overall = spend_cheapest_first(current ratings, exact caps, high_ap)
```

The result is then bounded by the §6.3 rule 4 ordering rules and the width guardrail.

Two changes matter, and both were indicated by measurement rather than chosen.

**The band midpoint replaces the band edges.** The previous model paired the §9.5 seasonal *minimum* with the seasonal *maximum* and discounted both by an "ordinary opportunity share" and two allocation efficiencies. That conflated the within-season spread of one season's grant, which averages out across a fifteen-season career, with the career-long spread of total opportunity received, which does not. Carrying season-scale spread as though it were career-scale uncertainty is what produced a forecast crediting a mean of 603 AP against 1,198 actually granted.

**The opportunity interval is conditioned on the prospect profile.** §7.2 makes the profile the determinant of how much opportunity a career generates, and High Upside is the only profile with genuine access to the §8.4 exceptional and generational outcomes, so its honest interval is wider. A single global interval cannot express that: §5.3 established that the exhaustive global sweep reached the coverage floor only by sitting on the coverage, width, and bias limits at once, which is a fit to sampling noise.

A second conditioning axis needs no parameter. The conversion saturates at Maximum Potential, so a career whose caps bind receives a narrow range automatically — more opportunity could not have helped it. That is why the measured width varies from 6 at the cap-bound end to 15 at the open-ended end while the median stays inside the guardrail.

#### Inputs

Creation-time only: current ratings, exact per-attribute caps, prospect profile, current age, the §9.1 cost table, the §9.5 seasonal availability bands, and the §7.2 growth-availability multipliers. The three fitted quantities are per-profile arrays of three values each — `projected_peak_opportunity_low`, `projected_peak_opportunity_high`, and `projected_peak_horizon_age` — published through `describe_tunables` with units and safe ranges as §4 requires.

#### Evidence that no future information leaks

- `ProjectedPeakCalculator.project` takes no `RandomSource` and no career-state argument. It cannot consult a draw it was never given, and adding one would be a signature change rather than a silent regression.
- `test_projection_ignores_identity_and_career_state` constructs the same player under three different career seeds and player identities and asserts an identical projection.
- The counterfactual that uses realized lifetime AP lives in the calibration layer, in `run_projected_peak_diagnostics.gd`, and is not reachable from the domain.
- The correction is nine versioned numbers, three per prospect profile, serving every career. There is no per-seed table and no memorised outcome.

#### Seed ranges

Fitting, tuning, and validation use disjoint deterministic seed ranges. The validation ranges were never measured until the parameters were frozen, and were not revisited afterwards.

| Purpose | Seeds | Careers | Runner |
| --- | --- | ---: | --- |
| Development — parameter fit | 1–600 | 600 | diagnostics |
| Tuning — independent confirmation | 200001–202000 | 2,000 | diagnostics |
| Validation A — untouched | 300001–303000 | 3,000 | diagnostics |
| Validation A — untouched | 300001–302000 | 2,000 | career progression |
| Validation B — untouched | 402001–405000 | 3,000 | diagnostics |
| Validation B — untouched | 402001–404000 | 2,000 | career progression |

The two runners sample the same untouched range at two sizes: the diagnostics runner supplies the subgroup tables, and the career-progression runner is the production judged path that also reports the §8.4 bands and executor parity. The two are never pooled, so the shared seeds are not double-counted evidence.

The tuning range required **no parameter change** — the values fitted on the development range passed it as they stood. That is a stronger result than a tuning pass, and it is why no third fitting iteration was run.

#### Results

Headline §6.3 measures. The model is deterministic on a fixed seed, so a rerun of any range reproduces these exactly.

| Range | Careers | Coverage (0.70–0.85) | Signed error (±2) | Median width (6–12) | Conversion error |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before, pooled | 1,200 | 0.292 | +10.0 | 11 | 0.0 |
| Development 1–600 | 600 | 0.7300 | −1.0 | 11 | 0.0 |
| Tuning 200001–202000 | 2,000 | 0.7220 | −1.0 | 11 | 0.0 |
| **Validation A 300001–303000** | 3,000 | **0.7473 ±0.0155** | **−1.0** | **11.0** | 0.0 |
| **Validation B 402001–405000** | 3,000 | **0.7370 ±0.0157** | **0.0** | **11.0** | 0.0 |

All three measures sit in the interior of their bands on both untouched ranges, not on an edge. The conversion error stays at zero throughout, confirming the correction went where the diagnosis said it should.

**Deterministic reruns.** Both validation ranges were executed twice — once before and once after the subgroup-rule correction described below — and reproduced their headline figures exactly: validation A returned 0.7473, 11.0, and −1.0 on both runs, validation B 0.7370, 11.0, and 0.0. The model consults no `RandomSource`, so this is expected; measuring it is what turns the expectation into evidence.

The same conclusion on the **production judged path**, `run_career_progression.gd`, which is the runner the certification workflows execute. Both validation ranges, 2,000 careers each, at commit `2a38f24`:

| Metric | Validation A (300001–302000) | Validation B (402001–404000) | Target |
| --- | ---: | ---: | ---: |
| `projected_peak.coverage` | 0.7420 ±0.0192 | 0.7360 ±0.0193 | 0.70–0.85 |
| `projected_peak.median_width` | 11.0 ±0.1458 | 11.0 ±0.1459 | 6–12 |
| `projected_peak.median_signed_error` | −1.0 ±0.2796 | 0.0000 ±0.2841 | ±2 |
| `parity.manual_vs_full_detail` | 0.0000 | 0.0000 | ±0.02 |
| `parity.manual_vs_aggregate` | 0.0000 | 0.0000 | ±0.02 |

Executor parity is exact, so the aggregate and full-detail executors remain consistent with the manual path under the new model. No §8.4 band moved: poor 66, ordinary 77, strong 82, exceptional 87, share above 95 at 0.0000, transition-gap share 0.0175 — every one of them identical to the pre-change measurement. The projected-peak correction is a display-side forecast change and touches no realized outcome, which is exactly what these figures confirm.

That run reports two failures, both expected and neither belonging to this work: `sample.meets_certification_size`, which fails correctly because 2,000 is not the §27.1 million, and `career_peak.rare_generational.median` at 90 against 92–95, which is the pre-existing §8.4 failure recorded in §5.3 and explicitly outside the scope of the projected-peak task. Its value is unchanged from before the correction.

#### Subgroup results

Creation-time groupings on the two validation ranges. `marginal` means outside the population band but inside the pathology bounds; `undersampled` means below 100 careers and therefore not judged.

| Grouping | Validation A | Validation B |
| --- | --- | --- |
| Prospect: ready_now | 0.733 in band | 0.705 in band |
| Prospect: balanced | 0.699 marginal | 0.719 in band |
| Prospect: high_upside | 0.791 in band | 0.773 in band |
| Family: guard | 0.740 in band | — |
| Family: wing | 0.744 in band | — |
| Family: big | 0.758 in band | — |
| Maturity: early | 0.742 in band | — |
| Maturity: average | 0.745 in band | — |
| Maturity: late | 0.754 in band | — |
| Max potential 86+ | 0.744 in band | 0.731 in band |
| Max potential below 86 | 0.713 in band | 0.698 marginal |
| Max potential below 80 | 0.758 in band | 0.763 in band |
| Max potential below 72 | 1.000, width-floored | 1.000, undersampled (n=98) |

Position family and maturity profile are uniformly healthy — 0.740–0.758 and 0.742–0.754 — which matters because neither is an input to the opportunity interval, so a spread there would have signalled a hidden dependence the model does not model.

**Starting-Overall bands are collinear with prospect profile in this population** and reproduce it exactly. The career simulator gives each profile a distinct completed-build band, so the starting-Overall grouping carries no independent information here. It is reported for completeness rather than as a second axis.

**Body-profile groups are degenerate in this population.** `CareerSimulator` builds every player from `default_body_for_family`, so there are exactly three distinct bodies and the body grouping is identical to the position-family grouping. A genuine body-profile subgroup analysis needs a population with body variation, which the career harness does not currently generate. This is recorded as a gap rather than reported as a pass.

**The weakest subgroup is `balanced`**, at 0.699 and 0.719 — marginal on one range, in band on the other. The cause is structural rather than a tuning miss: a Balanced prospect's outcome distribution has roughly 30% of its mass in the poorly-managed class, which lands about 11 Overall points below the median outcome. No range narrow enough to satisfy the width guardrail can reach that mass while keeping the midpoint honest, so Balanced coverage is effectively capped near its ordinary-plus-strong share. Buying those careers would cost roughly four Overall points of width and push the signed error positive.

#### Mutation evidence

A test that cannot fail is not evidence, so each guard was checked by breaking the model and confirming the guard fires. Every mutation was applied to the source, run, and reverted.

| Mutation | Guard that fired | Failures |
| --- | --- | ---: |
| Opportunity interval collapsed to one global constant across profiles | `test_risk_profile_changes_the_interval_width` | 2 |
| Maximum Potential ceiling replaced by the rating maximum | `test_bounds_and_ordering_hold_at_extremes` | 18 |
| Career seed leaked into the opportunity scale | `test_projection_ignores_identity_and_career_state` | 3 |
| Opportunity level reverted to the legacy discount and horizon | `test_regression_against_the_previous_pessimistic_model` | 3 |

One negative result is worth recording because it bounds what the leakage test proves. A first attempt at the leakage mutation passed the career seed through the `historical_peak_overall` argument, and **no test failed** — that argument cannot influence the result for the players under test, because it only relaxes bounds the projection was already inside. The identity test detects a leak that changes the answer; it does not detect a leak that is inert on the tested inputs. The structural guarantee is the stronger one: `project` has no career-state parameter at all, so a real leak requires a signature change rather than a silent edit.

GdUnit4 aborts a suite after failures, so the mutations were run against the whole basketball directory and the specific failing case identified; a mutation run against the single file can stop before reaching a later test.

#### Two corrections to the subgroup check itself

Both were made to the harness rather than to the model, and both are recorded here because a check that is changed after it fires needs to be auditable.

**Career outcome class is not a judged subgroup.** The first version of the pathology metric judged coverage inside the realized §8.4 outcome classes, and reported three pathologies. That check was wrong. Outcome class is a realized result, not information the forecast had, and a correctly calibrated 75% interval is *supposed* to miss inside the outcome tails: it covers the central mass and fails at both ends by construction. Demanding per-outcome coverage demands a forecast that already knows its answer, which §28 forbids. Only creation-time groupings — prospect profile, position family, maturity profile, starting-Overall band, Maximum-Potential band — are judged. The outcome table is still reported, as a diagnostic of where the interval sits.

**Over-coverage at the minimum width is not dishonesty.** Validation A flagged one pathology: `potential_below_72`, coverage 1.000 at a median width of 6.0 — which is exactly the §6.3 minimum width. These are cap-bound players whose Maximum Potential minus Current Overall is already at or below that minimum, so the displayed range *is* the whole legal interval and covering every realized peak is arithmetic rather than flattery. §6.3 forbids "widening the range to meaninglessness"; a range at the specification's own minimum has widened nothing. The ceiling test now applies only where the subgroup's median width exceeds the minimum, so a model that genuinely bought coverage with width is still caught.

That the same group passed unflagged in validation B — at n=98, below the judging threshold, rather than n=107 — confirms the flag was a sample-size artifact of a mis-specified rule and not a property of the model.

Both validation ranges were re-run after the correction so the archived artifacts reflect the rule as it now stands.

#### Regression

Run at commit `2a38f24` with the corrected model in place.

| Check | Result |
| --- | --- |
| Parse check under warnings-as-errors | 188 scripts, 0 failures |
| GdUnit4 full suite | 226 cases, 28 suites, 0 failures |
| `tests/run_all.gd` | PASS |
| Simulation smoke diagnostics | Invariants PASS |
| Builder calibration harness | PASS; ordinary high water 50 OVR against the 54 ceiling |
| Attribute sensitivity at 100,000 resolutions per point | 80 metrics, 0 failures |
| Calibration smoke | 15 metrics, 0 failures |
| Golden ledgers | **Unchanged** — `git diff tests/golden/` empty |

The golden result is the one worth stating explicitly. §6.2 forbids any resolution path from reading Current Overall, Maximum Potential, or Projected Peak, so a change to the projected-peak model must not be able to move a match ledger. It did not, which is a direct check on that separation rather than a formality.

The Builder bands are unmoved, so the §7.3.2 locked outcome bands and the creation-budget contract are unaffected by the projection change — as they must be, since the Builder consumes the projection for display only.

**Shard aggregation.** Three seed-disjoint shards over seeds 1–1200 combined through the existing aggregator: all three accepted, provenance and seed intervals validated, and the estimates rebuilt from the pooled raw terms rather than averaged — coverage 0.7450, median width 11.0, signed error −1.0. The two subgroup metrics are correctly reported as un-aggregatable, which is deliberate: subgroup membership is a property of the pooled population and a per-shard count cannot be summed into it.

That run exposed one harness defect, now fixed. The diagnostics runner declared no certification requirement, so a pooled diagnostic reported itself "below the required 0 complete player careers" — a sentence about nothing. It now declares the §27.1 progression sample like every other runner, so a short pooled run says how short it actually is.

#### Classification

| Item | Classification | Basis |
| --- | --- | --- |
| Determinism, ordering, cap enforcement, absence of career-state inputs | **Structural** | `tests/unit/basketball/test_projected_peak_model.gd`, 11 cases, each with mutation evidence |
| §6.3 coverage, signed error, median width | **Measured below requirement** | Passing on two untouched 3,000-career ranges and on the production judged path at 2,000 careers each; §27.1 requires 1,000,000 |
| Executor parity under the new model | **Measured below requirement** | 0.0000 on both validation ranges against a ±2% tolerance |
| Subgroup honesty | **Measured below requirement** | Zero pathological subgroups across 15–16 judged creation-time groupings per range |
| Body-profile subgroups | **Not measurable in this population** | The career harness generates one body per position family; see above |

Projected Peak is **ready for certification** in the sense that matters: the model passes every §6.3 measure with interior margin on independent samples it was never fitted against, on the runner the certification workflows execute. It is **not certified**, and cannot be from a developer machine — §6.4 gives the arithmetic. Certification requires the deep-verification workflow to run the sharded million-career report.

### 5.8 Rare-generational career-peak correction

Status: **Measured passing on two untouched validation ranges. Not certified** — the §27.1 million-career run remains later work (§6.4).

This is the fifth and last §8.4 band, and the one §5.3 left diagnosed but unfixed. It now reads 93 against the locked 92–95 on the development range and on both untouched validation ranges, with every adjacent band, the share above 95, the 72–74 transition, executor parity, and every §6.3 projected-peak measure unmoved or inside its band.

#### Root cause

`calibration/runners/run_generational_diagnostics.gd` exists to separate §8.4's five candidate corrections — "seasonal AP availability, the cost curve, cap distributions, aging, or decline" — rather than trying them in turn and watching the median move, which is curve fitting. It replays every career's own starting build and caps through the projection's ordinary cheapest-first conversion at multiples of the budget that career actually received, and repeats the exercise against an unbounded cap vector, so a career that ran out of opportunity is distinguishable from one that ran out of ceiling. A second runner, `run_generational_sweep.gd`, measures the two surviving levers as a grid because they interact.

Measured on 200 rare-generational careers over seeds 1–200 at the pre-change commit `0cf18ef`:

| Quantity | Median | Reading |
| --- | ---: | --- |
| Starting Overall | 46 | Identical for every career; the §7.3.2 completed build carries no spread |
| Maximum Potential Overall | 93 | p10 84, p90 98 |
| Realized peak | 90 | p90 91, maximum 92 |
| Headroom, MaxPot − peak | 3 | What the career left unfilled |
| Cap attainment at peak | 0.97 | p90 1.00 |
| Attributes at cap at peak | 4.5 | p90 19.1 — a quarter of the cohort fills every cap it has |
| Lifetime AP granted | 2,610 | 2,415 converted, 177 stranded unspent, 17 removed by decline |
| Peak age | 34 | Peak season 20 of 23; 90% of lifetime AP arrives before it |
| Allocation loss against cheapest-first | 0 | Mean 0.34 Overall |
| Allocation loss against the Overall-maximising bound | 0 | Mean 0.58 Overall |

**Three of the five candidates are ruled out by measurement.**

- **Allocation is not a cause.** The Overall-maximising spend — a bound no legal allocator can beat, because it is the §6.1 blend maximised subject to the §9.1 costs and the player's own caps — exceeds the realized career by 0.58 Overall on average. No reordering of spending closes a three-point gap.
- **Aging and decline are not a cause.** Natural decline removes 17 AP-equivalent across a 23-season career, and 90% of lifetime opportunity arrives before the peak season. Opportunity is not arriving too late to convert.
- **The cost curve is not mistuned.** The measured conversion matches the §9.1 table's own arithmetic almost exactly: raising twenty attributes from a completed freshman build to 89 costs 2,260 AP and to 90 costs 2,420, and the cohort converted 2,415 AP into a peak of 90.

**Two causes remain, and they interact.**

1. **Opportunity, and it is the dominant one.** The measured conversion curve, each career replayed from its own build and caps:

   | Budget | AP | Peak at the career's own caps | Peak against unbounded caps |
   | --- | ---: | ---: | ---: |
   | ×0.80 | 2,106 | 87 | 87 |
   | ×1.00 | 2,632 | 91 | 91 |
   | ×1.10 | 2,896 | 92 | 93 |
   | ×1.20 | 3,159 | **93** | 94 |
   | ×1.30 | 3,422 | 93 | 96 |
   | ×1.50 | 3,948 | 93 | 98 |

   The two columns agree to ×1.10 and separate above it: below that the caps do not bind and opportunity is the whole story; above it the career's own Maximum Potential saturates the conversion. The band needs about ×1.20.

2. **The cohort contained careers incapable of its own band.** At a selection pool of 2 the cohort's Maximum Potential p10 was 84. Those careers reach 96–100% cap attainment, strand up to 1,200 AP unspent, and peak in the mid-eighties at *every* opportunity level tested — the 86–89 histogram is identical across ×1.50, ×1.60, ×1.70 and ×1.80. That is a classification selecting careers that cannot reach the outcome it names, against a §8.4 band described as the rare conjunction of an elite ceiling *and* an elite career.

#### Implemented correction

Two model changes and two provenance corrections.

1. **`PATH_OPPORTUNITY[rare_generational]` 1.42 → 1.85.** The conversion curve asked for ×1.20 of the original budget, which is where this landed at first (1.70). §5.9 re-measured it against the §9.5 owner ruling once that ruling was enforced as a bound rather than checked afterwards, and 1.70 no longer reached the band: read the number and the reasoning there rather than here.
2. **`PATH_CEILING_SELECTION_POOL[rare_generational]` 2 → 3.** §8.1's selection pressure is an order statistic over the profile's own distribution, so every ceiling it yields was already reachable and §8.2's prohibition on silently increasing a cap holds. Measured at a fixed opportunity multiplier on the tuning range, the pool change lifted the cohort's tenth percentile from 88.9 to 90.0 and left the median at 91 — it repairs the tail it was chosen for and leaves the centre alone, which is the signature of a lever acting on the right defect. A pool of 4 was measured, tightens the tail slightly further, and presses the drawn ceiling against the profile's own 99 maximum often enough to pile the distribution on its clip; 3 is the smaller change.
3. **§9.6 game-development caps are now enforced.** The seasonal uplift was booked in its entirety to game participation — around 33 AP a season against a §9.6 cap of 12 in high school, 16 in college, and 20 in professional basketball. `ProgressionProfile.game_development_cap` carries the §9.6 row and `DevelopmentService.grant_game_development` trims to it, returning what it credited so the caller can place the remainder; the remainder is §9.3 training, which §9.5 names as part of the same seasonal total. **The amounts are unchanged and no measured result moves.** Verified directly: realized peak, lifetime AP granted, guardrail seasons, and guardrail excess were identical on the same 60 seeds before and after the split. What changes is that the ledger can account for them.
4. **§9.5 upper-guardrail warnings are emitted, explained, and counted.** The previous model already exceeded the guardrails — 9.7 seasons of 23 per generational career, by 181 AP — silently, while still missing the band. §9.5 makes an exceptional season a balance warning the source ledger must explain rather than a hard currency cap, so `DevelopmentService` now exposes `seasonal_guardrail_warning`, `seasonal_guardrail_is_explained`, and `seasonal_granted_total`. The generic offseason note is deliberately not accepted as an explanation: every season of a phase carries one, so a guardrail it could satisfy is a guardrail nothing could ever trip. `AttributePointLedger` indexes its per-career-year grant totals as entries arrive, because §9.7.2 binds every executor to the §9.5 guardrail and a check costing a full ledger scan is one no production path could afford to run.

#### AP source, grant, spend, and cap attainment

Every unit the cohort receives is granted through `DevelopmentService`, lands in the shared source ledger with its source, career year, executor, and balance-profile version, and — outside the generic offseason phase — carries a note naming what produced it. Mean per career over 400 rare-generational careers on the development range, at the final settings:

| Source | Before | After | Bound |
| --- | ---: | ---: | --- |
| `offseason` (§9.5 generic phase) | 1,837 | 1,837 | One per career year, receipt-enforced |
| `game` (§9.6 participation) | 774 | 395 | §9.6 seasonal cap: 12 / 16 / 20 by phase |
| `training` (§9.3) | 0 | 812 | Inside the §9.5 seasonal total and the §9.5 ruling ceiling |
| **Total granted** | **2,610** | **3,044** | — |

The `game` column falls because §9.6 now bounds it, not because the career received less; the difference moved to `training`, which is where §9.5 says the rest of a high-engagement season comes from.

Grant, spend, and attainment before and after, same cohort. **The "AP spent" row is the corrected figure throughout** — §5.9 explains why the field that used to carry it held rating points instead, and both quantities are now reported separately:

| Quantity | Before | After |
| --- | ---: | ---: |
| Lifetime AP granted, mean | 2,610 | 3,044 |
| Lifetime AP spent, mean | 2,415 | 2,868 |
| Rating points gained, mean | 913 | 972 |
| AP unspent at career end, mean | 177 | 159 |
| AP unspent at career end, median | 0 | 0.6 |
| AP removed by decline, mean | 17 | 17 |
| Cap attainment at peak, median | 0.97 | 0.96 |
| Attributes at cap at peak, mean | 7.4 | 7.2 |
| Maximum Potential Overall, median | 93 | 96 |
| Headroom, MaxPot − peak, mean | 3.4 | 2.4 |
| Realized peak, median | 90 | **93** |

Attainment does not rise, which is the point: the ceiling rose alongside the opportunity, so the cohort is opportunity-bound rather than cap-bound at its new peak. That is also what keeps 96+ out of reach — the caps, not a clamp, are what stop the distribution.

#### Seed ranges and sample sizes

No range was used for two purposes, and neither validation range was looked at until the model was fixed.

| Purpose | Seed range | Sample | Runner |
| --- | --- | ---: | --- |
| Diagnosis / development | 1–200, 1–400 | 200 and 400 forced-path careers | `run_generational_diagnostics.gd` |
| Development, population | 1–3000 | 3,000 careers | `run_career_progression.gd` |
| Tuning | 300001–300300 | 300 careers × 8 grid cells | `run_generational_sweep.gd` |
| **Validation A — untouched** | 700001–702000 | 2,000 careers | `run_career_progression.gd`, `run_projected_peak_diagnostics.gd` |
| **Validation A — untouched** | 700001–700400 | 400 forced-path careers | `run_generational_diagnostics.gd` |
| **Validation B — untouched** | 900001–902000 | 2,000 careers | `run_career_progression.gd`, `run_projected_peak_diagnostics.gd` |
| **Validation B — untouched** | 900001–900400 | 400 forced-path careers | `run_generational_diagnostics.gd` |
| Sharded aggregation | 1–1200 in three shards | 1,200 careers | `run_report_aggregation.gd` |

The tuning grid swept opportunity ∈ {1.50, 1.60, 1.70, 1.80} against selection pool ∈ {3, 4} through `CareerSimulator`'s diagnostic override rows, so no committed constant was edited between tuning cells.

The population runs carry only 39–60 rare-generational careers each, because the cohort is 2% of the population by construction. The forced-path runs exist for that reason: `path_for` consumes one draw whatever it returns and every path at or above `EXCEPTIONAL` takes the same prospect branch, so forcing the top path reproduces exactly the career the population would have produced from that seed. The property is proven on the run's own seeds by `--verify-forced` and pinned by `test_the_forced_path_override_reproduces_the_natural_career`, rather than assumed.

#### Before and after: the full §8.4 table

`run_career_progression.gd`, the runner the certification workflows execute. Before at commit `0cf18ef`, after at `2ece230` — that is, after the §9.5 owner ruling of §5.9 was enforced and the opportunity multiplier re-measured against it.

| Metric | Dev 1–3000 before | Dev after | Val A 700001–702000 before | Val A after | Val B 900001–902000 before | Val B after | Target |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Poor / injury-hit | 66 | 66 | 66 | 66 | 66 | 66 | below 72 |
| Ordinary successful | 77 | 77 | 77 | 77 | 77 | 77 | 74–79 |
| Strong, well managed | 82 | 82 | 82 | 82 | 82 | 82 | 80–85 |
| Exceptional | 87 | 87 | 87 | 87 | 87 | 87 | 86–91 |
| **Rare generational** | 90 | **93** | 91 | **93** | 90 | **93** | **92–95** |
| Share above 95 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | ≤ 0.0001 |
| Transition-gap share | 0.0170 | 0.0170 | 0.0155 | 0.0155 | 0.0140 | 0.0140 | 0.01–0.20 |
| Projected-peak coverage | 0.7483 | 0.7430 | 0.7435 | 0.7380 | 0.7415 | 0.7320 | 0.70–0.85 |
| Projected-peak median width | 11 | 11 | 11 | 11 | 11 | 11 | 6–12 |
| Projected-peak signed error | −1.0 | −1.0 | 0.0 | 0.0 | −1.0 | −1.0 | ±2 |
| Parity, manual vs full detail | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | ±2% |
| Parity, manual vs aggregate | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | ±2% |
| Mean lifetime AP granted | 1,197.7 | 1,204.9 | 1,195.4 | 1,203.6 | 1,189.0 | 1,198.1 | informational |
| Mean lifetime AP spent | not reported | 1,144.0 | not reported | 1,137.9 | not reported | 1,138.6 | informational |
| Mean lifetime AP unspent | not reported | 58.0 | not reported | 62.7 | not reported | 56.6 | informational |
| Mean rating points gained | not reported | 607.7 | not reported | 604.4 | not reported | 604.8 | informational |
| AP reconciliation failures | not reported | 0.0000 | not reported | 0.0000 | not reported | 0.0000 | exactly 0 |
| Guardrail season share | not reported | 0.0543 | not reported | 0.0569 | not reported | 0.0537 | informational |
| Guardrail excess AP per career | not reported | 12.0 | not reported | 12.7 | not reported | 12.4 | informational |
| Guardrail warnings explained | not reported | 1.0000 | not reported | 1.0000 | not reported | 1.0000 | exactly 1.0 |
| §9.5 ruling violations | not reported | 0.0000 | not reported | 0.0000 | not reported | 0.0000 | exactly 0 |

Every adjacent band is byte-identical before and after, as is the transition-gap share, because nothing outside the rare-generational path changed. Three shards over seeds 1–1200 pooled through the real aggregator to the same figures — poor 66, ordinary 77, strong 82, exceptional 87, rare generational 93, zero reconciliation failures, zero ruling violations — and it correctly refused to certify at 1,200 careers.

#### Distribution shape, and why it is tight

The 400-career forced-path cohorts, at the final settings:

| Range | n | p10 | p50 | p90 | Max | Above 95 | AP granted | Max overage |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Development 1–400 | 400 | 88 | **93** | 93 | 93 | 0 | 3,044 | 18.1% |
| Validation A 700001–700400 | 400 | 89 | **93** | 93 | 94 | 0 | 3,045 | 18.1% |
| Validation B 900001–900400 | 400 | 89 | **93** | 93 | 94 | 0 | 3,043 | 17.8% |

The tuning-range histogram at the chosen settings, 300 careers: 86:6 87:8 88:6 89:7 90:11 91:12 92:44 93:194 94:2, and nothing at 95 or above. Eighty percent of the cohort lands inside 92–95 and twenty percent below it; the sub-band tail is the careers whose drawn ceiling does not permit the band, which is a legitimate outcome for a cohort defined by career management rather than by talent alone, and it is unchanged by opportunity because those careers are ceiling-bound.

The distribution is narrow at the top, and it is narrower than it was before the §9.5 ruling was enforced. Two reasons, both explained rather than incidental. §8.4 asks for a median inside 92–95 *and* for 96+ to be practically nonexistent, which at a population share of 0.0001 permits roughly one career in two hundred of this cohort to pass 95, so a cohort satisfying both cannot be wide. And the ruling's per-season ceiling binds in three of the five career phases, which clips the high draws and removes variance along with the excess. Nothing clamps a realized peak: the shape comes from the §9.1 cost curve, which prices the last Overall points at 8 and 12 AP each, from the caps, which saturate the conversion, and now from a bound on opportunity that the owner set.

The distribution is deliberately narrow at the top, and that is a consequence of the locked requirements rather than a clamp. §8.4 asks for a median inside 92–95 *and* for 96+ to be practically nonexistent, which at a population share of 0.0001 permits roughly one career in two hundred of this cohort to pass 95. A cohort satisfying both cannot be wide. Nothing clamps a realized peak: the shape comes from the §9.1 cost curve, which prices the last Overall points at 8 and 12 AP each, and from the caps, which saturate the conversion. The mode at 93 is where an opportunity-bound cohort with low career-level variance in lifetime AP lands, and the sharp fall from 94 to 95 is Maximum Potential binding, not a bound being applied.

#### Projected Peak regression evidence

§6.3 is a protected passing system. `run_projected_peak_diagnostics.gd` on the same two untouched ranges, 2,000 careers each:

| Measure | Validation A | Validation B | Target |
| --- | ---: | ---: | --- |
| `diagnostic.coverage` | 0.7380 ±0.0193 | 0.7320 ±0.0194 | 0.70–0.85 |
| `diagnostic.median_width` | 11.0 ±0.1452 | 11.0 ±0.1466 | 6–12 |
| `diagnostic.conversion_signed_error` | 0.0 | 0.0 | informational |
| `diagnostic.total_signed_error` | 0.0 | 0.0 | informational |
| `projected_peak.pathological_subgroups` | 0.0000 | 0.0000 | exactly 0 |
| Judged creation-time subgroups | 15 | 15 | — |

Creation-time subgroup coverage on validation A ranges from 0.718 to 1.000 across prospect profile, starting-Overall band, and Maximum-Potential band, with no pathological group. The corrected cohort does move one *reported* figure: rare-generational outcome-class coverage falls to 0.154, because those careers' realized peaks rose three points while a forecast that cannot see the outcome label did not follow them. §5.7 established that outcome class is not a judged subgroup — it is a realized result, not information the forecast had, and a correctly calibrated 75% interval is supposed to miss inside the outcome tails. The judged creation-time groupings, and the pooled figure, are what §6.3 is measured on and all of them pass.

#### Executor parity

`parity.manual_vs_full_detail` and `parity.manual_vs_aggregate` are 0.0000 on the development range and on both validation ranges, against a ±2% tolerance, unchanged from before the correction. The suite additionally compares the three executors on the same seed at full resolution — granted opportunity, peak Overall, final Overall, and the complete twenty-rating signature — because a relative difference in mean peak Overall is a weak comparison that two different careers can satisfy by accident. A mutation giving the aggregate executor 5% less opportunity is invisible to the mean-peak comparison alone and is caught by the signature comparison.

#### Structural versus measured classification

The §8.4 cohorts are **structural**, not measured. `CareerSimulator` draws the outcome path first from fixed population shares, and the path then determines opportunity, ceiling selection pressure, coaching quality, mileage, and career length. Nothing reads a realized peak back to assign a label, and no label writes a rating: `test_the_outcome_label_grants_ratings_through_no_other_channel` restricts a career's grants to the three §9.5 seasonal sources, and `test_every_rating_point_is_reconstructible_from_the_ledger` rebuilds the finished twenty-rating vector from the starting build and the ledger alone while checking that the AP charged for each point is exactly what §9.1 prices that destination at.

The structural choice is faithful to §8.4, whose reading rules describe the bands as "career management quality and opportunity" — inputs, not outcomes. It is also a limitation worth stating: the report cannot presently answer the complementary question of what share of generationally-managed careers actually reach 92–95 except by reading the cohort's own distribution, which is why that distribution is reported above rather than only its median.

#### The cost: the §9.5 guardrail, and its owner ruling

This was the one open question §5.8 left for the owner, and it has since been ruled on. **§5.9 carries the ruling, its enforcement, and the measurements that go with it.** What follows is the position as §5.8 left it, kept because the ruling is only legible against the problem it answers.

Summed across the twenty-three seasons of this career shape, the §9.5 high-engagement guardrails permit **2,695 AP-equivalent** — 4 × 187 in high school, 3 × 163 in college, then 4 × 120, 6 × 91 and 6 × 72 across the three professional bands. The measured requirement for a median peak of 93 was about **3,140**, so the cohort ran **16.5% above the guardrails in aggregate**, passing its guardrail in 17 seasons of 23.

Reaching the band inside the guardrails is not possible with this career shape and this cost table. At 2,695 AP and perfect conversion the cohort's median peak is about 91, and the ×1.10 row of the conversion table above is already past the guardrail total.

The resolution follows the document's own authority rules. §8.4 is **Locked** (OD-A). The §9.5 bands are **Baselines**; §9.5 records them as provisional, as "not yet ship-approved", and as measured against a 400-career sample in which "one §8.4 band (rare generational) still misses". §8.4's verification note names seasonal AP availability as the first correction and forbids only relabelling the bands. A Locked target does not move to accommodate a Baseline tunable.

The owner ruling of 2026-08 settles it at 20% of that summed-guardrail figure, bounded to the rare-generational path and to ledgered elite opportunity. Enforcing it changed the model: see §5.9.

#### Tests and mutation evidence

`tests/unit/basketball/test_generational_progression.gd` adds 29 cases. Fifteen mutations were applied to the committed implementation, each run against the suite and then restored; `git status` was clean and `HEAD` unchanged after every one.

| Mutation | Detected by |
| --- | --- |
| §9.6 game cap removed | 5 cases, including the end-to-end per-season cap check |
| Offseason note allowed to explain a guardrail breach | 2 guardrail-explanation cases |
| Direct rating write, bypassing the cost table | ledger reconstruction, plus 3 band cases and 2 pre-existing contract cases |
| Private cheaper cost table | ledger reconstruction and 3 band cases |
| Duplicated generic offseason phase | receipt case and 4 band cases |
| Uplift grants lose their ledger note | provenance case and the guardrail-explanation case |
| Guardrail excess no longer warned | guardrail-explanation case |
| At-cap conversion counted as seasonal availability | seasonal-total case |
| Exceptional cohort raised to the generational settings | adjacent-band case and the no-exceptional-career-in-band case |
| Aggregate executor given 5% less opportunity | executor-parity case, via the rating signature |
| §9.1 cap check removed from `spend_general_ap` | direct spend-past-cap case |
| Opportunity raised to ×1.7 of the corrected setting | the 96+ case and the band case |
| Projected-peak per-profile conditioning collapsed | `test_projected_peak_model.gd` interval-width case |

Three of the twelve original mutations survived the first pass, which is the reason for running them. Each survivor named a real hole: the service's own cap check was never exercised end to end because every executor checks first; peak Overall alone is one rounded number two different careers can share; and raising the exceptional cohort's *opportunity* alone does not pull it into 92–95 because that cohort keeps a selection pool of one and is cap-bound well below the band. All three were fixed by strengthening the tests, and all three mutations are detected on re-run.

### 5.9 Closing the rare-generational milestone

Status: **Structurally closed and measured. Not certified** — the §27.1 million-career run remains later work (§6.4).

§5.8 delivered the §8.4 rare-generational band and left three things open: the §9.5 guardrail tension was recorded as an owner decision rather than settled, the parse/compile gate was known to be unreliable, and one reported AP figure was known to be misnamed. All three are closed here, and closing the second and third changed the first.

#### The owner ruling

**Ruling (authoritative, 2026-08).** *Rare-generational careers may exceed the §9.5 high-engagement upper guardrail by up to 20% when caused by ledgered elite opportunity, while emitting the required balance warning. This exception applies only to the rare-generational path and cannot alter AP costs, game-development caps, population shares, or adjacent outcome bands.*

The measurement it was made against is §5.8's: the cohort received about 3,140 AP-equivalent against a summed seasonal-guardrail allowance of **2,695**, a **16.5% overage**, passing its guardrail in 17 seasons of 23. The ruling caps that at **20%** of the same summed figure.

**It is modelled as a persistent career condition, not as a property of the outcome label.** `CareerOpportunityCondition.ELITE_OPPORTUNITY` is set once, before any season resolves, and is a stored career fact inside the §9.7.4 invariant signature — so a promoted player carries the same permission the aggregate row did. Seventeen exceptional seasons in one career are one condition rather than seventeen unrelated anomalies, which is what the ruling asks for, and a permission attached to a *condition* cannot be claimed by another cohort simply by being handed more opportunity.

**The bound is structural, not tuned.** `DevelopmentService.seasonal_opportunity_ceiling` applies it as each season is granted, so the lifetime total cannot exceed 1.20× the summed guardrails at *any* opportunity setting. The tuning sweep confirms it: at a multiplier of 2.20 the cohort reports an overage of exactly 0.200 and no violation. A later retune cannot walk the cohort past the ruling by accident, and the opportunity that is trimmed is never granted and never ledgered, so nothing is taken back from a wallet.

Careers without the condition are deliberately not trimmed. §9.5 already governs them through the balance warning and the source-ledger explanation, and bounding them would move outcome bands the ruling explicitly may not touch. What they may not do is run a career-long surplus: `career_opportunity_violation` fails any career whose lifetime grant exceeds its own summed guardrails without the condition, whatever band it belongs to.

**Enforcing it exposed a real defect in the previous constant.** At `PATH_OPPORTUNITY[rare_generational] = 1.70` the cohort *mean* overage was compliant at 16.5% while individual careers reached **26%**: measured on 400 careers, lifetime grants ran from 2,769 to 3,397 against a permitted ceiling of 3,234, putting roughly a fifth of the cohort outside the ruling behind a compliant average. **A cohort average is not a bound.** With the bound enforced, 1.70 dropped the median peak to 92 — inside the band but on its floor with no margin — so the multiplier was re-measured against the enforced ceiling and moved to **1.85**, where the median returns to 93 and the worst career reaches 17.9% against the permitted 20%.

1.85 was chosen over the other settings that also reach 93 because it leans on the clamp least. At 2.00 the worst career sits at 19.6%, and at 2.20 the clamp is doing all the work. The cohort should be inside the ruling on its own, with the clamp as a safety property rather than as the thing producing the result.

| Setting | Median peak | Max overage | Ruling violations | Peak histogram 91–95 |
| --- | ---: | ---: | ---: | --- |
| 1.70 | 92 | 0.142 | 0 | 91:20 92:180 93:52 94:0 95:0 |
| **1.85** | **93** | **0.179** | **0** | 91:12 92:44 93:194 94:2 95:0 |
| 2.00 | 93 | 0.196 | 0 | 91:12 92:16 93:201 94:23 95:0 |
| 2.20 | 93 | 0.200 | 0 | 91:12 92:14 93:125 94:101 95:0 |

Tuning range 300001–300300, 300 careers per cell, selection pool 3.

**What the exception does not touch**, each pinned by a test: §9.1 costs are identical for a career carrying the condition and one that is not; the §9.6 seasonal game-development cap is unmoved; the §8.4 population shares are unchanged and still sum to one; and the adjacent bands do not move, because nothing outside the rare-generational path changed.

**A consequence worth naming.** The per-season ceiling binds in three of the five phases, and clipping the high draws removes variance as well as excess. The cohort's realized peaks are correspondingly tighter than before: the mode sits at 93 with about two thirds of the cohort on it. That is explained rather than unexplained — it is an opportunity-bound cohort whose opportunity is now bounded — but it is a narrowing, and it is the reason the §8.4 distribution is reported as a histogram here rather than as a median alone.

#### The parse/compile gate could not fail

Diagnosed directly rather than from the earlier guess. The gate decided whether a script compiled with `load(path) == null`, and that condition never holds: measured on Godot 4.7.1, the GDScript resource format loader prints `Failed to load script ... with error "Parse error"` and **returns the failed script object anyway**. A file with a syntax error was walked, reported by the engine, and counted as a pass — 192 scripts, "0 failure(s)", exit status 0.

The import cache was **not** the mechanism, which the earlier note assumed. `ResourceLoader.load` with `CACHE_MODE_IGNORE` returns the same non-null broken object, so re-reading from disk would not have rescued the old predicate.

`Script.can_instantiate()` replaces it: measured false for a syntax error, for a warning configured as an error, and for a type error, and true for all 191 other scripts in the tree. An abstract script is legitimately non-instantiable and is exempted only when the file on disk actually declares `@abstract`, so a script that failed to compile can never claim the exemption.

Two further silent-pass routes are closed alongside it:

- The gate **self-tests before it walks anything**, compiling one script that works and one that does not, and reports failure rather than an unearned pass if it cannot tell them apart. A future engine change to the predicate therefore cannot quietly turn the gate back into a no-op.
- Every configured root must contain scripts, so a renamed or moved root fails instead of being skipped in silence.

The repair surfaced a third problem in the opposite direction. On a checkout with no `.godot`, the global class cache is empty and every reference to a `class_name` reports as a compile failure — measured at 154 of 193 scripts. That is as useless as a false pass, so it is refused explicitly with exit status 2, and the workflow now builds the cache in its own step first. The gate resolves its own helper by path rather than by global class name for the same reason.

| Gate state | Exit status | Reported |
| --- | ---: | --- |
| Clean tree, class cache present | 0 | 196 scripts checked, 0 failures |
| Malformed script in `src`, `tools`, `tests`, or `calibration` | 1 | the file, named, with the reason |
| No global class cache | 2 | refuses to run, names the fix |

The workflow step asserts the exit status explicitly rather than trusting the printed count, because a count is exactly the thing that lied.

#### AP accounting counted the wrong thing

`CareerResult.total_ap_spent` held the number of whole rating points a career gained. §9.1 prices a point by its destination — 1 AP below 60, rising to 12 at 95 and above — so the two quantities diverge further the higher a career climbs.

| Quantity | Old field | Corrected |
| --- | ---: | ---: |
| Rare-generational rating points gained | 972 | 972, as `total_rating_points_gained` |
| Rare-generational AP spent | reported as 972 | **2,868**, from the ledger |

The corrected figure comes off the shared ledger, which recorded each §9.1 cost as the cost table charged it, so there is one calculation of it rather than a second that could drift. `AttributePointEntry.is_attribute_spend()` is the single rule for what counts: §9.1 spends and §9.2 direct-progress resolutions both buy rating points, while §10.3 decline names an attribute but removes standing, and an unrealized-opportunity debit names no attribute at all.

**The diagnosis in §5.8 was not built on the broken field.** Its conversion figures came from `ap_spent_by_phase`, which was already ledger-derived and already genuine AP. The misnamed field appeared in one printed diagnostic line and in no report, no serializer, and no aggregator — verified by inspecting every stored report artefact. The only `ap_spent` in any committed report is `creation_ap_spent` in the Builder harness, which is the §7.1 creation budget and a different quantity, correctly named.

**Schema.** No stored field changes meaning, so `leaguebound.calibration.report/1` is unchanged. Four metrics are added — `mean_lifetime_ap_spent`, `mean_lifetime_ap_unspent`, `mean_rating_points_gained`, `ap_reconciliation_failures` — which is additive within the schema, and the aggregator buckets by metric id and rejects a shard set with mismatched metrics loudly rather than pooling it silently. Readers of older reports are unaffected; a new aggregator reading an old shard set reports the missing metric rather than inventing one.

**Reconciliation is now judged rather than assumed.** `progression.ap_reconciliation_failures` fails the report if any career breaks

> `granted (by ledger) − attribute spend − non-purchase debits = unspent`

and it caught a real defect on its first run: 88% of the population failed while the rare-generational diagnostics showed a residual of exactly zero. The identity had been stated on `total_ap_granted`, which is the opportunity a career *realized* — and a path that realizes less than the season offered books the shortfall as a debit, because the ledger rejects a negative grant, so subtracting that debit again double-counts it. The rare-generational path never showed it because its adjustment is always positive and the two figures coincide. Both quantities are now kept and named separately, and the reconciliation test runs every outcome path rather than only the one the correction was measured against.

#### Revalidating the §5.8 diagnosis against real AP

Each prior claim, re-checked with genuine AP accounting on the development range, 400 forced rare-generational careers over seeds 1–400.

| §5.8 claim | Verdict | Corrected evidence |
| --- | --- | --- |
| The cohort spends its available AP | **Confirmed, with the tail qualified** | Median unspent 0.6 AP of 3,046 granted; mean 159 because the top decile is cap-bound and strands up to 1,917. §5.8 already stated this as "the median career is opportunity-bound; only its upper ceiling tail is cap-bound", and real AP sharpens rather than contradicts it |
| The gap was opportunity-bound, not allocation-bound | **Confirmed** | Overall-maximising bound still beats the realized career by about 0.5 Overall; the conversion curve still separates capped from uncapped only above ×1.10 |
| `PATH_OPPORTUNITY = 1.70` is supported | **Not supported; corrected to 1.85** | Not because of AP accounting but because the ruling's bound, once enforced, cost the cohort about 220 AP and dropped the median to 92 |
| Ceiling selection pool 3 is supported | **Confirmed** | Maximum Potential median 96, p10 88; the cohort's sub-band tail is unchanged at about 20%, and remains ceiling-bound rather than opportunity-bound |
| §9.6 caps redirect the excess to training without changing the result | **Confirmed** | Game 12/16/20 per season honoured on every career-season; the redirect moves the ledger source and no measured outcome |
| The corrected cohort stays inside 92–95 without clamping | **Confirmed** | Median 93 on three ranges, maximum 93–94, nothing above 95. No realized peak is clamped; the shape comes from the §9.1 cost curve and the caps |
| Adjacent §8.4 bands do not move | **Confirmed** | 66 / 77 / 82 / 87 on every range, byte-identical to §5.8 |
| Projected Peak remains calibrated | **Confirmed** | Coverage, width, and bias unchanged and inside their bands on both untouched ranges |
| Executor parity remains exact | **Confirmed** | 0.0000 on all three ranges, and the three executors now also agree on granted, spent, unspent, and rating points |

#### Measured result

`run_career_progression.gd` at commit `2ece230`, the runner the certification workflows execute. Development range 1–3000; validation ranges 700001–702000 and 900001–902000, neither touched during tuning.

| Metric | Dev, 3,000 | Val A, 2,000 | Val B, 2,000 | Target |
| --- | ---: | ---: | ---: | --- |
| Poor / injury-hit | 66 | 66 | 66 | below 72 |
| Ordinary successful | 77 | 77 | 77 | 74–79 |
| Strong, well managed | 82 | 82 | 82 | 80–85 |
| Exceptional | 87 | 87 | 87 | 86–91 |
| **Rare generational** | **93** ±0.86 | **93** ±0.74 | **93** ±0.71 | **92–95** |
| Share above 95 | 0.0000 | 0.0000 | 0.0000 | ≤ 0.0001 |
| Transition-gap share | 0.0170 | 0.0155 | 0.0140 | 0.01–0.20 |
| Projected-peak coverage | 0.7430 | 0.7380 | 0.7320 | 0.70–0.85 |
| Projected-peak median width | 11.0 | 11.0 | 11.0 | 6–12 |
| Projected-peak signed error | −1.0 | 0.0 | −1.0 | ±2 |
| Parity, manual vs full detail | 0.0000 | 0.0000 | 0.0000 | ±2% |
| Parity, manual vs aggregate | 0.0000 | 0.0000 | 0.0000 | ±2% |
| **AP reconciliation failures** | **0.0000** | **0.0000** | **0.0000** | **exactly 0** |
| **§9.5 ruling violations** | **0.0000** | **0.0000** | **0.0000** | **exactly 0** |
| Guardrail warnings explained | 1.0000 | 1.0000 | 1.0000 | exactly 1.0 |
| Mean lifetime AP granted | 1,204.9 | 1,203.6 | 1,198.1 | informational |
| Mean lifetime AP spent | 1,144.0 | 1,137.9 | 1,138.6 | informational |
| Mean lifetime AP unspent | 58.0 | 62.7 | 56.6 | informational |
| Mean rating points gained | 607.7 | 604.4 | 604.8 | informational |
| Mean guardrail overage share | −0.4646 | −0.4655 | −0.4671 | informational |

The population-level overage share is negative because most careers never approach their guardrails; the ruling's bound applies to the rare-generational cohort, measured separately below.

The rare-generational cohort itself, 400 forced-path careers per range:

| Range | p10 | p50 | p90 | Max | Above 95 | AP granted | Mean overage | Max overage |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Development 1–400 | 88 | **93** | 93 | 93 | 0 | 3,044 | 13.0% | 18.1% |
| Validation A 700001–700400 | 89 | **93** | 93 | 94 | 0 | 3,045 | 13.0% | 18.1% |
| Validation B 900001–900400 | 89 | **93** | 93 | 94 | 0 | 3,043 | 12.9% | 17.8% |

Both validation ranges reproduce the development range exactly on the median, and every career on all three is inside the ruling with margin.

**Reconciled AP.** `granted (by ledger) − attribute spend − non-purchase debits = unspent` closes to zero on every career of every outcome path, on all three ranges and through three-shard aggregation. On the rare-generational cohort the components are: 3,044 granted, 2,868 spent buying 972 rating points, 17 removed by decline, and 159 left unspent — the last concentrated in the ceiling-bound top decile, whose median career leaves 0.6.

#### Regression and mutation evidence

Full battery at `2ece230`: parse gate 196 scripts / 0 failures / exit 0; GdUnit4 292 cases, 0 failures across 31 suites; `tests/run_all.gd` PASS; simulation invariants PASS; Builder calibration PASS; attribute sensitivity 80/80 judged at 100,000 resolutions per point; calibration smoke 15/15; career progression on three ranges; Projected Peak diagnostics on both untouched ranges, 0 pathological subgroups; three-shard aggregation pooling the new metrics and correctly refusing to certify at 1,200 careers; golden match ledgers regenerated byte-identical.

Seven mutations, each applied to the committed implementation, run against the suites, and restored — `git status` clean and `HEAD` unchanged after every one.

| Mutation | Detected by |
| --- | --- |
| The 20% ceiling stops being enforced as the grant is made | 3 cases, including the end-to-end no-career-violates check |
| The 20% ceiling stops being detected after the fact | the beyond-the-permitted-share case |
| The exception is handed to a second path | the only-the-generational-path case |
| The ledger explanation for an exceptional season disappears | 4 cases across provenance, explanation, and the ruling |
| §9.6 game-development caps are bypassed | 6 cases, including the exception-does-not-lift-the-cap case |
| Rating points are reported as AP spent | the two-quantities case and the every-path reconciliation case |
| The parse gate returns to the predicate that could never fire | the malformed-fixture case and the count-agrees-with-exit case |

The malformed-fixture case runs the committed gate in its own Godot process against a deliberately broken script written into `res://calibration`, asserts exit status 1 and the file named in the output, removes the fixture, and runs the gate again to require a pass. No invalid `.gd` file is committed, and the working tree was verified clean after every run.

#### Status of this milestone

**Structurally closed and measured; not certified.** The model is complete, the ruling is enforced by construction rather than by tuning, the accounting reconciles, and the gate that guards all of it can fail. What remains is sample size: §27.1 requires 1,000,000 careers and §6.4 gives the arithmetic for why no developer machine produces that. Nothing here may be described as certified.


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
4. ~~Rebuild the projected-peak interval so its width is conditioned on the individual career rather than scaled globally.~~ **Done** (§5.7). The interval is now conditioned on the prospect profile, with the player's own caps supplying a second axis through conversion saturation. All three §6.3 measures pass with interior margin on two untouched validation ranges and on the production judged path. Remaining dependency: the deep-verification workflow must run the sharded million-career report before any of it can be called certified.
5. ~~Resolve the rare-generational 92–95 peak miss.~~ **Done** (§5.8), and **closed** (§5.9). The band reads 93 on the development range and on two untouched validation ranges. The §9.5 tension §5.8 left open is settled by the owner ruling of 2026-08, which permits a bounded 20% exception for the rare-generational path only; enforcing it as a per-season bound made compliance structural and moved the opportunity multiplier from 1.70 to 1.85. Remaining dependency: the deep-verification workflow must run the sharded million-career report before any of it is certified.
6. **Diagnose the over-dispersed score margin before touching assist percentage or points per possession.** The top-domestic re-measurement (§5.5) shows 34.5% of games ending as blowouts against a target of 8–18%, only 19.3% close against 22–34%, and 1.8% reaching overtime against 4–8%. Those three are one defect, not three, and points per possession sitting at 1.2084 above its 1.08–1.18 band is very likely the same defect seen from another angle. Fixing the margin distribution first may move the points-per-possession miss on its own; tuning points per possession first would mask it. Assist percentage at 0.4815 is confirmed independent of the free-throw correction and needs its own creation-versus-attribution diagnosis. **The other four competitions must be re-measured before any of their recorded figures is used** — they all predate `00567d4`.
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
