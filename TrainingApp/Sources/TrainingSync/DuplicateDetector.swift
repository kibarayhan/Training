import Foundation
import TrainingCore

/// Spec §7: the same session can arrive via several paths (HealthKit +
/// Karoo FIT + Zwift). Two activities are duplicates when they share an
/// externalID, or match on sport + start proximity + duration similarity.
public enum DuplicateDetector {

    public static let startProximitySeconds = 180.0
    public static let durationSimilarityTolerance = 0.15

    public static func areDuplicates(_ a: Activity, _ b: Activity) -> Bool {
        if !a.externalIDs.isEmpty, !Set(a.externalIDs).isDisjoint(with: b.externalIDs) {
            return true
        }
        guard a.sport == b.sport else { return false }
        guard abs(a.start.timeIntervalSince(b.start)) <= startProximitySeconds else { return false }
        let longer = max(a.movingSeconds, b.movingSeconds)
        guard longer > 0 else { return true }
        return abs(a.movingSeconds - b.movingSeconds) / longer <= durationSimilarityTolerance
    }

    /// Groups of 2+ activities that look like the same session (union-find
    /// over the pairwise relation).
    public static func duplicateGroups(in activities: [Activity]) -> [[Activity]] {
        var parent = Array(activities.indices)
        func find(_ i: Int) -> Int {
            var i = i
            while parent[i] != i { parent[i] = parent[parent[i]]; i = parent[i] }
            return i
        }
        func union(_ i: Int, _ j: Int) { parent[find(i)] = find(j) }

        for i in activities.indices {
            for j in activities.indices where j > i {
                if areDuplicates(activities[i], activities[j]) { union(i, j) }
            }
        }

        var groups: [Int: [Activity]] = [:]
        for i in activities.indices {
            groups[find(i), default: []].append(activities[i])
        }
        return groups.values.filter { $0.count > 1 }
            .sorted { $0[0].start < $1[0].start }
    }

    /// Merge a duplicate group into one activity: the recording with the
    /// most samples survives as the identity, missing summary fields are
    /// filled from the other copies.
    public static func merge(_ group: [Activity]) -> Activity {
        precondition(!group.isEmpty)
        var best = group.max { a, b in
            if a.samples.count != b.samples.count { return a.samples.count < b.samples.count }
            return a.movingSeconds < b.movingSeconds
        }!
        for other in group where other.id != best.id {
            // Union external IDs so re-importing ANY copy is idempotent.
            for id in other.externalIDs where !best.externalIDs.contains(id) {
                best.externalIDs.append(id)
            }
            best.distanceMeters = best.distanceMeters ?? other.distanceMeters
            best.elevationGainMeters = best.elevationGainMeters ?? other.elevationGainMeters
            best.averagePower = best.averagePower ?? other.averagePower
            best.averageHeartRate = best.averageHeartRate ?? other.averageHeartRate
            best.normalizedPower = best.normalizedPower ?? other.normalizedPower
            best.perceivedExertion = best.perceivedExertion ?? other.perceivedExertion
            best.elapsedSeconds = best.elapsedSeconds ?? other.elapsedSeconds
        }
        return best
    }
}
