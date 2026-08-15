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

Potential Overall applies the same formula to exact per-attribute caps. It appears only in approved detailed builder and development views.

### 6.2 OVR guardrails

- Raising any one rating while all others remain fixed cannot reduce Overall.
- No non-rating state can change Overall.
- A one-point rounding boundary is acceptable; unexplained two-point UI differences are defects.
- No ordinary generated active player may have 99 Overall.
- Fewer than 0.1% of top-domestic active players should reach 95+ Overall in a stable mature world.
- The top domestic league should generally contain 0–3 players at 93+ and 4–15 players at 90+ in a season.

## 7. Builder and Prospect Profiles

### 7.1 Starting scale

The user begins the freshman year of high school. The builder begins from a body-adjusted base and then grants manual allocation currency.

| Component | Baseline |
| --- | ---: |
| Technical, scoring, playmaking, defense, and rebounding base | 35 |
| Offensive IQ and Defensive IQ base | 38 |
| Physical base before body adjustment | 45 |
| Manual starting Attribute Point budget | 150 AP |
| Minimum final attribute | 25 |
| Freshman builder soft starting maximum | 70 |
| Freshman builder absolute starting maximum | 75 |

Body choices redistribute at most 18 total rating points and are approximately zero-sum. No body selection can create more than a four-point direct modifier on one starting attribute. Physical dimensions primarily affect action access, reach, and matchups rather than granting free universal Overall.

### 7.2 Broad prospect profiles

| Profile | Starting AP modifier | Cap-generation modifier | Growth timing |
| --- | ---: | ---: | --- |
| Ready Now | +25 AP | −3 to non-primary cap center | 115% HS, 90% college, 80% pro growth availability |
| Balanced | 0 AP | No global modifier | 100% at every phase |
| High Upside | −20 AP | +4 to cap center | 85% HS, 115% college, 120% early-pro growth availability |

Profile multipliers change the number and quality of opportunities generated, not the AP cost of a rating. Exact displayed training rewards remain truthful after the multiplier is resolved.

### 7.3 Freshman outcome targets

The builder must permit final starting OVR from approximately 37 through 61. Most neutral preset builds should land from 46 through 54. An optimized specialist can place one or two abilities in the high 60s or low 70s only by accepting visible weaknesses elsewhere.

The confirmation screen reports current OVR, potential OVR, all exact caps, archetype description, likely behavioral profile, and all allocations. It does not label a legal build as bad.

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

### 8.2 Population distribution targets

| Population | Median OVR | 90th percentile | 99th percentile |
| --- | ---: | ---: | ---: |
| Incoming HS freshmen, potential OVR | 58–63 | 70–75 | 82–88 |
| Recruited college entrants, potential OVR | 67–72 | 78–83 | 88–92 |
| Top domestic draft pool, potential OVR | 74–78 | 84–88 | 92–95 |
| Top domestic rostered players, current OVR | 77–81 | 87–90 | 92–95 |

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

| Phase | Typical available AP-equivalent per season | High-engagement upper guardrail |
| --- | ---: | ---: |
| High school | 45–65 | 78 |
| Summer circuit | 8–16 | 20 |
| College | 35–55 | 68 |
| Domestic development | 30–48 | 60 |
| Overseas | 25–45 | 56 |
| Top domestic pro, age 19–24 | 24–40 | 50 |
| Top domestic pro, age 25–29 | 16–30 | 38 |
| Top domestic pro, age 30+ | 8–22 | 30 |

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

## 29. Implementation Migration

The current code contains useful prototypes but is not the approved balance model.

Required changes:

1. Replace the current 16-attribute cost registry with all 20 canonical attributes.
2. Remove attribute-specific upgrade prices; use the universal destination-rating table.
3. Replace position-weighted OVR with the role-neutral formula in Section 6.
4. Add Free Throw, Offensive IQ, Defensive IQ, and Vertical to all builder, cap, progression, simulation, fixture, and persistence contracts.
5. Replace legacy potential-tier-only logic with exact per-attribute caps plus derived potential OVR.
6. Preserve hidden fractional progress through migrations.
7. Move all possession constants into the versioned simulation balance profile.
8. Add balance ledgers for AP sources, BDP sources, economy transactions, rare-event hazards, and cap changes.
9. Require shared career-year completion receipts before annual age, natural development or decline, generic offseason development, or professional service can resolve.
10. Establish frozen legacy-engine reports before changing formulas so improvements are measured.
11. Do not weaken typed domain contracts or tests to accommodate incompatible archived schemas.

Existing values are retained only when they pass the new contract and calibration requirements.

## 30. Balance Approval Gates

### Gate B0 — Configuration integrity

- One validated profile loads offline.
- Every tuneable has a name, unit, safe range, and version.
- Deterministic golden seeds pass.

### Gate B1 — Ratings and builder

- All 20 attributes satisfy monotonic observable tests.
- OVR is role-neutral and population distributions match targets.
- Weak, experimental, specialist, and conventional builds are all legal and distinct.

### Gate B2 — Basketball distributions

- Every competition profile satisfies Section 14.
- Roles, rotations, and player-stat leaders remain plausible.
- Perfect-window and no-perfect-zone rules pass.

### Gate B3 — Career progression

- Million-career progression, cap, aging, mileage, and injury reports pass.
- Played and simulated development are equivalent.
- Elite outcomes remain rare without making ordinary careers static.
- Cross-level tests prove one career year cannot duplicate age, natural development or decline, generic offseason development, or professional-service resolution.

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

1. Rating and OVR population histograms by phase and age.
2. Attribute sensitivity plots for all 20 ratings.
3. Builder build-diversity and dominance report.
4. Team and player basketball statistics by competition.
5. Role, rotation, usage, and award-leader report.
6. Play/Sim/Skip and Tier A/Tier B parity report.
7. AP income/spending, cap attainment, peak age, and decline report.
8. Badge earning, spending, tier, and stacking report.
9. Injury frequency, severity, recovery, recurrence, and career-ending report.
10. Recruiting offers, transfers, pathway access, and roster-interest report.
11. GPA/eligibility and weekly opportunity-cost report.
12. Follower, NIL, agent, contract, cash, asset, and investment report.
13. Death, incarceration, clustering, and Second Chance report.
14. Monetization frequency and protected-context report.

## 32. Draft Decisions Requiring Evidence, Not New Design Discussion

The following numeric baselines should be implemented behind the balance registry and tested before being marked approved:

- The 150 AP starting builder budget and freshman OVR distribution.
- The role-neutral OVR blend of mean, top-eight, and bottom-six ratings.
- Seasonal AP availability and the six-band upgrade-cost curve.
- Exact shot table and perfect-zone widths.
- Competition statistical ranges and opposed-event sensitivity.
- Injury incident and severity rates.
- Follower economic multipliers and contract salary bands.
- Investment pre-clipping drift and the realized clipped return and volatility.
- Provisional death phase hazards required to produce the locked lifetime targets after the unified clock is verified.
- Provisional comeback-offer likelihood after the unified clock is verified.

Testing may tune these numbers inside their stated guardrails. Changing one-standard difficulty, the 20 ratings, permanent allocation, exact caps, guaranteed valid perfect releases, full Play/Sim parity, rare-event intent, non-pay-to-win economy, or any other structural invariant requires explicit approval from the owning design source under the authority hierarchy rather than an ordinary balance change.
