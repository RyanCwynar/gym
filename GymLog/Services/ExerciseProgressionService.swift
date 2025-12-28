import Foundation
import SwiftData

enum ExerciseType {
    case barbell
    case dumbbell
    case bodyweight
    case machine
    case cable
}

struct ProgressionSuggestion {
    enum SuggestionType {
        case weight
        case reps
    }

    let type: SuggestionType
    let amount: Double
    let message: String
}

class ExerciseProgressionService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Progression Evaluation

    func evaluateProgression(for exercise: Exercise) -> ProgressionSuggestion? {
        // 1. Check if all sets completed
        let completedSets = exercise.sets.filter { $0.isCompleted }
        guard completedSets.count == exercise.sets.count && !completedSets.isEmpty else {
            return nil  // Not all sets done or no sets at all
        }

        // 2. Check if target reps achieved
        guard let targetReps = exercise.targetReps else {
            return nil  // No target to compare against
        }

        let hitTarget = completedSets.allSatisfy { $0.reps >= targetReps }
        guard hitTarget else {
            return nil  // Didn't hit rep targets
        }

        // 3. Determine exercise type and suggest accordingly
        let exerciseType = determineExerciseType(exercise.name)

        switch exerciseType {
        case .barbell, .dumbbell:
            return ProgressionSuggestion(
                type: .weight,
                amount: 5,
                message: "Great work! Try adding 5 lbs next session."
            )

        case .bodyweight:
            return ProgressionSuggestion(
                type: .reps,
                amount: 1,
                message: "Awesome! Try adding 1 rep per set next time."
            )

        case .machine, .cable:
            return ProgressionSuggestion(
                type: .weight,
                amount: 10,
                message: "Nice! Consider adding 5-10 lbs next session."
            )
        }
    }

    // MARK: - Exercise Type Detection

    private func determineExerciseType(_ exerciseName: String) -> ExerciseType {
        let name = exerciseName.lowercased()

        // Barbell exercises
        let barbellKeywords = ["barbell", "squat", "deadlift", "bench press", "overhead press", "row"]
        if barbellKeywords.contains(where: { name.contains($0) }) && !name.contains("dumbbell") {
            return .barbell
        }

        // Dumbbell exercises
        let dumbbellKeywords = ["dumbbell", "db "]
        if dumbbellKeywords.contains(where: { name.contains($0) }) {
            return .dumbbell
        }

        // Bodyweight exercises
        let bodyweightKeywords = ["pull-up", "chin-up", "push-up", "dip", "plank"]
        if bodyweightKeywords.contains(where: { name.contains($0) }) {
            return .bodyweight
        }

        // Cable exercises
        let cableKeywords = ["cable", "rope", "pulldown", "pushdown"]
        if cableKeywords.contains(where: { name.contains($0) }) {
            return .cable
        }

        // Machine exercises
        let machineKeywords = ["machine", "leg press", "leg curl", "leg extension", "pec deck"]
        if machineKeywords.contains(where: { name.contains($0) }) {
            return .machine
        }

        // Default to barbell type
        return .barbell
    }

    // MARK: - Historical Data Queries

    func getPreviousPerformance(exerciseName: String, limit: Int = 3) -> [ExerciseHistory] {
        let descriptor = FetchDescriptor<ExerciseHistory>(
            predicate: #Predicate { $0.exerciseName == exerciseName },
            sortBy: [SortDescriptor(\.workoutDate, order: .reverse)]
        )

        do {
            let allHistory = try context.fetch(descriptor)
            return Array(allHistory.prefix(limit))
        } catch {
            print("Error fetching exercise history: \(error)")
            return []
        }
    }

    func getLastPerformance(exerciseName: String) -> ExerciseHistory? {
        return getPreviousPerformance(exerciseName: exerciseName, limit: 1).first
    }

    // MARK: - Historical Data Creation

    func createHistoryRecord(for exercise: Exercise, workout: Workout) {
        let historicalSets = exercise.sets.map { set in
            HistoricalSet(
                weight: set.weight,
                reps: set.reps,
                isCompleted: set.isCompleted
            )
        }

        let history = ExerciseHistory(
            exerciseName: exercise.name,
            workoutDate: workout.date,
            sets: historicalSets
        )
        history.workout = workout

        context.insert(history)
    }

    func createHistoryRecords(for workout: Workout) {
        for exercise in workout.exercises {
            createHistoryRecord(for: exercise, workout: workout)
        }

        do {
            try context.save()
        } catch {
            print("Error saving exercise history: \(error)")
        }
    }

    // MARK: - Progress Statistics

    func getProgressTrend(exerciseName: String, timeframe: TimeInterval = 7776000) -> [ExerciseHistory] {
        let startDate = Date().addingTimeInterval(-timeframe)  // Default: 90 days

        let descriptor = FetchDescriptor<ExerciseHistory>(
            predicate: #Predicate { history in
                history.exerciseName == exerciseName && history.workoutDate >= startDate
            },
            sortBy: [SortDescriptor(\.workoutDate, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching progress trend: \(error)")
            return []
        }
    }

    func getPersonalRecord(exerciseName: String) -> ExerciseHistory? {
        let descriptor = FetchDescriptor<ExerciseHistory>(
            predicate: #Predicate { $0.exerciseName == exerciseName }
        )

        do {
            let allHistory = try context.fetch(descriptor)
            return allHistory.max { ($0.bestSet?.volume ?? 0) < ($1.bestSet?.volume ?? 0) }
        } catch {
            print("Error fetching personal record: \(error)")
            return nil
        }
    }

    // MARK: - Helper Functions

    func formatPreviousPerformance(_ history: ExerciseHistory) -> String {
        guard let bestSet = history.bestSet else {
            return "No previous data"
        }

        return "\(Int(bestSet.weight)) lbs × \(bestSet.reps)"
    }

    func suggestStartingWeight(exerciseName: String) -> Double? {
        guard let lastPerformance = getLastPerformance(exerciseName: exerciseName),
              let bestSet = lastPerformance.bestSet else {
            return nil
        }

        return bestSet.weight
    }

    func suggestStartingReps(exerciseName: String) -> Int? {
        guard let lastPerformance = getLastPerformance(exerciseName: exerciseName),
              let bestSet = lastPerformance.bestSet else {
            return nil
        }

        return bestSet.reps
    }
}
