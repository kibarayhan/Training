import Foundation
import TrainingCore
import TrainingFIT
import TrainingSync

public struct WeekSummary: Equatable {
    public var plannedLoad: Double
    public var plannedSeconds: Double
    public var rampWarning: Bool
}

/// The app's root model: every screen talks to this, and everything it does
/// is platform-independent and tested on Linux. SwiftUI observes it through
/// a thin @Observable wrapper in the App layer; `onChange` fires after every
/// mutation for that purpose.
public final class TrainingAppModel {

    private var state: AppState
    private let persistence: Persistence
    private let now: () -> Date
    public var activityProvider: ActivityProvider?
    public var onChange: (() -> Void)?
    /// Set when a save fails (e.g. disk full); the UI observes this to warn
    /// the user instead of losing edits silently. Cleared on the next success.
    public private(set) var lastSaveError: Error?

    private var lastCompliance: [UUID: Compliance] = [:]
    private var lastUnplanned: [UUID] = []

    public init(persistence: Persistence, now: @escaping () -> Date = Date.init) {
        self.persistence = persistence
        self.now = now
        self.state = persistence.load() ?? AppState()
        rematch()
    }

    private func persist() {
        do {
            try persistence.save(state)
            lastSaveError = nil
        } catch {
            lastSaveError = error
        }
        onChange?()
    }

    // MARK: - Thresholds & zones

    public func setThreshold(_ kind: ThresholdKind, sport: Sport, value: Double,
                             validFrom: Date = .distantPast) {
        state.thresholds.add(ThresholdRecord(sport: sport, kind: kind,
                                             value: value, validFrom: validFrom))
        rematch()
        persist()
    }

    public func threshold(_ kind: ThresholdKind, sport: Sport, on date: Date) -> Double? {
        state.thresholds.value(kind, sport: sport, on: date)
    }

    public var zoneSettings: ZoneSettings { state.zones }

    public func setZoneModel(_ model: ZoneModel, sport: Sport, kind: TargetKind) {
        state.zones.set(model, sport: sport, kind: kind)
        persist()
    }

    // MARK: - Library

    public func addTemplate(_ template: WorkoutTemplate) {
        state.templates.append(template)
        persist()
    }

    /// Spec §4 edit semantics: past instances never change; future
    /// non-detached instances either follow the edit or detach.
    public func updateTemplate(_ template: WorkoutTemplate, propagateToFutureInstances: Bool) {
        guard let index = state.templates.firstIndex(where: { $0.id == template.id }) else { return }
        state.templates[index] = template
        let todayIndex = now().utcDayIndex
        for i in state.planned.indices
        where state.planned[i].templateID == template.id
            && !state.planned[i].detachedFromTemplate
            && state.planned[i].date.utcDayIndex >= todayIndex {
            if propagateToFutureInstances {
                state.planned[i].snapshot = WorkoutSnapshot(
                    name: template.name, sport: template.sport, items: template.items)
            } else {
                state.planned[i].detachedFromTemplate = true
            }
        }
        persist()
    }

    public func removeTemplate(_ id: UUID) {
        state.templates.removeAll { $0.id == id }
        persist()
    }

    public func template(_ id: UUID) -> WorkoutTemplate? {
        state.templates.first { $0.id == id }
    }

    public func templates(matching text: String? = nil, sport: Sport? = nil,
                          tag: String? = nil, folder: String? = nil) -> [WorkoutTemplate] {
        state.templates.filter { t in
            (text.map { t.name.localizedCaseInsensitiveContains($0) } ?? true)
                && (sport.map { t.sport == $0 } ?? true)
                && (tag.map { t.tags.contains($0) } ?? true)
                && (folder.map { t.folder == $0 } ?? true)
        }
    }

    public var allTags: [String] {
        var seen: Set<String> = []
        return state.templates.flatMap(\.tags).filter { seen.insert($0).inserted }
    }

    public func exportFIT(templateID: UUID) throws -> Data? {
        guard let template = template(templateID) else { return nil }
        return try FITWorkoutEncoder.encode(workout: template, on: now(),
                                            thresholds: state.thresholds, zones: state.zones)
    }

    public func importFITWorkout(_ data: Data) throws -> UUID {
        let template = try FITWorkoutDecoder.decode(data)
        state.templates.append(template)
        persist()
        return template.id
    }

    // MARK: - Planner

    public func schedule(templateID: UUID, on date: Date) -> UUID? {
        guard let template = template(templateID) else { return nil }
        let planned = PlannedWorkout(template: template, date: date)
        state.planned.append(planned)
        persist()
        return planned.id
    }

    public func scheduleAdHoc(name: String, sport: Sport, on date: Date,
                              estimatedDurationSeconds: Double?) -> UUID {
        let planned = PlannedWorkout(
            adHoc: WorkoutSnapshot(name: name, sport: sport, items: []),
            date: date, estimatedDurationSeconds: estimatedDurationSeconds)
        state.planned.append(planned)
        persist()
        return planned.id
    }

    public func plannedWorkout(_ id: UUID) -> PlannedWorkout? {
        state.planned.first { $0.id == id }
    }

    public func move(plannedID: UUID, to date: Date) {
        guard let i = state.planned.firstIndex(where: { $0.id == plannedID }) else { return }
        state.planned[i].date = date
        rematch()
        persist()
    }

    public func removePlanned(_ id: UUID) {
        state.planned.removeAll { $0.id == id }
        persist()
    }

    public func detachInstance(_ id: UUID) {
        guard let i = state.planned.firstIndex(where: { $0.id == id }) else { return }
        state.planned[i].detachedFromTemplate = true
        persist()
    }

    public func plannedWorkouts(inWeekOf date: Date) -> [PlannedWorkout] {
        let start = Self.isoWeekStart(of: date)
        return state.planned
            .filter { Self.isoWeekStart(of: $0.date) == start }
            .sorted { $0.date < $1.date }
    }

    public func duplicateWeek(from source: Date, to destination: Date) {
        let offset = Self.isoWeekStart(of: destination).timeIntervalSince(Self.isoWeekStart(of: source))
        for original in plannedWorkouts(inWeekOf: source) {
            var copy = PlannedWorkout(adHoc: original.snapshot,
                                      date: original.date.addingTimeInterval(offset),
                                      estimatedDurationSeconds: original.estimatedDurationSeconds)
            copy.templateID = original.templateID
            copy.detachedFromTemplate = original.detachedFromTemplate
            state.planned.append(copy)
        }
        persist()
    }

    public func weekSummary(weekOf date: Date) -> WeekSummary {
        var load = 0.0
        var seconds = 0.0
        for planned in plannedWorkouts(inWeekOf: date) {
            let estimate = WorkoutEstimator.estimate(planned: planned,
                                                     thresholds: state.thresholds,
                                                     zones: state.zones)
            load += estimate.load
            seconds += estimate.durationSeconds
        }
        return WeekSummary(plannedLoad: load, plannedSeconds: seconds,
                           rampWarning: RampGuard.isExcessive(plannedWeekLoad: load,
                                                              currentCTL: currentCTL()))
    }

    // MARK: - Events

    public var events: [TargetEvent] { state.events }

    public func addEvent(_ event: TargetEvent) {
        state.events.append(event)
        persist()
    }

    public func removeEvent(_ id: UUID) {
        state.events.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Ingest & matching

    public var activities: [Activity] { state.activities.sorted { $0.start < $1.start } }

    public func ingest(activities newActivities: [Activity]) {
        let knownIDs = Set(state.activities.flatMap(\.externalIDs))
        let fresh = newActivities.filter {
            $0.externalIDs.isEmpty || Set($0.externalIDs).isDisjoint(with: knownIDs)
        }
        guard !fresh.isEmpty else { return }
        state.activities.append(contentsOf: fresh)

        for group in DuplicateDetector.duplicateGroups(in: state.activities) {
            let merged = DuplicateDetector.merge(group)
            let groupIDs = Set(group.map(\.id))
            // Planned workouts pinned to a merged-away copy follow the survivor.
            for i in state.planned.indices
            where state.planned[i].matchedActivityID.map(groupIDs.contains) == true {
                state.planned[i].matchedActivityID = merged.id
            }
            state.activities.removeAll { groupIDs.contains($0.id) }
            state.activities.append(merged)
        }
        rematch()
        persist()
    }

    public func refreshActivities() throws {
        guard let provider = activityProvider else { return }
        ingest(activities: try provider.fetchActivities(since: state.activities.map(\.end).max()))
    }

    public func importFITActivity(_ data: Data) throws {
        ingest(activities: [try FITActivityDecoder.decode(data)])
    }

    public func relink(plannedID: UUID, activityID: UUID) {
        guard let i = state.planned.firstIndex(where: { $0.id == plannedID }) else { return }
        state.planned[i].matchedActivityID = activityID
        rematch()
        persist()
    }

    public func compliance(for plannedID: UUID) -> Compliance? {
        lastCompliance[plannedID]
    }

    public var unplannedActivityIDs: [UUID] { lastUnplanned }

    private func rematch() {
        let result = MatchingEngine.match(planned: state.planned, activities: state.activities,
                                          thresholds: state.thresholds, zones: state.zones,
                                          today: now())
        lastCompliance = state.planned.reduce(into: [:]) { acc, p in
            acc[p.id] = result.compliance[p.id]
        }
        lastUnplanned = result.unplannedActivityIDs
        // Persist auto-matches so they survive restarts and stay stable;
        // relink() remains the manual override.
        for i in state.planned.indices {
            if let match = result.assignments[state.planned[i].id] {
                state.planned[i].matchedActivityID = match
            }
        }
    }

    // MARK: - Watch sync

    public func applySync(to scheduler: WorkoutScheduler) throws -> [MappingNote] {
        let selection = SyncWindow.select(planned: state.planned, today: now())
        let diff = SyncWindow.diff(selection: selection,
                                   currentlySynced: scheduler.currentlySynced())
        for id in diff.toRemove {
            try scheduler.unschedule(id: id)
        }
        var allNotes: [MappingNote] = []
        for planned in diff.toAdd {
            let template = WorkoutTemplate(name: planned.snapshot.name,
                                           sport: planned.sport,
                                           items: planned.snapshot.items)
            let (mapped, notes) = WorkoutKitMapper.map(workout: template, on: planned.date,
                                                       thresholds: state.thresholds,
                                                       zones: state.zones)
            try scheduler.schedule(id: planned.id, mapped: mapped)
            allNotes.append(contentsOf: notes)
        }
        return allNotes
    }

    // MARK: - Dashboard

    private func dailyLoads() -> [DailyLoad] {
        var loads: [DailyLoad] = []
        for activity in state.activities {
            if let result = LoadCalculator.load(for: activity, thresholds: state.thresholds) {
                loads.append(DailyLoad(date: activity.start, sport: activity.sport,
                                       load: result.value))
            }
        }
        let todayIndex = now().utcDayIndex
        for planned in state.planned
        where planned.date.utcDayIndex >= todayIndex && planned.matchedActivityID == nil {
            let estimate = WorkoutEstimator.estimate(planned: planned,
                                                     thresholds: state.thresholds,
                                                     zones: state.zones)
            if estimate.hasEstimate {
                loads.append(DailyLoad(date: planned.date, sport: planned.sport,
                                       load: estimate.load))
            }
        }
        return loads
    }

    public func pmcSeries(from: Date, to: Date) -> [PMCPoint] {
        PMCEngine.series(loads: dailyLoads(), from: from, to: to)
    }

    public func currentCTL() -> Double {
        pmcSeries(from: now(), to: now()).last?.ctl ?? 0
    }

    public func projectedForm(eventID: UUID) -> Double? {
        guard let event = state.events.first(where: { $0.id == eventID }) else { return nil }
        let series = pmcSeries(from: event.date, to: event.date)
        return PMCEngine.form(on: event.date, in: series)
    }

    public func completedZoneTime(weekOf date: Date, sport: Sport,
                                  kind: TargetKind) -> [Int: Double] {
        let start = Self.isoWeekStart(of: date)
        var total: [Int: Double] = [:]
        for activity in state.activities
        where activity.sport == sport && Self.isoWeekStart(of: activity.start) == start {
            for (zone, seconds) in ZoneTime.seconds(for: activity, kind: kind,
                                                    thresholds: state.thresholds,
                                                    zones: state.zones) {
                total[zone, default: 0] += seconds
            }
        }
        return total
    }

    public func weeklyTotals() -> [WeekTotals] {
        WeeklyAggregator.totals(activities: state.activities, thresholds: state.thresholds)
    }

    // MARK: - Helpers

    static func isoWeekStart(of date: Date) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
