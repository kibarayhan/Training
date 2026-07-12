#if canImport(SwiftUI)
import SwiftUI
import Charts
import TrainingCore
import TrainingAppCore

/// Fitness dashboard: the CTL/ATL/TSB chart with the actual-vs-projected
/// split, race-day form callouts, and weekly totals.
///
/// UNVERIFIED: not compiled without Xcode. The Swift Charts marks are the most
/// likely thing to need tweaking on device.
struct DashboardScreen: View {
    @EnvironmentObject var app: AppModelObservable

    private var range: (from: Date, to: Date) {
        let today = Date()
        return (today.addingTimeInterval(-90 * 86_400),
                today.addingTimeInterval(42 * 86_400))
    }

    private var series: [PMCPoint] { app.model.pmcSeries(from: range.from, to: range.to) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    FitnessChart(series: series, today: Date(), events: app.model.events)

                    if let today = series.first(where: { Calendar.current.isDateInToday($0.date) }) {
                        HStack {
                            Metric(title: "Fitness", value: today.ctl, color: .blue)
                            Metric(title: "Fatigue", value: today.atl, color: .orange)
                            Metric(title: "Form", value: today.tsb, color: .green)
                        }
                    }

                    ForEach(app.model.events) { event in
                        if let form = app.model.projectedForm(eventID: event.id) {
                            HStack {
                                Text(event.name).font(.headline)
                                Spacer()
                                Text("Projected form \(Int(form))")
                                    .foregroundStyle(form > 0 ? .green : .orange)
                            }
                        }
                    }

                    WeeklyTotalsView(weeks: app.model.weeklyTotals())
                }
                .padding()
            }
            .navigationTitle("Fitness")
        }
    }
}

struct FitnessChart: View {
    let series: [PMCPoint]
    let today: Date
    let events: [TargetEvent]

    var body: some View {
        Chart {
            ForEach(series, id: \.date) { point in
                let projected = point.date > today
                LineMark(x: .value("Date", point.date), y: .value("Fitness", point.ctl))
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: projected ? [4, 3] : []))
                LineMark(x: .value("Date", point.date), y: .value("Fatigue", point.atl))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: projected ? [4, 3] : []))
            }
            RuleMark(x: .value("Today", today))
                .foregroundStyle(.secondary.opacity(0.4))
            ForEach(events) { event in
                RuleMark(x: .value("Event", event.date))
                    .foregroundStyle(.green.opacity(0.5))
                    .annotation { Text(event.name).font(.caption2) }
            }
        }
        .frame(height: 240)
    }
}

struct Metric: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(Int(value))").font(.title2.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyTotalsView: View {
    let weeks: [WeekTotals]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly totals").font(.headline)
            ForEach(weeks.suffix(6), id: \.weekStart) { week in
                HStack {
                    Text(week.weekStart, format: .dateTime.month().day())
                        .font(.caption).frame(width: 60, alignment: .leading)
                    Text("\(Int(week.total.load)) TSS")
                    Spacer()
                    Text("\(Int(week.total.seconds / 3600))h")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }
}

struct ProfileScreen: View {
    @EnvironmentObject var app: AppModelObservable

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycling") {
                    ThresholdField(title: "FTP (W)", kind: .ftp, sport: .ride, app: app)
                    ThresholdField(title: "LTHR (bpm)", kind: .lthr, sport: .ride, app: app)
                }
                Section("Running") {
                    ThresholdField(title: "Threshold pace (m/s)", kind: .thresholdSpeed, sport: .run, app: app)
                    ThresholdField(title: "LTHR (bpm)", kind: .lthr, sport: .run, app: app)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct ThresholdField: View {
    let title: String
    let kind: ThresholdKind
    let sport: Sport
    let app: AppModelObservable
    @State private var value: Double = 0

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", value: $value, format: .number)
                .multilineTextAlignment(.trailing)
                .onSubmit { app.model.setThreshold(kind, sport: sport, value: value) }
        }
        .onAppear {
            value = app.model.threshold(kind, sport: sport, on: Date()) ?? 0
        }
    }
}
#endif
