# Stage 4 owner decision — the college field-goal row

**Status: measurement and decision package. Nothing here is enacted.**
No production value, locked target, ruleset, or golden was changed to produce it.

| | |
| --- | --- |
| Branch / head | `stage4-calibration` |
| Supersedes nothing | Extends `PROJECT_STATUS.md` §5.22, which opened this decision |
| Classification | **Structural** where it describes what the code contains; **measured, not certified** where it reports a number. No figure here reaches the §27.1 sample |
| Decision owner | Project owner. This document does not choose |

---

## 1. The question, stated precisely

§5.22 established that college field-goal percentage misses its §14.1 floor
repeatably, that no production hypothesis survives counterfactual measurement,
and that the shortfall follows the **roster** rather than the rule profile. It
classified the cause as *fixture roster construction* and left an owner decision
open between two ladders: the roster ladder `CompetitionCatalog` walks, and the
band ladder §14.1 locks.

That ruling rested on a claim nobody had measured: **that the calibration
fixture is, or is not, what a production-built college roster looks like.** This
document measures it, and the answer changes which options are actually on the
table.

---

## 2. Phase 1 — fixture representativeness ruling

### 2.1 Provenance: every consumer draws from one constructor

| Consumer | College roster source |
| --- | --- |
| `run_competition_calibration.gd` | `CompetitionCatalog.match_for` → `team_for` |
| `run_fg_decomposition.gd` | `CompetitionCatalog.match_for` → `team_for` |
| `run_fg_counterfactual.gd` (cross and sweep) | `CompetitionCatalog.team_for` |
| `run_calibration_smoke.gd` | `CompetitionCatalog.match_for` → `team_for` |
| Validation ranges 950,000–950,999 and 960,000–960,999 (§5.22 §7) | `run_competition_calibration.gd`, therefore `team_for` |
| `tools/builder_calibration_harness.gd` | **`BuilderService`** — production, but it builds *single players*, never a roster |
| Production / career-generated college players | **Does not exist.** See §2.3 |
| College tier construction | **Does not exist.** See §2.4 |

Every game-level college measurement this project has ever published comes from
one function. There is no second college roster to compare it against.

### 2.2 What the fixture actually is: a hard-coded linear ladder

`CompetitionCatalog.team_for` builds a player as a **single scalar fanned out
through a fixed offset matrix**:

```
level  = _TEAM_RATING_CENTRE[competition]      # college = 66.0
       + tilt(variation)                        # ±TEAM_LEVEL_TILT (2.1), 13 steps
       + _TEAM_RATING_SPREAD[competition] * (0.5 - rank/9)   # college spread 15.0
       + ((index*29 + variation*17) % 9 - 4) * 0.5           # ±2 sawtooth

attr[k] = clamp(round(level + _SLOT_OFFSETS[k][slot]))       # 20 x 5 constant table
```

Every one of a player's twenty ratings is that one number plus a constant. This
is pinned as a test — `test_the_fixture_roster_is_one_scalar_per_player` — rather
than left as a description: move a player's level by one point and all twenty
ratings move by exactly one point.

The classification asked for is therefore unambiguous. It is **a hard-coded
linear ladder**. It is not a production-generated roster, not a synthetic
representative roster, and not a synthetic midpoint of anything.

Consequences that follow from the construction rather than from any measurement:

- **No age and no class year.** The fixture has neither field. There is no
  freshman, no senior, and no transition.
- **No archetype distribution.** Archetype is a deterministic function of the
  roster slot, so 200 college teams contain exactly **six** distinct derived
  archetypes, in fixed blocks.
- **No attribute correlation structure.** Correlation between any two ratings is
  exactly 1 within a slot, because both are the same scalar plus a constant.
- **No shooting distribution.** A team has no shooters and non-shooters; it has
  five slots whose three-point offsets are `+6, +9, +3, −4, −14` and nothing else.
- **Ten players, not a college roster's thirteen to fifteen.**
- **Bodies are constant per slot**, plus a one-inch bench shift.

### 2.3 Nothing under `src/` builds a roster

`grep` for the constructors, and the finding is structural rather than
statistical:

- `TeamMatchProfile.new(` — **zero** occurrences under `src/`.
- `PlayerMatchProfile.new(` — **zero** occurrences under `src/`.

Production **consumes** a `MatchInput` and never constructs one. There is no
roster generator, no team assembly, and no NPC population model anywhere in the
shipped code. This is pinned by
`test_production_constructs_no_roster_and_no_player_profile`, because the whole
decision rests on it and it would otherwise be a sentence that could quietly stop
being true.

### 2.4 There is no college tier system

"National power", "established program" and "building program" are not concepts
in this repository. The only `tier` symbols that exist are badge tiers
(`ActiveBadgeView.Tier`) and the three §14 game-stakes tiers. The Phase 1 request
to report per-tier construction has no subject.

### 2.5 Ruling

> **The college calibration fixture is not representative of production-built
> college rosters — because there are none.** It is a hard-coded linear ladder,
> and it is the only college roster that exists in this project. Calling it
> "unrepresentative" would imply a production roster it fails to match; calling
> it "representative" would imply one it matches. Neither is true today.

This is a **structural** finding, not a measured one.

---

## 3. Phase 2 — production-representative measurement

### 3.1 What could and could not be measured

The production system cannot generate a college roster, so no
production-representative *roster* population exists, and none is substituted
here. The 1,000-team / 1,000-game roster-level programme the brief asks for has
no subject to sample.

What **does** exist is a production-owned path that produces a *player* at
college age: `BuilderService` (creation) and `DevelopmentService` (progression),
both under `src/`, driven forward through the three §9.5 `COLLEGE` seasons by
`CareerSimulator`. That is measured here and labelled for exactly what it is.

| | |
| --- | --- |
| Runner | `calibration/runners/run_roster_provenance.gd --mode=builder` |
| Careers | 1,000 |
| Seeds | **1,200,001 – 1,201,000** — fresh, previously unused, disjoint from every range in `PROJECT_STATUS.md` |
| Observations | 3,000 (each career snapshotted at all three college class years) |
| Executor | `FULL_DETAIL_ALLOCATOR` |

### 3.2 The headline: the Overall centres agree

| Measure | Fixture college (200 teams, 2,000 players) | Production builder at college age (3,000 observations) |
| --- | ---: | ---: |
| **Mean current Overall** | **67.01** | **67.40** |
| Overall standard deviation | 5.14 | 4.67 |
| p10 / p50 / p90 | 60 / 67 / 74 | 61 / 68 / 74 |
| Minimum / maximum | 55 / 79 | 56 / 81 |
| Age | **none — the field does not exist** | 19, 20, 21 |
| Class years | **none** | 3 (1,000 observations each) |
| Distinct derived archetypes | **6** | 20+, genuinely varied |
| Starters / bench Overall | 71.18 / 62.84 | not applicable — no roster place |
| Team-strength spread (per-team mean Overall) | sd 1.34 | not applicable |

**The fixture's college rating centre is corroborated by production to within
0.39 Overall points.** This is the single most decision-relevant number in the
study, and it is what removes an option rather than adding one: raising the
fixture's college centre to chase the field-goal floor would move the fixture
*away* from where production's own creation-and-development contract puts a
college-age player.

### 3.3 Where the two populations differ: shape, not level

At essentially the same Overall, the two populations distribute those points very
differently.

| Attribute | Fixture | Builder | Difference |
| --- | ---: | ---: | ---: |
| short_range | 67.01 | 71.60 | **+4.59** ‡ |
| handle | 63.81 | 68.20 | **+4.39** |
| three_point | 66.01 | 70.21 | **+4.20** |
| dunking | 66.81 | 70.85 | **+4.04** ‡ |
| mid_range | 66.41 | 69.61 | **+3.20** ‡ |
| speed | 66.41 | 68.87 | +2.46 |
| perimeter_defense | 65.81 | 67.82 | +2.00 |
| defensive_rebounding | 67.01 | 67.67 | +0.66 |
| passing | 66.01 | 66.38 | +0.37 |
| free_throw | 63.41 | 62.78 | −0.63 |
| vision | 66.61 | 65.91 | −0.70 |
| interior_defense | 65.61 | 64.89 | −0.72 |
| strength | 67.01 | 65.62 | −1.39 |
| blocking | 66.01 | 64.60 | −1.41 |
| offensive_rebounding | 65.81 | 64.28 | −1.53 |
| offensive_iq | 67.21 | 65.43 | −1.78 |
| stealing | 66.21 | 64.16 | −2.05 |
| defensive_iq | 67.21 | 65.01 | −2.20 |
| vertical | 68.21 | 65.46 | −2.75 |
| stamina | 66.21 | 61.78 | **−4.43** |

The direction is consistent and is what the production contract is designed to
do: **the builder produces specialists** — emphasis attributes well above the
player's Overall, neutral attributes well below it — while **the fixture produces
flat players** whose every rating is their Overall plus a fixed positional
constant.

**This matters for the field-goal row specifically, because §14.1 field-goal
percentage reads shooting ratings, not Overall.** Two populations can agree on
Overall to a third of a point and still shoot differently.

### 3.4 A confound found while measuring, and reported rather than absorbed

‡ **The three marked rows are contaminated and their magnitudes must not be used
to size anything.**

`CareerSimulator._family_weights` is defective. It reads:

```gdscript
for attribute in CapGenerator.emphasis_from_family(family, [] as Array[int]):
    weights[attribute] = 1.0
```

`emphasis_from_family` returns a twenty-element array of **emphasis levels**
indexed by attribute. The loop iterates its *values* — which are
`AttributeEmphasis.Value` members `PRIMARY=0`, `SECONDARY=1`, `NEUTRAL=2` — and
uses them as *attribute indices*. Verified empirically at every family:

```
family Guard emphasis array = [2, 2, 2, 0, 2, 0, 0, 1, 1, 1, 2, 1, 2, 2, 2, 2, 0, 2, 2, 2]
  -> weighted 1.0: short_range, dunking, mid_range
family Wing  -> weighted 1.0: short_range, dunking, mid_range
family Big   -> weighted 1.0: short_range, dunking, mid_range
```

Every family receives identical weights, on attributes 0, 1 and 2, for every
career this harness has ever run. A Guard's creation spend is weighted toward
dunking and a Big's toward mid-range, and no family is weighted by its own
emphasis at all.

**What this does and does not invalidate:**

- **Contaminated:** `short_range`, `dunking`, `mid_range` — the three attributes
  the defect weights. Their `+4.59 / +4.04 / +3.20` gaps are inflated by an
  unknown amount.
- **Not contaminated:** `three_point (+4.20)`, `handle (+4.39)`,
  `speed (+2.46)`, `perimeter_defense (+2.00)`. These rise through the
  **production cap system** — `CapGenerator.FAMILY_PRIMARY` / `FAMILY_SECONDARY`
  raise their ceilings, and seasonal allocation fills toward those ceilings. The
  defect cannot reach them: their indices are not in `{0, 1, 2}`.
- **Overall is largely robust**, because the defect redistributes a fixed
  attribute-point budget rather than adding to it.

So the clean, load-bearing part of §3.3 is: **at the same Overall, the production
contract puts a college-age player's three-point rating about 4.2 points above
where the fixture puts it**, along with handle, speed and perimeter defence.

**This defect is not fixed here.** It lives in `calibration/harness/`, not in
production, and repairing it would move every recorded §8.4 career-progression
figure and invalidate validation ranges that were frozen before this task
existed. It is raised as its own work item in §8.

---

## 4. Phase 3 — the controlled decision grid

Common-random-number matched fixtures throughout: every cell runs identical
variations and identical seeds, and the match id is a function of the variation
alone, so a cell-to-cell difference is the manipulated factor with the draw
sequence cancelled.

| | |
| --- | --- |
| Runner | `calibration/runners/run_fg_counterfactual.gd` |
| Games | 400 complete games per cell |
| Variations / seeds | **980,000–980,399 / 980,001–980,400** — fresh, previously unused |
| Accounting | `decomposition.reconciled` PASS on every cell; zero identity breaches |

**These are diagnostic transforms and sensitivity instruments only.** A uniform
rating lift is not a proposed implementation — it is the instrument that measures
the engine's response to roster strength. Nothing here may enter production code.

### 4.1 Roster-ladder alternative — a uniform lift

| Metric | College band | +0 | +1 | +2 | +3 | +4 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| **Mean roster Overall** | — | 67.01 | 68.01 | 69.01 | 70.01 | 71.01 |
| **Field-goal %** | 0.420–0.490 | 0.4110 ✗ | 0.4179 ✗ | 0.4197 ✗ | **0.4241 ✓** | 0.4313 ✓ |
| Points per possession | 0.980–1.100 | 1.0483 | 1.0675 | 1.0714 | 1.0824 | **1.1019 ✗** |
| Turnovers / 100 | 15.00–21.00 | 15.409 | 15.300 | 15.118 | 15.028 | **14.941 ✗** |
| 2P% | — | 0.4531 | 0.4568 | 0.4611 | 0.4687 | 0.4737 |
| 3P% | 0.310–0.380 | 0.3299 | 0.3438 | 0.3412 | 0.3414 | 0.3535 |
| 3PA/FGA | 0.320–0.460 | 0.3417 | 0.3439 | 0.3459 | 0.3503 | 0.3524 |
| FT% | 0.670–0.790 | 0.7136 | 0.7263 | 0.7274 | 0.7342 | 0.7442 |
| FTA/FGA | 0.200–0.380 | 0.2548 | 0.2525 | 0.2517 | 0.2540 | 0.2522 |
| Offensive rebound % | 0.240–0.340 | 0.2521 | 0.2524 | 0.2510 | 0.2503 | 0.2521 |
| Assist % | 0.480–0.680 | 0.5230 | 0.5383 | 0.5389 | 0.5485 | 0.5559 |
| Possessions/game (both teams) | — | 144.28 | 144.84 | 144.48 | 144.50 | 144.71 |
| Overtime rate | 0.040–0.080 | 0.0350 ✗ | 0.0375 ✗ | 0.0200 ✗ | 0.0200 ✗ | 0.0300 ✗ |
| Close-game rate | 0.220–0.340 | 0.2950 | 0.2625 | 0.3125 | 0.2700 | 0.3075 |
| Blowout rate | 0.080–0.180 | 0.1200 | 0.1325 | 0.1425 | 0.1375 | 0.1250 |
| Points/game | — | 75.63 | 77.31 | 77.40 | 78.20 | 79.72 |

> **First point field-goal percentage enters the band: +3** (0.4241, interval
> [0.4199, 0.4283]).
>
> **First point another locked metric leaves its band: +4**, and *two* leave
> simultaneously — points per possession crosses its 1.100 ceiling at 1.1019, and
> turnovers per 100 drops through its 15.00 floor at 14.941.
>
> **The feasible window is exactly +3. It is one rating point wide.**

This is narrower than §5.22's estimate of "roughly +2 to +3", measured here at
400 games per cell against that section's 200, and it identifies a **second**
binding constraint §5.22 did not find: the college turnover floor. Turnovers fall
as rosters strengthen, and college starts only 0.41 above its floor.

**Overtime rate fails at every offset including the baseline.** It is a
pre-existing §14.2 failure recorded in §5.13 and §6, is not caused by any
transform here, and therefore does not bound the window.

### 4.2 Distribution alternative — raising only shooting

The §14.1 field-goal row reads shooting ratings. Overall is a weighted aggregate
that field-goal percentage never consults. So the same question was asked of the
attribute subset the statistic actually reads: `short_range`, `mid_range`,
`three_point`, with the roster level left exactly where the fixture puts it.

| Metric | College band | +0 | +2 | +3 | +4 | +5 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| **Mean roster Overall** | — | 67.01 | 67.21 | **67.61** | 67.61 | 68.01 |
| **Field-goal %** | 0.420–0.490 | 0.4110 ✗ | 0.4188 ✗ | **0.4245 ✓** | 0.4271 ✓ | 0.4311 ✓ |
| Points per possession | 0.980–1.100 | 1.0483 | 1.0640 | 1.0806 | 1.0872 | 1.0949 ✓ |
| Turnovers / 100 | 15.00–21.00 | 15.409 | 15.363 | 15.012 | 15.067 | 15.195 |
| 2P% | — | 0.4531 | 0.4609 | 0.4661 | 0.4697 | 0.4740 |
| 3P% | 0.310–0.380 | 0.3299 | 0.3394 | 0.3461 | 0.3482 | 0.3521 |
| 3PA/FGA | 0.320–0.460 | 0.3417 | 0.3465 | 0.3470 | 0.3509 | 0.3522 |
| FT% | 0.670–0.790 | 0.7136 | 0.7169 | 0.7183 | 0.7213 | 0.7224 |
| FTA/FGA | 0.200–0.380 | 0.2548 | 0.2486 | 0.2538 | 0.2523 | 0.2524 |
| Offensive rebound % | 0.240–0.340 | 0.2521 | 0.2524 | 0.2497 | 0.2528 | 0.2541 |
| Assist % | 0.480–0.680 | 0.5230 | 0.5248 | 0.5250 | 0.5256 | 0.5255 |
| Overtime rate | 0.040–0.080 | 0.0350 ✗ | 0.0250 ✗ | 0.0100 ✗ | 0.0350 ✗ | 0.0450 ✓ |
| Close-game rate | 0.220–0.340 | 0.2950 | 0.2650 | 0.2650 | 0.2225 | 0.2750 |
| Blowout rate | 0.080–0.180 | 0.1200 | 0.1300 | 0.1325 | 0.1375 | 0.1550 |

> **First point field-goal percentage enters the band: +3** (0.4245, interval
> [0.4204, 0.4286]).
>
> **No other locked metric leaves its band anywhere in the range tested**, out to
> +5. Points per possession reaches only 1.0949 against a 1.100 ceiling, and
> turnovers per 100 stays above its floor throughout.

### 4.3 The two alternatives, head to head at the point each clears

| | Uniform +3 | **Shooting-only +3** |
| --- | ---: | ---: |
| Field-goal % | 0.4241 | **0.4245** |
| Points per possession | 1.0824 | **1.0806** |
| Turnovers / 100 | 15.028 | 15.012 |
| **Mean roster Overall** | 70.01 | **67.61** |
| Overall inflation vs the shipped fixture | **+3.00** | **+0.60** |
| Overall vs the production builder's college-age 67.40 | **+2.61** | **+0.21** |
| Headroom before the next locked band breaks | **1 rating point** | **≥ 2 points** |

**The shooting-only route reaches the same field-goal percentage for one-fifth of
the Overall inflation, and it lands the fixture's rating centre within 0.21
Overall of where the production builder independently puts a college-age
player.**

Two independent lines of evidence converge on the same correction. §3.3 measured
the fixture's three-point rating at 4.20 points below the production builder's at
matched Overall, before this grid was run; the grid then found that a shooting
lift of +3 to +4 is exactly what closes the field-goal row. Neither measurement
was fitted to the other.

### 4.4 Rejection screen

Every alternative was tested against the disqualifiers the brief names.

| Disqualifier | Uniform lift | Shooting-only lift |
| --- | --- | --- |
| Produces dishonest Overall | **Yes at +3.** Puts college 2.61 Overall above what production builds at college age | **No.** +0.60, landing within 0.21 of the production centre |
| Breaks the intended college-to-development gap | **Yes.** Closes a 6.00-point gap to 3.00 — see §5 | **No.** 6.00 → 5.40 |
| Creates discontinuous progression | **Yes** — see §5.2 | No |
| Moves scoring through unrelated compensation | No — the field-goal identity reconciles on every cell | No — same |
| Relies on competition-specific shot bonuses | No. `ShotResolver` cannot name a competition; pinned by `test_shot_resolution_cannot_name_a_competition` | No — same |
| Alters rules to hit a statistic | No. Rules are held fixed in both grids | No — same |

---

## 5. Phase 4 — five-level consequences

### 5.1 The shipped ladder, measured on a fresh range

| | |
| --- | --- |
| Runner | `run_competition_calibration.gd --competition=all --games=400` |
| Variations / seeds | **990,000–990,399 / 990,001–990,400** — fresh, previously unused |

| Metric | High school | College | Development | Overseas | Top domestic |
| --- | ---: | ---: | ---: | ---: | ---: |
| **Fixture roster Overall centre** | 61.01 | 67.01 | 73.01 | 75.01 | 79.01 |
| Possessions/game | 70.84 ✓ | 72.08 ✓ | 95.68 ✓ | 74.92 ✓ | 101.62 ✓ |
| Points/game | 68.03 | 75.46 | 106.07 | 83.27 | 118.12 |
| Points per possession | 0.9603 ✓ | 1.0469 ✓ | 1.1086 ✓ | 1.1115 ✓ | 1.1624 ✓ |
| **Field-goal %** | **0.3899 ✗** | **0.4115 ✗** | 0.4358 ✓ | 0.4395 ✓ | 0.4563 ✓ |
| §14.1 floor | 0.390 | 0.420 | 0.430 | 0.430 | 0.450 |
| **Margin against floor** | **−0.0001** | **−0.0085** | +0.0058 | +0.0095 | +0.0113 |
| 3P% | 0.3086 ✓ | 0.3285 ✓ | 0.3511 ✓ | 0.3548 ✓ | 0.3776 ✓ |
| 3PA/FGA | 0.3229 ✓ | 0.3402 ✓ | 0.3508 ✓ | 0.3548 ✓ | 0.3626 ✓ |
| FT% | 0.6663 ✓ | 0.7170 ✓ | 0.7651 ✓ | 0.7728 ✓ | 0.8037 ✓ |
| FTA/FGA | 0.1987 ✓ | 0.2457 ✓ | 0.2237 ✓ | 0.2311 ✓ | 0.2182 ✓ |
| Turnovers/100 | 16.230 ✓ | 15.558 ✓ | 14.340 ✓ | 14.436 ✓ | 13.985 ✓ |
| Offensive rebound % | 0.2513 ✓ | 0.2563 ✓ | 0.2522 ✓ | 0.2554 ✓ | 0.2521 ✓ |
| Assist % | 0.4944 ✓ | 0.5159 ✓ | 0.5492 ✓ | 0.5525 ✓ | 0.5819 ✓ |
| Home win rate | 0.5325 ✓ | 0.5400 ✓ | 0.5650 ✗ | 0.5350 ✓ | 0.5375 ✓ |
| Overtime rate | 0.0325 ✗ | 0.0300 ✗ | 0.0225 ✗ | 0.0400 ✓ | 0.0125 ✗ |
| Close-game rate | 0.2600 ✓ | 0.2475 ✓ | 0.2325 ✓ | 0.2750 ✓ | 0.2050 ✗ |
| Blowout rate | 0.1375 ✓ | 0.1475 ✓ | 0.2000 ✗ | 0.1175 ✓ | 0.1925 ✗ |

**Progression is monotone and believable at every scoring statistic.** Field-goal
percentage, three-point percentage, three-point rate, free-throw percentage,
assist percentage and points per possession all rise strictly across the five
levels; turnovers per 100 falls strictly. Nothing here is out of order.

Two deviations are explained rather than treated as defects:

- **Possessions and points do not rise monotonically** — Development (95.7) and
  top domestic (101.6) sit far above overseas (74.9). That is the rule profile
  doing exactly what §4 permits: period length and shot clock differ per
  competition, so pace is a rules property and not a population one.
- **Free-throw rate peaks at college (0.2457)**, not at the top. College's rule
  profile reaches the bonus sooner. Also a rules property.

The failing rows — overtime at four of five, blowout at two, close-game at one,
Development's home win rate — are the pre-existing §14.2 and §5.21 blockers. They
are unrelated to this decision and are not moved by anything proposed here.

### 5.2 Why college specifically, and nowhere else

The roster ladder is **linear in rating**; the band ladder is **not linear in
percentage**.

| Step | Roster Overall gap | §14.1 floor step | Field-goal the gap actually buys | Surplus |
| --- | ---: | ---: | ---: | ---: |
| High school → College | **+6.00** | **+0.030** | +0.0216 | **−0.0084** |
| College → Development | **+6.00** | +0.010 | +0.0243 | **+0.0143** |
| Development → Overseas | +2.00 | 0.000 | +0.0037 | +0.0037 |
| Overseas → Top domestic | +4.00 | +0.020 | +0.0168 | −0.0032 |

The engine's field-goal response to roster strength, measured on matched fixtures
with the rules held fixed, is **+0.0051 per rating point** within college and
about **+0.004 per point** across levels — smooth, monotone and demonstrably
correct.

**The high-school-to-college step is the steepest in the entire band ladder at
+0.030, and the roster ladder gives it the same six rating points it gives the
+0.010 step to Development.** Six points buys roughly 0.024 of field-goal
percentage. College is asked for 0.030 and handed 0.024; Development is asked for
0.010 and handed 0.024. College absorbs the whole discrepancy, and that is the
entire finding.

Nothing about this is an engine defect. A linear roster ladder cannot sit
centrally inside a non-linear band ladder, and the level that ends up furthest
below its floor is the one whose required step is largest.

### 5.3 What a roster change would do to adjacent levels

| Consequence | Uniform +3 | Shooting-only +3 |
| --- | --- | --- |
| **College-to-Development Overall gap** | 6.00 → **3.00**, a 50% collapse | 6.00 → **5.40** |
| **High-school-to-College gap** | 6.00 → **9.00** | 6.00 → **6.60** |
| College stronger than Development? | No, but half as far below it | No |
| College stronger than overseas (75.01)? | No | No |
| **Overall truthfulness** | College player rated 70 who the production builder says is a 67 — **a 2.61-point lie in the direction the Builder is most visible to the user** | +0.21 from the production centre; within measurement noise |
| Freshman transition (high school 61 → college) | Widens to 9.00 points in one summer | Widens to 6.60 |
| Draft / development pathway | College at 70 against Development at 73 leaves 3 points to describe an entire professional step | 5.40 points preserved |
| Projected Peak and career progression | Career model is untouched by fixture rosters — **no direct effect** — but a college population 2.6 above the builder's own output would make any future roster generator inconsistent with the fixture the bands were certified on | Same structural note, at one-fifth the size |

**Neither option touches the career model.** `CompetitionCatalog` rosters are
calibration fixtures; `CareerSimulator`, `BuilderService` and `DevelopmentService`
never read them. Projected Peak, career progression and the §8.4 bands are
unaffected by any option in this document.

---

## 6. Band alternatives

Shown without editing `BALANCE_SPEC.md`. Judged against §5.22's pooled validation
figure — **0.4124 ±0.0018 → [0.4106, 0.4142]**, 2,000 games over ranges
950,000–950,999 and 960,000–960,999 — and against this task's fresh 990,000 range
at 0.4115.

| Candidate floor | Verdict on the measured output | Design meaning |
| --- | --- | --- |
| **0.420 (current, locked)** | **FAILS.** The pooled interval stops 0.0058 short | The steepest step in the §14.1 ladder, +0.030 above high school. Defensible against real college basketball, which shoots comfortably above 42% |
| **0.415** | **STILL FAILS.** The pooled interval's upper bound is 0.4142, below 0.415 | Buys nothing. A floor that neither passes nor expresses a design intent — it is a split difference, and it is the weakest candidate on the list |
| **0.410** | **PASSES**, and the whole pooled interval sits above it | Makes the band ladder near-uniform: 0.390 / **0.410** / 0.430 / 0.430 / 0.450, steps of +0.020 / +0.020 / 0.000 / +0.020 — which is the ladder a *linear* roster ladder naturally produces. But it puts simulated college below what the sport shows, and narrows the high-school-to-college separation the design asks for |
| **Data-centred provisional interval** | Not available | There is no production-representative college population to centre a band on (§2.3, §3.1). A band centred on the current output would be centred on the calibration fixture's own artifact — which is precisely the thing a locked target exists to prevent |

**A new ceiling is not proposed.** The current sample sits far below 0.490, but
distance below a ceiling is not evidence about the ceiling; the ceiling bounds a
league this population has never approached, and nothing here measures it.

---

## 7. Decision matrix

### Option A — Fix the calibration fixture only

| | |
| --- | --- |
| **Exact defect** | The fixture's attribute *shape*, not its level. At matched Overall, the production creation-and-development contract puts a college player's three-point rating **+4.20** above where the fixture puts it, along with handle (+4.39), speed (+2.46) and perimeter defence (+2.00). The fixture makes every rating equal to Overall plus a positional constant; the production contract makes specialists |
| **Correct representative construction** | Shooting ratings raised relative to Overall so the fixture matches the shape the production cap system produces. Measured at **+3 on `short_range`, `mid_range`, `three_point`**: field-goal percentage 0.4245, inside the band; Overall 67.61, within **0.21** of the production builder's 67.40; **no other locked band leaves its range out to +5** |
| **Does production field-goal percentage already pass?** | **Unknown, and unknowable today.** Production cannot assemble a college roster, so no production college game can be simulated. This is the honest answer and it is a real limitation of Option A |
| **Changes required** | `CompetitionCatalog._SLOT_OFFSETS` (calibration fixture, not production); re-measure all five levels; re-record §14.1 verdicts; update §5.22 and this document |
| **Production behaviour impact** | **None.** `CompetitionCatalog` is calibration-only and no shipped code reads it |
| **Risk** | The fixture would be shaped to match a *player* population from a career model whose own allocation weighting is currently defective (§3.4). The three-point evidence survives that defect; the short-range and mid-range evidence does not. **The defect should be repaired and the shape re-measured before the offsets are chosen** |

### Option B — Change the college rating ladder

| | |
| --- | --- |
| **Smallest viable change** | `_TEAM_RATING_CENTRE[COLLEGE]` 66.0 → 69.0 (+3). Nothing smaller clears the floor |
| **Field-goal and PPP consequence** | Field-goal 0.4110 → 0.4241 ✓; points per possession 1.0483 → 1.0824 ✓, but **+4 breaks it at 1.1019** and simultaneously breaks turnovers per 100 at 14.941. The viable window is one rating point wide |
| **Adjacent-level gaps** | College-to-Development collapses **6.00 → 3.00**; high-school-to-College widens **6.00 → 9.00** |
| **Player-builder and progression** | No direct effect — the career model never reads fixture rosters |
| **Overall truthfulness** | **This is where the option fails.** Production's own contract puts a college-age player at 67.40. Option B declares college to be 69–70. It fixes a statistic by making the fixture *less* like production, and §3.2 is direct evidence against it |
| **Files / migrations** | `calibration/targets/competition_catalog.gd`; all five levels re-measured; no data migration (no generated content exists) |
| **Stale content** | None today. There is no generated content to invalidate |

### Option C — Revise the locked college field-goal target

| | |
| --- | --- |
| **Proposed target** | The only candidate that passes is a **0.410** floor. 0.415 does not pass (§6) |
| **Statistical evidence** | 0.4124 ±0.0018 pooled over 2,000 untouched games; 0.4115 on a fresh 400-game range; four independent ranges, every interval below 0.420 |
| **Basketball / design justification** | It would make the band ladder near-uniform at +0.020 per level, which is internally coherent with a linear roster ladder. Against that: it puts simulated college below the shooting the real sport shows, and compresses the high-school-to-college separation the design is built around |
| **Does it bless a fixture artifact?** | **Yes, and demonstrably so.** §2 establishes that the fixture is the only college roster in existence and is a hard-coded linear ladder; §3.3 establishes that its shooting shape does not match the production contract. Moving the band to the fixture's output ratifies a construction the evidence says is wrong in shape |
| **Consequences elsewhere** | §14.1 college row; the §32 locked-target register; §27.1 certification would then certify against the revised band. It also forecloses Option A: once the band is moved down, a later fixture repair would push college *above* its own floor and the band would need moving again |

### Option D — Hybrid

| | |
| --- | --- |
| **Minimal roster adjustment** | Shooting-only **+2**: field-goal 0.4188, Overall 67.21 |
| **Minimal target adjustment** | Floor 0.415 |
| **Are both necessary?** | **No — and this is the finding that removes the option.** 0.4188 still misses a 0.415 floor. To make the hybrid pass, the shooting lift must reach +3 (0.4245), and at +3 the *current* 0.420 floor already passes. **The band change does no work.** |
| **Better than either single change?** | **No.** It is strictly dominated by Option A: the same roster change, plus a target concession that buys nothing |

### Option E — Defer until §27.1

| | |
| --- | --- |
| **What remains uncertain** | Whether the shape gap in §3.3 survives repair of the `_family_weights` defect; what a production college roster would measure, once one exists; whether 400- and 2,000-game samples hold at 100,000 |
| **Risk of leaving it** | Low in isolation — the miss is 0.0085 and stable across six independent ranges — but it keeps a §14.1 row red, and a red row blocks Stage 4 merge criteria |
| **Certification sample needed** | §27.1: **100,000 complete games per competition**. This task ran 400 per level; §5.22 ran 2,000 for college. No developer machine produces the certifying sample (§6.4) |
| **Is production work blocked?** | **No.** Nothing downstream depends on this row. Deferral costs nothing except leaving the row open |

### 7.1 Ranking

| Rank | Option | Verdict |
| --- | --- | --- |
| **1 — Recommended** | **A, fixture shape, preceded by repairing `_family_weights`** | The only option supported by two independent measurements that were not fitted to each other. Clears the band with ≥2 points of headroom, costs +0.60 Overall, lands within 0.21 of the production centre, and changes no production behaviour |
| **2 — Runner-up** | **E, defer to §27.1** | Costs nothing, blocks nothing, and preserves every option. The correct choice if the owner is unwilling to act on a sub-certification sample |
| Rejected | **B, rating ladder** | Directly contradicted by §3.2. Collapses the college-to-Development gap by half for a one-point-wide window |
| Rejected | **C, revise the band** | Ratifies a fixture artifact the evidence identifies as mis-shaped, and forecloses Option A |
| Rejected | **D, hybrid** | Strictly dominated. The band concession does no work at the roster change that passes |

**Confidence: moderate-to-high on the ranking, low on the exact magnitude.**

- **High confidence** that the fixture's rating *level* is not the problem —
  fixture 67.01 against production 67.40, from independent code paths.
- **High confidence** that a uniform lift has a one-point-wide window and a
  shooting-only lift has at least a two-point window — CRN-matched, 400 games per
  cell, accounting identities reconciled on every cell.
- **Moderate confidence** that shooting shape is the defect: the three-point
  evidence is clean, the short-range and mid-range evidence is contaminated by
  §3.4.
- **Low confidence in any specific offset.** +3 is where these samples cross, not
  a certified value, and it should be re-derived after §3.4 is repaired.

### 7.2 Reversible versus irreversible

| Consequence | Reversibility |
| --- | --- |
| Option A — fixture offsets | **Fully reversible.** Calibration-only; revert and re-measure |
| Option B — rating ladder | **Fully reversible today**, because no generated content exists. Becomes hard to reverse the moment a roster generator ships against the changed ladder |
| Option C — revise the locked band | **Effectively irreversible.** A locked §14.1 target that has been weakened once has lost its authority as a target, and every later measurement is judged against the weaker line |
| Option E — defer | Fully reversible |
| Repairing `_family_weights` | Reversible, but it **moves recorded §8.4 career figures** and invalidates validation ranges frozen before it. Needs its own task and its own fresh ranges |

### 7.3 The exact owner decision required

> **Does the owner accept that the college field-goal shortfall is a defect in
> the calibration fixture's attribute *shape* — its shooting ratings sitting
> roughly four points below where the production builder puts them at the same
> Overall — rather than in its rating *level* or in the §14.1 band?**
>
> **If yes:** authorise (1) repairing `CareerSimulator._family_weights`, (2)
> re-measuring the production shape on fresh seeds, and (3) re-deriving the
> fixture's shooting offsets from that measurement. Option A. No locked target
> moves and no production value changes.
>
> **If no, or if the owner declines to act below §27.1:** the row stays open as a
> measured miss until certification. Option E.
>
> Options B, C and D are recommended against, with the evidence above.

---

## 8. Classification, and what this task found on the way

### 8.1 Defect classes, kept distinct

| Class | Applies here? |
| --- | --- |
| **Engine defect** | **No.** No production simulation defect is demonstrated. The engine's field-goal response to roster strength is smooth, monotone and correct at +0.0051 per rating point; the same shared shot profile puts Development, overseas and top domestic inside their own floors; every accounting identity reconciles on every cell |
| **Fixture defect** | **Yes, and this task is what establishes it as a *shape* defect.** §5.22 named "fixture roster construction" as the class; §3.3 now says which property — shooting ratings roughly four points below the production contract's at matched Overall, with the rating level itself corroborated to 0.39 |
| **Specification conflict** | **Yes, and it is real and independent.** §5.2: the roster ladder is linear in rating and the §14.1 band ladder is not linear in percentage. Six rating points buys ~0.024 of field-goal percentage; the high-school-to-college step asks for 0.030 and the college-to-Development step asks for 0.010. That mismatch exists whatever the fixture's shape |
| **Owner preference** | **Yes — which contract moves.** Fixture shape (A), rating ladder (B), locked band (C), or nothing until certification (E). This document does not choose |
| **Sampling uncertainty** | **Yes, and it is not the explanation.** College misses on six independent ranges — 910k, 920k, 930k, 950k, 960k, 970k, plus this task's 980k and 990k — with every interval below the floor on its own. Sampling is ruled out as the cause and remains a live limit on the *magnitude* of any fix |

### 8.2 Evidence classification

| Finding | Classification |
| --- | --- |
| The fixture is a hard-coded linear ladder | **Structural.** Read from the constructor and pinned by test |
| Nothing under `src/` builds a roster or a player profile | **Structural.** Pinned by test |
| No college tier system exists | **Structural** |
| Fixture college Overall 67.01; production builder college-age Overall 67.40 | **Measured, not certified.** 2,000 fixture players; 1,000 careers / 3,000 observations |
| Three-point +4.20 at matched Overall | **Measured, not certified**, and clean of the §3.4 defect |
| Short-range / dunking / mid-range gaps | **Measured but contaminated** by §3.4. Not usable for sizing |
| Uniform grid: field-goal enters at +3, PPP and turnovers break at +4 | **Measured, not certified.** 400 games/cell, CRN-matched |
| Shooting grid: field-goal enters at +3, nothing else breaks to +5 | **Measured, not certified.** 400 games/cell, CRN-matched |
| Five-level state table | **Measured, not certified.** 400 games/level |
| `CareerSimulator._family_weights` is defective | **Structural.** Verified empirically at all three families |

**Nothing in this document is certified.** §27.1 requires 100,000 complete games
per competition; the largest sample here is 2,000 (§5.22, quoted) and this task's
own runs are 400 per cell or per level.

### 8.3 New work item — `CareerSimulator._family_weights`

Found while measuring, reported rather than absorbed, and **not fixed here**.

- **What:** `_family_weights` iterates the *values* returned by
  `CapGenerator.emphasis_from_family` and uses them as attribute *indices*, so
  every position family weights `short_range`, `dunking` and `mid_range` at 1.0
  and everything else at 0.35. No family is weighted by its own emphasis.
- **Where:** `calibration/harness/career_simulator.gd`. **Calibration harness, not
  production.** No shipped code path is affected.
- **Impact:** creation-time attribute-point allocation in every career the
  progression suites have ever run. Overall is largely preserved because the
  budget is redistributed rather than increased, which is consistent with the
  §8.4 career-peak bands measuring green.
- **Why it is not fixed in this task:** repairing it moves the recorded §8.4
  figures and invalidates validation ranges 700,001–702,000 and 900,001–902,000,
  which were frozen before this work existed. It needs its own task, its own
  fresh ranges, and its own re-measurement of the §8.4 bands.
- **Blocking:** it should be repaired **before** Option A's offsets are chosen,
  because it contaminates three of the four attributes Option A would move.

---

## 9. Reproduction

```bash
# Fixture provenance, all five levels
godot --headless --path . --script res://calibration/runners/run_roster_provenance.gd -- \
    --mode=fixture --teams=200 --label=fixture

# Production builder at college age (fresh seeds 1,200,001-1,201,000)
godot --headless --path . --script res://calibration/runners/run_roster_provenance.gd -- \
    --mode=builder --careers=1000 --base=1200001 --label=builder

# Uniform roster-level grid (seeds 980,001-980,400)
godot --headless --path . --script res://calibration/runners/run_fg_counterfactual.gd -- \
    --mode=sweep --rules=college --offsets=0,1,2,3,4 --games=400 --base=980000 --label=owner_grid

# Shooting-only distribution grid (same seeds, matched)
godot --headless --path . --script res://calibration/runners/run_fg_counterfactual.gd -- \
    --mode=distribution --rules=college --subset=shooting --offsets=0,2,3,4,5 \
    --games=400 --base=980000 --label=owner_shooting

# Five-level state table (seeds 990,001-990,400)
godot --headless --path . --script res://calibration/runners/run_competition_calibration.gd -- \
    --competition=all --games=400 --shard=2475 --shards=2476 --label=owner_five_level
```

### Seed-range separation

No range in this task serves two purposes, and none had been used before.

| Purpose | Range | Sample |
| --- | --- | ---: |
| Production-builder college-age population | career seeds 1,200,001–1,201,000 | 1,000 careers / 3,000 observations |
| Uniform roster grid | variations 980,000–980,399 | 400 games × 5 cells |
| Shooting distribution grid | variations 980,000–980,399 (**deliberately matched to the uniform grid** so the two are directly comparable) | 400 games × 5 cells |
| Five-level state table | variations 990,000–990,399 | 400 games × 5 levels |
| `test_roster_provenance.gd` | career seeds 1,250,001+ | 12 careers |

The two grids share a range **on purpose**: they are the same fixtures under two
different transforms, and comparing them requires it. They are never pooled.

---

## 10. Verification

Instrumentation was added to three files. None of it is production code, and the
evidence that it changed nothing is measured rather than asserted.

| Check | Result |
| --- | --- |
| `tools/parse_check.gd` | **236 scripts, 0 failures** (was 234; two new files) |
| `tests/run_all.gd` | **PASS**, golden ledgers included |
| Six golden ledger hashes | **Byte-identical.** `tests/golden/match_golden_hashes.json` still `be8c8b19b60abcb4965d9254b335a2396d3361c9fb17ea3b38a51e23d5eb4cf5` |
| `tools/simulation_smoke.gd` | **Byte-identical** apart from the wall-clock elapsed field (`in 4147 ms` → `in 4583 ms`). Every simulation figure is unchanged |
| Builder calibration | **PASS** |
| Attribute sensitivity | **80/80 PASS** at 100,000 resolutions |
| Calibration smoke | **15/15 PASS** |
| GdUnit4 | **523/523**, 46 suites, 0 failures, 0 orphans — 516 pre-existing plus 7 added here |
| Ruleset | Unchanged. No diff under `src/`, `calibration/targets/`, `tests/golden/`, or `BALANCE_SPEC.md` |

### 10.1 The counterfactual runner's existing modes are bit-identical

`run_fg_counterfactual.gd` gained a `distribution` mode and a wider report
payload. Both are inert on the paths that existed before: `_transform` returns
the roster object unchanged when a cell names no attributes, and every added
payload row is read from a `MatchMetricAccumulator` the runner was already
filling.

Proved rather than argued, by re-running §5.22's cross at its own range
(930,000–930,199, 200 games per cell) and comparing to the figures that section
published:

| Cell | §5.22 published | Re-run after this task's changes |
| --- | ---: | ---: |
| college rules × college rosters | 0.4104 ±0.0058 | **0.4104 ±0.0058** |
| college rules × development rosters | 0.4405 ±0.0061 | **0.4405 ±0.0061** |
| development rules × college rosters | 0.4057 ±0.0047 | **0.4057 ±0.0047** |
| development rules × development rosters | 0.4346 ±0.0048 | **0.4346 ±0.0048** |

Every cell reproduces to the digit, interval included.

### 10.2 The career instrumentation cannot change a career

`tests/calibration/test_roster_provenance.gd`, 7 tests:

| Test | What it establishes |
| --- | --- |
| `test_the_college_snapshot_is_not_taken_by_default` | The capture is off unless asked |
| `test_taking_the_college_snapshot_changes_no_career_outcome` | Twelve careers at fixed seeds produce identical path, seasons, starting/peak/final Overall, peak age, rating points gained, guardrail seasons, and all four AP-ledger totals with the capture on and off. **This is the RNG assertion**: a career is a chain of seeded draws across seventeen to twenty-three seasons, so one extra draw would desynchronize every quantity listed |
| `test_each_college_class_year_holds_its_own_ratings` | The snapshot copies rather than aliases live player state |
| `test_the_snapshot_covers_exactly_the_college_seasons` | Class-year count equals the §9.5 COLLEGE season count, derived from the phase table rather than a remembered number |
| `test_the_college_snapshot_reconciles_with_the_season_record` | Three independent arms agree: the snapshot's Overall, `overall_by_season` at that season, and the Overall recomputed from the captured rating vector |
| `test_production_constructs_no_roster_and_no_player_profile` | Pins the structural finding in §2.3 |
| `test_the_fixture_roster_is_one_scalar_per_player` | Pins the §2.2 classification: +1 roster level moves all twenty ratings by exactly +1 |

The pre-existing probe contract in `tests/calibration/test_fg_decomposition.gd`
is unchanged and still covers the rest of what the brief requires: the probe
cannot change the ledger, it is detached by default, `after_test()` tears it down
whatever the test did, a probe whose owner was freed is ignored via
`Callable.is_valid()`, the published field-goal interval goes through the
clustered ratio estimator over **team-games**, and
`tests/calibration/report_aggregation_suite.gd` proves aggregation pools raw
numerators and denominators rather than averaging shard estimates.

No mutation battery was run: no behavioural or guard code changed. The added
instrumentation is reporting, and its "cannot affect the result" property is
covered by the equality tests above rather than by mutating a branch that does
not exist.
