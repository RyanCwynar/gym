import Foundation

struct ExerciseTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscleGroup: MuscleGroup
    let description: String
    let isPrimary: Bool
    let defaultWeight: Double  // Default weight in lbs for a 90kg male in decent shape
    
    init(name: String, muscleGroup: MuscleGroup, description: String = "", isPrimary: Bool = false, defaultWeight: Double = 0) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.description = description
        self.isPrimary = isPrimary
        self.defaultWeight = defaultWeight
    }
}

struct ExerciseLibrary {
    static let exercises: [ExerciseTemplate] = [
        // Chest - defaults for 90kg male
        ExerciseTemplate(name: "Bench Press", muscleGroup: .chest, description: "Barbell bench press", isPrimary: true, defaultWeight: 135),
        ExerciseTemplate(name: "Incline Bench Press", muscleGroup: .chest, description: "Incline barbell press", defaultWeight: 115),
        ExerciseTemplate(name: "Dumbbell Bench Press", muscleGroup: .chest, description: "Flat dumbbell press", defaultWeight: 50),  // per dumbbell
        ExerciseTemplate(name: "Incline Dumbbell Press", muscleGroup: .chest, description: "Incline dumbbell press", defaultWeight: 45),
        ExerciseTemplate(name: "Cable Flyes", muscleGroup: .chest, description: "Cable chest flyes", defaultWeight: 30),  // per side
        ExerciseTemplate(name: "Dumbbell Flyes", muscleGroup: .chest, description: "Flat dumbbell flyes", defaultWeight: 30),
        ExerciseTemplate(name: "Push-Ups", muscleGroup: .chest, description: "Bodyweight push-ups", defaultWeight: 0),
        ExerciseTemplate(name: "Chest Dips", muscleGroup: .chest, description: "Weighted or bodyweight dips", defaultWeight: 0),
        ExerciseTemplate(name: "Machine Chest Press", muscleGroup: .chest, description: "Machine press", defaultWeight: 140),
        ExerciseTemplate(name: "Pec Deck", muscleGroup: .chest, description: "Pec deck machine", defaultWeight: 120),
        
        // Back
        ExerciseTemplate(name: "Deadlift", muscleGroup: .back, description: "Conventional deadlift", isPrimary: true, defaultWeight: 185),
        ExerciseTemplate(name: "Pull-Ups", muscleGroup: .back, description: "Bodyweight or weighted pull-ups", isPrimary: true, defaultWeight: 0),
        ExerciseTemplate(name: "Barbell Row", muscleGroup: .back, description: "Bent over barbell row", defaultWeight: 135),
        ExerciseTemplate(name: "Dumbbell Row", muscleGroup: .back, description: "Single arm dumbbell row", defaultWeight: 55),
        ExerciseTemplate(name: "Lat Pulldown", muscleGroup: .back, description: "Cable lat pulldown", defaultWeight: 120),
        ExerciseTemplate(name: "Seated Cable Row", muscleGroup: .back, description: "Seated row machine", defaultWeight: 120),
        ExerciseTemplate(name: "T-Bar Row", muscleGroup: .back, description: "T-bar row", defaultWeight: 90),
        ExerciseTemplate(name: "Face Pulls", muscleGroup: .back, description: "Cable face pulls", defaultWeight: 50),
        ExerciseTemplate(name: "Chin-Ups", muscleGroup: .back, description: "Underhand grip pull-ups", defaultWeight: 0),
        ExerciseTemplate(name: "Romanian Deadlift", muscleGroup: .back, description: "RDL for hamstrings and lower back", defaultWeight: 135),
        
        // Shoulders
        ExerciseTemplate(name: "Overhead Press", muscleGroup: .shoulders, description: "Standing barbell press", isPrimary: true, defaultWeight: 95),
        ExerciseTemplate(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, description: "Seated dumbbell press", defaultWeight: 40),
        ExerciseTemplate(name: "Lateral Raises", muscleGroup: .shoulders, description: "Dumbbell side raises", defaultWeight: 20),
        ExerciseTemplate(name: "Front Raises", muscleGroup: .shoulders, description: "Dumbbell front raises", defaultWeight: 20),
        ExerciseTemplate(name: "Rear Delt Flyes", muscleGroup: .shoulders, description: "Bent over rear delt flyes", defaultWeight: 15),
        ExerciseTemplate(name: "Arnold Press", muscleGroup: .shoulders, description: "Rotating dumbbell press", defaultWeight: 35),
        ExerciseTemplate(name: "Upright Row", muscleGroup: .shoulders, description: "Barbell or dumbbell upright row", defaultWeight: 65),
        ExerciseTemplate(name: "Shrugs", muscleGroup: .shoulders, description: "Barbell or dumbbell shrugs", defaultWeight: 60),  // dumbbells
        ExerciseTemplate(name: "Machine Shoulder Press", muscleGroup: .shoulders, description: "Seated machine press", defaultWeight: 100),
        
        // Biceps
        ExerciseTemplate(name: "Barbell Curl", muscleGroup: .biceps, description: "Standing barbell curl", isPrimary: true, defaultWeight: 65),
        ExerciseTemplate(name: "Dumbbell Curl", muscleGroup: .biceps, description: "Standing or seated dumbbell curls", defaultWeight: 30),
        ExerciseTemplate(name: "Hammer Curl", muscleGroup: .biceps, description: "Neutral grip dumbbell curls", defaultWeight: 30),
        ExerciseTemplate(name: "Preacher Curl", muscleGroup: .biceps, description: "EZ bar or dumbbell preacher curls", defaultWeight: 50),
        ExerciseTemplate(name: "Incline Dumbbell Curl", muscleGroup: .biceps, description: "Incline bench curls", defaultWeight: 25),
        ExerciseTemplate(name: "Cable Curl", muscleGroup: .biceps, description: "Standing cable curls", defaultWeight: 50),
        ExerciseTemplate(name: "Concentration Curl", muscleGroup: .biceps, description: "Seated single arm curls", defaultWeight: 25),
        ExerciseTemplate(name: "EZ Bar Curl", muscleGroup: .biceps, description: "EZ bar curls", defaultWeight: 60),
        
        // Triceps
        ExerciseTemplate(name: "Tricep Pushdown", muscleGroup: .triceps, description: "Cable pushdowns", isPrimary: true, defaultWeight: 60),
        ExerciseTemplate(name: "Skull Crushers", muscleGroup: .triceps, description: "Lying tricep extension", defaultWeight: 55),
        ExerciseTemplate(name: "Close Grip Bench Press", muscleGroup: .triceps, description: "Narrow grip bench press", defaultWeight: 115),
        ExerciseTemplate(name: "Overhead Tricep Extension", muscleGroup: .triceps, description: "Cable or dumbbell overhead extension", defaultWeight: 45),
        ExerciseTemplate(name: "Tricep Dips", muscleGroup: .triceps, description: "Bench or parallel bar dips", defaultWeight: 0),
        ExerciseTemplate(name: "Diamond Push-Ups", muscleGroup: .triceps, description: "Close hand push-ups", defaultWeight: 0),
        ExerciseTemplate(name: "Rope Pushdown", muscleGroup: .triceps, description: "Rope cable pushdowns", defaultWeight: 50),
        ExerciseTemplate(name: "Kickbacks", muscleGroup: .triceps, description: "Dumbbell tricep kickbacks", defaultWeight: 20),
        
        // Legs
        ExerciseTemplate(name: "Squat", muscleGroup: .legs, description: "Barbell back squat", isPrimary: true, defaultWeight: 155),
        ExerciseTemplate(name: "Leg Press", muscleGroup: .legs, description: "Machine leg press", isPrimary: true, defaultWeight: 270),
        ExerciseTemplate(name: "Lunges", muscleGroup: .legs, description: "Walking or stationary lunges", defaultWeight: 40),  // dumbbells
        ExerciseTemplate(name: "Leg Extension", muscleGroup: .legs, description: "Machine leg extension", defaultWeight: 100),
        ExerciseTemplate(name: "Leg Curl", muscleGroup: .legs, description: "Lying or seated leg curl", defaultWeight: 80),
        ExerciseTemplate(name: "Calf Raises", muscleGroup: .legs, description: "Standing or seated calf raises", defaultWeight: 150),
        ExerciseTemplate(name: "Bulgarian Split Squat", muscleGroup: .legs, description: "Rear foot elevated split squat", defaultWeight: 35),
        ExerciseTemplate(name: "Hack Squat", muscleGroup: .legs, description: "Machine hack squat", defaultWeight: 180),
        ExerciseTemplate(name: "Front Squat", muscleGroup: .legs, description: "Barbell front squat", defaultWeight: 115),
        ExerciseTemplate(name: "Hip Thrust", muscleGroup: .legs, description: "Barbell hip thrust", defaultWeight: 135),
        ExerciseTemplate(name: "Goblet Squat", muscleGroup: .legs, description: "Dumbbell or kettlebell squat", defaultWeight: 50),
        
        // Core - most are bodyweight
        ExerciseTemplate(name: "Plank", muscleGroup: .core, description: "Front plank hold", isPrimary: true, defaultWeight: 0),
        ExerciseTemplate(name: "Crunches", muscleGroup: .core, description: "Bodyweight crunches", defaultWeight: 0),
        ExerciseTemplate(name: "Hanging Leg Raise", muscleGroup: .core, description: "Hanging from bar", defaultWeight: 0),
        ExerciseTemplate(name: "Cable Crunch", muscleGroup: .core, description: "Kneeling cable crunch", defaultWeight: 80),
        ExerciseTemplate(name: "Russian Twist", muscleGroup: .core, description: "Weighted or bodyweight twists", defaultWeight: 25),
        ExerciseTemplate(name: "Ab Wheel Rollout", muscleGroup: .core, description: "Ab wheel exercise", defaultWeight: 0),
        ExerciseTemplate(name: "Mountain Climbers", muscleGroup: .core, description: "Dynamic plank exercise", defaultWeight: 0),
        ExerciseTemplate(name: "Dead Bug", muscleGroup: .core, description: "Core stability exercise", defaultWeight: 0),
        ExerciseTemplate(name: "Side Plank", muscleGroup: .core, description: "Lateral core hold", defaultWeight: 0),
        
        // Cardio - no weights
        ExerciseTemplate(name: "Treadmill", muscleGroup: .cardio, description: "Running or walking", defaultWeight: 0),
        ExerciseTemplate(name: "Stationary Bike", muscleGroup: .cardio, description: "Cycling", defaultWeight: 0),
        ExerciseTemplate(name: "Rowing Machine", muscleGroup: .cardio, description: "Rowing ergometer", defaultWeight: 0),
        ExerciseTemplate(name: "Elliptical", muscleGroup: .cardio, description: "Elliptical machine", defaultWeight: 0),
        ExerciseTemplate(name: "Stair Climber", muscleGroup: .cardio, description: "Stair stepper", defaultWeight: 0),
        ExerciseTemplate(name: "Jump Rope", muscleGroup: .cardio, description: "Skipping rope", defaultWeight: 0),
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

