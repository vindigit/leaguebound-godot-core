# Stage 4: legal Builder diversity and dominance evidence

This bounded, reproducible report delivers 2,368 games on two untouched
confirmation ranges, plus a 176-game exploratory instrument run, for
`BALANCE_SPEC.md` §31 report 3, §12.4 and §28. The portfolio shows observable
specialist trade-offs; universal dominance acceptance remains inconclusive.
Production behavior, economics, targets, tolerances and golden ledgers are
unchanged. This is not §27.1 certification, and Stage 4 remains incomplete.

## Authority, baseline and population

The follow-up starts from the verified basketball/player implementation at
`899a3972e48e8ce63de07b47b2e593e9c97df4d2`. The executable protocol was
committed at `51a115e` before retained confirmation outcomes. Instrument,
protocol and production hashes, actual execution HEAD, Godot and random-stream
versions travel with each range's metadata. The report runs through
`MatchSession` directly and never uses a game-result cache.

The current competition fixture authority is
`competition-catalog-v4-roster-pairing`. Its roster generator, corrected
population pairing, targets and canonical judgments are untouched. Historical
pre-v4 outcome measurements are not a current fairness baseline. Existing
high-school calibration rosters describe an entire high-school competition,
not entering freshmen. The primary experiment therefore builds **every
participant** as a legal age-14 freshman rather than placing a freshman into
an older or professional roster.

The new controlled freshman cohort maps the corrected catalog's roster-state
identities onto reproducible freshman career seeds. It preserves ABBA venue
and opener crossover, but it is a new freshman experimental population, not
the canonical competition team-stat calibration population. Small schedule
slices do not cover the catalog's complete 54,756-fixture Cartesian cycle.

## Actual construction constraints and sampled legal space

`BuilderService.begin_build` draws exact caps and the projected adult body
range. Allocation uses `BuilderState.raise_attribute`, or its existing
weighted allocation helpers, and always ends in `BuilderService.confirm`.
No attribute is edited to manufacture a supposedly comparable experimental
player. Team-role assignment is supplied when projecting a confirmed player
into a match snapshot, as the existing simulation contract permits.

| Construction fact | Current implementation and locked limit |
| --- | --- |
| Creation AP | Ready Now 235; Balanced 195; High Upside 155. Creation AP fully spent; career AP wallet zero. |
| Destination cost | 1 through rating 59, 2 through 69, 3 through 79, 5 through 89, 8 through 94, 12 through 99; identical for every attribute and executor. |
| Initial bases | 14 attributes at 35, IQ ratings at 38, four physical ratings at 45, then one body redistribution. |
| Body redistribution | At most 18 absolute rating points, at most 4 on one attribute, total signed adjustment within the implementation's one-point approximately-zero-sum tolerance. |
| Starting ratings | At least body-adjusted base and 25, soft maximum 70 reported rather than prohibited, absolute maximum 75 and exact cap enforced before spending. |
| Exact caps | 20 immutable generation caps in 40–99, including body incompatibility, family emphasis, profile offsets, selection pressure and clipped noise. User-style freshman construction uses selection pool one. |
| Height | Guard 66–74 in; Wing 70–78; Big 74–82. |
| Weight | Rounded `160 + 4.6 × (height − 72)` pounds, selectable margin ±22 within global credible bounds. |
| Wingspan | Height −2 through height +7 inches. |
| Standing reach | `BodyProfile` requires reach strictly greater than height. Fixtures use rounded `0.585 × height + 0.720 × wingspan`. Confirmation constructs `BodyMaturationState`, whose intermediate-containment check forbids reach above the stored projected adult maximum; final adult containment applies later. Direct non-default reach overrides are untested. |
| Maturity | Early/Average/Late alter maturation schedule. This match portfolio fixes Average and does not measure future maturation fairness. |
| Tendencies | Ten integer sliders, each 1–5: `5^10 = 9,765,625` discrete vectors before other choices. Neutral and two extreme vectors sampled. |
| Tactical/rotation roles | 11 tactical opportunity vectors and seven rotation intents exist. Subjects use Starter intent, and two tactical roles; legal off-role deployment is not repaired by the fixture. |
| Existing allocations | Stage 2 runner has conventional, flat, scoring, defensive, incompatible and extreme-specialist strategies plus seeded randomization. This portfolio adds explicit hybrids, physical specialists, body/tendency interventions and exploit-seeking priorities. |

The independent fixture validator uses literal destination-cost bands and
locked AP/domain/body/starting-max/exhaustion limits. It separately reconstructs
seeded immutable bases/caps without allocation or its validator, and compares
them to archived facts. This is an independent legality check and deterministic
replay, **not** a second independently implemented CapGenerator. A corrupt
record must fail with its intended reason rather than assert/crash inside
production construction.

The 18 primary wings all receive Balanced's 195 AP. The portfolio includes
flat balance; perimeter/finishing offense; creation; perimeter/rim defense;
rebounding; speed/strength physical builds; three-and-defense and
creator-defender hybrids; three/handle, IQ-only and cheapest-point exploit
searches; short/light/short-span and tall/heavy/long-span flat bodies; and
two tendency interventions over exactly the same balanced attributes/caps.
Focus attribute indices and deterministic fill order are executable in
`BuilderDominanceFixtures.portfolio` and archived in every build manifest.

| Arm | Weighted priorities or intervention |
| --- | --- |
| `balanced_flat` | Equalize rating increases over body-adjusted bases. |
| `perimeter_offense` | Mid-range, three-point, free throw, offensive IQ. |
| `finishing_offense` | Short range, dunking, speed, vertical. |
| `creation` | Handle, passing, vision, offensive IQ. |
| `perimeter_defense` | Perimeter defense, stealing, defensive IQ, speed. |
| `rim_defense` | Interior defense, blocking, defensive IQ, strength. |
| `rebounding` | Offensive/defensive rebounding, strength, vertical. |
| `speed_physical` | Speed, stamina, vertical. |
| `strength_physical` | Strength, stamina, vertical. |
| `three_and_defense` | Three-point, perimeter defense, stealing, defensive IQ. |
| `creator_defender` | Handle, passing, vision, perimeter defense, defensive IQ. |
| `exploit_three_handle` | Three-point, handle, speed. |
| `exploit_iq_only` | Offensive and defensive IQ. |
| `exploit_low_cost` | Minimize `100 × next-point cost + current rating`. |
| `body_small` / `body_large` | Flat spending at `(height, weight, span, reach)` = `(70,129,68,90)` / `(78,210,85,107)`, versus reference `(74,169,76,98)`. |
| `tendency_score` / `tendency_defense` | Identical reference attributes, caps, body, AP and role, with vectors `[5,5,1,1,5,5,5,1,5,5]` / `[1,1,5,5,1,1,1,5,1,1]`. Names identify interventions, not optimal tactics. |

Tendency vector order follows `SIMULATION_SPEC.md` §10.4: pass/score, patient/aggressive,
perimeter/interior, own-shot/off-ball, safe/creative passing, push/control tempo,
disciplined/gamble, attached/help, box-out/chase, and defer/seek clutch. All other
arms use `[3,3,3,3,3,3,3,3,3,3]`. The legal body arms also change body-adjusted
attributes and cap compatibility; their effects are bundled legal body effects,
not dimension-only causal comparisons.

Weighted focus spending respects caps/costs and spills residual AP through the
real Builder's cheapest legal fill. Flat spending equalizes increases over
body-adjusted bases; cheapest-point spending instead favors inexpensive low
current ratings. These are distinct legal allocation rules, not hand-created
rating vectors.

Two separate profile arms use the same flat policy with Ready Now/High Upside
budgets; they are **unequal-resource profile observations**. Separate balanced
guard/big arms change family, body, position slot and deployment together.
Neither set belongs in the primary equal-resource wing fairness inference.
Freshman match results do not establish long-term prospect profile fairness.

Current cap anchor centers are 81/85/88 for Ready Now/Balanced/High Upside,
with deviations 7/8/9 and anchor hard ranges 58–92/58–96/58–99. These are
anchors, not Potential OVR. §8.1 already discloses their change from older
75/79/83 baselines. Future opportunity remains intentionally different:
Ready Now uses 115%/90%/80% HS/college/pro availability, Balanced 100%, and
High Upside 85%/115%/120%. A freshman match comparison cannot price that
future opportunity.

## Frozen experiment and uncertainty

The committed protocol is
[`analysis/builder_dominance_followup/protocol.json`](../analysis/builder_dominance_followup/protocol.json).
Eight full-factorial contexts cross utility/shooter role, balanced/spacing
teammates, and perimeter/rim-oriented opposing allocations. Roles and lineup
contexts remain fixed within every comparison. Teammate and opponent signatures,
subject slot, career seeds, match identity, simulation seeds, chemistry,
condition, badges and home environment are controlled. Attributed performance
differences are build interventions within these cells; pooled results average
this selected deployment mix rather than establish a context-free quality rank.

The source roster identities and resulting career seeds/caps also vary between
cells because the fixture variation includes `1000 × cell`. Cross-cell changes
therefore combine role, lineup and opponent changes with different selected
players and rosters. Context interactions are descriptive selected-cell
differences, not a same-player deployment crossover or an isolated causal role,
lineup or matchup effect. The within-cell build comparisons retain their matched
controls. A same-player deployment crossover remains missing coverage.

Each quartet has subject/opponent orientation AB, BA, BA, AB. The subject
opens in phases 0 and 1; its opponent opens in phases 2 and 3. Thus each actual
subject plays home/away and opens/does not open once in every combination.
Every build sees the same seeds, roster identities and match identity.

| Range | Seed starts by cell | Primary games | Separate profile/family games |
| --- | --- | ---: | ---: |
| Exploration | 61,000,001 through 61,000,008, cell 0 | 144 | 32 |
| Untouched validation A | 71,000,001 + `1000 × cell`, eight seeds/cell | 1,152 | 32 |
| Untouched validation B | 81,000,001 + `1000 × cell`, eight seeds/cell | 1,152 | 32 |

Seeds are deliberately reused across matched builds; they are unique within a
build/range. The raw-data validator rejects duplicate rows, duplicate seeds
within a build, omitted contexts or quartet phases, venue/opener imbalance,
unequal primary AP/family, and changed controls. Exploration does not select
builds, settings, sample sizes or acceptance bands. Both confirmation ranges
remain untouched until the source and protocol freeze.

The 17 primary contrasts are each build versus `balanced_flat`, pooled over
eight contexts. Eleven separately reported observables cover eFG; points per
32 minutes; creation per 100 touches; turnovers per 100 touches; steals and
blocks per 100 on-court defensive possessions; offensive/defensive rebounds
per 100 offensive/defensive possessions; advantages per 100 touches; team
margin per game; and allowed eFG on attempts naming the subject as primary
defender. Raw numerators and denominators accompany every rate. Additional
counts expose assists, completed passes, screens, minutes, attempts, free throws,
plus/minus, team wins, and start-versus-terminal on-court possession exposure.

The attempt denominator follows the repository's current ledger convention,
which records missed shooting-foul attempts as field-goal attempts. Both
shooting and allowed eFG inherit that convention; free-throw attempts/makes
are retained explicitly. Different build foul opportunities can therefore
change the basketball meaning of an efficiency contrast even when its replay
and arithmetic are correct. The separate denominator audit recorded in
`PROJECT_STATUS.md` §5.39 remains open. This is a reporting limitation, not an
enacted change to shooting or foul accounting. On-court possession rates describe
exposure at the start of a possession; entering or leaving during it can
differ from terminal exposure. Raw terminal counts and minutes expose that
difference. Primary-defender eFG describes attributed shots, not all help
defense or a causal isolated contest-skill estimate.

Ratios divide summed numerators by summed denominators. A quartet's ratio
influence is `(N_j − R D_j) / mean(D_j)`, scaled into the metric's units.
Matched influence differences preserve covariance across builds. Student-t
intervals summarize the 16 selected quartets per build/range; events, shots,
player statistics and individual games are not treated as independent samples.
Bonferroni simultaneous intervals cover **374** predeclared contrasts
(`17 × 11 × 2 ranges`). Ordinary 95% intervals are also labeled exploratory.
Fewer than eight quartets or zero empirical variance yields an unavailable
interval. Cell-level n=2 evidence and profile/family n=2 evidence have no
inferential verdict. Sparse numerator support is flagged separately.

These small-sample intervals are conditional, approximate evidence about the
fixed roster/context schedule and repeatedly used generated players. They do
not establish random-population or mature-world coverage. Context heterogeneity
and sparse specialist opportunities further limit the approximation.

There is no locked numerical minimum practical effect for between-build
dominance. Effects are retained in native units and count equivalents per
32 minutes/100 opportunities. Practical importance remains unclassified;
positive simultaneous bounds alone are not called meaningful superiority.
No new tolerance or composite performance score is introduced.

The eleven-metric Pareto frontier is descriptive over this finite portfolio.
Turnovers and allowed eFG have favorable negative directions. Specialist
advantages and weaknesses remain separate columns. Broad superiority versus
the balanced reference would require every favorable simultaneous bound in
each range; a universal §28 violation additionally needs all relevant builds,
roles, lineups, matchups and meaningful effects. This sample cannot establish
that standard or its absence.

## Confirmatory measurements

Both ranges completed on execution HEAD
`07789d28f277a474ebec7df83d52c0564d0dbba0`: A at `2026-10-01T04:04:04Z`,
B at `2026-10-01T04:04:20Z`. Each contains 1,184 games: 64 per primary arm
(16 matched quartets across eight cells), and eight per separate profile/family
arm. Every range has zero instrument errors; all 147 instrument/production
fingerprints match before/after collection and the retained source. Runtime is
61.24/61.51 minutes, including construction, event measurement and concurrent
local gate work; it is not a portable engine throughput benchmark.

Versions are `builder-dominance-fixtures-v1`, `builder-dominance-audit-v1`,
`builder-dominance-analysis-v1`, `competition-catalog-v4-roster-pairing`,
`simulation-v17-stopped-foul-clock-and-live-rebound`,
`competition-v2-stopped-clock-pace`, `ratings-v1`, and `godot-pcg32-v1`.
The seed intervals are 71,000,001–71,000,008 and 81,000,001–81,000,008 in
cell 0, plus `1000 × cell` in cells 1–7. There are 64 distinct matched
simulation seeds per range, deliberately repeated across builds.

The full [aggregate evidence](../analysis/builder_dominance_followup/summary.json)
retains every raw counter, all 22 normalized metrics, per-cell measurements,
all 374 primary effects/intervals, and 306 descriptive pairwise records.
The generated [measurement tables](../analysis/builder_dominance_followup/MEASUREMENTS.md)
show all 18 primary arms' eleven observables and raw minutes, shooting counts,
free throws, touches, possession exposures and defended attempts side by side.
The separate profiles use their common cell-0 reference, not the pooled primary
reference. Full precision remains in the JSON.

An independent critic recomputed 81,533 checks over all 2,368 actual rows,
592 distinct arm/source draws, immutable facts, literal economics, ledger
counts/opportunities, paired uncertainty, directions and frontier arithmetic,
with zero failures. These are instrument/data checks, not evidence of statistical
calibration or independent-player population sample size.
The separate calculator also verifies both ordinary/simultaneous Student-t
endpoints using an independent analytic odd-degree method, and independently
parses all 69 table rows/414 displayed cells back against the aggregates.
Its [standalone source](../analysis/stage4_blocker_review/independent_archive_audit.cjs)
and [retained proof](../analysis/stage4_blocker_review/independent_archive_audit_results.json)
provide a reproducible second implementation without importing the analyzer.

### Specialist gains, weaknesses and uncertainty

The table gives the arm-minus-balanced effect and its Bonferroni simultaneous
interval in native units. Positive turnover differences are unfavorable.
Each contrast has 64 games per arm and 16 matched quartet clusters per range.
No effect is called practically meaningful without an applicable locked minimum.

| Arm and observable | Validation A effect [interval] | Validation B effect [interval] |
| --- | --- | --- |
| Perimeter offense: points /32 min | +3.20 [−1.36, 7.76] | +5.12 [−0.18, 10.42] |
| Its defensive rebounds /100 def possessions | −2.86 [−5.56, −0.15] | −2.38 [−5.01, 0.24] |
| Creation: turnovers /100 touches | −3.30 [−6.88, 0.29] | −3.27 [−7.89, 1.35] |
| Its defensive rebounds /100 def possessions | −3.62 [−7.09, −0.15] | −2.76 [−6.07, 0.54] |
| Rim defense: blocks /100 def possessions | +2.23 [0.43, 4.04] | +2.16 [0.34, 3.98], sparse reference |
| Its points /32 min | −2.34 [−6.03, 1.36] | −1.96 [−6.84, 2.91] |
| Rebounding: defensive rebounds /100 def possessions | +4.17 [2.11, 6.22] | +4.21 [0.55, 7.87] |
| Its turnovers /100 touches | +2.46 [−2.31, 7.23] | +1.73 [−2.16, 5.62] |

Perimeter offense's observed eFG is 40.71%/42.09%, versus 33.01%/34.67%
for flat balance; it creates fewer made field goals per 100 touches
(5.56/4.87 versus 6.93/7.55) and collects fewer defensive rebounds. The
creation arm has lower observed turnover rates (5.19/4.83 versus 8.48/8.10)
and lower scoring (7.63/7.98 versus 9.32/8.90 points per 32 minutes).
These persistent point-estimate trade-offs do not become simultaneous
confirmatory wins where the intervals cross zero.

Within the selected cells, perimeter-offense scoring and rim-defense blocks
have favorable point estimates in all eight cells in both ranges. Rebounding
has higher defensive-rebound point estimates in eight cells in A and seven
in B; B's utility/balanced-teammate/rim-opponent cell reverses by −1.90 per
100 defensive possessions. Creation lowers turnover point estimates in seven
cells in each range, with a different reversal cell. These are descriptive
within-cell intervention contrasts; n=2 forbids individual-cell confidence
claims, and between-cell source changes forbid a pure deployment explanation.

Rebounding's defensive-rebound increase has favorable simultaneous bounds in
both ranges without sparse-event flags. Its scoring is lower and turnovers
higher at the point estimates, with uncertainty spanning zero. Rim defense's
block difference has positive simultaneous bounds in both ranges, but the B
reference records only seven blocks and nonzero blocks in fewer than eight
quartets; its sparse-support warning prevents an unqualified inferential verdict.
There are 12 sparse-event flags in A and 17 in B, each among 187 primary contrasts.
All 374 intervals are numerically available; event support still limits their
interpretation. Individual matchup cells have only two quartets, so an intended
matchup win remains descriptive rather than statistically established.

All 18 arms lie on the **observed finite-portfolio** eleven-metric Pareto frontier
in each range. None of the 153 pairwise mean comparisons in either range has
one arm favorable on all eleven metrics. No arm has favorable simultaneous
bounds on all eleven observables versus flat balance in either range. Thus
there is no demonstrated broadly superior reference comparison or §28
every-observable violation here. This is not a no-dominance pass: sampling noise,
unclassified practical relevance, n=2 cells, fixed selected cohorts and the
untested legal space prevent that conclusion.

The exploit-seeking allocations also expose disadvantages. Cheapest-point
spending averages 8.05/8.34 points per 32 minutes versus 9.32/8.90, and only
15.41/14.92 minutes per game. It reaches five personal fouls in 38/32 games,
versus 9/9 for flat balance. Three/handle has higher scoring point estimates
(11.03/10.78), but only one/zero total blocks versus 20/seven and mixed creation
rates (7.35/5.79 versus 6.93/7.55 per 100 touches). IQ-only's eFG difference
shrinks from +8.32 percentage points in A to +0.61 in B; its defensive-rebound
rates are lower in both. None is a demonstrated broad outperformer.

### Body, tendencies and the separate body OVR guard

| Flat legal body | Displayed current OVR, both ranges | Raw current OVR, both ranges | Raw change vs reference | Mean of all 20 ratings |
| --- | ---: | ---: | ---: | ---: |
| Reference `(74,169,76,98)` | 48 | 47.6283333 | — | 47.05 |
| Small `(70,129,68,90)` | 48 | 47.6825000 | +0.0541667 | 47.05 |
| Large `(78,210,85,107)` | 48 | 47.5929167 | −0.0354167 | 47.05 |

The body policies exhaust the same 195 AP, while reallocating 18 absolute,
zero-sum starting points. Small-body current changes include handle/speed +2,
interior defense/blocking −2 and rebounding −1; the large-body changes reverse
these. Per-attribute magnitudes are at most two in these three sampled bodies.
Small-body caps equal the reference caps in every matched draw. Large-body
compatibility raises interior-defense caps by 4–16 in A/3–16 in B and blocking
caps by 4–18 in A/6–16 in B; the other caps are identical. This is a bundled legal
body/base/allocation/cap effect, not an isolated dimensions-only effect.

Large-body points per 32 minutes are higher (10.56/10.16 versus 9.32/8.90),
but the raw volume and availability are lower: 336/320 points in 64 games,
versus 362/333, and 15.91/15.75 minutes per game versus 19.43/18.70. It
records 243/246 personal fouls and 25/30 games reaching the high-school
five-foul limit, versus 167/159 fouls and 9/9 such games for the reference.
The existing engine removes players at that limit and also protects foul
trouble; this is an observed availability disadvantage consistent with that
mechanism. The counts alone do not attribute every minute difference solely
to foul-outs. Primary-defender eFG also excludes the opponent's free throws and
inherits the missed-foul FGA convention, so a foul-heavy body cannot be judged
by that efficiency rate alone.

Small-body points per 32 minutes are lower by 1.62/2.11, with simultaneous
intervals [−4.68, 1.45]/[−6.99, 2.78]. The large-body normalized point gains
are +1.24/+1.26, with intervals [−3.23, 5.71]/[−1.63, 4.15]. Neither is a
demonstrated universal body advantage. Separately, §7.4's systematic body OVR
guard remains **unverified**: the selected flat-body draws have equal displayed
OVR but unequal raw OVR, including a consistent small-body raw increase. No
new numerical tolerance is used to call that guard passed, and these three
derived-reach policies cannot establish the entire legal body/allocation space.

Tendency-only arms preserve every construction fact. The score vector's
observed scoring difference changes sign: −0.31/+1.47 points per 32 minutes,
with intervals [−3.55, 2.93]/[−2.90, 5.83]. It also has lower defensive
rebounding point estimates by 1.42/2.05. The defense vector's advantage rate
changes by +6.39/+0.97 per 100 touches, with intervals [−3.78, 16.57]/
[−12.72, 14.65], while its scoring is lower by 1.22/0.86. None proves one
tendency vector dominates every role or lineup; two vectors and two roles
provide very limited coverage of that separate §28 blocker.

### Creation budgets and profile distributions

Every one of the 296 arm/source draws per range exhausts its creation AP.
Across 592 distinct draws, completed Current OVR is 46–50, and the observed
maximum is 50 against the approximately-54 ceiling. Using the existing Stage 2
operational label of at most six raised attributes gives 382 extreme and 210
ordinary draws; this is a disclosed portfolio label, not a new acceptance rule.

| Prospect profile | A selected draw histogram | B selected draw histogram | Locked completed band |
| --- | --- | --- | --- |
| Balanced, including separate family arms | 46:105, 47:101, 48:86 | 46:108, 47:98, 48:86 | 46–50 |
| Ready Now | 50:2 | 50:2 | 48–52 |
| High Upside | 46:2 | 46:2 | 44–48 |

The observed bands and budget constraints hold for these selected constructions.
They are not the §27.1 portfolio-distribution sample or mature-world rarity
evidence. Ready Now/High Upside comparisons have only two quartets in cell 0,
unequal starting resources and no inferential intervals. For example Ready Now
averages 10.50/7.67 points per 32 minutes versus High Upside 7.91/6.91, but
has fewer minutes and more five-foul games (3/6 of eight versus 0/0). Those
descriptive freshman outcomes price neither future opportunity nor career value.

## Instrument validation and execution record

The focused suite passes 10/10 GdUnit cases before and after deliberate mutations,
including actual legal construction, immutable fact replay, control signatures,
all eight contexts, deliberate corruption witnesses, and exact fresh-game
determinism. Ten independent standard-library Python tests pass aggregation,
known Student-t quantiles, matched covariance, multiplicity, schedule coverage,
denominator corruption, tendency-only controls and profile separation.
The construction test independently checks all 22 arms at three career seeds
(66 confirmed states), including exact bases/caps, age 14, exhausted creation
budgets and a zero career point-ledger balance. Raw match manifests retain the
creation budget history; the zero career ledger is checked on the actual
confirmed states in this focused suite and follows the shared confirmation path.

The retained exploratory archive contains 176 games, all 22 arms and eight
matched seeds in cell 0, with zero instrument reconciliation errors. Its raw
SHA-256 is `cb6f1db8c28cb4c12b96f2037d88976dd2c71f1c9344105d21512665215c7cf4`.
An independent critic reconciled every actual row's literal AP costs, body
redistribution/domain limits, seeded facts, rational current/cap OVR, ledger
counts, opportunities and controlled schedule. All 44 distinct arm/source
draws exhaust their creation budgets; observed completed OVR is 46–50. Ready
Now is 50, Balanced 46–48, and High Upside 46, inside their respective locked
bands for this selected portfolio. This is not a population target certification.
Each exploratory arm has only two quartet clusters, so all inferential intervals
are unavailable. All 18 primary arms appear on the descriptive eleven-observable
frontier; this noisy finite sample establishes no absence of dominance and makes
no meaningful-specialist verdict. No candidate or allocation changed after these
outcomes.

The source mutation runner operates in an isolated temporary project; it
requires clean focused suites before and after. A parser error, runtime crash,
wrong test count, missing summary, or unrelated failure is rejected. Final
results record each intended assertion kill, commands, source hashes and logs.

The final isolated run kills all **14** deliberate instrument mutations:
eight remove AP-spend, seeded-cap, standing-reach, duplicate-seed,
quartet-completeness, venue/opener, defended-attempt or touch-ledger safeguards;
six change ratio aggregation, turnover direction, two-range multiplicity,
venue/opener validation, tendency-only facts or uncertainty dependence. Named
assertions kill each mutant with no parser/runtime errors. The clean restored
GdUnit and Python suites both pass 10/10. The original duplicate-guard Python
mutation was rejected because a redundant seed guard still protected the input;
the accepted venue/opener mutant makes the intended assert-not-raised witness
fail. This is assertion sensitivity, not a claim that these mutations exhaust
every possible instrument defect.

The retained proof is
[`mutations/results.json`](../analysis/builder_dominance_followup/mutations/results.json)
with the isolated-source hashes and execution commands in the committed driver.
An explicitly recorded trailing-whitespace-only Python test cleanup follows
that run; token comparison and a final clean 10/10 Python suite pass are recorded
in [`whitespace_cleanup.json`](../analysis/builder_dominance_followup/whitespace_cleanup.json).

An initial exploratory execution completed its 144 primary games and then
failed at the first secondary arm because the runner's conditional expression
returned an untyped `[0]` into `Array[int]`. The incomplete execution is rejected,
and its error/source-hash disposition is retained in
`failed_exploration_execution.json`. Its full redirected log and partial raw
archive were overwritten by the same-protocol clean rerun, and are not claimed
as retained measurements. The corrected typed cell-selection helper has
focused primary/secondary coverage. No confirmation outcome preceded the fix.

## Reproduce and inspect

Godot is pinned to 4.7.1-stable. Import once before running scripts; execute
independent processes for disjoint ranges if desired.

```powershell
& $Godot --headless --path . --import
& $Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/calibration/test_builder_dominance_followup.gd -c
& $Python analysis/builder_dominance_followup/test_analysis.py
node tools/run_builder_dominance_mutations.cjs $Godot $Python
& $Godot --headless --path . --script res://calibration/runners/run_builder_dominance_followup.gd -- --range=exploration --out=res://reports/builder_followup
& $Godot --headless --path . --script res://calibration/runners/run_builder_dominance_followup.gd -- --range=validation_a --out=res://reports/builder_followup
& $Godot --headless --path . --script res://calibration/runners/run_builder_dominance_followup.gd -- --range=validation_b --out=res://reports/builder_followup
& $Python analysis/builder_dominance_followup/analyze.py reports/builder_followup --output analysis/builder_dominance_followup/summary.json
& $Python analysis/builder_dominance_followup/render_tables.py
node analysis/stage4_blocker_review/independent_archive_audit.cjs $Python analysis/stage4_blocker_review/independent_archive_audit_results.json
```

`$Godot` and `$Python` mean absolute executable paths supplied by the caller;
Python 3 uses only its standard library, and the mutation driver uses Node's
standard library. Bulky NDJSON remains under ignored `reports/`; committed
metadata, hashes, compact aggregate evidence and definitions preserve replay.
An interrupted run cannot pass the aggregate validator.

The measured local runtimes are Godot `4.7.1.stable.official.a13da4feb`, Python
3.12.14 and Node 24.13.1. Local Python comes from the app's bundled runtime;
ordinary Python 3 installations require no package installation for this tool.

## Remaining blockers and next action

Builder report tooling and finite-portfolio evidence do not close §12.4/§28
universal dominance acceptance or full calibration. Increase independent legal
freshman population and opportunity coverage, including other tactical roles,
families, body/reach selections, tendencies and cap-limited realizations, under
a newly predeclared subsequent protocol. Maturation and long-term profile
trade-offs require lifecycle evidence. Higher competitions require genuine
development/selection construction before extending the starting-build claim.
The nightly/deep infrastructure proof and §27.1 certification remain subsequent
work; Stage 4 and Gate 0 remain incomplete.
