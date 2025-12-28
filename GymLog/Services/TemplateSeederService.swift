import Foundation
import SwiftData

class TemplateSeederService {
    static func seedDefaultTemplates(context: ModelContext) {
        // Check if templates already exist
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        if let existingTemplates = try? context.fetch(descriptor),
           !existingTemplates.isEmpty {
            return  // Templates already seeded
        }

        // Create pre-made templates
        let templates = [
            createTotalBodyWorkoutA(),
            createTotalBodyWorkoutB(),
            createPushDay(),
            createPullDay(),
            createLegDay()
        ]

        templates.forEach { context.insert($0) }

        do {
            try context.save()
        } catch {
            print("Error seeding templates: \(error)")
        }
    }

    // MARK: - Total Body Workout A
    private static func createTotalBodyWorkoutA() -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: "Total Body Workout A",
            templateDescription: "Balanced full-body workout focusing on compound movements",
            isCustom: false,
            category: "Total Body"
        )

        let exercises = [
            TemplateExercise(
                exerciseName: "Squat",
                muscleGroup: "Legs",
                order: 0,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 120,
                notes: "Compound movement - focus on depth and form"
            ),
            TemplateExercise(
                exerciseName: "Bench Press",
                muscleGroup: "Chest",
                order: 1,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 120,
                notes: "Primary push movement"
            ),
            TemplateExercise(
                exerciseName: "Barbell Row",
                muscleGroup: "Back",
                order: 2,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 90,
                notes: "Primary pull movement"
            ),
            TemplateExercise(
                exerciseName: "Overhead Press",
                muscleGroup: "Shoulders",
                order: 3,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 90,
                notes: "Shoulder pressing movement"
            ),
            TemplateExercise(
                exerciseName: "Romanian Deadlift",
                muscleGroup: "Legs",
                order: 4,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 90,
                notes: "Hamstring and lower back focus"
            )
        ]

        exercises.forEach { exercise in
            exercise.template = template
            template.templateExercises.append(exercise)
        }

        return template
    }

    // MARK: - Total Body Workout B
    private static func createTotalBodyWorkoutB() -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: "Total Body Workout B",
            templateDescription: "Alternative full-body workout with different exercise variations",
            isCustom: false,
            category: "Total Body"
        )

        let exercises = [
            TemplateExercise(
                exerciseName: "Deadlift",
                muscleGroup: "Back",
                order: 0,
                targetSets: 3,
                targetReps: 8,
                restSeconds: 180,
                notes: "King of compound movements - maintain neutral spine"
            ),
            TemplateExercise(
                exerciseName: "Pull-Ups",
                muscleGroup: "Back",
                order: 1,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 120,
                notes: "Assisted or weighted as needed"
            ),
            TemplateExercise(
                exerciseName: "Incline Dumbbell Press",
                muscleGroup: "Chest",
                order: 2,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 90,
                notes: "Upper chest focus"
            ),
            TemplateExercise(
                exerciseName: "Leg Press",
                muscleGroup: "Legs",
                order: 3,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 90,
                notes: "Quad dominant leg movement"
            ),
            TemplateExercise(
                exerciseName: "Lateral Raises",
                muscleGroup: "Shoulders",
                order: 4,
                targetSets: 3,
                targetReps: 15,
                restSeconds: 60,
                notes: "Shoulder isolation - lighter weight, higher reps"
            )
        ]

        exercises.forEach { exercise in
            exercise.template = template
            template.templateExercises.append(exercise)
        }

        return template
    }

    // MARK: - Push Day
    private static func createPushDay() -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: "Push Day",
            templateDescription: "Chest, shoulders, and triceps focused workout",
            isCustom: false,
            category: "Push"
        )

        let exercises = [
            TemplateExercise(
                exerciseName: "Bench Press",
                muscleGroup: "Chest",
                order: 0,
                targetSets: 4,
                targetReps: 8,
                restSeconds: 120,
                notes: "Primary strength movement"
            ),
            TemplateExercise(
                exerciseName: "Incline Dumbbell Press",
                muscleGroup: "Chest",
                order: 1,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 90,
                notes: "Upper chest development"
            ),
            TemplateExercise(
                exerciseName: "Dumbbell Flyes",
                muscleGroup: "Chest",
                order: 2,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 75,
                notes: "Chest isolation and stretch"
            ),
            TemplateExercise(
                exerciseName: "Overhead Press",
                muscleGroup: "Shoulders",
                order: 3,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 90,
                notes: "Shoulder pressing strength"
            ),
            TemplateExercise(
                exerciseName: "Tricep Pushdown",
                muscleGroup: "Triceps",
                order: 4,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 60,
                notes: "Tricep isolation to finish"
            )
        ]

        exercises.forEach { exercise in
            exercise.template = template
            template.templateExercises.append(exercise)
        }

        return template
    }

    // MARK: - Pull Day
    private static func createPullDay() -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: "Pull Day",
            templateDescription: "Back and biceps focused workout",
            isCustom: false,
            category: "Pull"
        )

        let exercises = [
            TemplateExercise(
                exerciseName: "Deadlift",
                muscleGroup: "Back",
                order: 0,
                targetSets: 3,
                targetReps: 8,
                restSeconds: 180,
                notes: "Primary pulling strength movement"
            ),
            TemplateExercise(
                exerciseName: "Pull-Ups",
                muscleGroup: "Back",
                order: 1,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 120,
                notes: "Vertical pull focus"
            ),
            TemplateExercise(
                exerciseName: "Barbell Row",
                muscleGroup: "Back",
                order: 2,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 90,
                notes: "Horizontal pull for mid-back"
            ),
            TemplateExercise(
                exerciseName: "Lat Pulldown",
                muscleGroup: "Back",
                order: 3,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 75,
                notes: "Lat width development"
            ),
            TemplateExercise(
                exerciseName: "Barbell Curl",
                muscleGroup: "Biceps",
                order: 4,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 60,
                notes: "Bicep isolation to finish"
            )
        ]

        exercises.forEach { exercise in
            exercise.template = template
            template.templateExercises.append(exercise)
        }

        return template
    }

    // MARK: - Leg Day
    private static func createLegDay() -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: "Leg Day",
            templateDescription: "Complete lower body workout",
            isCustom: false,
            category: "Legs"
        )

        let exercises = [
            TemplateExercise(
                exerciseName: "Squat",
                muscleGroup: "Legs",
                order: 0,
                targetSets: 4,
                targetReps: 8,
                restSeconds: 180,
                notes: "Primary leg strength movement"
            ),
            TemplateExercise(
                exerciseName: "Romanian Deadlift",
                muscleGroup: "Legs",
                order: 1,
                targetSets: 3,
                targetReps: 10,
                restSeconds: 120,
                notes: "Hamstring and glute focus"
            ),
            TemplateExercise(
                exerciseName: "Leg Press",
                muscleGroup: "Legs",
                order: 2,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 90,
                notes: "Additional quad volume"
            ),
            TemplateExercise(
                exerciseName: "Leg Curl",
                muscleGroup: "Legs",
                order: 3,
                targetSets: 3,
                targetReps: 12,
                restSeconds: 75,
                notes: "Hamstring isolation"
            ),
            TemplateExercise(
                exerciseName: "Calf Raises",
                muscleGroup: "Legs",
                order: 4,
                targetSets: 4,
                targetReps: 20,
                restSeconds: 60,
                notes: "Calf development - higher rep range"
            )
        ]

        exercises.forEach { exercise in
            exercise.template = template
            template.templateExercises.append(exercise)
        }

        return template
    }
}
