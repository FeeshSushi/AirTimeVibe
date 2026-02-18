import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var context
    let routine: Routine
    @State private var showingAddExercise = false
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
                    ForEach(routine.sortedExercises) { exercise in
                        NavigationLink(destination: ExerciseEditorView(exercise: exercise)) {
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
                HStack {
                    EditButton()
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !routine.exercises.isEmpty {
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
        .sheet(isPresented: $showingAddExercise) {
            NavigationStack {
                ExerciseEditorView(routine: routine)
            }
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            ActiveWorkoutView(routine: routine)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = routine.sortedExercises
        for index in offsets {
            context.delete(sorted[index])
        }
        reorder(routine.sortedExercises)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = routine.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        reorder(sorted)
    }

    private func reorder(_ exercises: [Exercise]) {
        for (i, exercise) in exercises.enumerated() {
            exercise.order = i
        }
    }
}
