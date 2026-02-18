import SwiftUI

struct SessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: session.date.formatted(date: .complete, time: .shortened))
                LabeledContent("Routine", value: session.routineName)
                LabeledContent("Exercises", value: "\(session.exerciseLogs.count)")
            }

            ForEach(session.exerciseLogs.sorted(by: { $0.exerciseName < $1.exerciseName })) { log in
                Section(log.exerciseName) {
                    let target = "Target: \(log.targetSets) × \(log.targetReps)"
                    Text(target)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if log.completedSets.isEmpty {
                        Text("No sets logged")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(log.completedSets.enumerated()), id: \.offset) { index, entry in
                            HStack {
                                Text("Set \(index + 1)")
                                    .font(.subheadline)
                                Spacer()
                                if entry.weight > 0 {
                                    Text("\(entry.weight, specifier: "%.1f") kg")
                                        .foregroundStyle(.secondary)
                                }
                                Text("× \(entry.reps) reps")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
