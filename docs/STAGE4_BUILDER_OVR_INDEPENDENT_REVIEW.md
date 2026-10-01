# Stage 4 Builder and OVR independent review

This review is independent of the report implementers. It records what was
inspected, requested corrections, and the boundaries of the evidence. It does
not authorize tuning or certify `BALANCE_SPEC.md` §27.1. Review status is
**accepted as a bounded reporting handoff, with explicit unresolved coverage
and owner blockers**. Actual code, tests, mutations and retained outputs are
reconciled below.

## Verified starting evidence

The critic observed local HEAD
`899a3972e48e8ce63de07b47b2e593e9c97df4d2` and an initially clean worktree.
No repository or ancestor `AGENTS.md` was found by the ancestor walk; the
user-supplied LeagueBound project instructions remain applicable. The synced
project mirror is reference-only and was not modified.

The prior margin follow-up's `analysis/margin_growth_followup/full_gate.log`
contains `Parse check: 271 script(s) checked, 0 failure(s)` and the final
`703 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`,
with 703/703 executed and exit 0. Its execution record identifies the complete
eight-step gate. This establishes the reported historical source-state
baseline, not a new run. An independent
`git diff --stat 74b2c55028bbb1a4cc43440ffec52f015c9ba7b2 899a3972e48e8ce63de07b47b2e593e9c97df4d2 -- src calibration/targets tests/golden`
had no output. Final-head verification remains the root agent's separately
recorded gate and actual GitHub checks.

The critic read `BALANCE_SPEC.md` §§6–8, §27, §28 and §31, the Simulation
Spec's player snapshot, body, opportunity and acceptance contracts, canonical
Builder/cost/OVR code, existing OVR exclusion tests, and the current roster
pairing and margin owner packages. The corrected catalog pairs existing
117-state rosters in full venue/opener quartets; a partial slice is not the
complete Cartesian population.

The top-domestic margin package's two larger corrected candidate ranges have
91/468 and 81/468 close games. Its newer 40-game diagnostic ranges do not
reproduce a unique late widening or scalar-roster cause. These are repeated
target misses with an unresolved mechanism; no deterministic margin defect
has been demonstrated. Historical biased adjacent-pair measurements are not
used as the current statistical baseline.

A separate read-only Node/crypto audit matched all 291 captured source hashes
and all 13 artifact hashes in the margin package's provenance/manifest against
the current files at `899a397`. A separate raw aggregate calculation recovered
92 numerical estimates in its canonical 40-game-per-competition report and
reconciled 98 metrics, 74 judged rows and nine failed verdicts. This verifies
the archive's integrity and arithmetic; the games were not rerun by the critic.

## Protocol criticism before retained measurements

The Builder implementer proposed a fixed 18-build Balanced 195-AP wing
portfolio, eight role/lineup/opponent cells, full venue/opener quartets, and
two untouched validation ranges. The OVR implementer proposed legal
within-player development interventions, matched games in full quartets,
source-player clusters, a rational formula oracle, and separate current/cap
population summaries. These were reviewed before confirmatory results.

Required interpretation and implementation corrections were sent directly to
the two implementers:

- Multiplicity must include both validation ranges and any primary stratum
  claims. Pointwise strata and all-pair Pareto tables must be labeled
  descriptive. Tiny cell counts cannot support universal dominance or
  equivalence claims.
- Every legal build must be independently checked against literal destination
  AP bands, original body-adjusted bases, credible body bounds, exact caps,
  the 75 starting ceiling, exhausted creation currency and the confirmed
  state. A call to the constructor alone is not an independent legality
  oracle.
- Equal starting AP comparisons remain separate from profiles with 155, 195
  and 235 AP and distinct future opportunity. Freshman outcomes cannot prove
  lifetime profile fairness. Legal body interventions also change bases and
  cap compatibility; that bundle cannot be called a dimension-only effect.
- Raw minutes, touches, attempts and on-court possession exposure accompany
  normalized outcomes. Steals/blocks alone do not exhaust defensive quality;
  primary-defender shot outcomes or an explicit missing-coverage statement is
  required. Missed shooting-foul attempts currently enter canonical FGA, so
  FG/eFG conventions remain material limitations.
- A finite wing/role/tendency portfolio is not an exhaustive §28 proof. A
  specialist's intended matchup success, broader observed advantage and a
  demonstrated every-major-observable violation are distinct claims.
- Source-player clusters preserve the dependence among all game orientations
  and intervention arms. Matching initial seeds does not guarantee identical
  later draws when game trajectories diverge. Sparse bootstrap intervals
  cannot be presented as guaranteed coverage.
- Synthetic catalog distributions and controlled career harnesses cannot
  establish mature active-world rarity. Serialization evidence must name the
  actual record/JSON boundary tested; the full SQLite save adapter is absent.
- Exact-cap Maximum Potential and the current≤potential invariant conflict
  when a legal cap reduction leaves current ratings above caps (§8.3).
  Any demonstrated example must be documented for owner resolution without
  replacing the locked formula or lowering current ratings.

## Final actual-code and output review

### Consolidated blocker recount tooling

The critic inspected `tools/stage4_blocker_audit.cjs`, its actual Node tests,
the isolated actual-source mutation driver and all seven recorded outcomes.
`node --test tests/tooling/test_stage4_blocker_audit.cjs` independently passed
11/11 tests, zero failures/skips. The driver requires a named intended failing
test and `ERR_ASSERTION`, rejects invalid execution, runs clean before/after,
and restores the original instrument bytes; a crash is not a kill. The enhanced
suite independently passed 12/12 after adding controlled venue recount. Its
`mutations_v2/results.json` records nine actual-source assertion kills and
clean before/after suites. Duplicate mutants were tightened to admit the
malformed artifact, so their intended failures are `Missing expected exception`
rather than changes in exception text. The final `mutations_v3/results.json`
adds a read-only Wilson endpoint reproducer witness: 13/13 Node cases were
independently rerun green, and ten meaningful actual-source mutants are killed.
The Wilson-center mutation fails the known-answer endpoint assertion with
`ERR_ASSERTION`, 13 executed cases and zero runtime errors. Earlier 7/11 and
9/12 records are versioned evidence, not counts to add to the final ten.

The archived corrected validation summaries independently yield 18 distinct
failed metric IDs when combined with the nine canonical small-run failures.
The one-range top-domestic three-point attempt rate failure is retained:
0.3599275 against 0.36–0.49, with a quartet interval crossing 0.36. It is not a
replicated gameplay defect. Raw population home-win failures occur for all
five competitions on at least one corrected range; the owner's §17.4
controlled symmetrized venue estimand remains separate. Independent arithmetic
over all 1,000 retained v17 mirror triples recovered all five controlled win
estimates and points/100 estimates to within 1e-12. The overseas legacy
`home.combined_cap_respected` failure adds the nineteenth distinct failed ID:
legacy 2.6321643 versus paired 1.9445731 points/100. The paired cap passes; the
legacy fail stays visible as a reporting-definition problem.

The fresh 40-per-competition report at `899a397` independently matches all 98
prior metric rows exactly, including nine failed verdicts. That source prefix
was reused, so the rerun confirms reproducibility rather than providing new
validation coverage.

### Interval reporting defect

Actual code inspection confirmed a reporting implementation problem:
[`MetricAggregation.interval_half_width()`](../calibration/harness/metric_aggregation.gd#L235)
returns half the Wilson endpoint width, while
[`CalibrationMetric.to_dictionary()`](../calibration/harness/calibration_metric.gd#L159)
centers that width on the raw
proportion. Using the source's `Z_95 = 1.959964`, an independent calculation for
0/40 gives Wilson `[0, 0.08762160245846368]`, while the fresh overtime rows
publish `[-0.0438108012292318, 0.0438108012292318]`. For 1/40, Wilson is
`[0.004426831453704344, 0.12881369088183614]`, while the published endpoints
are `[-0.0371934297140659, 0.0871934297140659]`.

The archive remains intact and the locked point-estimate verdicts are unchanged.
These endpoints must not be called Wilson bounds or used as reliable rare-event
coverage. A bounded endpoint-preservation correction with regression evidence
belongs before later §27.2 acceptance. Canonical FG% overrides its aggregation
width with a team-game ratio interval after aggregation; it is not a binomial
FG interval. The new Builder and OVR cluster methods are separately reviewed.

### Perimeter mechanism coverage

The critic inspected the current
[`ShotResolver.build_contest`](../src/domain/basketball/simulation/shot_resolver.gd#L78):
helper selection/help pressure occurs only inside `if interior` (lines 100–115).
The current Simulation Spec §12.3 explicitly records that a perimeter
closeout/rotation term is absent; tactical movement/arrival/location coverage
remains limited under §16.1 and §30.2. This is missing mechanism/coverage with
owner sequencing for further gameplay work, not a demonstrated margin cause or
a failed locked contest-frequency band. Implementing a new perimeter term is
outside this report correction.

The categorical historical claim that perimeter `HEAVY` is unreachable is too
strong for the current code. Capability is bounded at 1, reach at +0.12, and
advantage relief is nonnegative, so the current perimeter pressure bound is
`0.38 + 0.5*0.46 + 0.12 = 0.73`: it does not exclude `HEAVY` at 0.60.
It does exclude `SMOTHERED` at 0.82 on this unchanged profile. Actual ordinary
fixture frequencies are a separate empirical question, not established by that
upper bound.

### Builder and OVR precollection readiness

The critic inspected the actual Builder fixtures, audit, runner, analyzer and
tests. Literal destination costs, body bounds/redistribution, exact initial
caps, confirmation and exhausted budgets are checked. Immutable bases/caps are
replayed from the seeded constructor, which is a consistency check and not an
independent proof of the cap generator's algorithm. Invalid body facts return
before constructor assertions. Complete venue/opener quartets and identical
teammate/opponent signatures are required. The runner fingerprints report and
production source before collection and refuses changes by collection end.

The actual GdUnit log has 10/10 passing Builder tests, including real-game
instrument determinism. The critic independently ran
`C:\Users\valexander\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe analysis/builder_dominance_followup/test_analysis.py`:
10/10 passed. The matched ratio influence standard error, opportunity-weighted
ratios, full sample schedule and 374-comparison family have known-answer
witnesses. Additional independent Cauchy/df-2 closed-form calculations matched
the Student-t quantiles at the actual Bonferroni tail within 3e-9. Pooled n=16
quartets across eight fixed contexts, each with only n=2, remains approximate
conditional schedule evidence, not strong population coverage.

All 176 retained exploratory raw games, covering 22 builds and eight matched
game seeds, independently passed literal AP/body/cap/starting-limit checks,
current/potential rational oracles, ledger identities, opportunity bounds,
full quartets and controlled teammate/opponent signatures. Their raw SHA-256 is
`cb6f1db8c28cb4c12b96f2037d88976dd2c71f1c9344105d21512665215c7cf4`.
Of 147 metadata source hashes, 146 match current files exactly. The remaining
Python-test change was independently compared to the restored isolated copy:
only trailing whitespace changed, as the retained cleanup record discloses.
It has no basketball or test-token effect and preceded confirmation.

The eight cells also change fixture variation by `1000 * cell`. Actual catalog
roster identities and construction seeds therefore differ across cells. Each
within-cell build contrast holds its cohort, teammates, opponents and deployment
fixed, but differences across cells combine deployment/matchup changes with
different generated player and roster realizations. The pooled schedule and
descriptive interactions cannot be called a causal same-player role crossover.
That additional deployment coverage remains missing; the frozen confirmation
schedule was not changed after collection began.

The final Builder mutation record has 14 meaningful kills (eight GdUnit,
six Python), with clean 10/10 suites before and after. The initial redundant
Python duplicate-guard mutant was replaced: all matched arms' phase-2 venues
are corrupted consistently, and removing the venue guard yields actual
`ValueError not raised`, rather than a message-only mismatch. Actual GdUnit
mutant logs show intended named assertion failures and zero runtime errors.
The initial partial exploratory failure at the first secondary arm is rejected
and disclosed; the typed primary/secondary cell helper has focused coverage.
No candidate, protocol, sample or gameplay value was selected from these
exploratory outcomes. This establishes bounded Builder collection readiness,
not acceptance of as-yet-unreconciled confirmation outcomes.

Actual OVR code and 14 focused tests were inspected; its retained before log
has 14/14 passes. The rational oracle, ordering crossings, tie/half boundaries,
state exclusions, identical query ingress, record/JSON serialization boundary,
display labels and cache updates agree with the locked formula. The critic
requested that the cap-reduction owner example use permitted drops of at most
eight, and that an arithmetic uniform-vector example not be described as a
proven generated lifecycle state. That example was corrected to two 80→72 cap
drops. The retained separate consumer probe prints current 80/potential 79,
then the actual `DevelopmentProjection._init` assertion at line 41 and a
partially initialized returned object's 0/0 fields. This demonstrates the
owner conflict in a domain fixture; it is not a mutation kill or proof that the
current career generator reaches that vector. No rating formula or cap contract
was changed.

Formula monotonicity also follows independently of the finite tests: raising
one coordinate cannot lower any sorted order statistic. The top-eight and
bottom-six sums are therefore nondecreasing, while the all-attribute mean
strictly increases. Positive locked weights make raw OVR strictly increase;
clamping and rounding can create plateaus but cannot reverse that direction.
Permutation invariance follows because only the attribute multiset is read.

A read-only Node binary64 audit reproduced the actual arithmetic order for
all 164,304 exact-half aggregate triples within legal attribute sum bounds:
total 500–1,980, top-eight sum 200–792, bottom-six sum 150–594, and rational
numerator congruent to 1,200 modulo 2,400. This overinclusive set contains all
legal half-boundary vectors; none evaluated below its exact half. Separately,
one million seeded formula-only legal-domain vectors included 418 exact halves
with zero below-half drift. These are numeric support under the checked default
profile, not basketball fixtures or a claim about every platform.

The exhaustive aggregate check is reproducible with Node's standard library:

```javascript
let cases = 0, below = 0;
for (let sum20 = 500; sum20 <= 1980; sum20 += 5) {
  for (let top8 = 200; top8 <= 792; top8++) {
    if ((78 * sum20 + 75 * top8) % 40 !== 0) continue;
    for (let bottom6 = 150; bottom6 <= 594; bottom6++) {
      const numerator = 78 * sum20 + 75 * top8 + 40 * bottom6;
      if (numerator % 2400 !== 1200) continue;
      cases++;
      const raw = 0.65 * (sum20 / 20) + 0.25 * (top8 / 8)
        + 0.10 * (bottom6 / 6);
      if (raw < numerator / 2400) below++;
    }
  }
}
console.log({cases, below}); // {cases: 164304, below: 0}
```

The separate one-million-vector numeric support check uses this exact Node
recipe. It samples the integer active domain rather than complete legal Builder
states, and supports no cross-platform or exhaustive floating-point claim.

```javascript
let state = 78361, halves = 0, below = 0;
function draw() {
  state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
  return state;
}
for (let n = 0; n < 1000000; n++) {
  const values = Array.from({length: 20}, () => 25 + draw() % 75)
    .sort((a, b) => a - b);
  const total = values.reduce((a, b) => a + b, 0);
  const top = values.slice(12).reduce((a, b) => a + b, 0);
  const bottom = values.slice(0, 6).reduce((a, b) => a + b, 0);
  const numerator = 78 * total + 75 * top + 40 * bottom;
  if (numerator % 2400 !== 1200) continue;
  halves++;
  const raw = .65 * (total / 20) + .25 * (top / 8) + .10 * (bottom / 6);
  if (raw < numerator / 2400) below++;
}
console.log({halves, below}); // {halves: 418, below: 0}
```

The critic independently reran the initial OVR Node analysis suite: 11/11
passed. Actual source inspection nevertheless found missing archive-level
coverage checks (coherently shifted confirmation ranges, absent held-fixed
hashes, incomplete catalog/college games, and duplicate/missing finite
histogram populations). Those checks and their regression/mutation witnesses
were required before confirmatory collection. The expanded actual analyzer
independently passed 29/29 named Node cases. It validates exact A/B source and
gameplay ranges, all slots and held-fixed hashes, twenty distinct players per
catalog/college game, corrected quartet identities, chronological college
provenance, both complete histogram ranges and five finite populations. Its
shared Builder reader now actually consumes both raw files and checks the
18-build equal-195-AP primary portfolio before describing comparable ratings.

One final Node mutation was rejected by criticism: corrupting only the second
histogram made deletion of the oracle guard fail merely because another
archive-equality guard still rejected the artifact. The recorded regex mismatch
is not a meaningful kill. Both payloads must be corrupted identically, with the
removed oracle admitting the artifact and the test failing with `Missing
expected exception`; the driver must reject regex-message-only failures.
The corrected final replay has ten semantic analyzer kills with clean 29/29
suites before and after each, exact analyzer/test/driver hashes and a global
rejection of regex-message-only failures. The five GdUnit source mutations
were independently inspected: named intended assertions, zero runtime errors
and clean 14/14 suites before and after each.

A subsequent actual-source check corrected an evidence-availability claim:
`CareerSimulator` already retains `peak_values` under diagnostics and the final
state's canonical attributes. Its OVR histogram caller enables diagnostics, so
peak/final current vectors can be archived and independently checked now.
Only arbitrary all-season attribute vectors are absent. The critic requested
two measurement fields and oracle/corruption checks before OVR collection;
this changes no generated population, seed range, estimator or production
behavior. The resulting final analyzer independently passed 30/30 cases. All
three analyzer/test/driver fingerprints and all 23 mutation log fingerprints
reconcile. Eleven meaningful analyzer mutations are killed, with clean 30/30
suites before and after each. The new peak-vector guard mutation admits its
corrupt record and fails `Missing expected exception`. Earlier 10/29 proof is
superseded, not added to this final count. This establishes bounded OVR
confirmation readiness; final acceptance still awaits actual A/B records.

The critic independently reconciled both completed Builder confirmation
archives at execution head `07789d28f277a474ebec7df83d52c0564d0dbba0`.
The standalone audit imports neither report analyzer. Its literal AP costs,
body redistribution and domains, starting bounds, immutable caps, rational
current/potential OVR, scoring/ledger identities, opportunities, unique fixture
identities, disjoint gameplay ranges and venue/opener controls all agree with
the retained 2,368 rows. Exactly 2,304 rows are the equal-195-AP primary
experiment; the 64 profile/family rows remain separate. There are 592 distinct
arm/source draws, 64 shared seeds per range and 32 chosen roster pairs across
the two ranges. Every archived production/instrument fingerprint agrees with
the actual frozen source.

All pooled and cell raw counters, all 22 normalized/descriptive observables,
374 primary contrast estimates/denominators/directions/standard errors and
ordinary/simultaneous interval endpoints, and 306 pairwise Pareto comparisons
independently reconcile. Student-t15 quantiles were independently obtained
from the analytic integral of `cos^14`, without the analyzer's incomplete-beta
continued fraction. The final archived replay has 81,533 checks and zero
failures; the earlier 80,037-check replay is superseded, not added. All 18 primary
builds remain on the descriptive frontier in both ranges; none demonstrates
simultaneous superiority in all eleven observables against the balanced
reference. Cell-level n=2 and limited legal-space sampling preclude a universal
guardrail pass. Across-cell deployment effects remain confounded with source,
caps and roster realizations. The three selected body arms all display 48,
with independently calculated raw OVR 47.6283333, 47.6825 and 47.5929167;
this selected cohort does not certify the separate body/OVR guardrail.

Builder raw SHA-256 values are
`9de2c0ff7fd1e317b40a565ab6aaf7e66dba8ec9271678ee3261f7d6d8793f10` (A)
and `3f9cfb9cb1f0ca5ffda71e663e37b08d1bf71641acfa216c80661cea62e97f4a` (B).
The reusable read-only source is
[`independent_archive_audit.cjs`](../analysis/stage4_blocker_review/independent_archive_audit.cjs).
Its source SHA-256 is
`2c8bf2c97b652b97905b7b2491441eb2f2773245531ba9ddebf678ca25afb635`.
It invokes an embedded independent Python standard-library calculator using
an explicit interpreter path; it needs no report-module import or third-party
package. Its final result JSON records exact command/source and raw hashes.

```powershell
node analysis/stage4_blocker_review/independent_archive_audit.cjs $Python analysis/stage4_blocker_review/independent_archive_audit_results.json --with-ovr
```

The optional OVR mode independently reconciles all 2,496 archived player-game
rows: 576 controlled focus-player games, 1,600 catalog player-game records and
320 natural-college player-game records. It verifies 288 disjoint unique
gameplay seeds, literal intervention costs/cap-preserving vectors, held-fixed
teammate/opponent facts, current/raw/exact-cap arithmetic, all pooled/family
rates and every reported overall/stratum/demeaned correlation. The fourteen
primary Bonferroni bootstrap effect/interval pairs reproduce using a separate
Python implementation of pooled vectors, source-player resampling and the
declared LCG. Histograms independently reconcile for 2,000 unique natural
career seeds and 5,850 shared fixture records counted once. There are 70,807
OVR checks, giving 152,340 combined checks with the 81,533 Builder checks;
these are arithmetic assertions, not extra test cases or independent samples.

The catalog correlation unit is a logical roster-state/player observation.
The self-paired first quartet merges two identical roster copies into eight
exposures per observation; the second quartet has four exposures per
observation. There are 150 such catalog observations per range, not 200.
College has 40 four-game observations per range. The critic explicitly checked
those denominators and the different opportunity strata they produce.

All20 improvements increase displayed current OVR from 47 to 57 and have
favorable simultaneous bounds for five of seven primary outcomes in both
ranges. Assists/turnovers remain inconclusive. Foul counts rise from 206/240
to 322/333, while average minutes fall from 19.22/19.69 to 18.00/18.42.
The report exposes these availability costs and does not infer that every
attribute improvement wins every observable. Catalog aggregate FG correlations
0.352/0.273 become 0.284/−0.014 after joint adjustment, precluding a universal
within-role prediction claim. Sparse strata and the two natural-college source
populations per range remain explicit limits. The 319 exact-cap potentials at
95+ and six at 99 describe ceilings in the natural harness, while peak current
never exceeds 94 here; neither statistic certifies active-world rarity.

A post-collection presentation correction removes unarchived shared-Builder
on-court opponent counts previously defaulted to zero. The critic read the
actual retained before aggregate (SHA-256
`89f1710a3fa7f115f3743f604770b8219921b983789e521c805778cfae725ed3`)
and after aggregate (`e33c45a0559e6c7c0e3df1b17e70ca7b7282b792370f1461fd21822c09797b68`).
All within-player, population relationship, histogram, input and protocol
sections are deeply identical; shared pair counts/context correlations are
also identical. The final Node suite independently passes 31/31. All three
current source and 25 log fingerprints reconcile; twelve intended semantic
assertion kills have clean 31-case suites before/after, with no crashes or
message-only kills. The earlier 30/11 proof is superseded, not added. Combined
current proof is 14 Builder, 17 OVR (five GdUnit/twelve Node), and ten blocker
mutations. The critic also required correction of three actual attribute-index
transcription mistakes: vision versus offensive IQ, large-body OREB 46 versus
block 47, and college rebound values 79/79 versus 69/77. Corrected selected-case
evidence retains canonical names/vectors and the higher college vector's
componentwise improvements, without claiming a unique explanation for its
four-game rebound reversal.

The bounded Builder, OVR and blocker reporting handoff is accepted. Formula
ingress/implementation truthfulness, archive arithmetic and the stated finite
measurements are supported. Universal build/body/tendency fairness, lifecycle
profile value, mature-world rarity, missing save/population/deployment coverage
and the owner cap-ordering conflict remain unresolved. Statistical target
misses and the proven Wilson endpoint reporting problem remain in the
consolidated queue. This acceptance does not close Stage 4 or §27.1.

Initial stale parse failures are not counted as a clean parse gate. The final
complete eight-step gate at source `05163e375ccce5d33030a48496424be3581163ef`
passes with 279 parsed scripts, 727/727 GdUnit cases and 59/59 suites. The critic
inspected the actual log and XML, independently counted all test/suite nodes,
confirmed zero failure/error/skip nodes, and verified the retained XML is an
exact byte copy of `reports/report_136/results.xml` (SHA-256
`a2bb52efb53851350597b997a219477000e24e28746678b38ff64019397385f0`).
All six committed golden hashes reproduce without regeneration. Production,
targets and goldens remain unchanged. Historical ObjectDB/resource cleanup
and debugger-port stderr occur in both baseline and new logs; zero errors is
the GdUnit outcome, not absence of all process diagnostics. Later CJS/report
presentation changes do not change those frozen Godot sources. Exact final-head
GitHub publication/check evidence is recorded by the root handoff.
The first full-gate attempt at `79e7a26` passed its seven earlier steps but was
deliberately stopped by the root during GdUnit after the OVR measurement runner
changed following parsing. Its exit 127 and preserved partial log are disclosed
in `gate_interruption_v1.json`; no completed gate or test defect is inferred.
The full eight-step sequence was restarted after the final source freeze and
completed as recorded above.
