import XCTest
import TrainingCore
@testable import TrainingFIT

final class WorkoutDecodeTests: XCTestCase {

    private let day = Date(timeIntervalSince1970: 1_770_000_000)

    private var thresholds: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 4.0, validFrom: .distantPast),
        ])
    }

    private func roundTrip(_ workout: WorkoutTemplate) throws -> WorkoutTemplate {
        let data = try FITWorkoutEncoder.encode(workout: workout, on: day,
                                                thresholds: thresholds, zones: .defaults)
        return try FITWorkoutDecoder.decode(data)
    }

    func testRoundTripIntervalWorkoutStructure() throws {
        let original = WorkoutTemplate(name: "4x3 threshold", sport: .ride, items: [
            .step(Step(role: .warmup, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.50, upper: 0.65))),
            .repeatBlock(RepeatBlock(count: 4, steps: [
                Step(role: .work, length: .time(seconds: 180),
                     target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.98, upper: 1.05)),
                Step(role: .recovery, length: .time(seconds: 120),
                     target: IntensityTarget(kind: .power, reference: .absolute, lower: 100, upper: 140)),
            ])),
            .step(Step(role: .cooldown, length: .open, target: nil)),
        ])
        let decoded = try roundTrip(original)

        XCTAssertEqual(decoded.name, "4x3 threshold")
        XCTAssertEqual(decoded.sport, .ride)
        XCTAssertEqual(decoded.items.count, 3)

        guard case .step(let warmup) = decoded.items[0] else { return XCTFail("expected step") }
        XCTAssertEqual(warmup.role, .warmup)
        XCTAssertEqual(warmup.length, .time(seconds: 600))
        XCTAssertEqual(warmup.target?.kind, .power)
        XCTAssertEqual(warmup.target?.reference, .percentOfThreshold)
        XCTAssertEqual(warmup.target!.lower, 0.50, accuracy: 0.001)
        XCTAssertEqual(warmup.target!.upper, 0.65, accuracy: 0.001)

        guard case .repeatBlock(let block) = decoded.items[1] else { return XCTFail("expected repeat") }
        XCTAssertEqual(block.count, 4)
        XCTAssertEqual(block.steps.count, 2)
        XCTAssertEqual(block.steps[0].role, .work)
        XCTAssertEqual(block.steps[1].role, .recovery)
        XCTAssertEqual(block.steps[1].target?.reference, .absolute)
        XCTAssertEqual(block.steps[1].target!.lower, 100, accuracy: 0.001)
        XCTAssertEqual(block.steps[1].target!.upper, 140, accuracy: 0.001)

        guard case .step(let cooldown) = decoded.items[2] else { return XCTFail("expected step") }
        XCTAssertEqual(cooldown.role, .cooldown)
        XCTAssertEqual(cooldown.length, .open)
        XCTAssertNil(cooldown.target)
    }

    func testRoundTripDistanceAndSpeedTarget() throws {
        let original = WorkoutTemplate(name: "800s", sport: .run, items: [
            .step(Step(role: .work, length: .distance(meters: 800),
                       target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 1.0, upper: 1.05))),
        ])
        let decoded = try roundTrip(original)
        guard case .step(let step) = decoded.items[0] else { return XCTFail() }
        XCTAssertEqual(step.length, .distance(meters: 800))
        // Percent pace was resolved to absolute m/s at encode time; import
        // recovers absolute speed (4.0–4.2 m/s), not the original percent.
        XCTAssertEqual(step.target?.kind, .pace)
        XCTAssertEqual(step.target?.reference, .absolute)
        XCTAssertEqual(step.target!.lower, 4.0, accuracy: 0.005)
        XCTAssertEqual(step.target!.upper, 4.2, accuracy: 0.005)
    }

    func testRoundTripHeartRateAndCadence() throws {
        let original = WorkoutTemplate(name: "Z2+spin", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 1800),
                       target: IntensityTarget(kind: .heartRate, reference: .absolute, lower: 130, upper: 145))),
            .step(Step(role: .work, length: .time(seconds: 60),
                       target: IntensityTarget(kind: .cadence, reference: .absolute, lower: 95, upper: 110))),
        ])
        let decoded = try roundTrip(original)
        guard case .step(let hr) = decoded.items[0], case .step(let cad) = decoded.items[1] else {
            return XCTFail()
        }
        XCTAssertEqual(hr.target?.kind, .heartRate)
        XCTAssertEqual(hr.target!.lower, 130, accuracy: 0.001)
        XCTAssertEqual(hr.target!.upper, 145, accuracy: 0.001)
        XCTAssertEqual(cad.target?.kind, .cadence)
        XCTAssertEqual(cad.target!.lower, 95, accuracy: 0.001)
    }

    func testPowerZoneTargetImports() throws {
        let original = WorkoutTemplate(name: "Zone ride", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .power, reference: .zone, lower: 3, upper: 3))),
        ])
        let decoded = try roundTrip(original)
        guard case .step(let step) = decoded.items[0] else { return XCTFail() }
        XCTAssertEqual(step.target?.reference, .zone)
        XCTAssertEqual(step.target?.lower, 3)
    }

    func testOpenTargetImportsAsNoTarget() throws {
        let original = WorkoutTemplate(name: "Feel", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .rpe, reference: .absolute, lower: 6, upper: 7))),
        ])
        let decoded = try roundTrip(original)
        guard case .step(let step) = decoded.items[0] else { return XCTFail() }
        XCTAssertNil(step.target, "RPE degraded to open on export; import yields no target")
    }

    func testNonWorkoutFileThrows() {
        // An activity file is not a workout file.
        var writer = FITRecordWriter()
        writer.define(localType: 0, globalMessage: 0, fields: [(0, 1, .enumeration)])
        writer.appendData(localType: 0, values: [.uint8(4)]) // type 4 = activity
        let file = FITFileBuilder.wrap(records: writer.data)
        XCTAssertThrowsError(try FITWorkoutDecoder.decode(file)) {
            XCTAssertEqual($0 as? FITWorkoutDecodeError, .notAWorkoutFile)
        }
    }

    func testUnsupportedSportThrows() {
        var writer = FITRecordWriter()
        writer.define(localType: 0, globalMessage: 0, fields: [(0, 1, .enumeration)])
        writer.appendData(localType: 0, values: [.uint8(5)])
        writer.define(localType: 1, globalMessage: 26, fields: [(4, 1, .enumeration), (6, 2, .uint16)])
        writer.appendData(localType: 1, values: [.uint8(5), .uint16(0)]) // swimming
        let file = FITFileBuilder.wrap(records: writer.data)
        XCTAssertThrowsError(try FITWorkoutDecoder.decode(file)) {
            XCTAssertEqual($0 as? FITWorkoutDecodeError, .unsupportedSport(5))
        }
    }
}
