import XCTest
import TrainingCore
@testable import TrainingSync

final class MatchingTests: XCTestCase {

    // UTC midnights
    private func day(_ n: Int) -> Date { Date(timeIntervalSince1970: 1_767_225_600 + Double(n) * 86_400) }
    private func at(_ n: Int, hour: Int) -> Date { day(n).addingTimeInterval(Double(hour) * 3600) }

    private func plannedHourRide(on n: Int) -> PlannedWorkout {
        let template = WorkoutTemplate(name: "1h steady", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 3600),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.7, upper: 0.8))),
        ])
        return PlannedWorkout(template: template, date: day(n))
    }

    private func ride(on n: Int, hour: Int = 10, seconds: Double = 3600) -> Activity {
        Activity(source: .healthKit, sport: .ride, start: at(n, hour: hour), movingSeconds: seconds)
    }

    private func run(_ engineInput: ([PlannedWorkout], [Activity]), today: Int = 100) -> MatchResult {
        MatchingEngine.match(planned: engineInput.0, activities: engineInput.1,
                             thresholds: ThresholdStore(records: []), zones: .defaults,
                             today: day(today))
    }

    func testSameDayActivityMatches() {
        let planned = plannedHourRide(on: 10)
        let activity = ride(on: 10)
        let result = run(([planned], [activity]))
        XCTAssertEqual(result.assignments[planned.id], activity.id)
        XCTAssertEqual(result.compliance[planned.id], .completed)
    }

    func testDayLateActivityMatches() {
        let planned = plannedHourRide(on: 10)
        let activity = ride(on: 11)
        let result = run(([planned], [activity]))
        XCTAssertEqual(result.assignments[planned.id], activity.id)
    }

    func testTwoDaysLateDoesNotMatch() {
        let planned = plannedHourRide(on: 10)
        let activity = ride(on: 12)
        let result = run(([planned], [activity]))
        XCTAssertNil(result.assignments[planned.id])
        XCTAssertEqual(result.compliance[planned.id], .missed)
        XCTAssertEqual(result.unplannedActivityIDs, [activity.id])
    }

    func testDifferentSportNeverMatches() {
        let planned = plannedHourRide(on: 10)
        let activity = Activity(source: .healthKit, sport: .run, start: at(10, hour: 9), movingSeconds: 3600)
        let result = run(([planned], [activity]))
        XCTAssertNil(result.assignments[planned.id])
    }

    func testSameDayPreferredOverAdjacentDay() {
        let planned = plannedHourRide(on: 10)
        let adjacent = ride(on: 9)
        let sameDay = ride(on: 10)
        let result = run(([planned], [adjacent, sameDay]))
        XCTAssertEqual(result.assignments[planned.id], sameDay.id)
        XCTAssertEqual(result.unplannedActivityIDs, [adjacent.id])
    }

    func testDurationSimilarityBreaksTies() {
        let planned = plannedHourRide(on: 10) // estimated 3600s
        let short = ride(on: 10, hour: 8, seconds: 900)
        let matching = ride(on: 10, hour: 16, seconds: 3500)
        let result = run(([planned], [short, matching]))
        XCTAssertEqual(result.assignments[planned.id], matching.id)
    }

    func testEachActivityMatchesAtMostOnePlanned() {
        let p1 = plannedHourRide(on: 10)
        let p2 = plannedHourRide(on: 10)
        let activity = ride(on: 10)
        let result = run(([p1, p2], [activity]))
        let matched = [p1.id, p2.id].compactMap { result.assignments[$0] }
        XCTAssertEqual(matched.count, 1, "one activity cannot complete two planned workouts")
        // The other planned workout is missed (it's in the past).
        let unmatchedID = result.assignments[p1.id] == nil ? p1.id : p2.id
        XCTAssertEqual(result.compliance[unmatchedID], .missed)
    }

    func testVeryDifferentDurationClassifiedSubstituted() {
        let planned = plannedHourRide(on: 10) // 3600s estimate
        let activity = ride(on: 10, seconds: 1200) // rode a third of it
        let result = run(([planned], [activity]))
        XCTAssertEqual(result.assignments[planned.id], activity.id)
        XCTAssertEqual(result.compliance[planned.id], .substituted)
    }

    func testFuturePlannedWorkoutNotMissed() {
        let planned = plannedHourRide(on: 200) // after today=100
        let result = run(([planned], []))
        XCTAssertNil(result.compliance[planned.id], "future workouts have no compliance yet")
    }

    func testManualRelinkOverridesAutoMatch() {
        let planned = plannedHourRide(on: 10)
        let auto = ride(on: 10)
        let other = ride(on: 11, seconds: 1000)
        var result = run(([planned], [auto, other]))
        XCTAssertEqual(result.assignments[planned.id], auto.id)
        result.relink(plannedID: planned.id, to: other.id)
        XCTAssertEqual(result.assignments[planned.id], other.id)
        XCTAssertTrue(result.unplannedActivityIDs.contains(auto.id))
        XCTAssertFalse(result.unplannedActivityIDs.contains(other.id))
        XCTAssertNil(result.compliance[planned.id],
                     "relink clears the stale verdict; persisting the pin and re-matching recomputes it")
    }

    func testPreMatchedPlannedRespected() {
        // A planned workout already carrying matchedActivityID keeps it.
        var planned = plannedHourRide(on: 10)
        let pinned = ride(on: 11, seconds: 1000)
        let better = ride(on: 10)
        planned.matchedActivityID = pinned.id
        let result = run(([planned], [pinned, better]))
        XCTAssertEqual(result.assignments[planned.id], pinned.id)
        XCTAssertTrue(result.unplannedActivityIDs.contains(better.id))
    }
}
