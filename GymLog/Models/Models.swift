import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var date: Date
    var startDate: Date  // When workout actually started (for timer)
    var name: String
    var notes: String
    var duration: TimeInterval       // Total duration of workout
    var savedWorkTime: TimeInterval  // Total time spent actually doing sets
    var isCompleted: Bool
    var templateId: UUID?
    var templateName: String?
    var repeatedFromWorkoutId: UUID?  // ID of workout this was repeated from (for comparison)

    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startDate: Date = Date(),
        name: String = "Workout",
        notes: String = "",
        duration: TimeInterval = 0,
        savedWorkTime: TimeInterval = 0,
        isCompleted: Bool = false,
        templateId: UUID? = nil,
        templateName: String? = nil,
        repeatedFromWorkoutId: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.startDate = startDate
        self.name = name
        self.notes = notes
        self.duration = duration
        self.savedWorkTime = savedWorkTime
        self.isCompleted = isCompleted
        self.templateId = templateId
        self.templateName = templateName
        self.repeatedFromWorkoutId = repeatedFromWorkoutId
        self.exercises = []
    }
    
    var elapsedTime: TimeInterval {
        let elapsed = Date().timeIntervalSince(startDate)
        // Cap at 2 hours (7200 seconds)
        return min(elapsed, 7200)
    }
    
    // Total work time across all sets
    var totalWorkTime: TimeInterval {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                var time = set.workTime
                // Add currently running timer if active
                if let startTime = set.workStartTime {
                    time += Date().timeIntervalSince(startTime)
                }
                return setTotal + time
            }
        }
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

    var usedTemplate: Bool {
        templateId != nil
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var order: Int
    var targetSets: Int?
    var targetReps: Int?
    var previousBest: String?
    var suggestionNote: String?
    var duration: TimeInterval  // For cardio exercises (in seconds)
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String = "",
        order: Int = 0,
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        previousBest: String? = nil,
        suggestionNote: String? = nil,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.previousBest = previousBest
        self.suggestionNote = suggestionNote
        self.duration = duration
        self.sets = []
    }
    
    var isCardio: Bool {
        muscleGroup.lowercased() == "cardio"
    }
    
    var sortedSets: [ExerciseSet] {
        sets.sorted { $0.order < $1.order }
    }
    
    var bestSet: ExerciseSet? {
        sets.max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }

    var hasProgression: Bool {
        guard let targetReps = targetReps else { return false }
        return sets.allSatisfy { $0.isCompleted && $0.reps >= targetReps }
    }
}

@Model
final class ExerciseSet {
    var id: UUID
    var reps: Int
    var weight: Double
    var order: Int
    var isCompleted: Bool
    var previousWeight: Double?
    var previousReps: Int?
    var workTime: TimeInterval  // Actual time spent doing the set (in seconds)
    var workStartTime: Date?    // When the set timer started (for persistence)
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        reps: Int = 0,
        weight: Double = 0,
        order: Int = 0,
        isCompleted: Bool = false,
        previousWeight: Double? = nil,
        previousReps: Int? = nil,
        workTime: TimeInterval = 0,
        workStartTime: Date? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.order = order
        self.isCompleted = isCompleted
        self.previousWeight = previousWeight
        self.previousReps = previousReps
        self.workTime = workTime
        self.workStartTime = workStartTime
    }
    
    var volume: Double {
        Double(reps) * weight
    }
    
    var isTimerRunning: Bool {
        workStartTime != nil
    }
}

// MARK: - Workout Template
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var templateDescription: String
    var isCustom: Bool
    var category: String
    var createdDate: Date
    var lastUsed: Date?
    var timesUsed: Int

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var templateExercises: [TemplateExercise]

    init(
        id: UUID = UUID(),
        name: String,
        templateDescription: String = "",
        isCustom: Bool = false,
        category: String = "Total Body",
        createdDate: Date = Date(),
        lastUsed: Date? = nil,
        timesUsed: Int = 0
    ) {
        self.id = id
        self.name = name
        self.templateDescription = templateDescription
        self.isCustom = isCustom
        self.category = category
        self.createdDate = createdDate
        self.lastUsed = lastUsed
        self.timesUsed = timesUsed
        self.templateExercises = []
    }

    var estimatedDuration: TimeInterval {
        let averageSecondsPerSet = 45.0
        let averageRestBetweenSets = 90.0
        let totalSets = templateExercises.reduce(0) { $0 + $1.targetSets }
        return TimeInterval(totalSets) * (averageSecondsPerSet + averageRestBetweenSets)
    }
}

// MARK: - Template Exercise
@Model
final class TemplateExercise {
    var id: UUID
    var exerciseName: String
    var muscleGroup: String
    var order: Int
    var targetSets: Int
    var targetReps: Int
    var restSeconds: Int
    var notes: String

    var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        muscleGroup: String = "",
        order: Int = 0,
        targetSets: Int = 3,
        targetReps: Int = 10,
        restSeconds: Int = 90,
        notes: String = ""
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

// MARK: - Exercise History
@Model
final class ExerciseHistory {
    var id: UUID
    var exerciseName: String
    var workoutDate: Date
    var setsData: Data

    var workout: Workout?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        workoutDate: Date,
        sets: [HistoricalSet]
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.workoutDate = workoutDate

        if let encoded = try? JSONEncoder().encode(sets) {
            self.setsData = encoded
        } else {
            self.setsData = Data()
        }
    }

    var sets: [HistoricalSet] {
        get {
            if let decoded = try? JSONDecoder().decode([HistoricalSet].self, from: setsData) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                setsData = encoded
            }
        }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    var bestSet: HistoricalSet? {
        sets.max { $0.volume < $1.volume }
    }

    var averageWeight: Double {
        guard !sets.isEmpty else { return 0 }
        let totalWeight = sets.reduce(0.0) { $0 + $1.weight }
        return totalWeight / Double(sets.count)
    }
}

// MARK: - Historical Set
struct HistoricalSet: Codable {
    let weight: Double
    let reps: Int
    let isCompleted: Bool

    var volume: Double {
        weight * Double(reps)
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

