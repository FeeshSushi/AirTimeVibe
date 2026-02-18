import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var showingAddExercise = false

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "figure.run",
                        description: Text("Tap + to create your first exercise.")
                    )
                } else {
                    List {
                        ForEach(exercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRowView(exercise: exercise)
                            }
                        }
                        .onDelete(perform: deleteExercises)
                    }
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                NavigationStack {
                    ExerciseEditorView(routine: nil)
                }
            }
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            context.delete(exercises[index])
        }
    }
}

// MARK: - Row

private struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail: image > video placeholder > default icon
            Group {
                if let imageURL = exercise.imageURL,
                   let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if exercise.videoFileName != nil {
                    Image(systemName: "video.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 48, height: 48)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !exercise.routines.isEmpty {
                    Text(exercise.routines.map(\.name).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
