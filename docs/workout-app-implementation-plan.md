# Implementation Plan: Structured Training App MVP

**Status:** v1 — 2026-07-11
**Implements:** `workout-app-mvp-spec.md` (all sections)
**Constraint that shapes this plan:** no Mac access for ~2 weeks. Everything in
**Phase A** compiles and unit-tests on Linux (Swift toolchain + SwiftPM, CI via
GitHub Actions) so that Mac-day is integration testing, not greenfield coding.

---

## 0. Strategy

1. **Phase A (now → Mac-day):** build the entire platform-independent core as Swift
   packages — domain model, all math, FIT encode/decode, matching/dedup, projection —
   with exhaustive unit tests. No UI, no HealthKit, no WorkoutKit linkage (interfaces
   only, behind protocols).
2. **Phase B (Mac-day, ~2 days):** create the Xcode project, drop the packages in, run
   the two **de-risking spikes** on real hardware (WorkoutKit → your Watch; FIT file →
   your Garmin + Karoo). Spike results may amend the mapping layer — that's expected
   and cheap because the core is already tested.
3. **Phase C (weeks 3–8):** vertical slice first, then feature milestones in dependency
   order. Each milestone ends in something usable on your own devices.

**Repo:** create a new dedicated repository (e.g. `training-app`) on Mac-day or sooner;
Phase A packages can be developed there immediately since SwiftPM needs no Mac.

---

## Phase A — Platform-independent core (no Mac needed, ~2 weeks)

### Package layout

```
TrainingApp/
├── Package.swift
├── Sources/
│   ├── TrainingCore/        # domain model + math (zero dependencies)
│   ├── TrainingFIT/         # FIT encode/decode (depends on TrainingCore)
│   └── TrainingSync/        # matching, dedup, sync-window logic (depends on TrainingCore)
└── Tests/                   # mirrors Sources; fixture FIT files in Tests/Fixtures
```

Rules: pure Swift, `Foundation` only, everything `Codable` + `Sendable`,
no `import HealthKit/WorkoutKit/SwiftData` anywhere in these packages.
Persistence and Apple frameworks are adapters added in Phase C.

### A1. Domain model (`TrainingCore`) — spec §3, §4

- [ ] `Sport` (run, ride — extensible), `IntensityTargetKind` (power, pace, HR, cadence, RPE/none)
- [ ] `WorkoutTemplate` = metadata (name, sport, tags/folder, notes) + `[WorkoutItem]`
- [ ] `WorkoutItem` = `.step(Step)` | `.repeatBlock(count, [Step])` (single level enforced by type)
- [ ] `Step` = role (warmup/work/recovery/cooldown/rest) + length (`.time`, `.distance`, `.open`) + target (kind + range, or none)
- [ ] `ThresholdRecord(sport, kind, value, validFrom)` + `ThresholdStore.value(for:sport:kind:on:date)`
- [ ] `ZoneModel` per sport/kind, default schemes (7-zone power, 5-zone HR/pace), user-editable boundaries
- [ ] `PlannedWorkout` (instance: template snapshot + date + sport), `TargetEvent`
- [ ] `Activity` (source, sport, start, duration, distance, samples summary, per-zone times, load + load-method)
- [ ] Template→instance semantics: instances hold a **snapshot**; template edits prompt for future instances (flag on instance: `detachedFromTemplate`)
- Tests: model invariants, Codable round-trips, threshold-history date lookups (edges: activity before first record, same-day change)

### A2. Training math (`TrainingCore`) — spec §8

- [ ] Load calculators + **fallback chain**: power TSS → hrTSS/TRIMP → rTSS (run pace) → RPE×duration → duration×sport-default-IF; result carries which method was used
- [ ] Estimated load + time-in-zone **preview from workout steps** (work out per-step IF from target midpoint; open steps use role defaults)
- [ ] PMC engine: CTL (42d EWMA), ATL (7d), TSB; combined + per-sport series
- [ ] **Projection**: continue PMC over future `PlannedWorkout` estimated loads; race-day form lookup for `TargetEvent`
- [ ] Weekly/monthly aggregates per sport: time, distance, elevation, load, zone-time (completed and planned)
- [ ] Ramp-rate guard: warn when scheduled week > ~1.3× chronic weekly load
- Tests: golden-value tests against hand-computed examples; property tests (CTL monotonic under constant load, projection equals actuals when compliance is 100%); cross-check a sample against Intervals.icu output for sanity

### A3. FIT encode/decode (`TrainingFIT`) — spec §5

FIT is Garmin's binary format; no official Swift SDK. Implement the needed subset
directly (header, record framing, definition/data messages, CRC-16):

- [ ] **Encoder — structured workout files**: `file_id`, `workout`, `workout_step` messages; repeat steps (`repeat_until_steps_cmplt`); durations time/distance/open; targets power/pace(speed)/HR/cadence zones and custom ranges. This is the Garmin/Karoo export path.
- [ ] **Decoder — activity files (subset)**: `file_id`, `session`, `lap`, `record` (timestamp, power, HR, speed/distance, cadence, altitude) → `Activity` with samples; tolerate unknown messages/fields (skip, don't fail); developer-field tolerance
- [ ] Fixtures: real FIT files from your own Garmin/Karoo/Zwift history committed to `Tests/Fixtures` (you can export these from Garmin Connect / Hammerhead dashboard **without a Mac** — do this during Phase A)
- [ ] `.zwo` encoder (power workouts only) — stretch, only if A1–A6 are done
- Tests: encode→decode round-trip equals original model; decode fixtures produce plausible sessions (duration/avg power within tolerance of what the platforms display); CRC and malformed-file handling

### A4. Mapping layer + lossless-mapping table — spec §2 design rule

- [ ] `WorkoutKitMappable` protocol in `TrainingCore` describing the WorkoutKit-shaped
      output (mirror types: `MappedCustomWorkout`, `MappedIntervalBlock`, `MappedStep`,
      `MappedAlert`) — actual `import WorkoutKit` conformance is a thin Phase-B adapter
- [ ] Mapping functions: internal model → Mapped* (WorkoutKit shape) and → FIT encoder input
- [ ] **Degradation rules documented in code + doc table**: cadence-as-secondary dropped for WorkoutKit (kept for FIT); RPE/no-target steps → no alert; open steps → WorkoutKit open goal / FIT lap-press duration
- [ ] `docs/mapping-table.md`: feature × (internal / WorkoutKit / FIT) with loss notes — the living doc required by the spec
- Tests: every builder-expressible workout maps to both targets without error; snapshot tests of mapped output

### A5. Matching, dedup, sync window (`TrainingSync`) — spec §6, §7

- [ ] Auto-match: same sport within ±1 day; scoring when multiple candidates (closest date, then duration/load similarity); manual re-link API
- [ ] Compliance classifier: completed / substituted (structure similarity below threshold) / missed / unplanned
- [ ] **Duplicate detection**: sport + start-time proximity (±3 min default) + duration/distance similarity → merge policy (prefer richer sample set); force merge/split API
- [ ] WorkoutKit **sync-window selector**: nearest ≤15 scheduled workouts, stable ordering, diff-based add/remove plan
- Tests: table-driven scenarios — late workout (+1 day), two activities one day, substituted ride, Zwift ride arriving twice (HealthKit + Karoo FIT), month with 40 scheduled workouts windowed to 15

### A6. CI

- [ ] GitHub Actions: `swift build && swift test` on Linux for every push — keeps the core honest until Xcode exists

**Phase A definition of done:** all packages green on Linux CI; FIT fixture files decode;
a scripted demo (`swift run demo`) builds a workout, exports FIT bytes, simulates a
season of activities, and prints the PMC + projection — reviewable without any Apple device.

---

## Phase B — Mac-day: spikes + project scaffold (~2 days)

### B1. Scaffold (half day)
- [ ] Xcode project: iOS app target (iOS 17+), packages added, SwiftData persistence adapter for `TrainingCore` types, CloudKit-enabled container, HealthKit + WorkoutKit entitlements/usage strings
- [ ] Personal team signing; app runs on your iPhone

### B2. Spike 1 — WorkoutKit proof (day 1)
Hardcoded workout (warmup, 4×[3min power-range / 2min recovery], open cooldown):
- [ ] Authorization flow; schedule via WorkoutKit; appears in Watch Workout app under app branding
- [ ] Ride it (or fake it on the trainer): verify step alerts (power range), open-step lap behavior, transition haptics
- [ ] Query completed scheduled workouts; read the HKWorkout back with samples
- [ ] Confirm 15-workout window behavior + what happens on over-schedule
- **Checklist output:** amend `mapping-table.md` with observed reality vs docs

### B3. Spike 2 — FIT on real head units (day 1–2)
- [ ] AirDrop/USB the Phase-A-generated FIT workout to Garmin (`NewFiles/`) and import via Hammerhead dashboard to Karoo
- [ ] Execute on both; verify step names, durations, targets render correctly
- [ ] Export the resulting completed activities; run through `TrainingFIT` decoder; verify dedup/matching pipeline end-to-end with real files
- **Checklist output:** device quirks list; encoder fixes as needed

Spikes deliberately come **before** any UI work: if either fails, the spec amendment
costs days, not weeks.

---

## Phase C — App build-out (weeks 3–8, order = dependency order)

### M1. Vertical slice (week 3) — spec §10 criteria 2 + 4, thin
Minimal hardcoded-style UI: pick a template from a seeded library → put on date →
WorkoutKit sync → HealthKit ingest → auto-match → PMC chart datapoint moves.
*Proves the whole loop in-app; everything after is widening.*

### M2. Workout builder UI (weeks 3–4) — spec §4
- Step/repeat editor (add, reorder, duplicate); three length modes; all five target kinds with per-sport pickers (%FTP etc. resolved via threshold store)
- Live estimated TSS + time-in-zone preview
- Library: tags/folders, search, sport filter; template vs instance semantics with the edit-prompt flow
- FIT workout **import** into library (share-sheet / file picker)

### M3. Athlete profile & zones UI (week 4) — spec §3
- Threshold entry with dated history timeline; zone editors per sport/kind; first-run guided setup (incl. estimate-from-race-time)

### M4. Calendar & planning (week 5) — spec §6
- Week/month views, drag-reschedule, duplicate/shift week; target events; planned weekly totals + ramp-rate warning
- WorkoutKit rolling sync (window selector from A5) + sync-status indicators; export scheduled workout as FIT via share sheet

### M5. Activity ingestion & matching UI (week 6) — spec §7
- HealthKit anchored queries (workouts + samples) with permission-degraded mode
- FIT activity import; dedup review UI (merge/split); match review (re-link, compliance badges: completed/substituted/missed/unplanned); load-method shown per activity

### M6. Fitness & totals (week 7) — spec §8
- PMC chart (Swift Charts): combined + per-sport toggle, actual/projected visual split, race-day form callout
- Weekly/monthly totals + time-in-zone screens (completed and planned)

### M7. Hardening & acceptance pass (week 8)
- Empty states, error surfaces (sync failures at the trailhead → §13 of discovery doc), threshold-change recompute, performance with 2–3 years of history
- Walk **all six §10 acceptance criteria** end-to-end and record results in the spec doc

### Post-MVP backlog (unchanged from spec §9)
Per-step compliance/interval detection → HealthKit wellness panel → text parser →
Garmin/Strava inbound sync (apply for **Garmin developer program during Phase A** — approval lead time) → eFTP → plan templates.

---

## Test-readiness checklist for Mac-day (prepare during Phase A, no Mac needed)

- [ ] Export 5–10 recent FIT **activities** from Garmin Connect + Hammerhead dashboard + Zwift → commit as test fixtures
- [ ] Note your current FTP, LTHR (run/bike), threshold pace + approximate history for seeding
- [ ] Pick the 5 real workouts you actually do → become the seeded template library and spike payloads
- [ ] Apple ID ready; check iOS ≥17 / watchOS ≥10 on your devices
- [ ] Apply for Garmin Connect Developer Program (for v2 sync)
- [ ] Create the dedicated `training-app` repository

## Risks & watch items

| Risk | Mitigation in plan |
|---|---|
| WorkoutKit behaves differently on-device than documented | Spike B2 before any UI; mapping layer isolates changes |
| FIT encoding rejected by Garmin/Karoo firmware | Spike B3 with real devices; fixtures from your own units |
| FIT decoder scope creep (format is huge) | Subset decoding, skip-unknown policy, fixtures define "enough" |
| SwiftData/CloudKit friction with value-type domain model | Domain stays plain Swift; persistence is an adapter layer only |
| Solo timeline slips | Milestones are independently shippable; M1 slice always demoable |

## Effort summary

| Phase | Duration | Mac needed |
|---|---|---|
| A: core packages + tests | ~2 weeks (now) | No |
| B: scaffold + 2 spikes | ~2 days | Yes |
| C: M1–M7 app build-out | ~6 weeks part-time | Yes |
| **Total to MVP acceptance** | **~8–9 weeks from today** | |
