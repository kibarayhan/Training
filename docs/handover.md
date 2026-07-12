# Handover Document

**Project:** Structured training app for running & cycling
**Branch:** `claude/workout-app-market-research-9e5j2n`
**Handover date:** 2026-07-12
**From:** current build sessions (research → spec → Phase A engine → Phase C app layer)
**To:** whoever continues on a Mac (likely you, kibarayhan@gmail.com)

This document is the "pick it up cold" guide. Read `architecture-design.md`
alongside it for the *why*; this is the *what next and how*.

---

## 1. TL;DR — where we are

- A **complete, tested engine** for the app exists as four Swift packages
  (~2,600 loc, **156 passing tests**) plus a **written-but-uncompiled SwiftUI +
  Apple-adapter layer** (~1,100 loc).
- Everything that can be built and verified **without a Mac** is done. What
  remains genuinely needs Xcode and your devices.
- All work is committed and pushed to the branch above. Nothing is stashed or
  uncommitted.

**Current phase status** (from `workout-app-implementation-plan.md`):

| Phase | What | State |
|---|---|---|
| A1–A6 | Engine: domain, math, FIT, mapping, sync, demo, CI | ✅ done, tested |
| C0a | FIT workout **import** | ✅ done, tested |
| C0b | `TrainingAppModel` (app logic behind protocols) | ✅ done, tested |
| C1 | SwiftUI views + HealthKit/WorkoutKit adapters | ✅ written & reviewed, **not compiled** |
| **B** | **Xcode project + 2 hardware spikes** | ⏳ **your first job on Mac-day** |

---

## 2. Document map (read in this order)

1. `workout-app-market-research.md` — is this worth building? (feasible; niche)
2. `workout-app-discovery-questions.md` — all product decisions, with answers
3. `workout-app-mvp-spec.md` — **the requirements**, single source of truth
4. `workout-app-vs-intervals-icu.md` — what we deliberately don't build
5. `workout-app-implementation-plan.md` — the phased plan (A/B/C)
6. `architecture-design.md` — how the code is structured and why
7. `mapping-table.md` — internal ↔ WorkoutKit ↔ FIT format matrix
8. **this file** — how to continue

---

## 3. The product in three sentences

Build structured running/cycling workouts (warm-up, power/HR/pace/cadence
intervals, single-level repeats), schedule them on a calendar, push them to
Apple Watch (natively via WorkoutKit) and to Garmin/Karoo (via FIT export),
then auto-match completed activities back to the plan and track fitness
(CTL/ATL/TSB) with a projection through your planned workouts to race day.
It's an iPhone + Apple Watch app, personal-use-first. The differentiator vs
TrainingPeaks/Intervals.icu is being genuinely Apple-Watch-native.

---

## 4. What exists, concretely

```
TrainingApp/
├── Package.swift                 5 targets + 4 test targets
├── Sources/
│   ├── TrainingCore/             domain model + fitness math + WorkoutKit mapping  (86 tests)
│   ├── TrainingFIT/              FIT encode/decode                                 (27 tests)
│   ├── TrainingSync/             match / dedup / sync window                       (26 tests)
│   ├── TrainingAppCore/          TrainingAppModel — the app's brain                (17 tests)
│   └── demo/                     runnable end-to-end pipeline
├── App/                          SwiftUI + Apple adapters — UNVERIFIED, see App/README.md
├── scripts/test-linux.sh         Linux test runner (see §6)
├── swift-env.sh                  Linux Swift env setup
└── .github/workflows/            CI: swift test + demo on swift:6.1
```

Everything under `Sources/` and `Tests/` is **trusted** (compiled + tested).
Everything under `App/` is a **first draft** to compile and fix on device.

---

## 5. Your first day on a Mac (Phase B) — ordered checklist

**Prerequisites to have done before/at Mac-day** (from the plan's readiness list):
- [ ] Apple Developer Program enrolled ($99/yr) — needed for CloudKit and to
      avoid 7-day provisioning expiry. Start early; it can take days.
- [ ] Exported 5–10 real FIT **activity** files from Garmin Connect / Hammerhead
      / Zwift → these become decoder fixtures and validate the real format.
- [ ] (Optional, v2) Garmin Developer Program applied for.
- [ ] Current + historical FTP / LTHR / threshold pace noted for seeding.

**B1 — scaffold (½ day):**
1. `git clone` the branch; open `TrainingApp/Package.swift` in Xcode — confirm
   `swift test` passes natively (this validates the packages compile on a real
   Apple toolchain, not just Linux).
2. New Xcode **iOS App** project (iOS 17+). Add the local Swift package. Add the
   `App/` folder's files to the app target.
3. Add capabilities/entitlements: HealthKit, and Info.plist usage strings
   (`NSHealthShareUsageDescription`, WorkoutKit scheduling authorization).
   **Start local-only** (no CloudKit until enrolled).
4. Fix compile errors in `App/` — expect several; they are wiring/API-shape
   bugs, not logic. `App/README.md` lists the four highest-risk spots, the big
   one being **WorkoutKit initializer signatures** in `WorkoutKitScheduler.swift`
   (they shift across SDK versions — reconcile against the shipping API).

**B2 — WorkoutKit spike (day 1):** hardcode one interval workout, schedule it to
your Watch, ride/fake it, confirm step alerts + open-step behavior + the
completed-workout query. Then update `mapping-table.md` with observed reality.

**B3 — FIT spike (day 1–2):** export a workout via `exportFIT`, get it onto your
Garmin and Karoo (verify the import *path* first — Garmin Connect does **not**
accept structured-workout FIT; USB `NewFiles/` does; Karoo varies by firmware;
Intervals.icu API is the documented fallback bridge). Then round-trip a real
completed FIT activity through `FITActivityDecoder` and the dedup/match pipeline.

Only after B1–B3 do you build out the remaining Phase C screens with confidence.

---

## 6. How to run things

**On a Mac / CI (normal):**
```bash
cd TrainingApp
swift test          # all 156 tests
swift run demo      # end-to-end pipeline, prints PMC + projection
```

**On Linux (this build environment only — nixpkgs Swift 5.8 lacks libIndexStore,
so SwiftPM test discovery doesn't work):**
```bash
cd TrainingApp
source swift-env.sh
./scripts/test-linux.sh all      # or: core | fit | sync | appcore | demo
```
The Linux runner generates XCTMain entry points via `scripts/gen-test-main.py`.
It rejects async test methods (a known limitation) — write sync tests, or run
them on the Mac. **You will not need any of this on a Mac** — it exists purely
to have made headless progress possible.

---

## 7. Environment gotchas (documented so you don't rediscover them)

- The Linux container that built this **blocks swift.org and container
  registries**; Swift was installed via the Nix binary cache (5.8). On your Mac,
  ignore all of this — use the normal toolchain.
- `swift-tools-version` is pinned to 5.8 for that reason. Bumping it on a Mac is
  fine and harmless.
- `Activity.externalIDs` is intentionally a `[String]`, not a scalar — do not
  "simplify" it (it prevents re-import duplication; see architecture §5.2).
- Thresholds are always resolved with a date. If you add a code path that reads
  an FTP without `on: date`, that's a bug.

---

## 8. Commit history (feature-by-feature, each reviewed)

```
edf653a  C1 review fixes (WorkoutScheduler ambiguity + 4)
c0a024a  C1: SwiftUI views + Apple adapters (uncompiled)
8aee8e0  C0b: TrainingAppModel (app logic)
e52db5f  C0a: FIT workout-file decoder (import)
9e886da  A6: demo + CI + Phase A wrap-up
7c479a0  A5: matching / dedup / sync window
f321c7f  A4: WorkoutKit mapping + mapping table
89c1f8a  A3: FIT encode/decode
995685c  A2: training math (load, PMC, projection)
c2c6e0f  A1: domain model
…        (docs commits precede these)
```
Every A*/C* commit was TDD (tests first) and had a code-review pass whose
findings were fixed before commit — see each commit message for what the review
caught.

---

## 9. Risks to keep in view

| Risk | Where addressed / what to watch |
|---|---|
| WorkoutKit API shapes differ from what's written | `App/WorkoutKitScheduler.swift`; verify in B2 first thing |
| No manual FIT import path on your Garmin/Karoo firmware | B3 verifies path; Intervals.icu API bridge is the fallback |
| HealthKit sample identifiers/units wrong | `App/HealthKitActivityProvider.swift`; validate against real HKWorkout |
| Apple ships this natively (training load is in watchOS now) | product risk; differentiate on depth Apple won't do (periodization, power) |
| Scope creep back into "compete with Intervals.icu" | re-read `workout-app-vs-intervals-icu.md` before adding analytics |

---

## 10. Definition of "MVP done" (from spec §10 — your finish line)

1. Build a workout with repeats + all step-length + all target types on the
   phone in < 2 min.
2. Schedule it; it appears in the Watch's native Workout app with correct step
   alerts.
3. Export it as FIT; it runs on a Garmin **and** a Karoo.
4. Import a Garmin FIT activity; it dedupes, auto-matches (±1 day), and updates
   the fitness chart with the correctly-dated load.
5. Fitness chart shows combined + per-sport CTL/ATL/TSB with projection and
   race-day form.
6. Weekly view shows planned vs completed load, time-in-zone, and totals.

The engine for all six already exists and is tested; Phase B+ is about wiring it
to real Apple/Garmin hardware and the UI.
