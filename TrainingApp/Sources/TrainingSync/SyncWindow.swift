import Foundation
import TrainingCore

/// WorkoutKit accepts at most 15 scheduled workouts at a time (spec §6):
/// keep the nearest upcoming, uncompleted ones synced, and compute the
/// add/remove diff against what's already on the Watch.
public enum SyncWindow {

    public static let capacity = 15

    public static func select(planned: [PlannedWorkout], today: Date) -> [PlannedWorkout] {
        let todayIndex = today.utcDayIndex
        return planned
            .filter { $0.date.utcDayIndex >= todayIndex && $0.matchedActivityID == nil }
            .sorted {
                if $0.date != $1.date { return $0.date < $1.date }
                return $0.id.uuidString < $1.id.uuidString
            }
            .prefix(capacity)
            .map { $0 }
    }

    public struct Diff {
        public var toAdd: [PlannedWorkout]
        public var toRemove: [UUID]
    }

    public static func diff(selection: [PlannedWorkout], currentlySynced: Set<UUID>) -> Diff {
        let selectedIDs = Set(selection.map(\.id))
        return Diff(
            toAdd: selection.filter { !currentlySynced.contains($0.id) },
            toRemove: currentlySynced.subtracting(selectedIDs).sorted { $0.uuidString < $1.uuidString })
    }
}
