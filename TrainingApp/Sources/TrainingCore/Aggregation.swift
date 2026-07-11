import Foundation

public struct SportTotals: Equatable, Sendable {
    public var seconds: Double = 0
    public var distanceMeters: Double = 0
    public var elevationGainMeters: Double = 0
    public var load: Double = 0
}

public struct WeekTotals: Equatable, Sendable {
    /// Monday 00:00 UTC of the ISO week.
    public var weekStart: Date
    public var bySport: [Sport: SportTotals]

    public var total: SportTotals {
        bySport.values.reduce(into: SportTotals()) { acc, t in
            acc.seconds += t.seconds
            acc.distanceMeters += t.distanceMeters
            acc.elevationGainMeters += t.elevationGainMeters
            acc.load += t.load
        }
    }
}

public enum WeeklyAggregator {

    private static var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    public static func totals(activities: [Activity],
                              thresholds: ThresholdStore) -> [WeekTotals] {
        let calendar = isoCalendar
        var byWeek: [Date: [Sport: SportTotals]] = [:]

        for activity in activities {
            let components = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: activity.start)
            guard let weekStart = calendar.date(from: components) else { continue }

            var totals = byWeek[weekStart]?[activity.sport] ?? SportTotals()
            totals.seconds += activity.movingSeconds
            totals.distanceMeters += activity.distanceMeters ?? 0
            totals.elevationGainMeters += activity.elevationGainMeters ?? 0
            totals.load += LoadCalculator.load(for: activity, thresholds: thresholds)?.value ?? 0
            byWeek[weekStart, default: [:]][activity.sport] = totals
        }

        return byWeek.keys.sorted().map { WeekTotals(weekStart: $0, bySport: byWeek[$0]!) }
    }
}

/// Time in zone from an activity's samples, using the canonical classifier.
public enum ZoneTime {

    public static func seconds(for activity: Activity, kind: TargetKind,
                               thresholds: ThresholdStore,
                               zones: ZoneSettings) -> [Int: Double] {
        guard let thresholdKind = ThresholdStore.thresholdKind(for: kind, sport: activity.sport),
              let threshold = thresholds.value(thresholdKind, sport: activity.sport, on: activity.start),
              let model = zones.model(sport: activity.sport, kind: kind),
              model.isWellFormed else {
            return [:]
        }

        func value(_ sample: Sample) -> Double? {
            switch kind {
            case .power: return sample.power
            case .heartRate: return sample.heartRate
            case .pace: return sample.speed
            case .cadence, .rpe: return nil
            }
        }

        /// Recording gaps (auto-pause, tunnel dropout) must not credit the
        /// pre-gap zone with the whole pause, so clamp per-sample dt.
        let maxSampleGapSeconds = 10.0

        var result: [Int: Double] = [:]
        let samples = activity.samples
        for (index, sample) in samples.enumerated() {
            guard let v = value(sample),
                  let zone = model.zone(forValue: v, threshold: threshold) else { continue }
            let dt: Double
            if index + 1 < samples.count {
                let gap = samples[index + 1].offsetSeconds - sample.offsetSeconds
                dt = min(max(gap, 0), maxSampleGapSeconds)
            } else {
                dt = 1
            }
            result[zone, default: 0] += dt
        }
        return result
    }
}

/// Spec §8: warn when a scheduled week's load jumps far above the chronic
/// weekly load implied by current fitness (CTL × 7).
public enum RampGuard {

    public static let factor = 1.3
    /// Below this chronic weekly load the guard stays quiet — a brand-new
    /// athlete's first weeks would otherwise always warn.
    public static let minimumChronicWeeklyLoad = 70.0

    public static func isExcessive(plannedWeekLoad: Double, currentCTL: Double) -> Bool {
        let chronicWeekly = currentCTL * 7
        guard chronicWeekly >= minimumChronicWeeklyLoad else { return false }
        return plannedWeekLoad > chronicWeekly * factor
    }
}
