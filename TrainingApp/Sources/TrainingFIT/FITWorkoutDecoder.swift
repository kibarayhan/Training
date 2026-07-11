import Foundation
import TrainingCore

public enum FITWorkoutDecodeError: Error, Equatable {
    case notAWorkoutFile
    case unsupportedSport(UInt8)
    case malformedRepeat
}

/// Decodes a FIT workout file into a WorkoutTemplate — the import half of the
/// library exchange (spec §5). Repeat steps are reconstructed into
/// RepeatBlocks; targets come back in the units FIT carries: %FTP power and
/// zones stay relative, everything else imports as absolute values.
public enum FITWorkoutDecoder {

    public static func decode(_ file: Data) throws -> WorkoutTemplate {
        let messages = try FITMessageReader.messages(from: file)

        guard let fileID = messages.first(where: { $0.globalMessage == 0 }),
              fileID.value(field: 0) == 5 else {
            throw FITWorkoutDecodeError.notAWorkoutFile
        }
        guard let workoutMsg = messages.first(where: { $0.globalMessage == 26 }) else {
            throw FITWorkoutDecodeError.notAWorkoutFile
        }

        let sport: Sport
        switch workoutMsg.value(field: 4).map(UInt8.init) {
        case 1: sport = .run
        case 2: sport = .ride
        case let other: throw FITWorkoutDecodeError.unsupportedSport(other ?? 0xFF)
        }
        let name = workoutMsg.string(field: 8) ?? "Imported workout"

        var items: [WorkoutItem] = []
        // Tracks how many leading FIT steps each item spans, so repeat rows
        // can find which trailing items they enclose.
        var fitIndexOfItemStart: [Int] = []
        var fitIndex = 0

        for message in messages where message.globalMessage == 27 {
            let durationType = message.value(field: 1).map(UInt8.init) ?? 0

            if durationType == 6 {
                // Repeat row: duration_value = first step index, target/
                // custom field carries the repetition count.
                let fromIndex = Int(message.value(field: 2) ?? 0)
                let count = Int(message.value(field: 4) ?? 0)
                guard count >= 1,
                      let firstEnclosed = fitIndexOfItemStart.firstIndex(where: { $0 >= fromIndex }),
                      fitIndexOfItemStart[firstEnclosed] == fromIndex else {
                    throw FITWorkoutDecodeError.malformedRepeat
                }
                var enclosedSteps: [Step] = []
                for item in items[firstEnclosed...] {
                    guard case .step(let s) = item else {
                        throw FITWorkoutDecodeError.malformedRepeat // nested repeats
                    }
                    enclosedSteps.append(s)
                }
                items.removeSubrange(firstEnclosed...)
                fitIndexOfItemStart.removeSubrange(firstEnclosed...)
                items.append(.repeatBlock(RepeatBlock(count: count, steps: enclosedSteps)))
                fitIndexOfItemStart.append(fromIndex)
                fitIndex += 1
                continue
            }

            let step = Step(role: role(fromIntensity: message.value(field: 7)),
                            length: length(type: durationType, value: message.value(field: 2)),
                            target: target(from: message))
            items.append(.step(step))
            fitIndexOfItemStart.append(fitIndex)
            fitIndex += 1
        }

        return WorkoutTemplate(name: name, sport: sport, items: items)
    }

    private static func role(fromIntensity raw: Double?) -> StepRole {
        switch raw.map(UInt8.init) {
        case 1: return .rest
        case 2: return .warmup
        case 3: return .cooldown
        case 4: return .recovery
        default: return .work
        }
    }

    private static func length(type: UInt8, value: Double?) -> StepLength {
        switch type {
        case 0: return .time(seconds: (value ?? 0) / 1000)
        case 1: return .distance(meters: (value ?? 0) / 100)
        default: return .open
        }
    }

    private static func target(from message: FITMessage) -> IntensityTarget? {
        let targetType = message.value(field: 3).map(UInt8.init) ?? 2
        let zoneValue = message.value(field: 4) ?? 0
        let low = message.value(field: 5)
        let high = message.value(field: 6)

        switch targetType {
        case 4: // power
            if zoneValue > 0 {
                return IntensityTarget(kind: .power, reference: .zone,
                                       lower: zoneValue, upper: zoneValue)
            }
            guard let low, let high else { return nil }
            if low > 1000 || high > 1000 {
                return IntensityTarget(kind: .power, reference: .absolute,
                                       lower: low - 1000, upper: high - 1000)
            }
            return IntensityTarget(kind: .power, reference: .percentOfThreshold,
                                   lower: low / 100, upper: high / 100)

        case 1: // heart rate: values above 100 are bpm + 100; ≤100 is %max, unsupported
            if zoneValue > 0 {
                return IntensityTarget(kind: .heartRate, reference: .zone,
                                       lower: zoneValue, upper: zoneValue)
            }
            guard let low, let high, low > 100, high > 100 else { return nil }
            return IntensityTarget(kind: .heartRate, reference: .absolute,
                                   lower: low - 100, upper: high - 100)

        case 0: // speed, mm/s
            guard let low, let high, high > 0 else { return nil }
            return IntensityTarget(kind: .pace, reference: .absolute,
                                   lower: low / 1000, upper: high / 1000)

        case 3: // cadence
            guard let low, let high, high > 0 else { return nil }
            return IntensityTarget(kind: .cadence, reference: .absolute,
                                   lower: low, upper: high)

        default:
            return nil
        }
    }
}
