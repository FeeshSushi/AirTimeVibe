import SwiftUI
import SwiftData
import AVKit

// MARK: - Draft types (in-memory, not persisted until session is saved)

struct SetEntryDraft {
    var weight: Double = 0
    var reps: Int
    var completed: Bool = false

    init(targetReps: Int = 0) {
        self.reps = targetReps
    }
}

struct ExerciseLogDraft {
    var exerciseName: String
    var targetSets: Int
    var targetReps: Int
    var sets: [SetEntryDraft]

    init(exercise: Exercise) {
        self.exerciseName = exercise.name
        self.targetSets = exercise.sets
        self.targetReps = exercise.reps
        self.sets = Array(repeating: SetEntryDraft(targetReps: exercise.reps), count: exercise.sets)
    }
}

// MARK: - ActiveWorkoutView

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let routine: Routine

    @State private var currentIndex = 0
    @State private var drafts: [ExerciseLogDraft] = []
    @State private var showFinishConfirm = false
    @State private var finished = false

    private var sortedExercises: [Exercise] { routine.sortedExercises }
    private var currentExercise: Exercise? {
        guard currentIndex < sortedExercises.count else { return nil }
        return sortedExercises[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentIndex + 1), total: Double(sortedExercises.count))
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("\(currentIndex + 1) / \(sortedExercises.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if finished {
                    finishedView
                } else if let exercise = currentExercise, currentIndex < drafts.count {
                    exerciseView(exercise: exercise, draftIndex: currentIndex)
                }

                // Navigation row
                HStack {
                    if currentIndex > 0 {
                        Button("Previous") { currentIndex -= 1 }
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    if !finished {
                        if currentIndex < sortedExercises.count - 1 {
                            Button("Next") { currentIndex += 1 }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Finish") { showFinishConfirm = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog("Save this workout?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
                Button("Save & Finish") { saveSession() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onAppear {
            drafts = sortedExercises.map { ExerciseLogDraft(exercise: $0) }
        }
    }

    // MARK: - Exercise View

    @ViewBuilder
    private func exerciseView(exercise: Exercise, draftIndex: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text(exercise.name)
                        .font(.title.bold())
                    Text("Target: \(exercise.sets) sets × \(exercise.reps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Video
                if let url = exercise.videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                // Notes
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Sets
                VStack(spacing: 10) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        SetRowView(
                            setNumber: setIndex + 1,
                            targetReps: exercise.reps,
                            draft: draftBinding(draftIndex: draftIndex, setIndex: setIndex)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    // MARK: - Finished View

    private var finishedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Workout Complete!")
                .font(.largeTitle.bold())
            Text("Great work today.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Binding helper

    private func draftBinding(draftIndex: Int, setIndex: Int) -> Binding<SetEntryDraft> {
        Binding(
            get: {
                guard draftIndex < drafts.count, setIndex < drafts[draftIndex].sets.count else {
                    return SetEntryDraft()
                }
                return drafts[draftIndex].sets[setIndex]
            },
            set: { newValue in
                guard draftIndex < drafts.count, setIndex < drafts[draftIndex].sets.count else { return }
                drafts[draftIndex].sets[setIndex] = newValue
            }
        )
    }

    // MARK: - Persistence

    private func saveSession() {
        let session = WorkoutSession(routine: routine)
        context.insert(session)

        for draft in drafts {
            let log = ExerciseLog(
                exerciseName: draft.exerciseName,
                targetSets: draft.targetSets,
                targetReps: draft.targetReps
            )
            log.completedSets = draft.sets.map { SetEntry(weight: $0.weight, reps: $0.reps) }
            log.session = session
            context.insert(log)
        }

        finished = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - SetRowView

struct SetRowView: View {
    let setNumber: Int
    let targetReps: Int
    @Binding var draft: SetEntryDraft

    var body: some View {
        HStack(spacing: 10) {
            Text("Set \(setNumber)")
                .font(.subheadline.bold())
                .frame(width: 54, alignment: .leading)

            // Weight field
            HStack(spacing: 4) {
                Image(systemName: "scalemass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("0", value: $draft.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 52)
                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Reps field
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("\(targetReps)", value: $draft.reps, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 40)
                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Spacer()

            // Complete toggle
            Button {
                draft.completed.toggle()
            } label: {
                Image(systemName: draft.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(draft.completed ? .green : .secondary)
            }
        }
        .padding()
        .background(draft.completed ? Color.green.opacity(0.08) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
