# LeagueBound Game Design Document

| Field | Value |
| --- | --- |
| Version | 1.0 consolidation draft |
| Date | August 2, 2026 |
| Status | **Locked** |
| Product | Single-player basketball career RPG and simulation |
| Platforms | iOS and Android |
| Orientation | Portrait only |
| Authority | Broad product-design vision within the approved source hierarchy |

## Document Authority

Conflicts are resolved in this order: (1) explicit owner rulings, (2) locked level-specific system documents, (3) later and more-specific working frameworks, (4) this GDD, (5) the PRD, (6) the Simulation Specification, (7) the Balance Specification, (8) `GODOT_TDD.md`, (9) the Content Bible, and (10) older or superseded drafts. A higher source controls whenever two sources disagree. `GODOT_TDD.md` is the current technical implementation authority and may choose a compatible representation, but it cannot redefine game rules, add player-facing scope, or override a higher-authority source. The previous React Native / Expo `TDD.md` is archived reference only.

## 1. Game Identity

### 1.1 Player fantasy

> Playing the basketball career I never had.

LeagueBound allows the user to build and live a complete basketball career, beginning as a freshman at a United States high school and potentially continuing through college, developmental basketball, overseas leagues, and the highest domestic professional level.

The objective is not simply to reach 99 Overall or the Hall of Fame. The player attempts to build the best career possible while responding to the opportunities, setbacks, relationships, and consequences created by that life. The game evaluates the career from what naturally happens rather than asking the user to select a predetermined ambition or ending.

### 1.2 Experience pillars

1. **Live the career:** Basketball, school, money, relationships, reputation, injuries, and major life events form one continuous history.
2. **Earn the outcome:** The game does not protect the user from weak builds, poor decisions, lost opportunities, declining talent, or bad luck.
3. **Understand the basketball:** Detailed ratings and realistic team systems reward knowledgeable fans, while contextual choices and clear feedback remain understandable to newcomers.
4. **Play at mobile speed:** A meaningful game normally takes three to five minutes. Quiet weeks move quickly; important moments receive more attention.
5. **Create a different story every time:** A fixed fictional basketball structure provides identity and continuity, while generated people, decisions, careers, and events create replayability.

### 1.3 Tone and audience

LeagueBound targets Gen Z and Millennial sports fans, dedicated basketball enthusiasts, and mobile players who enjoy career, life-simulation, and management games.

The basketball world is primarily realistic. Rare larger-than-life events provide surprise and dark humor. Absurd events use a dry, non-graphic presentation and remain uncommon enough that the world does not become a parody.

The game is designed toward a 16+ audience and is not marketed to children under 13. This is a content target rather than a guaranteed store classification; Apple, Google Play, IARC, and regional authorities assign the final rating from the shipped content and disclosures.

Death, serious injury, incarceration, infidelity, and other mature circumstances remain non-graphic. The game does not depict explicit sexual activity, provide instructional criminal content, or use real-money gambling and paid randomized items. Dark humor cannot depend on graphic violence or real-world tragedy.

### 1.4 Reference mixture

- PS2-era Madden Superstar and NCAA Campus Legend: an interactive personal living space as the emotional center of the career.
- New Star Soccer: short sessions, quick life decisions, selective match participation, and accessible career rhythm.
- Ultimate Basketball GM and ZenGM: persistent rosters, statistics, transactions, league history, and a credible simulated ecosystem.
- Hoop Land: a readable, stylized, top-down basketball court with strong team identity.
- BitLife sports careers: life events and career outcomes that emerge without selecting a victory condition.

References communicate product qualities only. LeagueBound uses original teams, leagues, characters, art, terminology, and code.

## 2. Product Structure

### 2.1 Career boundaries

- Men’s basketball only at launch.
- Every standard career begins in the United States.
- The formal career begins during freshman year of high school.
- An optional, skippable three-game middle-school tournament acts as a prologue and tutorial. Its results can affect initial reputation and opportunities without overriding the player’s broader prospect profile.
- A professional career can last no more than 25 credited seasons across all professional levels combined. The complete playing-contract term and every option must fit within the player’s remaining professional-season capacity, regardless of guarantee status.
- A career can end through voluntary retirement, maximum service time, career-ending injury, incarceration, death, or the inability to find a roster because of ability, decline, reputation, eligibility, or market interest.
- Declining talent and lack of roster interest are normal career outcomes and do not qualify for rescue mechanics.

### 2.2 Authored fictional basketball world

Each new standard career begins with the same recognizable fictional structure: leagues, schools, colleges, professional organizations, rivalries, rules, coaching identities, baseline prestige, and foundational history. Players and many staff members are generated. Results, transfers, injuries, coaching changes, development, relationships, and league history cause the world to diverge after the career begins.

Real geography can be used, but the basketball organizations are fictional. International youth origins are reserved for future consideration; overseas basketball remains an available later-career pathway.

### 2.3 World simulation tiers

The world uses one shared set of eligibility, membership, contract, development, injury, award, and career-history rules at three levels of detail:

- **Full simulation:** The user’s active competition, team, games, and directly relevant opponents retain possession, lineup, box-score, health, and transaction detail.
- **Relevant aggregate simulation:** Major or personally relevant competitions retain the evidence needed for credible schedules, rosters, standings, statistics, injuries, development, awards, and movement without resolving every possession.
- **Background-summary simulation:** Distant competitions retain stable identities, champions, qualifying awards, broad movement, and notable events without manufacturing unsupported detail.

All tiers obey the same legal rules; reduced detail changes evidence resolution, not eligibility or outcomes. Competitions and people can be promoted prospectively when they become relevant. Stable identity and already committed history persist through promotion, and the game never fabricates historical box scores or rewrites a known achievement.

### 2.4 Version 1.0 career boundary

Version 1.0 prioritizes one complete, replayable freshman-to-retirement career. The launch experience must support the core basketball, progression, pathway, health, reputation, relationship, financial, narrative, and legacy-summary loops across that career before generational expansion is attempted.

Child/New Game Plus careers, inherited assets, deeper investment systems, and the most elaborate family simulation are post-launch features. Their future requirements may influence save compatibility and data architecture, but they are not version 1.0 acceptance criteria.

### 2.5 Version 1.0 world size

The launch world combines a generated high-school layer with a standard authored scale for later levels:

- The player’s active state contains 32 persistent high schools generated from the approved identity canon: four districts of eight schools.
- A lightweight national school pool represents schools outside the active state without permanently maintaining full rosters for every program.
- 64 colleges distributed across several conferences and competitive tiers.
- 16 regional and national summer clubs.
- 12 domestic developmental teams.
- 12 teams in one fully supported overseas league.
- 24 teams in the top domestic professional league.

The non-high-school organizations, their identities, and their baseline structure remain fixed across new standard careers. High-school generation is deterministic for the career’s content version and seed, and every materialized school retains a stable identity for that career. Rosters and many staff members are generated. Each directly relevant organization must have a recognizable name, colors, competitive profile, coaching context, and home environment. Tiered simulation controls runtime cost; national reach does not require possession-level or roster-level simulation everywhere.

### 2.6 Career-year order and once-only resolution

Every career year uses one global ordered spine. Inapplicable milestones are skipped rather than replaced or rerun:

1. Regular competition.
2. Postseason.
3. Awards and competition-season close.
4. School summer basketball or graduate exposure, when applicable.
5. Eligibility, declaration, and permitted withdrawal decisions.
6. Top draft and signing-rights resolution.
7. Contract, roster, transfer, assignment, and release movement.
8. Out-of-basketball determination and offseason development or decline.
9. Career-year rollover.

Each resolved milestone records a durable completion receipt. Reloading, changing levels, signing, transferring, being assigned, or re-entering a detailed simulation tier cannot resolve it twice. A career year permits at most one age increase, one professional-service credit, one natural development-or-decline resolution, and one generic offseason resolution. A player who occupies a professional roster during official competition earns no more than one service credit for that year, even after changing professional levels.

### 2.7 Career state, membership, and control

- **Rostered:** The player holds the one current official playing membership for an organization.
- **Free agent:** The player has no playing membership or active playing contract, remains eligible to pursue offers, and has not entered an unresolved out-of-basketball cycle.
- **Out of basketball (OOB):** An offseason closes without an accepted playing contract or other valid playing membership, leaving the player outside organized basketball while the continuation rules in Section 19 remain unresolved.
- **Career complete:** A permanent ending has resolved and any eligible Second Chance decision has been completed or declined; the career is then archived for legacy review.

At any instant, a player can have at most one official playing membership, one active playing contract, one top-domestic signing-rights holder, and one temporary assignment overlay. These are separate facts: rights reserve only a future top-domestic signing opportunity, while an assignment requires an already accepted top-domestic playing contract and does not create a second membership. Representation, endorsements, NIL arrangements, sponsorships, housing, and other non-playing agreements do not count as playing contracts. Professional loans do not exist at launch.

School-season and summer-club memberships are sequential competition memberships, never simultaneous current memberships. When an accepted summer-club place begins after the player's school season ends, the club becomes the one current official playing membership. Any continuing school place is represented as a next-season roster reservation or school affiliation until the summer membership closes and the school membership can resume under the applicable school and transfer rules.

Availability, assignment, and game registration remain separate from membership. **Inactive** is a derived presentation label based on those facts, not a stored flat career state. This lean model supports the mobile scope without adding detailed labor-administration play.

## 3. Core Player Loop

### 3.1 Session loop

1. Return to the Personal Hub.
2. Review the current week, messages, health, obligations, and opportunities.
3. Spend discretionary time on training, recovery, study, relationships, research, work, media, or other available activities.
4. Resolve required decisions and interruptions.
5. Choose whether to play or simulate each eligible game.
6. Review results, development, consequences, and world changes.
7. Advance until the next meaningful interruption.

Quiet weeks may resolve quickly. Important weeks receive more presentation and decision weight. The game stops for decisions that cannot be safely automated.

### 3.2 Weekly capacity

Weekly activities use a hybrid structure:

- Automatic obligations consume time without requiring repetitive confirmation.
- Discretionary activity capacity changes dynamically with the career phase and circumstances.
- Contextual opportunities appear as temporary cards or physical Hub interactions.
- Energy and condition limit overuse.
- Risky overbooking is possible when circumstances permit.

Available actions change because of injury, suspension, travel, academics, playoffs, employment, money, trust, release, incarceration, and offseason status. Unavailable actions remain visible with a descriptive explanation. For example, a suspended player can see Team Facilities but cannot access them.

## 4. Personal Hub and Navigation

### 4.1 Primary design philosophy

The Personal Hub is the emotional and navigational center of LeagueBound. It is a stylized, interactive physical living space rather than a generic sports dashboard.

Rooms use a layered 2.5D production format. Painted two-dimensional backgrounds, separated interactive furniture and objects, foreground elements, lighting, particles, and restrained parallax create physical depth without a free-roaming 3D environment. Contextual animation can communicate weather, time, messages, relationships, possessions, achievements, and career status. This format is the standard for every residence and must remain performant on mid-range mobile devices.

The residence changes with the player’s life:

- Family bedroom during high school.
- Dormitory or appropriate housing during college and development pathways.
- Apartment or modest residence early in the professional career.
- Higher-status homes when the player chooses and can afford them.

The room reflects career history through trophies, equipment, photographs, gifts, collectibles, family objects, sponsor items, and purchases. These changes communicate progression without granting hidden basketball bonuses.

### 4.2 Hub interaction model

Objects act as recognizable system entrances. Exact objects can change by residence, but the underlying destinations remain stable.

- Calendar or schedule: weeks, games, obligations, deadlines, and Play/Sim choices.
- Phone: messages, the single fictional social platform, advisors, relationships, offers, and news.
- Training equipment: development, recovery, condition, and stored training opportunities.
- Trophy case or career wall: statistics, accolades, records, badges, and legacy.
- Desk or laptop: academics, contracts, finances, research, rosters, standings, and deeper management information.
- Wardrobe or mirror: avatar appearance and owned cosmetics.
- Door or travel object: facilities, visits, games, events, and other locations when available.

The Hub is not free-roaming 3D gameplay. It is a touch-friendly layered scene with clear interactive hotspots, designed for portrait screens and rapid access.

### 4.3 Navigation rules

- Portrait orientation is mandatory across the entire game.
- Career screens favor reachable lower-screen controls, large targets, swipeable choices, and minimal precision requirements.
- Active basketball can require focused two-handed input, but movement remains automatic.
- Deeper rosters, statistics, standings, finances, and history sit one layer beneath the Hub.
- Important information cannot depend solely on decorative objects or color.

### 4.4 Information and notification priority

Information follows a four-level priority model:

1. **Physical Hub signals:** Ambient, non-blocking state appears through room changes and object states, such as a glowing phone, new trophy, packed travel bag, stored training indicator, photograph, gift, sponsor object, weather, or lighting change.
2. **Phone and inbox:** Actionable but non-immediate information includes social posts, relationship messages, advisor reports, recruiting interest, nonurgent offers, medical updates, news, and world events. Deadlines remain visible.
3. **Required interruptions:** Calendar advancement stops for expiring contracts or offers, enrollment and transfer decisions, medical-eligibility rulings, suspensions, legal events, career-ending events, and any decision that cannot be safely automated.
4. **Deep menus:** Full rosters, detailed statistics, standings, schedules, scouting, financial ledgers, career records, rules, and eligibility history remain available without producing constant alerts.

No individual update should occupy more than one level unless its urgency genuinely changes. The player must be able to distinguish unread information from advancement-blocking decisions immediately.

### 4.5 Hybrid onboarding

Onboarding combines an optional basketball prologue with contextual first-use help:

- The optional three-game middle-school tournament teaches game-day decisions, execution challenges, Play/Sim, basic ratings, and Personal Hub navigation.
- Game 1 introduces the core game-day interaction loop and basic execution.
- Game 2 introduces role expectations, adversity, fatigue, and imperfect circumstances.
- Game 3 serves as a higher-stakes finale or placement game and completes the initial evaluation period.
- All three games remain available regardless of earlier wins or losses; the bracket or placement structure cannot remove onboarding content.
- Skipping the prologue begins freshman year immediately without a progression penalty.
- Career systems provide short explanations the first time they naturally appear, including training, academics, recruiting, transfers, health, relationships, representation, contracts, finances, and reputation.
- An on-demand basketball glossary explains unfamiliar tactical, career, eligibility, and contract terminology.
- Individual explanations can be dismissed permanently and reopened through Settings or Help.
- Returning players can disable first-use explanations.
- Onboarding explains system behavior and visible risk without prescribing the correct choice.
- Tutorials never widen timing windows, improve ratings, alter opportunities, or change simulation outcomes.

Prologue performance is meaningful but deliberately limited by the three-game sample. Initial offers, reputation, and public attention also consider the generated prospect profile, position, physical tools, background, and coach evaluation. One exceptional or poor game can influence the starting situation but cannot define the entire prospect by itself.

## 5. Avatar and Character Presentation

- The user manually customizes a simplified cartoon head-and-shoulders avatar.
- NPC avatars are procedurally generated from the same modular visual system.
- Portraits appear in rosters, messages, relationships, social posts, recruiting, awards, and narrative events.
- Expressions change with circumstances such as confidence, anger, injury, grief, fatigue, celebration, embarrassment, and conflict.
- Avatars do not need to appear during the top-down tactical court view.
- Cosmetic packs can add portrait parts, hairstyles, accessories, facial hair, clothing themes, and related presentation options.

## 6. Player Creation and Ratings

### 6.1 Builder philosophy

The builder permits viable, intentionally weak, experimental, and highly specialized players. It does not prevent poor decisions or provide aggressive warnings. A neutral confirmation screen summarizes the build before commitment.

The user begins with a broad position family—Guard, Wing, or Big. Exact primary and secondary positions emerge from physical dimensions, ratings, play style, and early performance.

Physical dimensions are selected freely within credible position limits. Point forwards, stretch bigs, and other uncommon profiles remain possible but require the corresponding investment and tradeoffs.

**Creation budget exhaustion.** All creation Attribute Points must be spent before the build can be confirmed. Creation currency cannot be retained, banked, or carried into the career. A weak or experimental player remains legal through poor, lopsided, or incompatible allocation—never through refusing to allocate. The unallocated builder state is a preview, not a legal completed build, and the confirmation control stays unavailable until the budget reaches zero.

### 6.2 Builder constraints

- Manual allocation of detailed ratings.
- Increasing costs at higher rating bands.
- Freshman starting limits.
- Position and physical-profile constraints.
- Exact per-attribute potential caps.
- Full expenditure of the creation Attribute Point budget before confirmation.
- Current freshman body selection and a maturity timing choice, with a bounded projected adult range.
- A live, derived archetype preview that describes rather than restricts the build.
- Derived role prerequisites and previewed build behavior.
- Training capacity and diminishing returns.
- Team, coach, role, and usage fit that affect opportunity rather than secretly rewriting ability.

The player selects a broad prospect profile: Ready Now, Balanced, or High Upside. This contributes to the exact attribute potential caps.

Completed builds land in profile-appropriate current Overall bands. The bands, the empty pre-allocation preview value, and the ceiling for an ordinary completed build are numeric targets owned by the Balance Specification.

### 6.3 Public ratings

All ratings use whole numbers and universal rating bands. Hidden fractional progress is shown through a visual progress bar without displaying the precise fraction.

**Scoring**

1. Short Range
2. Dunking
3. Mid-Range
4. Three-Point
5. Free Throw

**Playmaking**

6. Handle
7. Passing
8. Vision
9. Offensive IQ

**Defense**

10. Perimeter Defense
11. Interior Defense
12. Stealing
13. Blocking
14. Defensive IQ

**Rebounding**

15. Offensive Rebounding
16. Defensive Rebounding

**Physical**

17. Speed
18. Strength
19. Stamina
20. Vertical

Every rating must have a documented simulation effect, progression curve, potential cap, and builder cost. A rating that cannot produce a measurable outcome should not exist.

### 6.4 Overall and information

LeagueBound displays three separate development values. They answer different questions, carry different certainty, and must never be presented as interchangeable.

| Value | Player-facing label | Meaning |
| --- | --- | --- |
| Current Overall | **Current Overall** | Present role-neutral ability, calculated from current ratings only. |
| Maximum Potential Overall | **Maximum Potential** | The Overall formula applied to the player's exact per-attribute caps. It is a physical and skill ceiling, not a promise. |
| Projected Peak | **Projected Peak** | A realistic *range* for the best Overall this career is likely to reach, given available development, timing profile, age, ordinary opportunity, caps, and expected decline. |

Rules:

- One exact current Overall rating is displayed for every player.
- The same role-neutral formula applies to the user and NPCs.
- Overall derives from basketball abilities and their interactions. It excludes popularity, trust, team fit, and public reputation.
- Overall is a displayed description of ability. It is never an input to basketball resolution; the simulation reads attributes, capabilities, body, and context.
- Maximum Potential is reached only by filling every cap. Almost no career does this, and the interface never implies otherwise.
- Projected Peak is always shown as a range, never a single guaranteed number. It moves as development, health, opportunity, and age change.
- The Builder and detailed development views show all three with their distinct labels and explain the distinction neutrally, without encouragement or discouragement.
- NPC rosters and current Overall ratings are always visible.
- Detailed NPC attributes, tendencies, health effects, and evaluations can be incomplete or stale.
- Personal playing experience provides the strongest scouting knowledge. A long-term opponent can eventually become fully scouted.
- Information can become stale after major development, injury, or aging.
- Sufficient coach preparation or organizational evaluation can update the information.

### 6.5 Body and maturation

The body is a real basketball fact with a life of its own, separate from ratings.

At creation the user selects:

- Current freshman height.
- Current freshman weight.
- Current freshman wingspan and standing reach.
- A maturity timing profile: **Early**, **Average**, or **Late**.

The Builder then displays a **bounded projected adult range** for each physical dimension. It does not display the exact adult body.

- Exact growth is deterministic from the versioned career seed and is fixed the moment the career is created.
- Growth stays hidden until it actually occurs, then resolves visibly at its normal career moment.
- Growth can never leave the projected range that was displayed at confirmation.
- Growth never retroactively invalidates a confirmed build, and never silently alters ratings. Any rating change accompanying a body change is a separately resolved, visibly explained effect under the ordinary progression, health, and decline rules.
- Early maturity means more of the growth arrives during high school; Late maturity means more of it arrives afterward. Neither timing is strictly better.

Body affects action validity, reach, positioning, matchups, and a bounded redistribution of starting ratings. It is never free Overall. A taller, longer player gains access and leverage; he does not gain Overall for the measurement itself.

## 7. Attribute Progression and Aging

### 7.1 Attribute Points

- Training usually awards general Attribute Points that can be allocated to any rating below its cap.
- Certain focused training sessions and circumstances apply progress directly to a named attribute.
- General Attribute Points can be spent freely between games.
- Attribute allocation is permanent.
- Unspent Attribute Points accumulate.
- Each universal rating band has a fixed Attribute Point cost per whole rating increase. Higher bands cost progressively more.
- Exact costs belong in the Balance Specification.

Games provide smaller participation-based development. Performance influence is modest and relative to role so that users are not punished for accepting limited minutes. Played and simulated games use identical development rules and seasonal safeguards prevent farming.

### 7.2 Training

- Unused training opportunities accumulate to a visible storage cap.
- The cap varies slightly with age, facilities, coaching, offseason status, and major circumstances.
- Training previews its exact expected Attribute Point reward, type, time or energy cost, injury risk, modifiers, and eligibility.
- Ordinary completed training always provides the displayed reward.
- Random interruption or modification occurs only through clearly signaled exceptional events.
- Stored opportunities are completed individually, with a repeat shortcut allowed.

### 7.3 Potential and exceptional development

Exact potential caps are normally stable. Rare breakthroughs, setbacks, injuries, or major narrative circumstances can raise or lower individual caps. These changes remain meaningful, bounded, and uncommon.

If a cap falls below a current rating, the cap change does not silently remove the current rating. Growth above the new cap is blocked; any later current-rating loss must occur through a separately resolved and visibly explained decline, injury, or setback.

### 7.4 Aging and mileage

Meaningful rating decline occurs through aging, injury, extreme inactivity, or other major circumstances—not arbitrary seasonal erosion.

- Physical ratings peak and decline earlier.
- Technical skills remain stable longer.
- Offensive IQ and Defensive IQ can remain stable or improve later in a career.
- Physical decline uses a hybrid career-mileage model based on age, minutes, workload, injuries, recovery, schedule congestion, physical profile, strain, and inactivity.

Durability is a hidden precise value summarized by a reliable qualitative label. Condition, workload, injury history, recurrence warnings, and medical risk remain visible. Durability is not one of the 20 public attributes and cannot be purchased with Attribute Points.

### 7.5 Career peak expectations

A career peak is earned, not assumed. For a sensible build without rare breakthroughs, most careers peak well below the top of the rating scale:

- A poorly managed or injury-hit career peaks low.
- An ordinary successful career peaks in a solid, unremarkable band.
- A strong, well-managed career peaks clearly above that.
- Exceptional and rare generational careers exist but are genuinely uncommon.
- A current Overall of 96 or higher is practically nonexistent, even for the best careers.

Individual attributes may still reach 99. The scale is not compressed; it is Overall that resists extremes, because reaching an elite Overall requires broad excellence rather than one elite skill.

The exact peak distribution, its bands, and its acceptance tolerances are numeric targets owned by the Balance Specification and are verified by large-sample career reports.

### 7.6 Development applies to everyone

There is one development contract in LeagueBound. It governs the user and every NPC.

- The user spends Attribute Points manually and permanently.
- Fully simulated NPCs receive equivalent development opportunity and allocate it through an automatic allocator that obeys the same costs, caps, timing, aging, decline, and source-ledger rules.
- Reduced-detail parts of the world may resolve development in aggregate for performance, but the results must match what the detailed process would have produced.
- Changing how closely the game is simulating a player never changes that player. A prospect who becomes relevant is the same player he already was.

This is why NPC careers are credible: they are not scripted rosters, and they are not given development the user cannot earn.

## 8. Badges

- Version 1.0 contains 16 badges organized into four focused families of four.
- Finalized qualifying awards identified by the owning level rules award Badge Development Points.
- Any earned point can be spent on any badge.
- Badge tiers are Bronze, Silver, Gold, and Hall of Fame.
- Higher tiers cost progressively more.
- Badges are always active and intentionally difficult to acquire.
- Repeating a qualifying finalized award can award another point each time when the owning rule permits repeats.
- Unspent Badge Development Points carry forward indefinitely.
- Badge spending is permanent during ordinary play.
- Very rare narrative events can automatically increase a badge by one tier.

Each competition’s locked system document owns award eligibility, participation requirements, and timing. Awards finalize exactly once after that competition’s postseason for the career year, under a stable award ID. Watch-list, candidate, semifinalist, and finalist status never awards Badge Development Points; only a final qualifying award can do so. Statistics, awards, records, earnings, service, and history retain their level and competition attribution.

The game permits one complete paid badge-only respec per career. It refunds spent Badge Development Points but does not change attributes, body, tendencies, potential, or earned point totals. Pricing cannot be randomized or presented with artificial urgency, and purchase recovery must be reliable.

## 9. Basketball Gameplay

### 9.1 Authoritative engine

Played games and simulated games use the same authoritative basketball engine. User input changes decisions and execution; it does not switch to a separate set of basketball rules.

The simulation models possessions, lineups, rotations, role, pace, score, time, fatigue, fouls, matchups, tendencies, coaching instructions, and contextual basketball decisions. Exact formulas belong in the Simulation and Balance Specifications.

### 9.2 Play or Sim

- The user chooses which eligible games to play and which to simulate.
- Rivalries, showcases, playoffs, revenge games, record chases, and other important games are highlighted.
- Participation is never forced when simulation is available.
- A played game normally lasts three to five minutes.
- A low-role game can finish in under three minutes with few or no interactions.
- Higher stakes increase presentation, crowd intensity, commentary, pressure, consequences, and clutch depth more than match length.

### 9.3 Played-game structure

Movement runs automatically. The game advances through a fast tactical simulation and stops or slows for action-specific opportunities involving the user.

Interaction frequency changes with role, minutes, usage, game state, and actual involvement. The game does not manufacture touches to entertain the user.

At a relevant opportunity, the player can:

- Make a contextual basketball decision.
- Select a play or influence strategy when authorized.
- Complete a short action-specific execution challenge.
- Occasionally control a deeper featured possession.

Actions use a contextual mixture of taps, holds, swipes, timing, and concise choices. The interaction must match the basketball action being performed.

### 9.4 Portrait court

- Game day uses a stylized, top-down, full-court portrait layout.
- Play travels vertically.
- Player markers and the ball remain legible on small screens.
- Team-specific floors, arenas, crowds, backgrounds, and presentation create identity.
- Whacky sound effects and zany visual flourishes are allowed when they do not obscure basketball information.
- A broadcast-style scoreboard, captions, and optional detailed logs communicate state.

### 9.5 Shooting and execution

- Shot timing is pure user skill.
- Ratings and context change the difficulty, stability, and size of the timing window.
- A valid perfect release guarantees success.
- Attempts that permit guaranteed success are visibly identified.
- Some attempts are too compromised to contain a perfect zone.
- For non-shooting actions, perfect execution maximizes the chosen action’s quality, but defenders and context can still counter it.

### 9.6 Decisions, pausing, and skipping

- Contextual decisions occur under real-time pressure with a limited response window.
- IQ and preparation can affect recognition and available reading time where appropriate.
- The user may pause outside an active execution challenge.
- Backgrounding safely preserves an active challenge without rerolling or extending it.
- From the bench or between appearances, the user can skip to the next appearance or final result.
- If no further appearance occurs, only the final result is shown.
- When skipping, the engine controls the player through established tendencies and coaching instructions.
- Skipping does not impose an artificial penalty, but the user loses the possible benefit of manual execution.

## 10. Tendencies, Roles, and Coaching

### 10.1 User tendencies

Tendencies are freely editable between games and remain unchanged unless the user deliberately edits them. They use clear five-position sliders:

- Pass First ↔ Score First
- Patient ↔ Aggressive
- Perimeter ↔ Interior
- Create Own Shot ↔ Off-Ball
- Safe ↔ Creative Passing
- Push Transition ↔ Control Tempo
- Disciplined Defense ↔ Gamble
- Stay Attached ↔ Help
- Box Out ↔ Chase Rebounds
- Defer ↔ Seek Clutch Opportunities

During automatic play, behavior is weighted between user tendencies and coach instructions. Coaching influence varies with strictness, role, trust, professionalism, veteran status, and game context. Coaches never permanently edit user tendencies.

### 10.2 Layered player identity

A player's identity is expressed in separate layers. They are never merged, and none of them is a substitute for ability.

**Layer 1 — Rotation role.** How much the coach intends to use the player. One of: Star, Starter, Sixth Player, Rotation, Bench, Reserve, or Developmental. Rotation role is an intent set by the coach.

Availability facts—did not play, emergency duty, medically unavailable, not registered—are *not* rotation roles. They are separate derived states, and a night on the bench does not demote a Starter.

**Layer 2 — Tactical role.** What job the player is asked to do in a given game. Version 1.0 supports these tactical roles:

Primary Creator, Secondary Creator, Shooter, Slasher, Connector, Post Option, Roll/Pop Big, Perimeter Stopper, Interior Anchor, Rebounder, and Utility/Energy.

Only one tactical role is active at a time. It remains fixed during the game and can change only between games. Emergency actions do not silently relabel the player.

**Layer 3 — Derived archetype.** A read-only description assembled from body, ratings, and demonstrated profile, using composable descriptors such as *Two-Way Shot-Creating Guard* or *Stretch Rim Protector*. Archetypes describe; they never grant. No attribute, action, badge, role, or opportunity is unlocked by carrying an archetype label, and no archetype is exclusive to a build.

The separation of concerns is strict:

- **Tendencies** modify what the player prefers to attempt during automatic play.
- **Tactical role** modifies the opportunity the player receives.
- **Capability and context** determine whether the attempt succeeds.

Nothing in this layer stack changes a rating. A Shooter who cannot shoot will take shots and miss them.

### 10.3 Coaching identity and rotations

Every coach has one recognizable tactical identity, supported by a few compatible management traits.

Possible identities include pace-and-space, motion, star-centric, post-oriented, transition, defensive discipline, pressure, development-first, balanced, and veteran-reliant basketball. Management traits address areas such as rotation depth, mistake tolerance, development, and discipline.

Coaches establish relatively stable planned rotations, then adjust contextually for fatigue, fouls, injury, matchup, score, and overtime.

### 10.4 Trust and institutional authority

- High school: Coach Trust and Program Trust.
- College: Coach Trust and Athletic Department Trust.
- Professional organizations: Coach Trust and Front Office Trust.

Coach Trust represents the individual coach’s opinion. Institutional Trust represents standing within the organization. When leadership changes, a new coach inherits part of the player’s program reputation before forming an individual view.

While rostered, the user is a player within an organization. Full rosters are visible, but the organization retains final authority. Increased trust and veteran leadership allow the user to call plays, shape strategy, make suggestions, and influence personnel decisions without becoming a general manager. Free-agent, out-of-basketball, and career-complete periods do not imply organizational membership.

### 10.5 Chemistry

Team Chemistry is shown as one letter grade backed by a hidden continuous value. It derives from relationships, familiarity, role acceptance, trust, leadership, results, stability, and fit. Its basketball effects are real but modest. Individual relationships remain separate.

## 11. Career Pathways

### 11.1 Access rule

The player can enter only pathways for which he has received and accepted a legitimate offer or meets the pathway’s formal eligibility requirements. Menus never present impossible freedom as a valid contract or roster choice. No professional playing offer is guaranteed. Domestic developmental and overseas offers must be earned from performance, profile, eligibility, fit, and market interest; neither route is a guaranteed fallback.

Potential post-high-school routes include:

- College basketball.
- Domestic developmental leagues.
- Overseas basketball.
- Top domestic basketball only after one complete post-high-school career year and satisfaction of the final-entry rules in Section 11.6; immediate high-school-to-top entry is not permitted.
- Temporarily leaving organized basketball and attempting a highly risky comeback.

A complete post-high-school Out-of-Basketball career year counts toward the time requirement for first top-domestic draft eligibility even though it creates no roster membership, playing contract, or professional-service credit. For this route, the first post-high-school OOB cycle credits the qualifying year at the next scheduled top-draft eligibility checkpoint, before the second consecutive OOB determination, so the player receives a valid first/final entry opportunity rather than an accidental timing dead end. The player must still satisfy the single final-entry deadline; if no contract is accepted afterward, the ordinary second-failure rule remains in force.

### 11.2 High school placement and transfer

The player has a guaranteed assigned local public high school. The optional middle-school tournament can generate legitimate offers from other programs.

The school decision screen shows every accessible option with:

- Coaching identity.
- Projected role.
- Competition level.
- Prestige.
- Academics.
- Development quality.
- Relevant costs, conditions, and known risks.

Transfers are permitted during any offseason and can produce positive or negative consequences. Some information remains hidden until arrival, but the player can assess risk through public facts, research, visits, advisors, relationships, reputation access, and confidence labels. Essential known conditions are never hidden merely to create a trap.

### 11.3 High school competition

- Each active state contains four eight-school districts. The player’s district is simulated in full detail; the other three districts use reduced detail until a school becomes directly relevant.
- The 20-game regular season contains 14 home-and-away district games, four scheduled interdistrict games, and two scheduled showcase, rivalry, or tournament games.
- District qualification uses district record. Ties resolve by head-to-head mini-table, capped district point differential, then a deterministic draw established with the schedule.
- The top four schools from each district enter a 16-team, single-elimination state tournament. Its fixed cross-district bracket prevents same-district first-round matchups and does not reseed. Four wins produce the state champion.
- The 96-team National Tournament uses permanent state allocation tiers: 24 standard states receive one berth for the state champion, 16 strong states receive two berths for both finalists, and 10 major states receive four berths for all semifinalists.
- National seeds 33 through 96 play an opening round; seeds 1 through 32 receive byes. The bracket then continues with 64 schools and does not reseed or apply geographic protection. A national champion plays six games with a bye or seven without one.
- A high-school team therefore plays 20 to 31 official games depending on state and national advancement.
- All games can be simulated; the user chooses which to play.

The former classification championships, Open bracket, and separate small national invitational are not part of this structure. The National Tournament is the sole national school championship.

Schools outside the player’s district show a stable identity, location, record, Team Power Rating, state result, tournament history, and limited featured information. They gain roster, rotation, coaching, health, and tactical detail prospectively when direct competition, recruiting, transfer interest, scouting, or a narrative dependency makes them relevant. Promotion never changes a committed record or seed and never fabricates historical player box scores.

If the player transfers out of state, the destination becomes the active state and deterministically materializes its four districts. The prior state returns to reduced detail while committed history and personally known players and relationships persist.

School basketball and summer basketball occupy separate calendar segments. References to **24 content** remain presentation shorthand for 20 official school regular-season games plus four summer tournament blocks, not a season-length rule. Summer begins after the player’s actual school elimination date; deeper postseason runs produce a later arrival and carry their real fatigue, injury exposure, travel, development, and recovery consequences.

### 11.4 Summer basketball

LeagueBound uses an original national and regional AAU-style ecosystem.

- Summer basketball begins only after the player’s school season actually ends and uses separate clubs, schedules, statistics, workload, exposure, and history.
- The baseline annual presentation plan contains four summer tournament blocks; a block is not equivalent to one game.

- Regional and national circuits contain roughly 10–16 games for a deep run.
- Invitations and eligibility are required.
- Clubs differ in prestige, role, coaching, exposure, cost, travel, workload, and injury risk.
- The player can decline participation.
- The 16 summer organizations use separate age- and grade-appropriate squads rather than treating one roster as every cohort.
- Standard summer-circuit participation follows the freshman, sophomore, and junior school seasons.
- Committed graduates normally prepare for the next level. Unsigned graduates may receive legitimate invitations to separate exposure events; these are not a continuation of the standard underclass circuit.

Offer deadlines are visible. Event participation can preserve, improve, condition, or risk offers, but attendance does not automatically delay enrollment or create unavailable pathways.

### 11.5 College basketball

- Top-tier programs play approximately 30–32 regular-season games.
- Lower tiers play approximately 24–30.
- An eight-team conference tournament can add no more than three games.
- The 36-team national postseason can add five games for a team with an opening-round bye or six for a team that begins in the opening round.
- Mobile pacing comes from selective participation and calendar acceleration, not artificially short seasons.

College programs carry an ordinary 15-player roster. A successful walk-on occupies one of those 15 places; there is no separate practice-only or extended-walk-on roster. Commitments reserve projected roster and scholarship capacity in the appropriate future year. The sole capacity exception is an automatic, temporary hardship replacement authorized only when existing unavailability prevents a legal minimum game-day roster; it cannot become an ordinary sixteenth place or a walk-on route.

The college clock allows five academic years to play four competition seasons, with one ordinary redshirt and at most one rare medical-extension year. The locked College World system owns the visible, tuneable participation threshold, medical-hardship qualification, academic eligibility, and postseason treatment; postseason participation consumes a competition season. A first ordinary transfer is immediately eligible, while later transfers require a qualifying exception or one academic residence year that consumes an academic year but not a competition season.

Eligible players can enter a professional evaluation process, receive consensus-tier feedback and—when information supports it—a pick range with confidence. Workouts, interviews, medical information, new play, and organizational disagreement can change the evaluation. The user may withdraw before the final-entry deadline and return to college if still eligible. A finalized declaration permanently ends college eligibility and consumes the one lifetime final entry described in Section 11.6.

### 11.6 Professional basketball

The top domestic league uses an 82-game regular season, a fictional play-in structure, and four best-of-seven playoff rounds. Other leagues use appropriate shorter schedules.

The top draft has up to 48 selection opportunities. An organization passes only when no eligible entrant remains. A player receives only one finalized lifetime entry; a permitted pre-deadline withdrawal does not consume it. An undrafted final entrant becomes a free agent and can reach professional basketball only through earned contract opportunities.

Organizations present an initial contract. A representative automatically improves available terms according to negotiation ability and leverage. The user then accepts or rejects the final offer.

Representation options include:

- Self-representation.
- Parent representation.
- A certified hired agent.

Self and parent representation generally produce weaker terms. Contracts can include salary, duration, guarantees, options, incentives, role language, trade protections, and termination conditions. The complete term and every option are validated against the remaining portion of the 25-season professional maximum, including non-guaranteed seasons.

A drafted player can reject the drafting organization and pursue another eligible route, including overseas play or sitting out. The draft offseason is signing window one. The drafting organization retains only the top-domestic signing restriction through four signing windows. Those rights may be traded within the original clock or released early; a trade does not restart the clock, and any rights still active expire at the close of window four. Rights do not force a contract, membership, or assignment. Sitting out is intentionally risky and can lead to OOB resolution.

A developmental assignment requires an accepted top-domestic playing contract and is recorded as a temporary overlay on the player’s existing membership. It is not a rights-only placement or a loan. Import eligibility can change during a contract, but the roster classification and import-slot charge remain fixed for that term and are reconsidered only when a new or renewed playing contract begins.

A contracted player can request a trade at any time outside the locked game-day sequence. A private request and a public demand produce different pressure, leak risk, trust, and reputation consequences. Neither guarantees a trade or chosen destination.

## 12. Health, Availability, Injury, and Suspension

- The user may choose to play through an injury when medically eligible.
- Visible information includes expected performance limitations and qualitative aggravation, recurrence, and long-term risk.
- Team doctors can declare the player medically ineligible based on severity.
- Significant injuries offer meaningful choices such as rest, rehabilitation, surgery, playing through when cleared, seeking a second opinion, or using a specialist.
- Recovery estimates show a range, availability, limitations, qualitative risks, cost, medical recommendation, and confidence.
- Better information narrows uncertainty; poor staff produce wider estimates rather than deliberate lies.
- Essential safety information is never locked behind payment or advertising.
- Rehabilitation replaces some or all training opportunities according to severity.
- If injuries, suspensions, or other unavailability leave an organization unable to register a legal game roster, it automatically receives a temporary hardship replacement before the next match. This preserves schedule legality without ending existing memberships.
- A proposed suspension can be challenged before the ruling becomes final. Once finalized, its displayed duration is fixed and there is no separate post-ruling appeal.

## 13. Reputation, Social Media, and Followers

Reputation uses several related concepts rather than one universal popularity score:

- Basketball Reputation.
- Public Profile.
- Professionalism.
- Geographic Reach.
- Contextual reputation tags.
- Individual relationships.
- Phase-specific organizational trust.

LeagueBound contains one fictional social platform. It is primarily read-only. Occasionally the user can ignore a post or reply using authored options. Reply options communicate their general tone and risk before selection; consequences can range from negligible to severe.

A visible follower count rises and falls throughout the career. It directly affects recruiting attention, NIL access, sponsorships, media pressure, endorsement value, and audience reach. Media and community activities can grow the audience at the cost of time or energy.

## 14. NIL, Advisors, and Agents

NIL opportunities begin in high school. Rules vary by state and program but remain fixed throughout an individual career.

Deals can contain hidden risks, misleading promises, exclusivity, performance requirements, and reputation consequences. Research or advisor review can reveal these risks with confidence appropriate to the source.

Before professional representation, the user can seek advice from parents, a high-school coach, or a hired agent. A small agent pool refreshes each season. The user can hire and fire when contract terms permit.

Agent quality is displayed through reliable letter grades. Contracts include an upfront fee, a percentage commission, duration, termination costs, and possible relationship or reputation consequences. Advisors provide information and automatic negotiation; the player makes the final Accept or Reject decision.

## 15. Academics

- One GPA and eligibility model applies during relevant phases.
- Academic outcomes depend on study decisions, obligations, missed time, and circumstances rather than a separate academic-talent rating.
- Academic ineligibility can restrict games, offers, transfers, and college participation.
- Study competes with training, recovery, social, and other weekly activities.

## 16. Money, Assets, and Investment

- The player has one cash balance and a readable transaction history.
- Income includes contracts, NIL, sponsorships, endorsements, prizes where lawful, and events.
- Expenses include representation, treatment, recurring living costs, travel or event conditions, termination fees, purchases, and life events.
- Houses, cars, and luxury items serve collection, status, and role-playing purposes. They can have price, upkeep, resale value, and narrative consequences but do not grant arbitrary basketball boosts.
- One simple diversified investment fund is available.
- The player can deposit or withdraw at any time outside locked sequences.
- The fund is fee-free for simplicity.
- Calendar-based changes are saved permanently to prevent reload exploitation.

Version 1.0 does not require a deeper portfolio, individual securities, business ownership, or other expanded investment simulation.

## 17. Relationships and Family

The game tracks family, teammates, coaches, agents, romantic partners, rivals, friends, and mentors.

Relationships are presented through a qualitative summary calculated from hidden dimensions such as Trust, Respect, Affection, Rivalry, Loyalty, and Resentment. The interface explains the visible relationship naturally without exposing every number.

Romantic lives can include long-term partnerships, marriage, breakups, infidelity, and children. Presentation remains non-explicit and age-rating appropriate.

Version 1.0 can represent these relationships through authored events, relationship states, and career-history outcomes. Detailed household management, playable descendants, inheritance, and other elaborate family simulation are post-launch.

## 18. Narrative System

### 18.1 Event philosophy

Narrative events are circumstance-driven rather than guaranteed on a calendar. Quiet weeks are allowed. Ordinary weeks avoid stacking multiple major decisions, and major events remain uncommon.

The event system tracks:

- Prerequisites and exclusions.
- Career phase, calendar, location, organization, role, reputation, money, and health.
- Character and relationship history.
- Previous choices and unresolved storylines.
- Repetition limits and cooldowns.
- Event exclusivity and follow-up state.

Events should follow causally instead of appearing as disconnected prompts.

### 18.2 Content construction

- Major events are fully authored and testable.
- Repeatable life events use modular authored content with strict compatibility rules.
- Recaps, rumors, milestones, and social posts are assembled through deterministic rules based on actual simulation state.
- Live generative AI does not invent binding choices, consequences, contracts, injuries, crimes, deaths, or relationship outcomes.

This approach supports offline play, moderation, reproducibility, and reliable saves.

### 18.3 Major events and accolades

Career history records both major life events and basketball accomplishments, including state statistical leadership, championships, elite summer events, state awards, collegiate tournament success, national statistical leadership, draft outcomes, All-Star selections, professional awards, records, and defining career moments. Statistics, awards, records, earnings, service, and accomplishments remain attributed to the level and competition where they occurred; combined career summaries do not overwrite the separated source history.

### 18.4 Version 1.0 content floor

Version 1.0 targets the following minimum replayability catalog:

- 60 major fully authored events.
- 200 modular life events, including at least 80 relationship-focused events.
- 300 social and news templates capable of producing additional rule-based variations from real simulation state.
- 30 injury families with severity, recovery, and recurrence variants.
- At least 24 hairstyles, 12 facial-hair options, 16 accessories, and 24 clothing styles within the modular avatar system.
- 12 modular court themes, plus distinctive court treatments for all 24 top professional organizations.
- At least 120 gameplay, crowd, interface, and zany presentation sound effects.

These are ship-readiness floors rather than reasons to delay system testing until every item is complete. Content should be integrated and validated incrementally. The launch badge catalog contains the 16 badges defined in Section 8.

## 19. Career Endings, Death, and Second Chance

### 19.1 Career evaluation

There is no win/lose screen. At retirement or permanent ending, the game creates a descriptive legacy summary using what actually occurred:

- Career tier or legacy assessment.
- Personal and team achievements.
- Defining moments and turning points.
- Records and earnings.
- Relationships and reputation.
- Comparison with previous careers and family history.

A legendary reserve, overseas icon, loyal hometown player, injury comeback, wealthy role player, or all-time great can each create a meaningful career.

### 19.2 Continuation, OOB, and retirement

An ordinary school or college offseason does not trigger OOB while a valid roster membership will continue into the next competition season. When no such school or college membership carries forward, an offseason without an accepted professional playing contract places the player in or continues OOB status. The first consecutive unsuccessful offseason sets the OOB count to one; a second consecutive unsuccessful offseason makes the career complete. Accepting a playing contract resets the count. Rejected, expired, withdrawn, and never-received professional offers all resolve through this same cycle rather than creating separate hidden ending rules.

Professional service ends after 25 credited seasons across all professional levels, and no contract or option may cross that boundary. Voluntary retirement ends playing membership and forfeits unearned future salary except amounts already vested; the organization resolves the accounting automatically without a separate buyout minigame.

### 19.3 Rare death

Death is enabled for the user and NPCs in every career.

- The target lifetime probability for the user is approximately 1% across a complete career.
- Named NPC death can be slightly more common, with a tentative target near 1.25% and controls preventing implausible clustering.
- Causes can be realistic or obscure and absurd.
- Absurd deaths use deadpan, clearly fictional, non-graphic language.
- NPC death is permanent.

Final probabilities belong in the Balance Specification and must be tested across millions of simulated careers rather than interpreted as an annual chance.

### 19.4 Second Chance

When the user’s career ends early because of death, a career-ending prison sentence, or a career-ending injury, the game offers one rewarded-ad Second Chance for that specific event.

- Completing the ad literally resurrects or fully restores the player.
- There is no mechanical penalty.
- The specific event can be reversed only once.
- A later, distinct qualifying event can create another one-time offer.
- Normal retirement, maximum seasons, declining talent, and lack of roster interest do not qualify.
- A qualifying ending first creates a recoverable pending checkpoint; the career is not archived before the Second Chance decision resolves.
- If offline, the ending remains pending until reconnection and ad availability, or the user can accept the ending immediately.
- The opportunity is not consumed unless the rewarded ad completes successfully.
- A completed ad restores the player and resumes the career. An eligible pending ending becomes career complete and is archived only after the user declines the restoration or accepts the ending; being offline or receiving a failed/no-fill ad never causes archival.

## 20. Generational New Game Plus — Post-Launch

A player’s child can eventually become a generated basketball prospect and begin a future playable career in the same evolved world.

- The world and complete history continue.
- Family records and multi-generation legacy are tracked.
- Account-wide cosmetics remain available.
- The child has separate ratings, potential caps, badges, Badge Development Points, followers, and finances.
- No basketball ability is inherited mechanically.
- Parent mentorship can occur when circumstances permit.
- The child receives 25% of the parent player’s liquid cash and inherits supported family assets.
- Asset ownership, timing, upkeep, and edge cases require a dedicated post-core specification before implementation.

This is New Game Plus, not a second unrelated playable character inside the same active career.

This entire section describes a planned post-launch expansion. Version 1.0 saves should preserve enough stable world, family, career-history, and asset identifiers to support future migration, but launch is not blocked by playable descendants or inheritance.

## 21. Saving and Persistence

- The complete game is playable offline.
- Career progress saves locally and automatically; there is no manual Save command.
- Autosaves occur after meaningful state changes and make major outcomes permanent immediately.
- Save operations around major decisions use a recoverable transaction pattern to prevent duplication or partial outcomes.
- Crashes load the most recent valid checkpoint.
- Quitting or reloading cannot avoid losses, injuries, deaths, incarceration, contracts, relationship consequences, scouting errors, or other resolved outcomes.
- The permanence model is explained in Settings and Help rather than marketed as an Ironman mode.
- High-consequence confirmations state permanence when needed.

Launch supports exactly three independent local career slots. Each ordinary new career creates a fresh world and does not share progression or career history with another slot; only account-level settings and purchased entitlements are shared. Only a child/New Game Plus career continues an evolved world.

The player can permanently delete a save after a strong confirmation. Deletion removes the career, its world, and career-earned legacy provenance immediately. Real-money purchases and settings are never deleted. An independently created child/New Game Plus save remains playable.

Cloud backup may be added later. The launch save format must still include stable identifiers, schema versioning, timestamps, migration support, and account-unlock references. Paid purchases can be restored when online.

## 22. Monetization

LeagueBound is free, supported by advertising and optional purchases.

### 22.1 Advertising

- Rewarded advertising is the primary ad format.
- Mandatory interstitials are used minimally, with a starting target of no more than one per 8–12 minutes of active play plus cooldowns and session caps.
- Interstitials can appear after a game, after calendar advancement, after a quiet week, or when returning from a genuine session break.
- Ads never interrupt an active game, execution challenge, important decision, injury, death, prison event, contract, recruitment choice, or emotional scene.
- Ads do not appear offline.
- Advertising cannot sell ratings, potential, guaranteed offers, draft position, injury immunity, or favorable simulation outcomes.
- Served ads must be appropriate for the game’s assigned age rating and regional audience.
- Rewarded Second Chance presentation cannot use a countdown, artificial urgency, deceptive dismissal, or language intended to exploit distress around the career-ending event.

### 22.2 Purchases

Allowed purchases include:

- Avatar themes and parts.
- Hairstyles, accessories, facial hair, clothing, jerseys, and warmups.
- Interface themes and colorways.
- Zany backgrounds.
- Readable visual-effect or sound packs.
- The one-per-career badge respec.

Paid cosmetics are account-wide and permanent. Achievement and legacy cosmetics can also become account-wide. Houses, cars, and other in-world status items remain career-owned unless a supported inheritance rule applies.

Paid story packs are not part of the launch plan because of content, simulation, compatibility, and quality-assurance complexity.

Digital purchases use the applicable platform in-app purchase system and display their price, effect, permanence, and limitations before confirmation. LeagueBound contains no loot boxes, paid randomized rewards, or real-money wagering.

### 22.3 Privacy and platform disclosures

- Data collection is minimized because the career and authored social simulation function offline.
- The fictional social platform contains no user-generated content and does not connect users with strangers.
- Advertising, analytics, crash-reporting, and purchase SDK behavior must be disclosed accurately in each store and the privacy policy.
- Content-rating and target-audience questionnaires must be updated whenever shipped content changes the answers.
- Store marketing remains suitable for a general storefront even though the game itself targets mature teens and adults.

## 23. Accessibility and Input Comfort

Launch accessibility focuses on visual and input comfort without altering basketball outcomes:

- Adjustable text size.
- High contrast.
- Colorblind-safe palettes.
- Reduced motion.
- Screen-shake control.
- Reduced flashing effects.
- Sound-effect intensity.
- Haptic intensity.
- Large touch targets and readable typography.

Launch does not include timing-window assistance, reduced injury risk, boosted progression, improved scouting, easier academics, or easier recruiting and contracts. Accessibility additions that affect execution can be evaluated later without changing the single-standard career simulation.

## 24. Difficulty

LeagueBound has one standardized difficulty. Challenge emerges from build decisions, execution, role, opportunity, team fit, injuries, aging, relationships, finances, academics, competition, and bounded randomness.

There are no Easy, Normal, or Hard economy or simulation presets. Monetization does not function as a difficulty bypass.

## 25. Presentation and Audio Direction

The visual identity combines a grounded, premium basketball career simulation with colorful, zany personality.

- The Personal Hub and characters create warmth, identity, and visible life progression.
- Basketball information remains clean and highly legible.
- Team colors, court designs, crowds, backgrounds, celebrations, transitions, and sound effects carry much of the playful energy.
- Serious injuries, deaths, legal consequences, and emotional events use restrained presentation.
- Important games feel larger through entrances, crowd audio, environment, commentary, pressure cues, and consequences rather than substantially longer sessions.
- Sound effects can be exaggerated and memorable but cannot obscure timing or accessibility cues.

The previous all-dark, card-only “sports control room” direction is superseded. Dark surfaces may still appear where readable, but they are not the product identity or exclusive palette.

## 26. Launch Design Principles

These rules should be used to reject conflicting features:

1. The user is a basketball player, not a coach, general manager, or omniscient league operator.
2. The Personal Hub is the emotional home; spreadsheets support the fantasy rather than replace it.
3. User choice can influence probability and opportunity but cannot guarantee control over organizations or life.
4. Manual skill matters during played games; attributes determine difficulty and capability.
5. Played and simulated basketball share one truth.
6. Career consequences save permanently.
7. Important information is clear, but the game does not warn users away from every bad choice.
8. Random breakthroughs and setbacks exist but remain bounded and uncommon.
9. Major narrative events are rare, causal, authored, and testable.
10. Every new system must justify its value to the career fantasy and its cost on mobile performance, content production, balancing, and save compatibility.

## 27. Required Companion Specifications

The following details are intentionally not finalized inside the GDD:

- **Product Requirements Document:** launch scope, user flows, acceptance criteria, supported devices, performance budgets, analytics, compliance, and release milestones.
- **Simulation Specification:** possession states, derived ratings, shot and defense resolution, rotations, fatigue, fouls, statistics, and calibration targets.
- **Balance Specification:** attribute costs, rating bands, potential distributions, progression rates, career mileage, injuries, rare-event probabilities, recruiting odds, contracts, economy, and investment behavior.
- **Content Bible:** fictional basketball identities and presentation canon, including teams, programs, coaches, event templates, social posts, accolades, badges, death and legal-event tone, avatars, backgrounds, and audio; structural formats and rules remain with their owning design sources.
- **Personal Hub UX Specification:** objects, states, transitions, residence variants, phase-specific access, inbox priority, and notification behavior.
- **Godot Technical Design Document (`GODOT_TDD.md`):** pure-core and engine boundaries, deterministic randomness, SQLite save transactions, migrations, mobile platform integrations, and test strategy.

## 28. Lock Status

This GDD is **Locked** as the broad product-design vision for LeagueBound version 1.0 within the authority hierarchy stated at the start of the document. Explicit owner rulings and locked level-specific systems control their subjects, and companion specifications implement or tune the design without silently redefining it.

Locking the GDD does not freeze tuning values or prevent evidence-based iteration. Formula values, technical implementation, production milestones, detailed content definitions, and acceptance criteria belong in the companion specifications subject to the same hierarchy. Any future proposal that changes the player fantasy, launch boundary, core loop, career structure, authoritative simulation philosophy, Personal Hub, monetization boundaries, or other principles in this document requires an explicit GDD change review rather than an undocumented implementation decision.
