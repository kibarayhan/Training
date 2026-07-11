import Foundation

public enum FITReadError: Error, Equatable {
    case truncated
    case badMagic
    case badCRC
    case unknownLocalType(UInt8)
    case unsupportedBaseType(UInt8)
}

public struct FITMessage {
    public var globalMessage: UInt16
    /// Numeric field values by field definition number (invalid sentinels
    /// already filtered out).
    public var numbers: [UInt8: Double]
    /// Raw bytes for string fields.
    public var strings: [UInt8: String]

    public func value(field: UInt8) -> Double? { numbers[field] }
    public func string(field: UInt8) -> String? { strings[field] }
}

/// Generic FIT record parser: header, CRC, definition/data messages,
/// developer fields (skipped), compressed-timestamp headers. Returns every
/// message in file order; callers pick the globals they understand.
public enum FITMessageReader {

    private struct FieldDef {
        var field: UInt8
        var size: Int
        var baseType: FITBaseType?
    }

    private struct Definition {
        var globalMessage: UInt16
        var bigEndian: Bool
        var fields: [FieldDef]
        var developerFieldBytes: Int
    }

    public static func messages(from file: Data) throws -> [FITMessage] {
        let data = Data(file) // normalize indices
        guard data.count >= 14 + 2 else { throw FITReadError.truncated }
        let headerSize = Int(data[0])
        guard headerSize == 12 || headerSize == 14, data.count >= headerSize + 2 else {
            throw FITReadError.truncated
        }
        guard data[8..<12].elementsEqual(Array(".FIT".utf8)) else { throw FITReadError.badMagic }
        guard FITCRC.compute(data) == 0 else { throw FITReadError.badCRC }

        let dataSize = Int(data[4]) | (Int(data[5]) << 8) | (Int(data[6]) << 16) | (Int(data[7]) << 24)
        let recordsEnd = headerSize + dataSize
        guard recordsEnd + 2 <= data.count else { throw FITReadError.truncated }

        var definitions: [UInt8: Definition] = [:]
        var messages: [FITMessage] = []
        var lastTimestamp: Double?
        var offset = headerSize

        func read(_ count: Int) throws -> Data {
            guard offset + count <= recordsEnd else { throw FITReadError.truncated }
            defer { offset += count }
            return data[offset..<offset + count]
        }

        while offset < recordsEnd {
            guard let header = try read(1).first else { throw FITReadError.truncated }

            if header & 0x80 != 0 && header & 0x40 == 0 {
                // Compressed timestamp data message.
                let localType = (header >> 5) & 0x03
                let timeOffset = Double(header & 0x1F)
                guard let def = definitions[localType] else {
                    throw FITReadError.unknownLocalType(localType)
                }
                var message = try readData(def: def, read: read)
                if let last = lastTimestamp {
                    // Expand 5-bit rollover offset onto the last full timestamp.
                    let base = last - last.truncatingRemainder(dividingBy: 32)
                    var ts = base + timeOffset
                    if ts < last { ts += 32 }
                    message.numbers[253] = ts
                    lastTimestamp = ts
                }
                messages.append(message)
                continue
            }

            if header & 0x40 != 0 {
                // Definition message (bit 5 = developer fields present).
                let localType = header & 0x0F
                let hasDeveloperFields = header & 0x20 != 0
                _ = try read(1) // reserved
                let arch = try read(1).first!
                let globalBytes = try read(2)
                let g0 = globalBytes[globalBytes.startIndex], g1 = globalBytes[globalBytes.startIndex + 1]
                let global = arch == 1 ? (UInt16(g0) << 8 | UInt16(g1)) : (UInt16(g1) << 8 | UInt16(g0))
                let fieldCount = Int(try read(1).first!)
                var fields: [FieldDef] = []
                for _ in 0..<fieldCount {
                    let triple = try read(3)
                    let base = triple.startIndex
                    fields.append(FieldDef(field: triple[base],
                                           size: Int(triple[base + 1]),
                                           baseType: FITBaseType(rawValue: triple[base + 2])))
                }
                var developerBytes = 0
                if hasDeveloperFields {
                    let devCount = Int(try read(1).first!)
                    for _ in 0..<devCount {
                        let triple = try read(3)
                        developerBytes += Int(triple[triple.startIndex + 1])
                    }
                }
                definitions[localType] = Definition(globalMessage: global,
                                                    bigEndian: arch == 1,
                                                    fields: fields,
                                                    developerFieldBytes: developerBytes)
                continue
            }

            // Normal data message.
            let localType = header & 0x0F
            guard let def = definitions[localType] else {
                throw FITReadError.unknownLocalType(localType)
            }
            let message = try readData(def: def, read: read)
            if let ts = message.numbers[253] { lastTimestamp = ts }
            messages.append(message)
        }
        return messages
    }

    private static func readData(def: Definition,
                                 read: (Int) throws -> Data) throws -> FITMessage {
        var numbers: [UInt8: Double] = [:]
        var strings: [UInt8: String] = [:]
        for field in def.fields {
            let bytes = try read(field.size)
            guard let baseType = field.baseType else { continue } // unknown type: skip bytes
            if baseType == .string {
                let raw = bytes.prefix { $0 != 0 }
                strings[field.field] = String(decoding: raw, as: UTF8.self)
                continue
            }
            guard field.size == baseType.size else { continue } // arrays unsupported: skip
            var raw: UInt64 = 0
            if def.bigEndian {
                for b in bytes { raw = raw << 8 | UInt64(b) }
            } else {
                for b in bytes.reversed() { raw = raw << 8 | UInt64(b) }
            }
            if !baseType.isInvalid(raw) {
                numbers[field.field] = Double(raw)
            }
        }
        if def.developerFieldBytes > 0 {
            _ = try read(def.developerFieldBytes)
        }
        return FITMessage(globalMessage: def.globalMessage, numbers: numbers, strings: strings)
    }
}
