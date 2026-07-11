import XCTest
@testable import TrainingCore

final class TargetResolutionTests: XCTestCase {

    private let day: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 6; c.day = 15
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    private var store: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
            ThresholdRecord(sport: .ride, kind: .lthr, value: 165, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 4.0, validFrom: .distantPast),
        ])
    }

    func testPercentOfThresholdResolvesToWatts() {
        let target = IntensityTarget(kind: .power, reference: .percentOfThreshold, lower: 0.9, upper: 1.0)
        let resolved = target.resolved(sport: .ride, on: day, thresholds: store, zones: ZoneSettings.defaults)
        XCTAssertEqual(resolved?.lower, 225)
        XCTAssertEqual(resolved?.upper, 250)
        XCTAssertEqual(resolved?.kind, .power)
    }

    func testAbsoluteTargetPassesThrough() {
        let target = IntensityTarget(kind: .heartRate, reference: .absolute, lower: 140, upper: 155)
        let resolved = target.resolved(sport: .ride, on: day, thresholds: store, zones: ZoneSettings.defaults)
        XCTAssertEqual(resolved?.lower, 140)
        XCTAssertEqual(resolved?.upper, 155)
    }

    func testZoneReferenceResolvesToAbsoluteRange() {
        // Ride power zone 2 with default Coggan zones on FTP 250: 55%..75% → 137.5..187.5 W
        let target = IntensityTarget(kind: .power, reference: .zone, lower: 2, upper: 2)
        let resolved = target.resolved(sport: .ride, on: day, thresholds: store, zones: ZoneSettings.defaults)
        XCTAssertEqual(resolved!.lower, 137.5, accuracy: 0.01)
        XCTAssertEqual(resolved!.upper, 187.5, accuracy: 0.01)
    }

    func testPercentWithoutThresholdIsNil() {
        // No run LTHR in store → HR percent target unresolvable
        let target = IntensityTarget(kind: .heartRate, reference: .percentOfThreshold, lower: 0.8, upper: 0.9)
        XCTAssertNil(target.resolved(sport: .run, on: day, thresholds: store, zones: ZoneSettings.defaults))
    }

    func testRPEResolvesWithoutThreshold() {
        let target = IntensityTarget(kind: .rpe, reference: .absolute, lower: 6, upper: 7)
        let resolved = target.resolved(sport: .run, on: day, thresholds: store, zones: ZoneSettings.defaults)
        XCTAssertEqual(resolved?.lower, 6)
        XCTAssertEqual(resolved?.upper, 7)
    }

    func testPaceTargetResolvesToSpeed() {
        // 95..105% of threshold speed 4.0 m/s
        let target = IntensityTarget(kind: .pace, reference: .percentOfThreshold, lower: 0.95, upper: 1.05)
        let resolved = target.resolved(sport: .run, on: day, thresholds: store, zones: ZoneSettings.defaults)
        XCTAssertEqual(resolved!.lower, 3.8, accuracy: 0.001)
        XCTAssertEqual(resolved!.upper, 4.2, accuracy: 0.001)
    }
}
