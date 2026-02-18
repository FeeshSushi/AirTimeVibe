import SwiftUI
import SwiftData

struct ExerciseLibraryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let routine: Routine

    // Exercises not yet linked to this routine
    private var availableExercises: [Exercise] {
        let existingIDs = Set(routine.exercises.map(\.id))
        return allExercises.filter { !existingIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availableExercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises to Add",
                        systemImage: "checkmark.circle",
                        description: Text("All library exercises are already in this routine.")
                    )
                } else {
                    List {
                        ForEach(availableExercises) { exercise in
                            Button {
                                addToRoutine(exercise)
                            } label: {
                                PickerRowView(exercise: exercise)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Add from Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addToRoutine(_ exercise: Exercise) {
        exercise.order = routine.exercises.count
        routine.exercises.append(exercise)
        dismiss()
    }
}

// MARK: - Row

private struct PickerRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let imageURL = exercise.imageURL,
                   let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "plus.circle")
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}
