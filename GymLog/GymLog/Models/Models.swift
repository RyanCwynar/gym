import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var date: Date
    var name: String
    var notes: String
    var duration: TimeInterval
    var isCompleted: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        name: String = "Workout",
        notes: String = "",
        duration: TimeInterval = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.notes = notes
        self.duration = duration
        self.isCompleted = isCompleted
        self.exercises = []
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (Double(set.reps) * set.weight)
            }
        }
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var order: Int
    var workout: Workout?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]
    
    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String = "",
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.order = order
        self.sets = []
    }
    
    var sortedSets: [ExerciseSet] {
        sets.sorted { $0.order < $1.order }
    }
    
    var bestSet: ExerciseSet? {
        sets.max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }
}

@Model
final class ExerciseSet {
    var id: UUID
    var reps: Int
    var weight: Double
    var order: Int
    var isCompleted: Bool
    var exercise: Exercise?
    
    init(
        id: UUID = UUID(),
        reps: Int = 0,
        weight: Double = 0,
        order: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.order = order
        self.isCompleted = isCompleted
    }
    
    var volume: Double {
        Double(reps) * weight
    }
}

// MARK: - Muscle Groups
enum MuscleGroup: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    
    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.strengthtraining.traditional"
        case .triceps: return "figure.strengthtraining.functional"
        case .legs: return "figure.run"
        case .core: return "figure.core.training"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
    
    var color: String {
        switch self {
        case .chest: return "ChestColor"
        case .back: return "BackColor"
        case .shoulders: return "ShouldersColor"
        case .biceps: return "BicepsColor"
        case .triceps: return "TricepsColor"
        case .legs: return "LegsColor"
        case .core: return "CoreColor"
        case .cardio: return "CardioColor"
        case .fullBody: return "FullBodyColor"
        }
    }
}

