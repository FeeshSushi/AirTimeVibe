import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RoutinesView()
                .tabItem {
                    Label("Routines", systemImage: "dumbbell.fill")
                }
            ExercisesView()
                .tabItem {
                    Label("Exercises", systemImage: "figure.run")
                }
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
    }
}
