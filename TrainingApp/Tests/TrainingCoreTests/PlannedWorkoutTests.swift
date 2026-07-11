import XCTest
@testable import TrainingCore

final class PlannedWorkoutTests: XCTestCase {

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    private func template() -> WorkoutTemplate {
        WorkoutTemplate(name: "Tempo", sport: .run, items: [
            .step(Step(role: .work, length: .time(seconds: 1200),
                       target: IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 0.9, upper: 0.95))),
        ])
    }

    func testSchedulingSnapshotsTemplate() {
        var tpl = template()
        let planned = PlannedWorkout(template: tpl, date: day(2026, 7, 20))

        // Later template edit must not leak into the scheduled instance.
        tpl.name = "Tempo v2"
        tpl.items = []

        XCTAssertEqual(planned.snapshot.name, "Tempo")
        XCTAssertEqual(planned.snapshot.items.count, 1)
        XCTAssertEqual(planned.templateID, tpl.id, "instance remembers its origin template")
        XCTAssertFalse(planned.detachedFromTemplate)
    }

    func testDetachedInstanceFlagged() {
        var planned = PlannedWorkout(template: template(), date: day(2026, 7, 20))
        planned.snapshot.items.append(.step(Step(role: .cooldown, length: .open, target: nil)))
        planned.detachedFromTemplate = true
        XCTAssertTrue(planned.detachedFromTemplate)
    }

    func testAdHocPlannedWorkoutWithoutTemplate() {
        // Spec: unstructured planned entries ("2h easy ride") exist without a template.
        let planned = PlannedWorkout(
            adHoc: WorkoutSnapshot(name: "2h easy", sport: .ride, items: []),
            date: day(2026, 7, 21),
            estimatedDurationSeconds: 7200)
        XCTAssertNil(planned.templateID)
        XCTAssertEqual(planned.estimatedDurationSeconds, 7200)
    }

    func testSportComesFromSnapshot() {
        let planned = PlannedWorkout(template: template(), date: day(2026, 7, 20))
        XCTAssertEqual(planned.sport, .run)
    }

    func testCodableRoundTrip() throws {
        let planned = PlannedWorkout(template: template(), date: day(2026, 7, 20))
        let data = try JSONEncoder().encode(planned)
        XCTAssertEqual(try JSONDecoder().decode(PlannedWorkout.self, from: data), planned)
    }

    func testTargetEventCodable() throws {
        let event = TargetEvent(name: "Berlin Marathon", date: day(2026, 9, 27), sport: .run)
        let data = try JSONEncoder().encode(event)
        XCTAssertEqual(try JSONDecoder().decode(TargetEvent.self, from: data), event)
    }
}
