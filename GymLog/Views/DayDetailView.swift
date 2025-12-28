import SwiftUI
import SwiftData

// MARK: - Day Detail View
struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    @Bindable var workout: Workout
    
    @State private var todaysWorkoutToOpen: Workout?
    
    // Get today's workout if it exists
    private var todaysWorkout: Workout? {
        allWorkouts.first { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Header
                        headerCard
                        
                        // Add to Today Button (only for past days)
                        if !Calendar.current.isDateInToday(workout.date) {
                            addToTodayButton
                        }
                        
                        // Stats
                        statsRow
                        
                        // Exercises
                        exercisesSection
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, GymTheme.Spacing.xxl)
                }
            }
            .navigationTitle(workout.date.formatted(date: .long, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gymPrimary)
                }
            }
            .sheet(item: $todaysWorkoutToOpen) { todayWorkout in
                WorkoutView(workout: todayWorkout)
            }
        }
    }
    
    private var headerCard: some View {
        HStack {
            // Active Work Time
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundColor(.gymPrimary)
                    Text("Active Work Time")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
                
                Text(formatWorkTime(workout.savedWorkTime))
                    .font(GymTheme.Typography.statValue)
                    .foregroundColor(.gymPrimary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            if workout.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gymSuccess)
            }
        }
        .padding(GymTheme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [Color(hex: "1F1F32"), Color(hex: "2D2D44")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
    
    private func formatWorkTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var addToTodayButton: some View {
        Button {
            addExercisesToToday()
        } label: {
            HStack(spacing: GymTheme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add to Today")
                        .font(GymTheme.Typography.headline)
                    Text("Copy these exercises to today's log")
                        .font(GymTheme.Typography.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(GymTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "FF8C5A")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            StatBox(value: "\(workout.exercises.count)", label: "Exercises", color: .gymPrimary)
            StatBox(value: "\(workout.totalSets)", label: "Sets", color: .gymSecondary)
            StatBox(value: "\(workout.totalReps)", label: "Reps", color: .gymAccent)
        }
    }
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            Text("Exercises")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                ExerciseDetailCard(exercise: exercise)
            }
        }
    }
    
    private func addExercisesToToday() {
        // Get or create today's workout
        let targetWorkout: Workout
        
        if let existing = todaysWorkout {
            targetWorkout = existing
        } else {
            // Create today's workout
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMM d"
            let dayName = dateFormatter.string(from: Date())
            
            targetWorkout = Workout(name: dayName)
            modelContext.insert(targetWorkout)
        }
        
        // Get the current max order in today's workout
        let maxOrder = targetWorkout.exercises.map { $0.order }.max() ?? -1
        
        // Add exercises from this day to today
        for (index, originalExercise) in workout.exercises.sorted(by: { $0.order < $1.order }).enumerated() {
            let newExercise = Exercise(
                name: originalExercise.name,
                muscleGroup: originalExercise.muscleGroup,
                order: maxOrder + 1 + index
            )
            
            for originalSet in originalExercise.sortedSets {
                let newSet = ExerciseSet(
                    reps: originalSet.reps,
                    weight: originalSet.weight,
                    order: originalSet.order,
                    isCompleted: false,
                    previousWeight: originalSet.weight,
                    previousReps: originalSet.reps
                )
                newExercise.sets.append(newSet)
                newSet.exercise = newExercise
            }
            
            targetWorkout.exercises.append(newExercise)
            newExercise.workout = targetWorkout
        }
        
        // Open today's workout
        todaysWorkoutToOpen = targetWorkout
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.0fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(GymTheme.Typography.title2)
                .foregroundColor(color)
            Text(label)
                .font(GymTheme.Typography.caption)
                .foregroundColor(.gymTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

// MARK: - Day Activity Card
struct DayActivityCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    private var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInYesterday(workout.date) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: workout.date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayLabel)
                            .font(GymTheme.Typography.cardTitle)
                            .foregroundColor(.gymText)
                        
                        Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    }
                    
                    Spacer()
                    
                    if workout.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gymSuccess)
                            .font(.system(size: 20))
                    }
                }
                
                Divider()
                    .background(Color.gymTextSecondary.opacity(0.3))
                
                // Exercise summary
                HStack(spacing: GymTheme.Spacing.lg) {
                    Label("\(workout.exercises.count)", systemImage: "dumbbell.fill")
                        .font(GymTheme.Typography.footnote)
                        .foregroundColor(.gymTextSecondary)
                    
                    Label("\(workout.totalSets)", systemImage: "square.stack.fill")
                        .font(GymTheme.Typography.footnote)
                        .foregroundColor(.gymTextSecondary)
                    
                    if workout.totalVolume > 0 {
                        Label(formatVolume(workout.totalVolume), systemImage: "scalemass.fill")
                            .font(GymTheme.Typography.footnote)
                            .foregroundColor(.gymTextSecondary)
                    }
                }
                
                // Exercise names
                if !workout.exercises.isEmpty {
                    Text(workout.exercises.sorted { $0.order < $1.order }.map { $0.name }.joined(separator: " • "))
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
        .buttonStyle(.plain)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.0fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

