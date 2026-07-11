import XCTest
@testable import TrainingCore

final class WorkoutModelTests: XCTestCase {

    private func makeIntervalWorkout() -> WorkoutTemplate {
        WorkoutTemplate(
            name: "4x3min threshold",
            sport: .ride,
            tags: ["intervals", "threshold"],
            items: [
                .step(Step(role: .warmup, length: .time(seconds: 600),
                           target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.50, upper: 0.65))),
                .repeatBlock(RepeatBlock(count: 4, steps: [
                    Step(role: .work, length: .time(seconds: 180),
                         target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.98, upper: 1.05)),
                    Step(role: .recovery, length: .time(seconds: 120),
                         target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.40, upper: 0.55)),
                ])),
                .step(Step(role: .cooldown, length: .open, target: nil)),
            ])
    }

    func testFlattenedStepsExpandsRepeats() {
        let workout = makeIntervalWorkout()
        let steps = workout.flattenedSteps
        // warmup + 4 * (work + recovery) + cooldown
        XCTAssertEqual(steps.count, 1 + 4 * 2 + 1)
        XCTAssertEqual(steps.first?.role, .warmup)
        XCTAssertEqual(steps[1].role, .work)
        XCTAssertEqual(steps[2].role, .recovery)
        XCTAssertEqual(steps.last?.role, .cooldown)
    }

    func testKnownDurationSumsTimeSteps() {
        let workout = makeIntervalWorkout()
        // 600 warmup + 4*(180+120); the open cooldown contributes 0 to *known* time
        XCTAssertEqual(workout.knownDurationSeconds, 600 + 4 * 300)
    }

    func testStepsWithAllLengthTypes() {
        let steps = [
            Step(role: .work, length: .time(seconds: 300), target: nil),
            Step(role: .work, length: .distance(meters: 800), target: nil),
            Step(role: .work, length: .open, target: nil),
        ]
        XCTAssertEqual(steps[0].length, .time(seconds: 300))
        XCTAssertEqual(steps[1].length, .distance(meters: 800))
        XCTAssertEqual(steps[2].length, .open)
    }

    func testTemplateCodableRoundTrip() throws {
        let workout = makeIntervalWorkout()
        let data = try JSONEncoder().encode(workout)
        let decoded = try JSONDecoder().decode(WorkoutTemplate.self, from: data)
        XCTAssertEqual(decoded, workout)
    }

    func testValidationRejectsBadValues() {
        let bad = WorkoutTemplate(name: "", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: -5), target: nil)),
            .repeatBlock(RepeatBlock(count: 0, steps: [])),
            .step(Step(role: .work, length: .time(seconds: 60),
                       target: IntensityTarget(kind: .power, reference: .absolute, lower: 300, upper: 250))),
        ])
        let issues = bad.validate()
        XCTAssertTrue(issues.contains(.emptyName))
        XCTAssertTrue(issues.contains(.nonPositiveStepLength))
        XCTAssertTrue(issues.contains(.emptyRepeatBlock))
        XCTAssertTrue(issues.contains(.nonPositiveRepeatCount))
        XCTAssertTrue(issues.contains(.invertedTargetRange))
    }

    func testValidWorkoutHasNoIssues() {
        XCTAssertTrue(makeIntervalWorkout().validate().isEmpty)
    }

    func testRPETargetNeedsNoThreshold() {
        let step = Step(role: .work, length: .time(seconds: 1200),
                        target: IntensityTarget(kind: .rpe, reference: .absolute, lower: 6, upper: 7))
        XCTAssertEqual(step.target?.kind, .rpe)
    }
}
