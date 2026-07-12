#if canImport(SwiftUI)
import SwiftUI
import TrainingCore

/// Editors for a step's length and target, plus small shared widgets. Kept in
/// one file because they're tightly coupled to StepEditor.
///
/// UNVERIFIED: not compiled without Xcode.

struct StepLengthField: View {
    @Binding var length: StepLength

    private enum Mode: String, CaseIterable { case time, distance, open }

    private var mode: Mode {
        switch length {
        case .time: return .time
        case .distance: return .distance
        case .open: return .open
        }
    }

    var body: some View {
        HStack {
            Picker("Length", selection: Binding(
                get: { mode },
                set: { newMode in
                    switch newMode {
                    case .time: length = .time(seconds: 300)
                    case .distance: length = .distance(meters: 1000)
                    case .open: length = .open
                    }
                })) {
                Text("Time").tag(Mode.time)
                Text("Distance").tag(Mode.distance)
                Text("Lap").tag(Mode.open)
            }
            .pickerStyle(.segmented)

            switch length {
            case .time(let seconds):
                Stepper("\(Int(seconds) / 60):\(String(format: "%02d", Int(seconds) % 60))",
                        value: Binding(get: { seconds }, set: { length = .time(seconds: $0) }),
                        in: 5...7200, step: 5)
            case .distance(let meters):
                Stepper("\(Int(meters)) m",
                        value: Binding(get: { meters }, set: { length = .distance(meters: $0) }),
                        in: 50...50000, step: 50)
            case .open:
                Text("Until lap button").foregroundStyle(.secondary)
            }
        }
    }
}

struct TargetField: View {
    @Binding var target: IntensityTarget?
    let sport: Sport

    private var kinds: [TargetKind] {
        // Power only makes sense on the bike; everything else on both.
        sport == .ride ? [.power, .heartRate, .cadence, .rpe] : [.pace, .heartRate, .cadence, .rpe]
    }

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Target", isOn: Binding(
                get: { target != nil },
                set: { on in
                    target = on ? IntensityTarget(kind: kinds[0], reference: .percentOfThreshold,
                                                  lower: 0.7, upper: 0.8) : nil
                }))
            if let current = target {
                Picker("Type", selection: Binding(
                    get: { current.kind },
                    set: { target?.kind = $0 })) {
                    ForEach(kinds, id: \.self) { Text(label(for: $0)).tag($0) }
                }
                .pickerStyle(.menu)
                HStack {
                    TextField("Low", value: Binding(get: { current.lower }, set: { target?.lower = $0 }),
                              format: .number)
                    Text("–")
                    TextField("High", value: Binding(get: { current.upper }, set: { target?.upper = $0 }),
                              format: .number)
                    Text(unit(for: current))
                }
            }
        }
    }

    private func label(for kind: TargetKind) -> String {
        switch kind {
        case .power: return "Power"
        case .pace: return "Pace"
        case .heartRate: return "Heart rate"
        case .cadence: return "Cadence"
        case .rpe: return "RPE"
        }
    }

    private func unit(for target: IntensityTarget) -> String {
        switch target.reference {
        case .percentOfThreshold: return "×thr"
        case .zone: return "zone"
        case .absolute:
            switch target.kind {
            case .power: return "W"
            case .pace: return "m/s"
            case .heartRate: return "bpm"
            case .cadence: return "rpm"
            case .rpe: return "/10"
            }
        }
    }
}

struct TagsField: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading) {
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag).font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.tint.opacity(0.15), in: Capsule())
                                .onTapGesture { tags.removeAll { $0 == tag } }
                        }
                    }
                }
            }
            HStack {
                TextField("Add tag", text: $newTag)
                Button("Add") {
                    let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty, !tags.contains(trimmed) { tags.append(trimmed) }
                    newTag = ""
                }
                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

struct ZoneBar: View {
    let zoneSeconds: [Int: Double]

    private let colors: [Color] = [.gray, .blue, .green, .yellow, .orange, .red, .purple]

    var body: some View {
        let total = max(zoneSeconds.values.reduce(0, +), 1)
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(zoneSeconds.keys.sorted(), id: \.self) { zone in
                    Rectangle()
                        .fill(colors[min(max(zone - 1, 0), colors.count - 1)])
                        .frame(width: geo.size.width * (zoneSeconds[zone]! / total))
                }
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
#endif
