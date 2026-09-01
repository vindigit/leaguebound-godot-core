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

### Toolchain setup

`tools/install_godot.sh` installs the pinned Godot 4.7.1-stable build on Linux and verifies the download against the SHA-512 digest the Godot project publishes for that release. A digest mismatch discards the archive and installs nothing. The script is idempotent and prints the installed binary's path.

**The project must be imported before any script is run.** Godot resolves `class_name` identifiers from `.godot/global_script_class_cache.cfg`, and only the importer writes that file. On a fresh clone it does not exist, so `godot --script` treats every global class as an undeclared identifier and each typed script fails to parse under the warnings-as-errors settings in `project.godot`. The resulting wall of parse errors is a missing cache, not a broken engine build:

```bash
godot --headless --path . --import
```

`tools/run_checks.sh` does all of this — resolve or install the pinned binary, import, then run the gated checks in CI order. It is the single entry point used by CI and by managed sessions:

```bash
tools/run_checks.sh                    # import, parse, acceptance, smoke, calibration, gdunit
tools/run_checks.sh acceptance gdunit  # a subset; the import always runs first
```

Set `GODOT_BIN` to use an already-installed binary instead of the one `tools/install_godot.sh` manages.

In Claude Code on the web, `.claude/hooks/session-start.sh` runs both steps at session start and exports `GODOT_BIN`, so a session begins with a verified engine and a populated class cache.

### Individual checks

From the repository root, after importing:

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

## Calibration

`calibration/` holds the committed calibration harness. Every runner writes a machine-readable report to `reports/` and prints a human summary, and every report carries the same provenance block: commit SHA, Godot version and build mode, rules and balance profile with versions, RNG algorithm and stream-key version, seed range, sample count, elapsed time and throughput. Every judged metric names its exact definition, its denominator, its interval where one applies, and the document section that owns its target.

Acceptance targets live in one place, `calibration/targets/calibration_targets.gd`. A runner cannot invent a band; it asks for one by name and gets the owning section with it.

```powershell
# All twenty attributes: monotonic direction, meaningful 50->80 effect, and the
# rule that an IQ rating cannot replace a primary skill.
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_attribute_sensitivity.gd -- --resolutions=100000

# Team and player basketball statistics against BALANCE_SPEC §14, per competition.
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_competition_calibration.gd -- --games=200

# The BALANCE_SPEC §8.4 locked career peak curve, projected-peak honesty, and
# user/NPC development parity.
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_career_progression.gd -- --careers=2000

# Where the engine spends its time, measured before any optimization.
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_performance_profile.gd -- --games=20
```

Sample size is always a command-line argument, and every report states the size it reached against the `BALANCE_SPEC.md` §27.1 certification requirement. A short run is reported as measured-but-not-certified; it can never be mistaken for a certification.

`BALANCE_SPEC.md` §32.1 records what the Stage 4 calibration actually established and what it did not. Read it before quoting any calibrated number as settled.

### Layered CI

| Workflow | When | What it covers |
| --- | --- | --- |
| `headless-tests.yml` | Every push and pull request | Unit tests, structural invariants, reconciliation, golden fixtures, Builder smoke portfolio, attribute sensitivity at full sample, and a small deterministic calibration smoke with broad control limits. |
| `nightly-calibration.yml` | Nightly and on demand | Sharded competition suites, sensitivity, Builder tournament, and the performance profile. |
| `deep-verification.yml` | Weekly and before release | The §27.1 minimum samples: sharded million-career progression and 100,000-game competition certification. |

The pull-request calibration smoke is a structural check, not a release certification. It exists to catch an event family that stopped firing; its control limits are the §14.1 bands deliberately widened, and it says so in its own output.

## Explicitly out of scope

- Personal Hub or other UI.
- Career calendar, recruiting, contracts, eligibility, or endings.
- World simulation.
- Persistence or save slots. `PlayerSystemMigration` defines the record-level schema migrations; no database backs them yet.
- Narrative systems.
- Content generation or ingestion pipelines.
- Analytics, ads, purchases, or platform SDKs.
- React Native, Expo, Zustand, IndexedDB, npm, or JavaScript runtime dependencies.
