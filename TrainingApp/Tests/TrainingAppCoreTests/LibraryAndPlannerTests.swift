import XCTest
import TrainingCore
@testable import TrainingAppCore

final class LibraryAndPlannerTests: XCTestCase {

    private func day(_ n: Int) -> Date { Date(timeIntervalSince1970: 1_767_225_600 + Double(n) * 86_400) }

    private func makeModel(today: Int = 50) -> TrainingAppModel {
        let model = TrainingAppModel(persistence: InMemoryPersistence(), now: { self.day(today) })
        model.setThreshold(.ftp, sport: .ride, value: 250)
        model.setThreshold(.thresholdSpeed, sport: .run, value: 4.0)
        return model
    }

    private func intervalTemplate(name: String = "4x3") -> WorkoutTemplate {
        WorkoutTemplate(name: name, sport: .ride, tags: ["vo2"], items: [
            .step(Step(role: .work, length: .time(seconds: 3600),
                       target: IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.9, upper: 1.0))),
        ])
    }

    // MARK: Library

    func testAddSearchAndFilterTemplates() {
        let model = makeModel()
        model.addTemplate(intervalTemplate(name: "4x3 threshold"))
        model.addTemplate(WorkoutTemplate(name: "Easy run", sport: .run, tags: ["easy"], items: []))

        XCTAssertEqual(model.templates(matching: "thresh").map(\.name), ["4x3 threshold"])
        XCTAssertEqual(model.templates(sport: .run).map(\.name), ["Easy run"])
        XCTAssertEqual(model.templates(tag: "vo2").count, 1)
        XCTAssertEqual(Set(model.allTags), ["vo2", "easy"])
    }

    func testTemplateEditPropagationChoice() {
        let model = makeModel(today: 50)
        var template = intervalTemplate()
        model.addTemplate(template)
        let pastID = model.schedule(templateID: template.id, on: day(10))!
        let futureID = model.schedule(templateID: template.id, on: day(60))!
        let detachedID = model.schedule(templateID: template.id, on: day(65))!
        model.detachInstance(detachedID)

        template.name = "4x3 v2"
        model.updateTemplate(template, propagateToFutureInstances: true)

        XCTAssertEqual(model.plannedWorkout(pastID)?.snapshot.name, "4x3",
                       "past instances are history; edits never touch them")
        XCTAssertEqual(model.plannedWorkout(futureID)?.snapshot.name, "4x3 v2")
        XCTAssertEqual(model.plannedWorkout(detachedID)?.snapshot.name, "4x3",
                       "detached instances keep their own content")
    }

    func testTemplateEditWithoutPropagation() {
        let model = makeModel(today: 50)
        var template = intervalTemplate()
        model.addTemplate(template)
        let futureID = model.schedule(templateID: template.id, on: day(60))!
        template.name = "4x3 v2"
        model.updateTemplate(template, propagateToFutureInstances: false)
        XCTAssertEqual(model.plannedWorkout(futureID)?.snapshot.name, "4x3")
        XCTAssertTrue(model.plannedWorkout(futureID)!.detachedFromTemplate,
                      "not propagating detaches the instance")
    }

    func testFITImportRoundTripIntoLibrary() throws {
        let model = makeModel()
        model.addTemplate(intervalTemplate(name: "Exported"))
        let data = try model.exportFIT(templateID: model.templates(matching: "Exported")[0].id)!
        let importedID = try model.importFITWorkout(data)
        XCTAssertEqual(model.template(importedID)?.name, "Exported")
        XCTAssertEqual(model.template(importedID)?.sport, .ride)
    }

    // MARK: Planner

    func testScheduleAndMove() {
        let model = makeModel()
        let template = intervalTemplate()
        model.addTemplate(template)
        let id = model.schedule(templateID: template.id, on: day(60))!
        XCTAssertEqual(model.plannedWorkouts(inWeekOf: day(60)).count, 1)
        model.move(plannedID: id, to: day(61))
        XCTAssertEqual(model.plannedWorkout(id)?.date, day(61))
    }

    func testDuplicateWeekCopiesForward() {
        let model = makeModel()
        let template = intervalTemplate()
        model.addTemplate(template)
        _ = model.schedule(templateID: template.id, on: day(56)) // Monday-ish anchor
        _ = model.schedule(templateID: template.id, on: day(58))
        model.duplicateWeek(from: day(56), to: day(63))
        XCTAssertEqual(model.plannedWorkouts(inWeekOf: day(63)).count, 2)
        XCTAssertEqual(model.plannedWorkouts(inWeekOf: day(63)).map(\.date).sorted(),
                       [day(63), day(65)])
    }

    func testPlannedWeekTotalsAndRampWarning() {
        let model = makeModel(today: 50)
        // Build a real fitness base: 40 days of hour-long rides at IF 0.8.
        model.ingest(activities: (0..<40).map {
            Activity(source: .healthKit, sport: .ride, start: day(10 + $0),
                     movingSeconds: 3600, normalizedPower: 200)
        })
        let template = intervalTemplate() // ~90 TSS estimate (0.95 mid IF)
        model.addTemplate(template)
        // day(53) is Monday 2026-02-23 — keep all six inside one ISO week.
        for offset in 0..<6 {
            _ = model.schedule(templateID: template.id, on: day(53 + offset))
        }
        let week = model.weekSummary(weekOf: day(53))
        XCTAssertEqual(week.plannedLoad, 6 * 90.25, accuracy: 1.0)
        // Chronic weekly ≈ CTL(≈40) × 7 ≈ 280; 540 planned > 1.3 × 280.
        XCTAssertTrue(week.rampWarning)
    }

    func testRampGuardQuietOnZeroBase() {
        let model = makeModel(today: 50)
        let template = intervalTemplate()
        model.addTemplate(template)
        _ = model.schedule(templateID: template.id, on: day(56))
        let week = model.weekSummary(weekOf: day(56))
        XCTAssertFalse(week.rampWarning)
    }

    func testTargetEventsCRUD() {
        let model = makeModel()
        let event = TargetEvent(name: "Race", date: day(100), sport: .ride)
        model.addEvent(event)
        XCTAssertEqual(model.events.count, 1)
        model.removeEvent(event.id)
        XCTAssertTrue(model.events.isEmpty)
    }

    func testSaveFailureIsSurfacedNotSwallowed() {
        final class FailingPersistence: Persistence {
            func load() -> AppState? { nil }
            func save(_ state: AppState) throws {
                throw NSError(domain: "disk", code: 28) // ENOSPC
            }
        }
        let model = TrainingAppModel(persistence: FailingPersistence(), now: { self.day(50) })
        XCTAssertNil(model.lastSaveError)
        model.addTemplate(intervalTemplate())
        XCTAssertNotNil(model.lastSaveError, "a failed save must be observable, not lost")
    }

    func testPersistenceRoundTrip() throws {
        let persistence = InMemoryPersistence()
        let model = TrainingAppModel(persistence: persistence, now: { self.day(50) })
        model.addTemplate(intervalTemplate())
        model.setThreshold(.ftp, sport: .ride, value: 250)
        _ = model.schedule(templateID: model.templates(matching: "4x3")[0].id, on: day(60))

        let reloaded = TrainingAppModel(persistence: persistence, now: { self.day(50) })
        XCTAssertEqual(reloaded.templates(matching: "4x3").count, 1)
        XCTAssertEqual(reloaded.plannedWorkouts(inWeekOf: day(60)).count, 1)
        XCTAssertEqual(reloaded.threshold(.ftp, sport: .ride, on: self.day(51)), 250)
    }
}
