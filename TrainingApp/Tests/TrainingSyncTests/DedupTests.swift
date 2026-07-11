import XCTest
import TrainingCore
@testable import TrainingSync

final class DedupTests: XCTestCase {

    private let base = Date(timeIntervalSince1970: 1_770_000_000)

    private func activity(startOffset: Double, seconds: Double = 3600,
                          sport: Sport = .ride, source: ActivitySource = .healthKit,
                          samples: Int = 0, distance: Double? = 30_000) -> Activity {
        Activity(source: source, sport: sport,
                 start: base.addingTimeInterval(startOffset),
                 movingSeconds: seconds, distanceMeters: distance,
                 samples: (0..<samples).map { Sample(offsetSeconds: Double($0), power: 200) })
    }

    func testSameRideFromTwoSourcesIsDuplicate() {
        // Zwift ride arriving via HealthKit and via Karoo FIT import.
        let a = activity(startOffset: 0, source: .healthKit)
        let b = activity(startOffset: 60, source: .fitImport(device: "Karoo"))
        let groups = DuplicateDetector.duplicateGroups(in: [a, b])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].map(\.id)), [a.id, b.id])
    }

    func testDifferentStartTimesNotDuplicate() {
        let a = activity(startOffset: 0)
        let b = activity(startOffset: 3 * 3600)
        XCTAssertTrue(DuplicateDetector.duplicateGroups(in: [a, b]).isEmpty)
    }

    func testDifferentSportsNotDuplicate() {
        let a = activity(startOffset: 0, sport: .ride)
        let b = activity(startOffset: 30, sport: .run)
        XCTAssertTrue(DuplicateDetector.duplicateGroups(in: [a, b]).isEmpty)
    }

    func testVeryDifferentDurationNotDuplicate() {
        // Same start window but 1h vs 10min is two different recordings
        // (e.g. a false start), not the same session.
        let a = activity(startOffset: 0, seconds: 3600)
        let b = activity(startOffset: 60, seconds: 600)
        XCTAssertTrue(DuplicateDetector.duplicateGroups(in: [a, b]).isEmpty)
    }

    func testSameExternalIDIsAlwaysDuplicate() {
        var a = activity(startOffset: 0)
        var b = activity(startOffset: 7200, seconds: 500)
        a.externalIDs = ["fit-1-2"]
        b.externalIDs = ["fit-1-2"]
        XCTAssertEqual(DuplicateDetector.duplicateGroups(in: [a, b]).count, 1)
    }

    func testMergePrefersRicherSamples() {
        let sparse = activity(startOffset: 0, samples: 0, distance: nil)
        let rich = activity(startOffset: 30, samples: 100)
        let merged = DuplicateDetector.merge([sparse, rich])
        XCTAssertEqual(merged.id, rich.id, "richest recording is the surviving identity")
        XCTAssertEqual(merged.samples.count, 100)
        XCTAssertEqual(merged.distanceMeters, 30_000, "missing fields filled from the other copy")
    }

    func testMergeUnionsExternalIDsForIdempotentReimport() {
        var a = activity(startOffset: 0, samples: 100)
        a.externalIDs = ["hk-abc"]
        var b = activity(startOffset: 30)
        b.externalIDs = ["fit-1-2"]
        let merged = DuplicateDetector.merge([a, b])
        XCTAssertEqual(Set(merged.externalIDs), ["hk-abc", "fit-1-2"],
                       "re-importing either source copy must still hit the merged record")
    }

    func testMergeFillsMissingSummaryFields() {
        var a = activity(startOffset: 0, samples: 50)
        a.averagePower = nil
        a.averageHeartRate = nil
        var b = activity(startOffset: 30, samples: 10)
        b.averagePower = 210
        b.averageHeartRate = 145
        let merged = DuplicateDetector.merge([a, b])
        XCTAssertEqual(merged.id, a.id)
        XCTAssertEqual(merged.averagePower, 210)
        XCTAssertEqual(merged.averageHeartRate, 145)
    }

    func testThreeWayGroup() {
        let a = activity(startOffset: 0, source: .healthKit)
        let b = activity(startOffset: 30, source: .fitImport(device: "Karoo"))
        let c = activity(startOffset: 90, source: .fitImport(device: "Zwift"))
        let groups = DuplicateDetector.duplicateGroups(in: [a, b, c])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].count, 3)
    }
}
