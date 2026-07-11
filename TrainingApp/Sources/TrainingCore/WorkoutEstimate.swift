import Foundation

public struct WorkoutEstimate: Equatable, Sendable {
    public var load: Double
    public var durationSeconds: Double
    /// Predicted seconds per zone (1-based), for kinds with a zone model.
    public var zoneSeconds: [Int: Double]
    /// False when there was nothing to estimate from (no steps, no duration) —
    /// the planner must flag such entries rather than project a rest day.
    public var hasEstimate: Bool = true
}

/// Estimated load and time-in-zone for a workout's steps — the number shown
/// in the builder and the input the projection uses for future workouts.
public enum WorkoutEstimator {

    /// Assumed duration of an open (lap-button) step.
    public static let openStepSeconds = 300.0
    /// Fallback speeds for distance steps without a resolvable pace target.
    static let defaultSpeed: [Sport: Double] = [.run: 3.0, .ride: 8.0]
    /// IF assumed for steps whose target is missing or unresolvable.
    static let roleDefaultIF: [StepRole: Double] = [
        .warmup: 0.6, .work: 0.7, .recovery: 0.5, .cooldown: 0.5, .rest: 0.3,
    ]

    public static func estimate(workout: WorkoutTemplate, on date: Date,
                                thresholds: ThresholdStore, zones: ZoneSettings) -> WorkoutEstimate {
        estimate(sport: workout.sport, steps: workout.flattenedSteps,
                 on: date, thresholds: thresholds, zones: zones)
    }

    public static func estimate(planned: PlannedWorkout,
                                thresholds: ThresholdStore, zones: ZoneSettings) -> WorkoutEstimate {
        let steps = planned.snapshot.flattenedSteps
        if steps.isEmpty {
            // No steps and no duration is unestimable: hasEstimate lets the
            // planner surface it instead of silently projecting a rest day.
            let seconds = planned.estimatedDurationSeconds ?? 0
            return WorkoutEstimate(
                load: LoadCalculator.trainingLoad(seconds: seconds,
                                                  intensityFactor: LoadCalculator.defaultIF),
                durationSeconds: seconds,
                zoneSeconds: [:],
                hasEstimate: seconds > 0)
        }
        return estimate(sport: planned.sport, steps: steps,
                        on: planned.date, thresholds: thresholds, zones: zones)
    }

    static func estimate(sport: Sport, steps: [Step], on date: Date,
                         thresholds: ThresholdStore, zones: ZoneSettings) -> WorkoutEstimate {
        var load = 0.0
        var duration = 0.0
        var zoneSeconds: [Int: Double] = [:]

        for step in steps {
            let intensity = intensityFactor(for: step, sport: sport, on: date,
                                            thresholds: thresholds, zones: zones)
            let seconds = durationSeconds(for: step, sport: sport, intensityFactor: intensity.factor,
                                          on: date, thresholds: thresholds)
            duration += seconds
            load += LoadCalculator.trainingLoad(seconds: seconds, intensityFactor: intensity.factor)

            if let kind = intensity.kind, let absolute = intensity.absoluteMid,
               let thresholdKind = ThresholdStore.thresholdKind(for: kind, sport: sport),
               let threshold = thresholds.value(thresholdKind, sport: sport, on: date),
               let model = zones.model(sport: sport, kind: kind),
               let zone = model.zone(forValue: absolute, threshold: threshold) {
                zoneSeconds[zone, default: 0] += seconds
            }
        }
        return WorkoutEstimate(load: load, durationSeconds: duration, zoneSeconds: zoneSeconds)
    }

    private struct StepIntensity {
        var factor: Double
        /// Target kind when the factor came from a resolvable target.
        var kind: TargetKind?
        /// Absolute midpoint in native units, for zone classification.
        var absoluteMid: Double?
    }

    private static func intensityFactor(for step: Step, sport: Sport, on date: Date,
                                        thresholds: ThresholdStore,
                                        zones: ZoneSettings) -> StepIntensity {
        let roleDefault = StepIntensity(factor: roleDefaultIF[step.role] ?? 0.6,
                                        kind: nil, absoluteMid: nil)
        guard let target = step.target else { return roleDefault }

        if target.kind == .rpe {
            let mid = (target.lower + target.upper) / 2
            return StepIntensity(factor: mid / LoadCalculator.thresholdRPE,
                                 kind: nil, absoluteMid: nil)
        }
        if target.kind == .cadence { return roleDefault }

        guard let thresholdKind = ThresholdStore.thresholdKind(for: target.kind, sport: sport),
              let threshold = thresholds.value(thresholdKind, sport: sport, on: date),
              threshold > 0,
              let resolved = target.resolved(sport: sport, on: date,
                                             thresholds: thresholds, zones: zones) else {
            return roleDefault
        }
        // The top zone resolves with an unbounded upper edge; approximate its
        // midpoint just above the lower edge instead of averaging to infinity.
        let mid = resolved.upper.isFinite
            ? (resolved.lower + resolved.upper) / 2
            : resolved.lower * 1.1
        return StepIntensity(factor: mid / threshold, kind: target.kind, absoluteMid: mid)
    }

    private static func durationSeconds(for step: Step, sport: Sport, intensityFactor: Double,
                                        on date: Date, thresholds: ThresholdStore) -> Double {
        switch step.length {
        case .time(let seconds):
            return seconds
        case .open:
            return openStepSeconds
        case .distance(let meters):
            if step.target?.kind == .pace,
               let thresholdSpeed = thresholds.value(.thresholdSpeed, sport: sport, on: date),
               thresholdSpeed > 0 {
                let speed = intensityFactor * thresholdSpeed
                if speed > 0 { return meters / speed }
            }
            let fallback = defaultSpeed[sport] ?? 3.0
            return meters / fallback
        }
    }
}
