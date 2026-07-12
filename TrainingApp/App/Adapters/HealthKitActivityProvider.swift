#if canImport(HealthKit)
import Foundation
import HealthKit
import TrainingCore
import TrainingAppCore

/// Reads completed running/cycling workouts (and their power/HR/speed/cadence
/// samples) from HealthKit into TrainingCore Activities. This is the real
/// implementation of TrainingAppCore.ActivityProvider.
///
/// UNVERIFIED: written without a Mac; validate on device in Phase B spike B2.
/// The sample-type keys, unit choices, and statistics options are the parts
/// most likely to need adjustment against real HKWorkout data.
public final class HealthKitActivityProvider: ActivityProvider {

    private let store = HKHealthStore()

    public init() {}

    public static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        let quantities: [HKQuantityTypeIdentifier] = [
            .heartRate, .cyclingPower, .runningSpeed, .cyclingSpeed,
            .cyclingCadence, .runningPower, .distanceCycling, .distanceWalkingRunning,
        ]
        for id in quantities {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        return types
    }

    public func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    /// ActivityProvider is synchronous by design (keeps the model simple and
    /// testable). HealthKit's queries are completion-handler based and run on
    /// HealthKit's own internal queue, so we bridge with plain semaphores — no
    /// `Task`, so nothing blocks the Swift-concurrency cooperative pool. The
    /// model calls this from a background DispatchQueue, never the main actor.
    public func fetchActivities(since: Date?) throws -> [Activity] {
        let workouts = try fetchWorkouts(since: since)
        var activities: [Activity] = []
        for workout in workouts {
            guard let sport = Self.sport(from: workout.workoutActivityType) else { continue }
            activities.append(activity(from: workout, sport: sport))
        }
        return activities
    }

    private func fetchWorkouts(since: Date?) throws -> [HKWorkout] {
        let predicate: NSPredicate? = since.map {
            HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate)
        }
        var outcome: Result<[HKWorkout], Error> = .success([])
        let semaphore = DispatchSemaphore(value: 0)
        let query = HKSampleQuery(
            sampleType: .workoutType(), predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error { outcome = .failure(error) }
            else { outcome = .success((samples as? [HKWorkout]) ?? []) }
            semaphore.signal()
        }
        store.execute(query)
        semaphore.wait()
        return try outcome.get()
    }

    private static func sport(from type: HKWorkoutActivityType) -> Sport? {
        switch type {
        case .running: return .run
        case .cycling: return .ride
        default: return nil
        }
    }

    private func activity(from workout: HKWorkout, sport: Sport) -> Activity {
        let power = sport == .ride ? HKQuantityType.quantityType(forIdentifier: .cyclingPower)
                                   : HKQuantityType.quantityType(forIdentifier: .runningPower)
        let avgPower = averageQuantity(power, in: workout, unit: .watt())
        let avgHR = averageQuantity(
            HKQuantityType.quantityType(forIdentifier: .heartRate), in: workout,
            unit: HKUnit.count().unitDivided(by: .minute()))

        let distance = workout.totalDistance?.doubleValue(for: .meter())
        // HKWorkout.duration is active (moving) time; wall-clock end−start is
        // elapsed, which is ≥ duration when the recording had pauses.
        let moving = workout.duration
        let elapsed = workout.endDate.timeIntervalSince(workout.startDate)

        return Activity(
            source: .healthKit,
            externalIDs: [workout.uuid.uuidString],
            sport: sport,
            start: workout.startDate,
            movingSeconds: moving,
            elapsedSeconds: elapsed,
            distanceMeters: distance,
            elevationGainMeters: (workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?
                .doubleValue(for: .meter()),
            averagePower: avgPower,
            averageHeartRate: avgHR,
            samples: [])  // Detailed sample series loaded lazily; see note below.
    }

    private func averageQuantity(_ type: HKQuantityType?, in workout: HKWorkout,
                                 unit: HKUnit) -> Double? {
        guard let type else { return nil }
        var value: Double?
        let semaphore = DispatchSemaphore(value: 0)
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(
            quantityType: type, quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, stats, _ in
            value = stats?.averageQuantity()?.doubleValue(for: unit)
            semaphore.signal()
        }
        store.execute(query)
        semaphore.wait()
        return value
    }
}
#endif
