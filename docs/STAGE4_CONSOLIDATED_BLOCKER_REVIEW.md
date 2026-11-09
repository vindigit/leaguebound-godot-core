# Stage 4 consolidated blocker review

**Current update (§5.41):** the identified Wilson endpoint serialization and
margin-runner presentation paths are corrected and independently mutation
tested. The historical reports and their printed intervals below remain
unchanged. Pooled FG%/PPP ratio uncertainty, dependence units and all other
listed statistical, coverage and owner blockers remain open; see the
[pooled ratio investigation](STAGE4_POOLED_RATIO_INTERVAL_NOTES.md).

The Builder and OVR reports now have executable instruments, fixed protocols,
independent tests and retained measurements. Stage 4 is **not complete**.
No §27.1 certification or nightly/deep infrastructure proof is claimed.
Match simulation, shooting, overtime, clocks, pace, rating coefficients,
Builder economics, targets and tolerances remain unchanged. The later §5.41
follow-up changes calibration interval reporting.

## Baseline and evidence precedence

Work began on the clean Godot checkout at exact local/remote/PR head
`899a3972e48e8ce63de07b47b2e593e9c97df4d2`; PR #1 was open, draft and
unmerged. Its exact-head Actions run 36052758151 succeeded. The archived local
gate reports 703 passing cases across 57 suites and 271 parsed scripts;
independent review matched the log and source evidence. The source diff from
`74b2c550` to that head is empty for production, targets and goldens.

The current canonical 40-per-competition runner has been replayed on that
exact production head. All 98 metric rows and all sections reproduce the prior
report exactly, including nine failures. This verifies repeatability on the
same seed prefix; it does not supply an untouched sample. The two corrected
468-game candidate home ranges are reused and independently recounted from
all 4,680 per-game rows. Biased adjacent-pairing measurements are historical
diagnoses, never current calibration baselines.

Latest authority is the locked Balance/Simulation contracts and explicit owner
rulings. Older categorical claims that overtime bands are mathematically
unreachable, that roster effects were eliminated, or that shooting is the
unique margin cause are superseded by `PROJECT_STATUS.md` §5.39 and the
[margin owner package](STAGE4_TOP_DOMESTIC_MARGIN_OWNER_DECISION.md).
The stopped FT clock, stopped foul administration, pace re-derivation and
corrected roster pairing are implemented; they are not still-open proposals.

## Failed verdict inventory

[MEASUREMENTS.md](../analysis/stage4_blocker_review/MEASUREMENTS.md) enumerates
every supported failed metric ID and its exact unchanged contract, current
estimate, range evidence, interval and category. The reproducible
[machine registry](../analysis/stage4_blocker_review/blocker_recount.json)
also carries raw numerators/denominators, sample counts, source hashes and a
next action for each individual row. There are **19 distinct failed IDs** in
the declared current evidence inventory: fresh canonical, the two corrected
candidate home arms, and the latest retained controlled venue reports. This
is a union of report failures, not 19 proven gameplay defects.

| Findings / competitions | Exact contract | Classification and reproducibility | Next action |
| --- | --- | --- | --- |
| `sample.meets_certification_size` | §27.1: 100,000 complete games **per competition** | **Insufficient sample or missing coverage.** Fresh report has 40 each, not 200 each. Every range is below certification. | Close population, measurement, mechanism, owner and infrastructure prerequisites; only then separately authorize certification. |
| HS FG% and college FG% | §14.1: HS 0.39–0.47, college 0.42–0.49 | **Statistical target miss without a proven defect.** Fresh 0.3714844 / 0.4026326; both corrected 468-game ranges also fail. Repeated measurement, unresolved cause. | Audit the FGA convention first, then appropriate generated roster shape. Retain the [college owner package](STAGE4_COLLEGE_FIELD_GOAL_OWNER_DECISION.md), whose uniform shooting-offset interpretation was withdrawn. |
| College 3P%; top-domestic 3P attempt rate | §14.1: college 0.31–0.38; top attempt share 0.36–0.49 | **Statistical target miss without a proven defect.** College 3P fails the 40-game prefix; top attempt share fails corrected A at 0.3599275, passes B, and A's interval crosses 0.36. No replicated directional defect. | Recount shot-zone/FGA terms and composition; retain both outcomes. No shooting lift or tolerance change. |
| Overtime, all five competitions | §14.2: 4–8% | **Statistical target miss without a proven defect.** Fresh failures are development/overseas/top; all five point estimates fail both corrected 468-game ranges. Top A/B 7/468 and 10/468; other rare-event intervals are often sparse or overlap the floor. | Diagnose regulation-tie opportunities and survival on balanced disjoint ranges; inspect deadlines/clock paths without manufacturing ties. A calibration-policy or target change requires an owner ruling. |
| Development blowouts; top close and blowouts | §14.2: ≥20-point blowouts 8–18%; ≤5-point close games 22–34% | **Statistical target miss without a proven defect.** Development blowouts A/B 94/468 and 95/468; top close 91/468 and 81/468, blowouts 117/468 and 108/468. Fresh top small-cell close/blowouts pass and do not erase larger misses. | Retain [margin channel evidence](STAGE4_TOP_DOMESTIC_MARGIN_OWNER_DECISION.md); use a specifically controlled mechanism contrast before selecting a correction. No proven repeatable causal margin defect. |
| Raw population home-win, all five competitions | §14.2 raw canonical band 0.53–0.56, with owner's controlled venue estimand as calibration authority | **Infrastructure/reporting problem.** Each competition has at least one raw failed verdict; roster/context population wins are not the locked equal-team venue test. | Retain raw failures and reconcile estimand labels; measure §17.4 with controlled mirror triples and disjoint ranges, not a raw-population home-court retune. |
| Overseas legacy `home.combined_cap_respected` | §17.4: combined +2.5 points/100 cap | **Infrastructure/reporting problem.** The retained 200-triple report has legacy 2.6321643 FAIL and canonical paired 1.9445731 PASS. Neither supersedes the other's published row. | Reconcile legacy/paired definitions and denominator uncertainty. Controlled repeated-range evidence is needed before changing home environment. |

There is **no newly proven implementation defect** in these basketball
verdicts. A repeatable point estimate outside a band is a calibration blocker;
it does not identify a faulty probability, clock or roster rule. Green unit
tests also do not certify a statistical distribution.

There was a separately proven **reporting implementation problem** under §27.2
at the archived baseline; §5.41 corrects the identified endpoints for new
reports and preserves these historical artifacts.
`MetricAggregation.interval_half_width()` computes half the Wilson endpoint
width for proportions, but `CalibrationMetric.to_dictionary()` centers that
width on the raw estimate. For 0/40, the published interval is
[-0.0438108012, 0.0438108012]; the Wilson endpoints are
[0, 0.0876216025]. For 1/40 the corresponding intervals are
[-0.0371934297, 0.0871934297] and [0.0044268315, 0.1288136909].
These are not interchangeable intervals. Historical report values remain
visible, and cannot support claims of correct Wilson coverage. FG% explicitly
overrides this width with its existing team-game ratio interval; it is not
described as binomial here. Shot-level attempt proportions also need explicit
game-dependence treatment. The new Builder/OVR analyses use their declared
cluster methods. This additional reporting blocker is separate from the
19 failed metric IDs, and changes no basketball verdict or behavior.

All five pace and PPP rows pass the current prefix and both corrected larger
ranges. Controlled v17 mirror evidence has all five attributable home-win
point estimates and all five paired caps passing, over 200 triples each.
Its intervals remain broad; the legacy overseas failure and all raw population
failures stay visible. These are reused diagnosis observations, not new venue
holdouts or a home-court certification.

## Builder and OVR acceptance state

The [Builder report](STAGE4_BUILDER_DOMINANCE_REPORT.md) separates equal-AP
starting-build comparisons from the intended unequal profile opportunity
trade-offs. A finite portfolio, limited roles and sparse deployment cells
cannot establish that every legal configuration is non-dominant. Intended
specialist matchup wins, descriptive Pareto-frontier membership, broad local
superiority and a proven every-major-observable §28 violation are separate
claims. Neither lack of significance nor a specialist's loss of efficiency
establishes universal fairness. See its fixed primary comparisons, simultaneous
interval family, raw/normalized counts, legality audit and missing coverage.
Within-cell build comparisons hold the selected players and controls fixed;
cross-cell differences also change the generated cohort. They do not isolate
a causal deployment effect. The body arms expose raw/displayed OVR and legal
attribute/cap changes, but do not prove the universal §7.4 body-OVR guardrail.
Both fixed Builder ranges completed 1,184 games, including 1,152 equal-195-AP
primary games each. Independent review reconciles 81,533 Builder facts with zero
failures, all 374 predeclared contrasts and 306 descriptive pairwise records.
Rebounding DRB differences are +4.17/+4.21 per 100 defensive possessions with
simultaneous intervals [2.11,6.22]/[0.55,7.87]. Perimeter-offense point estimates
of +3.20/+5.12 points per 32 minutes accompany DRB differences −2.86/−2.38.
All eighteen arms remain on each descriptive frontier; none has favorable
simultaneous bounds across all eleven primary observables. This is bounded
trade-off evidence, not a practical-equivalence or universal-fairness pass.

The [OVR report](STAGE4_OVR_TRUTHFULNESS_REPORT.md) audits exact arithmetic,
ordering boundaries, exclusions, record serialization and existing consumers,
then tests empirical basketball relationships separately. Current OVR and
Maximum Potential are not match inputs; higher OVR is not a promise to win
every role/matchup. Synthetic fixtures and a controlled career harness cannot
establish §6.2 mature-world 95+/93+/90+ rarity or active-season selection.
Missing population/lifecycle evidence remains **insufficient coverage**.

Both OVR ranges completed: 576 controlled within-player games, 80 catalog
games and 16 generated-college games, plus 2,000 distinct career-histogram
draws and 80 separate college-source career simulations.
The 5,850 shared finite fixture vectors are counted once, not once per range.
All-20 legal attribute improvements produce mean displayed OVR gains of ten.
Points/32 increase +6.16/+5.85, with fourteen-comparison familywise intervals
[4.24,8.06]/[3.99,7.65]; FG increases +9.41/+7.53 percentage points,
[4.09,14.84]/[2.54,12.07]. Team margin, rebounding and steals/blocks also
have favorable simultaneous intervals in both ranges. Assists/turnovers remain
inconclusive in that family. Raw disadvantages are retained: mean minutes fall
19.22→18.00 and 19.69→18.42; personal fouls rise 206→322 and 240→333.
These are funded development interventions, not equal-resource freshman
comparisons. Catalog pooled OVR/scoring correlations .447/.380 weaken to
.294/.067 after joint competition/position/tactical/rotation adjustment;
FG becomes .284/−.014. Aggregate usefulness does not guarantee within-stratum
ordering. Same-OVR specialists and selected scoring/rebounding inversions
preserve their raw opportunities and concrete attribute/body/deployment
differences. Independent review reconciles all fourteen primary bootstrap
intervals, relationship strata and histograms in 70,807 OVR checks, zero failures.
No empirical formula inadequacy or rating-consumption defect is established.

The existing perimeter help/closeout gap is also retained as **insufficient
mechanism coverage**, with owner sequencing needed for a subsequent gameplay
task. `ShotResolver.build_contest()` applies its helper pressure only to
interior attempts; `SIMULATION_SPEC.md` §12.3 records the missing perimeter
closeout/rotation term, and §§16.1/30.2 leave tactical movement/location
coverage open. This is not an identified cause of a margin or shooting miss.
The source comment claiming perimeter HEAVY contests are categorically
unreachable is too strong: the current capability/reach bound can reach 0.73,
above the 0.60 HEAVY threshold. No historical contest frequency is treated as a
current locked verdict, and no contest parameter or mechanism changes here.

The exact-cap audit demonstrates an **explicit owner decision**: §8.3 permits
a cap below current with no implicit current-rating loss, while §6.3 requires
current≤potential and defines potential by the same formula on exact caps.
The existing projection consumer asserts that ordering. No formula change,
cap inflation or silent attribute loss is authorized to resolve the conflict.
The OVR package preserves examples, alternatives, consequences and uncertainty.

The locked coefficient structure and existing 0.65/0.25/0.10 profile remain in
force. No numeric practical dominance tolerance or OVR-to-performance pass
threshold has been invented. Between-build practical meaning is reported in
native units; any additional acceptance interpretation needs design authority.

## Dependency-ordered work queue

| Order | Work | May proceed safely / approval dependency | Must close before §27.1 acceptance? |
| --- | --- | --- | --- |
| 0 | Reconstruct pooled ratio uncertainty and establish dependence units | Wilson endpoint serialization is corrected (§5.41). Pool ratio moments only with explicit numeric/missingness handling; determine game/quartet dependence and preserve historical artifacts. | Yes for §27.2 uncertainty evidence. |
| 0a | Enforce shard engine/source identity and verify immutable inputs | §5.41 demonstrates the actual aggregator accepts separately altered Godot-version and dirty-note metadata; HEAD alone does not identify modified executable bytes. Add deterministic rejection tests and a verifiable clean/immutable-source mechanism without assuming an empty note proves cleanliness. | Yes before trusting pooled certification evidence. |
| 1 | Ledger FGA/3PA convention and denominator audit, known-answer fixtures, exact paired replay | Owner directed real-world, competition-specific conventions; the [owner package](STAGE4_FGA_CONVENTION_OWNER_DECISION.md) records source coverage, timing uncertainties and event-stream consequences. Implement with concrete regressions and retain uncertain cases explicitly. | Yes for shooting-band validity; it also affects usage/eFG instruments. |
| 2 | Resolve exact-cap/current≤potential conflict | **Owner ruling required.** Report examples are concrete; resolving by redefining potential, restricting exceptional caps, or separately applying visible rating loss changes a locked contract. Independent reporting and other diagnoses can continue. | Yes for §6.3/B1 acceptance and lifecycle truthfulness. |
| 3 | Reconcile population home-win labels and legacy/paired cap definitions; collect controlled disjoint mirror venue ranges | Safe reporting/diagnosis. Preserve the owner's symmetrized estimator; tuning home environment needs separate authority and replicated controlled evidence. | Yes for §14.2/§17.4 verdict consistency. |
| 4 | Competition-appropriate generated roster-shape evidence, especially college shooting | Safe bounded generation/analysis from existing legal player/development paths; a production roster/world system remains outside current scope. An offset, economics or target amendment needs owner approval. | Yes for representative population interpretation, or explicitly unresolved as a certification blocker. |
| 5 | Controlled margin and overtime mechanism diagnostics | Safe observation with matched, balanced, disjoint ranges. Sample shortage is not a defect. Desperation window remains a separate owner calibration choice; approved FT/roster corrections are already closed. | Yes: repeated close/blowout/OT misses remain open. |
| 5a | Perimeter help/closeout, defensive rotation and tactical-location coverage | Retain the acknowledged Simulation Spec gap. A new mechanism needs a separately scoped implementation task and owner sequencing; it cannot be smuggled into report tooling or justified as a proven margin correction. | Yes for the relevant simulation-readiness coverage, without inventing a contest-frequency target. |
| 6 | Broader Builder positions, same-player deployment crossovers, all tactical-role/lineup combinations, §7.4 body-OVR coverage and tendency search followed by untouched confirmation | Reuse legal tooling; freeze candidate search separately from confirmation. No hidden build restriction, new composite or desired-verdict loop. | Yes for broader §§7.4/12.4/28 guardrail coverage; finite portfolio cannot exhaust legal space. |
| 7 | OVR active-player phase/age populations and within-strata relationship coverage; cap/current lifecycle consequences | Safe harness evidence where legitimate populations exist. Mature-world seasonal rarity is unavailable until an appropriate lifecycle/selection population exists; do not claim it from fixtures. | Yes for §6.2/§31 report 1 population acceptance. |
| 8 | Required match-level single-attribute, role/rotation/leader, fatigue/workload and Play/Sim/Skip / Tier A-B parity coverage | Existing isolated sensitivity and deterministic parity tests are green foundations, not full report/sample substitutes. No new career or product feature scope is implied. | Yes for the applicable §§27/31 and Simulation Readiness contracts. |
| 9 | Postseason/stakes coverage, badge/injury and other Stage 4 reports currently lacking appropriate populations | Record exact missing population/coverage and owner sequencing. Do not invent schedules or unimplemented career domains to produce a nominal pass. | Yes where the release profile claims those contracts; absent evidence remains blocked. |
| 10 | Nightly/deep provenance, sharding/overlap/aggregation and release/mobile performance proof | **Subsequent work**, separately authorized. Existing combiner code and tests are not an executed end-to-end infrastructure proof. | Yes before trusting a certification artifact; do not run here. |
| 11 | Full §27.1 samples and all locked verdicts with unchanged tolerances | **Subsequent separately authorized work** after the above prerequisites. A sample-size pass alone cannot certify failed gameplay contracts. | This is the certification step; not executed or claimed. |

Recommended next engineering task: a bounded measurement-validity follow-up
covering pooled ratio uncertainty and the FGA/3PA denominator audit,
with known-answer and ledger replay evidence, while the owner resolves the
exact-cap ordering conflict. It can improve measurement validity without
tuning basketball.

## Reproduction and verification

[Execution record](../analysis/stage4_blocker_review/EXECUTION.md),
[measurements](../analysis/stage4_blocker_review/MEASUREMENTS.md),
[Builder/OVR independent review](STAGE4_BUILDER_OVR_INDEPENDENT_REVIEW.md)
and their respective source/manifests provide commands, versions, seeds,
counts, tests, mutation outcomes and limitations. At the historical §5.40
runtime source `05163e3`, the eight-step gate passed 727/727 cases, 59 suites,
279 parsed scripts and unchanged goldens; 54 separate analysis cases and 41
semantic mutations were recorded. The current §5.41 correction has its own
[execution record](../analysis/pooled_ratio_followup/EXECUTION.md): a fresh
complete gate passes 735/735 cases, 60 suites, 280 parsed scripts and the same
goldens. Its eight distinct source mutations yield nine intended detections;
interrupted preliminary gates are not counted. GdUnit has zero
errors/failures/skips/orphans; the historical Builder-smoke cleanup diagnostics
remain disclosed. Exact final-head GitHub checks and the open/draft/unmerged PR
state are inspected after ordinary fast-forward publication, with results
recorded in PR #1. All claims remain measured, not certified.
