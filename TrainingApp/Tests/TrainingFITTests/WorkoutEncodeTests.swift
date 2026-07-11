import XCTest
import TrainingCore
@testable import TrainingFIT

final class WorkoutEncodeTests: XCTestCase {

    private let day = Date(timeIntervalSince1970: 1_770_000_000)

    private var thresholds: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
            ThresholdRecord(sport: .ride, kind: .lthr, value: 165, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 4.0, validFrom: .distantPast),
        ])
    }

    private func intervalWorkout() -> WorkoutTemplate {
        WorkoutTemplate(name: "4x3 threshold", sport: .ride, items: [
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
    }

    private func encodeAndParse(_ workout: WorkoutTemplate) throws -> [FITMessage] {
        let data = try FITWorkoutEncoder.encode(
            workout: workout, on: day, thresholds: thresholds, zones: .defaults)
        XCTAssertEqual(FITCRC.compute(data), 0, "file CRC must self-check")
        return try FITMessageReader.messages(from: data)
    }

    func testFileIDIdentifiesWorkoutFile() throws {
        let messages = try encodeAndParse(intervalWorkout())
        let fileID = messages.first { $0.globalMessage == 0 }
        XCTAssertNotNil(fileID)
        XCTAssertEqual(fileID?.value(field: 0), 5, "file type 5 == workout")
    }

    func testWorkoutMessageHasSportAndStepCount() throws {
        let messages = try encodeAndParse(intervalWorkout())
        let workoutMsg = messages.first { $0.globalMessage == 26 }
        XCTAssertNotNil(workoutMsg)
        XCTAssertEqual(workoutMsg?.value(field: 4), 2, "FIT sport 2 == cycling")
        // warmup + work + recovery + repeat-step + cooldown = 5 FIT steps
        XCTAssertEqual(workoutMsg?.value(field: 6), 5)
        XCTAssertEqual(workoutMsg?.string(field: 8), "4x3 threshold")
    }

    func testStepsEncodeDurationsTargetsAndIntensity() throws {
        let messages = try encodeAndParse(intervalWorkout())
        let steps = messages.filter { $0.globalMessage == 27 }
        XCTAssertEqual(steps.count, 5)

        // Step 0: warmup, 600s = 600_000 ms, power percent range 50–65 (%FTP), intensity warmup(2)
        XCTAssertEqual(steps[0].value(field: 254), 0, "message_index")
        XCTAssertEqual(steps[0].value(field: 1), 0, "duration_type time")
        XCTAssertEqual(steps[0].value(field: 2), 600_000)
        XCTAssertEqual(steps[0].value(field: 3), 4, "target_type power")
        XCTAssertEqual(steps[0].value(field: 4), 0, "custom range marker")
        XCTAssertEqual(steps[0].value(field: 5), 50)
        XCTAssertEqual(steps[0].value(field: 6), 65)
        XCTAssertEqual(steps[0].value(field: 7), 2, "intensity warmup")

        // Step 1: work 180s, %FTP 98–105
        XCTAssertEqual(steps[1].value(field: 2), 180_000)
        XCTAssertEqual(steps[1].value(field: 5), 98)
        XCTAssertEqual(steps[1].value(field: 6), 105)
        XCTAssertEqual(steps[1].value(field: 7), 0, "intensity active")

        // Step 2: recovery with absolute watts → 1000 + watts
        XCTAssertEqual(steps[2].value(field: 5), 1100)
        XCTAssertEqual(steps[2].value(field: 6), 1140)

        // Step 3: repeat from step index 1, 4 times
        XCTAssertEqual(steps[3].value(field: 1), 6, "duration_type repeat_until_steps_cmplt")
        XCTAssertEqual(steps[3].value(field: 2), 1, "repeat from message_index 1")
        XCTAssertEqual(steps[3].value(field: 4), 4, "repetition count")

        // Step 4: open cooldown
        XCTAssertEqual(steps[4].value(field: 1), 5, "duration_type open")
        XCTAssertEqual(steps[4].value(field: 3), 2, "target_type open")
        XCTAssertEqual(steps[4].value(field: 7), 3, "intensity cooldown")
    }

    func testDistanceStepEncodesCentimeters() throws {
        let workout = WorkoutTemplate(name: "Track", sport: .run, items: [
            .step(Step(role: .work, length: .distance(meters: 800),
                       target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 1.0, upper: 1.0))),
        ])
        let messages = try encodeAndParse(workout)
        let step = messages.first { $0.globalMessage == 27 }
        XCTAssertEqual(step?.value(field: 1), 1, "duration_type distance")
        XCTAssertEqual(step?.value(field: 2), 80_000, "800m in cm")
        // pace percent resolved against threshold speed 4 m/s → 4000 mm/s both bounds
        XCTAssertEqual(step?.value(field: 3), 0, "target_type speed")
        XCTAssertEqual(step?.value(field: 5), 4000)
        XCTAssertEqual(step?.value(field: 6), 4000)
    }

    func testHeartRateTargetEncodesBPMPlus100() throws {
        let workout = WorkoutTemplate(name: "Z2 ride", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 1800),
                       target: IntensityTarget(kind: .heartRate, reference: .absolute, lower: 130, upper: 145))),
        ])
        let messages = try encodeAndParse(workout)
        let step = messages.first { $0.globalMessage == 27 }
        XCTAssertEqual(step?.value(field: 3), 1, "target_type heart rate")
        XCTAssertEqual(step?.value(field: 5), 230)
        XCTAssertEqual(step?.value(field: 6), 245)
    }

    func testCadenceTarget() throws {
        let workout = WorkoutTemplate(name: "Spin ups", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 60),
                       target: IntensityTarget(kind: .cadence, reference: .absolute, lower: 95, upper: 110))),
        ])
        let messages = try encodeAndParse(workout)
        let step = messages.first { $0.globalMessage == 27 }
        XCTAssertEqual(step?.value(field: 3), 3, "target_type cadence")
        XCTAssertEqual(step?.value(field: 5), 95)
        XCTAssertEqual(step?.value(field: 6), 110)
    }

    func testRPEAndUnresolvableTargetsBecomeOpen() throws {
        let workout = WorkoutTemplate(name: "Feel", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .rpe, reference: .absolute, lower: 6, upper: 7))),
            // HR percent needs LTHR; the run store has none → open target
            .step(Step(role: .work, length: .time(seconds: 600),
                       target: IntensityTarget(kind: .heartRate, reference: .percentOfThreshold, lower: 0.8, upper: 0.9))),
        ])
        let messages = try encodeAndParse(workout)
        let steps = messages.filter { $0.globalMessage == 27 }
        XCTAssertEqual(steps[0].value(field: 3), 2, "RPE exports as open target")
        XCTAssertEqual(steps[1].value(field: 3), 2, "unresolvable percent HR exports as open")
    }

    func testRunSportEncoded() throws {
        let workout = WorkoutTemplate(name: "Run", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: 60), target: nil)),
        ])
        let messages = try encodeAndParse(workout)
        XCTAssertEqual(messages.first { $0.globalMessage == 26 }?.value(field: 4), 1, "FIT sport 1 == running")
    }
}
