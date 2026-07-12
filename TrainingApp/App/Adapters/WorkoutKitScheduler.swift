#if canImport(WorkoutKit)
import Foundation
import WorkoutKit
import HealthKit
import TrainingCore
import TrainingAppCore

/// Real WorkoutScheduler backed by WorkoutKit: converts a MappedWorkout into a
/// CustomWorkout and syncs it to the Watch. This is the ONLY place that
/// imports WorkoutKit — the mapping lives in TrainingCore and is fully tested;
/// here we just translate the mirror types into Apple's.
///
/// UNVERIFIED: written without a Mac. Spike B2 must confirm the goal/alert
/// initializers below match the shipping WorkoutKit API (they have shifted
/// across betas) and that scheduling round-trips through the Watch.
// `WorkoutScheduler` is exported by BOTH WorkoutKit (a class) and
// TrainingAppCore (our protocol), so every use must be qualified.
public final class WorkoutKitScheduler: TrainingAppCore.WorkoutScheduler {

    public init() {}

    public func requestAuthorization() async -> Bool {
        await WorkoutKit.WorkoutScheduler.shared.requestAuthorization() == .authorized
    }

    // TrainingAppCore tracks which plannedIDs are synced in its own state;
    // WorkoutKit's scheduled list is keyed by date, so we mirror ids here.
    private var syncedIDs: Set<UUID> = []

    public func currentlySynced() -> Set<UUID> { syncedIDs }

    public func schedule(id: UUID, mapped: MappedWorkout) throws {
        let custom = Self.customWorkout(from: mapped)
        let plan = WorkoutPlan(.custom(custom))
        Task {
            try? await WorkoutKit.WorkoutScheduler.shared.schedule(plan, at: nil)
        }
        syncedIDs.insert(id)
    }

    public func unschedule(id: UUID) throws {
        syncedIDs.remove(id)
        // Removal is by scheduled date in WorkoutKit; the app layer drives the
        // diff, and a full re-sync on the next applySync reconciles.
    }

    // MARK: - Mirror → WorkoutKit translation

    static func customWorkout(from mapped: MappedWorkout) -> CustomWorkout {
        let activity: HKWorkoutActivityType = mapped.sport == .ride ? .cycling : .running
        let blocks = mapped.blocks.map { block in
            IntervalBlock(
                steps: block.steps.map { intervalStep(purpose: $0.purpose, step: $0.step) },
                iterations: block.iterations)
        }
        return CustomWorkout(
            activity: activity,
            location: .outdoor,
            displayName: mapped.displayName,
            warmup: mapped.warmup.map { warmupStep(from: $0) },
            blocks: blocks,
            cooldown: mapped.cooldown.map { cooldownStep(from: $0) })
    }

    private static func warmupStep(from step: MappedStep) -> WorkoutStep {
        var s = WorkoutStep(goal: goal(from: step.goal))
        if let alert = alert(from: step.alert) { s.alert = alert }
        return s
    }

    private static func cooldownStep(from step: MappedStep) -> WorkoutStep {
        warmupStep(from: step)
    }

    private static func intervalStep(purpose: MappedPurpose, step: MappedStep) -> IntervalStep {
        var interval = IntervalStep(purpose == .work ? .work : .recovery,
                                    goal: goal(from: step.goal))
        if let alert = alert(from: step.alert) { interval.step.alert = alert }
        return interval
    }

    private static func goal(from goal: MappedGoal) -> WorkoutGoal {
        switch goal {
        case .time(let seconds): return .time(seconds, .seconds)
        case .distance(let meters): return .distance(meters, .meters)
        case .open: return .open
        }
    }

    private static func alert(from alert: MappedAlert?) -> (any WorkoutAlert)? {
        switch alert {
        case .powerRange(let lo, let hi):
            return PowerRangeAlert(target: Measurement(value: lo, unit: .watts)...Measurement(value: hi, unit: .watts))
        case .heartRateRange(let lo, let hi):
            return HeartRateRangeAlert(target: Int(lo)...Int(hi))
        case .speedRange(let lo, let hi):
            return SpeedRangeAlert(
                target: Measurement(value: lo, unit: .metersPerSecond)...Measurement(value: hi, unit: .metersPerSecond))
        case .cadenceRange(let lo, let hi):
            return CadenceRangeAlert(target: Int(lo)...Int(hi))
        case .none:
            return nil
        }
    }
}
#endif
