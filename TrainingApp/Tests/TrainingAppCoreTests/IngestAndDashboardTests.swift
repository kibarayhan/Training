import XCTest
import TrainingCore
@testable import TrainingAppCore

final class IngestAndDashboardTests: XCTestCase {

    private func day(_ n: Int) -> Date { Date(timeIntervalSince1970: 1_767_225_600 + Double(n) * 86_400) }

    private final class FakeProvider: ActivityProvider {
        var pending: [Activity] = []
        func fetchActivities(since: Date?) throws -> [Activity] { pending }
    }

    private final class FakeScheduler: WorkoutScheduler {
        var synced: Set<UUID> = []
        var scheduled: [MappedWorkout] = []
        func currentlySynced() -> Set<UUID> { synced }
        func schedule(id: UUID, mapped: MappedWorkout) throws {
            synced.insert(id); scheduled.append(mapped)
        }
        func unschedule(id: UUID) throws { synced.remove(id) }
    }

    private func makeModel(today: Int = 50) -> (TrainingAppModel, FakeProvider) {
        let provider = FakeProvider()
        let model = TrainingAppModel(persistence: InMemoryPersistence(), now: { self.day(today) })
        model.activityProvider = provider
        model.setThreshold(.ftp, sport: .ride, value: 250)
        return (model, provider)
    }

    private func rideTemplate() -> WorkoutTemplate {
        WorkoutTemplate(name: "1h ride", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 3600),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.7, upper: 0.8))),
        ])
    }

    func testRefreshIngestsDedupesAndMatches() throws {
        let (model, provider) = makeModel()
        let template = rideTemplate()
        model.addTemplate(template)
        let plannedID = model.schedule(templateID: template.id, on: day(40))!

        let ride = Activity(source: .healthKit, externalIDs: ["hk-1"], sport: .ride,
                            start: day(40).addingTimeInterval(6 * 3600), movingSeconds: 3500)
        let dupe = Activity(source: .fitImport(device: "Karoo"), externalIDs: ["fit-9"], sport: .ride,
                            start: ride.start.addingTimeInterval(30), movingSeconds: 3480,
                            samples: [Sample(offsetSeconds: 0, power: 200)])
        provider.pending = [ride]
        try model.refreshActivities()
        model.ingest(activities: [dupe])

        XCTAssertEqual(model.activities.count, 1, "duplicate copies merged")
        XCTAssertEqual(Set(model.activities[0].externalIDs), ["hk-1", "fit-9"])
        XCTAssertEqual(model.compliance(for: plannedID), .completed)
        XCTAssertNotNil(model.plannedWorkout(plannedID)?.matchedActivityID)
    }

    func testReimportingKnownExternalIDIsIdempotent() throws {
        let (model, _) = makeModel()
        let ride = Activity(source: .fitImport(device: "Karoo"), externalIDs: ["fit-9"], sport: .ride,
                            start: day(40), movingSeconds: 3600)
        model.ingest(activities: [ride])
        model.ingest(activities: [ride])
        XCTAssertEqual(model.activities.count, 1)
    }

    func testManualRelinkPersists() {
        let (model, _) = makeModel()
        let template = rideTemplate()
        model.addTemplate(template)
        let plannedID = model.schedule(templateID: template.id, on: day(40))!
        let short = Activity(source: .healthKit, externalIDs: ["a"], sport: .ride,
                             start: day(40), movingSeconds: 800)
        let long = Activity(source: .healthKit, externalIDs: ["b"], sport: .ride,
                            start: day(41), movingSeconds: 3600)
        model.ingest(activities: [short, long])
        // Auto-match picked the same-day short ride; user relinks to the long one.
        model.relink(plannedID: plannedID, activityID: long.id)
        XCTAssertEqual(model.plannedWorkout(plannedID)?.matchedActivityID, long.id)
        XCTAssertEqual(model.compliance(for: plannedID), .completed,
                       "verdict recomputed after relink")
    }

    func testSyncPlanFillsWatchAndRemovesStale() throws {
        let (model, _) = makeModel(today: 50)
        let scheduler = FakeScheduler()
        let template = rideTemplate()
        model.addTemplate(template)
        for offset in 0..<20 { _ = model.schedule(templateID: template.id, on: day(51 + offset)) }
        let stale = UUID()
        scheduler.synced = [stale]

        let notes = try model.applySync(to: scheduler)
        XCTAssertEqual(scheduler.synced.count, 15)
        XCTAssertFalse(scheduler.synced.contains(stale))
        XCTAssertEqual(scheduler.scheduled.count, 15)
        XCTAssertTrue(notes.isEmpty, "clean power targets produce no degradation notes")
    }

    func testDashboardProjectionAndRaceForm() {
        let (model, _) = makeModel(today: 50)
        let template = rideTemplate()
        model.addTemplate(template)
        // 30 completed days, then a planned taper to a race.
        model.ingest(activities: (0..<30).map {
            Activity(source: .healthKit, externalIDs: ["r\($0)"], sport: .ride,
                     start: day(20 + $0), movingSeconds: 3600, normalizedPower: 210)
        })
        for offset in [52, 54, 56] { _ = model.schedule(templateID: template.id, on: day(offset)) }
        model.addEvent(TargetEvent(name: "Race", date: day(58), sport: .ride))

        let series = model.pmcSeries(from: day(20), to: day(58))
        XCTAssertEqual(series.count, 39)
        let raceForm = model.projectedForm(eventID: model.events[0].id)
        XCTAssertNotNil(raceForm)
        XCTAssertGreaterThan(raceForm!, series.first { $0.date == day(50) }!.tsb,
                             "taper into race day must raise form vs today")
    }

    func testWeeklyZoneTimeAggregation() {
        let (model, _) = makeModel()
        var samples: [Sample] = []
        for i in 0..<600 { samples.append(Sample(offsetSeconds: Double(i), power: 125)) } // Z1
        for i in 600..<1200 { samples.append(Sample(offsetSeconds: Double(i), power: 250)) } // Z4
        model.ingest(activities: [
            Activity(source: .healthKit, externalIDs: ["z"], sport: .ride,
                     start: day(40), movingSeconds: 1200, samples: samples),
        ])
        let zones = model.completedZoneTime(weekOf: day(40), sport: .ride, kind: .power)
        XCTAssertEqual(zones[1] ?? 0, 600, accuracy: 3)
        XCTAssertEqual(zones[4] ?? 0, 600, accuracy: 3)
    }
}
