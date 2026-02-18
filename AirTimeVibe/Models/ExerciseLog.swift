import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var exerciseName: String
    var targetSets: Int
    var targetReps: Int
    var completedSets: [SetEntry]
    var session: WorkoutSession?

    init(exerciseName: String, targetSets: Int, targetReps: Int) {
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.completedSets = []
    }
}

struct SetEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var weight: Double
    var reps: Int
}
