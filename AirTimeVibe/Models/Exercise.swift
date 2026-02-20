import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var sets: Int
    var reps: Int
    var notes: String
    var videoFileName: String?
    var trimStart: Double
    var trimEnd: Double
    var order: Int
    var imageFileName: String?
    var category: ExerciseCategory?
    var primaryMuscleGroup: MuscleGroup?

    // Many-to-many: an exercise can belong to multiple routines.
    // Routine owns the @Relationship annotation; SwiftData infers this side from the inverse: keypath.
    var routines: [Routine] = []

    init(name: String, sets: Int = 3, reps: Int = 10, notes: String = "", order: Int = 0) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.trimStart = 0
        self.trimEnd = 0
        self.order = order
    }

    var videoURL: URL? {
        guard let fileName = videoFileName else { return nil }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    var imageURL: URL? {
        guard let fileName = imageFileName else { return nil }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }
}
