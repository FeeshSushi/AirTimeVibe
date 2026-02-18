import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var routineName: String
    var routine: Routine?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog] = []

    init(routine: Routine) {
        self.date = Date()
        self.routineName = routine.name
        self.routine = routine
    }
}
