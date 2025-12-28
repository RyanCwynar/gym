import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var showingExercisePicker = false
    
    // Get or create today's workout
    private var todaysWorkout: Workout? {
        let calendar = Calendar.current
        return workouts.first { calendar.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Today's Work Time Summary (if any activity)
                        if let today = todaysWorkout, !today.exercises.isEmpty {
                            workTimeSummary(today)
                        }
                        
                        // Add Exercise Button
                        addExerciseButton
                        
                        // Today's Exercises (shown directly with sets)
                        if let today = todaysWorkout, !today.exercises.isEmpty {
                            todaysExercisesSection(today)
                        }
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet { exerciseName, muscleGroup in
                    addExerciseToToday(name: exerciseName, muscleGroup: muscleGroup)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                
                Text(greeting)
                    .font(GymTheme.Typography.largeTitle)
                    .foregroundColor(.gymText)
            }
            
            Spacer()
        }
        .padding(.top, GymTheme.Spacing.lg)
    }
    
    // MARK: - Work Time Summary
    private func workTimeSummary(_ workout: Workout) -> some View {
        TimelineView(.animation(minimumInterval: 1.0, paused: !hasRunningTimer(workout))) { timeline in
            let totalTime = calculateTotalWorkTime(workout, at: timeline.date)
            
            HStack(spacing: GymTheme.Spacing.lg) {
                // Work time
                HStack(spacing: GymTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(hasRunningTimer(workout) ? Color.gymPrimary : Color.gymSuccess.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(hasRunningTimer(workout) ? .white : .gymSuccess)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Work Time")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                        
                        Text(formatTotalTime(totalTime))
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(hasRunningTimer(workout) ? .gymPrimary : .gymText)
                    }
                }
                
                Spacer()
                
                // Sets completed
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Completed")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                    
                    Text("\(completedSets(workout))/\(workout.totalSets)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gymSuccess)
                }
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
    }
    
    private func hasRunningTimer(_ workout: Workout) -> Bool {
        for exercise in workout.exercises {
            for set in exercise.sets {
                if set.workStartTime != nil {
                    return true
                }
            }
        }
        return false
    }
    
    private func calculateTotalWorkTime(_ workout: Workout, at date: Date) -> TimeInterval {
        var total: TimeInterval = 0
        for exercise in workout.exercises {
            // Add cardio exercise duration
            if exercise.muscleGroup == "Cardio" {
                total += exercise.duration
            }
            // Add set work times
            for set in exercise.sets {
                total += set.workTime
                if let startTime = set.workStartTime {
                    total += date.timeIntervalSince(startTime)
                }
            }
        }
        return total
    }
    
    private func completedSets(_ workout: Workout) -> Int {
        var count = 0
        for exercise in workout.exercises {
            for set in exercise.sets {
                if set.isCompleted {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func completedReps(_ workout: Workout) -> Int {
        var count = 0
        for exercise in workout.exercises {
            for set in exercise.sets {
                if set.isCompleted {
                    count += set.reps
                }
            }
        }
        return count
    }
    
    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Add Exercise Button
    private var addExerciseButton: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                
                Text("Add Exercise")
                    .font(GymTheme.Typography.headline)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(GymTheme.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "FF8C5A")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Today's Exercises Section
    private func todaysExercisesSection(_ workout: Workout) -> some View {
        let completedSetCount = completedSets(workout)
        let completedRepCount = completedReps(workout)
        
        return VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            // Summary stats
            HStack(spacing: GymTheme.Spacing.lg) {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gymSecondary)
                    Text("\(workout.exercises.count)")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymText)
                }
                .fixedSize()
                
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gymAccent)
                    Text("\(completedSetCount)/\(workout.totalSets)")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymText)
                }
                .fixedSize()
                
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.system(size: 12))
                        .foregroundColor(.gymSuccess)
                    Text("\(completedRepCount)/\(workout.totalReps)")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymText)
                }
                .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            
            // Exercise cards with inline sets
            ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                InlineExerciseCard(exercise: exercise, onDelete: {
                    deleteExercise(exercise, from: workout)
                })
            }
        }
    }
    
    private func deleteExercise(_ exercise: Exercise, from workout: Workout) {
        workout.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
    
    // MARK: - Add Exercise to Today
    private func addExerciseToToday(name: String, muscleGroup: String) {
        let workout: Workout
        
        if let existing = todaysWorkout {
            workout = existing
        } else {
            // Create today's workout
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMM d"
            let dayName = dateFormatter.string(from: Date())
            
            workout = Workout(name: dayName)
            modelContext.insert(workout)
        }
        
        // Add the exercise
        let exercise = Exercise(
            name: name,
            muscleGroup: muscleGroup,
            order: workout.exercises.count
        )
        
        // Only add a default set for non-cardio exercises
        if muscleGroup != "Cardio" {
            let set = ExerciseSet(reps: 8, weight: 0, order: 0)
            exercise.sets.append(set)
            set.exercise = exercise
        }
        
        workout.exercises.append(exercise)
        exercise.workout = workout
        
        // No modal - exercise appears inline on dashboard
    }
    
    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Late night gains"
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
