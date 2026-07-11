import Foundation

public enum ThresholdKind: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    /// Functional threshold power, watts (ride).
    case ftp
    /// Lactate threshold heart rate, bpm (per sport).
    case lthr
    /// Threshold speed, m/s (run; UI presents as pace).
    case thresholdSpeed
}

public struct ThresholdRecord: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var sport: Sport
    public var kind: ThresholdKind
    public var value: Double
    public var validFrom: Date

    public init(id: UUID = UUID(), sport: Sport, kind: ThresholdKind, value: Double, validFrom: Date) {
        self.id = id
        self.sport = sport
        self.kind = kind
        self.value = value
        self.validFrom = validFrom
    }
}

/// Dated threshold history. The value for a date is the record with the
/// latest `validFrom` that is on or before that date; among records sharing
/// a `validFrom`, the last added wins.
public struct ThresholdStore: Codable, Equatable, Sendable {
    public private(set) var records: [ThresholdRecord]

    public init(records: [ThresholdRecord] = []) {
        self.records = records
    }

    public mutating func add(_ record: ThresholdRecord) {
        records.append(record)
    }

    public func value(_ kind: ThresholdKind, sport: Sport, on date: Date) -> Double? {
        var best: (index: Int, record: ThresholdRecord)?
        for (index, record) in records.enumerated() {
            guard record.kind == kind, record.sport == sport, record.validFrom <= date else { continue }
            if let current = best {
                if record.validFrom > current.record.validFrom ||
                   (record.validFrom == current.record.validFrom && index > current.index) {
                    best = (index, record)
                }
            } else {
                best = (index, record)
            }
        }
        return best?.record.value
    }

    /// The threshold kind that resolves targets of `kind` for `sport`.
    public static func thresholdKind(for kind: TargetKind, sport: Sport) -> ThresholdKind? {
        switch kind {
        case .power: return sport == .ride ? .ftp : nil
        case .pace: return .thresholdSpeed
        case .heartRate: return .lthr
        case .cadence, .rpe: return nil
        }
    }
}
