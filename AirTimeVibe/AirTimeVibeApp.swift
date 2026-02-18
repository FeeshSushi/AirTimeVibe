import SwiftUI
import SwiftData

@main
struct AirTimeVibeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Routine.self, WorkoutSession.self])
    }
}
