import Foundation

/// The frozen content of a workout at scheduling time.
public struct WorkoutSnapshot: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var sport: Sport
    public var items: [WorkoutItem]

    public init(name: String, sport: Sport, items: [WorkoutItem]) {
        self.name = name
        self.sport = sport
        self.items = items
    }

    public var flattenedSteps: [Step] { items.flattenedSteps }
}

public enum Compliance: String, Codable, Equatable, Sendable {
    case completed
    case substituted
    case missed
    case unplanned
}

public struct PlannedWorkout: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var snapshot: WorkoutSnapshot
    /// Origin template, nil for ad-hoc entries ("2h easy ride").
    public var templateID: UUID?
    /// True once the instance was edited away from its template.
    public var detachedFromTemplate: Bool
    /// For unstructured entries without steps; structured entries derive
    /// duration from their steps.
    public var estimatedDurationSeconds: Double?
    public var note: String?
    /// Set by the matching engine.
    public var matchedActivityID: UUID?

    public var sport: Sport { snapshot.sport }

    public init(template: WorkoutTemplate, date: Date, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.snapshot = WorkoutSnapshot(name: template.name, sport: template.sport, items: template.items)
        self.templateID = template.id
        self.detachedFromTemplate = false
        self.estimatedDurationSeconds = nil
        self.note = note
        self.matchedActivityID = nil
    }

    public init(adHoc snapshot: WorkoutSnapshot, date: Date,
                estimatedDurationSeconds: Double? = nil, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.snapshot = snapshot
        self.templateID = nil
        self.detachedFromTemplate = false
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.note = note
        self.matchedActivityID = nil
    }
}

public struct TargetEvent: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var date: Date
    public var sport: Sport?

    public init(id: UUID = UUID(), name: String, date: Date, sport: Sport? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.sport = sport
    }
}
