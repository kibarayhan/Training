#if canImport(SwiftUI)
import SwiftUI
import TrainingCore
import TrainingAppCore

/// Weekly plan view: scheduled workouts per day, planned-load total with the
/// ramp warning, compliance badges once activities are matched, and the Watch
/// sync action.
///
/// UNVERIFIED: not compiled without Xcode.
struct CalendarScreen: View {
    @EnvironmentObject var app: AppModelObservable
    @State private var weekAnchor = Date()
    @State private var pickingTemplateFor: Date?
    @State private var syncNotes: [MappingNote] = []

    private var days: [Date] {
        let start = TrainingAppModel.isoWeekStart(of: weekAnchor)
        return (0..<7).map { start.addingTimeInterval(Double($0) * 86_400) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WeekHeader(summary: app.model.weekSummary(weekOf: weekAnchor))
                }
                ForEach(days, id: \.self) { day in
                    Section(day.formatted(.dateTime.weekday(.wide).month().day())) {
                        ForEach(app.model.plannedWorkouts(inWeekOf: weekAnchor)
                            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }) { planned in
                            PlannedRow(planned: planned,
                                       compliance: app.model.compliance(for: planned.id))
                        }
                        Button {
                            pickingTemplateFor = day
                        } label: {
                            Label("Add workout", systemImage: "plus.circle")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { shiftWeek(-1) } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .principal) {
                    Text(TrainingAppModel.isoWeekStart(of: weekAnchor),
                         format: .dateTime.month().day())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { shiftWeek(1) } label: { Image(systemName: "chevron.right") }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Sync to Watch") { sync() }
                }
            }
            .sheet(item: Binding(get: { pickingTemplateFor.map { DateBox(date: $0) } },
                                 set: { pickingTemplateFor = $0?.date })) { box in
                TemplatePicker { templateID in
                    _ = app.model.schedule(templateID: templateID, on: box.date)
                    pickingTemplateFor = nil
                }
            }
        }
    }

    private func shiftWeek(_ delta: Int) {
        weekAnchor = weekAnchor.addingTimeInterval(Double(delta) * 7 * 86_400)
    }

    private func sync() {
        #if canImport(WorkoutKit)
        let scheduler = WorkoutKitScheduler()
        syncNotes = (try? app.model.applySync(to: scheduler)) ?? []
        #endif
    }
}

struct WeekHeader: View {
    let summary: WeekSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Planned load").font(.caption).foregroundStyle(.secondary)
                Text("\(Int(summary.plannedLoad)) TSS").font(.title3.bold())
            }
            Spacer()
            if summary.rampWarning {
                Label("Big jump", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }
}

struct PlannedRow: View {
    let planned: PlannedWorkout
    let compliance: Compliance?

    var body: some View {
        HStack {
            Image(systemName: planned.sport == .ride ? "bicycle" : "figure.run")
            Text(planned.snapshot.name)
            Spacer()
            if let compliance {
                ComplianceBadge(compliance: compliance)
            }
        }
    }
}

struct ComplianceBadge: View {
    let compliance: Compliance

    var body: some View {
        let (text, color): (String, Color) = {
            switch compliance {
            case .completed: return ("Done", .green)
            case .substituted: return ("Modified", .yellow)
            case .missed: return ("Missed", .red)
            case .unplanned: return ("Extra", .blue)
            }
        }()
        Text(text).font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }
}

struct TemplatePicker: View {
    @EnvironmentObject var app: AppModelObservable
    @Environment(\.dismiss) private var dismiss
    let onPick: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List(app.model.templates()) { template in
                Button(template.name) { onPick(template.id); dismiss() }
            }
            .navigationTitle("Choose workout")
        }
    }
}

private struct DateBox: Identifiable { let date: Date; var id: TimeInterval { date.timeIntervalSince1970 } }
#endif
