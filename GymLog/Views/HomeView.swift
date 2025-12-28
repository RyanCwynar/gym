import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var showingExercisePicker = false
    @State private var activeWorkout: Workout?
    
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
                        
                        // Add Exercise Button
                        addExerciseButton
                        
                        // Today's Exercises (shown directly)
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
            .sheet(item: $activeWorkout) { workout in
                WorkoutView(workout: workout)
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
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            // Summary stats
            HStack(spacing: GymTheme.Spacing.lg) {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gymSecondary)
                    Text("\(workout.exercises.count) exercises")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymText)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gymAccent)
                    Text("\(workout.totalSets) sets")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymText)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "repeat")
                        .font(.system(size: 14))
                        .foregroundColor(.gymSuccess)
                    Text("\(workout.totalReps) reps")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymText)
                }
                
                Spacer()
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            
            // Exercise cards
            ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                TodayExerciseCard(exercise: exercise) {
                    activeWorkout = workout
                }
            }
        }
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
        
        // Add a default set
        let set = ExerciseSet(reps: 8, weight: 0, order: 0)
        exercise.sets.append(set)
        set.exercise = exercise
        
        workout.exercises.append(exercise)
        exercise.workout = workout
        
        // Open the workout to edit the exercise
        activeWorkout = workout
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

// MARK: - Today Exercise Card
struct TodayExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GymTheme.Spacing.md) {
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(muscleGroupColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: muscleGroupIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(muscleGroupColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                    
                    HStack(spacing: GymTheme.Spacing.md) {
                        if exercise.sets.count > 0 {
                            Text("\(exercise.sets.count) sets")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymTextSecondary)
                        }
                        
                        if let bestSet = exercise.sets.max(by: { $0.weight < $1.weight }), bestSet.weight > 0 {
                            Text("\(Int(bestSet.weight)) lbs × \(bestSet.reps)")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymPrimary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gymTextSecondary.opacity(0.5))
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        }
        .buttonStyle(.plain)
    }
    
    private var muscleGroupColor: Color {
        guard let group = MuscleGroup(rawValue: exercise.muscleGroup) else {
            return .gymPrimary
        }
        switch group {
        case .chest: return Color(hex: "FF6B6B")
        case .back: return Color(hex: "4ECDC4")
        case .shoulders: return Color(hex: "FFE66D")
        case .arms: return Color(hex: "FF8C5A")
        case .legs: return Color(hex: "A8E6CF")
        case .core: return Color(hex: "95E1D3")
        case .fullBody: return Color(hex: "DDA0DD")
        case .cardio: return Color(hex: "F38181")
        }
    }
    
    private var muscleGroupIcon: String {
        guard let group = MuscleGroup(rawValue: exercise.muscleGroup) else {
            return "dumbbell.fill"
        }
        return group.icon
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

// MARK: - Exercise Picker Sheet
struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String, String) -> Void
    
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                if selectedMuscleGroup == nil {
                    muscleGroupGrid
                } else {
                    exerciseList
                }
            }
            .navigationTitle(selectedMuscleGroup?.rawValue ?? "Select Muscle Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedMuscleGroup != nil {
                        Button {
                            selectedMuscleGroup = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.gymPrimary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gymTextSecondary)
                }
            }
        }
    }
    
    private var muscleGroupGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: GymTheme.Spacing.md) {
                ForEach(MuscleGroup.allCases.filter { $0 != .fullBody }, id: \.self) { group in
                    Button {
                        selectedMuscleGroup = group
                    } label: {
                        VStack(spacing: GymTheme.Spacing.sm) {
                            Image(systemName: group.icon)
                                .font(.system(size: 32))
                                .foregroundColor(muscleGroupColor(group))
                            
                            Text(group.rawValue)
                                .font(GymTheme.Typography.headline)
                                .foregroundColor(.gymText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, GymTheme.Spacing.xl)
                        .background(Color.gymSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
                    }
                }
            }
            .padding(GymTheme.Spacing.md)
        }
    }
    
    private var exerciseList: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gymTextSecondary)
                
                TextField("Search exercises", text: $searchText)
                    .foregroundColor(.gymText)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gymTextSecondary)
                    }
                }
            }
            .padding(GymTheme.Spacing.sm)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            .padding(.horizontal, GymTheme.Spacing.md)
            .padding(.top, GymTheme.Spacing.md)
            
            ScrollView {
                LazyVStack(spacing: GymTheme.Spacing.xs) {
                    // Custom exercise option
                    if !searchText.isEmpty {
                        Button {
                            onSelect(searchText.trimmingCharacters(in: .whitespacesAndNewlines), selectedMuscleGroup?.rawValue ?? "Other")
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gymSuccess)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add \"\(searchText)\"")
                                        .font(GymTheme.Typography.headline)
                                        .foregroundColor(.gymText)
                                    
                                    Text("Create custom exercise")
                                        .font(GymTheme.Typography.caption)
                                        .foregroundColor(.gymTextSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(GymTheme.Spacing.md)
                            .background(Color.gymSuccess.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                        }
                    }
                    
                    // Existing exercises
                    ForEach(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise.name, exercise.muscleGroup.rawValue)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(GymTheme.Typography.headline)
                                        .foregroundColor(.gymText)
                                    
                                    if !exercise.description.isEmpty {
                                        Text(exercise.description)
                                            .font(GymTheme.Typography.caption)
                                            .foregroundColor(.gymTextSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gymPrimary)
                            }
                            .padding(GymTheme.Spacing.md)
                            .background(Color.gymSurfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                        }
                    }
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.top, GymTheme.Spacing.md)
                .padding(.bottom, GymTheme.Spacing.xl)
            }
        }
    }
    
    private var filteredExercises: [ExerciseTemplate] {
        guard let group = selectedMuscleGroup else { return [] }
        var exercises = ExerciseLibrary.exercises(for: group)
        
        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return exercises
    }
    
    private func muscleGroupColor(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: return Color(hex: "FF6B6B")
        case .back: return Color(hex: "4ECDC4")
        case .shoulders: return Color(hex: "45B7D1")
        case .biceps: return Color(hex: "96CEB4")
        case .triceps: return Color(hex: "FFEAA7")
        case .legs: return Color(hex: "DDA0DD")
        case .core: return Color(hex: "98D8C8")
        case .cardio: return Color(hex: "F7DC6F")
        case .fullBody: return Color.gymPrimary
        }
    }
}

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

#Preview {
    HomeView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
