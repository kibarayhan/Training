import XCTest
import TrainingCore
@testable import TrainingSync

final class SyncWindowTests: XCTestCase {

    private func day(_ n: Int) -> Date { Date(timeIntervalSince1970: 1_767_225_600 + Double(n) * 86_400) }

    private func planned(on n: Int, matched: Bool = false) -> PlannedWorkout {
        let template = WorkoutTemplate(name: "W\(n)", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 3600), target: nil)),
        ])
        var p = PlannedWorkout(template: template, date: day(n))
        if matched { p.matchedActivityID = UUID() }
        return p
    }

    func testSelectsAtMostFifteenNearestUpcoming() {
        let month = (0..<40).map { planned(on: $0) }
        let selection = SyncWindow.select(planned: month, today: day(5))
        XCTAssertEqual(selection.count, 15)
        XCTAssertEqual(selection.first?.date, day(5), "today's workout syncs first")
        XCTAssertEqual(selection.last?.date, day(19))
    }

    func testPastWorkoutsExcluded() {
        let items = [planned(on: 1), planned(on: 2), planned(on: 10)]
        let selection = SyncWindow.select(planned: items, today: day(5))
        XCTAssertEqual(selection.map(\.date), [day(10)])
    }

    func testCompletedWorkoutsExcluded() {
        let done = planned(on: 6, matched: true)
        let todo = planned(on: 7)
        let selection = SyncWindow.select(planned: [done, todo], today: day(5))
        XCTAssertEqual(selection.map(\.id), [todo.id])
    }

    func testStableOrderingForSameDay() {
        let a = planned(on: 6)
        let b = planned(on: 6)
        let first = SyncWindow.select(planned: [a, b], today: day(5))
        let second = SyncWindow.select(planned: [b, a], today: day(5))
        XCTAssertEqual(first.map(\.id), second.map(\.id),
                       "same-day ordering must not depend on input order")
    }

    func testDiffPlan() {
        let keep = planned(on: 6)
        let add = planned(on: 7)
        let stale = UUID() // synced previously, no longer selected
        let selection = [keep, add]
        let diff = SyncWindow.diff(selection: selection, currentlySynced: [keep.id, stale])
        XCTAssertEqual(diff.toAdd.map(\.id), [add.id])
        XCTAssertEqual(diff.toRemove, [stale])
    }

    func testEmptyPlanSyncsNothing() {
        XCTAssertTrue(SyncWindow.select(planned: [], today: day(0)).isEmpty)
    }
}
