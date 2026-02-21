import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var context
    let routine: Routine
    @State private var showingAddExercise = false
    @State private var showingAddOptions = false
    @State private var showingExercisePicker = false
    @State private var showingWorkout = false

    var body: some View {
        Group {
            if routine.sortedExercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Tap + to add your first exercise.")
                )
            } else {
                List {
                    ForEach(Array(routine.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24, alignment: .center)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    Text("\(exercise.sets) sets × \(exercise.reps) reps")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !exercise.notes.isEmpty {
                                        Text(exercise.notes)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    EditButton()
                    Button {
                        showingAddOptions = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !routine.sortedExercises.isEmpty {
                Button {
                    showingWorkout = true
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.bar)
            }
        }
        .confirmationDialog("Add Exercise", isPresented: $showingAddOptions, titleVisibility: .visible) {
            Button("Create New Exercise") { showingAddExercise = true }
            Button("Add from Library")   { showingExercisePicker = true }
        }
        .sheet(isPresented: $showingAddExercise) {
            NavigationStack {
                ExerciseEditorView(routine: routine)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExerciseLibraryPickerView(routine: routine)
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            ActiveWorkoutView(routine: routine)
        }
    }

    // Unlinks the exercise from this routine only — does not delete it from the library.
    private func deleteExercises(at offsets: IndexSet) {
        let sorted = routine.sortedExercises
        for index in offsets {
            let ex = sorted[index]
            routine.exercises.removeAll { $0.id == ex.id }
        }
        reorder(routine.sortedExercises)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = routine.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        reorder(sorted)
    }

    private func reorder(_ exercises: [Exercise]) {
        routine.exerciseOrder = exercises.map(\.uuid)
    }
}
