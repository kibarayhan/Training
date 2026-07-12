#if canImport(SwiftUI)
import SwiftUI
import TrainingAppCore

/// App entry point. The @main type and Info.plist usage strings
/// (NSHealthShareUsageDescription, WorkoutKit scheduling) are added when the
/// Xcode project is created on Mac-day; this file provides the root scene.
///
/// UNVERIFIED: not compiled without Xcode. Structure reviewed by eye.
@main
struct TrainingApp: App {
    @StateObject private var app = AppModelObservable.live()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(app)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject var app: AppModelObservable

    var body: some View {
        TabView {
            CalendarScreen()
                .tabItem { Label("Plan", systemImage: "calendar") }
            LibraryScreen()
                .tabItem { Label("Library", systemImage: "square.stack") }
            DashboardScreen()
                .tabItem { Label("Fitness", systemImage: "chart.xyaxis.line") }
            ProfileScreen()
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .overlay(alignment: .top) {
            if app.saveError != nil {
                Text("Couldn’t save — check available storage")
                    .font(.footnote).padding(8)
                    .background(.red.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
        }
    }
}
#endif
