# Stage 4: calibration roster pairing

This follow-up starts at `11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4`.
The remote branch, clean worktree and PR #1's open/draft/unmerged state were
verified before changes. Its exact-head CI run was successful with 684 tests.
Production match-engine code, ratings formulas, rule profiles, clock behavior,
probability parameters, targets, tolerances and overtime logic are unchanged.

## Construction defect and correction

Previously, `match_for(v)` selected roster variations `2v` and `2v+1`.
`team_for(t)` selects ladder index `37t mod 13`, so home has index `9v mod 13`
and away has `(9v+11) mod 13`. With 0.35 rating points per ladder step, the
home-minus-away **ladder tilt** is +0.70 in eleven of thirteen variations and
-3.85 in two. Its mean is zero; its asymmetric distribution systematically
assigns the more common small advantage to home. These are ladder tilts, not
claims that every actual rounded player or team Overall differs by exactly
those amounts. Player noise has period nine, giving the full roster generator
a 117-variation period, before crossing opening-possession parity.

Catalog v4 changes which existing rosters meet. It preserves `team_for`, its
13-step ladder, 2.1-point half-width, player noise, rounding, bodies, tactical
and rotation roles, and explicit rating offsets. For quartet index `k=v/4`,
select `A=k mod 117` and `B=(2A+floor(k/117)) mod 117`. The four fixtures use
AB, BA, BA, AB, while the existing opener remains home, away, home, away.
Each actual roster has equal assignment weight in every venue/opener
combination; diagonal quartets pair the roster with itself.
This equality survives rounding and any deterministic, context-free projection
of the roster alone.

Every aligned 468-game slice has uniform home and away roster marginals.
Across 54,756 fixtures, every ordered pair of the 117 existing roster states
is covered. A 468-game slice includes 117 base pairs spanning 13 of 169 ladder
pair cells before reversal, and 231 roster/25 ladder cells after including
both orientations. It is a balanced deterministic schedule slice, not an independent
sample from the entire Cartesian population. Partial quartets need not balance;
explicit opener policies and venue-attached offsets remain deliberate
interventions. Mirror diagnostics retain their original construction.

Three runners which duplicated the population selection now use the same
helper: contest sweep, FG counterfactual (including its roster summary), and
the generated-population branch of home-court diagnostics. Direct single-team
and intentional mirror fixtures remain unchanged. Catalog version is descriptive,
so source hashes and isolated baseline output paths establish provenance.

The construction audit enumerates all 117 actual rounded rosters per
competition and applies the existing `TeamStrengthIndex.expected_gap` projection.
Every competition's old 234-fixture cycle has 198 positive gaps, 36 negative
gaps and no zero gaps. Every corrected complete cycle has 27,144 positive,
27,144 negative and 468 zero gaps. Both means are zero. Thus a mean-only audit
would miss the original asymmetry. The projection is a diagnostic capability
index, not Current Overall and not a forced or predicted final score. The gap
is `(home offense - away defense) - (away offense - home defense)`, measured
in centi-capability points (one point is 0.01 of normalized capability).

| Competition | Old gap RMS | Corrected complete-cycle gap RMS |
| --- | ---: | ---: |
| High school | 4.41076 | 4.97292 |
| College | 4.42776 | 5.05258 |
| Developmental | 4.40583 | 4.96880 |
| Overseas | 4.40583 | 4.96880 |
| Top domestic | 4.38866 | 4.96255 |

This is an exact construction change in dispersion. It does not establish
whether a game-outcome metric improves, worsens or stays equivalent. The audit
JSON retains the individual rating vectors and complete gap histograms.

## Measurement protocol

Ranges, sample sizes and matched-arm design were recorded before the first
retained baseline launch, and committed before any baseline cell completed.
Support-count clarifications and uncertainty safeguards were finalized during
baseline collection, before candidate or validation outcomes, without changing
the construction or ranges. Diagnostic variations
23,400,000–23,400,467 and untouched validation variations
28,080,000–28,080,467 and 32,760,000–32,760,467 are disjoint and aligned to 468.
Every competition uses the same simulation seed `variation+1` before/after,
with home-environment strengths 0.5 and 0.0. No candidate parameter is selected
from game outcomes. Untouched refers to simulation outcomes: structural tests
may inspect the predeclared deterministic roster identities, but neither
validation range's games are run before the construction is frozen. The exact
starting tree is retained in a detached worktree;
both trees run identical new instrumentation directly through `MatchSession`,
without a result cache.

Raw observations retain game-level numerators/denominators, regulation and OT
possession counts, final signed margin, scores, full attribute vectors, mean
attributes, raw role-neutral Overall and starter raw Overall. The canonical
runner's original judgments are retained, including failures and the short
certification sample. Raw-to-canonical checks reconcile mandatory metrics.

Ratios use summed numerators divided by summed denominators. For quartet `j`,
the ratio influence is `(N_j - R D_j) / mean(D_j)`. Exploratory 95% intervals
use 1.96 times the sample standard deviation of these influences divided by
sqrt(117). Before/after differences subtract matched influences, retaining
covariance. Final-margin SD differences use 10,000 paired quartet-bootstrap
resamples with fixed analysis seed 22092026. Intervals are conditional on the
selected deterministic schedule slices, without multiplicity correction;
nonsignificance is not equivalence or proof of no effect. These intervals
summarize observed quartet variation; they do not establish design-based
coverage for the complete Cartesian roster population.

Rare-event limitations were specified before candidate outcomes. Binary rates
include event/complement-bearing quartet counts; paired changes include the
positive, negative and equal-count quartets. Fewer than ten event-bearing or
complement-bearing quartets, or fewer than ten discordant quartets for a paired
change, flags a sparse normal approximation. Ten is a diagnostic heuristic,
not a new acceptance tolerance or a guarantee of coverage. Zero empirical
variance produces an unavailable interval, not a purported precise [0,0]
confidence interval. Normal bounds are not silently clipped. Sparse or
unavailable intervals cannot support a replicated-direction claim.

Population home-win rates are not the locked even-team home-win estimand.
The home-minus-neutral contrast isolates the environment intervention on each
observed input, and its before/after difference measures interaction with the
fixture correction. This two-arm diagnostic does not replace the canonical
three-arm controlled §17.4 cap test or establish a new cap verdict.

## Evidence and limits

Nine construction tests pass. Nine actual-source mutants are rejected by
assertions, including restoration of adjacent pairing, opener correlation,
nonuniform roster marginals, lost Cartesian coverage, collapsed player-noise
states, swapped explicit offsets, two omitted consumer migrations and the
mirror consumer's int64 narrowing. Consumer coverage includes structural wiring
checks and actual runtime calls to the home-court input constructor; it does
not claim execution of the other custom runners. The roster tests independently
execute construction. The expanded evidence is accepted in `bd42dc1` and
archived under `verified_mutations_v2/`. The final harness restores exact original bytes, including
the UTF-8 marker, and independent review matched every log and source hash.
Earlier incomplete or byte-restoration-failed attempts remain explicitly
superseded. See `CONSTRUCTION_VERIFICATION.md` for reproduction and scope.

The existing 24-game college compensation snapshot uses the catalog. The same
seeds/indices therefore now select different pairings. Its original 22-case
suite completed with three assertion failures and no errors. Matched audits
reproduced those three moved channels, and only their expectation pins changed:

| Channel | Before observation | After observation | Expectation change |
| --- | ---: | ---: | --- |
| Turnover rate | 0.1553075995 | 0.1549511002 | 0.1534 retained |
| ORB extension rate | 0.1121833534 | 0.1191931540 | 0.1122 → 0.1192 |
| ORB share | 0.2355580482 | 0.2429127293 | 0.2356 → 0.2429 |
| Assisted share | 0.6458164094 | 0.6328382838 | 0.6449 → 0.6328 |
| Both-team possessions/game | 138.1666667 | 136.3333333 | 138.17 retained |

All original tolerances remain: 0.004 for the rate pins, 2.0 for possessions.
The revised focused suite passes 22/22. These are reviewed snapshot updates,
not evidence that population channel rates are unchanged or inside their
locked bands. Original failures, both audits, revised passes and XML are
archived in `analysis/roster_pairing_followup/fixed_fixture/`.

The first complete eight-step local gate passed at Godot source state
(`bf275ccc89e16fe75830fd34a37529faf8df610a`): import, 266-script parse with no
failures, project acceptance including six unchanged goldens, simulation smoke,
810-build Builder portfolio, 80/80 attribute-sensitivity judgments, 15/15
structural-smoke judgments, and 692/692 tests across 55/55 suites. Independent
review reconciles every XML case and suite against the source declarations.
Test errors, failures, skips, flaky cases and orphans are zero. Deliberate
parse-detector/expected-error diagnostics and existing shutdown warnings remain
in the log; this is not a claim of error-free stdout.

Subsequent review found a large-index regression in the migrated home-court
consumer: packing the legacy mirror index `2v` into 32 bits changed its roster
at variation 1,073,741,824. The consumer now preserves the original int64 scalar
indices. A new actual-consumer test fails against the old source and passes
all 280 corrected inputs, covering five competitions, both construction modes,
both orientations and environment arms, and safe indices through `2^56+1`.
The expanded nine-mutant run is complete and accepted. The fresh complete
eight-step gate at source state `a15bdd00debf2e75925c9376ff316650b46b516b`
passes 693/693 cases in 55/55 suites, with 266 scripts parsed and unchanged
six-golden acceptance. Independent review reconciles exact XML suite paths and
test functions against source and matches archived XML bytes to the original.
The earlier 692-test gate is historical and does not verify the later consumer
correction.

This narrowly scoped correction does not change primary game observations:
the measurement runner never loads this consumer, its population indices stay
within 0–116, and all declared game ranges are below the mirror boundary.
`consumer_width_amendment.json` binds the exact old/new consumer hashes and
397 unchanged runtime/contract files without rewriting the original freeze or
process records. Independent review accepts that limited exception; the replay
guard applies it only to the candidate's exact consumer path and hash transition.

All twenty diagnostic cells are complete (9,360 games), and independent review
accepts their evidence integrity; see `DIAGNOSIS_REVIEW.md` and the committed
diagnostic summary. Both untouched validation ranges have twenty complete cells
each (9,360 games per range). Independent archive, arithmetic and fixture
reviews accept their bounded evidence; see `VALIDATION_A_REVIEW.md`,
`VALIDATION_B_REVIEW.md`, `VALIDATION_A_FIXTURE_REVIEW.md` and
`VALIDATION_B_FIXTURE_REVIEW.md`. The complete per-cell measurements, including
all canonical failures, are in `MEASUREMENTS.md`. All five candidate home-arm
possession and points-per-possession bands pass on both ranges. Other failures
remain: top-domestic close-game share newly fails in both, while its paired
change interval excludes zero only in B; population home-win verdict changes
reverse between ranges, and all candidate home-arm overtime bands fail.
Across ninety home-arm paired outcome/margin-width changes and ten two-arm
venue contrasts, none has a repeated same-direction interval exclusion. That
does not establish equivalence, proof of sampling noise, or an absent roster
contribution to overtime. A bounded twenty-cell, eighty-game replay matches
every archived four-game raw-row prefix exactly; independent hash, source,
metadata and runtime-log review accepts it. That proves instrumented raw-row
reproduction, not event-ledger byte identity or eighty additional calibration
observations. Publication/exact-head CI checks remain pending.
An execution interruption on September 22 stopped the attempted new v2 gate
during GdUnit without a completion result, and stopped five validation cells
midgame. The v2 log and five partial cell logs are preserved. Five completed
baseline cells were verified and retained; only the 35 missing declared cells
restarted with their original labels, variations and seeds. The restart manifest
was recorded after the restart began, and independent review checked its hashes
and source scope. Interrupted prefixes are extra attempted simulations, excluded
from completed-cell totals. A full v3 gate restarted from import. Neither the
interrupted v2 run nor the partial games are counted as passing evidence.
Neither the diagnostic nor the two untouched-range comparisons establish a
replicated outcome direction or equivalence. In particular, nonsignificant
home-effect contrasts do not exclude
roster-population interactions, and mirrored overtime results do not exclude
every roster contribution. No §27.1 certification is claimed; this task does not
authorize downstream tuning or completion of Stage 4.

Reproduction entry points and raw evidence live in
`analysis/roster_pairing_followup/`. The candidate freeze records the complete
tracked production/calibration/test file hashes on both trees, distinguishing
the reviewed calibration changes from unchanged engine and locked contracts.
