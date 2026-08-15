# LeagueBound Product Requirements Document

| Field | Value |
| --- | --- |
| Version | 2.1 |
| Date | August 14, 2026 |
| Status | Draft for implementation planning |
| Product owner | LeagueBound team |
| Platforms | iOS and Android |
| Technology baseline | Godot 4.x, typed GDScript, iOS and Android export |
| Source authority | Approved hierarchy in Section 1 |

## 1. Purpose

This document translates the approved LeagueBound design into testable version 1.0 product requirements. It defines what must ship, what is deliberately deferred, how users move through the product, how completion is evaluated, and which release gates prevent unfinished systems from being treated as production-ready.

This PRD does not define final formulas, probabilities, tuning values, individual story scripts, or low-level software architecture. Those belong in the companion Simulation, Balance, Content, Personal Hub UX, and Technical Design specifications.

When current documents disagree, apply this authority order:

1. Explicit owner rulings.
2. Explicitly locked, level-specific system documents.
3. Later and more-specific working frameworks.
4. `GDD.md`.
5. This PRD.
6. `SIMULATION_SPEC.md`.
7. `BALANCE_SPEC.md`.
8. `GODOT_TDD.md`.
9. `CONTENT_BIBLE.md`.
10. Older or broader superseded wording.

A higher source controls whenever two sources disagree. `GODOT_TDD.md` is the current technical implementation authority and may choose a compatible representation, but it cannot redefine game rules, add player-facing scope, or override a higher-authority source. The previous React Native / Expo `TDD.md` and implementation are archived reference only. A new Godot repository establishes current implementation evidence; historical project-status and design artifacts are not gameplay authority.

## 2. Product Summary

LeagueBound is an offline-first, single-player basketball career RPG and simulation for portrait mobile devices. The user creates a player, begins as a United States high-school freshman, and lives a career that can progress through college, developmental basketball, overseas competition, and the top domestic professional league.

The central promise is:

> Playing the basketball career I never had.

The player is not a general manager and does not control the world. He develops his abilities, performs in games, manages his time and life, evaluates legitimate opportunities, builds relationships, earns influence, and lives with permanent outcomes. A complete career is evaluated through its naturally produced history rather than a selected victory condition.

## 3. Product Goals

### 3.1 Primary goals

1. Deliver one complete and replayable freshman-to-retirement career in version 1.0.
2. Make a layered 2.5D Personal Hub the emotional and navigational center of the experience.
3. Join accessible three-to-five-minute played games with a credible shared simulation engine.
4. Give basketball experts meaningful depth without requiring newcomers to understand every term immediately.
5. Support persistent rosters, history, relationships, progression, and consequences while remaining fully playable offline.
6. Create enough authored and systemic variation for multiple careers to feel meaningfully different.
7. Release a stable, compliant mobile product that does not monetize competitive outcomes.

### 3.2 Non-goals for version 1.0

- Multiplayer, online leagues, leaderboards, or user-generated content.
- Women’s basketball.
- International youth origins.
- Licensed real-world teams, leagues, athletes, logos, or tournaments.
- Child/New Game Plus careers.
- Inherited assets or playable descendants.
- Detailed household or family management.
- Deep portfolio investing, individual securities, or business ownership.
- Free-roaming 3D residences.
- Landscape orientation.
- Joystick player movement.
- Full team management or general-manager authority.
- Cloud save as a launch dependency.
- Paid story packs, loot boxes, randomized paid rewards, or pay-to-win boosts.
- Live generative AI producing binding narrative or simulation outcomes.

## 4. Target Users and Jobs

### 4.1 Career-story player

Wants a memorable life and basketball history containing relationships, difficult choices, setbacks, money, status, and unexpected events.

**Job:** “Let me live a basketball life that produces stories I want to remember and compare.”

### 4.2 Basketball optimizer

Wants detailed ratings, build experimentation, credible tactics, statistics, team fit, roster movement, and understandable simulation consequences.

**Job:** “Let me build a specific kind of player and see whether that player actually works in basketball.”

### 4.3 Short-session mobile player

Wants meaningful progress during a few minutes without losing the depth of a long career.

**Job:** “Let me make one useful decision, play or simulate a game, and leave knowing my career saved.”

### 4.4 Returning career-mode fan

Recognizes the emotional appeal of classic Superstar and Campus Legend modes and wants a modern mobile equivalent centered on the player’s personal space.

**Job:** “Make my career feel like a place and a life, not a sequence of spreadsheet screens.”

## 5. Version 1.0 Experience Boundary

### 5.1 Career phases

Version 1.0 must support:

1. Player creation.
2. Optional three-game middle-school prologue.
3. Four high-school seasons.
4. Eligible summer basketball.
5. Post-high-school pathway selection from legitimate offers.
6. College eligibility and competition where selected.
7. Domestic development, overseas, temporary departure, and comeback pathways where legitimately offered and eligible.
8. Top-domestic draft eligibility only after one complete post-high-school career year; immediate high-school-to-top entry does not exist.
9. A professional career lasting up to 25 credited seasons across domestic development, overseas, and top domestic play combined.
10. Voluntary and involuntary career endings.
11. A complete legacy summary.

The user does not need to experience every phase during one career. The product requirement is that every supported route can form a valid, complete career.

### 5.2 Launch world

The launch world contains:

- 32 persistent high schools in the player’s active state, generated as four eight-school districts, plus a lightweight national school pool.
- 64 colleges.
- 16 summer organizations, each operating separate age- or grade-group squads under one organizational identity.
- 12 domestic developmental teams.
- 12 teams in one supported overseas league.
- 24 top domestic professional teams.

Every materialized organization requires a stable identifier, name, location, colors, competitive profile, home environment, coaching context, schedule participation, roster rules, and historical record. Background national schools require only the summary identity and competitive state defined below until relevance promotion. Rosters and many staff members may be generated.

### 5.3 Launch content floor

The ship candidate must contain at least:

- 60 major authored events.
- 200 modular life events, including at least 80 relationship-focused events.
- 300 social and news templates with rule-based variants.
- 16 four-tier badges.
- 30 injury families with severity, recovery, and recurrence variants.
- 24 hairstyles, 12 facial-hair options, 16 accessories, and 24 clothing styles.
- 12 modular court themes.
- Distinctive court treatments for all 24 top professional teams.
- 120 gameplay, crowd, interface, and zany presentation sound effects.

Content counts are release floors, not substitutes for quality. Duplicate text with renamed entities does not count as a distinct authored event unless its prerequisites, choices, and consequences materially differ.

## 6. Critical User Journeys

### 6.1 Start a standard career

1. Select an empty save slot.
2. Create and customize the player.
3. Allocate physical profile and detailed ratings.
4. Review exact Overall, visible caps, derived archetype, and build summary.
5. Confirm the permanent build.
6. Choose to play or skip the middle-school prologue.
7. Enter the freshman Personal Hub.

**Success condition:** The user reaches the freshman Personal Hub with a valid player, valid assigned public school, initialized world, initialized schedule, and durable autosave.

### 6.2 Complete a normal week

1. Enter the Personal Hub and understand current status.
2. Review required obligations and available discretionary capacity.
3. Choose activities or leave capacity unused.
4. Resolve blocking decisions.
5. Choose Play or Sim for an eligible game.
6. Receive results, development, relationships, finances, reputation, and world updates.
7. Advance to the next meaningful interruption.

**Success condition:** The week resolves without contradictory state, duplicate rewards, lost decisions, or manual saving.

### 6.3 Play a game

1. Review opponent, role, health, and importance.
2. Enter the portrait top-down court.
3. Observe automatic movement and tactical simulation.
4. Respond to role-appropriate contextual opportunities.
5. Complete action-specific challenges where offered.
6. Skip to the next appearance or final result when desired.
7. Review the postgame report and return to the career.

**Success condition:** A normal meaningful game completes in approximately three to five minutes and produces the same statistical and progression contract used by a simulated game.

### 6.4 Evaluate an offer

1. Receive a legitimate offer through the phone or a required interruption.
2. Review public facts, role, prestige, coaching identity, conditions, deadlines, and known risk.
3. Research or seek advice when available.
4. Accept or reject the final offer.
5. Persist the decision and its consequences immediately.

**Success condition:** The user cannot select an ineligible destination, miss a hidden mandatory term that should be public, or reverse the result by quitting.

### 6.5 End a career

1. Trigger retirement, maximum service, lack of roster interest, career-ending injury, incarceration, or death.
2. Offer Second Chance only for a qualifying unforeseen ending.
3. Permanently accept the ending or complete the eligible rewarded-ad rescue.
4. Produce a legacy summary from the actual career history.
5. Return to save-slot management without losing account-owned purchases.

**Success condition:** The ending, rescue eligibility, legacy record, and save state survive restart and cannot be duplicated.

## 7. Functional Requirements

Requirement priority uses:

- **P0:** Required for version 1.0 submission.
- **P1:** Required for the intended version 1.0 experience but can follow the first end-to-end internal build.
- **P2:** Valuable polish that may be reduced only through explicit product review.

### 7.1 Application foundation and navigation

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| APP-001 | P0 | The shipping app runs in portrait orientation only. | iOS and Android builds remain portrait across the Hub, menus, game day, ads, and return-from-background flows. |
| APP-002 | P0 | The app opens to save-slot management or resumes the most recently selected valid career according to product settings. | No development reset, hard-coded test player, or data-clearing behavior is present in production. |
| APP-003 | P0 | The primary career navigation is the Personal Hub. | A user can access the current week, phone, training, career history, deeper records, and appearance from recognizable Hub objects or stable companion navigation. |
| APP-004 | P0 | Navigation never requires network connectivity. | Every career destination except advertising, purchase, restore, and optional future cloud functions works in airplane mode. |
| APP-005 | P1 | Unavailable actions remain visible with an explanation. | Suspension, injury, travel, eligibility, money, phase, and role restrictions identify why access is blocked. |

### 7.2 Save slots, autosave, and offline operation

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| SAVE-001 | P0 | Version 1.0 provides exactly three independent local career slots. | Each slot displays player name, age, phase, organization, season, Overall, status, last-played time, and generation marker. Worlds, choices, progression, and career history never cross slots; only account-level settings and purchased entitlements may be shared. |
| SAVE-002 | P0 | Career state autosaves after every meaningful mutation. | Restarting after a game, allocation, offer, event, injury, purchase effect, or calendar advance restores the resolved state. |
| SAVE-003 | P0 | Committed major outcomes and approved pending checkpoints are permanent immediately. | Force-quitting cannot reroll or avoid a resolved loss, injury, death, incarceration, contract, transfer, relationship event, or scouting result. A qualifying Second Chance ending remains a durable pending checkpoint rather than becoming a permanent archive before the user resolves it. |
| SAVE-004 | P0 | Save writes use recoverable transactions and schema migration. | Interrupted writes load the last valid checkpoint; migrations are automated, versioned, and tested. |
| SAVE-005 | P0 | A career can be deleted permanently after strong confirmation. | The exact target is identified, deletion removes career-owned data, and account purchases/settings remain intact. |
| SAVE-006 | P0 | The complete career remains playable offline. | A new or existing career can advance without login or server access after required install assets exist locally. |
| SAVE-007 | P1 | The data model is compatible with future cloud backup and post-launch New Game Plus. | Saves have stable IDs, timestamps, schema versions, world/history identifiers, unlock provenance, and migration tests. |

### 7.3 Player creation and avatar

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| BUILD-001 | P0 | The builder supports Guard, Wing, and Big position families and credible physical ranges. | Invalid physical combinations are prevented; unusual but credible builds remain possible. |
| BUILD-002 | P0 | The user manually allocates all 20 public attributes. | Allocation uses whole points, universal bands, increasing costs, and exact per-attribute potential caps. |
| BUILD-003 | P0 | The builder permits weak, experimental, and specialized builds. | Confirmation summarizes the result without blocking or labeling a build as incorrect. |
| BUILD-004 | P0 | Current Overall is exact and role-neutral. | The same formula applies to user and NPC players and excludes popularity, trust, and team fit. |
| BUILD-005 | P0 | Archetype and position labels are derived descriptions. | Changing physical or attribute inputs updates the preview without imposing archetype-exclusive attributes. |
| AVATAR-001 | P0 | The user can customize a modular portrait avatar. | Skin tone, face, hair, facial hair where applicable, clothing, and supported accessories persist across every portrait surface. |
| AVATAR-002 | P0 | NPC portraits are generated from the compatible modular system. | Generated combinations are valid, diverse, stable by character ID, and render offline. |
| AVATAR-003 | P1 | Portrait expressions respond to circumstances. | At minimum, neutral, confident, celebratory, angry, injured, fatigued, embarrassed, and grieving states are supported where context permits. |

### 7.4 Personal Hub

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| HUB-001 | P0 | Every career phase has an appropriate layered 2.5D residence. | High school, college/development, early professional, and higher-status residence states are supported without free-roaming 3D. |
| HUB-002 | P0 | Hub scenes use background, interactive midground, foreground, lighting, and restrained parallax layers. | Effects maintain readability and honor reduced-motion settings. |
| HUB-003 | P0 | Hub objects reflect game state. | Unread phone, travel, training storage, trophies, owned items, relationships, and major status changes can visibly alter the scene. |
| HUB-004 | P0 | Hub hotspots remain explicit and accessible. | Every interactive object has a visible or discoverable label, a large touch target, and a nonvisual accessibility name. |
| HUB-005 | P1 | Residences reflect owned assets and career history without granting hidden boosts. | Cosmetic/status changes persist and match the financial ledger and career record. |

### 7.5 Calendar and weekly loop

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| WEEK-001 | P0 | The career advances through weeks with automatic obligations and variable discretionary capacity. | Capacity responds to phase, travel, injury, suspension, academics, playoffs, money, and offseason state. |
| WEEK-002 | P0 | Quiet periods can resolve rapidly. | A user can advance ordinary weeks without opening repetitive empty screens. |
| WEEK-003 | P0 | The game stops for decisions that cannot be safely automated. | Advancement cannot bypass expiring offers, enrollment, medical ineligibility, legal events, or career-ending choices. |
| WEEK-004 | P0 | Information follows the four-level priority model. | Ambient Hub state, phone/inbox items, required interruptions, and deep reference menus do not compete for identical prominence. |
| WEEK-005 | P1 | Risky overbooking is possible where allowed. | The preview communicates visible time, energy, condition, and known consequences before confirmation. |
| WEEK-006 | P0 | School basketball and summer basketball use distinct calendar segments. | School-team games, summer-club tournament blocks, statistics, standings, workload, and history cannot be merged or double-counted. |
| WEEK-007 | P0 | Every pathway advances through one global career-year spine with once-only annual resolution. | Reloading, changing levels, transferring, assignment, recall, release, or changing simulation detail cannot rerun a completed milestone. Each career year permits at most one age increase, one natural development-or-decline resolution, one generic offseason-development phase, and one professional-service credit; professional service is credited at most once when the player occupies a professional roster during official competition. |

### 7.6 World, rosters, and organizations

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| WORLD-001 | P0 | Every new standard career starts from the same fictional basketball canon and deterministic generation rules. | Fixed later-level organizations remain authored; high-school identities and structures reproduce from the career seed and content version and remain stable after materialization. |
| WORLD-002 | P0 | People and results cause the world to diverge. | Generated rosters, development, injuries, transfers, staff changes, awards, and championships persist in history. |
| WORLD-003 | P0 | The world uses full-detail, relevant-aggregate, and background-summary simulation fidelity. | Detail may change, but every tier obeys the same membership, eligibility, contract, rights, assignment, import, career-year, roster, and history rules. Direct competition receives possession detail; relevant competition retains sufficient aggregate evidence; distant competition retains legal summaries and major outcomes without fabricated historical box scores. |
| WORLD-004 | P0 | Every team produces a legal roster under its competition-specific rules. | Roster size, eligibility, scholarships, contracts, redshirts, development status, availability, and game registration are enforced while each player's identity and committed history remain stable. |
| WORLD-005 | P0 | Full rosters and exact current Overall ratings are visible for materialized teams. | Background high schools show identity, location, record, Team Power Rating, state result, tournament history, and limited featured information until relevance promotion; detailed scouting information can remain incomplete or stale. |
| WORLD-007 | P0 | High-school simulation depth follows relevance. | The active district uses full detail, other active-state districts use team-level detail, and the national pool uses national-index detail without fabricated historical box scores. |
| WORLD-008 | P0 | Relevance promotion is deterministic, persistent, and prospective. | Notability, direct competition, recruiting, award relevance, transfer or draft interest, scouting, relationships, or narrative dependency persist the person’s identity, legal membership, eligibility, sufficient aggregate evidence, awards, movement, and committed history before added detail. Promotion cannot change committed records or seeds or fabricate prior box scores. |
| WORLD-009 | P0 | An out-of-state high-school transfer moves the active-state window. | The destination state materializes deterministically; the former state reduces detail while committed history and personally known people and relationships persist. |
| WORLD-006 | P0 | Statistics, awards, records, earnings, service, and history remain attributed to the competition level where they occurred. | School, summer, college, developmental, overseas, and top-domestic records remain queryable without being combined into an incorrect official total; retained detail remains appropriate to the simulation tier. |
| WORLD-010 | P0 | Membership, playing contracts, top-domestic signing rights, and temporary assignment are separate control facts. | A player has at most one current official playing membership, one active playing contract, one top-domestic signing-rights holder, and one assignment overlay. Rights alone create no contract, membership, salary, or assignment authority; assignment requires an accepted top-domestic playing contract and creates no second membership or playing contract. Non-playing agreements do not count as playing contracts. During summer-club competition, the club is the one current membership and a continuing school place is a next-season reservation or affiliation until summer membership closes. |
| WORLD-011 | P0 | Availability, eligibility, assignment, and game-day registration remain separate from membership. | Injury, suspension, assignment, or non-registration never silently ends membership or creates another one. “Inactive” is a derived presentation label. Professional loans do not exist at launch for the user or background players. |

### 7.7 Basketball simulation and game day

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| SIM-001 | P0 | Played and simulated games use one authoritative engine. | Identical inputs produce compatible statistical distributions, development, fatigue, injuries, and outcomes regardless of presentation mode. |
| SIM-002 | P0 | The engine models possession context. | Score, time, period, lineups, role, tactics, fatigue, fouls, matchup, tendencies, and coaching instructions influence resolution. |
| SIM-003 | P0 | Coaches maintain planned rotations with contextual adjustment. | Fatigue, fouls, injury, score, matchup, and overtime can change minutes without rebuilding the rotation arbitrarily every possession. |
| SIM-004 | P0 | The user can choose Play or Sim for every eligible game. | Highlighted importance never forces manual play. |
| GAME-001 | P0 | Played games use a portrait, top-down, vertically oriented full court. | Court, players, ball, score, clock, and interaction targets remain readable on supported phone sizes. |
| GAME-002 | P0 | Movement is automatic and interactions are contextual. | No joystick is required; action options appear only when the player has a valid basketball opportunity. |
| GAME-003 | P0 | Interaction frequency follows role and involvement. | Bench and low-usage games can have few or no prompts without generating fake touches. |
| GAME-004 | P0 | A normal meaningful game lasts approximately three to five minutes. | Beta telemetry and timed usability testing meet the range for the median played meaningful game. |
| GAME-005 | P0 | Action challenges match their basketball action. | Shooting, passing, defense, rebounding, cutting, screening, and related opportunities do not reuse an unrelated input merely for variety. |
| GAME-006 | P0 | Shooting timing is user skill, with ratings controlling difficulty. | Valid perfect releases are clearly identified and guaranteed to succeed; impossible attempts can omit a perfect zone. |
| GAME-007 | P0 | Non-shooting perfect execution can still be countered. | The engine maximizes action quality without bypassing defenders or context. |
| GAME-008 | P0 | The user can pause outside an active challenge and safely background the app. | Pausing cannot extend or reroll a challenge; background restoration does not corrupt match state. |
| GAME-009 | P0 | The user can skip to the next appearance or final result. | Skipped time follows saved tendencies and coach instructions and applies no artificial penalty. |
| GAME-010 | P1 | Important games receive elevated presentation rather than major length inflation. | Entrances, crowd, backgrounds, commentary, pressure cues, and clutch depth scale with importance. |

### 7.8 Tendencies, roles, trust, and chemistry

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| ROLE-001 | P0 | The user has ten freely editable five-position tendency sliders between games. | Tendencies persist, never change automatically, and affect simulated behavior. |
| ROLE-002 | P0 | Players have one rotation role and one active tactical role. | The tactical label remains fixed during a game and can change only between games. |
| ROLE-003 | P0 | Coaches have one recognizable tactical identity and compatible management traits. | Identity affects tactics; traits affect rotation, development, discipline, and mistake tolerance. |
| TRUST-001 | P0 | Coach Trust and institution-equivalent trust are distinct. | High school uses Program Trust, college uses Athletic Department Trust, and professional phases use Front Office Trust. |
| TRUST-002 | P1 | Trust unlocks influence without transferring organizational control. | Veteran users can call plays, suggest strategy, and influence decisions while the organization keeps final authority. |
| CHEM-001 | P1 | Team Chemistry is displayed as one letter grade. | A hidden continuous value derives from relationships, familiarity, role acceptance, stability, fit, and results and has modest effects. |

### 7.9 Attributes, training, aging, and badges

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| PROG-001 | P0 | General Attribute Points can be spent between games on any eligible attribute. | Costs follow universal rating bands, increases are whole points, caps are enforced, and allocation is permanent. |
| PROG-002 | P0 | Focused circumstances can apply direct attribute progress. | Direct progress identifies its target and respects the same cap and fractional-progress rules. |
| PROG-003 | P0 | Fractional progress is visible but not numerically precise. | A progress bar updates correctly without showing its exact hidden fraction. |
| PROG-004 | P0 | Training previews and pays an exact ordinary reward. | A completed ordinary session always provides the displayed Attribute Points; exceptional interruption is clearly signaled. |
| PROG-005 | P0 | Training opportunities accumulate to a visible contextual cap. | Stored amount survives restart and responds to age, facilities, coaching, offseason, and major circumstances within documented limits. |
| PROG-006 | P0 | Played and simulated games use identical development rules. | Neither path produces a hidden progression multiplier; seasonal anti-farming limits apply equally. |
| AGE-001 | P0 | Aging and decline are category-specific and mileage-aware. | Physical abilities decline earlier; technical and IQ ratings follow documented later-career curves influenced by workload, injury, and inactivity. |
| BADGE-001 | P0 | Version 1.0 contains exactly 16 badges in four focused families. | Each supports Bronze, Silver, Gold, and Hall of Fame and has a measurable simulation contract. |
| BADGE-002 | P0 | Finalized qualifying awards identified by the owning competition can award spendable Badge Development Points. | Each competition finalizes awards exactly once after its postseason for the career year. Candidate, watch-list, nomination, semifinalist, and finalist status never grants a point; a repeated finalized award grants another point only when the owning rule permits it. Unspent points persist indefinitely. |
| BADGE-003 | P1 | One paid badge-only respec is available per career. | It refunds only spent badge points, is clearly priced, cannot affect attributes or potential, and cannot be purchased twice for the same career. |

### 7.10 School, summer, and college pathways

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| PATH-001 | P0 | Every player has a guaranteed assigned local public high school. | A career remains valid when the prologue is skipped or produces no outside offer. |
| PATH-002 | P0 | Only legitimate earned offers and formally eligible routes are selectable. | Inaccessible routes remain absent or visibly unavailable with a reason. Completing high school does not guarantee a developmental or overseas offer; a player with no continuing school or college membership and no accepted professional playing contract can enter Out of Basketball. |
| PATH-003 | P0 | High-school regular seasons contain 14 home-and-away district games, four scheduled interdistrict games, and two scheduled showcase, rivalry, or tournament games. | Every school receives exactly 20 regular-season games; only district games determine the four qualifiers from each eight-school district. |
| PATH-005 | P0 | Four district qualifiers enter a 16-team state tournament. | The fixed cross-district single-elimination bracket prevents same-district first-round games, does not reseed, and produces a champion after four rounds. |
| PATH-006 | P0 | State results populate one 96-team National Tournament through permanent state allocation tiers. | Twenty-four states qualify one champion, 16 qualify two finalists, and 10 qualify four semifinalists; seeds 33–96 play an opening round, seeds 1–32 receive byes, and the bracket produces one champion without reseeding or geographic protection. |
| PATH-007 | P0 | The state tournament and National Tournament replace classification, Open-bracket, and smaller invitational championships. | No deprecated school championship can generate a second national title or add games to the official schedule. |
| PATH-004 | P0 | Transfers occur only during offseasons. | Known benefits, risks, costs, deadlines, and consequences are previewed; research can reduce uncertainty. |
| SUMMER-001 | P0 | The 16 summer organizations operate as umbrella identities with separate age- or grade-group squads in a calendar segment separate from school basketball. | Standard participation follows the freshman, sophomore, and junior school seasons. Unsigned graduates use separate exposure events rather than returning to ordinary age-group squads. Entry uses the player’s actual school-elimination date and carries fatigue, health, travel, development, recovery, statistics, and history state without merging school and summer competition. An accepted club becomes the one current competition membership for the summer; the continuing school place is retained only as a next-season roster reservation or affiliation and resumes after club membership closes. |
| COLLEGE-001 | P0 | College schedules use authentic-style game counts. | Regular seasons remain within the owning College World ranges; an eight-team conference tournament requires no more than three games, and the 36-team national tournament requires five wins with an opening-round bye or six wins from the opening round. |
| COLLEGE-002 | P0 | College provides five academic years in which to play no more than four competition seasons, with one ordinary redshirt and at most one rare approved medical-extension year. | The participation threshold is player-visible and tuneable within that structure; participation beyond it consumes the season, and postseason participation always consumes the competition season. Eligibility history remains visible and deterministic. |
| COLLEGE-003 | P1 | Eligible users can enter and withdraw from professional evaluation before a deadline. | Feedback includes consensus tier, conditional range, confidence, and updates from new evidence. |
| COLLEGE-004 | P0 | College programs carry 15-player rosters. | A successful walk-on occupies one of the 15 positions, no practice-only or extended roster bypass exists, and commitments reserve projected roster and applicable scholarship capacity. |
| COLLEGE-005 | P0 | College transfer eligibility follows the approved first-transfer and repeat-transfer rules. | The first ordinary transfer is immediately eligible. A later transfer requires an applicable exception or one non-playing residence year; residence consumes an academic year but not a competition season. |
| COLLEGE-006 | P0 | Professional declaration has one clear withdrawal boundary. | Timely withdrawal before final entry preserves college eligibility when otherwise valid. A finalized declaration permanently ends college eligibility and consumes the one lifetime final entry. |

### 7.11 Professional pathways and contracts

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| PRO-001 | P0 | The top domestic league uses 82 regular-season games, a fictional play-in, and four best-of-seven playoff rounds. | Scheduling, standings, qualification, fatigue, awards, and history complete without calendar corruption. |
| PRO-002 | P0 | Representation improves final contract terms automatically. | Self, parent, and agent representation produce documented negotiation differences; the user accepts or rejects the final offer. |
| PRO-003 | P0 | Drafted players can reject the drafting team and pursue eligible alternatives. | The draft offseason is signing-rights window one. One top organization can hold the rights, which may be traded or released and otherwise expire at the close of window four; a trade does not restart the clock. Rights restrict only top-domestic signing and do not force a contract, membership, or assignment. |
| PRO-004 | P0 | Contracted users can request a trade outside locked game-day sequences. | Private and public requests produce distinct pressure, leak, trust, and reputation consequences without guaranteeing a move. |
| PRO-005 | P1 | Contract terms support salary, duration, guarantees, options, incentives, role language, protections, and termination conditions. | All active terms are visible before acceptance and enforced afterward. |
| PRO-006 | P0 | Top-domestic draft entry begins only after one complete post-high-school career year and is final only once in a lifetime. | The player cannot enter directly from high school. The qualifying year may be completed in college, domestic development, overseas basketball, or Out of Basketball; an OOB year advances the eligibility clock but creates no membership, contract, or professional-service credit. The first post-high-school OOB cycle credits eligibility at the next scheduled draft checkpoint before the second consecutive OOB determination, preventing a timing dead end. The draft provides up to 48 selection opportunities and an organization passes when no eligible entrant remains. A final entrant who goes undrafted becomes a free agent and cannot re-enter a later draft. |
| PRO-007 | P0 | A developmental assignment requires an accepted top-domestic playing contract. | A rights-only player cannot be assigned. Assignment remains a temporary overlay on the existing top contract and membership and does not create a loan or second playing contract. |
| PRO-008 | P0 | Overseas import classification is fixed at the playing-contract boundary. | Underlying residency or naturalization eligibility may change during a term, but the roster classification and import-slot treatment remain fixed until a new or renewed contract begins. |
| PRO-009 | P0 | Professional offers and retirement respect the shared 25-season boundary. | The complete proposed playing-contract term and every option, including non-guaranteed seasons, fit the player’s remaining capacity across all professional levels or cannot be accepted as written. Retirement ends membership, forfeits unearned future salary except vested amounts, and resolves accounting automatically without a buyout minigame. |

### 7.12 Health and injury

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| HEALTH-001 | P0 | Condition, workload, injury history, and qualitative durability information are visible. | Hidden exact durability is never shown as a false precise value. |
| HEALTH-002 | P0 | The user can play through an injury only when medically eligible. | Performance limitations and qualitative aggravation, recurrence, and long-term risk are shown before confirmation. |
| HEALTH-003 | P0 | Team doctors can declare medical ineligibility. | The restriction blocks game participation and displays its basis and estimated review state. |
| HEALTH-004 | P1 | Significant injuries offer rest, rehabilitation, surgery, second opinion, specialist, and cleared play-through when context permits. | Each option displays recovery estimate, limitations, risk, cost, recommendation, and confidence. |
| HEALTH-005 | P0 | Rehabilitation replaces training according to severity. | Training storage, rewards, and recovery cannot be duplicated during rehab. |
| HEALTH-006 | P0 | Lowering a potential cap does not silently lower current ability. | A cap-only reduction preserves the current rating and blocks further growth while current ability remains above the cap. Any current-rating loss resolves as a separate visible injury, health, or decline effect. |
| HEALTH-007 | P0 | A scheduled match always receives a legal game-day roster. | If injury, suspension, or other unavailability leaves an organization below its competition minimum, an authorized hardship or temporary replacement is supplied automatically before match creation without requiring user-controlled roster administration. The owning competition's narrow exception preserves existing memberships; at college it may exceed the ordinary fifteen-player cap only for demonstrated necessity and cannot become an ordinary roster, walk-on, or recruiting route. |
| HEALTH-008 | P0 | Suspension decisions have one pre-ruling challenge boundary and a fixed final result. | A proposed suspension may be challenged before it becomes final. Once imposed, the displayed duration is fixed and version 1.0 provides no separate post-ruling appeal. |

### 7.13 Reputation, social, NIL, and representation

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| REP-001 | P0 | Basketball Reputation, Public Profile, Professionalism, Reach, tags, relationships, and phase trust are distinct. | No single popularity number substitutes for all opportunity logic. |
| SOCIAL-001 | P1 | One authored fictional social platform is primarily read-only. | It functions offline and contains no user-generated content or real-user communication. |
| SOCIAL-002 | P1 | Occasional reply choices signal tone and risk. | Ignoring is always available and consequences range according to authored rules. |
| SOCIAL-003 | P0 | A visible follower count affects opportunities and pressure. | Recruiting, NIL, sponsorship, endorsement, and media systems read the same persisted follower value. |
| NIL-001 | P1 | NIL can begin in high school under fixed career rules. | State/program eligibility, hidden clauses, research, advice, negotiation, and consequences are enforced. |
| AGENT-001 | P1 | Parents, high-school coach, self-representation, and hired agents have phase-appropriate roles. | Reliable letter grades, fees, commissions, durations, termination costs, and negotiation outcomes are visible and persisted. |

### 7.14 Academics, finances, assets, and relationships

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| ACADEMIC-001 | P0 | One GPA and eligibility system responds to study decisions and circumstances. | Academic outcomes can block participation and offers and contain no separate aptitude attribute. |
| MONEY-001 | P0 | One cash balance and immutable transaction ledger track all income and expense. | Every balance change has a source, date/week, category, and amount; totals reconcile after restart. |
| MONEY-002 | P1 | Houses, cars, and luxury items support collection, status, resale, upkeep, and narrative use. | Items do not grant undocumented basketball bonuses. |
| MONEY-003 | P1 | One simple fee-free diversified fund supports deposits and withdrawals. | Calendar changes are permanent and cannot be rerolled through reload. |
| REL-001 | P0 | Family, teammates, coaches, agents, romantic partners, rivals, friends, and mentors use a shared relationship model. | Qualitative labels derive from persistent hidden dimensions and character history. |
| REL-002 | P1 | Version 1.0 supports authored partnership, marriage, breakup, infidelity, and child outcomes. | Content remains non-explicit; no playable descendant, household simulation, or inheritance is required. |

### 7.15 Narrative, endings, and legacy

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| NARR-001 | P0 | Events are selected from prerequisites, history, cooldowns, repetition limits, unresolved stories, phase, and context. | Invalid, contradictory, or immediately repeated major events fail automated validation. |
| NARR-002 | P0 | Major outcomes are authored and deterministic from saved state and random seed. | Replaying from the same pre-event test fixture produces the same offered event and consequence. |
| NARR-003 | P0 | Quiet weeks and ordinary weeks without major drama are valid. | The scheduler does not force an event solely because a week advanced. |
| END-001 | P0 | Careers can end through all approved routes. | Each route records a cause, date/season, competition level, history entry, eligibility for Second Chance, and legacy result. |
| END-002 | P0 | User lifetime death probability targets approximately 1% and named NPC death approximately 1.25%. | Large deterministic simulations meet approved confidence ranges and clustering limits; values are not applied as annual probabilities. |
| END-003 | P0 | Death events are deadpan, fictional, non-graphic, and compliant with the 16+ design target. | Content review rejects graphic description, real-victim reference, or use of real tragedy as a joke. |
| CHANCE-001 | P0 | One rewarded-ad Second Chance is available for each distinct qualifying death, prison, or career-ending injury event. | Successful completion fully restores the user; the same event cannot be rescued twice. |
| CHANCE-002 | P0 | A qualifying ending remains a recoverable pending checkpoint until restoration succeeds or the user permanently accepts the ending. | The career is not committed as complete or archived before that decision. Verified restoration atomically returns the valid pre-event state; offline, no-fill, cancellation, SDK failure, and restart leave the opportunity pending and unconsumed. |
| END-004 | P0 | Out of Basketball uses one visible two-failure continuation rule. | A continuing school or college membership prevents an ordinary offseason from counting. Otherwise, an offseason without an accepted professional playing contract counts whether no offer existed or all offers were rejected; the second consecutive failed offseason ends the career, and accepting a playing contract resets the count. |
| LEGACY-001 | P0 | The game generates a descriptive legacy summary from actual, level-attributed history. | Achievements, teams, statistics, awards, records, earnings, relationships, reputation, and defining moments remain attributed to the school, summer, college, developmental, overseas, or top-domestic competition where they occurred. |

### 7.16 Monetization and purchases

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| AD-001 | P0 | Rewarded ads are the primary advertising format. | Reward, eligibility, and failure behavior are stated before viewing; no reward is granted without verified completion. |
| AD-002 | P0 | Mandatory interstitials are tightly capped. | Initial configuration does not exceed one per 8–12 minutes of active play and includes cooldown and session caps. |
| AD-003 | P0 | Ads never interrupt protected moments. | No ad appears during active games, challenges, major choices, injury, death, prison, contract, recruiting, or emotional scenes. |
| AD-004 | P0 | Ads and purchases disappear gracefully offline. | Career navigation and progression remain intact without blank ad containers or blocked ordinary advancement. |
| IAP-001 | P0 | Digital purchases use platform purchase systems and are restorable. | Interrupted, duplicate, refunded, and restored transactions are handled idempotently. |
| IAP-002 | P0 | Paid cosmetics are account-wide and permanent. | Deleting a career never deletes purchased cosmetics. |
| IAP-003 | P0 | No purchase changes ratings, potential, offers, draft position, health immunity, or simulation odds. | Automated entitlement tests confirm cosmetic/service boundaries. |

### 7.17 Accessibility, settings, and help

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| ACCESS-001 | P0 | Settings include text size, high contrast, colorblind-safe palettes, reduced motion, screen shake, flashing reduction, sound intensity, and haptic intensity. | Settings apply consistently, persist, and do not expose unreadable combinations. |
| ACCESS-002 | P0 | Touch targets and essential text meet supported mobile accessibility requirements. | Automated and manual accessibility checks pass on minimum supported screen sizes. |
| ACCESS-003 | P0 | Launch accessibility does not alter simulation difficulty. | No setting widens timing windows, reduces injury, boosts progression, or improves recruiting/scouting outcomes. |
| HELP-001 | P0 | Hybrid onboarding includes an optional three-game prologue and contextual first-use explanations. | A played prologue schedules exactly three games covering introduction, adversity, and finale/placement; every player can access all three regardless of earlier results. Skipping creates no progression penalty; tips can be dismissed, disabled, reopened, and do not change outcomes. |
| HELP-003 | P0 | Prologue evaluation uses multiple sources of evidence. | Offers, reputation, and followers respond to the three games but also use the generated prospect profile, position, physical tools, background, and coach evaluation; one game cannot independently force an elite or failed starting outcome. |
| HELP-002 | P1 | An on-demand glossary explains basketball, eligibility, career, health, and contract terms. | Every specialized term used in a required decision has a linked or searchable definition. |

### 7.18 Cross-system transition integrity

| ID | Priority | Requirement | Acceptance criteria |
| --- | --- | --- | --- |
| TRANS-001 | P0 | Every supported pathway transition preserves one coherent legal career state. | For every required scenario below, acceptance evidence records and validates all eleven axes: (1) current team membership, (2) active playing contract status, (3) top-domestic signing-rights ownership, (4) assignment status and assignment authority, (5) playing availability, (6) remaining college eligibility, (7) roster legality, (8) career-year accounting including age, development, service, and offseason resolution, (9) valid next choices, (10) statistical and historical destination, and (11) career continuation or termination condition. |
| TRANS-002 | P0 | The required transition matrix passes without state overlap, duplication, or history drift. | Each of TR-01 through TR-22 produces the same legal outcome after save/reload and at every applicable simulation fidelity. No transition can create a second membership or playing contract, duplicate an annual resolution, assign through rights alone, fabricate background history, or bypass an ending boundary. |

| Scenario ID | Required transition scenario |
| --- | --- |
| TR-01 | Scholarship college → draft → top league |
| TR-02 | Walk-on attempt → 15-player roster or failure |
| TR-03 | High school → developmental → final draft/free agency |
| TR-04 | High school → overseas → final draft/free agency |
| TR-05 | Ordinary redshirt below and above the configured threshold |
| TR-06 | First transfer with immediate eligibility |
| TR-07 | Second transfer with exception and residence-year branches |
| TR-08 | Declaration followed by timely withdrawal |
| TR-09 | Final entrant goes undrafted and cannot re-enter |
| TR-10 | Drafted player rejects the rights holder |
| TR-11 | Contracted drafted player receives an assignment |
| TR-12 | Direct developmental player leaves through a valid top exit |
| TR-13 | Overseas player returns through expiry, exit, or release |
| TR-14 | Mid-year professional level change without duplicate age, development, or service |
| TR-15 | Injury/suspension triggers an automatic legal-roster replacement |
| TR-16 | Released veteran rejects all offers and enters OOB |
| TR-17 | OOB player signs and resets the failure count |
| TR-18 | Two consecutive unsuccessful OOB offseasons end the career |
| TR-19 | A proposed contract is truncated/rejected at the 25-season boundary |
| TR-20 | A background prospect becomes relevant with persistent identity and aggregate evidence |
| TR-21 | School season → summer club → next-season school reservation/return |
| TR-22 | High-school graduate → one OOB year → first/final top-draft eligibility |

## 8. Nonfunctional Requirements

### 8.1 Performance targets

Targets apply to supported mid-range devices defined in the Technical Design Document and verified on physical iOS and Android hardware.

| ID | Target |
| --- | --- |
| PERF-001 | Production cold launch reaches an interactive save-slot or Hub screen within 4 seconds at the 90th percentile, excluding first install asset preparation. |
| PERF-002 | Ordinary Hub hotspot feedback begins within 100 ms and screen transitions complete within 300 ms at the 90th percentile. |
| PERF-003 | The 2.5D Hub and game-day court sustain 55+ rendered frames per second at the 90th percentile during ordinary use, with no repeated long-frame stalls. |
| PERF-004 | A normal weekly advance completes within 2 seconds at the 90th percentile; an unusually large offseason advance provides responsive progress feedback and completes within 10 seconds. |
| PERF-005 | Autosave does not block visible interaction for more than 100 ms and completes or safely checkpoints before destructive navigation. |
| PERF-006 | Production install size target is 250 MB or less before optional future downloadable content. |
| PERF-007 | The game remains usable after 60 minutes without unbounded memory growth, audio duplication, input degradation, or simulation slowdown. |

### 8.2 Reliability targets

| ID | Target |
| --- | --- |
| RELIAB-001 | 99.5% or better crash-free sessions during release-candidate testing. |
| RELIAB-002 | Zero known reproducible save-loss, duplicate-reward, or transaction-duplication defects at submission. |
| RELIAB-003 | The pinned Godot 4.x project imports headlessly, all typed GDScript parses without errors, and configured warnings-as-errors checks pass. |
| RELIAB-004 | All required automated suites pass from a clean checkout without hanging or depending on test order. |
| RELIAB-005 | Deterministic simulation fixtures reproduce in headless and exported Godot builds across supported devices and save migrations. |
| RELIAB-006 | A 25-season soak career and repeated create/load/delete cycles across all three independent slots complete without invalid or shared career state. |

### 8.3 Privacy and compliance

- LeagueBound is designed toward a 16+ audience and is not marketed to children under 13.
- Final ratings are assigned through current platform and regional processes.
- Content remains non-graphic and contains no explicit sexual activity.
- The app contains no user-generated content, stranger communication, gambling, or paid randomized items.
- Advertising, analytics, crash, and purchase SDK collection is minimized and accurately disclosed.
- Ads must be appropriate for the assigned age rating.
- Store listing, screenshots, and review notes must accurately disclose ads, purchases, dark events, and offline behavior.
- A privacy policy and data-safety disclosures are required before external testing involving production SDKs.

## 9. Analytics and Product Validation

The career must not require analytics connectivity. When analytics are enabled and consented where required, events queue safely and upload later without containing story text, names entered by the user, or unnecessary personal data.

### 9.1 Required product funnels

- Install → first launch → career slot created.
- Builder started → build confirmed.
- Prologue offered → played or skipped → completed where played.
- Freshman Hub entered → first week completed.
- Game offered → Play or Sim → result completed.
- High-school season started → completed.
- Post-high-school offer received → accepted/rejected → pathway entered.
- College/development/overseas phase entered and completed.
- Professional league reached.
- Career ended → Second Chance offered/used/declined → legacy viewed.
- Second and third careers started.

### 9.2 Beta measurement goals

Numeric engagement targets should be set after the complete freshman vertical slice produces representative data. Before that point, invented retention targets are not release evidence.

The beta must evaluate:

- Whether users understand the Personal Hub without reverting to a dashboard.
- Median time to first meaningful decision.
- Median meaningful played-game duration.
- Play-versus-Sim choice by importance and role.
- Tutorial skip, completion, and help-reopen rates.
- Career-phase completion and abandonment points.
- Build diversity and attribute/badge concentration.
- Event repetition and notification dismissal.
- Save recovery and offline-session success.
- Ad frequency, dismissal, and Second Chance completion without pressure complaints.

## 10. New Repository Baseline

LeagueBound version 1.0 implementation begins in a clean Godot 4.x repository. No runtime feature is considered delivered merely because a prototype existed in the archived React Native / Expo project.

### 10.1 Design and evidence retained

- All higher-authority design documents, level systems, the Simulation Specification, Balance Specification, Content Bible, approved rulings, and testable product requirements remain in force.
- Approved arithmetic, transition scenarios, acceptance criteria, deterministic fixture intent, and useful calibration observations may be carried forward as evidence.
- Fictional identity/content records may be migrated only after schema, stable-ID, provenance, and authority validation.

Retained evidence is an input to verification, not permission to copy an incompatible architecture or treat prototype behavior as a rule.

### 10.2 Runtime implementation starts clean

- Godot scenes, nodes, Resources, signals, application services, and persistence adapters are created under `GODOT_TDD.md`.
- Match simulation is implemented as a pure, seeded, headless core before presentation depends on it.
- Career/world state, Personal Hub presentation, match presentation, narrative, and platform integrations remain separated by documented interfaces.
- Exactly three local career slots use the approved SQLite repository boundary, migrations, transaction-safe autosave, backup, and recovery.
- Android and iOS exports are exercised from the foundation gate onward.

### 10.3 Archived implementation boundary

The previous React Native / Expo implementation and its `TDD.md` are archived reference only. They may inform questions or fixture comparison, but their component model, stores, types, dependencies, scripts, migrations, and build pipeline are not the new repository baseline and are not live technical authority.

### 10.4 Initial verification baseline

Before product-surface expansion, the new repository must produce clean evidence for headless import and tests, deterministic simulation, SQLite save/recovery on both mobile targets, three-slot isolation, and export/install/start smoke tests. **Godot Foundation Gate 0** supplies that baseline.

## 11. Delivery Gates

Gates are evidence-based outcomes, not calendar estimates. Work does not advance merely because a date passes.

### Gate 0 — Godot foundation

- A pinned Godot 4.x project imports and runs headlessly from a clean checkout.
- Typed GDScript parses cleanly, configured warnings-as-errors checks pass, and the full foundation test suite completes reliably.
- The pure match core runs without a scene tree and reproduces a seeded fixture.
- Scene/node/Resource/signal, domain, application, infrastructure, and presentation boundaries are documented and enforced by tests or static checks.
- The pinned SQLite adapter opens, migrates, transactionally writes, backs up, restores, and reopens test saves on Android and iOS release-equivalent targets.
- Exactly three isolated local career slots pass create, load, autosave, recovery, and delete tests without shared mutable state.
- One minimal Godot flow can create or resume a slot, render a projection, and commit a deterministic command without scene-owned career state.
- Android and iOS export builds install, launch, save, background/resume, and reopen successfully.
- The 22-scenario transition test harness exists and records all eleven required state axes.
- No archived React Native / Expo runtime dependency or build command is part of the new Godot application pipeline.

### Gate 1 — Freshman vertical slice

- Exactly three isolated local career slots and reliable autosave.
- Locked player builder and avatar foundation.
- Optional three-game middle-school prologue.
- Freshman bedroom Personal Hub.
- One complete weekly loop.
- One portrait played game and Sim path using the shared engine.
- Training, academics, health, recruiting, relationship, and phone surfaces represented at minimum slice depth.
- A freshman season can advance without developer intervention.

### Gate 2 — Complete high-school career

- Four high-school seasons and postseason.
- Summer organization umbrellas, separate age- or grade-group squads, and the unsigned-graduate exposure route.
- Transfers, recruiting, NIL, reputation, followers, advisors, and school trust.
- High-school content and progression calibrated.
- Post-high-school pathway decision works from legitimate offers.

### Gate 3 — College and alternative pathways

- Complete 15-player college rosters, five/play-four eligibility, redshirts, academics, transfers, declaration/withdrawal, and professional evaluation.
- Domestic development and overseas league function as full playable/simmable routes.
- Agents, contracts, finances, injuries, relationships, and world history persist across phase changes.

### Gate 4 — Professional career and ending

- Complete 82-game top league, play-in, playoffs, one-year/final-entry draft eligibility, four-window rights, contract-required assignment, import classification, contracts, trades, aging, mileage, roster interest, Out of Basketball, and retirement.
- All qualifying and normal career endings work.
- Second Chance and legacy summary work online/offline as specified.
- A 25-season automated soak career completes without duplicate annual or professional-service resolution and without a contract or option crossing the shared professional-season boundary.

### Gate 5 — Content-complete alpha

- Launch world count and content floors are met.
- All 16 badges and 30 injury families are integrated and balanced to alpha targets.
- Personal Hub residence states, avatar catalog, courts, sounds, social content, and relationship content are complete.
- No placeholder user-facing content remains.

### Gate 6 — Monetized beta

- Ads, purchases, restore, offline degradation, privacy disclosures, and age-rating safeguards are implemented.
- Performance, accessibility, onboarding, content repetition, balance, and funnel measurement occur on physical devices.
- Economy and ad configuration can be adjusted without app logic changes while respecting approved structural boundaries.

### Gate 7 — Release candidate

- Every P0 requirement passes acceptance testing.
- All 22 transition-integrity scenarios pass with all eleven required state axes recorded and valid.
- Approved P1 exceptions are documented with owner and post-launch plan.
- Reliability, performance, compliance, content, save migration, purchase, and 25-season soak gates pass.
- Store metadata and reviewer instructions accurately describe the product.
- `PROJECT_STATUS.md` is updated with evidence from the candidate build.

## 12. Release Blockers

Any of the following blocks version 1.0 submission:

- Save loss, state rollback exploit, duplicated reward, or purchase duplication.
- Godot import/parser failure, configured static-check failure, or a nondeterministic required test suite.
- A career phase that cannot reach a valid ending.
- Played and simulated games using incompatible outcome or progression rules.
- Placeholder Personal Hub, court, action challenge, organization, event, or store content in a required flow.
- Missing offline functionality outside explicitly network-dependent services.
- Ads appearing in protected moments or exceeding configured caps.
- Pay-to-win purchase behavior.
- Unrated, undisclosed, graphic, or policy-incompatible content.
- A required decision that can disappear, expire invisibly, or be automated against the player’s stated rules.
- Inaccessible required controls or unreadable essential information on supported devices.
- Any required transition scenario that creates overlapping membership or playing contracts, duplicates career-year or professional-service resolution, permits rights-only assignment, begins a match without a legal roster, rewrites committed background history, misattributes competition history, or archives a qualifying ending before Second Chance resolves.

## 13. Companion Documents Required

Implementation planning is not complete until the following focused documents exist:

1. **Godot Technical Design Document (`GODOT_TDD.md`):** pure-core and scene boundaries, application/infrastructure separation, SQLite save transactions, deterministic randomness, world simulation, mobile export strategy, platform integrations, and testing. The previous `TDD.md` is archived reference only.
2. **Simulation Specification (`SIMULATION_SPEC.md`):** possession state, derived skills, lineups, rotations, tactics, shot/pass/defense resolution, fatigue, fouls, and statistical calibration.
3. **Balance Specification (`BALANCE_SPEC.md`):** builder costs, rating bands, potential, progression, aging, mileage, injuries, recruiting, contracts, economy, rare events, and ad configuration bounds.
4. **Personal Hub UX Specification:** scene layers, hotspots, state priority, residence variants, navigation, inbox, notifications, accessibility, and production asset rules.
5. **Content Bible:** organizations, coaches, badges, injuries, events, relationships, social/news voice, death/legal-event safeguards, avatars, courts, backgrounds, and audio.
6. **Analytics and Privacy Plan:** event taxonomy, consent, offline queue, retention, SDK inventory, data deletion, store disclosures, and beta dashboards.

## 14. Change Control

The approved source hierarchy controls locked design. This PRD can be refined as implementation evidence improves, but it cannot silently alter an owner ruling, a controlling level-specific rule, the game fantasy, or version 1.0 structural requirements.

A proposed change requires explicit product review if it alters:

- Version 1.0 career boundary.
- Personal Hub primacy or 2.5D format.
- Portrait-only play.
- The authoritative shared simulation principle.
- Manual permanent attribute allocation.
- Play/Sim choice.
- Offline operation or permanent autosave outcomes.
- Monetization boundaries.
- World or content floors.
- 16+ design safeguards.

Requirement acceptance criteria can become more precise without reopening the controlling design when the change only clarifies how an approved outcome is verified.
