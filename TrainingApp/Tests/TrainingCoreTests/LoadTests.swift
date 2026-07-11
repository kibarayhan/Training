import XCTest
@testable import TrainingCore

final class LoadTests: XCTestCase {

    private let day = Date(timeIntervalSince1970: 1_770_000_000)

    private var thresholds: ThresholdStore {
        ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 250, validFrom: .distantPast),
            ThresholdRecord(sport: .ride, kind: .lthr, value: 165, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .lthr, value: 172, validFrom: .distantPast),
            ThresholdRecord(sport: .run, kind: .thresholdSpeed, value: 4.0, validFrom: .distantPast),
        ])
    }

    private func load(_ activity: Activity) -> LoadResult? {
        LoadCalculator.load(for: activity, thresholds: thresholds)
    }

    // MARK: Power TSS

    func testPowerTSSFromNormalizedPower() {
        // NP 200 on FTP 250 for 1h: IF 0.8 → TSS 64
        let a = Activity(source: .manual, sport: .ride, start: day,
                         movingSeconds: 3600, normalizedPower: 200)
        let result = load(a)
        XCTAssertEqual(result?.method, .powerTSS)
        XCTAssertEqual(result!.value, 64.0, accuracy: 0.001)
    }

    func testPowerTSSAtThresholdForOneHourIs100() {
        let a = Activity(source: .manual, sport: .ride, start: day,
                         movingSeconds: 3600, normalizedPower: 250)
        XCTAssertEqual(load(a)!.value, 100.0, accuracy: 0.001)
    }

    func testNormalizedPowerComputedFromSamples() {
        // Constant power: NP == that power.
        let samples = (0..<120).map { Sample(offsetSeconds: Double($0), power: 200) }
        let a = Activity(source: .manual, sport: .ride, start: day,
                         movingSeconds: 120, samples: samples)
        let result = load(a)
        XCTAssertEqual(result?.method, .powerTSS)
        // 120s at IF 0.8: TSS = (120/3600) * 0.64 * 100
        XCTAssertEqual(result!.value, 120.0 / 3600.0 * 0.64 * 100.0, accuracy: 0.01)
    }

    func testNormalizedPowerExceedsAverageForVariablePower() {
        var samples: [Sample] = []
        for i in 0..<600 {
            samples.append(Sample(offsetSeconds: Double(i), power: i % 60 < 30 ? 100 : 300))
        }
        let np = LoadCalculator.normalizedPower(samples: samples)
        XCTAssertNotNil(np)
        XCTAssertGreaterThan(np!, 200, "NP must exceed average for spiky power")
    }

    func testAveragePowerUsedWhenNoNPOrSamples() {
        let a = Activity(source: .manual, sport: .ride, start: day,
                         movingSeconds: 3600, averagePower: 200)
        let result = load(a)
        XCTAssertEqual(result?.method, .powerTSS)
        XCTAssertEqual(result!.value, 64.0, accuracy: 0.001)
    }

    // MARK: Fallback chain

    func testFallsBackToHeartRateWhenNoPower() {
        // avg HR 150 on LTHR 165 for 2h: IF 0.9091 → TSS 165.29
        let a = Activity(source: .manual, sport: .ride, start: day,
                         movingSeconds: 7200, averageHeartRate: 150)
        let result = load(a)
        XCTAssertEqual(result?.method, .hrTSS)
        XCTAssertEqual(result!.value, 165.29, accuracy: 0.01)
    }

    func testFallsBackToPaceWhenNoPowerOrHR() {
        // avg speed 3.6 on threshold 4.0 for 1h: IF 0.9 → TSS 81
        let a = Activity(source: .manual, sport: .run, start: day,
                         movingSeconds: 3600, distanceMeters: 12960)
        let result = load(a)
        XCTAssertEqual(result?.method, .paceTSS)
        XCTAssertEqual(result!.value, 81.0, accuracy: 0.01)
    }

    func testFallsBackToRPE() {
        // No sensors at all, RPE 7 ≈ threshold for 1h → 100
        let a = Activity(source: .manual, sport: .run, start: day,
                         movingSeconds: 3600, perceivedExertion: 7)
        let result = LoadCalculator.load(for: a, thresholds: ThresholdStore(records: []))
        XCTAssertEqual(result?.method, .rpe)
        XCTAssertEqual(result!.value, 100.0, accuracy: 0.01)
    }

    func testFallsBackToSportDefaultIF() {
        // Nothing but duration: default IF 0.65 for 2h → 84.5
        let a = Activity(source: .manual, sport: .ride, start: day, movingSeconds: 7200)
        let result = LoadCalculator.load(for: a, thresholds: ThresholdStore(records: []))
        XCTAssertEqual(result?.method, .defaultIntensity)
        XCTAssertEqual(result!.value, 84.5, accuracy: 0.01)
    }

    func testPowerPreferredOverHR() {
        let a = Activity(source: .manual, sport: .ride, start: day,
                         movingSeconds: 3600, averageHeartRate: 150, normalizedPower: 200)
        XCTAssertEqual(load(a)?.method, .powerTSS)
    }

    func testHRPreferredOverPace() {
        let a = Activity(source: .manual, sport: .run, start: day,
                         movingSeconds: 3600, distanceMeters: 12960, averageHeartRate: 150)
        XCTAssertEqual(load(a)?.method, .hrTSS)
    }

    func testZeroDurationYieldsNil() {
        let a = Activity(source: .manual, sport: .ride, start: day, movingSeconds: 0)
        XCTAssertNil(load(a))
    }

    func testHistoricalThresholdUsed() {
        // FTP was 200 until July 2026; activity in January must use 200.
        let jan = Date(timeIntervalSince1970: 1_767_270_000) // 2026-01-01
        let jul = Date(timeIntervalSince1970: 1_782_900_000) // 2026-07-01
        let store = ThresholdStore(records: [
            ThresholdRecord(sport: .ride, kind: .ftp, value: 200, validFrom: .distantPast),
            ThresholdRecord(sport: .ride, kind: .ftp, value: 260, validFrom: jul),
        ])
        let a = Activity(source: .manual, sport: .ride, start: jan,
                         movingSeconds: 3600, normalizedPower: 200)
        let result = LoadCalculator.load(for: a, thresholds: store)
        // IF = 200/200 = 1.0 → TSS 100 (not 200/260)
        XCTAssertEqual(result!.value, 100.0, accuracy: 0.01)
    }
}
