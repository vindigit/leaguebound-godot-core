# LeagueBound Balance Specification

**Version:** 0.1  
**Status:** Draft numerical baseline for implementation and calibration  
**Date:** August 2, 2026  
**Authority:** Tuneable-value and guardrail owner within the approved source hierarchy

## 1. Purpose

This document defines the initial numeric model for LeagueBound version 1.0. It turns approved design into tuneable values, curves, targets, and statistical acceptance tests.

This specification answers:

- What every rating band means and costs.
- How the 20 public ratings become capabilities and Overall.
- How quickly players develop, peak, decline, and reach their caps.
- How games, training, badges, injuries, recruiting, trust, followers, contracts, and money scale.
- How rare death, incarceration, and other career-ending events remain genuinely rare.
- Which basketball distributions the simulation must reproduce.
- What evidence is required before a proposed value becomes an approved shipping value.

When current sources conflict, authority runs from explicit owner rulings, to locked level-specific systems, to later and more-specific frameworks, then to the GDD, PRD, Simulation Specification, this Balance Specification, `GODOT_TDD.md`, Content Bible, and finally older or superseded wording. A higher source controls. `GODOT_TDD.md` implements approved gameplay and cannot redefine it; the previous React Native / Expo `TDD.md` is archived reference only.

This specification owns tuneable values, distributions, curves, statistical targets, guardrails, and the evidence required to approve them. It does not own structural eligibility, career state, membership, contracts, rights, assignment, competition history, or ending legality. A balance value that would change one of those rules is invalid even when it produces desirable aggregate results.

## 2. Balance Status and Vocabulary

Values use four classifications:

| Classification | Meaning |
| --- | --- |
| **Structural invariant** | A rule owned by a higher-authority design source and repeated here only as a validation constraint. It is not a balance parameter. |
| **Locked value** | A numeric target explicitly fixed by an owning source. It cannot change through ordinary tuning. |
| **Baseline** | The initial implementation value. It can move after documented calibration evidence. |
| **Guardrail** | A permitted range or tuneable constraint. Tuning may move inside it without redesigning the feature. |

Unless explicitly marked as a Structural invariant, Locked value, or Guardrail, values in version 0.1 are Baselines. A Baseline is not considered ship-approved until its required simulation report passes. Structural invariants are never inferred from a favorable statistical result and cannot be relaxed through a balance profile.

### 2.1 Structural invariants and deferred tuneables

Structural invariants define whether a career state or transition is legal. Balance may measure and validate them but cannot change them. Examples include the five-academic-year/four-competition-season college envelope, the one-playing-contract rule, award ownership and finalization order, the shared 25-professional-season boundary, and the once-only career-year resolution rules.

The explicitly deferred tuneable categories are:

- Ordinary-redshirt appearance threshold
- Draft-lottery odds
- Salary distributions
- Comeback-offer likelihood
- Award formulas
- Hardship-replacement thresholds
- Suspension lengths
- Import-market supply

These categories may move only inside the structure established by their owning design source. Tuning cannot create a new pathway, membership state, contract authority, award qualification, history result, or ending rule.

### 2.2 Owner-locked player-system decisions

The following decisions are explicit owner rulings. They sit at the top of the authority hierarchy, supersede conflicting older wording anywhere in this specification, and are **Locked values**. Tuning may change the parameters that produce them; it may not change the targets themselves.

| ID | Locked decision | Owning sections |
| --- | --- | --- |
| **OD-A** | Career peak distribution for a sensible Balanced build without rare breakthroughs. | §8.4 |
| **OD-B** | Completed freshman Builder outcome bands, creation-budget exhaustion, and the empty-preview distinction. | §7.1, §7.3, §7.3.4 |
| **OD-C** | Body maturation: user-selected freshman body and timing, bounded projected adult range, deterministic hidden growth. | §7.4 |
| **OD-D** | Current Overall, Maximum Potential Overall, and Projected Peak are three distinct values. | §6.3 |
| **OD-E** | One canonical development contract for the user, full-detail NPCs, and aggregate executors. | §9.7 |
| **OD-F** | Rotation role, tactical role, and derived archetype are separate layers. | §12.4 |

An owner-locked target is never satisfied by widening its own band. When a candidate profile misses a locked target, the tunable moves, not the target.

## 3. Balance Principles

1. **One standard difficulty.** There are no easier economy, progression, injury, recruiting, or simulation presets.
2. **Ability is not destiny.** Strong ratings produce meaningful advantages while context, competition, decisions, health, and bounded randomness preserve uncertainty.
3. **Perfect means perfect only when valid.** A manual release inside a visible valid perfect zone is guaranteed to succeed. The defense can prevent that zone from existing.
4. **Weak and strange builds remain legal.** Balance protects simulation integrity, not the user from poor allocation.
5. **Played and simulated games pay the same.** Presentation and manual execution do not change progression, fatigue, injury, or economic reward schedules.
6. **Specialists must be real.** A specialized player can dominate a narrow skill without receiving an artificially elite universal Overall.
7. **Scarcity creates career texture.** Elite ratings, Hall of Fame badges, major awards, huge contracts, and catastrophic events remain uncommon.
8. **No hidden rubber-banding.** Score margin cannot secretly improve the losing team’s ratings or make probability.
9. **Money cannot buy basketball ability.** Real-money purchases never change ratings, caps, health odds, recruiting, or simulation outcomes.
10. **Every important random result is reproducible.** Tuning operates on versioned seeded streams, not `Math.random()`.

## 4. Balance Configuration and Versioning

Every production tuning constant belongs to a named balance profile. Anonymous numeric literals are prohibited inside resolution code.

```ts
interface BalanceProfile {
  version: string;
  ratings: RatingBalance;
  builder: BuilderBalance;
  progression: ProgressionBalance;
  simulation: SimulationBalance;
  health: HealthBalance;
  recruiting: RecruitingBalance;
  social: SocialBalance;
  economy: EconomyBalance;
  rareEvents: RareEventBalance;
  monetization: MonetizationBalance;
  calibration: CalibrationRequirements;
}
```

Rules:

- Each career stores the balance-profile version with which it was created.
- New careers use the newest approved bundled profile.
- Existing careers remain pinned to their profile unless a migration corrects an invalid or exploitative result.
- Balance migrations must be deterministic and record the old version, new version, and reason.
- Remote connectivity is never required to load a valid balance profile.
- Developer overrides are unavailable in release builds and cannot contaminate save files.

### 4.1 Simulation ruleset history

The simulation half of the profile is versioned separately because it is the half that moves a match ledger. A change to it invalidates every committed golden hash by construction, so the version is the record of *why* those hashes were allowed to move.

| Version | Change | Golden-ledger effect |
| --- | --- | --- |
| `simulation-v1` | Initial multi-action possession engine | — |
| `simulation-v2-calibrated` | Free-throw attribution correction (`00567d4`) | One scenario regenerated deliberately |
| `simulation-v3-margin` | §18.2 settled-game rotation; mandatory-first substitution ordering; `offensive_rebound_base` 0.28 → 0.25; `steal_opportunity_on_ball` 0.175 → 0.200 and `steal_opportunity_pass` 0.14 → 0.160 | All six scenarios regenerated; the overtime scenario needed a re-derived seed because the previous one stopped reaching overtime. `PROJECT_STATUS.md` §5.10 carries the evidence and the blast-radius proof |

| `simulation-v4-management` | §10.2/§10.3/§18.2 score-and-clock game management (`GameManagement`): a team protecting a lead consumes more clock, resets more, hunts fewer threes and stops crashing the offensive glass, and a team chasing one does the reverse; §20.2 end-of-regulation possession strategy preferring the shot value that levels the game; §4/§5 coaching timeouts with a per-competition allowance | All six scenarios regenerated. Every one of these changes moves the clock, the action mix or the event stream of any game that reaches a managed score state, and five of the six fixtures do. `PROJECT_STATUS.md` §5.11 carries the evidence and the blast-radius proof |

| `simulation-v5-garbage-time` | §18.2 score-and-time rotation rebuilt as `GarbageTimeRule`: a possession-based safety measure with **asymmetric leading and trailing thresholds** (owner ruling of 2026-08-20), a `GARBAGE_TIME` ledger event and a `TeamMatchState.settled_mode` the rotation reads instead of recomputing. `decided_game_margin` and `decided_game_clock_share` are replaced by `settled_minimum_margin`, `settled_swing_points_per_pair`, `settled_leading_safety`, `settled_trailing_safety`, `settled_release_share` and `settled_minimum_pairs_left` | **No committed hash moved.** All six scenarios reproduce exactly, because none of the six fixtures reaches the eighteen-point coaching floor the rule needs before it can fire. The version moves because the balance profile's tunables and the engine's rotation behaviour did, not because a hash was allowed to. `PROJECT_STATUS.md` §5.12 carries the evidence |

A golden hash is regenerated only after an explicit version change, and only after `tools/golden_ledger_harness.gd` confirms that every scenario still exercises the behaviour it is named for. Regenerating to silence a failing test is prohibited.

## 5. Public Rating Scale

All 20 public ratings are whole numbers from 25 through 99. A value below 25 is reserved for non-player placeholders and cannot appear on an active basketball player.

| Rating | Universal label | Expected meaning |
| ---: | --- | --- |
| 25–39 | Severe weakness | Liability even at lower competition levels |
| 40–49 | Poor | Below ordinary competitive standard |
| 50–59 | Developing | Functional in favorable lower-level contexts |
| 60–69 | Competent | Dependable ordinary competitive skill |
| 70–79 | Good | Clear strength; viable at strong college/pro contexts |
| 80–89 | Excellent | High-level professional quality |
| 90–94 | Elite | Among the strongest active players in that ability |
| 95–98 | Generational | Rare, career-defining ability |
| 99 | Apex | Best-in-world ceiling, still bounded by action validity |

The same band names apply to every attribute. Competition does not change the underlying rating; it changes opponents, rules, pace, and context.

### 5.1 Rating normalization

For formulas that need a unit interval:

```text
NormalizedRating(r) = clamp((r - 25) / 74, 0, 1)
```

For opposed basketball checks:

```text
RatingDifferential(a, b) = (a - b) / 10
```

One ten-point capability advantage is therefore one standard opposed-check unit before context. Probability functions use a logistic or bounded curve so a ten-point advantage is meaningful without becoming deterministic.

### 5.2 Capability weights

Derived capabilities use a weighted average on the 25–99 scale before context modifiers. Primary inputs must retain at least 55% of the weight.

Every weight in the following table is a **Baseline**. The 55% primary-input floor and the requirement that each capability name its primary skill are structural; the exact percentages are versioned tunables that become ship-approved only after the attribute sensitivity report (§31 report 2) and the build-diversity report (§31 report 3) pass. Do not cite these percentages as proven values.

| Capability | Initial weights |
| --- | --- |
| Ball Security | Handle 65%, Strength 15%, Offensive IQ 20% |
| Handle Creation | Handle 55%, Speed 25%, Offensive IQ 20% |
| Pass Accuracy | Passing 65%, Vision 15%, Offensive IQ 20% |
| Pass Read Quality | Vision 60%, Offensive IQ 25%, Passing 15% |
| Shot Selection | Offensive IQ 70%, Vision 20%, relevant shooting rating 10% |
| Rim Touch Finish | Short Range 60%, Strength 15%, Speed 10%, Offensive IQ 15% |
| Dunk Threat | Dunking 60%, Vertical 20%, Strength 10%, Speed 10% |
| Midrange Shotmaking | Mid-Range 80%, Offensive IQ 20% |
| Three-Point Shotmaking | Three-Point 82%, Offensive IQ 18% |
| Free-Throw Shotmaking | Free Throw 92%, Offensive IQ 8% |
| Off-Ball Timing | Offensive IQ 60%, Speed 25%, Vision 15% |
| Offensive Rebound Positioning | Offensive Rebounding 60%, Strength 15%, Vertical 15%, Offensive IQ 10% |
| Point-of-Attack Containment | Perimeter Defense 55%, Speed 20%, Strength 10%, Defensive IQ 15% |
| Perimeter Contest | Perimeter Defense 55%, Speed 15%, Vertical 10%, Defensive IQ 20% |
| Interior Positioning | Interior Defense 60%, Strength 20%, Defensive IQ 20% |
| Rim Protection | Blocking 55%, Interior Defense 15%, Vertical 15%, Defensive IQ 15% |
| Passing-Lane Defense | Stealing 60%, Defensive IQ 25%, Speed 15% |
| On-Ball Disruption | Stealing 55%, Perimeter Defense 20%, Speed 10%, Defensive IQ 15% |
| Help Recognition | Defensive IQ 75%, Speed 15%, role execution 10% |
| Defensive Rebound Positioning | Defensive Rebounding 60%, Strength 15%, Vertical 15%, Defensive IQ 10% |

Fatigue, injury, body, badges, and live context apply after the base capability. IQ improves the circumstances in which a skill is used and cannot replace the named primary skill.

**"Role execution" is not a role.** The 10% `role execution` term in Help Recognition means the quality of the player's execution of his current defensive assignment in the live possession — a contextual behavioral input. It is not the tactical role identity, and it must not be implemented by reading a `TacticalRole` ID. No capability in this table may take rotation role, tactical role, or derived archetype as an input (§12.4). Identity layers reach opportunity, never capability.

## 6. Role-Neutral Overall

Current Overall is exact, public, and calculated identically for users and NPCs. It excludes position, role, popularity, followers, trust, morale, team fit, potential, and reputation.

### 6.1 Formula

Let:

- `M20` be the arithmetic mean of all 20 current attributes.
- `T8` be the mean of the player’s eight highest current attributes.
- `B6` be the mean of the player’s six lowest current attributes.

```text
OverallRaw = 0.65 × M20 + 0.25 × T8 + 0.10 × B6
DisplayedOverall = round(clamp(OverallRaw, 25, 99))
```

This formula is role-neutral, gives specialized strengths some credit, and still makes serious weaknesses matter. No attribute receives a permanent position-based weight.

The *structure* of the blend—mean, top-eight, bottom-six, role-neutral, no positional weighting—is locked. The three coefficients `0.65 / 0.25 / 0.10` are **Baselines**. They are versioned tunables and are ship-approved only after the OVR population histogram report (§31 report 1) and the build-diversity and dominance report (§31 report 3) pass. Because every Builder and progression target in this document is expressed in Overall, changing a coefficient invalidates §7.3 and §8.4 evidence and requires those reports to be rerun.

### 6.2 OVR guardrails

- Raising any one rating while all others remain fixed cannot reduce Overall.
- No non-rating state can change Overall.
- A one-point rounding boundary is acceptable; unexplained two-point UI differences are defects.
- No ordinary generated active player may have 99 Overall.
- Fewer than 0.1% of top-domestic active players should reach 95+ Overall in a stable mature world.
- The top domestic league should generally contain 0–3 players at 93+ and 4–15 players at 90+ in a season.
- A current Overall of 96 or above is practically nonexistent. It is not forbidden by a clamp, but no ordinary career path may produce it, and a candidate profile that generates a measurable population above 95 fails Gate B1. (**Locked value**, OD-A.)
- Individual attributes may reach 99. The resistance to extreme Overall comes from the breadth requirement in the blend, never from compressing the attribute scale.
- **Overall is never a simulation input.** No resolution path—shot, pass, defense, rebound, foul, rotation, matchup, or Tier B aggregation—may read Current Overall, Maximum Potential Overall, or Projected Peak. They are display projections derived from ratings. A dependency check enforcing this is a release blocker (§28).

### 6.3 Three distinct development values

Three separate values describe a player's development. They are computed differently, carry different certainty, and each requires its own UI label. Presenting any one of them as another is a defect. (**Locked value**, OD-D.)

| Value | Required UI label | Definition | Type |
| --- | --- | --- | --- |
| Current Overall | **Current Overall** | §6.1 formula applied to current ratings. | Exact integer |
| Maximum Potential Overall | **Maximum Potential** | §6.1 formula applied to the player's exact per-attribute caps (§8). | Exact integer |
| Projected Peak | **Projected Peak** | Realistic best Overall this career is likely to reach. | Inclusive integer **range** |

Rules:

1. Maximum Potential is a physical and skill ceiling, not a promise. It assumes every cap is filled, which effectively no career achieves. It must never be labeled "potential rating," "future Overall," or anything implying attainment.
2. Projected Peak is always a range and never a single number. Its inputs are: available development opportunity for the remaining career, the prospect timing profile (§7.2), current age and the aging curves (§10.2), ordinary—not best-case—opportunity, exact per-attribute caps, and expected decline.
3. Projected Peak is recomputed as those inputs change. It is not stored as a promise made at creation, and it moves both directions.
4. `CurrentOverall ≤ MaximumPotentialOverall` always holds. The Projected Peak range must lie at or below Maximum Potential and at or above Current Overall, except that a player already in decline may show a Projected Peak range whose upper bound equals his historical peak.
5. Projected Peak must never be more optimistic than the evidence supports. Its honesty is an acceptance requirement, not a presentation preference (§30, Gate B3).
6. None of the three values may be used as a simulation input (§6.2).

**Projected-peak honesty target.** Across the million-career progression report, the realized career peak Overall must fall inside the Projected Peak range displayed at the start of the career for **70–85%** of careers, and the range must not be so wide that it is uninformative: the median displayed range width is a **Guardrail** of 6–12 Overall points. Both figures are **Baselines pending the §31 report 7 result**; the requirement that the range be honest and bounded is Locked. A model that achieves coverage by widening the range to meaninglessness fails, as does one that achieves a narrow range by systematic optimism. Systematic bias is reported separately: the median signed error between realized peak and range midpoint must not exceed ±2 Overall points.

## 7. Builder and Prospect Profiles

### 7.1 Starting scale

The user begins the freshman year of high school. The builder begins from a body-adjusted base and then grants manual allocation currency.

| Component | Baseline |
| --- | ---: |
| Technical, scoring, playmaking, defense, and rebounding base | 35 |
| Offensive IQ and Defensive IQ base | 38 |
| Physical base before body adjustment | 45 |
| Manual starting Attribute Point budget | 195 AP |
| Minimum final attribute | 25 |
| Freshman builder soft starting maximum | 70 |
| Freshman builder absolute starting maximum | 75 |

Body choices redistribute at most 18 total rating points and are approximately zero-sum. No body selection can create more than a four-point direct modifier on one starting attribute. Physical dimensions primarily affect action access, reach, and matchups rather than granting free universal Overall.

**Creation-budget exhaustion.** The creation Attribute Point budget must be fully spent before a build can be confirmed. Retained creation currency cannot be carried into the career, converted to direct progress, refunded, or banked for later seasons. The Builder blocks confirmation while any creation AP remains unspent. (**Locked value**, OD-B.)

This makes weak builds a consequence of allocation, not of hoarding. An intentionally poor player is produced by spending the full budget into incompatible, redundant, or role-irrelevant attributes—which is legal and unblocked—rather than by declining to spend it.

The starting bases and the 195 AP budget in the table above are **Baselines**, not proven values. The budget was raised from 150 to 195 by the Stage 2 Builder calibration run; see §7.3.3 for the measurement and the constraints that governed it. Reachability against the §7.3.2 bands is demonstrated; the full §31 report 3 distribution at the §27.1 sample size is not, and the values remain provisional (§32).

### 7.2 Broad prospect profiles

| Profile | Starting AP modifier | Cap-generation modifier | Growth timing |
| --- | ---: | ---: | --- |
| Ready Now | +40 AP | −3 to non-primary cap center | 115% HS, 90% college, 80% pro growth availability |
| Balanced | 0 AP | No global modifier | 100% at every phase |
| High Upside | −40 AP | +4 to cap center | 85% HS, 115% college, 120% early-pro growth availability |

Profile multipliers change the number and quality of opportunities generated, not the AP cost of a rating. Exact displayed training rewards remain truthful after the multiplier is resolved.

### 7.3 Freshman outcome targets

This section supersedes the earlier "approximately 37 through 61" completed-build range, which conflated three different states. The empty preview, a completed profile build, and an extreme specialist are separate targets and are stated separately below.

#### 7.3.1 Empty pre-allocation preview

Before any creation AP is spent, the Builder displays a preview Overall of approximately **37–39**. At the §7.1 baselines this value is derived, not chosen:

```text
M20 = (14 × 35 + 2 × 38 + 4 × 45) / 20 = 37.30
T8  = (4 × 45 + 2 × 38 + 2 × 35) / 8   = 40.75
B6  = 35.00
OverallRaw = 0.65 × 37.30 + 0.25 × 40.75 + 0.10 × 35.00 = 37.93  →  38
```

This state is a **preview only**. It is not a legal completed build, cannot be confirmed (§7.1), and must never be cited as the Builder's minimum outcome. Any statement that the Builder permits a completed freshman near 37 OVR is incorrect. (**Locked value**, OD-B.)

#### 7.3.2 Completed profile bands

A completed, confirmed freshman build lands in the band for its prospect profile. (**Locked values**, OD-B.)

| Prospect profile | Completed freshman current OVR |
| --- | ---: |
| High Upside | 44–48 |
| Balanced | 46–50 |
| Ready Now | 48–52 |

- An **extreme specialist**—a build concentrating its budget into very few attributes while accepting severe weaknesses—may land approximately **two OVR outside** its profile band in either direction.
- An **ordinary completed build must not exceed approximately 54 current OVR**. This is the absolute completed-freshman ceiling across all profiles and allocation strategies, including specialists. A candidate profile that produces completed builds above 54 fails Gate B1.
- There is no corresponding floor beyond the 25-per-attribute minimum. Deliberately poor allocation may land below its profile band, and that is a legal, intended outcome.

The confirmation screen reports Current Overall, Maximum Potential, Projected Peak, all exact caps, the projected adult body range, archetype description, likely behavioral profile, and all allocations, using the distinct labels required by §6.3. It does not label a legal build as bad.

#### 7.3.3 Derived calibration gap in the current baselines

The §7.1 baselines do not currently reach the locked bands in §7.3.2. Deriving the reachable outcome from the documented base ratings, the §7.2 profile AP modifiers, and the §9.1 cost table—where all allocation below rating 60 costs 1 AP per point—gives:

| Prospect profile | Creation AP | Flat allocation | Maximum concentration | Locked band |
| --- | ---: | ---: | ---: | ---: |
| High Upside | 130 | 44 | 46 | 44–48 |
| Balanced | 150 | 45 | 47 | 46–50 |
| Ready Now | 175 | 47 | 48 | 48–52 |

Because every attribute stays inside the 1 AP band, `M20` rises by exactly `AP / 20` regardless of distribution; concentration adds a further 1–2 OVR by raising `T8` while `B6` stays at its floor. The upper half of every locked band is therefore unreachable, and the Balanced and Ready Now bands are reachable only at their extreme lower edge under maximum concentration.

**Resolution.** The locked bands are the acceptance target; the creation AP budget and the body-adjusted starting bases are the tunables.

Calibration is bounded by three constraints that must hold simultaneously:

1. Completed builds must reach the locked bands in §7.3.2.
2. No ordinary completed build may exceed approximately 54 OVR.
3. The soft and absolute per-attribute starting maxima of 70 and 75 remain in force.

Raising the AP budget alone satisfies constraint 1 while threatening constraint 2. Calibration must therefore evaluate the budget, the starting bases, and the low-band cost curve together, and record which combination was accepted.

#### 7.3.4 Accepted Stage 2 combination

The Stage 2 Builder calibration harness (`tools/builder_calibration_harness.gd`) swept 810 completed builds across every prospect profile, maturity profile, position family, three body variants per family, and six allocation strategies plus randomized builds, from fixed seeds. The accepted combination is:

| Tunable | Was | Now |
| --- | ---: | ---: |
| Creation AP budget (Balanced) | 150 | **195** |
| Ready Now modifier | +25 | **+40** |
| High Upside modifier | −20 | **−40** |
| Starting bases | 35 / 38 / 45 | **unchanged** |
| Low-band cost curve | 1 AP below 60 | **unchanged** |

The bases were deliberately left alone so the §7.3.1 empty-preview derivation still yields 38 from the documented bases, rather than becoming a second number needing its own evidence.

Measured completed-build current OVR:

| Prospect profile | Ordinary builds | Extreme specialists | Locked band |
| --- | ---: | ---: | ---: |
| High Upside | 46–47 | 45–46 | 44–48 |
| Balanced | 48–49 | 46–48 | 46–50 |
| Ready Now | 49–50 | 47–49 | 48–52 |

All three constraints hold: every ordinary build lands inside its locked band, every extreme specialist lands within the approximately two-OVR tolerance, and the ordinary high-water mark is 50 against the 54 ceiling.

**Why the distributions are narrow.** Each profile spans roughly two OVR rather than filling its four-point band. This is the same mechanism §7.3.3 identified: below rating 60 every point costs 1 AP, so `M20` rises by `AP / 20` almost regardless of distribution, and allocation strategy moves the result only through `T8` and `B6`. Concentration past 60 is *less* efficient, not more, because the cost doubles. Widening the spread would require changing the low-band cost curve, which would alter every progression figure downstream. That trade is a Stage 4 decision with report 7 evidence, not a Stage 2 one.

**Status.** This demonstrates reachability at fixed seeds. It is not the §31 report 3 build-diversity run at the §27.1 sample size, and it does not close the calibration. The 195 AP budget, the 35/38/45 bases, and the ±40 profile modifiers all remain explicitly provisional (§32).

### 7.4 Body maturation

The body is a persistent, versioned player fact with its own state and its own resolution schedule. (**Locked structure**, OD-C.)

#### 7.4.1 Selected state

At creation the user selects current freshman height, weight, wingspan/standing reach, and one maturity timing profile: **Early**, **Average**, or **Late**. All four selections are stored as the confirmed freshman body.

#### 7.4.2 Projected adult range

From the selected body and timing profile, the Builder computes and displays a **bounded projected adult range** for each dimension. The displayed range is stored with the career at confirmation and becomes a binding contract.

| Rule | Status |
| --- | --- |
| The displayed range is stored at confirmation and is immutable for the career. | Structural invariant |
| Realized adult body must fall inside the stored range on every dimension. | Structural invariant |
| The exact adult body is drawn deterministically from the versioned career seed at creation and remains hidden until each increment resolves. | Structural invariant |
| Range widths per dimension | **Baseline**, pending §31 report 15 |
| Share of total growth delivered by timing profile and career phase | **Baseline**, pending §31 report 15 |

Range width is a genuine tuning tension and is deliberately left unset: too narrow makes the maturity choice meaningless, too wide makes the projection uninformative. The report must show that Early, Average, and Late produce materially different realized high-school bodies while every realization stays inside its stored range.

#### 7.4.3 Resolution invariants

1. **Determinism.** Growth is a function of the versioned career seed, career-year identity, and stored body state. Reloading, changing simulation detail, Play/Sim choice, or device cannot reroll it.
2. **Containment.** No growth increment may take any dimension outside the stored projected range. A tuning change that would violate containment for an existing career is invalid; it applies to new careers only.
3. **No retroactive invalidation.** Growth never invalidates a confirmed build, never re-runs allocation, never refunds or re-charges AP, and never changes a per-attribute cap by itself.
4. **No silent rating change.** A body increment may not alter any of the 20 public ratings as a side effect. Where design intends a rating consequence, it resolves as a separate, visible, ledgered effect under the ordinary progression rules, exactly as §8.3 and HEALTH-006 require for cap changes.
5. **Bounded starting redistribution only.** The ±18-point, approximately zero-sum redistribution in §7.1 applies once, at creation. Later growth does not grant a second redistribution.
6. **Not free Overall.** Body affects action validity, reach, positioning, and matchups. Across the build-diversity report, body selection alone must not produce a systematic Overall advantage; a body configuration that dominates every major observable is a release blocker (§28).

#### 7.4.4 Persistence and migration

Confirmed freshman body, maturity profile, stored projected adult range, realized current body, and the resolved-increment ledger are all saved career facts, not derived values. They carry a schema version. Any migration that cannot recover a stored projected range must reconstruct the widest range consistent with the realized body and record the limitation, never narrow a range around the realized value to fabricate precision. `GODOT_TDD.md` §5.5 and §5.7 own the type and persistence contract.

## 8. Potential Cap Distribution

Each attribute receives an exact cap between 40 and 99 from a correlated player ceiling, build/body constraints, prospect profile, and bounded per-attribute noise.

### 8.1 Player ceiling distributions

The user’s builder uses the selected profile. Generated NPCs use the same distributions with competition-appropriate selection pressure.

| Prospect profile | Ceiling center, freshman generation | Standard deviation | Hard range |
| --- | ---: | ---: | ---: |
| Ready Now | 75 | 7 | 58–92 |
| Balanced | 79 | 8 | 58–96 |
| High Upside | 83 | 9 | 58–99 |

The ceiling center is not Potential Overall. It is the anchor from which attribute caps are derived. Primary build attributes receive `+4 to +10`; secondary strengths receive `+1 to +5`; neutral attributes receive `−3 to +3`; incompatible physical or specialist tradeoffs can receive `−6 to −16`.

Per-attribute noise is normally distributed with standard deviation 2.5 and clipped to ±6. All draws use the career-generation stream.

**Implementation status: the ceiling centers above were moved by Stage 4 and this table had not recorded it.** `ProgressionProfile` implements `81 / 85 / 88` against the `75 / 79 / 83` stated here; the deviations and hard ranges are unchanged. The change was made with the §9.5 seasonal bands, because a ceiling centre producing a Maximum Potential near 72 made the §8.2 top-domestic rostered median of 77–81 unreachable at any level of opportunity. These are **Baselines** and §32 keeps them provisional pending report 7, so the move is permitted; leaving the document disagreeing with the code was not. The previous values are retained here so the change stays auditable, exactly as §9.5 retains its previous baselines.

**Selection pressure is now an explicit parameter.** §8.1's "competition-appropriate selection pressure" is implemented on `CapGenerator.generate` as an order statistic: the ceiling is the highest of a named pool of draws from the profile's own distribution. A pool of one is no selection and consumes exactly one draw. This satisfies §8.2's requirement that the engine "must not silently increase a player's cap merely because he reached a higher league", because every ceiling the pool can yield was already reachable from the unselected distribution — what changes is which players are sampled, not what the distribution contains.

**Implementation status: the rare-generational cohort draws from a pool of three.** Every other generated population uses a pool of one. The pool was raised because the cohort was measured to contain careers whose Maximum Potential sat below the §8.4 band the cohort is defined to reach — at a pool of two its tenth percentile was 84 against a band of 92–95, and those careers filled every cap, stranded up to 1,200 AP-equivalent, and peaked in the mid-eighties at every opportunity level tested. Raising the pool lifted the cohort's tenth percentile and left its median untouched, because the median career is opportunity-bound rather than cap-bound. `PROJECT_STATUS.md` §5.8 carries the measurement.

### 8.2 Population distribution targets

| Population | Median OVR | 90th percentile | 99th percentile |
| --- | ---: | ---: | ---: |
| Incoming HS freshmen, Maximum Potential OVR | 58–63 | 70–75 | 82–88 |
| Recruited college entrants, Maximum Potential OVR | 67–72 | 78–83 | 88–92 |
| Top domestic draft pool, Maximum Potential OVR | 74–78 | 84–88 | 92–95 |
| Top domestic rostered players, current OVR | 77–81 | 87–90 | 92–95 |

"Maximum Potential OVR" here is the value defined in §6.3: the Overall formula applied to exact per-attribute caps. It is a ceiling, and these targets describe the distribution of ceilings in each population — not what those players will actually reach. Realized peaks are governed by §8.4.

Selection creates later-phase distributions; the engine must not silently increase a player’s cap merely because he reached a higher league.

### 8.3 Exceptional cap changes

Ordinary development never changes caps.

| Event | Eligible chance | Magnitude | Limits |
| --- | ---: | ---: | --- |
| Unprompted positive breakthrough at offseason resolution | 0.30% per active player-season | +1 to +3 on one relevant cap | At most one per offseason |
| Unprompted negative setback | 0.20% per active player-season | −1 to −2 on one relevant cap | A cap may fall below current; cap-only change preserves current rating |
| Major authored development event | Content-defined, global lifetime target 5–10% of careers | ±1 to ±4 | Must have causal prerequisites |
| Major or catastrophic injury | Severity-driven | −1 to −8 across affected caps | Cap change is visible after medical resolution; any current-rating effect resolves separately |

Random cap changes use cooldowns and should affect no more than 12% of complete user careers outside injury. A change larger than four points requires a major injury or explicitly approved unique event.

A potential-cap reduction by itself never lowers the current rating. If the new cap is below current ability, the current rating remains unchanged and further growth in that attribute is blocked until current ability is no longer above the cap. A separately resolved and visibly explained health, injury, or decline effect may lower current ability, but it uses its own effect and ledger entry; current-rating loss is never inferred silently from the cap mutation.

### 8.4 Career peak distribution

This is the acceptance target for peak **current** Overall reached at any point in a complete career, measured for a sensible Balanced build that receives no rare breakthrough. (**Locked value**, OD-A.)

| Career outcome | Peak current OVR |
| --- | ---: |
| Poorly managed or injury-hit | Below 72 |
| Ordinary successful | 74–79 |
| Strong and well-managed | 80–85 |
| Exceptional | 86–91 |
| Rare generational | 92–95 |
| Practically nonexistent | 96+ |

Reading rules:

- "Sensible Balanced build" means the Balanced prospect profile, a completed build inside §7.3.2, allocation that is coherent for its position family, and no rare cap breakthrough (§8.3).
- The bands describe career management quality and opportunity, not difficulty settings. There is one standard difficulty (§3.1).
- 96+ is not blocked by a clamp. It must simply not occur through any ordinary path. Individual attributes may still reach 99 (§6.2).
- The gap between the 72-and-below band and the 74–79 band is intentional: it is the region where a career is neither clearly failed nor clearly successful, and the report should show a continuous distribution across it rather than a spike.
- Ready Now and High Upside peaks are expected to shift within these bands—earlier and lower, later and higher respectively—but no profile may relocate the top of the distribution.

**Verification.** The million-career progression report (§27.1, §31 report 7) segments complete careers by outcome classification and reports the peak-OVR distribution for each band, plus the population share above 95. Failing this target is a Gate B3 failure. It is corrected by tuning seasonal AP availability, the cost curve, cap distributions, aging, or decline — never by relabeling the bands.

**Relationship to other targets.** This distribution, the §8.2 population targets, the §6.2 OVR guardrails, and the §6.3 projected-peak honesty target are four views of the same underlying progression model and must be reported together. A profile that satisfies one by breaking another has not passed.

**Unmeasured relationship.** The mapping from the §8.1 ceiling center, through Maximum Potential Overall, to realized Projected Peak is not currently defined numerically. §8.1 states explicitly that the ceiling center is not Potential Overall, and no conversion has been measured. Stage 4 must report that mapping rather than assume it; until then, no statement of the form "a Balanced player peaks near his ceiling center" may be made in any document or interface.

## 9. Attribute Point Economy

### 9.1 Universal upgrade costs

The cost is determined by the destination rating and is identical for all 20 attributes.

| Destination rating | Cost per whole rating increase |
| ---: | ---: |
| 25–59 | 1 AP |
| 60–69 | 2 AP |
| 70–79 | 3 AP |
| 80–89 | 5 AP |
| 90–94 | 8 AP |
| 95–99 | 12 AP |

Examples:

- 58 → 60 costs 3 AP: one point into 59 and two into 60.
- 69 → 70 costs 3 AP.
- 79 → 80 costs 5 AP.
- 94 → 95 costs 12 AP.
- 90 → 99 costs 92 AP.

Allocation is permanent. There is no attribute respec. Caps are checked before currency is consumed.

### 9.2 Direct attribute progress

Focused progress uses AP-equivalent units attached to one attribute. One direct-progress unit fills one AP of the current upgrade cost. When the bar reaches the required cost, the rating increases by one and surplus progress carries into the next eligible point.

The interface displays the progress bar without its exact fraction. At cap, unresolved direct progress converts to general AP at 50% efficiency, rounded down only at the end of the event. This prevents a cap from deleting an earned reward without making focused training identical to general AP.

### 9.3 Training rewards

| Training intensity | Ordinary reward | Energy/condition cost | Base injury-candidate multiplier |
| --- | ---: | ---: | ---: |
| Light | 1 AP | 4 | 0.50× |
| Standard | 2 AP | 8 | 1.00× |
| Hard | 3 AP | 14 | 1.65× |
| Elite/specialist | 4 AP or equivalent direct progress | 16 | 1.80× |

Elite/specialist sessions require suitable facilities, coaching, money, relationships, or phase access. An ordinary completed session always grants the displayed reward.

A Standard session has a 0.10% baseline chance to resolve a training injury incident before durability, condition, facility, and intensity modifiers. Light, Hard, and Elite sessions use the multipliers in the table. Training injuries use family-appropriate severity weights and cannot bypass the Health service.

### 9.4 Opportunity storage

| Context | Storage cap |
| --- | ---: |
| HS freshman/sophomore | 5 sessions |
| HS junior/senior | 4 sessions |
| College | 4 sessions |
| Development/overseas | 4 sessions |
| Top domestic pro | 3 sessions |
| Offseason bonus | +1 session |
| Poor facilities or active moderate limitation | −1 session, minimum 2 |
| Elite facilities and development coach | +1 session, maximum 6 |

A typical competitive week creates one training opportunity. Dense travel weeks may create none; open offseason weeks may create two. Stored sessions are consumed individually.

High-school workload baselines assume 20 official school regular-season games: 14 district, four interdistrict, and two showcase, rivalry, or tournament games. State qualifiers add one to four games. National qualifiers add one to seven games depending on seed and advancement. A team therefore plays 20 to 31 official school games.

School basketball and summer basketball are balanced as separate calendar segments. Fatigue, condition, injury exposure, progression, travel, and recovery are charged from actual games played. A deep school-postseason run delays summer entry and carries its committed state forward. Additional postseason games create exposure and ordinary development opportunities but remain inside seasonal AP-equivalent and direct-progress guardrails; they cannot become unlimited progression farming.

Reduced-detail high-school simulation uses Team Power Rating only as a bounded summary of roster quality, coaching, form, health, and competitive environment. It must be calibrated against full-detail outcomes at equivalent inputs. Relevance promotion must generate a roster whose aggregate capability falls within the approved TPR tolerance and cannot improve or weaken a school because the user is about to face it.

### 9.5 Seasonal progression targets

Every annual progression source uses the shared career-year identity and its completion receipts. One career year permits at most one age increase, one natural development-or-decline resolution, one generic offseason-development phase, and one professional-service credit. Changing levels, assignment, recall, release, or a second offseason entry cannot rerun any of them. Professional service is credited only when the player occupies a professional roster during official competition and is still capped at one credit for that career year. Balance owns the magnitude and distribution of eligible progression, not the scheduling or duplication of these structural resolutions.

These totals include training, game participation, focused direct progress converted to AP equivalent, and ordinary development events. They exclude rare breakthroughs.

**Status: raised by the Stage 4 progression measurement; still short of certification.** The bands below were multiplied by approximately 2.4 during Stage 4. The previous values are recorded in the table so the change is auditable.

**The lifetime conversion is now measured.** It was the largest single finding of Stage 4. Deriving the requirement arithmetically: a completed freshman near 48 OVR reaching a strong peak of 80–85 must raise twenty attributes by roughly thirty points each, which against the §9.1 escalating cost bands (1 AP below 60, 2 AP at 60–69, 3 AP at 70–79, 5 AP at 80–89) costs approximately **1,150 lifetime AP-equivalent**. The previous bands delivered a measured mean of **469**. The §8.4 curve was therefore unreachable by construction rather than by mistuning, and no amount of allocation skill could have closed a 2.5× shortfall.

At the raised bands the measured mean lifetime grant is **1,165 AP-equivalent** and mean cap attainment is **0.88**, so caps — not currency — are now the binding constraint, which is the intended relationship.

| Phase | Typical available AP-equivalent per season | High-engagement upper guardrail | Previous baseline |
| --- | ---: | ---: | ---: |
| High school | 108–156 | 187 | 45–65 |
| Summer circuit | 18–38 | 48 | 8–16 |
| College | 84–132 | 163 | 35–55 |
| Domestic development | 72–115 | 144 | 30–48 |
| Overseas | 60–108 | 134 | 25–45 |
| Top domestic pro, age 19–24 | 58–96 | 120 | 24–40 |
| Top domestic pro, age 25–29 | 38–72 | 91 | 16–30 |
| Top domestic pro, age 30+ | 19–53 | 72 | 8–22 |

These remain **Baselines**. The measurement behind them used 400 complete careers, not the §27.1 million. They are better-founded than the values they replace and are not yet ship-approved.

#### Owner ruling, 2026-08: the bounded elite-opportunity exception

**Ruling (authoritative).** *Rare-generational careers may exceed the §9.5 high-engagement upper guardrail by up to 20% when caused by ledgered elite opportunity, while emitting the required balance warning. This exception applies only to the rare-generational path and cannot alter AP costs, game-development caps, population shares, or adjacent outcome bands.*

**What it was ruling on.** All five §8.4 bands now measure inside their locked targets, and reaching the rare-generational band takes that cohort above the guardrails in this table. Summed across a twenty-three-season career the guardrails permit about **2,695 AP-equivalent**; the cohort was measured receiving about 3,140, a **16.5% overage**, and passing its guardrail in 17 seasons of 23. §8.4 is Locked and these bands are Baselines, so the tension resolved in §8.4's favour; the ruling sets the price at which that is acceptable and caps it at **20%** of the same summed-guardrail figure the 16.5% was measured against.

**How the exception is bounded.** The permission attaches to a **persistent career condition** (`CareerOpportunityCondition.ELITE_OPPORTUNITY`), not to an outcome label. Seventeen exceptional seasons in one career are one condition and not seventeen anomalies, and a permission attached to a condition cannot be claimed by another cohort merely by being handed more opportunity. A career without the condition that runs a career-long surplus above its own summed guardrails is a defect whatever band it belongs to; a career *with* it may exceed by up to the share this section's profile carries.

The bound is enforced as each season is granted, by `DevelopmentService.seasonal_opportunity_ceiling`, rather than checked afterwards. That makes the lifetime total provably under 1.20× the summed guardrails at any opportunity setting, so a later retune cannot walk the cohort past the ruling by accident. Careers without the condition are not trimmed: §9.5 already governs them through the balance warning and the source-ledger explanation, and bounding them would move outcome bands the ruling explicitly may not touch.

**What enforcing it exposed.** At the opportunity multiplier chosen before the ruling, the cohort *mean* overage was compliant at 16.5% while individual careers reached 26% — roughly a fifth of the cohort outside the ruling behind a compliant average. The multiplier was re-measured against the enforced bound and now sits where the worst career reaches 17.9% against the permitted 20%. A cohort average is not a bound.

**What the exception does not do.** It changes no §9.1 cost, no §9.6 seasonal game-development cap, no §8.4 population share, and no seasonal draw. Every exceeding season still raises the balance warning this section requires, still carries a source-ledger entry naming what produced the excess, and is still judged for that explanation by the career-progression report. `PROJECT_STATUS.md` §5.8 and §5.9 carry the measurements and the regression evidence.

The upper guardrail is not a hard currency cap. It triggers a balance warning and requires the source ledger to explain why the season was exceptional.

### 9.6 Game development

Game participation fills a seasonal development pool:

```text
GameDevelopment = ParticipationBase × RoleRelativePerformance × CompetitionQuality × DevelopmentRoom
```

- `ParticipationBase` depends on minutes and meaningful involvement, not box-score volume alone.
- `RoleRelativePerformance` ranges from 0.85 to 1.15.
- `CompetitionQuality` ranges from 0.85 to 1.20.
- `DevelopmentRoom` declines from 1.00 below 70 rating to 0.25 at 95+.

Seasonal game-development caps are 12 AP-equivalent in HS, 16 in college/alternatives, and 20 in top domestic professional basketball. Played and simulated games share the same pool and formula.

**Implementation status: the caps are enforced.** `ProgressionProfile.game_development_cap` carries the row above per career phase and `DevelopmentService.grant_game_development` trims a grant to whatever the season has left, returning what it credited so the caller can place the remainder through a source that can account for it. The formula's four terms are not yet implemented — game participation is currently supplied as a seasonal AP-equivalent total rather than resolved per game — so this records the cap, not the formula.

### 9.7 One canonical development contract

There is exactly one development contract in LeagueBound. It governs the user, fully simulated NPCs, and aggregate executors alike. Detail level changes how the contract is executed, never what it produces. (**Locked structure**, OD-E.)

#### 9.7.1 Executors

| Executor | Applies to | Allocation method |
| --- | --- | --- |
| **Manual** | The user | The user spends AP and direct progress personally and permanently. |
| **Full-detail allocator** | Named NPCs in full-detail simulation | An AI allocator spends AP-equivalent opportunity under identical rules. |
| **Aggregate executor** | Reduced-detail populations | Development is resolved in bulk, reproducing the distributions the full-detail allocator would have produced. |

#### 9.7.2 Rules binding every executor

All three executors are bound identically by:

- The universal destination-rating cost table (§9.1).
- Exact per-attribute caps and the cap-change rules (§8, §8.3).
- Prospect timing profiles and growth availability multipliers (§7.2).
- Aging curves, mileage, and annual decline (§10).
- Seasonal availability bands and upper guardrails (§9.5).
- The source ledger. Every AP-equivalent unit granted or spent records its source, career year, executor, and balance-profile version — for NPCs exactly as for the user.
- Career-year completion receipts. One career year permits one natural development-or-decline resolution per player regardless of executor (§9.5).

The full-detail allocator receives **AP-equivalent opportunity**, not finished ratings. It is not permitted to write a rating directly, to exceed a cap, to spend currency it was not granted, or to use a private cost table. An allocator implemented as "assign a target rating and interpolate" violates this contract even when its aggregate output looks correct.

#### 9.7.3 Aggregate executors

An aggregate executor may skip per-attribute deliberation for performance. It must still:

- Draw its totals from the same seasonal availability model.
- Respect caps, cost bands, and decline.
- Produce attribute-level distributions statistically indistinguishable from the full-detail allocator at equivalent inputs, within the Tier A/Tier B tolerances in §27.2.
- Write source-ledger entries at whatever granularity it resolves, so promotion has real history to inherit.

#### 9.7.4 Detail-promotion invariance

**Changing a player's simulation detail level must not change the player.** Promoting a background prospect to full detail, or demoting a player to aggregate simulation, may add or drop *evidence resolution* — it may never alter current ratings, caps, body, maturity state, accumulated development, or committed history.

This extends the existing prospective-promotion rule (WORLD-008, `SIMULATION_SPEC.md` §26.4) from history to the player's development state itself. The acceptance test is exact and is a Gate B3 requirement: simulate a matched cohort to a fixed career year under each detail level, then compare. Ratings, caps, and body must match exactly for the same seed; aggregate-resolved cohorts must match full-detail cohorts distributionally within §27.2 tolerances.

A player who improves because the user is about to face him is a release blocker (§28).

## 10. Aging, Mileage, and Decline

### 10.1 Career mileage

Mileage is a hidden cumulative value.

```text
SeasonMileage =
  minutesFactor
  × workloadFactor
  × congestionFactor
  × playThroughFactor
  × recoveryFactor
  + majorInjuryMileage
```

An ordinary healthy starter season produces approximately 1.0 mileage. Bench seasons produce 0.35–0.70. Extremely heavy seasons can reach 1.40. Major injury adds 0.25–1.50 depending on severity and treatment. Excellent recovery can reduce new seasonal mileage by up to 15% but never erase existing mileage.

### 10.2 Category aging curves

| Category | Growth-dominant ages | Plateau | Natural decline begins | Late decline |
| --- | --- | --- | --- | --- |
| Speed and Vertical | 14–23 | 24–27 | 28 | Strong after 33 |
| Stamina | 14–25 | 26–29 | 30 | Strong after 35 |
| Strength | 14–26 | 27–31 | 32 | Strong after 36 |
| Technical scoring/handle/passing | 14–27 | 28–32 | 33 | Moderate after 37 |
| Rebounding and positional defense | 14–27 | 28–32 | 33 | Moderate, mileage-sensitive |
| Offensive IQ and Defensive IQ | 14–31 | 32–36 | 37 | Mild after 40 |

Natural age- and mileage-based development or decline resolves once at the shared career-year offseason milestone. A qualifying major health event may apply a separate, visible health effect when it occurs, but it cannot rerun the natural annual resolution. There is no invisible weekly erosion.

### 10.3 Annual natural decline baseline

Values are expected total rating points removed from a category, distributed toward the most exposed attributes. Fractional decline accumulates invisibly until a whole point resolves.

| Age band | Physical | Technical | IQ |
| --- | ---: | ---: | ---: |
| 28–30 | 0.5–1.5 | 0 | 0 to +0.5 |
| 31–33 | 1.5–3.0 | 0–0.5 | 0 to +0.5 |
| 34–36 | 3.0–5.0 | 0.5–1.5 | 0 |
| 37–39 | 4.0–7.0 | 1.5–3.0 | 0–0.5 |
| 40+ | 6.0–10.0 | 2.5–5.0 | 0.5–1.5 |

Mileage modifies physical decline from 0.75× for a lightly used healthy career to 1.50× for extreme mileage. Long inactivity can independently reduce Stamina, Speed, and technical sharpness by 1–6 points after a clear warning and recovery opportunity.

Natural decline cannot reduce an attribute more than five whole points in one offseason without a major injury or extraordinary circumstance.

## 11. Badge Economy and Effect Envelope

### 11.1 Badge Development Point costs

Badge points are universal and can be spent on any badge.

| Upgrade | Marginal cost | Total cost from locked |
| --- | ---: | ---: |
| Unlock Bronze | 1 BDP | 1 |
| Bronze → Silver | 2 BDP | 3 |
| Silver → Gold | 4 BDP | 7 |
| Gold → Hall of Fame | 7 BDP | 14 |

Hall of Fame is deliberately difficult. A strong complete career should usually earn 6–12 BDP. An elite award-heavy career may earn 14–24. More than 30 requires an extraordinarily long and decorated career.

Every qualifying repeat award uses its normal point value only when the owning competition permits repeats. A stable award identifier and idempotent finalization receipt prevent one result from matching multiple synonymous triggers or paying twice.

### 11.2 Award-owned BDP cadence

Each competition's owning design defines award eligibility, participation requirements, qualification, and timing. Balance may tune an approved award formula and its BDP cadence, but it cannot turn attention, reputation, a title, a statistic, or a career milestone into a qualifying award.

The owning competition finalizes each award exactly once after its postseason for the competition and career year. Finalization records a stable award identifier and an idempotent receipt before any authorized BDP is granted. Reloading or changing levels cannot rerun that result.

| Finalized award class | Baseline BDP when the owning design explicitly marks it qualifying |
| --- | ---: |
| Qualifying phase or competition award | 1 |
| Qualifying top-domestic All-Star selection | 1 each finalized occurrence |
| Qualifying top-domestic major individual award | 1 each finalized occurrence |
| Other explicitly enumerated qualifying award | Owning rule, ordinarily 1 |

Candidate, watch-list, nomination, semifinalist, or finalist status never grants BDP. Only a finalized qualifying award may grant it. No ordinary game, ordinary training session, follower milestone, purchase, cash milestone, team title by itself, statistical-leader label by itself, or record milestone by itself awards BDP.

### 11.3 Badge effect envelope

| Tier | Typical relative improvement to eligible result | Maximum relative improvement | Maximum absolute probability change |
| --- | ---: | ---: | ---: |
| Bronze | 2–3% | 4% | 1.5 percentage points |
| Silver | 4–6% | 7% | 2.5 percentage points |
| Gold | 7–9% | 11% | 4 percentage points |
| Hall of Fame | 10–13% | 15% | 6 percentage points |

Badges activate only after their prerequisites and cannot create an invalid action. Stacked badges affecting the same probability are capped at 18% relative and six absolute percentage points. Badge contributions to non-probability capability scores are capped at +8 total points.

A very rare authored event may grant one free tier. Lifetime target: 1–3% of complete careers. It cannot raise a badge above Hall of Fame or refund points already spent.

## 12. Automatic Action Selection

### 12.1 Five-position tendency mapping

| Slider position | Multiplier toward selected pole |
| ---: | ---: |
| 1 | 0.82× |
| 2 | 0.91× |
| 3 | 1.00× |
| 4 | 1.10× |
| 5 | 1.22× |

The opposing action family receives the reciprocal multiplier. Neutral position three is exactly 1.00. Tendency effects never change ratings.

### 12.2 Action-weight factor guardrails

| Factor | Ordinary range | Exceptional range |
| --- | ---: | ---: |
| Role opportunity | 0.60–1.50 | 0.35–1.80 |
| User tendency | 0.82–1.22 | Fixed by table |
| Coach instruction | 0.88–1.15 | 0.80–1.25 on explicit play call |
| Tactical fit | 0.75–1.30 | 0.60–1.45 |
| Matchup opportunity | 0.80–1.25 | 0.65–1.50 |
| Score/clock | 0.70–1.45 | 0.40–2.00 late clock |
| Capability confidence | 0.80–1.20 | 0.70–1.30 |
| Fatigue availability | 0.75–1.00 | 0.55 minimum when still medically available |

After multiplication, a valid candidate weight is clamped to 0.15–3.50 times its action-family base. Only invalidity can set a weight to zero.

### 12.3 Player and coach priority

The user’s saved tendencies provide 75% of the ordinary behavioral preference and coach instruction provides 25%.

The player share ranges from 60% for a low-trust young player under a strict coach to 90% for a trusted veteran leader. Explicit called plays can control the immediate action structure but do not permanently change tendencies.

### 12.4 Layered identity and its numeric boundaries

Rotation role, tactical role, and derived archetype are three separate layers with three separate numeric privileges. (**Locked structure**, OD-F. `SIMULATION_SPEC.md` §10.6 owns the behavioral contract and the stable IDs.)

| Layer | May affect | May never affect |
| --- | --- | --- |
| Tendencies | The player-preference share of action weight, via the §12.1 five-position multipliers | Ratings, capabilities, success probability |
| Tactical role | `RoleOpportunity` in the §12.2 action-weight table, and planned minutes/usage | Ratings, capabilities, success probability |
| Rotation role | Planned minutes and substitution priority | Ratings, capabilities, success probability |
| Derived archetype | **Nothing.** It is a read-only description. | Everything |

Numeric consequences:

- `RoleOpportunity` stays inside its existing 0.60–1.50 ordinary and 0.35–1.80 exceptional bounds (§12.2). Tactical role is the primary contributor to that factor and gains no separate multiplier elsewhere in the resolution chain. Role therefore changes how often a player attempts something, never how well it goes.
- No tactical role may contribute to any capability score, shot probability, contest strength, rebound candidate score, turnover risk, or foul curve.
- Derived archetype has no numeric representation in any resolution path. It is computed for display from body, ratings, and demonstrated profile, and computing it must be side-effect free. A balance profile containing an archetype-keyed coefficient is invalid.
- Capability plus context determines success. This is the only path to a better outcome, and it is fed by ratings, body, badges, fatigue, and match context — never by identity labels.

**Equal-budget build diversity and universal dominance.** Given an identical creation AP budget, materially different legal builds must produce materially different, non-dominated outcome profiles. The build-diversity report (§31 report 3) must show that no single legal combination of body, allocation, tendencies, and tactical role produces better results across every major observable. A universally dominant configuration is a release blocker (§28) and is corrected by changing capability weights, cost curves, or opportunity bounds — never by hiding the configuration from the Builder.

## 13. Shot and Manual Execution Balance

### 13.1 Open, balanced simulated make baselines

These are ordinary open attempts with good catch/balance, normal fatigue, no badge, and no unusual pressure. Intermediate ratings interpolate monotonically.

| Relevant rating | Close non-dunk | Valid dunk | Mid-range | Standard three | Free throw |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 40 | 40% | 62% | 25% | 20% | 50% |
| 55 | 50% | 72% | 34% | 29% | 64% |
| 70 | 60% | 82% | 43% | 37% | 76% |
| 85 | 69% | 90% | 51% | 44% | 86% |
| 99 | 78% | 96% | 58% | 50% | 94% |

A dunk percentage applies only after location, body, traffic, fatigue, and Dunk Threat make the dunk valid.

### 13.2 Probability floors and ceilings

| Shot family | Non-perfect floor | Non-perfect ceiling |
| --- | ---: | ---: |
| Close non-dunk | 2% | 88% |
| Dunk | 5% | 98% |
| Mid-range | 1% | 72% |
| Standard three | 1% | 62% |
| Deep three | 0.5% | 48% |
| Free throw | 35% | 97% |

These ceilings do not apply to a valid manual perfect release, which is 100% successful.

### 13.3 Contest penalties

Penalties are initial absolute percentage-point equivalents before shot-specific nonlinear resolution.

| Contest | Shot penalty | Perfect-zone effect |
| --- | ---: | --- |
| Open | 0 | Full baseline width |
| Light | −3 to −5 | −1 percentage point of meter width |
| Moderate | −8 to −12 | −2.5 points of width |
| Heavy | −16 to −24 | −5 points; zone may disappear |
| Smothered | −28 to −45 | No perfect zone |

Movement applies 0 to −8 points; poor catch quality 0 to −7; severe fatigue 0 to −10; clock desperation 0 to −12. Compatible penalties combine with diminishing returns and cannot make an invalid shot valid.

### 13.4 Perfect-zone width

Baseline width is expressed as a percentage of the complete timing meter for an open, balanced attempt.

| Relevant rating | Baseline perfect-zone width |
| ---: | ---: |
| 40 | 2% |
| 55 | 3.5% |
| 70 | 5% |
| 85 | 7% |
| 99 | 9% |

Close non-dunk and dunk challenges can use action-specific curves but retain the same visible-guarantee rule. The minimum visible valid zone is 1.25% of the meter. If context reduces it below that value, the attempt has no perfect zone and the UI must communicate that before input resolves.

Non-perfect manual timing can contribute from −18 to +10 probability points. The engine measures raw user timing without correction, magnetic snapping, or launch-day assistance.

## 14. Possession Event Targets

The following are stable target bands for mature seasons. They are fictional-league targets, not claims about one exact real-world season.

### 14.1 Team statistical targets

| Metric | HS | College | Development | Overseas | Top domestic pro |
| --- | ---: | ---: | ---: | ---: | ---: |
| Possessions/game | 61–72 | 64–73 | 88–101 | 70–82 | 96–103 |
| Points/possession | 0.91–1.05 | 0.98–1.10 | 1.00–1.12 | 1.00–1.13 | 1.08–1.18 |
| FG% | 39–47% | 42–49% | 43–50% | 43–51% | 45–51% |
| 3P% | 28–36% | 31–38% | 31–38% | 32–39% | 34–40% |
| 3PA/FGA | 24–39% | 32–46% | 32–47% | 30–46% | 36–49% |
| FT% | 62–76% | 67–79% | 68–80% | 69–82% | 73–83% |
| Turnovers/100 possessions | 15–24 | 15–21 | 14–20 | 13–19 | 11–16 |
| Offensive rebound % | 25–38% | 24–34% | 23–33% | 23–34% | 20–31% |
| Free-throw attempts/FGA | 18–38% | 20–38% | 18–36% | 20–39% | 18–34% |
| Assist % | 42–66% | 48–68% | 48–69% | 50–72% | 52–72% |

### 14.2 Game-shape targets

- Even-team home win rate: 53–56%; baseline 54.5%.
- Overtime frequency: 4–8% of games.
- Games decided by five or fewer points: 22–34%.
- Games decided by 20 or more: 8–18%, competition-dependent.
- Top domestic rotation players average 12–36 minutes depending on role; ordinary starters cluster at 27–35.
- Shipping tolerance for impossible or unreconciled box scores is zero.
- Team totals must emerge from possessions. Tuning may not directly force a final score.

### 14.3 Opposed event curves

For turnovers, steals, blocks, rebounds, and advantage creation, an ordinary ten-point capability edge should change the qualifying-event probability by approximately 15–25% relative. A 25-point edge should change it by 40–70% relative without exceeding event-specific caps.

| Event | Baseline after valid opportunity | Floor | Ceiling |
| --- | ---: | ---: | ---: |
| Lost-handle or bad-pass turnover | 8% | 1% | 35% |
| Valid strip/interception converts to steal | 28% | 5% | 65% |
| Valid block opportunity converts | 18% | 3% | 55% |
| Valid illegal-contact opportunity becomes a foul | 20% | 3% | 58% |
| Advantage action creates clear/breakdown advantage | 24% | 5% | 70% |
| Qualifying pass becomes credited assist if shot scores | 74% | 55% | 95% |
| Offensive team wins rebound | competition target | 12% | 48% |
| Immediate putback after offensive rebound | 23% | 8% | 48% |

These are conditional event rates. They are not applied once per possession without candidate generation.

## 15. Fatigue, Condition, and Recovery

### 15.1 Acute fatigue

Acute fatigue is hidden from 0 to 100 and shown through a readable condition state.

```text
BaseFatiguePerActiveMinute = 1.20 × (1 - 0.42 × NormalizedRating(Stamina))
```

Additional load per high-intensity action ranges from 0.15 to 0.80. Transition sprint, repeated creation, full-pressure defense, contact finishes, and aggressive rebounding cost more. Bench recovery is 1.5 fatigue per real game minute, modified by Stamina from 0.85× to 1.20×.

| Acute fatigue | Label | Typical effect |
| ---: | --- | --- |
| 0–24 | Fresh | No penalty |
| 25–44 | Working | Up to −2 capability in repeated high-intensity actions |
| 45–64 | Tired | −2 to −6 affected capability; slower recovery |
| 65–79 | Exhausted | −5 to −10; higher mistake and injury-candidate rates |
| 80–100 | Spent | −8 to −16; substitution strongly preferred |

Fatigue never subtracts one flat value from all ratings.

### 15.2 Between-game condition

Healthy players recover 18 condition points per ordinary rest day, 10 on travel days, and 4 on dense game days. Treatment and facilities modify recovery by −20% to +25%. Condition below 60 raises fatigue accumulation; below 40 raises injury-candidate rate; below 25 normally triggers medical or coach restriction.

## 16. Injury and Durability

### 16.1 Injury candidates

Baseline resolved injury incidents per 1,000 active player-minutes:

| Competition | Rate |
| --- | ---: |
| High school | 0.35 |
| Summer circuit | 0.55 |
| College | 0.44 |
| Domestic development | 0.54 |
| Overseas | 0.50 |
| Top domestic pro | 0.48 |

The match engine first emits contextual candidates. The Health service applies durability, fatigue, contact, workload, surface/travel, existing injury, and recovery modifiers.

### 16.2 Durability

Hidden durability uses 0–100 and is generated with a population mean of 64 and standard deviation of 14, clipped to 20–95.

| Hidden value | Reliable public label | Candidate-rate multiplier |
| ---: | --- | ---: |
| 20–39 | Fragile | 1.40× |
| 40–54 | Concerning | 1.18× |
| 55–69 | Typical | 1.00× |
| 70–84 | Durable | 0.82× |
| 85–100 | Exceptional | 0.68× |

The label is reliable but does not reveal the precise value. Injury history can move the hidden value by −1 to −12; exceptionally successful long-term recovery can restore at most half of injury-caused durability loss.

### 16.3 Severity distribution

| Severity | Share of resolved incidents | Typical missed time |
| --- | ---: | --- |
| Knock/temporary limitation | 58.02% | None to one game |
| Minor | 26% | 2–14 days |
| Moderate | 11% | 2–8 weeks |
| Major | 4.3% | 2–9 months |
| Catastrophic | 0.65% | 6–18 months, meaningful cap/decline risk |
| Career-ending | 0.03% | Career ends unless Second Chance is used |

Family and action context alter this table. The full-career user target for basketball-caused career-ending injury is 0.4–0.8% among careers lasting at least ten competitive seasons.

### 16.4 Play-through and treatment

| Choice | Short-term availability | Aggravation multiplier | Recovery effect |
| --- | --- | ---: | --- |
| Rest | No play | 0.50× | Baseline best nonsurgical recovery |
| Rehabilitation | Limited/no play | 0.70× | Replaces training; improves recurrence outlook |
| Play through, minor | Reduced | 1.50× | Recovery 10–30% longer |
| Play through, moderate | Strongly reduced | 2.50× | Recovery 25–60% longer |
| Surgery | No play | Procedure-specific | Higher immediate risk, improved long-term outcome where indicated |
| Second opinion | No direct effect | 1.00× | Narrows or revises uncertainty |
| Specialist | No direct effect | 0.85–0.95× | Costs money; never guarantees success |

Doctors normally prohibit play for catastrophic injuries, unstable fractures, severe neurological/cardiac conditions, and other content-defined unsafe states.

## 17. Chemistry, Trust, Morale, and Environment

### 17.1 Team Chemistry

Chemistry is hidden 0–100 and displayed as a letter grade.

| Score | Grade |
| ---: | --- |
| 93–100 | A+ |
| 85–92 | A |
| 77–84 | B |
| 69–76 | C |
| 60–68 | D |
| 0–59 | F |

Chemistry affects only coordination-dependent events. At the extremes, it ranges from −4% to +4% relative pass/catch, help/recovery, screen, rotation, and late-clock coordination probability. Aggregate effect is capped at ±2.0 points per 100 possessions against an otherwise identical opponent.

### 17.2 Trust

Coach and institution-equivalent trust use separate hidden 0–100 values with qualitative labels.

| Trust | Typical access |
| ---: | --- |
| 0–24 | Minimal tolerance; no strategic influence |
| 25–49 | Ordinary assigned role |
| 50–64 | Can make low-stakes suggestions |
| 65–79 | Can call limited plays and influence tactical discussion |
| 80–92 | Veteran-leader influence and meaningful suggestions |
| 93–100 | Franchise/program icon influence; organization retains final control |

Trust changes role opportunity and organizational listening. It never changes the make probability of an identical shot. A new coach inherits 30–55% of Program/Athletic Department/Front Office standing into initial Coach Trust, capped at 65.

### 17.3 Morale and professionalism

Morale can modify decision confidence, effort selection, and recovery by at most ±3%. Professionalism can modify coach tolerance, event weights, and negotiation/reputation results by at most ±8%. Neither modifies raw shooting ratings or serves as comeback logic.

### 17.4 Home environment and pressure

- Equal-team home win target: 54.5%, allowed 53–56%.
- No single home modifier may exceed four absolute probability points.
- Combined environment contributions are capped at +2.5 points per 100 possessions.
- Pressure can shrink a manual perfect zone by at most 20% relative, visibly.
- Pressure can change simulated decision/execution noise by at most five absolute probability points.
- Momentum is disabled in the version 0.1 baseline. Enabling it requires a separate no-rubber-band report.

### 17.5 Relationship labels

Each relationship dimension uses a hidden −100 to +100 value. The visible qualitative summary is selected from the strongest relevant dimensions and recent causal history.

| Dominant net relationship state | Ordinary label family |
| ---: | --- |
| −100 to −61 | Hostile / bitter / estranged |
| −60 to −21 | Strained / distrustful / tense |
| −20 to +20 | Uncertain / distant / professional |
| +21 to +60 | Friendly / respectful / supportive |
| +61 to +100 | Close / loyal / devoted |

An ordinary interaction moves one relevant dimension by 2–8 points. A major betrayal, sacrifice, commitment, breakup, or reconciliation can move it by 10–35. No generic repeated interaction can be farmed after three uses without a cooldown or changed circumstance.

### 17.6 Scouting knowledge and staleness

Current OVR and complete rosters are visible for materialized teams. Background high schools expose Team Power Rating and summary information rather than a fictional complete roster. Once relevance promotion materializes the roster, current OVR is visible under the normal rules. Detailed NPC attributes, tendencies, limitations, and evaluations use knowledge confidence from 0–100.

| Knowledge source | Confidence gain |
| --- | ---: |
| One game sharing the court | 8–15 |
| One game observed but no shared minutes | 3–7 |
| Recent coach scouting report | 15–35 |
| Athletic department/front office evaluation | 20–45 |
| Teammate season familiarity | 2–5 per meaningful week, capped by access |

At 85+ confidence, exact detailed attributes can be shown. At 60–84, attributes show narrow three-to-five-point ranges or qualitative certainty. At 30–59, ranges span 6–12 points. Below 30, only broad strengths and weaknesses are dependable.

A player becomes fully personally scouted after either eight meaningful shared games or 240 shared competitive minutes, provided no staleness trigger has occurred. The following reduce confidence:

- A net change of three or more rating points since the observation: −20 to −45.
- A significant injury or return from major injury: −25 to −55 for affected information.
- An offseason at age 30+: −10 to −25.
- Twelve months without observation: −15, then −5 per additional season.

Sufficient current coach, athletic-department, or front-office evaluation can refresh stale data. The user can unknowingly rely on stale information when neither personal familiarity nor organizational evaluation is sufficient.

## 18. Recruiting and Pathway Access

### 18.1 Evaluation score

Offers require formal eligibility and roster need before probability is evaluated.

```text
RecruitingEvaluation =
  0.40 × BasketballEvaluation
  + 0.15 × RecentPerformance
  + 0.10 × CompetitionAndExposure
  + 0.10 × TacticalAndRosterFit
  + 0.10 × AcademicEligibility
  + 0.05 × BasketballReputation
  + 0.05 × RelationshipAccess
  + 0.05 × PublicProfile
```

Basketball Evaluation combines current ability, age-adjusted projection, body/position need, role-relative performance, health information, and scouting confidence. Followers cannot compensate for inability or ineligibility.

### 18.2 Program interest

```text
OfferChance = logistic((RecruitingEvaluation - ProgramThreshold) / 7)
              × RosterNeed
              × OfferCapacity
```

- `RosterNeed` ranges from 0.65 to 1.35.
- `OfferCapacity` is zero when no legitimate place exists.
- A formal offer generally requires at least 70% interest and an open offer slot.
- Conditional offers can begin at 55% interest if the unmet condition is explicit.
- Interest moves by no more than 18 points from one ordinary game and no more than 30 from a major showcase or severe event.

### 18.3 Offer-count targets

| Prospect state | Legitimate accessible offers at decision point |
| --- | ---: |
| Below outside-program standard | Guaranteed local public school only |
| Developing/local contributor | Local plus 0–2 alternatives |
| Strong regional prospect | 3–7 alternatives |
| National prospect | 6–14 alternatives |
| Elite national prospect | 10–20 alternatives |

The UI presents every accessible option. Twenty is a content/readability guardrail, not a hidden deletion rule; excess equivalent offers should be prevented through program capacity and realistic competition.

### 18.4 Transfer uncertainty

Research confidence uses 0–100 internally:

- Public facts start at 100 confidence and cannot become secret.
- Ordinary program claims start at 55–75.
- Reliable advisor review adds 10–25.
- Visit/relevant relationship adds 8–20.
- Elite information access can reach 95 but never guarantees hidden personal chemistry or future events.

Known upside and risk effects are generally bounded to ±15 trust, ±12 role-opportunity points, ±10% development opportunity, and phase-appropriate money/cost changes. Larger consequences require a clearly signaled major condition.

## 19. Academics

GPA uses 0.0–4.0.

| GPA | State |
| ---: | --- |
| 3.5–4.0 | Strong standing |
| 2.5–3.49 | Good standing |
| 2.0–2.49 | Eligible but at risk |
| 1.75–1.99 | Probation; participation can be restricted |
| Below 1.75 | Ineligible |

The standard participation threshold is 2.0. A probation rule may temporarily permit participation according to fixed state/program rules, but a player below 1.75 cannot compete.

A standard study activity improves the term projection by 0.08–0.16 GPA before diminishing returns. Missing required study or accumulating absences can reduce it by 0.05–0.20. No single ordinary weekly decision changes final GPA by more than 0.15. Major circumstances are explicitly labeled.

### 19.1 College eligibility balance boundary

The college structure is fixed: five academic years contain no more than four competition seasons, the player may use one ordinary redshirt, and no more than one rare approved medical-extension year may be added. Postseason participation consumes the competition season. These are structural invariants, not balance knobs.

The exact ordinary-redshirt appearance threshold is a deferred tuneable. It must be universal, player-visible before participation, and calibrated without changing the five/play-four envelope, creating repeat ordinary redshirts, or allowing postseason participation to preserve the season.

## 20. Reputation, Followers, and Social Reach

### 20.1 Follower scale

Follower count is exact and visible. Influence uses a logarithmic reach score so celebrity matters without linear runaway.

```text
ReachScore = clamp(log10(followers + 10) / 7, 0, 1)
```

| Followers | Public reach |
| ---: | --- |
| 0–999 | Local/private |
| 1,000–9,999 | Emerging local |
| 10,000–99,999 | Regional |
| 100,000–999,999 | National |
| 1,000,000–9,999,999 | Star |
| 10,000,000+ | Global celebrity |

Freshman careers begin with 50–500 followers, modified by background and the optional three-game prologue but never by paid cosmetics.

The three prologue games form one bounded evaluation window. Starting follower count, reputation, and offer quality use aggregate prologue evidence together with prospect profile, position, physical tools, background, and coach evaluation. No single game supplies more than 50% of the total prologue-performance contribution, and the complete prologue-performance contribution cannot move the player outside the documented freshman starting bands by itself.

Skipping the prologue uses neutral performance evidence. It provides no hidden win, loss, statistical line, Attribute Points, fatigue, injury roll, follower penalty, reputation penalty, or offer penalty. The generated prospect profile and non-performance circumstances still produce a valid freshman starting state and the guaranteed local public-school placement.

### 20.2 Growth and loss

Ordinary gains use both a flat component and a percentage component:

```text
FollowerDelta = EventBase × Performance/Reputation Multiplier
                + CurrentFollowers × EventRate
```

- Ordinary positive weekly change: 0–3% plus a phase-scaled flat gain.
- Major achievement: 5–25% plus flat gain.
- Ordinary negative event: −1% to −8%.
- Severe scandal or public consequence: −10% to −45%.
- No ordinary social reply can add or remove more than 12%.
- Repeating identical post templates applies 70%, 45%, then 25% effectiveness before cooldown.

### 20.3 Influence bounds

- Recruiting attention: at most +12% relative offer discovery, never formal eligibility.
- NIL/sponsorship deal frequency: up to +100% at extreme reach.
- NIL/sponsorship value: 0.80× to 2.25× before agent negotiation.
- Media pressure: 0% to +20% pressure-event frequency.
- Reputation consequences remain separate; followers do not equal respect or professionalism.

## 21. NIL, Agents, and Negotiation

### 21.1 NIL value bands in world-start dollars

| Phase/reach | Typical deal value | Rare upper tail |
| --- | ---: | ---: |
| HS local | $100–$2,500 | $10,000 |
| HS regional/national | $2,500–$40,000 | $250,000 |
| Exceptional HS celebrity | $40,000–$250,000 | $1,000,000 |
| College local | $500–$10,000 | $50,000 |
| College regional/national | $10,000–$250,000 | $1,000,000 |
| Elite college celebrity | $250,000–$1,500,000 | $3,500,000 |

Deal value is driven by reach, basketball reputation, market, exclusivity, deliverables, duration, risk, and negotiation. A large follower count cannot create a deal where state/program rules prohibit it.

### 21.2 Advisor and agent grades

Displayed grades reliably describe quality.

| Grade | Negotiated value improvement | Hidden-risk discovery | Typical commission |
| --- | ---: | ---: | ---: |
| Self | 0% | 35% | 0% |
| Parent | 1–2% | 50% | 0% |
| D | 2–3% | 55% | 3–5% |
| C | 3–5% | 65% | 4–7% |
| B | 5–8% | 78% | 5–8% |
| A | 8–11% | 90% | 6–10% |
| A+ | 10–13% | 96% | 8–12% |

Negotiation improvements apply to expected guaranteed economic value, not necessarily headline salary. An agent cannot invent leverage, offers, or eligibility.

Upfront fees range from $0–$1,000 for small HS representation, $1,000–$25,000 for major NIL representation, and $10,000–$100,000 for professional representation. Contracts last one to three seasons. Early termination commonly costs 25–100% of remaining projected fixed fees plus authored relationship consequences.

### 21.3 Professional endorsement bands

| Public/market state | Typical annual endorsement value | Rare upper tail |
| --- | ---: | ---: |
| Emerging pro | $10,000–$100,000 | $300,000 |
| Established rotation player | $75,000–$600,000 | $1,500,000 |
| Star | $500,000–$3,000,000 | $8,000,000 |
| Global celebrity | $3,000,000–$12,000,000 | $25,000,000 |

Endorsement value depends on followers, basketball reputation, geography, professionalism, exclusivity, deliverables, and current availability. It cannot affect roster eligibility or basketball ratings.

### 21.4 Institutional sponsorship bands

Institutional sponsorship definitions use named world-start annual value bands. These values affect the fictional partnership's scale and presentation; they do not become player cash unless a separate eligible NIL or endorsement contract is offered.

| Band key | Typical annual value | Rare upper tail |
| --- | ---: | ---: |
| `institutional-local` | $5,000–$75,000 | $150,000 |
| `institutional-regional` | $50,000–$400,000 | $1,000,000 |
| `institutional-national` | $300,000–$3,000,000 | $8,000,000 |
| `institutional-global` | $2,000,000–$12,000,000 | $30,000,000 |

The sponsorship schema's player-facing NIL and endorsement keys map directly to Sections 21.1 and 21.3. Institutional keys are restricted to team, competition, award, and media targets.

## 22. Professional Contracts and Roster Interest

All values are in world-start dollars before the economy index.

### 22.1 Salary bands

| Market role | Top domestic annual value |
| --- | ---: |
| Fringe/minimum | $800,000–$1,800,000 |
| Reserve | $1,800,000–$5,000,000 |
| Rotation player | $4,000,000–$12,000,000 |
| Starter | $10,000,000–$26,000,000 |
| Star | $24,000,000–$45,000,000 |
| Superstar | $40,000,000–$62,000,000 |

| Alternative pathway | Annual value |
| --- | ---: |
| Domestic development | $25,000–$650,000 |
| Overseas reserve/development | $40,000–$150,000 |
| Overseas rotation/starter | $120,000–$750,000 |
| Overseas star | $700,000–$2,500,000 |

The $25,000–$650,000 domestic-development range is fixed by the later, level-specific system. Balance owns the offer distribution inside that range. Values near $650,000 must remain rare and require meaningful market leverage; calibration may reshape frequency but cannot lower the structural ceiling.

### 22.2 Rookie structures

Top domestic rookie contracts last three to five seasons according to draft tier and team options:

- Elite selections: four guaranteed seasons plus an optional fifth-year mechanism where applicable.
- Standard drafted selections: two or three guaranteed seasons plus one or two team-controlled seasons.
- Late/undrafted signings: one to three seasons with weaker guarantees.

Total guaranteed value ranges from $2.5 million for marginal entrants to $48 million for elite selections before negotiation. Contract content remains fictional and does not copy a licensed league agreement.

The complete playing-contract term and every option must fit within the player's remaining portion of the 25-professional-season maximum across all professional levels. Validation includes non-guaranteed seasons. Balance may tune term and option distributions only after this structural eligibility check passes.

### 22.3 Roster-interest score

```text
RosterInterest =
  0.38 × CurrentBasketballValue
  + 0.18 × RoleFit
  + 0.12 × RecentAvailability
  + 0.10 × AgeAndProjection
  + 0.08 × MarketScarcity
  + 0.06 × Professionalism
  + 0.05 × PriorRelationship
  + 0.03 × CommercialValue
```

Commercial value can break a close tie but cannot keep a clearly unqualified player in the top league. No viable offer is a normal career outcome and never qualifies for Second Chance.

Comeback-offer likelihood distributions are provisional until the unified career-year and professional-service clock is implemented and verified across pathways. Recalibration may change legitimate offer frequency only; career-state and ending legality remain with their owning design source and are not balance parameters.

## 23. Cash, Living Costs, Assets, and Investment

### 23.1 Economy index

Each career begins at index 1.00. Annual inflation is generated once from 1.5–3.5%, centered at 2.2%, and remains stable enough to avoid wild economic drift. Salaries, recurring costs, asset prices, and sponsorship markets use the same index.

### 23.2 Recurring living costs

| Phase/lifestyle | Monthly baseline |
| --- | ---: |
| Dependent HS player | $0–$250 discretionary |
| College housing/support covered | $150–$1,200 |
| Development player | $2,000–$5,000 |
| Overseas player | $1,500–$7,000 depending on team support |
| Top domestic modest | $7,500–$15,000 |
| Top domestic wealthy | $15,000–$50,000 |
| Luxury lifestyle | $50,000–$250,000+ |

Lifestyle choice affects possessions, status, relationships, and events but never directly boosts ratings.

Income uses simplified automatic withholding so displayed spendable cash remains credible without a tax minigame. Effective withholding ranges from 10–25% for HS/college NIL income, 20–38% for development or overseas income, and 28–42% for top-domestic professional income. Contract and deal previews show gross value, agent share, estimated withholding, and expected net value.

### 23.3 Assets

- Vehicles generally depreciate 10–25% in year one and 5–15% annually thereafter, with collector exceptions authored explicitly.
- Houses change value with the economy and local asset modifier, ordinarily −8% to +12% annually.
- Ordinary resale friction is 3% for houses and 8% for cars/luxury goods.
- Upkeep ranges from 1–4% of purchase price annually for houses and 5–15% for vehicles/luxury assets.
- Assets cannot be repeatedly bought and sold for guaranteed profit.

### 23.4 Simple investment fund

The fund is diversified, fee-free, unleveraged, and has no user-selectable risk level.

```text
MonthlyLogReturn = clamp(
  Normal((ln(1.05) - 0.5 * 0.12^2) / 12, 0.12 / sqrt(12)),
  -0.12,
  +0.12
)
```

Before monthly clipping, this log-return drift targets an approximate 5% long-run nominal annual arithmetic expectation with 12% annualized volatility. Individual years can lose money. There are no loans, leverage, options, shorting, day trading, fees, or guaranteed returns.

The ±12% monthly clipping changes the realized distribution and must be explicitly reverified rather than assumed neutral. Under independent monthly draws, an analytical check of the stated clamped-normal model yields approximately **4.9968%** expected annual arithmetic return and **12.64%** annual return standard deviation; the clipping changes the mean by about **-0.32 basis points** from the unclipped 5% target. The required million-path economy report must reproduce those derived values within its declared tolerance and measure tail behavior and any deposit/withdraw interaction before the value is ship-approved.

The calendar applies and autosaves the month’s return before accepting deposits or withdrawals at that boundary. The future return stream is seeded and hidden. Reloading cannot change it. Deposits and withdrawals remain available outside locked decisions.

## 24. Rare Career Events

### 24.1 User death hazard

The 1% target is a complete-career probability, not an annual roll.

The phase hazards below are provisional calibration seeds. They must be recalibrated after the unified career-year and professional-service clock is implemented so a pathway change cannot create duplicate or skipped exposure. The approximately 1% lifetime intent remains the acceptance target; the table is not a set of shipping annual probabilities until that clock-based report passes.

| Phase | Baseline hazard per active career-year |
| --- | ---: |
| High school | 0.010% |
| College | 0.020% |
| Development/overseas | 0.030% |
| Top domestic pro, ages 19–29 | 0.025% |
| Top domestic pro, ages 30–39 | 0.035% |
| Active career, age 40+ | 0.045% |

Authored risky circumstances can multiply the current event hazard from 0.25× to 8.0×, but ordinary risk cannot exceed 0.25% in one year. A clearly extraordinary causal event may use a content-specific probability and must be included in aggregate career tests.

Required result across complete careers reaching at least ten competitive seasons: 0.90–1.10% user deaths, with a point target of 1.00%.

### 24.2 NPC death

Named NPCs provisionally use 1.25× the equivalent user hazard. These distributions require the same post-clock recalibration as the user table. The required named-NPC lifetime target remains 1.10–1.40%, centered near 1.25%.

Surfaced death-story controls:

- At least 12 ordinary weeks between unrelated named death stories shown to the user.
- No more than two unrelated named death stories surfaced in one career season.
- Death can still resolve in world state when presentation is deferred.
- Closely related authored incidents can override the presentation cooldown only with explicit content approval.

### 24.3 Cause tone mix

After a death is validly selected:

| Cause family | Target share |
| --- | ---: |
| Realistic accident, illness, or natural cause | 75% |
| Obscure but plausible | 20% |
| Clearly fictional absurdity | 5% |

Tone selection cannot alter the death probability. Absurd causes remain deadpan, non-graphic, and exceptionally rare.

### 24.4 Career-ending incarceration

For a player who never enters a meaningful legal-risk state, lifetime career-ending incarceration should remain below 0.15%. Across all user careers, including authored choices and consequences, the launch target is 0.25–0.60%.

Risk arises through causal events, choices, relationships, and unresolved legal state. There is no context-free annual prison lottery. A single ordinary low-risk reply or social choice cannot cause career-ending incarceration without intervening escalation and confirmation of risk.

### 24.5 Second Chance restoration

Qualifying events are death, career-ending incarceration, and career-ending injury. For each distinct qualifying event:

- One successfully completed rewarded ad fully reverses the ending.
- Health, eligibility, ratings, caps, badges, cash, trust, contract, and roster position return to the valid pre-event state.
- Condition returns to 100 and the career can continue.
- There is no balance penalty, recurrence modifier, reputation penalty, or hidden reduced potential.
- The event cannot offer another Second Chance if the same event transaction is replayed.
- A later distinct qualifying event can create its own offer.

Normal retirement, maximum seasons, declining talent, and lack of roster interest remain ineligible.

## 25. Advertising and Paid Respec Balance

### 25.1 Interstitials

- Baseline cooldown: 10 minutes of active play.
- Allowed cooldown range: 8–12 minutes.
- Maximum: two interstitials in any rolling 30 active minutes.
- Maximum: three interstitials in one continuous session.
- A genuine background break of at least 20 minutes resets the session cap but not a protected emotional sequence.
- Offline time, menus left idle, ads, and background time do not count as active play.

Ads remain prohibited in all contexts listed in the GDD.

### 25.2 Badge respec

The paid badge respec:

- Can be purchased once per career.
- Refunds exactly all BDP spent through user allocation.
- Does not remove total earned BDP.
- Does not refund or remove free narrative tiers; those stay attached to their badge.
- Changes no attribute, cap, tendency, health, economy, or event probability.
- Has one fixed regional storefront price tier and no randomized discount or urgency mechanic.

The exact real-money price is a publishing decision and is intentionally not set by gameplay balance.

## 26. Career Legacy Assessment

The ending evaluates what naturally happened. It does not ask the user to select a desired story.

Six independent axes score 0–100:

- Individual basketball achievement.
- Team achievement.
- Career longevity and resilience.
- Financial outcome.
- Relationships and public standing.
- Historical distinctiveness and defining moments.

The descriptive summary selects the player’s two strongest axes, one defining weakness or unresolved “what if,” and actual recorded turning points. It must support successful reserve, overseas icon, loyal program figure, injury comeback, wealthy role player, and all-time-great careers.

If a compact career tier is displayed:

```text
LegacyScore =
  0.25 × strongest axis
  + 0.20 × second-strongest axis
  + 0.15 × third-strongest axis
  + 0.40 × mean of the remaining three axes
```

The formula intentionally rewards multiple kinds of careers. It has no effect on gameplay rewards, recruiting, contracts, or simulation results.

## 27. Calibration Sample Sizes and Tolerances

### 27.1 Required sample sizes

| Report | Minimum sample |
| --- | ---: |
| One isolated probability/function boundary | 100,000 resolutions per test point |
| One-attribute sensitivity sweep | 50,000 matched resolutions per rating step |
| Competition team-stat calibration | 100,000 complete games per competition profile |
| Play/Sim/Skip parity | 50,000 matched game triplets |
| Tier A/Tier B parity | 250,000 matched input pairs per competition |
| Progression and aging | 1,000,000 complete player careers |
| Recruiting/pathway distributions | 1,000,000 prospect cohorts |
| User death target | 5,000,000 complete careers |
| Named-NPC death and clustering | 5,000,000 complete careers/world samples |
| Economy/investment exploit check | 1,000,000 30-year economy paths |

### 27.2 Acceptance tolerances

- Team shooting percentages: target band and ±0.5 percentage points between equivalent execution tiers.
- Possessions and points: target band and ±1.5% relative between Tier A and Tier B.
- Turnover, rebound, assist, foul, steal, and block rates: ±2.0% relative Tier A/Tier B, or ±0.35 absolute percentage points when the event is rare.
- Rotation-role mean minutes: ±0.75 minutes between equivalent tiers.
- Play/automatic, full Sim, and Skip distributions: no statistically meaningful difference after correcting for intentionally supplied manual input.
- Attribute sensitivity: 95% confidence interval must show the correct direction and at least the documented minimum practical effect from rating 50 to 80.
- Death targets: Wilson 95% confidence interval must lie inside the specified lifetime band.
- Economy: no deterministic deposit/withdraw sequence may produce risk-free profit above the economy index.
- Investment clipping: the million-path report must compare the realized clipped annual arithmetic mean and volatility with the unclipped 5%/12% targets and document any permitted recalibration.

Statistical significance without a meaningful effect is insufficient. Reports include effect size, interval, seed range, balance version, and sample count.

## 28. Exploit and Fairness Guardrails

The following are release blockers:

- Playing instead of simulating produces more AP, badge progress, favorable injury odds, or contract value from identical underlying performance.
- Repeating low-stakes games bypasses seasonal development caps.
- Force-quitting changes a resolved game, injury, offer, investment return, death, prison result, or purchase effect.
- One tendency configuration dominates every role and lineup.
- One legal body/build combination produces better results in every major observable.
- Followers alone create elite offers or roster spots.
- Cash purchases create rating, cap, health, or opportunity advantages.
- Chemistry, home court, morale, badges, or pressure exceed their documented caps.
- Tier B world simulation systematically creates different player archetypes, award leaders, or career survival than Tier A.
- Rare-event probability is interpreted as a visible annual chance or clusters implausibly.
- Any resolution path reads Current Overall, Maximum Potential Overall, or Projected Peak as a simulation input.
- Changing a player's simulation detail level changes his ratings, caps, body, or accumulated development.
- Creation Attribute Points survive build confirmation in any form.
- A realized body leaves the projected adult range stored at confirmation, or a body increment alters a rating without a separate visible effect.
- A derived archetype grants any capability, opportunity, attribute, or probability.
- Projected Peak is displayed as a single value, or is systematically optimistic beyond its approved bias tolerance.

## 29. Implementation Migration

This section describes the **actual state of the Godot repository**, not the archived React Native / Expo prototype. Items 1–4 in §29.1 were satisfied by the Godot simulation-core baseline; items 5–15 by the Stage 2 player-development domain.

### 29.1 Satisfied in the current Godot core

1. All 20 canonical attributes exist as a typed domain model (`AttributeKey`, `PlayerAttributes`). The archived 16-attribute model is gone, not merely deprecated.
2. Free Throw, Offensive IQ, Defensive IQ, and Vertical are present in the attribute domain and in match profiles.
3. Active ratings validate at 25–99 with sub-25 rejection (`Rating`).
4. Randomness flows through an injected, versioned, label-derived `RandomSource`; domain code calls no global RNG.
5. The role-neutral Overall formula, Maximum Potential, and Projected Peak exist as one canonical implementation each (`OverallCalculator`, `ProjectedPeakCalculator`, `DevelopmentProjection`).
6. The Builder, creation budget, AP economy, exact per-attribute cap model, and progression system exist (`BuilderService`, `CreationBudget`, `AttributeCostTable`, `AttributeCaps`, `DevelopmentService`).
7. `BodyProfile` carries standing reach. Maturity profile, stored projected adult range, realized growth, and the increment ledger exist (`BodyMaturationState`, `BodyRange`, `GrowthIncrement`).
8. `TacticalRole` is the eleven locked version 1.0 IDs. The `balanced` default is gone.
9. `RotationRole` is the seven locked usage-intent IDs. Availability facts are no longer overloaded onto it.
10. Balance ledgers exist for AP sources, cap changes, and body increments (`AttributePointLedger`, `CapChangeLedger`, growth-increment ledger). BDP, economy, and rare-event ledgers remain outstanding.
11. Shared career-year completion receipts exist (`CareerYearReceipts`) and are honoured by every executor.
12. Versioned, validated balance profiles exist for ratings, builder, and progression (`RatingsProfile`, `BuilderProfile`, `ProgressionProfile`, `BalanceProfileSet`), each publishing named tunables with units and safe ranges.
13. One canonical development contract binds the user, the full-detail NPC allocator, and the aggregate executor to the same costs, caps, receipts, and source ledger (§9.7).
14. Detail-promotion invariance is implemented and tested (`PlayerDevelopmentState.invariant_signature`).
15. A deterministic migration exists for every player-system schema change made in Stage 2 (`PlayerSystemMigration`).

Satisfied here means the contract exists, is implemented, and is tested. It does **not** mean the values are calibrated: the §31 reports at §27.1 sample sizes have not been run, and §32 governs which values remain provisional.

### 29.2 Outstanding

Items 1–3 below were satisfied before Stage 4 or by it; they are retained with their resolution recorded rather than deleted, because §29.3 forbids marking an item satisfied merely because a type exists.

1. ~~`CapabilityCalculator` implements three capabilities against the twenty required by §5.2.~~ **Resolved before Stage 4.** All twenty §5.2 capabilities plus the four §7.3 physical capabilities exist in `RatingsProfile` with the specified weights, and Stage 4 verified every weight row against this document.
2. ~~`ShotResolver` contains anonymous numeric literals inside resolution code.~~ **Resolved.** Every shot, contest, and continuation constant is a named tunable on `SimulationBalanceProfile` with a unit and a safe range, and Gate B0 rejects one outside its range — which it did during Stage 4 calibration, catching a kick-out share pushed past its declared bound.
3. ~~Attribute monotonicity tests are explicitly deferred.~~ **Resolved by Stage 4.** `calibration/runners/run_attribute_sensitivity.gd` verifies, for all twenty attributes: addressability, monotonic direction across ratings 40/50/65/80/90, and a meaningful 50→80 effect; and for every capability weighting an IQ rating alongside a different primary, that the IQ movement stays under 60% of the primary's. It runs in the pull-request gate at the §27.1 isolated-boundary sample size of 100,000 resolutions per test point. **What remains uncovered** is the match-level half of §8 of `SIMULATION_SPEC.md`: box-score effects, role-relative value, team impact, and fatigue/availability effects per attribute are not yet measured.
4. BDP, economy transaction, and rare-event hazard ledgers do not exist.
5. No career or world domain is implemented. Career-year receipts exist as a type but nothing advances the calendar, so professional-service credit and offseason scheduling are untested end to end.
6. Balance profiles are typed domain value objects rather than authored Resources under `resources/balance/` as `GODOT_TDD.md` §5.6 specifies. The domain purity boundary (§5.1) forbids domain code from loading Resources, so the intended shape is an infrastructure loader mapping authored `.tres` files onto these value objects. That loader is not written, and no persistence layer exists to pin a profile version per career.
7. Seasonal AP availability, the projected-peak model, and cap distributions are implemented but uncalibrated; reports 3, 7, 15, and 16 have not been run.
8. `PlayerSystemMigration` operates on record dictionaries because no SQLite persistence layer exists yet to supply real rows.

### 29.3 Standing rules

- Establish frozen baseline reports before changing formulas so improvements are measured rather than assumed.
- Preserve hidden fractional progress through migrations.
- Do not weaken typed domain contracts or tests to accommodate incompatible archived schemas.
- Do not mark a §29.2 item satisfied because a type exists. It is satisfied when the contract is implemented, tested, and its required report passes.

Existing values are retained only when they pass the new contract and calibration requirements.

## 30. Balance Approval Gates

### Gate B0 — Configuration integrity

- One validated profile loads offline.
- Every tuneable has a name, unit, safe range, and version.
- Deterministic golden seeds pass.

### Gate B1 — Ratings and builder

- All 20 attributes satisfy monotonic observable tests, and each produces at least one statistically detectable required observable (§8 of `SIMULATION_SPEC.md`).
- OVR is role-neutral and population distributions match targets.
- Weak, experimental, specialist, and conventional builds are all legal and distinct.
- **Creation-budget exhaustion:** confirmation is impossible while creation AP remains, no path carries creation currency into the career, and no refund, conversion, or banking route exists (§7.1).
- **Builder profile OVR distributions:** completed builds satisfy the locked bands in §7.3.2 per prospect profile, extreme specialists stay within approximately two OVR of their band, and no ordinary completed build exceeds approximately 54 OVR. The empty preview is verified to be non-confirmable and is reported separately from completed builds.
- **Equal-budget build diversity and universal-dominance rejection:** no legal configuration dominates across every major observable at equal budget (§12.4).
- **OVR truthfulness without simulation input:** displayed Overall matches the formula applied to current ratings within the one-point rounding boundary, and a dependency check proves no resolution path reads Overall, Maximum Potential, or Projected Peak (§6.2).
- **Three-value labeling:** Current Overall, Maximum Potential, and Projected Peak are distinct, distinctly labeled, and satisfy the ordering rules in §6.3.

### Gate B2 — Basketball distributions

- Every competition profile satisfies Section 14.
- Roles, rotations, and player-stat leaders remain plausible.
- Perfect-window and no-perfect-zone rules pass.

### Gate B3 — Career progression

- Million-career progression, cap, aging, mileage, and injury reports pass.
- Played and simulated development are equivalent.
- Elite outcomes remain rare without making ordinary careers static.
- Cross-level tests prove one career year cannot duplicate age, natural development or decline, generic offseason development, or professional-service resolution.
- **Career peak distribution:** the locked §8.4 bands are reproduced, including a practically nonexistent population above 95 OVR.
- **Projected-peak honesty:** realized peaks fall inside the displayed range at the §6.3 coverage rate, median range width stays inside its guardrail, and median signed error stays within ±2 OVR.
- **User/NPC progression parity:** the manual path and the full-detail allocator produce statistically indistinguishable rating, cap-attainment, peak-age, and decline distributions from equivalent opportunity (§9.7).
- **Detail-promotion invariance:** matched cohorts simulated at different detail levels produce identical ratings, caps, and body state for the same seed, and aggregate-resolved cohorts match full-detail cohorts within §27.2 tolerances (§9.7.4).
- **Body maturation:** every realized adult body falls inside its stored projected range, growth is reproducible from the career seed, no body increment alters a rating as a side effect, and Early/Average/Late produce materially different realized high-school bodies (§7.4).

### Gate B4 — Career systems

- Recruiting, GPA, follower, agent, contract, roster-interest, and economy distributions pass.
- No known reload, investment, training, follower, or agent exploit remains.
- College thresholds preserve the fixed five/play-four structure, and every professional offer's complete term and options fit remaining service capacity.

### Gate B5 — Rare events and monetization

- Recalibrated post-clock death bands and the established incarceration lifetime bands pass at required sample sizes.
- Injury career-ending rate and Second Chance restoration pass.
- Ad cooldown/session rules and paid-respec invariants pass offline/online lifecycle tests.

## 31. Required Reports

Every candidate release profile produces:

1. Rating and OVR population histograms by phase and age, including the share above 95 current OVR.
2. Attribute sensitivity plots for all 20 ratings, with the required-observable effect size for each.
3. Builder build-diversity and dominance report, including completed-build OVR distributions by prospect profile, the extreme-specialist tail, the completed-build ceiling, and creation-budget exhaustion evidence.
4. Team and player basketball statistics by competition.
5. Role, rotation, usage, and award-leader report.
6. Play/Sim/Skip and Tier A/Tier B parity report.
7. AP income/spending, cap attainment, peak age, and decline report, including the career peak distribution against §8.4, the lifetime AP-to-peak-Overall conversion, and projected-peak coverage, width, and signed bias.
8. Badge earning, spending, tier, and stacking report.
9. Injury frequency, severity, recovery, recurrence, and career-ending report.
10. Recruiting offers, transfers, pathway access, and roster-interest report.
11. GPA/eligibility and weekly opportunity-cost report.
12. Follower, NIL, agent, contract, cash, asset, and investment report.
13. Death, incarceration, clustering, and Second Chance report.
14. Monetization frequency and protected-context report.
15. Body maturation report: realized-versus-projected containment, timing-profile separation, growth determinism, and the absence of side-effect rating changes.
16. User/NPC development parity and detail-promotion invariance report, covering the manual path, the full-detail allocator, and aggregate executors at equivalent opportunity.

## 32. Draft Decisions Requiring Evidence, Not New Design Discussion

The following numeric baselines should be implemented behind the balance registry and tested before being marked approved. Each names the report that must pass before it becomes a shipping value.

| Provisional value | Owning section | Required report |
| --- | --- | ---: |
| The 195 AP creation budget, the 35/38/45 starting bases, and the ±40 profile modifiers | §7.1, §7.2, §7.3.4 | 3 |
| The role-neutral OVR coefficients 0.65 / 0.25 / 0.10 | §6.1 | 1, 3 |
| Derived-capability weights for all 20 capabilities | §5.2 | 2, 3 |
| Seasonal AP availability bands and upper guardrails | §9.5 | 7 |
| The six-band upgrade-cost curve | §9.1 | 7 |
| Projected-peak model, coverage rate, and range-width guardrail | §6.3 | 7 |
| Body projected-range widths and timing-profile growth shares | §7.4.2 | 15 |
| Full-detail NPC allocator behavior and aggregate-executor distributions | §9.7 | 16 |
| Ceiling-center to Maximum-Potential to Projected-Peak mapping | §8.1, §8.4 | 7 |
| Exact shot table and perfect-zone widths | §13 | 4 |
| Competition statistical ranges and opposed-event sensitivity | §14 | 4 |
| Injury incident and severity rates | §16 | 9 |
| Follower economic multipliers and contract salary bands | §20, §22 | 12 |
| Investment pre-clipping drift and realized clipped return and volatility | §23.4 | 12 |
| Death phase hazards required to produce the locked lifetime targets after the unified clock is verified | §24.1 | 13 |
| Comeback-offer likelihood after the unified clock is verified | §22.3 | 10 |

The locked targets these values must reach — the §7.3.2 Builder bands, the §8.4 career peak distribution, and the §24 lifetime rare-event targets — are not in this table. They are owner rulings and are not tunable.

### 32.1 Stage 4 calibration status

Stage 4 built a committed calibration harness under `calibration/`, ran it, and moved values on the evidence. This section records what the evidence actually supports, because §2 forbids treating a Baseline as approved and §29.3 forbids marking an item satisfied because a type exists.

**Passing at the sample size run.**

- All twenty attributes: addressed, monotonic, meaningful 50→80 effect, no IQ substitution for a primary skill. Run at the full §27.1 isolated-boundary sample.
- Career peak distribution for four of the five §8.4 bands: poorly managed (median 66, target below 72), ordinary successful (77, target 74–79), strong (82, target 80–85), exceptional (87, target 86–91).
- Population share peaking above 95 Overall: zero, against the "practically nonexistent" requirement.
- Continuity across the deliberate 72–74 gap.
- Manual, full-detail-allocator, and aggregate-executor progression parity: identical mean peak Overall from equivalent opportunity.
- Builder completed-build bands (§7.3.2) continue to hold after the progression change.
- Determinism: committed golden ledgers reproduce exactly; regenerated deliberately under an explicit engine and balance version change.

**Failing or unmeasured, with the reason.**

| Item | Status | Reason |
| --- | --- | --- |
| §8.4 rare generational band | **Corrected. Passes on independent validation ranges; not certified.** Median 93 against 92–95 | **Cause measured, not assumed, and the first measurement was half right.** The recorded cause — saturated cap attainment — described the cohort's ceiling tail, not its median career. Replaying every career's own build and caps through the projection's ordinary conversion at multiples of its real budget showed the median career spending everything it was granted and stopping three Overall short of its own ceiling, and put the requirement at about 3,140 lifetime AP against 2,610 granted rather than the 2,900 previously inferred. Allocation was ruled out by the Overall-maximising bound, which beats the realized career by 0.58 Overall; aging and decline by the 17 AP-equivalent decline removes across a whole career. The correction raises the cohort's opportunity by the measured factor and its §8.1 selection pool from two to three, and it costs the cohort roughly 16.5% above the §9.5 guardrails, warned and ledger-explained. `PROJECT_STATUS.md` §5.8. |
| §6.3 projected-peak coverage and bias | **Corrected. Passes on independent validation ranges; not certified.** Coverage 0.7473 and 0.7370 against 0.70–0.85, median signed error −1.0 and 0.0 against ±2, median width 11 against 6–12, on two untouched 3,000-career ranges (seeds 300001–303000 and 402001–405000); the production judged path agrees at 2,000 careers per range with executor parity exactly 0.0000. The model now takes the §9.5 band **midpoint** over a per-profile horizon as expected opportunity and conditions the interval on the prospect profile, with the player's own caps narrowing it wherever they bind through the conversion's saturation. Parameters were fitted on seeds 1–600 and confirmed unchanged on seeds 200001–202000. No §8.4 band moved and no golden ledger changed, which is the direct check that §6.2's prohibition on Overall reaching a resolution path still holds. The diagnosis that produced it is retained below. | **The recorded cause was right about the direction and silent about the size, which is not actionable.** Splitting the signed error into the model's two independent halves at 3,000 careers gives +10.0 attributable to the credited opportunity budget and **0.0** to the AP-to-Overall conversion: given the true lifetime AP the model predicts the realized peak exactly. It credits a mean of 603 AP against 1,198 granted, and realized opportunity runs at 1.39× the projection's own upper bound. By outcome class the displayed range brackets only poorly-managed careers (coverage 1.000, error −1.0) against 0.046/0.042/0.033 for ordinary, strong and exceptional — a severe hidden subgroup failure the pooled coverage figure conceals. What the model calls "ordinary opportunity" is poor-career opportunity. **The coverage band and the width guardrail are jointly satisfiable**: the irreducible width — the narrowest window reaching 70% coverage inside groups sharing every creation-time input, which bounds any model built from those inputs — is 8.0 against the 6–12 guardrail, reproduced on two independent seed ranges. The failure is the model, not the requirement. The shape is what is wrong: one global opportunity interval applied to every career tops out at 0.666 coverage, while the irreducible width ranges from 6 to 16 across groups, so the interval must be conditioned per career rather than scaled uniformly. |
| §14.1 competition bands | **Ten of eleven pass at top domestic; all five levels re-measured on one untouched range** | Every level was re-measured at 400 games on variations 60,000-60,399 under `simulation-v3-margin` and again under `simulation-v4-management`, and once more on the untouched range 350,000-350,399 under `simulation-v5-garbage-time`, so no figure in this table predates its own engine any more. Points per possession moved from 1.2084 to **1.1680** — inside 1.08-1.18 on the judged range, and 1.1771 ±0.0040 pooled over 2,100 population games, which is inside the band with its interval touching the ceiling. It was corrected at its measured source: field-goal attempts per possession ran at 0.967 against a band-consistent 0.90, and the two processes that set that number are offensive rebounding and ball-handling disruption. Points per possession is 1.1691 under `simulation-v4-management`, eleven ten-thousandths from where §5.10 left it, because the score-and-clock correction changes which action a coach selects and not how efficient anybody is. Assist percentage is the only remaining §14.1 failure at top domestic — 0.4854 against 0.52-0.72, statistically unchanged and belonging to the assist model. The other four levels: high school 10/10, overseas 9/10, development 9/10, college 8/10, with college field-goal percentage at 0.4151 against a 0.42 floor and assist percentage failing at all four. `PROJECT_STATUS.md` §5.10. |
| §14.2 game-shape targets | **Blowout share passes at three of five competition levels; close-game share passes at all five; overtime passes at one. A competition-specific amendment is proposed and awaits owner decision.** Blowout 0.1300 / 0.1700 / 0.2450 / 0.1550 / 0.2725 across high school, college, development, overseas and top domestic at 400 games each on the untouched range 350,000-350,399, and 0.2320 / 0.2120 on two untouched 500-game population validation ranges. Close-game share 0.2200-0.2700 at every level. Overtime 0.0100-0.0425. High school passes all fifteen judged metrics. `PROJECT_STATUS.md` §5.10, §5.11, §5.12 and §5.13. | **Three tasks of measurement, and the answer changed twice.** §5.10 reconstructed the margin as an independent random walk and called §14.2 unreachable; §5.11 measured the covariance the reconstruction assumed away, found it genuinely zero, and traced that to three authorised mechanisms the engine did not have — score-and-clock game management, end-of-regulation possession strategy, and coaching timeouts. Implementing them raised the even-team covariance from +4.67 to +25.12 and cut the margin's variance by a sixth, with no probability touched anywhere. §5.12 then implemented the asymmetric garbage-time rotation the owner authorised on 2026-08-20: a possession-based safety measure, `|margin| / (1.77 * sqrt(possession_pairs_left))`, with the leading coach's threshold at 2.6 standard deviations and the trailing coach's at 4.2. It moves minutes and nothing else — the same shot from the same shooter resolves identically at +30 and −30 — and it cut the even-team blowout share from 0.2467 to 0.1883 and margin variance by a further fifth, while §14.1 moved only in the fourth decimal and no golden hash changed at all. **What remains is classified rather than argued.** The overtime band is unreachable at any dispersion this possession and scoring model can produce: a ledger-faithful replay model reaches a tie rate of 0.0334 at a margin standard deviation of 9.90, because the probability of an exactly level score is the margin density at zero. That is a property of this scoring model and not a law of basketball; a fuller end-of-regulation repertoire would concentrate mass at level, and it is a system this engine does not yet have. The blowout band at the two high-possession competitions is reachable only outside the owner-ruled safe ranges, because `sigma_margin = sqrt(2 n sigma^2)` and §14.1 locks both terms per competition. `PROJECT_STATUS.md` §5.13 proposes competition-specific bands, labels them simulation-derived and provisional because no authoritative external benchmark was available to consult, sets out three costed owner options, and **enacts nothing**. |
| §27.1 certification sample sizes | Not reached anywhere except attribute sensitivity | See the performance finding below. |
| Builder tournament dominance rejection (§12.4) | Not run | The round-robin tournament runner is not implemented. |
| OVR truthfulness suite (§31 report 1) | Not run | Not implemented. |
| Play/Sim/Skip and Tier A/Tier B parity at §27.1 sizes | Not run at scale | Play/Sim/Skip parity remains proven structurally by byte-identical ledgers in the acceptance suite, which is stronger evidence than a distributional test, but the §27.1 matched-triplet sample was not run. |
| Body maturation report (§31 report 15) | **Implemented; measured below the required sample** | `calibration/runners/run_body_maturation.gd`, with nightly and deep workflow jobs and an aggregation path verified end to end on real shards. At 2,000 matched maturity triples all eleven §7.4.2/§7.4.3 structural invariants measure exactly 1.0000 — adult containment, intermediate legality, skeletal monotonicity, determinism from the career seed, increment idempotency, exact increment count, no rating, cap or currency side effect, body plausibility, and the stored range matching the versioned widths. Timing separation is 0.4797 and realized high-school growth shares are 0.785 / 0.547 / 0.306 against a configured 0.75 / 0.50 / 0.25. Timing is confirmed to be a schedule rather than a budget: the matched triples end on an identical adult body. The sample is short of §27.1 and the report says so rather than claiming certification. |

**The performance finding that constrains all of the above.** The Stage 4 profile measured the match engine at **5,496 ms per complete reference game** before optimization and **1,345 ms after** — a 4.09× improvement with byte-identical ledgers. The dominant cost was found by measurement, not assumption: `Rating.normalized` was formatting a three-argument assert message on every call, because GDScript evaluates an assert message eagerly in a debug build, costing 3.92 µs against 0.026 µs for the arithmetic it exists to do. Fixing that, memoizing the immutable half of capability resolution, and removing per-candidate string construction accounted for the whole gain.

At 1,345 ms per game, the §27.1 requirement of 100,000 games per competition is roughly 37 hours per competition on one process. **The 10 ms per game calibration goal is not reachable in GDScript for this engine design**: a game resolves roughly 460 candidate-generation calls of about 25 candidates each, and at GDScript's method-dispatch cost that is a few hundred milliseconds of irreducible floor. Reaching the goal requires the possession engine in a compiled extension. This is a documented risk, not a solved problem.

Testing may tune these numbers inside their stated guardrails. Changing one-standard difficulty, the 20 ratings, permanent allocation, exact caps, guaranteed valid perfect releases, full Play/Sim parity, rare-event intent, non-pay-to-win economy, the separation of the three development values, the separation of the identity layers, body-growth containment, or any other structural invariant requires explicit approval from the owning design source under the authority hierarchy rather than an ordinary balance change.

## 33. Owner-Locked Decision Traceability

Each locked decision, its owning sections, and the implementation and test consumers that must satisfy it.

| Decision | Owning sections | Implementation consumers | Test and report consumers |
| --- | --- | --- | --- |
| **OD-A** Career peak distribution | `BALANCE_SPEC.md` §8.4 (numeric owner); `GDD.md` §7.5 (philosophy); `PRD.md` PROG-009 | Progression service, aging and decline model, cap distribution, seasonal AP model | Gate B3; report 7; `GODOT_TDD.md` §13.2 progression suite |
| **OD-B** Builder outcome bands and budget exhaustion | `BALANCE_SPEC.md` §7.1, §7.3 (numeric owner); `GDD.md` §6.1–6.2; `PRD.md` BUILD-003, BUILD-006, BUILD-010 | `BuilderService`, `CreationBudget`, cost table, confirmation guard | Gate B1; report 3; `GODOT_TDD.md` §13.2 builder suite |
| **OD-C** Body maturation | `BALANCE_SPEC.md` §7.4 (numeric owner); `GDD.md` §6.5; `SIMULATION_SPEC.md` §6.1, §6.3; `PRD.md` BUILD-008, BUILD-009, AGE-002 | `BodyProfile`, `BodyMaturationState`, `BodyMaturationService`, increment ledger, save schema and migration | Gate B3; report 15; `GODOT_TDD.md` §13.2 body suite and migration tests |
| **OD-D** Three development values | `BALANCE_SPEC.md` §6.2, §6.3 (numeric owner); `GDD.md` §6.4; `SIMULATION_SPEC.md` §6; `PRD.md` BUILD-007, BUILD-011, PROG-010 | `DevelopmentProjection`, `OverallCalculator`, cap model, projected-peak model, `DevelopmentProjectionQuery` | Gate B1, Gate B3; reports 1, 3, 7; `GODOT_TDD.md` §13.2 projection suite and Overall-exclusion check |
| **OD-E** One development contract | `BALANCE_SPEC.md` §9.7 (numeric owner); `GDD.md` §7.6; `SIMULATION_SPEC.md` §26.5; `PRD.md` PROG-007, PROG-008 | `DevelopmentService`, `AttributeAllocator`, `AggregateDevelopmentExecutor`, `AttributePointLedger`, career-year receipts | Gate B3; report 16; `GODOT_TDD.md` §13.2 parity and promotion suites |
| **OD-F** Layered identity | `SIMULATION_SPEC.md` §10.6 (behavioral owner and stable IDs); `BALANCE_SPEC.md` §12.4 (numeric bounds); `GDD.md` §10.2; `PRD.md` ROLE-002, ROLE-004 | `RotationRole`, `TacticalRole`, archetype projection, action-weight construction, rotation planning | Gate B1, Gate B2; report 3, report 5; `GODOT_TDD.md` §13.2 identity suite |
