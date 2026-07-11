import Foundation

public enum LoadMethod: String, Codable, Equatable, Sendable {
    case powerTSS
    case hrTSS
    case paceTSS
    case rpe
    case defaultIntensity
}

public struct LoadResult: Equatable, Sendable {
    public var value: Double
    public var method: LoadMethod
}

/// Training load with the spec §7 fallback chain:
/// power TSS → hrTSS → pace TSS → RPE → duration × sport default IF.
/// All methods share the same shape, hours × IF² × 100, so values stay
/// comparable across the chain.
public enum LoadCalculator {

    /// RPE that corresponds to threshold intensity (IF 1.0) on the 0–10 scale.
    public static let thresholdRPE = 7.0
    /// IF assumed for activities that carry nothing but a duration.
    public static let defaultIF = 0.65

    /// The single load shape shared by actual and estimated load, so
    /// projection and history stay comparable: hours × IF² × 100.
    public static func trainingLoad(seconds: Double, intensityFactor: Double) -> Double {
        seconds / 3600 * intensityFactor * intensityFactor * 100
    }

    public static func load(for activity: Activity, thresholds: ThresholdStore) -> LoadResult? {
        let seconds = activity.movingSeconds
        guard seconds > 0 else { return nil }

        func tss(_ intensityFactor: Double, _ method: LoadMethod) -> LoadResult {
            LoadResult(value: trainingLoad(seconds: seconds, intensityFactor: intensityFactor),
                       method: method)
        }

        // 1. Power
        if let ftp = thresholds.value(.ftp, sport: activity.sport, on: activity.start), ftp > 0 {
            let np = activity.normalizedPower
                ?? normalizedPower(samples: activity.samples)
                ?? activity.averagePower
            if let np { return tss(np / ftp, .powerTSS) }
        }

        // 2. Heart rate
        if let lthr = thresholds.value(.lthr, sport: activity.sport, on: activity.start), lthr > 0 {
            let hr = activity.averageHeartRate ?? average(activity.samples.compactMap(\.heartRate))
            if let hr { return tss(hr / lthr, .hrTSS) }
        }

        // 3. Pace
        if let thresholdSpeed = thresholds.value(.thresholdSpeed, sport: activity.sport, on: activity.start),
           thresholdSpeed > 0 {
            let speed: Double? = {
                if let d = activity.distanceMeters {
                    return d / seconds
                }
                return average(activity.samples.compactMap(\.speed))
            }()
            if let speed { return tss(speed / thresholdSpeed, .paceTSS) }
        }

        // 4. RPE
        if let rpe = activity.perceivedExertion {
            return tss(rpe / thresholdRPE, .rpe)
        }

        // 5. Duration only
        return tss(defaultIF, .defaultIntensity)
    }

    /// Classic NP: 30-second rolling average of power, fourth-power mean,
    /// fourth root. Assumes roughly 1 Hz contiguous samples; recording gaps
    /// are blended across the window (acceptable error — validate against
    /// real device FIT fixtures in Phase B and revisit if it matters).
    /// Returns nil when there is not enough power data for a single window.
    public static func normalizedPower(samples: [Sample]) -> Double? {
        let power = samples.compactMap(\.power)
        let window = 30
        guard power.count >= window else { return nil }
        var rollingSum = power[0..<window].reduce(0, +)
        var fourthPowerSum = pow(rollingSum / Double(window), 4)
        var count = 1.0
        for i in window..<power.count {
            rollingSum += power[i] - power[i - window]
            fourthPowerSum += pow(rollingSum / Double(window), 4)
            count += 1
        }
        return pow(fourthPowerSum / count, 0.25)
    }

    private static func average(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}
