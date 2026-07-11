import Foundation

/// Zones defined as inclusive upper bounds expressed as fractions of the
/// threshold value; the final zone above the last bound is implicit.
public struct ZoneModel: Codable, Equatable, Hashable, Sendable {
    public var kind: TargetKind
    /// Ascending inclusive upper bounds, as fractions of threshold (1.0 == threshold).
    public var upperBoundFractions: [Double]

    public init(kind: TargetKind, upperBoundFractions: [Double]) {
        self.kind = kind
        self.upperBoundFractions = upperBoundFractions
    }

    public var zoneCount: Int { upperBoundFractions.count + 1 }

    /// Boundaries must be strictly ascending and positive; user editing can
    /// break this, so consumers check before classifying.
    public var isWellFormed: Bool {
        guard let first = upperBoundFractions.first, first > 0 else { return false }
        return zip(upperBoundFractions, upperBoundFractions.dropFirst()).allSatisfy { $0 < $1 }
    }

    /// 1-based zone for an absolute value. This is the canonical classifier:
    /// a value exactly on a boundary belongs to the lower zone. Returns nil
    /// for a non-positive threshold or malformed boundaries rather than
    /// silently misclassifying.
    public func zone(forValue value: Double, threshold: Double) -> Int? {
        guard threshold > 0, isWellFormed else { return nil }
        let fraction = value / threshold
        for (index, bound) in upperBoundFractions.enumerated() where fraction <= bound {
            return index + 1
        }
        return zoneCount
    }

    /// Absolute value ranges per zone for display and target resolution; the
    /// last range is unbounded above. Ranges tile half-open; for classifying
    /// a sample (where the shared edge must belong to the lower zone) use
    /// `zone(forValue:threshold:)` instead.
    public func absoluteRanges(threshold: Double) -> [Range<Double>] {
        var ranges: [Range<Double>] = []
        var lower = 0.0
        for bound in upperBoundFractions {
            let upper = bound * threshold
            ranges.append(lower..<upper)
            lower = upper
        }
        ranges.append(lower..<Double.infinity)
        return ranges
    }

    // Coggan classic 7-zone power model.
    public static let defaultPower = ZoneModel(
        kind: .power, upperBoundFractions: [0.55, 0.75, 0.90, 1.05, 1.20, 1.50])

    // Coggan 5-zone heart-rate model (% of LTHR).
    public static let defaultHeartRate = ZoneModel(
        kind: .heartRate, upperBoundFractions: [0.68, 0.83, 0.94, 1.05])

    // 5-zone pace model (% of threshold speed).
    public static let defaultPace = ZoneModel(
        kind: .pace, upperBoundFractions: [0.80, 0.88, 0.95, 1.02])
}

/// The athlete's zone models per sport and target kind, with sensible defaults.
public struct ZoneSettings: Codable, Equatable, Sendable {
    private var models: [String: ZoneModel]

    public init(models: [String: ZoneModel] = [:]) {
        self.models = models
    }

    private static func key(_ sport: Sport, _ kind: TargetKind) -> String {
        "\(sport.rawValue)/\(kind.rawValue)"
    }

    public mutating func set(_ model: ZoneModel, sport: Sport, kind: TargetKind) {
        models[Self.key(sport, kind)] = model
    }

    public func model(sport: Sport, kind: TargetKind) -> ZoneModel? {
        if let custom = models[Self.key(sport, kind)] { return custom }
        switch kind {
        case .power: return sport == .ride ? .defaultPower : nil
        case .heartRate: return .defaultHeartRate
        case .pace: return .defaultPace
        case .cadence, .rpe: return nil
        }
    }

    public static let defaults = ZoneSettings()
}
