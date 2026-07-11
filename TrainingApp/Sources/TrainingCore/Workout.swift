import Foundation

public enum Sport: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case run
    case ride
}

public enum StepRole: String, Codable, CaseIterable, Equatable, Sendable {
    case warmup
    case work
    case recovery
    case cooldown
    case rest
}

public enum StepLength: Codable, Equatable, Hashable, Sendable {
    case time(seconds: Double)
    case distance(meters: Double)
    /// Open-ended step, terminated by the athlete (lap button).
    case open
}

public enum TargetKind: String, Codable, CaseIterable, Equatable, Sendable {
    case power
    case pace
    case heartRate
    case cadence
    case rpe
}

/// How a target's lower/upper values are interpreted.
public enum TargetReference: String, Codable, Equatable, Sendable {
    /// Native units: watts, m/s (pace stored as speed), bpm, rpm, or RPE 0–10.
    case absolute
    /// Fraction of the sport's threshold for this kind (1.0 == threshold).
    case percentOfThreshold
    /// Zone number in the athlete's zone model (lower == upper == zone).
    case zone
}

public struct IntensityTarget: Codable, Equatable, Hashable, Sendable {
    public var kind: TargetKind
    public var reference: TargetReference
    public var lower: Double
    public var upper: Double

    public init(kind: TargetKind, reference: TargetReference, lower: Double, upper: Double) {
        self.kind = kind
        self.reference = reference
        self.lower = lower
        self.upper = upper
    }
}

public struct Step: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var role: StepRole
    public var length: StepLength
    public var target: IntensityTarget?
    public var note: String?

    public init(id: UUID = UUID(), role: StepRole, length: StepLength,
                target: IntensityTarget?, note: String? = nil) {
        self.id = id
        self.role = role
        self.length = length
        self.target = target
        self.note = note
    }
}

/// Single-level repeat: a block of steps executed `count` times.
/// Nesting is impossible by construction — blocks contain only `Step`s.
public struct RepeatBlock: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var count: Int
    public var steps: [Step]

    public init(id: UUID = UUID(), count: Int, steps: [Step]) {
        self.id = id
        self.count = count
        self.steps = steps
    }
}

public enum WorkoutItem: Codable, Equatable, Hashable, Identifiable, Sendable {
    case step(Step)
    case repeatBlock(RepeatBlock)

    public var id: UUID {
        switch self {
        case .step(let s): return s.id
        case .repeatBlock(let b): return b.id
        }
    }
}

extension Array where Element == WorkoutItem {
    /// Shared flattening used by WorkoutTemplate and WorkoutSnapshot.
    public var flattenedSteps: [Step] {
        flatMap { item -> [Step] in
            switch item {
            case .step(let s):
                return [s]
            case .repeatBlock(let block):
                return (0..<Swift.max(block.count, 0)).flatMap { _ in block.steps }
            }
        }
    }
}

public struct WorkoutTemplate: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var sport: Sport
    public var tags: [String]
    public var folder: String?
    public var notes: String?
    public var items: [WorkoutItem]

    public init(id: UUID = UUID(), name: String, sport: Sport, tags: [String] = [],
                folder: String? = nil, notes: String? = nil, items: [WorkoutItem]) {
        self.id = id
        self.name = name
        self.sport = sport
        self.tags = tags
        self.folder = folder
        self.notes = notes
        self.items = items
    }

    /// All steps in execution order, with repeat blocks expanded.
    /// NOTE: steps inside a repeat block appear once per iteration with the
    /// SAME `id` (the id names the template step, not the occurrence) — key
    /// occurrence-sensitive consumers (UI lists, per-step compliance) by
    /// position, not id.
    public var flattenedSteps: [Step] { items.flattenedSteps }

    /// Sum of all time-based step durations. Distance and open steps
    /// contribute nothing here; load estimation handles them separately.
    public var knownDurationSeconds: Double {
        flattenedSteps.reduce(0) { total, step in
            if case .time(let seconds) = step.length { return total + seconds }
            return total
        }
    }
}

// MARK: - Validation

public enum WorkoutValidationIssue: Equatable, Sendable {
    case emptyName
    case nonPositiveStepLength
    case emptyRepeatBlock
    case nonPositiveRepeatCount
    case invertedTargetRange
}

extension WorkoutTemplate {
    public func validate() -> [WorkoutValidationIssue] {
        var issues: [WorkoutValidationIssue] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyName)
        }
        var allSteps: [Step] = []
        for item in items {
            switch item {
            case .step(let s):
                allSteps.append(s)
            case .repeatBlock(let block):
                if block.steps.isEmpty { issues.append(.emptyRepeatBlock) }
                if block.count < 1 { issues.append(.nonPositiveRepeatCount) }
                allSteps.append(contentsOf: block.steps)
            }
        }
        for step in allSteps {
            switch step.length {
            case .time(let s) where s <= 0: issues.append(.nonPositiveStepLength)
            case .distance(let m) where m <= 0: issues.append(.nonPositiveStepLength)
            default: break
            }
            if let target = step.target, target.lower > target.upper {
                issues.append(.invertedTargetRange)
            }
        }
        return issues
    }
}
