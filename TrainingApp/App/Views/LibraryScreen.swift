#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers
import TrainingCore
import TrainingAppCore

/// The workout library: search, filter by sport/tag, create, edit, export FIT,
/// and import a FIT workout file.
///
/// UNVERIFIED: not compiled without Xcode.
struct LibraryScreen: View {
    @EnvironmentObject var app: AppModelObservable
    @State private var search = ""
    @State private var sportFilter: Sport?
    @State private var showingImporter = false
    @State private var showingBuilder = false
    @State private var exportURL: ExportDocument?

    private var results: [WorkoutTemplate] {
        app.model.templates(matching: search.isEmpty ? nil : search, sport: sportFilter)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(results) { template in
                    NavigationLink {
                        WorkoutBuilderView(existing: template)
                    } label: {
                        WorkoutRow(template: template, app: app)
                    }
                    .swipeActions {
                        Button("Export") { export(template) }
                        Button("Delete", role: .destructive) { app.model.removeTemplate(template.id) }
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Sport", selection: $sportFilter) {
                        Text("All").tag(Sport?.none)
                        Text("Ride").tag(Sport?.some(.ride))
                        Text("Run").tag(Sport?.some(.run))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // A NavigationLink inside a Menu is a dead pattern (the menu
                    // dismisses without pushing), so present the builder as a
                    // sheet from a plain Button instead.
                    Menu {
                        Button("New workout") { showingBuilder = true }
                        Button("Import FIT…") { showingImporter = true }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingBuilder) {
                NavigationStack { WorkoutBuilderView() }
            }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [UTType(filenameExtension: "fit") ?? .data]) { result in
                if case .success(let url) = result { importFIT(url) }
            }
            .sheet(item: $exportURL) { doc in
                ShareLink(item: doc.url).padding()
            }
        }
    }

    private func export(_ template: WorkoutTemplate) {
        guard let data = try? app.model.exportFIT(templateID: template.id) else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(template.name).fit")
        try? data.write(to: url)
        exportURL = ExportDocument(url: url)
    }

    private func importFIT(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        _ = try? app.model.importFITWorkout(data)
    }
}

struct WorkoutRow: View {
    let template: WorkoutTemplate
    let app: AppModelObservable

    var body: some View {
        let estimate = WorkoutEstimator.estimate(
            workout: template, on: Date(),
            thresholds: app.model.thresholdStoreSnapshot, zones: app.model.zoneSettings)
        VStack(alignment: .leading) {
            Text(template.name).font(.headline)
            HStack(spacing: 8) {
                Label(template.sport == .ride ? "Ride" : "Run",
                      systemImage: template.sport == .ride ? "bicycle" : "figure.run")
                Text("\(Int(estimate.load)) TSS")
                if !template.tags.isEmpty {
                    Text(template.tags.joined(separator: ", "))
                }
            }
            .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct ExportDocument: Identifiable {
    let id = UUID()
    let url: URL
}
#endif
