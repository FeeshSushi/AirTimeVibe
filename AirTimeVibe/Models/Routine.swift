import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Exercise.routine)
    var exercises: [Exercise] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }

    var sortedExercises: [Exercise] {
        exercises.sorted { $0.order < $1.order }
    }
}
