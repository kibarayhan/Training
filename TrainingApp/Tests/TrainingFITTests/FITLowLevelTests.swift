import XCTest
@testable import TrainingFIT

final class FITLowLevelTests: XCTestCase {

    func testCRCSelfCheckProperty() {
        // FIT CRC-16: appending the CRC to the data makes the running CRC zero.
        let data = Data([0x0E, 0x10, 0x98, 0x08, 0x10, 0x00, 0x00, 0x00, 0x2E, 0x46, 0x49, 0x54])
        let crc = FITCRC.compute(data)
        var withCRC = data
        withCRC.append(UInt8(crc & 0xFF))
        withCRC.append(UInt8(crc >> 8))
        XCTAssertEqual(FITCRC.compute(withCRC), 0)
    }

    func testCRCOfEmptyIsZero() {
        XCTAssertEqual(FITCRC.compute(Data()), 0)
    }

    func testHeaderStructure() {
        let payload = Data([0x01, 0x02, 0x03])
        let file = FITFileBuilder.wrap(records: payload)
        XCTAssertEqual(file.count, 14 + 3 + 2, "14-byte header + payload + trailing CRC")
        XCTAssertEqual(file[0], 14, "header size")
        XCTAssertEqual(Array(file[8..<12]), Array(".FIT".utf8))
        // data size little-endian at bytes 4..7
        let size = UInt32(file[4]) | (UInt32(file[5]) << 8) | (UInt32(file[6]) << 16) | (UInt32(file[7]) << 24)
        XCTAssertEqual(size, 3)
        // whole-file CRC self-check
        XCTAssertEqual(FITCRC.compute(file), 0)
    }
}
