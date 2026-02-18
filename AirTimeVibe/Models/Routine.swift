import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    var createdAt: Date

    // Many-to-many: deleting a routine unlinks exercises but does not delete them.
    @Relationship(deleteRule: .nullify, inverse: \Exercise.routines)
    var exercises: [Exercise] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }

    var sortedExercises: [Exercise] {
        exercises.sorted { $0.order < $1.order }
    }
}
