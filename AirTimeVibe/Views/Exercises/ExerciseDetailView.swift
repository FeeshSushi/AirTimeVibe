import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingEdit = false
    @State private var player: AVPlayer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero media
                Group {
                    if let imageURL = exercise.imageURL,
                       let uiImage = UIImage(contentsOfFile: imageURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else if exercise.videoURL != nil {
                        VideoPlayer(player: player)
                    } else {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 160)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color(.systemGray5))

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
        .onAppear {
            if let url = exercise.videoURL {
                player = AVPlayer(url: url)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ExerciseEditorView(exercise: exercise)
            }
        }
    }
}
