import Foundation

public enum ActivitySource: Codable, Equatable, Hashable, Sendable {
    case healthKit
    case fitImport(device: String?)
    case manual
}

public struct Sample: Codable, Equatable, Hashable, Sendable {
    public var offsetSeconds: Double
    public var power: Double?
    public var heartRate: Double?
    /// m/s
    public var speed: Double?
    public var cadence: Double?

    public init(offsetSeconds: Double, power: Double? = nil, heartRate: Double? = nil,
                speed: Double? = nil, cadence: Double? = nil) {
        self.offsetSeconds = offsetSeconds
        self.power = power
        self.heartRate = heartRate
        self.speed = speed
        self.cadence = cadence
    }
}

public struct Activity: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var source: ActivitySource
    /// Stable identifiers from the source systems (HealthKit UUID, FIT
    /// serial+timestamp), used for idempotent re-import and dedup. Plural
    /// because merging duplicates unions the identifiers of every copy —
    /// re-importing any of them must still hit the merged record.
    public var externalIDs: [String]
    public var sport: Sport
    public var start: Date
    public var movingSeconds: Double
    /// Wall-clock duration including pauses; nil when the source only
    /// reports moving time.
    public var elapsedSeconds: Double?
    public var distanceMeters: Double?
    public var elevationGainMeters: Double?
    public var averagePower: Double?
    public var averageHeartRate: Double?
    /// Precomputed by the source when available; otherwise derived from samples.
    public var normalizedPower: Double?
    /// Athlete-entered RPE 0–10, the last resort of the load fallback chain.
    public var perceivedExertion: Double?
    public var samples: [Sample]

    /// Wall-clock end, preferring elapsed over moving time so dedup windows
    /// line up across sources that report pauses differently.
    public var end: Date { start.addingTimeInterval(elapsedSeconds ?? movingSeconds) }

    public init(id: UUID = UUID(), source: ActivitySource, externalIDs: [String] = [],
                sport: Sport, start: Date, movingSeconds: Double,
                elapsedSeconds: Double? = nil,
                distanceMeters: Double? = nil, elevationGainMeters: Double? = nil,
                averagePower: Double? = nil, averageHeartRate: Double? = nil,
                normalizedPower: Double? = nil, perceivedExertion: Double? = nil,
                samples: [Sample] = []) {
        self.id = id
        self.source = source
        self.externalIDs = externalIDs
        self.sport = sport
        self.start = start
        self.movingSeconds = movingSeconds
        self.elapsedSeconds = elapsedSeconds
        self.distanceMeters = distanceMeters
        self.elevationGainMeters = elevationGainMeters
        self.averagePower = averagePower
        self.averageHeartRate = averageHeartRate
        self.normalizedPower = normalizedPower
        self.perceivedExertion = perceivedExertion
        self.samples = samples
    }
}
