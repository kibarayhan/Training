import Foundation

/// A target resolved to absolute native units (W, m/s, bpm, rpm, RPE).
public struct ResolvedTarget: Equatable, Sendable {
    public var kind: TargetKind
    public var lower: Double
    public var upper: Double

    public init(kind: TargetKind, lower: Double, upper: Double) {
        self.kind = kind
        self.lower = lower
        self.upper = upper
    }
}

extension IntensityTarget {
    /// Resolve to absolute units for a sport on a date, using the thresholds
    /// valid on that date. Returns nil when a required threshold or zone
    /// model is missing.
    public func resolved(sport: Sport, on date: Date,
                         thresholds: ThresholdStore,
                         zones: ZoneSettings) -> ResolvedTarget? {
        switch reference {
        case .absolute:
            return ResolvedTarget(kind: kind, lower: lower, upper: upper)

        case .percentOfThreshold:
            guard let thresholdKind = ThresholdStore.thresholdKind(for: kind, sport: sport),
                  let threshold = thresholds.value(thresholdKind, sport: sport, on: date) else {
                return nil
            }
            return ResolvedTarget(kind: kind, lower: lower * threshold, upper: upper * threshold)

        case .zone:
            guard let thresholdKind = ThresholdStore.thresholdKind(for: kind, sport: sport),
                  let threshold = thresholds.value(thresholdKind, sport: sport, on: date),
                  threshold > 0,
                  let model = zones.model(sport: sport, kind: kind),
                  model.isWellFormed else {
                return nil
            }
            let ranges = model.absoluteRanges(threshold: threshold)
            let lowerZone = Int(lower), upperZone = Int(upper)
            guard lowerZone >= 1, upperZone <= ranges.count, lowerZone <= upperZone else { return nil }
            return ResolvedTarget(kind: kind,
                                  lower: ranges[lowerZone - 1].lowerBound,
                                  upper: ranges[upperZone - 1].upperBound)
        }
    }
}
