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

**Stage 4 is not complete.** All five §8.4 career-peak bands now measure inside their locked targets, and two mandatory reports remain unimplemented. The two projected-peak failures are corrected and pass with interior margin on independent validation ranges (§5.7); the §8.4 rare-generational band is corrected and passes on two further untouched ranges (§5.8); and §5.9 closes that milestone by recording the §9.5 owner ruling, enforcing its 20% bound structurally, repairing a parse gate that could not fail, and correcting an AP figure that counted rating points. §5.10 diagnoses the §14.2 score-margin failure to its mechanism, corrects two real defects — a calibration fixture that manufactured its own mismatches and a missing §18.2 rotation pressure — and moves points per possession inside its band. §5.11 then tests §5.10's own premise, which was that the two teams' scoring is uncorrelated, and finds it true of the engine and false of basketball: three mechanisms the specification already authorised — score-and-clock game management, end-of-regulation possession strategy, and coaching timeouts — were structurally absent, and implementing them moves the final margin's variance by a sixth through coaching alone, with no probability touched. **§14.2's close-game share now passes at all five competition levels and all three dispersion targets pass at high school**, against three of fifteen before. §5.12 then implements the asymmetric garbage-time rotation threshold the owner authorised on 2026-08-20 — a coach protecting a safe lead rests his starters before a coach facing the same deficit concedes — as a possession-based safety measure with a `GARBAGE_TIME` ledger event and no probability anywhere. **Blowout share falls at all five levels and now passes at three; high school passes every one of its fifteen judged metrics.** §14.1 is unmoved to the fourth decimal and no golden hash changed. §5.13 is the resulting owner-decision package: the remaining §14.2 incompatibility is classified per target, an amendment is proposed with competition-specific bands, and three costed options are set out. **No target was changed and no proposal is enacted.** No Stage 4 result is certified, and §6.4 explains why none can be produced without CI hardware. The full gate inventory is §5.6.

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
- The score-margin decomposition runner and its mirror fixture, the §18.2 settled-game rotation, mandatory-first substitution ordering, three possession-rate corrections, and the `simulation-v3-margin` ruleset the regenerated golden ledgers belong to (§5.10).
- The score-margin covariance runner, its permutation control and its two replay models, `GameManagement`'s score-and-clock coaching, the end-of-regulation possession strategy, §4/§5 coaching timeouts, and the `simulation-v4-management` ruleset the regenerated golden ledgers belong to (§5.11).
- `GarbageTimeRule`'s possession-based settled-rotation safety, its asymmetric leading and trailing thresholds under the owner ruling of 2026-08-20, the `GARBAGE_TIME` ledger event and `TeamMatchState.settled_mode`, and the `simulation-v5-garbage-time` ruleset (§5.12). The §14.2 amendment in §5.13 is a **proposal awaiting owner decision**, not accepted work.

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
| GdUnit4 suite | **Structural** | 366 cases, 37 suites, 0 failures |
| `tests/run_all.gd` acceptance | **Structural** | PASS |
| Parse check under warnings-as-errors | **Structural** | 208 scripts, 0 failures |
| Simulation smoke diagnostics | **Structural** | Invariants PASS under the `simulation-v5-garbage-time` ruleset |
| Golden ledgers and determinism | **Structural** | Six scenarios. **Unchanged by `simulation-v5-garbage-time` (§5.12):** no hash and no seed moved, because the six fixtures finish at four to thirteen points and the settled rotation needs eighteen before it can fire. Regenerated once under `simulation-v4-management` (§5.11), where the blast radius was proved by diffing every scenario's event stream |
| Event/stat reconciliation | **Structural** | In the acceptance suite |
| Play/Sim/Skip parity | **Structural** | Byte-identical ledgers. The §27.1 50,000-triplet distributional report is **not run** |
| Detail-promotion invariance | **Structural** | `PlayerDevelopmentState.invariant_signature` |
| Creation-budget exhaustion | **Structural** | Builder suite |
| Overall-exclusion dependency check | **Structural** | Dependency test |
| Shard aggregation and provenance validation | **Structural** | Ten synthetic cases plus mutation testing; verified on real body-maturation shards |
| Attribute sensitivity | **Measured at requirement** | 100,000 resolutions per test point; 80/80 pass, re-run under `simulation-v5-garbage-time`. Not aggregated into a certification report |
| Builder completed-build bands | **Measured below requirement** | 810 builds at fixed seeds |
| Body maturation (report 15) | **Measured below requirement** | 2,000 triples; all 13 invariants at 1.0000, timing separation 0.4797 |
| Career progression, all five §8.4 bands | **Measured below requirement** | 3,000 careers; poor 66, ordinary 77, strong 82, exceptional 87, rare generational 93 (§5.8) |
| Population share peaking above 95 OVR | **Measured below requirement** | 0.0000 at 3,000 careers |
| §8.4 continuity across the 72–74 gap | **Measured below requirement** | 0.017 share at 3,000 careers, against a 0.01–0.20 band |
| Executor parity (manual / full-detail / aggregate) | **Measured below requirement** | Relative peak difference 0.0000 at 3,000 careers |
| Performance profile | **Measured below requirement** | 1,157.7 ms/game debug against a same-machine before of 1,149.4, +0.7% (§5.12); no release-template measurement |
| Competition §14.1 bands, top domestic | **Measured below requirement** | Re-measured at 400 games on the untouched range 60,000-60,399 (§5.11). **Ten of eleven pass**, unchanged by the score-and-clock correction; assist percentage is the only §14.1 failure |
| Competition §14.1 bands, other four | **Measured below requirement** | Re-measured again at 400 games each on the same untouched range under `simulation-v4-management` (§5.11). High school 10/10, college 8/10, development 9/10, overseas 9/10 — identical to §5.10 |
| **§14.1 top-domestic assist percentage** | **Failed** | 0.4820 against 0.52-0.72 at 400 games on the untouched range 350,000-350,399, against 0.4817 for the same games before the settled rotation (§5.12). Measurement only; no assist parameter has ever been tuned. It also fails at development and overseas |
| §14.1 top-domestic points per possession | **Measured below requirement; on its ceiling** | 1.1691 on 60,000-60,399 (§5.11) and **1.1809 on 350,000-350,399** against a 1.18 ceiling — where the same games measure 1.1844 *before* the settled rotation, which moved it down (§5.12). The range-to-range spread straddles the ceiling and no aggregate tuning was done in either direction |
| **§14.2 blowout share** | **Failed at two of five levels** | **Improved again (§5.12).** High school 0.1300 ✓, college 0.1700 ✓ and overseas 0.1550 ✓ pass; development 0.2450 and top domestic 0.2725 do not. 0.2320 and 0.2120 on two untouched 500-game validation ranges, and 0.1883 pooled over 600 even-team games. §5.13 proposes competition-specific bands and does not enact them |
| **§14.2 close-game share** | **Passes at all five competition levels** | 0.2700 / 0.2700 / 0.2200 / 0.2700 / 0.2475 against 0.22-0.34 on the untouched range 350,000-350,399 (§5.12). The two 500-game population validation ranges sit at 0.2220 and 0.2060, so the pass is marginal and is reported as marginal |
| **§14.2 overtime rate** | **Failed at four of five levels** | High school 0.0425 ✓; college 0.0100, development 0.0225, overseas 0.0250, top domestic 0.0175. Unmoved by the settled rotation, as expected. **Unreachable by any dispersion mechanism under the current possession/scoring model (§5.11, §5.13):** the replay model's tie rate never reaches 0.04 even at a margin standard deviation of 9.9. §5.13 classifies this narrowly and proposes a band |
| **§14.2 home win rate** | **Failed at four of five levels** | 0.5450 / 0.5250 / 0.5200 / 0.5275 / 0.5325 against 0.53-0.56 at 400 games (§5.12), and inside the band on both 500-game population validation ranges. **Untouched by this work and explicitly out of its scope.** The cause §5.10 measured is unchanged: the home environment is worth about 0.3 points a game where the band needs about 2.1 |
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
| §14.2 starter and rotation minutes | **Measured below requirement** | 28.84 starter mean against 27-35 at 400 games, from 30.05 before the settled rotation (§5.12) |
| Score-margin decomposition identity and classification | **Structural** | The six-term identity reconstructs every game's margin to within a thousandth of a point on every range run; both §14.2 boundaries tested from both sides on synthetic rows |
| Home/away and team-A/team-B symmetry | **Structural** | Mean pregame strength difference 0.0000 on the mirror fixture; identical rosters reproduce byte-identical ledgers; no resolution path reads the score outside the documented late-game windows |
| No score clamp, no rubber band | **Structural** | In the body of a game, two possessions identical except for a thirty-point scoreboard swing resolve to identical events. Inside the §18.2 managed window, where the score is now read, they resolve from the identical *probabilities* and differ only in which action the coach selects (§5.11). Margins reach past 25 without piling on a bound |
| §18.2 settled-game rotation | **Structural** | **Rebuilt (§5.12).** A possession-based safety measure with asymmetric leading and trailing thresholds under the owner ruling of 2026-08-20. Cannot fire below eighteen points, cannot fire early, releases with hysteresis when the game becomes competitive again, scales across all five game lengths by a square-root law, and is explained in the ledger by a `GARBAGE_TIME` event per transition |
| Mandatory-first substitution ordering | **Structural** | §5.1 departures claim the bench before any coaching preference; a latent starvation bug is fixed (§5.10) |
| Possession, score and points-per-possession reconciliation | **Structural** | Possession records sum to the box score on every golden scenario |
| Over-dispersion ratio | **Measured below requirement** | 1.01-1.09 on the population ranges, 1.03 on the mirror fixture. The estimator is validated against synthetic independent and synthetic correlated data |
| Scoring covariance and the margin-variance identity | **Structural** | `Var(A − B) = Var(A) + Var(B) − 2·Cov(A, B)` closes to 0.0000 on every range run, and on synthetic rows whose answer is known (§5.11) |
| §10.2/§10.3/§18.2 score-and-clock management | **Structural** | Off through ordinary basketball; symmetric under reversal of the scoreboard across pace, action mix and the crash decision; blind to ratings, strength and any intended winner; grants no shot or free-throw probability; bounded by named tunables inside Gate B0's safe ranges |
| §4/§5 coaching timeouts | **Structural** | A phase-appropriate per-competition allowance, spent and never replenished, triggered only by an opponent's qualifying run, resting both teams equally |
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


### 5.10 Score-margin dispersion: diagnosed, corrected in part, and bounded

Status: **Two real defects corrected and validated on two untouched ranges. The remaining gap is proven unreachable at §14.1's rates and is recorded as an owner question rather than closed with a mechanism that would have to be hidden to survive review.**

§5.5 read the four §14.2 failures as one defect — "the game-to-game score margin is over-dispersed" — and guessed that points per possession shared its cause. The first half was right. The second was wrong, and testing it before acting on it was the point: the corrections that move points per possession do almost nothing to the margin, and the reason is arithmetic rather than tuning.

#### The instrument

`calibration/runners/run_margin_diagnostics.gd` publishes three things the competition report cannot.

**An exact six-term identity.** Every game's signed margin is rewritten as `2·mean(FGA)·Δ eFG% + 2·mean(eFG%)·(Δ possessions + Δ offensive rebounds − Δ turnovers + Δ volume residual) + Δ free throws made`. Because `points from field = 2 · eFG · FGA` is an algebraic identity rather than an approximation, the six terms reconstruct the margin exactly — `decomposition.identity_closes` passed on every range run, worst reconstruction error below a thousandth of a point — so `Var(M) = Σ Cov(cᵢ, M)` holds and the six covariance shares are a real partition summing to one. The sixth term is *defined* as the residual of the identity and is reported as such rather than absorbed.

**A pregame strength index.** `TeamStrengthIndex` is the planned-minute-weighted mean of the §5.2 capability values, offence and defence, for a roster. Overall never appears: §6.2 forbids it as a simulation input, and a diagnostic built on it would be explaining the margin with a number the engine never reads. Every term is immutable match input, so the index cannot absorb any of the variance it is used to explain.

**Two fixtures.** The population fixture is the one the competition report measures. The mirror fixture (`CompetitionCatalog.mirrored_match_for`) plays both sides from the same roster, so the pregame gap is exactly zero and any margin it produces was invented during the game. Mirror results are never judged against §14.2 — a league of identical teams is not the league §14.2 describes — and the report labels them without a verdict.

#### The baseline

1,000 complete top-domestic games on a new development range, variations 20,000–20,999 (RNG seeds 20,001–21,000), at `62cfd61`. Every definition was checked before anything was diagnosed: absolute score difference, `games` as the denominator for all three §14.2 shares, decided games as the denominator for home win rate, and regulation ties classified from period scores rather than inferred.

| Metric | Measured | Target | Verdict |
| --- | ---: | ---: | --- |
| Blowout share | 0.3640 ±0.0298 | 0.08–0.18 | **FAIL** |
| Close-game share | 0.1730 ±0.0234 | 0.22–0.34 | **FAIL** |
| Overtime rate | 0.0190 ±0.0086 | 0.04–0.08 | **FAIL** |
| Margin standard deviation | 20.672 | — | — |
| Mean / median absolute margin | 16.98 ±0.75 / 14.0 | — | — |
| Absolute margin p75 / p90 / p95 / p99 | 25 / 34 / 40 / 50 | — | — |
| One-possession (≤3) / two-possession (≤6) | 0.0920 / 0.2150 | — | — |
| Regulation ties, all of which entered overtime | 0.0190, 1.0000 | 1.0000 | PASS |
| Points per possession | 1.2091 | 1.08–1.18 | **FAIL** |
| Possessions per team-game | 99.70 | 96–103 | PASS |

Those reproduce the §5.5 400-game figures (0.3450 / 0.1925 / 0.0175 / 1.2084), so they are a property of the engine rather than of one sample.

#### What the margin was made of

| Component | Standard deviation, points | Share of margin variance |
| --- | ---: | ---: |
| Shooting efficiency | 17.58 | 0.6944 |
| Free throws | 8.59 | 0.1985 |
| Turnovers | 5.50 | 0.1176 |
| Offensive rebounds | 6.01 | 0.0240 |
| Shot-volume residual | 3.05 | −0.0317 |
| Possessions | 1.96 | −0.0028 |

Pregame strength explained **0.2877** of the margin variance at 1.3168 points per centi-capability point of gap, leaving a residual standard deviation of **17.45**. A 150-game mirror run agreed: with the gap held at exactly zero the margin standard deviation was **17.60** and the blowout share **0.2733**.

Conditioned on matchup strength, same 1,000 games:

| Band (absolute pregame gap) | Games | Blowout | Close | Overtime | Mean abs. margin | Margin SD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Near-even, < 1.5 | 109 | 0.2844 | 0.1927 | 0.0183 | 14.73 | 17.99 |
| Modest, 1.5–4.0 | 229 | 0.2838 | 0.2009 | 0.0393 | 14.36 | 17.51 |
| Large, ≥ 4.0 | 662 | 0.4048 | 0.1601 | 0.0121 | 18.26 | 22.07 |

Two facts fall out of that table and they need different answers. **Sixty-six per cent of the calibration population was a large mismatch and eleven per cent was near-even**, which is a fixture fact, not a basketball one. And **nominally even games still produced 28.4% blowouts**, which is not.

#### Root cause

**One — the calibration fixture manufactured its own mismatches, asymmetrically.** `CompetitionCatalog.team_for` already applied a deterministic ±3.0 rating-point team tilt. On top of it, `run_competition_calibration.gd` added a second offset on a five-game cycle and applied it to the **away** roster only. The two spreads stacked to a between-team difference of 3.39 rating points of standard deviation, put the pregame gap at 8.42, and gave the strength term 28.8% of the margin variance. Nothing in §14 asks for that population. The away-only application averaged to zero over the cycle, so it never showed up as bias and never would have.

**Two — the margin is an almost exactly independent accumulation of possessions.** The pooled within-team-game variance of one possession's points is **1.59**. A random walk of ~100 such possessions per side has a margin standard deviation of `√(2 · 100 · 1.59) = 17.9`. Measured mirror figure: 17.60 before, 18.42 after, with a directly reported over-dispersion ratio of **1.03**. There is no runaway correlation to remove, no persistent hot-team state, no snowball, and no leakage: the engine does exactly what independent possessions do, and that is the whole of its dispersion.

**Three — the per-possession scoring quantum sets that dispersion, and §14.1 pins the quantum.** The possession-outcome distribution measured before the correction is 0 points 49.5%, 1 point 1.6%, 2 points 29.0%, 3 points 19.1%, 4 or more 0.8%, and after it 50.5% / 1.6% / 28.1% / 18.6% / 0.9%. Nineteen per cent of possessions arriving in three-point units is what makes `E[X²]` large, and it follows directly from §14.1's three-point attempt rate and percentage at the engine's shot volume. A three-point possession costs three units of mean and nine of `E[X²]`; a two costs two and four. That ratio is the whole mechanism.

#### The arithmetic that bounds the result

`Var(margin) = 2 · n · σ²`, where `n` is possessions per team and `σ²` the per-possession points variance. §14.1 fixes both. Building the possession-outcome distribution implied by each corner of every §14.1 top-domestic band — possessions 96–103, points per possession 1.08–1.18, three-point attempt rate 36–49%, three-point percentage 34–40%, field-goal percentage 45–51%, free-throw rate 18–34%, free-throw percentage 73–83% — gives `σ²` between **1.38 and 1.60** and therefore a margin standard deviation between **16.3 and 17.9** with the pregame gap at exactly zero. A near-normal margin at 16.3 produces a **21.9%** blowout share. §14.2's ceiling is 18%.

The measurement agrees with the arithmetic where it can be checked. After the fixture correction, the near-even band measures 0.2232 / 0.2523 / 0.2920 blowouts across three ranges at margin standard deviations of 16.1 / 16.1 / 19.4 — the floor the arithmetic predicts, reached from a population that no longer manufactures mismatches.

Nothing inside §14.1 moves it materially. Free throws are the variance-cheapest points available — one point at a time costs 1 of `E[X²]` per unit of mean, against 2 for a two-pointer and 3 for a three — and lifting the free-throw rate from 0.2155 to 0.30 at a fixed points per possession lowers `σ²` from 1.60 to 1.50, about one percentage point of blowout share. Dropping the three-point attempt rate to its §14.1 floor of 0.36 is worth about the same. Correcting points per possession is worth almost nothing: scaling every scoring outcome down by 8% lowers `σ²` from 1.576 to 1.561, because `E[X²]` and `μ²` fall together.

**So §14.1 and §14.2 are not jointly satisfiable under an independent-possession model, and the engine's possessions are independent.** Closing the remainder needs a mechanism that makes a team's later possessions worse *because* it is ahead. §14.2's own "team totals must emerge from possessions", §20.3's no-comeback-script rule, and this task's prohibition on rubber-banding all forbid exactly that. It is recorded below as an owner question.

#### Hypotheses ruled out, with the evidence

| Candidate | Ruled out by |
| --- | --- |
| Accidental persistent team-level scoring multiplier | Over-dispersion ratio 1.03 on the mirror fixture, 1.01–1.09 on the population ranges. `TestMarginDecomposition` confirms the estimator reports 1.15 and above when a persistent multiplier is present |
| Game-level hot/cold state persisting too strongly | Same measurement |
| Possession outcomes too independent, or too correlated | Same measurement, from both sides |
| Team quality applied more than once | Slope 1.12–1.49 points per centi-capability point across four ranges; a duplicated influence roughly doubles it, and `test_capability_edge_moves_the_margin_monotonically_and_boundedly` now bounds it |
| Asymmetric quality, minutes, substitutions, or home-court treatment | Mean home-minus-away pregame strength 0.0042 / −0.0125 / 0.0002 / 0.0105; starter-minute difference within 0.6 minutes; possession difference 0.39–0.67, which is the one extra possession home gets by inbounding first |
| One team receiving systematically better rotation participation | Mirror fixture, 250 games: pregame strength difference exactly 0.0000, starter-minute difference −0.20 |
| Excessive transition snowballing after turnovers or misses | Possessions component carries −0.3% of margin variance; largest unanswered run averages 12.0 points; four-or-more-point possessions run at 1.6–1.8 a game |
| Offensive rebounds compounding into runaway second chances | Offensive-rebound component carries 2.4% of margin variance |
| Foul or bonus feedback producing runaway scoring | Free-throw component is 20–21% of margin variance at a standard deviation of 8.6 points. That is the size of a free-throw differential, not a feedback loop |
| Intentional fouling starting too early or creating too much late margin | 0.41–0.56 intentional fouls a game, score-and-clock gated, now with a direct test at every boundary |
| Overtime logic suppressing regulation ties | Every regulation tie entered overtime and every overtime game was level at the end of regulation, on every range run |
| Integer rounding or threshold effects near tied scores | Classification tested at both sides of both §14.2 boundaries on synthetic rows |
| Pace variance amplifying strength differences | Possession-differential component standard deviation 1.9 points; possessions per team-game 99.7–101.1 against a 96–103 band |
| Home-court advantage too large or duplicated | Home shot bonus 0.006 at an environment of 0.5; measured home win rate 0.52 |
| Shared RNG streams coupling independent events, or separate streams destroying legitimate correlation | The over-dispersion ratio is the direct test of both, and it measures what independence predicts |
| Asymmetric state leakage between consecutive games | A game's ledger hash is unchanged by simulating other games between two runs of it |
| Points per possession sharing the margin's cause | Measured: correcting it moves `σ²` by about 1% |

#### The corrections

**1. The fixture stopped manufacturing mismatches.** The runners no longer add a level offset of their own. `CompetitionCatalog` owns the entire between-team spread through one named constant, `TEAM_LEVEL_TILT`, and applies it to both rosters. It moved to **2.1 rating points** of half-width. The pregame gap's standard deviation fell from 8.42 to 4.37–4.42, and the population moved from 11% near-even / 66% large mismatch to **22% / 62% / 15%**.

This is a fixture change and it is reported as one. The near-even band and the mirror fixture are published beside every population figure precisely so that narrowing the population cannot be mistaken for fixing the engine — and the numbers show it did not: the near-even band is still at 22–29% blowouts.

**2. §18.2's score-and-time rotation exists now.** `SIMULATION_SPEC.md` §18.2 has always required rotations to adjust for score and time; the engine did not. `RotationResolver.game_is_decided` gates a `decided_game` substitution reason on the **absolute** margin inside a share of the final regulation period, so the two benches empty on identical terms; the incoming player is chosen by smallest planned share, so the bench empties from the bottom and the rule converges. It moves who is on the floor — the whole of a rotation role's §10.6.1 privilege — and no probability. It fires in **37–38%** of games at **5.4–5.6** check-ins a game.

Two defects surfaced while building it, and both are fixed rather than worked around. It first tested a fixed planned-minute threshold, which re-ordered the same substitution on every possession once the lineup could go no deeper — fourteen settled-game check-ins a game. And it exposed a latent ordering bug in `RotationResolver.plan`: substitutions were planned in lineup order, so a discretionary substitution could take the last eligible bench player and leave a fouled-out player with no legal replacement. Mandatory departures now claim the bench first. That bug predates this work; it was unreachable only because every discretionary reason previously required a completed stint.

**3. Points per possession, corrected at its measured source.** The overshoot decomposes to field-goal attempts per possession — 0.967 measured against roughly 0.90 for a league at the band's midpoint — and two processes set that number. `offensive_rebound_base` moved 0.28 → **0.25**, and `steal_opportunity_on_ball` / `steal_opportunity_pass` moved 0.175 / 0.14 → **0.200 / 0.160**.

`turnover_base` was tried first and **reverted**. It feeds only the unforced mistake, which is about half a turnover per hundred possessions, so moving it from 0.050 to 0.058 changed the measured rate by 0.03 per hundred. Recording the failed attempt matters more than quietly keeping it: a tunable moved for a reason the measurement does not support is how a profile fills with constants nobody can justify.

#### Changed parameters

| Parameter | Was | Now | Unit | Safe range | Provenance |
| --- | ---: | ---: | --- | --- | --- |
| `CompetitionCatalog.TEAM_LEVEL_TILT` | 3.0, plus a second runner offset | 2.1 | rating points, half-width | 0.0–4.0 | Pregame gap explained 28.8% of margin variance; 66% of the population was a large mismatch |
| `SimulationBalanceProfile.decided_game_margin` | — | 20 | points | 10–40 | New. §18.2 score and time |
| `SimulationBalanceProfile.decided_game_clock_share` | — | 0.42 | share of the final period | 0.0–0.75 | New. The last five minutes of a twelve-minute period, expressed as a share so the school and college profiles get a sensible window |
| `SimulationBalanceProfile.offensive_rebound_base` | 0.28 | 0.25 | probability | 0.12–0.48 | 15.6 second chances per 100 possessions; §14.1 top-domestic band 0.20–0.31 and 0.28 sat in its upper half |
| `SimulationBalanceProfile.steal_opportunity_on_ball` | 0.175 | 0.200 | probability | 0.05–0.40 | Field-goal attempts per possession 0.967 against a band-consistent 0.90 |
| `SimulationBalanceProfile.steal_opportunity_pass` | 0.14 | 0.160 | probability | 0.05–0.40 | Same |
| `SimulationBalanceProfile.turnover_base` | 0.050 | 0.050 (unchanged) | probability | 0.01–0.35 | Tried at 0.058; measured effect 0.03 turnovers per 100 possessions; reverted |

No §14.1 band, §14.2 target, §13.1 baseline, or §13.2 floor or ceiling was touched.

#### Seed-range separation

No range serves two purposes.

| Purpose | Variations | RNG seeds | Games |
| --- | --- | --- | ---: |
| Diagnosis, population, before | 20,000–20,999 | 20,001–21,000 | 1,000 |
| Diagnosis, population, after | 20,000–20,499 | 20,001–20,500 | 500 |
| Diagnosis, mirror, before | 10,500–10,649 | 10,501–10,650 | 150 |
| Diagnosis, mirror, after | 70,000–70,249 | 70,001–70,250 | 250 |
| Tuning probes | ≥ 1,000,000 | ≥ 1,000,001 | 20–250 |
| **Validation A**, untouched | 40,000–40,499 | 40,001–40,500 | 500 |
| **Validation B**, untouched | 50,000–50,499 | 50,001–50,500 | 500 |
| Competition re-measurement, all five levels | 60,000–60,399 | 60,001–60,400 | 400 |

Validation A and Validation B were run once, after the correction was frozen, and no value was chosen from them.

#### Before and after

| Metric | Before (dev, 1,000) | After (dev, 500) | **Validation A** (500) | **Validation B** (500) | Target |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blowout share | 0.3640 ±0.0298 | 0.2760 ±0.0391 | **0.2880 ±0.0396** | **0.3100 ±0.0404** | 0.08–0.18 |
| Close-game share | 0.1730 ±0.0234 | 0.2100 ±0.0356 | **0.2100 ±0.0356** | **0.2060 ±0.0354** | 0.22–0.34 |
| Overtime rate | 0.0190 ±0.0086 | 0.0120 ±0.0102 | **0.0220 ±0.0133** | **0.0260 ±0.0144** | 0.04–0.08 |
| Margin standard deviation | 20.672 | 18.141 | 18.888 | 19.468 | — |
| Mean absolute margin | 16.98 ±0.75 | 14.72 ±0.93 | 15.17 ±0.99 | 15.67 ±1.01 | — |
| Median absolute margin | 14.0 | 12.5 | 13.0 | 13.0 | — |
| Absolute margin p90 / p95 / p99 | 34 / 40 / 50 | 31 / 35 / 47 | 32 / 38 / 48 | 32 / 37 / 50 | — |
| One-possession (≤3) | 0.0920 | 0.0960 | 0.0940 | 0.1100 | — |
| Two-possession (≤6) | 0.2150 | 0.2600 | 0.2540 | 0.2480 | — |
| Regulation tie rate | 0.0190 | 0.0120 | 0.0220 | 0.0260 | — |
| Every regulation tie entered overtime | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| Points per possession | 1.2091 | 1.1800 | 1.1829 | 1.1758 | 1.08–1.18 |
| Possessions per team-game | 99.70 | 101.08 | 100.91 | 100.97 | 96–103 |
| Pregame-gap standard deviation | 8.420 | 4.372 | 4.417 | 4.394 | — |
| Strength-explained variance share | 0.2877 | 0.0735 | 0.1183 | 0.1125 | — |
| Residual (engine) standard deviation | 17.447 | 17.462 | 17.736 | 18.341 | — |
| Per-possession points variance | 1.595 | 1.583 | 1.593 | 1.582 | — |
| Over-dispersion ratio | 0.99 (mirror) | 1.014 | 1.054 | 1.089 | — |

Engine-conditioned, with the pregame gap held at exactly zero:

| Metric | Mirror before (150) | Mirror after (250) |
| --- | ---: | ---: |
| Blowout share | 0.2733 ±0.0707 | 0.2920 ±0.0560 |
| Close-game share | 0.1933 ±0.0629 | 0.2040 ±0.0498 |
| Overtime rate | 0.0133 ±0.0218 | 0.0280 ±0.0215 |
| Margin standard deviation | 17.602 | 18.423 |
| Points per possession | 1.1939 | 1.1724 |
| Pregame strength difference | 0.0000 | 0.0000 |

**The corrections did what they were supposed to do and nothing more.** Close-game share improved from 0.173 to 0.206–0.210 and margin standard deviation from 20.7 to 18.1–19.5, entirely through the fixture; the engine's own dispersion is unchanged at 17.4–18.3, which is the number the arithmetic says cannot move. Close-game share is now 0.01 short of its band rather than 0.05 short. Blowout share improved by about eight percentage points and remains far outside. Overtime did not move.

#### Matchup-conditioned margins after the correction

| Range | Band | Games | Blowout | Close | Overtime | Mean abs. margin | Margin SD |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Validation A | Near-even | 111 | 0.2523 | 0.2342 | 0.0000 | 13.33 | 16.13 |
| Validation A | Modest | 311 | 0.2669 | 0.2219 | 0.0322 | 14.74 | 17.93 |
| Validation A | Large | 78 | 0.4231 | 0.1282 | 0.0128 | 19.50 | 19.36 |
| Validation B | Near-even | 113 | 0.2920 | 0.2124 | 0.0265 | 15.42 | 19.40 |
| Validation B | Modest | 310 | 0.2806 | 0.2161 | 0.0258 | 14.68 | 17.54 |
| Validation B | Large | 77 | 0.4545 | 0.1558 | 0.0260 | 20.00 | 20.07 |
| Dev after | Near-even | 112 | 0.2232 | 0.2232 | 0.0089 | 13.29 | 16.07 |
| Dev after | Modest | 312 | 0.2885 | 0.2115 | 0.0128 | 14.84 | 17.92 |
| Dev after | Large | 76 | 0.3026 | 0.1842 | 0.0132 | 16.36 | 17.54 |

Large mismatches still produce 30–45% blowouts, which is basketball and is not a defect. Near-even games produce 22–29%, which is the arithmetic floor and is the whole of the remaining failure.

#### Home and away are symmetric

The population fixture draws both benches from the same distribution and gives them the same tactics, so any systematic edge is a defect. Measured on the mirror fixture with the §19.4 home environment switched off, where the only remaining asymmetry is that home inbounds first:

| Range | Games | Mean home-minus-away margin | Mean possession difference |
| --- | ---: | ---: | ---: |
| 88,000–88,199 | 200 | +4.575 ±2.306 | +0.275 |
| 100,000–100,249 | 250 | +0.324 ±2.297 | +0.508 |
| 120,000–120,249 | 250 | +0.944 ±2.414 | +0.348 |
| **Pooled** | **700** | **+1.76 ±1.36** | +0.38 |

The first range on its own reads as a four-and-a-half-point home advantage at nearly four standard errors, and it is worth saying plainly that it is not one: pooled over 700 games the edge is 1.76 points, and inbounding first is worth about 0.4 of that at 1.17 points a possession. On the population fixture the mean signed margin measures −0.84 ±2.45, and the five competition home win rates average 0.516. A single 200-game range is not enough to answer this question, and the in-suite test now says so rather than pretending otherwise.

Mean pregame strength difference is 0.0000 on the mirror fixture and within 0.013 capability points on every population range; starter minutes differ by under one minute and substitutions by under one per game, both fluctuating in sign.

#### The five competition levels, re-measured

400 games each on the untouched range 60,000–60,399. Every figure predating `00567d4` is superseded, and the four non-top-domestic profiles had never been measured against the current engine at all.

| Metric | High school | College | Development | Overseas | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Possessions per team-game | 68.68 ✓ | 70.88 ✓ | 95.02 ✓ | 74.42 ✓ | 100.77 ✓ |
| Points per possession | 0.9559 ✓ | 1.0490 ✓ | 1.1049 ✓ | 1.1187 ✓ | **1.1680 ✓** |
| Field-goal % | 0.3932 ✓ | **0.4151 ✗** | 0.4326 ✓ | 0.4388 ✓ | 0.4548 ✓ |
| Three-point % | 0.3056 ✓ | 0.3282 ✓ | 0.3417 ✓ | 0.3489 ✓ | 0.3682 ✓ |
| Three-point attempt rate | 0.3384 ✓ | 0.3747 ✓ | 0.3945 ✓ | 0.3954 ✓ | 0.4088 ✓ |
| Free-throw % | 0.6723 ✓ | 0.7132 ✓ | 0.7601 ✓ | 0.7690 ✓ | 0.8048 ✓ |
| Free-throw attempt rate | 0.1996 ✓ | 0.2518 ✓ | 0.2103 ✓ | 0.2203 ✓ | 0.2132 ✓ |
| Turnovers per 100 | 17.79 ✓ | 16.25 ✓ | 14.58 ✓ | 14.22 ✓ | 14.11 ✓ |
| Offensive rebound % | 0.2597 ✓ | 0.2516 ✓ | 0.2558 ✓ | 0.2554 ✓ | 0.2515 ✓ |
| **Assist %** | 0.4805 ✓ | **0.4783 ✗** | **0.4758 ✗** | **0.4782 ✗** | **0.4831 ✗** |
| Home win rate | **0.5175 ✗** | **0.4900 ✗** | 0.5500 ✓ | 0.5375 ✓ | **0.4850 ✗** |
| Overtime rate | **0.0325 ✗** | **0.0150 ✗** | **0.0200 ✗** | **0.0300 ✗** | **0.0200 ✗** |
| Close-game share | 0.2925 ✓ | 0.2200 ✓ | **0.2025 ✗** | 0.2725 ✓ | **0.2075 ✗** |
| Blowout share | **0.1850 ✗** | **0.2400 ✗** | **0.2750 ✗** | **0.2300 ✗** | **0.3025 ✗** |
| Starter mean minutes | 20.33 | 25.03 | 30.45 | 25.00 | 30.09 ✓ |

**Ten of eleven §14.1 metrics now pass at top domestic**, against nine before; points per possession moved inside and assist percentage is the only §14.1 failure left, which this task was told to measure and not tune.

**The blowout share across the five levels is the clearest evidence for the diagnosis in this document.** `σ_margin = √(2 · n · σ²)` predicts that blowouts scale with possessions and per-possession scoring, and the five levels order themselves exactly that way: high school at 68.7 possessions and 0.96 points per possession produces 18.5% blowouts, and top domestic at 100.8 and 1.17 produces 30.3%. High school — the *least* concentrated talent pool, where basketball intuition expects the most blowouts — comes closest to the band, because it plays the fewest and cheapest possessions. Reconstructing each level's possession-outcome distribution from its own measured rates, and adding the fixture's 6.5-point strength term, predicts these margin standard deviations against the ones the measured blowout shares imply:

| Level | Possessions | Per-possession variance | Predicted margin SD | Implied by measured blowout share |
| --- | ---: | ---: | ---: | ---: |
| High school | 68.68 | 1.39 | 15.1 | 15.1 |
| College | 70.88 | 1.42 | 15.6 | 17.0 |
| Overseas | 74.42 | 1.47 | 16.7 | 16.7 |
| Development | 95.02 | 1.52 | 18.2 | 18.3 |
| Top domestic | 100.77 | 1.59 | 19.1 | 19.4 |

Four of the five land within 0.3 points. College is 1.4 points under-predicted, which its own blowout interval of ±0.042 at 400 games spans. The model is not a story fitted to top domestic; it predicts four competitions it was not built on, and it predicts them from each level's own §14.1 rates.

Two failures surfaced that this task did not create and does not fix. **College field-goal percentage** is 0.4151 against a 0.42–0.49 floor. **Home win rate** fails at three of five levels, and its cause is legible: `home_environment_shot_bonus` is 0.006 and the environment is 0.5, so the home side gains about 0.3 points a game where §14.2's 53–56% band needs roughly 2.1 at a margin standard deviation near 19. Raising it is a one-line change inside the tunable's existing 0.0–0.03 range, and it is deliberately not made here — it would add points per possession, which is already at its ceiling, and it would invalidate validation ranges chosen and frozen before it.

#### Golden-ledger impact

Every committed ledger changed, and had to. The settled-game rotation moves players, the offensive-rebound rate changes how many second chances a possession gets, and the disruption opportunity changes how many possessions end in a steal — all three alter the event stream of every game. The simulation ruleset version moved from `simulation-v2-calibrated` to **`simulation-v3-margin`** to say so.

The blast radius was proved rather than assumed. The substitution-ordering fix was made *after* the first regeneration, and re-running the acceptance suite against the already-regenerated hashes changed exactly one scenario — `substitution_foul_out`, the only fixture that produces a foul-out. The overtime scenario stopped reaching overtime at its old seed and was re-derived with `find_scenario_seeds.gd` rather than left as a hash that passes while covering nothing; every scenario still satisfies the behaviour it is named for, checked by the harness on every regeneration.

#### Remaining failures, and the question they raise

**§14.2 blowout and overtime cannot be reached at §14.1's rates.** The blowout floor is about 22% against a ceiling of 18%; the overtime rate is bounded above by the density of a near-normal margin at zero, about 2.4% at a standard deviation of 16.3, against a 4–8% band. Both gaps have the same shape: §14.2 describes a league tighter than §14.1's possession economy can produce without a mechanism that reverts the margin toward zero.

**Points per possession is inside its band on the judged range and at the ceiling everywhere else.** It was 1.2091, decisively outside. It is now **1.1680** on the fresh 400-game competition range that §14.1 is judged on — a pass — and 1.1758 / 1.1800 / 1.1829 on the three 500-game diagnostic ranges. Pooled over all 2,100 population games it is **1.1771 ±0.0040**, inside 1.08–1.18 with the interval's upper edge touching the ceiling. That is a genuine improvement and a weak closure, and it is reported as both.

The two instruments that report it agree. `MatchMetricAccumulator` and `MarginDecomposition` both read `TeamStatLine.points` and `TeamStatLine.engine_possessions`, and `test_possessions_scores_and_points_per_possession_reconcile` proves per game that those agree with the possession records themselves. The spread across ranges above is sample variation, not two instruments disagreeing: a 200-game diagnostic run over the first half of the competition range reports 1.1787 against the competition report's 1.1680 over the full 400.

It is boxed in for the same structural reason the margin is. Every remaining §14.1-legal lever trades one band for another. Removing a shot from a possession also ends the possession sooner, so possessions per team-game rose from 99.7 to 100.8 and the points-per-possession gain came to about two thirds of the attempt reduction. Offensive rebounding cannot go lower globally: at a base of 0.25 the realized top-domestic rate is 0.2515 and the **high-school** floor is 0.25, so one more step down fails high school in order to pass top domestic. Turnovers cannot go much higher: the top-domestic ceiling is 16 per 100 possessions, the engine is at 14.1, and more turnovers push possessions toward the 103 ceiling. **The structural fix is to make the offensive-rebound rate competition-scoped** — §14.1 already bands it per competition, and one global constant cannot satisfy five different bands — but that is a shipping-model change and is deliberately not made here.

These are owner questions, not engineering ones, and they are not answered here. The candidate answers all sit outside this task's authority: move §14.2's game-shape bands, move §14.1's possession or three-point bands, scope the offensive-rebound rate per competition, or authorise a bounded margin-reversion mechanism under §20.3's momentum clause with the no-comeback-script tests it already requires. Nothing in §14 was rewritten to match the measurement.

#### Tests

`tests/simulation/test_score_margin.gd` — 17 cases against the running engine.

- Identical rosters produce no *large* one-sided edge, and both benches win games.
- Identical rosters receive the same rotation, measured as starter minutes.
- Swapping identical rosters reproduces a byte-identical ledger.
- A capability edge moves the expected margin monotonically and at a **bounded** slope. Both halves matter: without monotonicity the engine is not reading team strength, and without the bound a duplicated influence would pass a monotonicity check while doubling the slope.
- A capability edge does not decide every game, stated as an overlap between the margin distributions at zero edge and at five rating points, because an upset count at eight games is a coin flip at any honest slope.
- Even matchups keep a realistic spread — bounded below so the engine cannot collapse to a rating lookup, and above so a persistent game-level state cannot hide there.
- No clamp bounds the final margin, and margins do not pile against a bound.
- **Resolution ignores the score.** Two possessions identical in the random stream, the lineups, the clock and the possession identity, differing only by a thirty-point scoreboard swing, resolve to identical events. Run in the *final period*, outside both score-aware windows, because that is where a rubber band would be least conspicuous.
- The same from the other side: a team eighteen points ahead and a team eighteen points behind resolve identically.
- Intentional fouling activates only under valid conditions, checked at both sides of the margin bound, the clock bound, and the sign.
- The settled-game rotation is symmetric in the sign of the margin, never fires before the final period or in overtime, and converges after at most five substitutions a side.
- Regulation ties enter overtime and overtime games were tied in regulation, both directions.
- Overtime games reconcile into the same box score and period list.
- Possessions, points and points per possession reconcile with the ledger.
- Repeated games do not leak state.
- Play, Sim and Skip produce the same ledger and the same margin.

`tests/calibration/test_margin_decomposition.gd` — 8 cases on synthetic rows whose answers are known, because a simulated game has no known answer. The §14.2 boundaries from both sides, the identity's exact closure on unrelated box scores, the covariance shares summing to one, the over-dispersion ratio measuring 1.00 on genuinely independent possessions **and above 1.15 on deliberately correlated ones**, the strength regression recovering a known slope, and the three matchup bands partitioning the sample exactly once.

#### Mutation evidence

Each mutation was applied to a byte-exact backup, the detector run, and the file restored; `git status --porcelain` was compared before and after the battery.

| # | Mutation | Detector | What it reported |
| --- | --- | --- | --- |
| 1 | The team level offset applied twice in `CompetitionCatalog.team_for` — a team's quality reaching its roster through two code paths, which is the class of defect the fixture actually had | `test_capability_edge_moves_the_margin_monotonically_and_boundedly` | Slope 7.85 points of margin per rating point against a bound of 7.00 |
| 2 | The away side never substitutes | `test_identical_rosters_receive_the_same_rotation` | Starter-minute difference 90.93 against a bound of 3.39 |
| 3 | A persistent per-team, per-match shot-probability offset of ±0.15 | The margin report's `possession.overdispersion_ratio` | Margin standard deviation 26.07 against an independent-possession implication of 17.72 — a ratio of 1.47 against a measured baseline of 1.03 |
| 4 | `PeriodController.match_is_complete` returns true whatever the score | `test_regulation_ties_enter_overtime` | A game ended level in regulation without entering overtime |
| 5 | Intentional fouling widened to a ten-minute window and a thirty-point margin | `test_intentional_fouling_activates_only_under_valid_conditions`, and Gate B0's safe-range check in `tests/run_all.gd` | Both tunables outside their documented envelopes; three further behavioural tests in the margin suite failed as well |
| 6 | A blowout classified as `> 20` instead of `>= 20` | `test_margin_classification_uses_the_specified_boundaries` | Three blowouts counted as two |
| 7 | Free-throw points dropped from the possession record | `tests/run_all.gd` acceptance | Six failures: every golden ledger, plus reconciliation |
| 8 | `RotationResolver.game_is_decided` always returns false | `test_settled_game_rotation_is_symmetric_and_bounded` | The settled case reported not settled |

**Two mutations were run twice, and both first attempts were worth keeping in the record.**

The first mutation 1 added a second capability term inside shot resolution and was **not** detected. That is the right answer: it strengthens one channel of one term by about 20%, which is calibration drift, and the bound exists to catch a *duplicated influence* — roughly a doubling — not to freeze the slope. Restating the mutation as the real defect class, a level offset applied on two paths, produced 7.85 against the 7.00 bound.

The first mutation 5 was detected by three behavioural tests but not by the test named after it, and the reason was a defect in that test: it derived every boundary it checked from the profile it was checking, so widening the window widened the assertions with it. The test now pins the tunables against fixed, coaching-plausible values as well as checking the gate's shape against the profile. A test that reads its bounds from the thing being changed cannot notice the thing being changed.

#### Regression

Run under `simulation-v3-margin` with the correction frozen.

| Check | Result |
| --- | --- |
| Parse/compile gate under warnings-as-errors | 201 scripts, 0 failures; the detector self-test passes on every run |
| GdUnit4 full suite | 317 cases, 34 suites, 0 failures |
| `tests/run_all.gd` acceptance | PASS |
| Simulation smoke diagnostics | Invariants PASS |
| Golden ledgers | Regenerated deliberately under an explicit ruleset change; every scenario still covers its named behaviour |
| Builder calibration | PASS |
| Attribute sensitivity at 100,000 resolutions per point | 80 metrics, 80 judged, 0 failures |
| Calibration smoke | 15 metrics, 15 judged, 0 failures |
| Career progression, three shards of 1,000 careers | All five §8.4 bands pass (66 / 77 / 82 / 87 / 93); share above 95 OVR 0.0000; §8.4 transition-gap share 0.0160; AP reconciliation failures 0.0000; §9.5 guardrail warnings explained 1.0000; §9.5 opportunity-ruling violations 0.0000. The only failure on each shard is `sample.meets_certification_size`, which fails correctly at 1,000 careers against §27.1's 1,000,000 |
| Executor parity | Manual vs full-detail and manual vs aggregate relative peak difference both exactly 0.0000, Cohen's *d* 0.000 |
| Projected Peak, inside the career report | Coverage 0.7400 ±0.0271, median width 11.0, median signed error −1.0 — all inside their §6.3 bands |
| Projected Peak diagnostics, fresh 2,000-career range (seeds 400,001-402,000) | Coverage 0.7440 ±0.0191 against 0.70-0.85, median width 11.0 against 6-12, total signed error 0.0000 ±0.2845 against ±2, zero pathological subgroups across 15 judged creation-time groupings. 3 judged metrics, 0 failures |
| Real shard aggregation | Three seed-disjoint competition shards of 120 games each, written to `res://shards` and pooled end to end. All three accepted, provenance and seed-disjointness validated, raw terms pooled; the aggregate reports points per possession 1.1755 and possessions 100.99 ±0.25 over 360 games, and refuses to certify because `certification.sample_reached` is 0.0000 against §27.1. This run exists to exercise the aggregation path; its game-shape numbers are not cited as evidence anywhere |
| Top-domestic competition validation, two untouched ranges | The before/after table above |
| Five competition levels on a fresh range | The competition table above |

The progression results deserve one sentence of explanation rather than a shrug: **nothing in this correction touches the development domain.** `CareerSimulator`, `DevelopmentService`, and the projected-peak model reference neither `SimulationBalanceProfile`'s match tunables, nor `CompetitionCatalog`, nor `RotationResolver`, which is checkable by grep and was checked. The runs above are a regression check on that separation, not a re-derivation, and they confirm it: every §5.7, §5.8 and §5.9 figure reproduces.

#### Performance

| | Before (`62cfd61`) | After | Change |
| --- | ---: | ---: | ---: |
| Milliseconds per complete reference game | 1398.5 | 1448.4 | +3.6% |

Measured with the same runner at 20 games, on a quiet machine, in a worktree checked out at the before commit rather than by stashing. The cost is the settled-game rotation asking whether the game is decided once per on-court player per possession, plus the second substitution-planning pass. It does not change the §6.4 arithmetic: at roughly 1.45 seconds a game the §27.1 100,000-game certification is about 40 hours per competition on one process, and no GDExtension work was started because nothing in this correction required it.

#### Classification

- **Structural:** the margin decomposition identity, the classification boundaries, home/away symmetry, the absence of a score clamp or a trailing-team modifier, the intentional-foul gate, the settled-game rotation gate and its convergence, mandatory-first substitution ordering, regulation-tie-to-overtime agreement, ledger reconciliation of possessions, scores and points per possession, Play/Sim/Skip equality, and cross-game isolation. All proven by deterministic tests.
- **Measured below requirement:** every §14.2 and §14.1 figure above. 500 games per validation range against §27.1's 100,000 per competition.
- **Failed:** §14.2 blowout share, close-game share and overtime rate; §14.1 points per possession at two of three ranges.
- **Certified:** nothing.

### 5.11 The margin is not a random walk in basketball, and now it is not one here either

Status: **The zero-covariance assumption behind §5.10's conclusion is measured rather than assumed, and it was true — of the engine, not of basketball. Three structurally absent mechanisms the specification already authorised are implemented, and they move the margin's variance by 15-17% through legitimate coaching. §14.2's close-game share now passes at all five competition levels and the blowout and overtime rates pass at high school; the remaining gap is quantified, bounded, and put to the owner with three options rather than closed with a mechanism that would have to be hidden to survive review.**

§5.10 reconstructed the final-margin variance as `2·n·σ²` and concluded that §14.2 is unreachable at §14.1's rates. That reconstruction is exact only under `Cov(A, B) = 0`, and the covariance had never been measured. The owner declined the conclusion on exactly that ground. This section measures it.

#### The instruments

`ScoringCovariance` and `run_margin_covariance.gd` answer "is the covariance zero" three separate ways, because it is three separate questions.

1. **The identity, on the measured columns.** `Var(A − B) = Var(A) + Var(B) − 2·Cov(A, B)` is computed term by term and the two sides are published beside each other. The reconstruction error is reported rather than asserted, so a decomposition that stopped closing would be visible instead of confidently wrong.
2. **The margin as a path.** Every possession contributes a signed increment. The lag-k autocorrelation of those increments, and the variance ratio at seven horizons from one possession to eighty, say whether the path is a random walk at the horizons a coach actually acts on. Both are centred inside each team-game so between-game effects cannot appear as serial structure.
3. **Two replay models.** Each game is rebuilt from the pooled empirical distribution of possession outcomes, drawing its own regulation possession counts. The undamped model is the honest form of "independent random walk"; the damped model additionally costs the leading team a stated number of points per possession once the margin passes a threshold. The second is the feasibility frontier, and it is expressed in the only unit that lets a person judge it: **how much less effective a team protecting a lead has to become.**

Two instrument defects were found and fixed before any of this was read, and both would have produced confident nonsense.

- **The variance ratio is biased by its own centring.** Subtracting each team's in-game mean forces the whole sequence to sum to zero, so the ratio falls with the horizon even for a sequence with no structure at all — 0.62 at eighty possessions where the truth is one. The fix is a control: eight deterministic permutations of each game's own increments, which preserve the multiset exactly and destroy every serial and score-state structure. The real statistic divided by the control is bias-free, and a standalone simulation of independent possessions confirms the control reproduces the artefact to within 5%.
- **Resampling each game from its own outcomes double-counts the noise it is meant to isolate.** A game's realized efficiency *is* the sample mean of its possessions, so drawing from that distribution reproduces the realization and then adds the same sampling variance a second time. The first version of the model reported a null margin standard deviation of 25.2 against a measured 18.4 — the engine looked *less* dispersed than independence, which is the opposite of the truth. Pooling across the sample fixes it.

`ScoringCovariance`'s own arithmetic is tested against rows whose answers are known: the identity closing on unrelated box scores, a deliberately constructed covariance coming back out, residualization removing a shared linear predictor, the permutation control returning exactly one without serial structure, and the damped model reducing dispersion monotonically while keeping the margin on the integer lattice — which it must, because the overtime rate is read as the share of margins that are exactly zero.

#### Baseline: the covariance was zero, and nothing was removing it

Mirror fixture, 300 games on variations 210,000-210,299, where the pregame gap is exactly zero and only the engine's own dispersion remains.

| Term | Before |
| --- | ---: |
| `Var(home points)` | 159.97 |
| `Var(away points)` | 196.70 |
| `Cov(home, away)` | **+4.67** |
| `Corr(home, away)` | **+0.026** |
| `Var(margin)` measured | 347.32 |
| `Var(margin)` reconstructed from the three terms above | 347.32 |
| Reconstruction error | **0.0000** |
| Covariance a shared possession count alone implies | +15.54 |
| Residual covariance after pace and possessions are projected out | −10.65 |

**The identity closes exactly and the covariance is zero.** The population fixture agrees: −6.11 at a standard error near 8 over 500 games.

The path agrees too, and this is the stronger result. Corrected variance ratios on the mirror fixture:

| Horizon, team possessions | 1 | 2 | 5 | 10 | 20 | 40 | 80 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Variance ratio, corrected | 1.000 | 1.012 | 1.019 | 1.006 | 0.998 | 1.012 | 1.011 |

Flat at one from one possession to eighty. The margin was a random walk at *every* horizon, and the independence replay model closes the argument end to end: it produced a margin standard deviation of 18.26 against a measured regulation 18.62, blowouts of 28.7% against 34.0%, and ties of 2.28% against 3.33%.

So §5.10's premise was true. **What it did not establish is why**, and the answer is not a law of basketball. It is that no mechanism in the engine created any covariance at all.

#### The mechanisms, inspected

Every score state played identically. Measured on the mirror fixture before the correction:

| Absolute margin | Possessions | Points/possession | 3PA share | Seconds/possession | Leading s/poss | Trailing s/poss | Leading minus trailing points/possession |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ≤ 5 | 40.0% | 1.1975 | 0.4096 | 14.30 | 14.13 | 14.47 | −0.0014 |
| 6-14 | 36.0% | 1.1873 | 0.4163 | 14.28 | 14.10 | 14.44 | +0.0183 |
| ≥ 15 | 24.0% | 1.1525 | 0.4003 | 14.27 | 14.04 | 14.47 | **+0.0128** |

A team fifteen or more points ahead consumed *less* clock than the team chasing it, hunted almost exactly the same share of threes, and outscored it. That is not basketball, and it is the whole of the missing covariance.

| Mechanism | Specification | Before |
| --- | --- | --- |
| Shared pace environment | §4 `paceEnvironmentId` | Present, but constant per competition — no game-to-game shared term |
| Shared officiating environment | §4 `officiatingProfileId` | **Declared and never read.** Recorded as a finding; adding officiating variation would *raise* margin variance and is out of this task's scope |
| Venue environment | §19.4 | Present as `home_environment`, fixed at 0.5 by the calibration fixture, so zero variance |
| Common possession count | §9 | Present structurally — possessions alternate |
| Symmetric foul interpretation | §13.1 | Present, and symmetric |
| Shared late-game clock conditions | §13.1 | Present, inside the last forty seconds only |
| Timeouts after runs | §4 `timeoutRule`, §5 `TimeoutState` | **Structurally absent** |
| Lineup changes after runs | §18.2 | Absent beyond fatigue, foul trouble and the settled game |
| Protecting a lead by reducing pace | §10.2, §10.3, §18.2 | **Absent.** `ClockResolver` never read the score |
| Trailing team raising shot variance | §10.3, §20.2 | Incomplete — one ×1.25 constant inside the last forty seconds, applied at any deficit |
| Offensive-rebound crash by score and clock | §14.2 crash intent, §18.2 | **Absent.** `ReboundResolver.crashes` never read the score |
| Intentional fouling | §13.1 | Present and correctly gated |
| Garbage-time substitutions | §18.2 | Present since §5.10, symmetric in the absolute margin |
| End-of-period and end-of-game possession strategy | §10.2, §20.2 | **Absent.** No rule preferred the shot value that levels the game |

#### The correction: `simulation-v4-management`

One class, `GameManagement`, owns the score half of §10.3's `ScoreClockContext`. It computes one bounded number, identically for both teams:

```text
pressure = (possession_pairs_needed / possession_pairs_left − floor) / (1 − floor)
```

`possession_pairs_needed` is the margin over what a trailing team takes back in one pair of possessions it wins outright. `possession_pairs_left` is the remaining regulation time over the pace **this game has actually played at**, read from its own elapsed time and possession count — which is why one set of constants is correct for a thirty-two-minute school game and a forty-eight-minute professional one. Below the floor nothing happens at all, which is what leaves every §14.1 band measured on the basketball that certified it.

Three effects, each bounded by a named tunable and then again by the §12.2 guardrails the rest of the weight product already lives under:

1. **Clock.** The team ahead consumes more of it, the team behind less. The two gains are deliberately different sizes, because a possession has a physical floor: the chasing side can save far less than the protecting side can spend, and that asymmetry is the whole of the mechanism's effect on possession count.
2. **Action selection.** The team ahead prefers resets and refuses the widest-outcome shot; the team behind does the reverse. On the last possession of regulation a trailing team prefers the shot value that *levels* the game — a three down three, a two down two — rather than the highest value available, which is what the previous blanket three-point preference got wrong.
3. **The offensive glass.** The team ahead stops sending players to it and retreats; the team behind sends more. This moves where five players stand and changes no rebounding probability for anybody who does go.

Beside it, §4's timeout rule and §5's timeout state exist for the first time. Each competition grants a phase-appropriate allowance, a coach spends one to answer a run of eight or more unanswered points while enough regulation remains to want it, and the reducer spends the allowance and rests everybody on the floor on both sides. Overtime grants no more.

**Why this is not rubber-banding, stated as properties rather than as intent.** Both coaches compute the same `pressure` from the same public state; the sign of a team's own margin selects which half of the policy it applies, so swapping the two rosters swaps the two behaviours. The inputs are the score, the clock, the period, the rules and the realized pace — there is nothing in them that could carry a rating, a strength index, an intended winner or a target margin, and a test proves that replacing both rosters with much stronger ones leaves every factor identical. No probability moves: the same shot, from the same shooter, against the same defender, resolves to the identical make probability at +30, 0 and −30. What the score is allowed to change is which shot a coach chooses, which is exactly what §10.3 puts it in the weight product to do.

#### Changed parameters

Every one of them is new. No existing tunable was moved, and no §14.1 band, §14.2 target, §13.1 baseline or §13.2 bound was touched.

| Parameter | Value | Unit | Safe range | Provenance |
| --- | ---: | --- | --- | --- |
| `management_swing_points` | 2.4 | points per possession pair | 1.0-6.0 | A trailing team that wins a pair outright scores about 1.17 and denies about as much |
| `management_pressure_floor` | 0.20 | share of remaining pairs | 0.0-0.60 | Chosen so a ten-point margin with a half to play — about a tenth of the remaining pairs — changes nothing, which is what leaves §14.1 measured on the basketball that certified it |
| `protect_pace_gain` | 0.22 | share of the time draw | 0.0-0.40 | Coaching-plausible upper end of "run the clock"; measured effect is +0.6 seconds a possession in the decided state |
| `chase_pace_relief` | 0.12 | share of the time draw | 0.0-0.30 | Deliberately about half the protecting gain: a possession has a physical floor |
| `protect_reset_gain` | 0.35 | share of the §10.3 factor | 0.0-0.60 | Inside the §12.2 `score_clock_max` guardrail at full pressure |
| `protect_three_relief` | 0.25 | share of the §10.3 factor | 0.0-0.50 | Measured effect is a 0.397 → 0.374 three-point share for the leading team in the decided state |
| `chase_three_gain` | 0.30 | share of the §10.3 factor | 0.0-0.60 | Measured effect is 0.404 → 0.418 for the trailing team |
| `protect_crash_relief` | 0.45 | share of the crash rate | 0.0-0.60 | The largest single contributor to the measured drift; a team protecting a lead sends nobody to the offensive glass |
| `chase_crash_gain` | 0.25 | share of the crash rate | 0.0-0.60 | Smaller than the relief: there are only so many players to send |
| `endgame_possession_ms` | 32000 | ms of regulation left | 8000-60000 | About one possession plus the stop that would follow it |
| `endgame_tie_gain` | 0.40 | share of the §10.3 factor | 0.0-0.80 | New |
| `endgame_tie_relief` | 0.35 | share of the §10.3 factor | 0.0-0.70 | New |
| `timeout_run_points` | 8 | points | 4-15 | The smallest unanswered streak a coach is conventionally described as stopping |
| `timeout_recovery_points` | 6.0 | acute fatigue | 0-20 | A timeout is a rest and nothing else |
| `timeout_run_reserve_ms` | 90000 | ms of regulation left | 0-180000 | Below it a coach holds what he has for the endgame |
| `CompetitionRuleProfile.timeouts_per_team` | 5 / 4 / 7 / 5 / 7 | timeouts | 0-12 | Phase-appropriate, high school through top domestic |

**A maximal setting was tried on the tuning range and rejected.** Every gain was moved to the top of its declared safe range at once — pressure floor 0.10, protecting pace 0.30, crash relief 0.60, chasing three 0.45. It bought 0.4 points of margin standard deviation, did not improve the blowout share at all (0.26 against 0.24 at the shipped values, well inside a 300-game interval), and made the overtime rate *worse* by pushing trailing teams onto threes when a two would have levelled the game. Recording the rejected setting matters more than quietly keeping it: this is the shape of a mechanism tuned toward a target rather than toward basketball, and the measurement says it does not even reach the target.

#### Seed-range separation

No range serves two purposes. Every range below is new to this task except the competition re-measurement, which is deliberately the range §5.10 used so that the five levels compare before against after on identical fixtures.

| Purpose | Variations | RNG seeds | Games |
| --- | --- | --- | ---: |
| Diagnosis, population, before and after | 200,000-200,499 | 200,001-200,500 | 500 |
| Diagnosis, mirror, before and after | 210,000-210,299 | 210,001-210,300 | 300 |
| Development and tuning probes | ≥ 1,500,000 | ≥ 1,500,001 | 250-300 each |
| Symmetry, mirror with the home environment off | 270,000-270,299 | 270,001-270,300 | 300 |
| **Validation A — untouched** | 230,000-230,499 | 230,001-230,500 | 500 |
| **Validation B — untouched** | 240,000-240,499 | 240,001-240,500 | 500 |
| Competition re-measurement, all five levels | 60,000-60,399 | 60,001-60,400 | 400 each |

Validation A and Validation B were run once, after the tunables were frozen, and no value was chosen from them.

#### Before and after

Population fixture, 500 games, variations 200,000-200,499 — the same games before and after.

| Metric | Before | After | **Validation A** | **Validation B** | Target |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blowout share | 0.3300 ±0.0411 | **0.2600 ±0.0383** | 0.2660 ±0.0386 | 0.2840 ±0.0394 | 0.08-0.18 |
| Close-game share | 0.2040 ±0.0353 | 0.2000 ±0.0350 | 0.1880 ±0.0342 | 0.2040 ±0.0353 | 0.22-0.34 |
| Overtime rate | 0.0220 ±0.0133 | 0.0260 ±0.0144 | 0.0260 ±0.0144 | 0.0200 ±0.0128 | 0.04-0.08 |
| Home win rate | 0.5120 ±0.0436 | **0.5300 ±0.0436 ✓** | **0.5500 ±0.0434 ✓** | **0.5380 ±0.0435 ✓** | 0.53-0.56 |
| Margin standard deviation | 19.157 | **17.630** | 17.792 | 18.052 | — |
| Mean absolute margin | 15.75 | 14.37 | 14.65 | 14.67 | — |
| Median absolute margin | 14.0 | 12.0 | 12.0 | 12.0 | — |
| `Var(home points)` | 162.82 | 146.11 | 161.56 | 172.04 | — |
| `Var(away points)` | 191.94 | 175.13 | 155.32 | 164.55 | — |
| `Cov(home, away)` | −6.11 | +5.21 | +0.16 | +5.36 | — |
| Residual covariance | −3.15 | +1.36 | +3.52 | +8.93 | — |
| `Var(margin)` measured | 366.98 | 310.82 | 316.55 | 325.87 | — |
| `Var(margin)` reconstructed | 366.98 | 310.82 | 316.55 | 325.87 | — |
| Reconstruction error | 0.0000 | 0.0000 | 0.0000 | 0.0000 | — |
| Points per possession | 1.1806 | 1.1850 | 1.1772 | 1.1801 | 1.08-1.18 |
| Possessions per team-game | 100.91 | 100.82 | 100.82 | 100.43 | 96-103 |
| Timeouts per game | 0.00 | 4.15 | 3.96 | 3.99 | — |
| Independent-possession margin SD | 18.05 | 18.05 | 17.67 | 18.09 | — |

Mirror fixture, 300 games, variations 210,000-210,299, where the pregame gap is exactly zero:

| Metric | Before | After |
| --- | ---: | ---: |
| Blowout share | 0.3400 | **0.2567** |
| Close-game share | 0.1933 | **0.2233 ✓** |
| Overtime rate | 0.0333 | 0.0133 |
| Margin standard deviation | 18.637 | **16.993** |
| `Var(home points)` | 159.97 | 156.85 |
| `Var(away points)` | 196.70 | 182.17 |
| `Cov(home, away)` | **+4.67** | **+25.12** |
| `Corr(home, away)` | +0.026 | +0.149 |
| Residual covariance, pace and possessions removed | −10.65 | +12.68 |
| `Var(margin)` | 347.32 | **288.76** |
| Leading minus trailing points per possession, decided state | **+0.0128** | **−0.0200** |
| Leading seconds per possession, decided state | 14.04 | 14.69 |
| Trailing seconds per possession, decided state | 14.47 | 14.03 |
| Leading three-point share, decided state | 0.3965 | 0.3735 |
| Trailing three-point share, decided state | 0.4037 | 0.4176 |
| Measured margin SD against the independent-possession model | 18.62 vs 18.26 | **16.96 vs 18.11** |

**The variance moved, and the identity says exactly where from.** On the mirror fixture `Var(margin)` fell by 58.56. Of that, 40.90 is the covariance term — `−2·ΔCov` at `ΔCov = +20.45` — and 17.65 is the two teams' own scoring variances falling as clock management narrowed their totals. Seventy per cent of the improvement is covariance the engine did not have before. On the population fixture the split is 40/60 the other way, because the pregame strength gap contributes a *negative* covariance that masks part of the mechanism's positive one; the residual column, which removes strength, pace and possessions, moves from −3.15 to +1.36 there and from −10.65 to +12.68 on the mirror.

The margin is no longer an independent random walk. Before, the engine's dispersion sat 2% *above* what independent possessions imply; after, it sits 6% below.

#### The five competition levels

400 games each on the untouched range 60,000-60,399, the same fixture §5.10 measured. Before-figures are §5.10's.

| §14.2 metric | High school | College | Development | Overseas | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blowout, before | 0.1850 ✗ | 0.2400 ✗ | 0.2750 ✗ | 0.2300 ✗ | 0.3025 ✗ |
| **Blowout, after** | **0.1400 ✓** | **0.1750 ✓** | 0.2550 ✗ | 0.1950 ✗ | 0.2450 ✗ |
| Close, before | 0.2925 ✓ | 0.2200 ✓ | 0.2025 ✗ | 0.2725 ✓ | 0.2075 ✗ |
| **Close, after** | **0.2825 ✓** | **0.2700 ✓** | **0.2200 ✓** | **0.3000 ✓** | **0.2225 ✓** |
| Overtime, before | 0.0325 ✗ | 0.0150 ✗ | 0.0200 ✗ | 0.0300 ✗ | 0.0200 ✗ |
| **Overtime, after** | **0.0450 ✓** | 0.0250 ✗ | 0.0275 ✗ | 0.0375 ✗ | 0.0225 ✗ |
| Home win, before | 0.5175 ✗ | 0.4900 ✗ | 0.5500 ✓ | 0.5375 ✓ | 0.4850 ✗ |
| Home win, after | 0.5225 ✗ | 0.5200 ✗ | 0.5525 ✓ | 0.4950 ✗ | 0.5025 ✗ |

**Close-game share now passes at all five levels**, against three of five before. **Blowout share passes at high school and college**, against none before, and overseas at 0.1950 ±0.0388 has the ceiling inside its interval. High school passes all three dispersion targets.

That pattern is the finding, not a coincidence. §14.2's blowout and overtime bands are consistent with the *low* end of §14.1's possession economy and not with the high end: high school plays 68.6 possessions at 0.957 points each and lands inside every band, and top domestic plays 100.6 at 1.169 and does not. The mechanism is scaled to basketball, not to a target, and it therefore closes the gap exactly where the arithmetic leaves room.

§14.1 is unmoved. Every band that passed before passes now, at every level, with the same two exceptions §5.10 recorded: assist percentage, which this task was told to measure and not tune, and college field-goal percentage.

| §14.1 metric, top domestic | Before | After | Target |
| --- | ---: | ---: | ---: |
| Possessions per team-game | 100.77 | 100.64 | 96-103 ✓ |
| Points per possession | 1.1680 | **1.1691** | 1.08-1.18 ✓ |
| Field-goal % | 0.4548 | 0.4557 | 0.45-0.51 ✓ |
| Three-point % | 0.3682 | 0.3692 | 0.34-0.40 ✓ |
| Three-point attempt rate | 0.4088 | 0.4100 | 0.36-0.49 ✓ |
| Free-throw % | 0.8048 | 0.8069 | 0.73-0.83 ✓ |
| Free-throw attempt rate | 0.2132 | 0.2135 | 0.18-0.34 ✓ |
| Turnovers per 100 | 14.11 | 14.08 | 11-16 ✓ |
| Offensive rebound % | 0.2515 | 0.2480 | 0.20-0.31 ✓ |
| **Assist %** | 0.4831 | **0.4854** | 0.52-0.72 ✗ |
| Starter mean minutes | 30.09 | 30.23 | 27-35 ✓ |

**Points per possession is where §5.10 left it and no aggregate tuning was done to keep it there.** It moved from 1.1680 to 1.1691 — eleven ten-thousandths, on the same 400 games — because the mechanism changes which action a coach selects and not how efficient anybody is. Assist percentage is reported as a measurement only; it moved by 0.0023 and no assist parameter was touched.

#### Owner decision: what §14.2 still needs, and what it would cost

The investigation the owner asked for is complete, and it changed the answer twice. §5.10's premise was right — the covariance was zero — but its conclusion was wrong, because the covariance was zero for an implementation reason and not for a basketball one. Legitimate coaching produced a sixth of the margin's variance without touching a single probability. What follows is what remains, quantified in units a person can rule on.

**The frontier, measured rather than assumed.** A ledger-faithful replay model rebuilds each game from the pooled empirical distribution of its own possession outcomes and costs the leading team a stated number of points per possession once the margin passes a threshold. That single number is the measurable consequence of every legitimate late-game mechanism there is — resting starters, running clock, refusing the offensive glass, taking the safe shot — so the frontier is expressed in it. Population fixture, 500 games, threshold fifteen points:

| Leading-team penalty | As a share of scoring efficiency | Margin SD | Blowout | Close | Tie |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0.00 | 0% | 17.85 | 0.2720 | 0.2522 | 0.0256 |
| 0.05 | 4.2% | 16.60 | 0.2284 | 0.2564 | 0.0252 |
| **0.10** | **8.4%** | 15.32 | **0.1910** | 0.2668 | 0.0280 |
| **0.15** | **12.7%** | 14.31 | **0.1626 ✓** | 0.2698 ✓ | 0.0278 |
| 0.20 | 16.9% | 13.64 | 0.1400 ✓ | 0.2632 ✓ | 0.0226 |
| 0.30 | 25.3% | 12.21 | 0.0846 ✓ | 0.2764 ✓ | 0.0214 |

The engine now delivers a measured leading-team penalty of **0.008 to 0.020** points per possession in the decided state. The blowout ceiling needs about **0.12**, six to fifteen times more. That is not an absurd number in basketball — a leading team's efficiency really does fall by around a tenth in garbage time — but reaching it in this engine means the leading team's *lineup* has to change, because pace, shot mix and the offensive glass together are worth about a fiftieth of its efficiency and they are already applied at coaching-plausible strength. Pushing them to the top of their safe ranges was tried and bought nothing.

**Overtime is unreachable at any dispersion whatsoever, and this is the hard result.** The tie column above never reaches 4% — not at a penalty of 0.30, not at a margin standard deviation of 12.2. Extending the model to a threshold of ten points and a penalty of 0.30 produces a margin standard deviation of **9.90**, a blowout share of 4.3%, and a tie rate of **0.0334**: a league whose games are decided by ten points on average still cannot reach §14.2's overtime floor. The reason is arithmetic and it is not about this engine. The probability of an exactly level regulation score is the density of the margin distribution at zero, which is bounded above by roughly `1 / (σ·√(2π))`; at any σ a basketball league can have, that is 2-3%. Real leagues clear 4% only because end-of-regulation behaviour puts an *atom* at exactly zero — a trailing team shoots the shot that levels the game, and a leading team plays for the last one. This engine now has that behaviour, and it is worth a fraction of a percentage point here because it can only reach the games that arrive at the last possession within one score, which is about a tenth of them.

**Three options, quantified.**

1. **Accept the mechanism as shipped and revise §14.2's game-shape bands to what the possession economy supports.** Blowout 0.14-0.28 and overtime 0.02-0.05 across the five levels, with close-game share left at 0.22-0.34 where it now passes everywhere. Cost: two locked targets move, and they move to fit a measurement, which is exactly what this project's rules exist to prevent. Benefit: nothing in the engine changes and no realism is traded. This is the smallest revision that makes the targets satisfiable, and it is the one this section recommends *only* if the owner also accepts that §14.1 and §14.2 were written to different leagues.
2. **Make garbage-time rotation asymmetric in its threshold.** A coach protecting a lead rests his starters earlier than a coach chasing one concedes: the settled-game rule would fire for the leading team at a lower absolute margin, or earlier in the period, than for the trailing team. This is real — it is the dominant cause of the leading-team efficiency drop in actual garbage time — and it is symmetric under exchange, because it is the *situation* that differs and not the team. Estimated worth 0.04-0.07 points per possession of leading-team penalty, which the frontier above puts at a blowout share near 0.21-0.23 at top domestic: an improvement, not a pass. Cost: it is the change most easily mistaken for a comeback mechanism, it needs its own no-comeback-script test suite, and it is a design decision about coaching identity rather than a calibration one. It is deliberately **not** made here.
3. **Scope §14.1's possession and efficiency economy per competition and let §14.2 follow.** The five levels already show that §14.2 is satisfiable at 68 possessions and 0.96 points each and not at 101 and 1.17. Lowering top-domestic points per possession toward the middle of its band, or possessions toward the bottom of theirs, moves the blowout share with the square root of the product. Cost: this task was told not to push points per possession toward the middle of its band, and §5.10 showed the remaining §14.1-legal levers each trade one band for another. Benefit: it treats the cause rather than the symptom.

**Recommendation.** Option 1 for overtime, unconditionally: the 4-8% band is not reachable by any mechanism this engine could legitimately contain, and no amount of further work will change that — it is a property of a discrete margin's density at zero. Option 2 for the blowout share, taken as a deliberate design decision with its own test suite, and only after the owner has ruled that an asymmetric rest threshold is coaching rather than rubber-banding. Nothing in §14 was rewritten here.

#### Tests

`tests/simulation/test_game_management.gd` — 16 cases against the mechanism directly.

- Pressure is exactly zero at every ordinary margin in every period of a full-length game, which is the §14.1 guarantee stated as a test.
- Pressure reaches its ceiling when a trailing team is genuinely out of time, and a twenty-point margin with a half to play is not an endgame.
- Both teams compute the same pressure; reversing the scoreboard swaps the two policies exactly, across pace, action mix **and** the crash decision.
- The policy is blind to who the players are: replacing both rosters with much stronger ones leaves every factor identical, which is the direct statement that it cannot read strength, an intended winner or a target margin.
- Leading-team clock control is bounded, in the tunable and in the realized factor, at every margin and clock; the protecting gain exceeds the chasing relief by construction.
- The chasing strategy changes selection and stays inside the §12.2 guardrail.
- **The score grants no shot probability.** Same shooter, defender, zone, contest, lineup, clock and random stream; a thirty-point swing in both directions; identical resolved probability.
- The free-throw pressure term §20.1 does allow is symmetric in the *absolute* margin.
- The end-of-regulation rule seeks the tying shot value, for either team, and applies to nothing else — not to a deficit a single shot cannot level, not to a leading team, not with time for another possession, and not before the final period.
- Every competition grants a bounded timeout allowance; timeouts are spent, never replenished, and never over-spent, including through overtime.
- Every timeout in a played game answers a run at least as long as the threshold, is called by the team that was not on the run, and leaves enough regulation to want it.
- A timeout rests everybody on the floor on both sides by the same amount, and spends only the calling team's allowance.

`tests/calibration/test_scoring_covariance.gd` — 8 cases on rows whose answers are known: the identity closing on unrelated box scores, a constructed covariance coming back out, zero reported as zero, residualization removing a shared linear predictor, the permutation control returning exactly one without serial structure and moving with the real statistic when there is some, the damped model reducing dispersion monotonically and keeping the margin on the integer lattice, and the §14.2 and score-state boundaries on both sides of each edge.

`tests/simulation/test_score_margin.gd` gains one case and restates two. The score-blindness comparison now runs in the *body* of a full-length game, where the mechanism declares itself off, because running it in the final period would measure the mechanism rather than a rubber band; and a new case asserts the property that replaces it inside the managed window — that a team thirty ahead and a team thirty behind resolve from the same probabilities, and only their selection differs.

#### Mutation evidence

Each mutation was applied to a byte-exact backup, the detector run, and the file restored. `git status --porcelain` was captured before and after the whole battery and compared: **identical**.

| # | Mutation | Detector | What it reported |
| --- | --- | --- | --- |
| 1 | A trailing team's field-goal probability raised by 0.05 | `test_the_score_grants_no_shot_probability` | The probability at −30 differed from the probability at 0 |
| 2 | The reducer clamps any lead above twenty-five points back to twenty-five | `MatchSession`'s box-score reconciliation assertion | 16 errors and 2 failures across the margin suite. A score clamp is structurally unreachable: scores are reduced from events and reconciled against the ledger, so clamping one desynchronizes the two |
| 3 | `GameManagement.pace_multiplier` applies to the home side only | `test_the_policy_mirrors_when_the_scoreboard_is_reversed` | Two failures: the away side's factor at a reversed scoreboard was 1.0 |
| 4 | The protecting half of the action mix removed, leaving the chasing half | `test_the_policy_mirrors_when_the_scoreboard_is_reversed` | **Not detected on the first attempt.** See below |
| 5 | `protect_pace_gain` raised to 0.85 | Gate B0's safe-range check in `tests/run_all.gd`, and `test_the_policy_mirrors_when_the_scoreboard_is_reversed` | `management.protect_pace_gain = 0.85 share (safe 0.0..0.4)`, plus every golden ledger |
| 6 | The top-domestic timeout allowance set to zero | `test_every_competition_grants_a_bounded_timeout_allowance` | An allowance below the documented floor |
| 7 | `RotationResolver.game_is_decided` returns true whatever the margin | `test_settled_game_rotation_is_symmetric_and_bounded` | A level game reported as settled |
| 8 | Intentional fouling widened to a ten-minute window and a thirty-point margin | Gate B0's safe-range check, and the margin suite | Both tunables named outside their envelopes; the margin suite fails at `test_no_clamp_bounds_the_final_margin` because the widened rule compresses the margin |
| 9 | `ScoringCovariance.reconstructed_margin_variance` drops the `−2·Cov` term | `test_the_margin_variance_identity_closes_exactly` | The identity stopped closing on unrelated box scores |
| 10 | The timeout decision reads the wall clock | `test_stepped_play_matches_full_simulation` and `test_committed_hashes_reproduce_exactly` | Three failures: Play and Sim disagreed, and every committed hash moved |

**Mutation 4 is the one worth keeping in the record.** It removes score-aware tactics from the *leading* team only, which is precisely "score-aware tactics applied to only one team", and the suite did not notice — because the symmetry test asserted the pace factor for both roles but the action factor only for the chasing one. A test that checks the side that is behind and not the side that is ahead cannot see a policy that protects nobody. The test now asserts both halves of the action mix and both halves of the crash decision, and the restated mutation fails it in 8 ms.

#### Golden-ledger impact

Every committed ledger changed, deliberately, under an explicit ruleset change from `simulation-v3-margin` to **`simulation-v4-management`**.

The blast radius was proved rather than assumed. Each scenario's full event stream was dumped from the engine before and after and diffed line by line:

| Scenario | First divergence | Cause |
| --- | --- | --- |
| `regulation` | event 441 | A `timeout` inserted; everything after it shifts |
| `offensive_rebound` | event 165 | A `timeout` inserted |
| `foul_free_throw` | event 154 | An action selection inside a managed score state; no timeout in the game |
| `substitution_foul_out` | event 697 | An action selection in the third period |
| `late_game` | event 159 | An action selection; the possession then ends on the shot clock rather than a handoff |
| `overtime` | — | Re-derived seed |

**The overtime scenario needed a new seed and it is the only one that did.** A game that finishes level is by definition one that reached a managed score state, so seed 31676 stopped reaching overtime — which is the single thing that fixture exists to cover. `find_scenario_seeds.gd` derived 39595 over a 2,000-seed search, and confirmed in the same pass that the other five scenarios still exercise their named behaviour at the seeds they always had. No hash was regenerated to silence a failing test: the harness re-checks every scenario's requirement on every regeneration, and refused nothing.

#### Regression

Run under `simulation-v4-management` with the correction frozen.

| Check | Result |
| --- | --- |
| Parse/compile gate under warnings-as-errors | 206 scripts, 0 failures; the detector self-test passes on every run |
| GdUnit4 full suite | **344 cases, 0 failures**, against 317 before |
| `tests/run_all.gd` acceptance | PASS |
| Simulation smoke diagnostics | Invariants PASS |
| Golden ledgers | Regenerated under an explicit ruleset change; every scenario still covers its named behaviour, checked by the harness on regeneration |
| Builder calibration | PASS |
| Attribute sensitivity at 100,000 resolutions per point | 80 metrics, 80 judged, **0 failures** |
| Calibration smoke | 15 metrics, 15 judged, **0 failures** |
| Career progression, three shards of 1,000 careers | All five §8.4 bands pass on all three shards (66 / 77 / 82 / 87 / 93, with shard 2's rare-generational at 92); share above 95 OVR 0.0000; AP reconciliation failures 0.0000; §9.5 opportunity-ruling violations 0.0000; §9.5 guardrail warnings explained 1.0000. The only failure on each shard is `sample.meets_certification_size`, which fails correctly at 1,000 careers against §27.1's 1,000,000 |
| Executor parity | Manual vs full-detail and manual vs aggregate relative peak difference both exactly 0.0000, Cohen's *d* 0.000, on all three shards |
| Projected Peak, inside the career report | Coverage 0.7400 ±0.0271, median width 11.0, median signed error −1.0 — all inside their §6.3 bands |
| Projected Peak diagnostics, 2,000 careers | Coverage 0.7440 ±0.0191, median width 11.0, total signed error 0.0000 ±0.2845, zero pathological subgroups. 3 judged metrics, 0 failures |
| Rare-generational diagnostics, 400 forced-path careers | Reproduces §5.8's allocation bound and phase accounting unchanged |
| Real shard aggregation | Three seed-disjoint top-domestic shards of 120 games each, pooled end to end. All three accepted, provenance and seed-disjointness validated, raw terms pooled; the aggregate reports points per possession, possessions and the §14.2 shares over 360 games and refuses to certify because `certification.sample_reached` is 0.0000 against §27.1 |
| Five competition reports | The table above |
| Two untouched validation ranges | The table above |

**Nothing in this correction touches the development domain**, and the runs above are the regression check on that separation rather than a re-derivation. `CareerSimulator`, `DevelopmentService` and the projected-peak model reference neither `SimulationBalanceProfile`'s match tunables nor `GameManagement`, which is checkable by grep and was checked; every §5.7, §5.8 and §5.9 figure reproduces exactly.

#### Performance

| | Before (`d6f9744`) | After |
| --- | ---: | ---: |
| Milliseconds per complete reference game, quiet machine | 1336.8 | **1355.9** (+1.4%) |
| Milliseconds per complete reference game, first cut, three competing processes | 1342.4 | 1493.5 (+11.3%) |

Measured with the same runner at 20 games, on the same machine, with the before figure taken from a worktree checked out at the before commit rather than by stashing. The two rows are two separate paired measurements; the second is the one that found the problem and the first is the one that reports the shipped cost.

The first cut cost 11%, and the reason was worth fixing rather than accepting. `GameManagement.pressure` was being recomputed for every action candidate, and a possession generates about forty of them from one state — forty identical answers. It is now resolved once per `generate` call beside the lineup spacing and passed in. The arithmetic is the same arithmetic in the same order, which is why the memoization moved no golden hash: `tests/run_all.gd` passed against the already-regenerated hashes immediately afterwards, which is the proof that the optimization is behaviour-preserving rather than a second correction wearing an optimization's clothes.

It does not change the §6.4 arithmetic: at roughly 1.36 seconds a game the §27.1 100,000-game certification is about 37 hours per competition on one process.

#### Classification

- **Structural:** the `Var(A − B) = Var(A) + Var(B) − 2·Cov(A, B)` identity and its exact closure; the score-state and §14.2 classification boundaries; `GameManagement`'s pressure being zero through ordinary basketball; its symmetry under reversal of the scoreboard across pace, action mix and the crash decision; its blindness to ratings, strength and any intended winner; the bound on leading-team clock control; the end-of-regulation gate; the timeout gate, allowance, and equal rest for both teams; the absence of any score effect on shot or free-throw probability; the permutation control's identity property; ledger reconciliation of possessions, scores and points per possession; Play/Sim/Skip equality; and cross-game isolation. All proven by deterministic tests.
- **Measured below requirement:** every §14.2 and §14.1 figure above. 300-500 games per range against §27.1's 100,000 per competition.
- **Failed:** §14.2 blowout share at three of five competition levels and overtime rate at four of five; §14.2 home win rate at four of five. §14.1 assist percentage at four of five and college field-goal percentage, both unchanged and both pre-existing.
- **Certified:** nothing.

### 5.12 Garbage time is a coaching decision, and the two coaches reach it at different moments

Status: **The owner authorised an asymmetric settled-rotation threshold on 2026-08-20 and it is implemented, validated on four untouched ranges, and measured across all five competitions. Blowout share falls by five to six percentage points everywhere and passes at three of five levels. The remaining §14.2 incompatibility is now quantified per competition and is put to the owner as a proposed amendment, which this section does not enact.**

§5.11 measured the score margin's covariance, found it zero, and traced that to three authorised mechanisms the engine did not have. It implemented them and stopped at a boundary it could not cross alone: the leading team's efficiency drop in a decided game measured 0.008–0.020 points per possession against the 0.12 the blowout ceiling needs, and the largest remaining lever — a coach resting his starters *earlier* than his opposite number concedes — was a design decision rather than a calibration one. The owner has now made it.

#### The rule

`GarbageTimeRule` replaces one universal raw margin inside a share of the final period with a possession-based safety measure:

```text
safety = |margin| / (settled_swing_points_per_pair * sqrt(possession_pairs_left))
```

The margin of the game still to be played is a sum over the remaining possession pairs, so its standard deviation grows with the **square root** of them. That is the whole reason one constant covers a thirty-two-minute school game and a forty-eight-minute professional one without a per-competition table, and why twenty points with nine minutes left and thirty points with twenty minutes left are the same decision. `possession_pairs_left` is read from the pace the game has actually played at, so a slow competition buys fewer pairs from the same clock and reaches a given safety sooner.

Two thresholds read that one shared number:

| Role | Threshold | Approximate win probability | What it means |
| --- | ---: | ---: | --- |
| Leading | `settled_leading_safety` = 2.6 | ≈ 99.5% | The coach who is ahead has won and starts protecting people |
| Trailing | `settled_trailing_safety` = 4.2 | ≈ 99.998% | The coach who is behind concedes, late and reluctantly |

Three guards keep it away from competitive basketball: a margin below `settled_minimum_margin` (18 points) never qualifies whatever the arithmetic says; a game with fewer than `settled_minimum_pairs_left` (one pair) remaining cannot newly enter, because there is no rest left to give; and the state releases — on both the safety and the margin floor, each with a `settled_release_share` of 0.85 hysteresis — when the trailing team actually closes the gap.

The state lives on `TeamMatchState.settled_mode`, is written **only** by `MatchStateReducer` from a `GARBAGE_TIME` event carrying the mode and the signed margin it was taken at, and is read by `RotationResolver` without being recomputed. No policy lives in the substitution loop, and no rotation exists that the ledger cannot explain.

#### Why this is coaching and not a rubber band

The owner's ruling set eight conditions. Each is a property, and each is asserted:

| Condition | How it is enforced | Where it is proven |
| --- | --- | --- |
| Changes lineup and rotation decisions only | The only consumer is `RotationResolver._departure_reason` and the closing-lineup preference | `test_the_rotation_reads_the_settled_mode_and_does_not_recompute_it` |
| Does not modify ratings | Capability resolution for the same player is identical at +30, 0, −30 and in either settled mode | `test_the_trailing_team_receives_no_rating_or_capability_bonus` |
| Does not modify shot, turnover, rebound or foul probability | The same shot, shooter, defender, zone, contest, lineup, clock and random stream resolve to the identical make probability in and out of the state | `test_the_same_shot_keeps_its_probability_in_and_out_of_garbage_time` |
| Forces no make, miss, turnover, tie, overtime or comeback | Nothing in the class reaches a resolver; its whole output is a `Mode` | The two rows above, plus the measured comeback share of 0.000–0.014 |
| Cannot inspect the intended winner or target final margin | Its inputs are the margin, the clock, the period, the rules and the realized pace. Replacing both rosters with much stronger ones changes nothing | `test_the_rule_cannot_read_strength_or_an_intended_winner` |
| Uses only observable score, clock, period, timeout and lineup state | Same | Same |
| Bounded, deterministic, versioned, ledger-explained | Six named tunables inside Gate B0 safe ranges; a `GARBAGE_TIME` event per transition; byte-identical ledgers on repeated seeds | `test_every_settled_substitution_is_explained_by_a_ledger_entry`, `test_play_sim_and_skip_agree_with_the_settled_state` |
| Does not activate during genuinely competitive games | An eighteen-point coaching floor beneath a 2.6-standard-deviation safety | `test_garbage_time_cannot_activate_in_a_close_game`, `test_garbage_time_cannot_activate_too_early` |

**The policy is symmetric and the roles are not, and the difference is testable.** Put the same roster on the other side of the same scoreboard and its behaviour reverses exactly: home at +m behaves as away does at −m, at every margin tested. The asymmetry is between *situations*, not between teams — which is what makes it coaching. A rubber band would key on identity, on strength, or on an intended outcome, and three separate tests show it keys on none of them.

#### Changed parameters

`decided_game_margin` and `decided_game_clock_share` are **removed**: they were the entire previous rule and are replaced, not adjusted. Everything below is new.

| Parameter | Value | Unit | Safe range | Provenance |
| --- | ---: | --- | --- | --- |
| `settled_minimum_margin` | 18 | points | 8-40 | The coaching floor. Twelve points with ninety seconds left is arithmetically safe and no coach empties a bench into it; eighteen is the smallest margin at which resting people is a recognisable decision rather than a forfeit |
| `settled_swing_points_per_pair` | 1.77 | points per √possession pair | 1.0-3.0 | **Measured, not chosen.** The pooled within-team-game variance of one possession's points is about 1.57 across the five competitions, and two possessions per pair gives `sqrt(2 × 1.57) = 1.77` |
| `settled_leading_safety` | 2.6 | standard deviations | 1.5-6.0 | ≈ 99.5% win probability. The lower of the two thresholds; the gap to the row below is the authorised asymmetry |
| `settled_trailing_safety` | 4.2 | standard deviations | 2.0-10.0 | ≈ 99.998%. Trailing coaches concede late and reluctantly |
| `settled_release_share` | 0.85 | share of the entry threshold | 0.50-1.00 | Hysteresis, applied to both the safety and the margin floor. Without it a game trading baskets at eighteen points alternates rotations every possession |
| `settled_minimum_pairs_left` | 1.0 | possession pairs | 0.0-6.0 | Below one pair there is no rest left to give and a substitution is churn |
| `CompetitionRuleProfile` | unchanged | — | — | No competition profile needed a threshold of its own: the square-root law does the scaling |

**One defect was found by measurement and fixed before the implementation was frozen.** The first cut applied hysteresis to the safety number but released on the raw eighteen-point floor, so a settled game trading baskets around that boundary re-entered and released repeatedly: 1.47 activations and 0.90 resumptions a game. Giving the floor the same release share cut those to 0.94 and 0.43 with no other change.

**No threshold was moved after the first measurement.** The implementation was frozen before any validation range was touched, and the two thresholds are the values above.

#### Seed-range separation

Every range in this section is new. None appears in §5.7 through §5.11.

| Purpose | Variations | RNG seeds | Games |
| --- | --- | --- | ---: |
| Development probe | 2,000,000-2,000,249 | 2,000,001-2,000,250 | 250 |
| Tuning | — | — | not required |
| **Validation A — untouched** | 310,000-310,499 | 310,001-310,500 | 500 |
| **Validation B — untouched** | 320,000-320,499 | 320,001-320,500 | 500 |
| **Mirror validation A — untouched** | 330,000-330,299 | 330,001-330,300 | 300 |
| **Mirror validation B — untouched** | 345,000-345,299 | 345,001-345,300 | 300 |
| Five-level paired measurement | 350,000-350,399 | 350,001-350,400 | 400 each |

Every range was run on **both** the frozen implementation and a worktree checked out at `8e1c72b`, so every before/after pair below is the same games played by two engines. The before tree carries the same diagnostic harness and runner — a copy, not a rebuild — with the two references to the new class replaced by literals, so the instrument is identical and only the engine differs.

No tuning range was needed: the thresholds were derived from win probability and the measured possession variance, not fitted.

#### Even-team fixtures first

Mirror fixtures, where the pregame gap is exactly zero and only the engine's own dispersion remains. 300 games each.

| Metric | Mirror A before | **Mirror A after** | Mirror B before | **Mirror B after** |
| --- | ---: | ---: | ---: | ---: |
| Blowout share | 0.2433 | **0.1833** | 0.2500 | **0.1933** |
| Close-game share | 0.1800 | 0.1867 | 0.2200 | 0.2267 |
| Overtime rate | 0.0233 | 0.0233 | 0.0067 | 0.0067 |
| Margin standard deviation | 17.346 | **15.559** | 17.327 | **15.533** |
| `Var(margin)` | 300.88 | **242.07** | 300.23 | **241.28** |
| `Cov(home, away)` | +20.25 | **+37.10** | +11.61 | **+31.26** |
| Mean absolute margin | 13.89 | 12.65 | — | — |
| Points per possession | 1.1808 | 1.1795 | 1.1802 | — |
| Possessions per team-game | 100.85 | 100.84 | 100.49 | — |
| Substitutions per game | 73.22 | 80.12 | — | — |

Pooled over 600 even-team games the blowout share moves from **0.2467 to 0.1883** and the margin's variance falls by **19.6%**, of which the covariance term is the larger part.

#### Population fixtures

| Metric | Validation A before | **Validation A after** | Validation B before | **Validation B after** | Target |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blowout share | 0.2840 ±0.0394 | **0.2320 ±0.0369** | 0.2520 ±0.0380 | **0.2120 ±0.0358** | 0.08-0.18 |
| Close-game share | 0.2260 ±0.0366 | 0.2220 ±0.0364 | 0.2020 ±0.0351 | 0.2060 ±0.0354 | 0.22-0.34 |
| Overtime rate | 0.0280 ±0.0148 | 0.0300 ±0.0153 | 0.0120 ±0.0102 | 0.0120 ±0.0102 | 0.04-0.08 |
| Home win rate | 0.5320 ±0.0436 | 0.5320 ✓ | 0.5560 ±0.0434 | 0.5540 ✓ | 0.53-0.56 |
| Margin standard deviation | 18.605 | **16.571** | 17.340 | **16.108** | — |
| Mean absolute margin | 14.86 | 13.52 | 14.09 | 13.10 | — |
| Median absolute margin | 12.0 | 11.0 | 11.5 | 11.0 | — |
| One-possession rate (≤3) | 0.1220 | 0.1200 | 0.1080 | 0.1120 | — |
| Two-possession rate (≤6) | 0.2680 | 0.2740 | 0.2720 | 0.2720 | — |
| Lead changes per game | 6.638 | 6.638 | 6.874 | 6.884 | — |
| Ties per game | 9.116 | 9.100 | 8.840 | 8.852 | — |
| Largest lead, mean | 22.46 | 21.56 | 21.91 | 21.37 | — |
| `Var(margin)` | 346.16 | **274.60** | 300.67 | **259.45** | — |
| `Cov(home, away)` | −2.40 | **+19.13** | +6.75 | **+22.96** | — |
| Residual covariance | −5.28 | **+13.59** | +7.26 | **+21.01** | — |
| Points per possession | 1.1836 | 1.1806 | 1.1807 | 1.1768 | 1.08-1.18 |
| Possessions per team-game | 100.71 | 100.67 | 100.73 | 100.69 | 96-103 |
| Substitutions per game | 72.37 | 79.85 | — | 79.75 | — |

**The earlier 21-23% estimate is confirmed and was very slightly optimistic.** Pooled over the two 500-game validation ranges and the 400-game top-domestic level run — 1,400 population games — the blowout share measures **0.2364 ±0.0223**. The 21-23% interval sits inside that at its lower edge.

#### Garbage-time activation, re-entry and minutes

| Measure | Mirror A | Mirror B | Validation A | Validation B | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Games where either coach settled | 0.4800 | 0.4700 | 0.5020 | 0.4800 | 0.4975 |
| Games where the leading coach settled | 0.4800 | 0.4700 | 0.5020 | 0.4800 | 0.4975 |
| Games where the trailing coach conceded | 0.3200 | 0.3467 | 0.3700 | 0.3340 | 0.3900 |
| Games where a coach returned to his rotation | 0.3033 | 0.2933 | 0.3040 | 0.2880 | 0.2625 |
| Activations per game | 0.940 | — | 1.088 | 0.986 | 1.085 |
| Resumptions per game | 0.433 | 0.447 | 0.484 | 0.470 | 0.400 |
| Absolute margin at first activation | 22.68 | — | 23.45 | 23.04 | 23.69 |
| Share of regulation left at first activation | 0.2097 | — | 0.2335 | 0.2208 | 0.2419 |
| **False positive**: activated, finished inside six | 0.0486 | 0.0426 | 0.0478 | 0.0458 | 0.0402 |
| **False positive**: activated, finished inside ten | 0.1944 | 0.1560 | 0.1514 | 0.1625 | 0.1156 |
| **Comeback**: won by the side behind at activation | 0.0139 | 0.0000 | 0.0000 | 0.0042 | 0.0050 |
| Starter share of on-court time **before** activation | 0.6454 | 0.6481 | 0.6465 | 0.6481 | 0.6454 |
| **Leading** starter share **after** activation | **0.1652** | **0.1610** | **0.1359** | **0.1298** | **0.1179** |
| **Trailing** starter share **after** activation | **0.4664** | **0.4626** | **0.4731** | **0.4505** | **0.4286** |

**The two rows at the bottom are the correction, measured.** Before activation the two benches are interchangeable at 65% starter time. After it the leading team's starters hold 12-17% of its minutes and the trailing team's hold 43-47% — a leading bench playing a trailing rotation, which is what garbage time is. The leading coach reaches the decision in about half of all games and the trailing coach in about a third, and the gap between those two shares is the window.

**The state is not a latch and it is not a trap.** A coach returns to his competitive rotation in about 29% of games, and the comeback share — activated games won by the side that was behind when it began — is **0.000 to 0.014**. That is not zero because the trailing team occasionally does come back, and when it does the state releases first: the release is a *consequence* of points the trailing team scored, never a cause of them.

Activation is called on a game that finishes inside six points about **4.5%** of the time. That is the rule's honest error rate at a mean activation margin of 23 points with a fifth of regulation left, and it is reported rather than tuned away.

#### The five competition levels

400 games each on the untouched range 350,000-350,399, the same games played by both engines. §14.2 game shape first.

| §14.2 metric | High school | College | Development | Overseas | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blowout, before | 0.1625 ✓ | 0.1950 ✗ | 0.2875 ✗ | 0.1950 ✗ | 0.2925 ✗ |
| **Blowout, after** | **0.1300 ✓** | **0.1700 ✓** | 0.2450 ✗ | **0.1550 ✓** | 0.2725 ✗ |
| Close, before | 0.2550 ✓ | 0.2675 ✓ | 0.2200 ✓ | 0.2650 ✓ | 0.2425 ✓ |
| **Close, after** | **0.2700 ✓** | **0.2700 ✓** | **0.2200 ✓** | **0.2700 ✓** | **0.2475 ✓** |
| Overtime, before | 0.0425 ✓ | 0.0125 ✗ | 0.0225 ✗ | 0.0250 ✗ | 0.0150 ✗ |
| **Overtime, after** | **0.0425 ✓** | 0.0100 ✗ | 0.0225 ✗ | 0.0250 ✗ | 0.0175 ✗ |
| Home win, before | 0.5475 ✗ | 0.5225 ✗ | 0.5200 ✗ | 0.5300 ✓ | 0.5300 ✓ |
| Home win, after | 0.5450 ✗ | 0.5250 ✗ | 0.5200 ✗ | 0.5275 ✗ | 0.5325 ✓ |
| Margin standard deviation, before | 14.53 | 14.92 | 19.02 | 14.65 | 18.45 |
| **Margin standard deviation, after** | **13.40** | **14.00** | **17.92** | **13.41** | **17.73** |
| `Cov(home, away)`, before | +1.60 | −6.64 | −15.34 | +11.61 | −3.78 |
| **`Cov(home, away)`, after** | **+10.08** | **+2.56** | **−1.77** | **+21.33** | **+2.62** |
| Garbage-time activation | 0.3375 | 0.3575 | 0.4850 | 0.3750 | 0.4975 |
| Leading starter share after | 0.1392 | 0.1510 | 0.1466 | 0.1585 | 0.1179 |
| Trailing starter share after | 0.4719 | 0.4582 | 0.4438 | 0.4458 | 0.4286 |

**Blowout share improves at all five levels and now passes at three.** Overseas moves inside the band; college moves inside; high school moves further inside. The two levels still outside are the two that play the most possessions at the highest efficiency, which is the same ordering §5.10 and §5.11 found and the same one the arithmetic predicts.

**High school passes every one of the fifteen judged metrics**, §14.1 and §14.2 together, for the first time.

#### §14.1 regression: nothing moved

Same games, same range, both engines. The rule touches minutes, so §14.1 rates move in the fourth decimal and nowhere else.

| §14.1 metric | High school | College | Development | Overseas | Top domestic |
| --- | --- | --- | --- | --- | --- |
| Possessions per team-game | 68.72 → 68.60 ✓ | 70.43 → 70.38 ✓ | 94.48 → 94.31 ✓ | 74.34 → 74.34 ✓ | 100.37 → 100.31 ✓ |
| Points per possession | 0.9603 → 0.9581 ✓ | 1.0462 → 1.0453 ✓ | 1.1090 → 1.1078 ✓ | 1.1119 → 1.1108 ✓ | 1.1844 → **1.1809** ✗ |
| Field-goal % | 0.3970 → 0.3960 ✓ | 0.4144 → 0.4146 ✗ | 0.4363 → 0.4360 ✓ | 0.4366 → 0.4362 ✓ | 0.4601 → 0.4596 ✓ |
| Three-point % | 0.3153 → 0.3140 ✓ | 0.3289 → 0.3295 ✓ | 0.3472 → 0.3468 ✓ | 0.3523 → 0.3519 ✓ | 0.3699 → 0.3690 ✓ |
| Three-point attempt rate | 0.3422 → 0.3409 ✓ | 0.3743 → 0.3739 ✓ | 0.3917 → 0.3905 ✓ | 0.3945 → 0.3935 ✓ | 0.4108 → 0.4099 ✓ |
| Free-throw % | 0.6717 → 0.6695 ✓ | 0.7142 → 0.7138 ✓ | 0.7564 → 0.7549 ✓ | 0.7629 → 0.7614 ✓ | 0.8036 → 0.8018 ✓ |
| Free-throw attempt rate | 0.1944 → 0.1958 ✓ | 0.2497 → 0.2488 ✓ | 0.2129 → 0.2141 ✓ | 0.2182 → 0.2192 ✓ | 0.2192 → 0.2202 ✓ |
| Turnovers per 100 | 17.71 → 17.72 ✓ | 16.65 → 16.71 ✓ | 14.70 → 14.78 ✓ | 14.19 → 14.16 ✓ | 14.01 → 14.12 ✓ |
| Offensive rebound % | 0.2535 → 0.2536 ✓ | 0.2553 → 0.2561 ✓ | 0.2535 → 0.2545 ✓ | 0.2523 → 0.2519 ✓ | 0.2564 → 0.2559 ✓ |
| **Assist %** | 0.4768 → 0.4772 ✓ | 0.4851 → 0.4840 ✓ | 0.4731 → 0.4740 ✗ | 0.4701 → 0.4712 ✗ | 0.4817 → 0.4820 ✗ |
| Starter mean minutes | 20.36 → 19.71 | 25.08 → 24.79 | 30.40 → 29.16 | 25.03 → 24.38 | 30.05 → **28.84 ✓** |

**Every pass/fail verdict is identical before and after, at every level.** The only §14.1 metric that changes verdict is none of them.

**Points per possession, without tuning.** Top domestic reads 1.1809 on this range and fails the 1.18 ceiling — and it fails *before* the change too, at 1.1844. The range is hot: the same engine measured 1.1691 on 60,000-60,399 in §5.11 and 1.1768-1.1806 on the two validation ranges here. The garbage-time rule moved it **down** by 0.0035, toward the band, because a bench plays the last six minutes of half the games. Nothing was tuned to achieve that and nothing was tuned to hide it: the honest statement is that points per possession sits on its ceiling and its range-to-range spread straddles it.

**Assist percentage, home advantage and college field-goal percentage are untouched measurements.** Assist moves by at most 0.0011 at any level and no assist parameter exists in this diff. Home win rate moves by at most 0.0025 and the §5.11 cause — the home environment is worth about 0.3 points a game where the band needs about 2.1 — is unchanged. College field-goal percentage moves from 0.4144 to 0.4146 against a 0.42 floor. All three were explicitly out of scope and all three are reported exactly as measured.

#### Tests

`tests/simulation/test_garbage_time.gd` — 22 cases against the rule directly.

- The safety number is one shared property of the game: both teams read the same value, a level game has none, and it grows with the margin and with the clock running out.
- **The safety obeys the square-root law it is built on**: doubling the margin is exactly equivalent to quadrupling the possessions left, and halving the margin halves the safety. This is the property that lets one constant serve five competitions, and the property a rule dividing by the possessions would break while still ordering the extremes correctly.
- Reversing the scoreboard swaps the two roles exactly, at every margin tested.
- The policy is blind to who the players are: replacing both rosters with much stronger ones leaves the safety and the decision identical.
- The leading coach settles before the trailing one; the trailing coach never concedes first; and both settle once the game is decided enough.
- Garbage time cannot activate in a close game at any clock, cannot activate early at any margin, and cannot begin with less than a possession pair left.
- Returning to the competitive rotation is rule-based and symmetric; the state has hysteresis, on a state found by search rather than asserted from a literal; a lead changing hands ends it.
- **The same shot keeps its make probability** in and out of the state, at +30, 0 and −30, with the random stream held fixed; and capability resolution for the same player is identical at every margin and in either mode.
- Intentional fouling and the settled state cannot overlap — the two windows are disjoint by construction at every margin from one to twenty-three.
- Timeouts stay valid through the settled state: the allowance is spent, never replenished, never over-spent.
- **Every settled-game substitution is preceded by a live `GARBAGE_TIME` entry for the same team**, each entry names a valid mode, carries a margin at or beyond the coaching floor, and agrees in sign with the mode it declares.
- Minutes and lineup participation reconcile: five per team on court throughout, every check-out matched by a live check-in, team minutes within one per cent of five times the game.
- Play, Sim and Skip agree; the same seed reproduces the ledger byte for byte; the state does not leak between games.
- The thresholds scale across all five competitions' game lengths.

`tests/simulation/test_score_margin.gd` gains a raised sample and a stronger assertion. `EDGE_SAMPLE` moves from 8 to 24 because at eight games the edge-overlap statistic had become a boundary — the edged fixture's minimum and the neutral fixture's maximum landed on the same integer, which says nothing. At twenty-four the same fixture shows a five-point capability edge **losing three of its games**, and the test now asserts that directly as well as the overlap. Its settled-game cases are restated against the new contract: the rotation *reads* a mode it never recomputes, and a thirty-point scoreboard alone settles nobody.

#### Mutation evidence

Each mutation was applied to a byte-exact backup, the detector run, and the file restored. `git status --porcelain` was captured before and after the whole battery and compared: **identical**.

| # | Mutation | Detector | What it reported |
| --- | --- | --- | --- |
| 1 | The eighteen-point coaching floor removed | `test_garbage_time_cannot_activate_in_a_close_game` | Ten assertion failures; games settled at margins of one to eleven points |
| 2 | Only the home side receives the policy | `test_reversing_the_scoreboard_swaps_the_two_roles` | Six failures; home at `+m` no longer behaved as away at `−m` |
| 3 | The trailing team's field-goal probability raised by 0.05 | `test_the_same_shot_keeps_its_probability_in_and_out_of_garbage_time` | The probability at −30 differed from the probability at 0 |
| 4 | The reducer clamps any lead above twenty-five points | `MatchSession`'s box-score reconciliation assertion | Four errors across the suite. A score clamp is structurally unreachable: scores are reduced from events and reconciled against the ledger |
| 5 | The leading coach never settles | `test_the_leading_coach_settles_before_the_trailing_one` | Six failures: the trailing coach conceded first, and no leading-only window existed |
| 6 | The trailing coach never concedes | `test_the_leading_coach_settles_before_the_trailing_one` | Both coaches never settle, however decided the game becomes |
| 7 | Entries dropped from the ledger, leaving only the resumptions | `test_every_settled_substitution_is_explained_by_a_ledger_entry` | A settled-game check-in with no live garbage-time entry |
| 8 | The settled state never releases | `test_returning_to_the_competitive_rotation_is_rule_based_and_symmetric` | Three failures; a twelve-point game stayed settled |
| 9 | Safety scales with the possessions left rather than their square root | `test_safety_obeys_the_square_root_law` | **Not detected on the first attempt.** See below |
| 10 | A settled-game substitution checks a player in without checking anyone out | `RotationResolver.validate` | `exactly five eligible players per team must be on court`, immediately, followed by a cascade of lineup and matchup failures |

**Mutation 9 is the one worth keeping in the record.** Replacing `sqrt(pairs)` with `pairs / 6` — a rule that scales with the possessions left rather than with their square root, and therefore reads a thirty-two-minute game and a forty-eight-minute one differently — passed the whole suite. The scaling test asserted the *extremes*: a settled margin settles everywhere, a competitive one settles nowhere, and nothing settles in the first period. A linear rule satisfies all three, because the coaching floor masks the middle and the extremes still order correctly. What it cannot satisfy is the law the rule is built on, and the suite did not assert it. `test_safety_obeys_the_square_root_law` now does — doubling the margin must equal quadrupling the possessions left — and the restated mutation fails it in 13 ms. A test that checks the ends of a curve is not checking its shape.

#### Golden-ledger impact

**No committed hash moved, and no scenario seed moved.** All six golden ledgers reproduce exactly, `tests/run_all.gd` passes against the hashes committed under `simulation-v4-management`, and `tests/fixtures/golden_scenarios.gd` is untouched.

The reason is legible rather than lucky: the six fixtures finish at margins of four to thirteen points, and the rule needs eighteen before it can fire at all. The blast radius of a rule that only acts on decided games is exactly the set of games that become decided, and none of the committed scenarios does.

The simulation ruleset version still moves, from `simulation-v4-management` to **`simulation-v5-garbage-time`**, because the balance profile's tunables and the engine's rotation behaviour both changed. The version records why hashes *would* have been allowed to move; that none did is the evidence, not the exemption.

#### Regression

| Check | Result |
| --- | --- |
| Parse/compile gate under warnings-as-errors | 208 scripts, 0 failures |
| GdUnit4 full suite | **366 cases, 0 failures**, against 344 before |
| `tests/run_all.gd` acceptance | PASS |
| Simulation smoke and invariants | Invariants PASS |
| All six golden scenarios | Reproduce exactly; no hash or seed changed |
| Builder calibration | PASS |
| Attribute sensitivity at 100,000 resolutions per point | 80 metrics, 80 judged, **0 failures** |
| Calibration smoke | 15 metrics, 15 judged, **0 failures** |
| Career progression, three shards of 1,000 careers | All five §8.4 bands pass on all three shards; share above 95 OVR 0.0000; §8.4 transition-gap share 0.0160; AP reconciliation failures 0.0000; §9.5 opportunity-ruling violations 0.0000. The only failure on each shard is `sample.meets_certification_size` at 1,000 careers against §27.1's 1,000,000 |
| AP reconciliation | 0.0000 failures on all three shards |
| Executor parity | Manual vs full-detail and manual vs aggregate relative peak difference both exactly 0.0000, Cohen's *d* 0.000, on all three shards |
| Projected Peak regression | Coverage 0.7440 ±0.0191, median width 11.0, zero pathological subgroups. 3 judged metrics, 0 failures |
| Rare-generational regression | 400 forced-path careers reproduce §5.8's allocation bound and phase accounting unchanged |
| Real shard aggregation | Three seed-disjoint top-domestic shards of 120 games pooled end to end; all accepted, provenance and seed-disjointness validated; refuses to certify at `certification.sample_reached` 0.0000 |
| Five-level competition reports | The tables above, before and after, on one untouched range |

Every §5.7, §5.8, §5.9 and §5.11 figure reproduces. Nothing in this correction touches the development domain, and the career runs are the regression check on that separation rather than a re-derivation.

#### Performance

| | Before (`8e1c72b`) | After | Change |
| --- | ---: | ---: | ---: |
| Milliseconds per complete reference game | 1149.4 | 1157.7 | **+0.7%** |

Measured with the same runner at 20 games, on the same quiet machine, with the before figure taken from a worktree checked out at the before commit rather than by stashing. The cost is one safety evaluation per team between possessions — two square roots a possession pair — and it is inside the noise of a measurement that moves by more than this between otherwise identical runs.

#### Classification

- **Structural:** the safety number's square-root law and its symmetry; the policy's blindness to ratings, strength and any intended winner; the coaching floor, the early-game guard and the no-time-left guard; the asymmetric ordering of the two thresholds and the existence of a leading-only window; release with hysteresis and on a lead changing hands; the absence of any score or settled-state effect on shot probability or capability; the disjointness of intentional fouling and the settled state; the ledger explaining every settled substitution; minute and lineup reconciliation; Play/Sim/Skip equality; cross-game isolation; and the golden ledgers reproducing unchanged. All proven by deterministic tests.
- **Measured below requirement:** every §14.2 and §14.1 figure above. 300-500 games per range against §27.1's 100,000 per competition.
- **Failed:** §14.2 blowout share at development and top domestic; overtime rate at four of five levels; home win rate at four of five. §14.1 assist percentage at three of five, college field-goal percentage, and top-domestic points per possession on this range — all three unchanged by this work and all three explicitly out of its scope.
- **Certified:** nothing.

### 5.13 Proposed §14.2 amendment — for owner decision, not enacted

Status: **A proposal. Nothing in `BALANCE_SPEC.md` §14.2 has been changed, and nothing below is approved. The current targets remain the targets against which every report in this document is judged, and every failure against them is still reported as a failure.**

§14.2 states four game-shape targets as one universal band each, for all five competitions. Three tasks of measurement now say that two of those four cannot be universal, and one of them cannot be met at all under the current possession and scoring model. This section sets out what would have to change, what it would cost, and what the owner would be accepting.

#### What is measured, and what kind of problem each target is

The task's five categories, assigned:

| Target | Category | Why |
| --- | --- | --- |
| **Overtime 4-8%** | **Mathematically impossible under the current legal possession/scoring model** | The probability of an exactly level regulation score is the margin distribution's density at zero. Under §14.1's possession economy — 68-101 possessions worth 0, 1, 2 or 3 points at the measured rates — a ledger-faithful replay model reaches a tie rate of only 0.0334 at a margin standard deviation of **9.90**, a league whose games are decided by ten points on average. Every legal dispersion is worse. This is a property of *this* scoring model, **not a law of basketball**: a league with a fuller end-of-regulation repertoire concentrates extra mass at exactly level, and that repertoire is a system this engine does not yet have |
| **Blowout 8-18%, top domestic and development** | **Possible through legitimate behaviour but outside current safe ranges** | The replay model puts the ceiling at a leading-team penalty near 0.12 points per possession. The authorised rotation asymmetry delivers a measured 0.03-0.05 at coaching-plausible thresholds and reaches 0.212-0.273. Lowering `settled_minimum_margin` toward 12, or `settled_leading_safety` toward 1.8, would close more of it — and both would put the rule inside genuinely competitive games, which the owner ruling forbids |
| **Blowout 8-18%, the other three levels** | **Met** | High school 0.1300, college 0.1700, overseas 0.1550 |
| **Games decided by five or fewer, 22-34%** | **Met at all five levels** | 0.2200-0.2700. It is marginal on the two 500-game population ranges (0.2060, 0.2220) and is reported as marginal |
| **Even-team home win rate 53-56%** | **Currently failing because implementation is incomplete** | `home_environment_shot_bonus` is 0.006 against an environment of 0.5, worth about 0.3 points a game where the band needs about 2.1. §5.11 measured the cause; raising it is a one-line change inside an existing safe range and was out of scope for both that task and this one |

No target is classified "possible but requires prohibited rubber-banding", and none is classified "target itself is unsupported" — the bands are all defensible descriptions of *some* league; the question is which league, and at what possession economy.

#### The proposed amendment

Every figure in the "achievable" column is a measurement on the untouched range 350,000-350,399 at 400 games, with the two 500-game validation ranges quoted for top domestic. Every proposed band is **simulation-derived**.

| Target | Current band | Level | Measured, after | Achievable range | **Proposed band** |
| --- | --- | --- | ---: | --- | --- |
| Overtime | 4-8%, universal | High school | 0.0425 | 0.03-0.05 | **3-6%** |
| | | College | 0.0100 | 0.01-0.03 | **1-4%** |
| | | Development | 0.0225 | 0.01-0.04 | **1-4%** |
| | | Overseas | 0.0250 | 0.01-0.04 | **1-4%** |
| | | Top domestic | 0.0175 | 0.012-0.030 | **1-4%** |
| Decided by ≤5 | 22-34%, universal | all five | 0.2200-0.2700 | 0.19-0.30 | **20-34%, universal (unchanged band, widened floor)** |
| Decided by ≥20 | 8-18%, competition-dependent | High school | 0.1300 | 0.11-0.16 | **8-18%** (unchanged) |
| | | College | 0.1700 | 0.14-0.20 | **10-22%** |
| | | Overseas | 0.1550 | 0.13-0.19 | **10-22%** |
| | | Development | 0.2450 | 0.21-0.28 | **16-30%** |
| | | Top domestic | 0.2725 | 0.212-0.273 | **16-30%** |
| Even-team home win | 53-56% | all five | 0.5200-0.5540 | not measured under a corrected home environment | **unchanged**; the failure is an unfinished implementation, not an unsupported target |

#### Why the bands separate by competition, in the engine's own arithmetic

§14.2's blowout band is already labelled "competition-dependent" and has never been given competition-dependent numbers. The dependence is not a preference; it is `sigma_margin = sqrt(2 · n · sigma_possession^2)` and it is measured:

| Level | Possessions per team-game | Points per possession | Margin SD, after | Blowout share, after |
| --- | ---: | ---: | ---: | ---: |
| High school | 68.60 | 0.9581 | 13.40 | 0.1300 |
| College | 70.38 | 1.0453 | 14.00 | 0.1700 |
| Overseas | 74.34 | 1.1108 | 13.41 | 0.1550 |
| Development | 94.31 | 1.1078 | 17.92 | 0.2450 |
| Top domestic | 100.31 | 1.1809 | 17.73 | 0.2725 |

A game with half again as many possessions, each worth a fifth more, has a margin distribution about a third wider. §14.1 *sets* those possession counts and those efficiencies, per competition, and locks them. A universal §14.2 blowout band therefore asks five different leagues to produce the same tail from deliberately different economies. The two bands are describing incompatible things, and the incompatibility is in the specification rather than in the engine.

The overtime band is a separate argument and a stronger one. The probability of an exactly level score is bounded above by the margin density at zero, which no legitimate mechanism raises without collapsing the dispersion to a value no basketball league has. §5.11's replay model, extended here, reaches 0.0334 at a margin standard deviation of 9.90. **4% is not reachable at any dispersion this scoring model can produce.**

#### External benchmarks

**None were consulted, and the proposal is therefore labelled simulation-derived and provisional.**

This is a deliberate refusal rather than an omission. This environment has no access to an authoritative primary source for league game-shape statistics — an official league statistics service, or a published dataset with a stated methodology — and a figure recalled from training or taken from an unverifiable secondary source is exactly the invented external benchmark the brief forbids. Quoting one would make the proposal look better sourced than it is.

To convert this proposal from provisional to benchmarked, an owner would need, for each comparable competition and a stated span of seasons:

1. **Overtime rate** — games reaching at least one overtime period, divided by games played. Definition must state whether abandoned and forfeited games are excluded.
2. **Margin distribution** — the share of games decided by five or fewer and by twenty or more, on final score including overtime, with the same tie-handling this engine uses.
3. **Possessions per team-game and points per possession**, on a stated possession definition, so the benchmark can be read against §14.1 rather than beside it.
4. **Home win rate** for evenly matched teams, or a rating-adjusted equivalent, since a raw home win rate confounds home advantage with schedule strength.

Without items 3 and 4 a benchmark cannot be compared to this engine at all: a league's blowout rate is a function of its possession economy and its competitive balance, and quoting one without the other two is how a target gets set to a number no engine with these §14.1 bands could ever produce.

#### Three quantified options

**Option 1 — Preserve the current targets and build the additional authorised system they require.**

What it needs: a fuller end-of-regulation model. The overtime band is unreachable because too few games arrive at the final possession within one score, and those that do resolve with too little structure. The missing system is the deliberate endgame: two-for-one possession management, fouling while ahead by three, timeout-to-advance, and designed last-possession plays. All four are legitimate coaching, all four are in `SIMULATION_SPEC.md`'s scope, and none exists.

Quantified: the engine's one-possession rate (≤3 points) is 0.100-0.144 and its tie rate is 0.012-0.030. To reach a 4% tie rate the endgame would have to convert roughly **30% of one-score finishes into exact ties**, against a current conversion near 20%. That is a large but not absurd target for a system built for it. Blowout share would additionally need the leading-team penalty raised from 0.03-0.05 to 0.12 by some mechanism not yet identified.

Cost: a substantial new subsystem, its own calibration, its own no-comeback-script suite, and Stage 4 stays open for it. Benefit: no locked target moves.

**Option 2 — Adopt competition-specific §14.2 bands.**

What it needs: the table above, written into §14.2, and a note that the blowout and overtime bands are functions of §14.1's possession economy.

Quantified: with the proposed bands, all five competitions pass blowout, close-game and overtime immediately on the measured evidence, and the only remaining §14.2 failure is the home win rate, whose cause is already measured and whose fix is one line. §14.1 is unaffected.

Cost: two locked targets move, and they move to fit a measurement — which is the thing this project's rules exist to prevent. The defence is that §14.2 already says "competition-dependent" for the blowout band and has never had competition-dependent numbers, and that the overtime band is not reachable by any legal engine rather than merely unreached by this one. Benefit: the specification stops asking five economies for one tail.

**Option 3 — Accept a deliberately different LeagueBound game-shape identity.**

What it needs: a ruling that LeagueBound's basketball is higher-variance than the leagues §14.2 was written from, and that its game shape is a design property rather than a fidelity target. §14.2's blowout and overtime bands become *informational* — measured and published every run, judged against nothing — while §14.1 stays locked and judged.

Quantified: nothing changes in the engine. Every §14.2 figure in this document stands as the identity: blowouts 13-27% by level, overtime 1-4%, close games 22-27%.

Cost: the project loses its only external anchor on game shape, and a future regression that widened the margin further would have nothing to fail against. Benefit: no new subsystem, no moved target, and honest labelling.

#### Recommendation

**Option 2 for overtime, unconditionally.** The 4-8% band is not reachable by any mechanism this engine could legitimately contain under §14.1's scoring model, and no amount of further work changes that; keeping it costs a permanent known failure that carries no information. The proposed 1-4% and 3-6% bands are what the possession economy supports.

**Option 2 for the blowout band as well, but only as far as the arithmetic requires** — 16-30% for the two high-possession competitions, 10-22% for the two middle ones, unchanged at high school. Option 1's endgame system is worth building for its own sake and would improve the overtime rate, but it should be commissioned as basketball rather than as a way of hitting a number, and it will not close the blowout gap at all.

**Option 3 is not recommended.** Making the bands informational removes the only thing that would catch a future regression in game shape, and the measurements in this document exist precisely because the bands were judged.

This recommendation is not enacted. §14.2 is unchanged in `BALANCE_SPEC.md`, every report in this document is still judged against the current bands, and the failures are still recorded as failures.

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
