import Foundation

// Mirror types shaped 1:1 like WorkoutKit's CustomWorkout tree. Pure Swift
// so they compile and test on any platform; the Phase B adapter converts
// them to real WorkoutKit types with `import WorkoutKit` in a dozen lines.

public enum MappedGoal: Equatable, Sendable {
    case time(seconds: Double)
    case distance(meters: Double)
    case open
}

public enum MappedAlert: Equatable, Sendable {
    case powerRange(lowerWatts: Double, upperWatts: Double)
    case heartRateRange(lowerBPM: Double, upperBPM: Double)
    /// WorkoutKit expresses pace as speed.
    case speedRange(lowerMetersPerSecond: Double, upperMetersPerSecond: Double)
    case cadenceRange(lowerRPM: Double, upperRPM: Double)
}

public struct MappedStep: Equatable, Sendable {
    public var goal: MappedGoal
    public var alert: MappedAlert?
}

public enum MappedPurpose: Equatable, Sendable {
    case work
    case recovery
}

public struct MappedIntervalBlock: Equatable, Sendable {
    public var iterations: Int
    public var steps: [(purpose: MappedPurpose, step: MappedStep)]

    public static func == (lhs: MappedIntervalBlock, rhs: MappedIntervalBlock) -> Bool {
        lhs.iterations == rhs.iterations
            && lhs.steps.count == rhs.steps.count
            && zip(lhs.steps, rhs.steps).allSatisfy { $0.purpose == $1.purpose && $0.step == $1.step }
    }
}

public struct MappedWorkout: Sendable {
    public var sport: Sport
    public var displayName: String
    public var warmup: MappedStep?
    public var blocks: [MappedIntervalBlock]
    public var cooldown: MappedStep?
}

/// A lossy-mapping event, surfaced in the UI so the athlete knows what the
/// Watch will and won't alert on. The full matrix lives in docs/mapping-table.md.
public struct MappingNote: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case rpeHasNoDeviceAlert
        case unresolvableTarget
        case topZoneClamped
        case cadencePercentUnsupported
    }
    public var kind: Kind
    public var stepID: UUID
}

public enum WorkoutKitMapper {

    /// Factor applied to the lower bound to give the unbounded top zone a
    /// finite alert ceiling.
    public static let topZoneCeilingFactor = 1.25

    public static func map(workout: WorkoutTemplate, on date: Date,
                           thresholds: ThresholdStore,
                           zones: ZoneSettings) -> (workout: MappedWorkout, notes: [MappingNote]) {
        var notes: [MappingNote] = []
        var items = workout.items

        // WorkoutKit has exactly one warmup and one cooldown slot; they can
        // only absorb a LEADING warmup step / TRAILING cooldown step.
        var warmup: MappedStep?
        if case .step(let first)? = items.first, first.role == .warmup {
            warmup = mappedStep(first, sport: workout.sport, on: date,
                                thresholds: thresholds, zones: zones, notes: &notes)
            items.removeFirst()
        }
        var cooldown: MappedStep?
        if case .step(let last)? = items.last, last.role == .cooldown {
            cooldown = mappedStep(last, sport: workout.sport, on: date,
                                  thresholds: thresholds, zones: zones, notes: &notes)
            items.removeLast()
        }

        var blocks: [MappedIntervalBlock] = []
        for item in items {
            switch item {
            case .step(let step):
                blocks.append(MappedIntervalBlock(
                    iterations: 1,
                    steps: [(purpose(for: step.role),
                             mappedStep(step, sport: workout.sport, on: date,
                                        thresholds: thresholds, zones: zones, notes: &notes))]))
            case .repeatBlock(let block):
                blocks.append(MappedIntervalBlock(
                    iterations: max(block.count, 1),
                    steps: block.steps.map { step in
                        (purpose(for: step.role),
                         mappedStep(step, sport: workout.sport, on: date,
                                    thresholds: thresholds, zones: zones, notes: &notes))
                    }))
            }
        }

        return (MappedWorkout(sport: workout.sport, displayName: workout.name,
                              warmup: warmup, blocks: blocks, cooldown: cooldown),
                notes)
    }

    /// Mid-workout easy steps (warmup/recovery/cooldown/rest roles) all map
    /// to WorkoutKit's recovery purpose; only work is work.
    private static func purpose(for role: StepRole) -> MappedPurpose {
        role == .work ? .work : .recovery
    }

    private static func mappedStep(_ step: Step, sport: Sport, on date: Date,
                                   thresholds: ThresholdStore, zones: ZoneSettings,
                                   notes: inout [MappingNote]) -> MappedStep {
        let goal: MappedGoal
        switch step.length {
        case .time(let seconds): goal = .time(seconds: seconds)
        case .distance(let meters): goal = .distance(meters: meters)
        case .open: goal = .open
        }
        return MappedStep(goal: goal,
                          alert: alert(for: step, sport: sport, on: date,
                                       thresholds: thresholds, zones: zones, notes: &notes))
    }

    private static func alert(for step: Step, sport: Sport, on date: Date,
                              thresholds: ThresholdStore, zones: ZoneSettings,
                              notes: inout [MappingNote]) -> MappedAlert? {
        guard let target = step.target else { return nil }

        switch target.kind {
        case .rpe:
            notes.append(MappingNote(kind: .rpeHasNoDeviceAlert, stepID: step.id))
            return nil

        case .cadence:
            guard target.reference == .absolute else {
                notes.append(MappingNote(kind: .cadencePercentUnsupported, stepID: step.id))
                return nil
            }
            return .cadenceRange(lowerRPM: target.lower, upperRPM: target.upper)

        case .power, .heartRate, .pace:
            guard let resolved = resolvedOrAbsolute(target, sport: sport, on: date,
                                                    thresholds: thresholds, zones: zones) else {
                notes.append(MappingNote(kind: .unresolvableTarget, stepID: step.id))
                return nil
            }
            var upper = resolved.upper
            if !upper.isFinite {
                upper = resolved.lower * topZoneCeilingFactor
                notes.append(MappingNote(kind: .topZoneClamped, stepID: step.id))
            }
            switch target.kind {
            case .power:
                return .powerRange(lowerWatts: resolved.lower, upperWatts: upper)
            case .heartRate:
                return .heartRateRange(lowerBPM: resolved.lower, upperBPM: upper)
            case .pace:
                return .speedRange(lowerMetersPerSecond: resolved.lower, upperMetersPerSecond: upper)
            default:
                return nil
            }
        }
    }

    private static func resolvedOrAbsolute(_ target: IntensityTarget, sport: Sport, on date: Date,
                                           thresholds: ThresholdStore,
                                           zones: ZoneSettings) -> ResolvedTarget? {
        if target.reference == .absolute {
            return ResolvedTarget(kind: target.kind, lower: target.lower, upper: target.upper)
        }
        return target.resolved(sport: sport, on: date, thresholds: thresholds, zones: zones)
    }
}
