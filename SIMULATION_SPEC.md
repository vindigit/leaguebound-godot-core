# LeagueBound Basketball Simulation Specification

| Field | Value |
| --- | --- |
| Version | 1.0 contract draft |
| Date | August 2, 2026 |
| Status | Draft for simulation and balance review |
| Basketball design source | `GDD.md`, within the approved source-authority hierarchy |
| Product requirements | `PRD.md` |
| Architecture implementation | `GODOT_TDD.md`; it cannot redefine gameplay |
| Current implementation evidence | The Godot repository itself: `README.md`, the headless acceptance runner under `tests/`, and CI results |

## 1. Purpose

This document defines the authoritative basketball-resolution and evidence-output contract shared by played games, simulated user games, relevant world games, statistics, and presentation. It produces evidence for progression and scouting but does not own career or world legality.

It answers:

- What state the basketball engine owns.
- How a possession progresses.
- How all 20 public attributes create measurable basketball effects.
- How coaches, roles, tactics, tendencies, fatigue, chemistry, and context influence decisions.
- How manual user decisions and execution enter the same engine used by automatic simulation.
- How outcomes produce statistics, injuries, development inputs, key moments, and visual frames.
- What Tier A, Tier B, and Tier C simulation may simplify.
- What the Balance Specification must tune and calibrate.

This document defines formula structure, dependencies, invariants, and measurable outputs. It intentionally leaves numeric weights, curves, thresholds, and target ranges to `BALANCE_SPEC.md`.

Owner rulings, locked level-specific systems, later and more-specific frameworks, and the `GDD.md` control career structure under the approved authority hierarchy. This specification consumes their resolved membership, contract, rights, assignment, eligibility, import, career-year, award, and ending state; it does not redefine that state.

### 1.1 Middle-school prologue boundary

The optional prologue contains exactly three scheduled games. Its competition format guarantees access to an introduction game, an adversity game, and a finale or placement game regardless of prior results. Each game supports Play or Sim and uses the same authoritative ratings, possession resolution, statistics, fatigue, health, and result contracts as other user-team games.

The prologue produces performance evidence rather than a standalone verdict. Career systems combine the three-game evidence with the generated prospect profile, position, physical tools, background, and coach evaluation when resolving starting reputation, followers, and legitimate high-school offers. The match engine returns facts and evaluation inputs; it does not directly create offers or prescribe the career outcome.

Skipping the prologue does not simulate hidden games and does not apply a performance, progression, health, or opportunity penalty. The guaranteed assigned local public school remains available in every case.

### 1.2 High-school schedule boundary

The high-school simulation baseline is 20 official regular-season games: 14 home-and-away district games, four scheduled interdistrict games, and two scheduled showcase, rivalry, or tournament games. Only district record determines qualification. The top four schools in each of four districts enter a 16-team state bracket worth up to four games. State results feed one 96-team National Tournament worth up to seven games, producing a maximum 31-game official school season.

District ties resolve by head-to-head mini-table, capped district point differential, then a deterministic schedule-seeded draw. The state bracket uses fixed cross-district pairings, prevents same-district first-round games, and never reseeds. National seeds 33â€“96 play the opening round, seeds 1â€“32 receive byes, and the bracket applies neither reseeding nor geographic protection.

School basketball and summer club basketball never share one undifferentiated schedule or two simultaneous current memberships. Summer eligibility begins after the playerâ€™s actual school-elimination date. When an accepted summer place begins, the club becomes the one current competition membership and the continuing school place is retained only as a next-season reservation or affiliation until club membership closes. Each summer block expands into the games defined by its competition format and preserves separate club, statistics, workload, recruiting exposure, and history attribution.

## 2. Simulation Principles

### 2.1 One basketball truth

For a user-controlled game, Play and Sim consume the same:

- Player ratings and potential-independent current ability.
- Lineups, rotations, roles, availability, and minutes plan.
- Coaching identity, game plan, and tactical instructions.
- Tendencies.
- Fatigue, injuries, fouls, chemistry, and morale inputs approved by the Balance Specification.
- Competition rules.
- Possession resolution.
- Box-score attribution.
- Development, health, and postgame output contract.

Manual play supplies decisions and execution quality at selected opportunities. Sim supplies those inputs through the player/coach behavioral model. Manual play does not switch to separate shot, fatigue, or statistical rules.

### 2.2 User is one player

The user directly influences only his player and the limited strategic authority earned through role, leadership, and trust. Career and world services supply the legal roster and game-day registration. Within a match, the coach controls minutes, tactical roles, matchup assignments, and final team strategy. The match engine cannot create a professional assignment.

### 2.3 Ratings express capability; tendencies express choice

- Attributes determine what a player can execute and how difficult execution is.
- Tendencies determine what the player attempts when multiple actions are valid.
- Coaching instructions and roles modify action selection.
- Neither a tendency nor coach instruction directly grants ability.
- A high rating does not force usage; a low tendency can reduce how often the skill is attempted.

### 2.4 Context matters without erasing ratings

Defense, positioning, fatigue, injury, pressure, spacing, clock, score, role, and competition rules affect outcomes. Contextual effects are bounded so that an elite player remains meaningfully better than a weak player across large samples.

### 2.5 Outcomes are reproducible

All random decisions use the versioned `RandomSource` contract defined in `GODOT_TDD.md`. The same input snapshot, ruleset, decision, execution result, and random stream state produce the same output.

### 2.6 Basketball statistics must emerge

The engine does not select a desired final score or player stat line and reverse-engineer possessions to reach it. Statistics emerge from lineups, possessions, actions, and outcomes. Tier B may aggregate decision steps but still uses the same capability and calibration contracts.

## 3. Scope and Fidelity

### 3.1 Version 1.0 supported basketball

The engine supports:

- Five-on-five menâ€™s basketball.
- High school, summer club, college, domestic developmental, overseas, and top domestic professional rule profiles.
- Regulation and overtime.
- Planned rotations and contextual substitutions.
- Half-court, transition, inbound, late-clock, and end-game possessions.
- Shooting, driving, passing, ball handling, off-ball movement, screening, post actions, turnovers, fouls, free throws, rebounding, steals, and blocks.
- Coach identities, tactical roles, team chemistry, player tendencies, and home environment.
- Played, fully simulated, and world-simulation outputs.

### 3.2 Explicit abstractions

Version 1.0 does not simulate:

- Physics-based collisions.
- Free joystick movement.
- Every foot placement or animation frame as authoritative state.
- Fully authored playbooks with dozens of diagrammed branches per coach.
- Referee personalities.
- Detailed arena altitude, travel distance, or biomechanical models unless later justified by balance evidence.

Automatic tactical movement is represented by court coordinates and matchup state derived from basketball actions. Visual interpolation is presentation only.

### 3.3 Career and world legal-state boundary

Basketball fidelity may change by simulation tier; career law does not. Tier A, Tier B, and Tier C consume the same upstream-validated legal state and obey the same structural rules.

- A player has at most one official playing membership, one active playing contract, one top-domestic signing-rights holder, and one temporary assignment overlay. School and summer-club membership are sequential, with any continuing school place represented only as a next-season reservation or affiliation while the club is current. Signing rights do not create membership or assignment authority, and a developmental assignment requires an accepted top-domestic playing contract. Membership, assignment, medical or disciplinary availability, and game-day registration remain separate. Professional loans do not exist at launch.
- Career services own and validate college roster and competition eligibility, redshirt and transfer state, college declaration and permitted-withdrawal state, final draft entry, Out-of-Basketball status, and the 25-professional-season boundary. A completed post-high-school OOB year may satisfy first-draft timing without membership, a contract, or service, and its first-cycle eligibility credit is available at the next scheduled draft checkpoint before the second-failure determination. Simulation consumes those decisions without restoring, extending, or reinterpreting them.
- An overseas roster's import classification and import-slot treatment remain fixed for the accepted contract term. Underlying residency or naturalization evidence may change, but simulation cannot reclassify the player until a new or renewed term is validated upstream.
- Suspension challenges resolve upstream before a ruling becomes final. Simulation consumes the fixed final duration and resulting availability; it cannot create a separate appeal or shorten the ruling.
- Career and world services resolve the ordered career-year milestones through once-only completion receipts. Tier B or Tier C calendar aggregation may produce basketball and evaluation evidence, but changing levels, assignment, recall, release, or simulation tier cannot duplicate age, professional service, development, award, Out-of-Basketball, or rollover resolution.

These are input and output boundaries, not additional match-state schemas.

## 4. Competition Rule Profiles

Each game receives one immutable `CompetitionRuleProfile`.

```ts
interface CompetitionRuleProfile {
  id: string;
  version: string;
  periodStructure: PeriodStructure;
  overtimeSeconds: number;
  shotClockSeconds: number;
  frontcourtSeconds: number;
  personalFoulLimit: number;
  teamFoulRule: TeamFoulRule;
  timeoutRule: TimeoutRule;
  threePointProfileId: string;
  restrictedAreaProfileId: string;
  possessionArrowEnabled: boolean;
  paceEnvironmentId: string;
  officiatingProfileId: string;
  rosterRuleProfileId: string;
}
```

Rules are phase-appropriate and recognizable without using licensed league names. Period length, foul bonus, line distance, pace environment, and roster rules are configurable data. The engine does not infer rules from a generic `PRO` flag.

The roster rule profile validates competition-specific game-day limits and substitution behavior against the registration supplied by career and world services. It cannot create or change contractual membership, a playing contract, signing rights, a professional assignment, import classification, college eligibility, or a temporary replacement.

Competition environment can change spacing, expected pace, shot-location difficulty, officiating, and substitution patterns. It cannot secretly rewrite stored player ratings.

## 5. Authoritative Match State

Before a `MatchSnapshot` is created, career and world services supply a validated legal roster, game-day registration, competition eligibility, and current availability for each team. If injuries, suspensions, or other valid unavailability leave a team below the competition's minimum legal game-day roster, those services automatically supply an authorized hardship or temporary replacement before match creation without deleting or reclassifying the existing memberships. `MatchSessionService` rejects an unresolved invalid input; the match engine never invents membership, contracts, rights, assignments, import changes, or replacement players.

```ts
interface MatchSnapshot {
  matchId: string;
  gameId: GameId;
  ruleProfileId: string;
  status: MatchStatus;
  period: PeriodState;
  clock: ClockState;
  score: ScoreState;
  possession: PossessionState;
  home: TeamMatchState;
  away: TeamMatchState;
  lineups: LineupState;
  rotations: RotationState;
  fouls: FoulState;
  timeouts: TimeoutState;
  momentumContext: MomentumContext;
  userContext?: UserMatchContext;
  pendingOpportunity?: PendingOpportunity;
  accumulatedStats: MatchStatistics;
  eventSequence: number;
  rngState: RandomState;
  revision: number;
}
```

### 5.1 Match invariants

- Exactly one offense and one defense exist during a live possession.
- Five eligible players per team are on court unless a rules-profile exception is explicitly supported.
- An on-court player belongs to one team and one active lineup slot.
- Score, clock, possession, fouls, and box score can change only through domain events.
- A field goal attempt has exactly one shooter.
- A made field goal has one shot value and at most one assister.
- A rebound can occur only after a reboundable miss.
- A player who has fouled out, been ejected, or become medically unavailable cannot re-enter.
- Match completion is terminal except for the idempotent career-result commit.
- Match events never mutate upstream membership, contract, rights, assignment, import, eligibility, or game-registration state.

## 6. Player Match Snapshot

The engine receives an immutable game-start snapshot of each eligible player plus mutable match-only state. Every active named player supplied to Tier A or Tier B uses the canonical 20 whole-number ratings from 25 through 99. Values below 25 are non-player generation or migration placeholders and cannot enter a match. Tier C team aggregates need not invent named ratings; once a player is relevant and named, the same active-player domain applies.

```ts
interface PlayerMatchProfile {
  playerId: PlayerId;
  positions: PositionProfile;
  body: BodyProfile;
  attributes: Record<AttributeKey, Rating>;
  badges: ActiveBadgeView[];
  tendencies: PlayerTendencies;
  rotationRole: RotationRole;
  tacticalRole: TacticalRole;
  condition: number;
  injuryLimitations: InjuryLimitation[];
  qualitativeDurabilityBand: string;
}

interface PlayerMatchRuntime {
  playerId: PlayerId;
  onCourt: boolean;
  minutesPlayedSeconds: number;
  currentEnergy: number;
  acuteFatigue: number;
  foulCount: number;
  touches: number;
  usageEvents: number;
  matchupId?: PlayerId;
  hotContext: number;
  performanceFlags: string[];
}
```

Potential caps, Attribute Points, follower count, money, and scouting visibility are not match-resolution inputs.

**Overall is not a match-resolution input either.** Current Overall, Maximum Potential Overall, and Projected Peak are display projections derived from ratings and caps (`BALANCE_SPEC.md` Â§6.3). No capability, action weight, shot profile, contest, rebound score, foul curve, rotation decision, or Tier B aggregate may read any of them. Basketball reads the 20 attributes, body, badges, and match context. This keeps Overall truthful as a description without letting a display value become a cause.

### 6.1 Body contract

`BodyProfile` is a persistent player fact supplied to the engine, not a match-only value. The engine consumes the **realized current body**; it never consumes the projected adult range, the maturity profile, or any unresolved growth.

```ts
interface BodyProfile {
  heightInches: number;        // realized current
  weightPounds: number;        // realized current
  wingspanInches: number;      // realized current
  standingReachInches: number; // realized current
}
```

Body affects, and only affects:

- **Action validity.** Whether a dunk, post seal, block attempt, or contest is physically available.
- **Reach.** Contest arrival quality, block access, rebound access, passing-lane coverage, and finish access over a defender.
- **Positioning and leverage.** Post resistance, box-out results, screen quality, and drive absorption, in combination with Strength.
- **Matchups.** Assignment suitability and the size/speed mismatch terms in advantage resolution.

Body must never contribute a general bonus to unrelated outcomes, and it must never be read as a proxy for Overall. Maturity profile, projected adult range, and growth resolution live in the career domain (`BALANCE_SPEC.md` Â§7.4); the match engine cannot resolve, advance, or observe growth.

### 6.2 Layered identity in the match profile

`rotationRole` and `tacticalRole` are separate fields with separate effects (Â§10.6). Derived archetype is **not** a match-profile field: it is a display projection and is never supplied to the engine.

Availability facts â€” did not play, emergency duty, medically unavailable, not registered â€” are represented by lineup, rotation, and `injuryLimitations` state, not by overloading `rotationRole`.

### 6.3 Body state transitions

Body state changes only in the career domain, only at approved career-year moments, and only under these transitions:

| Transition | Preconditions | Effects |
| --- | --- | --- |
| `CONFIRM_BODY` | Build confirmation; creation budget exhausted | Stores freshman body, maturity profile, and the displayed projected adult range as immutable career facts |
| `RESOLVE_GROWTH_INCREMENT` | Scheduled career-year body milestone; not already resolved for that career year | Applies a deterministic increment from the versioned career seed; writes an increment ledger entry |
| `REACH_ADULT_BODY` | All scheduled increments resolved | Marks the body final; no further increments are legal |

Invariants:

- Every increment leaves the realized body inside the stored projected range on every dimension.
- Growth is idempotent per career year under the shared completion-receipt rules; reloading, changing level, or changing simulation tier cannot re-resolve or skip an increment.
- No increment writes a public rating. Any intended rating consequence resolves as a separate, visible, ledgered progression effect.
- A match in progress never observes a body change. Growth resolves outside match sessions and enters the next `MatchSnapshot` through an ordinary game-start profile.

## 7. Derived Basketball Capabilities

Public attributes feed reusable derived capabilities. A capability is a pure, versioned function of current ratings, body, active badges, and match context.

Numeric weights and nonlinear curves belong in the Balance Specification. Every formula must satisfy monotonicity tests unless a documented interaction explains otherwise.

### 7.1 Offensive capabilities

| Capability | Primary inputs | Secondary inputs | Used for |
| --- | --- | --- | --- |
| Ball Security | Handle | Strength, Offensive IQ, fatigue | Live-dribble turnovers, pressure resistance, strips |
| Handle Creation | Handle | Speed, Offensive IQ | Beating initial defender, creating separation, changing direction |
| Pass Accuracy | Passing | Vision, Offensive IQ, fatigue | Target accuracy, catch quality, out-of-bounds and bad-pass risk |
| Pass Read Quality | Vision | Offensive IQ, Passing | Finding open players, anticipating help, recognizing skip and interior passes |
| Shot Selection | Offensive IQ | Vision, role, tendencies | Attempt quality, late-clock decisions, mismatch recognition |
| Rim Touch Finish | Short Range | Strength, Speed, Offensive IQ | Layups, floaters, close non-dunk finishes |
| Dunk Threat | Dunking | Vertical, Strength, Speed | Dunk eligibility, attempt frequency when chosen, finish force |
| Midrange Shotmaking | Mid-Range | Offensive IQ, fatigue | Pull-ups, stationary midrange, turnaround abstractions |
| Three-Point Shotmaking | Three-Point | Offensive IQ, fatigue | Catch-and-shoot, pull-up, deep-shot eligibility |
| Free-Throw Shotmaking | Free Throw | fatigue, pressure context | Free-throw result and simulated timing stability |
| Off-Ball Timing | Offensive IQ | Speed, Vision | Cuts, relocations, screening reads, spacing maintenance |
| Offensive Rebound Positioning | Offensive Rebounding | Strength, Vertical, Offensive IQ | Crash eligibility, position, rebound share, putback opportunity |

### 7.2 Defensive capabilities

| Capability | Primary inputs | Secondary inputs | Used for |
| --- | --- | --- | --- |
| Point-of-Attack Containment | Perimeter Defense | Speed, Strength, Defensive IQ | Drive prevention, separation denial, pickup pressure |
| Perimeter Contest | Perimeter Defense | Speed, Vertical, Defensive IQ | Jumper contest strength and closeout quality |
| Interior Positioning | Interior Defense | Strength, Defensive IQ | Post resistance, rim positioning, foul discipline |
| Rim Protection | Blocking | Interior Defense, Vertical, Defensive IQ | Block threat, shot alteration, verticality |
| Passing-Lane Defense | Stealing | Defensive IQ, Speed | Deflections, interceptions, denial |
| On-Ball Disruption | Stealing | Perimeter Defense, Speed, Defensive IQ | Strip attempts and pressure turnovers |
| Help Recognition | Defensive IQ | Speed, role | Help timing, rotations, tag/recover decisions |
| Defensive Rebound Positioning | Defensive Rebounding | Strength, Vertical, Defensive IQ | Box-out quality, rebound share, possession security |

### 7.3 Physical capabilities

| Capability | Inputs | Used for |
| --- | --- | --- |
| Court Speed | Speed | Transition participation, recovery, cuts, closeouts, movement timing |
| Contact Force | Strength | Drives, screens, post play, box-outs, contact stability |
| Burst/Reach | Vertical and Speed | Dunk/block/rebound reach, explosive actions |
| Work Capacity | Stamina | Fatigue accumulation, recovery during rest, late-game stability |

### 7.4 IQ rules

Offensive IQ and Defensive IQ are not generic hidden bonuses added to every probability.

- Offensive IQ affects action selection, spacing, timing, mismatch recognition, shot quality, and offensive foul/late-clock mistakes.
- Defensive IQ affects matchup positioning, help, rotations, closeouts, box-outs, verticality, and gambling discipline.
- IQ can improve the context in which a technical rating is used; it cannot turn a poor shooter into an elite shooter by itself.

## 8. Public Attribute Simulation Contracts

Every public attribute has mandatory direct observables.

| Attribute | Required measurable effects |
| --- | --- |
| Short Range | Close non-dunk make quality; floater/layup stability; close touch under contest |
| Dunking | Dunk eligibility; dunk attempt selection when available; dunk finish quality |
| Mid-Range | Midrange make quality; viable window size for manual timing; simulated midrange execution |
| Three-Point | Three-point make quality; viable range/window; simulated three-point execution |
| Free Throw | Free-throw make quality and manual timing-window difficulty |
| Handle | Separation creation; dribble pressure resistance; live-ball turnover risk |
| Passing | Pass placement and catch quality; bad-pass turnover risk; assist conversion support |
| Vision | Open-target recognition; advanced-pass selection; help-defense reading |
| Offensive IQ | Shot/action selection; off-ball timing; late-clock and mismatch decisions |
| Perimeter Defense | On-ball containment; jumper contests; screen navigation abstraction |
| Interior Defense | Post resistance; rim positioning; legal contact and foul avoidance |
| Stealing | Strip and interception success after a valid steal opportunity |
| Blocking | Block and strong alteration success after a valid contest opportunity |
| Defensive IQ | Help/rotation/closeout quality; gamble selection; box-out and foul discipline |
| Offensive Rebounding | Crash positioning; offensive rebound share; putback-opportunity creation |
| Defensive Rebounding | Box-out and defensive rebound share; rebound security |
| Speed | Transition/cut/closeout timing; separation and recovery; court coverage |
| Strength | Contact stability; screens; post leverage; box-outs; strong-drive resistance |
| Stamina | Fatigue accumulation and recovery; late-game execution stability |
| Vertical | Dunk/block/rebound reach; explosive contest and finish support |

An automated contract test must fail if changing one attribute across a meaningful range produces no statistically detectable change in any required observable.

## 9. Possession State Machine

### 9.1 States

```ts
type PossessionNode =
  | "DEAD_BALL"
  | "INBOUND"
  | "ADVANCE"
  | "TRANSITION_DECISION"
  | "HALF_COURT_ENTRY"
  | "ACTION_SELECTION"
  | "ACTION_EXECUTION"
  | "ADVANTAGE_STATE"
  | "SHOT_SETUP"
  | "SHOT_RESOLUTION"
  | "FOUL_RESOLUTION"
  | "REBOUND_RESOLUTION"
  | "PUTBACK_DECISION"
  | "POSSESSION_END";
```

### 9.2 Standard flow

```text
Dead ball / inbound
  â†’ advance or transition
  â†’ half-court entry when transition does not resolve
  â†’ choose initiator and action
  â†’ defense selects coverage/response
  â†’ resolve advantage, turnover, foul, reset, or shot setup
  â†’ resolve shot or free throws
  â†’ rebound or change possession
  â†’ update clock, fatigue, fouls, statistics, and presentation events
```

A possession can contain multiple actions and resets before a terminal result. The current one-action possession can remain as a migration mode, but the target state machine must support pass-to-action chains, help rotations, offensive rebounds, and late-clock continuation.

### 9.3 Possession input context

```ts
interface PossessionContext {
  offenseLineup: OnCourtLineup;
  defenseLineup: OnCourtLineup;
  scoreContext: ScoreContext;
  clockContext: ClockContext;
  spacing: SpacingState;
  matchups: MatchupState;
  offensePlan: TeamGamePlan;
  defensePlan: TeamGamePlan;
  teamChemistry: TeamChemistryContext;
  homeEnvironment: HomeEnvironmentContext;
}
```

### 9.4 Time consumption

Each state transition consumes time from a bounded distribution defined by action, pace, game plan, pressure, and rules. Time is never negative and the engine cannot begin a new action after the period expires.

- Transition actions consume less time.
- Patient offense and resets consume more time.
- Late-clock state restricts legal action choices.
- Offensive rebounds use the rule profileâ€™s reset behavior.
- Dead-ball fouls and free throws use separate event time without incorrectly consuming shot-clock time.
- **The game clock restarts on the throw-in's legal touch, not on the whistle before it.** A possession that begins from a stopped clock — a foul, a violation, a ball out of bounds, the start of a period — charges nothing for retrieving the ball, for the official's administration, or for the throw-in itself, so its `INBOUND` carries the possession's own starting clock. A possession that begins while the clock is still running, which in this model is the restart after a made basket in open play, charges the throw-in as elapsed time because the clock never stopped. Whether the clock was stopped is a fact the session supplies to the possession; the possession does not infer it.
- **A possession that begins with almost no time left does not run the ordinary opening.** Below a bounded game-clock threshold the offense advances the ball if the clock allows and then commits to an attempt from wherever it stands, without a half-court set. It is not given that set for free: the attempt carries the `TacticalLocation` it was actually taken from, and §12.6 charges it for the distance.

## 10. Action Selection

### 10.1 Action families

Version 1.0 action families:

- Initiate pass or swing.
- Drive or attack closeout.
- Pull-up or stationary shot.
- Post action.
- Pick-and-roll or pick-and-pop action.
- Handoff.
- Off-ball cut.
- Relocation or spot-up.
- Screen.
- Reset.
- Transition attack or advance.

The Simulation Specification does not require the user to receive a prompt for every action. Most actions occur automatically.

### 10.2 Candidate generation

The engine first generates valid candidates from:

- Ball and player location.
- Role and lineup.
- Matchup and defensive coverage.
- Clock and score.
- Player capability thresholds.
- Team tactics and current play call.
- Injury and fatigue restrictions.

An impossible action receives no weight. The engine does not allow a tendency slider to create an invalid dunk, pass target, or on-court touch.

### 10.3 Weight construction

For automatic selection:

```text
ActionWeight =
  Validity
  Ã— RoleOpportunity
  Ã— PlayerTendency
  Ã— CoachInstruction
  Ã— TacticalFit
  Ã— MatchupOpportunity
  Ã— ScoreClockContext
  Ã— CapabilityConfidence
  Ã— FatigueAvailability
```

The Balance Specification defines curves and caps. No single factor except validity can reduce every action to zero.

### 10.4 User tendency sliders

The ten five-position sliders affect automatic behavior:

- Pass First â†” Score First.
- Patient â†” Aggressive.
- Perimeter â†” Interior.
- Create Own Shot â†” Off-Ball.
- Safe â†” Creative Passing.
- Push Transition â†” Control Tempo.
- Disciplined Defense â†” Gamble.
- Stay Attached â†” Help.
- Box Out â†” Chase Rebounds.
- Defer â†” Seek Clutch Opportunities.

Slider positions map to centered bounded multipliers. They never modify ratings or permanent coach instructions.

### 10.5 Coach authority

Coach instructions modify automatic behavior according to:

- Coach strictness.
- Player rotation and tactical role.
- Coach Trust.
- Institutional standing.
- Professionalism.
- Veteran/leadership authority.
- Current play call and game state.

The playerâ€™s saved tendencies remain the behavioral baseline. Coaching can substantially shape role and opportunity but cannot permanently rewrite those sliders.

### 10.6 Layered identity contract

Rotation role, tactical role, and derived archetype are three separate layers. This section owns their behavioral contract and their stable identifiers. `BALANCE_SPEC.md` Â§12.4 owns the numeric bounds.

#### 10.6.1 Rotation roles

Rotation role is the coach's usage intent. Version 1.0 stable IDs:

| ID | Label |
| --- | --- |
| `star` | Star |
| `starter` | Starter |
| `sixth_player` | Sixth Player |
| `rotation` | Rotation |
| `bench` | Bench |
| `reserve` | Reserve |
| `developmental` | Developmental |

Rotation role affects planned minutes, substitution priority, and closing-lineup consideration. It does not affect capability or success probability.

Availability and outcome facts are **not** rotation roles. Did-not-play, emergency duty, limited availability, medical unavailability, and non-registration are separate derived states. A Starter who does not play remains a Starter; the engine records a DNP, not a demotion.

#### 10.6.2 Tactical roles

Tactical role is the job assigned for one game. Version 1.0 stable IDs:

| ID | Label | Primary opportunity effect |
| --- | --- | --- |
| `primary_creator` | Primary Creator | On-ball initiation, pick-and-roll handling, late-clock creation |
| `secondary_creator` | Secondary Creator | Secondary initiation, attacking closeouts, advantage continuation |
| `shooter` | Shooter | Spot-up and relocation volume, off-screen usage |
| `slasher` | Slasher | Cutting, driving lanes, rim attempts off advantage |
| `connector` | Connector | Swing passing, short-roll reads, ball movement continuity |
| `post_option` | Post Option | Post entries, seals, interior attempts |
| `roll_pop_big` | Roll/Pop Big | Screen setting, roll and pop continuations |
| `perimeter_stopper` | Perimeter Stopper | Toughest perimeter assignment, on-ball containment share |
| `interior_anchor` | Interior Anchor | Rim protection responsibility, help positioning priority |
| `rebounder` | Rebounder | Crash and box-out priority on both glasses |
| `utility_energy` | Utility/Energy | Flexible assignment, effort actions, matchup coverage |

Rules:

- Exactly one tactical role is active per player per game. It is fixed for the game and can change only between games (Â§18.1).
- No consolidation was applied. All eleven roles required by the owner ruling are retained as distinct IDs because each maps to a distinct opportunity vector in the table above; merging any two would erase a real difference in candidate generation and role opportunity.
- Tactical role modifies `RoleOpportunity` in the Â§10.3 weight construction, and planned minutes and assignment in Â§18. It modifies **nothing else**. It never contributes to a capability, a shot profile, a contest, a rebound candidate score, a turnover risk, or a foul curve.
- A tactical role never gates action validity. A `shooter` may drive and a `roll_pop_big` may pass; the role changes how often those are selected, not whether they are legal.
- Assigning a role a player is unsuited for is legal and produces bad basketball, not corrected basketball. The engine does not silently reassign.

#### 10.6.3 Derived archetype

Derived archetype is a read-only description assembled from body, current ratings, and demonstrated profile. It uses composable descriptors, for example *Two-Way Shot-Creating Guard* or *Stretch Rim Protector*, built from:

1. A two-way axis descriptor, from the balance of offensive and defensive capability.
2. One or two capability descriptors, from the player's dominant capability clusters.
3. A position-family noun, from body and position profile.

Rules:

- Archetype is computed for display only. It is not a match input, is not persisted as a gameplay fact, and computing it is side-effect free.
- Archetype grants nothing: no attribute, capability, action, opportunity, badge, role eligibility, or probability.
- Archetype is not exclusive. Two players may share a descriptor without sharing any mechanical property, and a build is never restricted to archetype-appropriate attributes.
- Archetype updates as ratings and body change. It has no memory and creates no lock-in.

#### 10.6.4 Separation of concerns

| Input | Determines |
| --- | --- |
| Tendencies | What the player prefers to attempt when several actions are valid |
| Tactical role | What opportunity the player receives |
| Rotation role | How much the player is on the floor |
| Capability and context | Whether the attempt succeeds |

Success flows only from the last row. No identity layer may be used to reach it.

## 11. Offensive Action Resolution

### 11.1 Advantage model

Actions create an `AdvantageResult` before a shot or terminal outcome.

```ts
interface AdvantageResult {
  level: "NONE" | "SMALL" | "CLEAR" | "BREAKDOWN";
  creatorId?: PlayerId;
  beneficiaryId?: PlayerId;
  defenseRotation: DefenseRotationState;
  turnoverRisk: number;
  foulPressure: number;
  availableContinuations: ContinuationOption[];
}
```

Examples:

- A drive compares Handle Creation, Court Speed, and Ball Security against containment, help recognition, and interior positioning.
- A pass compares Pass Accuracy and Read Quality against denial, passing-lane defense, distance, and pressure.
- A screen action combines screener strength/timing, handler creation, defender navigation, and coverage.
- A cut combines off-ball timing and speed against defensive awareness and help positioning.

### 11.2 Turnovers

Turnovers require a cause and actor attribution.

```ts
type TurnoverCause =
  | "BAD_PASS"
  | "INTERCEPTION"
  | "LOST_HANDLE"
  | "STRIP"
  | "OFFENSIVE_FOUL"
  | "SHOT_CLOCK"
  | "OUT_OF_BOUNDS"
  | "TRAVEL_OR_VIOLATION";
```

Turnover probability is built from action risk, ball security/pass quality, defender disruption, pressure, fatigue, decision quality, spacing, and badges. A steal is credited only when a defender caused a qualifying live-ball turnover.

### 11.3 Passing and assists

A pass event records:

- Passer and receiver.
- Pass type/risk family.
- Target openness before and after catch.
- Catch quality.
- Defensive rotation caused.
- Whether the pass directly created the eventual shot.

Assist attribution follows configurable competition/stat rules. Vision increases recognition and creation; Passing increases execution. A high Vision player can see a pass that poor Passing fails to deliver. A high Passing player with poor Vision may accurately deliver only obvious options.

**Implementation status: the passer-to-shot relationship is an explicit record, and "whether the pass directly created the eventual shot" is settled at the shot rather than at the pass.** `PassCreation` carries the passer, the receiver, the openness the delivery produced, the catch quality it earned, the defender it moved, and the competition's own credited-assist rule; `PASS_COMPLETED` records all of it. A delivery creates the attempt when the record is live, the ball reached *that* shooter, the passer is not the shooter, and the shot's family is one the competition credits — the last of these being `CompetitionRuleProfile.assist_rule_id` and `credited_assist_families`, which all five version 1.0 competitions share as `delivered-shot-v1`. The creator is stamped on `FIELD_GOAL_ATTEMPT` and `FIELD_GOAL_MADE` before the shot resolves, so §24.3's requirement that every official statistic derive from an ordered event holds for assists without reconstruction.

The record is invalidated by a possession change, a turnover, an offensive rebound, a free-throw whistle, a reset, an attack that does not finish, a later pass replacing it, and the shot that consumes it. Two of those are defence in depth rather than the load-bearing guard, and `PROJECT_STATUS.md` §5.15 records which and why.

The attribute split is implemented as this section and §8 state it together: Vision leads the §11.1 advantage roll a completed pass makes — recognition and creation — and Passing leads the delivery, the catch quality, and the §14.3 conditional that converts a created basket into a credited assist, which §8 names "assist conversion support".

### 11.4 Screens and off-ball value

Screens and off-ball actions produce measurable events even when they do not appear in the public box score:

- Separation generated.
- Defensive switch or rotation caused.
- Shot-quality change.
- Advantage continuation.
- Offensive foul risk.

These events can influence coach evaluation and role-relative match rating without inventing official statistics.

## 12. Shot Model

### 12.1 Shot intent

```ts
interface ShotIntent {
  shooterId: PlayerId;
  zone: ShotZone;
  subtype: ShotSubtype;
  assistedState: "UNASSISTED" | "CREATED" | "CATCH_AND_SHOOT";
  distanceBand: string;
  clockPressure: number;
  movementLoad: number;
  contactLoad: number;
}
```

Shot zones at minimum include restricted rim, close non-rim, midrange, standard three, and deep three. Public logs can group these more simply.

**Implementation status: `assistedState` is recorded on the attempt, not only on the make.** `CATCH_AND_SHOOT` is a shot taken off the catch, `CREATED` one the delivery produced but the shooter finished on the move, and `UNASSISTED` everything the shooter made for himself — including a shot he created for himself after catching an ordinary pass. The engine previously recorded `CREATED` for exactly that last case, which is the inverse of what this section means, and recorded nothing at all on the attempt.

### 12.2 Shot context construction

The engine calculates:

- Shooter technical capability for zone/subtype.
- Shot selection quality from Offensive IQ and context.
- Separation from prior action.
- Defender contest arrival and quality.
- Help and rim protection.
- Catch/pass quality.
- Balance/movement load.
- Fatigue and injury limitations.
- Clock and pressure context.
- Competition line-distance/environment effects.
- Badge effects.

### 12.3 Contest state

```ts
type ContestBand = "OPEN" | "LIGHT" | "MODERATE" | "HEAVY" | "SMOTHERED";

interface ShotContest {
  band: ContestBand;
  primaryDefenderId?: PlayerId;
  helperId?: PlayerId;
  blockEligible: boolean;
  altered: boolean;
  legalContact: number;
}
```

Contest is created from actual defensive positioning and capabilities. It is not selected as independent random flavor after shot probability is known.

**Defender capability must span more than one band.** Contest pressure is centred on a base and moved by how far the defender's contest capability sits from the middle of the scale. If that span is narrower than the distance between band boundaries, the best and worst defenders in a league produce contests inside the same band and the clause above is satisfied in form only — capability is read, and then makes no difference. `BALANCE_SPEC.md` §14.1 carries the measured consequence and the corrected value.

**Perimeter contests currently have no help term.** Help pressure is applied only to interior attempts, so a perimeter jumper's pressure comes from the primary defender alone and cannot reach the `HEAVY` threshold. `SMOTHERED` is therefore unreachable on the perimeter. This is a known gap, recorded rather than modelled; closing it requires a perimeter closeout or rotation term that does not exist yet.

### 12.4 Execution window

Every manually executed shot receives an `ExecutionWindow`:

```ts
interface ExecutionWindow {
  viable: boolean;
  perfectZoneStart: number;
  perfectZoneEnd: number;
  successCurveId: string;
  stability: number;
  visibleGuaranteedSuccess: boolean;
}
```

- Ratings and context determine window size, stability, and whether a perfect zone exists.
- User timing is pure player input and is not corrected by hidden assistance.
- A valid perfect zone is visibly and audibly identified.
- A result inside a valid perfect zone guarantees a made shot.
- A smothered, desperate, physically invalid, or otherwise impossible attempt can set `viable = false` and contain no perfect zone.
- A missed timing window does not guarantee a miss; the engine resolves make quality from timing, rating, context, and defense.

### 12.5 Simulated execution

When the user is not manually executing, the engine creates `ExecutionQuality` from:

- Relevant shooting rating.
- Shot type familiarity encoded through ratings/badges, not a hidden separate skill unless approved later.
- Fatigue and injury.
- Pressure and IQ-derived preparation.
- Competition environment.
- Deterministic random stream.

Automatic execution can produce excellent or poor releases. It cannot use the manual guaranteed-perfect contract unless it actually samples the defined perfect band.

### 12.6 Make resolution

```text
if manual execution is valid perfect:
  made = true
else:
  MakeQuality = ShotCapability
              + ExecutionContribution
              + Advantage/PassQuality
              - Contest/BlockPressure
              - Fatigue/Injury/Movement/Clock penalties
              + bounded Badge and Environment effects
  made = randomCheck(mapQualityToProbability(MakeQuality, shotProfile))
```

Probability floors and ceilings are shot-profile-specific and defined in the Balance Specification. Floors cannot make absurd shots routinely viable, and ceilings cannot erase the userâ€™s valid perfect guarantee.

### 12.7 Blocks and alterations

Block evaluation occurs before ordinary make resolution when the defender has a valid block opportunity.

- Blocking is primary.
- Interior or Perimeter Defense selects positioning quality by shot area.
- Vertical and reach/body profile affect access.
- Defensive IQ affects timing and foul avoidance.
- Shooter separation, release type, height, strength, and dunk force resist the block.

A non-blocking contest can still alter make quality. A block is credited only when it produces a blocked-shot event.

## 13. Free Throws and Fouls

### 13.1 Foul opportunities

Fouls emerge from:

- Contact actions.
- Defender position and discipline.
- Offensive aggression.
- Strength and speed mismatch.
- Help timing.
- Contest type.
- Fatigue.
- Officiating profile.
- Deliberate late-game strategy.

The engine distinguishes shooting, non-shooting, offensive, loose-ball, and intentional fouls at the abstraction needed for rules and statistics.

### 13.2 Free throws

- Free Throw is the primary technical rating.
- Fatigue, pressure, injury, and competition environment are bounded context.
- Manual free throws use an action-specific timing challenge.
- A valid visible perfect release guarantees success under the same rule as other shots.
- Automatic free throws use simulated execution.
- Attempts, makes, team fouls, personal fouls, bonus state, and possession continuation are attributed exactly once.

### 13.3 Foul discipline

Defensive IQ and Interior/Perimeter Defense reduce avoidable foul risk through better position and legal contest selection. Stealing and Blocking increase success after a valid attempt; they do not independently force constant gambling. The Disciplined â†” Gamble tendency and coach instructions determine attempt frequency.

## 14. Rebounding

### 14.1 Rebound opportunity

Misses produce a rebound profile from shot zone, trajectory abstraction, block/alteration, and player locations.

### 14.2 Candidate score

```text
ReboundCandidateScore =
  Positioning
  + Relevant Rebound Rating
  + BoxOut/Crash Intent
  + Strength Leverage
  + Vertical/Reach Access
  + Defensive IQ or Offensive IQ Timing
  - Fatigue and Injury Limitation
  + bounded Random Variation
```

Defensive players receive positional advantage according to shot/rebound profile and box-out execution, not a universal arbitrary bonus.

### 14.3 User interaction

Meaningful user rebound opportunities can offer action-specific positioning or timing interaction. Perfect execution maximizes the playerâ€™s candidate quality but does not guarantee possession against superior position, size, teammates, or opponents.

### 14.4 Offensive rebounds and putbacks

An offensive rebound can produce:

- Immediate putback.
- Kick-out/reset.
- Foul.
- Turnover.
- Held ball where supported.

Choice follows tendencies, role, clock, spacing, capability, and user decision where prompted.

## 15. Defense

### 15.1 Matchups and assignments

Defensive assignments derive from positions, tactical roles, lineup capability, coach plan, switches, and game context. The engine can temporarily reassign after transition or screening actions without permanently changing the plan.

### 15.2 Coverage families

Launch coverage abstractions include:

- Man principles.
- Switch.
- Drop.
- Hedge/show and recover.
- Trap/blitz.
- Zone families.
- Help-heavy or stay-home principles.
- Pressure or conservative ball handling defense.

Coverage changes candidate actions, spacing, matchup responsibilities, and help timing. It does not apply one flat team defense multiplier.

### 15.3 Defensive action selection

Automatic defenders choose contain, pressure, help, recover, switch, gamble, contest, box out, or transition assignment from:

- Coach plan.
- Stay Attached â†” Help tendency.
- Disciplined â†” Gamble tendency.
- Box Out â†” Chase Rebounds tendency.
- Defensive IQ.
- Matchup and action.
- Score, clock, foul trouble, fatigue, and role.

### 15.4 User defense

The user receives prompts only when his assignment creates a meaningful decision or execution opportunity. Failure to respond delegates the moment to saved tendencies and coach instructions rather than automatically selecting the worst possible defense.

## 16. Transition and Automatic Movement

### 16.1 Tactical coordinates

The domain tracks normalized court location and role state, not animation pixels.

```ts
interface TacticalLocation {
  x: number; // validated normalized court coordinate
  y: number;
  lane: "LEFT" | "CENTER" | "RIGHT";
  depth: string;
  movementIntent: MovementIntent;
}
```

### 16.2 Movement intents

- Advance ball.
- Fill lane.
- Rim run.
- Trail.
- Cut.
- Relocate.
- Set screen.
- Roll or pop.
- Post seal.
- Close out.
- Help/tag.
- Recover.
- Box out.
- Pursue rebound.

The engine advances tactical locations at possession-action boundaries. Presentation interpolates smooth motion between authoritative frames.

### 16.3 Speed and fatigue

Speed affects time to reach tactical locations. Stamina and acute fatigue reduce repeat-action effectiveness. Strength can preserve line or position through contact. Automatic movement never consumes manual joystick input.

## 17. Fatigue, Condition, and Injury

### 17.1 Fatigue model

Acute match fatigue changes from:

- Seconds and possessions played.
- Action intensity.
- Touches and usage.
- Transition involvement.
- Defensive workload.
- Work-rate choice.
- Stamina.
- Pregame condition and active injury.
- Rest on bench and stoppages.

Fatigue affects burst, stability, decision execution, contest arrival, ball security, and recovery. It does not directly subtract the same flat amount from all ratings.

### 17.2 Work rate

User work rate changes involvement and action intensity with a corresponding fatigue cost. It cannot create guaranteed touches or overrule the coachâ€™s substitution authority.

### 17.3 Injury events

The match engine emits injury-candidate events with context:

```ts
interface InjuryCandidateEvent {
  playerId: PlayerId;
  actionFamily: string;
  contactLevel: number;
  fatigueLevel: number;
  existingLimitationIds: string[];
  workloadContext: WorkloadContext;
}
```

The Health service resolves injury family, severity, and consequences using durability, career mileage, existing injuries, context, and the health RNG stream. The match engine then applies immediate availability/limitation output. This keeps the 30-family injury catalog outside hard-coded possession logic.

## 18. Roles, Rotations, and Minutes

### 18.1 Planned rotation

Before tipoff, the coach creates:

- Starters.
- Planned minute ranges.
- Substitution groups.
- Tactical role per player.
- Matchup assignments.
- Closing-lineup priorities.
- Emergency depth order.

The user can view the plan to the degree allowed by product presentation.

The active tactical role assigned to a player is fixed for the entire game. Contextual actions and emergency lineup duties can differ from that role without silently changing its label. A coach can assign a different tactical role only between games.

### 18.2 Contextual adjustment

Rotations adjust for:

- Foul trouble.
- Acute fatigue.
- Injury.
- Performance only within bounded coaching tolerance.
- Score and time.
- Matchup and tactical needs.
- Overtime.
- Discipline and coach trust where relevant.

The engine does not recalculate optimal rotations from scratch every possession. Stability is part of coaching identity.

### 18.3 DNP and limited role

A played game can legitimately produce:

- No appearance.
- A short appearance with no prompts.
- Limited role interactions.
- Full high-usage involvement.

The postgame still resolves team result, condition, relationship context, and any role-relative development input.

## 19. Chemistry, Trust, Morale, and Home Environment

### 19.1 Chemistry

Team Chemistry has modest bounded effects on coordination-dependent outcomes:

- Pass/catch quality.
- Help and recovery timing.
- Screening and off-ball synchronization.
- Rotation execution.
- Late-clock communication.

Chemistry does not directly add a large flat shooting or defense bonus.

### 19.2 Coach trust

Coach Trust affects:

- Planned opportunity and tolerance.
- Authority to call plays or suggest strategy.
- Whether deviations produce role consequences.

It does not increase the probability that an identical physical shot goes in.

### 19.3 Morale and professionalism

If included as match inputs, morale and professionalism effects must be small, visible through condition or decision behavior, and specified in the Balance Specification. They cannot serve as a hidden rubber-band mechanic.

### 19.4 Home environment

Home advantage can affect bounded officiating, communication, composure, and familiarity factors. Its aggregate effect is calibrated as a small win-rate edge for otherwise even teams. It never guarantees an outcome.

**Which metric carries the verdict.** The §14.2 home-win target is judged by the controlled, symmetrized paired venue-side win estimator defined in `BALANCE_SPEC.md` §17.4. The marginal single-arm home win rate is an informational population diagnostic and does not independently determine the home-environment calibration verdict. Both are published; only the paired estimator carries a target.

**How the aggregate effect is measured.** The venue's contribution is a *paired two-arm* quantity and never one column of games. Three arms play identical fixtures at identical seeds — the venue at strength `E`, the same fixture at strength `0`, and the venue swapped to the other bench at strength `E` — and the contribution is the mean of the two venue arms' estimates against the shared control. A single arm carries the fixture, the rosters and the seeds along with the venue and cannot separate them. `BALANCE_SPEC.md` §17.4 states the estimator and the cap it feeds.

### 19.5 Opening possession

**The engine does not choose which team receives the opening possession.** `MatchInput.initial_possession_team_id` is a required input with no default, validated to name one of the two supplied teams. The match engine consumes a `MatchInput` and never constructs one.

No tip-off, jump ball, possession arrow, or alternating-possession rule is modelled at version 0.1. `CompetitionRuleProfile.possession_arrow_enabled` is reserved and unread; wiring it up is a specification change and requires this section to describe the rule first.

Until a scheduling or career layer exists to decide it from real fixture context, choosing the opening possession belongs to whoever builds the input. **A measurement fixture must counterbalance it.** Receiving the opening possession is worth a measurable margin on its own; a fixture that gives it to the same side in every game puts a first-possession edge inside every home/away differential measured on that fixture, including §14.2's equal-team home win rate.

## 20. Pressure, Clutch, and Momentum

### 20.1 Pressure

Pressure derives from score margin, time, game importance, crowd, personal stakes, foul state, and role. It can affect recognition time, simulated decision noise, and execution stability.

Manual timing remains user skill. Pressure may change window stability or size through visible context but cannot secretly alter the measured input after submission.

### 20.2 Clutch behavior

Defer â†” Seek Clutch Opportunities changes willingness to initiate or accept late-game actions. Coach plan, role, matchup, and ability still determine access.

### 20.3 Momentum

Momentum is optional and disabled until calibration proves it improves realism without rubber-banding.

If enabled:

- It is bounded and symmetric.
- It derives from recent on-court events.
- It affects confidence/decision context rather than overriding ratings.
- It is exposed in debug contributions.
- It passes no-comeback-script tests.

The score alone cannot cause the trailing team to receive an artificial make bonus.

## 21. Badges

### 21.1 Badge behavior contract

Each of the 16 launch badges must define:

- Trigger prerequisites.
- Eligible action stages.
- Bronze, Silver, Gold, and Hall of Fame effects.
- Maximum bounded contribution.
- Interaction rules with other badges.
- Debug attribution.
- Calibration tests.

### 21.2 Rules

- Badges modify specific basketball capabilities or contextual curves.
- Badges do not bypass action validity.
- Badge effects are active in played and simulated games.
- Multiple effects cannot stack beyond documented caps.
- Removing all badges must still produce a complete valid simulation.

## 22. User Opportunities and Key Moments

### 22.1 Opportunity generation

The engine can surface an opportunity when:

- The user is on court.
- The user is materially involved in the authoritative action.
- A meaningful decision or execution exists.
- No unresolved opportunity is active.
- Prompt frequency and cooldown rules permit it.

Importance increases presentation priority but does not fabricate involvement.

### 22.2 Opportunity types

- Shot creation and shot execution.
- Passing read.
- Drive/finish decision.
- Off-ball cut or relocation.
- Screen action.
- On-ball containment.
- Help/stay decision.
- Passing-lane gamble.
- Rim contest.
- Rebound positioning.
- Foul/clock decision.
- Play-call or strategy influence when authorized.

### 22.3 Decision timeout

User decisions remain under real-time pressure and expose a limited response window appropriate to the action. Recognition, preparation, and basketball IQ can affect when the situation becomes visible, but launch accessibility does not change the outcome rules or create an easier simulation mode.

If time expires:

- The engine resolves behavior from saved tendencies, coach instructions, role, and context.
- Timeout is not automatically the worst option.
- The selected automatic action is recorded for deterministic resolution.

### 22.4 Prompt pacing

The scheduler uses:

- Role and minutes.
- Actual touch/assignment involvement.
- Game importance and leverage.
- Recent prompt history.
- Action variety.
- User-selected skip state.

A low-role game can finish with no opportunities. A star can receive more opportunities without controlling every possession.

The presentation scheduler targets approximately three to five minutes for a normal meaningful played game. A DNP, short appearance, or low-involvement game can finish in under three minutes. Stakes primarily change presentation intensity and clutch depth rather than substantially extending game length.

## 23. Play, Sim, and Skip Contracts

### 23.1 Play

- Engine advances automatically between opportunities.
- User decisions and execution are committed to the match session.
- Presentation can speed or slow between interactions without changing domain event order.

### 23.2 Sim full game

- Uses the same match-start snapshot, rule profile, rotations, and Tier A possession engine for the userâ€™s game.
- Generates automatic decisions and execution for every player.
- Produces the same final result schema and development/health inputs.

### 23.3 Skip to next appearance

- Simulates until the next time the user checks into the game.
- Stops if a required nonautomatable user decision exists outside ordinary basketball execution.
- Returns final result if no later appearance occurs.

### 23.4 Skip to final result

- Simulates all remaining opportunities from saved tendencies and coach instructions.
- Does not reduce rewards or apply a skip penalty.
- Cannot be undone after final result commits.

### 23.5 Pause and background

- Pausing is allowed outside an active execution challenge.
- Backgrounding during a challenge persists the prechallenge state and challenge identity.
- Resume cannot reroll the opportunity, restart the window for advantage, or duplicate the result.

## 24. Statistics and Event Attribution

### 24.1 Required player box score

At minimum:

- Seconds/minutes played.
- Points.
- Field goals made/attempted.
- Three-pointers made/attempted.
- Free throws made/attempted.
- Offensive and defensive rebounds.
- Assists.
- Steals.
- Blocks.
- Turnovers.
- Personal fouls.
- Plus/minus where competition supports it.

### 24.2 Required team/game statistics

- Score by period.
- Possessions estimate and engine possessions.
- Shooting splits.
- Offensive/defensive rebounds.
- Assists.
- Steals, blocks, turnovers, fouls.
- Points in paint or equivalent zone summary.
- Fast-break/transition points where supported.
- Lead changes, ties, largest lead, and overtime.

### 24.3 Event ledger

Every official statistic derives from an ordered domain event with unique sequence ID. Applying the same event twice is rejected.

```ts
interface MatchDomainEvent {
  matchId: string;
  sequence: number;
  period: number;
  clockMs: number;
  type: string;
  actors: PlayerId[];
  teamId?: OrganizationId;
  payload: unknown;
}
```

The box score is a materialized projection of events and is reconciled at match completion.

### 24.4 Match rating

Player match rating is role-relative and derives from documented basketball contributions and mistakes. It can include off-ball/screen/defensive events unavailable in the public box score, but every contribution must have an engine event source. It does not directly grant arbitrary Attribute Points.

## 25. Match Output Contract

```ts
interface MatchFinalResult {
  matchId: string;
  gameId: GameId;
  rulesetVersions: MatchRulesetVersions;
  finalScore: ScoreState;
  periodScores: PeriodScore[];
  overtimePeriods: number;
  playerStats: PlayerStatLine[];
  teamStats: TeamStatLine[];
  lineupMinutes: LineupMinuteRecord[];
  injuries: InjuryCandidateEvent[];
  fatigueOutput: PlayerFatigueOutput[];
  roleEvaluationEvents: RoleEvaluationEvent[];
  relationshipEvents: BasketballRelationshipEvent[];
  accoladeCandidates: AccoladeCandidate[];
  debug?: MatchDebugOutput;
  finalEventSequence: number;
}
```

Career systems consume this immutable result through one idempotent command. `accoladeCandidates` are performance evidence, not finalized awards. The owning competition applies its eligibility and participation rules and finalizes awards exactly once after its postseason for the competition and career year. Candidate, watch-list, nomination, semifinalist, or finalist status never directly grants a Badge Development Point; only a finalized qualifying award may do so when the owning level rule and Balance Specification authorize it.

The match engine does not award cash, followers, Attribute Points, Badge Development Points, finalized awards, offers, or relationships directly. Its idempotent match-result commit is not the career-year resolver and cannot substitute for an annual completion receipt.

## 26. Tier B and Tier C Compatibility

Fidelity changes basketball detail only. Every tier consumes upstream-validated legal rosters and career state, preserves the same completion receipts, and follows the legal-state boundary in Section 3.3.

### 26.1 User games

Every user-team game uses the Tier A engine whether the user selects Play or Sim.

### 26.2 Tier B games

Tier B can aggregate multi-action possessions, but it must share:

- Validated legal membership, eligibility, availability, and game-day registration.
- Current attributes and derived-capability definitions.
- Availability, lineups, planned minutes, and fatigue principles.
- Tactics, roles, tendencies, and chemistry bounds.
- Shot-zone, turnover, rebound, foul, and pace calibration targets.
- Injury and development output contracts.
- Official box-score schema.

When a player becomes notable, recruited, award-relevant, transfer-relevant, draft-relevant, directly connected, or otherwise material to the career, Tier B retains a persistent identity, legal membership, eligibility, sufficient aggregate season evidence, awards and movement, and committed history. Later promotion cannot regenerate that player into a contradictory past.

Tier B results are tested against Tier A distributions for equivalent inputs. Material divergence requires a documented reason and approved tolerance.

### 26.3 Tier C competition

Tier C can resolve basketball results for games or calendar groups from team and player aggregates. It produces evidence for the owning career and world services and must preserve:

- Team strength and style identity.
- Legal team and roster summaries plus material availability supplied upstream.
- Player development, aging, health, and evaluation inputs without directly resolving the annual change.
- Results, champions, records, notable injuries, and award-candidate evidence.
- Upstream legally resolved roster and transaction state.
- Cross-tier statistical compatibility where information becomes visible.

Tier C does not create membership, playing contracts, signing rights, professional assignments, import changes, or replacements. It does not directly resolve annual progression, professional service, Out-of-Basketball state, transactions, or awards. It produces no fabricated detailed box scores or possession history.

### 26.4 High-school relevance tiers

- The playerâ€™s active district uses full player- and game-level simulation.
- The other three districts in the active state use team-level schedule, standings, qualification, and result simulation.
- Schools outside the active state use national-index simulation based on Team Power Rating, schedule context, state performance, and bounded deterministic variance.

Team Power Rating is a reduced-detail team input summarizing roster quality, coaching, form, health, and competitive environment. It never substitutes for the active ratings or aggregate evidence of a persistent named player.

A background school or player enters relevant-aggregate simulation when direct competition, recruiting, notability, award relevance, transfer or draft interest, scouting, a relationship, or a narrative dependency makes it relevant. At that point the world service persists identity, legal membership, eligibility, sufficient aggregate evidence, awards and movement, and committed history. Promotion to full detail adds only previously uncommitted roster, rotation, coaching, health, and tactical detail prospectively and deterministically. It cannot change a committed result or tournament seed, and previously summarized games never receive fabricated player box scores.

### 26.5 Development boundary and detail-promotion invariance

Development is a career-domain resolution, not a match resolution. This specification defines the boundary; `BALANCE_SPEC.md` Â§9.7 owns the canonical development contract and its distributions.

**The match engine's role.** The engine emits participation, role-relative performance, and workload evidence in `MatchFinalResult`. It never grants Attribute Points, never allocates them, never changes a rating or a cap, and never advances a career year (Â§25).

**Executor equivalence.** One canonical development contract governs the user, full-detail NPCs, and aggregate executors. Detail level changes how the contract is executed, never what it produces:

- The user allocates manually.
- Full-detail NPCs receive AP-equivalent opportunity and allocate through an automatic allocator bound by identical costs, caps, timing, aging, decline, and source-ledger rules.
- Tier B and Tier C executors may resolve development in aggregate, but must reproduce the distributions the full-detail path would have produced, within the tolerances in `BALANCE_SPEC.md` Â§27.2.

**Detail-promotion invariance.** Changing a player's simulation detail level must not change the player. Promotion and demotion may add or drop evidence resolution; they may never alter current ratings, potential caps, body state, maturity state, accumulated development, or committed history. This extends Â§26.4's prospective-promotion rule from history to development state.

The engine must therefore never receive a player whose ratings depend on how closely he is being simulated. A player who is stronger because the user is about to face him violates this contract and the parity requirements in Â§27.5.

## 27. Calibration Framework

### 27.1 Calibration hierarchy

1. Possession and event validity.
2. Team-level statistical realism.
3. Player role and minute realism.
4. Attribute sensitivity and build differentiation.
5. Competition-level differences.
6. Career consequences and progression inputs.
7. Played-versus-simmed parity.

Do not tune final scores before turnover, shot selection, foul, and rebound processes are structurally correct.

### 27.2 Required team metrics

By competition and season:

- Possessions per game.
- Points per possession and game.
- Field-goal, three-point, two-point, and free-throw percentages.
- Three-point attempt rate.
- Free-throw rate.
- Turnover percentage.
- Offensive rebound percentage.
- Assist percentage.
- Steal and block rates.
- Foul rate.
- Home win rate and margin.
- Score-margin distribution.
- Overtime frequency.

### 27.3 Required player metrics

- Minutes and starts by rotation role.
- Usage distribution.
- Shot-zone distribution by role/archetype.
- Efficiency by rating and context.
- Assist/turnover relationship.
- Rebound share by position/body/ratings.
- Foul and block/steal rates.
- Fatigue decline by stint and workload.
- DNP and low-minute frequency.
- Award-evidence and statistical-leader plausibility over seasons; award finalization remains competition-owned.

### 27.4 Sensitivity requirements

Controlled experiments must demonstrate:

- Increasing a relevant attribute improves its required observables over large samples.
- Unrelated attributes do not dominate the outcome.
- Specialized builds create strengths and weaknesses rather than universal Overall dominance.
- A 99 rating produces exceptional capability but not impossible action access.
- Perfect manual shooting succeeds only when the attempt exposes a valid perfect zone.
- Defense can remove or shrink that zone through legitimate context.
- Team chemistry, home court, badges, morale, and momentum remain within approved bounded effects.

### 27.5 Parity requirements

For identical match inputs across large samples:

- Played games with automatic/no manual intervention match full Sim distributions.
- Skip-to-final matches full Sim distributions.
- Tier B matches Tier A team-level distributions within defined tolerances.
- Presentation speed and device frame rate do not change results.

## 28. Debug and Explainability

Development builds can request contribution traces:

```ts
interface ResolutionTrace {
  eventId: string;
  candidates: CandidateWeightTrace[];
  selectedCandidate: string;
  capabilityInputs: CapabilityTrace[];
  contextModifiers: ModifierTrace[];
  badgeContributions: BadgeContributionTrace[];
  probability?: number;
  randomDraw?: number;
  result: string;
}
```

Rules:

- Debug traces are deterministic and excluded from release UI.
- Traces identify versioned formulas and content IDs.
- Hidden precise durability, event odds, and stale scouting truth do not leak into player-facing screens.
- Balance tools can aggregate traces without storing user-entered names.

## 29. Automated Simulation Verification

Required suites:

1. Possession-state invariant tests.
2. Clock, period, overtime, foul, and substitution tests by rule profile.
3. Stat-event reconciliation tests.
4. Determinism golden fixtures.
5. Attribute contract and monotonicity tests for all 20 ratings.
6. Tendency and coach-authority behavior tests.
7. Rotation/minute distribution tests.
8. Manual perfect-window tests.
9. Played/Sim/Skip parity tests.
10. Tier A/Tier B distribution comparison.
11. Extreme-build and intentionally weak-build tests.
12. Fatigue, injury-candidate, and play-through limitation tests.
13. Badge trigger, tier, stacking, and cap tests.
14. Large-sample competition calibration reports.
15. Multi-season leader, award-evidence, downstream award-integration, and roster-role plausibility reports.
16. Upstream legal-state validation fixtures covering contractual membership, active playing contracts, rights-only assignment rejection, contract-term import classification, college and draft eligibility, Out-of-Basketball state, and the 25-season boundary.
17. Legal-roster preflight tests proving automatic authorized replacement occurs before match creation and the match engine never invents legal state or players.
18. Active-player 25â€“99 rating-domain tests and sub-25 placeholder rejection.
19. Tier B relevance-promotion persistence and no-retroactive-box-score tests.
20. Tier B/Tier C annual-receipt, professional-service, level-change, and Out-of-Basketball idempotency tests.
21. Award-candidate non-BDP and exactly-once downstream award-finalization tests.
22. Overall-exclusion tests proving no resolution path reads Current Overall, Maximum Potential Overall, or Projected Peak (Â§6).
23. Layered-identity tests: rotation role affects minutes only, tactical role affects opportunity only, derived archetype affects nothing, and no identity layer reaches a capability or probability (Â§10.6).
24. Tactical-role stability tests proving one active role per player per game, fixed for the game, with emergency duty and DNP never relabeling the player.
25. Body contract tests covering action validity, reach, positioning, and matchup effects, and proving the engine cannot observe or resolve growth (Â§6.1, Â§6.3).
26. Detail-promotion invariance tests proving ratings, caps, and body are identical across simulation detail levels for the same seed (Â§26.5).
27. User/NPC development parity tests proving the manual path and the full-detail allocator produce equivalent distributions from equivalent opportunity.

Statistical tests use fixed seeds, sample-size declarations, confidence intervals, and failure tolerances from the Balance Specification. They cannot pass by expanding tolerances after every failure without a documented tuning decision.

## 30. New Godot Engine Handoff

### 30.1 Retain as verified design and calibration evidence

- Seeded possession resolution concepts.
- Existing action, turnover, steal, assist, shot-zone, contest, block, rebound, putback, fatigue, and home-court functions where calibration supports them.
- Key-moment scheduler, contextual options, challenge scoring, and resolution concepts.
- Play-by-play and box-score projections after event-contract migration.
- Existing deterministic and extreme-attribute test intent.

### 30.2 Replace or expand

Completed in the current Godot core:

- âœ… Replace 16-attribute inputs with the canonical 20-attribute model.
- âœ… Add free-throw rating, Offensive IQ, Defensive IQ, and Vertical contracts.
- âœ… Replace raw RNG callbacks with the injected versioned `RandomSource`.
- âœ… Keep scene nodes and presentation state from owning score, clock, box score, or engine state. (Currently trivially satisfied: no presentation layer exists yet.)

Also completed since that list was written:

- [x] Replace fixed five-player `Team` tuples with upstream-validated roster, lineup, and rotation snapshots (`TeamMatchProfile`, `TeamMatchState`, `RotationPlan`). Runtime lineup state is the sole authority for participation.
- [x] Replace generic league scaling with explicit competition rule/environment profiles. Five exist -- high school, college, domestic development, overseas, and top domestic professional -- and the pace environment is now a number the clock consumes rather than an id nothing read.
- [x] Expand one-action possessions into multi-action possession state (`PossessionEngine`).
- [x] Add planned rotations, substitutions, full fouls, minutes, coverage, and role state.
- [x] Expand `CapabilityCalculator` to the full derived-capability set, using the weights owned by the Balance Specification. All twenty capability rows plus the four physical capabilities are present and were verified against that table.
- [x] Move the anonymous numeric literals in shot resolution into the versioned simulation balance profile. Every match constant is a named tunable with a unit and a safe range, and the configuration-integrity check rejects one outside its range.
- [x] Replace the unconstrained `TacticalRole` string and its `balanced` default with the stable ID set.
- [x] Replace the `RotationRole` enumeration that mixed usage intent with availability facts.
- [x] Extend `BodyProfile` with standing reach, and add the career-domain maturity, projected-range, and growth-ledger state.
- [x] Implement §18.2's **score and time** rotation pressure. Six of §18.2's eight pressures are now implemented; performance-within-tolerance and coach trust remain outstanding because no career domain supplies them. The rule is `GarbageTimeRule`, and it is a *possession-based safety* rather than a raw margin: a lead is safe when it is large against the standard deviation of the margin still to be played, which is `settled_swing_points_per_pair * sqrt(possession_pairs_left)`. Two thresholds read that one shared number, and **the leading coach's is the lower of the two** — a coach who has won the game rests people before a coach who has lost it concedes. That asymmetry is authorised by the owner ruling of 2026-08-20 and is an asymmetry of *situation*: the policy is one policy, the sign of a team's own margin selects which half applies, and putting the same roster on the other side of the same scoreboard reverses its behaviour exactly. The state lives on `TeamMatchState.settled_mode`, is written only by `MatchStateReducer` from a `GARBAGE_TIME` event carrying the mode and the margin it was taken at, and is released — with hysteresis, and on both the safety and the coaching margin floor — when the trailing team actually closes the gap. `RotationResolver` reads it and never recomputes it, so no policy lives in the substitution loop. It moves minutes and nothing else: no rating, no probability, no possession.
- [x] Implement §10.2's **clock and score** candidate input and §10.3's `ScoreClockContext` as a real score term. `GameManagement` computes one bounded pressure — the deficit expressed in possession pairs, over the pairs the remaining regulation time actually buys at the pace this game has played at — and the team ahead protects the lead while the team behind chases it. It reaches the clock draw, the action weights and the offensive-glass crash decision, and it reaches no probability: the same shot, from the same shooter, against the same defender, resolves identically at any score. Before it, the score entered resolution only inside the last forty seconds of the final period, and the measured seconds per possession, actions per possession and three-point share were identical across every score state.
- [x] Implement §20.2 **clutch behaviour** as an end-of-regulation possession strategy. On the last possession of regulation a trailing team prefers the shot value that levels the game — a three when down three, a two when down two — instead of hunting the highest value available. It is the deficit that selects the value, so either team holds the same rule.
- [x] Implement §4's `timeoutRule` and §5's `TimeoutState`. Each competition profile grants a phase-appropriate allowance, `TeamMatchState` carries what is left, and a coach spends one to answer an opponent's run of `timeout_run_points` or more unanswered points while enough regulation remains to want it. A `TIMEOUT` event is written to the ledger; the reducer spends the allowance and rests everybody on the floor on both sides. It grants no probability and moves no possession. Overtime grants no further timeouts.
- [x] Order substitution planning by force rather than by lineup position. §5.1's mandatory departures — foul-out, ejection, medical unavailability — claim the bench before any discretionary substitution does. The previous single pass could hand the last eligible bench player to a coaching preference and leave a fouled-out player with no legal replacement; that was unreachable while every discretionary reason required a completed stint, and became reachable the moment the settled-game rule could move four players at once.
- [x] Give the engine a **game-stakes context** (§18.2 contextual adjustment). `GameStakes` is three tiers — `REGULAR`, `POSTSEASON`, `CHAMPIONSHIP_OR_ELIMINATION` — carried on `MatchInput` and defaulted to `REGULAR`. `StakesPolicy` is the only place a tier becomes a number, and four coaching decisions read it: how far past his planned minute share a coach lets a player run, how much regulation must remain before he spends a timeout on an opponent's run rather than holding it, how many standard deviations of safety he demands before entering the settled rotation, and how early and how firmly the end-of-regulation tie-seeking preference applies. Every effect is `base * (1 + step * tier)`, so a regular-season game multiplies by exactly one and every committed golden ledger is byte-identical. A tier reaches no resolver, no rating, and no capability; it cannot read a competition, a round, a team, or a result. **Mapping real game metadata onto a tier belongs to the future scheduling and career layers, not to the engine** — the engine is handed a tier and learns nothing else about the occasion, which is what keeps a tier from becoming a place to hide a per-tournament exception.

Outstanding:

- Add tactical coordinates to resolution. `TacticalLocation` now has exactly one production reader: §12.6 make resolution charges an attempt for the distance between where it was actually taken and the distance its own shot zone implies, which is what stops a backcourt heave resolving on arc odds. That is the whole of it. Tactical movement frames are still not part of possession resolution — rebound positioning, contest arrival and help distance do not read a location, and a possession that runs the ordinary opening does not carry one. This item stays outstanding.
- Remove career money, morale, and Ink state from the match adapter. (No such coupling exists in the new repository; this remains a rule for future adapters rather than a migration task.)
- Prevent match-initialization drift by using `MatchSessionService` after legal-roster preflight and any authorized automatic replacement. `MatchSession` exists and is the single session behind Play, Sim, and Skip; the upstream preflight does not, because no career or world domain is implemented.

Implementation status is not calibration status. This section records what is *implemented*; `BALANCE_SPEC.md` section 32.1 records what is *calibrated*, and the two are separate claims.

### 30.3 Implementation stages

1. Freeze approved design fixtures and any trustworthy archived baseline distributions as reference evidence.
2. Add canonical player/team adapters and 20-attribute mapping.
3. Unify initialization through the match-session contract after upstream legal-roster and game-registration validation.
4. Convert possession results into ordered domain events and reconcile current box scores.
5. Add rules profiles, periods, fouls, lineups, minutes, and substitutions.
6. Add tactical movement frames and portrait-court presentation adapter.
7. Add manual decision/execution input through the same resolution path.
8. Add Tier B executor and parity harness.
9. Remove legacy match and Ink coupling after all callers migrate.

At every stage, approved statistical baselines and trustworthy archived evidence are compared rather than discarded. A change is accepted because it satisfies the locked contract and calibration evidence, not merely because the new code is newer.

## 31. Balance Specification Handoff

`BALANCE_SPEC.md` must provide numeric values or curves for:

- Rating normalization and derived-capability weights.
- Action-selection multipliers and caps.
- Shot profiles, floors, ceilings, window shapes, and context penalties.
- Turnover, steal, assist, block, rebound, foul, and putback curves.
- Fatigue accumulation/recovery and injury-candidate rates.
- Coach authority, chemistry, home environment, pressure, morale, and momentum bounds.
- Badge effects and stacking caps.
- Competition pace, rules, environment, and statistical targets.
- Tier A/Tier B tolerance bands.
- Calibration sample sizes and confidence thresholds.
- Role-opportunity bounds for every tactical role, and the proof that no identity layer reaches a capability.
- Body dimension effects on action validity, reach, positioning, and matchups.
- Projected-peak model inputs, coverage rate, and range-width guardrails.
- Development-opportunity distributions for the full-detail NPC allocator and aggregate executors.

No production tuning constant should remain anonymously embedded in engine code. Every tunable value belongs to a named, validated, versioned balance profile with documented units and safe range.

## 32. Definition of Simulation Readiness

The simulation contract is implementation-ready when:

- All 20 attributes have approved measurable effects and contract tests.
- Active named Tier A and Tier B player ratings validate at 25â€“99, and sub-25 placeholders are rejected from matches.
- No resolution path reads Current Overall, Maximum Potential Overall, or Projected Peak.
- Rotation role, tactical role, and derived archetype are separate, use their stable IDs, and stay within their declared effect boundaries.
- Body affects only action validity, reach, positioning, and matchups, and the engine cannot observe or resolve growth.
- Detail-promotion invariance holds for ratings, caps, and body state.
- Canonical player, roster, lineup, match, event, and result types compile.
- Every match begins from an upstream-validated legal roster and game-day registration, with any authorized temporary replacement supplied before `MatchSnapshot` creation.
- One user game can Play, Sim, and Skip through one match session.
- Manual shooting honors valid visible perfect guarantees.
- Coaches, tendencies, roles, rotations, fatigue, and fouls affect valid engine state.
- Box scores reconcile from ordered events.
- Determinism fixtures pass across supported runtimes.
- Tier B and Tier C legal-state parity, annual-receipt, persistent-history, and award-ownership verification passes.
- Tier A baseline metrics are stable enough for Balance Specification tuning.
- The Godot engine has measured calibration evidence and no direct career, narrative-runtime, scene, or presentation-state mutation dependency.
