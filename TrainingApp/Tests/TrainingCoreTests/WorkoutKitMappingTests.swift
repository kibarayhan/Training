import XCTest
@testable import TrainingCore

final class WorkoutKitMappingTests: XCTestCase {

    private let day = Date(timeIntervalSince1970: 1_770_000_000)

    private var thresholds: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 4.0, validFrom: .distantPast),
        ])
    }

    private func map(_ workout: WorkoutTemplate) -> (workout: MappedWorkout, notes: [MappingNote]) {
        WorkoutKitMapper.map(workout: workout, on: day, thresholds: thresholds, zones: .defaults)
    }

    func testClassicIntervalWorkoutShape() {
        let workout = WorkoutTemplate(name: "4x3", sport: .ride, items: [
            .step(Step(role: .warmup, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.5, upper: 0.65))),
            .repeatBlock(RepeatBlock(count: 4, steps: [
                Step(role: .work, length: .time(seconds: 180),
                     target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.98, upper: 1.05)),
                Step(role: .recovery, length: .time(seconds: 120), target: nil),
            ])),
            .step(Step(role: .cooldown, length: .open, target: nil)),
        ])
        let (mapped, _) = map(workout)

        XCTAssertEqual(mapped.displayName, "4x3")
        XCTAssertEqual(mapped.sport, .ride)
        XCTAssertNotNil(mapped.warmup, "leading warmup step fills the warmup slot")
        XCTAssertNotNil(mapped.cooldown, "trailing cooldown step fills the cooldown slot")
        XCTAssertEqual(mapped.blocks.count, 1)
        XCTAssertEqual(mapped.blocks[0].iterations, 4)
        XCTAssertEqual(mapped.blocks[0].steps.count, 2)
        XCTAssertEqual(mapped.blocks[0].steps[0].purpose, .work)
        XCTAssertEqual(mapped.blocks[0].steps[1].purpose, .recovery)
        if case .open = mapped.cooldown!.goal {} else { XCTFail("cooldown must map to open goal") }
    }

    func testPowerAlertResolvedToWatts() {
        let workout = WorkoutTemplate(name: "SS", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 1200),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.9, upper: 0.95))),
        ])
        let (mapped, _) = map(workout)
        let step = mapped.blocks[0].steps[0].step
        guard case .powerRange(let low, let high) = step.alert else {
            return XCTFail("expected power range alert")
        }
        XCTAssertEqual(low, 225, accuracy: 0.01)
        XCTAssertEqual(high, 237.5, accuracy: 0.01)
        if case .time(let seconds) = step.goal {
            XCTAssertEqual(seconds, 1200)
        } else { XCTFail("expected time goal") }
    }

    func testPaceAlertUsesSpeedAndDistanceGoal() {
        let workout = WorkoutTemplate(name: "800s", sport: .run, items: [
            .step(Step(role: .work, length: .distance(meters: 800),
                       target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 1.0, upper: 1.05))),
        ])
        let (mapped, _) = map(workout)
        let step = mapped.blocks[0].steps[0].step
        guard case .speedRange(let low, let high) = step.alert else {
            return XCTFail("expected speed range alert")
        }
        XCTAssertEqual(low, 4.0, accuracy: 0.001)
        XCTAssertEqual(high, 4.2, accuracy: 0.001)
        if case .distance(let meters) = step.goal {
            XCTAssertEqual(meters, 800)
        } else { XCTFail("expected distance goal") }
    }

    func testMidWorkoutWarmupBecomesBlock() {
        // Only a LEADING warmup can occupy WorkoutKit's warmup slot.
        let workout = WorkoutTemplate(name: "Two efforts", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 300),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 1.0, upper: 1.05))),
            .step(Step(role: .warmup, length: .time(seconds: 300), target: nil)),
            .step(Step(role: .work, length: .time(seconds: 300),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 1.0, upper: 1.05))),
        ])
        let (mapped, _) = map(workout)
        XCTAssertNil(mapped.warmup)
        XCTAssertEqual(mapped.blocks.count, 3)
        XCTAssertEqual(mapped.blocks[1].steps[0].purpose, .recovery,
                       "mid-workout warmup maps to a recovery-purpose interval step")
    }

    func testRPEStepHasNoAlertAndEmitsNote() {
        let workout = WorkoutTemplate(name: "Feel", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .rpe, reference: .absolute, lower: 6, upper: 7))),
        ])
        let (mapped, notes) = map(workout)
        XCTAssertNil(mapped.blocks[0].steps[0].step.alert)
        XCTAssertTrue(notes.contains { $0.kind == .rpeHasNoDeviceAlert })
    }

    func testUnresolvableTargetDegradesWithNote() {
        // HR percent with no LTHR anywhere.
        let workout = WorkoutTemplate(name: "Z2", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .heartRate, reference: .percentOfThreshold, lower: 0.8, upper: 0.9))),
        ])
        let (mapped, notes) = map(workout)
        XCTAssertNil(mapped.blocks[0].steps[0].step.alert)
        XCTAssertTrue(notes.contains { $0.kind == .unresolvableTarget })
    }

    func testTopZoneClampedToFiniteAlert() {
        let workout = WorkoutTemplate(name: "Sprints", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 30),
                       target: IntensityTarget(kind: .power, reference: .zone, lower: 7, upper: 7))),
        ])
        let (mapped, notes) = map(workout)
        guard case .powerRange(let low, let high) = mapped.blocks[0].steps[0].step.alert else {
            return XCTFail("expected power range alert")
        }
        XCTAssertTrue(high.isFinite)
        XCTAssertGreaterThan(high, low)
        XCTAssertTrue(notes.contains { $0.kind == .topZoneClamped })
    }

    func testCadenceAlertMapped() {
        let workout = WorkoutTemplate(name: "Spin", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 60),
                       target: IntensityTarget(kind: .cadence, reference: .absolute, lower: 95, upper: 110))),
        ])
        let (mapped, _) = map(workout)
        guard case .cadenceRange(let low, let high) = mapped.blocks[0].steps[0].step.alert else {
            return XCTFail("expected cadence range alert")
        }
        XCTAssertEqual(low, 95)
        XCTAssertEqual(high, 110)
    }

    func testWarmupCooldownOnlyWorkoutMapsToEmptyBlocks() {
        let workout = WorkoutTemplate(name: "Openers", sport: .ride, items: [
            .step(Step(role: .warmup, length: .time(seconds: 300), target: nil)),
            .step(Step(role: .cooldown, length: .open, target: nil)),
        ])
        let (mapped, _) = map(workout)
        XCTAssertNotNil(mapped.warmup)
        XCTAssertNotNil(mapped.cooldown)
        XCTAssertTrue(mapped.blocks.isEmpty)
    }

    func testEveryLengthAndTargetCombinationMaps() {
        // Smoke test: nothing the builder can express may crash the mapper.
        let lengths: [StepLength] = [.time(seconds: 60), .distance(meters: 400), .open]
        let targets: [IntensityTarget?] = [
            nil,
            IntensityTarget(kind: .power, reference: .absolute, lower: 200, upper: 220),
            IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.9, upper: 1.0),
            IntensityTarget(kind: .power, reference: .zone, lower: 2, upper: 3),
            IntensityTarget(kind: .heartRate, reference: .absolute, lower: 130, upper: 150),
            IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 0.95, upper: 1.0),
            IntensityTarget(kind: .cadence, reference: .absolute, lower: 90, upper: 100),
            IntensityTarget(kind: .rpe, reference: .absolute, lower: 5, upper: 6),
        ]
        for sport in Sport.allCases {
            for length in lengths {
                for target in targets {
                    let workout = WorkoutTemplate(name: "combo", sport: sport, items: [
                        .step(Step(role: .work, length: length, target: target)),
                        .repeatBlock(RepeatBlock(count: 2, steps: [
                            Step(role: .work, length: length, target: target),
                            Step(role: .recovery, length: .time(seconds: 60), target: nil),
                        ])),
                    ])
                    let (mapped, _) = map(workout)
                    XCTAssertEqual(mapped.blocks.count, 2)
                }
            }
        }
    }
}
