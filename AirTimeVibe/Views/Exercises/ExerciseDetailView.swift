import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                Group {
                    if let imageURL = exercise.imageURL,
                       let uiImage = UIImage(contentsOfFile: imageURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(Color(.systemGray5))
                .clipped()

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
