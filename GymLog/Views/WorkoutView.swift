import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: Workout
    var originalWorkout: Workout?  // For repeated workouts - used for comparison
    
    // Query completed workouts to find previous exercise weights
    @Query(filter: #Predicate<Workout> { $0.isCompleted }, sort: \Workout.date, order: .reverse)
    private var completedWorkouts: [Workout]
    
    @State private var showingExercisePicker = false
    @State private var showingFinishAlert = false
    @State private var showingDiscardAlert = false
    @State private var showingComparison = false
    @State private var repeatedWorkout: Workout?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Timer Card
                        timerCard
                        
                        // Exercises
                        exercisesSection
                        
                        // Add Exercise Button
                        addExerciseButton
                        
                        // Notes Section
                        notesSection
                        
                        // Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, GymTheme.Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(workout.isCompleted ? "Done" : "Cancel") {
                        // Just dismiss - workout data auto-saves via SwiftData
                            dismiss()
                        }
                    .foregroundColor(workout.isCompleted ? .gymPrimary : .gymTextSecondary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(workout.date.formatted(date: .long, time: .omitted))
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                MuscleGroupPickerView { exerciseName, muscleGroup in
                    addExercise(name: exerciseName, muscleGroup: muscleGroup)
                }
            }
            .fullScreenCover(isPresented: $showingComparison) {
                if let original = originalWorkout {
                    WorkoutComparisonView(
                        newWorkout: workout,
                        originalWorkout: original,
                        onDismiss: { dismiss() }
                    )
                }
            }
            .fullScreenCover(item: $repeatedWorkout) { newWorkout in
                WorkoutView(workout: newWorkout, originalWorkout: workout)
            }
            .alert("Finish Workout?", isPresented: $showingFinishAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Finish") {
                    finishWorkout()
                }
            } message: {
                Text("Mark this workout as complete?")
            }
            .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    modelContext.delete(workout)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to discard this workout? All progress will be lost.")
            }
        }
    }
    
    // MARK: - Stats Card
    private var timerCard: some View {
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
                
                Text(formatDuration(workout.totalWorkTime))
                    .font(GymTheme.Typography.statValue)
                    .foregroundColor(.gymPrimary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: GymTheme.Spacing.md) {
                VStack(alignment: .center) {
                    Text("\(workout.exercises.count)")
                        .font(GymTheme.Typography.title2)
                        .foregroundColor(.gymSecondary)
                    Text("exercises")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
                
                VStack(alignment: .center) {
                    Text("\(workout.totalSets)")
                        .font(GymTheme.Typography.title2)
                        .foregroundColor(.gymAccent)
                    Text("sets")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
                
                VStack(alignment: .center) {
                    Text("\(workout.totalReps)")
                        .font(GymTheme.Typography.title2)
                        .foregroundColor(.gymSuccess)
                    Text("reps")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
            }
        }
        .padding(GymTheme.Spacing.lg)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                if exercise.isCardio {
                    CardioExerciseCard(exercise: exercise, onDelete: {
                        deleteExercise(exercise)
                    })
                } else {
                ExerciseCard(exercise: exercise, onDelete: {
                    deleteExercise(exercise)
                })
                }
            }
        }
    }
    
    // MARK: - Add Exercise Button
    private var addExerciseButton: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Exercise")
                    .font(GymTheme.Typography.headline)
            }
            .foregroundColor(.gymPrimary)
            .frame(maxWidth: .infinity)
            .padding(GymTheme.Spacing.md)
            .background(Color.gymPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: GymTheme.Radius.medium)
                    .stroke(Color.gymPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
            Text("Notes")
                .font(GymTheme.Typography.headline)
                .foregroundColor(.gymText)
            
            TextField("Add workout notes...", text: $workout.notes, axis: .vertical)
                .font(GymTheme.Typography.body)
                .foregroundColor(.gymText)
                .lineLimit(3...6)
                .padding(GymTheme.Spacing.md)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        }
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if workout.isCompleted {
            // For completed workouts, show Done and Repeat buttons
            VStack(spacing: GymTheme.Spacing.md) {
                // Repeat Workout Button
                Button {
                    repeatWorkout()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Repeat Workout")
                    }
                    .font(GymTheme.Typography.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GymTheme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "FF8C5A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                }
                
                // Done Editing Button
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done")
                    }
                    .font(GymTheme.Typography.buttonText)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GymTheme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "4CAF50"), Color(hex: "66BB6A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                }
            }
            .padding(.top, GymTheme.Spacing.lg)
        } else {
            // For in-progress workouts, show Finish and Discard buttons
            VStack(spacing: GymTheme.Spacing.md) {
            Button {
                showingFinishAlert = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Finish Workout")
                }
                .font(GymTheme.Typography.buttonText)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GymTheme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "4CAF50"), Color(hex: "66BB6A")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            }
                
                Button {
                    showingDiscardAlert = true
                } label: {
                    Text("Discard Workout")
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymError)
                }
                .padding(.top, GymTheme.Spacing.sm)
            }
            .padding(.top, GymTheme.Spacing.lg)
        }
    }
    
    // MARK: - Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func addExercise(name: String, muscleGroup: String) {
        let exercise = Exercise(
            name: name,
            muscleGroup: muscleGroup,
            order: workout.exercises.count
        )
        
        // Find last weight and reps used for this exercise
        let (lastWeight, lastReps) = findLastWeightAndReps(for: name)
        
        // Get default weight from template if no history
        let defaultWeight = getDefaultWeight(for: name)
        let weightToUse = lastWeight ?? defaultWeight
        
        // Add first set with last used weight/reps (or defaults)
        let set = ExerciseSet(
            reps: lastReps ?? 8,
            weight: weightToUse,
            order: 0,
            previousWeight: lastWeight,  // Only show previous if we actually have history
            previousReps: lastReps
        )
        exercise.sets.append(set)
        set.exercise = exercise
        
        workout.exercises.append(exercise)
        exercise.workout = workout
    }
    
    /// Find the last weight and reps used for an exercise from workout history
    private func findLastWeightAndReps(for exerciseName: String) -> (Double?, Int?) {
        // Search through completed workouts (already sorted by date, newest first)
        for completedWorkout in completedWorkouts {
            // Skip the current workout if it's somehow in the list
            if completedWorkout.id == workout.id { continue }
            
            // Find the exercise by name
            if let exercise = completedWorkout.exercises.first(where: { $0.name == exerciseName }) {
                // Get the last set from that exercise
                if let lastSet = exercise.sortedSets.last {
                    return (lastSet.weight, lastSet.reps)
                }
            }
        }
        return (nil, nil)
    }
    
    /// Get default weight for an exercise from the template library
    private func getDefaultWeight(for exerciseName: String) -> Double {
        if let template = ExerciseLibrary.exercises.first(where: { $0.name == exerciseName }) {
            return template.defaultWeight
        }
        return 0  // Custom exercises default to 0
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        workout.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
    
    private func finishWorkout() {
        // Stop any running set timers
        for exercise in workout.exercises {
            for set in exercise.sets {
                if let startTime = set.workStartTime {
                    set.workTime += Date().timeIntervalSince(startTime)
                    set.workStartTime = nil
                }
            }
        }
        
        workout.isCompleted = true
        workout.savedWorkTime = workout.totalWorkTime     // Time actually spent doing sets
        
        // Show comparison if this is a repeated workout
        if originalWorkout != nil {
            showingComparison = true
        } else {
            dismiss()
        }
    }
    
    private func repeatWorkout() {
        // Create a new workout based on this completed one
        let newWorkout = Workout(
            name: workout.name,
            repeatedFromWorkoutId: workout.id
        )
        
        // Copy all exercises
        for originalExercise in workout.exercises.sorted(by: { $0.order < $1.order }) {
            let newExercise = Exercise(
                name: originalExercise.name,
                muscleGroup: originalExercise.muscleGroup,
                order: originalExercise.order,
                targetSets: originalExercise.targetSets,
                targetReps: originalExercise.targetReps
            )
            
            // Copy all sets with same weight/reps but reset completion and work time
            for originalSet in originalExercise.sortedSets {
                let newSet = ExerciseSet(
                    reps: originalSet.reps,
                    weight: originalSet.weight,
                    order: originalSet.order,
                    isCompleted: false,
                    previousWeight: originalSet.weight,
                    previousReps: originalSet.reps,
                    workTime: 0,
                    workStartTime: nil
                )
                newExercise.sets.append(newSet)
                newSet.exercise = newExercise
            }
            
            newWorkout.exercises.append(newExercise)
            newExercise.workout = newWorkout
        }
        
        // Insert into model context and present
        modelContext.insert(newWorkout)
        repeatedWorkout = newWorkout
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: Exercise
    let onDelete: () -> Void
    
    @State private var newlyAddedSetId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                    
                    Text(exercise.muscleGroup)
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gymTextSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            
            // Sets
            VStack(spacing: GymTheme.Spacing.sm) {
                ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                    SetRow(
                        set: set,
                        setNumber: index + 1,
                        previousWeight: index > 0 ? exercise.sortedSets[index - 1].weight : nil,
                        isNewlyAdded: set.id == newlyAddedSetId,
                        onDelete: { deleteSet(set) },
                        onEditingChanged: { isEditing in
                            if !isEditing && set.id == newlyAddedSetId {
                                newlyAddedSetId = nil
                            }
                        }
                    )
                }
            }
            
            // Add Set Button
            Button {
                addSet()
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Set")
                        .font(GymTheme.Typography.subheadline)
                }
                .foregroundColor(.gymSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GymTheme.Spacing.sm)
                .background(Color.gymSecondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
    
    private func addSet() {
        // Get weight and reps from last set if exists, default reps to 8
        let lastSet = exercise.sortedSets.last
        let lastWeight = lastSet?.weight ?? 0
        let lastReps = lastSet?.reps ?? 8
        let set = ExerciseSet(reps: lastReps, weight: lastWeight, order: exercise.sets.count)
        exercise.sets.append(set)
        set.exercise = exercise
        
        // Mark this set as newly added so it starts expanded
        newlyAddedSetId = set.id
        
        // Create the set in Convex immediately
        print("🔵 addSet called for: \(exercise.name)")
        Task {
            await createSetInConvex(set: set)
        }
    }
    
    private func createSetInConvex(set: ExerciseSet) async {
        print("🔵 createSetInConvex called")
        print("🔵 API Key ID: \(ConvexAPI.shared.apiKeyId ?? "nil")")
        print("🔵 isAuthenticated: \(ConvexAPI.shared.isAuthenticated)")
        
        guard ConvexAPI.shared.isAuthenticated else {
            print("❌ Not authenticated - skipping Convex save")
            return
        }
        
        let workoutId = exercise.workout?.id.uuidString
        
        do {
            print("🔵 Calling createSet mutation...")
            let result = try await ConvexAPI.shared.createSet(
                exerciseName: exercise.name,
                exerciseType: ConvexAPI.exerciseType(for: exercise.muscleGroup),
                weight: set.weight > 0 ? set.weight : nil,
                reps: set.reps > 0 ? set.reps : nil,
                workoutId: workoutId,
                setOrder: set.order
            )
            print("✅ Set saved to Convex: \(exercise.name), ID: \(result)")
        } catch {
            print("❌ Error creating set in Convex: \(error)")
        }
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        exercise.sets.removeAll { $0.id == set.id }
    }
}

// MARK: - Cardio Exercise Card
struct CardioExerciseCard: View {
    @Bindable var exercise: Exercise
    let onDelete: () -> Void
    
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var accumulatedTime: TimeInterval = 0
    @State private var isEditingMinutes = false
    @State private var minutesText: String = ""
    
    private var currentDisplayTime: TimeInterval {
        if isTimerRunning, let startTime = timerStartTime {
            return accumulatedTime + Date().timeIntervalSince(startTime)
        }
        return accumulatedTime
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(GymTheme.Typography.headline)
                            .foregroundColor(.gymText)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gymPrimary)
                            Text("Cardio")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Remove Exercise", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gymTextSecondary)
                            .frame(width: 32, height: 32)
                    }
                }
                
                // Timer Display
                VStack(spacing: GymTheme.Spacing.md) {
                    // Large time display - uses timeline.date to trigger updates
                    let _ = timeline.date
                    Text(formatTime(currentDisplayTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(isTimerRunning ? .gymPrimary : .gymText)
                        .monospacedDigit()
                    
                    // Timer controls
                    HStack(spacing: GymTheme.Spacing.lg) {
                        // Play/Pause button
                        Button {
                            toggleTimer()
                        } label: {
                            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(
                                    Circle()
                                        .fill(isTimerRunning ? Color.gymWarning : Color.gymSuccess)
                                )
                        }
                        
                        // Reset button
                        Button {
                            resetTimer()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gymTextSecondary)
                                .frame(width: 48, height: 48)
                                .background(Color.gymSurface)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Manual entry option
                    if isEditingMinutes {
                        HStack(spacing: GymTheme.Spacing.sm) {
                            TextField("0", text: $minutesText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.gymText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(.vertical, GymTheme.Spacing.sm)
                                .background(Color.gymSurface)
                                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
                            
                            Text("minutes")
                                .font(GymTheme.Typography.body)
                                .foregroundColor(.gymTextSecondary)
                            
                            Button {
                                if let mins = Double(minutesText) {
                                    let seconds = mins * 60
                                    accumulatedTime = seconds
                                    exercise.duration = seconds
                                }
                                isEditingMinutes = false
                            } label: {
                                Text("Set")
                                    .font(GymTheme.Typography.buttonText)
                                    .foregroundColor(.gymSuccess)
                                    .padding(.horizontal, GymTheme.Spacing.md)
                                    .padding(.vertical, GymTheme.Spacing.sm)
                                    .background(Color.gymSuccess.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    } else {
                        Button {
                            minutesText = String(Int(currentDisplayTime / 60))
                            isEditingMinutes = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                Text("Enter minutes manually")
                                    .font(GymTheme.Typography.caption)
                            }
                            .foregroundColor(.gymSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, GymTheme.Spacing.md)
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
        .onAppear {
            // Load saved duration
            accumulatedTime = exercise.duration
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            // Pause - save accumulated time
            if let startTime = timerStartTime {
                accumulatedTime += Date().timeIntervalSince(startTime)
            }
            timerStartTime = nil
            isTimerRunning = false
            
            // Save duration
            exercise.duration = accumulatedTime
            
            // Save to Convex when cardio duration is logged
            Task {
                await saveCardioToConvex()
            }
        } else {
            // Play - start timer
            timerStartTime = Date()
            isTimerRunning = true
        }
    }
    
    private func saveCardioToConvex() async {
        let workoutId = exercise.workout?.id.uuidString
        let durationSeconds = Int(exercise.duration) // Convert TimeInterval to Int
        
        do {
            _ = try await ConvexAPI.shared.createSet(
                exerciseName: exercise.name,
                exerciseType: .cardio,
                duration: durationSeconds > 0 ? durationSeconds : nil,
                workoutId: workoutId
            )
            print("✅ Cardio saved to Convex: \(exercise.name)")
        } catch {
            print("❌ Error saving cardio to Convex: \(error)")
        }
    }
    
    private func resetTimer() {
        isTimerRunning = false
        timerStartTime = nil
        accumulatedTime = 0
        exercise.duration = 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Set Row with Collapsed/Expanded States
struct SetRow: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    let previousWeight: Double?
    var isNewlyAdded: Bool = false
    let onDelete: () -> Void
    var onEditingChanged: ((Bool) -> Void)? = nil
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var isEditing: Bool = false
    
    // Computed property for current work time display
    private func currentWorkTime(at date: Date) -> TimeInterval {
        if let startTime = set.workStartTime {
            return set.workTime + date.timeIntervalSince(startTime)
        }
        return set.workTime
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            VStack(spacing: GymTheme.Spacing.sm) {
                if isEditing {
                    expandedView(at: timeline.date)
                } else {
                    collapsedView(at: timeline.date)
                }
            }
            .padding(GymTheme.Spacing.md)
            .background(set.isCompleted ? Color.gymSuccess.opacity(0.08) : (set.workStartTime != nil ? Color.gymPrimary.opacity(0.08) : Color.gymSurface.opacity(0.3)))
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        }
        .onAppear {
            // Auto-fill weight from previous set or use current value
            if set.weight == 0, let prevWeight = previousWeight, prevWeight > 0 {
                set.weight = prevWeight
            }
            weightText = set.weight > 0 ? String(format: "%.0f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
            
            // Start expanded if newly added
            if isNewlyAdded {
                isEditing = true
            }
        }
        .onChange(of: isEditing) { _, newValue in
            onEditingChanged?(newValue)
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
    
    // MARK: - Collapsed View (Single Row)
    private func collapsedView(at date: Date) -> some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            // Work time timer button
            Button {
                toggleWorkTimer()
            } label: {
                ZStack {
                    Circle()
                        .fill(set.workStartTime != nil ? Color.gymPrimary : Color.gymSurface)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: set.workStartTime != nil ? "stop.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(set.workStartTime != nil ? .white : .gymPrimary)
                }
            }
            .fixedSize()
            
            // Set number with completion indicator
            Button {
                set.isCompleted.toggle()
                // Save to Convex when marked as completed
                if set.isCompleted {
                    Task {
                        await saveSetToConvex()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(set.isCompleted ? Color.gymSuccess : Color.gymTextSecondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if set.isCompleted {
                        Circle()
                            .fill(Color.gymSuccess)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(setNumber)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gymTextSecondary)
                    }
                }
            }
            .fixedSize()
            
            // Tappable area to edit - weight and reps display
            Button {
                isEditing = true
            } label: {
            VStack(alignment: .leading, spacing: 2) {
                    // Show weight only if > 0 (bodyweight exercises just show reps)
                    Text(set.weight > 0 ? "\(String(format: "%.0f", set.weight)) lbs × \(set.reps) reps" : "\(set.reps) reps")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.gymText)
                        .lineLimit(1)
                    
                    // Show work time if recorded or running
                    let workTime = currentWorkTime(at: date)
                    if workTime > 0 || set.workStartTime != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(formatWorkTime(workTime))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(set.workStartTime != nil ? .gymPrimary : .gymTextSecondary)
                    }
                }
                .contentShape(Rectangle())
            }
            
            Spacer()
            
            // Edit button
            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gymSecondary)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.gymError.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.gymError.opacity(0.1))
                    .clipShape(Circle())
            }
            .fixedSize()
        }
    }
    
    // MARK: - Expanded View (Full Editing)
    private func expandedView(at date: Date) -> some View {
        VStack(spacing: GymTheme.Spacing.sm) {
            // Row 1: Set number, work timer, and done/delete buttons
            HStack {
                HStack(spacing: GymTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .stroke(set.isCompleted ? Color.gymSuccess : Color.gymTextSecondary.opacity(0.5), lineWidth: 2)
                            .frame(width: 32, height: 32)
                        
                        if set.isCompleted {
                            Circle()
                                .fill(Color.gymSuccess)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(setNumber)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gymTextSecondary)
                        }
                    }
                    
                    Text("Set \(setNumber)")
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                }
                
                Spacer()
                
                // Done button
                Button {
                    // Stop timer if running when done
                    if set.workStartTime != nil {
                        toggleWorkTimer()
                    }
                    isEditing = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.gymSuccess)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gymSuccess.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.gymError.opacity(0.7))
                        .padding(8)
                        .background(Color.gymError.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Row 2: Work Time Timer
            HStack(spacing: GymTheme.Spacing.md) {
                // Play/Stop button
                Button {
                    toggleWorkTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: set.workStartTime != nil ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text(set.workStartTime != nil ? "Stop" : "Start Set")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(set.workStartTime != nil ? Color.gymWarning : Color.gymPrimary)
                    .clipShape(Capsule())
                }
                
                // Work time display
                VStack(alignment: .leading, spacing: 2) {
                    Text("Work Time")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gymTextSecondary)
                
                    Text(formatWorkTime(currentWorkTime(at: date)))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(set.workStartTime != nil ? .gymPrimary : .gymText)
                }
                
                Spacer()
                
                // Reset button
                if set.workTime > 0 || set.workStartTime != nil {
                    Button {
                        set.workTime = 0
                        set.workStartTime = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gymTextSecondary)
                            .padding(8)
                            .background(Color.gymSurface)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.vertical, GymTheme.Spacing.xs)
            .padding(.horizontal, GymTheme.Spacing.sm)
            .background(Color.gymSurface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            
            // Row 3: Weight controls
            HStack(spacing: GymTheme.Spacing.sm) {
                Button {
                    adjustWeight(-5)
                } label: {
                    Text("-5")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .frame(width: 50, height: 48)
                        .background(Color.gymPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                HStack(spacing: 4) {
                TextField("0", text: $weightText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.gymText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    .onChange(of: weightText) { _, newValue in
                        set.weight = Double(newValue) ?? 0
            }
            
                    Text("lbs")
                        .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gymTextSecondary)
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.vertical, GymTheme.Spacing.sm)
                .background(Color.gymSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    adjustWeight(5)
                } label: {
                    Text("+5")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .frame(width: 50, height: 48)
                        .background(Color.gymPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Row 4: Reps controls
            HStack(spacing: GymTheme.Spacing.sm) {
                Button {
                    adjustReps(-1)
                } label: {
                    Text("-1")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.gymSecondary)
                        .frame(width: 50, height: 48)
                        .background(Color.gymSecondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                HStack(spacing: 4) {
                TextField("0", text: $repsText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.gymText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    .onChange(of: repsText) { _, newValue in
                        set.reps = Int(newValue) ?? 0
                    }
                    
                    Text("reps")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gymTextSecondary)
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.vertical, GymTheme.Spacing.sm)
                .background(Color.gymSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    adjustReps(1)
                } label: {
                    Text("+1")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.gymSecondary)
                        .frame(width: 50, height: 48)
                        .background(Color.gymSecondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    private func toggleWorkTimer() {
        if set.workStartTime != nil {
            // Stop timer - accumulate time
            set.workTime += Date().timeIntervalSince(set.workStartTime!)
            set.workStartTime = nil
            
            // Save to Convex when work time is logged
            Task {
                await saveSetToConvex()
            }
        } else {
            // Start timer
            set.workStartTime = Date()
        }
    }
    
    private func saveSetToConvex() async {
        guard let exercise = set.exercise else { return }
        
        // Get workout ID if available (using exercise's workout)
        let workoutId = exercise.workout?.id.uuidString
        let workTimeSeconds = Int(set.workTime) // Convert TimeInterval to Int
        
        do {
            _ = try await ConvexAPI.shared.createSet(
                exerciseName: exercise.name,
                exerciseType: ConvexAPI.exerciseType(for: exercise.muscleGroup),
                weight: set.weight > 0 ? set.weight : nil,
                reps: set.reps > 0 ? set.reps : nil,
                workTime: workTimeSeconds > 0 ? workTimeSeconds : nil,
                workoutId: workoutId,
                setOrder: set.order
            )
            print("✅ Set saved to Convex: \(exercise.name)")
        } catch {
            print("❌ Error saving set to Convex: \(error)")
        }
    }
    
    private func formatWorkTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func adjustWeight(_ delta: Double) {
        let newWeight = max(0, set.weight + delta)
        set.weight = newWeight
        weightText = String(format: "%.0f", newWeight)
    }
    
    private func adjustReps(_ delta: Int) {
        let newReps = max(0, set.reps + delta)
        set.reps = newReps
        repsText = "\(newReps)"
    }
}

// MARK: - Muscle Group Picker (Simplified Exercise Selection)
struct MuscleGroupPickerView: View {
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
                    // Muscle group grid
                    muscleGroupGrid
                } else {
                    // Exercise list for selected muscle group
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
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gymPrimary)
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
                    // Show "Add custom exercise" option when searching
                    if !searchText.isEmpty {
                        Button {
                            let customName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            onSelect(customName, selectedMuscleGroup?.rawValue ?? "Other")
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
                                    
                                    Text("Create custom exercise in \(selectedMuscleGroup?.rawValue ?? "Other")")
                                        .font(GymTheme.Typography.caption)
                                        .foregroundColor(.gymTextSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(GymTheme.Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [Color.gymSuccess.opacity(0.2), Color.gymSuccess.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: GymTheme.Radius.medium)
                                    .stroke(Color.gymSuccess.opacity(0.3), lineWidth: 1)
                            )
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
                    
                    // Show message if no exercises found
                    if filteredExercises.isEmpty && searchText.isEmpty {
                        Text("No exercises in this category")
                            .font(GymTheme.Typography.body)
                            .foregroundColor(.gymTextSecondary)
                            .padding(.top, GymTheme.Spacing.xl)
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

// MARK: - Workout Comparison View
struct WorkoutComparisonView: View {
    let newWorkout: Workout
    let originalWorkout: Workout
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Overall Stats Comparison
                        overallStatsSection
                        
                        // Exercise by Exercise Comparison
                        exerciseComparisonSection
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, GymTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Workout Complete!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymPrimary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            Image(systemName: overallImprovement >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(overallImprovement >= 0 ? .gymSuccess : .gymError)
            
            Text(overallImprovement >= 0 ? "Great Progress!" : "Keep Pushing!")
                .font(GymTheme.Typography.title1)
                .foregroundColor(.gymText)
            
            Text("Compared to \(originalWorkout.date.formatted(date: .abbreviated, time: .omitted))")
                .font(GymTheme.Typography.subheadline)
                .foregroundColor(.gymTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(GymTheme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color(hex: "1F1F32"), Color(hex: "2D2D44")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
    
    // MARK: - Overall Stats Section
    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            Text("Overall Comparison")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            VStack(spacing: GymTheme.Spacing.sm) {
                ComparisonRow(
                    label: "Total Volume",
                    oldValue: formatVolume(originalWorkout.totalVolume),
                    newValue: formatVolume(newWorkout.totalVolume),
                    change: volumeChange,
                    unit: "lbs"
                )
                
                ComparisonRow(
                    label: "Work Time",
                    oldValue: formatDuration(originalWorkout.savedWorkTime),
                    newValue: formatDuration(newWorkout.savedWorkTime),
                    change: workTimeChange,
                    unit: ""
                )
                
                ComparisonRow(
                    label: "Total Sets",
                    oldValue: "\(originalWorkout.totalSets)",
                    newValue: "\(newWorkout.totalSets)",
                    change: Double(newWorkout.totalSets - originalWorkout.totalSets),
                    unit: ""
                )
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
    }
    
    // MARK: - Exercise Comparison Section
    private var exerciseComparisonSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            Text("Exercise Breakdown")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            ForEach(newWorkout.exercises.sorted { $0.order < $1.order }) { newExercise in
                if let originalExercise = originalWorkout.exercises.first(where: { $0.name == newExercise.name }) {
                    ExerciseComparisonCard(
                        exerciseName: newExercise.name,
                        newExercise: newExercise,
                        originalExercise: originalExercise
                    )
                } else {
                    // New exercise not in original workout
                    NewExerciseCard(exercise: newExercise)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var volumeChange: Double {
        newWorkout.totalVolume - originalWorkout.totalVolume
    }
    
    private var workTimeChange: Double {
        newWorkout.savedWorkTime - originalWorkout.savedWorkTime
    }
    
    private var overallImprovement: Double {
        // Consider volume increase as positive improvement
        volumeChange
    }
    
    // MARK: - Helpers
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%d:%02d:%02d", hours, mins, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Comparison Row
struct ComparisonRow: View {
    let label: String
    let oldValue: String
    let newValue: String
    let change: Double
    let unit: String
    var lowerIsBetter: Bool = false
    
    private var isImproved: Bool {
        lowerIsBetter ? change < 0 : change > 0
    }
    
    private var changeColor: Color {
        if change == 0 { return .gymTextSecondary }
        return isImproved ? .gymSuccess : .gymError
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(GymTheme.Typography.subheadline)
                .foregroundColor(.gymTextSecondary)
            
            Spacer()
            
            HStack(spacing: GymTheme.Spacing.md) {
                // Old value
                Text(oldValue)
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gymTextSecondary)
                
                // New value
                Text(newValue)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                
                // Change indicator
                if change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        
                        if !unit.isEmpty {
                            Text(String(format: "%.0f", abs(change)))
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundColor(changeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(changeColor.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, GymTheme.Spacing.xs)
    }
}

// MARK: - Exercise Comparison Card
struct ExerciseComparisonCard: View {
    let exerciseName: String
    let newExercise: Exercise
    let originalExercise: Exercise
    
    private var bestNewSet: ExerciseSet? {
        newExercise.sets.max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }
    
    private var bestOriginalSet: ExerciseSet? {
        originalExercise.sets.max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }
    
    private var weightChange: Double {
        (bestNewSet?.weight ?? 0) - (bestOriginalSet?.weight ?? 0)
    }
    
    private var repsChange: Int {
        (bestNewSet?.reps ?? 0) - (bestOriginalSet?.reps ?? 0)
    }
    
    private var setCountChange: Int {
        newExercise.sets.count - originalExercise.sets.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
            // Header
            HStack {
                Text(exerciseName)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                
                Spacer()
                
                // Overall indicator
                if weightChange > 0 || repsChange > 0 {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.gymSuccess)
                } else if weightChange < 0 || repsChange < 0 {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.gymError)
                } else {
                    Image(systemName: "equal.circle.fill")
                        .foregroundColor(.gymTextSecondary)
                }
            }
            
            // Best set comparison
            HStack(spacing: GymTheme.Spacing.lg) {
                // Weight - only show for weighted exercises
                if (bestNewSet?.weight ?? 0) > 0 || (bestOriginalSet?.weight ?? 0) > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best Weight")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gymTextSecondary)
                        
                        HStack(spacing: 4) {
                            Text("\(String(format: "%.0f", bestNewSet?.weight ?? 0)) lbs")
                                .font(GymTheme.Typography.subheadline)
                                .foregroundColor(.gymText)
                            
                            if weightChange != 0 {
                                Text(weightChange > 0 ? "+\(Int(weightChange))" : "\(Int(weightChange))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(weightChange > 0 ? .gymSuccess : .gymError)
                            }
                        }
                    }
                }
                
                // Reps
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best Reps")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gymTextSecondary)
                    
                    HStack(spacing: 4) {
                        Text("\(bestNewSet?.reps ?? 0) reps")
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymText)
                        
                        if repsChange != 0 {
                            Text(repsChange > 0 ? "+\(repsChange)" : "\(repsChange)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(repsChange > 0 ? .gymSuccess : .gymError)
                        }
                    }
                }
                
                // Sets
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sets")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gymTextSecondary)
                    
                    HStack(spacing: 4) {
                        Text("\(newExercise.sets.count)")
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymText)
                        
                        if setCountChange != 0 {
                            Text(setCountChange > 0 ? "+\(setCountChange)" : "\(setCountChange)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(setCountChange > 0 ? .gymSuccess : .gymError)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

// MARK: - New Exercise Card (not in original)
struct NewExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                
                Text("\(exercise.sets.count) sets")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
            }
            
            Spacer()
            
            Text("NEW")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gymSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gymSecondary.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

#Preview {
    let workout = Workout(name: "Push Day")
    return WorkoutView(workout: workout)
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
