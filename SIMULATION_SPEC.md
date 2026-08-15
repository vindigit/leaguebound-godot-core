# LeagueBound Basketball Simulation Specification

| Field | Value |
| --- | --- |
| Version | 1.0 contract draft |
| Date | August 2, 2026 |
| Status | Draft for simulation and balance review |
| Basketball design source | `GDD.md`, within the approved source-authority hierarchy |
| Product requirements | `PRD.md` |
| Architecture implementation | `GODOT_TDD.md`; it cannot redefine gameplay |
| Current implementation evidence | `PROJECT_STATUS.md` |

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

District ties resolve by head-to-head mini-table, capped district point differential, then a deterministic schedule-seeded draw. The state bracket uses fixed cross-district pairings, prevents same-district first-round games, and never reseeds. National seeds 33–96 play the opening round, seeds 1–32 receive byes, and the bracket applies neither reseeding nor geographic protection.

School basketball and summer club basketball never share one undifferentiated schedule or two simultaneous current memberships. Summer eligibility begins after the player’s actual school-elimination date. When an accepted summer place begins, the club becomes the one current competition membership and the continuing school place is retained only as a next-season reservation or affiliation until club membership closes. Each summer block expands into the games defined by its competition format and preserves separate club, statistics, workload, recruiting exposure, and history attribution.

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

- Five-on-five men’s basketball.
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
  → advance or transition
  → half-court entry when transition does not resolve
  → choose initiator and action
  → defense selects coverage/response
  → resolve advantage, turnover, foul, reset, or shot setup
  → resolve shot or free throws
  → rebound or change possession
  → update clock, fatigue, fouls, statistics, and presentation events
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
- Offensive rebounds use the rule profile’s reset behavior.
- Dead-ball fouls and free throws use separate event time without incorrectly consuming shot-clock time.

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
  × RoleOpportunity
  × PlayerTendency
  × CoachInstruction
  × TacticalFit
  × MatchupOpportunity
  × ScoreClockContext
  × CapabilityConfidence
  × FatigueAvailability
```

The Balance Specification defines curves and caps. No single factor except validity can reduce every action to zero.

### 10.4 User tendency sliders

The ten five-position sliders affect automatic behavior:

- Pass First ↔ Score First.
- Patient ↔ Aggressive.
- Perimeter ↔ Interior.
- Create Own Shot ↔ Off-Ball.
- Safe ↔ Creative Passing.
- Push Transition ↔ Control Tempo.
- Disciplined Defense ↔ Gamble.
- Stay Attached ↔ Help.
- Box Out ↔ Chase Rebounds.
- Defer ↔ Seek Clutch Opportunities.

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

The player’s saved tendencies remain the behavioral baseline. Coaching can substantially shape role and opportunity but cannot permanently rewrite those sliders.

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

Probability floors and ceilings are shot-profile-specific and defined in the Balance Specification. Floors cannot make absurd shots routinely viable, and ceilings cannot erase the user’s valid perfect guarantee.

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

Defensive IQ and Interior/Perimeter Defense reduce avoidable foul risk through better position and legal contest selection. Stealing and Blocking increase success after a valid attempt; they do not independently force constant gambling. The Disciplined ↔ Gamble tendency and coach instructions determine attempt frequency.

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

Meaningful user rebound opportunities can offer action-specific positioning or timing interaction. Perfect execution maximizes the player’s candidate quality but does not guarantee possession against superior position, size, teammates, or opponents.

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
- Stay Attached ↔ Help tendency.
- Disciplined ↔ Gamble tendency.
- Box Out ↔ Chase Rebounds tendency.
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

User work rate changes involvement and action intensity with a corresponding fatigue cost. It cannot create guaranteed touches or overrule the coach’s substitution authority.

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

## 20. Pressure, Clutch, and Momentum

### 20.1 Pressure

Pressure derives from score margin, time, game importance, crowd, personal stakes, foul state, and role. It can affect recognition time, simulated decision noise, and execution stability.

Manual timing remains user skill. Pressure may change window stability or size through visible context but cannot secretly alter the measured input after submission.

### 20.2 Clutch behavior

Defer ↔ Seek Clutch Opportunities changes willingness to initiate or accept late-game actions. Coach plan, role, matchup, and ability still determine access.

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

- Uses the same match-start snapshot, rule profile, rotations, and Tier A possession engine for the user’s game.
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

- The player’s active district uses full player- and game-level simulation.
- The other three districts in the active state use team-level schedule, standings, qualification, and result simulation.
- Schools outside the active state use national-index simulation based on Team Power Rating, schedule context, state performance, and bounded deterministic variance.

Team Power Rating is a reduced-detail team input summarizing roster quality, coaching, form, health, and competitive environment. It never substitutes for the active ratings or aggregate evidence of a persistent named player.

A background school or player enters relevant-aggregate simulation when direct competition, recruiting, notability, award relevance, transfer or draft interest, scouting, a relationship, or a narrative dependency makes it relevant. At that point the world service persists identity, legal membership, eligibility, sufficient aggregate evidence, awards and movement, and committed history. Promotion to full detail adds only previously uncommitted roster, rotation, coaching, health, and tactical detail prospectively and deterministically. It cannot change a committed result or tournament seed, and previously summarized games never receive fabricated player box scores.

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
18. Active-player 25–99 rating-domain tests and sub-25 placeholder rejection.
19. Tier B relevance-promotion persistence and no-retroactive-box-score tests.
20. Tier B/Tier C annual-receipt, professional-service, level-change, and Out-of-Basketball idempotency tests.
21. Award-candidate non-BDP and exactly-once downstream award-finalization tests.

Statistical tests use fixed seeds, sample-size declarations, confidence intervals, and failure tolerances from the Balance Specification. They cannot pass by expanding tolerances after every failure without a documented tuning decision.

## 30. New Godot Engine Handoff

### 30.1 Retain as verified design and calibration evidence

- Seeded possession resolution concepts.
- Existing action, turnover, steal, assist, shot-zone, contest, block, rebound, putback, fatigue, and home-court functions where calibration supports them.
- Key-moment scheduler, contextual options, challenge scoring, and resolution concepts.
- Play-by-play and box-score projections after event-contract migration.
- Existing deterministic and extreme-attribute test intent.

### 30.2 Replace or expand

- Replace 16-attribute inputs with the canonical 20-attribute model.
- Replace fixed five-player `Team` tuples with upstream-validated roster, lineup, and rotation snapshots.
- Replace generic league scaling with explicit competition rule/environment profiles.
- Expand one-action possessions into multi-action possession state.
- Add free-throw rating, Offensive IQ, Defensive IQ, and Vertical contracts.
- Add planned rotations, substitutions, full fouls, minutes, tactical coordinates, coverage, and role state.
- Remove career money, morale, and Ink state from the match adapter.
- Keep scene nodes and presentation state from owning score, clock, box score, or engine state.
- Replace raw RNG callbacks with the injected versioned `RandomSource`.
- Prevent match-initialization drift by using `MatchSessionService` after legal-roster preflight and any authorized automatic replacement.

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

No production tuning constant should remain anonymously embedded in engine code. Every tunable value belongs to a named, validated, versioned balance profile with documented units and safe range.

## 32. Definition of Simulation Readiness

The simulation contract is implementation-ready when:

- All 20 attributes have approved measurable effects and contract tests.
- Active named Tier A and Tier B player ratings validate at 25–99, and sub-25 placeholders are rejected from matches.
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
