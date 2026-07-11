import Foundation
import TrainingCore

public enum FITDecodeError: Error, Equatable {
    case missingSession
    case unsupportedSport(UInt8)
    case missingStartTime
    /// Multisport/brick files carry several sessions; splitting them into
    /// separate activities is post-MVP — fail loudly instead of corrupting.
    case multiSessionUnsupported
}

/// Decodes a FIT *activity* file (Garmin, Karoo, Zwift exports) into a
/// TrainingCore Activity: session summary + record samples. Unknown
/// messages and fields are skipped by the reader.
public enum FITActivityDecoder {

    static let fitEpochOffset = 631_065_600.0

    public static func decode(_ file: Data) throws -> Activity {
        let messages = try FITMessageReader.messages(from: file)

        let sessions = messages.filter { $0.globalMessage == 18 }
        guard let session = sessions.first else {
            throw FITDecodeError.missingSession
        }
        guard sessions.count == 1 else {
            throw FITDecodeError.multiSessionUnsupported
        }
        guard let sportRaw = session.value(field: 5) else {
            throw FITDecodeError.missingSession
        }
        let sport: Sport
        switch UInt8(sportRaw) {
        case 1: sport = .run
        case 2: sport = .ride
        default: throw FITDecodeError.unsupportedSport(UInt8(sportRaw))
        }

        guard let startFIT = session.value(field: 2) else {
            throw FITDecodeError.missingStartTime
        }
        let start = Date(timeIntervalSince1970: fitEpochOffset + startFIT)

        // session total_timer_time(8) and total_elapsed_time(7): ms.
        let moving = (session.value(field: 8) ?? 0) / 1000
        let elapsed = session.value(field: 7).map { $0 / 1000 }
        // total_distance(9): cm.
        let distance = session.value(field: 9).map { $0 / 100 }

        var samples: [Sample] = []
        for message in messages where message.globalMessage == 20 {
            guard let ts = message.value(field: 253) else { continue }
            // Legacy speed (6, uint16) or enhanced_speed (73, uint32), both mm/s.
            let speed = message.value(field: 6) ?? message.value(field: 73)
            samples.append(Sample(
                offsetSeconds: ts - startFIT,
                power: message.value(field: 7),
                heartRate: message.value(field: 3),
                speed: speed.map { $0 / 1000 },
                cadence: message.value(field: 4)))
        }

        let fileID = messages.first { $0.globalMessage == 0 }
        let serial = fileID?.value(field: 3).map { String(UInt64($0)) } ?? "unknown"
        let created = fileID?.value(field: 4).map { String(UInt64($0)) }
            ?? String(UInt64(startFIT))

        return Activity(
            source: .fitImport(device: nil),
            externalID: "fit-\(serial)-\(created)",
            sport: sport,
            start: start,
            movingSeconds: moving,
            elapsedSeconds: elapsed,
            distanceMeters: distance,
            elevationGainMeters: session.value(field: 22),
            averagePower: session.value(field: 20),
            averageHeartRate: session.value(field: 16),
            normalizedPower: session.value(field: 34),
            samples: samples)
    }
}
