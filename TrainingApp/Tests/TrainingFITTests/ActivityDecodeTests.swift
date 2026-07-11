import XCTest
import TrainingCore
@testable import TrainingFIT

final class ActivityDecodeTests: XCTestCase {

    /// FIT timestamps count seconds from 1989-12-31T00:00:00Z.
    private let fitEpochOffset = 631_065_600.0
    private let startFIT: UInt32 = 1_100_000_000

    /// Build a minimal synthetic activity FIT file with the low-level writer
    /// (independent of the workout encoder's message logic).
    private func syntheticActivity(sport: UInt8 = 2, dropCRC: Bool = false,
                                   truncate: Bool = false,
                                   secondSession: Bool = false,
                                   enhancedSpeedOnly: Bool = false) -> Data {
        var writer = FITRecordWriter()

        // file_id: type(0)=4 activity, serial(3)
        writer.define(localType: 0, globalMessage: 0, fields: [
            (0, 1, .enumeration), (3, 4, .uint32z),
        ])
        writer.appendData(localType: 0, values: [.uint8(4), .uint32(12_345_678)])

        // Unknown message the decoder must skip (developer gizmo 999)
        writer.define(localType: 1, globalMessage: 999, fields: [(0, 4, .uint32)])
        writer.appendData(localType: 1, values: [.uint32(42)])

        if enhancedSpeedOnly {
            // Modern devices: enhanced_speed(73 u32 mm/s), no legacy speed field.
            writer.define(localType: 2, globalMessage: 20, fields: [
                (253, 4, .uint32), (7, 2, .uint16), (3, 1, .uint8), (73, 4, .uint32),
            ])
            for i in 0..<10 {
                writer.appendData(localType: 2, values: [
                    .uint32(startFIT + UInt32(i)), .uint16(200 + UInt16(i)),
                    .uint8(140), .uint32(8_000),
                ])
            }
        } else {
            // record messages: timestamp(253), power(7 u16), heart_rate(3 u8), speed(6 u16 mm/s)
            writer.define(localType: 2, globalMessage: 20, fields: [
                (253, 4, .uint32), (7, 2, .uint16), (3, 1, .uint8), (6, 2, .uint16),
            ])
            for i in 0..<10 {
                writer.appendData(localType: 2, values: [
                    .uint32(startFIT + UInt32(i)),
                    .uint16(200 + UInt16(i)),
                    .uint8(140),
                    .uint16(8_000), // 8 m/s
                ])
            }
            // One record with invalid power (0xFFFF) — must decode as nil power.
            writer.appendData(localType: 2, values: [
                .uint32(startFIT + 10), .uint16(0xFFFF), .uint8(141), .uint16(8_100),
            ])
        }

        // session: sport(5), start_time(2), total_timer_time(8 u32 ms scale 1000),
        // total_elapsed_time(7), total_distance(9 u32 cm scale 100),
        // avg_power(20 u16), avg_heart_rate(16 u8), total_ascent(22 u16)
        writer.define(localType: 3, globalMessage: 18, fields: [
            (5, 1, .enumeration), (2, 4, .uint32), (8, 4, .uint32), (7, 4, .uint32),
            (9, 4, .uint32), (20, 2, .uint16), (16, 1, .uint8), (22, 2, .uint16),
        ])
        writer.appendData(localType: 3, values: [
            .uint8(sport), .uint32(startFIT),
            .uint32(3_600_000), .uint32(3_900_000),
            .uint32(3_000_000), // 30 km in cm
            .uint16(205), .uint8(140), .uint16(250),
        ])
        if secondSession {
            writer.appendData(localType: 3, values: [
                .uint8(1), .uint32(startFIT + 4000),
                .uint32(1_800_000), .uint32(1_800_000),
                .uint32(500_000),
                .uint16(0xFFFF), .uint8(150), .uint16(50),
            ])
        }

        var file = FITFileBuilder.wrap(records: writer.data)
        if dropCRC { file[file.count - 1] ^= 0xFF }
        if truncate { file = file.prefix(20) }
        return file
    }

    func testDecodesSessionIntoActivity() throws {
        let activity = try FITActivityDecoder.decode(syntheticActivity())
        XCTAssertEqual(activity.sport, .ride)
        XCTAssertEqual(activity.start.timeIntervalSince1970,
                       fitEpochOffset + Double(startFIT), accuracy: 0.001)
        XCTAssertEqual(activity.movingSeconds, 3600, accuracy: 0.001)
        XCTAssertEqual(activity.elapsedSeconds ?? 0, 3900, accuracy: 0.001)
        XCTAssertEqual(activity.distanceMeters ?? 0, 30_000, accuracy: 0.01)
        XCTAssertEqual(activity.averagePower, 205)
        XCTAssertEqual(activity.averageHeartRate, 140)
        XCTAssertEqual(activity.elevationGainMeters, 250)
        XCTAssertEqual(activity.source, .fitImport(device: nil))
        XCTAssertNotNil(activity.externalID)
    }

    func testDecodesRecordsIntoSamples() throws {
        let activity = try FITActivityDecoder.decode(syntheticActivity())
        XCTAssertEqual(activity.samples.count, 11)
        XCTAssertEqual(activity.samples[0].offsetSeconds, 0)
        XCTAssertEqual(activity.samples[0].power, 200)
        XCTAssertEqual(activity.samples[0].heartRate, 140)
        XCTAssertEqual(activity.samples[0].speed ?? 0, 8.0, accuracy: 0.001)
        XCTAssertEqual(activity.samples[9].offsetSeconds, 9)
        XCTAssertEqual(activity.samples[9].power, 209)
        XCTAssertNil(activity.samples[10].power, "0xFFFF is FIT invalid → nil")
    }

    func testRunSportMapped() throws {
        let activity = try FITActivityDecoder.decode(syntheticActivity(sport: 1))
        XCTAssertEqual(activity.sport, .run)
    }

    func testUnsupportedSportThrows() {
        XCTAssertThrowsError(try FITActivityDecoder.decode(syntheticActivity(sport: 5)))
    }

    func testEnhancedSpeedFieldDecoded() throws {
        let activity = try FITActivityDecoder.decode(syntheticActivity(enhancedSpeedOnly: true))
        XCTAssertEqual(activity.samples[0].speed ?? 0, 8.0, accuracy: 0.001,
                       "enhanced_speed (field 73) must be read when legacy speed is absent")
    }

    func testMultiSessionFileThrows() {
        XCTAssertThrowsError(try FITActivityDecoder.decode(syntheticActivity(secondSession: true))) {
            XCTAssertEqual($0 as? FITDecodeError, .multiSessionUnsupported)
        }
    }

    func testCorruptCRCThrows() {
        XCTAssertThrowsError(try FITActivityDecoder.decode(syntheticActivity(dropCRC: true)))
    }

    func testTruncatedFileThrows() {
        XCTAssertThrowsError(try FITActivityDecoder.decode(syntheticActivity(truncate: true)))
    }

    func testEncoderOutputSurvivesGenericReader() throws {
        // Cross-check: the workout encoder's bytes parse with the same reader
        // used for activities (shared record framing).
        let workout = WorkoutTemplate(name: "X", sport: .ride, items: [
            .step(Step(role: .work, length: .time(seconds: 60), target: nil)),
        ])
        let data = try FITWorkoutEncoder.encode(
            workout: workout, on: Date(), thresholds: ThresholdStore(records: []), zones: .defaults)
        let messages = try FITMessageReader.messages(from: data)
        XCTAssertFalse(messages.isEmpty)
    }
}
