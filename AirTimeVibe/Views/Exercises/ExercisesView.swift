import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var showingAddExercise = false
    @State private var filterCategory: ExerciseCategory? = nil
    @State private var filterMuscleGroup: MuscleGroup? = nil

    private var filteredExercises: [Exercise] {
        exercises.filter { ex in
            (filterCategory == nil || ex.category == filterCategory) &&
            (filterMuscleGroup == nil || ex.primaryMuscleGroup == filterMuscleGroup)
        }
    }

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
                        filterBar
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        if filteredExercises.isEmpty {
                            ContentUnavailableView(
                                "No Matches",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No exercises match the selected filters.")
                            )
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(filteredExercises) { exercise in
                                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                    ExerciseRowView(exercise: exercise)
                                }
                            }
                            .onDelete(perform: deleteExercises)
                        }
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

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredExercises[index])
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let img = systemImage {
                    Label(label, systemImage: img)
                } else {
                    Text(label)
                }
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray5), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
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
                    Image(systemName: exercise.category?.systemImage ?? "figure.strengthtraining.traditional")
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
                HStack(spacing: 6) {
                    Text("\(exercise.sets) sets × \(exercise.reps) reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let group = exercise.primaryMuscleGroup {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(group.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
