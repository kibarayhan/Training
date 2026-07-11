import XCTest
@testable import TrainingCore

final class ThresholdStoreTests: XCTestCase {

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    func testValueBeforeFirstRecordIsNil() {
        let store = ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: day(2026, 3, 1)),
        ])
        XCTAssertNil(store.value(.ftp, sport: .ride, on: day(2026, 2, 28)))
    }

    func testValuePicksRecordValidOnDate() {
        let store = ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: day(2026, 1, 1)),
            ThresholdRecord(sport: .ride, kind: .ftp, value: 265, validFrom: day(2026, 6, 1)),
        ])
        XCTAssertEqual(store.value(.ftp, sport: .ride, on: day(2026, 3, 15)), 250)
        XCTAssertEqual(store.value(.ftp, sport: .ride, on: day(2026, 6, 1)), 265, "validFrom day itself uses the new value")
        XCTAssertEqual(store.value(.ftp, sport: .ride, on: day(2026, 12, 31)), 265)
    }

    func testHistoricalActivityScoredAgainstHistoricalThreshold() {
        // The spec's core requirement: January workouts stay scored against January FTP.
        let store = ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 200, validFrom: day(2025, 11, 1)),
            ThresholdRecord(sport: .ride, kind: .ftp, value: 260, validFrom: day(2026, 7, 1)),
        ])
        XCTAssertEqual(store.value(.ftp, sport: .ride, on: day(2026, 1, 10)), 200)
    }

    func testSameDayChangeLastAddedWins() {
        let store = ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: day(2026, 5, 1)),
            ThresholdRecord(sport: .ride, kind: .ftp, value: 255, validFrom: day(2026, 5, 1)),
        ])
        XCTAssertEqual(store.value(.ftp, sport: .ride, on: day(2026, 5, 2)), 255)
    }

    func testSportsAndKindsAreIndependent() {
        let store = ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: day(2026, 1, 1)),
            ThresholdRecord(sport: .ride, kind: .lthr, value: 168, validFrom: day(2026, 1, 1)),
            ThresholdRecord(sport: .run, kind: .lthr, value: 175, validFrom: day(2026, 1, 1)),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 3.85, validFrom: day(2026, 1, 1)),
        ])
        XCTAssertEqual(store.value(.lthr, sport: .ride, on: day(2026, 2, 1)), 168)
        XCTAssertEqual(store.value(.lthr, sport: .run, on: day(2026, 2, 1)), 175)
        XCTAssertEqual(store.value(.thresholdSpeed, sport: .run, on: day(2026, 2, 1)), 3.85)
        XCTAssertNil(store.value(.ftp, sport: .run, on: day(2026, 2, 1)), "run has no FTP record")
    }

    func testRecordsCodableRoundTrip() throws {
        let records = [
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 3.9, validFrom: day(2026, 4, 2)),
            ThresholdRecord(sport: .ride, kind: .ftp, value: 251, validFrom: day(2026, 4, 3)),
        ]
        let data = try JSONEncoder().encode(records)
        let decoded = try JSONDecoder().decode([ThresholdRecord].self, from: data)
        XCTAssertEqual(decoded, records)
    }
}
