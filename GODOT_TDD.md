# LeagueBound Godot Technical Design Document

| Field | Value |
| --- | --- |
| Version | 1.0 architecture baseline |
| Date | August 14, 2026 |
| Status | Current technical implementation authority for the new repository |
| Engine | Godot 4.x; exact stable patch version pinned by the repository and CI |
| Launch language | Typed GDScript |
| Platforms | iOS and Android; portrait only |
| Product requirements | `PRD.md` |
| Basketball contract | `SIMULATION_SPEC.md` |
| Archived predecessor | `TDD.md`; reference only |

## 1. Purpose and authority

This document defines the implementation architecture for the new Godot repository. It owns technical boundaries, dependency direction, persistence strategy, deterministic execution, test strategy, deployment evidence, and implementation gates. It does not define gameplay.

When sources conflict, use this order:

1. Explicit owner rulings.
2. Locked level-specific system documents.
3. Later and more-specific working frameworks.
4. `GDD.md`.
5. `PRD.md`.
6. `SIMULATION_SPEC.md`.
7. `BALANCE_SPEC.md`.
8. This document.
9. `CONTENT_BIBLE.md`.
10. Archived or superseded material, including `TDD.md` and the React Native / Expo prototype.

This document may choose a compatible technical representation. It may not redefine membership, eligibility, contracts, rights, assignments, career-year resolution, competition rules, balance values, content canon, or player-facing behavior owned above it.

## 2. Architectural goals

The architecture must provide:

- A pure, headless, seeded simulation core that is independent of scenes, frames, devices, and rendering.
- One basketball engine for Play, Sim, and Skip.
- Strict separation among match simulation, career/world rules, the Personal Hub, narrative presentation, and platform integrations.
- Exactly three independent local career slots with transaction-safe autosave, recovery, and migrations.
- Deterministic career and match reproduction from committed inputs and explicit random streams.
- Fast portrait-mobile presentation without placing game law in scene scripts.
- Test execution from the command line without opening a game window.
- iOS and Android export evidence from the start of implementation.

The architecture must not:

- Port the React Native component tree, Zustand stores, TypeScript types, Expo modules, or JavaScript test/build pipeline into the new runtime.
- Treat a Godot scene tree, autoload, signal bus, or SQLite table as a gameplay owner.
- Create separate played-game and simulated-game rules.
- Make content, analytics, ads, purchases, or narrative connectivity prerequisites for an offline career.
- Add a general-manager control surface or administrative minigames not approved by product design.

## 3. Technology decisions

### 3.1 Engine and renderer

- Use a pinned stable Godot 4.x release. Engine upgrades require an architecture decision record, clean headless tests, migration verification, and Android/iOS export smoke tests.
- Start with Godot's Mobile renderer. A Compatibility-renderer fallback may be supported when device testing proves it necessary.
- The game remains portrait-first. Scene composition, safe areas, touch targets, and performance budgets must be verified at supported phone and tablet aspect ratios.

### 3.2 Language

Typed GDScript is the launch application language.

Reasons:

- It is the engine-native path for scenes, Resources, signals, editor tooling, and headless scripts.
- It avoids making the launch mobile exports depend on the experimental limitations documented for Godot C# mobile support.
- A single application language keeps the initial repository, test harness, and mobile debugging surface small.

GDScript requirements:

- Use static type annotations for public methods, stored state, signal payloads, and domain collections.
- Treat warnings promoted by the project configuration as build failures.
- Avoid untyped `Dictionary` payloads at cross-layer boundaries; use named value objects or validated data-transfer objects.
- Do not use global random functions inside domain code.

C# is not a launch dependency. A later C# adoption requires an approved architecture decision and full mobile-export proof. C++/GDExtension is limited to pinned native integrations such as SQLite or a measured performance hotspot with an isolated interface.

### 3.3 Persistence

Use SQLite through the Godot 4 `godot-sqlite` GDExtension, pinned to a reviewed version and wrapped behind repository interfaces. Gate 0 must prove its exact binaries on physical or release-equivalent Android arm64 and iOS arm64 builds before career implementation expands.

The application must never call the addon's API from scenes or domain services. `SqliteConnection`, SQL statements, migrations, and addon-specific values remain inside `infrastructure/persistence/`.

If the selected addon version cannot pass both mobile targets, replace only the infrastructure adapter with a maintained project-owned SQLite GDExtension. The repository contracts and save semantics remain unchanged.

## 4. Layer model and dependency direction

The repository uses four application layers:

```text
presentation (scenes, nodes, input, animation, view models)
        ↓ commands / queries                ↑ presentation events
application (use cases, orchestration, transactions, projections)
        ↓ ports
domain (pure rules, state transitions, simulation, value objects)
        ↑ implementations
infrastructure (SQLite, files, platform SDKs, clock, device services)
```

Allowed dependency direction is inward. Domain code imports no presentation, infrastructure, database, advertising, purchase, analytics, or device APIs. Application code depends on domain contracts and abstract ports. Infrastructure implements ports. Presentation calls application use cases and renders projections.

Dependency violations are release blockers, even when a feature appears to work.

## 5. Pure domain and simulation core

### 5.1 Purity boundary

The pure core is composed of typed GDScript classes extending `RefCounted` or other non-Node data/value types. It may use deterministic collections and arithmetic from the Godot runtime, but it must not access:

- `Node`, `SceneTree`, scenes, frame timing, or rendering.
- `ResourceLoader`, `FileAccess`, SQLite, network, or platform SDKs.
- Autoload singletons.
- Wall-clock time.
- Global randomness.
- UI or narrative presentation state.

Every domain operation receives all required state, configuration, and randomness explicitly and returns a result without hidden side effects.

### 5.2 Deterministic random streams

All nondeterminism flows through a versioned `RandomSource` interface. Each stream derives from committed identity inputs such as:

- Career seed.
- Career-year identity.
- Owning system and operation.
- Competition, match, event, organization, or player stable identity.
- Ruleset and balance-profile versions.

Rules:

- Never call `randf`, `randi`, `randomize`, or a shared global generator in domain code.
- Child streams must be derived by stable labels, not by incidental call order across unrelated systems.
- Iteration order is canonical before consuming randomness.
- A committed result stores the seed/stream reference and version needed to reproduce it.
- Loading, retrying, presentation speed, Play/Sim choice, and device frame rate cannot reroll a committed outcome.

### 5.3 Match engine contract

The match engine accepts an immutable, upstream-validated `MatchInput` and returns a `MatchResult` plus an ordered evidence/event stream.

Conceptually:

```gdscript
func simulate_match(input: MatchInput, random_source: RandomSource) -> MatchResult
```

The engine owns basketball resolution described by `SIMULATION_SPEC.md`. It may calculate possessions, actions, time, fouls, substitutions, fatigue, injuries, statistics, and accolade evidence. It cannot:

- Create or change roster membership, a playing contract, signing rights, a professional assignment, college eligibility, import classification, or Out-of-Basketball state.
- Generate an unauthorized replacement player.
- Finalize awards or directly grant Badge Development Points.
- Advance age, professional service, generic offseason development, or a career year.
- Write a save.

Career/world application services validate the legal roster and game-day registration and supply any authorized automatic replacement before creating `MatchInput`.

### 5.4 Play, Sim, and Skip

Play, Sim, and Skip call the same match session and engine:

- **Play** supplies user decisions and execution samples at approved opportunities.
- **Sim** supplies those values through the same player/coach behavior model.
- **Skip** advances the same session to the requested boundary without rendering intervening moments.

Presentation may interpolate or omit events. It may not recalculate results.

### 5.5 Player-system domain types

The player system is pure domain. Every type below extends `RefCounted` or another non-Node value type, receives its configuration and randomness explicitly, and has no scene, persistence, or platform dependency.

| Type | Owns | Notes |
| --- | --- | --- |
| `AttributeKey`, `PlayerAttributes`, `Rating` | The canonical 20 attributes and the 25–99 active domain | Implemented |
| `AttributeCaps` | Exact per-attribute potential caps | One cap per attribute; cap changes are ledgered |
| `BodyProfile` | Realized current height, weight, wingspan, standing reach | Extend the existing type with standing reach |
| `BodyMaturationState` | Confirmed freshman body, maturity profile, stored projected adult range, resolved-increment ledger | Career fact, not derived |
| `MaturityProfile` | `early`, `average`, `late` | Stable IDs |
| `CreationBudget` | Creation AP granted, spent, and remaining | Confirmation is illegal while remaining is non-zero |
| `AttributePointLedger` | Every AP-equivalent grant and spend with source, career year, executor, and balance version | Shared by the user and every NPC executor |
| `RotationRole` | The seven usage-intent roles | Replaces the current availability-mixing enum |
| `TacticalRole` | The eleven version 1.0 tactical role IDs | Replaces the unconstrained string |
| `PlayerTendencies` | The ten five-position sliders | Implemented |
| `OverallCalculator` | The role-neutral Overall formula | Pure function of ratings and coefficients |
| `DevelopmentProjection` | Current Overall, Maximum Potential Overall, Projected Peak range | The only supported source of these three values |
| `DerivedArchetype` | Composable display descriptors | Side-effect free; never a simulation input |

Two rules bind these types:

1. **Overall is derived, never stored as authority.** Current Overall, Maximum Potential, and Projected Peak are computed from ratings, caps, and the versioned profile. A cached copy may exist for query performance, but it is invalidated on any rating, cap, or body change and is never the value a rule reads.
2. **No basketball resolution path may depend on `DevelopmentProjection` or `DerivedArchetype`.** This is enforced by an automated dependency check (§13.2, §18), not by convention.

### 5.6 Versioned profile ownership

The player system reads three versioned balance profiles, all authored as Resources under `resources/balance/` and all pinned per career:

| Profile | Owns | Consumers |
| --- | --- | --- |
| `RatingsProfile` | Overall coefficients, capability weights, rating band definitions | `OverallCalculator`, capability calculators |
| `BuilderProfile` | Starting bases, creation AP budget, prospect-profile modifiers, per-attribute starting maxima, body redistribution bounds, projected-range widths | Builder service |
| `ProgressionProfile` | Upgrade cost table, seasonal availability, aging and decline curves, cap distributions, projected-peak model | Development service, allocator, aggregate executor |

Rules:

- A career stores the version of every profile it was created with and remains pinned to them (`BALANCE_SPEC.md` §4).
- No player-system constant may appear as an anonymous literal in domain code. A tunable without a name, unit, safe range, and version fails Gate 0.
- Profiles are immutable at runtime. A loaded profile Resource is never mutated; session-specific variation requires an explicit duplicate (§7).
- Changing a profile version requires a deterministic migration that records old version, new version, and reason.

### 5.7 Player-system persistence facts

These are **stored career facts**, not derived values, and each carries a schema version:

- Current ratings for all 20 attributes.
- Exact per-attribute caps, plus the cap-change ledger.
- Confirmed freshman body, maturity profile, and the projected adult range stored at confirmation.
- Realized current body and the resolved growth-increment ledger.
- Creation budget grant and final spend record.
- The AP-equivalent source ledger, including hidden fractional direct progress.
- Rotation role, tactical role, and tendencies.
- Balance-profile versions pinned at career creation.

These are **derived and never stored as authority**: Current Overall, Maximum Potential Overall, Projected Peak, derived archetype, and derived position labels.

Migration rules specific to this system:

- Hidden fractional progress is preserved across migrations (`BALANCE_SPEC.md` §29.3).
- A migration that cannot recover a stored projected adult range reconstructs the **widest** range consistent with the realized body and records the limitation. Narrowing a range around a realized value to fabricate precision is prohibited.
- A migration may never resolve a growth increment, spend AP, or change a cap as a side effect.

### 5.8 Player-system service boundaries

| Service | Layer | Responsibility |
| --- | --- | --- |
| `BuilderService` | application | Validates allocation against caps, costs, and starting maxima; enforces budget exhaustion; commits the confirmed build in one transaction |
| `DevelopmentService` | application | Grants AP-equivalent opportunity, applies allocation, enforces career-year receipts, writes the source ledger |
| `AttributeAllocator` | domain | The full-detail NPC allocation strategy; bound by the same costs and caps as the user |
| `AggregateDevelopmentExecutor` | domain | Bulk development that reproduces allocator distributions |
| `BodyMaturationService` | application | Resolves scheduled growth increments deterministically and idempotently |
| `DevelopmentProjectionQuery` | application | The single read path supplying the three development values and the archetype to presentation |

The match engine consumes ratings, body, badges, tendencies, and roles. It never calls any service in this table.

### 5.9 Career and world core

Career/world domain services own legal transitions delegated by the design documents. They validate and resolve:

- Career-year milestones and once-only completion receipts.
- Membership, playing contracts, top-league rights, assignment overlays, availability, and game registration as distinct concepts.
- School, summer, college, professional, and Out-of-Basketball transitions.
- Eligibility, roster legality, import classification, rights windows, and the 25-professional-season boundary.
- Offers, accepted decisions, releases, retirement, ending checkpoints, Second Chance, and archive eligibility.
- Tier B and Tier C world outcomes using the same legal rules as the user path.

No scene or match event directly mutates these states.

## 6. Godot scene and node boundaries

### 6.1 Scene responsibilities

Scenes own composition, input, animation, focus, accessibility presentation, audio cues, and view lifetime. Recommended top-level composition:

```text
AppRoot
├── ScreenHost
│   ├── SaveSlotsScreen
│   ├── BuilderScreen
│   ├── HubScreen
│   ├── MatchScreen
│   └── LegacyScreen
├── OverlayHost
│   ├── ModalLayer
│   ├── NotificationLayer
│   └── LoadingLayer
└── AccessibilityLayer
```

The tree is illustrative, not a mandate that every screen remain instantiated. Screen transitions go through a navigation service; screens do not reach into sibling nodes for domain state.

### 6.2 Node rules

- A node may own transient presentation state such as animation progress, selected tab, focus, or an open modal.
- A node must not be the canonical owner of career, match, economy, eligibility, roster, or save state.
- **A scene must never independently recalculate Overall, Maximum Potential, Projected Peak, derived archetype, attribute upgrade costs, per-attribute caps, remaining creation budget, or projected body range.** These arrive as a domain projection through an application query and are rendered as received. A Builder or development screen that computes a cost table, re-derives an archetype, or recomputes Overall from displayed ratings is a dependency violation and a release blocker, even when its arithmetic happens to agree. Two implementations of one formula is one formula too many, and the scene copy is the one that silently drifts when a balance profile changes.
- `_process` and `_physics_process` may render/interpolate committed state; they do not advance the career calendar or resolve simulation law.
- Scene teardown cannot discard a committed choice or simulation result.
- Re-entering a scene reconstructs its view from an application projection.

### 6.3 Autoloads

Keep autoloads small and infrastructure-oriented. Expected candidates are:

- `AppKernel`: constructs dependencies and starts the application.
- `NavigationService`: changes screens and owns back-stack behavior.
- `AudioService`: presents approved audio cues.
- `PlatformService`: exposes lifecycle, safe area, haptics, store, ads, and analytics ports.

Autoloads must not become a universal mutable game-state store. Career state is loaded through a slot-scoped application session and persisted through repositories.

## 7. Resource boundaries

Godot `Resource` files are for authored, versioned, mostly immutable configuration and content references, including:

- Competition rule profiles.
- Balance profiles and safe ranges.
- Content catalogs and stable identity references.
- Narrative definitions and presentation metadata.
- UI themes, court definitions, audio definitions, and avatar catalog entries.

Resources are not live save records. Runtime mutation of a loaded shared Resource is prohibited unless it has first been explicitly duplicated into unshared session data. Career saves store stable IDs and versions, not serialized scene nodes or shared Resource object graphs.

Resource import validation must reject duplicate stable IDs, broken references, values outside approved bounds, and content records that attempt to define structural rules.

## 8. Signals and application communication

Signals are presentation and lifecycle notifications, not hidden commands.

- Use typed signals with named payload types.
- A user action calls an application command explicitly; the committed result may then emit a presentation event.
- Signals may announce navigation, view refresh, audio, progress, lifecycle, or a completed application transaction.
- Signals must not cause a second domain resolution, reward, save transaction, or random draw.
- Avoid an unrestricted global event bus. Scope subscriptions to a screen, session, or explicit application service.
- Connect and disconnect according to node lifetime; late signals must be harmless after navigation.

Domain functions return results or domain events. The application layer commits them and decides which presentation signals to publish.

## 9. Career, Hub, match, and narrative separation

### 9.1 Career application service

The career application service is the transaction boundary for player decisions, calendar advancement, offers, game preparation, result commits, and endings. It loads one slot, validates the command, runs domain operations, commits atomically, and returns a projection.

### 9.2 Personal Hub

The Personal Hub is a presentation shell over career projections. Hotspots query available actions and send explicit commands. Hub objects do not infer eligibility or mutate the database. A bedroom, apartment, phone, training object, or calendar is a view of application state, not its owner.

### 9.3 Match session

`MatchSessionService` coordinates:

1. Legal-roster and game-registration preflight.
2. Upstream automatic replacement when required.
3. Immutable match-input creation.
4. Match-engine execution or incremental stepping.
5. Presentation-safe event delivery.
6. One idempotent final-result commit.

`MatchScreen` renders the session. It never writes box scores, injuries, awards, or career state directly.

### 9.4 Narrative

Narrative services consume approved content definitions and committed career facts. They return choices and proposed effects. The career application service validates and applies those effects through normal domain rules.

Narrative code cannot bypass costs, grant illegal membership, create an unauthorized offer, alter a finalized result, or write directly to persistence. If a future narrative runtime is adopted, it remains behind this interface.

## 10. Persistence and save integrity

### 10.1 Storage layout

Version 1.0 has exactly three local career slots. Use:

- One small account/index database for settings, entitlements, slot summaries, and recovery metadata.
- One SQLite database per career slot under `user://saves/`.
- Versioned authored Resources under `res://`; they are not copied into the mutable save except where migration reproducibility requires a compact version snapshot.

Separate slot databases make isolation, backup, delete, and recovery auditable. No table may contain mutable state for more than one career slot.

### 10.2 Repository ports

Application code uses interfaces such as:

- `CareerRepository`.
- `MatchRepository`.
- `HistoryRepository`.
- `ContentCatalog`.
- `SettingsRepository`.
- `EntitlementRepository`.

SQLite implementations use bound parameters, foreign-key enforcement, explicit transactions, and a single serialized writer per open slot. Domain objects do not expose SQL rows.

### 10.3 Transaction rules

One player decision or automatic milestone is one application transaction:

1. Load the expected slot version.
2. Validate prerequisites and idempotency keys.
3. Resolve deterministic domain changes.
4. Append committed events/evidence and update projections.
5. Record completion receipts.
6. Commit atomically.
7. Publish presentation notifications after commit.

Optimistic version checks reject stale commands. Retrying the same command or result commit is idempotent and cannot duplicate money, attributes, awards, games, age, service, history, or ending transitions.

### 10.4 Autosave and recovery

- Autosave follows every permanent choice, resolved match, milestone, purchase/restore change, and ending-state change.
- App suspension requests a checkpoint but correctness cannot depend on receiving a final lifecycle callback.
- Keep a known-good backup or SQLite online backup at controlled checkpoints.
- On open, run integrity/version checks before migration. A failed migration leaves the original save recoverable.
- Second Chance stores a pending-ending checkpoint. Permanent archive commits only after the controlling career-ending service confirms that no pending restoration remains; ordinary offline, failed-fill, or temporarily unavailable-ad states stay pending.
- Slot deletion requires explicit confirmation and uses a recoverable tombstone period before physical cleanup where platform storage allows it.

### 10.5 Migrations

Every schema change has a monotonic migration, fixture coverage from every supported prior version, and rollback/recovery instructions. Migrations cannot invent detailed historical evidence. When old state lacks safe evidence, preserve the coarsest truthful aggregate and mark the limitation internally.

## 11. Background work and mobile lifecycle

- Keep UI and scene-tree mutation on the main thread.
- Expensive pure simulation may run through `WorkerThreadPool` only after profiling demonstrates a need.
- Worker tasks receive detached immutable inputs and return detached results; they do not touch Nodes, shared mutable Resources, SQLite connections, or platform SDKs.
- Every worker task is joined/observed, cancellable at an application boundary, and safe to discard before commit.
- Database writes are serialized. Read concurrency is permitted only after addon/device testing proves it safe and useful.
- App pause, background, interruption, or orientation events cannot cause a second simulation commit.

## 12. Project structure

Target repository layout:

```text
project.godot
addons/
  godot-sqlite/
  gdUnit4/
src/
  domain/
    shared/
    basketball/
    career/
    world/
    economy/
  application/
    commands/
    queries/
    sessions/
    ports/
  infrastructure/
    persistence/
    platform/
    content/
    telemetry/
  presentation/
    app/
    hub/
    match/
    builder/
    legacy/
resources/
  balance/
  competitions/
  content/
scenes/
tests/
  unit/
  integration/
  simulation/
  transitions/
  persistence/
  device/
tools/
docs/
```

Feature folders may be subdivided, but dependency direction and layer responsibilities remain unchanged.

## 13. Testing strategy

### 13.1 Framework and execution

Use GdUnit4, pinned to a reviewed Godot-4-compatible version, for GDScript unit, integration, scene, and test-double support. Maintain a small project-owned headless acceptance runner so release-critical suites do not depend on editor interaction.

Canonical headless entry points must work from a clean checkout, for example:

```text
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --script res://tests/run_transitions.gd
```

The executable name may be platform-specific. CI pins it and records the engine version.

### 13.2 Required suites

- Pure domain unit tests for every rule and invalid transition.
- Seeded match fixtures, property tests, statistical calibration, and Play/Sim parity.
- **Builder suite:** creation-budget exhaustion, confirmation blocked while AP remains, no carry/refund/convert path, cost and cap enforcement, per-attribute starting maxima, completed-build OVR distributions against the locked profile bands, extreme-specialist tail, and the completed-build ceiling.
- **Projection suite:** the three development values are distinct and correctly ordered, Projected Peak is always a range, projections recompute on rating/cap/body change, and a cached projection is invalidated rather than served stale.
- **Overall-exclusion dependency check:** no basketball resolution path, balance profile, or persisted gameplay fact reads Current Overall, Maximum Potential, Projected Peak, or derived archetype.
- **Identity suite:** rotation role affects minutes only, tactical role affects opportunity only, archetype affects nothing, one active tactical role per game fixed for the game, and availability facts never relabel a rotation role.
- **Body suite:** growth determinism from the versioned career seed, containment inside the stored projected range, one increment per career-year milestone under shared receipts, no side-effect rating change, timing-profile separation, and the widest-range migration rule.
- **Development parity suite:** the manual path, the full-detail allocator, and the aggregate executor produce equivalent distributions from equivalent opportunity, and no allocator writes a rating directly or exceeds a cap.
- **Detail-promotion invariance suite:** ratings, caps, and body are identical across simulation detail levels for the same seed.
- **Presentation boundary tests:** Builder and development scenes render projection values without recomputing Overall, archetype, costs, caps, or projected peak.
- All 22 PRD transition scenarios recording all eleven required state axes.
- Career-year and professional-service idempotency tests.
- Three-slot isolation, create/load/delete, autosave, backup, recovery, and migration tests.
- SQLite transaction interruption and duplicate-command tests.
- Resource/catalog validation and stable-ID tests.
- Scene tests for navigation, focus, safe areas, lifecycle, and presentation-only signal behavior.
- Tier A/B/C legal-state and history-parity tests.
- Pending-ending and Second Chance ordering tests.
- Android and iOS export/install/start/save/resume smoke tests.
- A seeded 25-season soak career.

Statistical suites declare seeds, sample sizes, tolerance sources, and balance-profile versions. A failed suite is fixed through code or an approved balance change, not by silently widening tolerance.

### 13.3 Test doubles

Tests replace clock, random streams, persistence ports, ads, purchases, analytics, and device lifecycle through injected interfaces. Domain tests do not construct a scene tree or open SQLite.

## 14. Content, analytics, ads, and purchases

- Approved content is imported into validated Resources or a read-only catalog produced by the Godot content pipeline.
- Content tools operate headlessly and remain separate from career saves.
- Analytics queues locally and never blocks a career transaction.
- Advertising and purchase SDKs are infrastructure adapters behind platform ports.
- Entitlement verification and restore are idempotent. Paid state cannot change basketball ability, potential, health, opportunity legality, or simulation odds.
- Network failure preserves offline gameplay and pending, recoverable platform operations.

## 15. Performance and observability

Measure on supported physical devices:

- Cold launch and resume.
- Hub input latency and transitions.
- Match frame pacing.
- Weekly and offseason advance time.
- Autosave stall time.
- Memory across a 60-minute session.
- Tier B/C world processing and database growth across 25 seasons.

Development builds expose structured logs for commands, transaction IDs, deterministic seeds/versions, match commits, migrations, and recovery. Production logs exclude user-entered names, narrative text, and unnecessary personal data.

Optimization order is measurement, algorithm/data correction, background execution where safe, then isolated native code only when evidence justifies it. Presentation shortcuts may not change simulation results.

## 16. Security and platform boundaries

- Keep secrets and store credentials out of the repository and Resources.
- Validate all imported content, migration input, and platform callbacks.
- Use bound SQL parameters; dynamic identifiers come only from fixed internal allowlists.
- Store mutable databases under `user://`, never `res://`.
- Treat client-side purchase state as a cached entitlement subject to platform verification and restore behavior.
- Document third-party addon versions, licenses, checksums, and mobile binaries.

## 17. Architecture decision records

Create a short ADR before changing:

- Engine major/minor line.
- Launch application language.
- SQLite addon or storage engine.
- Random-stream/versioning contract.
- Save-database layout.
- Narrative runtime.
- Renderer baseline.
- A domain/presentation dependency rule.

An ADR records context, decision, alternatives, consequences, migration impact, and evidence. It cannot override a higher-authority gameplay source.

## 18. Godot foundation gate

Gate 0 passes only when a clean new repository demonstrates:

1. A pinned Godot 4.x project imports and runs headlessly in CI.
2. Typed GDScript parsing and the complete automated suite pass from a clean checkout.
3. The pure match engine executes the same seeded fixture without a scene tree and reproduces its result.
4. The application-layer dependency checks prevent domain imports of scenes, persistence, platform SDKs, and autoloads.
5. The pinned SQLite adapter opens, migrates, writes, backs up, restores, and reopens one test slot.
6. Three isolated local slots pass create/load/save/delete and cross-slot contamination tests.
7. A minimal scene can create/resume a slot, render a projection, and commit one deterministic command without owning domain state.
8. Android and iOS export builds launch on release-equivalent targets and pass a database save/resume smoke test.
9. The 22-scenario transition runner exists, even if later content gates are still pending.
10. The archived React Native / Expo application is absent from the new runtime dependency graph and build pipeline.
11. The player-system dependency checks pass: no basketball resolution path reads a development projection or derived archetype, no player-system tunable appears as an anonymous literal in domain code, and no scene recalculates Overall, archetype, costs, caps, or projected peak.

## 19. Definition of architecture readiness

Implementation may advance beyond the foundation when:

- Domain, application, infrastructure, and presentation boundaries are enforced in code review and tests.
- Seeded headless simulation is reproducible.
- The match engine cannot mutate career law or persistence directly.
- Hub and narrative paths use application commands and projections.
- SQLite mobile proof, migration, recovery, and three-slot isolation pass.
- Scenes and signals remain presentation/orchestration mechanisms rather than state authorities.
- Headless unit, integration, simulation, persistence, and transition suites run reliably.
- Both mobile export paths are exercised continuously enough to catch native-addon and packaging failures early.

## 20. Reference implementation sources

The choices above are grounded in the current official Godot documentation for headless command-line execution, Resources, signals, worker tasks, and mobile export, plus the primary repositories for `godot-sqlite` and GdUnit4. Repository onboarding should pin exact versions rather than depending on a floating latest release.

- Godot command-line and headless execution: <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
- Godot Resources: <https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html>
- Godot signals: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>
- Godot worker thread pool: <https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html>
- Godot iOS export: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html>
- Godot Android export: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html>
- `godot-sqlite` primary repository: <https://github.com/2shady4u/godot-sqlite>
- GdUnit4 primary repository: <https://github.com/godot-gdunit-labs/gdUnit4>
