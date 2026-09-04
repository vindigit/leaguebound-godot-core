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

**Stage 4 is not complete.** All five §8.4 career-peak bands now measure inside their locked targets, and two mandatory reports remain unimplemented. The two projected-peak failures are corrected and pass with interior margin on independent validation ranges (§5.7); the §8.4 rare-generational band is corrected and passes on two further untouched ranges (§5.8); and §5.9 closes that milestone by recording the §9.5 owner ruling, enforcing its 20% bound structurally, repairing a parse gate that could not fail, and correcting an AP figure that counted rating points. §5.10 diagnoses the §14.2 score-margin failure to its mechanism, corrects two real defects — a calibration fixture that manufactured its own mismatches and a missing §18.2 rotation pressure — and moves points per possession inside its band. §5.11 then tests §5.10's own premise, which was that the two teams' scoring is uncorrelated, and finds it true of the engine and false of basketball: three mechanisms the specification already authorised — score-and-clock game management, end-of-regulation possession strategy, and coaching timeouts — were structurally absent, and implementing them moves the final margin's variance by a sixth through coaching alone, with no probability touched. **§14.2's close-game share now passes at all five competition levels and all three dispersion targets pass at high school**, against three of fifteen before. §5.12 then implements the asymmetric garbage-time rotation threshold the owner authorised on 2026-08-20 — a coach protecting a safe lead rests his starters before a coach facing the same deficit concedes — as a possession-based safety measure with a `GARBAGE_TIME` ledger event and no probability anywhere. **Blowout share falls at all five levels and now passes at three; high school passes every one of its fifteen judged metrics.** §14.1 is unmoved to the fourth decimal and no golden hash changed. §5.13 is the resulting owner-decision package: the remaining §14.2 incompatibility is classified per target, an amendment is proposed with competition-specific bands, and three costed options are set out. **No target was changed and no proposal is enacted.** No Stage 4 result is certified, and §6.4 explains why none can be produced without CI hardware. The full gate inventory is §5.6. §5.25 then builds the four systems §5.13's Option 1 named as missing — two-for-one clock management, a leading-by-three foul, timeout-to-advance, and a designed final possession — plus three requested alongside them, under a 2026-09-01 owner ruling scoped to college and top domestic. Every decision is structurally proven never to touch a shot, free-throw, or contact probability, and reachable in real games. **The 200-game-per-point measurement this environment can run does not confidently show either competition's overtime rate moving into the §14.2 band, and does not regress anything it touched** — college's field-goal percentage, both competitions' already-measured blowout and close-game figures, and the §5.19 home-court result are each confirmed unmoved on the same ranges before and after.

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
- The `GameStakes` three-tier contract, `MatchInput.stakes` defaulted to `REGULAR`, `StakesPolicy` and the four coaching decisions that read it, the matched stakes diagnostic runner, and the focused scripted-drama audit (§5.14). **No ruleset version changed and no golden ledger moved**: the regular-season path is byte-identical, which is the point of the default.
- The §11.3 passer-to-shot event chain: `PassCreation`, the corrected pass beneficiary, the creator stamped on every shot attempt and make, the catch-and-shoot and spot-up continuations, the competition-scoped credited-assist rule, the restored §14.3 conditional baseline, the assist-chain audit and its diagnostics runner, and the `simulation-v6-pass-creation` ruleset the regenerated golden ledgers belong to (§5.15).
- `EndgameStrategy`'s two-for-one clock management, hold-for-the-final-shot, quick-two-vs-tying-three preference past `GameManagement`'s own window, a designed final-possession play, a leading-by-three foul (`FoulType.Value.LEADING_PROTECT`), an intentional final free-throw miss, and timeout-to-advance (`CompetitionRuleProfile.timeout_advance_permitted`), first built under `simulation-v9-endgame-strategy`, corrected through v10/v11 (§5.25–§5.27), and instrumented and deadline-corrected under `simulation-v12-endgame-ledger-and-resource-contract` (§5.29), and joined by the opening-state clock and location contract of `simulation-v13-opening-clock-and-location-contract` (§5.30). The v9 measurements in §5.25 remain pre-correction diagnostics. **Measured, not certified:** the repertoire is real and auditable, but no version yet closes the overtime band.

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
- A three-tier `GameStakes` context on the match input, defaulted to `REGULAR`, read by exactly four coaching decisions and by no resolver (§5.14).

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
- A matched game-stakes diagnostic that plays identical fixtures at identical seeds under all three stakes tiers, in population and mirror fixture modes, and judges no band (§5.14).

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
| Competition §14.1 bands | ~~Substantially converged, not certified~~ **Top-domestic points per possession corrected (§5.20):** 1.1694 ±0.0037 pooled over two untouched 1,000-game ranges against 1.08–1.18, from 1.1847. Zero §14.1 verdict changes at any of the five levels. **College and high-school field-goal percentage re-examined (§5.22): high school does not reproduce — 0.3888 ±0.0018 pooled over two untouched 1,000-game ranges with the interval reaching its 0.390 floor — and college reproduces at 0.4124 against 0.420 with no production defect behind it.** Measured, not certified |
| Assist percentage | ~~**Fail:** 48.15% top domestic at 400 games against 52–72%~~ **Corrected (§5.15):** 58.9% and 58.2% top domestic on two untouched 100-game validation ranges, and inside the band at all five competition levels on both. Measured, not certified. |
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
| GdUnit4 suite | **Structural** | 410 cases, 39 suites, 0 failures |
| `tests/run_all.gd` acceptance | **Structural** | PASS |
| Parse check under warnings-as-errors | **Structural** | 216 scripts, 0 failures |
| Simulation smoke diagnostics | **Structural** | Invariants PASS under the `simulation-v6-pass-creation` ruleset |
| Golden ledgers and determinism | **Structural** | Six scenarios. Regenerated under `simulation-v6-pass-creation` (§5.15): all six hashes moved and exactly one seed did, and the blast radius was proved by diffing every scenario's event stream to its first divergent event. Unchanged by `simulation-v5-garbage-time` (§5.12); regenerated once before that under `simulation-v4-management` (§5.11) |
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
| Competition §14.1 bands, top domestic | **Measured below requirement** | Re-measured at 100 games on each of two untouched ranges under `simulation-v6-pass-creation` (§5.15). **Ten of eleven pass on Validation A and eleven of eleven on Validation B**: assist percentage is corrected to 0.5890 and 0.5817 and now passes; points per possession is 1.1809 against a 1.18 ceiling on A and 1.173 on B |
| Competition §14.1 bands, other four | **Measured below requirement** | Re-measured at 100 games each on two untouched ranges under `simulation-v6-pass-creation` (§5.15). High school 10/10, college 9/10, development 10/10, overseas 10/10; assist percentage passes at all four where it failed at three, and college field-goal percentage is the only remaining failure below top domestic |
| **§14.1 top-domestic assist percentage** | **Failed** | 0.4820 against 0.52-0.72 at 400 games on the untouched range 350,000-350,399, against 0.4817 for the same games before the settled rotation (§5.12). Measurement only; no assist parameter has ever been tuned. It also fails at development and overseas |
| §14.1 top-domestic points per possession | **Measured below requirement; on its ceiling** | 1.1691 on 60,000-60,399 (§5.11) and **1.1809 on 350,000-350,399** against a 1.18 ceiling — where the same games measure 1.1844 *before* the settled rotation, which moved it down (§5.12). The range-to-range spread straddles the ceiling and no aggregate tuning was done in either direction |
| **§14.2 blowout share** | **Failed at two of five levels** | **Improved again (§5.12).** High school 0.1300 ✓, college 0.1700 ✓ and overseas 0.1550 ✓ pass; development 0.2450 and top domestic 0.2725 do not. 0.2320 and 0.2120 on two untouched 500-game validation ranges, and 0.1883 pooled over 600 even-team games. §5.13 proposes competition-specific bands and does not enact them |
| **§14.2 close-game share** | **Passes at all five competition levels** | 0.2700 / 0.2700 / 0.2200 / 0.2700 / 0.2475 against 0.22-0.34 on the untouched range 350,000-350,399 (§5.12). The two 500-game population validation ranges sit at 0.2220 and 0.2060, so the pass is marginal and is reported as marginal |
| **§14.2 overtime rate** | **Failed at four of five levels** | High school 0.0425 ✓; college 0.0100, development 0.0225, overseas 0.0250, top domestic 0.0175. Unmoved by the settled rotation, as expected. **Unreachable by any dispersion mechanism under the current possession/scoring model (§5.11, §5.13):** the replay model's tie rate never reaches 0.04 even at a margin standard deviation of 9.9. §5.13 classifies this narrowly and proposes a band |
| **§14.2 home win rate** | **Measured below requirement; five-level pool inside the band, Development below it on the pooled two-range v8 measurement** | **Corrected (§5.17), re-measured on the paired estimator (§5.18), re-measured again after the contest correction (§5.20 §13, §5.21).** Under `v7` the five-level pool was **0.5432 ±0.0125** and **0.5360 ±0.0122** on two untouched ranges. Under `v8` the five-level pool on Validation C is **0.5344 ±0.0127**, still inside 0.53–0.56 (§5.20 §13). **Development** is the level outside it: **0.5160** on Validation C, **0.5400** on Validation D, **0.5280 ±0.0206 pooled over 500 matched fixtures** against a 0.530 floor, with the pooled interval covering the band and the two ranges statistically indistinguishable (§5.21). The §17.4 cap holds everywhere. Not certified: 1,500 complete Development games against §27.1's 100,000 per competition |
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

### 5.14 The engine learns what a game is worth, and nothing else about the occasion

Status: **A minimal game-stakes contract is implemented, tested, mutation-checked, and measured at two levels on matched fixtures. `REGULAR` is the default and every committed golden ledger is byte-identical. The directional overtime hypothesis is reported honestly against what was measured; nothing was tuned to produce it. Full five-level stakes calibration remains deferred until real schedules and postseason matchups exist.**

This is a domain-and-behaviour task, not a calibration phase. No §14.1 or §14.2 number moved, no band was widened, and no tunable outside the five new ones was touched.

#### The contract

`GameStakes` is three tiers and nothing else:

| Tier | Meaning |
| --- | --- |
| `REGULAR` | an ordinary regular-season game |
| `POSTSEASON` | a playoff or tournament game that is not itself a championship or a win-or-go-home game |
| `CHAMPIONSHIP_OR_ELIMINATION` | Finals games, championship games, Final Four games, and any other win-or-go-home contest |

`MatchInput.stakes` carries it as the last constructor argument, defaulted to `REGULAR`. Three deliberately absent things define the contract as much as the three present ones:

- **No competition, round, league, team, or rivalry appears anywhere in it.** The engine is handed a tier and learns nothing else about the occasion — not that it is game 7, not which series, not who is playing.
- **No fourth tier and no numeric "importance" scale.** A scale invites interpolation and interpolation invites a per-tournament exception.
- **No scheduling dependency.** There is no schedule, bracket, postseason, or career layer in this repository, and this does not wait for one.

**Mapping real game metadata onto a tier is the future scheduling layer's responsibility, not the engine's.** When a schedule exists it will know that a fixture is a conference final and will hand the engine `CHAMPIONSHIP_OR_ELIMINATION`; the engine will still know nothing else. That boundary is the reason the enum is coarse: a tier the engine cannot decompose is a tier that cannot acquire special cases.

#### The default is load-bearing, and "byte-identical" is the evidence

Every stakes effect has the same shape:

```text
effect = base * (1 + step * tier)
```

`tier` is 0, 1, or 2. `StakesPolicy.factor` returns literal `1.0` on the `tier <= 0` branch rather than computing `1 + step * 0`, so a regular-season game is not approximately unchanged — it executes the same floating-point arithmetic in the same order it executed before this input existed.

The check that matters: **all six committed golden ledgers hash identically after the change**, and `tools/golden_ledger_harness.gd` rewrote `tests/golden/match_golden_hashes.json` to a byte-identical file. No hash was regenerated, and none needed to be.

| Scenario | Hash | Score |
| --- | --- | --- |
| `regulation` | `2e2f34ade6426bbe…4706145b` | 40-34 |
| `overtime` | `6bb5a1e491a33e4f…eef8200e` | 17-23 |
| `offensive_rebound` | `af56368b06a8dd42…e702442c8` | 41-28 |
| `foul_free_throw` | `da4fd07e710b82aa…42c5f461` | 18-14 |
| `substitution_foul_out` | `e3e19f4079ec3f9b…c391aa71` | 32-25 |
| `late_game` | `649c38d8fc775659…7e001e8070` | 22-12 |

#### What a tier is allowed to change, and what it actually changes

`StakesPolicy` is the only place a tier becomes a number, and four coaching decisions read it. They are the four the owner's list names, and the list of authorised effects is deliberately *not* exhausted: pace and clock strategy, intentional-foul strategy, and the garbage-time release threshold were all authorised and all left alone, because the smallest coherent set that establishes the contract is smaller than the set that is permitted.

| # | Decision | Existing system extended | Tunable | Regular | Postseason | Championship |
| --- | --- | --- | --- | ---: | ---: | ---: |
| 1 | Rotation tightness and bench depth | `RotationResolver._departure_reason`, the §18.1 planned-minutes branch | `stakes_rotation_tightness_step` = 0.10 | ×1.00 | ×1.10 | ×1.20 |
| 2 | Timeout reservation | `MatchSession._consider_timeout`, the §4/§5 run-stopping branch | `stakes_timeout_reserve_step` = 0.35 | 90.0 s | 121.5 s | 153.0 s |
| 3 | Settled-rotation patience | `GarbageTimeRule.entry_threshold` | `stakes_settled_patience_step` = 0.15 | 2.60 / 4.20 σ | 2.99 / 4.83 σ | 3.38 / 5.46 σ |
| 4a | Final-possession window | `GameManagement.endgame_multiplier` | `stakes_endgame_window_step` = 0.50 | 32 s | 48 s | 64 s |
| 4b | Final-possession conviction | `GameManagement.endgame_multiplier` | `stakes_endgame_conviction_step` = 0.25 | ×1.00 | ×1.25 | ×1.50 |

Every one of the five is a Gate B0 tunable with a unit and a safe range, and every product is clamped twice — once by `StakesPolicy.MAXIMUM_FACTOR` (2.0) and again by the bound the base value already lived under. A profile that set every step to a thousand produces a bounded, playable, wrong game rather than an unbounded one, and `test_no_step_can_push_a_factor_past_the_declared_maximum` asserts it.

#### What a tier may never do

The forbidden list, and how each prohibition is enforced rather than promised:

| Forbidden | How it is structurally impossible | Where it is proven |
| --- | --- | --- |
| Change ratings or derived capabilities | `CapabilityCalculator` has no stakes parameter; `RatingsProfile` is not reachable from `StakesPolicy` | `test_no_rating_or_capability_moves_with_the_stakes` — all 24 capabilities, both rosters, at rest and fatigued, in and out of the settled rotation |
| Change shot accuracy | No resolver reads a tier; a search of `src/` enforces it | `test_the_same_shot_resolves_identically_at_every_tier`, `test_only_the_declared_consumers_read_a_stakes_tier` |
| Change turnover, foul or rebound probability without a selected action | Same | `test_turnover_foul_and_rebound_resolution_are_identical_at_every_tier` |
| Improve the trailing team / weaken the leading team | A tier is a property of the *match*, applied identically to both sides; it has no team parameter to discriminate through | `test_reversing_the_scoreboard_reverses_the_policy_at_every_tier` |
| Clamp the score or margin | Nothing in the change touches `MatchStateReducer`'s scoring path | `test_championship_games_still_blow_out_and_still_reach_garbage_time` |
| Force a make, miss, turnover, foul, tie or overtime | Nothing reaches a resolver's outcome; the four outputs are two thresholds, one duration and two multipliers on a candidate weight | The three probability rows above |
| Reroll an outcome | No tier is read after a draw; determinism holds at every tier and across all three executors | `test_every_tier_reproduces_byte_for_byte_and_across_executors` |
| Read the eventual winner or the final result | The policy's inputs are a balance profile and an integer | `test_strength_identity_and_the_expected_winner_do_not_reach_the_policy` — both rosters moved ±30 rating points, decisions unchanged |
| Favour a team identity | Same; and the mirrored fixture swaps the shirts | `test_mirroring_home_and_away_mirrors_the_whole_game` |
| Add a momentum, clutch, comeback, excitement or drama multiplier | None exists anywhere in `src/`; see the audit below | Audit §"no drama engine exists" |
| Guarantee a championship stays close | Championship blowouts and championship garbage time both occur, measured | `test_championship_games_still_blow_out_and_still_reach_garbage_time` |

The principle, stated once: **script the circumstances, never the result.**

#### Garbage time keeps its guards

The accepted asymmetric settled-rotation system of §5.12 is retained unchanged. A tier scales *how much of the same evidence a coach demands*; it does not change the evidence, remove a guard, or create an exemption.

| Constraint | Status | Where |
| --- | --- | --- |
| Mathematical safety remains part of entry | `safety()` is untouched — same formula, same inputs, shared by both teams | `GarbageTimeRule.safety` |
| Truly decided championship games still reach garbage time | Safety grows without bound as the clock runs out; the multiplier is finite and clamped at 2.0 | `test_high_stakes_settle_later_but_still_settle` (a 40-point championship game settles) |
| High stakes cannot keep starters active indefinitely | Same; plus the coaching floor and the one-pair guard are untouched | `test_the_settled_guards_survive_the_highest_tier` |
| Reversing the scoreboard reverses behaviour | `role_for` is untouched; both thresholds scale by the same factor so the roles keep their gap | `test_reversing_the_scoreboard_reverses_the_policy_at_every_tier`, `test_a_settled_championship_coach_is_released_when_the_lead_is_cut` |
| Equal states treat home and away identically | Stakes live on the match, not on a team | `test_mirroring_home_and_away_mirrors_the_whole_game` |
| Stakes cannot alter possession resolution | No resolver reads a tier | the search test |

##### The "false positive within six points" metric, defined exactly

The metric `garbage.false_positive_two_possession` has been quoted since §5.12 without its denominator being written down. It is:

```text
false_positive_share(6.0) = |{ activated games with |final margin| <= 6 }| / |{ activated games }|
```

- **Denominator — "activated games".** A game in which **either** coach entered the settled rotation at least once, read from `GARBAGE_TIME` events carrying `detail_id == "entered"`. Games that never activated are not in the denominator at all, so the metric is conditional on activation and is *not* a share of all games. `ScoringCovariance.activated_rows()` is the filter.
- **Numerator — what makes an activation "false".** The **final** absolute margin of the completed game, including overtime, is six points or fewer. Six is one two-possession swing: the smallest margin that a single trip and a stop can erase, and therefore the smallest final margin at which the claim "this game was over" is retrospectively false.
- **Unit of counting is the game, not the activation.** A game with four entries and three releases counts once.
- **It is a retrospective test, not a decision test.** The rule cannot see the final margin; the metric can. A non-zero value is not automatically a defect — a genuine comeback the trailing team earned makes a correct activation look false — but a large one means the state is being entered on games that were not over. The ten-point variant (`garbage.false_positive_ten_points`) is the same construction at a wider threshold.
- **It is measured, never judged.** Both variants are `CalibrationMetric.raw`; neither carries a band.


#### Focused scripted-drama audit

Every production mechanism in `src/` that reads score, margin, clock, period, run length, home/away status, an expected winner, a team or player identity, a stakes tier, or a realized outcome. The audit is deliberately narrow: it is a search for hidden outcome correction in the match engine, not a career or progression review.

Two columns matter more than the classification. **"Reads"** is what the mechanism is allowed to see. **"Changes"** distinguishes a *decision* — which legal action a coach or player selects, or who is on the floor — from an *execution probability* — the chance a selected action succeeds. A mechanism that reads the scoreboard and changes a decision is coaching. A mechanism that reads the scoreboard and changes an execution probability is the thing this audit exists to find.

| Mechanism | Reads | Changes | Classification |
| --- | --- | --- | --- |
| `GameManagement.pressure` / `pressure_for` | own signed margin, clock, period, realized pace, rules | nothing directly; produces one intensity in [0,1] | **1. Legitimate basketball strategy** |
| `GameManagement.pace_multiplier` | pressure, sign of own margin | **decision** — how much clock a possession consumes | **1. Legitimate.** No probability. The protect/chase gains differ in size because a possession has a physical floor |
| `GameManagement.action_multiplier_at` | pressure, sign of own margin, action family, zone | **decision** — one candidate's §10.3 score-and-clock weight | **1. Legitimate** |
| `GameManagement.crash_multiplier` | pressure, sign of own margin | **decision, sampled** — the share of players sent to the offensive glass | **1. Legitimate.** The only place a coaching decision is expressed as a sampled share rather than a candidate weight, so it is worth being exact: it changes *how often a player crashes*, and changes nothing about whether a player who crashed wins the ball. The rebound contest itself never sees it |
| `GameManagement.endgame_multiplier` (tie-seeking) | period, regulation remaining, own deficit, zone, stakes | **decision** — prefers the shot value that levels the game | **1. Legitimate.** Symmetric: the deficit selects the shot value and either team can hold it |
| `GarbageTimeRule.safety` | absolute margin, realized pace, rules | nothing directly; one number shared by both teams | **1. Legitimate** |
| `GarbageTimeRule.entry_threshold` / `should_enter` / `should_leave` | own signed margin, safety, clock, rules, stakes | **decision** — the settled `Mode` | **1. Legitimate.** Asymmetric by *role*, never by team. Swap the rosters and the behaviours swap |
| `RotationResolver._departure_reason`, settled branch | `TeamMatchState.settled_mode` (reduced from the ledger), bench depth | **decision** — who comes off | **1. Legitimate** |
| `RotationResolver._departure_reason`, planned-minutes branch | realized vs planned minute share, stint, stakes | **decision** — who comes off | **1. Legitimate** |
| `RotationResolver._is_closing_time` | period, clock, settled mode | **decision** — closing-lineup preference on a check-in | **1. Legitimate** |
| `MatchSession._consider_timeout` | opponent run length, timeouts remaining, regulation remaining, stakes | **decision** — whether a timeout is called | **1. Legitimate.** Its effect is rest, applied to **everybody on the floor on both teams** (`MatchStateReducer._apply_timeout`), so it cannot be an advantage for the side that called it |
| `FoulResolver.resolve_intentional_foul` | period, game clock, defence's own deficit (1–6 points) | **decision** — selects the deliberate foul as the action | **1. Legitimate.** It does raise the foul rate in that window, and that is the explicitly-selected-action carve-out working as intended: a coach chose to foul. It is available only to the trailing side because only the trailing side has a reason, which is basketball rather than assistance — the foul stops the clock and gives the *leading* team free throws |
| `FreeThrowResolver.probability`, §20.1 pressure | `is_late_game()` and \|own margin\| ≤ 5 | **execution probability** — subtracts up to `clock_desperation_penalty_max × 0.35 × (1 − composure)` | **1. Legitimate, and the one to look at hardest.** It is the only score-and-clock read in the engine that moves an execution probability. Three properties keep it honest: it is **symmetric in the sign of the margin** (a late close game, not a late deficit), it only ever **reduces** the probability, and it is scaled by the shooter's **own Offensive IQ** so it is a property of the player rather than of the situation's desired outcome. It cannot help a trailing team and it cannot hurt a leading one specifically |
| `ShotResolver._clock_desperation` | the **shot** clock only | **execution probability** — a rushed shot is worse | **1. Legitimate.** Reads no score, no game clock, no period |
| `ShotResolver` home bonus | `input.is_home(offense)`, `home_environment` | **execution probability** — up to +0.006 | **1. Legitimate (§19.4).** Keyed on the shirt, not on a team identity; bounded; never conditioned on score |
| `FreeThrowResolver` home penalty | same | **execution probability** — up to −0.006 for the away side | **1. Legitimate (§19.4)** |
| `FoulResolver._contact_probability` home term | same | **execution probability** — ±1% multiplicative on the contact base | **1. Legitimate (§19.4)** |
| `MatchStateReducer` | events only | state | **1. Legitimate.** No score-conditioned branch exists; the only score comparison in the whole scoring path is `PeriodController.match_is_complete`, which is the overtime rule |
| `PeriodController.match_is_complete` | clock, period, whether the score is level | **decision** — whether another period is played | **1. Legitimate.** This is the rulebook |
| `StakesPolicy` (new) | a balance profile and an integer tier | **decision** — four thresholds | **1. Legitimate** |

##### Findings

**No mechanism was classified 2, 3, 4, or 5.** There is no presentation-only behaviour in `src/` — the repository has no presentation layer at all. There is no calibration-fixture behaviour in production code — the fixtures live in `calibration/` and `tests/` and nothing in `src/` knows they exist. Nothing was classified suspicious, and **no hidden rubber-banding was found.**

**No drama engine exists.** A case-insensitive search of `src/` for *momentum*, *clutch*, *comeback*, *excitement*, *drama*, *upset*, *rubber*, *hot hand*, and *streak* returns four hits and all four are inert:

- `GameManagement`'s class comment, arguing that it is *not* rubber-banding;
- `GameManagement.endgame_multiplier`'s comment, citing §20.2 clutch behaviour as the source of the tie-seeking rule;
- `TendencySlider.Value.DEFER_SEEK_CLUTCH` — a declared per-player tendency slider that **no production code reads**. It is a name in an enum and nothing consumes it. Recorded here because a slider called "clutch" is exactly what an audit should chase down, and the answer is that it is unimplemented;
- the run-length counter in `MatchSession`, which feeds the timeout decision and nothing else.

`ScoringCovariance`'s *comeback* and *streak* references are all in `calibration/` — they are measurements of the engine, not inputs to it.

**Expected winner and team strength are structurally unreachable from the match engine.** `TeamStrengthIndex` — the only thing in the repository that computes a pregame expectation — lives in `calibration/harness/` and has **zero references** from `src/` or `tests/`. No resolver, no coaching rule, and no rotation reads a rating aggregate, a seed, or a favourite.

**Rare-generational treatment does not reach the simulation.** It appears in `career_opportunity_condition.gd` and `progression_profile.gd` only — career progression and its configuration. No file under `src/domain/basketball/simulation/` references it, and nothing in it reacts to an in-progress game or a realized result. Per the task's instruction it is mentioned only to record that finding; the career audit is out of scope and was not performed.

**One asymmetry between the two shirts is real, authorised, and worth stating plainly:** §19.4 home environment changes three execution probabilities. It is bounded (≤0.006 on a shot, ≤1% multiplicative on contact), keyed on the home/away *slot* rather than on any team identity, and never conditioned on the score. It is also the reason a mirrored fixture is not exactly symmetric unless `home_environment` is set to zero — which cost one iteration of the stakes mirror test to discover, and is recorded above.


#### Tests

`tests/simulation/test_game_stakes.gd` — 22 cases. The thirteen required proofs and their homes:

| # | Required proof | Case |
| --- | --- | --- |
| 1 | Missing context defaults to `REGULAR` | `test_a_match_built_without_stakes_is_a_regular_season_game` (constructor default, fixture factory, calibration catalog, and all six golden scenarios) |
| 2 | Regular-season behaviour is backward compatible | `test_the_regular_tier_multiplies_every_effect_by_exactly_one`, `test_the_default_and_an_explicit_regular_tier_are_the_same_game` |
| 3 | Identical context, inputs and seed stay deterministic | `test_every_tier_reproduces_byte_for_byte_and_across_executors` (all three tiers, plus Play/Sim/Skip parity at the highest) |
| 4 | Stakes affect only authorised coaching decisions | `test_the_four_authorized_thresholds_move_and_stay_bounded`, `test_only_the_declared_consumers_read_a_stakes_tier` (searches every `.gd` under `src/` and fails on an eighth reader) |
| 5 | Shot probability and resolution identical across tiers | `test_the_same_shot_resolves_identically_at_every_tier` (probability, outcome, and draws consumed), `test_turnover_foul_and_rebound_resolution_are_identical_at_every_tier` |
| 6 | Capability resolution identical across tiers | `test_no_rating_or_capability_moves_with_the_stakes` (24 capabilities × 20 players × fatigued × settled) |
| 7 | Reversing the scoreboard reverses leading/trailing policy | `test_reversing_the_scoreboard_reverses_the_policy_at_every_tier` |
| 8 | Mirroring home and away mirrors behaviour | `test_mirroring_home_and_away_mirrors_the_whole_game` (three seeds × three tiers, asserted possession-by-possession) |
| 9 | Team identity and expected winner do not reach the policy | `test_strength_identity_and_the_expected_winner_do_not_reach_the_policy` (both rosters ±30 rating points) |
| 10 | Championship games still blow out and still reach garbage time | `test_championship_games_still_blow_out_and_still_reach_garbage_time` |
| 11 | Regular-season games still reach overtime | `test_regular_season_games_still_reach_overtime`, plus the standing `overtime` golden scenario |
| 12 | High-stakes entry is later but mathematically bounded | `test_high_stakes_settle_later_but_still_settle`, `test_the_settled_guards_survive_the_highest_tier`, `test_a_settled_championship_coach_is_released_when_the_lead_is_cut` |
| 13 | State transitions stay reducer-owned and ledger-explained | `test_state_transitions_stay_reducer_owned_at_the_highest_tier` |

Two further cases exist because a mutation asked for them: `test_no_step_can_push_a_factor_past_the_declared_maximum` and `test_the_endgame_window_changes_selection_and_never_resolution`.

#### Mutation battery

Eight mutations. Each was applied over a byte-exact backup **in an isolated git worktree at the committed implementation**, checked against `tests/run_all.gd` (which carries the six golden ledgers, determinism and Play/Sim parity) and three GdUnit4 guard suites — `test_game_stakes`, `test_garbage_time`, `test_score_margin` — then restored. `git status --porcelain` and `HEAD` were compared before and after every one, and every one restored byte-clean with `HEAD` unchanged.

| # | Mutation | Detected by |
| --- | --- | --- |
| 1 | Direct high-stakes accuracy boost — a tier added to the make probability | `test_the_same_shot_resolves_identically_at_every_tier`, `test_only_the_declared_consumers_read_a_stakes_tier` |
| 2 | Trailing-team capability boost — the side behind shoots better | `test_the_same_shot_keeps_its_probability_in_and_out_of_garbage_time`, `test_the_managed_window_changes_selection_and_not_resolution`, `test_identical_rosters_receive_the_same_rotation` |
| 3 | Forced late tie — a levelling shot inside 30 s cannot miss | **first pass: `run_all.gd` only.** After the test it named was written: `test_the_endgame_window_changes_selection_and_never_resolution` as well |
| 4 | Team-identity exception — one named roster is never settled on | 7 cases across two suites, including `test_reversing_the_scoreboard_reverses_the_policy_at_every_tier` and `test_the_leading_coach_settles_before_the_trailing_one` |
| 5 | Broken default-to-regular — a stakes-free match becomes a playoff | `run_all.gd` (golden ledgers) plus `test_a_match_built_without_stakes_is_a_regular_season_game` and three more |
| 6 | Home/away asymmetry — the home shirt settles on half the evidence | 8 cases, including `test_mirroring_home_and_away_mirrors_the_whole_game` |
| 7 | Removal of the stakes coaching distinction — every tier is a Tuesday | `test_the_four_authorized_thresholds_move_and_stay_bounded`, `test_higher_stakes_widen_and_sharpen_the_tie_seeking_window_only`, `test_high_stakes_settle_later_but_still_settle` |
| 8 | Bypass of garbage-time safety — the 18-point coaching floor removed | `run_all.gd` plus `test_the_settled_guards_survive_the_highest_tier`, `test_garbage_time_cannot_activate_in_a_close_game` and two more |

**Mutation 3 is the one worth recording.** It was detected on the first pass only by the committed golden ledgers. That is a real detection, and it is also the weaker kind: a golden hash says *something moved*, not that an execution probability was scripted. Nothing in the behavioural suite distinguished "the coach hunts the tying shot harder" from "the tying shot cannot miss", which is precisely the distinction this whole task is about. `test_the_endgame_window_changes_selection_and_never_resolution` was written to say the second thing — two boards differing only in regulation remaining, with shooter, defender, zone, contest, fatigue, shot clock and stream pinned, resolving to the identical probability, the identical outcome and the identical draw count — and the mutation was re-run against it and is now detected behaviourally.

#### Bounded diagnostic measurement

**BELOW CERTIFICATION REQUIREMENT.** `BALANCE_SPEC.md` §27.1 requires far larger samples. Nothing below certifies a band, nothing below is judged against one, and every metric the runner emits is `CalibrationMetric.raw`. Two levels only — College and Top Domestic — as scoped; the full five-level stakes calibration is deferred.

The design is **matched**: within one sample, the three tiers play the *identical* fixtures at the *identical* seeds. The three columns are one sample played three ways, so a column difference is the stakes tier rather than roster noise.

##### Seed ranges

New, and disjoint from every range in §5.7 through §5.13.

| Purpose | Variations | RNG seeds | Games per tier |
| --- | --- | --- | ---: |
| **Development** — the range the implementation was looked at on | 470,000-470,299 | 470,001-470,300 | 300 |
| **Validation — untouched** | 480,000-480,299 | 480,001-480,300 | 300 |
| **Mirror, zero pregame gap** | 480,000-480,249 | 480,001-480,250 | 250 |

No tuning range was needed, and none was used: the five step tunables were chosen from coaching plausibility before any range was run and **were not changed afterwards**. Nothing was fitted to the validation range or to the hypothesis.

##### College, matched

| Metric | Development: regular / postseason / championship | Validation: regular / postseason / championship |
| --- | --- | --- |
| Overtime rate | 0.0367 / 0.0167 / 0.0200 | 0.0333 / 0.0400 / 0.0333 |
| Close-game rate (≤5) | 0.3033 / 0.3033 / **0.2400** | 0.3000 / 0.3167 / **0.2333** |
| Blowout rate (≥20) | 0.1267 / 0.1333 / 0.1367 | 0.1433 / 0.1633 / 0.1633 |
| Margin SD | 13.093 / 13.185 / 13.676 | 13.114 / 14.064 / 14.812 |
| Points per possession | 1.0435 / 1.0469 / 1.0451 | 1.0446 / 1.0522 / 1.0524 |
| Possessions per team-game | 70.52 / 70.45 / 70.68 | 70.93 / 71.03 / 71.12 |
| Timeouts per game | 2.600 / 2.620 / 2.510 | 2.537 / 2.493 / 2.437 |
| Starter minute share | 0.6259 / 0.6343 / **0.7055** | 0.6231 / 0.6292 / **0.7022** |
| Top-player minutes | 27.94 / 28.63 / **33.42** | 28.04 / 28.66 / **33.40** |
| Garbage-time activation rate | 0.3333 / 0.3267 / 0.3267 | 0.3567 / 0.3433 / 0.3300 |
| Garbage-time releases per game | 0.3167 / 0.2433 / **0.2067** | 0.3200 / 0.2333 / **0.1400** |
| Comebacks after activation | 0.0000 / 0.0000 / 0.0000 | 0.0280 / 0.0000 / 0.0000 |
| Tie-seeking opportunities per game | 0.2467 / 0.2167 / 0.2167 | 0.2100 / 0.2233 / 0.1800 |
| Tie-seeking levelling share | 0.5405 / 0.4308 / 0.3846 | 0.4921 / 0.4328 / 0.5000 |
| Intentional fouls per game | 0.4700 / 0.4300 / 0.4533 | 0.5067 / 0.4667 / 0.4067 |

##### Top Domestic, matched

| Metric | Development: regular / postseason / championship | Validation: regular / postseason / championship |
| --- | --- | --- |
| Overtime rate | 0.0133 / 0.0367 / 0.0133 | 0.0300 / 0.0167 / 0.0300 |
| Close-game rate (≤5) | 0.2367 / 0.2267 / 0.2167 | 0.2133 / 0.1600 / 0.1967 |
| Blowout rate (≥20) | 0.2533 / 0.1867 / 0.2400 | 0.1867 / 0.2167 / 0.2800 |
| Margin SD | 17.066 / 15.433 / 16.849 | 15.613 / 16.201 / 17.935 |
| Points per possession | 1.1728 / 1.1762 / 1.1755 | 1.1782 / 1.1743 / 1.1735 |
| Possessions per team-game | 100.39 / 100.85 / 100.82 | 100.92 / 100.98 / 100.98 |
| Timeouts per game | 4.117 / 4.097 / 3.980 | 4.057 / 3.907 / 3.973 |
| Starter minute share | 0.6065 / 0.6436 / 0.6396 | 0.6122 / 0.6418 / 0.6387 |
| Top-player minutes | 33.13 / 35.52 / **40.57** | 33.25 / 35.30 / **40.43** |
| Garbage-time activation rate | 0.5000 / 0.4200 / **0.4100** | 0.4467 / 0.4333 / 0.4567 |
| Garbage-time releases per game | 0.4933 / 0.2933 / **0.2233** | 0.4400 / 0.3400 / **0.2000** |
| Comebacks after activation | 0.0000 / 0.0000 / 0.0000 | 0.0299 / 0.0000 / 0.0073 |
| Tie-seeking opportunities per game | 0.2167 / 0.2467 / 0.1933 | 0.2133 / 0.2267 / 0.1333 |
| Tie-seeking levelling share | 0.3538 / 0.5270 / 0.4655 | 0.4688 / 0.5147 / 0.5000 |
| Intentional fouls per game | 0.5133 / 0.5300 / 0.5100 | 0.6133 / 0.4967 / 0.4667 |

##### Pooled

Population is the four matched ranges above, 1,200 games per tier. Mirror is the two zero-pregame-gap ranges, 500 games per tier.

| Metric | Population reg / post / champ | Mirror reg / post / champ |
| --- | --- | --- |
| Overtime rate | 0.0283 / 0.0275 / 0.0242 | 0.0300 / 0.0380 / **0.0420** |
| Close-game rate | 0.2633 / 0.2517 / **0.2217** | 0.2980 / 0.2860 / 0.2900 |
| Blowout rate | 0.1775 / 0.1750 / 0.2050 | 0.1540 / 0.1520 / 0.1780 |
| Margin SD | 14.722 / 14.721 / 15.818 | 13.540 / 13.759 / 14.277 |
| Points per possession | 1.1098 / 1.1124 / 1.1116 | 1.1153 / 1.1116 / 1.1093 |
| Possessions per team-game | 85.69 / 85.83 / 85.90 | 85.84 / 86.06 / 86.23 |
| Starter minute share | 0.6169 / 0.6372 / 0.6715 | 0.6183 / 0.6392 / 0.6729 |
| Top-player minutes | 30.59 / 32.03 / 36.95 | 30.66 / 32.22 / 37.47 |
| Timeouts per game | 3.328 / 3.279 / 3.225 | 3.262 / 3.232 / 3.228 |
| Garbage activation rate | 0.4092 / 0.3808 / 0.3808 | 0.3660 / 0.3460 / 0.3420 |
| Garbage releases per game | 0.3925 / 0.2775 / 0.1925 | 0.3360 / 0.2580 / 0.1820 |
| Intentional fouls per game | 0.5258 / 0.4808 / 0.4592 | 0.4700 / 0.5480 / 0.5020 |

#### Did overtime increase? No, and the reason is worth having

**In the four matched population samples the hypothesised ordering does not appear, in any of them, and the pooled point estimate runs slightly the wrong way: 0.0283 → 0.0275 → 0.0242.** In the two matched mirror samples the ordering does appear pooled — 0.0300 → 0.0380 → 0.0420, monotone — and appears strictly in one of the two individually.

Neither result is statistically distinguishable from no effect. At an overtime rate near 3%, 1,200 games per tier carry a standard error near ±0.5 percentage points on each cell and 500 games near ±0.8; the pooled population difference is 0.6 standard errors and the pooled mirror difference is 1.0. **This sample cannot resolve a one-point difference in overtime rate, and no claim in either direction is made from it.**

Assigning the result to the four candidate explanations, in order of how much of it each carries:

1. **The coaching differences are real and large — but not on the quantity the hypothesis is about.** The four thresholds do exactly what they were built to do, consistently across all six samples and far outside noise: top-player minutes move +6.4 (population) and +6.8 (mirror) from regular to championship, starter minute share moves +5.5 points, garbage-time releases fall by half, timeouts fall about 3%. None of those is a mechanism for producing a tie. The set was chosen to be minimal and coherent, and the price of minimality is that its largest effect is on *minutes*.

2. **In a real league, the largest effect actively works against the hypothesis.** Tightening the rotation puts the better players on the floor longer *for both teams*. Where a pregame strength gap exists it is amplified: pooled population close-game share falls 4.2 points (−2.4 standard errors, the most significant movement in the whole diagnostic), blowout share rises 2.8, and margin SD rises 1.10. The mirror fixtures, which have no gap to amplify, show close-game share flat (−0.8 points) and margin SD rising only 0.74. **That contrast is the amplification, measured.** It is a legitimate consequence of a legitimate coaching decision, not a defect, and it is the reason the population and mirror samples point in opposite directions.

3. **Sample noise carries the rest.** See the standard errors above.

4. **The scoring model's end-of-regulation repertoire is the real ceiling, and §5.13 already said so.** That section found the overtime band unreachable because "the probability of an exactly level regulation score is the margin distribution's density at zero", and noted that "a league with a fuller end-of-regulation repertoire concentrates extra mass at exactly level, and that repertoire is a system this engine does not yet have". Nothing in this task changed that. The engine still has no advance-the-ball timeout, no two-for-one, no deliberate foul while *leading*, no intentional miss on a last free throw, and no end-of-period possession planning. The tie-seeking rule this task widened and sharpened is the *only* end-of-regulation repertoire that exists, it fires on roughly 0.2 possessions a game, and widening its window from 32 to 64 seconds cannot move a 3% rate by a measurable amount when there are a fifth of a possession per game to work with.

**Nothing was tuned toward the ordering.** The five step tunables were fixed before the first range was run and were not touched afterwards. The runner emits no band and cannot fail on the hypothesis. The result is reported as measured.

One measurement is reported with a caveat rather than a conclusion. The **tie-seeking levelling share** moves inconsistently — down at College development, flat at College validation, up at Top Domestic development. It is confounded by construction: the matched design pairs *fixtures*, not *game states*, so once behaviour diverges the set of down-two-or-three situations diverges too, and the samples are 40-75 attempts. The policy itself is asserted directly by unit test at a fixed state, where it does widen and sharpen monotonically; the aggregate share is not evidence about it either way.

#### §14.1 and PPP regression

Nothing moved, and most of it could not have.

| Check | Result |
| --- | --- |
| Six committed golden ledgers | byte-identical hashes; the harness rewrote the hash file to identical bytes |
| `tools/simulation_smoke.gd` | every reported figure identical to the pre-change run; the only difference in the whole output is the wall-clock line |
| Attribute sensitivity, 100,000 resolutions × 80 metrics | every estimate identical to the pre-change run; 80/80 PASS |
| Calibration smoke, 6 games × 15 metrics | every estimate identical to the pre-change run; 15/15 PASS |
| Regular-season PPP, College | 1.0435 / 1.0446 against §5.13's recorded 1.0453 |
| Regular-season PPP, Top Domestic | 1.1728 / 1.1782 against §5.13's recorded 1.1809 |
| Regular-season possessions, College | 70.52 / 70.93 against §5.13's recorded 70.38 |
| Regular-season possessions, Top Domestic | 100.39 / 100.92 against §5.13's recorded 100.31 |

The regular-season column *is* the pre-change engine, bit for bit, so any difference from §5.13 above is that section's seed range against this one and nothing else.

The higher tiers move PPP by at most +0.4% and possessions by at most +0.25% — a consequence of better players being on the floor for longer, not of any change to shooting. **No §14.1 or §14.2 target, band, or tolerance was modified, and none is judged against a non-regular tier.**

#### Regression and performance

| Gate | Result |
| --- | --- |
| Import / global class cache | built, exit 0 |
| `tools/parse_check.gd` under warnings-as-errors | 212 scripts, 0 failures, **exit 0 asserted** |
| GdUnit4, `res://tests` | 38 suites, **388 cases, 0 failures, 0 errors, 0 orphans** (366 before this change) |
| `tests/run_all.gd` | PASS — golden ledgers, determinism, possession contract, Play/Sim/Skip parity, event/stat reconciliation, aggregation |
| `tools/simulation_smoke.gd` | PASS, invariants clean |
| `tools/builder_calibration_harness.gd` | PASS, 810 builds in locked bands |
| Attribute sensitivity | 80/80 PASS |
| Calibration smoke | 15/15 PASS |
| Career progression, 2,000 careers | 16/17 judged PASS; the single FAIL is `sample.meets_certification_size` (2,000 against §27.1's 1,000,000), the standing §6.4 blocker and not a behaviour result. Career progression does not simulate matches |
| Projected Peak diagnostics, 1,200 careers | PASS, coverage 0.7383, median width 11, 0 pathological subgroups |
| Executor parity | `parity.manual_vs_full_detail` and `parity.manual_vs_aggregate` both 0.0000 against ±0.02 |
| Determinism | `test_full_game_determinism`, `test_possession_determinism`, and per-tier reproduction across all three executors |
| Ledger reconciliation | `test_event_stat_reconciliation` plus the box-score assertions inside `MatchSession.build_output` |
| Golden-ledger verification | all six unchanged |

Neither million-scale certification nor a five-level calibration campaign was run.

**Performance**, `run_performance_profile.gd` at 40 games, editor-debug build with asserts active, two passes each on an otherwise idle machine:

| | Pass 1 | Pass 2 | Possessions/second |
| --- | ---: | ---: | ---: |
| Before (`6bd54d9`) | 1305.7 ms/game | 1308.8 ms/game | 155 / 154 |
| After | 1318.8 ms/game | 1325.2 ms/game | 153 / 152 |

**+1.2%**, and the two distributions do not overlap, so it is a real cost rather than noise. It is four extra static calls per decision point, each of which returns a literal on the regular-season branch. Reported rather than explained away.

#### Deferred

Explicitly out of scope here and not started:

- **Full five-level stakes calibration.** Deferred until real schedules and postseason matchups exist. Running it now would calibrate against fixtures that assign a tier arbitrarily, which is not the population any future band would describe.
- **The scheduling and career mapping.** No schedule, bracket, series, or postseason exists. Mapping real game metadata onto a tier is that layer's responsibility; the engine's side of the contract is complete and needs no further change to receive it.
- **Late-game timeout *usage*.** Stakes reserve timeouts; they do not spend them differently, because there is no advance-the-ball or set-play timeout mechanism to spend them on. Adding one is an engine feature, not a stakes feature.
- **The remaining authorised effects.** Pace and clock strategy, intentional-foul strategy, and the garbage-time *release* threshold are all authorised for stakes and were all deliberately left alone. The smallest coherent set was the brief.
- **A fuller end-of-regulation repertoire** — two-for-one, advance-the-ball, deliberate fouling while leading, intentional last-free-throw misses, end-of-period possession planning. §5.13 identified this as the reason the §14.2 overtime band is unreachable, and this task's measurement is further evidence for it. It is the single change most likely to make the stakes/overtime hypothesis testable at all.
- **Postseason scheduling, brackets, Finals series, narrative, career consequences, presentation, and content.** Out of scope by instruction, and none was added.

### 5.15 A pass that beats the defence now creates the shot it was thrown for

Status: **The §14.1 assist band is met at all five competition levels on two untouched validation ranges, and the §14.3 conditional sits inside its locked envelope at every level. The cause was creation, not attribution, and the compensating constant that had been hiding it is removed. Not certified: §27.1 requires 100,000 games per competition and this is 100.**

Assist percentage had been the longest-standing §14.1 failure. It was also flat — 46.5% to 49.7% at every level, while §14.1 asks for a band that *rises* from 42–66% at high school to 52–72% at top domestic. A metric that does not move with competition level is not a tuning miss; it is a ceiling.

#### The metric, before anything was diagnosed

Assist percentage is **credited `ASSIST` events over made field goals**, both counted from the ordered ledger and never inferred from a final score. `MatchMetricAccumulator.assist_percentage()` reads the box score, which is a projection of those same events; `AssistChainAudit` rebuilds the relationship from the ledger independently and the two are required to agree. The §14.3 conditional has a different denominator and is reported separately: **credited assists over made field goals that carried a recorded creator**.

The accounting identity holds exactly at every level, on both validation ranges: assisted plus unassisted equals total eligible makes, with zero duplicate assisters, zero orphaned assists, zero self-assists, zero cross-team assists, zero unexplained assists, and zero team/player reconciliation failures.

#### Baseline decomposition

40 games per competition on variations 600,000–600,039 (RNG seeds 600,001–600,040), at `7b1bfe3`:

| Level | FGM | Assist % | Makes with a qualifying delivery | Conditional credit | Pass-created attempts | Self-created attempts |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| High school | 2,072 | 47.9% | 57.4% | 83.4% | 52.7% | 47.3% |
| College | 2,167 | 48.5% | 53.9% | 90.1% | 50.9% | 49.1% |
| Development | 3,182 | 47.5% | 52.3% | 90.8% | 49.4% | 50.6% |
| Overseas | 2,488 | 48.0% | 52.1% | 92.1% | 49.3% | 50.7% |
| Top domestic | 3,494 | 47.7% | 52.4% | 90.9% | 49.5% | 50.6% |

Two numbers in that table decide the diagnosis.

**The conditional was running at 83–92% against a locked §14.3 baseline of 74%.** `SimulationBalanceProfile.assist_base` had been raised from 0.74 to 0.94 in `fbc8b63`. That is not a tuning choice inside a band; §14.3 is a locked row and 0.94 is outside it. It was holding assist percentage near 48% by crediting almost every qualifying delivery rather than by creating shots — the exact shortcut the brief forbids. **Reported as a code-versus-document conflict and corrected, not resolved silently.**

**Only 52% of made field goals were reached by a qualifying delivery at all.** That is the ceiling: no attribution rule can credit more than that, and at the locked conversion it caps assist percentage near 0.52 × 0.78 ≈ 41%. So attribution was over-generous and creation was the binding constraint, and correcting attribution alone would have made the number *worse*.

The ledger says why. Measured over 2,429 possessions of top-domestic basketball at `7b1bfe3`:

- **40.8% of all field-goal attempts happened in a possession with no completed pass in it at all**, and 30.6% of attempts were taken on the possession's very first action.
- Pull-up jump shots were **77.3% of every attempt**, and only 52% of them followed a pass.
- The offence completed **about one pass per shot**.

#### Root cause

**The advantage a pass creates was attributed to the passer and then discarded, so a pass could not create a shot.** Three linked defects, all in production, all ledger-visible:

1. **`AdvantageResolver` recorded the passer as the beneficiary of his own pass.** §11.1 gives `AdvantageResult` separate `creatorId` and `beneficiaryId` fields precisely so an action can create for somebody else. The §10.3 advantage continuation in `ActionCandidateGenerator._tactical_fit` lifts the *beneficiary's* next candidates by up to 1.20×, so it was lifting the candidates of a player who no longer had the ball. The receiver — the man the delivery actually freed — carried none of it into his own decision.

2. **`PossessionContext.last_pass_created_advantage` was written on every completed pass and read by nothing.** That field is §11.3's "whether the pass directly created the eventual shot". It was computed correctly and thrown away. The pass was consequently the only creating family in the engine with **no continuation at all**: a drive kicks out, a pick action rolls, a post kicks out, a cut is fed and finished, and a pass simply handed the ball over and ended its action.

3. **`RELOCATION` — 9.3% of every action, and §10.1 names the family "relocation or spot-up" — emitted an off-ball event and changed no state whatsoever.** It could not produce a shot, a pass, an advantage anyone consumed, or a state anyone read. A spot-up whose ball never arrives is not a basketball action, and it is the other half of the missing creation: `OFF_BALL_CUT` had its feed-and-finish and `RELOCATION` had nothing.

And one compensating defect, `assist_base` at 0.94, which had been covering for all three.

#### Ruled out

- **Lost lineage.** Measured, not assumed: `unexplained_assists` was **zero** at every level in the baseline audit. Every assist the engine credited was already explainable from ledger evidence — a live pass, from that passer, reaching that shooter. Nothing was being dropped between the pass and the reducer.
- **A reducer or box-score defect.** Team and player assists reconciled in every baseline game, and the projection agreed with the ledger event-for-event.
- **The stat rule being too narrow in the aggregate.** Widening the credited families is worth about a point and a half; it does not span a twenty-point gap. It was still corrected, in both directions — see below.
- **Executor divergence.** Play, Sim and Skip were already byte-identical and remain so.

#### The event-chain contract, before and after

Before, the chain was implicit and lived in two loose fields:

```text
pass -> last_passer_id (StringName), last_pass_created_advantage (never read)
shot -> is the family one of {PULL_UP, OFF_BALL_CUT, POST_ACTION}?
     -> is last_passer_id non-empty and not the shooter?
```

That rule never checked that the ball had reached *this* shooter, credited a post move off an entry pass, refused a transition finish off a pass ahead, and recorded `created` on the made-basket event for a shooter who had created his own shot after catching a pass — the inverse of §12.1's meaning.

After, the relationship is an explicit record, `PassCreation`, and it says when it stops being true:

```text
pass completed -> PassCreation{passer, receiver, openness, catch quality,
                              rotated defender, competition credited families}
invalidated by -> possession change | turnover | offensive rebound
                  | free-throw whistle | reset | a non-finishing attack
                  | a later pass replacing it | the shot that consumes it
delivery creates the shot iff -> the record is live
                              AND the ball reached this shooter
                              AND the passer is not the shooter
                              AND the family is one the competition credits
attempt event  -> carries the creator and the §12.1 assisted state
made event     -> carries the same creator and state
assist         -> only against a recorded creator, and only after the §14.3
                  conditional resolves against the passer's execution
```

`FIELD_GOAL_ATTEMPT` and `FIELD_GOAL_MADE` now carry the creator in `tertiary_player_id`, so an assist is a pure function of ledger evidence and the audit can check it without reconstructing anything. `PASS_COMPLETED` carries the rotating defender and the catch quality, which is the rest of what §11.3 asks a pass event to record.

#### The correction

Five changes, in the brief's preferred order, with each contribution measured separately on the tuning range (variations 3,000,000–3,000,019).

1. **Preserve the lineage that existed.** A pass's beneficiary is its receiver. `AdvantageResolver.resolve` — three lines.
2. **Correct attribution.** Eligibility follows the recorded relationship instead of a hard-coded family list: the delivery must have reached this shooter, and the family must be one the delivery produces. `POST_ACTION` is removed — an entry pass followed by a post move is the post player creating his own shot — and `TRANSITION_ATTACK` is added, because a pass ahead finished in transition is an assist. The credited family set is a **competition rule** (`CompetitionRuleProfile.assist_rule_id`, `credited_assist_families`), which is what §11.3's "configurable competition/stat rules" asks for; all five competitions share `delivered-shot-v1`, because no §4 or §14 requirement asks any of them to differ.
3. **Restore the locked conditional.** `assist_base` back to 0.74, and driven by **Pass Accuracy** rather than Read Quality, because §8 puts "assist conversion support" on Passing and "open-target recognition" on Vision.
4. **Add the missing pass-created shot states.** The pass gains the catch-and-shoot continuation every other creating family already had, and the spot-up gains the feed it existed for. Both fire in proportion to the openness the action actually produced — a catch-and-shoot needs a beat of space, not a broken-down defence — and both resolve against the advantage **one level lower**, because the closeout arrives while the shooter gathers. Both consume their own §9.4 action time; resolving them for free shortened every possession they touched and raised pace by the rate they fired.
5. **Correct action-family selection, last and only because the first four were not enough.** `base_weight_pull_up` 0.86 → 0.50. The constant is documented as the rate at which a *family* is considered, but `ActionCandidateGenerator` emits one pull-up candidate per legal shot zone, so a stated 0.86 reached the candidate pool as 2.6–3.4 and the zone enumeration, not the stated rate, set the shot mix.

The catch-and-shoot's zone is chosen by the **same §10.3 candidate machinery the ordinary pull-up uses**, not by a rule written beside it. A hand-written "take the highest expected points" version made every competition shoot the same share of threes, because expected points does not know that a high-school offence and a professional one are shaped differently; the §10.3 factors — the shooter's capability, his Perimeter↔Interior slider, the coach's shot-profile instruction, spacing, his matchup — do.

#### Contribution of each half

Top domestic, tuning range, 20 games:

| Stage | Assist % | Possessions | PPP | Turnovers/100 |
| --- | ---: | ---: | ---: | ---: |
| `7b1bfe3` | 47.5% | 99.9 | 1.224 | 13.4 |
| Event chain corrected, conditional restored, continuations added | 51.3% | 107.7 | 1.229 | 11.3 |
| Shot-mix correction added | **58.1%** | 101.9 | **1.161** | 14.5 |

The two halves are not independent and were not meant to be. The continuations end a possession in the action the pass arrives, which shortens possessions, raises pace and removes turnover opportunities; restoring the ball-movement share puts the actions back. Together they land inside the band on all four numbers, and points per possession — a §14.1 failure at `7b1bfe3` on this range — comes back inside 1.08–1.18 as a consequence rather than as a target.

#### Seed-range separation

Every range below is new to this task and appears nowhere in §5.7 through §5.14.

| Purpose | Variations | RNG seeds | Games per level |
| --- | --- | --- | ---: |
| Baseline decomposition and diagnosis | 600,000–600,039 | 600,001–600,040 | 40 |
| Development and tuning probes | ≥ 3,000,000 | ≥ 3,000,001 | 12–20 |
| **Validation A — untouched** | 610,000–610,099 | 610,001–610,100 | 100 |
| **Validation B — untouched** | 620,000–620,099 | 620,001–620,100 | 100 |

Neither validation range was measured until the five changes were frozen, and neither was revisited afterwards. No stakes, margin, progression, or Projected-Peak fitting range was reused.

#### Result: the §14.1 assist band, before and after

100 games per competition on each untouched validation range, measured by `calibration/runners/run_assist_diagnostics.gd` from the ledger.

| Level | Band | Before (`7b1bfe3`, 40 games) | Validation A | Validation B |
| --- | --- | ---: | ---: | ---: |
| High school | 42–66% | 47.9% | **50.8% ±1.3** | **49.7% ±1.4** |
| College | 48–68% | 48.5% | **53.1% ±1.3** | **52.9% ±1.3** |
| Development | 48–69% | 47.5% | **54.8% ±1.1** | **55.0% ±1.1** |
| Overseas | 50–72% | 48.0% | **55.3% ±1.2** | **55.2% ±1.2** |
| Top domestic | 52–72% | 47.7% | **58.9% ±1.0** | **58.2% ±1.0** |

Every level passes on both ranges, and the metric now **rises with competition level** as §14.1 asks. The two ranges agree to within 1.1 points at every level, and the largest disagreement is at the level with the widest band.

#### The §14.3 conditional

Credited assists over made field goals carrying a recorded creator, against the locked floor-to-ceiling envelope of 55–95% around a 74% baseline:

| Level | Validation A | Validation B |
| --- | ---: | ---: |
| High school | 74.9% | 73.2% |
| College | 80.2% | 80.9% |
| Development | 85.4% | 85.6% |
| Overseas | 87.5% | 86.8% |
| Top domestic | 90.7% | 90.1% |

All inside the envelope, and ordered by level — which is the capability term doing its job rather than a constant: the baseline is the rate at an even matchup, and a top-domestic roster's Pass Accuracy sits well above the middle of the scale while a high-school roster's sits near it. High school landing at 74.9% against a 74% baseline is the clearest evidence the curve is being used as written.

#### Creation, not credit

| Level (Validation A) | Makes with a recorded creator | Pass-created attempts | Catch-and-shoot attempts | Self-created attempts |
| --- | ---: | ---: | ---: | ---: |
| High school | 67.8% | 65.4% | 56.1% | 34.6% |
| College | 66.2% | 64.1% | 54.9% | 35.9% |
| Development | 64.1% | 61.4% | 52.9% | 38.6% |
| Overseas | 63.2% | 61.2% | 52.5% | 38.8% |
| Top domestic | 64.9% | 62.8% | 53.6% | 37.2% |

Against 52–57% of makes carrying a delivery before. The gain is creation: the offence now reaches a shot through a pass far more often, and the conditional that turns those into credit went **down** to its locked value at the same time.

#### Subgroups

Top domestic, Validation A, 9,024 made field goals. No pathological subgroup and no group carrying the result.

**By shot zone** — the shape a reader should check first, because it is where the old model was most obviously wrong:

| Zone | Before | After |
| --- | ---: | ---: |
| Standard three | 55.8% | **71.3%** |
| Restricted rim | 71.1% | 65.7% |
| Midrange | 34.0% | 56.8% |
| Close non-rim | 33.9% | 50.0% |
| Deep three | 41.1% | 38.5% |

Three-point makes being assisted more often than rim makes is the single most recognisable property of modern basketball, and the engine had it backwards. It does not any more. The deep three stays the least-assisted zone, which is right: it is the shot a creator takes for himself.

**By action family:** off-ball cut 93.4%, pull-up 65.4%, transition attack 33.3% (60 makes, undersampled), and exactly 0.0% for drive, pick action, post action and putback — the four families where the shooter creates his own attempt. That the four are exactly zero rather than nearly zero is the attribution rule being categorical rather than probabilistic.

**By phase:** half court 58.8%, transition 59.3%. The two are within half a point, which they should be: a transition finish off a pass ahead and a half-court catch-and-shoot are both deliveries.

**By scorer role:** 50.9% (secondary creator) to 65.2% (roll/pop big), with primary creator at 55.6% and shooter at 62.5%. Bigs and shooters are assisted most, creators least. Nobody is above 70% or below 50%.

**By passer role:** primary creator 15.9% of assists, slasher 12.9%, shooter 12.3%, secondary creator 11.7%, roll/pop big 11.1%, connector 9.8%, interior anchor 9.4%, perimeter stopper 7.7%, post option 6.1%, rebounder 3.2%. The primary creator leads without dominating, and the tail is genuine ball movement rather than one player's box score. **Undersampled subgroups are named in the report** rather than being quietly averaged: at 100 games the rebounder passer group and the transition-attack family are below the 200-event threshold at top domestic, and several passer-role groups are below it at high school.

#### Turnovers, and the thing to be suspicious of

More passing must not buy safe ball movement. It did not.

| Level (Validation A) | Pass turnover rate | Assist/turnover |
| --- | ---: | ---: |
| High school | 5.4% | 1.71 |
| College | 5.1% | 1.98 |
| Development | 5.0% | 2.09 |
| Overseas | 5.0% | 2.13 |
| Top domestic | 4.5% | 2.51 |

Pass turnover rate — bad passes and interceptions over all pass attempts — is **4.5–5.5%, against 4.8–6.3% before**. It is a per-pass rate and it did not fall to buy the assists; the extra assists came from more passes at the same risk, which is what "more ball movement" is supposed to cost. Turnovers per 100 possessions are reported in the §14.1 table below and stay inside their bands at every level.

#### Vision and Passing stay distinct

Measured at the resolvers that own them, at 400 samples per point, rating 40 against 95:

- **Vision** raises the material-advantage rate of a completed pass — §11.1's "open-target recognition" — and raises it **more than Passing does**, which is the assertion that fails if Read Quality is taken out of the creation roll.
- **Passing** raises pass completion, raises catch quality, and raises the §14.3 conditional. Measured in production as well as in arithmetic: an offence of 95-Passing players credits a larger share of the baskets its own deliveries created than a 40-Passing offence does, with shooters, defence, rules and seeds held fixed.
- **Neither moves the receiver's shot.** The shooter's own shot capability, the contest band he faces, and his resolved make probability are identical whoever passed him the ball.
- The two are separable in the way §11.3 describes in words: a high-Vision, low-Passing player creates more open targets *and* turns the ball over more; a high-Passing, low-Vision player delivers safely and creates less.

**A contradiction between the brief and the specification, reported rather than resolved silently.** The brief's test 16 asks that Passing affect delivery and turnover risk "without modifying shot probability". `SIMULATION_SPEC.md` §12.6 lists `Advantage/PassQuality` as a term of `MakeQuality`, and §12.2 lists "catch/pass quality" among the shot-context inputs. Read literally the two disagree. This task implemented the specification — a badly delivered ball is a harder catch, as a bounded §12.2 context penalty — and tested the property that the brief is actually protecting: Passing is not a shooting rating, and it does not reach the shooter's capability, baseline, contest, or resolved probability at a fixed catch quality.

#### Mutation evidence

Fifteen mutations, each applied to production code, run against the assist, attribute-contract, invariant, reconciliation and parity suites, and restored byte-clean. Thirteen were killed.

| Mutation | Result | First guard to catch it |
| --- | --- | --- |
| Drop the creator before shot resolution | **Killed** (7) | `test_every_assist_is_explained_by_a_recorded_creation_event` |
| Credit every make after any pass | **Killed** (12) | `test_a_self_created_shot_is_unassisted` |
| Credit the shooter as his own assister | **Killed** (2) | `test_a_delivery_only_creates_for_the_man_it_reached` |
| Retain creator context across an offensive rebound | *Survived — equivalent* | — |
| Retain it *and* credit putbacks | **Killed** (12) | `test_a_self_created_shot_is_unassisted` |
| Credit assists on missed shots | **Killed** (39 + 89 assertion errors) | `test_a_missed_shot_produces_no_assist` |
| Remove the free-throw creation clear | *Survived — equivalent* | — |
| Emit an assist on a made free throw | **Killed** (39 + 78 assertion errors) | `test_free_throws_produce_no_assists` |
| Remove Vision from recognition | **Killed** (2) | `test_vision_changes_open_target_recognition_and_creation` |
| Remove Passing from execution | **Killed** (1) | `test_passing_drives_the_conditional_credit_rate_in_production` |
| Make Passing change shot accuracy | **Killed** (3) | `test_passing_changes_delivery_execution_and_assist_conversion` |
| Collapse every shot into assisted | **Killed** (5) | `test_a_self_created_shot_is_unassisted` |
| Collapse every shot into unassisted | **Killed** (57) | `test_every_assist_is_explained_by_a_recorded_creation_event` |
| Break team/player assist reconciliation | **Killed** (39 + 78 assertion errors) | `test_team_and_player_assists_reconcile` |
| Make Skip produce different assists from Sim | **Killed** (6) | `test_play_sim_and_skip_agree_on_every_credited_assist` |

**Three mutations survived the first pass and each exposed a real gap, which was closed rather than argued away.**

- *Remove Passing from execution* survived because the §14.3 conditional was asserted against the balance profile's arithmetic rather than against the engine. It is now measured in production, from the ledger.
- *Remove Vision from recognition* survived on one distinctness assertion, because Pass Accuracy carries 15% Vision under the locked §5.2 weight table, so Vision moved the advantage rate either way. The test now requires Vision to move it *more* than Passing does.
- *Make Passing change shot accuracy* survived because the test reused one `CapabilityCalculator` across two fixtures that share player ids, and the calculator memoizes by player id and is documented as living for exactly one `MatchInput`. The second arm was being answered with the first arm's ratings, so that assertion had been vacuous since the moment it was written.

**Two required mutations survive as equivalent mutants, and are reported as such rather than being made to look dead.** Removing the creation clear at the offensive rebound, and removing it at the free-throw whistle, change no credited assist on any reachable path — including when compounded with removing the blanket "a shot consumes its delivery" clear. The property they attack is held by two stronger guards nearer the decision: the delivery must have reached *this* shooter, and the shot's family must be one a delivery produces. A putback is neither, and a free throw is not a field goal. The audit measures this directly: **`broken_chains.offensive_rebound` is exactly zero at every level**, because the attempt that preceded the rebound had already consumed the record. The clears stay as the explicit §14.4 and §11.3 statement of when creation context ends; the evidence is that they are defence in depth rather than the load-bearing guard, and the mutations that reach the property are killed by twelve and thirty-nine tests respectively.

#### Golden ledgers

All six goldens were recorded before the change and all six moved, which is correct: the corrections change production pass and shot events on the first offensive action of almost every possession.

First divergence, at the seeds each scenario always had:

| Scenario | First divergent event | What changed |
| --- | --- | --- |
| `substitution_foul_out` | seq 17, `advantage_created` | `home_p4 \| home_p4` → `home_p4 \| home_p5`: the pass's beneficiary is its receiver. Nothing else about the event moves. |
| `offensive_rebound` | seq 17, `pass_completed` | the §11.3 fields appear — the rotating defender (`away_p5`) and the catch quality (89) |
| `regulation` | seq 27, `action_selected` | `pass_swing` → `handoff`: the shot-mix correction changes candidate weights |
| `foul_free_throw` | seq 16, `action_selected` | `off_ball_cut` → `relocation` |
| `late_game` | seq 16, `action_selected` | `drive` → `pass_swing` |
| `overtime` | seq 25, `action_selected` | `post_action` → `pick_action` |

The blast radius matches the defect exactly: every divergence is the first offensive action after half-court entry, which is the earliest point at which any of the three corrections can bite, and the first two are the corrections in their purest form — one field of one event, with the rest of the ledger to that point identical.

**One scenario seed moved and only one.** `find_scenario_seeds.gd` re-checked all six over a 4,000-seed search: the overtime fixture stopped finishing level and moved from 39,595 to 190,056, carrying two overtimes rather than one so the check has a margin. The other five still exercise their named behaviour at the seeds they always had — including the offensive-rebound continuation and the foul-out substitution, which the §11.3 event chain runs straight through. **The ruleset is bumped to `simulation-v6-pass-creation`**, which is what the contract requires before a golden may be regenerated, and no hash was regenerated to make a gate pass: the harness re-checks every scenario's requirement on every regeneration and refused nothing.

#### Two fixtures that were testing by coincidence

Both were found by this change and are fixed rather than relaxed.

- `test_offensive_rebound_percentage_uses_the_required_denominator` asserted that a team's own defensive rebounds differed from its opponent's in one golden game. They stopped differing (22 against 22). The rule — the denominator is the opponent's defensive rebounds — is now proven on lines built so the two differ by construction, which is what the assertion was always trying to say.
- `test_regular_season_games_still_reach_overtime` hung on a forty-seed block that stopped containing an overtime. At 4–8% of games, forty fixtures expect one or two, and which forty finish level is a property of the scoring shape. The block moves from 6,100 to 6,140 and carries two.

And one fixture was asking for a roster nobody can legally supply. `_mismatched_match` tilted the two rosters ±9 rating points; at that tilt the weaker roster now fouls out **six of its ten players**, and a ten-man roster under a six-foul limit then has no legal fifth player. That is the upstream supply problem `RotationResolver` names — §5 requires career services to authorise a replacement and forbids the engine from inventing one — rather than an engine defect. The tilt drops to ±7, which still blows eleven of twelve games open and still produces several hundred settled-rotation check-ins.

#### Regression guardrails: the complete §14.1 table, before and after, on identical seeds

100 games per competition on Validation A (variations 610,000–610,099), the pre-change engine at `7b1bfe3` against the post-change engine, playing the identical fixtures at the identical seeds. A bold figure is one that changed band membership.

| Metric | Band | HS before → after | College | Development | Overseas | Top domestic |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Possessions/game | per level | 69.2 → 71.6 | 70.9 → 72.2 | 95.5 → 95.9 | 75.2 → 74.9 | 100.7 → 102.0 |
| Points/possession | per level | 0.941 → 0.959 | 1.024 → 1.061 | 1.096 → 1.105 | 1.111 → 1.114 | 1.178 → **1.181** |
| FG% | per level | **38.99 → 39.3** | 40.61 → 41.25 | **42.90 → 43.4** | 44.0 → 44.2 | 45.7 → 46.8 |
| 3P% | per level | 30.5 → 32.4 | 31.7 → 34.0 | 34.3 → 35.6 | 34.3 → 36.7 | 37.2 → 37.9 |
| 3PA/FGA | per level | 34.8 → 31.7 | 36.8 → 34.0 | 39.6 → 35.7 | 39.5 → 35.4 | 41.8 → 37.0 |
| FT% | per level | 67.5 → 66.1 | 70.5 → 72.9 | 76.4 → 75.8 | 77.5 → 76.6 | 80.6 → 80.6 |
| FTA/FGA | per level | 20.1 → 19.8 | 25.8 → 25.7 | 20.7 → 22.1 | 22.0 → 22.2 | 21.0 → 21.6 |
| Turnovers/100 | per level | 18.0 → 16.8 | 16.6 → 15.3 | 14.7 → 14.7 | 14.5 → 14.6 | 14.0 → 14.2 |
| Offensive rebound % | per level | **24.15 → 25.1** | 24.8 → 25.5 | 25.3 → 25.7 | 24.6 → 25.8 | 25.6 → 25.3 |
| **Assist %** | per level | **48.9 → 50.8** | **48.7 → 53.1** | **47.4 → 54.8** | **47.5 → 55.3** | **48.7 → 58.9** |
| Fouls/game | — | 16.6 → 16.7 | 16.4 → 16.2 | 21.1 → 22.0 | 16.8 → 16.7 | 22.2 → 22.7 |
| Steals/game | — | 5.8 → 5.7 | 5.6 → 5.4 | 7.0 → 6.9 | 5.3 → 5.5 | 7.4 → 7.3 |
| Blocks/game | — | 2.4 → 2.7 | 2.8 → 2.7 | 4.0 → 4.3 | 3.1 → 3.6 | 4.3 → 4.8 |

**Four §14.1 failures resolved and one created.** Assist percentage passes at all five levels where it failed at three; high-school field-goal percentage and offensive rebound percentage and development field-goal percentage each cross from just outside their floor to just inside. College field-goal percentage improves from 40.61% to 41.25% and still fails against a 42% floor, which is the pre-existing failure §32.1 already records.

**The one created failure is top-domestic points per possession, and it is nine ten-thousandths.** 1.178 before and 1.1809 after, against a 1.08–1.18 ceiling — inside by two thousandths, then outside by one. On Validation B the same comparison is 1.166 → 1.173 and passes on both sides. The metric moved by about +0.004 and it sits on the ceiling either way. It is reported as a regression because it is one, and it is a smaller failure than the 1.186 §32.1 currently records.

**The largest movement outside the target is the three-point attempt rate, and it moves toward reality rather than away.** 3PA/FGA falls 3–5 points at every level and stays inside its band at all five, while three-point *percentage* rises 1–2 points at every level and also stays inside. That is the same fact twice: the offence now takes fewer, better three-point attempts, because the ones it takes are more often catch-and-shoot off a delivery instead of pull-ups off the dribble. Assisted three-point makes go from 55.8% to 71.3% at top domestic.

**Turnovers did not fall to pay for the assists.** Turnovers per 100 possessions move by at most 1.3 at any level, downward at the two lowest-possession levels and flat-to-slightly-up at the other three, and every level stays inside its §14.1 band on both validation ranges. The per-pass risk is unchanged.

**Home win rate, overtime frequency, and blowout share are not resolvable at 100 games**, and both engines wander across their bands on both ranges — home win rate has a standard error near five points against a three-point band. They are §14.2 items, they are out of this task's scope, and no claim is made about them here in either direction.

#### Determinism, parity, and reconciliation

- **Determinism.** Identical seeds and inputs reproduce identical attribution across all six golden scenarios, asserted on the assist-and-make signature rather than only on the hash.
- **Executor parity.** Play, Sim and Skip produce byte-identical ledgers and identical team assist totals. The mutation that makes Skip derive a different possession stream is killed by the parity assertion.
- **Reconciliation.** Team assists equal the sum of player assists in every game at every level, and no team has more assists than made field goals carrying a recorded creator — a new box-score invariant added with this change, projected from the ledger by `BoxScoreProjector` and checked by `MatchStatistics.reconcile`.
- **Independence from any aggregate.** The attribution decision reads the creation record and the passer's Pass Accuracy. The only balance terms it touches are the §14.3 conditional's own three, and the test asserts that those three equal the locked §14.3 row.

#### Performance

`run_performance_profile.gd` at the reference game: candidate generation remains the dominant cost at 44.9% of a game, unchanged in shape. The two continuations add one shot resolution to the possessions where they fire and the shot-mix correction adds actions to the rest, so the cost moves with the action count rather than with any new per-action work. Reported rather than optimised; §32.1's finding that the §27.1 sample is not reachable in GDScript for this engine design is unaffected.

#### The gate at the final commit

| Step | Result |
| --- | --- |
| Import / class-cache preparation | exit 0 |
| Parse check under warnings-as-errors | 216 scripts, 0 failures, exit 0 |
| Full GdUnit4 suite | 410 cases, 39 suites, 0 errors, 0 failures |
| `tests/run_all.gd` acceptance | PASS |
| Simulation smoke and invariants | Invariants PASS |
| Builder calibration | PASS, 810 builds in their locked bands |
| Attribute sensitivity at the locked sample | 80/80 PASS at 100,000 resolutions per point |
| Calibration smoke | 15/15 PASS |
| Five-level competition calibration | Two untouched validation ranges; §14.1 assist passes at all five levels on both |
| Career progression | 17 judged, 1 failure — `sample.meets_certification_size`, which fails correctly at 400 careers |
| Projected Peak diagnostics | 3 judged, 0 failures |
| Stakes regression | 54 metrics, 0 judged, 0 failures; the matched diagnostic is deliberately unjudged |
| Determinism | Byte-identical reproduction across all six goldens |
| Executor parity | Play, Sim and Skip byte-identical |
| Ledger reconciliation | Zero failures at every level, plus the new assists-versus-created-makes invariant |
| Shard aggregation | Ten synthetic cases plus mutation testing, unchanged |
| Golden-ledger verification | Six scenarios, regenerated once under an explicit ruleset bump, all verifying |
| Performance comparison | Candidate generation 44.9% of a game, shape unchanged |

Nothing here reaches a §27.1 certification sample and nothing here claims to.

#### What this is, and what it is not

| Claim | Status |
| --- | --- |
| The event chain is explicit, ledger-visible, deterministic and reducer-owned | **Structural** — proven by tests and by fifteen mutations |
| Assist percentage is inside its §14.1 band at all five levels | **Measured**, on two untouched 100-game validation ranges, and not certified |
| The §14.3 conditional is inside its locked envelope at all five levels | **Measured**, same ranges, and not certified |
| Any of the above at the §27.1 sample | **Not certified.** 100 games per competition against a requirement of 100,000. The reports say so and fail their own `sample.meets_certification_size` metric rather than implying otherwise. |

#### Remaining Stage 4 blockers, unchanged by this task

Nothing here touched, and nothing here fixes: home advantage and the §14.2 home win rate, overtime frequency, the §14.2 blowout share at the two high-possession competitions, college field-goal percentage, Builder dominance, OVR truthfulness, career progression, Projected Peak, postseason scheduling, or the §27.1 certification sample. Top-domestic points per possession moves from a clear failure to the ceiling of its band and is recorded as still failing by nine ten-thousandths, which is a smaller failure than it was and is still a failure.

### 5.16 The assist checkpoint closes, and three equivalent mutants were hiding an unguarded property

Status: **Closed as verification. One real defect found and fixed — a test gap, not an engine defect — and no assist tuning was performed. `RELOCATION` is a productive basketball action and is measured as such. The §14.1 top-domestic points-per-possession figure is re-measured on an untouched 1,000-game range and the earlier `1.1809` is classified.**

This section closes §5.15's outstanding verification items. It changes no balance value, no assist parameter, and no production behaviour. The one change it makes is a test.

#### 1. Mutation accounting

Fifteen mutations, each applied to production code, run against the assist, attribute-contract, invariant, reconciliation and parity suites, and restored byte-clean. **Thirteen killed, two equivalent** — and both equivalence claims are now *proven* rather than inferred from a silent suite.

The proof mechanism is new and is committed as `tools/mutation_fingerprint.gd`. It replays a fixed set of complete matches — five competitions × three venue arms × eight games = **120 complete ledgers** — serializes every one with `MatchLedgerSerializer`, and reduces the set to a single fingerprint. §24.3 makes the ordered ledger the authority for every official statistic, so two runs with the same fingerprint produced the same events in the same order and therefore the same everything. An equivalent mutant leaves the fingerprint byte-identical; a live one does not, whatever the suite said.

Clean baseline: `7f492e86…3ed7`, 120 scenarios, 4,552 assists, 21,545 points, 4,493 fouls, 3,983 free-throw attempts.

| # | Mutation | Production behaviour changed | Initial result | Test that detected it | Test added or strengthened | Final result | Class | Evidence for equivalence |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Drop the creator before shot resolution | `_resolve_shot` stops stamping `creator_id` on `FIELD_GOAL_ATTEMPT` | Killed (7) | `test_every_assist_is_explained_by_a_recorded_creation_event` | — | Killed | killed | — |
| 2 | Credit every make after any pass | `PassCreation.creates_shot_for` drops the credited-family test | Killed (12) | `test_a_self_created_shot_is_unassisted` | — | Killed | killed | — |
| 3 | Credit the shooter as his own assister | `PassCreation.reaches` drops `passer_id != shooter_id` | Killed (2) | `test_a_delivery_only_creates_for_the_man_it_reached` | — | Killed | killed | — |
| 4 | Retain creator context across an offensive rebound | `_resolve_rebound` no longer clears `pass_creation` | **Survived** | — | `test_a_delivery_creates_at_most_one_attempt` (new; kills the pair, not this alone) | **Survived** | **equivalent** | Structural: `_resolve_shot` (626–629) is the only consumer of `pass_creation`, and all three entries to `_resolve_rebound` (650 blocked, 687 missed, 836 missed final free throw) already cleared it at 638 or 800. Empirical: fingerprint byte-identical over 120 ledgers. |
| 5 | Retain it *and* credit putbacks | Adds `PUTBACK` to `DELIVERED_FAMILIES` with mutation 4 | Killed (12) | `test_a_self_created_shot_is_unassisted` | — | Killed | killed | — |
| 6 | Credit assists on missed shots | `_credit_assist` called from the miss branch | Killed (39 + 89 assertion errors) | `test_a_missed_shot_produces_no_assist` | — | Killed | killed | — |
| 7 | Remove the free-throw creation clear | `_resolve_free_throws` no longer clears `pass_creation` | **Survived** | — | `test_a_delivery_creates_at_most_one_attempt` (new; see note below) | **Survived** | **equivalent** | Structural: every exit from `_resolve_free_throws` either terminates the possession — and `PossessionContext._init` starts the next one at `PassCreation.none()` — or reaches `_resolve_rebound`, which clears at 907 before any shot resolves. The free-throw loop itself never reads `pass_creation`. Empirical: fingerprint byte-identical over 120 ledgers. |
| 8 | Emit an assist on a made free throw | `FREE_THROW_MADE` routed through `_credit_assist` | Killed (39 + 78 assertion errors) | `test_free_throws_produce_no_assists` | — | Killed | killed | — |
| 9 | Remove Vision from recognition | `PASS_READ_QUALITY` weight dropped from the pass advantage roll | Survived → gap | `test_vision_changes_open_target_recognition_and_creation` | **Strengthened**: Pass Accuracy carries 15% Vision under the locked §5.2 table, so Vision moved the rate either way; the test now requires Vision to move it *more* than Passing does | Killed (2) | killed | — |
| 10 | Remove Passing from execution | `PASS_ACCURACY` dropped from `_credit_assist` | Survived → gap | `test_passing_drives_the_conditional_credit_rate_in_production` | **Added**: the §14.3 conditional had been asserted against the balance profile's arithmetic rather than against the engine; it is now measured in production, from the ledger | Killed (1) | killed | — |
| 11 | Make Passing change shot accuracy | A direct Passing term added to `ShotResolver.resolve_make` | Survived → gap | `test_passing_changes_delivery_execution_and_assist_conversion` | **Fixed**: the test reused one `CapabilityCalculator` across two fixtures sharing player ids, and the calculator memoizes by player id, so the second arm was answered with the first arm's ratings and the assertion had been vacuous since it was written | Killed (3) | killed | — |
| 12 | Collapse every shot into assisted | `assisted_state` returns `CATCH_AND_SHOOT` unconditionally | Killed (5) | `test_a_self_created_shot_is_unassisted` | — | Killed | killed | — |
| 13 | Collapse every shot into unassisted | `assisted_state` returns `UNASSISTED` unconditionally | Killed (57) | `test_every_assist_is_explained_by_a_recorded_creation_event` | — | Killed | killed | — |
| 14 | Break team/player assist reconciliation | Reducer stops summing player assists into the team line | Killed (39 + 78 assertion errors) | `test_team_and_player_assists_reconcile` | — | Killed | killed | — |
| 15 | Make Skip produce different assists from Sim | Skip derives a different possession stream | Killed (6) | `test_play_sim_and_skip_agree_on_every_credited_assist` | — | Killed | killed | — |

**Both equivalent mutants are genuinely equivalent, and §5.15's stronger claim about them was wrong.**

§5.15 said the two clears "change no credited assist on any reachable path — *including when compounded with removing the blanket 'a shot consumes its delivery' clear*". The first half is right and is now proven twice over. The second half is false, and finding that out is the substance of this checkpoint.

There are **three** creation clears on the shot path, not two: the offensive-rebound clear (row 4), the free-throw clear (row 7), and the blanket clear in `_resolve_shot` that §5.15 never listed as a mutation at all. The full lattice, each cell measured on the same 120 ledgers:

| Mutation set | Fingerprint | Ledgers changed | Assists | Class |
| --- | --- | ---: | ---: | --- |
| none (clean) | `7f492e86…3ed7` | — | 4,552 | — |
| offensive-rebound clear removed (4) | `7f492e86…3ed7` | 0 of 120 | 4,552 | equivalent |
| free-throw clear removed (7) | `7f492e86…3ed7` | 0 of 120 | 4,552 | equivalent |
| blanket shot clear removed (unlisted) | `7f492e86…3ed7` | 0 of 120 | 4,552 | equivalent |
| (4) + (7) | `7f492e86…3ed7` | 0 of 120 | 4,552 | equivalent |
| **(4) + blanket** | `b8b43901…5901` | **20 of 120** | **4,555** | **live** |
| (4) + (7) + blanket | `b8b43901…5901` | 20 of 120 | 4,555 | live |

The three clears were not defence in depth. They were **mutually masking**: each one is unreachable only because the other two catch every path, so mutation testing them one at a time reports three harmless deletions and says nothing about the property they exist to hold — which was defended by nothing but their conjunction. The free-throw clear turns out to be inert to the live path entirely; the minimal live pair is the offensive-rebound clear plus the blanket one.

**And the whole assist, reconciliation, invariant and parity suite passed on the live pair.** 86 test cases, 0 failures, against a mutation that moves twenty ledgers and credits three assists that should not exist.

The chain is ordinary basketball, and the first divergent event names it exactly. High school, variation 900,004, event 60:

```text
54 pass_completed      home_p5 -> home_p2   pass_swing  clear
55 field_goal_attempt  home_p2  creator=home_p5   pull_up   midrange
56 field_goal_missed   home_p2
57 rebound             home_p2  OFFENSIVE          (his own miss)
59 action_selected     home_p2                     pull_up   deep_three
60 field_goal_attempt  home_p2  creator=(none)     pull_up   deep_three   <- clean
60 field_goal_attempt  home_p2  creator=home_p5    pull_up   deep_three   <- live pair
```

A passer feeds a shooter, the shooter misses the shot the delivery created, the shooter rebounds his own miss and shoots again off the dribble — and the second attempt comes back carrying the first delivery's passer. Had it dropped, **one pass would have been two assists**.

**Why the existing guard could not see it.** `test_no_credited_assist_crosses_an_invalidating_event` checks `ASSIST` events. An attempt that inherits a stale creator and then *misses* emits no assist at all, so the guard was blind to exactly the case that produces the defect. §12.1 records the creator on the shot *intent*, so the attempt is where the property has to be checked.

**The guard that was missing**, added in `975c210`: `test_a_delivery_creates_at_most_one_attempt` walks the ledger, holds the live delivery's passer and receiver, invalidates it on a possession change, turnover, steal, free-throw whistle or rebound **and on every field-goal attempt**, and asserts that any attempt carrying a creator carries the live delivery's passer and was taken by the man that delivery reached. It runs over the six goldens plus six full top-domestic games, because the goldens are too short to reach the chain. It passes clean (22/22) and fails on the live pair with the stale creator named.

It does not kill rows 4 and 7 individually, and nothing can: those mutations change no observable, which is what equivalence means. What it does is make the property they defend hold on its own evidence instead of on a coincidence between three redundant statements.

#### 2. `RELOCATION` behaviour

**It routes into the pass/catch-and-shoot continuation. It is not presentation-only, not suppressed, not removed, and not defective.** §5.15 fixed it; this checkpoint measures the fix rather than restating it.

Exact before and after, both from production:

```gdscript
# Before (7b1bfe3 and earlier) — the whole branch:
ActionFamily.Value.RELOCATION:
    _emit(MatchDomainEvent.OFF_BALL_ACTION, _context.offense.team_id,
        candidate.actor_id, candidate.target_id, &"",
        candidate.action_id(), advantage.level_id())

# After (fd0f71d) — `_resolve_relocation`:
#   emit the same OFF_BALL_ACTION event
#   return if late clock
#   return unless spot_up draw < relocation_spot_up_share (0.80) * advantage.quality_share()
#   build a real PASS_SWING feed from the ball handler to the relocating player
#   resolve that feed's turnover risk — it can end the possession
#   _record_completed_pass(...)  -> PASS_COMPLETED, PassCreation, ball handler moves
#   _resolve_catch_and_shoot(...) -> the shot the relocation was run for
```

One correction to §5.15's wording: the old branch did not change *no* state. `_resolve_action` sets `_context.advantage` and emits `ADVANTAGE_CREATED` for every family before dispatch, so the relocation's openness was computed and recorded. What the *branch* did was nothing with it — the openness led nowhere, because the ball never arrived.

Effect, dimension by dimension:

| Dimension | Before | After |
| --- | --- | --- |
| Openness | Computed by `AdvantageResolver`, written to `_context.advantage`, emitted — and consumed by nothing on this path | Gates the spot-up directly (`relocation_spot_up_share × advantage.quality_share()`) and is carried onto the delivery as the receiver's §11.1 openness |
| Spacing | Affected *selection* only: `lerpf(0.85, 1.20, spacing)` in `_tactical_fit` | Unchanged on selection; spacing now also reaches the shot, because the relocation can produce one |
| Defensive rotation | Not recorded | `_record_completed_pass` records `rotated_defender_id = defender_of(receiver)`, so §11.3's "defensive rotation caused" is in the ledger |
| Receiver identity | None — no ball movement | `_context.ball_handler_id` becomes the relocating player |
| Shot selection | None | `_resolve_catch_and_shoot` picks the zone the *receiver's* own capability supports, which is what makes it his shot and the passer's creation |
| Pass creation | None | A real `PASS_SWING` feed with real turnover risk, recorded as `PASS_COMPLETED` with catch quality |
| Assist eligibility | Impossible — no attempt, no delivery | The catch-and-shoot resolves as `PULL_UP`, which is in `PassCreation.DELIVERED_FAMILIES`, so it is assist-eligible |
| Time consumption | `_consume(_clock.action_ms(...))` runs before dispatch for every selected action, so the relocation always cost time | **Unchanged** at the action level. Possessions end sooner only because a shot now happens |

**Measured, not asserted.** `RELOCATION` is **10.07%** of selected actions at top domestic in the current build. Reverting `_resolve_relocation` to its pre-fix body and re-running the same 120 ledgers:

| | Clean | Reverted to no-op | Delta |
| --- | ---: | ---: | ---: |
| Ledgers changed | — | **120 of 120** | every game |
| Assists | 4,552 | 4,344 | **−208 (−4.6%)** |
| Points | 21,545 | 21,169 | −376 |
| Fouls | 4,493 | 4,553 | +60 |
| Free-throw attempts | 3,983 | 4,151 | +168 |

Every single game changes. The family is load-bearing, and the "high-frequency no-op in the calibrated engine" the brief forbids does not exist here any more.

#### 4. Vision/Passing contract

The previous prompt demanded that Passing never affect shot probability. That is stricter than the governing specification, and the correct boundary is recorded here.

| Rule | Status in the implementation |
| --- | --- |
| Passing may influence **delivery quality, catch quality, and the resulting physical shot context** | **Yes, and only through that path.** `_delivered_catch_quality` reads `PASS_ACCURACY` (Passing 65%, Vision 15%, Offensive IQ 20%) into `PassCreation.catch_quality`, and `ShotResolver.resolve_make` applies it as `probability -= clampf(1 - catch_quality, 0, 1) × catch_quality_penalty_max` (0.07 max, floor 0.70). It is a §12.2 physical shot-context term, it only ever subtracts, and it is clamped by the zone's own floor and ceiling. |
| Passing must **not** provide an unexplained direct shooting bonus | **Confirmed.** `PASS_ACCURACY` appears in exactly three production sites: `TurnoverResolver.resolve_pass` (delivery completion), `AdvantageResolver` (0.40 of the pass creation roll), and `PossessionEngine` (catch quality and the §14.3 conditional). It appears in no shooting capability and in no term of `resolve_make`. Mutation 11 above adds such a term and is killed. |
| Vision may influence **recognition and creation** | **Yes.** `PASS_READ_QUALITY` (Vision 60%, Offensive IQ 25%, Passing 15%) leads the pass advantage roll at 0.60 against Pass Accuracy's 0.40, and Vision carries 20% of `SHOT_SELECTION`. High Vision with poor Passing sees the open man and turns it over; high Passing with poor Vision delivers the obvious pass safely and creates less. |
| Neither may **retroactively award an assist** | **Confirmed.** The creator is settled and stamped on the `FIELD_GOAL_ATTEMPT` event before `resolve_make` is called. `_credit_assist` runs after a made basket — because §14.1 defines an assist against a made field goal — but reads only the pre-recorded `creator_id`, the passer's Pass Accuracy, and a fresh draw. It cannot invent a creator, and rows 1, 6, 12 and 13 kill the mutations that try. |
| Neither may **guarantee a make** | **Confirmed.** Catch quality can only reduce make probability, and the result is clamped to `shot_floor(zone, dunk)`/`shot_ceiling(zone, dunk)`. |

#### 3. Top-domestic points per possession, on an untouched 1,000-game range

Validation A's `1.1809` was one hundred games. This is one thousand, on variations **700,000–700,999** (RNG seeds 700,001–701,000), a range no previous section has touched, at `4f7cbf5`. Nothing was tuned toward it and nothing was tuned after it.

| §14.1 metric | Estimate | Interval | Band | Verdict |
| --- | ---: | ---: | ---: | --- |
| Points per possession | **1.1863** | ±0.0052 | 1.08–1.18 | **FAIL** |
| Possessions per game | 101.7970 | ±0.1632 | 96–103 | PASS |
| Field-goal percentage | 0.4679 | ±0.0022 | 45–51% | PASS |
| Three-point percentage | 0.3857 | ±0.0036 | 34–40% | PASS |
| Three-point attempt rate | 0.3630 | ±0.0021 | 36–49% | PASS |
| Free-throw percentage | 0.8010 | ±0.0038 | 73–83% | PASS |
| Free-throw attempts per FGA | 0.2183 | ±0.0018 | 18–34% | PASS |
| Turnovers per 100 possessions | 13.8599 | — | 11–16 | PASS |
| Offensive rebound percentage | 0.2550 | ±0.0027 | 20–31% | PASS |
| Assist percentage | 0.5872 | ±0.0032 | 52–72% | PASS |

Ten of eleven §14.1 rows pass. The eleventh does not, and it misses by more than it was reported to.

**The interval is the point.** Points per possession was the one judged §14.1 row published with no interval at all, which is how a nine-ten-thousandth miss came to be described as a boundary condition. It has one now — the linearized ratio estimator, because points per possession is a ratio of two sums whose numerator and denominator covary — and it reads **[1.1811, 1.1915]**. The whole interval is above the 1.1800 ceiling.

Three independent untouched ranges at `simulation-v6-pass-creation`:

| Range | Games | Points per possession |
| --- | ---: | ---: |
| 610,000–610,099 (Validation A) | 100 | 1.1809 |
| 620,000–620,099 (Validation B) | 100 | 1.1730 |
| **700,000–700,999 (this run)** | **1,000** | **1.1863 ±0.0052** |

**Classification: a genuine, repeatable band failure of about +0.0063 — not sampling noise, and not negligible.** Taking the four options the brief names in turn:

- **Sampling noise?** No. A larger sample moved the estimate *away* from the band and tightened the interval entirely outside it. Noise does not do that.
- **A repeatable assist-chain regression?** Partly, and the honest word is "contribution" rather than "regression". §5.15 recorded points per possession moving 1.178 → 1.1809 on Validation A when the pass continuation landed, and the pre-assist pooled figure was 1.1771 ±0.0040 over 2,100 games. The assist work is worth something under a hundredth here. It is not a defect: the chain does what §11.3 specifies, and every assist-adjacent §14.1 and §14.3 row is inside its band.
- **A pre-existing range effect?** Substantially yes. The metric was already sitting on its ceiling before the assist work — 1.1771 with an interval touching 1.18 — so the assist contribution pushed a boundary figure over rather than creating the problem.
- **A genuine but negligible boundary condition?** No. Negligible was the reading available at 100 games without an interval. At 1,000 games with one, it is a real failure.

**No parameter was changed.** The brief forbids moving any parameter solely to put this number under 1.1800, and forbids reopening the assist implementation without a demonstrated causal defect. No causal defect was demonstrated — the assist chain is correct and its own rows pass — so the honest outcome is that top-domestic points per possession is a §14.1 failure of +0.0063, recorded and left alone. It is a calibration debt against the possession model, not an assist defect, and it belongs to whichever task is allowed to move scoring rates.

Action and shot mix on the same engine (400 top-domestic games, variations 710,000–710,399):

| Action family | Share | | Shot zone | Share |
| --- | ---: | --- | --- | ---: |
| Pass/swing | 32.73% | | Close non-rim | 28.60% |
| Pull-up | 14.25% | | Standard three | 26.02% |
| Off-ball cut | 11.19% | | Midrange | 23.64% |
| Relocation | 9.84% | | Restricted rim | 11.52% |
| Screen | 8.74% | | Deep three | 10.21% |
| Drive | 6.72% | | | |
| Handoff | 5.97% | | | |
| Pick action | 5.08% | | | |
| Reset | 1.92% | | | |
| Post action | 1.74% | | | |
| Transition attack | 0.95% | | | |
| Putback | 0.86% | | | |

#### Part 1 exit criteria

| Criterion | Status |
| --- | --- |
| CI is green | Verified on `fd0f71d` before any change (run 32418975454, "Pull request gate", success) and re-run after each Part 1 commit |
| The 15-mutation table reconciles | 15 mutations, 13 killed, 2 equivalent — and the two equivalences are now proven rather than inferred |
| Equivalent mutants are genuinely equivalent or killed | **Proven equivalent**, structurally and over 120 complete ledgers. A third, unlisted clear is equivalent too, and the *combination* is live and is now killed |
| `RELOCATION` is meaningful or removed | **Meaningful.** Reverting it changes 120 of 120 ledgers and removes 208 assists |
| Larger-sample PPP is reported without target-chasing | 1,000 games, untouched range, interval published, failure recorded, no parameter moved |
| Assist accounting, bands, parity, ledger reconciliation remain green | Unchanged: assist percentage 0.5872 ±0.0032 inside 52–72%, and the full acceptance runner passes |
| No new assist tuning was performed without a proven defect | No balance value was changed. The only Part 1 production-adjacent change is a test and two diagnostic tools |


### 5.17 Home court was a fifth of what §14.2 asks for, and most of it came through a channel §19.4 does not authorize

Status: **Diagnosed, corrected, and measured on two untouched validation ranges. Pooled over ten frozen samples the venue-attributable equal-team home win rate is 54.64% against a 54.5% baseline, and the contribution is 1.93 points per 100 possessions against a 2.5 cap. Not certified: individual 250-game ranges disagree by more than the effect is worth, two of ten breach the published cap metric at overseas, one of ten fails the venue-reversal control, and §27.1 wants 100,000 games per competition.**

> **§5.18 supersedes three figures below.** The "1.93 points per 100" is the mean of the *home-arm-only* column — the metric this section itself diagnosed as defective — and the corrected paired two-arm estimator reads **1.73 and 1.46** on two fresh ranges. The "25,000 complete games" is a tenfold double count of a per-arm figure; the real totals are **7,500 simulations over 2,500 unique paired fixtures**. And both failures recorded here — the two overseas cap breaches and the one venue-reversal failure — **do not survive correction**: zero of ten on each, on ranges opened after the estimator was frozen. The narrative below is left as written, because it is the record of what was believed when it was written; §5.18 is the correction.

#### The measurement that had to be built first

§14.2's row is "**even-team** home win rate: 53–56%; baseline 54.5%". Every previous measurement of it was taken on the population fixture, and that fixture cannot answer the question for two independent reasons.

**It is not even.** `CompetitionCatalog.match_for` gives the two benches different variations, so a population sample carries a real strength spread. The spread is symmetric, so it does not bias the estimate much, but it inflates its variance — which is why four of five levels "failed" at 400 games with intervals five points wide.

**It gives the home team the ball.** `match_for` sets `initial_possession_team_id` to the home team, every game. At top domestic that opening inbound is worth more than the entire §19.4 environment. The 1,000-game population run in §5.16 reports a home win rate of **0.5630 ±0.0307**, which reads like a home advantage above its band and is mostly an unearned possession.

So `run_home_court_diagnostics.gd` is new, and its design is the finding. Both benches are built from the same variation — every rating, body, tactical role, rotation role and game plan identical, pregame gap exactly zero. Three arms play the identical fixtures at the identical seeds:

```text
home      home = A, away = B, environment = 0.5
neutral   home = A, away = B, environment = 0
reversed  home = B, away = A, environment = 0.5
```

The opening inbound alternates on variation parity and is held constant inside every matched triple, so it is balanced over the sample and cancels inside each pair.

And the arms are **differenced per game**, not compared as column means. That is what makes the measurement possible at all: the unpaired margin has a standard deviation near 15, and the paired difference near 4. Two column means at 300 games cannot see an effect worth one and a half points; the paired difference can see it to about half a point.

Two independent estimates are reported and §19.4 requires them to agree:

```text
effect on A =  margin_home[i]     - margin_neutral[i]
effect on B =  margin_reversed[i] + margin_neutral[i]
```

The second is the venue reversal done as a subtraction on the other bench. An effect attached to a roster rather than to a building gives two numbers of opposite sign. **It agrees at all five levels, before and after the correction.**

#### Phase 1 — the baseline

400 games per arm, mirror fixtures, variations 710,000–710,399, at `aff6cc9`:

| Level | Neutral win rate | Neutral mean margin | Neutral margin σ | Home-arm gain | Reversed-arm gain | Pooled gain | Possessions | Needed for 54.5% | Delivered | Home-arm win rate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| High school | 0.4975 | +0.235 ±1.177 | 12.01 | +0.290 ±0.370 | +0.380 ±0.341 | **+0.335** | 71.09 | 1.36 | 25% | 0.5075 |
| College | 0.4875 | −0.030 ±1.297 | 13.23 | +0.695 ±0.354 | +0.425 ±0.359 | **+0.560** | 72.04 | 1.49 | 38% | 0.5150 |
| Development | 0.4525* | −1.100 ±1.421 | 14.50 | +0.613 ±0.498 | +0.655 ±0.451 | **+0.634** | 95.55 | 1.64 | 39% | 0.4525 |
| Overseas | 0.5375 | +0.740 ±1.307 | 13.34 | +0.660 ±0.416 | +0.510 ±0.373 | **+0.585** | 75.09 | 1.51 | 39% | 0.5425 |
| Top domestic | 0.4950 | +0.570 ±1.486 | 15.17 | +0.075 ±0.520 | +0.633 ±0.482 | **+0.354** | 101.66 | 1.71 | 21% | 0.4975 |

The neutral control centres on 50% and on a zero mean margin, which is what makes the rest of the table readable. The venue effect is **a fifth to two fifths of what §14.2 requires**, and the reversal agrees at every level.

**The cap and the target are compatible, and the arithmetic is worth stating because the brief asks.** The margin a 54.5% win rate needs is `z(0.545) × σ = 0.1130 × σ`; §17.4 allows `2.5 × possessions ÷ 100` points per game.

| Level | Needed (pts/game) | §17.4 allows (pts/game) | Headroom |
| --- | ---: | ---: | ---: |
| High school | 1.36 | 1.78 | 0.42 |
| College | 1.49 | 1.80 | 0.31 |
| Development | 1.64 | 2.39 | 0.75 |
| Overseas | 1.51 | 1.88 | 0.37 |
| Top domestic | 1.71 | 2.54 | 0.83 |

There is no contradiction to report to the owner: every level can reach 54.5% inside the cap, with the least headroom at college.
#### Phase 2 — every production read of the home environment

The inventory is short, and its shortness is the finding. There is **one input**, read at **three sites**, with **no aggregation and no cap enforcement anywhere**.

`MatchInput.home_environment` is a bare `float` in `0.0..1.0`, defaulting to `0.5`. `SIMULATION_SPEC.md` §9.3 names the field `homeEnvironment: HomeEnvironmentContext`; no such type exists. `PossessionContext`'s own class docstring lists "home environment" among the things §9.3 requires it to carry, and it carries no field for it — every consumer reaches through `context.input.home_environment` and `context.input.is_home(...)`.

| # | Input | Consumer | Exact probability or decision affected | Maximum contribution at env 0.5 | Stacks with another environment modifier | Combined cap enforced | Visible in ledger or report | Neutral bypasses it | Venue reversal flips the sign |
| ---: | --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `home_environment`, `is_home(offense)` | `ShotResolver.resolve_make` | `probability += home_environment_shot_bonus × env` on **every** home field-goal attempt | **+0.30** absolute probability points | Yes — with 2 and 3 | **No** | **No** — the ledger carries the contest band, never the environment term | Yes (multiplied by `env`) | Yes |
| 2 | `home_environment`, `is_home(offense)` | `FoulResolver._contact_probability` | `base ×= 1 ± home_environment_foul_bonus × env` on the shared contact model | ±0.5% relative ≈ **±0.10** absolute points on a 0.20 base | Yes | **No** | **No** | Yes | Yes |
| 3 | `home_environment`, `is_home(offense)` | `FreeThrowResolver.probability` | `value -= home_environment_shot_bonus × env` for the **away** shooter | **−0.30** absolute probability points | Yes | **No** | **No** | Yes | Yes |

Three details worth recording because each one matters to the correction:

- **Path 2 is correctly gated.** `_contact_probability` is reached only from `resolve_shooting_foul`, `resolve_non_shooting_foul` and `resolve_loose_ball_foul`, each of which requires a real action with real contact. It cannot create a foul without a valid foul opportunity. `resolve_offensive_foul` computes its own probability and is **not** touched, which is right: a crowd influences whether the *defence* is whistled, and a home charge call is not the same event.
- **Path 2 partially self-cancels on the glass.** `resolve_loose_ball_foul` runs `_contact_probability` and then splits the call 50/50 between offensive and defensive, so half the extra whistles the home multiplier buys while home has the ball are charged *to* the home team.
- **Path 1 is not one of §19.4's channels.** §19.4 authorizes "bounded officiating, communication, composure, and familiarity". A term added to the make probability of every home attempt regardless of who is shooting, from where, or against what contest is none of those; it is the flat shooting bonus §19.2 rules out in the same breath for Coach Trust ("does not increase the probability that an identical physical shot goes in"). It is also **65% of the total current effect**, so the channel that carries most of the home advantage is the one channel that is not authorized to carry any of it.

**No `HomeEnvironmentContext`, no channel accounting, no aggregation, no cap check.** Nothing in production sums the three contributions, nothing compares the sum with §17.4's +2.5 points per 100 possessions, and nothing bounds any single one against §17.4's four absolute probability points. Both caps are satisfied today only because the effects are far too small to reach them.


#### Root cause

**The home environment is worth about a fifth of §14.2's target, and roughly two thirds of that fifth was arriving through a flat field-goal make bonus that §19.4 does not authorize.**

Taking the brief's candidate list in turn, because ruling things out is most of the work:

| Candidate | Verdict |
| --- | --- |
| Home context exists but is never consumed | **Ruled out.** Consumed at three sites, all of them live |
| Effects are too weak | **Confirmed — primary.** +0.35 to +0.63 points a game against a 1.36–1.71 requirement |
| Effects cancel one another | **Ruled out.** All three point the same way; the reversal agrees at all five levels |
| Only one permitted channel is implemented | **Confirmed — contributing.** Of §19.4's four, only officiating existed as such, plus a free-throw composure term. Communication and familiarity were absent entirely, and the largest term was not one of the four |
| Neutral and home contexts are indistinguishable | **Ruled out.** Every site multiplies by strength, so zero is provably zero — and all forty neutral ledgers are byte-identical across the correction |
| Home identity is lost before possession resolution | **Ruled out.** `is_home` is available at every consumer and correct at every one |
| A fixture or team-strength offset contaminates measurement | **Confirmed — contributing, and large.** The population fixture hands the home team every opening inbound, which is worth more than the environment |
| Officiating/familiarity/communication effects are missing | **Confirmed** for communication and familiarity |
| The effect exists but the report measures it incorrectly | **Confirmed.** §14.2's even-team row was judged on a fixture that is neither even nor venue-neutral, at a sample whose interval spans the band |

The previous diagnosis in §5.11 reached the right magnitude — "worth about 0.3 points a game where the band needs about 2.1" — and named the wrong remedy: "raising it is a one-line change inside the tunable's existing 0.0–0.03 range". That one line raises `home_environment_shot_bonus`, and the brief's own test list forbids exactly what it produces: *"9. Identical physical shot context does not receive an unexplained home make bonus."* Against the old implementation that test fails by construction.

#### The correction

**`HomeEnvironmentContext`**, which `SIMULATION_SPEC.md` §9.3 has always named and the engine has never had. One input, three channels, no setter.

| Channel | §19.4 basis | Where it acts | Value at strength 1.0 | At production strength 0.5 |
| --- | --- | --- | ---: | ---: |
| Officiating | "bounded officiating" | `FoulResolver._contact_probability`, on the conversion of a contact opportunity that already exists | 0.009 | ±0.45 pp |
| Communication | "communication", and the familiarity that is the same mechanism | `TurnoverResolver.resolve_pass`, on the home side's unforced delivery error | 0.013 | −0.65 pp |
| Composure | "composure", inside §17.4's pressure envelope | `TurnoverResolver.resolve_ball_handling` and `FreeThrowResolver.probability`, on the visiting side | 0.008 | −0.40 pp |

**Familiarity is deliberately not a fourth channel.** §19.4 lists it beside communication, and in this engine both act on the same mechanism — how well a delivery and its catch are coordinated. Implementing it twice would be two names for one effect and would make the combined cap harder to read rather than easier. The brief's instruction is to use the fewest channels necessary.

**What was removed.** `home_environment_shot_bonus` added a term to the make probability of every home field-goal attempt, regardless of who was shooting, from where, or against what contest. That is not officiating, communication, composure or familiarity; §19.2 rules out the identical thing for Coach Trust in the same breath — "it does not increase the probability that an identical physical shot goes in" — and it was carrying about 65% of the old effect. `ShotResolver` now reads no home-environment term at all, and the venue reaches a shot only through §12.2 catch quality, which is a property of the delivery.

**What is bounded, and how.**

- **Per modifier**, structurally and exactly: every channel is clamped to `MAX_SINGLE_MODIFIER = 0.04`, which is §17.4's four absolute probability points. A balance profile that asks for more gets the cap rather than the number it asked for, so the bound holds without depending on assertions being compiled in.
- **Combined**, in two halves that meet in the middle. The sum of the channel modifiers is bounded at `MAX_COMBINED_MODIFIER = 0.09` — exact, testable, and true without any calibration constant. The realized points per 100 possessions is then *measured* on paired fixtures and judged against §17.4's +2.5 directly. Neither half is sufficient alone: a modifier bound cannot know what a possession is worth, and a cohort average cannot prove an individual game stayed inside it.
- **Neutral is zero**, provably: every channel is multiplied by strength, and `from_profile` returns `neutral()` at zero. Proven at the ledger, not asserted — see below.
- **No second modifier can hide.** Every production read goes through the context, and a test scans the executable source of all nine simulation files for a bare `home_environment` read that is not the context object.
- **Nothing reads the game.** The type takes one float and has no setter. A test strips the comments from its source and asserts the code mentions no team, score, margin, clock, period, winner, result, leading or trailing. A comeback mechanism cannot be written through this API because the API cannot see anything to come back from.

#### Per-channel decomposition

150 games per arm at top domestic on the tuning range, one channel switched off at a time, against a three-channel total of +2.10 points a game at the pre-final setting:

| Configuration | Pooled venue gain | Channel's contribution | Share |
| --- | ---: | ---: | ---: |
| All three | +2.10 | — | — |
| Officiating off | +0.65 | **+1.45** | 69% |
| Communication off | +1.59 | **+0.51** | 24% |
| Composure off (by difference) | — | **+0.14** | 7% |

Officiating carries most of it, which is what §19.4 leads with, and communication carries a real quarter. The shares are what this table is for; the absolute levels are from the pre-final setting and were scaled by 0.70 afterwards.

**One implementation note worth recording, because it nearly caused a wrong decision.** The communication channel appears to do nothing when probed with a *top* passer in a neutral-advantage context: §14.3 floors the unforced pass error at 1%, the probe sits on that floor, and the term is clamped away before it can act. The first version of the reachability test probed exactly that context and reported "this channel moves nothing" against clean production code. The channel is not inert — the decomposition above measures it at a quarter of the whole effect — and the test now probes the fifth starter, where the error rate is off its floor.


#### Tests

`tests/simulation/test_home_environment.gd`, 22 cases covering the 23 required properties (several properties share one case where one measurement answers both):

| # | Property | Case |
| ---: | --- | --- |
| 1 | Neutral games apply zero home effect | `test_a_neutral_court_applies_no_home_effect` |
| 2 | Missing home context uses the documented default | `test_a_missing_home_context_uses_the_documented_default` |
| 3, 16 | Swapping venue swaps the advantage, with the mirrored event changes | `test_swapping_the_venue_swaps_the_advantage` |
| 4 | Identical home/away identity creates no effect | `test_identical_home_and_away_identity_is_rejected` |
| 5 | Team identity does not affect the modifier | `test_the_modifier_reads_only_venue_strength`, `test_team_identity_does_not_change_any_channel` |
| 6, 17, 18 | Expected winner, result and margin are never read | `test_no_channel_reads_the_scoreboard`, `test_the_foul_and_turnover_resolvers_never_read_the_score`, `test_the_advantage_does_not_depend_on_the_margin` |
| 7, 8 | Stored ratings and capability values unchanged | `test_the_venue_changes_no_rating_or_capability` |
| 9 | Identical physical shot context gets no home make bonus | `test_an_identical_shot_context_has_no_home_make_bonus` |
| 10 | Effects operate only through documented channels | `test_effects_operate_only_through_documented_channels` |
| 11 | No modifier exceeds four absolute probability points | `test_no_single_modifier_exceeds_four_absolute_points` |
| 12, 25 | Combined contributions bounded; no hidden second modifier | `test_combined_contributions_stay_inside_the_budget` |
| 13, 14 | Neutral and home Play/Sim/Skip identical | `test_play_sim_and_skip_agree_at_every_venue` |
| 15 | Determinism for identical venue, inputs and seed | `test_identical_venue_inputs_and_seed_reproduce_the_ledger` |
| 19, 20 | No guaranteed outcome; away teams win a substantial share | `test_away_teams_still_win_a_substantial_share` |
| 21 | Stakes tiers do not change the home-policy contract | `test_stakes_tiers_do_not_change_the_home_contract` |
| 22 | Ledger and box-score totals reconcile | `test_ledger_and_box_score_reconcile_at_every_venue` |
| 23 | The diagnostic distinguishes home, away and neutral | `test_the_diagnostic_distinguishes_the_three_fixtures` |
| — | A neutral game cannot observe the modifier values at all | `test_a_neutral_game_cannot_observe_the_home_modifiers` |
| — | Each channel moves the rate it claims to move | `test_every_channel_actually_moves_its_own_rate` |

**Two of these are worth explaining, because the first versions were wrong and passed anyway.**

`test_no_channel_reads_the_scoreboard` resolves the identical possession 6,000 times against two scoreboards twenty points apart and compares **integer counts**, not rates. The first version compared floats against a 0.005 tolerance — looser than the entire channel, which moves these counts by a few dozen in six thousand — and two mutations walked through it.

`test_the_foul_and_turnover_resolvers_never_read_the_score` exists because sampling cannot close this on its own. A comeback modifier placed where §14.3's 1% turnover floor clamps it changes the probability and not the outcome: invisible to any number of draws, and still live in a real game. So the score is forbidden at the source, in the three functions the venue reaches — `FoulResolver._contact_probability`, `TurnoverResolver.resolve_pass`, `resolve_ball_handling`. It is scoped to those functions rather than to whole files on purpose: §13.1's deliberate late-game foul is a coaching decision gated on score and clock, and §20.1 gives the free-throw resolver a late-and-close pressure term that applies in both buildings. A scan that forbade those would be forbidding the specification.

#### Mutation evidence

Fourteen mutations, each applied to production code, run against the home-environment, parity and reconciliation suites, and restored byte-clean. **All fourteen are killed.**

| # | Mutation | Result | First guard to catch it |
| ---: | --- | --- | --- |
| 1 | Home context ignored | **Killed** | `test_a_missing_home_context_uses_the_documented_default` |
| 2 | Neutral context receiving a home effect | **Killed** | `test_a_neutral_court_applies_no_home_effect` |
| 3 | Flat home shooting boost | **Killed** | `test_an_identical_shot_context_has_no_home_make_bonus` |
| 4 | Home-team stored-rating boost | **Killed** | `test_an_identical_shot_context_has_no_home_make_bonus` |
| 5 | Trailing-home-team comeback boost | **Killed** | `test_the_foul_and_turnover_resolvers_never_read_the_score` |
| 6 | Score-aware officiating | **Killed** | `test_no_channel_reads_the_scoreboard` |
| 7 | Team-identity exception | **Killed** | `test_every_channel_actually_moves_its_own_rate` |
| 8 | Expected-winner dependency | **Killed** | `test_no_channel_reads_the_scoreboard` |
| 9 | Reversed home/away sign | **Killed** | `test_swapping_the_venue_swaps_the_advantage` |
| 10 | Individual modifier above four points | **Killed** | `test_no_single_modifier_exceeds_four_absolute_points` |
| 11 | Combined environment cap bypass | **Killed** | `test_combined_contributions_stay_inside_the_budget` |
| 12 | Executor divergence | **Killed**, abnormally — see below | the run does not complete |
| 13 | Missing ledger/diagnostic explanation | **Killed** | `test_effects_operate_only_through_documented_channels` |
| 14 | Home effect leaking into neutral games | **Killed** | `test_a_neutral_game_cannot_observe_the_home_modifiers` |

Five of these survived the first pass — 5, 6, 7, 8 and 12 — and each survival was a real gap that was closed rather than argued away. The tolerance problem is described above. Mutation 7 revealed that a team-identity exception hides from a lift comparison but not from a lift *measurement*.

**Mutation 12 is a special case worth recording precisely, because it says something stronger than a passing test.** Executor divergence cannot be written as a Skip-only behavioural mutation, because there is no Skip-only code path: `MatchEngine.simulate_match` is a thin front door onto the same `MatchSession` that Play and Skip drive, and `skip_to_final_result()` is literally `return run_to_completion()`. A mutation in the shared path changes all three executors equally, which is not a divergence at all. Making Skip differ requires first breaking that delegation, and the mutation that does — replacing the session's venue after the reducer and projector have been built from it — drives the run into a state it cannot finish. It is detected, the gate goes red, and it is honest to say it terminates abnormally rather than on a clean assertion. §2.1 parity here is structural, not merely tested.


#### Validation

Seed ranges, all disjoint and all owned by this section:

| Purpose | Variations | Used for |
| --- | --- | --- |
| Diagnosis | 710,000–710,399 | The pre-correction baseline, 400 games per arm |
| Tuning | 720,000–720,299 | First fit |
| Tuning (second) | 730,000–730,299 | Second fit. Opened as a validation range and then a value was changed after reading it, so it is a tuning range whatever it was called |
| **Validation A** | **780,000–780,249** | Opened after the values were frozen |
| **Validation B** | **790,000–790,249** | Same |

**Validation A**, 250 games per arm, mirror fixtures, at `b963431`:

| Level | Home win rate | Neutral control | Home-arm gain | Reversed-arm gain | Pooled gain | Points/100 | Cap | Reversal |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| High school | 0.5800 ±0.0612 **✗** | 0.5040 | +1.596 ±0.925 | +0.676 ±0.842 | +1.14 | 2.260 ±1.310 | PASS | PASS |
| College | 0.5360 ±0.0618 **✓** | 0.4880 | +1.252 ±0.814 | +1.220 ±0.913 | +1.24 | 1.739 ±1.131 | PASS | PASS |
| Development | 0.5560 ±0.0616 **✓** | 0.4720 | +2.084 ±1.139 | +2.128 ±1.060 | +2.11 | 2.192 ±1.198 | PASS | PASS |
| Overseas | 0.5520 ±0.0616 **✓** | 0.5160 | +2.104 ±0.832 | +0.056 ±0.790 | +1.08 | 2.801 ±1.108 | PASS | **FAIL** |
| Top domestic | 0.5720 ±0.0613 **✗** | 0.5200 | +2.244 ±1.211 | +0.696 ±1.202 | +1.47 | 2.204 ±1.189 | PASS | PASS |

Before and after, on the equal-team mirror fixture:

| Level | Before (pooled gain) | After (pooled gain) | Before (home win) | After (home win) | Needed |
| --- | ---: | ---: | ---: | ---: | ---: |
| High school | +0.34 | **+1.14** | 0.5075 | 0.5800 | 1.36 |
| College | +0.56 | **+1.24** | 0.5150 | 0.5360 | 1.49 |
| Development | +0.63 | **+2.11** | 0.4525 | 0.5560 | 1.64 |
| Overseas | +0.59 | **+1.08** | 0.5425 | 0.5520 | 1.51 |
| Top domestic | +0.35 | **+1.47** | 0.4975 | 0.5720 | 1.71 |

**Validation B**, 250 games per arm, variations 790,000–790,249, same build:

| Level | Home win rate | Neutral control | Home-arm gain | Reversed-arm gain | Pooled gain | Points/100 (home arm) | Cap | Reversal |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| High school | 0.5040 ±0.0620 **✗** | 0.5160 | +0.724 ±0.855 | +1.028 ±0.880 | +0.88 | 1.020 ±1.204 | PASS | PASS |
| College | 0.5960 ±0.0608 **✗** | 0.5360 | +1.348 ±0.899 | +1.236 ±0.890 | +1.29 | 1.864 ±1.244 | PASS | PASS |
| Development | 0.5640 ±0.0615 **✗** | 0.5040 | +1.636 ±0.985 | +1.768 ±0.962 | +1.70 | 1.709 ±1.029 | PASS | PASS |
| Overseas | 0.5600 ±0.0615 **✓** | 0.4560 | +2.616 ±0.965 | +0.900 ±0.930 | +1.76 | 3.498 ±1.290 | **FAIL** | PASS |
| Top domestic | 0.5080 ±0.0620 **✗** | 0.5520 | +0.020 ±1.162 | +1.240 ±1.047 | +0.63 | 0.020 ±1.146 | PASS | PASS |

#### The two ranges disagree by more than the effect, and that is the result

Top domestic reads 0.5720 on Validation A and 0.5080 on Validation B. Both are 250-game samples of the same frozen build, both are legitimate, and they differ by six and a half points — more than the entire correction is worth. High school does the same thing in the other direction (0.5800 against 0.5040).

That is not a defect in the correction. It is the measurement telling the truth about itself: at 250 games per arm the home win rate carries a ±6.2 point interval, and two draws from a distribution that wide will routinely land a band apart. **Reporting either range alone as "the" result would be picking a number.**

So both are reported, and pooled. Ten frozen samples — five levels × two untouched ranges, 2,500 games per arm in total:

| Statistic | Pooled over ten samples | Target |
| --- | ---: | ---: |
| Home win rate, raw | **0.5528** | 0.530–0.560 |
| Neutral control | 0.5064 | 0.500 |
| **Home win rate, net of the neutral control** | **0.5464** | **0.545 baseline** |
| Mean venue gain | +1.33 points/game | 1.36–1.71 |
| Mean contribution | **1.93 points per 100** | ≤ 2.5 |
| In band on the raw point estimate | 4 of 10 | — |
| Venue reversal agrees | 9 of 10 | 10 of 10 |
| Combined cap respected as published | 8 of 10 | 10 of 10 |

**The neutral-corrected pooled figure is 54.64% against a 54.5% baseline**, and the pooled contribution is 1.93 points per 100 against a 2.5 cap. Those are the two numbers this task was asked to move, and both land where §14.2 and §17.4 ask them to. They are pooled over 25,000 complete games and are still **not a §27.1 certification**, which wants 100,000 games per competition.

**Two failures are reported rather than smoothed over.**

**The published cap metric fails twice, both at overseas** — 2.801 on A and 3.498 on B against +2.5. This is partly a real level-specific effect and partly a defect in the metric, and the honest split matters: `paired_points_per_100` is computed from the **home arm alone**, which is the noisier of the two estimates the report already publishes. Recomputed on the pooled two-arm gain the report also prints, no level breaches the cap on either range:

| Level | A (pooled) | B (pooled) |
| --- | ---: | ---: |
| High school | 1.61 | 1.24 |
| College | 1.72 | 1.79 |
| Development | 2.22 | 1.79 |
| Overseas | 1.44 | **2.34** |
| Top domestic | 1.44 | 0.62 |

Ten of ten inside +2.5, with overseas the closest at 2.34. **The cap metric should be judged on the pooled estimator, and it is not yet.** That is a reporting defect in `run_home_court_diagnostics.gd`, recorded here rather than quietly fixed after the fact, and it is the first thing the next task on this section should change.

**The venue-reversal control fails once**, at overseas on Validation A: +2.104 ±0.832 against +0.056 ±0.790, intervals that do not overlap. It agrees at overseas on Validation B (+2.616 against +0.900) and on the 400-game diagnosis range (+0.66 against +0.51). One two-and-a-half-sigma disagreement in ten paired estimates is what a correct control does occasionally; it is reported as a FAIL because that is what it is.

**What this does and does not establish, stated plainly.**

- **The target is met on the pooled estimate.** Net of the neutral control, the venue-attributable equal-team home win rate is **54.64%** against a 54.5% baseline, and the contribution is **1.93 points per 100** against a 2.5 cap. Before the correction the venue was worth a fifth to two fifths of what §14.2 asks; it is now worth essentially exactly what §14.2 asks.
- **No individual range establishes that, and none should be quoted as if it did.** Four of ten samples sit inside 53–56% on the raw point estimate, and the two frozen ranges disagree at top domestic by six and a half points. The pooled figure is the measurement; the individual ones are draws from a ±6.2-point interval.
- **The neutral control is clean.** 0.456 to 0.552 across the ten samples, pooling to 0.5064, consistent with 0.50.
- **The caps hold on the pooled estimator and fail twice as published.** Ten of ten pooled two-arm contributions are inside +2.5, the largest 2.34 at overseas. The published metric uses the home arm alone and breaches at overseas on both ranges — a reporting defect recorded above, not a licence to ignore the level.
- **The venue reversal agrees nine times in ten**, failing once at overseas on Validation A.
- **None of this is certified and cannot be at this sample.** §27.1 asks for 100,000 games per competition; this is 250 per arm per range, 25,000 complete games in total. **[§5.18: the total is 7,500 simulations over 2,500 unique paired fixtures. 25,000 multiplied a per-arm figure by the ten samples already inside it.]**

#### Regression guardrails

Pooled §14.1 statistics are the check that matters here, because every game contains one home team and one away team, so a home/away differential that moves in the model should leave the league-wide totals effectively where they were. Over the 120-ledger mutation fingerprint, before and after the whole correction:

| Pooled total | Before | After | Change |
| --- | ---: | ---: | ---: |
| Assists | 4,552 | 4,550 | −0.04% |
| Points | 21,545 | 21,633 | +0.41% |
| Personal fouls | 4,493 | 4,492 | −0.02% |
| Free-throw attempts | 3,983 | 4,114 | +3.3% |

Fouls are flat pooled, which is exactly what a symmetric officiating channel should do: the extra whistles the home side draws are the ones the away side does not. Free-throw attempts rise 3.3% pooled, because the shift interacts with bonus state rather than cancelling inside it; at top domestic that moves free-throw attempts per field-goal attempt from 0.2183 toward 0.226 against an 18–34% band, which is comfortably inside it and is the one §14.1 row this correction visibly touches.

Determinism, executor parity and ledger reconciliation are unchanged and are asserted at both venues by the new suite. The full acceptance runner, the 314-case GdUnit suite, builder calibration, the 80-metric attribute-sensitivity gate and the calibration smoke all pass.

#### Golden ledgers

All six were recorded before any production change. **Three are byte-identical to the hashes they had at `fd0f71d`** — overtime, offensive rebound, and foul/free throw — which is itself evidence about the size of the effect: those scenarios are short enough that a change of a few tenths of a probability point flips no draw in them.

Three moved. Every one first diverges on a **foul call**, and both signs are represented:

| Scenario | First divergent event | What changed | Channel |
| --- | --- | --- | --- |
| `regulation` | event 103 | A home post-up attempt becomes a non-shooting defensive foul drawn by the home side | Officiating, home on offence |
| `substitution_foul_out` | event 423 | A shooting foul by the home defence no longer happens; the possession ends on a made basket | Officiating, away on offence |
| `late_game` | event 342 | A defensive rebound becomes a shooting foul drawn by the home side | Officiating, home on offence |

- **Neutral behaviour is unchanged, proven rather than argued.** All **40 neutral ledgers** in the mutation fingerprint — five competitions × eight games — are byte-identical before and after. The home arm changed 38 of 40 and the reversed arm 36 of 40.
- **The divergence is inside the documented caps**, which is what the channel bounds and the measured points-per-100 above establish.
- **No scenario was reseeded.** All six kept the seeds they had, and the harness re-verified that each still exercises the behaviour it is named for.
- **The ruleset is bumped** to `simulation-v7-home-environment`, because the production simulation contract changed.

#### What this is, and what it is not

| Claim | Status |
| --- | --- |
| Every §19.4 home effect comes through one bounded, audited context, and no other path exists | **Structural** — proven by tests, by a source scan, and by fourteen mutations |
| Individual modifiers are at or below §17.4's four absolute probability points | **Structural** — enforced by clamping, not by assertion |
| Neutral courts contribute exactly zero | **Structural** — proven at the ledger over 40 complete neutral games |
| Combined contributions are at or below +2.5 points per 100 possessions | **Measured**, 10/10 on the pooled two-arm estimator and 8/10 as the report currently publishes it; the two failures are both at overseas and the metric defect behind them is recorded above |
| Equal-team home win rate is inside 53–56% | **Measured pooled, not established per range.** 54.64% net of the neutral control over ten frozen samples; 4/10 individual ranges inside on the raw point estimate |
| Any of the above at the §27.1 sample | **Not certified.** 250 games per arm per range against a requirement of 100,000 per competition |

#### Remaining Stage 4 blockers, unchanged by this task

Top-domestic points per possession at +0.0063 over its ceiling (§5.16), college field-goal percentage, the §14.2 overtime and blowout rows, Builder dominance, OVR truthfulness, career progression, Projected Peak, postseason scheduling, and the §27.1 certification sample. None of them is touched here.

> **§5.20 corrects two entries in that list.** Top-domestic points per possession is no longer a blocker: it measures **1.1694 ±0.0037** pooled over two untouched 1,000-game ranges, inside the 1.08–1.18 band. And **career progression and Projected Peak were misclassified as implementation defects** — both are structurally complete and measured green (§5.7, §5.8, §5.9); what remains for each is the §27.1 certification sample, which is the standing §6.4 hardware blocker and not a behaviour result. See §6 for the corrected classification.


### 5.18 The venue estimator was reading one arm, and the fixture was giving the home team every opening possession

Status: **Instrumentation corrected; conclusions re-measured on two untouched ranges. Both previously recorded failures — the two overseas cap breaches and the venue-reversal failure — were artifacts of the estimator and do not survive correction. Two published figures were arithmetically wrong and are corrected here. No production value was changed and no golden hash moved.**

This section is a measurement closeout. §5.17 accepted the home-environment mechanisms and then recorded three unresolved problems with the package that measured them. All three are settled below.

#### 1. The opening possession: a fixture artifact, and what it was worth

**The engine does not choose who receives the opening possession, and never has.** `MatchInput.initial_possession_team_id` has no default and is validated to name one of the two supplied teams. `MatchEngine` consumes a `MatchInput` and never constructs one, and **nothing anywhere under `src/` constructs one** — the scheduling and career layers that would eventually decide this do not exist yet.

**No specification describes an opening-possession rule.** There is no jump ball, possession arrow, or alternating-possession rule in `SIMULATION_SPEC.md`, `BALANCE_SPEC.md`, `GDD.md`, or `PRD.md`. `CompetitionRuleProfile.possession_arrow_enabled` is declared and read by nothing.

**`CompetitionCatalog` chose, and chose `home.team_id` unconditionally**, in `match_for` and `mirrored_match_for` alike, for every fixture either has ever built.

So the ruling is **calibration-fixture artifact**, and the correction belongs to the fixture. Production is untouched, because there is no production behaviour here to correct. `SIMULATION_SPEC.md` §19.5 now states the contract that was previously unwritten: the engine does not choose, no tip-off is modelled, and a measurement fixture must counterbalance.

**Where it mattered.** `run_home_court_diagnostics.gd` already alternated the opener in `_venue_input`, so the §5.17 venue figures were *not* contaminated. The contaminated metric is `run_competition_calibration.gd`'s **banded §14.2 `home_win_rate`**, judged against 53–56% over fixtures where the home team also received every opening inbound — while the runner's own comment asserted that the measured home win rate was "the environment effect and nothing else". It was the environment plus the inbound. The comment now says what the fixture guarantees.

**What the inbound is worth.** `run_opening_possession.gd` measures it independently of the venue, on two audit ranges no other section owns (800,000–800,149 and 805,000–805,149). Six cells play one shared set of mirror fixtures at one shared set of seeds: environment on and off, crossed with the venue opening, the visitor opening, and the counterbalance itself. Pooled over ten samples (five levels × two ranges, 150 matched pairs each):

| Effect | Contrast, venue-opens minus visitor-opens | Value of receiving the inbound | Resolved at this sample |
| --- | ---: | ---: | --- |
| Win rate | +0.0347 ±0.0285 | **+1.73 percentage points** | **Yes** |
| Possessions per game | +0.400 ±0.340 | **+0.20** | **Yes** |
| Final margin | +0.912 ±0.925 | +0.456 points | No |
| Points per possession | −0.0046 ±0.0070 | −0.0023 | No |

The result is physically coherent rather than merely non-zero: the side that opens receives the extra odd possession, that is worth about half a point of margin, and **efficiency does not move**. More possessions, not better ones, which is the only shape this effect could honestly take.

**§14.2's band is three points wide.** An uncounterbalanced opener was worth 1.73 points of home win rate — more than half the width of the band it sat inside.

**The counterbalance is exact and the two effects are separable.** `venue_open_share` is 0.5000 at all five levels on both ranges, ten of ten. The opening-by-environment interaction covers zero in **nine of ten** samples (high school on range B is the exception at −5.767 ±4.002; one exceedance in ten at a 95% interval is what a correct control does). Separability is what licenses counterbalancing the inbound away without disturbing the venue estimate — it is checked, not assumed.

**The opening-possession effect was not subtracted from anything.** The corrected §14.2 figures below come from a fixture that never had it, which is a different and stronger claim than removing it arithmetically afterwards.

#### 2. The estimator: it was reading one arm of a matched pair

`paired_points_per_100` was formed from the home arm's gain over the neutral control. The reversed arm — an independent estimate of the same quantity, which the same report already printed — never entered the number §17.4 was judged against.

`VenueEffectEstimator` is that arithmetic, extracted so it can be tested against known answers. The published contribution is the mean of the two arm estimates:

```text
effect on A = margin_home[i]     - margin_neutral[i]
effect on B = margin_reversed[i] + margin_neutral[i]
```

**The control cancels from that mean** — `((h - n) + (r + n))/2 = (h + r)/2` — and that is the design working rather than an accident. A biased control cannot bias the contribution, which is exactly what licenses reading the neutral arm as an independent check on the fixture instead of as an input to the answer. The neutral arm remains required: a fixture missing any arm is refused, not estimated from what survived.

**That property is visible in the data.** High school on Validation C reads a raw home win rate of 0.5560 and a neutral control of 0.5560 — a marginal difference of exactly zero — while the paired estimate is 0.5360. The two-arm estimator cancels a fixture-side bias that the marginal comparison would have reported as "no home advantage at all".

The single-arm reading is still published, renamed `home_arm_points_per_100` and documented as not being what §17.4 is judged on, so the gap between the old metric and the corrected one stays visible rather than disappearing into a better number.

#### 3. The sample arithmetic, and two figures that were wrong

**"25,000 complete games" was a tenfold double count.** 250 games × 5 levels × 2 ranges is 2,500 games *per arm*; that figure was then multiplied by the ten samples already inside it.

| Quantity | §5.17 published | Actual |
| --- | ---: | ---: |
| Games per arm, per level, per range | 250 | 250 |
| Games per arm, all levels and ranges | 2,500 | 2,500 |
| Arms | 3 | 3 |
| **Total simulations executed** | **25,000** | **7,500** |
| **Unique paired fixtures** | not stated | **2,500** |

**"1.93 points per 100" was the defective metric's own output.** It is exactly the mean of the ten home-arm-only figures (19.307 / 10 = 1.9307). The same section's own two-arm recomputation averages 1.621. §17.4's published pass was quoted from the estimator that section diagnosed as broken two paragraphs later. `BALANCE_SPEC.md` §17.4 is corrected.

The runner now publishes both counts per level and pooled — `venue.matched_pairs` and `venue.complete_games` — with the definition stating explicitly that three arms of one fixture are three complete games and **one** piece of independent evidence. `sample_well_formed` and `sample_complete` pass at every level on both ranges: no fixture is missing an arm, none was observed twice, and no shard overlapped another.

**Pooling weights.** Every level contributes 250 pairs, so equal-weight and games-weighted pooling coincide. The pooled estimator is the unweighted mean of the per-fixture paired series over the union of fixture keys; keys carry the competition, so two levels at the same variation cannot merge.

**Ranges.** Validation A and B validated the channel *values* and nothing was tuned after reading them, which remains true. But they were read through a cap metric that no longer exists, so **two fresh ranges were opened after the estimator was frozen**: Validation C at 810,000–810,249 and Validation D at 820,000–820,249. Nothing here is fitted to anything; this is a measurement precaution, not a suspicion.

#### 4. Five levels, two untouched ranges, corrected estimator

250 matched pairs per level per range. Mirror fixtures, common random numbers, counterbalanced opening inbound.

| Level | Attributable home win rate, Val C | Val D | Venue points/100, Val C | Val D | Cap | Reversal |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| High school | 0.5360 ±0.0291 PASS | 0.5380 ±0.0287 PASS | 1.539 ±0.750 | 1.498 ±0.745 | PASS/PASS | PASS/PASS |
| College | 0.5340 ±0.0272 PASS | 0.5480 ±0.0266 PASS | 1.759 ±0.801 | 1.662 ±0.666 | PASS/PASS | PASS/PASS |
| Development | 0.5420 ±0.0281 PASS | 0.5440 ±0.0283 PASS | 1.485 ±0.727 | 1.624 ±0.662 | PASS/PASS | PASS/PASS |
| Overseas | 0.5400 ±0.0273 PASS | 0.5400 ±0.0273 PASS | 2.297 ±0.775 | 1.354 ±0.747 | PASS/PASS | PASS/PASS |
| Top domestic | **0.5640 ±0.0283 FAIL** | **0.5100 ±0.0251 FAIL** | 1.651 ±0.664 | 1.214 ±0.626 | PASS/PASS | PASS/PASS |
| **Pooled** | **0.5432 ±0.0125 PASS** | **0.5360 ±0.0122 PASS** | **1.729 ±0.331** | **1.460 ±0.307** | PASS/PASS | PASS/PASS |

| Range | Raw home win rate | Neutral control | Attributable | Raw margin | Paired margin |
| --- | ---: | ---: | ---: | ---: | ---: |
| Validation C | 0.5336 | 0.5072 | 0.5432 ±0.0125 | +1.540 | +1.435 ±0.275 |
| Validation D | 0.5336 | 0.4968 | 0.5360 ±0.0122 | +1.343 | +1.214 ±0.255 |

**The estimator repair is doing the work, and it is measurable.** Per-level intervals moved from ±0.0612–±0.0620 under the marginal estimator to ±0.0251–±0.0291 under the paired one — a 2.3× tightening on the same 250 games, which is the common-random-number pairing finally being used rather than thrown away.

#### 5. The two recorded failures do not survive correction

| Finding | §5.17, as published | Corrected estimator, Val C and D |
| --- | --- | --- |
| §17.4 cap | **2 breaches of 10** — overseas 2.801 and 3.498 | **0 breaches of 10**, plus both pooled. Overseas reads 2.297 and 1.354 |
| Venue reversal | **1 failure of 10** — overseas, Validation A | **0 failures of 10**, plus both pooled |

**Both were artifacts of the metric, not properties of the level.** §5.17 suspected this of the cap and recorded it as the first thing the next task on this section should change; it is now measured on fresh ranges rather than recomputed on the ranges that produced the suspicion.

#### 6. What is *not* resolved

**Top domestic fails the §14.2 band on both untouched ranges, in opposite directions.** 0.5640 on Validation C, 0.5100 on Validation D. The intervals do not overlap; the gap is **2.80 standard errors**. That is a genuine tension in the model rather than a reading artifact, and the pooled pass must not be read as covering it. **No parameter was changed for it.**

**The marginal metric and the corrected one disagree about which levels pass.** `home.win_rate` — the single-arm reading, still judged against §14.2 — fails at four of five levels on Validation C, while `venue.attributable_home_win_rate` passes at four of five on the same games. Re-pointing that band at the paired estimator is the consistent extension of the cap repair and is **recommended but not done**: which estimator judges a locked target is an owner decision, not a measurement one. **[Ruled on by the owner and enacted in §5.19.]**

#### 7. Regular-season §14.1 after the counterbalance

The counterbalance changes which games the population fixture plays, so top-domestic points per possession was re-measured on a fresh untouched 1,000-game range, 830,000–830,999.

| Range | Points per possession | Interval |
| --- | ---: | --- |
| 700,000–700,999 (§5.16, preserved) | 1.1863 ±0.0052 | [1.1811, 1.1915] |
| **830,000–830,999 (counterbalanced)** | **1.1831 ±0.0053** | [1.1778, 1.1884] |
| **Pooled, 2,000 games** | **1.1847 ±0.0037** | **[1.1810, 1.1884]** |

The measurement moved by −0.0032, which is **0.84 standard errors** — no change at all. The pooled interval sits entirely above the 1.1800 ceiling. **Top-domestic points per possession remains a genuine §14.1 failure and was not touched.** Possessions per game reads 101.7390 ±0.1535 and passes. On the same range the §14.2 population home win rate reads 0.5520 ±0.0308 and passes; overtime, close-game and blowout rates fail and sit inside the identity §5.13 already records for them, unchanged by this work and out of its scope.

#### 8. Tests and the mutation battery

`VenueEffectEstimator` carries 22 arithmetic tests on rows whose answers are known, and `test_opening_possession.gd` carries 12 contract tests. The strongest of the latter asserts that **nothing under `res://src` constructs a `MatchInput`**: if a scheduling layer ever does, the ruling in §1 above stops being true and somebody must write a real opening-possession rule into `SIMULATION_SPEC.md` rather than leaning on a fixture counterbalance.

Twelve mutations, run sequentially in an isolated worktree at `6eecd66` under a 300-second and 2,048 MB budget, each restored byte-clean with the worktree re-verified:

| # | Mutation | Outcome |
| --- | --- | --- |
| M1 | The fixture returns `home.team_id` unconditionally again | DETECTED, 4 tests |
| M2 | Counterbalance alternates on a period of 3 — "mostly" balanced | DETECTED, 3 tests |
| M3 | `points_per_100` returns the home-arm gain | DETECTED, 3 tests |
| M4 | Reversed arm differenced against the next fixture's control | DETECTED, 2 tests |
| M5 | `observe` overwrites a duplicate instead of refusing it | DETECTED, 2 tests |
| M6 | An overlapping shard is merged anyway | DETECTED, 1 test |
| M7 | The venue-reversal control can no longer fail | DETECTED, 1 test |
| M8 | Neutral guard weakened from `<= 0.0` to `< 0.0` | **EQUIVALENT** |
| M8b | A neutral court keeps `is_neutral()` true but gains a live channel | DETECTED, 1 test |
| M9 | A flat home shot bonus added to make probability | DETECTED, 1 test |
| M10a | Skip stops at the end of regulation instead of delegating | DETECTED, 1 test |
| M10b | Skip consumes an extra draw before delegating | **EQUIVALENT** |

Every baseline completed comfortably inside both budgets. **No mutation was scored on a timeout, a memory breach, or a crash.**

**Three results are worth recording in detail, because each exposed something a passing battery would have hidden.**

**M4 survived its first run, and the reason is not the obvious one.** The pairing test gave both fixtures the same neutral margin, so borrowing the neighbour's control cancelled identically. The deeper problem is that **the published mean cannot detect this class of defect at all**: shifting every control by one position cyclically changes fixture *i*'s gain by `(n[i+1] - n[i])/2`, and those differences sum to zero around the cycle. The mean is exactly unchanged while every per-fixture value is wrong. Only the series or its dispersion discriminates, so both are asserted now — the series value by value, and a second test requiring exactly zero dispersion on a sample where every fixture carries an identical effect.

**M10a survived a coverage gap that had nothing to do with the estimator.** A Skip that stops at the end of regulation produced byte-identical output on every fixture in the parity suite, because **the suite never played a game that reached overtime**. It is not an equivalent mutation — §23.4 forbids Skip reducing the result, and dropping the extra period is exactly that. The suite now runs all three executors over the `overtime` golden scenario's fixture and seed, asserting overtime actually occurred before comparing anything, and M10a is detected.

**M8 and M10b are equivalent, and the reasons are load-bearing.** `from_profile` builds every channel as `modifier × strength`, so at strength zero both branches construct an identical object and `is_neutral()` is true either way — no test can distinguish them and none should. `SeededRandomSource.derive` builds each possession's stream from the **immutable root seed** and a label and never reads the generator's mutable state, so consuming an extra draw before delegating cannot change any outcome. That is §23.5's resume-safety holding by construction, and a suite that "detected" it would be asserting something false.

#### 9. Classification of every conclusion

- **Structural:** the engine has no opening-possession behaviour; no `MatchInput` is constructed under `src/`; the estimator's arm symmetry, control cancellation, pair completeness, duplicate refusal and shard-overlap refusal; the counterbalance's determinism and its independence from any random source; executor parity through overtime. All proven by deterministic test.
- **Measured, below the §27.1 requirement:** every number in sections 1, 4 and 7 above. 250 matched pairs per level per range against a requirement of 100,000 complete games per competition.
- **Certified:** nothing. `venue.certification_sample_reached` reads **0.0075** — 750 complete games against 100,000 — and is published as a ratio precisely so that it cannot be read as a verdict.

#### 10. Golden ledgers

**Unchanged.** All six hashes and the ledger file's own SHA-256 (`9f56843a…`) are identical before and after, and `test_golden_ledgers.gd` passes 7 of 7. This work is instrumentation-only: it touched calibration fixtures, a calibration runner, a new calibration harness class, and tests. The golden scenarios are built by `MatchFixtureFactory`, not by `CompetitionCatalog`, so the fixture counterbalance cannot reach them — and no production resolver was modified at all.

### 5.19 The §14.2 home-win estimator: owner ruling enacted

Status: **Ruling enacted. No production value changed, no target changed, no measurement re-run — the same games now carry the verdict the ruling assigns.** Provisional measured evidence, not certification.

§5.18 recommended re-pointing the §14.2 home-win band at the paired estimator and explicitly declined to do it, on the grounds that which estimator judges a locked target is an owner decision. The owner has ruled:

> The §14.2 home-win target is judged by the controlled, symmetrized paired venue-side win estimator. The marginal single-arm `home.win_rate` remains an informational population diagnostic and does not independently determine the home-environment calibration verdict.

#### The canonical estimator, and the form the code uses

The ruling defines the judged quantity as

```text
0.5 × [ P(designated venue side wins when the environment favours it)
      + P(opposite venue side wins when the environment is reversed) ]
```

The implementation uses the paired-fixture form, and the two are **identical rather than approximately equal**:

```text
paired_win_gain[i] = 0.5 × ((wv(hᵢ) − wv(nᵢ)) + (wv(rᵢ) − wv(−nᵢ)))
                   = 0.5 × (wv(hᵢ) + wv(rᵢ) − 1)        since wv(n) + wv(−n) = 1
estimate           = 0.5 + mean_i(paired_win_gain[i])
                   = 0.5 × (mean_i wv(hᵢ) + mean_i wv(rᵢ))
```

which is the canonical form with no approximation. `win_value` scoring a tie as 0.5 is what makes `wv(n) + wv(−n) = 1` hold for *every* margin, and therefore what makes the reduction exact; any other tie convention would turn the identity into an approximation. `VenueEffectEstimator.canonical_venue_win_rate` computes the reduced form directly, a unit test asserts the two agree, and every report now publishes `venue.canonical_form_agrees` so a divergence would show up in the run rather than only in a test.

**The identity was checked against the measured data before it was asserted.** Across all ten level×range samples from §5.18, `0.5 × (home-arm win rate + reversed-arm win rate)` reproduces the published `attributable_home_win_rate` exactly:

| Level | Val C: 0.5 × (home + reversed) | Published | Val D: 0.5 × (home + reversed) | Published |
| --- | ---: | ---: | ---: | ---: |
| High school | 0.5 × (0.5560 + 0.5160) = 0.5360 | 0.5360 | 0.5 × (0.4880 + 0.5880) = 0.5380 | 0.5380 |
| College | 0.5 × (0.5120 + 0.5560) = 0.5340 | 0.5340 | 0.5 × (0.5480 + 0.5480) = 0.5480 | 0.5480 |
| Development | 0.5 × (0.5240 + 0.5600) = 0.5420 | 0.5420 | 0.5 × (0.5560 + 0.5320) = 0.5440 | 0.5440 |
| Overseas | 0.5 × (0.4880 + 0.5920) = 0.5400 | 0.5400 | 0.5 × (0.5880 + 0.4920) = 0.5400 | 0.5400 |
| Top domestic | 0.5 × (0.5880 + 0.5400) = **0.5640** | 0.5640 | 0.5 × (0.4880 + 0.5320) = **0.5100** | 0.5100 |

#### The published contract

| Element | Definition |
| --- | --- |
| Formula | `0.5 + mean_i(paired_win_gain[i])`, identical to the canonical form above |
| Denominator | Matched fixtures carrying all three arms. **Not simulations** — one fixture is three complete games and one observation |
| Arm construction | `home` = venue A at strength `E`; `neutral` = same fixture at strength `0`; `reversed` = venue B at strength `E`. Identical rosters, identical seeds, opening inbound counterbalanced and constant across arms |
| Ties | Win 1, loss 0, tie 0.5. A completed game is never a tie; defined for totality and to keep the reduction exact |
| Weighting | Weight 1 per matched pair. Not reweighted by level size, not weighted by report count |
| Interval | 1.96 × SE of the per-fixture paired series |
| Pooling | Union of fixture keys; overlapping keys refused rather than double-counted |

#### Roles of the two metrics

| Metric | Role | Target |
| --- | --- | --- |
| `venue.attributable_home_win_rate` | **Judged.** Carries the §14.2 verdict | 0.530–0.560 |
| `home.win_rate` | **Informational** population diagnostic. Still published | none |

`home.win_rate` stays in every report. Removing it would delete the evidence that the two estimators disagree, which is the thing most worth keeping: at overseas on Validation C the marginal reading is **0.4880** while the judged reading on the same games is **0.5400**. A single arm carries the fixture, the rosters and the seeds along with the venue, so it can fail while the venue contribution is correct.

**Metric identity and schema.** The id `%s.home.win_rate` is unchanged deliberately. `report_aggregator` buckets by id and refuses to pool metrics whose targets differ across shards, so an old stored shard meeting a new one fails loudly rather than silently pooling a judged metric with an informational one. The home-court runner is single-shard in any case — `set_shard(0, 1, …)`, no `--shard` option — so nothing aggregates it today.

#### What the ruling does not change

No home-environment production value moved. Neutral venue remains exactly neutral, the three authorized channels are untouched, counterbalancing remains exact at 0.5000, venue reversal remains a published control, and the ≤2.5 points-per-100 paired contribution cap is unchanged and still judged on the paired contribution. The §14.2 band itself is still 0.530–0.560; only the estimator reading it moved, and a test pins the band values so a future edit cannot quietly widen them.

#### The top-domestic disagreement is preserved, not resolved

| Range | Judged estimate |
| --- | ---: |
| Validation C (810,000–810,249, 250 pairs) | **0.5640** |
| Validation D (820,000–820,249, 250 pairs) | **0.5100** |
| **Combined, 500 matched pairs** | **0.5370** |

The combined figure sits inside 0.530–0.560, and that is **not** a resolution of the disagreement. The two ranges are 2.80 standard errors apart with non-overlapping intervals; a midpoint that lands in band is arithmetic, not agreement. **Classification: provisional measured evidence.** It is not certification, and §27.1's requirement of 100,000 complete games per competition is untouched — 500 matched pairs is 1,500 complete games.

#### Tests

Nine assertions across two suites, six of them named by the ruling:

- the paired estimator, not the marginal metric, carries the target and the verdict;
- the marginal metric returns `informational` for values from 0.0 to 1.0 and can never fail the gate;
- a disagreement between the two is resolved by the judged metric alone;
- the judged metric still fails on a genuinely wrong venue effect — the ruling moves which metric decides, it does not make the gate unfailable;
- reversing which arm is called `home` preserves the estimate and its interval exactly;
- a control biased to hand every game to the nominal home side leaves the judged estimate unmoved while the marginal reading goes to 1.0;
- missing, duplicated, mismatched and overlapping pairs all leave the judged number untouched;
- pooling weights by matched pair, not report — a 190-pair shard at 1.00 pooled with a 10-pair shard at 0.00 gives 0.95, not 0.50;
- the §14.2 band is still 0.530–0.560.

Two of these caught defects in their own first drafts. The biased-control test initially used a margin of zero for every control game, which is a *tie* rather than a neutral result: `decided_games` stayed at zero and the marginal rate read 0.0000 instead of 0.5000. And the source-shape test used a fixed character window to find which constructor emitted a metric, which straddled unrelated code and reported whichever constructor happened to be nearby — replaced with a backward search to the nearest enclosing `CalibrationMetric.` call.

### 5.20 Defenders barely determined the contest, and that was the points-per-possession excess

Status: **Diagnosed from the ledger, corrected in one shared production value, validated on two untouched 1,000-game ranges. Top-domestic points per possession is inside its §14.1 band with margin on both. Zero §14.1 verdict changes at any of the five levels. One golden hash of six moved, with first-divergence evidence.** Measured, not certified.

§5.18 closed the home-court measurement and left top-domestic points per possession recorded as a genuine failure of about +0.0047 — pooled **1.1847 ±0.0037** over 2,000 games against a 1.08–1.18 ceiling, interval entirely above it. This section finds the cause and corrects it.

#### 1. The accounting decomposition

A number that misses by four ten-thousandths of a point per possession cannot be diagnosed by looking at points per possession. `PppDecomposition` takes it apart from the **ordered ledger** and the possession records — never the box score, because a decomposition that trusted a projection would be checking the projection — into terms that sum back exactly:

```text
PPP = 2PT points/possession + 3PT points/possession + FT points/possession
```

Three identities are enforced rather than assumed, and a breach is published rather than absorbed:

```text
2PT points + 3PT points + FT points   == ledger points
sum(possession_record.points_scored)  == ledger points
count(POSSESSION_ENDED)               == count(possession records)
```

plus a third independent check against the box score, and a requirement that every field-goal result be preceded by an attempt in the same possession.

**The gate fired on its first ten games.** The decomposition was reading `event.points` on `FREE_THROW_MADE`, which the ledger leaves at **zero** — a free throw's value is carried by the event type, and `amount` holds the attempt index. About thirty points a game, silently missing. An accounting that had quietly absorbed that would have added up and been wrong, which is worse than no accounting at all.

#### 2. Where the excess is, and where it is not

400 games per level on diagnosis ranges 840,000–840,399 and 845,000–845,399:

| Term | Top domestic | Overseas | Δ |
| --- | ---: | ---: | ---: |
| **PPP total** | **1.1726** | **1.1204** | **+0.0522** |
| 2PT ppp | 0.6173 | 0.5975 | +0.0198 |
| 3PT ppp | 0.3898 | 0.3572 | +0.0326 |
| FT ppp | 0.1655 | 0.1657 | −0.0002 |

**It is not a top-domestic defect.** Zone *shares* match overseas within ±0.006 while zone *accuracy* is uniformly higher in every zone (+0.012 to +0.029) — exactly what a four-point roster-rating gap through a **shared** balance profile produces. The measured level gap (0.0643) matches the §14.1 band-midpoint gap (0.0650). The level relationship was already right; top domestic breaches first because its band is **77% as wide** as overseas'.

**And top domestic is not getting easier shots** — it carries *more* contest pressure than overseas (mean penalty 0.0522 against 0.0490). Its efficiency edge is entirely shooter quality.

Ruled out on measurement rather than argument:

| Hypothesis | Evidence against |
| --- | --- |
| Offensive-rebound extensions | Extension rate **lower** at top domestic, 0.1111 vs 0.1128 |
| Turnovers | 0.1402 vs 0.1410 — flat |
| Free throws | FT ppp −0.0002; FT attempt rate at 12% of its band |
| Three-point volume | 3PAr at the band **floor** (0.3614 vs 0.36–0.49). A three returns 1.137 points an attempt against a two's 1.019, so *more* threes would raise PPP — the low rate suppresses it |
| Transition, putbacks, second chance, garbage time, foul-generated trips | All within noise of overseas |

#### 3. The cause: the contest-band distribution

| Band | Penalty | Top domestic share / accuracy | Overseas share / accuracy |
| --- | ---: | --- | --- |
| open | 0.000 | 29.98% / 61.70% | 32.15% / 58.89% |
| light | 0.040 | 34.81% / 45.92% | 34.86% / 42.71% |
| moderate | 0.100 | 32.18% / 34.89% | 30.86% / 32.31% |
| heavy | 0.200 | **3.03%** / 28.90% | **2.12%** / 23.44% |
| smothered | 0.365 | **0.00%** | **0.00%** |

Two thirds of every attempt at every level resolves `OPEN` or `LIGHT`, and `SMOTHERED` never happens at all. **The bands are not the problem** — accuracy falls correctly and steeply across them. The distribution feeding them is.

The mechanism is in `ShotResolver.build_contest`:

```text
pressure = 0.38 + (capability − 0.5) × 0.35 + reach + help×0.55 − advantage×0.55
bands at 0.20 / 0.40 / 0.60 / 0.82
```

At a span of 0.35 the **entire** capability range moves pressure by at most ±0.175 — less than one band width. The best perimeter defender in the league and the worst produced contests under one band apart. `SIMULATION_SPEC.md` §12.3 says contest "is created from actual defensive positioning and capabilities"; at 0.35 it substantially was not.

#### 4. Choosing the correction

Both candidate tunables were measured on **matched fixtures at identical seeds** on tuning range 850,000–850,199, so a cell-to-cell difference is the tunable with roster, matchup and draw sequence cancelled.

| Tunable | Value | ΔPPP | ΔFG% | PPP per FG% | heavy | smothered |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| *(baseline)* | span 0.35 | — | — | — | 2.79% | 0.00% |
| `capability_span` | 0.50 | −0.0096 | −0.0064 | 1.50 | 5.04% | 0.00% |
| `capability_span` | 0.65 | −0.0456 | −0.0264 | 1.73 | 12.00% | 0.75% |
| `advantage_relief` | 0.45 | −0.0167 | −0.0102 | 1.64 | 2.83% | 0.00% |
| `advantage_relief` | 0.35 | −0.0326 | −0.0193 | 1.69 | 3.23% | 0.00% |

**`advantage_relief` was rejected on evidence.** It cannot produce heavy contests at any value — `heavy` stays pinned at 2.8–3.2% while it merely shuffles shots between open, light and moderate — and it costs more field-goal percentage per unit of points per possession.

#### 5. The value was chosen twice, and the first choice is the interesting part

**0.52 was frozen and validated first, and it passed.** Both untouched ranges returned PPP inside band with every §14.1 row passing. It was still the wrong value.

Field-goal percentage landed at 0.4528 and 0.4510 against a **0.4500 floor** — 0.0010 to 0.0028 of headroom, with one range's interval lower bound at 0.4488, beneath the floor. The two bands are coupled: contest pressure moves FG% roughly 1:1 and PPP 1.59:1, so the feasible window is narrow —

```text
FG% floor 0.4500  ⟹  PPP ≥ ~1.161
PPP ceiling 1.1800 ⟹  FG% ≤ ~0.4633
```

— and 0.52 sat at the bottom of it. Across the four measured pre-change ranges the expected position at 0.52 leaves roughly a **7% chance per 1,000-game range of breaching a locked band**. Passing twice on that is not a corrected calibration.

**The paired before/after is what made the decision possible.** Running the pre-change value on the identical validation fixtures gave three different estimates of the same effect:

| Method | ΔPPP |
| --- | ---: |
| 200-game tuning grid, CRN | −0.0118 |
| Naive cross-range subtraction | −0.0247 |
| **Paired, identical seeds, 2,000 games** | **−0.0170** |

The spread is entirely seed-range variation (~0.005 on this metric). Neither uncontrolled estimate was trustworthy, and this is the same class of error §5.18 corrected in the "25,000 games" and "1.93 points per 100" figures.

**0.46 centres the window** and lifts the worst margin from 1.5σ to 2.2σ. Ranges **860,000–865,999 are recorded as tuning ranges** because they informed that choice; they are not quoted as validation for the shipped value.

#### 6. The correction

**`contest_capability_span: 0.35 → 0.46`.** One value, in the one balance profile every competition shares. Ruleset bumped to `simulation-v8-contest-capability`.

At 0.46 the capability range spans ±0.26 — more than a full band — so a good defender and a poor one now produce genuinely different contests. Nothing else moved: `contest_base_pressure`, `contest_advantage_relief` and `contest_help_weight` are untouched, as is every shooting, turnover, rebounding and assist term.

#### 7. Validation, on ranges opened after the value was frozen

1,000 top-domestic games each.

| Metric | Val A (870,000) | Val B (875,000) | Pooled | Band |
| --- | ---: | ---: | ---: | --- |
| **Points per possession** | **1.1686 ±0.0053** | **1.1701 ±0.0051** | **1.1694 ±0.0037** | 1.08–1.18 **PASS** |
| Field-goal percentage | 0.4587 | 0.4590 | 0.4588 | 0.45–0.51 PASS |
| Three-point percentage | 0.3781 | 0.3793 | — | 0.34–0.40 PASS |
| Three-point attempt rate | 0.3617 | 0.3622 | — | 0.36–0.49 PASS |
| Free-throw percentage | 0.7989 | 0.8029 | — | 0.73–0.83 PASS |
| Free-throw attempt rate | 0.2196 | 0.2206 | — | 0.18–0.34 PASS |
| Turnovers per 100 | 13.8457 | 13.8551 | — | 11–16 PASS |
| Offensive rebound % | 0.2528 | 0.2522 | — | 0.20–0.31 PASS |
| **Assist percentage** | **0.5838** | **0.5839** | — | 0.52–0.72 PASS |
| Possessions per game | 101.5805 | 101.6595 | — | 96–103 PASS |
| Home win rate | 0.5360 | 0.5370 | — | 0.53–0.56 PASS |

Margins: **0.0106 below the points-per-possession ceiling** and **0.0088 above the field-goal floor**, roughly 2.1 and 4.5 range-standard-deviations respectively.

#### 8. Five-level regression: zero verdict changes

Paired before/after on one shared range, 880,000–880,249, 250 games per level.

| Level | PPP before → after | Δ | Field-goal % verdict |
| --- | ---: | ---: | --- |
| High school | 0.9574 → 0.9594 | **+0.0020** | FAIL → FAIL (pre-existing) |
| College | 1.0424 → 1.0443 | **+0.0019** | FAIL → FAIL (pre-existing) |
| Development | 1.1123 → 1.1083 | −0.0040 | PASS → PASS |
| Overseas | 1.1140 → 1.1084 | −0.0056 | PASS → PASS |
| **Top domestic** | **1.1784 → 1.1683** | **−0.0101** | PASS → PASS |

**Not one of the 45 §14.1 rows changed verdict.** The two field-goal failures at high school and college fail on *both* sides, which is why the paired run was necessary rather than simply showing that the current verdicts pass. Assist percentage moves by at most 0.0035 anywhere; turnovers and offensive rebounding are flat.

**The effect is monotone in roster strength and pivots at college**, because capability centres near 0.5 there. Scoring rising slightly where defenders are poor and falling where they are good is the mechanism behaving correctly, and it was deliberately **not** cancelled — an offset there would be exactly the compensation defect the correction was chosen to avoid.

#### 9. Golden ledgers: one hash of six, with first-divergence evidence

| Scenario | Seed | Hash | Status |
| --- | ---: | --- | --- |
| regulation | 20260815 | `52dfdb1a…` | unchanged |
| overtime | 190056 | `ab37ad08…` | unchanged |
| offensive_rebound | 7001 | `5dbd798f…` | unchanged |
| foul_free_throw | 4242 | `31ce2e07…` | unchanged |
| **substitution_foul_out** | 31337 | `42586a2a…` → **`f03f1a3a…`** | **changed** |
| late_game | 8675309 | `af3f5cc9…` | unchanged |

**First divergence: event 423**, after 422 byte-identical events.

```text
OLD  possession_ended | away | made_score
NEW  foul | home_p14 on away_p12 | shooting | restricted_rim
```

A tighter rim contest draws a shooting foul where the old value allowed a clean score. Pressure feeds `legal_contact`, so this is the corrected mechanism visible in the ledger rather than unexplained churn.

**Why only one moved.** The pressure shift is `(capability − 0.5) × 0.11`, and the golden fixtures are built at ratings 72 and 70 — defenders near the capability centre — so their shift is small and flips an outcome only where a draw already sat near a threshold. Regenerated through `golden_ledger_harness.gd`, which verified every scenario still exercises the behaviour it is named for; **no reseeding was required**.

#### 10. What this does not fix

**The `SMOTHERED` gap is structural, not a tuning shortfall.** It rises from 0.00% to a fraction of a per cent and no value of this tunable closes it, because `build_contest` applies `help_pressure` **only when the shot is interior**. A perimeter jumper has no help or closeout term at all and essentially cannot reach the 0.60 `HEAVY` threshold. Closing that is a new mechanism and separate work; it is recorded in the tunable's own documentation rather than bundled in here.

#### 11. Tests and mutations

Eleven tests in `test_ppp_decomposition.gd` covering the accounting identity, possession-denominator reconciliation against three independent sources, the correction moving the component it was chosen for, unrelated components not moving, per-competition rule profiles against the shared balance profile, the absence of any competition-identity or calibration-target read in the contest path, the absence of any scoreboard read in `build_contest`, and every golden scenario still exercising its named behaviour. The reconciliation gate is itself tested for its ability to *fail*.

Thirteen mutations, sequential, isolated worktree at `6f7c02e`, 600-second and 2,048 MB budgets, every baseline comfortable, each restored byte-clean:

| # | Mutation | Outcome |
| --- | --- | --- |
| N1 | The marginal `home.win_rate` becomes judged again | DETECTED |
| N2 | The paired estimator loses its target | DETECTED |
| N3 | The canonical form reads the neutral arm instead of the reversed arm | DETECTED |
| N4 | A tie scores as a loss, breaking `wv(n) + wv(−n) = 1` | DETECTED |
| N5b | Merge takes every second fixture, weighting by report | DETECTED |
| N6 | The correction is reverted to 0.35 | DETECTED |
| N7 | The ruleset is not bumped alongside the behaviour change | DETECTED |
| N8 | A free throw is worth zero points again | DETECTED |
| N9 | The accounting identity can no longer fail | DETECTED |
| N10 | Contest pressure stops reading defender capability | DETECTED |
| N11 | A competition-scoped scoring hack keyed on `top_domestic_pro` | DETECTED |
| N12 | Contest pressure reads the scoreboard | DETECTED |
| N13 | A golden hash is edited | DETECTED |

**No mutation was scored on a timeout, a memory breach, or a crash.** One earlier attempt at N5 survived and was withdrawn rather than reported as a test gap: it guarded the mutated branch with `randf() < -1.0`, which is always false, making it dead code and an equivalent mutant by construction. N5b is the same defect written so that it actually executes.

#### 12. Classification

- **Structural:** the accounting identities and their ability to fail; the contest path's inability to read a competition identity, a calibration target, or the scoreboard; the shared balance profile against per-competition rule profiles; every golden scenario still exercising its named behaviour.
- **Measured, below the §27.1 requirement:** every number in sections 2, 3, 4, 7 and 8. Validation is 1,000 top-domestic games per untouched range against §27.1's 100,000 per competition.
- **Certified:** nothing.

#### 13. The venue effect after the correction, re-measured

The §14.2 paired venue figures in §5.18 and §5.19 were all measured under ruleset `simulation-v7-home-environment`. The contest correction changes shot conversion, and §19.4's channels move probabilities that a heavier contest has already pushed down, so there is a real mechanism by which the venue effect could move. It was re-measured rather than assumed.

Validation C (810,000–810,249), 250 matched pairs per level — the same fixtures and seeds §5.18 used, with only the ruleset differing, so this is a controlled before/after and not two independent samples.

| Level | v7 attributable | v8 attributable | Δ | Verdict |
| --- | ---: | ---: | ---: | --- |
| High school | 0.5360 | 0.5440 | +0.0080 | PASS → PASS |
| College | 0.5340 | 0.5380 | +0.0040 | PASS → PASS |
| **Development** | 0.5420 | **0.5160** | **−0.0260** | **PASS → FAIL** |
| Overseas | 0.5400 | 0.5360 | −0.0040 | PASS → PASS |
| **Top domestic** | 0.5640 | **0.5380** | −0.0260 | **FAIL → PASS** |
| **Pooled** | **0.5432** | **0.5344 ±0.0127** | −0.0088 | **PASS → PASS** |

| Control | v7 | v8 |
| --- | --- | --- |
| §17.4 cap respected | 5 of 5 and pooled | **5 of 5 and pooled** |
| Venue reversal agrees | 5 of 5 and pooled | **5 of 5 and pooled** |
| Canonical form agrees | — | **5 of 5 and pooled** |
| Pooled contribution, points per 100 | 1.729 | **1.396** against a 2.5 cap |

**Preserved at the pooled level, which is the level §5.19 classified the evidence at.** The venue-attributable win rate stays inside 53–56%, the cap holds everywhere with more headroom than before, and the reversal control is clean.

**One level changed verdict, and it is recorded rather than averaged away.** Development fell 0.0260 and now sits 0.0140 below the floor; its own interval of ±0.0293 covers the band, so at 250 pairs this is a marginal failure and not a resolved one. Top domestic moved the same 0.0260 in the other direction and crossed *into* the band. The count of levels outside the band is unchanged at one; which level it is has moved.

**The direction is a real interaction, not sampling.** The pooled contribution fell from 1.729 to 1.396 points per 100. A heavier contest lowers make probability, and §19.4's officiating, communication and composure channels act on probabilities that have already been pushed down, so the venue is worth slightly less when shots are better defended. That is two authorized mechanisms interacting; it moves the cap metric *away* from its limit rather than toward it, and no §19.4 value was touched to produce it.

**What this does not establish.** ~~One range at 250 pairs per level cannot separate the development movement from range scatter, and §5.19 already recorded that individual levels are draws from an interval while the pooled figure is the measurement. A second untouched range under `v8` would settle whether development's fall is the interaction or the draw; it has not been run, and no claim is made either way.~~ **Superseded by §5.21**, which ran that second range. Development reads **0.5400** on Validation D and **0.5280 ±0.0206 pooled over 500 matched fixtures**; the two ranges are statistically indistinguishable (−0.0240 ±0.0412), so the answer is neither "the interaction" nor "the draw" as posed — the pooled estimate sits 0.0020 below the floor with an interval that covers the band.

**Process note.** This measurement was missing from the first completion report, which asserted that the paired estimator and cap were preserved on the strength of the *marginal population* home win rate passing on the points-per-possession validation ranges. That is a different metric on a different fixture, and §5.17 had already established it is the wrong measurement for §14.2's even-team row. The claim was corrected by measuring it.
### 5.21 The second range was run, and pooled Development sits two thousandths below the floor

§5.20 §13 left exactly one thing open, in its own words: "one range at 250 pairs
per level cannot separate the development movement from range scatter … a second
untouched range under `v8` would settle whether development's fall is the
interaction or the draw; it has not been run, and no claim is made either way."

It has now been run. **Only Development, only Validation D, only under the
current `simulation-v8-contest-capability` ruleset.** No other level was
re-measured, no new seed range was opened, no unrelated calibration was rerun,
and no production value was changed under any result.

#### 1. Development on Validation D

Validation D is 820,000–820,249: the range §5.18 already documented, disjoint
from Validation C and from every range §5.7–§5.16 used. 250 matched fixtures,
three arms each — home, neutral, reversed — at identical seeds, ratings, rosters
and counterbalanced opening possession, for 750 complete simulations.

| Required check | Result |
| --- | ---: |
| `venue.attributable_home_win_rate` | **0.5400** |
| 95% interval, paired-fixture series | **±0.0290** → [0.5110, 0.5690] |
| `venue.points_per_100` | **1.6018 ±0.6515** |
| §17.4 cap verdict against ≤2.5 | **PASS** |
| Venue-reversal agreement | **PASS** |
| Canonical-form agreement | **PASS** |
| `sample_well_formed` | **true** |
| `sample_complete` | **true** |
| Unique matched pairs | **250** |
| Complete simulations | **750** |
| Marginal `home.win_rate` | 0.5440 ±0.0617 — **INFORMATIONAL, cannot fail the gate** |

**Validation D passes the §14.2 band.** Every control is clean: the sample is
well formed and complete, the canonical form agrees with the paired form to
better than 1e-9, the reversal agrees, and the cap holds with a point estimate
less than two-thirds of its limit.

#### 2. Pooling C and D, over fixtures rather than over reports

Validation C was re-run under the same ruleset and **reproduced §5.20 §13
exactly: 0.5160 ±0.0293**, to the digit. That is the controlled starting point,
not a new observation.

The two ranges were then combined **over the union of their per-fixture paired
observations**, weight 1 per matched fixture, by the same `VenueEffectEstimator`
that judged each range on its own. Averaging the two published rates was
explicitly not done: an average weights by report rather than by fixture, cannot
form the pooled interval — which is a property of the combined per-fixture
series — and cannot detect a shared fixture. The union was verified disjoint:
**zero overlapping fixture keys**, so 500 pairs is the sum of the parts and not
a number the estimator quietly shrank.

| | Validation C | Validation D | **Pooled C+D** |
| --- | ---: | ---: | ---: |
| Matched fixtures | 250 | 250 | **500** |
| Complete simulations | 750 | 750 | **1,500** |
| Attributable home win rate | 0.5160 ±0.0293 | 0.5400 ±0.0290 | **0.5280 ±0.0206** |
| 95% interval | [0.4867, 0.5453] | [0.5110, 0.5690] | **[0.5074, 0.5486]** |
| Points per 100 | 1.0865 ±0.7416 | 1.6018 ±0.6515 | **1.3448 ±0.4935** |
| §14.2 band verdict | **FAIL** | PASS | **FAIL** |
| §17.4 cap verdict | PASS | PASS | **PASS** |
| Reversal / canonical / well-formed / complete | PASS | PASS | **PASS** |

**C versus D: −0.0240 ±0.0412**, interval [−0.0652, +0.0172], z = −1.14. The
interval covers zero, so **the two ranges are not distinguishable** and the
per-range spread is scatter, exactly as §5.19 said individual levels behave.
What the second range settled is not that C was anomalous — it is that neither
range is anomalous, and the pooled estimate is the measurement.

#### 3. v7 → v8

| Range | v7 attributable | v8 attributable | Δ |
| --- | ---: | ---: | ---: |
| Validation C | 0.5420 | 0.5160 | −0.0260 |
| Validation D | 0.5440 | 0.5400 | −0.0040 |
| **Combined** | **0.5430** | **0.5280** | **−0.0150** |

| Range | v7 points per 100 | v8 points per 100 |
| --- | ---: | ---: |
| Validation C | 1.485 | 1.0865 |
| Validation D | 1.624 | 1.6018 |

The combined v7 figure is **derived, not re-measured**: v7's per-fixture
observations were not retained, and re-running them would mean reverting the
ruleset. Because both v7 ranges carry exactly 250 matched fixtures, the
equal-weight union of their fixtures is arithmetically identical to the mean of
their two rates, so 0.5430 is exact for this pooling rule rather than an
average standing in for one. It is labelled derived wherever it is quoted.

**The v7→v8 movement is concentrated almost entirely in Validation C.** D moved
four ten-thousandths and its contribution barely moved at all. That is a further
reason not to read C's fall as the interaction acting uniformly.

#### 4. The verdict

**Pooled Development C+D reads 0.5280 against a floor of 0.5300 — short by
0.0020.** Under the decision rule this is a **measured contest/home-environment
interaction blocker**, and it is recorded as one.

It is recorded with its uncertainty rather than as a settled deficit: the pooled
95% interval [0.5074, 0.5486] **covers the band**, and the miss is two
thousandths of a win rate at 500 matched fixtures. This is a point estimate
below a floor, not a demonstrated structural failure to produce a home
advantage. §27.1 asks for 100,000 complete games per competition; 1,500 is 1.5%
of that.

**Nothing was tuned for it.** `contest_capability_span` is unchanged, every
§19.4 channel value is unchanged, the §14.2 band and §17.4 cap are unchanged,
the contest correction was not reverted, and no production simulation code was
touched.

#### 5. Channel decomposition: which channel the interaction reaches

§19.4's three implemented channels and their profile values are unchanged —
officiating 0.009, communication 0.013, composure 0.008, summing to 0.030
against the 0.09 structural budget `HomeEnvironmentContext` enforces. Each acts
on a different observable, so the venue side's arm-to-arm differences say which
ones are still delivering.

| Channel | Observable it moves | C (home − neutral) | D (home − neutral) | Reading |
| --- | --- | ---: | ---: | --- |
| Communication | Turnovers per 100 | **−0.393** | **−0.432** | Delivering, stable across ranges |
| Officiating | Free-throw attempt rate | **+0.0144** | **+0.0113** | Delivering, stable across ranges |
| Composure | Field-goal percentage | **−0.0023** | **−0.0018** | **Flat to slightly negative in both ranges** |

**The two channels that act on discrete, countable events are intact; the one
that routes through shot conversion is not visible.** Communication moves
unforced pass error and officiating moves the conversion of an existing foul
opportunity — neither passes through the contest — and both reproduce their
expected sign and rough size on both ranges. Composure applies execution noise
to resolutions that include shooting, and field-goal percentage at home is flat
to marginally *negative* against the same fixture at a neutral court, on both
ranges independently.

That is precisely the mechanism §5.20 §13 recorded, localized: making defender
capability determine the contest means shot make probability is more determined
by the defensive contest and correspondingly less movable by a small composure
nudge. The channels that never touch the contest are unaffected; the one that
does is diluted.

Expressed in the units §17.4 is written in, the pooled venue is worth **1.285
points a game** paired, against the **1.36 to 1.71 points a game** §17.4 records
as the range consistent with a 53–56% band. The shortfall in the win rate and
the shortfall in the margin are the same shortfall.

**A caution on this decomposition.** The field-goal differences are ~0.002 at
250 fixtures per range and are individually inside noise. What carries weight is
that the sign is the same on two disjoint ranges while the other two channels
reproduce cleanly on both — not the magnitude of any single cell. This is
directional evidence about where to look, not a measured per-channel budget.

#### 6. The reversal control, and why the arm split is not a defect

| | Home-arm win value | Reversed-arm win value | Canonical 0.5 × (h + r) |
| --- | ---: | ---: | ---: |
| Validation C | 0.5400 | 0.4920 | 0.5160 |
| Validation D | 0.5440 | 0.5360 | 0.5400 |
| **Pooled** | **0.5420** | **0.5140** | **0.5280** |

C and D disagree about which arm carries more of the effect, and **they disagree
in opposite directions**: C's margin gain is +1.284 from the home bench against
+0.788 reversed, D's is +0.892 against +2.176. Pooled, the gap is −0.394 against
a combined reach of 1.547. Every one of those agreements passes, including at
the pooled level. An effect attached to a roster rather than to a building would
show a consistent sign here; this flips, which is what scatter looks like.

#### 7. Instrumentation added, and what it does not touch

Correct fixture-level pooling was not possible from the existing artifacts:
neither the arm rows nor the estimator payload carried per-fixture observations,
only summary means, and pooling from summary means is the thing this section
must not do. Three additions, all measurement-side:

- `VenueEffectEstimator.fixture_rows()` — exposes the per-fixture triples the
  estimate was already formed from. Incomplete fixtures are omitted, for the
  same reason they contribute to nothing else.
- `--emit-pairs` on `run_home_court_diagnostics.gd` — **off by default**, so
  every existing report keeps its present shape. It also now states progress
  every 50 matched pairs, because a 750-game run that prints nothing is
  indistinguishable from a hung one.
- `calibration/runners/run_venue_pooled_estimate.gd` — replays emitted
  observations into the authoritative estimator and pools with `merge`, the
  union of fixture keys, refusing overlaps. It simulates nothing.

The pooling runner **re-derives each source range from its own emitted rows and
compares against what that range's report published**, as a judged metric rather
than a note: both ranges reproduced to better than 1e-9. An independent
recomputation of the canonical form, written from the §14.2 ruling rather than
from the GDScript, agrees with the engine to 0.0 on the rates and ~1e-15 on
points per 100.

Three tests were added for the round-trip property the pooling rests on:
replayed rows rebuild an identical estimator, incomplete fixtures never appear
in emitted rows, and pooling from rows matches pooling estimators directly.

No production simulation code was changed. **All six golden ledger hashes are
byte-identical** — verified by recomputation in the acceptance suite, not by
inspecting the file.

#### 8. Classification

- **Structural:** the pooling rule — union of fixture keys, weight 1 per matched
  fixture, overlaps refused — and its tests; the reproduction check binding
  emitted rows to published estimates; the §19.4 channel bound.
- **Measured, below the §27.1 requirement:** every number in this section.
  1,500 complete Development games against §27.1's 100,000 per competition, and
  Development only.
- **Certified:** nothing.

#### 9. What this does not establish

Development is one level of five. This section says nothing about the other
four under `v8` beyond what §5.20 §13 already recorded on Validation C, and
nothing about the five-level pooled figure on Validation D, which was not run.
The pooled five-level Validation C result remains §5.20 §13's 0.5344 ±0.0127,
inside the band.

### 5.22 One of the two field-goal failures is not a failure, and the other one is not a defect

Status: **High school does not reproduce as a repeatable failure and is
reclassified. College reproduces on every range run and is confirmed. Neither
has a causal defect in production, so no production value was changed and all
six golden hashes are byte-identical.** Measured, not certified.

Both levels have carried a §14.1 field-goal-percentage failure across several
rulesets, and §5.20 §8 recorded them together as "FAIL → FAIL (pre-existing)"
without publishing either number. They were treated here as two separate
questions, and they turned out to have two different answers.

#### 1. What was published before

| Section | Ruleset | Level | Field-goal % | Band floor |
| --- | --- | --- | ---: | ---: |
| §5.10 | `v3`/`v5` | High school | 0.3932 ✓ | 0.390 |
| §5.10 | `v3`/`v5` | College | 0.4151 ✗ | 0.420 |
| §5.12 | `v5` | College | 0.4144 → 0.4146 ✗ | 0.420 |
| §5.15 | `v6` | High school | crossed from just outside to just inside | 0.390 |
| §5.15 | `v6` | College | 0.4061 → 0.4125, and 0.4070 on the second range ✗ | 0.420 |
| §5.20 §8 | `v8` | Both | verdict only, no value published | — |

High school has been on both sides of its floor under three rulesets. College
has never been inside its band. That asymmetry is the first evidence that these
are not one finding, and it is why they were sampled and ruled on separately.

#### 2. The interval this verdict is read against was wrong, and is fixed

`run_competition_calibration.gd` published field-goal percentage with a Wilson
interval over **attempts**. Attempts inside one team-game share a roster, an
opponent, a game plan and a fatigue path, so they are not independent trials and
that interval is the wrong shape for the quantity — it is the same class of
error §5.18 corrected in the venue sample and §5.20 §5 corrected in the paired
before/after.

Field-goal percentage is now published with the **clustered ratio estimator over
team-games** that points per possession already used: the residual
`y_i − R·x_i` carries the covariance the two totals share, which is exactly what
makes a ratio's variance different from either total's. The estimator is pinned
against a hand-computed value and against a series whose answer is known by
construction, and a mutant that reverts it to a binomial is detected.

Every interval in this section is that estimator. None of them is binomial.

#### 3. Phase 1: fresh diagnosis on two untouched ranges

400 games per level per range, one worker per level, ranges **910,000–910,399**
and **920,000–920,399** — neither used by any previous diagnosis, tuning,
validation, regression or test.

| Level | Range A (910,000) | Range B (920,000) | Pooled from counts (800 games) |
| --- | ---: | ---: | ---: |
| **High school** | 0.3865 ±0.0041 **FAIL** | **0.3906 ±0.0040 PASS** | **0.3885 ±0.0029** |
| **College** | 0.4146 ±0.0042 FAIL | 0.4105 ±0.0041 FAIL | **0.4126 ±0.0029** |

**The two high-school ranges return opposite verdicts.** Range B passes. The
pooled interval is [0.3856, 0.3914] and **reaches the band**.

**Both college ranges miss below**, and each range's interval — [0.4104, 0.4188]
and [0.4064, 0.4147] — lies entirely beneath the 0.420 floor on its own.

Under the classification rule this is **MARGINAL/UNRESOLVED at high school** and
**REPEATABLE FAILURE at college**. Pooling is over the underlying per-team-game
counts, never over the two published percentages; the average of the rates is
quoted beside the pooled figure only to show it was not used.

#### 4. Phase 2: the accounting decomposition, and it closes

`PppDecomposition` was extended from the points identity to the field-goal one,
which is independently breakable: a decomposition can attribute every point
correctly and still lose a shot off the zone axis, and the zone shares will
still sum to one and still look like basketball.

Four axes now count the same shots and all four are required to total the
ledger's own count — zone, contest band, assisted state, and the box score,
which `BoxScoreProjector` builds on a different code path. Attempts, makes and
the box-score arm are checked per game so two games with opposite errors cannot
cancel. **Zero violations and zero identity breaches at every level, on every
range run in this section**, across 268,751 high-school and 271,419 college
attempts at validation size alone.

Pooled over both diagnosis ranges, 800 games per level, beside Development as
the adjacent passing control and top domestic as the anchor:

| Term | High school | College | Development | Top domestic |
| --- | ---: | ---: | ---: | ---: |
| **Field-goal %** | **0.3885** | **0.4126** | **0.4356** | **0.4566** |
| §14.1 band | 0.39–0.47 | 0.42–0.49 | 0.43–0.50 | 0.45–0.51 |
| Against floor | −0.0015 | −0.0074 | **+0.0056** | **+0.0066** |
| 2P% / 3P% | 0.4268 / 0.3083 | 0.4542 / 0.3326 | 0.4793 / 0.3552 | 0.5041 / 0.3748 |
| 3PA/FGA | 0.3227 | 0.3419 | 0.3527 | 0.3668 |
| Points from twos / threes / free throws | 62,266 / 32,154 / 14,278 | — | — | — |
| PPP from twos / threes / free throws | 0.5498 / 0.2839 / 0.1261 | 0.5617 / 0.3205 / 0.1715 | — | — |
| Possessions/game (both teams) | 141.56 | 144.22 | 191.03 | 202.88 |
| Mean shooter capability | 0.5182 | 0.5984 | 0.6768 | 0.7562 |
| Mean primary-defender capability | 0.5035 | 0.5805 | 0.6566 | 0.7374 |
| Mean contest pressure | 0.2319 | 0.2678 | 0.3044 | 0.3401 |
| Mean contest penalty | 0.0358 | 0.0443 | 0.0497 | 0.0574 |
| Mean §13.1 baseline | 0.4419 | 0.4725 | 0.5018 | 0.5288 |
| Mean make probability | 0.4048 | 0.4305 | 0.4557 | 0.4833 |
| Block rate | 0.0389 | 0.0434 | 0.0483 | 0.0545 |
| Shooting-foul rate | 0.1186 | 0.1185 | 0.1191 | 0.1175 |
| Turnovers/possession | 0.1625 | 0.1533 | 0.1424 | 0.1404 |
| Offensive-rebound extension rate | 0.1252 | 0.1207 | 0.1160 | 0.1125 |
| Assisted share of makes | 0.6483 | 0.6359 | 0.6165 | 0.6254 |
| Clamped share (§13.2 floor/ceiling) | 0.0000 | 0.0000 | 0.0002 | 0.0026 |

The probability terms are read **out of `ShotResolver` itself** rather than
rebuilt here, and they are published as an attribution: they sum to the mean
make probability, and the residual — non-zero only through the §13.2 clamp — is
published beside them so a term going missing cannot hide inside a plausible
total. It is 0.0000 at every level.

| Term, mean signed contribution | High school | College | Development | Top domestic |
| --- | ---: | ---: | ---: | ---: |
| §13.1 baseline | +0.4419 | +0.4725 | +0.5018 | +0.5288 |
| Contest penalty | −0.0344 | −0.0427 | −0.0479 | −0.0549 |
| Advantage / pass-quality bonus | **+0.0352** | **+0.0353** | **+0.0353** | **+0.0355** |
| Catch-quality penalty | −0.0060 | −0.0048 | −0.0036 | −0.0025 |
| Movement penalty | **−0.0269** | **−0.0269** | **−0.0271** | **−0.0268** |
| Fatigue penalty | **−0.0046** | **−0.0047** | **−0.0048** | **−0.0045** |
| Clock-pressure penalty | −0.0013 | −0.0030 | −0.0068 | −0.0051 |
| Shot-selection bonus | +0.0009 | +0.0048 | +0.0088 | +0.0127 |
| **Residual (clamp)** | **0.0000** | **0.0000** | **0.0000** | **0.0000** |

**Every term that is not driven by capability is flat across all five levels**:
movement to within 0.0003, the advantage bonus to within 0.0003, fatigue to
within 0.0003, the shooting-foul rate to within 0.0016. Nothing in the shared
profile bites a weak level harder than a strong one.

#### 5. Phase 3: every production hypothesis is ruled out on measurement

Ruled out by measurement, not by reading the code:

| Hypothesis | Evidence against |
| --- | --- |
| **Shot mix** | Zone shares match within ±0.021 at every level, and the one real difference runs the *wrong way*: high school takes 4.6% deep threes against top domestic's 10.4%, and the deep three is the worst shot on the floor. The mix favours the failing levels |
| **Accuracy within identical zones** | The baseline-to-realized gap *grows* with level in every zone — restricted rim +0.013 at high school against +0.042 at top domestic, close non-rim +0.115 against +0.172. Higher levels lose more, not less |
| **Contest distribution** | High school resolves 42.0% of attempts `OPEN` against top domestic's 26.5%. The failing levels get the *easier* contests |
| **Accuracy within identical contest bands** | Accuracy falls monotonically across bands at every level, and the bands' own penalties are shared constants |
| **Shooter-rating distribution** | Mean shooter capability steps 0.5182 → 0.5984 → 0.6768 → 0.7562, three gaps of 0.0802, 0.0784 and 0.0794 against a roster ladder of exactly 6 rating points each. One rating point is 1/74 = 0.0135; six is 0.0811. The ladder is delivered |
| **Defender-rating distribution** | Steps with the shooter ladder, and produces *lighter* contests at the failing levels |
| **Player builder / rating normalization** | `Rating.normalized` and `shot_baseline`'s inverse round-trip exactly at nine ratings from 25 to 99, pinned by test. The curve is monotone in rating in all five zones |
| **Simulated execution quality** | Catch, movement, fatigue and clock terms are flat or favour the failing levels |
| **Pass / advantage quality** | The advantage bonus is +0.0352 to +0.0355 across all five levels — flat to three ten-thousandths |
| **Fatigue or movement penalties** | −0.0046 and −0.0269, flat to three ten-thousandths across all five levels |
| **Rule profile** | Crossed against rosters below: worth −0.004 to −0.006, and in the direction that would make Development *worse* than college |
| **Three-point line / competition environment** | All five competitions carry `standard_arc` and `standard_restricted`. No competition varies the line, by construction |
| **Sampling only** | College misses on four independent ranges totalling 2,800 games, with every range's interval below the floor on its own |

**The decisive measurement is the cross.** Rule profiles were crossed against
roster populations on matched fixtures at identical seeds, 200 games per cell,
range 930,000–930,199:

| Cell | Field-goal % |
| --- | ---: |
| college rules × college rosters | 0.4104 ±0.0058 |
| college rules × **development rosters** | **0.4405 ±0.0061** |
| development rules × **college rosters** | **0.4057 ±0.0047** |
| development rules × development rosters | 0.4346 ±0.0048 |
| high-school rules × high-school rosters | 0.3864 ±0.0059 |
| high-school rules × **development rosters** | **0.4388 ±0.0060** |
| development rules × **high-school rosters** | **0.3826 ±0.0050** |

**Field-goal percentage follows the roster and not the rules.** Swapping the
roster moves it +0.0289 to +0.0524; swapping the rule profile moves it −0.0038
to −0.0059, roughly a seventh as much and in the opposite direction. The *band
verdict* follows the roster too: college's rules with Development's roster
returns **0.4405, comfortably inside college's 0.42–0.49 band**, while
Development's rules with college's roster returns **0.4057, below Development's
own floor**.

The first version of this cross named each match after its cell. `MatchSession`
derives every possession's random stream from `"match:%s:possession:%d"`, so
that gave each cell a different draw sequence and destroyed the pairing the
runner exists to provide — two nominally identical cells measured 0.0018 apart
on pure label noise. The match id is now a function of the variation alone, the
cells reproduce each other to the digit, and the numbers above are the repaired
run.

**Root-cause ruling, stated separately per level as required:**

- **High school — no failure to attribute.** The fresh evidence does not
  establish a repeatable failure. Two of the four ranges run in this section
  pass, and every pooled interval reaches the band.
- **College — a confirmed failure with no production defect.** The shortfall is
  carried entirely by where the calibration fixture places the college roster,
  and the engine's response to roster strength is smooth, monotone, and
  demonstrably correct: the same shared profile, the same shot resolution and
  the same balance values put Development at +0.0056 and top domestic at +0.0066
  inside their own floors. The defect class is **fixture roster construction**,
  not the player builder, not rating normalization, not the shared balance
  profile, not the competition rule profile, and not reporting.

#### 6. Why nothing was corrected

A production correction requires **both** a repeatable failure and a causal
defect. College has the first and not the second, so production is unchanged.

The remaining gap is a mismatch between two ladders. `CompetitionCatalog`
walks a roster ladder that is linear in rating — 60, 66, 72, 74, 78 — while
§14.1's floors climb 0.390, 0.420, 0.430, 0.430, 0.450, which is +0.030 from
high school to college and +0.010 from college to Development. The engine's own
response is uniform at about +0.0044 of field-goal percentage per rating point.
A linear roster ladder cannot sit centrally in a non-linear band ladder, and the
level that ends up furthest from its floor is college.

Measured on the same matched fixtures, holding the rules and moving only the
roster level:

| Roster level | College field-goal % | College PPP | High-school field-goal % | High-school PPP |
| --- | ---: | ---: | ---: | ---: |
| +0 (as shipped) | 0.4104 | 1.0434 | 0.3864 | 0.9594 |
| +2 | **0.4215** | 1.0746 | **0.4020** | 0.9926 |
| +4 | 0.4311 | **1.1016** | 0.4054 | 1.0093 |
| +6 | 0.4416 | **1.1315** | 0.4114 | 1.0293 |

College needs about **+2 rating points** to clear its field-goal floor, and by
**+4** its points per possession has crossed the 1.10 ceiling §14.1 locks. The
feasible window is roughly +2 to +3 points, and moving one level along the
ladder does not preserve the intended rating gap between levels, which this work
is explicitly forbidden from disturbing. Amending §14.1's college band is the
other way to close it, and that is a locked target which must not be weakened to
match observed output.

**Both remaining options are owner decisions and neither is enacted here.** They
are recorded in §6 as an open blocker rather than resolved by tuning.

#### 7. Validation: two fresh untouched ranges, 1,000 games per level per range

Ranges **950,000–950,999** and **960,000–960,999**, opened only after the
no-change ruling was reached, and used for nothing else.

| Level | Validation A | Validation B | Pooled from counts (2,000 games) | Floor | Verdict |
| --- | ---: | ---: | ---: | ---: | --- |
| **High school** | 0.3884 ±0.0025 | 0.3892 ±0.0026 | **0.3888 ±0.0018** → [0.3870, **0.3906**] | 0.390 | **MARGINAL/UNRESOLVED — interval reaches the band** |
| **College** | 0.4129 ±0.0027 | 0.4119 ±0.0026 | **0.4124 ±0.0018** → [0.4106, **0.4142**] | 0.420 | **REPEATABLE FAILURE — interval entirely below the band** |

High school's pooled interval still covers its floor at 2,000 games and 268,751
attempts. Its point estimate misses by 0.0012 — a third of the miss college
carries — and it has now passed on one diagnosis range and failed on three. It
is recorded as **unresolved**, not as a failure and not as a pass.

College misses by 0.0076, and its pooled interval over 271,419 attempts stops
0.0058 short of the floor with every one of its four range intervals lying
entirely below it. That is a settled measurement of a real shortfall,
and §27.1 asks for 100,000 games per competition against the 2,000 run here.

#### 8. Five-level §14.1 verdicts on a fresh range

Range **970,000–970,399**, 400 games per level. Production simulation behaviour
is unchanged by this work, so this is a state table rather than a before/after:
the "before" is byte-identical to the "after" and all six golden hashes prove it.

| Metric | High school | College | Development | Overseas | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Possessions/game | 70.83 ✓ | 72.08 ✓ | 95.64 ✓ | 75.08 ✓ | 101.79 ✓ |
| Points per possession | 0.9598 ✓ | 1.0495 ✓ | 1.1029 ✓ | 1.1113 ✓ | 1.1666 ✓ |
| **Field-goal %** | **0.3861 ✗** | **0.4117 ✗** | 0.4335 ✓ | 0.4377 ✓ | 0.4581 ✓ |
| Three-point % | 0.3058 ✓ | 0.3278 ✓ | 0.3481 ✓ | 0.3512 ✓ | 0.3781 ✓ |
| 3PA/FGA | 0.3207 ✓ | 0.3426 ✓ | 0.3500 ✓ | 0.3528 ✓ | 0.3646 ✓ |
| Free-throw % | 0.6725 ✓ | 0.7145 ✓ | 0.7588 ✓ | 0.7714 ✓ | 0.7991 ✓ |
| Free-throw attempts/FGA | 0.2041 ✓ | 0.2510 ✓ | 0.2242 ✓ | 0.2309 ✓ | 0.2178 ✓ |
| Turnovers/100 | 16.09 ✓ | 15.59 ✓ | 14.36 ✓ | 14.12 ✓ | 13.79 ✓ |
| Offensive rebound % | 0.2544 ✓ | 0.2581 ✓ | 0.2539 ✓ | 0.2528 ✓ | 0.2503 ✓ |
| Assist % | 0.5011 ✓ | 0.5272 ✓ | 0.5484 ✓ | 0.5476 ✓ | 0.5864 ✓ |

**Forty-eight of the fifty §14.1 rows pass. The two that fail are the two this
section is about, and no previously passing verdict became a failure.** Starter
and rotation minutes pass at top domestic. The §14.2 game-shape rows behave
exactly as §5.13 and §5.21 already record — overtime short at four levels,
blowout share high at the two high-possession competitions, the marginal
population home win rate scattering either side of its band on a metric §5.19
already ruled is not the §14.2 authority — and none of them moved.

**The Development venue result is untouched and was not used as a target.**
`contest_capability_span` is unchanged, every §19.4 channel value is unchanged,
and no production simulation code was modified, so §5.21's **0.5280 ±0.0206
pooled over 500 matched fixtures** stands exactly as it was: a point estimate
0.0020 below a 0.530 floor whose interval covers the band. No claim is made that
this work moved it in either direction, because it cannot have.

#### 9. Tests

Twenty-one tests in `tests/calibration/test_fg_decomposition.gd`, plus a
strengthened guard in `test_ppp_decomposition.gd`:

- The field-goal identities close on all four axes, and the gate is required to
  **fail** on a manufactured breach of each axis independently.
- The ledger, the possession records and the box score agree about field goals,
  per game.
- Two-point and three-point makes reconcile to made field goals, and the scoring
  identity `2·2PM + 3·3PM + FTM = points` closes.
- Zone attempts and contest-band attempts each total field-goal attempts, and
  each axis's shares sum to one.
- Contest-band accuracy is monotone in every band the fixture actually uses, on
  a fixture sized so at least three bands are judged — the fixture was **grown**
  to reach that, and the threshold was not lowered to meet it.
- Shooter capability moves make probability; defender capability moves contest
  pressure, measured through the probe rather than by re-deriving the formula.
- Rating normalization round-trips through the §13.1 curve at nine ratings, and
  the curve is monotone in every zone.
- The roster ladder is strictly increasing across all five competitions, with
  the top-domestic end inside the one range §8.2 pins as a current-OVR median.
- Shared shot resolution cannot name a competition, cannot reach a rule profile,
  and cannot see the scoreboard; calibration targets cannot reach it.
- The diagnostic probe cannot change the ledger — the same seed produces a
  byte-identical signature with and without it — is detached by default, and its
  published terms sum to the probability they describe.
- The published field-goal interval goes through the ratio estimator, pinned
  against a hand-computed value and against a series whose answer is known.
- Turnovers, offensive rebounding, pace and assists are pinned on a fixed
  deterministic fixture, so a scoring change paid for through any of them moves
  a number this suite is watching.

No existing sample floor or tolerance was weakened. `test_ppp_decomposition.gd`'s
competition guard was **widened** after the mutation battery walked past it.

#### 10. Mutation battery

Fifteen mutations, run sequentially in an isolated worktree with a 600-second
and 2,048 MB budget per mutant, every baseline green, each mutant restored
byte-clean against a pristine tree hash.

| # | Mutation | Outcome |
| --- | --- | --- |
| M1 | Contest pressure stops reading defender capability | DETECTED — `test_defender_capability_moves_contest_pressure` |
| M2 | Make probability stops reading shooter capability | DETECTED — `test_shooter_capability_moves_make_probability` |
| M3 | High-school-only scoring bonus in shared shot resolution | DETECTED — `test_shot_resolution_cannot_name_a_competition` |
| M4 | College-only scoring bonus in shared shot resolution | DETECTED — `test_shot_resolution_cannot_name_a_competition` |
| M5 | Contest reads the competition identity | DETECTED — `test_the_contest_path_cannot_read_a_competition_or_a_target` |
| M6 | Make resolution reads the scoreboard | DETECTED — `test_the_probe_terms_sum_to_the_probability_they_describe` |
| M7 | Field-goal accounting loses a zone attempt | DETECTED — `test_the_field_goal_identities_close_on_every_axis` |
| M8 | A made free throw is worth zero points again | DETECTED — `test_the_scoring_terms_account_for_every_point` |
| M9 | The field-goal identity can no longer fail | DETECTED — `test_the_field_goal_gate_reports_a_breach_rather_than_absorbing_it` |
| M10 | Scoring offset through turnovers | DETECTED — `test_the_compensation_channels_are_pinned_on_a_fixed_fixture` |
| M11 | Scoring offset through offensive rebounding | DETECTED — `test_the_compensation_channels_are_pinned_on_a_fixed_fixture` |
| M12 | Assist ownership disturbed | DETECTED — `test_every_assist_is_explained_by_a_recorded_creation_event` |
| M13 | A golden hash is edited without regeneration | DETECTED — `FAIL: golden ledger changed for scenario regulation` |
| M14 | The diagnostic probe changes the ledger | DETECTED — `test_shooter_capability_moves_make_probability` |
| M15 | The field-goal interval reverts to a binomial one | DETECTED — `test_the_published_field_goal_interval_goes_through_the_ratio_estimator` |

**Fifteen of fifteen detected by a named assertion or a compile failure
attributable to the mutant.** No mutation was scored on a timeout, a memory
breach, a crash, an invalid mutation or a setup failure.

**Six of them were not detected on the first pass, and that is the finding.**
The first battery scored 9 of 15. M3, M4 and M5 survived because the
competition guard forbade four tokens and the mutants reached their per-league
branch through `context.input.rule_profile.profile_id`, which matched none of
them. M10 and M11 survived because nothing pinned the compensation channels on
a fixed fixture. M15 survived because nothing pinned the interval's estimator.
The tests were widened to close each gap — the guard now bans the route rather
than four spellings — and the battery was re-run to 15 of 15. No mutant was
withdrawn and none was scored equivalent.

**"Revert the correction" and "disable the diagnosed causal input" have no
mutant, honestly recorded:** there is no correction to revert, and the diagnosed
cause is a fixture roster level rather than a production input. M1 and M2 stand
in for the second of those by disabling the two capability inputs the diagnosis
turned on, and both are detected.

#### 11. Golden ledgers

**No production event behaviour changed, and all six golden hashes are
byte-identical** — verified by recomputation in the acceptance suite, not by
inspecting the committed file. The ruleset stays at
`simulation-v8-contest-capability` and was deliberately **not** bumped, because
nothing it versions has moved.

| Scenario | Seed | Hash | Status |
| --- | ---: | --- | --- |
| regulation | 20260815 | `52dfdb1a…` | unchanged |
| overtime | 190056 | `ab37ad08…` | unchanged |
| offensive_rebound | 7001 | `5dbd798f…` | unchanged |
| foul_free_throw | 4242 | `31ce2e07…` | unchanged |
| substitution_foul_out | 31337 | `f03f1a3a…` | unchanged |
| late_game | 8675309 | `af3f5cc9…` | unchanged |

The committed hash file is unchanged at `be8c8b19…`. There are no first
divergences to report.

The one production file this work touches is `ShotResolver`, and it touches it
only to expose the terms it had already computed to a diagnostic sink that is
null by default. The make probability was rewritten from eight sequential
compound assignments into one left-associative expression over named terms —
the identical sequence of IEEE-754 operations, which the golden hashes are the
evidence for rather than the claim.

#### 12. Seed-range ledger

| Purpose | Range | Sample | Status |
| --- | --- | --- | --- |
| Diagnosis A | 910,000–910,399 | 400 games × high school, college, Development, top domestic | **Spent — diagnosis** |
| Diagnosis B | 920,000–920,399 | 400 games × high school, college | **Spent — diagnosis** |
| Counterfactual cross and roster sweep | 930,000–930,199 | 200 games × 15 cells | **Spent — counterfactual** |
| **Validation A — untouched until the ruling** | 950,000–950,999 | 1,000 games × high school, college | **Spent — validation** |
| **Validation B — untouched until the ruling** | 960,000–960,999 | 1,000 games × high school, college | **Spent — validation** |
| Five-level §14.1 table | 970,000–970,399 | 400 games × five levels | **Spent — regression** |
| `test_fg_decomposition.gd` | 905,000+ | suite-owned | **Spent — tests** |

940,000 was deliberately avoided: `test_guardrail_exception.gd` owns it. No
range in this table appears in §5.7–§5.21.

#### 13. Performance

No production hot path gained work. The diagnostic probe is a null `Callable`
check per contest and per make in an ordinary run, and the make probability is
the same arithmetic rearranged. The 400-game single-level calibration runs in
this section held 1.1 games/second on the same debug build §5.12 profiled.

#### 14. Classification

- **Structural:** the four field-goal identities and their demonstrated ability
  to fail; the probe's inability to change the ledger; shared shot resolution's
  inability to name a competition, reach a rule profile, or see the scoreboard;
  the ratio estimator standing behind the published field-goal interval; the
  rating-normalization round trip; the roster ladder's ordering.
- **Measured, below the §27.1 requirement:** every number in sections 3 through
  8. The largest sample here is 2,000 complete games per level against §27.1's
  100,000 per competition, which is 2%.
- **Certified:** nothing.

### 5.23 The college field-goal decision, and what the fixture actually is

Status: **Owner-decision package delivered. Nothing enacted.** No production
value, locked target, ruleset or golden changed; all six golden hashes and the
smoke output are byte-identical.

Full package: **[`docs/STAGE4_COLLEGE_FIELD_GOAL_OWNER_DECISION.md`](docs/STAGE4_COLLEGE_FIELD_GOAL_OWNER_DECISION.md)**.

§5.22 classified the college §14.1 field-goal miss as *fixture roster
construction* and left an owner decision open between the roster ladder and the
band ladder. That ruling rested on an unmeasured claim: whether the calibration
fixture resembles a production-built college roster. This section measures it,
and the answer removes an option rather than adding one.

#### 1. Fixture representativeness ruling — structural

Every college measurement this project has published — `run_competition_calibration.gd`,
`run_fg_decomposition.gd`, `run_calibration_smoke.gd`, `run_fg_counterfactual.gd`,
and the 950,000 / 960,000 / 970,000 validation ranges — draws its rosters from one
function, `CompetitionCatalog.team_for`.

That function is a **hard-coded linear ladder**: every one of a player's twenty
ratings is a single scalar plus a constant from a fixed 20×5 offset table. It
carries no age, no class year, no attribute correlation structure, six distinct
archetypes across 200 teams, and ten players rather than a college roster's
thirteen to fifteen.

**Nothing under `src/` constructs a `TeamMatchProfile` or a `PlayerMatchProfile`.**
Production consumes rosters and never generates them; there is no roster
generator, no team assembly, and no college tier system. Both facts are pinned by
`tests/calibration/test_roster_provenance.gd` rather than left as prose.

So the fixture is neither representative nor unrepresentative of production
college rosters: **it is the only college roster that exists.**

#### 2. Production-builder evidence — measured, not certified

The closest production-owned path to a college player is `BuilderService` +
`DevelopmentService` run through the three §9.5 COLLEGE seasons. 1,000 careers on
fresh seeds **1,200,001–1,201,000**, snapshotted at every college class year:

| Measure | Fixture college | Production builder, college age |
| --- | ---: | ---: |
| Mean current Overall | **67.01** | **67.40** |
| Overall standard deviation | 5.14 | 4.67 |
| Age / class year | **neither field exists** | 19–21 / three classes |
| Distinct derived archetypes | 6 | 20+ |
| **three_point** | 66.01 | **70.21 (+4.20)** |

> **Superseded by the §5.24 family-weight repair.** Every "production builder"
> figure in this table was measured through the defective `_family_weights` and
> is contaminated. The corrected paired remeasurement on these same seeds is in
> §5.24 §9. In short: Overall 67.40 → **67.48** and three_point 70.21 → **70.74**
> both survive, but `short_range` 71.60 → **68.89**, `mid_range` 69.61 →
> **65.19** and `dunking` 70.85 → **68.13** are withdrawn. The claim that the
> fixture's shooting *shape* is uncorroborated survives; the claim that the gap
> is uniform across the shooting zones does not.

**The fixture's college rating *level* is corroborated by production to 0.39
Overall points; its shooting *shape* is not.** Field-goal percentage reads
shooting ratings, not Overall.

A defect was found while measuring and is reported rather than absorbed:
`CareerSimulator._family_weights` iterates emphasis *levels* as attribute
*indices*, so every position family weights `short_range`, `dunking` and
`mid_range` at 1.0 and everything else at 0.35. It is calibration-harness code,
not production. It contaminates those three rows; the three-point row is
cap-driven and clean. **It is not fixed here** — repairing it moves recorded §8.4
figures and invalidates frozen validation ranges — and is carried as its own item
in §6 and §9.

> **Repaired in §5.24.** The "three-point row is cap-driven and clean" reading
> was right at *college age* and wrong at *creation time*: a Guard invested
> −0.33 in `three_point` against a neutral control where the repair gives
> +5.77. Three college seasons of development recover a cap-driven attribute
> regardless of its starting value, which is why the college centre moved only
> +0.53. The conclusion held; the evidence offered for it did not.

#### 3. Controlled grid — measured, not certified

CRN-matched, 400 complete games per cell, fresh variations **980,000–980,399**,
accounting identities reconciled on every cell.

| Transform | Field-goal enters 0.420 | First other locked band to break | Overall cost |
| --- | --- | --- | ---: |
| **Uniform roster lift** | **+3** (0.4241) | **+4** — points per possession 1.1019 against a 1.100 ceiling **and** turnovers/100 14.941 against a 15.00 floor | **+3.00** |
| **Shooting-only lift** | **+3** (0.4245) | **none out to +5** | **+0.60** |

The uniform window is **one rating point wide** — narrower than §5.22's estimate
of +2 to +3, and with a second binding constraint that section did not find. The
shooting-only route reaches the same field-goal percentage for one-fifth of the
Overall inflation and lands the fixture within **0.21** Overall of the production
builder's own college-age centre.

#### 4. Five-level consequences — measured, not certified

Fresh variations **990,000–990,399**, 400 games per level.

| Metric | High school | College | Development | Overseas | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Field-goal % | 0.3899 ✗ | **0.4115 ✗** | 0.4358 ✓ | 0.4395 ✓ | 0.4563 ✓ |
| §14.1 floor | 0.390 | 0.420 | 0.430 | 0.430 | 0.450 |
| Margin | −0.0001 | **−0.0085** | +0.0058 | +0.0095 | +0.0113 |

Every scoring statistic is monotone across the five levels. Pace and free-throw
rate are not, and both are rule-profile properties §4 permits.

**Why college and nowhere else:** the roster ladder is linear in rating
(61/67/73/75/79) and the band ladder is not linear in percentage (floors stepping
+0.030, +0.010, 0.000, +0.020). Six rating points buys roughly 0.024 of
field-goal percentage. The high-school-to-college step asks for 0.030 and is
handed 0.024; the college-to-Development step asks for 0.010 and is handed the
same 0.024. College absorbs the whole discrepancy. That is a **specification
conflict** between two ladders, and it exists whatever the fixture's shape.

#### 5. Decision matrix and recommendation

| Rank | Option | Verdict |
| --- | --- | --- |
| **1** | **A — fix the fixture's shooting shape**, after repairing `_family_weights` | Two independent measurements, not fitted to each other, converge on it. ≥2 points of headroom, +0.60 Overall, no production behaviour change. **§5.24 has now repaired `_family_weights`. Option A's direction survives and its three-point gap widens from +4.20 to +4.73, but the uniform shooting lift its offsets assumed is withdrawn: corrected, the fixture is 4.73 low on `three_point`, 1.88 low on `short_range` and 1.22 _high_ on `mid_range`. The per-zone shape must be re-derived, which needs roster assembly and is therefore still blocked** |
| **2** | **E — defer to §27.1** | Costs nothing, blocks nothing, preserves every option |
| ✗ | **B — raise the college rating ladder** | Contradicted by the production builder's own 67.40. Collapses the college-to-Development gap 6.00 → 3.00 for a one-point window |
| ✗ | **C — revise the locked 0.420 floor** | A 0.415 floor **still fails** (pooled interval tops out at 0.4142); only 0.410 passes, and it ratifies a fixture artifact and forecloses Option A |
| ✗ | **D — hybrid** | Strictly dominated: at the shooting lift that passes (+3), the current 0.420 floor already passes, so the band concession does no work |

**The exact owner decision:** *does the owner accept that the shortfall is a
defect in the calibration fixture's attribute shape — shooting roughly four
points below the production builder's at matched Overall — rather than in its
rating level or in the §14.1 band?* If yes, Option A, and no locked target moves.
If no, or if the owner declines to act below §27.1, Option E.

#### 6. Classification

- **Engine defect:** none demonstrated.
- **Fixture defect:** yes — now identified as a *shape* defect, not a level one.
- **Specification conflict:** yes — linear roster ladder against a non-linear band ladder.
- **Owner preference:** yes — which of the two contracts moves.
- **Sampling uncertainty:** ruled out as the cause (six independent ranges), and a live limit on the magnitude of any fix.
- **Certification:** nothing here is certified. §27.1 asks 100,000 games per competition; this task ran 400 per cell.


### 5.24 A family emphasized whatever sat at canonical indices 0-2, and every §8.4 figure was measured through it

§5.23 reported, without fixing, that `CareerSimulator._family_weights` read
`AttributeEmphasis` levels as `AttributeKey` indices. This section establishes
the exact mechanism, proves the call graph rather than asserting it, repairs it,
and re-measures everything the defect reached. It changes no locked target, no
roster, no fixture, and no match-engine tuning.

#### 1. The exact mechanism — structural proof

`CapGenerator.emphasis_from_family` returns an array **indexed by canonical
attribute** whose **values** are `AttributeEmphasis.Value` levels. The defective
body iterated that array's values and used each one as an index:

```gdscript
for attribute in CapGenerator.emphasis_from_family(family, [] as Array[int]):
    weights[attribute] = 1.0
```

The set of indices written is therefore the set of *distinct emphasis levels
present*, not the set of emphasized attributes. Every family declares four
primaries, four secondaries and twelve neutrals, so every family wrote exactly
`{PRIMARY, SECONDARY, NEUTRAL}` = `{0, 1, 2}`. Canonical attributes 0, 1 and 2
are `short_range`, `dunking` and `mid_range`.

`INCOMPATIBLE` (3) never appeared, because this call site passes an empty
incompatible list — which is why `three_point`, canonical index 3, was the one
shooting attribute the defect left at the baseline while emphasizing the other
three.

The result: **three families, one weight vector.** Sum 8.9500 for all three
(17 × 0.35 + 3 × 1.00), above-baseline set identical for all three.

#### 2. Call-graph classification — structural proof, not inherited

§5.23 classified this as "calibration harness, not production". That
classification is correct, and it is now proved rather than asserted:

| Question | Evidence |
| --- | --- |
| Call sites of `_family_weights` | Exactly one: `career_simulator.gd:371`, inside `simulate` |
| Anything under `src/` referencing `CareerSimulator` | **None.** Only `calibration/runners/*` (7 runners) and 4 test suites |
| Any other site iterating an emphasis array as indices | **None.** `grep` over every `.gd` returns one hit, the defect itself |
| `BuilderService.begin_build` (production) | Passes the whole emphasis array to `CapGenerator.generate`, which reads `emphasis[attribute]`. **Correct** |

Classification: **builder/calibration behaviour only.**

| Surface | Affected? |
| --- | --- |
| Initial player construction (production Builder) | **No** — the user allocates; this weight vector is never built |
| Yearly progression, Projected Peak, OVR, archetype assignment | **No** — the logic is untouched; only the *starting build* fed to the harness was wrong |
| Cap allocation | **No** — caps come from `emphasis_from_family` read correctly by `generate` |
| `MatchInput` construction, saved career state, frozen receipts | **No** — `CareerSimulator` persists nothing and is not reachable from any production command |
| Every §8.4 / §9.5 figure ever measured through the harness | **Yes** |

No migration or versioning implications: nothing persisted, nothing versioned,
and no existing save or frozen receipt is altered.

#### 3. Pre-fix evidence — first divergence, fixed seeds

`run_family_weight_audit.gd`, seeds 1,310,001–1,310,027, nine controlled
prospect × maturity cells per family against a neutral (flat 0.35) control at
identical seed, body and caps. **42 contract failures.**

| Family | Declares primary | Actually above baseline | Top three weights |
| --- | --- | --- | --- |
| guard | handle, speed, three_point, passing | short_range, dunking, mid_range | short_range, dunking, mid_range |
| wing | short_range, three_point, perimeter_defense, speed | short_range, dunking, mid_range | short_range, dunking, mid_range |
| big | interior_defense, blocking, defensive_rebounding, strength | short_range, dunking, mid_range | short_range, dunking, mid_range |

Creation-time attribute deltas against the neutral control, identical for all
three families:

| Attribute | Pre-fix lift vs neutral control |
| --- | ---: |
| short_range, dunking, mid_range | **+10.00** each |
| three_point | **−0.33** |
| free_throw | −8.00 |
| handle | −11.00 |
| passing | −11.67 |
| vision | −13.67 |
| offensive_iq | −8.00 |
| perimeter_defense | −7.33 |

Every family's **Overall lift against the neutral control was −0.67**: the
defective weighting produced *worse* players than a flat vector, because it
spent the budget on attributes whose caps the family draw had not raised.

Determinism was byte-identical throughout — the defect was perfectly
reproducible, which is why no determinism, parity or reconciliation assertion
ever caught it. Weight sum 8.9500, no duplicates, no invalid keys.

Audit fingerprint (pre-fix): `366d2eac542a92ecf1cea3668003302d5cd27cb51ae8e518270f9b68367e2eef`

#### 4. The repair — smallest correct change

`_family_weights` becomes `CareerSimulator.family_allocation_weights`, resolving
the emphasis vector **by canonical index**:

```gdscript
static func weights_for_emphasis(emphasis: Array[int]) -> Array[float]:
    var weights: Array[float] = []
    for attribute in range(AttributeKey.COUNT):
        weights.append(_weight_for_emphasis(emphasis[attribute]))
    return weights
```

**No weight magnitude was tuned to reproduce a published measurement.**

- `PRIMARY_WEIGHT = 1.00` and `NEUTRAL_WEIGHT = 0.35` are the two weights this
  function already used, unchanged.
- `SECONDARY_WEIGHT = 0.70` is the tier the defect made unreachable. It is
  simultaneously the arithmetic midpoint of the other two and the weight
  `tools/builder_calibration_harness.gd` has committed for the *same*
  family-secondary tier since the Builder portfolio was written. The two
  harnesses now describe one contract rather than two.
- `INCOMPATIBLE` is deliberately given **no** weight and halts loudly. A body
  tradeoff reaching creation-time *spending* rather than only the cap draw
  would be a new balance decision, and must be taken deliberately.

The catalog now validates itself (`CapGenerator.family_catalog_failures`):
duplicate declarations, out-of-range keys, empty primary tiers, and coverage
gaps are reported **by name**, and `emphasis_from_family` asserts on them.

The family catalog itself was **not** redesigned. It was audited for internal
contradiction and none exists: no family declares an attribute in both tiers,
and no declaration is out of range. No owner decision is required there.

#### 5. Canonical attribute coverage

Seventeen of twenty attributes are emphasized by at least one family. The
remaining three are now **declared** family-neutral in
`CapGenerator.FAMILY_NEUTRAL_ATTRIBUTES` rather than left as an unexplained gap.
**No family was invented to close the gap.**

| Attribute | Why it is family-neutral |
| --- | --- |
| `free_throw` | A closed skill from a stationary line against no defender. Every family shoots them; a family emphasis would make it a positional perk |
| `defensive_iq` | The *reading* half of defence, which §12.4 keeps equally available to every build. Families shape the *physical* half, and all four of those are emphasized |
| `stamina` | Conditioning, which body maturation and the §9.5 season model already move. A family emphasis would double-count it |

An attribute that is neither emphasized nor declared neutral is now a loud
failure, so this partition cannot drift silently.

#### 6. Post-fix contract — structural proof

`run_family_weight_audit.gd` on the same seeds: **PASS, 0 failures.**

| Family | Above baseline | Top three weights | Weight sum | Determinism |
| --- | --- | --- | ---: | --- |
| guard | exactly its 8 declared | three_point, handle, passing | 11.0000 | byte-identical |
| wing | exactly its 8 declared | short_range, three_point, perimeter_defense | 11.0000 | byte-identical |
| big | exactly its 8 declared | interior_defense, blocking, defensive_rebounding | 11.0000 | byte-identical |

Audit fingerprint (post-fix): `a2d182ffde9da9f370c30388fa47f12aa72d51a999c18df1093970d14d239a15`

#### 6a. Seed ledger for this repair

Every range below is fresh: none appears in any earlier diagnosis, tuning,
validation or regression table in this document. No range is used for two
purposes.

| Purpose | Seed range | Sample | Runner |
| --- | --- | ---: | --- |
| Contract audit (pre-fix and post-fix, paired) | 1,310,001–1,310,027 | 27 controlled cells × 2 arms × 3 families | `run_family_weight_audit.gd` |
| Contract test suite | 1,320,001–1,320,999 | 30 cases | `test_family_weight_contract.gd` |
| **Builder distribution — validation** | **1,330,001–1,333,000** | 1,000 players per family × 2 arms | `run_builder_family_distribution.gd` |
| **Progression — validation A′ (untouched)** | **1,350,001–1,352,000** | 2,000 careers | `run_career_progression.gd`, `run_projected_peak_diagnostics.gd` |
| **Progression — validation B′ (untouched)** | **1,360,001–1,362,000** | 2,000 careers | `run_career_progression.gd`, `run_projected_peak_diagnostics.gd` |
| Paired causal attribution only — **not validation** | 700,001–702,000 | 2,000 careers × 2 arms | `run_career_progression.gd` |
| Paired causal attribution only — **not validation** | 1,200,001–1,201,000 | 1,000 careers × 2 arms | `run_roster_provenance.gd` |

The two paired ranges are reruns of ranges §5.9 and §5.23 already spent. They are
used **only** to attribute a difference to the repair on identical seeds, and
carry no validation weight. Ranges **700,001–702,000** and **900,001–902,000**
are retired as validation ranges by this repair, exactly as §6 item 6b
anticipated; **1,350,001–1,352,000** and **1,360,001–1,362,000** replace them.

#### 7. Builder distribution — measured, below certification size

`run_builder_family_distribution.gd`, **1,000 players per family**, fresh seed
ledger **1,330,001–1,333,000**, disjoint from every range recorded above. Talent
level (3 prospect profiles), maturity (3), and physical profile (3 body variants
spanning each family's legal freshman height range) all vary across the sample.
Every cell is built twice — once through the family's own §8.1 weights, once
through a flat control at identical seed, body and caps — so the family's
contribution is separable from position, talent and body.

| Measure | guard | wing | big |
| --- | ---: | ---: | ---: |
| n | 1,000 | 1,000 | 1,000 |
| Overall mean (sd) | 48.67 (1.25) | 48.67 (1.25) | 48.66 (1.25) |
| Overall P5/P25/P50/P75/P95 | 47/47/49/50/50 | 47/47/49/50/50 | 47/47/49/50/50 |
| **Overall lift vs neutral control** | **+0.00** | **+0.00** | **−0.00** |
| Maximum potential mean (sd) | 85.70 (7.57) | 85.83 (7.52) | 85.69 (7.77) |
| Projected peak low mean (sd) | 71.87 (2.53) | 71.92 (2.47) | 71.81 (2.59) |
| Projected peak high mean (sd) | 82.29 (5.17) | 82.39 (5.03) | 82.24 (5.24) |
| **Projected peak lift vs control** | **0.0000** | **0.0000** | **0.0000** |
| AP spent (control) | 195.0 (195.0) | 195.0 (195.0) | 195.0 (195.0) |
| Body height / weight / wingspan | 70.0 / 150.6 / 72.3 | 74.0 / 169.3 / 76.3 | 78.0 / 187.6 / 80.3 |
| Physical profiles | 66/70/74 in, 334/333/333 | 70/74/78 in | 74/78/82 in |
| Cap breaches | **0** | **0** | **0** |
| Illegal ratings | **0** | **0** | **0** |
| Unconfirmable builds | **0** | **0** | **0** |
| Determinism | byte-identical | byte-identical | byte-identical |

Distribution fingerprint: `180dc981a41bcf8349fa2ba4eca53f9106ad0af4d450800ae88a4370f9a6a418`

**Family-emphasis lift against the controlled neutral comparison**, and the same
attribute in the families that do not declare it:

| Family | Declared primary | Mean | Control | Lift | Other families |
| --- | --- | ---: | ---: | ---: | --- |
| guard | handle | 62.45 | 59.00 | +3.45 | wing 59.00, big 35.00 |
| guard | speed | 59.12 | 45.00 | +14.12 | wing 59.58, big 45.00 |
| guard | three_point | 64.77 | 59.00 | +5.77 | wing 62.88, big 35.02 |
| guard | passing | 61.45 | 54.67 | +6.78 | wing 35.00, big 35.00 |
| wing | short_range | 65.55 | 59.00 | +6.55 | guard 35.44, big 59.14 |
| wing | three_point | 62.88 | 59.00 | +3.88 | guard 64.77, big 35.02 |
| wing | perimeter_defense | 62.23 | 42.36 | +19.87 | guard 58.33, big 35.00 |
| wing | speed | 59.58 | 45.00 | +14.57 | guard 59.12, big 45.00 |
| big | interior_defense | 64.80 | 35.02 | +29.77 | guard 35.00, wing 35.00 |
| big | blocking | 62.59 | 35.00 | +27.59 | guard 35.00, wing 35.00 |
| big | defensive_rebounding | 62.27 | 35.00 | +27.27 | guard 35.00, wing 57.89 |
| big | strength | 60.06 | 45.00 | +15.06 | guard 45.00, wing 45.00 |

Families **overlap rather than partition**: `speed` is a Guard *and* a Wing
primary and sits at 59.12 against 59.58; `three_point` is a Guard and Wing
primary at 64.77 against 62.88; `short_range` is a Wing primary and a Big
secondary at 65.55 against 59.14. Each family is visibly itself without being a
hard class.

**Unrelated-attribute movement.** The largest movement in an attribute a family
does not declare is a *reduction*, never a gain: guard `dunking` −24.00, wing
`free_throw` −23.99, big `free_throw` −23.99. That is the creation budget being
finite: what a family buys, it buys instead of something else. No undeclared
attribute rises.

**OVR truthfulness.** The family arm and the neutral arm spend an identical
195.0 AP and land on an identical mean Overall to two decimal places. The family
weighting therefore buys a *different* player, never a *better* one, and no
family carries a hidden total-OVR advantage. Projected Peak is identical to four
decimal places in every family, which is the expected result: Projected Peak is
drawn from the caps, and the allocation weights never touch a cap.

**Honest limitation.** At creation time the Guard arm produces a single derived
archetype across all 1,000 builds (`Shot-Creating Playmaking Guard`), because
weighted spending is deterministic and the Guard's declared set is narrow. Wing
produces 14 and Big 11. Archetype variety is a *development-time* property here,
not a creation-time one: the same contract measured at college age produces 73
distinct archetypes (§7 below). This is reported rather than absorbed; it is not
a regression, since the pre-fix arm was narrower still — one archetype for every
family, because every family built the same player.

#### 8. §8.4 / §9.5 progression, before and after

The repair changes the *starting build* every simulated career begins from, so
every progression figure ever measured through this harness is derived through
the defect. The historical figures in §5.9 are **not overwritten below**; they
are marked superseded and reproduced here as the pre-fix arm.

##### 8a. Paired causal attribution — seeds 700,001–702,000

Both arms run 2,000 careers plus two 2,000-career parity cohorts on **identical
seeds**, one against the defective tree and one against the repaired tree, so
every difference is the repair. The pre-fix arm **reproduces §5.9's published
Validation A column exactly**, which is what makes the pairing trustworthy.

| Metric | Pre-fix (= §5.9 Val A) | Post-fix | Moved? | Target |
| --- | ---: | ---: | --- | --- |
| Poor / injury-hit median | 66 | 66 | — | below 72 ✓ |
| Ordinary successful median | 77 | 77 | — | 74–79 ✓ |
| Strong, well managed median | 82 | 82 | — | 80–85 ✓ |
| Exceptional median | 87 | 87 | — | 86–91 ✓ |
| **Rare generational median** | **93** | **93** | — | **92–95 ✓** |
| Share above 95 | 0.0000 | 0.0000 | — | ≤ 0.0001 ✓ |
| Transition-gap share | 0.0155 | 0.0155 | — | 0.01–0.20 ✓ |
| **Projected-peak coverage** | **0.7380** | **0.7380** | — | 0.70–0.85 ✓ |
| **Projected-peak median width** | **11** | **11** | — | 6–12 ✓ |
| **Projected-peak median signed error** | **0** | **0** | — | ±2 ✓ |
| Parity, manual vs full detail | 0.0000 | 0.0000 | — | ±2% ✓ |
| Parity, manual vs aggregate | 0.0000 | 0.0000 | — | ±2% ✓ |
| AP reconciliation failures | 0 | 0 | — | exactly 0 ✓ |
| Guardrail warnings explained | 1.0000 | 1.0000 | — | exactly 1.0 ✓ |
| §9.5 ruling violations | 0 | 0 | — | exactly 0 ✓ |
| Guardrail season share | 0.0569 | 0.0569 | — | informational |
| Guardrail excess AP per career | 12.7342 | 12.7342 | — | informational |
| Mean lifetime AP granted | 1,203.5731 | 1,203.5731 | — | informational |
| Mean lifetime AP spent | 1,137.9305 | 1,137.9435 | **+0.0130** | informational |
| Mean lifetime AP unspent | 62.6841 | 62.6706 | **−0.0135** | informational |
| **Mean rating points gained** | **604.4085** | **585.7930** | **−18.6155** | informational |
| **Mean peak Overall** | **75.9420** | **75.9735** | **+0.0315** | informational |
| Mean cap attainment | 0.8839 | 0.8834 | −0.0005 | informational |
| Mean peak age | 28.3305 | 28.3470 | +0.0165 | informational |

**Every judged §8.4 and §9.5 contract is byte-identical.** No locked progression
contract became a failure. Both arms report exactly one failure —
`sample.meets_certification_size` — and it fails *identically* in both, because
2,000 careers is not §27.1's 1,000,000. It is a sample-size statement, not a
regression, and it was already failing before the repair.

The §8.4 career-peak distribution is likewise unmoved. Cohort sizes are
identical (513 / 795 / 457 / 196 / 39), and the only figure that moves anywhere
in the table is the poor/injury-hit P10, 65 → 66:

| Outcome | n | P10 pre → post | Median pre → post | P90 pre → post | Max pre → post |
| --- | ---: | --- | --- | --- | --- |
| poor_or_injury_hit | 513 | 65 → **66** | 66 → 66 | 67 → 67 | 68 → 68 |
| ordinary_successful | 795 | 75 → 75 | 77 → 77 | 78 → 78 | 79 → 79 |
| strong_well_managed | 457 | 76 → 76 | 82 → 82 | 83 → 83 | 84 → 84 |
| exceptional | 196 | 79 → 79 | 87 → 87 | 88 → 88 | 89 → 89 |
| rare_generational | 39 | 89 → 89 | **93 → 93** | 93 → 93 | 93 → 93 |

##### Why the bands did not move, and what did

The two figures that move are the interesting ones, and they move in opposite
directions: the corrected careers gain **18.6 fewer rating points** while
reaching a **marginally higher peak Overall** on an **identical** AP grant.

That is the expected signature of the repair rather than a coincidence. The
defect spent the creation budget on `short_range`, `dunking` and `mid_range`,
which the family cap draw had *not* raised — so those attributes sat low in the
§9.1 cost bands, where a rating point is cheap. Cheap points are plentiful and
contribute little. The repair spends the same budget on the attributes whose
caps the family draw *did* raise, which sit higher in the cost bands: fewer
points, each worth more Overall.

Cap attainment falls by 0.0005 for the same reason — the corrected build is
closer to the caps that matter and further from the ones that do not.

The §8.4 bands are unmoved because they are *peak Overall* bands, and peak
Overall is bounded by Maximum Potential, which is a function of the caps. The
weights never touch a cap. The defect wasted the creation budget; it could not
raise or lower the ceiling that the bands are measured against.

##### 8b. Fresh validation ranges

Ranges 700,001–702,000 and 900,001–902,000 are **retired as validation ranges**
by this repair, exactly as §6 item 6b anticipated, because they have now been
looked at during it. Two untouched replacements:

`run_career_progression.gd` post-fix, 2,000 careers plus two 2,000-career parity
cohorts per range. Neither range was looked at during the repair.

| Metric | Validation A′ 1,350,001–1,352,000 | Validation B′ 1,360,001–1,362,000 | Target |
| --- | ---: | ---: | --- |
| Poor / injury-hit median | 66 | 66 | below 72 ✓ |
| Ordinary successful median | 77 | 77 | 74–79 ✓ |
| Strong, well managed median | 82 | 82 | 80–85 ✓ |
| Exceptional median | 87 | 87 | 86–91 ✓ |
| **Rare generational median** | **92** | **93** | **92–95 ✓** |
| Share above 95 | 0.0000 | 0.0000 | ≤ 0.0001 ✓ |
| Transition-gap share | 0.0145 | 0.0170 | 0.01–0.20 ✓ |
| Projected-peak coverage | 0.7320 | 0.7380 | 0.70–0.85 ✓ |
| Projected-peak median width | 11 | 11 | 6–12 ✓ |
| Projected-peak median signed error | −1 | 0 | ±2 ✓ |
| Parity, manual vs full detail | 0.0000 | 0.0000 | ±2% ✓ |
| Parity, manual vs aggregate | 0.0000 | 0.0000 | ±2% ✓ |
| AP reconciliation failures | 0 | 0 | exactly 0 ✓ |
| Guardrail warnings explained | 1.0000 | 1.0000 | exactly 1.0 ✓ |
| §9.5 ruling violations | 0 | 0 | exactly 0 ✓ |
| Mean lifetime AP granted | 1,187.1134 | 1,216.0751 | informational |
| Mean lifetime AP spent | 1,120.2735 | 1,146.4075 | informational |
| Mean lifetime AP unspent | 63.9854 | 66.6901 | informational |
| Mean rating points gained | 580.9750 | 588.7570 | informational |
| Mean peak Overall | 75.7430 | 76.0520 | informational |
| Mean cap attainment | 0.8805 | 0.8833 | informational |
| Mean peak age | 28.2100 | 28.3125 | informational |
| Guardrail season share | 0.0509 | 0.0594 | informational |
| Guardrail excess AP per career | 11.1875 | 14.4327 | informational |

**Every judged §8.4 and §9.5 contract passes on both untouched ranges.** Each
range reports exactly one failure, `sample.meets_certification_size`, which is
the §27.1 sample-size statement and fails on every run of this length — before
the repair as well as after it.

The rare-generational median reads 92 on A′ and 93 on B′. Both are inside the
92–95 target. That cohort is 2% of the population by construction, so each range
carries only 39–41 careers of it, and a one-point median difference between two
40-career samples is ordinary sampling variation rather than a signal. The
paired pre/post arm in §8a is the evidence about *what the repair did*; these two
ranges are evidence that the repaired model still satisfies its locked contracts
on seeds nothing was fitted to.

##### 8c. Projected Peak subgroups

`run_projected_peak_diagnostics.gd`, same paired seeds, 2,000 careers per arm.
**Both arms pass; every judged metric is byte-identical.**

| Measure | Pre-fix | Post-fix | Target |
| --- | ---: | ---: | --- |
| `diagnostic.coverage` | 0.7380 | 0.7380 | 0.70–0.85 ✓ |
| `diagnostic.median_width` | 11 | 11 | 6–12 ✓ |
| `diagnostic.conversion_signed_error` | 0 | 0 | informational |
| `diagnostic.budget_signed_error` | 0 | 0 | informational |
| `diagnostic.total_signed_error` | 0 | 0 | informational |
| `diagnostic.clamp_effect_on_high_bound` | 0 | 0 | informational |
| `diagnostic.peak_age_minus_expected` | 0 | 0 | informational |
| `diagnostic.mean_realized_lifetime_ap` | 1,203.5731 | 1,203.5731 | informational |
| `diagnostic.mean_projected_lifetime_ap` | 1,389.9907 | 1,389.9907 | informational |
| `projected_peak.pathological_subgroups` | **0** | **0** | exactly 0 ✓ |
| `projected_peak.judged_subgroups` | 15 | 15 | — |

Per **position family** — the subgroup this repair could most plausibly have
damaged, since the whole defect was a family-identity defect:

| Family | n | Coverage pre → post | Median signed error | Median width | Median peak | Mean starting Overall pre → post | Mean cap attainment pre → post |
| --- | ---: | --- | ---: | ---: | ---: | --- | --- |
| guard | 681 | 0.7327 → **0.7327** | 0.0 → 0.0 | 11 → 11 | 77 → 77 | 47.7665 → **48.4758** | 0.8868 → 0.8858 |
| wing | 664 | 0.7349 → **0.7349** | −0.5 → −0.5 | 11 → 11 | 77 → 77 | 47.7681 → **48.4774** | 0.8824 → 0.8824 |
| big | 655 | 0.7466 → **0.7466** | 0.0 → 0.0 | 11 → 11 | 77 → 77 | 47.8687 → **48.5374** | 0.8824 → 0.8821 |

Every other judged grouping is byte-identical too — prospect profile (balanced
0.7184, high upside 0.7497, ready now 0.7414), maturity (average 0.7484, early
0.7352, late 0.7309), starting-Overall band, and Maximum-Potential band
(0.7176 / 0.7408 / 0.7537 / 1.0000). No pathological subgroup appears in either
arm.

**The two figures that move are exactly the two that should.** Mean starting
Overall rises by +0.67 to +0.71 in every family — the creation-time gain the
repair delivers, matching the audit's pre-fix −0.67 Overall deficit against a
neutral control. Mean cap attainment falls by 0.0003 to 0.0010, because the
corrected build sits closer to the caps that matter.

**Projected Peak itself is untouched.** Coverage, width, signed error, median
peak and median Maximum Potential are identical to four decimal places in every
subgroup. That is the expected result and a useful confirmation of the
call-graph classification: Projected Peak is derived from the caps, the caps are
drawn from `emphasis_from_family` read correctly, and the allocation weights
never reach a cap. A repair that had leaked into the cap draw would have moved
this table, and it does not.

No previously passing locked progression contract became a repeatable failure,
so no tuning value was touched to compensate for one.

#### 9. The corrected college snapshot, and what it does to §5.23

`run_roster_provenance.gd --mode=builder`, 1,000 careers, **the same seeds
1,200,001–1,201,000 §5.23 used**, run twice: once against the defective tree and
once against the repaired one. Paired on identical seeds, so every difference is
the repair and nothing else. These seeds are used here **for causal attribution
only** and are not offered as validation.

The pre-fix arm reproduces §5.23's published figures exactly — Overall 67.4010
against a recorded 67.40, standard deviation 4.6698 against 4.67 — which is what
makes the pairing trustworthy.

| Measure | Fixture college | Pre-fix production | Corrected production | Corrected − fixture |
| --- | ---: | ---: | ---: | ---: |
| Mean current Overall | 67.01 | 67.40 | **67.48** | +0.47 |
| Overall standard deviation | 5.14 | 4.67 | **4.56** | −0.58 |
| **short_range** | 67.01 | 71.60 | **68.89** | +1.88 |
| **dunking** | 66.81 | 70.85 | **68.13** | +1.32 |
| **mid_range** | 66.41 | 69.61 | **65.19** | **−1.22** |
| **three_point** | 66.01 | 70.21 | **70.74** | **+4.73** |
| **free_throw** | 63.41 | 62.78 | **63.17** | −0.24 |
| Shooting zone mean | 66.48 | 70.47 | **68.27** | +1.79 |
| offensive_iq | 67.21 | 65.43 | **66.29** | −0.92 |
| passing | 66.01 | 66.38 | **66.95** | +0.94 |
| vision | 66.61 | 65.91 | **66.30** | −0.31 |
| defensive mean | 66.17 | 65.30 | **65.84** | −0.33 |
| offensive_rebounding | 65.81 | 64.28 | **64.36** | −1.45 |
| defensive_rebounding | 67.01 | 67.67 | **68.15** | +1.14 |
| stamina | 66.21 | 61.78 | **62.66** | −3.55 |
| Distinct derived archetypes | 6 | 82 | **73** | — |
| Age / class year | neither field exists | 19–21 / three classes | 19–21 / three classes | — |

The position and age mixtures are byte-identical across the two arms (Guard
1023 / Wing 975 / Big 1002; ages 19/20/21 at 1000 each), because the repair
changes what a career *buys*, never which career is drawn.

##### Which §5.23 claims survive, and which are withdrawn

| §5.23 claim | Verdict |
| --- | --- |
| Production college three-point centre **70.21** | **Preserved, revised to 70.74.** The repair moves it +0.53. The figure was very nearly right for a reason §5.23 guessed at but did not prove |
| §5.23's stated reason: "the three-point row is cap-driven and clean" | **Preserved at college age, withdrawn at creation time.** The creation-time measurement shows `three_point` was contaminated *severely* — a Guard invested −0.33 against a neutral control where the repair gives +5.77. What §5.23 could not see is that three college seasons of development recover a cap-driven attribute regardless of its starting value. The conclusion was right; the evidence offered for it was not |
| Fixture college three-point centre **66.01** | **Preserved unchanged.** It is a fixture property and the repair cannot touch it |
| Fixture rating *level* corroborated (67.01 against 67.40) | **Preserved, strengthened.** 67.01 against 67.48; the gap narrows from 0.39 to 0.47 Overall — still well inside a point |
| Production `short_range` 71.60, `mid_range` 69.61, `dunking` 70.85 | **Withdrawn.** These are the three rows the defect emphasized. Corrected: 68.89, 65.19, 68.13 |
| "The fixture's shooting *shape* is not corroborated" | **Preserved in direction, materially revised in shape.** The gap is not a uniform ~4 points across the shooting zones. Corrected, the fixture is **4.73 low on three_point**, **1.88 low on short_range**, and **1.22 _high_ on mid_range** |
| "Shooting-only +3 lands within 0.21 Overall of production" | **Preserved as an Overall statement** — it now lands within 0.13 of 67.48. **Withdrawn as a shape justification.** A flat +3 across all shooting attributes is no longer supported: it would overshoot `mid_range` by roughly 4 points and still leave `three_point` short |
| **Option A as the leading owner recommendation** | **Direction preserved, exact offsets withdrawn and not re-derived here.** The corrected evidence still says the fixture's shooting shape is the defective property, and still says its rating level is right. It no longer supports a uniform shooting lift. Option A's *magnitude and per-zone shape* must be re-derived from this table, which this task does not do — that needs a justified diagnostic fixture, and §5.23's grid was run on contaminated production evidence |

§5.23's decision matrix rankings (A over E, with B, C and D excluded) are **not
disturbed**: B was excluded by the production Overall centre, which moved by
+0.08; C and D were excluded by the band arithmetic, which is untouched.

The three-point gap that motivates Option A **widened** from +4.20 to +4.73, so
the corrected evidence argues for Option A's direction slightly more strongly
than the contaminated evidence did.

##### What is still missing before a roster decision

The college FG% tuning grid was **not** rerun. §5.23's grid moved a *roster*
ladder, and translating this corrected *player* distribution into a justified
diagnostic fixture would require inventing roster assembly — thirteen to fifteen
players per team, a starter/bench split, and a team-strength ladder — none of
which exists under `src/`. That is roster generation, and this task ends before
it. The prerequisite is unchanged and now sharper: **a corrected per-zone
shooting shape (three_point +4.73, short_range +1.88, mid_range −1.22) needs a
roster construction to be expressed through before any FG% target can be judged
against it.**

#### 10. Mutation battery

Twelve targeted mutants, applied sequentially to an isolated worktree
(`git worktree` at the repaired tree, restored between mutants). The unmutated
control passes 36 cases in both suites before every run, so a mutant that fails
is failing on the mutation and not on the harness.

Detection requires a **named assertion failure**. Timeouts, crashes, memory
breaches, invalid mutations, setup failures and dead code are not detections and
are recorded as such.

| # | Mutant | Outcome | Named assertion that killed it (first listed; total detectors) |
| --- | --- | --- | --- |
| 1 | Restore the original "emphasis value as attribute index" defect | **KILLED** | `test_every_declared_attribute_receives_its_declared_tier_weight` (12 detectors, 102 assertion failures) |
| 2 | Route every family back to the universal short_range/dunking/mid_range trio | **KILLED** | `test_no_family_collapses_onto_the_old_universal_trio` (12 detectors, 102 failures) |
| 3 | Swap two canonical attribute indices while resolving identity (`three_point` ↔ `handle`) | **KILLED** | `test_a_single_emphasized_attribute_moves_only_its_own_weight` (4 detectors, 9 failures) |
| 4 | Ignore one declared family emphasis tier — secondaries fall to neutral | **KILLED** | `test_every_declared_attribute_receives_its_declared_tier_weight` (4 detectors, 30 failures) |
| 5 | Add an undeclared attribute to a family (`dunking` becomes a Guard primary) | **KILLED** | `test_the_guard_emphasizes_none_of_the_defect_trio` (19 detectors, 31 failures) |
| 6 | Duplicate one emphasized attribute across both tiers of a family | **KILLED** | `test_the_committed_family_catalog_is_well_formed` (19 detectors, 32 failures) |
| 7 | Break normalization — scale the resolved vector by 1.5 | **KILLED** | `test_the_weight_total_is_exactly_what_the_declaration_implies` (9 detectors, 540 failures) |
| 8 | Make dictionary insertion order reach the output | **KILLED** | `test_dictionary_insertion_order_does_not_change_the_output` (8 detectors, 81 failures) |
| 9 | Allow an unknown attribute key through the catalog validator silently | **KILLED** | `test_an_unknown_attribute_key_fails_loudly` (1 detector, 2 failures) |
| 10 | Leak family identity into competition-specific behaviour (`three_point` +0.25 when the college rule profile resolves) | **KILLED** | `test_the_repair_introduces_no_competition_specific_behaviour` (9 detectors, 17 failures) |
| 11 | Inflate Overall by a constant without changing any owned capability | **KILLED** | `test_empty_preview_reproduces_the_documented_derivation`, `test_scale_is_preserved_at_uniform_ratings` (2 detectors, 7 failures) — detected by the pre-existing `test_overall_calculator.gd`, not by this repair's suite |
| 12 | Break deterministic output — make the vector depend on the wall clock | **KILLED** | `test_the_weight_vector_is_a_pure_function_of_the_family`, `test_the_same_seed_and_family_reproduce_the_builder_exactly` (14 detectors, 494 failures) |

**12 of 12 killed by named assertions. None withdrawn, none equivalent.**

Every mutant ran the full 36 cases (fail-fast disabled with `-c`), so the
detector counts above are complete rather than truncated at the first failure.
The unmutated control passes 36/36 immediately before each run.

Two honesty notes:

- Mutants 5 and 6 also produced 426 runtime *errors* — the catalog assertion in
  `emphasis_from_family` firing. Those are **not** counted as detections. Both
  mutants are credited only to the named assertion failures, which occur without
  needing the runtime assert.
- Mutant 10's first pass was killed only by the weight-value assertions, while
  the competition-named test — which merely called the function repeatedly and
  compared the results to each other — stayed green against a constant offset.
  That test was too weak to mean what its name claimed, so it was rewritten to
  compare against a vector rebuilt from the catalog constants alone, with each
  competition's rule and balance profile resolved live between calls. The mutant
  is now killed by name. The original weakness is recorded rather than quietly
  fixed.

No mutant was withdrawn and none was equivalent.

#### 11. Golden ledgers, ruleset, and smoke

The repair is **diagnostics-only** by the call graph in §2 above, so the match
ruleset must not move and the golden ledgers must be byte-identical.

| Artifact | Before | After |
| --- | --- | --- |
| `ruleset_version` | `simulation-calibrated-v3` | `simulation-calibrated-v3` — unchanged |
| `tests/golden/match_golden_hashes.json` (file sha256) | `be8c8b19b60abcb4965d9254b335a2396d3361c9fb17ea3b38a51e23d5eb4cf5` | `be8c8b19b60abcb4965d9254b335a2396d3361c9fb17ea3b38a51e23d5eb4cf5` — **unchanged** |
| Six per-scenario ledger hashes | verified by `run_all.gd` | all six re-verified green by `run_all.gd` on the repaired tree; **no ledger regenerated, nothing reseeded** |
| Simulation smoke | — | **byte-identical apart from wall-clock metadata.** The pre-fix and post-fix outputs differ on exactly one line — `games: 10 (1 with overtime) in 4815 ms` against `… 4874 ms`. With that single timing figure normalized both files hash to `f32826a5ee80f392eef70e5d4246878f8ae261db3252daf3942a1bce9b4b2296` |

**Why the golden fixtures do not move.** The golden scenarios build their rosters
from `CompetitionCatalog.team_for`, a hard-coded ladder that never calls
`BuilderService` and never reaches `CareerSimulator`. The one production file
this change touches, `cap_generator.gd`, gains a constant, a pure validator, and
an `assert` that reads that validator — no draw is consumed, no value is
altered, and `emphasis_from_family` returns exactly what it returned before.
Nothing was reseeded and no golden hash was regenerated.

#### 12. Performance

The one production file this change touches gains an `assert` that runs a pure
catalog validator on **every** `emphasis_from_family` call — that is, once per
`BuilderService.begin_build`, on the production Builder path. Asserts are live
in the editor-debug binary every calibration and CI run uses, so the cost is
real there and worth measuring rather than assuming.

`tools/builder_calibration_harness.gd` isolates it exactly: it uses its own
`_weights_for` and never calls `family_allocation_weights`, so it performs
**byte-identical work** before and after the repair. The only difference on its
path is the new assert. Three alternating runs of each arm:

| Run | Pre-fix | Post-fix |
| --- | ---: | ---: |
| 1 | 27,163 ms | 27,880 ms |
| 2 | 27,836 ms | 27,954 ms |
| 3 | 28,318 ms | 27,374 ms |
| **Mean** | **27,772 ms** | **27,736 ms** |

Post-fix is **36 ms faster on average (−0.13%)**, against a run-to-run spread of
about 1,150 ms within each arm. The validator is O(20) over constants and runs
once per build against a build that then spends 195 AP through the cost table;
the measurement says what the arithmetic predicts, which is that it does not
register. No measurable performance effect.

The two paired 2,000-career progression runs corroborate this at a different
scale: 518,885 ms pre-fix against 515,719 ms post-fix for the same 6,000
careers, and 235,072 ms against 234,356 ms for the paired projected-peak
diagnostics.

#### 13. The complete gate, single-threaded

Run end to end in a throwaway worktree on the repaired tree, one step at a time,
with the class cache built there rather than in the working tree.

| # | Step | Result |
| --- | --- | --- |
| 1 | Class-cache build (`--import`) | exit 0 |
| 2 | Warnings-as-errors parse check, **exit status asserted** | exit 0 — 239 scripts checked, 0 failures |
| 3 | `tests/run_all.gd` (structure, determinism, **golden ledgers**) | **PASS** |
| 4 | Simulation smoke | **Invariants: PASS**, byte-identical to pre-fix apart from wall-clock |
| 5 | Builder calibration portfolio (Gate B1) | **Builder calibration: PASS** |
| 6 | Attribute sensitivity, 100,000 resolutions | **80 metrics, 80 judged, 0 failures: PASS** |
| 7 | Calibration smoke, 6 games | **15 metrics, 15 judged, 0 failures: PASS** |
| 8 | Family weight audit | **PASS**, fingerprint `a2d182ff…` |
| 9 | Full GdUnit4 suite | **553 cases / 47 suites, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans** — 13 min 12 s |
| 10 | Golden ledger file hash | `be8c8b19b60abcb4965d9254b335a2396d3361c9fb17ea3b38a51e23d5eb4cf5` — unchanged |

The suite grows from **523 cases across 46 suites** to **553 across 47**: the
thirty cases of `test_family_weight_contract.gd` and nothing else. No test was
skipped, quarantined, or relaxed.

#### 14. Classification of everything in this section

| Finding | Classification |
| --- | --- |
| The defect mechanism (emphasis level read as attribute index) | **Structural proof** — read from the source, reproduced, and pinned by 30 tests |
| Call-graph classification as calibration-only | **Structural proof** — exhaustive `grep` over every `.gd`, plus `test_roster_provenance.gd`'s existing structural assertion |
| Canonical attribute coverage partition (17 emphasized / 3 declared neutral) | **Structural proof** — enforced by `family_catalog_failures`, pinned by test |
| Weight vector contract per family | **Structural proof** — exact equality assertions, all three families, all twenty attributes |
| OVR truthfulness and no hidden family advantage | **Measured below certification size** — 3,000 builds; §27.1 sets no size for this, but it is a sample, not a proof |
| Builder distributions (means, sd, quantiles, lift) | **Measured below certification size** — 1,000 players per family |
| §8.4 / §9.5 progression figures | **Measured below certification size** — 2,000 careers per range; §27.1 asks 1,000,000 |
| Corrected college snapshot | **Measured below certification size** — 1,000 careers |
| §5.23's pre-fix college figures | **Historical contaminated evidence** — reproduced exactly, retained as the paired pre-fix arm, superseded for every purpose except causal attribution |
| §5.23's grid, decision matrix, and Option A offsets | **Historical contaminated evidence for the shape rows; owner decision still pending.** Direction preserved, exact offsets withdrawn |
| Which college FG% option the owner takes | **Owner decision still pending** — unchanged by this task, and still blocked behind roster generation |

Nothing in this section is **certified**. §27.1 asks for 1,000,000 careers and
100,000 games per competition; the largest sample here is 6,000 careers.

### 5.25 The four missing end-of-regulation systems, built and measured — the owner ruling classified rather than closed

> **SUPERSEDED IN PART BY §5.26. Everything below this line is a PRE-CORRECTION
> DIAGNOSTIC.**
>
> The measurements in this section were taken against
> `simulation-v9-endgame-strategy`. §5.26 subsequently found that five of the
> seven decisions built here were gated on the wrong side of the basketball
> question they were modelling — a *leading* team missing free throws on
> purpose, a tied team forbidden to hold for the last shot, a winning team's
> closer boosted for an early attempt, a timeout allowance drained on every
> possession of every close finish, and a leading-by-three foul that could
> repeat inside one possession and could fire outside the bonus, where it
> awards nothing.
>
> **The numbers below are retained, not deleted, and they are not wrong as
> records.** They are an accurate measurement of what the engine did at v9.
> They are simply not evidence about what it does now, and no verdict, band
> comparison, or reachability claim in this section should be read forward
> into `simulation-v10-endgame-corrections`. §5.26 carries the corrected
> measurements, taken on the same ranges and at the same sample size so the
> two are directly comparable.
>
> One statement in this section is corrected rather than merely superseded,
> because it was wrong when it was written and not only outdated: the grant of
> `timeout_advance_permitted` to **college**. See §5.26's first correction.

Status: **PRE-CORRECTION DIAGNOSTIC (`simulation-v9-endgame-strategy`). `EndgameStrategy` implements the four missing systems §5.13 named plus three requested alongside them. Every pre-implementation invariant §5.13 asked for is confirmed. The full gate was green at the time, including a full GdUnit4 rerun at 573 cases. Golden ledgers were regenerated and every changed hash is explained. Calibration measurement on six range/competition samples finds the mechanism correctly implemented, correctly bounded, and reachable, but does not find a clean, confident move of college or top domestic into the §14.2 overtime band — the honest result was "measured, mixed, and too small a sample to be a verdict," not a pass. §5.26 then found that "correctly bounded" was true of the code and false of the basketball: the gates were sound, and several of them were pointing the wrong way.**

#### The ruling

On 2026-09-01 the owner ruled, for college and top domestic only: keep the §14.2 4-8% overtime band; treat the measured overtime rates as missing end-of-regulation behaviour rather than as evidence the band is unreachable; keep the already-passing close-game and blowout bands for college; do not touch college's field-goal shortfall, which §5.22/§5.23 already attributed to the roster/rule-profile ladder mismatch and not to a production defect; and do not retune top domestic's blowout contract until this isolated endgame run reports. This is Option 1 from §5.13's three costed options — build the missing repertoire — applied to the two competitions whose overtime rate was worst, rather than Option 2's band amendment.

#### Pre-implementation confirmations, as required before any production code changed

1. **Architecture.** `GameManagement` (§5.11) already owns score-and-clock pace and action-family preference, and the tie-seeking shot-value rule for the last possession of regulation; `TimeoutState`/`timeouts_remaining` already exists and is spent only by `MatchSession._consider_timeout`'s run-stopping trigger. What was actually missing, checked against §5.13's own list: two-for-one clock management, a leading-by-three foul, timeout-to-advance, and a designed final-possession play. None of the four existed; all four do now.
2. **Shot and contact probability read no score or margin**, checked by inspection of every resolver: `ShotResolver` has zero score/margin reads. `FoulResolver`'s contact-probability core (`_contact_probability`) reads capability, tendency, body, and officiating — never score. The one pre-existing exception is `FreeThrowResolver.probability`'s §20.1 late-and-close composure term, documented and unchanged by this task.
3. **No production code under `src/domain` reads anything under `calibration/`.** Grepped exhaustively; the only related mechanism, `ShotResolver`'s `probe: Callable`, is null by default, set only by an external calibration runner, invoked only after the real draw is decided, and its return value is discarded.
4. **Scoreboard state affected only strategy/action-selection weighting before this task** — `GameManagement`'s own documented invariant, re-verified rather than assumed.

#### What was built

`src/domain/basketball/simulation/endgame_strategy.gd`, a new stateless class beside `GameManagement`, reusing every existing seam rather than adding new ones:

| Decision | Mechanism | Ledger signal |
| --- | --- | --- |
| Two-for-one | Trailing-or-tied, one to two shot clocks of regulation left: urgency added to a direct shot, taken off a reset, inside `ActionCandidateGenerator`'s existing §10.3 factor | `ACTION_SELECTED.detail_id = endgame_two_for_one` |
| Hold for the final shot | Leading, inside a short final-regulation window, shot clock not yet late: extra weight on a reset, on top of `GameManagement`'s ordinary protecting preference | `ACTION_SELECTED.detail_id = endgame_hold` |
| Quick-two vs. a timeout-backed tying three | Down exactly three, *outside* `GameManagement.endgame_multiplier`'s own tie-seeking window but with regulation time and a timeout in reserve: weight swings toward the two and off the three | `ACTION_SELECTED.detail_id = endgame_quick_two` |
| Designed final possession | Inside a narrow final-possession window: extra weight on the offence's own best `SHOT_SELECTION` capability on the floor — a capability read, not a comparison against the defence | `ACTION_SELECTED.detail_id = endgame_designed_play` |
| Leading-by-three foul | A defence up exactly three, inside its own (short, separately tunable) window, fouls before the tying three can be attempted — probabilistic (`leading_foul_share`), because this is coaching debate rather than necessity | `FOUL.detail_id`, new `FoulType.Value.LEADING_PROTECT` |
| Intentional final free-throw miss | A leading team's last attempt of a trip, inside a short window, where a make would still leave the trailing team a single-shot answer: deliberately missed — `FreeThrowResolver` is never consulted for this attempt, so there is no probability for the decision to touch. **This is backwards; see §5.26.** A leading team wants every point it can add, and a deliberate miss hands a live ball to the only side that needs one. | `FREE_THROW_MISSED.detail_id = intentional` |
| Timeout-to-advance | A trailing-or-tied team inside the final regulation window calls a timeout to inbound in the frontcourt rather than walk the ball up — gated by a new `CompetitionRuleProfile.timeout_advance_permitted` flag, a genuine rule difference rather than a coaching tendency, granted only to college and top domestic (the ruling's two named competitions); every other profile is unchanged | `TIMEOUT.detail_id = advance`; `ADVANCE.detail_id = timeout_advanced`, zero clock consumed for that one possession |
| *(correction)* | **The college grant in the row above was a mistake and is revoked in §5.26.** The 2026-09-01 ruling named college and top domestic as the competitions whose *measured overtime rate* was to be treated as missing behaviour. It decided nothing about either competition's rules. Deriving a §4 rule grant from which §14.2 band a measurement fell short of is the same error this section's own pre-implementation confirmation 3 exists to forbid, pointed the other way. Top domestic keeps the rule because it is that rule set's rule. | — |

Eleven new balance tunables, every one registered through `describe_tunables()`/Gate B0 with a name, unit, and safe range, following the existing convention exactly. Ruleset bumped from `simulation-v8-contest-capability` to **`simulation-v9-endgame-strategy`**, because the production simulation contract changed.

#### Golden-ledger impact

All six committed hashes changed. Every scenario's first divergence was located by inspecting its full dump for the new tags rather than assumed:

| Scenario | Cause |
| --- | --- |
| `regulation`, `offensive_rebound`, `foul_free_throw`, `substitution_foul_out`, `late_game` | `ACTION_SELECTED` tagged `endgame_two_for_one` (all five), and `endgame_hold` or `endgame_designed_play` in most of them — confirmed by grepping each dump's `detail_id` field, not inferred from the hash alone |
| `overtime` | The old seed (190056) stopped finishing level and needed a reseed — `find_scenario_seeds.gd` derived 31676 over a 2,000-seed search. The `test_play_sim_skip_parity.gd` suite duplicated this seed as a second hardcoded constant rather than reading `GoldenScenarios`, and needed the same fix by hand |

None of the six reaches `leading_protect`, the intentional miss, quick-two, or a timeout-advance-eligible rule profile — those four are covered by `tests/simulation/test_endgame_strategy.gd` and by direct reachability search instead, not by the golden set.

#### Tests and regression

`tests/simulation/test_endgame_strategy.gd`: every decision's eligibility gate (fires when eligible, refuses when ineligible), the two-for-one/hold mutual exclusion, the designated closer as a plain capability read, a real-game reachability search, and — the load-bearing one — `test_intentional_miss_never_touches_free_throw_probability`, which asserts `FreeThrowResolver.probability` is bit-identical whether or not the intentional-miss condition holds.

Writing this suite found three defects, all fixed and none in `EndgameStrategy` itself:

1. `test_game_management.gd`'s `test_timeouts_trigger_only_under_valid_conditions` treated every ledger `TIMEOUT` as a run-stopping one; top domestic now also grants timeout-to-advance, so it needed to branch on `detail_id`.
2. `test_play_sim_skip_parity.gd` duplicated the golden overtime seed as a second hardcoded constant instead of reading `GoldenScenarios`, and needed the same reseed by hand.
3. Two of this task's own new tests picked comparison points that crossed a *different*, pre-existing effect (two-for-one's window overlapping quick-two's; §20.1's `|margin| <= 5.0` free-throw pressure term) — both were test-isolation bugs, fixed by comparing a ratio and by choosing a same-window comparison margin respectively, not by touching production code.

Full GdUnit4 suite after every fix: **573 test cases, 0 errors, 0 failures, 48 suites**. Complete fast gate from a clean `.godot`: import, parse (242 scripts, 0 failures), project acceptance PASS, simulation smoke PASS, Builder calibration PASS, attribute sensitivity 80/80 judged 0 failures, calibration smoke 15/15 judged 0 failures, GdUnit4 573/573 — **every stage PASS**.

#### Calibration re-measurement

200 games per point, `run_competition_calibration.gd`, three seed ranges per competition — the same range before and after (700,000-700,199) plus two further untouched ranges (710,000-710,199 and 720,000-720,199), each range measured before *and* after so an apparent regression could be told apart from range-specific sampling variance rather than guessed at.

**College**, v8 → v9 (§14.1 field-goal percentage carried through unmoved, as required — 0.4104 before and after on the shared range, to four decimal places). *These "After" columns are the v9 arm, and are the **before** arm of §5.26's own comparison:*

| Range | Metric | Before | After |
| --- | --- | ---: | ---: |
| Same (700k) | Overtime | 3.00% ±2.50 | 3.50% ±2.67 |
| Same (700k) | Close game | 24.00% | 24.00% |
| Same (700k) | Blowout | 13.00% | 12.50% |
| Same (700k) | Home win | 52.00% | 52.50% |
| Validation A (710k) | Overtime | 1.50% | 2.00% |
| Validation A (710k) | Close game | 20.50% FAIL | 24.50% PASS |
| Validation A (710k) | Blowout | 19.50% FAIL | 20.50% FAIL |
| Validation B (720k) | Overtime | 4.00% PASS | 4.00% PASS |
| Validation B (720k) | Close game | 26.50% PASS | 27.50% PASS |
| Validation B (720k) | Blowout | 14.00% PASS | 14.00% PASS |

**Top domestic**, v8 → v9. *Same reading: the "After" column is v9, which §5.26 re-measures against v10:*

| Range | Metric | Before | After |
| --- | --- | ---: | ---: |
| Same (700k) | Overtime | 4.50% PASS | 1.50% FAIL |
| Same (700k) | Close game | 22.50% PASS | 22.50% PASS |
| Same (700k) | Blowout | 16.50% PASS | 15.50% PASS |
| Same (700k) | Home win | 57.50% FAIL | 56.50% FAIL |
| Validation A (710k) | Overtime | 4.50% PASS | 4.00% PASS |
| Validation A (710k) | Close game | 21.00% FAIL | 21.50% FAIL |
| Validation A (710k) | Blowout | 22.00% FAIL | 22.00% FAIL |
| Validation B (720k) | Overtime | 1.50% FAIL | 2.00% FAIL |
| Validation B (720k) | Close game | 18.00% FAIL | 17.00% FAIL |
| Validation B (720k) | Blowout | 28.00% FAIL | 27.00% FAIL |

**Reading this honestly.** The validation-range blowout and close-game failures are not new: measured before this task's code existed, on the identical seed range, they are the same within sampling noise (top domestic validation B blowout 28.00% before, 27.00% after; college validation A blowout 19.50% before, 20.50% after). These two ranges' rosters produce wide margins for reasons this task did not touch and did not introduce — confirmed by measuring the "before" arm specifically to settle it rather than assuming it. Overtime moved by less than one standard error in five of the six range/competition points and outside it in one (top domestic, same range: 9 of 200 games to 3 of 200) — within what a rate this rare produces run to run at n=200. **No range shows a confident pass of the 4-8% band that was not already at or near it before.** College reaches the floor on two of three ranges after (2.0%, 3.5%, 4.0%) against one of three before (1.5%, 3.0%, 4.0%) — a small, favourable, and not statistically decisive shift. Top domestic shows no consistent direction at all (4.5→1.5, 4.5→4.0, 1.5→2.0).

**Home-court estimator recheck** (`run_home_court_diagnostics.gd`, mirror mode, top domestic, `validation_c`, 200 matched pairs): `attributable_home_win_rate` 0.5450 ±0.0327, inside the 0.53-0.56 band; `canonical_form_agrees`, `reversal_agrees`, `cap_respected`, `sample_well_formed`, `sample_complete` all 1.0000. **The §5.19 result is not regressed.**

**Activation counts (PRE-CORRECTION)**, 200 games each, a fresh untouched range (950,000+), confirming every decision actually fires rather than being eligible-but-unreachable.

*Read these with §5.26 in hand.* This table was presented as evidence of reachability, and it is that. It was **also**, unread at the time, the clearest evidence of the timeout-advance defect: 491 and 836 activations in 200 games is between two and four calls per game, per competition, of a decision a coach makes once or twice a season's worth of close finishes. A count with nothing to compare it against could not say so, which is why `run_endgame_activation.gd` now reports per-game rates and margin states beside the raw counts.:

| Decision | College | Top domestic |
| --- | ---: | ---: |
| Two-for-one | 683 | 652 |
| Hold for the final shot | 145 | 152 |
| Quick-two vs. timeout-backed three | 6 | 9 |
| Designed final possession | 366 | 448 |
| Leading-by-three foul | 3 | 3 |
| Intentional free-throw miss | 5 | 6 |
| Timeout-to-advance | 491 | 836 |

Every one of the seven fires in real games at both competitions. The four §5.13 named as missing (two-for-one, the leading-by-three foul, timeout-to-advance, the designed play) are all reachable; three are common, one (the leading-by-three foul) is rare by design — `leading_foul_share` is deliberately smaller than the trailing team's desperation-foul share, because this is a live coaching debate rather than a last resort.

*Corrected reading (§5.26):* "fires in real games" was the whole of what this table was asked to establish, and it is a weaker claim than it looked. Three of these seven counts were produced by a decision firing in situations its own basketball rationale excludes — timeout-to-advance on essentially every trailing possession of a close last two minutes, the designed play for teams already comfortably ahead, and the intentional miss for the team that was *winning*. Reachability was real; correctness was not tested by it.

#### What this task did and did not establish

- **Built, structurally proven:** all seven decisions exist, are gated correctly (proven by the eligibility tests, not inferred), never reach a shot, free-throw, or contact probability (proven directly, not by absence of evidence), reconcile through the existing box-score projection unchanged, and are auditable in the ledger by construction.
- **Measured, not certified, and not decisive:** the six-point before/after comparison above. §27.1 asks for 100,000 games per competition; this task ran 200 per point, chosen to fit this environment rather than to settle the question, exactly as `run_competition_calibration.gd` itself reports every time it runs below certification size.
- **Not moved:** college's field-goal percentage (byte-identical on the shared range), college's or top domestic's blowout or close-game contracts (this task's brief explicitly forbade touching top domestic's blowout contract, and did not touch either), the home-court estimator's already-passing result.
- **Not answered:** whether the four-to-eight-percent band is reachable *at scale* with this repertoire. The honest read of six 200-game points is that the mechanism is real, bounded, and firing, and that it has not been shown — on the sample this environment can run — to close the gap §5.13 quantified as needing "roughly 30% of one-score finishes converted to exact ties against a current 20%". A future task with §27.1-scale compute, or CI hardware per §6.4, would settle this; this one could not.

No target in `BALANCE_SPEC.md` was changed. No million-scale certification was run. No pull request was opened or merged.

**What this section is now.** A complete and accurate record of a build and its
measurement, retained in full, whose behavioural conclusions do not carry
forward. §5.26 is the current state of the subsystem.

### 5.26 The endgame repertoire was built and gated backwards, and the v9 measurements measured that

Status: **`simulation-v10-endgame-corrections` corrects five of `EndgameStrategy`'s seven decisions — six defects across them — revokes a rule grant that should never have been made, and adds regression fixtures for the nine behaviours the correction brief named. The eight-step fast gate is green from a clean `.godot`. Golden ledgers were regenerated; four of six hashes moved and every divergence was located by first-differing event rather than accepted from the hash. §5.25's measurements are retained in full and reclassified as pre-correction diagnostics. Calibration was re-measured on the same three ranges, both arms, both competitions. NO OVERTIME CLOSURE IS CLAIMED.**

#### What was wrong

§5.25 shipped seven end-of-regulation coaching decisions and proved each one's
eligibility gate with a unit test. Every gate was internally correct: it fired
inside its window and refused outside it, and the suite proved exactly that.
What no test asked was whether the window described the situation a coach is
actually in — and for five of the seven it did not. One of those five was wrong
twice.

| Decision | What v9 did | Why that is not the basketball |
| --- | --- | --- |
| Intentional final free-throw miss | Fired for the team **ahead** by two or three | Inverted. A leading team wants every point it can add; the tactic exists for a trailing team whose free throw cannot tie but whose live rebound can. v9's version deliberately handed a live ball to the only side that needed one. |
| Hold for the final shot | Refused a **tied** team at every clock | Holding for the last shot of a tied game is the most ordinary end-of-regulation decision there is. v9 excluded it on the reasoning that a tied team wants two-for-one's extra possession instead — which is true only while there is time for that extra possession, i.e. exactly when the shot clock will expire before the game clock does. Inside that boundary the two clocks run out together and holding costs the offence nothing. v9 had the right reason and applied it at every clock instead of at the clocks it holds for. |
| Designed final possession | Boosted the designated closer at **every** margin | A team with a safe lead wants the clock, not its closer's best look. v9 pushed a winning team toward an early attempt in exactly the games it had already won. |
| Timeout-to-advance | Permitted whenever the competition allows it, the team is not ahead, it holds any timeout, and under two minutes remain | Those four conditions hold on *every* possession of *every* close last two minutes, so the answer was yes every time and the allowance was simply spent to zero. That is not a model of "a coach may advance the ball"; it is a model of a coach with nothing left when it matters. |
| Leading-by-three foul | Eligible on every action of a possession, in or out of the bonus | Outside the bonus the whistle awards no free throws: the offence keeps the ball, inbounds with a fresh shot clock, and can still shoot the three the foul was meant to prevent. And because nothing about the state changed, the same eligibility held on the next action, so one decision could become a run of whistles inside one possession. |
| Intentional miss, *second* defect | Had a ceiling on the clock and no floor | Found while writing the regression fixture, and only visible in played games: the plan is "miss, rebound, shoot", and nothing required the clock to hold a rebound and a shot. Measured across 2,000 games, **every** intentional miss the engine took ended on the horn before the rebound it was taken for. See correction 3a. |

A sixth item is not a gate at all but a rule:
`CompetitionRuleProfile.timeout_advance_permitted` was granted to **college**.
The 2026-09-01 owner ruling named college and top domestic as the two
competitions whose *measured overtime rate* was to be treated as evidence of
missing end-of-regulation behaviour. It said nothing about either competition's
rules. Turning "this competition's §14.2 measurement is low" into "this
competition advances the ball on a timeout" derives a §4 rule from a
calibration shortfall, which is §5.25's own pre-implementation confirmation 3
running in reverse. The grant is revoked. Top domestic keeps it on the only
ground that supports it: it is that rule set's rule.

**The v9 activation table said all of this and was not read that way.**
Timeout-to-advance at 491 activations per 200 college games and 836 per 200 top
domestic is two to four calls per game. Nothing in that report stated what the
number should look like, so an implausible count passed as evidence of
reachability. `run_endgame_activation.gd` now reports per-game rates and the
margin state of the deciding team beside every raw count, and judges four
shape invariants that would have failed at v9.

#### What changed

`EndgameStrategy`, `FoulResolver`, `PossessionEngine`, `MatchSession`,
`SimulationBalanceProfile`, `CompetitionRuleProfile`. No new class, no new
event type, no new seam — every correction narrows or redirects a decision that
already existed.

1. **College advancement revoked.** `college_profile()` no longer grants
   `timeout_advance_permitted`; `top_domestic_profile()` is the only profile
   that does. The comments in `competition_rule_profile.gd`,
   `endgame_strategy.gd`, `test_game_management.gd` and this document that
   treated the overtime ruling as a rule grant are corrected in place.
2. **The intentional miss is a trailing team's decision.** It fires only for
   the offence trailing by **exactly two** immediately before the last attempt
   of a trip (`EndgameStrategy.INTENTIONAL_MISS_DEFICIT`) — the single state
   where the point cannot tie and a live rebound can. Down one, a make ties.
   Down three or more, the point is worth having. A leading team never reaches
   it at any margin, clock, or attempt index. Two further conditions are
   load-bearing: the rule profile must make a missed final attempt live
   (`final_free_throw_reboundable`, or the plan is a plain surrender of the
   ball), and the emergency clock window must hold (with time for another
   possession, the point plus a stop is the better plan).
3. **The miss enters the ordinary live rebound, proven at the ledger.** It
   always did — `_resolve_free_throws` routes any unmade final attempt into the
   same `_resolve_rebound` every other miss uses — but nothing asserted it, and
   "the caller never consults `FreeThrowResolver`" reads uncomfortably close to
   "the caller decides who gets the ball." Two fixtures now settle it: a
   `REBOUND` event follows the intentional miss with no free-throw event
   between them, and across seeds **the defence wins the board too**. A
   decision that always produced an offensive rebound would be an award of the
   ball dressed as a miss; it is not one.
3a. **The emergency window has a floor, and had to be widened to clear it.**
   Writing the fixture above exposed a second defect in the same rule, and this
   one only shows up in played games. The plan is "miss, rebound, shoot", so
   the clock has to hold a rebound and a shot; there was no condition saying
   so. `EndgameStrategy.minimum_miss_window_ms` now supplies one, derived from
   the clock model that will actually charge for them — `rebound_seconds_max`
   for the board plus `action_seconds_min` for the putback, 3,000ms — and the
   rule refuses below it.
   That floor made the shipped window unreachable, which is the more
   interesting half. A free-throw trip charges `free_throw_event_seconds` per
   attempt, so a two-shot trip that begins inside the old 3,500ms window
   arrives at its last attempt with a millisecond left; the eligible band
   between floor and ceiling was about half a second wide. **Measured: across
   2,000 games at 3,500ms, every intentional miss the engine took had its
   possession end on the horn before the rebound it was taken for.** So
   `intentional_miss_clock_ms` is raised 3,500 → **7,000**, derived the same
   way rather than picked: above seven seconds the offence has a real
   alternative — take the free point, concede the ball, foul immediately and
   get it back — which needs the opponent's inbound (2s), the trip the foul
   buys them (4s) and one attempt of its own (1s). Inside seven seconds that
   plan does not fit and the miss is the only thing left.
   `SimulationBalanceProfile.validate()` now **fails** a profile whose window
   does not exceed its own floor, so the two numbers are related by validation
   rather than by a comment, and a future retune cannot quietly re-create a
   dead rule. Golden ledgers are unaffected by the change; the six hashes are
   identical with the window at 3,500 and at 7,000.
4. **A tied team may hold**, when the two clocks make it valid: regulation
   remaining inside the shot clock on the board, so the possession can be held
   to the horn instead of ending in a violation. Outside that the tied team
   still wants two-for-one's extra possession, which is exactly the
   complementary window — the two remain mutually exclusive, and the existing
   partition test still proves it.
5. **The designed play refuses a safe lead**, and refuses a deficit the clock
   cannot close. `EndgameStrategy.recoverable_deficit` draws that boundary from
   the clock rather than a fixed number: the possession in hand, plus one for
   every further `endgame_possession_ms` of regulation, each worth at most a
   three. A team down three with eight seconds gets its play; a team down nine
   with the same eight seconds does not.
6. **Timeout-to-advance is a decision.** Five conditions now stand between the
   rule and the whistle, each a reason a coach declines: a **dead-ball origin**
   (there is nothing to inbound after a live transfer, so the timeout stops a
   break rather than advancing anything); an **actionable margin** (trailing or
   tied, by a deficit `recoverable_deficit` says the clock can still close); a
   **meaningful clock benefit** (`timeout_advance_window_ms` retuned 120000 →
   **28000**, derived as one 24-second shot clock plus one four-second
   backcourt walk — past that the offence can walk the ball up and still run a
   full possession, so the allowance buys nothing); a **reserve**
   (`timeout_advance_reserve_timeouts`, 1, kept in hand *after* the call,
   because the possession that follows an advanced one is the one he needs to
   stop the clock for); and **not twice for the same possession**, held as
   session state rather than as an accident of call order.
7. **The leading-by-three foul is once per possession and only in the bonus.**
   `FoulResolver` now requires `bonus_free_throws_for(defense_team_fouls) > 0`
   — the same count the consequence branch reads, so the decision and its
   outcome cannot disagree about whether anybody is going to the line — and
   `PossessionEngine` allows it at most once per possession. The two guards are
   independent and both are needed: the bonus gate stops the foul that buys
   nothing, and the per-possession guard stops the second, third and fourth
   foul that would follow the one that bought something.

Ruleset bumped `simulation-v9-endgame-strategy` →
**`simulation-v10-endgame-corrections`**, because every one of the above changes
what the engine produces for the same input. One tunable added
(`timeout_advance_reserve_timeouts`) and two retuned
(`timeout_advance_window_ms` 120000 → 28000, `intentional_miss_clock_ms` 3500 →
7000), all registered through `describe_tunables()` with a name, unit and safe
range; the declared range on `timeout_advance_window_ms` was corrected too,
since 30000-180000 no longer contains its own value. Both retunes are derived
from the engine's own clock model in the comment beside them, and one of the
two is now enforced by `validate()` rather than trusted.

**No calibration target was changed.** `BALANCE_SPEC.md` is untouched — a
balance tunable is engine configuration, and the §14 bands these are measured
against are exactly as they were.

#### Regression fixtures

`tests/simulation/test_endgame_corrections.gd`, a suite separate from
`test_endgame_strategy.gd` on purpose: that one proves each gate in isolation,
this one is the named regression fixture per corrected behaviour, written so
that reintroducing the original defect fails it. Where the correction is about
what a coach does rather than what a predicate returns, the fixture drives a
real possession or a real match through the public path and reads the ledger —
because a predicate that is right and a ledger that is wrong is precisely the
failure mode the v9 measurements did not catch.

| Brief item | Fixture |
| --- | --- |
| College advancement refusal | `test_college_refuses_to_advance_the_ball_on_a_timeout` (profile and decision, with the same state under the same profile and only the grant flipped), `test_no_college_game_emits_an_advance_timeout` (6 played games) |
| Top-domestic advancement eligibility | `test_top_domestic_still_advances_the_ball_when_a_coach_would`, `test_the_advance_timeout_is_still_reachable_in_real_top_domestic_games` (30 played games) |
| Timeout-reserve preservation | `test_an_advancing_team_finishes_the_match_still_holding_its_reserve` (30 played games; the run-stopping trigger closes at 90s and the advance window opens at 28s, so nothing but an advance timeout can be called once the first one has been, which makes the final allowance a valid ledger statement of the bound) |
| Tied-team final-shot hold | `test_a_tied_team_holds_for_the_final_shot` (eligible *and* the reset weight actually applied; refused when the shot clock expires first) |
| Comfortable-lead clock drain | `test_a_comfortable_lead_drains_the_clock_instead_of_boosting_its_closer` (no closer boost **and** the hold weight still in place, so what replaced the boost is the draining the situation calls for rather than nothing) |
| Trailing intentional miss | `test_a_trailing_team_intentionally_misses_its_final_free_throw` (driven through `PossessionEngine`: the defence up three and in the bonus fouls, the offence shoots two, the first goes in, the last is missed on purpose) |
| Live rebound following the miss | `test_the_intentional_miss_enters_the_ordinary_live_rebound`, `test_the_defence_can_win_the_board_after_an_intentional_miss` |
| Leading-team refusal to intentionally miss | `test_a_leading_team_at_the_line_never_intentionally_misses` (the same fixture with the scores reversed, over 160 seeds), plus `test_a_leading_team_never_intentionally_misses` in the gate suite over every lead × attempt count × clock |
| Non-bonus / repeated leading-foul prevention | `test_no_leading_by_three_foul_is_committed_outside_the_bonus`, `test_at_most_one_leading_by_three_foul_per_possession`, `test_no_played_match_commits_two_leading_by_three_fouls_in_one_possession` (12 played games) |

The two suites together are **47 test cases**, all passing — the two added
beyond the brief's nine are the emergency-window floor found while writing the
trailing-miss fixture (correction 3a) and the profile validation that keeps the
window above it.

#### Golden-ledger impact

Regenerated deliberately with `tools/golden_ledger_harness.gd`, which also
re-verifies that every scenario still exercises the behaviour it is named for.
**Four of six hashes changed. Two did not, and that is evidence rather than an
omission.** Every divergence was located by dumping the full ledger from a
worktree at `063a1cc` and diffing it against the same dump from this tree, so
the first differing event is a fact rather than an inference from a hash.

| Scenario | First differing event | What changed |
| --- | --- | --- |
| `regulation` | seq 1132, period 4, 9397ms, away trailing **12** | `endgame_designed_play` → untagged. Down twelve with 9.4 seconds is not a recoverable deficit, so no play is drawn up for the closer. |
| `offensive_rebound` | seq 1146, period 4, 9401ms, home leading **6** | `endgame_designed_play` → `endgame_hold`. The lead stops boosting its closer and the reported decision becomes the clock-drain that was already applying underneath it. |
| `substitution_foul_out` | seq 933, period 4, 12345ms, home leading **14** | `endgame_designed_play`/`relocation` → `endgame_hold`/`screen`. The first divergence here is a genuinely different action, not only a different tag: the closer's boost was what had selected the relocation. |
| `late_game` | seq 410, period 2, 6156ms, away trailing **4** | `endgame_designed_play` → untagged. Down four with 6.2 seconds left is one possession's worth of clock and four points; the arithmetic does not close. |
| `overtime` | — | **Byte-identical.** Its possessions never reach a decision v10 changed, and its seed (31676) did not need to move again. |
| `foul_free_throw` | — | **Byte-identical**, same reason. |

Every changed scenario's **final score, possession count and event count are
unchanged**; the corrections altered late-game action *selection* without
altering any of these six outcomes. All four divergences are the designed play
correctly refusing a team it should never have been drawn up for — which is
what the correction is, visible in the one place a golden ledger can show it.

#### The eight-step fast gate

Complete, from a clean `.godot`, in the order `tools/run_checks.sh` runs them:

| Step | Result |
| --- | --- |
| 1. Import (builds the global class cache) | PASS |
| 2. Parse-check under warnings-as-errors | PASS — 243 scripts, 0 failures |
| 3. Project-owned headless acceptance | PASS |
| 4. Fixed-seed simulation smoke | PASS — invariants hold |
| 5. Builder smoke portfolio (§7.3.2 bands) | PASS — 810 builds, every class inside band |
| 6. Attribute sensitivity (PR sample, 100,000 resolutions) | PASS |
| 7. Calibration smoke (PR sample, 6 games) | PASS |
| 8. GdUnit4 suites | PASS — **600 test cases, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans, 49 suites** |

(573 cases at §5.25; the 27 added are this task's regression fixtures and the
gate-suite cases the corrections required.)

#### Calibration: the same three ranges, both arms, both competitions

200 games per point, `run_competition_calibration.gd`, the identical seed ranges
§5.25 used (700,000-700,199 / 710,000-710,199 / 720,000-720,199), each measured
at v9 **and** v10 so a difference is the correction rather than a range.

**The v9 arm reproduces §5.25 exactly.** Every one of the twelve overtime /
close-game / blowout / home-win figures §5.25 published in its "After" columns
comes back byte-identical from a worktree at `063a1cc`, and so does every one of
the fourteen v9 activation counts below. The pairing is therefore anchored:
what follows is a v9→v10 comparison, not two independent samples that happen to
be nearby.

**College** — the profile that lost the timeout-advance grant:

| Range | Metric | v9 | v10 |
| --- | --- | ---: | ---: |
| Same (700k) | Overtime | 3.50% FAIL | 3.00% FAIL |
| Same (700k) | Close game | 24.00% PASS | 24.00% PASS |
| Same (700k) | Blowout | 12.50% PASS | 12.00% PASS |
| Same (700k) | Home win | 52.50% FAIL | 53.00% **PASS** |
| Same (700k) | Field goal % | 0.4104 FAIL | 0.4099 FAIL |
| Validation A (710k) | Overtime | 2.00% FAIL | 1.50% FAIL |
| Validation A (710k) | Close game | 24.50% PASS | 23.50% PASS |
| Validation A (710k) | Blowout | 20.50% FAIL | 20.00% FAIL |
| Validation B (720k) | Overtime | 4.00% PASS | 4.50% PASS |
| Validation B (720k) | Close game | 27.50% PASS | 27.00% PASS |
| Validation B (720k) | Blowout | 14.00% PASS | 13.50% PASS |

**Top domestic** — the profile that keeps it:

| Range | Metric | v9 | v10 |
| --- | --- | ---: | ---: |
| Same (700k) | Overtime | 1.50% FAIL | 2.50% FAIL |
| Same (700k) | Close game | 22.50% PASS | 24.00% PASS |
| Same (700k) | Blowout | 15.50% PASS | 16.00% PASS |
| Same (700k) | Home win | 56.50% FAIL | 56.50% FAIL |
| Validation A (710k) | Overtime | 4.00% PASS | 3.50% **FAIL** |
| Validation A (710k) | Close game | 21.50% FAIL | 21.00% FAIL |
| Validation A (710k) | Blowout | 22.00% FAIL | 22.00% FAIL |
| Validation A (710k) | Home win | 55.00% PASS | 52.00% **FAIL** |
| Validation B (720k) | Overtime | 2.00% FAIL | 2.00% FAIL |
| Validation B (720k) | Close game | 17.00% FAIL | 19.00% FAIL |
| Validation B (720k) | Blowout | 27.00% FAIL | 27.50% FAIL |

**No overtime closure is claimed, and none is visible.** Overtime moves by at
most one percentage point at any of the six points, in both directions, with a
±2.1-3.0 point interval at n=200 — which is what a rate this rare does run to
run. College reaches the 4-8% floor on one of three ranges before and one of
three after. Top domestic on none after against one before. This is the same
verdict §5.25 reached, for the same reason: 200 games per point is not a sample
that can settle a 4% rate, and §27.1 asks for 100,000.

#### §14.1 regression check

Every §14.1 metric, both competitions, all three ranges, v9 against v10 —
**zero PASS→FAIL regressions on college**, and two on top domestic validation A,
reported rather than explained away:

| Verdict change | v9 | v10 | Interval | Reading |
| --- | ---: | ---: | ---: | --- |
| college home win, same range | 52.50% FAIL | 53.00% PASS | ±6.9 | Band edge crossed upward by half a point. |
| top domestic overtime, validation A | 4.00% PASS | 3.50% FAIL | ±2.6 | 8 games of 200 became 7. It was sitting exactly on the 4.00% floor. |
| top domestic home win, validation A | 55.00% PASS | 52.00% FAIL | ±6.9 | The largest single movement in the whole comparison, and still well inside its own interval; the same metric on the other two ranges moved 0.00 and -1.50 points and stayed on the same side of the band. |

Every one of the three is a marginal band crossing with a delta far smaller
than the interval attached to it, and each was already within a point or two of
its boundary at v9. **Every single §14.1 metric across all six
range/competition points moved by less than its own reported interval
half-width** — including possessions per game, points per possession, field
goal, three-point, free-throw, turnover, offensive-rebound, assist and rotation
minutes, which stay PASS on both arms wherever they were PASS. The two top
domestic verdict changes are honest FAILs that the correction is not exonerated
from, and they are not evidence of a broken mechanism at this sample size.

College's §14.1 field-goal percentage moved 0.4104 → 0.4099 on the shared
range. §5.25 required it to carry through unmoved and it did not quite: the
correction changes which action a late-game offence selects, so a shot mix
shifts by five ten-thousandths against a ±0.0055 interval. It is stated here
rather than rounded away. The metric's FAIL verdict is unchanged and its cause
is still what §5.22/§5.23 attributed it to.

#### Controlled home-court estimator

`run_home_court_diagnostics.gd`, mirror mode, top domestic, `validation_c`, 200
matched pairs — the identical cell §5.25 rechecked:

| Metric | v9 (§5.25) | v10 | Verdict |
| --- | ---: | ---: | --- |
| `venue.attributable_home_win_rate` | 0.5450 ±0.0327 | **0.5350 ±0.0299** | PASS, inside 0.53-0.56 |
| `venue.canonical_form_agrees` | 1.0000 | 1.0000 | PASS |
| `venue.reversal_agrees` | 1.0000 | 1.0000 | PASS |
| `venue.cap_respected` | 1.0000 | 1.0000 | PASS |
| `venue.sample_well_formed` | 1.0000 | 1.0000 | PASS |
| `venue.sample_complete` | 1.0000 | 1.0000 | PASS |
| `home.combined_cap_respected` | — | 1.0000 | PASS |

**The §5.19 result is not regressed.** The point estimate moved one point
inside a ±3.0-point interval and stayed in band, and every structural invariant
is exactly 1. This is the controlled measurement, and it is the one that speaks
to the `home_win_rate` verdict changes in the uncontrolled competition report
above: `run_competition_calibration.gd`'s home-win figure is measured over
population fixtures where the strength gap is not zero, which is why §5.19
exists.

#### Activation counts and shape, v9 against v10

200 games per competition, range 950,000+, the same cell §5.25 reported.
**Every one of the fourteen v9 counts below reproduces §5.25's table exactly**,
which is what makes this a paired comparison rather than a fresh measurement.

| Decision | College v9 | College v10 | Top domestic v9 | Top domestic v10 |
| --- | ---: | ---: | ---: | ---: |
| Two-for-one | 683 | 676 | 652 | 623 |
| Hold for the final shot | 145 | **311** | 152 | **326** |
| Quick-two vs. timeout-backed three | 6 | 13 | 9 | 18 |
| Designed final possession | 366 | **55** | 448 | **48** |
| Leading-by-three foul | 3 | 2 | 3 | 1 |
| Intentional free-throw miss | 5 | **0** | 6 | **1** |
| Timeout-to-advance | 491 | **0** | 836 | **28** |

Reading the four that moved:

- **Timeout-to-advance.** College goes to zero because the rule is revoked —
  the correct number for a competition that does not have the rule. Top
  domestic goes from 4.18 calls per game to **0.14**, and the most any single
  team spent in any single game falls from **6 to 2**. That is the difference
  between an allowance being drained and a coach making a decision.
- **Designed final possession** falls by roughly six-sevenths, which is the
  share of final possessions that belonged to a team already ahead or buried.
- **Hold for the final shot** roughly doubles, from tied teams now being
  allowed to hold and from the tag priority no longer being taken by a designed
  play that has correctly refused.
- **Quick-two** roughly doubles with no change to its own gate: `active_tag`
  reports the highest-priority decision in force, and the designed play used to
  outrank it. This is a change in what the ledger *labels*, not in what the
  engine *does* — the numeric effect of every decision that holds is applied
  independently of which one is named.

**The four shape invariants, which are the corrections stated as properties of
played games:**

| Invariant | College v9 | College v10 | Top domestic v9 | Top domestic v10 |
| --- | --- | --- | --- | --- |
| `no_leading_team_intentionally_missed` | **FAIL** | PASS | **FAIL** | PASS |
| `no_repeated_leading_foul` | PASS | PASS | **FAIL** | PASS |
| `no_advance_below_reserve` | **FAIL** | PASS | **FAIL** | PASS |
| `no_unpermitted_advance` | PASS | PASS | PASS | PASS |

The underlying counts are the sharpest statement of the defects in this whole
document:

- Of the **11** intentional free-throw misses v9 took across these 400 games,
  **every single one** — 5 of 5 at college, 6 of 6 at top domestic — was taken
  by a team that was not trailing by two. Not most: all of them. The decision
  never once fired in the state the tactic exists for. The larger sample below
  extends this to **38 of 38**.
- **And not one of those 11 produced a rebound**; all 11 possessions ended on
  the horn instead (`miss_ended_on_the_horn`). That is the second defect,
  measured: see correction 3a and the pooled table below.
- v9 called **181** college and **113** top domestic advance timeouts that left
  the calling coach below the reserve, out of 491 and 836.
- v9 committed **one** second leading-by-three foul inside a single possession
  at top domestic in 200 games — rare, and exactly the thing that cannot happen
  by construction now.

All four invariants are 1.0000 at v10 for both competitions.

#### The intentional miss at a larger sample, and what follows it

The intentional miss is rare by construction after the correction — a trailing
team, at the line, down exactly two before its last attempt, inside the final
seven seconds — so 200 games is too small to say anything about it. Pooling
every sample taken for this section (200 games per competition on range
950,000+ and 1,000 more on 955,000+, both arms, **2,400 games per version**)
settles three separate questions:

| Across 2,400 games per version | v9 | v10 |
| --- | ---: | ---: |
| Intentional misses taken | 38 | **5** |
| ...taken by a team **not** trailing by two | **38** | **0** |
| ...that resolved a live rebound | 5 | **5** |
| ...whose possession ended on the horn first | 33 | **0** |
| Rebounds won by the offence / the defence | 1 / 4 | **2 / 3** |

1. **Is it still reachable?** Yes — five in 2,400 games, about one every 480,
   which is what a state this specific should look like. Narrowing it did not
   narrow it into nothing, and the earlier 3,500ms window very nearly did
   (correction 3a).
2. **Is it correctly targeted?** Yes, and unambiguously. Across 2,400 v9 games
   the decision fired 38 times and **all 38 were the wrong team**. Across 2,400
   v10 games it fired 5 times and **none** were. Not most: none.
3. **Does it enter the live rebound rather than becoming an automatic
   possession outcome?** Yes, and this is now settled in production play rather
   than only in a fixture. **All five v10 misses resolved a `REBOUND` event —
   two won by the offence and three by the defence.** None ended on the horn.
   A decision that awarded the ball would show five offensive rebounds; a
   decision that was not live would show none. The route is structural —
   `_resolve_free_throws` sends any unmade final attempt into the same
   `_resolve_rebound` every other miss uses, with no branch for intentionality,
   and `EndgameStrategy` refuses outright under a profile where a missed final
   attempt is not live — and the ledger agrees with the structure.
   The contrast with v9 is the clearest single measurement in this section: 33
   of v9's 38 misses had the period expire before the board was contested at
   all, because the decision was gated on a window its own free-throw trip
   consumed. v9's intentional miss was, in practice, a team that did not need
   the rebound throwing away a free point and then the game ending.

#### What this task did and did not establish

- **Corrected, and proven at both the decision and the ledger:** all six gate
  defects and the revoked rule grant, each with a named regression fixture that
  fails if the original behaviour returns, and each with a v9→v10 activation or
  shape figure showing the change in played games rather than only in a
  predicate.
- **Not moved:** any calibration target (`BALANCE_SPEC.md` is untouched); the
  §5.19 home-court result (rechecked on the final code, in band at 0.5350
  ±0.0299, every invariant 1.0000); every §14.1 metric on college (zero
  PASS→FAIL across three ranges); the golden `overtime` and `foul_free_throw`
  scenarios (byte-identical); the final score, possession count and event count
  of all six golden scenarios.
- **Moved and reported rather than explained away:** two top domestic
  validation-A verdicts (overtime 4.00%→3.50%, home win 55.00%→52.00%), both
  marginal band crossings with deltas inside their own intervals; college's
  field-goal percentage by 0.0005 on the shared range, against §5.25's claim
  that it carried through unmoved.
- **NOT ESTABLISHED — no overtime closure is claimed.** The corrected engine
  does not confidently move college or top domestic into the §14.2 4-8% band at
  200 games per point, and this task neither claims it does nor treats the
  correction as evidence that it will. What the correction establishes is that
  the *previous* measurement was of a repertoire pointed the wrong way, so
  §5.25's mixed result was never the clean test of the owner ruling it was
  taken for. Whether the band is reachable at scale with a correctly gated
  repertoire remains open, and §27.1-scale compute or CI hardware per §6.4 is
  what would settle it.

No million-scale certification was run. No pull request was opened or merged.

### 5.27 The two decisions §5.26 left alone, read the way §5.26 read the others

Status: **§9 item 14 discharged. `run_endgame_decision_trace.gd` reads both decisions per activation instead of per count. Quick-two had a defect and is corrected by `simulation-v11-quick-two-stakes-window`; two-for-one was measured against a matched control and left unchanged because no defect was demonstrated. A third finding, in the ledger rather than in either decision, is reported and deliberately not fixed. Full suite 603 cases, 0 failures. NO OVERTIME CLOSURE IS CLAIMED AND NOTHING HERE IS CERTIFIED.**

#### The standard, and why the existing report could not meet it

§9 item 14 fixed the standard: the two defects §5.26 found were "both invisible
to a gate test and visible in an activation count", and neither two-for-one nor
quick-two had been read that way. But an activation count is only half of what
§5.26 actually used. A count says how often a decision fired; it never says
whether the thing the decision fired *for* then happened. Timeout-to-advance was
caught by a count because 491 per 200 games is absurd on its face. Nothing about
"two-for-one fired 3.23 times per game" is absurd on its face, so a count could
never have caught anything here.

`run_endgame_decision_trace.gd` reports the other half. For every activation it
records the clock the gate actually read, the shot clock, the margin, the action
selected and its family and zone, the milliseconds that action was charged, the
possession's outcome, whether the team got the ball back in the same period, the
timeout allowance before and after, and whether the sequence the decision exists
to set up was still arithmetically available when the possession ended.

**No engine instrumentation is involved.** Each game is played normally and its
ledger is then replayed through a second `MatchStateReducer`. The state
immediately before an `ACTION_SELECTED` event applies is the state
`EndgameStrategy.active_tag` read when the engine tagged it — the tag is
evaluated as an argument to `_emit`, so it runs before the reducer advances the
clock for that event — and the production gates are re-evaluated on it directly,
never a copy of their arithmetic. Two clocks are involved and they are not the
same number: the ledger records the clock *after* the action's time is charged,
every window in `EndgameStrategy` is drawn against the clock *before*, and every
clock quoted below is the second one.

That reconstruction is checked rather than asserted. Every recomputed tag is
compared against the tag the engine wrote: **1.000000 agreement over 39,383
final-period selections in 200 college games and 27,240 in 200 top domestic**,
with every mismatch accounted for by the ledger gap named below.

#### Finding 1 — quick-two was complementary to the tie-seeking rule at one stakes tier and inside it at the other two

`quick_two_preferred` exists to prefer a two at a three-point deficit *outside*
the window `GameManagement.endgame_multiplier` already owns, where that rule is
preferring the tying three. Its docstring asserted the two windows were
complementary and the gate test proved it. Both were true of regular-season
stakes and of nothing else.

The tie-seeking window is `StakesPolicy.endgame_window_ms`, which scales
`endgame_possession_ms` by `stakes_endgame_window_step`; quick-two was drawn
against the unscaled constant:

| stakes | tie-seeking window opens | quick-two window | overlap |
| --- | --- | --- | --- |
| regular | 32,000ms | (32,000, 46,000] | 0% |
| postseason | 48,000ms | (32,000, 46,000] | **100%** |
| championship or elimination | 64,000ms | (32,000, 46,000] | **100%** |

Inside the overlap the two rules disagree by construction and both multiply into
the same §10.3 factor, so the disagreement resolves as a product:

| stakes | tie rule, three | tie rule, two | quick-two, three | quick-two, two | net three | net two |
| --- | --- | --- | --- | --- | --- | --- |
| postseason | 1.50 | 0.5625 | 0.70 | 1.30 | **1.05** | **0.73** |
| championship | 1.60 | 0.4750 | 0.70 | 1.30 | **1.12** | **0.62** |

The three still wins at both tiers. Quick-two therefore never reverses the
preference it exists to reverse, and its entire effect above regular-season
stakes is to dilute the tie-seeking rule inside exactly the games the stakes
tiers exist to model.

The window is now measured from where the tie-seeking window actually ends at
the stakes the game carries, keeping its own span past it
(`EndgameStrategy.quick_two_span_ms`). A regular-season game reads
`endgame_window_ms == endgame_possession_ms` and reproduces the shipped window
to the millisecond, so **no committed golden, no §14 measurement and no
regular-season activation moves**; `run_stakes_diagnostics` at tiers 1 and 2
does, which is why the balance version moves. `validate()` now refuses a profile
whose two quick-two numbers leave no span, the same standard the
intentional-miss floor is held to since §5.26.

This was invisible to a gate test for a specific and repeatable reason: **every
fixture in the endgame suites carries `GameStakes.DEFAULT`.** The predicate was
correct at the one tier it was ever evaluated at. The new fixture drives all
three tiers, and fails at two of them against the previous gate.

It was equally invisible to an activation count. Both rules fire; a count cannot
show that they cancel.

#### Finding 2 — two-for-one changes what is selected and does not change what it is selected for

Two-for-one was measured against a matched control rather than argued about: the
same seeds and the same rosters, replayed with `two_for_one_urgency` zeroed and
nothing else different, on both competitions at 200 games per arm. Roster
generation has already happened by the time the knob is overwritten, so the arms
differ in the decision and in nothing else.

| measure | college | top domestic | pooled | 95% CI | verdict |
| --- | --- | --- | --- | --- | --- |
| direct-shot share | 13.9% → 17.5% | 14.4% → 17.2% | **+3.19pp** | +0.47 to +5.91 | significant (p=0.022) |
| possession length | 19,288 → 19,092ms | 17,142 → 16,583ms | −408ms | −925 to +109 | not distinguishable from zero |
| got the ball back again | 96.8% → 95.7% | 95.4% → 95.5% | −0.58pp | −2.07 to +0.91 | not distinguishable from zero |

The multiplier is wired and does what it says at the level it operates on: it
moves selection toward direct shots, consistently in both competitions and
significantly when the two independent samples are pooled. What it does not do,
at this sample, is buy the extra possession the decision exists for. The
possession does not get meaningfully shorter and the rate of getting the ball
back does not move at all.

**That is a bounded efficacy finding, not a defect, and nothing was changed on
the strength of it.** A decision that measurably shifts action selection is not
broken; it is a decision whose downstream effect is smaller than the noise at
200 games per arm. Two observations sit beside it without being acted on:

- Two-for-one applies no `recoverable_deficit` gate, unlike the two sibling
  decisions §5.26 corrected. **66.9% of college activations and 72.1% of top
  domestic ones are at a deficit of seven or more**, worst observed −37 and −41.
  A team down 37 with a minute left is still told to hurry. Hurrying is not
  obviously wrong basketball at any deficit, which is exactly why this is
  recorded rather than corrected: no defect is demonstrated.
- At the low end of the window the tactic is arithmetically marginal.
  Bucketing college by decision clock, only **6.4%** of activations in the
  (30s, 35s] band ended the possession with more than one shot clock left,
  against 98.8% in the (45s, 50s] band. The gate's lower bound is one shot
  clock; a genuine two-for-one needs closer to one shot clock plus two
  possessions.

Two claims the code makes about itself were checked and **hold**: `hold_for_final_shot_active`
and `two_for_one_active` never both apply (the live shot-clock cap is what saves
it, exactly on the boundary for top domestic), and quick-two composes rather than
conflicts with two-for-one, since one is keyed on action family and the other on
zone.

One claim does **not** hold, and is recorded without being acted on: quick-two's
timeout condition is justified by "a timeout in reserve to stop the clock after a
made two before fouling", and the engine has no mechanism by which a trailing
team spends a timeout that way. `_consider_timeout` and `_consider_advance_timeout`
are both evaluated only for the team *about to receive the ball*, and the only two
timeout causes are `run` and `advance`. Measured: **0 of 646 college and 0 of 696
top domestic two-for-one activations, and 0 of 3 and 0 of 17 quick-two
activations, spent a timeout after the decision.** The gate is a condition on a
resource that is never spent for the stated purpose. It is left in place because
it only ever narrows activation, and §5.25's ruling is explicit that the
repertoire is "not satisfied by a decision that fires more often".

#### Finding 3 — the putback is never tagged, so the activation report undercounts

Found by the reconstruction check rather than looked for.
`PossessionEngine._resolve_rebound` emits the offensive-rebound putback's
`ACTION_SELECTED` with a hardcoded empty `detail_id` instead of
`EndgameStrategy.active_tag`, so a putback taken while a decision was in force is
recorded in the ledger as though no decision was. It is **11 of 646** two-for-one
activations per 200 college games and **15 of 696** per 200 top domestic.

It is reported and **deliberately not fixed here**. It changes no played game —
no resolver reads that slot, and the putback is chosen by
`ReboundResolver.attempts_putback` on a path the §10.3 weight product never
touches — but `detail_id` is inside `MatchDomainEvent.signature()`, so correcting
it moves every committed golden hash. That is a deliberate act deserving its own
change, not something an audit should carry in silently. §5.26's conclusions do
not rest on it: none of the five decisions it corrected is an `ACTION_SELECTED`
event.

#### Contract change

`EndgameStrategy` is now the fifth declared reader of a stakes tier.
`test_only_the_declared_consumers_read_a_stakes_tier` failed on the correction,
which is that assertion doing its job, and the reader is declared rather than
routed around — passing the read through `GameManagement` would have kept the
list at four names while leaving the behaviour exactly as stakes-dependent. The
grant stays inside what `GameStakes` already permits a tier to change, "how early
he starts managing the last possession": the tier moves the circumstance in which
a preference between two legal shots applies, and reaches no probability, no
rating and no result.

#### Classification

- **ESTABLISHED.** Quick-two's window was inside the tie-seeking window at both
  stakes tiers above regular season, the two rules disagree there by
  construction, and the three wins anyway. Corrected, regression-fixtured across
  all three tiers, and mutation-checked: the fixture fails at two tiers against
  the previous gate.
- **ESTABLISHED.** Regular-season behaviour is unchanged to the millisecond, so
  every §14 figure recorded under `simulation-v10-endgame-corrections` remains
  comparable.
- **ESTABLISHED.** Two-for-one's multiplier shifts direct-shot selection by
  +3.19pp pooled (95% CI +0.47 to +5.91).
- **NOT ESTABLISHED.** That two-for-one buys the possession it exists for. The
  effect on possession length and on regaining the ball is indistinguishable
  from zero at 200 games per arm. This is a limit of the sample as much as a
  statement about the decision.
- **NOT ESTABLISHED — and not claimed.** That either finding moves the §14.2
  overtime band. Quick-two fires 0.015 times per game in college and 0.085 in
  top domestic at regular-season stakes; a decision at that rate cannot move a
  4-8% band whatever it does, and the correction is to its stakes behaviour,
  which no regular-season measurement sees at all.

### 5.28 Ten thousand games on a frozen ruleset: the overtime shortfall is no longer a sampling question

Status: **10,000 complete games per competition for college and top domestic, four seed-disjoint shards each, aggregated by `ReportAggregator` with every shard present and no seed overlap, plus 5,000 games per competition on a second disjoint range measuring the regulation margin distribution directly. NOT CERTIFIED AND NO CERTIFICATION IS CLAIMED — 10,000 games is one tenth of the §27.1 requirement and both aggregations ran under `--allow-uncertified`. The §14.2 overtime band is missed by both competitions on both ranges, 6.4 and 14.6 standard errors below the floor pooled over 15,000 games each, with the interval excluding the band. The margin curve is peaked at zero but not peaked enough, and the two competitions are short by very different amounts. No target was changed.**

#### What was run, and on what

The ruleset was frozen at `e55d015` before the run and not touched during it. The
two aggregate reports carry different commit stamps — `e55d015` for college and
`39fe2001` for top domestic — because §5.27 was committed to `PROJECT_STATUS.md`
while the run was in progress. **The diff between those two commits is
`PROJECT_STATUS.md` and nothing else; no `.gd` file differs**, so both
competitions were measured on the same engine, the same rules and the same
`simulation-v11-quick-two-stakes-window` balance. That is stated here rather
than papered over, because a report whose provenance line has to be explained is
worth exactly as much as the explanation.

Four shards of 2,500 games per competition, seeds 1..10,000, aggregated by
pooling numerators and denominators rather than averaging shard rates.
`certification.all_shards_present` passes; `certification.sample_reached` fails
by design and the report says so in its own notes.

`run_regulation_margin_shape.gd` then measured the regulation margin
distribution over four shards of 1,250 games per competition on seed range
970,001 onward, disjoint from the calibration run and from every other section's
range. The endgame activation audit was re-run at 2,000 games per competition on
its own 950,001 range.

#### §14.2 game shape, with intervals

| competition | metric | estimate | 95% CI | band | verdict |
| --- | --- | --- | --- | --- | --- |
| college | overtime | 0.0290 | [0.0257, 0.0323] | 0.04–0.08 | **below, 6.6 SE, CI excludes** |
| college | close game | 0.2671 | [0.2584, 0.2758] | 0.22–0.34 | inside |
| college | blowout | 0.1474 | [0.1405, 0.1543] | 0.08–0.18 | inside |
| college | home win | 0.5436 | [0.5338, 0.5534] | 0.53–0.56 | inside |
| top domestic | overtime | 0.0216 | [0.0188, 0.0244] | 0.04–0.08 | **below, 12.7 SE, CI excludes** |
| top domestic | close game | 0.2179 | [0.2098, 0.2260] | 0.22–0.34 | marginal, 0.5 SE, CI straddles |
| top domestic | blowout | 0.2262 | [0.2180, 0.2344] | 0.08–0.18 | **above, 11.0 SE, CI excludes** |
| top domestic | home win | 0.5413 | [0.5315, 0.5511] | 0.53–0.56 | inside |

#### §14.1, with intervals

Top domestic passes **every** §14.1 metric: field goal 0.4576 ±0.0007, three
point 0.3774 ±0.0011, three-point rate 0.3641 ±0.0007, free throw 0.8006
±0.0012, free-throw rate 0.2200 ±0.0006, turnovers 13.88 per 100, offensive
rebound 0.2532 ±0.0009, assist 0.5845 ±0.0010, possessions 101.75 ±0.05, points
per possession 1.1675. **The §5.5 points-per-possession miss is closed** — 1.1675
against a 1.08–1.18 band, where §5.5 measured 1.2084 — and so is the assist
percentage that §5.5 reported at 0.4815.

College passes every §14.1 metric **except field goal percentage**: 0.4114
[0.4106, 0.4122] against a 0.42–0.49 band, **21.1 standard errors below the
floor**. Possessions 72.12 ±0.04, points per possession 1.0486, three point
0.3301, turnovers 15.42 per 100, assist 0.5265, offensive rebound 0.2535 all
pass. The §5.23 college field-goal package is the open owner decision that
already names this, and this run measures it at a sample that removes any
remaining doubt that it is real.

#### The finding that matters for §9 item 13

§5.26 closed with the honest verdict that **200 games per point cannot settle a
4% rate**, and put the choice to the owner as "fund a §27.1-scale run that could
answer it, or amend the band". Ten thousand games per competition answers it
without a §27.1-scale run:

- College overtime is **6.6 standard errors** below the band floor.
- Top domestic overtime is **12.7 standard errors** below it.
- Both intervals exclude the entire 4–8% band. Neither is within reach of
  sampling noise.

**The shortfall is a mechanism gap, and it is established.** This is measured on
the corrected repertoire — every §5.26 shape invariant passes on both
competitions at 2,000 games (no leading team intentionally missed, no repeated
leading foul, no advance below reserve, no unpermitted advance), with
timeout-to-advance now at 0.0000 per game in college where the grant was revoked
and 0.1315 in top domestic where the rule is real, against the 2.46 and 4.18 per
game that §5.25 measured. So the repertoire is present, correctly gated, and
firing at plausible rates, **and the band is still missed decisively**. Building
it did not close the gap. That is a direct answer to the question §5.13 raised
and §5.25 could not settle, and it is worth more than the correction that
produced it.

#### Where the gap is *not*, and what its shape actually is

College is the informative case, because it now satisfies both of the other
§14.2 shape bands: close games 0.2671 (inside 0.22–0.34) and blowouts 0.1474
(inside 0.08–0.18). **A margin distribution of the right width still produces
less than three quarters of the overtime the band asks for.** So the overtime
shortfall is not the §5.5/§5.6 over-dispersion seen from another angle — that
defect is fixed for college and the overtime miss survived it.

The three §14.2 shape metrics are three points on one curve: overtime is the
mass at exactly zero, close game the mass within five, blowout the mass at
twenty or beyond. Two rates cannot distinguish a curve of the wrong *width* from
one of the wrong *shape*, so `run_regulation_margin_shape.gd` measures the curve
directly over 5,000 games per competition on its own seed range.

**The measurement corrects the inference that produced it.** Reasoning from the
two aggregate rates alone suggested a locally flat distribution, because zero's
share of the close-game mass (college 12.1%, top domestic 10.1%) sits near the
9.1% a flat curve would give. That statistic is misleading on its own: `|margin|`
folds two signed buckets into one for every non-zero value and one into one at
zero, so a flat *signed* distribution mechanically produces 1-in-11. Read in
signed density, both curves are genuinely peaked at zero:

| signed density, share of games | college | top domestic |
| --- | --- | --- |
| margin = 0 | 0.03500 | 0.02380 |
| mean over margin = ±1…±5 | 0.02532 | 0.02130 |
| **peak ratio at zero** | **1.38** | **1.12** |

So the engine does concentrate the margin on zero; it does not concentrate it
*enough*, and the two competitions are short by very different amounts. College's
zero bucket holds 175 games of 5,000 where the 4% floor needs 200 — **14% more
mass at exactly zero**. Top domestic's holds 119 where it needs 200 — **68%
more**. Within the close band the mass also rises with margin in both (college
175, 174, 263, 274, 263, 292 across |margin| 0 to 5), so the peak at zero is
narrow: one bucket above a rising shoulder rather than a broad mode.

That splits the remaining work rather than merging it. **College needs a modest
increase in zero-concentration and nothing else** — its width is right and its
peak is already 1.38x its neighbourhood. **Top domestic needs both**: its
distribution is still too wide (blowouts 0.2262, 11.0 SE above band, improved
from §5.5's 34.5% but not closed) and its zero peak is much weaker at 1.12x.
Treating the two competitions' overtime misses as one defect would be a mistake.

#### A caution the second range raises

The shape run used a disjoint seed range, which means a different synthetic
roster population, and the two ranges do not agree as closely as sampling alone
predicts:

| competition | seeds 1..10,000 | seeds 970,001..975,000 | difference | pooled (n=15,000) |
| --- | --- | --- | --- | --- |
| college overtime | 0.0290 [0.0257, 0.0323] | 0.0350 [0.0299, 0.0401] | +0.0060, p=0.052 | 0.0310 [0.0282, 0.0338] |
| top domestic overtime | 0.0216 [0.0188, 0.0244] | 0.0238 [0.0196, 0.0280] | +0.0022, p=0.397 | 0.0223 [0.0200, 0.0247] |

Top domestic is consistent across ranges. **College is borderline** — a 0.6
percentage point swing at p=0.052, which is large relative to a band floor of 4%
and is a roster-population effect rather than a sampling one, since both samples
are large. Neither range brings college inside the band, and pooled over 15,000
games it sits 6.4 standard errors below the floor while top domestic sits 14.6
below, so the conclusion is unaffected. But it means **a single seed range is not
a safe basis for a §14.2 verdict at this precision**, and any §27.1 run should
draw across ranges rather than extend one.

#### What this says about funding §27.1

Recorded as evidence for the owner, not as a decision:

A 100,000-game certification would narrow every interval above by a factor of
about 3.2. It would not bring any of the four decisive misses inside its band —
college overtime, top domestic overtime, top domestic blowout, and college field
goal percentage are excluded by 6.4, 14.6, 11.0 and 21.1 standard errors
respectively (the two overtime figures pooled over 15,000 games), and a 3.2x
narrowing moves none of them. **A §27.1 run funded
today would spend ten times this run's compute to certify a ruleset that already
fails four bands with the failure established.** The evidence supports spending
the next increment on the zero-concentration mechanism and on the §5.23 college
field-goal decision, then certifying.

#### Classification

- **ESTABLISHED.** College and top domestic miss the §14.2 overtime band, on two
  disjoint seed ranges and pooled over 15,000 games each (college 0.0310, 6.4 SE
  below; top domestic 0.0223, 14.6 SE below), with the interval excluding the
  band. The shortfall is not sampling noise, and §5.26's open question about
  sample size is closed.
- **ESTABLISHED.** The corrected endgame repertoire is present and correctly
  gated at 2,000 games per competition — all four §5.26 shape invariants pass —
  and the overtime band is missed anyway.
- **ESTABLISHED.** College's §14.2 margin *width* is now inside band on both
  close-game and blowout rates while its overtime rate is not, so the two are
  separable defects.
- **ESTABLISHED.** Top domestic closes the §5.5 points-per-possession and
  assist-percentage misses and passes all of §14.1; its blowout rate does not.
- **ESTABLISHED.** College field goal percentage is 21.1 SE below its §14.1
  floor.
- **ESTABLISHED.** The regulation margin distribution is peaked at zero rather
  than flat — signed density ratio 1.38 for college, 1.12 for top domestic — and
  the deficiency is the size of that peak, not its absence. College needs 14%
  more mass at exactly zero, top domestic 68%.
- **ESTABLISHED.** College's overtime rate differs between two large disjoint
  seed ranges by 0.6 percentage points at p=0.052. A single range is not a safe
  basis for a §14.2 verdict at this precision.
- **NOT ESTABLISHED.** What mechanism produces the missing zero-concentration in
  real basketball and is underweight here. The measurement localizes and sizes
  the gap; it does not name the mechanism.
- **NOT CLAIMED.** Certification of anything. 10,000 games is a tenth of §27.1
  and both aggregations ran under `--allow-uncertified`.
- **NOT CHANGED.** The 4–8% overtime target, and every other §14 band.

### 5.29 The missing putback tag is closed, timeout is removed from quick-two, and the tie gap is localized to final-possession execution

Status: **`simulation-v12-endgame-ledger-and-resource-contract` repairs two
established contract defects and one bounded final-action defect, adds a
reproducible regulation-tie decomposition runner, and measures the results on
matched seeds. The work improves attempt creation without touching shot,
contact, free-throw, rebound, or turnover probability. It does not close the
4–8% overtime band, change a target, or claim certification.**

#### Putback ledger continuity

`PossessionEngine._resolve_rebound` now stamps an offensive-rebound putback's
`ACTION_SELECTED.detail_id` with `EndgameStrategy.active_tag`, exactly as the
ordinary action loop already does. The known `offensive_rebound` golden scenario
proves the path and the dedicated test requires its fourth-quarter putback to
carry `endgame_two_for_one`.

Five golden scenarios are byte-identical to `8216e28`. The only changed hash is
`offensive_rebound`, from `5081bb9c…70551` to `c5dd8d06…13269`. The first and
only causal divergence is action sequence 1110 in period four at 48,101ms: the
putback's formerly empty `detail_id` becomes `endgame_two_for_one`. Seed 7001,
score 43–31, event count 1,160, and every played outcome are unchanged.

#### Quick-two owns no timeout

The quick-two plan is now stated and gated as what production actually models:
take the quick two, then foul on the opponent's inbound. No production path
spends a timeout in that sequence, so requiring an unused timeout was a false
resource dependency. The gate is now independent of timeout inventory and its
tunable is renamed from `quick_two_timeout_window_ms` to
`quick_two_window_ms`. Its stakes-scaled non-overlap boundary from §5.27 remains
unchanged. A paired test holds score, clock and stakes fixed and proves zero
timeouts and one timeout produce the same decision.

#### Two-for-one efficacy, at a larger matched sample

`run_endgame_decision_trace.gd` was run for 500 games per arm and competition,
with identical seeds and rosters in live and zero-gain arms:

| competition | direct-shot share, live → zero | possession ms, live → zero | another possession, live → zero |
| --- | ---: | ---: | ---: |
| college | 18.4% → 15.1% | 19,171 → 19,760 | 96.4% → 95.9% |
| top domestic | 19.5% → 16.8% | 15,267 → 15,801 | 94.6% → 95.6% |

The rule reliably changes the decision it owns: direct-shot selection rises
2.7–3.3 percentage points and the possession is roughly 0.5–0.6 seconds
shorter. It does not reliably increase the chance of another possession,
which is already 95–96%. **Two-for-one is therefore validated as tactical
selection and clock behavior, and rejected as the missing overtime mechanism.**
No production value changed.

#### The new decomposition and the defect it found

`run_regulation_tie_decomposition.gd` replays the authoritative ledger through
a second reducer and reports, separately by competition:

- signed margin buckets at 120, 60 and 30 seconds and their final transitions;
- possessions beginning inside 30 seconds while tied or trailing by at most
  three;
- tying field-goal and free-throw attempts, makes, and attempt-clock buckets;
- no-attempt possessions split by tied/trailing state, start clock, expiry and
  end reason;
- pregame capability-strength gap; and
- every endgame mechanism tag.

On seeds 990,001–990,250 before the final-action correction, college produced
24 no-attempt possessions from 46 tieable opportunities, 20 by period expiry;
top domestic produced 17 from 41, 16 by expiry. The failure was downstream of
margin creation and upstream of shot resolution: the engine selected a legal
action, consumed its full bounded duration, and—when that draw crossed the
horn—terminated the possession before emitting the action or its attempt.

The repair is deliberately narrow. Once a tied or recoverably trailing team's
designed play is inside the existing 2,500ms desperation threshold, an already
selected action whose ordinary duration would cross the horn is scheduled one
millisecond before it. Candidate selection stays stochastic. The action can
still turn the ball over, draw contact, miss, or make through the unchanged
resolvers. A leading team and every possession outside the designed-play gate
retain the ordinary clock draw.

Matched post-correction results on the same 250 games:

| competition | no attempt | expired without attempt | tying FG attempts | regulation ties |
| --- | ---: | ---: | ---: | ---: |
| college | 24 → **20** | 20 → **16** | 4 → **6** | 6 → **6** |
| top domestic | 17 → **9** | 16 → **7** | 7 → **10** | 2 → **2** |

This is the required shape: lost final actions and horn expiries fall, actual
attempts rise, and ties are not injected. At 250 games the overtime count does
not move, so **no overtime improvement is claimed**.

The remaining no-attempt expiries are now sharply localized. Eleven of
college's sixteen and all seven of top domestic's seven start with 0–5 seconds
already on the clock. They die in the inbound/advance/half-court opening states
before action selection, so the selected-action deadline cannot reach them.
That is a distinct opening-state clock contract requiring its own basketball
ruling—especially whether dead-ball inbound event time belongs on the game
clock and how sub-five-second full-court possessions are represented. It is not
silently altered here.

All eight fast-gate constituents pass on the final tree: import; parse (**246
scripts, 0 failures**); project acceptance; simulation smoke; Builder smoke;
attribute sensitivity (**80/80 judged, 0 failures**); calibration smoke
(**15/15 judged, 0 failures**); and GdUnit4 (**607/607 cases, 49/49 suites, 0
errors or failures**). The GdUnit run initially exposed that the parse-gate
self-test did not mirror the shipped import-before-parse entry point when its
temporary broken fixture was removed. The self-test now imports before each
isolated subprocess parse and serializes fixture access; its focused suite is
**7/7** on the exact final tree. This is gate evidence, not §27.1
certification.

#### Classification

- **CLOSED.** Putback actions preserve the endgame tag in force; the golden
  divergence is isolated and outcome-neutral.
- **CLOSED.** Quick-two no longer depends on a timeout no modeled sequence can
  spend; its stakes boundary remains complementary to tie-seeking.
- **VALIDATED, UNCHANGED.** Two-for-one affects shot selection and possession
  time, not the already-saturated ball-back rate; it is not the overtime fix.
- **CORRECTED.** Selected designed-play actions can no longer disappear solely
  because their duration draw crossed the horn inside the desperation window.
- **ESTABLISHED.** The remaining final-possession loss is concentrated before
  action selection in the opening-state clock path, especially possessions
  beginning with no more than five seconds.
- **NOT CLAIMED.** Overtime closure or certification. The 4–8% band is unchanged.

### 5.30 The opening-state clock contract: the inbound restarts the clock, and a five-second possession commits from where it stands

Status: **`simulation-v13-opening-clock-and-location-contract` implements the
2026-09-04 owner ruling on possession openings. A throw-in onto a stopped clock
no longer consumes game time; a possession beginning inside five seconds commits
to an attempt from its actual court location instead of running a half-court set
it has no time for; and that location enters shot resolution as a bounded §12.6
distance term — `TacticalLocation`'s first production reader. On the frozen
250-game paired range, college's expired-without-attempt possessions fall 16 → 9
and top domestic's 7 → 6, with the 0–5s bucket falling 11 → 6 and 7 → 4. It does
not close the 4–8% overtime band, change a target, or claim certification. It
does move §14.1 possessions per game out of band in both competitions, which is
reported below as a regression rather than compensated for.**

#### The owner ruling

Six clauses, quoted in substance:

1. Dead-ball inbound setup does not consume live game-clock time; the clock
   starts on the legal touch, so `INBOUND` emits at the possession's starting
   game clock.
2. After the touch, ordinary advancement and half-court setup still consume live
   clock. Normal possessions keep their bounded behaviour.
3. A possession beginning with five seconds or less must not have to complete the
   whole inbound → advance → half-court-entry sequence before action selection.
4. The desperation path must be location-aware, using the existing
   `TacticalLocation` rather than a parallel `is_heave` boolean.
5. A backcourt or unusually deep attempt must not receive ordinary arc odds; the
   distance consequence enters through the existing shot contract as a bounded,
   auditable term that cannot inspect the score, the band, or the desired result.
6. The system may create an opportunity, never an outcome.

#### Previous behaviour, and why the defect was structural

`PossessionEngine._open_possession` charged three draws before any action could
be chosen: `inbound_ms` (2–4s), `advance_ms` (2–5s) and `half_court_entry_ms`
(2–4s). Their minimum is **six seconds**. A possession that began with five or
fewer therefore expired in the opening states *whatever it drew* — not often,
not usually, but always. §5.29's selected-action deadline could not reach these
possessions because no action had been selected to release.

#### Exact implementation

- **`ClockResolver.inbound_ms` is renamed `running_clock_inbound_ms`** and the
  caller, not the resolver, decides whether to charge it.
- **`MatchSession._clock_stopped`** is a new session fact: true after any whistle
  restart and at every period start, false after a made basket in open play. It
  is written from the committed possession record and read only by the engine.
- **`PossessionEngine._open_possession`** takes `clock_stopped` and emits
  `INBOUND` at the possession's own clock whenever the clock was stopped, or
  whenever the possession is inside the desperation window. Otherwise it charges
  the running-clock inbound exactly as before.
- **`PossessionEngine._open_desperate`** runs when the possession begins at or
  below `desperation_opening_clock_ms` (5,000). It draws and charges the advance
  exactly as the ordinary path does — this is not free time — and *skips*
  half-court entry rather than discounting it. If the advance completes, the ball
  is `DEEP`; if it would cross the horn, the offence never gets it across and the
  ball is `BACKCOURT`.
- **`PossessionContext.ball_location`** carries that `TacticalLocation`, and is
  `null` on every possession that ran the ordinary opening.
- **`PossessionContext.desperation_opening`** records how the possession opened.
  `EndgameStrategy.final_release_due` returns true for such a possession, so the
  first action it manages to select is released before the horn instead of
  disappearing one state later.
- **`ShotResolver._location_distance_penalty`** subtracts a bounded term equal to
  the attempt's *excess* rim distance over the distance its own zone implies,
  normalized so one full arc-to-backcourt step costs
  `location_distance_penalty_max` (0.25). It is published in the shot probe and
  accumulated by `ShotTermAccumulator`.

#### Clock ownership

| Fact | Written by | Read by |
| --- | --- | --- |
| `_clock_stopped` | `MatchSession` only, from the committed record | `PossessionEngine._open_possession` only |
| `desperation_opening` | `PossessionEngine._open_possession` only | `EndgameStrategy.final_release_due` only |
| `ball_location` | `PossessionEngine._open_desperate` only | `ShotResolver` only |

None is folded into `live_start` or `advance_start`, which answer different
questions — whether there is anything to inbound, and whether a timeout bought
the frontcourt — and would have become ambiguous carrying a second meaning.

#### TacticalLocation ownership

§30.2 carried "`TacticalLocation` exists as a type but no resolver reads it" as
outstanding. It is now read by exactly one resolver, for exactly one purpose, on
possessions that genuinely produce a location. The type gained one static
accessor (`rim_distance_for_depth`) and nothing else. **The §30.2 item is not
closed**: tactical coordinates still do not drive rebound positioning, contest
arrival, or help distance, and this task deliberately did not expand them there.

#### A correction the measurement forced, and the assumption it rests on

Clause 1 applied to *every* dead-ball restart produces a decisive regression.
The engine calls every non-live possession start a dead ball, including the
restart after a made basket — but in real basketball the clock does not stop
after a made field goal in open play, and the throw-in happens on a running
clock. Charging nothing there frees roughly three and a half minutes of game time
per game:

| college, 200 games, seeds 0–199 | baseline | clause 1 applied to every restart |
| --- | ---: | ---: |
| possessions per game (target 64–73) | 71.89 ±0.30 **PASS** | **79.10 ±0.34 FAIL** |

So the ruling is implemented where the clock is genuinely stopped — after a
whistle, and at every period start — and the running-clock inbound is kept where
the clock never stopped. Inside the desperation window the clock is treated as
stopped whatever the cause, because every dead-ball restart stops it and a made
basket in the last five seconds is inside every modelled competition's late-game
stop. **Stated as an assumption rather than hidden:** `PossessionEndReason` does
not separate a made field goal from a made free throw, and a made final free
throw does stop the clock. Both are treated as running. The error is in the
direction that preserves the possessions band rather than inflating it, and
inside the last five seconds the desperation path already treats the clock as
stopped. Closing it needs a new end reason and is not taken here.

#### Matched measurement — the regulation-tie decomposition

`run_regulation_tie_decomposition.gd`, 250 games per competition, seeds
990,001–990,250, identical rosters and seeds in all three columns. Phase A
reproduces §5.29's published counts exactly.

**College**

| | A: baseline | B: stopped-clock inbound only | C: full contract |
| --- | ---: | ---: | ---: |
| regulation ties | 6 | 6 | 5 |
| final-30s opportunities | 47 | 38 | 42 |
| tying field goals | 1/6 | 3/6 | 0/6 |
| tying free throws | 1/2 | — | 1/1 |
| tieable possessions without attempt | 20 | 15 | **13** |
| expired without attempt | 16 | 11 | **9** |
| no-attempt start clock 0–5s | 11 | 9 | **6** |
| no-attempt end reasons | expired 16, turnover 4 | expired 11, turnover 4 | expired 9, turnover 4 |

**Top domestic**

| | A: baseline | B: stopped-clock inbound only | C: full contract |
| --- | ---: | ---: | ---: |
| regulation ties | 2 | 7 | 5 |
| final-30s opportunities | 41 | 54 | 54 |
| tying field goals | 2/10 | 4/11 | 5/12 |
| tying free throws | 2/3 | — | 1/2 |
| tieable possessions without attempt | 9 | 13 | 9 |
| expired without attempt | 7 | 10 | **6** |
| no-attempt start clock 0–5s | 7 | 6 | **4** |
| no-attempt end reasons | expired 7, turnover 2 | expired 10, turnover 3 | expired 6, turnover 3 |

Phase B is column B in isolation — the inbound contract with the desperation
window set to zero — and it is reported because it is the half of the change that
moves possession count. It is not the shipped configuration.

The mechanism does what it was built to do: **possessions dying before action
selection fall, and the 0–5s bucket that §5.29 localized falls hardest.** It does
not empty: the remainder are possessions that reach action selection and then
turn the ball over, or genuinely fail to release, which is the contract working
rather than failing.

#### Backcourt and deep attempts remain rare

`run_opening_state_audit.gd`, a new diagnostic runner, 100 games per competition
on seeds 990,001–990,100. The opening a possession ran is reconstructed from its
own events, so no new ledger field was needed.

| | college | top domestic |
| --- | ---: | ---: |
| possessions per game (both teams) | 147.38 | 206.88 |
| dead-ball openings still charged a running clock | 81.40% | 83.31% |
| desperation openings per game | 0.870 | 1.930 |
| — of which backcourt / deep | 65 / 22 | 128 / 65 |
| desperation share of all possessions | 0.590% | 0.933% |
| **desperation attempts as a share of all field-goal attempts** | **0.25%** | **0.41%** |
| desperation attempts made | 5 / 34 (0.1471) | 20 / 80 (0.2500) |
| desperation possessions ending in a turnover | 2 | 3 |
| desperation possessions expiring without transfer | 75 of 87 | 164 of 193 |

A quarter to four tenths of one percent of attempts, made at 15–25% rather than
at the arc's ~37%, with most such possessions still ending with no attempt at
all. That is an opportunity, not an outcome.

#### §14.1 and §14.2, matched at 200 games per competition

Seeds 0–199, identical rosters. **Every verdict change is named.**

| college | baseline | v13 | change |
| --- | ---: | ---: | --- |
| possessions per game (64–73) | 71.89 ±0.30 PASS | 73.16 ±0.29 | **PASS → FAIL** |
| points per possession (0.98–1.10) | 1.0445 PASS | 1.0491 PASS | — |
| field goal % (0.42–0.49) | 0.4099 FAIL | 0.4095 FAIL | already failing (§5.23) |
| three point % (0.31–0.38) | 0.3203 PASS | 0.3204 PASS | — |
| three-point rate (0.32–0.46) | 0.3473 PASS | 0.3467 PASS | — |
| free throw % (0.67–0.79) | 0.7139 PASS | 0.7080 PASS | — |
| free-throw rate (0.20–0.38) | 0.2469 PASS | 0.2495 PASS | — |
| turnovers per 100 (15–21) | 15.37 PASS | 15.28 PASS | — |
| offensive rebound % (0.24–0.34) | 0.2544 PASS | 0.2565 PASS | — |
| assist % (0.48–0.68) | 0.5181 PASS | 0.5162 PASS | — |
| home win (0.53–0.56) | 0.4500 FAIL | 0.4850 FAIL | already failing |
| overtime (0.04–0.08) | 0.0200 FAIL | 0.0200 FAIL | unmoved |
| close game (0.22–0.34) | 0.2750 PASS | 0.2800 PASS | — |
| blowout (0.08–0.18) | 0.1200 PASS | 0.1250 PASS | — |

| top domestic | baseline | v13 | change |
| --- | ---: | ---: | --- |
| possessions per game (96–103) | 101.91 ±0.38 PASS | 103.66 ±0.31 | **PASS → FAIL** |
| points per possession (1.08–1.18) | 1.1701 PASS | 1.1658 PASS | — |
| field goal % (0.45–0.51) | 0.4587 PASS | 0.4559 PASS | — |
| three point % (0.34–0.40) | — | 0.3743 PASS | — |
| turnovers per 100 (11–16) | — | 14.08 PASS | — |
| offensive rebound % (0.20–0.31) | — | 0.2502 PASS | — |
| assist % (0.52–0.72) | — | 0.5831 PASS | — |
| home win (0.53–0.56) | — | 0.5350 PASS | — |
| overtime (0.04–0.08) | 0.0250 FAIL | 0.0150 FAIL | still failing |
| close game (0.22–0.34) | 0.1850 FAIL | 0.1850 FAIL | unmoved |
| blowout (0.08–0.18) | 0.2850 FAIL | 0.2550 FAIL | still failing |

**The possessions regression is real and is this change's doing.** Freeing the
throw-in on whistle restarts — 18.6% of college's dead-ball openings, 16.7% of
top domestic's — returns roughly three seconds each, which buys about 1.3 and 1.8
extra possessions per game. Both point estimates now sit just outside a band
ceiling their intervals still straddle (college [72.87, 73.44] against 73.0; top
domestic [103.34, 103.97] against 103.0).

It is **not compensated for here.** The pace environment
(`CompetitionRuleProfile.pace_multiplier`) was calibrated against a clock model
that charged a throw-in the rules do not charge, so it now absorbs an error that
no longer exists. Re-deriving it per competition against the corrected contract
is the honest response and is a calibration decision, not an opening-state
defect; making it inside this task would have tuned a band to hide a mechanism.
**Recorded as the open item this change creates.**

Overtime: college unmoved at 0.0200, top domestic 0.0250 → 0.0150. At 200 games
either figure is four or five games; **no overtime movement is claimed in either
direction**, and none of this brings either competition near the 4–8% band.

#### Tests and mutation checks

`tests/simulation/test_opening_clock_contract.gd`, 17 cases, all passing, one per
clause of the ruling plus the invariants the ruling must not break. The five
mutations the brief names were run against it; every one is caught:

| mutation | caught by |
| --- | --- |
| reintroduce inbound game-clock consumption | `test_a_dead_ball_possession_emits_inbound_without_reducing_the_game_clock` |
| remove the desperation-opening branch | 7 cases, first `test_a_possession_below_five_thousand_ms_gets_no_free_half_court_setup` |
| treat a backcourt attempt like an ordinary arc attempt | `test_a_backcourt_attempt_does_not_receive_ordinary_arc_shot_odds` |
| guarantee the outcome of a located attempt | `test_no_desperation_path_guarantees_an_attempt_a_make_or_a_tie` |
| let the selected action cross the horn | `test_a_possession_shorter_than_any_action_draw_still_selects_one` |

**Two of those five initially survived, and the tests were strengthened rather
than the mutations softened.** A guaranteed make survived a possession-level
"some attempt was missed", because blocked attempts satisfy it on their own; the
assertion is now a per-attempt make-rate ceiling. A selected action crossing the
horn survived "every `ACTION_SELECTED` sits before the horn", because an action
that crosses the horn is never emitted and the assertion passed vacuously; a new
case starts a possession with less time than the shortest action draw, so only
the release clamp can produce an action at all.

#### Golden ledgers

All six hashes moved, deliberately, with the ruleset bumped to
`simulation-v13-opening-clock-and-location-contract`. Dumps were diffed against
`451dda8` per scenario.

**In all six, the first differing event is the same one**: the game's opening
`INBOUND`. The last identical event is `possession_started` at the period's full
clock; the inbound then emits at that same clock instead of two to four seconds
into it. Every later difference is downstream clock realignment and the different
game that follows from it — not a separate cause.

| scenario | last identical | first divergence | cause |
| --- | --- | --- | --- |
| regulation | `possession_started` @300000 | `inbound` 296000 → **300000** | inbound timestamp |
| overtime | `possession_started` @180000 | `inbound` 177000 → **180000** | inbound timestamp |
| offensive_rebound | `possession_started` @300000 | `inbound` 297000 → **300000** | inbound timestamp |
| foul_free_throw | `possession_started` @240000 | `inbound` 237000 → **240000** | inbound timestamp |
| substitution_foul_out | `possession_started` @240000 | `inbound` 236000 → **240000** | inbound timestamp |
| late_game | `possession_started` @240000 | `inbound` 236000 → **240000** | inbound timestamp |

Possessions rise in every scenario (regulation 78 → 80, offensive_rebound 73 →
74, substitution_foul_out 60 → 65), which is the same freed clock the §14.1 table
above measures.

The **overtime scenario's seed moved 31676 → 7919**, derived by
`find_scenario_seeds.gd` over a 600-seed search: 31676 no longer finishes level,
and a golden overtime scenario that reaches no overtime tests nothing. It is
again the only seed that moved; the other five still exercise their named
behaviour at the seeds they have always had.

#### Fixtures re-derived, and what was deliberately not weakened

Four suites outside the new one needed work. None had its assertion loosened:

- **`test_play_sim_skip_parity`** tracks the golden overtime seed by design, so
  its `OVERTIME_SEED` moved with it to 7919. **Skip/play parity itself never
  failed** — the failure was the fixture guard reporting that its game no longer
  reached overtime.
- **`test_endgame_corrections`** piggybacked on the `offensive_rebound` golden
  scenario for a fourth-quarter putback taken while two-for-one was active. At
  seed 7001 those two no longer coincide, though the scenario still has both its
  endgame tags and its five putbacks. The golden seed was **not** moved for an
  unrelated suite's convenience; the test now owns seed 7043 on the same fixture,
  found by reachability search.
- **`test_home_environment`**'s venue turnover edge was reading a signed mean of a
  per-game count over **12 games**. Measured over the same seeds, the forward
  arm's running mean is +0.250 at 12, −0.056 at 36, +0.233 at 60, −0.362 at 80
  and −0.890 at 200; the pre-v13 tree gave −0.380 at 200. **The venue effect is
  intact and at 200 games larger than before** — the 12-game fixture was reading
  noise and passed previously by luck. Its sample is raised to 100 per arm, which
  strengthens the assertion. A paired estimator over the same games would reach
  the same verdict far cheaper and is recorded as the better future shape.
- **`test_fg_decomposition`** re-pins the assisted share 0.6387 → 0.6571 and names
  why: the clock every possession starts on is an input to §10.3 through
  `GameManagement.remaining_ms`, so the action mix shifts. The other four pinned
  compensation channels are unmoved on the same fixture, which is the
  discrimination that test exists to provide. `ShotTermAccumulator` also gained
  the `location_penalty` term, because its own residual test correctly caught a
  term going missing from the attribution.

#### Validation

Run from a clean generated state (`.godot` removed) with `tools/run_checks.sh`:

| check | result |
| --- | --- |
| import | pass |
| parse gate | **248 scripts, 0 failures** |
| project acceptance | pass |
| simulation smoke | pass |
| Builder smoke | pass |
| attribute sensitivity | **80/80 judged, 0 failures** |
| calibration smoke | **15/15 judged, 0 failures** |
| GdUnit4 | **623/623 cases, 50/50 suites, 0 errors, 0 failures** |

`git diff --check` is clean. Gate evidence, not §27.1 certification.

#### Classification

- **CLOSED.** A throw-in onto a stopped clock consumes no game time, and
  `INBOUND` emits at the possession's starting clock. Work-queue item 18's first
  question — which opening stages consume live game clock — is answered.
- **CLOSED.** A possession beginning inside five seconds reaches action selection
  and can release a legal attempt before the horn. Item 18's second question —
  how a full-court desperation possession is represented — is answered: it
  advances if it can, commits from where it stands, and is charged for the
  distance.
- **CLOSED.** `TacticalLocation` has a production reader, and a backcourt or deep
  attempt no longer resolves on arc odds.
- **ESTABLISHED.** The opening-state loss §5.29 localized falls by 44% for
  college (16 → 9) and 14% for top domestic (7 → 6) on matched seeds, with the
  0–5s bucket falling 45% and 43%.
- **ESTABLISHED.** Backcourt and deep attempts are 0.25% and 0.41% of all
  field-goal attempts and go in at 15–25%.
- **REGRESSION, REPORTED NOT COMPENSATED.** §14.1 possessions per game moves out
  of band in both competitions (college 71.89 → 73.16 against 64–73; top domestic
  101.91 → 103.66 against 96–103) as the direct arithmetic consequence of not
  charging a throw-in the rules do not charge. The pace environment was
  calibrated against the old clock model and now needs re-deriving.
- **NOT ESTABLISHED.** Any overtime movement. College is unmoved at 0.0200 and
  top domestic moves 0.0250 → 0.0150 on 200 games, which is noise in both
  directions.
- **NOT CLAIMED.** Overtime closure, Stage 4 closure, or certification of
  anything. No §27.1 sample was run.
- **NOT CHANGED.** Every `BALANCE_SPEC.md` target and tolerance, including the
  4–8% overtime band. No shot accuracy, contact, free-throw, rebound or turnover
  probability was touched, no score was mutated, and no production path reads a
  calibration output.

## 6. Certification and workflow blockers

### 6.0 Blocker classification, corrected

Two items have been carried in the remaining-blocker lists as though they were open implementation defects. They are not, and §5.20 corrects the classification so the list reflects what is actually outstanding.

| Item | Correct classification |
| --- | --- |
| **Career progression** | **Structurally complete and measured green.** All five §8.4 career-peak bands measure inside their locked targets, executor parity is exact at 0.0000, and the §9.5 guardrail is enforced by construction (§5.8, §5.9). **Certification pending only** — §27.1 asks for 1,000,000 careers, which §6.4 explains no developer machine produces. Not an implementation defect |
| **Projected Peak** | **Structurally complete and measured green.** Coverage 0.7473 and 0.7370 against 70–85%, signed error −1.0 and 0.0 against ±2, both on untouched validation ranges, with 0 pathological subgroups (§5.7). **Certification pending only.** Not an implementation defect |
| **Top-domestic points per possession** | **Corrected (§5.20).** 1.1694 ±0.0037 pooled over two untouched 1,000-game ranges against 1.08–1.18. No longer a blocker |
| **High-school field-goal percentage** | **Not a repeatable failure (§5.22).** Two untouched 1,000-game validation ranges pool to 0.3888 ±0.0018 against a 0.390 floor, with the interval reaching the band, and one of four fresh ranges passes outright. Recorded as a **measured marginal/unresolved row**, not as a failure. Not an implementation defect |
| **College field-goal percentage** | **Confirmed as a repeatable measurement, cause now identified to the property (§5.22, §5.23).** 0.4124 pooled over two untouched 1,000-game ranges against a 0.420 floor, every range interval below it; 0.4115 on a fresh 400-game range. Every production hypothesis is ruled out by counterfactual measurement — field-goal percentage follows the **roster** (±0.03 to ±0.05) and not the rule profile (∓0.005). §5.23 measures the fixture against the production creation-and-development contract and finds the fixture's rating **level** corroborated (67.01 against 67.40) and its shooting **shape** not (three-point 66.01 against 70.21). **§5.24 repairs the `_family_weights` defect those figures were measured through and re-measures on the same seeds: the level finding survives (67.01 against 67.48) and so does the three-point gap, which widens to 66.01 against 70.74; the `short_range`, `mid_range` and `dunking` rows are withdrawn, and with them the assumption that a uniform shooting lift matches production.** **A fixture shape defect plus a linear-roster-against-non-linear-band specification conflict, not an implementation defect.** An owner-decision package is delivered at [`docs/STAGE4_COLLEGE_FIELD_GOAL_OWNER_DECISION.md`](docs/STAGE4_COLLEGE_FIELD_GOAL_OWNER_DECISION.md); the decision is not taken |

What remains genuinely open is listed in §6.4 and §9: **the college field-goal row, now carried as an owner decision between the calibration fixture's shooting shape, its roster ladder, and §14.1's band ladder rather than as an engine defect (§5.22, §5.23)**, ~~the `CareerSimulator._family_weights` defect §5.23 found in the calibration harness~~ (**repaired in §5.24**; what remains of it is the re-derivation of Option A's per-zone shooting offsets, which is blocked behind roster generation), the §14.2 overtime, close-game and blowout rows, **the Development §14.2 home-win row, which §5.21 classifies as a measured contest/home-environment interaction blocker at 0.5280 ±0.0206 pooled over two untouched ranges**, Builder dominance, OVR truthfulness, postseason scheduling, the perimeter contest gap recorded in §5.20 §10, and the §27.1 certification sample itself.

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
6a. **Take the §5.23 college field-goal owner decision**, or record a deliberate deferral to §27.1. The package is complete and the evidence is delivered; what is missing is the owner's choice of which contract moves. Nothing downstream is blocked by the deferral.
6b. ~~**Repair `CareerSimulator._family_weights`**~~ **Done (§5.24).** The emphasis vector now resolves by canonical index, every family emphasizes exactly what it declares, and the family catalog validates itself. Proved calibration-only by call graph; caps, OVR, Projected Peak, archetypes, `MatchInput` and saved career state are untouched, the six golden ledgers are byte-identical, and the ruleset did not move. Every judged §8.4/§9.5 contract is byte-identical on a paired pre/post run of seeds 700,001–702,000 and passes on two untouched replacement ranges, **1,350,001–1,352,000** and **1,360,001–1,362,000**; ranges 700,001–702,000 and 900,001–902,000 are retired as validation ranges as anticipated. What remains is downstream: **the §5.23 Option A per-zone offsets must be re-derived against the corrected shooting shape**, and that is blocked behind roster generation, not behind this repair.
7. Implement and run the Builder dominance tournament and the OVR truthfulness report. ~~Body maturation report 15~~ **is implemented** (§5.4) and awaits only its sample.
8. Complete the required game-shape and parity reports at usable samples.
9. Measure release-build and mobile-relevant performance before approving a native-extension ADR.
10. Merge Stage 4 only when its reports and CI evidence support every claim made at merge time.
11. After simulation readiness, resume the remaining Godot Foundation Gate work: SQLite, three slots, minimal application flow, transition harness, and Android/iOS proof.
12. Leave the **full five-level game-stakes calibration deferred** until real schedules and postseason matchups exist (§5.14). The contract, its tests, its mutation battery, and a two-level matched diagnostic are done; what is missing is a population in which a tier means something, and calibrating against fixtures that assign a tier arbitrarily would certify a band for a league that does not exist. The measurement most likely to make the stakes/overtime question answerable at all is a fuller end-of-regulation repertoire, which §5.13 already identifies as the reason the §14.2 overtime band is unreachable.
13. **Re-put the §5.13 overtime question to the owner — and it is now answerable without a §27.1 run (§5.28).** §5.26 reported that 200 games per point cannot settle a 4% rate. 10,000 games per competition on a frozen ruleset, plus 5,000 more on a second disjoint range, settle it: college sits at 0.0310 pooled over 15,000 games (6.4 SE below the 4% floor) and top domestic at 0.0223 (14.6 SE below), with the interval excluding the band on both ranges. **The shortfall is a mechanism gap and it is established**, measured on the corrected repertoire with all four §5.26 shape invariants passing. Building the repertoire did not close it. The choice the owner faces is therefore no longer "fund a run that could answer it or amend the band" — the run has been done at a tenth of §27.1 scale and answered it. What is open is whether to spend the next increment on the zero-concentration mechanism §5.28 localizes and sizes, or to amend §14.2. A §27.1 run funded today would narrow every interval by about 3.2x and move none of the four decisive misses inside its band.
14. ~~**Audit the remaining `EndgameStrategy` decisions the §5.26 correction did not touch.**~~ **Done (§5.27).** Both were read per activation rather than per count, by replaying each game's ledger through a second reducer and re-evaluating the production gates on the reconstructed state (reconstruction verified at 1.000000 tag agreement over 66,623 final-period selections). **Quick-two had a defect**: its window was drawn against the unscaled `endgame_possession_ms` while the tie-seeking window it must stay outside of is that constant scaled by the stakes tier, so the two were complementary at regular-season stakes and the whole of quick-two sat inside the tie-seeking window at both tiers above it, where the two rules disagree by construction and the three wins anyway. Corrected by `simulation-v11-quick-two-stakes-window`; regular season is unchanged to the millisecond. **Two-for-one was validated and left unchanged**: a matched A/B on identical seeds and rosters shows the multiplier shifts direct-shot selection by +3.19pp pooled (95% CI +0.47 to +5.91) but moves neither possession length nor the rate of regaining the ball beyond noise. No defect demonstrated, so nothing changed.

15. ~~**Tag the offensive-rebound putback with the endgame decision in force, and regenerate the golden ledgers deliberately.**~~ **Done (§5.29).** The putback now reads `EndgameStrategy.active_tag`; one known `offensive_rebound` golden hash moves for that field alone while seed, score, event count and played result remain unchanged.
16. **Continue the regulation-tie diagnosis per competition, without injecting ties (§5.28, §5.29, §5.30).** The curve is already peaked at zero — signed density ratio 1.38 for college, 1.12 for top domestic — and the decomposition proved that a material share of late tieable possessions never reaches an attempt. **Two mechanisms have now been repaired against that finding and neither closed the band.** §5.29 corrected the selected-action deadline; §5.30 corrected the opening-state clock and added the location-aware desperation opening. Together they take college's expired-without-attempt possessions from 20 to 9 and top domestic's from 16 to 6 on the frozen 250-game range, and overtime does not move: college sits at 0.0200 before and after on 200 matched games, top domestic at 0.0250 → 0.0150, both noise at that sample. **The attempt-creation explanation for the overtime shortfall is now substantially exhausted** — the possessions that were dying before an attempt largely no longer die, and the band is still missed by the margins §5.28 established at 15,000 games. The remaining zero-concentration gap is therefore unlikely to be found in end-of-regulation attempt creation, and the next diagnosis should look at the margin process itself rather than at the last possession. College still needs a modest zero-concentration increase with its width otherwise inside band; top domestic also remains too wide at the blowout end. Do not solve either by altering make probability or directly moving a final score to zero.
17. **Draw any §27.1 certification across seed ranges rather than extending one (§5.28).** College's overtime rate differs between two large disjoint ranges by 0.6 percentage points at p=0.052 — a roster-population effect, not sampling, since both samples are large. At a 4% band floor that is material, and a certification resting on one range would not be reproducible on another.
18. ~~**Resolve the sub-five-second opening-state clock contract before another overtime calibration run (§5.29).**~~ **Done (§5.30).** The 2026-09-04 owner ruling is implemented as `simulation-v13-opening-clock-and-location-contract`. A throw-in onto a stopped clock consumes no game time and `INBOUND` emits at the possession's starting clock; a possession beginning inside five seconds skips the half-court set it has no time for and commits from its actual `TacticalLocation`, which then costs it a bounded §12.6 distance term rather than giving it arc odds. On the same paired 250-game range, expired-without-attempt falls 16 → 9 for college and 7 → 6 for top domestic, and the 0–5s bucket falls 11 → 6 and 7 → 4. Backcourt and deep attempts are 0.25% and 0.41% of all field-goal attempts, made at 15–25%. Neither shot accuracy nor any tie was touched, and no overtime movement is claimed. **What it opens is item 19**, below: the correction moves §14.1 possessions per game out of band in both competitions.
19. **Re-derive each competition's `pace_multiplier` against the corrected clock contract (§5.30).** `simulation-v13` stopped charging a throw-in that a stopped clock does not charge, which returns roughly three seconds on 17–19% of possessions and moves §14.1 possessions per game from 71.89 to 73.16 for college (band 64–73) and from 101.91 to 103.66 for top domestic (band 96–103). Both are marginal — each interval still straddles its ceiling — and both are the direct arithmetic consequence of the correction rather than a defect in it. The pace environment was calibrated against a clock model that charged time the rules do not, so it now absorbs an error that no longer exists. This is a calibration decision and was deliberately not taken inside §5.30, because retuning pace in the same change would have hidden the mechanism behind the band it moved. Re-derive it per competition on untouched ranges, then re-measure §14.1 as a whole; do not widen the band instead.

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
