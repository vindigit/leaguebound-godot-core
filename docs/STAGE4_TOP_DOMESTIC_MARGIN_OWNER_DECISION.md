# Stage 4: top-domestic margin dispersion — owner decision

**Disposition:** no match-engine or calibration-target change. A deterministic
structural cause of the top-domestic close-game shortfall has not been proven.
The repeated failure remains open for the owner. This package does not claim
`BALANCE_SPEC.md` §27.1 certification.

## Starting state and evidence tiers

The investigation began from `origin/stage4-calibration` at
`74b2c55028bbb1a4cc43440ffec52f015c9ba7b2`, with a clean worktree. PR #1
was open, draft, unmerged and at that exact head. The earlier roster-pairing
follow-up's two untouched 468-game candidate home-arm ranges are **reused
evidence**, independently recounted from its archived per-game rows. They are
not 936 new exact-head games per competition. The present follow-up adds two
new disjoint 40-variation ranges per competition and matched arm. No result is
a 100,000-game competition certification sample.

| Earlier roster-pairing validation | A, 468 games | B, 468 games |
| --- | ---: | ---: |
| Top-domestic close, locked 22–34% | 91/468 = 19.44%, fail | 81/468 = 17.31%, fail |
| College close | 115/468 = 24.57%, pass | 138/468 = 29.49%, pass |
| Top-domestic final signed-margin SD | 16.99 | 16.35 |
| College final signed-margin SD | 13.13 | 13.49 |
| Top-domestic total possessions / college | 1.458 | 1.456 |

The earlier matched top close-share change from the pre-pairing construction
was −4.49 percentage points in A and −6.41 in B. The archived exploratory
quartet-normal 95% half-widths are 4.59 and 4.30 points respectively; A's
paired interval includes zero, B's excludes it. The candidate close-share
interval includes the 22% floor in A and excludes it in B. Repeated point-band
failure therefore does not prove the roster-pairing correction caused it.

Independent recount reconciled all 4,680 previous candidate per-game rows
across five competitions, their declared seed/quartet keys, 140 game-stat and
game-shape estimates/verdicts, and the six reported top rotation means. Every
competition's possession and points-per-possession bands pass on both ranges.
Other failures remain; all five overtime point estimates fail both ranges.
High-school and college FG%, developmental blowout share, and top-domestic
close and blowout share fail both ranges. Raw population home-win verdicts do
not replace the controlled §17.4 venue estimand. The previous records are at
`analysis/roster_pairing_followup/`; the present manifest and raw rows are at
`analysis/margin_growth_followup/`.

A separate fresh canonical runner on the starting production head remeasured
all five competitions at seeds 1–40 (40 games each). Its 98 metrics include
74 judged rows and nine failures, one being the global §27.1 sample-size
failure. The other eight are high-school FG%, college FG%, college 3P%,
college population home-win, developmental OT, overseas population home-win
and OT, and top-domestic OT. All five pace and PPP rows pass. Top-domestic
close is 10/40 (25%) and blowout is 7/40 (17.5%), both passing in this tiny
cell; OT is 1/40 (2.5%), failing. This does not cancel the two larger
close-share failures or establish a new verdict direction. The report is
`analysis/margin_growth_followup/competition_calibration_current_40_each.json`;
the runner exits nonzero when locked verdicts fail, so its exit 1 is expected
and preserved as a calibration result, not counted as a fast-gate pass.

## New matched protocol

The protocol was recorded before retained runs. A four-variation debugging
probe at 42,120,000 was excluded. Untouched A is 43,290,000–43,290,039;
untouched B is 47,970,000–47,970,039. Every range has ten aligned roster
quartets. College and top domestic each use three roster arms—ordinary catalog
AB, identical AA using the ordinary home roster on both sides, and reversed
BA—and two home-environment strengths, 0.0 and 0.5. This is 40 games per cell,
24 cells and 960 new games total. Each variation/arm/environment within a
competition has seed `variation+1`, the same match and game IDs, and the same
opening assignment. Their random-stream names match, but changing a game
trajectory can change subsequent draws. College and top domestic have distinct
competition-specific match IDs, so their comparison is descriptive rather
than a common-random-number rule-profile intervention.
The source-fingerprint manifest was captured after the four processes
launched and before they completed; it discloses that timing. Instrument and
runner semantics had been frozen before launch, and the post-run byte check
compares their hashes with the recorded manifest.

AA sets the scalar pregame gap to zero but changes the away roster's entire
composition and matchup geometry. BA swaps full roster indices without
swapping venue or opener. Neither arm isolates a causal percentage called
"roster strength." The aligned quartets preserve the roster schedule's local
counterbalance, but 40 games cover only part of its 468-game marginal cycle;
these cells do not represent the full Cartesian roster population. Quartets,
not individual games, are the uncertainty unit. Ten quartets per range make
rates, rare OT events, and bootstrap SD intervals exploratory. SD intervals
use 2,000 deterministically seeded paired-quartet bootstrap resamples; they
are pointwise and unadjusted across the many contrasts.

The ledger observer reconstructs home-minus-away scoring from actual ordered
events. It checks each native period and final score, box totals, possessions,
shot-probe alignment, clock partitions, and six-term identities. Four equal
elapsed-regulation bins allow a time-aligned college/top comparison despite
college halves and top-domestic quarters. The final 120 seconds and overtime
are separate windows. Its `live_ms` key means **charged game-clock time**,
including charged inbound time. `summarize.mjs` rejects incomplete cells,
duplicate/missing matched rows, range drift, wrong roster/opener keys, and
clock nonconservation. All four declared files passed with 960 rows and the
required aggregate witnesses for shots, blocks, fouls, free throws, rebounds,
turnovers, intentional fouls and late possessions. B had no top-domestic OT in
any of its 240 games across arms; that absence is reported, never manufactured.

## Signed growth and channels

The table uses the ordinary home arm in each new range. `Q1…Q4` are consecutive
equal elapsed-regulation bins; numbers in the first four columns are **signed
home-minus-away margin increments**, and the last four are SDs of the
**cumulative** signed margin. The college native periods are two halves; the
top-domestic native periods are four quarters. Native-period details remain in
`summary.json`.

| Range, competition | Q1 | Q2 | Q3 | Q4 | SD at Q1 | Q2 | Q3 | Q4 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A college | −2.55 | +1.23 | +0.88 | −1.02 | 7.30 | 12.49 | 13.40 | 13.61 |
| A top domestic | −0.93 | +2.05 | −0.70 | +2.90 | 10.61 | 14.39 | 12.36 | 13.45 |
| B college | −0.38 | +1.52 | +0.47 | +0.60 | 7.64 | 10.32 | 11.78 | 12.47 |
| B top domestic | −0.72 | +1.18 | +2.08 | −0.17 | 10.35 | 15.92 | 19.44 | 19.83 |

Top A narrows during Q3 while top B expands most strongly during Q3. Thus
"late-game expansion" is not a replicated explanation. In the final 120
seconds, the top home arm's mean change in absolute regulation margin is
+0.15 in A and −0.57 in B; the increment aligned to the pre-window leader is
−0.17 and −0.97. Two of eight pre-window close A games and three of six B
games crossed above five points; B also had three wide-to-close transitions.
Top late windows contained, per game, 9.20/8.95 possessions, 3.05/3.55 free
throw attempts, 2.23/2.92 makes, and 0.53/0.50 intentional fouls. These
channels are present, but the ledger does not show a repeated late widening.

Each signed quarter margin equals six exact accounting terms: realized field
efficiency, possession **imbalance**, offensive rebounds, turnovers, residual
field-attempt volume, and free throws made. The full quarter and native-period
component means are in `summary.json`; selected top-home quarter means below
show how the signed increments were carried. `Poss` is imbalance, not total
pace. Values are points per game; rounding may leave a 0.01 difference.

| Range/Q | Shooting | Turnovers | ORB | FT | Poss | Volume residual | Margin |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A Q1 | −2.10 | +0.09 | +0.62 | +0.70 | +0.11 | −0.35 | −0.93 |
| A Q2 | +1.37 | +0.54 | −0.08 | +0.15 | +0.04 | +0.04 | +2.05 |
| A Q3 | −0.75 | −0.34 | −0.14 | +0.68 | −0.05 | −0.09 | −0.70 |
| A Q4 | +2.30 | +0.51 | −0.43 | +0.35 | −0.07 | +0.24 | +2.90 |
| B Q1 | −0.57 | +0.24 | −0.18 | −0.33 | −0.02 | +0.14 | −0.72 |
| B Q2 | +0.91 | +0.30 | −0.16 | +0.25 | −0.14 | +0.02 | +1.18 |
| B Q3 | +1.08 | +0.83 | −0.38 | +0.78 | −0.03 | −0.20 | +2.08 |
| B Q4 | +0.01 | −0.02 | −0.41 | +0.20 | −0.17 | +0.22 | −0.17 |

The variance view uses `Cov(component, final margin) / Var(final margin)`;
shares can be negative and sum to one. Realized shooting-efficiency shares are
0.68/0.62 in top A/B versus 0.82/0.74 in college. The conditional make-roll
innovation shares are 0.50/0.37 in top versus 0.76/0.67 in college. The
conditional variance budget summed over observed unblocked shot rolls is
235/233 point-squared in top versus 153/155 in college; total possessions
are about 200 versus 136–137. Longer exposure is substantial descriptively.
The innovation is conditional on the observed shot and block; it is not all
shooting uncertainty. Its covariance with final margin also includes adaptive
future paths. Neither share proves a unique shooting-variance defect.

Top turnover covariance shares are 0.10/0.16, ORB 0.01/0.05, and free throws
0.24/0.28. College comparisons are 0.05/0.14, −0.05/0.01, and 0.21/0.15.
Those exact allocations identify carriers of realized margin variance, not
causal effects of changing any rate. Balanced extra possessions are absent
from the *imbalance* term even though they increase exposure and possible
variance. We therefore compare total possessions separately.

## Matched-arm findings and uncertainty

| New range | Ordinary home close | Ordinary home SD | Neutral ordinary SD | Neutral AA SD | Neutral BA SD |
| --- | ---: | ---: | ---: | ---: | ---: |
| A college | 7/40 | 13.62 | 12.88 | 12.62 | 11.73 |
| A top domestic | 5/40 | 13.49 | 14.02 | 15.16 | 19.24 |
| B college | 9/40 | 12.50 | 14.45 | 11.19 | 13.90 |
| B top domestic | 6/40 | 19.83 | 21.28 | 15.44 | 13.70 |

For top domestic, neutral ordinary-minus-AA SD is −1.14 points in A, with a
paired-quartet bootstrap 95% interval [−3.95, +2.18], and +5.84 in B,
[+0.89, +11.01]. Neutral ordinary-minus-BA SD likewise changes sign:
−5.22 in A, +7.59 in B. Strength-index gap SD is 4.41/6.07 for top A/B and
4.32/6.14 for college. This varying partial-slice roster spread and the arm
sign reversals block a replicated, uniquely structural roster attribution.
Top neutral AA close counts are 9/40 in A and 8/40 in B; neutral BA is 11/40
and 8/40. At home strength 0.5, AA is 8/40 and 6/40; BA is 11/40 and 8/40.
Some diagnostic arms reach the band in a 40-game cell and others do not;
these are not population verdicts. AA still has sizable top margin SD, so a
scalar strength-gap argument does not eliminate its observed dispersion.

Top ordinary home-minus-neutral **signed** margin is +3.00 points (quartet SE
1.33) in A and +1.50 (SE 1.51) in B. With ten quartets, a two-sided t interval
uses nine degrees of freedom (factor about 2.262); both include zero. College
contrasts are −0.58 and +1.33. The earlier 468-game top contrasts were +0.70
(archived normal 95% interval [−0.16,+1.55]) and +1.30 ([+0.48,+2.11]);
the B venue contrast excludes zero while A does not. Both point estimates are
positive; evidence against zero differs by range. Neither contrast isolates
the cause of the close-game failure. This two-arm intervention does not replace
the controlled three-arm §17.4 cap test.

## Adverse findings and corrected interpretations

- A one-variable strength-gap R² is a linear sample association, not the
  percentage of margin variance that "legitimately belongs" to roster
  strength. Its residual is not all "engine-invented" margin. AA changes the
  whole opponent roster, and BA trajectories can diverge after the same
  derived stream labels.
- An observed-to-independent-benchmark SD ratio near one cannot prove
  possession independence or exclude persistent game states, RNG coupling or
  covariance cancellation. Conditioning scoring covariance on *realized* pace
  is conditioning on an outcome, not removing an exogenous input; the residual
  is descriptive, not a unique in-game causal share.
- The score-margin, overtime, close-share and blowout failures have not been
  proven to be one defect or mathematically unreachable under §14.1. Prior
  categorical language is superseded in `PROJECT_STATUS.md` and the comments
  of `MarginDecomposition` and `ScoringCovariance`.
- The box-score projector currently counts missed attempts with shooting
  fouls in FGA. The scoring ledger and this audit deliberately reconcile that
  existing event definition. This denominator issue cannot change scores or
  explain margin dispersion, but it makes categorical claims about the cause
  of college/high-school FG% shortfalls premature. A separate accounting
  audit is needed before changing that statistic or its locked target. The
  [FIBA Statisticians’ Manual (2024), §2.1](https://assets.fiba.basketball/image/upload/documents-corporate-fiba-statisticians-manual-2024.pdf)
  excludes a missed shot with a shooting foul from FGA.
- B has zero top-domestic overtime games in 240 new arm games; this is sparse
  observation, not evidence of an impossibility. The prior larger ranges are
  the stronger overtime evidence.

## Decision requested of the owner

The complete eight-step local gate exited 0 with 57/57 GdUnit suites and
703/703 cases passing, including committed golden hashes, home-environment
invariants and the score-margin suite. The focused ten-case audit and all
sixteen actual-source mutants passed their independent checks. The evidence
manifest verifies 291 source fingerprints and byte-identical summary
recomputation. These structural checks do not turn the failed calibration
verdicts into passes or establish §27.1 certification. Exact published-head CI
is checked after the fast-forward push; the execution log is under
`analysis/margin_growth_followup/`.

1. **Keep the existing contracts and authorize deeper diagnosis (recommended).**
   Preserve the draft PR and unchanged production behavior. Fund larger,
   disjoint quartet-balanced diagnostics or a fully controlled mechanism
   intervention for the specific shortfall, plus the separate FGA accounting
   audit. The 40-game arm intervals cannot choose a tuning lever.
2. **Consider a specification amendment only after an external benchmark and
   owner ruling.** Any revised §14.2 band requires explicit design authority,
   provenance and a new validation plan. This package neither proposes a new
   number nor alters a target.

No clamp, tie/overtime manufacture, verdict-driven tuning, or rule/profile
change is part of either option. Match-engine, rating, clock, probability,
roster-pairing, target and tolerance files remain unchanged by this follow-up.
