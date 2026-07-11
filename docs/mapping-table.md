# Lossless-Mapping Table: Internal Model ↔ WorkoutKit ↔ FIT

Living document required by MVP spec §2/§5. Kept in sync with
`TrainingApp/Sources/TrainingCore/WorkoutKitMapping.swift` and
`TrainingApp/Sources/TrainingFIT/FITWorkoutEncoder.swift`; every "degrades"
cell has a `MappingNote` the UI surfaces. Verify the WorkoutKit column
against real hardware in Phase B spike B2.

## Structure

| Internal | WorkoutKit (Mapped*) | FIT workout_step |
|---|---|---|
| WorkoutTemplate | CustomWorkout(displayName, warmup?, blocks, cooldown?) | workout msg (26) + steps (27) |
| Leading warmup step | warmup slot | step with intensity=warmup(2) |
| Trailing cooldown step | cooldown slot | step with intensity=cooldown(3) |
| Mid-workout warmup/rest/recovery step | IntervalBlock(1×) with recovery purpose | step with matching intensity (rest=1, recovery=4) |
| Standalone work step | IntervalBlock(1×, work) | step, intensity=active(0) |
| RepeatBlock(n, steps) | IntervalBlock(n, steps) | steps + repeat step (duration_type=6, duration_value=first index, target_value=n) |
| Nested repeats | — impossible by construction (single level enforced in the type system) — | — |

## Step length

| Internal | WorkoutKit | FIT |
|---|---|---|
| time(seconds) | .time goal | duration_type=time(0), ms |
| distance(meters) | .distance goal | duration_type=distance(1), cm |
| open (lap button) | .open goal | duration_type=open(5) |

## Intensity targets

| Internal | WorkoutKit | FIT |
|---|---|---|
| power %FTP | power range alert, resolved to watts on export date | custom power range, native %FTP (values ≤1000) |
| power watts | power range alert | custom power range, watts+1000 |
| power zone | power range alert, resolved to watts; **top zone clamped to lower × 1.25** (`topZoneClamped` note) | target_value = zone number |
| HR bpm | HR range alert | custom HR range, bpm+100 |
| HR %LTHR / zone | resolved to bpm via thresholds on export date; **unresolvable → no alert / open target** (`unresolvableTarget` note) | resolved to bpm+100; unresolvable → open target |
| pace (stored as speed m/s) | speed range alert | custom speed range, mm/s |
| cadence rpm (absolute) | cadence range alert | target_type=cadence, custom range |
| cadence percent/zone | **no alert** (`cadencePercentUnsupported` note) | open target |
| RPE | **no device alert** (`rpeHasNoDeviceAlert` note); shown in step notes only | open target |
| no target | no alert | open target |

## Known WorkoutKit constraints (validate in spike B2)

- One warmup and one cooldown slot only; extra warmups become interval blocks.
- Alerts are reactive (fire on leaving range); no pre-step countdown API.
- One alert per step — internal model already enforces one target per step.
- ≤15 scheduled workouts synced at a time (sync-window selector in TrainingSync).

## Known FIT notes (validate in spike B3)

- Multisport activity files are rejected on import (`multiSessionUnsupported`) rather than mis-decoded.
- Record speed read from legacy field 6 or enhanced_speed 73.
- Workout names truncated UTF-8-safely to 31 bytes.
