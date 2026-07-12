import Foundation
import SwiftUI
import TrainingCore
import TrainingAppCore

/// SwiftUI bridge over the platform-independent TrainingAppModel. The model
/// holds all logic and is tested on Linux; this wrapper only republishes its
/// `onChange` as `objectWillChange` so views refresh. Keeping it this thin is
/// deliberate — no logic lives here, so nothing here needs a Mac to be trusted.
@MainActor
public final class AppModelObservable: ObservableObject {

    public let model: TrainingAppModel

    public init(model: TrainingAppModel) {
        self.model = model
        model.onChange = { [weak self] in
            Task { @MainActor in self?.objectWillChange.send() }
        }
    }

    /// Convenience factory for the app entry point: JSON snapshot in the
    /// app's Application Support directory.
    public static func live() -> AppModelObservable {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("training-appstate.json")
        let model = TrainingAppModel(persistence: JSONFilePersistence(url: url))
        return AppModelObservable(model: model)
    }

    // Pass-throughs the views use; each triggers the model's own persist+notify.
    public var templates: [WorkoutTemplate] { model.templates() }
    public var events: [TargetEvent] { model.events }
    public var saveError: Error? { model.lastSaveError }
}
