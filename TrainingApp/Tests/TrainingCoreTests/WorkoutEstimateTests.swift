import XCTest
@testable import TrainingCore

final class WorkoutEstimateTests: XCTestCase {

    private let day = Date(timeIntervalSince1970: 1_770_000_000)

    private var thresholds: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 4.0, validFrom: .distantPast),
        ])
    }

    func testEstimateForSteadyPowerWorkout() {
        // 1h at 90–110% FTP: midpoint IF 1.0 → TSS 100
        let workout = WorkoutTemplate(name: "Sweet spot", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 3600),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.9, upper: 1.1))),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        XCTAssertEqual(estimate.load, 100, accuracy: 0.5)
        XCTAssertEqual(estimate.durationSeconds, 3600, accuracy: 0.1)
    }

    func testEstimateSumsRepeats() {
        // 4 × (3min @ 100% + 2min @ 50%): work IF²=1 → 5 TSS/interval work part,
        // recovery IF²=0.25 → 0.833 TSS/interval
        let workout = WorkoutTemplate(name: "Intervals", sport: .ride, items: [
            .repeatBlock(RepeatBlock(count: 4, steps: [
                Step(role: .work, length: .time(seconds: 180),
                     target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 1.0, upper: 1.0)),
                Step(role: .recovery, length: .time(seconds: 120),
                     target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.5, upper: 0.5)),
            ])),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        let expected = 4.0 * (180.0 / 3600.0 * 1.0 + 120.0 / 3600.0 * 0.25) * 100.0
        XCTAssertEqual(estimate.load, expected, accuracy: 0.01)
    }

    func testDistanceStepDurationFromPaceTarget() {
        // 800m at threshold speed 4 m/s → 200s
        let workout = WorkoutTemplate(name: "Track", sport: .run, items: [
            .step(Step(role: .work, length: .distance(meters: 800),
                       target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 1.0, upper: 1.0))),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        XCTAssertEqual(estimate.durationSeconds, 200, accuracy: 0.1)
        XCTAssertEqual(estimate.load, 200.0 / 3600.0 * 1.0 * 100.0, accuracy: 0.1)
    }

    func testStepsWithoutTargetUseRoleDefaults() {
        let workout = WorkoutTemplate(name: "Easy hour", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 3600), target: nil)),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        // Role default IF for work is 0.7 → 49 TSS
        XCTAssertEqual(estimate.load, 3600.0 / 3600.0 * 0.49 * 100.0, accuracy: 0.5)
    }

    func testOpenStepsContributeRoleDefaultDuration() {
        let workout = WorkoutTemplate(name: "With open cooldown", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 3000),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.8, upper: 0.8))),
            .step(Step(role: .cooldown, length: .open, target: nil)),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        // Open steps assume 5 minutes at the role default intensity.
        XCTAssertEqual(estimate.durationSeconds, 3000 + 300, accuracy: 0.1)
        XCTAssertGreaterThan(estimate.load, 3000.0 / 3600.0 * 0.64 * 100.0 - 0.1)
    }

    func testTimeInZonePreview() {
        // 30min at 100% FTP (zone 4) + 30min at 50% (zone 1) on default Coggan zones
        let workout = WorkoutTemplate(name: "Split", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 1800),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 1.0, upper: 1.0))),
            .step(Step(role: .recovery, length: .time(seconds: 1800),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.5, upper: 0.5))),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        XCTAssertEqual(estimate.zoneSeconds[4], 1800)
        XCTAssertEqual(estimate.zoneSeconds[1], 1800)
    }

    func testUnstructuredPlannedWorkoutEstimate() {
        // Ad-hoc "2h easy ride" with no steps: duration × sport default IF.
        let planned = PlannedWorkout(
            adHoc: WorkoutSnapshot(name: "2h easy", sport: .ride, items: []),
            date: day, estimatedDurationSeconds: 7200)
        let estimate = WorkoutEstimator.estimate(
            planned: planned, thresholds: thresholds, zones: .defaults)
        XCTAssertEqual(estimate.load, 84.5, accuracy: 0.01)
        XCTAssertEqual(estimate.durationSeconds, 7200)
    }

    func testAdHocWithoutDurationHasNoEstimate() {
        let planned = PlannedWorkout(
            adHoc: WorkoutSnapshot(name: "easy ride", sport: .ride, items: []),
            date: day)
        let estimate = WorkoutEstimator.estimate(
            planned: planned, thresholds: thresholds, zones: .defaults)
        XCTAssertFalse(estimate.hasEstimate, "planner must flag unestimable entries")
        XCTAssertEqual(estimate.load, 0)
    }

    func testMissingThresholdFallsBackToRoleDefault() {
        // Run workout with pace target but no run thresholds in store.
        let workout = WorkoutTemplate(name: "Tempo", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: 1800),
                       target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 0.95, upper: 1.0))),
        ])
        let estimate = WorkoutEstimator.estimate(
            workout: workout, on: day, thresholds: ThresholdStore(records: []), zones: .defaults)
        XCTAssertEqual(estimate.load, 1800.0 / 3600.0 * 0.49 * 100.0, accuracy: 0.5)
    }
}
