import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    var createdAt: Date

    // Many-to-many: deleting a routine unlinks exercises but does not delete them.
    @Relationship(deleteRule: .nullify, inverse: \Exercise.routines)
    var exercises: [Exercise] = []

    // Per-routine exercise ordering stored as an array of Exercise UUIDs.
    var exerciseOrder: [UUID] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }

    var sortedExercises: [Exercise] {
        guard !exerciseOrder.isEmpty else {
            return exercises.sorted { $0.order < $1.order }
        }
        return exercises.sorted { a, b in
            let ai = exerciseOrder.firstIndex(of: a.uuid) ?? Int.max
            let bi = exerciseOrder.firstIndex(of: b.uuid) ?? Int.max
            return ai < bi
        }
    }
}
