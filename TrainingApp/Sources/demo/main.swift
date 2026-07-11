import Foundation
import TrainingCore
import TrainingFIT
import TrainingSync

// Phase A definition-of-done demo: build a workout, estimate it, export FIT,
// simulate a season, match activities to the plan, and print the PMC with a
// projection through the remaining plan to race day.

func day(_ n: Int) -> Date { Date(timeIntervalSince1970: 1_767_225_600 + Double(n) * 86_400) }
func fmt(_ v: Double) -> String { String(format: "%5.1f", v) }

let thresholds = ThresholdStore(records: [
    ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
    ThresholdRecord(sport: .ride, kind: .lthr, value: 165, validFrom: .distantPast),
    ThresholdRecord(sport: .run, kind: .lthr, value: 172, validFrom: .distantPast),
    ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 3.9, validFrom: .distantPast),
])

// ── 1. Build a structured workout ─────────────────────────────────────────
let intervals = WorkoutTemplate(name: "4x3min @ threshold", sport: .ride, items: [
    .step(Step(role: .warmup, length: .time(seconds: 600),
               target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.5, upper: 0.65))),
    .repeatBlock(RepeatBlock(count: 4, steps: [
        Step(role: .work, length: .time(seconds: 180),
             target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.98, upper: 1.05)),
        Step(role: .recovery, length: .time(seconds: 120),
             target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.4, upper: 0.55)),
    ])),
    .step(Step(role: .cooldown, length: .open, target: nil)),
])

let estimate = WorkoutEstimator.estimate(workout: intervals, on: day(80),
                                         thresholds: thresholds, zones: .defaults)
print("── Workout: \(intervals.name)")
print("   estimated load \(fmt(estimate.load)) TSS, \(Int(estimate.durationSeconds / 60)) min")
print("   time in zone: \(estimate.zoneSeconds.sorted { $0.key < $1.key }.map { "Z\($0.key)=\(Int($0.value / 60))m" }.joined(separator: " "))")

// ── 2. Export to FIT and cross-check by re-parsing ────────────────────────
let fit = try FITWorkoutEncoder.encode(workout: intervals, on: day(80),
                                       thresholds: thresholds, zones: .defaults)
let parsed = try FITMessageReader.messages(from: fit)
print("\n── FIT export: \(fit.count) bytes, CRC ok, \(parsed.filter { $0.globalMessage == 27 }.count) device steps")

// ── 3. Map for WorkoutKit ─────────────────────────────────────────────────
let (mapped, notes) = WorkoutKitMapper.map(workout: intervals, on: day(80),
                                           thresholds: thresholds, zones: .defaults)
print("── WorkoutKit mapping: warmup=\(mapped.warmup != nil), blocks=\(mapped.blocks.count), cooldown=\(mapped.cooldown != nil), notes=\(notes.count)")

// ── 4. Simulate 12 completed weeks + plan 4 future weeks ──────────────────
var activities: [Activity] = []
var planned: [PlannedWorkout] = []
let today = day(84)

for week in 0..<16 {
    let rideLoadFactor = 0.9 + Double(week) * 0.02 // gentle progression
    for offset in [0, 2, 4] { // Mon/Wed/Fri rides
        let date = day(week * 7 + offset)
        if date < today {
            activities.append(Activity(
                source: offset == 2 ? .fitImport(device: "Karoo") : .healthKit,
                sport: .ride, start: date.addingTimeInterval(6 * 3600),
                movingSeconds: 2100 * rideLoadFactor, normalizedPower: 230))
        }
        planned.append(PlannedWorkout(template: intervals, date: date))
    }
    let runDate = day(week * 7 + 5) // Saturday run
    let runTemplate = WorkoutTemplate(name: "45min steady run", sport: .run, items: [
        .step(Step(role: .work, length: .time(seconds: 2700),
                   target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 0.85, upper: 0.92))),
    ])
    planned.append(PlannedWorkout(template: runTemplate, date: runDate))
    if runDate < today {
        activities.append(Activity(source: .healthKit, sport: .run,
                                   start: runDate.addingTimeInterval(8 * 3600),
                                   movingSeconds: 2700, distanceMeters: 2700 * 3.4))
    }
}

// Duplicate injection: the same Wednesday ride also arrives via Zwift.
if let wednesday = activities.first(where: { $0.source == .fitImport(device: "Karoo") }) {
    activities.append(Activity(source: .fitImport(device: "Zwift"), sport: .ride,
                               start: wednesday.start.addingTimeInterval(45),
                               movingSeconds: wednesday.movingSeconds * 0.99,
                               normalizedPower: 231))
}
let dupeGroups = DuplicateDetector.duplicateGroups(in: activities)
for group in dupeGroups {
    let merged = DuplicateDetector.merge(group)
    activities.removeAll { a in group.contains { $0.id == a.id } }
    activities.append(merged)
}
print("\n── Dedup: \(dupeGroups.count) duplicate group(s) merged, \(activities.count) activities")

// ── 5. Match activities to the plan ───────────────────────────────────────
let result = MatchingEngine.match(planned: planned, activities: activities,
                                  thresholds: thresholds, zones: .defaults, today: today)
let counts = Dictionary(grouping: result.compliance.values) { $0 }.mapValues(\.count)
print("── Matching: completed=\(counts[.completed] ?? 0) substituted=\(counts[.substituted] ?? 0) missed=\(counts[.missed] ?? 0) unplanned=\(result.unplannedActivityIDs.count)")

// ── 6. Sync window ────────────────────────────────────────────────────────
let window = SyncWindow.select(planned: planned, today: today)
print("── Sync window: \(window.count) workouts queued for the Watch (cap \(SyncWindow.capacity))")

// ── 7. PMC with projection to race day ────────────────────────────────────
var loads: [DailyLoad] = []
for a in activities {
    if let load = LoadCalculator.load(for: a, thresholds: thresholds) {
        loads.append(DailyLoad(date: a.start, sport: a.sport, load: load.value))
    }
}
for p in planned where p.date >= today {
    let e = WorkoutEstimator.estimate(planned: p, thresholds: thresholds, zones: .defaults)
    if e.hasEstimate {
        loads.append(DailyLoad(date: p.date, sport: p.sport, load: e.load))
    }
}
let race = TargetEvent(name: "Race day", date: day(111), sport: .ride)
let series = PMCEngine.series(loads: loads, from: day(0), to: day(112))

print("\n── PMC (weekly snapshots; * = projected from plan)")
print("   week   CTL   ATL   TSB")
for week in stride(from: 6, through: 112, by: 7) {
    guard let point = series.first(where: { $0.date == day(week) }) else { continue }
    let marker = day(week) >= today ? " *" : ""
    let label = String(format: "w%02d", week / 7 + 1)
    print("   \(label)  \(fmt(point.ctl)) \(fmt(point.atl)) \(fmt(point.tsb))\(marker)")
}
if let form = PMCEngine.form(on: race.date, in: series) {
    print("\n── \(race.name) (\(race.date.utcDayIndex - today.utcDayIndex) days out): projected form \(fmt(form))")
}
print("\nPhase A demo complete.")
