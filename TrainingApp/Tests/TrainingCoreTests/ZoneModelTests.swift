import XCTest
@testable import TrainingCore

final class ZoneModelTests: XCTestCase {

    func testDefaultPowerModelHasSevenZones() {
        let model = ZoneModel.defaultPower
        XCTAssertEqual(model.zoneCount, 7)
    }

    func testDefaultHeartRateModelHasFiveZones() {
        XCTAssertEqual(ZoneModel.defaultHeartRate.zoneCount, 5)
        XCTAssertEqual(ZoneModel.defaultPace.zoneCount, 5)
    }

    func testPowerZoneClassificationAgainstThreshold() {
        let model = ZoneModel.defaultPower
        let ftp = 250.0
        // Coggan: Z1 ≤55%, Z2 ≤75%, Z3 ≤90%, Z4 ≤105%, Z5 ≤120%, Z6 ≤150%, Z7 above
        XCTAssertEqual(model.zone(forValue: 100, threshold: ftp), 1) // 40%
        XCTAssertEqual(model.zone(forValue: 170, threshold: ftp), 2) // 68%
        XCTAssertEqual(model.zone(forValue: 215, threshold: ftp), 3) // 86%
        XCTAssertEqual(model.zone(forValue: 250, threshold: ftp), 4) // 100%
        XCTAssertEqual(model.zone(forValue: 290, threshold: ftp), 5) // 116%
        XCTAssertEqual(model.zone(forValue: 350, threshold: ftp), 6) // 140%
        XCTAssertEqual(model.zone(forValue: 500, threshold: ftp), 7) // 200%
    }

    func testBoundaryValueBelongsToLowerZone() {
        let model = ZoneModel.defaultPower
        // exactly 55% of 200 = 110 → still zone 1 (boundaries are inclusive upper bounds)
        XCTAssertEqual(model.zone(forValue: 110, threshold: 200), 1)
        XCTAssertEqual(model.zone(forValue: 110.1, threshold: 200), 2)
    }

    func testCustomBoundariesRespected() {
        let custom = ZoneModel(kind: .power, upperBoundFractions: [0.6, 0.8, 1.0])
        XCTAssertEqual(custom.zoneCount, 4)
        XCTAssertEqual(custom.zone(forValue: 90, threshold: 100), 3)
        XCTAssertEqual(custom.zone(forValue: 150, threshold: 100), 4)
    }

    func testAbsoluteZoneRanges() {
        let model = ZoneModel(kind: .power, upperBoundFractions: [0.5, 1.0])
        let ranges = model.absoluteRanges(threshold: 200)
        XCTAssertEqual(ranges.count, 3)
        XCTAssertEqual(ranges[0].upperBound, 100)
        XCTAssertEqual(ranges[1].lowerBound, 100)
        XCTAssertEqual(ranges[1].upperBound, 200)
        XCTAssertEqual(ranges[2].upperBound, .infinity)
    }

    func testNonPositiveThresholdYieldsNoZone() {
        XCTAssertNil(ZoneModel.defaultPower.zone(forValue: 100, threshold: 0))
        XCTAssertNil(ZoneModel.defaultPower.zone(forValue: 100, threshold: -5))
    }

    func testMalformedBoundariesYieldNoZone() {
        let malformed = ZoneModel(kind: .power, upperBoundFractions: [0.9, 0.55, 1.05])
        XCTAssertFalse(malformed.isWellFormed)
        XCTAssertNil(malformed.zone(forValue: 100, threshold: 200))
        XCTAssertTrue(ZoneModel.defaultPower.isWellFormed)
    }

    func testBoundarySampleClassificationMatchesRangeSemantics() {
        // zone(forValue:) is the canonical classifier: boundary belongs to the
        // lower zone. absoluteRanges are half-open display/target ranges whose
        // shared edge is the same number; classification must stay in-bounds
        // of the range whose *upper* edge it is.
        let model = ZoneModel(kind: .power, upperBoundFractions: [0.5, 1.0])
        let ranges = model.absoluteRanges(threshold: 200)
        XCTAssertEqual(model.zone(forValue: 100, threshold: 200), 1)
        XCTAssertEqual(ranges[0].upperBound, 100)
    }

    func testZoneModelCodableRoundTrip() throws {
        let model = ZoneModel.defaultHeartRate
        let data = try JSONEncoder().encode(model)
        XCTAssertEqual(try JSONDecoder().decode(ZoneModel.self, from: data), model)
    }
}
