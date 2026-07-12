# App layer (SwiftUI + Apple adapters) — UNVERIFIED until Mac-day

This folder is the iPhone app's UI and its real Apple-framework adapters. Unlike
everything under `Sources/`, **none of it has been compiled or tested** — this
environment has no Xcode or Apple SDKs. It is written for adoption when the
Xcode project is created (Phase B) and has been reviewed only by reading.

Treat every file here as a first draft to compile, run, and fix on device.

## What's here

- `TrainingApp.swift` — `@main` App + root `TabView`.
- `Support/AppModelObservable.swift` — the only bridge between SwiftUI and the
  tested `TrainingAppModel`. Deliberately logic-free: it republishes the model's
  `onChange` as `objectWillChange`. All behavior lives in `TrainingAppCore`.
- `Views/` — builder, library, calendar, dashboard, profile. These call only the
  model's public API (verified to exist against `Sources/TrainingAppCore`).
- `Adapters/HealthKitActivityProvider.swift` — real `ActivityProvider`.
- `Adapters/WorkoutKitScheduler.swift` — real `WorkoutScheduler`; the only file
  importing WorkoutKit. Translates the tested `MappedWorkout` mirror types into
  Apple's `CustomWorkout`.

## Highest-risk items to verify first on Mac-day (spike B2)

1. **WorkoutKit API shapes** in `WorkoutKitScheduler` — `WorkoutStep`,
   `IntervalStep`, goal/alert initializers have shifted across betas; confirm
   against the shipping SDK.
2. **HealthKit sample/quantity identifiers and units** in
   `HealthKitActivityProvider` — `.cyclingPower`, `.runningSpeed`, average
   statistics options; validate against real `HKWorkout` data.
3. **Swift Charts marks** in `DashboardScreen` — dashed projected segments.
4. The synchronous-over-async semaphore bridge in `HealthKitActivityProvider`
   (ActivityProvider is sync; HealthKit is async) — confirm it doesn't deadlock
   on the main actor; the model calls `refreshActivities()` from a background Task.

## Guardrail

Because this layer is thin and all logic sits behind it in tested packages, a
bug here is a UI/wiring bug, not a logic bug — the fitness math, matching, FIT,
and mapping are all covered by the 135 tests under `Tests/`.
