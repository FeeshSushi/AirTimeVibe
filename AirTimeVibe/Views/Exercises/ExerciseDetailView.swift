import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingEdit = false
    @State private var player: AVPlayer?

    // Initialize player before first render so VideoPlayer never sees a nil player.
    init(exercise: Exercise) {
        self.exercise = exercise
        if let url = exercise.videoURL {
            self._player = State(initialValue: AVPlayer(url: url))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero media — each branch has a concrete frame so VideoPlayer
                // never collapses to 0×0 (Group with maxHeight alone won't prevent it).
                if let imageURL = exercise.imageURL,
                   let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color(.systemGray5))
                } else if let player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, height: 250)
                        .background(Color(.systemGray5))
                } else {
                    Color(.systemGray5)
                        .frame(maxWidth: .infinity, height: 160)
                        .overlay {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Name
                    Text(exercise.name)
                        .font(.largeTitle)
                        .bold()

                    // Notes (hidden if empty)
                    if !exercise.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                            Text(exercise.notes)
                                .font(.body)
                        }
                    }

                    // Volume
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Volume")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text("\(exercise.sets) sets × \(exercise.reps) reps")
                            .font(.body)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ExerciseEditorView(exercise: exercise)
            }
        }
    }
}
