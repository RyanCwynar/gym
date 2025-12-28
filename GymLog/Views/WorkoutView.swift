import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: Workout
    
    @State private var showingExercisePicker = false
    @State private var showingFinishAlert = false
    @State private var showingDiscardAlert = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedTime: TimeInterval = 0
    
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
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, 120)
                }
                
                // Bottom Action Bar
                VStack {
                    Spacer()
                    bottomActionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if workout.exercises.isEmpty {
                            modelContext.delete(workout)
                            dismiss()
                        } else {
                            showingDiscardAlert = true
                        }
                    }
                    .foregroundColor(.gymTextSecondary)
                }
                
                ToolbarItem(placement: .principal) {
                    TextField("Workout Name", text: $workout.name)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                        .multilineTextAlignment(.center)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                MuscleGroupPickerView { exerciseName, muscleGroup in
                    addExercise(name: exerciseName, muscleGroup: muscleGroup)
                }
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
            .onAppear {
                // Calculate elapsed from persisted start date
                elapsedTime = workout.elapsedTime
            }
            .onReceive(timer) { _ in
                if !workout.isCompleted {
                    elapsedTime = workout.elapsedTime
                }
            }
        }
    }
    
    // MARK: - Timer Card
    private var timerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                
                Text(formatDuration(elapsedTime))
                    .font(GymTheme.Typography.statValue)
                    .foregroundColor(.gymText)
                    .monospacedDigit()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: GymTheme.Spacing.xs) {
                HStack(spacing: GymTheme.Spacing.lg) {
                    VStack(alignment: .trailing) {
                        Text("\(workout.exercises.count)")
                            .font(GymTheme.Typography.title2)
                            .foregroundColor(.gymPrimary)
                        Text("exercises")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    }
                    
                    VStack(alignment: .trailing) {
                        Text("\(workout.totalSets)")
                            .font(GymTheme.Typography.title2)
                            .foregroundColor(.gymSecondary)
                        Text("sets")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    }
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
                ExerciseCard(exercise: exercise, onDelete: {
                    deleteExercise(exercise)
                })
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
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: GymTheme.Spacing.md) {
            Button {
                showingDiscardAlert = true
            } label: {
                Text("Discard")
                    .font(GymTheme.Typography.buttonText)
                    .foregroundColor(.gymError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GymTheme.Spacing.md)
                    .background(Color.gymError.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            }
            
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
        }
        .padding(GymTheme.Spacing.md)
        .background(
            Color.gymBackground
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
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
        
        // Add first set with default values
        let set = ExerciseSet(order: 0)
        exercise.sets.append(set)
        set.exercise = exercise
        
        workout.exercises.append(exercise)
        exercise.workout = workout
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        workout.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
    
    private func finishWorkout() {
        workout.isCompleted = true
        workout.duration = elapsedTime
        dismiss()
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: Exercise
    let onDelete: () -> Void
    
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
                        onDelete: { deleteSet(set) }
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
        // Get weight from last set if exists
        let lastWeight = exercise.sortedSets.last?.weight ?? 0
        let set = ExerciseSet(weight: lastWeight, order: exercise.sets.count)
        exercise.sets.append(set)
        set.exercise = exercise
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        exercise.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
    }
}

// MARK: - Set Row with +/- Buttons (Stacked Layout)
struct SetRow: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    let previousWeight: Double?
    let onDelete: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        VStack(spacing: GymTheme.Spacing.sm) {
            // Row 1: Set number and delete button
            HStack {
                // Set number / completion toggle
                Button {
                    set.isCompleted.toggle()
                } label: {
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
                            .foregroundColor(set.isCompleted ? .gymSuccess : .gymText)
                        
                        if set.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.gymSuccess)
                                .font(.system(size: 14))
                        }
                    }
                }
                
                Spacer()
                
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
            
            // Row 2: Weight controls
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
            
            // Row 3: Reps controls
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
        .padding(GymTheme.Spacing.md)
        .background(set.isCompleted ? Color.gymSuccess.opacity(0.08) : Color.gymSurface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        .onAppear {
            // Auto-fill weight from previous set or use current value
            if set.weight == 0, let prevWeight = previousWeight, prevWeight > 0 {
                set.weight = prevWeight
            }
            weightText = set.weight > 0 ? String(format: "%.0f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
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
            }
            .padding(GymTheme.Spacing.sm)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            .padding(.horizontal, GymTheme.Spacing.md)
            .padding(.top, GymTheme.Spacing.md)
            
            ScrollView {
                LazyVStack(spacing: GymTheme.Spacing.xs) {
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

#Preview {
    let workout = Workout(name: "Push Day")
    return WorkoutView(workout: workout)
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
