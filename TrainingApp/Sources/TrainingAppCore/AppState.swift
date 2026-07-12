import Foundation
import TrainingCore

/// The whole persisted world of the app. MVP persistence is a JSON snapshot
/// (local-first, no server per spec §2); CloudKit backup arrives after Apple
/// Developer enrollment as another Persistence conformance.
public struct AppState: Codable, Equatable {
    public var templates: [WorkoutTemplate] = []
    public var planned: [PlannedWorkout] = []
    public var activities: [Activity] = []
    public var thresholds: ThresholdStore = ThresholdStore(records: [])
    public var zones: ZoneSettings = .defaults
    public var events: [TargetEvent] = []

    public init() {}
}

public protocol Persistence {
    func load() -> AppState?
    /// Throws on failure so the model can surface it — a silently dropped
    /// save loses the user's edits with no warning (a full-disk iPhone is
    /// the realistic trigger).
    func save(_ state: AppState) throws
}

public final class InMemoryPersistence: Persistence {
    private var stored: AppState?
    public init() {}
    public func load() -> AppState? { stored }
    public func save(_ state: AppState) { stored = state }
}

/// Atomic JSON file snapshot — good enough for a personal tool's data volume
/// and trivially inspectable/exportable (GDPR §10 of the spec).
public final class JSONFilePersistence: Persistence {
    private let url: URL
    public init(url: URL) { self.url = url }

    public func load() -> AppState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppState.self, from: data)
    }

    public func save(_ state: AppState) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: .atomic)
    }
}

/// HealthKit stand-in (Phase C1 provides the real one).
public protocol ActivityProvider {
    func fetchActivities(since: Date?) throws -> [Activity]
}

/// WorkoutKit stand-in (Phase C1 provides the real one).
public protocol WorkoutScheduler {
    func currentlySynced() -> Set<UUID>
    func schedule(id: UUID, mapped: MappedWorkout) throws
    func unschedule(id: UUID) throws
}
