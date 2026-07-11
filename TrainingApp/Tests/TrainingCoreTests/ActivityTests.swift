import XCTest
@testable import TrainingCore

final class ActivityTests: XCTestCase {

    func testActivityConstructionAndCodable() throws {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let activity = Activity(
            source: .fitImport(device: "Karoo"),
            externalID: "fit-123",
            sport: .ride,
            start: start,
            movingSeconds: 3600,
            distanceMeters: 30_000,
            elevationGainMeters: 250,
            averagePower: 180,
            averageHeartRate: 142,
            normalizedPower: 195,
            perceivedExertion: nil,
            samples: [
                Sample(offsetSeconds: 0, power: 150, heartRate: 120, speed: 8.0, cadence: 90),
                Sample(offsetSeconds: 1, power: 210, heartRate: 121, speed: 8.2, cadence: 91),
            ])
        let data = try JSONEncoder().encode(activity)
        let decoded = try JSONDecoder().decode(Activity.self, from: data)
        XCTAssertEqual(decoded, activity)
        XCTAssertEqual(decoded.samples.count, 2)
    }

    func testSourcesAreDistinguishable() {
        XCTAssertNotEqual(ActivitySource.healthKit, ActivitySource.fitImport(device: nil))
        XCTAssertNotEqual(ActivitySource.fitImport(device: "Garmin"), ActivitySource.manual)
    }

    func testEndDateUsesElapsedWhenAvailable() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        // 2h ride with 20min of stops: wall-clock end comes from elapsed time,
        // so dedup windows overlap the HealthKit copy of the same ride.
        let paused = Activity(source: .manual, sport: .ride, start: start,
                              movingSeconds: 7200, elapsedSeconds: 8400)
        XCTAssertEqual(paused.end, start.addingTimeInterval(8400))

        let noPauses = Activity(source: .manual, sport: .run, start: start, movingSeconds: 1800)
        XCTAssertEqual(noPauses.end, start.addingTimeInterval(1800), "falls back to moving time")
    }
}
