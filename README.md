# LeagueBound Godot Core

LeagueBound is a single-player basketball career RPG for portrait-oriented iOS and Android devices.

This private repository is the new Godot 4.x runtime. The React Native/Expo application, TypeScript types, Zustand stores, IndexedDB persistence, and npm build pipeline are archived reference material only and are not part of the live stack.

## Technical baseline

- Engine: Godot 4.7.1-stable, pinned in local tooling and CI.
- Language: typed GDScript.
- Current runtime scope: pure basketball simulation core plus the player builder, ratings, and development domain.
- Execution: seeded, deterministic, and headless-friendly.
- Tests: project-owned headless acceptance runner plus GdUnit4 v6.2.0 (`d187702`).
- Platforms: iOS and Android, portrait only.

## Current implementation priority

The first vertical path is:

```text
immutable MatchInput
    -> deterministic multi-action possession state machine
    -> ordered domain events
    -> authoritative match-state reduction
    -> box-score projection
    -> regulation/overtime full-game result
```

The engine uses the canonical 20 public player attributes, validates active named-player ratings from 25 through 99, receives randomness explicitly, and reproduces results from the same input and seed.

## Match engine

A possession is a chain of actions, not a single roll. `PossessionEngine` implements the `SIMULATION_SPEC.md` §9 state machine — inbound, advance or transition, half-court entry, action selection and execution, advantage, foul, shot, free throw, rebound, putback, and possession end — over the eleven §10.1 action families.

Four contracts hold the design together:

- **One reduction.** `MatchStateReducer` is the only thing that writes match state, and the possession engine folds its own events onto its working snapshot with that same function. The state it decides from and the state the ledger produces cannot diverge, so a substituted or fouled-out player cannot keep playing.
- **Runtime lineups are authority.** `TeamMatchState` owns who is on court. Nothing reads the static starter list to decide participation.
- **Possession identity.** Every possession emits one start and one terminal end, carries a stable id and action sequence, and an offensive rebound continues it — same id, no new start, no extra team possession, and the rule profile's own shot-clock reset. `POSSESSION_ENDED.team_id` is the offence that ended; the next team travels in its own field.
- **One capability table.** `CapabilityCalculator` owns the §7 derived capabilities using the `BALANCE_SPEC.md` §5.2 weights held by `RatingsProfile`. No resolver re-derives a rating weight, and no capability reads an identity layer.

`MatchSession` is the single stepped session behind Play, Sim, and Skip. Because each possession derives its random stream from the match identity and possession sequence rather than from the caller's consumption order, stepping and running straight through produce byte-identical ledgers.

Every match-resolution constant lives in `SimulationBalanceProfile` or `CompetitionRuleProfile` as a named tunable with a unit and a safe range. Tactical role's entire numeric privilege is `RoleOpportunityTable`.

The simulation domain is independent of scenes, Nodes, frame timing, rendering, persistence, autoloads, wall-clock time, global randomness, and platform services.

## Design authority

The locked LeagueBound design documents remain authoritative:

- `GODOT_TDD.md` is the current technical implementation authority.
- `SIMULATION_SPEC.md` defines basketball resolution and match-output contracts.
- `BALANCE_SPEC.md` owns numeric weights, curves, bounds, calibration targets, and tolerances.
- The conflict hierarchy declared in `GODOT_TDD.md` applies.

The archived `TDD.md` and React Native/Expo codebase must not be treated as live architecture.

## Current boundaries

Current implementation belongs under:

```text
src/domain/shared/
src/domain/basketball/
src/application/commands/
src/application/queries/
tests/unit/
tests/simulation/
tools/
```

Career systems, world simulation, economy, persistence, presentation, scenes, the Personal Hub, narrative integration, recruiting, and content pipelines are outside this milestone.

## Player development domain

One canonical implementation supplies the Builder, the match engine, NPC development, and every simulation tier:

- `OverallCalculator` — the only role-neutral Overall formula.
- `ProjectedPeakCalculator` and `DevelopmentProjection` — Current Overall, Maximum Potential, and Projected Peak as three distinct values, the last always a range.
- `AttributeCostTable` — the universal destination-rating cost table, shared by the user and every NPC executor.
- `CapGenerator`, `BodyMaturationPlanner` — deterministic exact caps and body growth from the versioned career seed.
- `DerivedArchetype` — a read-only descriptor that grants nothing.

Two rules are enforced by automated checks rather than convention: no resolution path reads Current Overall, Maximum Potential, Projected Peak, or a derived archetype; and no scene recalculates any of them, or costs, caps, or projected body range. Presentation consumes `DevelopmentProjectionQuery` projections and renders them as received.

The match engine consumes structurally valid match inputs. It never creates or changes membership, contracts, signing rights, assignments, eligibility, import classification, awards, progression, or save data.

## Determinism rules

- Domain code never calls global `randf`, `randi`, or `randomize`.
- Every random decision uses an injected, versioned `RandomSource`.
- Child streams derive from stable identities and labels.
- Canonical iteration order is established before randomness is consumed.
- Presentation speed, frame rate, retries, and future Play/Sim/Skip selection cannot reroll committed outcomes.
- Ordered domain events are the only source of score and statistic changes.

## Headless verification

From the repository root:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_all.gd
```

The acceptance runner covers random-stream reproducibility, the canonical attribute domain, possession determinism, the Stage 3 possession contract, committed golden ledgers, Play/Sim parity, event/stat reconciliation, match invariants, seeded full-game reproduction, balance-configuration integrity, creation-budget exhaustion, development-value ordering, detail-promotion invariance, and body-growth determinism.

Committed golden ledger hashes live in `tests/golden/match_golden_hashes.json` and cover regulation, overtime, offensive-rebound continuation, foul and free throw, substitution and foul-out, and late-game scenarios. Each scenario is verified to still exercise the behaviour it is named for, so a golden hash cannot keep passing while covering nothing. Regenerate deliberately after an intended engine or balance change:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/golden_ledger_harness.gd
```

A fixed-seed smoke run reports team-level metrics and fails on invariant violations. Statistical bands are diagnostic only until the balance pass:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/simulation_smoke.gd
```

Every script must also parse under the project's warnings-as-errors configuration:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/parse_check.gd
```

The full GdUnit4 suite:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests
```

The Builder calibration harness sweeps 810 completed builds from fixed seeds and fails if the distribution leaves the owner-locked `BALANCE_SPEC.md` §7.3.2 bands. It writes a machine-readable report to `reports/builder_calibration.json`:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tools/builder_calibration_harness.gd
```

## Explicitly out of scope

- Personal Hub or other UI.
- Career calendar, recruiting, contracts, eligibility, or endings.
- World simulation.
- Persistence or save slots. `PlayerSystemMigration` defines the record-level schema migrations; no database backs them yet.
- Narrative systems.
- Content generation or ingestion pipelines.
- Analytics, ads, purchases, or platform SDKs.
- React Native, Expo, Zustand, IndexedDB, npm, or JavaScript runtime dependencies.
