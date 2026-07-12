#if canImport(SwiftUI)
import SwiftUI
import TrainingCore
import TrainingAppCore

/// Edits a WorkoutTemplate: name, sport, tags, and an ordered list of steps
/// and single-level repeat blocks, each with a length and optional target.
/// Shows the live load / duration / time-in-zone estimate from the model.
///
/// UNVERIFIED: not compiled without Xcode.
struct WorkoutBuilderView: View {
    @EnvironmentObject var app: AppModelObservable
    @Environment(\.dismiss) private var dismiss

    @State private var draft: WorkoutTemplate
    private let isNew: Bool

    init(existing: WorkoutTemplate? = nil) {
        if let existing {
            _draft = State(initialValue: existing)
            isNew = false
        } else {
            _draft = State(initialValue: WorkoutTemplate(name: "", sport: .ride, items: [
                .step(Step(role: .warmup, length: .time(seconds: 600), target: nil)),
            ]))
            isNew = true
        }
    }

    var body: some View {
        Form {
            Section("Workout") {
                TextField("Name", text: $draft.name)
                Picker("Sport", selection: $draft.sport) {
                    Text("Ride").tag(Sport.ride)
                    Text("Run").tag(Sport.run)
                }
                TagsField(tags: $draft.tags)
            }

            Section("Estimate") {
                let e = estimate
                LabeledContent("Load", value: "\(Int(e.load)) TSS")
                LabeledContent("Duration", value: durationText(e.durationSeconds))
                if !e.zoneSeconds.isEmpty {
                    ZoneBar(zoneSeconds: e.zoneSeconds)
                }
                if !e.hasEstimate {
                    Text("Add steps or a duration to estimate load")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Steps") {
                ForEach($draft.items, id: \.id) { $item in
                    WorkoutItemRow(item: $item, sport: draft.sport)
                }
                .onDelete { draft.items.remove(atOffsets: $0) }
                .onMove { draft.items.move(fromOffsets: $0, toOffset: $1) }

                Menu("Add") {
                    Button("Step") { draft.items.append(.step(Step(role: .work, length: .time(seconds: 300), target: nil))) }
                    Button("Repeat block") {
                        draft.items.append(.repeatBlock(RepeatBlock(count: 4, steps: [
                            Step(role: .work, length: .time(seconds: 180), target: nil),
                            Step(role: .recovery, length: .time(seconds: 120), target: nil),
                        ])))
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Workout" : "Edit Workout")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!draft.validate().isEmpty || draft.name.isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var estimate: WorkoutEstimate {
        WorkoutEstimator.estimate(workout: draft, on: Date(),
                                  thresholds: app.model.thresholdStoreSnapshot,
                                  zones: app.model.zoneSettings)
    }

    private func save() {
        if isNew {
            app.model.addTemplate(draft)
        } else {
            app.model.updateTemplate(draft, propagateToFutureInstances: true)
        }
        dismiss()
    }

    private func durationText(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        return "\(m / 60)h \(m % 60)m"
    }
}

/// One row in the builder: either a single step or a repeat block header with
/// its nested steps.
struct WorkoutItemRow: View {
    @Binding var item: WorkoutItem
    let sport: Sport

    var body: some View {
        switch item {
        case .step(let step):
            StepEditor(step: Binding(
                get: { step },
                set: { item = .step($0) }), sport: sport)
        case .repeatBlock(let block):
            DisclosureGroup("\(block.count)× repeat") {
                Stepper("Repeat \(block.count)×", value: Binding(
                    get: { block.count },
                    set: { item = .repeatBlock(RepeatBlock(id: block.id, count: $0, steps: block.steps)) }),
                    in: 1...30)
                ForEach(Array(block.steps.enumerated()), id: \.element.id) { index, step in
                    StepEditor(step: Binding(
                        get: { step },
                        set: { newStep in
                            var steps = block.steps
                            steps[index] = newStep
                            item = .repeatBlock(RepeatBlock(id: block.id, count: block.count, steps: steps))
                        }), sport: sport)
                }
            }
        }
    }
}

struct StepEditor: View {
    @Binding var step: Step
    let sport: Sport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Role", selection: $step.role) {
                ForEach(StepRole.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.menu)
            StepLengthField(length: $step.length)
            TargetField(target: $step.target, sport: sport)
        }
        .padding(.vertical, 4)
    }
}
#endif
