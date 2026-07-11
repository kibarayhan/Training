import Foundation

/// FIT CRC-16 (the nibble-table algorithm from the FIT SDK).
public enum FITCRC {
    private static let table: [UInt16] = [
        0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
        0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
    ]

    public static func compute(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0
        for byte in data {
            var tmp = table[Int(crc & 0xF)]
            crc = (crc >> 4) & 0x0FFF
            crc = crc ^ tmp ^ table[Int(byte & 0xF)]
            tmp = table[Int(crc & 0xF)]
            crc = (crc >> 4) & 0x0FFF
            crc = crc ^ tmp ^ table[Int((byte >> 4) & 0xF)]
        }
        return crc
    }
}

/// The subset of FIT base types this app reads and writes.
public enum FITBaseType: UInt8 {
    case enumeration = 0x00
    case uint8 = 0x02
    case string = 0x07
    case uint16 = 0x84
    case uint32 = 0x86
    case uint32z = 0x8C

    public var size: Int {
        switch self {
        case .enumeration, .uint8: return 1
        case .uint16: return 2
        case .uint32, .uint32z: return 4
        case .string: return 0 // size comes from the field definition
        }
    }

    /// FIT "invalid" sentinel for the type (a field set to this is absent).
    public func isInvalid(_ raw: UInt64) -> Bool {
        switch self {
        case .enumeration, .uint8: return raw == 0xFF
        case .uint16: return raw == 0xFFFF
        case .uint32: return raw == 0xFFFF_FFFF
        case .uint32z: return raw == 0
        case .string: return false
        }
    }
}

public enum FITValue {
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case string(String, size: Int)
}

/// Low-level writer for definition and data records; shared by the workout
/// encoder and the test fixtures so encode and decode are cross-checked
/// against independent message logic.
public struct FITRecordWriter {
    public private(set) var data = Data()

    public init() {}

    public mutating func define(localType: UInt8, globalMessage: UInt16,
                                fields: [(field: UInt8, size: UInt8, type: FITBaseType)]) {
        data.append(0x40 | (localType & 0x0F))
        data.append(0) // reserved
        data.append(0) // architecture: little-endian
        data.append(UInt8(globalMessage & 0xFF))
        data.append(UInt8(globalMessage >> 8))
        data.append(UInt8(fields.count))
        for f in fields {
            data.append(f.field)
            data.append(f.size)
            data.append(f.type.rawValue)
        }
    }

    public mutating func appendData(localType: UInt8, values: [FITValue]) {
        data.append(localType & 0x0F)
        for value in values {
            switch value {
            case .uint8(let v):
                data.append(v)
            case .uint16(let v):
                data.append(UInt8(v & 0xFF)); data.append(UInt8(v >> 8))
            case .uint32(let v):
                data.append(UInt8(v & 0xFF)); data.append(UInt8((v >> 8) & 0xFF))
                data.append(UInt8((v >> 16) & 0xFF)); data.append(UInt8((v >> 24) & 0xFF))
            case .string(let s, let size):
                // Truncate on a codepoint boundary so multibyte names never
                // export a broken UTF-8 sequence.
                var truncated = s
                while truncated.utf8.count > size - 1 {
                    truncated.removeLast()
                }
                var bytes = Array(truncated.utf8)
                bytes.append(0)
                while bytes.count < size { bytes.append(0) }
                data.append(contentsOf: bytes)
            }
        }
    }
}

/// Wraps encoded records in the 14-byte FIT header and trailing CRC.
public enum FITFileBuilder {
    public static func wrap(records: Data) -> Data {
        var header = Data()
        header.append(14) // header size
        header.append(0x10) // protocol version 1.0
        header.append(contentsOf: [0x54, 0x08]) // profile version 21.32 LE
        let size = UInt32(records.count)
        header.append(UInt8(size & 0xFF)); header.append(UInt8((size >> 8) & 0xFF))
        header.append(UInt8((size >> 16) & 0xFF)); header.append(UInt8((size >> 24) & 0xFF))
        header.append(contentsOf: Array(".FIT".utf8))
        let headerCRC = FITCRC.compute(header)
        header.append(UInt8(headerCRC & 0xFF)); header.append(UInt8(headerCRC >> 8))

        var file = header
        file.append(records)
        let fileCRC = FITCRC.compute(file)
        file.append(UInt8(fileCRC & 0xFF)); file.append(UInt8(fileCRC >> 8))
        return file
    }
}
