import Foundation
import TrainingCore

/// Encodes a structured workout as a FIT workout file for Garmin devices and
/// Hammerhead Karoo. Percent-of-FTP power targets export as %FTP natively;
/// HR and pace percent targets are resolved to absolute units via the
/// athlete's thresholds on the given date (unresolvable targets degrade to
/// open steps rather than failing the export).
public enum FITWorkoutEncoder {

    static let fitEpochOffset = 631_065_600.0

    enum FITSport: UInt8 {
        case running = 1
        case cycling = 2

        init(_ sport: Sport) {
            switch sport {
            case .run: self = .running
            case .ride: self = .cycling
            }
        }
    }

    enum DurationType: UInt8 {
        case time = 0
        case distance = 1
        case open = 5
        case repeatUntilStepsComplete = 6
    }

    enum TargetType: UInt8 {
        case speed = 0
        case heartRate = 1
        case open = 2
        case cadence = 3
        case power = 4
    }

    enum Intensity: UInt8 {
        case active = 0
        case rest = 1
        case warmup = 2
        case cooldown = 3
        case recovery = 4

        init(_ role: StepRole) {
            switch role {
            case .work: self = .active
            case .rest: self = .rest
            case .warmup: self = .warmup
            case .cooldown: self = .cooldown
            case .recovery: self = .recovery
            }
        }
    }

    private struct FITStep {
        var durationType: DurationType
        var durationValue: UInt32
        var targetType: TargetType
        var targetValue: UInt32
        var customLow: UInt32
        var customHigh: UInt32
        var intensity: Intensity
    }

    public static func encode(workout: WorkoutTemplate, on date: Date,
                              thresholds: ThresholdStore, zones: ZoneSettings) throws -> Data {
        var steps: [FITStep] = []

        for item in workout.items {
            switch item {
            case .step(let step):
                steps.append(fitStep(step, sport: workout.sport, on: date,
                                     thresholds: thresholds, zones: zones))
            case .repeatBlock(let block):
                let firstIndex = UInt32(steps.count)
                for step in block.steps {
                    steps.append(fitStep(step, sport: workout.sport, on: date,
                                         thresholds: thresholds, zones: zones))
                }
                steps.append(FITStep(durationType: .repeatUntilStepsComplete,
                                     durationValue: firstIndex,
                                     targetType: .open,
                                     targetValue: UInt32(max(block.count, 1)),
                                     customLow: 0, customHigh: 0,
                                     intensity: .active))
            }
        }

        var writer = FITRecordWriter()

        // file_id: type=workout(5), manufacturer=development(255), time_created
        writer.define(localType: 0, globalMessage: 0, fields: [
            (0, 1, .enumeration), (1, 2, .uint16), (4, 4, .uint32),
        ])
        writer.appendData(localType: 0, values: [
            .uint8(5), .uint16(255),
            .uint32(UInt32(max(date.timeIntervalSince1970 - fitEpochOffset, 0))),
        ])

        // workout: sport, num_valid_steps, wkt_name
        let nameSize = min(workout.name.utf8.count + 1, 32)
        writer.define(localType: 1, globalMessage: 26, fields: [
            (4, 1, .enumeration), (6, 2, .uint16), (8, UInt8(nameSize), .string),
        ])
        writer.appendData(localType: 1, values: [
            .uint8(FITSport(workout.sport).rawValue),
            .uint16(UInt16(steps.count)),
            .string(workout.name, size: nameSize),
        ])

        // workout_step
        writer.define(localType: 2, globalMessage: 27, fields: [
            (254, 2, .uint16), (1, 1, .enumeration), (2, 4, .uint32),
            (3, 1, .enumeration), (4, 4, .uint32), (5, 4, .uint32),
            (6, 4, .uint32), (7, 1, .enumeration),
        ])
        for (index, step) in steps.enumerated() {
            writer.appendData(localType: 2, values: [
                .uint16(UInt16(index)),
                .uint8(step.durationType.rawValue),
                .uint32(step.durationValue),
                .uint8(step.targetType.rawValue),
                .uint32(step.targetValue),
                .uint32(step.customLow),
                .uint32(step.customHigh),
                .uint8(step.intensity.rawValue),
            ])
        }

        return FITFileBuilder.wrap(records: writer.data)
    }

    private static func fitStep(_ step: Step, sport: Sport, on date: Date,
                                thresholds: ThresholdStore, zones: ZoneSettings) -> FITStep {
        let (durationType, durationValue): (DurationType, UInt32)
        switch step.length {
        case .time(let seconds):
            (durationType, durationValue) = (.time, UInt32(max(seconds * 1000, 0)))
        case .distance(let meters):
            (durationType, durationValue) = (.distance, UInt32(max(meters * 100, 0)))
        case .open:
            (durationType, durationValue) = (.open, 0)
        }

        let target = encodeTarget(step.target, sport: sport, on: date,
                                  thresholds: thresholds, zones: zones)
        return FITStep(durationType: durationType, durationValue: durationValue,
                       targetType: target.type, targetValue: target.value,
                       customLow: target.low, customHigh: target.high,
                       intensity: Intensity(step.role))
    }

    private static func encodeTarget(_ target: IntensityTarget?, sport: Sport, on date: Date,
                                     thresholds: ThresholdStore, zones: ZoneSettings)
        -> (type: TargetType, value: UInt32, low: UInt32, high: UInt32) {
        let open: (TargetType, UInt32, UInt32, UInt32) = (.open, 0, 0, 0)
        guard let target else { return open }

        switch target.kind {
        case .rpe:
            return open

        case .cadence:
            guard target.reference == .absolute else { return open }
            return (.cadence, 0, UInt32(max(target.lower, 0).rounded()), UInt32(max(target.upper, 0).rounded()))

        case .power:
            switch target.reference {
            case .percentOfThreshold:
                // FIT custom power 0–1000 is %FTP.
                return (.power, 0,
                        UInt32(max((target.lower * 100).rounded(), 0)),
                        UInt32(max((target.upper * 100).rounded(), 0)))
            case .absolute:
                // Above 1000 means watts + 1000.
                return (.power, 0,
                        UInt32(max(target.lower, 0).rounded()) + 1000,
                        UInt32(max(target.upper, 0).rounded()) + 1000)
            case .zone:
                return (.power, UInt32(max(target.lower, 1)), 0, 0)
            }

        case .heartRate:
            // FIT custom HR above 100 means bpm + 100 (0–100 would be %max,
            // which we don't track) — resolve everything to bpm.
            guard let resolved = resolvedOrAbsolute(target, sport: sport, on: date,
                                                    thresholds: thresholds, zones: zones) else {
                return open
            }
            return (.heartRate, 0,
                    UInt32(max(resolved.lower, 0).rounded()) + 100,
                    UInt32(max(resolved.upper, 0).rounded()) + 100)

        case .pace:
            guard let resolved = resolvedOrAbsolute(target, sport: sport, on: date,
                                                    thresholds: thresholds, zones: zones) else {
                return open
            }
            // Custom speed in mm/s.
            return (.speed, 0,
                    UInt32(max(resolved.lower * 1000, 0).rounded()),
                    UInt32(max(resolved.upper * 1000, 0).rounded()))
        }
    }

    private static func resolvedOrAbsolute(_ target: IntensityTarget, sport: Sport, on date: Date,
                                           thresholds: ThresholdStore,
                                           zones: ZoneSettings) -> ResolvedTarget? {
        if target.reference == .absolute {
            return ResolvedTarget(kind: target.kind, lower: target.lower, upper: target.upper)
        }
        return target.resolved(sport: sport, on: date, thresholds: thresholds, zones: zones)
    }
}
