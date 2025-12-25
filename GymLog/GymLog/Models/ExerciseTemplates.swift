import Foundation

struct ExerciseTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscleGroup: MuscleGroup
    let description: String
    let isPrimary: Bool
    
    init(name: String, muscleGroup: MuscleGroup, description: String = "", isPrimary: Bool = false) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.description = description
        self.isPrimary = isPrimary
    }
}

struct ExerciseLibrary {
    static let exercises: [ExerciseTemplate] = [
        // Chest
        ExerciseTemplate(name: "Bench Press", muscleGroup: .chest, description: "Barbell bench press", isPrimary: true),
        ExerciseTemplate(name: "Incline Bench Press", muscleGroup: .chest, description: "Incline barbell press"),
        ExerciseTemplate(name: "Dumbbell Bench Press", muscleGroup: .chest, description: "Flat dumbbell press"),
        ExerciseTemplate(name: "Incline Dumbbell Press", muscleGroup: .chest, description: "Incline dumbbell press"),
        ExerciseTemplate(name: "Cable Flyes", muscleGroup: .chest, description: "Cable chest flyes"),
        ExerciseTemplate(name: "Dumbbell Flyes", muscleGroup: .chest, description: "Flat dumbbell flyes"),
        ExerciseTemplate(name: "Push-Ups", muscleGroup: .chest, description: "Bodyweight push-ups"),
        ExerciseTemplate(name: "Chest Dips", muscleGroup: .chest, description: "Weighted or bodyweight dips"),
        ExerciseTemplate(name: "Machine Chest Press", muscleGroup: .chest, description: "Machine press"),
        ExerciseTemplate(name: "Pec Deck", muscleGroup: .chest, description: "Pec deck machine"),
        
        // Back
        ExerciseTemplate(name: "Deadlift", muscleGroup: .back, description: "Conventional deadlift", isPrimary: true),
        ExerciseTemplate(name: "Pull-Ups", muscleGroup: .back, description: "Bodyweight or weighted pull-ups", isPrimary: true),
        ExerciseTemplate(name: "Barbell Row", muscleGroup: .back, description: "Bent over barbell row"),
        ExerciseTemplate(name: "Dumbbell Row", muscleGroup: .back, description: "Single arm dumbbell row"),
        ExerciseTemplate(name: "Lat Pulldown", muscleGroup: .back, description: "Cable lat pulldown"),
        ExerciseTemplate(name: "Seated Cable Row", muscleGroup: .back, description: "Seated row machine"),
        ExerciseTemplate(name: "T-Bar Row", muscleGroup: .back, description: "T-bar row"),
        ExerciseTemplate(name: "Face Pulls", muscleGroup: .back, description: "Cable face pulls"),
        ExerciseTemplate(name: "Chin-Ups", muscleGroup: .back, description: "Underhand grip pull-ups"),
        ExerciseTemplate(name: "Romanian Deadlift", muscleGroup: .back, description: "RDL for hamstrings and lower back"),
        
        // Shoulders
        ExerciseTemplate(name: "Overhead Press", muscleGroup: .shoulders, description: "Standing barbell press", isPrimary: true),
        ExerciseTemplate(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, description: "Seated dumbbell press"),
        ExerciseTemplate(name: "Lateral Raises", muscleGroup: .shoulders, description: "Dumbbell side raises"),
        ExerciseTemplate(name: "Front Raises", muscleGroup: .shoulders, description: "Dumbbell front raises"),
        ExerciseTemplate(name: "Rear Delt Flyes", muscleGroup: .shoulders, description: "Bent over rear delt flyes"),
        ExerciseTemplate(name: "Arnold Press", muscleGroup: .shoulders, description: "Rotating dumbbell press"),
        ExerciseTemplate(name: "Upright Row", muscleGroup: .shoulders, description: "Barbell or dumbbell upright row"),
        ExerciseTemplate(name: "Shrugs", muscleGroup: .shoulders, description: "Barbell or dumbbell shrugs"),
        ExerciseTemplate(name: "Machine Shoulder Press", muscleGroup: .shoulders, description: "Seated machine press"),
        
        // Biceps
        ExerciseTemplate(name: "Barbell Curl", muscleGroup: .biceps, description: "Standing barbell curl", isPrimary: true),
        ExerciseTemplate(name: "Dumbbell Curl", muscleGroup: .biceps, description: "Standing or seated dumbbell curls"),
        ExerciseTemplate(name: "Hammer Curl", muscleGroup: .biceps, description: "Neutral grip dumbbell curls"),
        ExerciseTemplate(name: "Preacher Curl", muscleGroup: .biceps, description: "EZ bar or dumbbell preacher curls"),
        ExerciseTemplate(name: "Incline Dumbbell Curl", muscleGroup: .biceps, description: "Incline bench curls"),
        ExerciseTemplate(name: "Cable Curl", muscleGroup: .biceps, description: "Standing cable curls"),
        ExerciseTemplate(name: "Concentration Curl", muscleGroup: .biceps, description: "Seated single arm curls"),
        ExerciseTemplate(name: "EZ Bar Curl", muscleGroup: .biceps, description: "EZ bar curls"),
        
        // Triceps
        ExerciseTemplate(name: "Tricep Pushdown", muscleGroup: .triceps, description: "Cable pushdowns", isPrimary: true),
        ExerciseTemplate(name: "Skull Crushers", muscleGroup: .triceps, description: "Lying tricep extension"),
        ExerciseTemplate(name: "Close Grip Bench Press", muscleGroup: .triceps, description: "Narrow grip bench press"),
        ExerciseTemplate(name: "Overhead Tricep Extension", muscleGroup: .triceps, description: "Cable or dumbbell overhead extension"),
        ExerciseTemplate(name: "Tricep Dips", muscleGroup: .triceps, description: "Bench or parallel bar dips"),
        ExerciseTemplate(name: "Diamond Push-Ups", muscleGroup: .triceps, description: "Close hand push-ups"),
        ExerciseTemplate(name: "Rope Pushdown", muscleGroup: .triceps, description: "Rope cable pushdowns"),
        ExerciseTemplate(name: "Kickbacks", muscleGroup: .triceps, description: "Dumbbell tricep kickbacks"),
        
        // Legs
        ExerciseTemplate(name: "Squat", muscleGroup: .legs, description: "Barbell back squat", isPrimary: true),
        ExerciseTemplate(name: "Leg Press", muscleGroup: .legs, description: "Machine leg press", isPrimary: true),
        ExerciseTemplate(name: "Lunges", muscleGroup: .legs, description: "Walking or stationary lunges"),
        ExerciseTemplate(name: "Leg Extension", muscleGroup: .legs, description: "Machine leg extension"),
        ExerciseTemplate(name: "Leg Curl", muscleGroup: .legs, description: "Lying or seated leg curl"),
        ExerciseTemplate(name: "Calf Raises", muscleGroup: .legs, description: "Standing or seated calf raises"),
        ExerciseTemplate(name: "Bulgarian Split Squat", muscleGroup: .legs, description: "Rear foot elevated split squat"),
        ExerciseTemplate(name: "Hack Squat", muscleGroup: .legs, description: "Machine hack squat"),
        ExerciseTemplate(name: "Front Squat", muscleGroup: .legs, description: "Barbell front squat"),
        ExerciseTemplate(name: "Hip Thrust", muscleGroup: .legs, description: "Barbell hip thrust"),
        ExerciseTemplate(name: "Goblet Squat", muscleGroup: .legs, description: "Dumbbell or kettlebell squat"),
        
        // Core
        ExerciseTemplate(name: "Plank", muscleGroup: .core, description: "Front plank hold", isPrimary: true),
        ExerciseTemplate(name: "Crunches", muscleGroup: .core, description: "Bodyweight crunches"),
        ExerciseTemplate(name: "Hanging Leg Raise", muscleGroup: .core, description: "Hanging from bar"),
        ExerciseTemplate(name: "Cable Crunch", muscleGroup: .core, description: "Kneeling cable crunch"),
        ExerciseTemplate(name: "Russian Twist", muscleGroup: .core, description: "Weighted or bodyweight twists"),
        ExerciseTemplate(name: "Ab Wheel Rollout", muscleGroup: .core, description: "Ab wheel exercise"),
        ExerciseTemplate(name: "Mountain Climbers", muscleGroup: .core, description: "Dynamic plank exercise"),
        ExerciseTemplate(name: "Dead Bug", muscleGroup: .core, description: "Core stability exercise"),
        ExerciseTemplate(name: "Side Plank", muscleGroup: .core, description: "Lateral core hold"),
        
        // Cardio
        ExerciseTemplate(name: "Treadmill", muscleGroup: .cardio, description: "Running or walking"),
        ExerciseTemplate(name: "Stationary Bike", muscleGroup: .cardio, description: "Cycling"),
        ExerciseTemplate(name: "Rowing Machine", muscleGroup: .cardio, description: "Rowing ergometer"),
        ExerciseTemplate(name: "Elliptical", muscleGroup: .cardio, description: "Elliptical machine"),
        ExerciseTemplate(name: "Stair Climber", muscleGroup: .cardio, description: "Stair stepper"),
        ExerciseTemplate(name: "Jump Rope", muscleGroup: .cardio, description: "Skipping rope"),
    ]
    
    static func exercises(for muscleGroup: MuscleGroup) -> [ExerciseTemplate] {
        exercises.filter { $0.muscleGroup == muscleGroup }
    }
    
    static func search(_ query: String) -> [ExerciseTemplate] {
        guard !query.isEmpty else { return exercises }
        return exercises.filter { 
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.muscleGroup.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    static var primaryExercises: [ExerciseTemplate] {
        exercises.filter { $0.isPrimary }
    }
}

