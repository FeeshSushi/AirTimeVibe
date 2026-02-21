import SwiftUI
import SwiftData

struct ExerciseLibraryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let routine: Routine

    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var filterCategory: ExerciseCategory? = nil
    @State private var filterMuscleGroup: MuscleGroup? = nil

    // Exercises not yet linked to this routine
    private var allAvailableExercises: [Exercise] {
        let existingIDs = Set(routine.exercises.map(\.id))
        return allExercises.filter { !existingIDs.contains($0.id) }
    }

    private var filteredAvailableExercises: [Exercise] {
        allAvailableExercises.filter { ex in
            (filterCategory == nil || ex.category == filterCategory) &&
            (filterMuscleGroup == nil || ex.primaryMuscleGroup == filterMuscleGroup)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allAvailableExercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises to Add",
                        systemImage: "checkmark.circle",
                        description: Text("All library exercises are already in this routine.")
                    )
                } else {
                    List {
                        filterBar
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        if filteredAvailableExercises.isEmpty {
                            ContentUnavailableView(
                                "No Matches",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No exercises match the selected filters.")
                            )
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(filteredAvailableExercises) { exercise in
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: filterCategory == nil) {
                        filterCategory = nil
                    }
                    ForEach(ExerciseCategory.allCases) { cat in
                        FilterChip(
                            label: cat.rawValue,
                            systemImage: cat.systemImage,
                            isSelected: filterCategory == cat
                        ) {
                            filterCategory = filterCategory == cat ? nil : cat
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "Any Muscle", isSelected: filterMuscleGroup == nil) {
                        filterMuscleGroup = nil
                    }
                    ForEach(MuscleGroup.allCases) { group in
                        FilterChip(label: group.rawValue, isSelected: filterMuscleGroup == group) {
                            filterMuscleGroup = filterMuscleGroup == group ? nil : group
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Helpers

    private func toggleSelection(_ exercise: Exercise) {
        if selectedIDs.contains(exercise.id) {
            selectedIDs.remove(exercise.id)
        } else {
            selectedIDs.insert(exercise.id)
        }
    }

    private func addSelected() {
        let exercises = filteredAvailableExercises.filter { selectedIDs.contains($0.id) }
        for exercise in exercises {
            routine.exercises.append(exercise)
            routine.exerciseOrder.append(exercise.uuid)
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
