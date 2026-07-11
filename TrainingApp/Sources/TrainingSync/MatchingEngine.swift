import Foundation
import TrainingCore

public struct MatchResult {
    /// plannedID → activityID
    public private(set) var assignments: [UUID: UUID]
    /// plannedID → compliance; future workouts are absent (no verdict yet).
    public private(set) var compliance: [UUID: Compliance]
    public private(set) var unplannedActivityIDs: [UUID]

    /// Manual override: point a planned workout at a different activity.
    /// The displaced activity becomes unplanned again. The stale verdict is
    /// cleared, not guessed — callers persist the link on the model
    /// (PlannedWorkout.matchedActivityID) and re-run match(), whose
    /// pre-pinned pass recomputes the duration-based verdict.
    public mutating func relink(plannedID: UUID, to activityID: UUID) {
        if let previous = assignments[plannedID], previous != activityID {
            unplannedActivityIDs.append(previous)
        }
        assignments[plannedID] = activityID
        unplannedActivityIDs.removeAll { $0 == activityID }
        compliance[plannedID] = nil
    }

    init(assignments: [UUID: UUID], compliance: [UUID: Compliance], unplannedActivityIDs: [UUID]) {
        self.assignments = assignments
        self.compliance = compliance
        self.unplannedActivityIDs = unplannedActivityIDs
    }
}

/// Spec §7: auto-match completed activities to planned workouts of the same
/// sport within ±1 day; same-day wins, then duration similarity. Compliance
/// is judged coarsely (duration vs estimate) until per-step interval
/// detection exists post-MVP — the API already returns per-planned verdicts
/// so that upgrade won't change callers.
public enum MatchingEngine {

    static let dayWindow = 1
    /// Matched activities within this duration ratio of the estimate count
    /// as completed; beyond it they're substitutions.
    static let completedDurationTolerance = 0.4

    public static func match(planned: [PlannedWorkout], activities: [Activity],
                             thresholds: ThresholdStore, zones: ZoneSettings,
                             today: Date) -> MatchResult {
        var assignments: [UUID: UUID] = [:]
        var compliance: [UUID: Compliance] = [:]
        var takenActivities: Set<UUID> = []

        func dayIndex(_ date: Date) -> Int { date.utcDayIndex }
        let todayIndex = dayIndex(today)

        // Pre-pinned matches (user overrides persisted on the model) hold.
        for p in planned {
            if let pinned = p.matchedActivityID {
                assignments[p.id] = pinned
                takenActivities.insert(pinned)
            }
        }

        struct Candidate {
            var plannedID: UUID
            var activityID: UUID
            var dayDistance: Int
            var durationScore: Double
        }

        var candidates: [Candidate] = []
        for p in planned where assignments[p.id] == nil {
            let estimate = WorkoutEstimator.estimate(planned: p, thresholds: thresholds, zones: zones)
            for a in activities where !takenActivities.contains(a.id) {
                guard a.sport == p.sport else { continue }
                let distance = abs(dayIndex(a.start) - dayIndex(p.date))
                guard distance <= dayWindow else { continue }
                let durationScore = estimate.durationSeconds > 0
                    ? abs(a.movingSeconds - estimate.durationSeconds) / estimate.durationSeconds
                    : 0
                candidates.append(Candidate(plannedID: p.id, activityID: a.id,
                                            dayDistance: distance, durationScore: durationScore))
            }
        }

        // Greedy best-first: same day beats adjacent day, then closest duration.
        candidates.sort {
            if $0.dayDistance != $1.dayDistance { return $0.dayDistance < $1.dayDistance }
            return $0.durationScore < $1.durationScore
        }
        for c in candidates {
            guard assignments[c.plannedID] == nil, !takenActivities.contains(c.activityID) else { continue }
            assignments[c.plannedID] = c.activityID
            takenActivities.insert(c.activityID)
        }

        // Compliance verdicts.
        let activityByID = Dictionary(uniqueKeysWithValues: activities.map { ($0.id, $0) })
        for p in planned {
            if let activityID = assignments[p.id] {
                let estimate = WorkoutEstimator.estimate(planned: p, thresholds: thresholds, zones: zones)
                if let activity = activityByID[activityID],
                   estimate.hasEstimate, estimate.durationSeconds > 0 {
                    let deviation = abs(activity.movingSeconds - estimate.durationSeconds)
                        / estimate.durationSeconds
                    compliance[p.id] = deviation <= completedDurationTolerance ? .completed : .substituted
                } else {
                    compliance[p.id] = .completed
                }
            } else if dayIndex(p.date) < todayIndex {
                compliance[p.id] = .missed
            }
            // Future unmatched planned workouts get no verdict.
        }

        let unplanned = activities.filter { !takenActivities.contains($0.id) }.map(\.id)
        return MatchResult(assignments: assignments, compliance: compliance,
                           unplannedActivityIDs: unplanned)
    }
}
