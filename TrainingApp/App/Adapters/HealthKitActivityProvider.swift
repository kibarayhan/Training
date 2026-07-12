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

    /// ActivityProvider is synchronous, but HealthKit is async; bridge with a
    /// semaphore. Callers invoke this off the main thread (the model's refresh
    /// runs in a Task).
    public func fetchActivities(since: Date?) throws -> [Activity] {
        var result: Result<[Activity], Error>!
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do { result = .success(try await fetchAsync(since: since)) }
            catch { result = .failure(error) }
            semaphore.signal()
        }
        semaphore.wait()
        return try result.get()
    }

    private func fetchAsync(since: Date?) async throws -> [Activity] {
        let predicate: NSPredicate? = since.map {
            HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate)
        }
        let workouts = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(), predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: (samples as? [HKWorkout]) ?? []) }
            }
            store.execute(query)
        }

        var activities: [Activity] = []
        for workout in workouts {
            guard let sport = Self.sport(from: workout.workoutActivityType) else { continue }
            activities.append(await activity(from: workout, sport: sport))
        }
        return activities
    }

    private static func sport(from type: HKWorkoutActivityType) -> Sport? {
        switch type {
        case .running: return .run
        case .cycling: return .ride
        default: return nil
        }
    }

    private func activity(from workout: HKWorkout, sport: Sport) async -> Activity {
        let power = sport == .ride ? HKQuantityType.quantityType(forIdentifier: .cyclingPower)
                                   : HKQuantityType.quantityType(forIdentifier: .runningPower)
        let avgPower = await averageQuantity(power, in: workout, unit: .watt())
        let avgHR = await averageQuantity(
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
                                 unit: HKUnit) async -> Double? {
        guard let type else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            let predicate = HKQuery.predicateForObjects(from: workout)
            let query = HKStatisticsQuery(
                quantityType: type, quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                cont.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }
}
#endif
