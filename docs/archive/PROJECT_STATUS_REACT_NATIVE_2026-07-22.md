> [!WARNING]
> **ARCHIVED HISTORICAL SNAPSHOT — SUPERSEDED**
>
> This document describes the retired React Native/Expo implementation as inspected on July 22, 2026. It is not current implementation evidence or authority for LeagueBound Godot Core. Do not execute its TypeScript, Jest, Zustand, AsyncStorage, npm, Ink, React Native, Expo, application-shell, persistence, or repair instructions against the Godot repository. Current status is maintained in the repository-root `PROJECT_STATUS.md`.

# LeagueBound Project Status

| Field | Value |
| --- | --- |
| Snapshot date | July 22, 2026 |
| Active product documents | `GDD.md`, `PRD.md`, `TDD.md`, `SIMULATION_SPEC.md`, `BALANCE_SPEC.md`, and `CONTENT_BIBLE.md` |
| Current delivery gate | **Gate 0 — Stabilized foundation** |
| Gate status | **Not met** |
| Active application | Repository root `leaguebound-fresh` |
| Archived reference | `LeagueBoundRPG/` |

## 1. Executive Status

LeagueBound is a functional but unstable preproduction vertical slice. The repository contains valuable builder, simulation, key-moment, persistence, and early career-loop work. It does not yet implement the locked version 1.0 product described by `GDD.md` and `PRD.md`.

The current priority is stabilization and schema alignment—not expanding into more career phases or content. Strict TypeScript fails, match integration tests rely on a removed store API, the full suite is not reliably green, and the development application clears saved career state on launch.

The repository now also contains a verified content-production foundation: strict schemas, complete generation planning, prompt packs, draft/approval provenance, graph and originality checks, launch coverage accounting, and deterministic approved-only export. This makes controlled drafting possible in parallel; it does not authorize runtime import or imply that the launch catalog exists.

The project should not be deleted or restarted wholesale. The builder and core simulation work have evidence-backed value. The application shell, career architecture, save model, and presentation require substantial redesign around the locked Personal Hub product.

## 2. Methodology

Status is assigned from active code paths, automated tests, and direct verification in the root application. A type, constant, mock, or test fixture does not count as implemented unless the feature is connected to an active user flow or is explicitly classified as foundation work.

This snapshot includes the current working tree, which contains pre-existing uncommitted career and UI changes. Those changes were inspected but not modified while producing this report.

Status labels mean:

- **Verified foundation:** Implemented code with passing focused automated coverage, but not necessarily compliant with the final PRD.
- **Partial:** A real path or model exists but does not satisfy the end-to-end requirement.
- **Rebuild required:** Existing work conflicts materially with the locked design or production architecture.
- **Not started:** No active end-to-end implementation was found.
- **Blocked:** A prerequisite failure prevents the associated delivery gate from passing.

## 3. Verification Baseline

### 3.1 Automated verification

| Check | Result | Evidence |
| --- | --- | --- |
| Test discovery | 61 test files found | `npx jest --listTests` |
| Builder group | **Pass:** 9/9 suites, 39/39 tests | `npm run test:builder -- --silent` |
| Career-store group | **Pass:** 9/9 suites, 47/47 tests | `npm run test:career-store -- --silent` |
| Match-engine group | **Fail:** 10/12 suites, 53/64 tests pass | `npm run test:match-engine -- --silent` |
| Key-moment group | **Fail:** 6/8 suites, 29/44 tests pass | `npm run test:key-moments -- --silent` |
| Strict TypeScript | **Fail** | `npx tsc --noEmit --pretty false` |
| Content pipeline | **Pass:** 1 suite, 9/9 tests; isolated ingest/promotion/export passes | `npm run typecheck:content`, `npm run test:content`, `npm run content:check` |
| Full Jest invocation | **Unreliable:** did not complete during the diagnostic window | `npm test -- --runInBand` was terminated without a valid summary |

The focused groups overlap and must not be added together as a repository-wide pass count.

### 3.2 Primary failures

Match and key-moment failures share a clear integration cause: several tests still call `useMatchStore.getState().initializeMatch(...)`, but the active `MatchStore` no longer exposes that function. This creates both runtime test failures and TypeScript errors.

Strict TypeScript also reports drift in:

- Player-card fixtures and public attribute shapes.
- High-school schedule window types.
- Recruiting arithmetic.
- Optional box-score fields.
- Match work-rate and focus types.
- Key-moment context bands and leverage.
- Career-store selector input shapes.
- Readonly team fixtures.
- Rating-brand types in simulation tests.
- Builder classification and badge fixtures.

These failures show multiple evolving contracts without one canonical schema.

### 3.3 Production entry blocker

`App.tsx` currently declares `DEV_RESET_ON_LAUNCH = true` and clears persisted career storage during development startup. This is useful for temporary iteration but prevents meaningful persistence testing and must be removed from the normal entry path before Gate 0 can pass.

## 4. Verified Foundations

### 4.1 Builder and player-model foundation

The repository contains working allocation, caps, presets, classification, derived ratings, role tendencies, public attributes, progression, badge resolution, and simulation projection modules.

Evidence:

- `src/builder/allocate.ts`
- `src/builder/caps.ts`
- `src/builder/classify.ts`
- `src/builder/derivedRatings.ts`
- `src/builder/publicAttributes.ts`
- `src/builder/progression.ts`
- `src/builder/roleTendencies.ts`
- `src/builder/archetypeSimContracts.ts`
- Focused builder verification: 9 suites and 39 tests passing.

Assessment: **Verified foundation.** It must still be reconciled with the final 20-attribute builder, exact-cap presentation, permanent allocation, and 16-badge catalog in the PRD.

### 4.2 Core match simulation

The repository contains a real possession-based engine, adapter, tuning validation, team/player fixtures, box-score accounting, momentum, home-court tuning, badge effects, and play-by-play rendering.

Evidence:

- `src/matchEngine.ts`
- `src/matchEngineAdapter.ts`
- `src/matchEngineTuning.js`
- `src/matchEngineTuningValidation.ts`
- `src/features/match/store/useMatchEngineStore.ts`
- `src/match/playByPlay/renderer.ts`
- 10 of 12 focused match-engine suites pass.

Assessment: **Verified foundation with broken integration contract.** The engine is worth retaining and calibrating; the match-store boundary and presentation path require repair.

### 4.3 Key moments and action challenges

Scheduling, contextual choice generation, offensive and defensive moment types, execution scoring, resolution, log composition, and UI components exist.

Evidence:

- `src/match/keyMoments/`
- `src/features/match/components/ActionChallengeRenderer.tsx`
- `src/features/match/components/KeyMomentOverlay.tsx`
- `src/features/match/screens/MatchScreen.tsx`
- 6 of 8 focused key-moment suites pass.
- Full-match smoke and MatchScreen key-moment integration tests pass in the focused group.

Assessment: **Partial.** The underlying system is substantial, but tests and store integration are inconsistent and the active presentation is not the locked portrait top-down court.

### 4.4 Career state and persistence foundation

The career store persists through Zustand and AsyncStorage, includes migration logic, supports builder-to-career handoff, and models multiple career concepts.

Evidence:

- `src/store/useCareerStore.ts`
- `src/types/career.ts`
- `src/types/careerProgression.ts`
- Focused career-store verification: 9 suites and 47 tests passing.

Assessment: **Verified single-career foundation.** It does not provide three independent save slots, transaction-safe outcome commits, checkpoint recovery, unlock provenance, or production-safe startup behavior.

### 4.5 Early career loop

The active state contains a four-match middle-school tournament, school-path selection, weekly action capacity, early eligibility/GPA concepts, recruiting interest and offers, finance entries, role tags, and a high-school season schedule generator.

Evidence:

- `src/features/career/highSchoolSeason.ts`
- `src/features/career/recruiting.ts`
- `src/features/career/weeklyActions.ts`
- `src/features/career/screens/SchoolPathSelectionScreen.tsx`
- `src/screens/HomeScreen.tsx`
- `src/store/useCareerStore.ts`

Assessment: **Partial and currently under active modification.** The high-school schedule and recruiting path are included in current TypeScript failures, and the end-to-end four-season high-school career is not demonstrated.

### 4.6 Narrative bridge

Ink can load an authored scene, display lines and choices, interpret action tags, and write results to career state.

Evidence:

- `src/narrative/inkManager.ts`
- `src/components/NarrativeOverlay.tsx`
- `src/narrative/practice_coach.ink`
- `src/narrative/assets/practice_coach.json`

Assessment: **Foundation only.** One practice scene does not satisfy the event scheduler, causality, cooldown, repetition, relationship, or launch content requirements.

### 4.7 Content production pipeline

The repository now has a standalone, provider-neutral authoring system under `content/` with 24 content families, strict JSON Schema 2020-12 contracts, controlled effects and badge hooks, owner-decision manifests, a 150-batch production plan, 16 ready prompt packs, hostile-input screening, draft/source receipts, human and specialist promotion gates, graph validation, similarity screening, coverage reports, and content-addressed exports.

Evidence:

- `CONTENT_BIBLE.md`
- `content/README.md`
- `content/schemas/`
- `content/manifests/`
- `scripts/content/`
- `test/contentTooling.test.ts`
- `npm run typecheck:content`: pass.
- `npm run test:content`: 9/9 pass, including isolated end-to-end ingest, promotion, and export.
- `npm run content:check`: pass with expected in-progress coverage notices.

Assessment: **Verified production foundation; catalog empty by design.** Five owner decisions remain open, generated content has not yet been reviewed, production assets do not exist, and badge hooks remain planned until the canonical 20-attribute migration. No content export is connected to the current runtime.

## 5. Rebuild Required

### 5.1 Application shell and Personal Hub

The active `HomeScreen` is a dense dashboard and modal-driven shell. It is not the layered 2.5D Personal Hub defined by the GDD.

Required replacement:

- Save-slot entry and resume behavior.
- Freshman bedroom and phase-appropriate residence scenes.
- Layered background, midground, foreground, lighting, animation, and parallax.
- Physical object state and accessible hotspots.
- Four-level notification priority.
- Stable access to phone, schedule, training, career history, records, and appearance.

Status: **Rebuild required.** No production Personal Hub implementation exists.

### 5.2 Played-game presentation

The existing match flow uses simulation screens, logs, overlays, and action challenges. It does not provide the locked portrait top-down full court with vertical play direction and automatic movement representation.

Status: **Rebuild presentation; retain engine concepts.** The engine and contextual moments can support the new court after contract stabilization.

### 5.3 Canonical domain architecture

Player, builder, career, team, match, key-moment, schedule, and test fixtures currently expose incompatible generations of the same concepts.

Status: **Rebuild boundary required.** Gate 0 needs one canonical schema and explicit adapters rather than additional casts and duplicated type families.

## 6. Partial PRD Coverage

| Product area | Current evidence | Status |
| --- | --- | --- |
| Player creation | Active backstory/builder flow and strong builder modules | Partial; not final locked builder UX |
| Optional prologue | Four-match tournament state exists | Partial; not confirmed skippable hybrid onboarding flow |
| Weekly loop | Action slots and advancement logic exist | Partial; not full dynamic capacity/interrupt model |
| High-school schedule | Generator and role tags exist | Partial; current type failure and no proven four-season completion |
| Recruiting/offers | Interest, offer generation, and school selection exist | Partial; current type failure and incomplete risk/advisor model |
| Academics | GPA and eligibility fields/actions exist | Partial |
| Finances | Balance/ledger concepts exist | Partial |
| Injury | Minor ankle-sprain consequence exists | Placeholder relative to 30-family system |
| Relationships | Basic types and state exist | Partial; not the locked multidimensional life system |
| Match simulation | Substantial engine and focused passing tests | Partial; integration contract broken |
| Key moments | Substantial scheduler/resolution/challenge work | Partial; integration contract broken |
| Persistence | One persisted Zustand career with migration | Partial; no slots or transactional autosave |
| News/feed | Hometown and postgame items exist | Legacy presentation; not the authored social/phone system |

## 7. Not Started End to End

No active version 1.0-complete implementation was found for:

- Three independent career save slots.
- Transaction-safe autosave checkpoints and permanent major-outcome commits.
- The layered 2.5D Personal Hub.
- Manual modular avatar customization and generated expressive NPC portraits.
- The complete 128-organization fixed later-level world, generated active-state high-school structure, and lightweight national school pool.
- Tier A/B/C persistent world simulation.
- Full configurable rosters, rotations, staff identities, team chemistry, and history.
- Four complete high-school seasons and summer circuits.
- Full college schedules, eligibility, redshirts, hardship, transfers, and draft evaluation.
- Complete domestic development and overseas pathways.
- An 82-game professional league, play-in, four playoff rounds, contracts, rights, trades, and roster-interest endings.
- The final Attribute Point economy, training storage, aging, mileage, and cap-change system.
- The locked 16-badge catalog and paid badge respec.
- Thirty injury families and meaningful treatment choices.
- The complete reputation, follower, fictional social, NIL, advisor, and agent loops.
- Houses, cars, recurring living costs, and the simple investment fund as complete systems.
- Full relationship, romance, family, rival, friend, and mentor event coverage.
- Career-ending prison, death, Second Chance, retirement, and legacy-summary flows.
- Production ads, purchases, restore, account entitlements, and offline ad handling.
- Launch accessibility settings and hybrid onboarding/glossary.
- App-store privacy, age-rating, reviewer, and submission readiness.
- Required performance, save, and 25-season soak verification.

## 8. Delivery Gate Assessment

| Gate | Status | Reason |
| --- | --- | --- |
| Gate 0 — Stabilized foundation | **Not met** | TypeScript fails; match/key-moment tests fail; full suite is unreliable; dev launch clears persistence; canonical schemas are not settled. |
| Gate 1 — Freshman vertical slice | **Not met** | Several ingredients exist, but no save slots, 2.5D Hub, portrait court, production autosave, or complete PRD-conforming freshman flow. |
| Gate 2 — Complete high-school career | **Not met** | Early high-school work exists but four-season, summer, NIL, transfer, and pathway completion are not proven. |
| Gate 3 — College and alternatives | **Not met** | Mostly type scaffolding and generic schedule/state branches. |
| Gate 4 — Professional career and ending | **Not met** | No complete professional ecosystem or ending pipeline. |
| Gate 5 — Content-complete alpha | **Not met** | Launch organization and content floors are absent. |
| Gate 6 — Monetized beta | **Not met** | Ads, purchases, compliance, accessibility, and physical-device budgets are absent. |
| Gate 7 — Release candidate | **Not met** | Prior gates and release blockers remain open. |

## 9. Gate 0 Work Queue

Work should proceed in this order unless new evidence changes the dependency:

1. Disable destructive development reset from ordinary app startup and replace it with an explicit developer-only reset action.
2. Select canonical `Player`, 20-attribute, rating, `Team`, `Career`, `SeasonSchedule`, `Match`, and key-moment contracts.
3. Repair or intentionally migrate the `useMatchStore.initializeMatch` boundary across runtime and tests.
4. Fix all strict TypeScript errors without broad `any` casts or weakening strict mode.
5. Make all 61 discovered test files finish reliably from one clean command.
6. Add a clean-checkout verification command covering typecheck, tests, and deterministic simulation fixtures.
7. Document current save schema/version, migration fixtures, and the transition path to three slots and transactional commits.
8. Decide the architecture seam between the authoritative engine, match presentation, career orchestration, and future tiered world simulation.
9. Update this status report with command evidence after Gate 0 passes.

Feature expansion into college, professional, monetization, runtime content import, or mass final content approval should not precede items 1–6. Controlled draft generation may proceed through the isolated content pipeline because it cannot mutate runtime code or self-approve canon.

## 10. Immediate Risks

### Schema drift

The same concepts are represented by incompatible runtime, builder, and test types. Additional features will multiply repair cost until one canonical model is chosen.

### Monolithic career store

`useCareerStore.ts` currently owns a broad and growing set of responsibilities. Extending it directly to the full world, multiple slots, transactions, content scheduling, and purchases would increase migration and corruption risk.

### False confidence from focused green tests

Builder and career-store groups pass, but strict compilation and match integration do not. Passing isolated suites must not be interpreted as a shippable vertical slice.

### Presentation replacement cost

The current dashboard UI is not a skin away from the locked Personal Hub. Production planning must treat the Hub and portrait court as new experience surfaces while deliberately reusing stable logic underneath.

### Scope sequencing

The locked version 1.0 is large. The delivery gates in `PRD.md` are mandatory scope-control tools; implementing scattered late-career systems before the freshman slice is production-safe will create disconnected scaffolding.

## 11. Status Maintenance Rules

- Update this file only from code and verification evidence.
- Do not use roadmap intent as implementation status.
- Do not count archived `LeagueBoundRPG/` code.
- Record exact commands and outcomes for Gate 0 and release gates.
- Mark a gate met only when every listed outcome in `PRD.md` has evidence.
- Link future issue trackers or milestone documents rather than expanding this file into another design specification.
