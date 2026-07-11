import XCTest
@testable import TrainingCore

final class AggregationTests: XCTestCase {

    // Monday 2026-01-05 00:00 UTC — start of ISO week 2, 2026.
    private let monday = Date(timeIntervalSince1970: 1_767_571_200)
    private func date(dayOffset: Int, hour: Int = 10) -> Date {
        monday.addingTimeInterval(Double(dayOffset) * 86_400 + Double(hour) * 3600)
    }

    private var thresholds: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
        ])
    }

    func testWeeklyTotalsGroupBySportAndWeek() {
        let activities = [
            Activity(source: .manual, sport: .ride, start: date(dayOffset: 0),
                     movingSeconds: 3600, distanceMeters: 30_000, elevationGainMeters: 200,
                     normalizedPower: 250),
            Activity(source: .manual, sport: .ride, start: date(dayOffset: 2),
                     movingSeconds: 1800, distanceMeters: 15_000, elevationGainMeters: 100,
                     normalizedPower: 250),
            Activity(source: .manual, sport: .run, start: date(dayOffset: 1),
                     movingSeconds: 2400, distanceMeters: 8_000, perceivedExertion: 7),
            // Next ISO week:
            Activity(source: .manual, sport: .ride, start: date(dayOffset: 7),
                     movingSeconds: 3600, distanceMeters: 28_000, normalizedPower: 125),
        ]
        let weeks = WeeklyAggregator.totals(activities: activities, thresholds: thresholds)

        XCTAssertEqual(weeks.count, 2)
        let week1 = weeks[0]
        let rideW1 = week1.bySport[.ride]!
        XCTAssertEqual(rideW1.seconds, 5400)
        XCTAssertEqual(rideW1.distanceMeters, 45_000)
        XCTAssertEqual(rideW1.elevationGainMeters, 300)
        XCTAssertEqual(rideW1.load, 150, accuracy: 0.01) // 100 + 50 TSS at threshold
        let runW1 = week1.bySport[.run]!
        XCTAssertEqual(runW1.seconds, 2400)
        XCTAssertEqual(runW1.load, 2400.0 / 3600.0 * 100.0, accuracy: 0.01) // RPE 7 == threshold

        let week2 = weeks[1]
        XCTAssertEqual(week2.bySport[.ride]!.load, 25, accuracy: 0.01) // IF 0.5 for 1h
        XCTAssertNil(week2.bySport[.run])
    }

    func testWeekTotalCombinesSports() {
        let activities = [
            Activity(source: .manual, sport: .ride, start: date(dayOffset: 0),
                     movingSeconds: 3600, normalizedPower: 250),
            Activity(source: .manual, sport: .run, start: date(dayOffset: 1),
                     movingSeconds: 3600, perceivedExertion: 7),
        ]
        let weeks = WeeklyAggregator.totals(activities: activities, thresholds: thresholds)
        XCTAssertEqual(weeks[0].total.load, 200, accuracy: 0.1)
        XCTAssertEqual(weeks[0].total.seconds, 7200)
    }

    func testTimeInZoneFromSamples() {
        // 600s at 125W (Z1 on FTP 250, ≤55% == ≤137.5) then 600s at 250W (Z4)
        var samples: [Sample] = []
        for i in 0..<600 { samples.append(Sample(offsetSeconds: Double(i), power: 125)) }
        for i in 600..<1200 { samples.append(Sample(offsetSeconds: Double(i), power: 250)) }
        let activity = Activity(source: .manual, sport: .ride, start: date(dayOffset: 0),
                                movingSeconds: 1200, samples: samples)
        let zones = ZoneTime.seconds(for: activity, kind: .power,
                                     thresholds: thresholds, zones: .defaults)
        XCTAssertEqual(zones[1] ?? 0, 600, accuracy: 2)
        XCTAssertEqual(zones[4] ?? 0, 600, accuracy: 2)
    }

    func testRecordingGapDoesNotInflateZoneTime() {
        // 60s at 250W, then a 20-minute pause, then 60s at 250W: the pause
        // must contribute at most the clamped gap, not 1200s of Z4.
        var samples: [Sample] = []
        for i in 0..<60 { samples.append(Sample(offsetSeconds: Double(i), power: 250)) }
        for i in 0..<60 { samples.append(Sample(offsetSeconds: 1260 + Double(i), power: 250)) }
        let activity = Activity(source: .manual, sport: .ride, start: date(dayOffset: 0),
                                movingSeconds: 120, samples: samples)
        let zones = ZoneTime.seconds(for: activity, kind: .power,
                                     thresholds: thresholds, zones: .defaults)
        XCTAssertLessThan(zones[4] ?? 0, 140, "pause must not count as riding time")
    }

    func testRampRateGuard() {
        // Chronic weekly load ≈ CTL × 7. CTL 50 → chronic 350.
        // A 500-load week is a jump beyond the 1.3 factor (455) → warn.
        XCTAssertTrue(RampGuard.isExcessive(plannedWeekLoad: 500, currentCTL: 50))
        XCTAssertFalse(RampGuard.isExcessive(plannedWeekLoad: 420, currentCTL: 50))
    }

    func testRampGuardIgnoresTrivialBase() {
        // With no fitness base at all, any first week would "warn" — suppress
        // below a minimal chronic load so onboarding isn't a wall of warnings.
        XCTAssertFalse(RampGuard.isExcessive(plannedWeekLoad: 100, currentCTL: 0))
    }
}
