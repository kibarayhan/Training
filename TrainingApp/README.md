# TrainingApp — Phase A core packages

Platform-independent core of the structured training app defined in
`../docs/workout-app-mvp-spec.md`, built per
`../docs/workout-app-implementation-plan.md`. Pure Swift + Foundation; no
HealthKit/WorkoutKit/SwiftData imports — those arrive as thin adapters in
the Xcode project (Phase B).

## Modules

- **TrainingCore** — domain model (workouts, steps, single-level repeats,
  thresholds with dated history, zones, planned workouts, activities),
  training math (load fallback chain, workout estimation, CTL/ATL/TSB engine
  with projection, weekly aggregates, ramp guard), and the WorkoutKit mapping
  layer (mirror types + degradation notes; see `../docs/mapping-table.md`).
- **TrainingFIT** — FIT binary subset: structured-workout encoder for
  Garmin/Karoo and activity-file decoder (session + records, skip-unknown).
- **TrainingSync** — ±1-day plan matching with compliance verdicts,
  duplicate detection/merge across sources, 15-workout Watch sync window.
- **demo** — end-to-end script: build → estimate → FIT export → dedup →
  match → PMC with projection to race day.

## Testing

- Mac / CI (official toolchains): `swift test`, `swift run demo`.
- This Linux container (nixpkgs Swift 5.8, which lacks libIndexStore and
  therefore SwiftPM test discovery): `./scripts/test-linux.sh [all|core|fit|sync|demo]`
  after `source swift-env.sh`. The runner generates XCTMain entry points via
  `scripts/gen-test-main.py` (no async tests, no commented-out registration).

## Status

Phase A complete: 132 tests green. Next: Phase B Mac-day scaffold + the two
hardware spikes (WorkoutKit on Watch, FIT files on Garmin/Karoo).
