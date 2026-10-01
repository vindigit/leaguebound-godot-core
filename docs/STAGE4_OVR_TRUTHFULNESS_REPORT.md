# Stage 4 OVR truthfulness follow-up

This is a bounded Stage 4 instrument, arithmetic/consumer audit, and basketball
performance report. Production behavior, the locked rating formula, Builder
economics, shooting, pace, clocks and calibration targets are unchanged.
It does not run §27.1 certification or complete Stage 4. The consolidated
blocker review owns the overall gate and release conclusions.

The locked arithmetic agrees with independent oracles. In both untouched
freshman ranges, broad within-player improvements raised scoring, rebounding,
steals/blocks and team margin, while increasing fouls and reducing minutes.
Current OVR has conditional performance relationships rather than a universal
matchup ordering. Exact-cap potential is arithmetically truthful; its ordering
after permitted cap loss remains an explicit owner conflict.

## Locked arithmetic and consumption

BALANCE_SPEC §6 defines a role-neutral summary:

```
OverallRaw = 0.65 * mean(all 20 attributes)
           + 0.25 * mean(top eight attributes)
           + 0.10 * mean(bottom six attributes)
Displayed = round(clamp(OverallRaw, 25, 99))
```

Exact-cap potential uses precisely the same formula on the twenty exact caps.
The independent integer oracle is
`(78*sum20 + 75*sumTop8 + 40*sumBottom6)/2400`; it sorts independently and
clamps before half-up rounding. A fixed legal-domain vector has raw 56.5 and
displayed 57; changing its 44 attribute to 43 displays 56. Helper-only 0/120
uniform vectors test clamps, and never become active players.

The current calculator's signature accepts only `PlayerAttributes` and
`RatingsProfile`. Position, tactical/rotation role, reputation, popularity,
morale, trust, team fit, age, prospect and potential have no current-rating
ingress. The same calculator and projection query are used for users and
NPCs; changing detail level, role and identity does not choose a new formula.
The separate potential method is the only exact-cap ingress. Existing
simulation OVR-exclusion tests scan resolution, event, result and projection
paths: basketball resolves raw attributes/body/tendencies and does not consume
current or potential OVR. This is an ingress and source audit, not a promise
that equal OVR means equal basketball behavior.

The fourteen focused GdUnit tests independently compare 500 seeded vectors,
all twenty attribute sweeps through 25–99 including rank crossings and ties,
permutations, clamp/half boundaries, exact caps, non-rating exclusions,
user/NPC identity, cache refresh and existing display rows. JSON/schema-2
record roundtrips preserve canonical attributes/caps and rederive both ratings;
OVR is not stored as authoritative state. This exercises the current-schema
pass-through path, not a legacy migration. This is record-level serialization:
the repository has no full SQLite player save/reload adapter to certify.
`BuilderConfirmationView` retains the existing Current Overall, Maximum
Potential and Projected Peak labels. No new UI was built.

One deterministic owner conflict is separate from formula truthfulness.
Permitted §8.3 cap loss can place caps below current attributes, while §6.3
also demands current ≤ potential universally. The retained domain example
has current 80, exact-cap potential 79 after two permitted 80→72 injury cap
entries, and actually reaches the projection consumer's ordering assertion.
Godot returns a partially initialized 0/0 object after logging that assertion.
This uniform vector is not claimed to be a naturally generated career state.
See [the owner package](STAGE4_OVR_CAP_ORDERING_OWNER_DECISION.md) and its
exact log/source evidence. No locked contract was silently reconciled.

## Frozen basketball design and populations

`analysis/ovr_truthfulness_followup/protocol.json` was committed before
confirmation at `51a115ee22d1bd622fae991fc450a4eef7e43bcb`; the expected
production baseline is `899a3972e48e8ce63de07b47b2e593e9c97df4d2`.
Raw run manifests record actual execution heads and SHA-256 values for the
runner, harness, focused tests, protocol and every production GDScript, and
refuse any source change by collection end. Shared Builder manifests carry
their independent fixture, audit, protocol and production hashes.
Range A executed at `f3bca23cab22e7833808ea037dfbf2ef2f259292` and B at
`05163e375ccce5d33030a48496424be3581163ef`. Each has 140 production GDScript
fingerprints, three separate Gd instrument fingerprints and the protocol
fingerprint; both report unchanged sources through collection. The later
shared Builder presentation correction is disclosed below and changed none
of these sources, samples or estimators.

The primary experiment begins with legally confirmed Balanced age-14
freshmen, Average maturity and default guard/wing/big bodies. Every rating is
purchased through Builder raising and confirmation, never inserted by editing
an array. Its ledger cost audit uses the literal §9.1 bands. Body bases and
selection checks reuse BuilderRules, so that helper is not claimed to be an
independent full body-rule implementation; the Builder report supplies the
literal body/AP/limit and seeded cap-replay audit for its portfolio.

Each range has eight source-player clusters per family (24 total), with three
arms and a full venue/opener quartet: baseline, all twenty attributes raised
ten points toward exact caps, and only the five scoring attributes raised ten
points toward exact caps. Each intervention grants the exact cost and spends
it through canonical `DevelopmentService`; exact caps stay unchanged. These
are controlled attribute interventions, not equal-resource starting builds or
natural season opportunity predictions. In particular, the broad grant can
exceed a normal freshman seasonal opportunity. Teammates and opponents are
confirmed freshmen, with body, role, lineup, tendencies and input fingerprints
held fixed within each comparison. Guard/wing/big subjects start at PG/creator,
SF/slasher and C/interior anchor. Environment is zero.

Within each quartet the subject is home/open, away/open, away/not-open,
home/not-open. Arms share the same gameplay seed for each slot; changed events
can consume different subsequent draws, so matched seeds do not promise
identical later random draws. Match/game labels are deliberately constant;
independent cluster/slot seeds identify these pure stateless experiments.

| Evidence | Range A | Range B | Fixed size |
| --- | --- | --- | --- |
| Within-player sources | 9800001–9800024 | 9900001–9900024 | 24 source players/range |
| Within-player games | 9810001–9810096 | 9910001–9910096 | 288 games/range; 3 arms/seed |
| Corrected catalog games | 9820001–9820040 | 9920001–9920040 | 40 games/range; five competitions |
| Natural college sources | 9840001–9840040 | 9940001–9940040 | 40 source players/range |
| Natural college games | 9850001–9850008 | 9950001–9950008 | 8 games/range; two populations |
| Natural career histograms | 9860001–9861000 | 9960001–9961000 | 1000 natural careers/range |

The catalog extension preserves `competition-catalog-v4-roster-pairing`, its
117 roster states and corrected ABBA/alternating-opener design. It observes
unchanged competition-appropriate catalog players; it does not transplant
freshmen into professional teams. Its 1170 players per competition, counted
once per roster-state/player, are synthetic calibration fixtures with absent
ages/caps. They are not the §8.2 recruited/draft/active-world populations.

The college extension samples natural `CareerSimulator` paths without an
imposed career outcome or performance selection. It uses recorded college
class snapshots (slot modulo three chooses class), original exact caps,
creation AP, source seeds and recorded ages. Bodies are resolved through
`BodyMaturationService` chronologically from years two through the snapshot
career year using the original confirm stream; ratings stay equal to the
recorded snapshot. The career harness itself did not resolve those body
milestones. First-five starters and remaining rotation players are an
experimental roster assignment, not a production roster-selection system.
Two source populations per range is sparse coverage.

## Observables, uncertainty and interpretation

The seven predeclared aggregate all20-versus-baseline primaries are margin,
points/32 minutes, FG fraction, assists/100 touches, turnovers/100 touches,
rebounds/32 minutes, and steals+blocks/32 minutes. Raw counts accompany every
normalized measure. Secondary measures include eFG, creation/advantages,
three-point outcomes, defensive rebounding, fouls, team wins, possession
contribution and opponent shooting while the player is on court. On-court
opportunity uses presence at POSSESSION_STARTED; mid-possession substitutions
do not create a new possession opportunity. Minutes use authoritative integer
box-score seconds, not a reconstructed continuous clock. On-court opponent FG
is a lineup result, not an isolated defender statistic.

Ratios divide pooled raw numerators by pooled denominators; undefined zero
denominators remain null. Field-goal percentages preserve the existing FGA
semantics, including missed shooting-foul attempts counted as FGA (§5.39).
The denominator-owner audit remains open; FG/eFG comparisons therefore carry
that interpretation risk. No report-side ratio silently fixes gameplay.

Paired bootstrap resamples whole source-player quartets, stratifying family,
with 10,000 deterministic draws. Pointwise 95% and Bonferroni familywise 95%
intervals cover seven primaries across both untouched ranges (14 comparisons).
Family n=8 intervals and scoring-only comparisons are descriptive. No locked
minimum OVR-to-performance effect exists: native-unit magnitudes/intervals
are reported without inventing acceptance bands. Lack of an interval excluding
zero is not equivalence, nor proof of a bad rating formula.

Catalog/college relationships use direct basketball observables, not a score
derived from OVR weights. The Pearson predictor is continuous raw current OVR;
displayed-current ranges and same-displayed-rating examples remain separate.
Player quartets are pooled before correlations;
bootstrap retains whole source-population/quartet clusters and stratifies
competition (2000 draws). Competition, position, tactical/rotation role,
derived specialization, minutes and touch opportunity strata are reported,
including joint within-stratum demeaned relationships. There are only two
quartets/populations per competition/range; dependent player observations
do not become independent populations. Such intervals are sparse and
descriptive, with no calibrated pass/fail interpretation.
The catalog self-pair quartet uses identical roster states on both teams.
Its home/away copies therefore pool into ten logical state observations with
eight player-game exposures each; the second quartet contributes twenty
observations with four exposures each. This yields 150 logical roster-state
observations and 800 raw player-game rows per range, rather than 200 player
quartets. The same catalog states recur across ranges. Generated college has
40 source-player observations with four exposures each per range.

Shared Builder confirmation is a descriptive secondary comparable-player
analysis. Only the eighteen Balanced wing 195-AP primary builds enter it;
Ready Now/High Upside and guard/big secondary arms are excluded. Same displayed
OVR pairs retain different exact rating vectors, bodies/tendencies, contextual
lineup/opponent, raw counts and outcomes. These pairs illustrate differences
the role-neutral summary deliberately omits. Differing-OVR inversions retain
those same fields. Correlation, isolated matchup wins and generic possible
causes do not establish formula defects or a universal dominance violation.

## Retained measurements

The completed archive contains 576 within-player games, 80 corrected catalog
games and 16 naturally generated college games. Both range collectors exited
zero. The verifier accepted every fixed seed, complete venue/opener quartet,
three-arm match, source/control signature, formula and count identity. There
are 192 unique within-player seeds reused across three arms, 80 catalog seeds
and 16 college seeds. Natural population diagnostics contain 2000 unique
career seeds; the identical 5850 fixture roster-state/player records are
counted once across the two histogram files. They are not 5850 independent
world populations or necessarily distinct numeric attribute vectors.
The 2000 histogram career draws are separate from the additional 80 source
careers used to construct the generated-college match populations, for 2080
source-career executions in the retained OVR collection.

### Controlled current-attribute improvements

Each row below represents 96 games, pooled from 24 source-player quartets.
REB is offensive/defensive rebounds, and S+B is steals plus blocks. Full raw
counts and every normalized observable are in
[the aggregate](../analysis/ovr_truthfulness_followup/aggregate.json).

| Range/arm | Displayed OVR | Seconds | Points | FGM/FGA | 3PM | AST/TOV | REB | S+B |
| --- | --- | ---: | ---: | --- | ---: | --- | --- | ---: |
| A baseline | 47 | 110700 | 602 | 230/681 | 35 | 67/122 | 101/341 | 74 |
| A all20 | 57 | 103655 | 896 | 345/799 | 82 | 75/105 | 126/395 | 119 |
| A scoring5 | 50 | 113528 | 816 | 303/804 | 80 | 64/111 | 98/359 | 84 |
| B baseline | 47 | 113387 | 610 | 243/738 | 33 | 79/140 | 126/362 | 79 |
| B all20 | 57 | 106077 | 894 | 335/828 | 79 | 99/115 | 155/432 | 136 |
| B scoring5 | 50 | 112347 | 773 | 290/832 | 77 | 78/134 | 118/353 | 80 |

| Range/arm | Touches | Offensive/defensive on-court possessions | Personal fouls | Created made FGs | Team wins | Mean margin |
| --- | ---: | --- | ---: | ---: | --- | ---: |
| A baseline | 1747 | 3794/3802 | 206 | 124 | 45/96 | −0.19 |
| A all20 | 1725 | 3547/3569 | 322 | 127 | 60/96 | +4.08 |
| A scoring5 | 1859 | 3890/3891 | 211 | 118 | 49/96 | +0.29 |
| B baseline | 1802 | 3858/3884 | 240 | 134 | 44/96 | +0.09 |
| B all20 | 1791 | 3592/3619 | 333 | 134 | 57/96 | +4.10 |
| B scoring5 | 1856 | 3826/3836 | 232 | 130 | 48/96 | +0.48 |

The primary effects are **all20 minus baseline**, with the predeclared
14-comparison familywise 95% bootstrap intervals. FG changes are percentage
points under the existing foul-attempt denominator semantics. Lower turnover
rates are favorable. Pointwise intervals, exact unrounded effects and all
secondary intervals remain in the aggregate.

| Primary observable | Range A effect [familywise 95% interval] | Range B effect [familywise 95% interval] |
| --- | --- | --- |
| Team margin | +4.27 [1.74, 6.86] | +4.01 [0.30, 7.34] |
| Points/32 minutes | +6.16 [4.24, 8.06] | +5.85 [3.99, 7.65] |
| FG percentage points | +9.41 [4.09, 14.84] | +7.53 [2.54, 12.07] |
| Assists/100 touches | +0.51 [−1.15, 2.11] | +1.14 [−0.16, 2.49] |
| Turnovers/100 touches | −0.90 [−2.89, 1.15] | −1.35 [−3.09, 0.23] |
| Rebounds/32 minutes | +1.98 [0.75, 3.01] | +2.36 [1.42, 3.31] |
| Steals+blocks/32 minutes | +0.92 [0.42, 1.44] | +1.12 [0.51, 1.74] |

Five primary directions have familywise intervals excluding zero in both
ranges. Assists and turnover effects remain inconclusive in the declared
family; favorable point estimates do not establish an effect or equivalence.
The all20 mean raw-OVR gains are 9.994/10.000 and displayed gains are exactly
ten. These resource-funded improvements support useful conditional rating
relationships, not starting-build fairness or formula-wide performance proof.

Disadvantages remain visible. All20 mean minutes fall from 19.22 to 18.00 in A
and 19.69 to 18.42 in B. Fouls/32 rise from 3.57 to 5.96 and 4.06 to 6.03.
Five-foul games rise from 16 to 25 and 13 to 31. The eligibility path excludes
fouled-out players, but these archives do not retain the fifth-foul timestamp
or foul-type decomposition, so the causal share of lost minutes is unresolved.
Passes, touches, on-court possessions and creation counts do not all improve.
No composite conceals these costs.

Scoring5 is a descriptive secondary intervention. Points/32 improve by
3.36 [2.29, 4.46] and 2.88 [1.91, 3.89] in pointwise 95% intervals. FG improves
3.91 [0.25, 7.60] and 1.93 [−1.29, 5.27] percentage points; the second range
does not resolve that efficiency effect. Mean-margin gains of +0.48/+0.39 have
intervals spanning zero. Family-level all20 scoring gains are guard +7.39/+5.73,
wing +6.38/+7.44 and big +4.84/+4.32 points/32. Family samples are eight
clusters each, and assist effects change sign in some families. Their full
intervals are descriptive, outside the fourteen primary comparisons.

### Current OVR versus observed basketball performance

The following are Pearson correlations with continuous raw current OVR.
Each cell is **overall → jointly demeaned within competition, position,
tactical role and rotation role**. These are descriptive associations,
including sparse whole-population bootstrap intervals in the aggregate.
They are not causal effects or new calibration verdicts.

| Population/range (observations; clusters) | Points/32 | FG fraction | Assists/100 touches | Turnovers/100 touches | Rebounds/32 |
| --- | --- | --- | --- | --- | --- |
| Catalog A (150; 10) | .447 → .294 | .352 → .284 | .426 → .164 | −.227 → .059 | −.171 → −.142 |
| Catalog B (150; 10) | .380 → .067 | .273 → −.014 | .482 → .135 | −.082 → −.082 | −.091 → .099 |
| Generated college A (40; 2) | .550 → .524 | .308 → .408 | .153 → .087 | −.207 → −.096 | .555 → .593 |
| Generated college B (40; 2) | .327 → .327 | .222 → .248 | .227 → .259 | −.183 → −.213 | .323 → .370 |

Catalog scoring and creation associations stay positive after joint adjustment
but weaken markedly. FG does not persist in range B, and turnover/rebounding
relationships change sign or remain weak. Within-competition catalog scoring
correlations remain positive (.118–.466 across the ten competition/range
strata); high-school B FG is −.094 despite a positive pooled FG relationship.
All five position strata have positive catalog scoring in A; center scoring
is −.169 in B. Thus a pooled cross-competition relationship cannot stand in
for within-position usefulness.

Generated college scoring and FG associations persist after joint adjustment,
but specific deployment strata differ: B PG FG is .591, C .037 and SF −.061.
Its PG steals/blocks association is −.022. Family-based role assignment makes
position and tactical role collinear here, so those strata cannot identify
separate position and role effects. Starter/rotation mean-minute bins also
coincide in these college samples. Only two source populations per range
produce discrete, sometimes deceptively narrow bootstrap intervals; these
are weak population evidence despite forty player observations.

Minute/opportunity stratification also matters. Catalog B FG is .317 for
20+ minute players (89 observations), .199 for 10–20 minutes (49), and −.003
below ten minutes (12). It is −.077 below ten touches/game (15 observations)
and .382 for 10–25 touches (120). College low-touch strata contain only two/one
players and have undefined correlations. College specialization has 22/23
derived-archetype strata; seventeen in each range have fewer than three
observations and undefined correlations. These are missing or sparse coverage,
not zero relationships. Catalog specialization has seven strata, one similarly
undefined. Every actual stratum and raw opportunity denominator is retained.

Opponent FG while the player is on court correlates positively with OVR in
catalog A/B (.540/.534), where higher competitions also have stronger opponents.
Joint associations are .476/−.061, and college is −.149/+.087 overall. This
lineup-dependent metric does not establish that better defenders permit more
shots or that the rating is incorrectly consumed. Direct resolution does not
read OVR; changing competition/opponents and deployment remains confounding.

### Investigated same-rating differences and inversions

The shared Builder reader validates 2368 complete confirmation games and
uses 2304 equal-resource primary games. It forms 576 source/context
observations, finding 1386 same-displayed-OVR pair instances and 3385
differing-OVR pair instances with at least one reversed observable. These
are dependent, descriptive pair counts, not independent samples, universal
rating violations or corrected significance claims. The eight cells and two
quartets provide 64 games per build/range. The concrete cases below preserve
the same counterpart, venue/opener seed, teammates and opponents within each
cell/quartet. Cross-cell role/lineup contrasts also change source caps; they
do not isolate deployment alone.

| Build (displayed OVR) | A points; FGM/FGA | B points; FGM/FGA | A/B points per32 | A/B eFG% | A/B TOV/100 touches | A/B rebounds per32 |
| --- | --- | --- | --- | --- | --- | --- |
| Balanced flat (48) | 362; 139/465 | 333; 135/424 | 9.32/8.90 | 33.01/34.67 | 8.48/8.10 | 9.88/9.44 |
| Perimeter offense (47) | 485; 181/533 | 552; 196/556 | 12.51/14.02 | 40.71/42.09 | 8.38/7.67 | 7.56/7.60 |
| Creation (47) | 302; 125/494 | 320; 126/493 | 7.63/7.98 | 27.33/27.48 | 5.19/4.83 | 6.94/7.38 |
| Large body (48) | 336; 136/398 | 320; 130/399 | 10.56/10.16 | 37.06/34.59 | 10.15/7.42 | 11.06/9.75 |

Perimeter offense and creation share displayed 47, body, tendencies, budget,
caps and deployment in each matched context. Their actual priorities differ:
the first A case buys midrange/three/FT at 70/74/70 versus creation's 35/35/35;
creation buys handling/passing/vision at 73/71/68 versus 35/35/35; offensive IQ
is 69 in both. The
scoring specialist converts more attempts and scores more, while creation
has fewer turnovers per touch. These measured strengths and weaknesses
explain why equal scalar summaries need not mean equal basketball utility.
First-case vectors are illustrative; full per-cell vectors and cap-dependent
allocation variations are retained, rather than assumed identical across cells.

The higher-rated balanced 48 loses scoring to perimeter 47 in both ranges,
but gains rebounds and steals/blocks (1.67/1.66 versus 1.11/1.12 per32).
This is a specialist's intended scoring trade-off, not an incorrect arithmetic
ordering or better results in every major observable.

Large and reference bodies both display 48, with all20 means 47.05 and raw
OVRs 47.5929/47.6283. The legal body adjustment also redistributes attributes:
large has OREB/block 46/47 rather than 45/45, speed 52 rather than 54 and stamina
53 rather than 54. Its height/weight/wingspan/reach are 78/210/85/107 versus
74/169/76/98. Body mechanics and these base adjustments remain bundled.
Large rebounds/blocks more per minute but plays 15.91/15.75 minutes versus
19.43/18.70, and its raw scoring is lower despite higher points/32. Five-foul
games are 25/30 versus 9/9; large's five-foul games average 13.08/13.20 minutes,
compared with 17.73/17.99 in its other games. This exposes foul/opportunity
effects behind the normalization inversion. Fifth-foul timing and targeted
body-only interventions are absent, so a unique causal attribution remains
unresolved. All body comparisons retain raw counts and ten tendencies.

A natural college example provides a different limitation. In B population
zero, seed 9940002's 70-OVR age-20 center and seed 9940001's 66-OVR age-19
center share the same team, four games, starter/interior-anchor deployment
and all-three tendencies. The higher player scores 44 versus 25 points
(16/27 versus 10/25 FG), but has 20 versus 27 rebounds and 5/54 versus 7/67
assists/touches. The higher player's twenty-attribute vector weakly exceeds
the lower vector throughout, including OREB/DREB 79/79 versus 69/77; its
rebound reversal cannot be explained by weaker rebound ratings. Mean
minutes are 23.71 versus 25.57; on-court defensive misses are 101 versus108,
and created made FGs are 6 versus10. Body/reach, age, prospect, opposing
matchup assignment and live opportunities differ; their original AP budgets
are intentionally unequal. This is not an equal-resource fairness comparison.
It investigates observed exposure and specialization differences without
claiming they fully explain a four-game, selected inversion. Causal attribution
and rating-formula inadequacy remain unproven.

[Selected case evidence](../analysis/ovr_truthfulness_followup/inversion_cases.json)
contains raw counts, context-specific summaries, source hashes and explicit
unavailable counters. Shared Builder lacks on-court opponent FGA/FGM/miss
counts; those are omitted, not asserted as zero. Its defender-attributed
attempt/make measures remain available separately.

### Current and potential population coverage

| Natural career-harness quantity | n | Min / median / max | Displayed 95+ | Displayed 99 |
| --- | ---: | --- | ---: | ---: |
| Freshman current | 2000 | 47 / 49 / 50 | 0 | 0 |
| Confirmed exact-cap potential | 2000 | 62 / 87 / 99 | 319 | 6 |
| Career peak current | 2000 | 62 / 77 / 94 | 0 | 0 |
| Career final current | 2000 | 61 / 77 / 94 | 0 | 0 |

Every retained start, exact-cap, college, peak and final vector agrees with
the independent arithmetic oracle. Ordinary generated freshmen never begin
at 99 in these samples; potential 99 is an exact-cap ceiling rather than an
automatic current rating or attainment promise. Peak/final raw vectors exist
and were actually captured. All-season scalar age/phase distributions are
available, but all-season raw vectors are not captured by the career harness.
None of these distributions certifies a mature-world rarity target.

The fixture current min/median/max values, with 1170 records per competition,
are high school 49/61/73, college 55/67/79, development 62/73/84, overseas
64/75/86 and top domestic 68/79/90. Exact caps/ages are absent there, so fixture
potential and lifecycle guardrails are untested. No freshman-versus-professional
match transplant was used.

## Instrument verification

The focused GdUnit suite is 14/14 green before and after five actual-source
mutations. Each mutation reaches its intended named assertion with zero
runtime errors: formula offset, floor replacing half rounding, wrong exact-cap
potential, repeated gameplay seed, and shifted touch denominator. Crashes,
parse failures and the separate expected owner probe do not count as kills.

The Node analyzer suite has 31 coverage/statistical known-answer cases:
pooled ratios, zero denominators, determinism, matched dependence,
14-comparison interval widening, coherently shifted archives, absent control
hashes, slot domains, complete twenty-player catalog/college games, corrected
pairing, natural career ranges/body provenance, both histogram populations,
duplicates/coverage, natural peak/final vector oracles, actual shared Builder
consumption and absent-counter/real-layout presentation. Twelve actual-source
analyzer mutations require intended semantic assertion failures and clean
31-case suites before/after each. A histogram witness corrupts both ranges
identically so a removed oracle guard must actually admit the bad artifact;
an across-range mismatch is not substituted for that proof. Mutation records
retain exact source and log hashes.

Independent criticism also executed 70,807 OVR archive checks with zero
failures, using a separate standard-library Python implementation driven by
the retained Node archive audit. It imports no OVR analyzer and reproduces
all fourteen primary effect/interval pairs, pooled numerators/denominators,
overall/stratum/joint relationships, literal AP/formula oracles and population
histograms. This count measures assertions, not additional test cases or
independent samples. Its 81,533 Builder assertions are reported separately.

A post-collection reporting correction removed fabricated zero counters for
shared Builder fields absent from its archive. The added known-answer layout
test and actual erasure mutation verify that unknown is not observed zero.
[Correction evidence](../analysis/ovr_truthfulness_followup/reporting_correction_evidence.json)
retains before/after aggregate hashes and deep equality of all within-player,
catalog/college, histogram and primary-method sections, and unchanged Builder
pair counts/context correlations. The final analyzer SHA-256 is
`5b41d2cfdf3ac578d421569dd98a1a0fdbabffa949a26b8e662f77ac8c797424`.
No estimator, fixed comparison, sample, GDScript or production source changed.

## Reproduction and retained artifacts

Run from the repository root with Godot 4.7.1 and Node 24.13.1; no Node package
installation is required. A single confirmation process at a time avoids
contention while other Stage 4 measurements/gates are active.

```powershell
$godot = 'C:\Users\valexander\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$node = 'C:\nvm4w\nodejs\node.exe'
& $godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/calibration/test_ovr_truthfulness_audit.gd -c
& $node tests/tooling/test_ovr_truthfulness_analysis.cjs
& $node tools/run_ovr_truthfulness_mutations.cjs $godot
& $node tools/run_ovr_analysis_mutations.cjs
& $godot --headless --path . --script res://calibration/runners/run_ovr_truthfulness_followup.gd -- --range=A --label=A --mode=all
& $godot --headless --path . --script res://calibration/runners/run_ovr_truthfulness_followup.gd -- --range=B --label=B --mode=all
& $node analysis/ovr_truthfulness_followup/analyze.cjs reports analysis/ovr_truthfulness_followup/aggregate.json reports/builder_followup/validation_a.ndjson reports/builder_followup/validation_b.ndjson
$python = 'C:\Users\valexander\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $node analysis/stage4_blocker_review/independent_archive_audit.cjs $python analysis/stage4_blocker_review/independent_archive_audit_results.json --with-ovr
```

The selected inversion tables are descriptive extracts, not another search or
confirmatory experiment. After the complete verifier above, reproduce their
pooled counts and opportunity diagnostics directly from the same raw files:

```powershell
@'
const fs = require('fs');
const A = require('./analysis/ovr_truthfulness_followup/analyze.cjs');
const read = p => fs.readFileSync(p, 'utf8').trim().split(/\r?\n/).map(JSON.parse);
const builds = ['balanced_flat','perimeter_offense','creation','body_small','body_large'];
for (const range of ['a','b']) {
  const rows = read('reports/builder_followup/validation_'+range+'.ndjson');
  for (const id of builds) {
    const rr = rows.filter(r => r.primary && r.build_id === id);
    const mapped = rr.map(r => ({...r, team_score:r.team_points,
      opponent_score:r.opponent_points, won:r.team_win,
      current_ovr:r.build.current_overall, raw_ovr:A.oracle(r.build.ratings).raw}));
    const raw = A.totals(mapped);
    const unavailable = A.COUNTS.filter(k => mapped.some(r => !Object.hasOwn(r,k)));
    for (const k of unavailable) delete raw[k];
    const metrics = A.metrics(raw); delete metrics.opponent_field_goal_fraction_on_court;
    console.log(JSON.stringify({range,id,raw,metrics,unavailable,
      five_foul_games:rr.filter(r => r.personal_fouls >= 5).length}));
  }
}
for (const range of ['A','B']) {
  const rows = read('reports/ovr_within_'+range+'.ndjson');
  for (const arm of [...new Set(rows.map(r => r.arm))]) {
    const rr = rows.filter(r => r.arm === arm);
    console.log(JSON.stringify({range,arm,raw:A.totals(rr),
      five_foul_games:rr.filter(r => r.personal_fouls >= 5).length}));
  }
}
const college = read('reports/ovr_college_B.ndjson');
for (const id of ['college_0_p1','college_0_p0']) {
  const rr = college.filter(r => r.cluster === 0 && r.player_id === id);
  console.log(JSON.stringify({id,raw:A.totals(rr),metrics:A.metrics(A.totals(rr))}));
}
'@ | & $node -
```

Raw NDJSON/histogram output and bulky logs remain in ignored `reports/` or
ignored `*.log` files. Checked-in aggregates, run manifests, source/log hashes,
mutation summaries and this documentation carry the reproducible handoff.
The 36-game `--range=smoke --mode=within --clusters=1 --label=smoke` run only
validated instruments; it is excluded from all confirmation estimates.

## Coverage limits and next action

The finite portfolio and samples cannot prove every legal build is fair or
every higher OVR player wins every matchup. Role-neutral OVR is truthful as an
arithmetic summary; basketball usefulness must be judged against its measured
attributes/deployment/role constraints. The existing owner cap-order conflict
must be resolved explicitly. No weights, ratings or simulation consumption
are tuned from these outcomes.

Natural career model start/cap/college/peak/final distributions are available,
but contemporaneous mature-world rosters, lifecycle survival/selection,
stable top-domestic seasonal 95+/93+/90+ rarity, recruited/draft medians,
injury-cap-loss prevalence, natural top-domestic age/role match performance,
and full save-adapter behavior remain untested. Potential is a ceiling summary,
not an attainment guarantee. Green arithmetic tests and small samples cannot
close statistical certification blockers. Nightly/deep infrastructure proof
and §27.1 remain subsequent work under the consolidated dependency queue.
