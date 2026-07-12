# Architecture & Design Document

**Project:** Structured training app for running & cycling (working name: TrainingApp)
**Status:** Phase A + Phase C0/C1 implemented; Phase B (Xcode + hardware) pending Mac access
**Last updated:** 2026-07-12
**Related docs:** `workout-app-mvp-spec.md` (requirements), `workout-app-implementation-plan.md` (phasing), `mapping-table.md` (format matrix), `workout-app-vs-intervals-icu.md` (competitive scope)

---

## 1. Purpose & scope

A native iOS + Apple Watch app for a self-coached endurance athlete to build
structured workouts, schedule them, execute them on Apple Watch or a Garmin/
Karoo head unit, auto-match completed activities back to the plan, and track &
project fitness (CTL/ATL/TSB) through planned workouts. Personal-tool-first;
data model designed as if `users > 1` but features built for `users = 1`.

Full requirements are in `workout-app-mvp-spec.md`. This document explains **how
the code is structured and why**, so a new engineer (or a future session) can
navigate and extend it safely.

---

## 2. Guiding architectural principle

> **All logic lives in platform-independent, unit-tested Swift packages. Apple
> frameworks (HealthKit, WorkoutKit, SwiftUI, SwiftData) are thin adapters at
> the edge, behind protocols.**

This is the single most important decision and everything else follows from it.
Consequences:

- The entire engine — domain model, fitness math, FIT binary format, WorkoutKit
  *mapping*, matching/dedup — compiles and tests on Linux with no Apple SDK.
  That is what allowed ~4,600 lines and 156 tests to be built and verified
  before a Mac was available.
- A bug in the app is almost always a **UI/wiring bug** in `App/`, not a logic
  bug — the logic is covered by tests. This bounds where to look when something
  breaks on device.
- Swapping or adding a platform (an Android port, a CLI, a future macOS
  companion) reuses every package unchanged; only the adapter layer is rewritten.

---

## 3. Module map

```
TrainingApp/                     Swift package (SwiftPM)
├── Sources/
│   ├── TrainingCore/    (1182 loc)  Domain model + all training math + WorkoutKit mapping
│   ├── TrainingFIT/     ( 734 loc)  FIT binary encode/decode (Garmin/Karoo/Zwift)
│   ├── TrainingSync/    ( 224 loc)  Matching, duplicate detection, Watch sync window
│   ├── TrainingAppCore/ ( 441 loc)  TrainingAppModel: the app's root logic behind protocol seams
│   └── demo/                        Executable: end-to-end pipeline, runnable headless
├── Tests/                            156 tests mirroring the four library targets
└── App/                 (1086 loc)  SwiftUI views + HealthKit/WorkoutKit adapters — UNVERIFIED (no Xcode yet)
```

Dependency direction (arrows point "depends on"):

```
        App  ──────────────┐
         │                 │
         ▼                 ▼
   TrainingAppCore ──► TrainingFIT ──► TrainingCore
         │           TrainingSync ──►──┘
         └────────────────────────────►
```

`TrainingCore` depends on nothing but Foundation. Everything depends inward
toward it. `App` is the only target that imports Apple UI/health frameworks.

---

## 4. Layer-by-layer design

### 4.1 TrainingCore — domain model + math

The pure heart. Value types only, all `Codable`+`Sendable`, no reference
semantics, no I/O.

**Domain model (`Workout.swift`, `Planning.swift`, `Activity.swift`, `Thresholds.swift`, `Zones.swift`):**

- `WorkoutTemplate` → `[WorkoutItem]` where an item is `.step(Step)` or
  `.repeatBlock(RepeatBlock)`. **Single-level repeats are enforced by the type
  system** — a `RepeatBlock` contains `[Step]`, not `[WorkoutItem]`, so nesting
  is unrepresentable. This matches what both WorkoutKit and FIT can express.
- `Step` = role + `StepLength` (`.time`/`.distance`/`.open`) + optional
  `IntensityTarget`. Targets carry a `reference` (`.absolute` / `.percentOfThreshold`
  / `.zone`) so a workout stays valid as thresholds change over time.
- `ThresholdStore` holds **dated** `ThresholdRecord`s. Every load/target
  calculation resolves the threshold *valid on the activity's date* — a January
  ride is always scored against January's FTP. This is the subtlety that makes
  the fitness history honest, and it is pervasive: never resolve a threshold
  without a date.
- `PlannedWorkout` holds a **snapshot** of the template at scheduling time plus
  a `templateID` and `detachedFromTemplate` flag. Editing a template never
  silently rewrites history (see §5.1).
- `Activity` carries both `movingSeconds` and `elapsedSeconds` (wall-clock),
  and `externalIDs: [String]` (plural — see §5.2), plus a `Sample` series.

**Training math (`Load.swift`, `WorkoutEstimate.swift`, `PMC.swift`, `Aggregation.swift`):**

- `LoadCalculator` computes training load with a documented **fallback chain**:
  power TSS → HR TSS → pace TSS → RPE → duration×default-IF. Every method shares
  one shape, `hours × IF² × 100` (`LoadCalculator.trainingLoad`), so historical
  and estimated loads are directly comparable.
- `WorkoutEstimator` prices a workout's steps into `{load, durationSeconds,
  zoneSeconds, hasEstimate}` — this is both the builder's live preview and the
  input to projection.
- `PMCEngine` is the Banister/Coggan impulse-response model: `x_t = x_{t-1}·e^(−1/τ)
  + load_t·(1−e^(−1/τ))`, τ = 42 (CTL) / 7 (ATL), TSB = yesterday's CTL−ATL.
  **Projection is not a separate code path** — it is the same recursion fed with
  *planned* loads for future days. A test asserts a continuous series equals one
  split into "actual + planned", which is the property that makes the projection
  trustworthy.
- `Aggregation` = weekly totals, time-in-zone from samples (with a gap clamp so
  pauses don't inflate zones), and the ramp-rate guard.

**Mapping (`WorkoutKitMapping.swift`):** pure mirror types (`MappedWorkout`,
`MappedIntervalBlock`, `MappedStep`, `MappedGoal`, `MappedAlert`) shaped exactly
like WorkoutKit's `CustomWorkout` tree, plus `MappingNote`s recording every
lossy degradation (RPE has no device alert, unresolvable target, top-zone
clamp). This lives in Core — and is fully tested — so the actual `import
WorkoutKit` adapter is a mechanical translation with no logic to get wrong.

### 4.2 TrainingFIT — the interchange format

Hand-rolled FIT binary (there is no official Swift SDK). Split into:

- `FITCore` — CRC-16, base types, the low-level record writer, file framing.
- `FITMessageReader` — a generic parser (both endians, developer fields,
  compressed-timestamp headers, **skips unknown messages/fields**) so decoders
  only pick the globals they understand and future FIT additions don't break us.
- `FITWorkoutEncoder` / `FITWorkoutDecoder` — structured-workout export/import.
  Encoder+decoder are cross-checked by round-trip tests.
- `FITActivityDecoder` — completed-activity files → `Activity` (+ samples).
  Rejects multi-session/brick files loudly rather than mis-decoding.

The design rule from the spec — *the internal model must export losslessly to
both WorkoutKit and FIT* — is enforced here and in `WorkoutKitMapping`, with the
matrix documented in `docs/mapping-table.md`.

### 4.3 TrainingSync — reconciliation

Three independent, stateless engines:

- `MatchingEngine` — greedy best-first match of activities to planned workouts:
  same sport, within ±1 day, same-day preferred then closest duration. Respects
  user-pinned matches. Emits coarse compliance (`completed`/`substituted`/
  `missed`/`unplanned`) — API shaped so per-step interval-detection compliance
  slots in post-MVP without changing callers.
- `DuplicateDetector` — union-find grouping of the same session arriving via
  multiple sources (shared external ID, or sport + start proximity + duration
  similarity); merge keeps the richest recording and **unions external IDs** so
  re-import stays idempotent.
- `SyncWindow` — selects the nearest ≤15 upcoming uncompleted workouts (Apple's
  cap) with stable ordering, and diffs against what's on the Watch.

### 4.4 TrainingAppCore — the application model

`TrainingAppModel` is the single object every screen talks to. It owns an
`AppState` (one `Codable` struct: templates, planned, activities, thresholds,
zones, events) and orchestrates the engines above. Key seams:

- `Persistence` (protocol) — `InMemoryPersistence` for tests, `JSONFilePersistence`
  for the app. `save` **throws**; the model exposes `lastSaveError` so a full
  disk surfaces instead of silently dropping edits.
- `ActivityProvider` (protocol) — HealthKit stand-in; fakes in tests.
- `WorkoutScheduler` (protocol) — WorkoutKit stand-in; fakes in tests.

Everything the app *does* — library CRUD, scheduling, week summaries, ingest +
dedup + match, Watch sync planning, PMC/projection queries — is a method here,
and every method is tested on Linux.

### 4.5 App — the unverified edge

SwiftUI screens (`CalendarScreen`, `LibraryScreen`, `WorkoutBuilderView`,
`DashboardScreen`, `ProfileScreen`) + `AppModelObservable` (a logic-free
`ObservableObject` republishing the model's `onChange`) + the two real adapters
(`HealthKitActivityProvider`, `WorkoutKitScheduler`). **Not compiled** — no
Xcode in the build environment. Reviewed by reading; see `App/README.md` for
the four highest-risk items to verify on device.

---

## 5. Key design decisions & their rationale

### 5.1 Template vs instance (edit semantics)
Scheduling snapshots the template. `updateTemplate(_, propagateToFutureInstances:)`
touches only **future, non-detached** instances; past instances are immutable
history and detached instances keep their own content. Rationale: a fitness
chart built on top of workouts that silently changed under it would be a lie.

### 5.2 `externalIDs` is a set, not a scalar
Merging duplicates unions the IDs of every copy, so re-importing *any* source
copy of a merged activity still resolves to the merged record. A scalar would
re-duplicate on the next import — the exact bug the C0b review caught.

### 5.3 Dated thresholds everywhere
Load and target resolution are always `(sport, kind, on: date)`. This is the
recurring invariant; violating it corrupts history retroactively.

### 5.4 Projection = same math, planned inputs
No separate forecasting engine. Future days feed the PMC recursion with workout
estimates. Keeps one source of truth and makes "if you follow this plan…"
provably consistent with "what actually happened."

### 5.5 Mirror types for WorkoutKit
Rather than `#if canImport(WorkoutKit)` scattered through logic, the mapping
produces plain Swift mirror types in Core (tested), and one adapter translates
them. The Apple API surface — which shifts across betas — is isolated to ~60
lines.

### 5.6 Local-first persistence
A single JSON snapshot (atomic write). No server (spec: personal tool, no
backend). CloudKit backup is a future `Persistence` conformance, gated on paid
Apple Developer enrollment. Trivially inspectable and exportable (GDPR).

---

## 6. Data flow: the core loop

```
Build (WorkoutBuilderView → addTemplate)
  → Schedule (CalendarScreen → schedule → PlannedWorkout snapshot)
    → Sync   (applySync → SyncWindow → WorkoutKitMapper → WorkoutKitScheduler → Watch)
    → Export (exportFIT → FITWorkoutEncoder → Garmin/Karoo)
  → Execute (on device)
    → Ingest (refreshActivities → HealthKit / importFITActivity → FITActivityDecoder)
      → Dedup (DuplicateDetector)
      → Match (MatchingEngine, ±1 day → compliance)
        → Fitness (LoadCalculator → PMCEngine → chart + projection → race-day form)
```

Every arrow except the two device hops (Watch execution, head-unit execution)
is exercised headless by `Sources/demo`.

---

## 7. Testing strategy

- **156 tests**, TDD (red first) across the four library targets: TrainingCore
  86, TrainingFIT 27, TrainingSync 26, TrainingAppCore 17.
- Property/oracle tests where they matter: PMC constant-load convergence,
  projection-equals-actuals, FIT encode↔decode round-trip.
- **Linux runner** (`scripts/test-linux.sh`) exists because the environment's
  nixpkgs Swift 5.8 lacks `libIndexStore` (SwiftPM test discovery). It compiles
  generated XCTMain entry points. On Mac/CI, plain `swift test` is used instead;
  CI runs on the official `swift:6.1` image (`.github/workflows/swift-tests.yml`).
- `App/` has **zero automated coverage** by necessity — the guardrail is that it
  contains no logic.

---

## 8. Known limitations & deferred scope

- **Not built until Mac-day:** the Xcode project, app target/entitlements, the
  real on-device behavior of both adapters.
- **Post-MVP (spec §9):** per-step compliance via interval detection, HealthKit
  wellness panel, natural-language/text workout entry, inbound Garmin/Strava
  sync, auto FTP estimation, multi-week plan templates, ramps, `.zwo`/`.mrc`.
- **Single-athlete assumptions:** no accounts, no coach↔athlete, no sharing.
- **iOS/watchOS only:** no Android, no web planner (conscious scope cut vs
  Intervals.icu — see the gap analysis doc).

---

## 9. Where to make common changes

| I want to… | Touch |
|---|---|
| Add a target type / step kind | `TrainingCore/Workout.swift` (+ resolution, + FIT/WorkoutKit mapping, + tests) |
| Change how load is computed | `TrainingCore/Load.swift` (one function; keep the shared shape) |
| Support a new device format | new decoder/encoder in `TrainingFIT`, reuse `FITMessageReader` |
| Change matching rules | `TrainingSync/MatchingEngine.swift` |
| Add an app action/screen | method on `TrainingAppModel` (+ test), then a view in `App/` |
| Add real cloud backup | new `Persistence` conformance in `App/` |
