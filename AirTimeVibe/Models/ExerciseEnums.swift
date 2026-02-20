import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case stretch  = "Stretch"
    case mobility = "Mobility"
    case strength = "Strength"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .stretch:  "figure.flexibility"
        case .mobility: "figure.mixed.cardio"
        case .strength: "figure.strengthtraining.traditional"
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest      = "Chest"
    case back       = "Back"
    case shoulders  = "Shoulders"
    case biceps     = "Biceps"
    case triceps    = "Triceps"
    case forearms   = "Forearms"
    case core       = "Core"
    case quads      = "Quads"
    case hamstrings = "Hamstrings"
    case glutes     = "Glutes"
    case calves     = "Calves"
    case hipFlexors = "Hip Flexors"
    case fullBody   = "Full Body"

    var id: String { rawValue }
}
