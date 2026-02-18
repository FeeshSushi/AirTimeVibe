import SwiftUI
import SwiftData

struct ExerciseLibraryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let routine: Routine

    @State private var selectedIDs: Set<PersistentIdentifier> = []

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
                                toggleSelection(exercise)
                            } label: {
                                PickerRowView(exercise: exercise, isSelected: selectedIDs.contains(exercise.id))
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedIDs.count))") {
                        addSelected()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(_ exercise: Exercise) {
        if selectedIDs.contains(exercise.id) {
            selectedIDs.remove(exercise.id)
        } else {
            selectedIDs.insert(exercise.id)
        }
    }

    private func addSelected() {
        let exercises = availableExercises.filter { selectedIDs.contains($0.id) }
        for exercise in exercises {
            exercise.order = routine.exercises.count
            routine.exercises.append(exercise)
        }
        dismiss()
    }
}

// MARK: - Row

private struct PickerRowView: View {
    let exercise: Exercise
    let isSelected: Bool

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

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : Color(.systemGray3))
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}
