# Pace re-derived after stopped-clock corrections

Scope: the v16/v17 timing corrections followed by five competition clock
multipliers. No shooting, scoring, overtime, target or tolerance tuning.
The authoritative bands remain `BALANCE_SPEC.md` §14.1. All figures here are
measured diagnostics, not §27.1 certification.

## Matched derivation

The timing-corrected engine is `simulation-v17-stopped-foul-clock-and-live-rebound`.
Training uses 200 games per competition, variations 17000000–17000199, at the
shipped multiplier and at 1.10 times that multiplier. Rosters, seeds and every
other rule field are matched. Raw per-game sufficient statistics and complete
canonical competition judgments are retained under
`analysis/timing_pace_followup/reports/`.

| Competition | Original p | N at p | N at 1.10p | Fitted p |
| --- | ---: | ---: | ---: | ---: |
| High school | 0.834 | 73.1750 | 66.6650 | 0.920 |
| College | 1.041 | 74.6475 | 68.3925 | 1.143 |
| Development | 0.955 | 99.5850 | 90.9300 | 1.009 |
| Overseas | 1.031 | 77.7150 | 71.4325 | 1.057 |
| Top domestic pro | 0.891 | 106.3450 | 97.2275 | 0.956 |

N is full-game engine possessions per team, including overtime. Fit a local
response, not an exact physical law:

```text
slope = (1/N1 - 1/N0) / (p1 - p0)
p* = p0 + (1/Nobjective - 1/N0) / slope
```

The locked band midpoints (66.5, 68.5, 94.5, 76, 99.5) are fitting objectives;
they do not replace the original acceptance bands. Candidates are rounded to
three decimals. No ordering adjustment or second fitted candidate was needed:
`HS < top domestic < development < overseas < college` is preserved.
The profile version advances to `competition-v2-stopped-clock-pace`.

Actual possession response also depends on rounding, action trajectories,
fatigue, lineups and overtime. That is why the fit is remeasured on training
and separately validated; the inverse response formula is not itself evidence
of acceptance. Paired game-cluster intervals for the perturbation exclude zero
at every level. An independent critic reproduced all candidates and intervals
from the raw observations using separate arithmetic.

## Freeze and acceptance protocol

Candidate source commit: `743d845145268d223736e1bfb3a53bd2bf52fa6b`.
No validation range is opened before the training recheck. The declared
untouched ranges are 400 games/profile each: variations 18000000–18000399
and 19000000–19000399, seeds equal variation+1. The criterion is the original
possession bands and the complete eight-step gate, not proximity to midpoints.

All scoring/game-shape verdicts and home-court diagnostic failures must remain
visible. Matched base-versus-final training estimates isolate pace changes
under corrected timing. They do not measure population effects of the whole
follow-up versus the old remote head. The separate 24-game fixed-fixture audit
supports that narrower before/timing/pace comparison only.

The precise commands, scope, uncertainty definitions and aborted-launch record
are in `analysis/timing_pace_followup/PROTOCOL.md` and `COMMANDS.md`.

## Matched training recheck and regression observations

The single fitted vector remeasures at 66.5700, 68.4075, 94.2800, 75.8200 and 99.5025
possessions/team respectively. All five pass. No additional fit was made.

The intervention reduces possessions per game; it does not leave scoring unchanged:

| Competition | Points/team before →  after | PPP before →  after | Paired PPP change ±95% half-width |
| --- | ---: | ---: | ---: |
| High school | 70.1375 → 63.4600 | 0.9585 → 0.9533 | −0.00521 ±0.01200 |
| College | 78.6900 → 71.0525 | 1.0542 → 1.0387 | −0.01549 ±0.01108 |
| Development | 109.8850 → 102.6525 | 1.1034 → 1.0888 | −0.01462 ±0.01022 |
| Overseas | 86.8725 → 83.4850 | 1.1178 → 1.1011 | −0.01674 ±0.01172 |
| Top domestic pro | 124.0175 → 115.4600 | 1.1662 → 1.1604 | −0.00581 ±0.01155 |

PPP stays inside its existing band in all five training cells. The pointwise
paired intervals exclude zero for college, development and overseas, so those
indirect changes must not be described as absent. Intervals are exploratory,
without multiplicity correction, on training data used for pace selection.

Other canonical verdict changes are preserved:

- High-school raw home-win 0.530→ 0.495: pass→ fail.
- College raw home-win 0.560→ 0.595: pass→ fail.
- Development overtime 0.040→ 0.010: pass→ fail.
- Overseas close-game share 0.245→ 0.190: pass→ fail.
- College close-game share 0.205→ 0.250: fail→ pass.
- Development blowout share 0.215→ 0.175: fail→ pass.

All five overtime readings fail after fitting. High-school and college FG%
remain below their floors, and top-domestic close-game/blowout shares remain
outside their bands. Development raw home-win remains outside its band (0.585 → 0.580). Overseas raw home-win also falls 0.080 (paired half-width
0.06858) while failing in both arms; unchanged verdicts do not imply unchanged
outcomes. The population raw home-win rows are distinct from the controlled
venue estimator recheck. These observations are not dismissed as sampling
artifacts and do not authorize tuning another system.

## Provenance detail

The canonical reports record the checkout HEAD at process start, not a dirty
source fingerprint. Training base/slow processes started at `15225e8` with the
v17 timing patch already applied; final-training processes started at `76ce60c`
with the candidate profile already applied. They are **not** old-head population
simulations. Frozen source hashes, the timing commit `928ebcf` and candidate
commit `743d845` identify the executed code. The only measurement-runner byte
change during training was removal of two trailing blank lines, independently
reconciled against its recorded hash. Heldouts start after `743d845` and the
explicit validation freeze. See the raw archive for the unmodified metadata.

## Untouched validation A

400 games per competition, variations 18000000–18000399. All five original
possession bands pass; the critic independently reconciled raw rows, seed
contiguity, regulation/OT totals, source identity and ratio calculations.

| Competition | Possessions/team ±95% game-cluster half-width | Locked band |
| --- | ---: | --- |
| high school | 66.2100 ±0.3244 | 61–72 |
| college | 68.3287 ±0.3123 | 64–73 |
| development | 94.6088 ±0.3627 | 88–101 |
| overseas | 75.8200 ±0.3169 | 70–82 |
| top domestic pro | 99.5075 ±0.3599 | 96–103 |

At the A review, B and the final checks were still pending; B results follow
below. The completed venue recheck is recorded below; the complete gate result is recorded below. PPP passes in all five A cells, but the canonical
reports still fail other metrics: HS field-goal/raw home-win; college
field-goal/raw home-win/overtime; development field-goal/raw home-win/overtime/
close-game/blowout; overseas raw home-win/overtime; top domestic overtime/
close-game/blowout. Development's blowout share is 0.2475 against 0.08–0.18.
HS overtime reads 0.0400 and passes in A; the training failure is not presented
as universal. Every report also fails the certification sample requirement.

## Putback fixture failure discovered by the complete gate

The first complete-gate attempt exposed a stale reachability fixture in
`test_putbacks_carry_the_endgame_decision_in_force`. Seed 7095 now produces four
putbacks, none in a two-for-one-eligible situation. A pre-action state replay
finds no tag mismatch: the final-period putbacks occur at 159755ms and 15995ms,
outside the (24000ms, 58000ms] two-for-one window. This is not evidence of a
production tagging defect.

A declared bounded search from 7096 through 7300 first reaches the intended
branch at seed 7104: period 4, 44215ms, away trailing by 27, event 1152. That
fixture has six putbacks and exactly one two-for-one witness. The test now
compares every putback tag with the decision reconstructed immediately before
that action, and separately requires exactly one eligible and tagged witness.
The independent critic checked the actual eligibility and replay ordering.
No production source, golden seed, statistical target or tolerance changes in
this repair. `putback_fixture_audit.json` retains the original-seed diagnosis
and every searched seed through the first hit. The 19-case focused suite and tag-removal mutation passed their checks;
the final complete eight-step execution is recorded below.

## Untouched validation B and combined pace result

The second 400-game/profile range also passes all five original possession
bands. No value changed after either holdout was opened. Observed possession
ordering is HS < college < overseas < development < top domestic in both.

| Competition | A possessions/team ±95% half-width | B possessions/team ±95% half-width | Locked band |
| --- | ---: | ---: | --- |
| high school | 66.2100 ±0.3244 | 66.4287 ±0.2956 | 61–72 |
| college | 68.3287 ±0.3123 | 68.1663 ±0.2556 | 64–73 |
| development | 94.6088 ±0.3627 | 94.3563 ±0.3369 | 88–101 |
| overseas | 75.8200 ±0.3169 | 75.6813 ±0.3025 | 70–82 |
| top domestic pro | 99.5075 ±0.3599 | 99.4175 ±0.3094 | 96–103 |

All ten heldout PPP rows pass. This does not mean scoring or game shape is
certified or unchanged. Both ranges fail HS/college/development FG; development
blowout; and college/development/overseas/top-domestic overtime. Top-domestic
close-game and blowout shares fail in both. B additionally fails top-domestic
three-point-attempt rate and raw home-win. HS overtime fails B but passes A;
overseas raw home-win fails A but passes B. The complete failed-row inventory,
including numerical bands, and the ten-cell scoring/shape table are in
[`HELDOUT_VERDICTS.md`](../analysis/timing_pace_followup/HELDOUT_VERDICTS.md).
Full canonical reports retain every judged and informational row, including
certification-size failures. The controlled venue recheck and full gate results follow below.
Possession-band success alone does not complete Stage 4.

The development training blowout improvement does not generalize to the heldouts
(A 0.2475; B 0.1875, both fail). Development FG passed training but fails both
heldouts (0.428743 and 0.428928). Conversely, the overseas training close-game
failure does not recur (A 0.2600; B 0.2375, both pass). Top-domestic B's failed
three-point-attempt rate is 0.359986816084377 against a 0.36 floor; displaying
it as 0.360 must not erase that verdict. These are observed heldout outcomes,
not proof that pace caused each failure: no matched old-pace arms were run on
the heldouts, and the matched training comparison has its own stated limits.

## Controlled home-court recheck

All five 200-fixture mirror diagnostics are complete (1000 matched triples,
3000 games, diagnosis variations 710000–710199). Every paired attributable
home-win estimate and paired §17.4 cap passes. Overseas retains the failed
legacy efficiency-gap cap: 2.632164 > 2.5, while its paired estimate is 1.944573.
That canonical report remains FAIL. No home-environment tuning was performed.
The per-profile estimates, intervals, exact failure and distinctions between
legacy, home-only and paired calculations are retained in
[`VENUE_RECHECK.md`](../analysis/timing_pace_followup/VENUE_RECHECK.md).
These diagnostics do not establish certification or prove all home-court
questions closed. The complete eight-step gate result follows below.

## Score-margin guard correction from the complete run

The second eight-step invocation completed with exit 100 and one assertion
failure: the unchanged 24-game +5 capability-edge portfolio contained no upset.
The other executed cases passed. GdUnit launched 54 suites and executed 670
actual cases; the XML root declares 683 because the score-margin suite stopped
after its fifth case, leaving 13 cases unrun. The declared count must not be
reported as 683 executed passes. `second_gate_attempt_results.xml` and the
complete log retain this failed run.

A retrospective full-log review also found the same score-margin failure in
the stopped first attempt. It was missed by the progress-tail review before
the first restart; `first_gate_attempt_disposition.json` records that correction.
Matched isolated audits reproduce 3/24 upsets at the original head, 3/24 after
timing alone, and 0/24 after the pace adjustment. The original 24 indices,
rosters and seeds remain unchanged; its overlap (2 < 26) and slope (3.65 within
1–7), plus the other distribution guards, are retained. The failed upset-count
assertion is explicitly replaced, not relabeled as a pass. BALANCE_SPEC §3
principle 2 requires uncertainty but sets no minimum upset rate for this fixture.

Test-only commit `54fdffd` separates a selected full-game reachability witness
from those distribution guards. Index 33/seed 511033482 produces a genuinely
stronger roster losing 99–115, with independently reconciled scoring, completed
periods and deterministic ledger replay. A valid-ledger forced-favorite reroll
mutant fails exactly the two loss assertions while all other witness checks
pass. The full focused score-margin suite passes 19/19. The independent critic
accepts this changed test contract and its limited, existential claim; it is not
an unbiased upset-rate estimate or a claim that the original fast gate was
unchanged. No production code, locked target, sample size or numeric tolerance
was altered. Full attribution, original failure and mutation evidence are in
[`SCORE_MARGIN_REACHABILITY_VERIFICATION.md`](../analysis/timing_pace_followup/SCORE_MARGIN_REACHABILITY_VERIFICATION.md).
The complete eight-step gate restarted from the beginning at `54fdffd` and
completed successfully, as recorded below.

## Complete local gate and scope of acceptance

One fresh `tools/run_checks.sh` invocation at
`54fdffd1805251f9b2ee1828d4c2caf98ab871f9` completes all eight steps with exit 0.
The XML contains **684 actual testcase entries**, matching its 684 declared
cases, across **54/54 suites**. Every suite's declared and executed counts agree.
There are zero errors, failures, skips, flaky cases or orphans. This is a whole
passing run after both reviewed test corrections, not a stitched result.

| Step | Result |
| --- | --- |
| Import | Pass |
| Warnings-as-errors parse | 263 scripts, 0 failures |
| Project acceptance | Pass, including all six reviewed goldens |
| Fixed-seed simulation smoke | Pass |
| Builder portfolio | Pass |
| Attribute sensitivity | 80/80 judged metrics pass |
| Calibration smoke | 15/15 judged metrics pass |
| GdUnit | 684/684 cases, 54/54 suites, all pass |

`full_gate.txt`, `full_gate_result.json`, `full_gate_results.xml` and
`full_gate_audit.json` retain the completed execution. Nine timing mutants under
the final pace vector and two supplementary mutations (removed putback tag and
valid-ledger forced-favorite reroll) are assertion-killed. Source and test hashes
are retained with their results. Logs also retain deliberate parse self-test
errors, asserted error cases and existing tool/debugger shutdown diagnostics;
this is an exit-code/assertion claim, not a claim that stdout contains no error
text. Locked contract/target files are unchanged from `15225e8`.

The accepted scope is timing correctness, a measured five-profile pace fit,
both untouched possession-band validations, and the disclosed regression
recheck. Scoring, game-shape, raw home-win and the overseas legacy-cap failures
remain. The changed upset-test contract proves selected reachability only.
Stage 4, Gate 0 and §27.1 certification remain incomplete.

The published head is verified separately by GitHub CI after the final evidence
commit is pushed. The exact head and run are recorded in PR #1's description and
checks; this pre-publication report does not claim a future CI result. PR #1
remains draft and unmerged.
