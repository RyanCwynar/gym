import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: Workout
    
    @State private var showingExercisePicker = false
    @State private var showingFinishAlert = false
    @State private var showingDiscardAlert = false
    @State private var workoutTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedTime: TimeInterval = 0
    @State private var workoutStartTime: Date?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Workout Header
                        workoutHeader
                        
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
                ExercisePickerView { template in
                    addExercise(from: template)
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
                if workoutStartTime == nil {
                    workoutStartTime = Date()
                }
            }
            .onReceive(workoutTimer) { _ in
                if let startTime = workoutStartTime, !workout.isCompleted {
                    elapsedTime = Date().timeIntervalSince(startTime)
                }
            }
        }
    }
    
    // MARK: - Workout Header
    private var workoutHeader: some View {
        VStack(spacing: GymTheme.Spacing.xs) {
            Text(workout.date.formatted(date: .complete, time: .omitted))
                .font(GymTheme.Typography.subheadline)
                .foregroundColor(.gymTextSecondary)
        }
        .padding(.top, GymTheme.Spacing.md)
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
    
    private func addExercise(from template: ExerciseTemplate) {
        let exercise = Exercise(
            name: template.name,
            muscleGroup: template.muscleGroup.rawValue,
            order: workout.exercises.count
        )
        
        // Add default set
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
    
    @State private var setInputs: [(weight: String, reps: String)] = []
    
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
            VStack(spacing: GymTheme.Spacing.xs) {
                ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                    SetRow(set: set, setNumber: index + 1, onDelete: {
                        deleteSet(set)
                    })
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
        let set = ExerciseSet(order: exercise.sets.count)
        exercise.sets.append(set)
        set.exercise = exercise
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        exercise.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
    }
}

// MARK: - Set Row
struct SetRow: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    let onDelete: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: GymTheme.Spacing.md) {
            // Set number / completion toggle
            Button {
                set.isCompleted.toggle()
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
                            .font(GymTheme.Typography.footnote)
                            .foregroundColor(.gymTextSecondary)
                    }
                }
            }
            
            // Weight input
            VStack(alignment: .leading, spacing: 2) {
                Text("lbs")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gymTextSecondary)
                
                TextField("0", text: $weightText)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .padding(.vertical, 6)
                    .background(Color.gymSurface)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
                    .onChange(of: weightText) { _, newValue in
                        set.weight = Double(newValue) ?? 0
                    }
            }
            
            Text("×")
                .font(GymTheme.Typography.headline)
                .foregroundColor(.gymTextSecondary)
            
            // Reps input
            VStack(alignment: .leading, spacing: 2) {
                Text("reps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gymTextSecondary)
                
                TextField("0", text: $repsText)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(Color.gymSurface)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
                    .onChange(of: repsText) { _, newValue in
                        set.reps = Int(newValue) ?? 0
                    }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gymTextSecondary.opacity(0.5))
            }
        }
        .padding(.vertical, GymTheme.Spacing.xs)
        .padding(.horizontal, GymTheme.Spacing.sm)
        .background(set.isCompleted ? Color.gymSuccess.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
        .onAppear {
            weightText = set.weight > 0 ? String(format: "%.0f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

// MARK: - Exercise Picker View
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (ExerciseTemplate) -> Void
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    
    var filteredExercises: [ExerciseTemplate] {
        var exercises = ExerciseLibrary.exercises
        
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup }
        }
        
        if !searchText.isEmpty {
            exercises = exercises.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
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
                    
                    // Muscle group filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: GymTheme.Spacing.xs) {
                            MuscleGroupChip(
                                muscleGroup: MuscleGroup.fullBody,
                                isSelected: selectedMuscleGroup == nil
                            ) {
                                selectedMuscleGroup = nil
                            }
                            
                            ForEach(MuscleGroup.allCases.filter { $0 != .fullBody }, id: \.self) { group in
                                MuscleGroupChip(
                                    muscleGroup: group,
                                    isSelected: selectedMuscleGroup == group
                                ) {
                                    selectedMuscleGroup = group
                                }
                            }
                        }
                        .padding(.horizontal, GymTheme.Spacing.md)
                    }
                    .padding(.vertical, GymTheme.Spacing.md)
                    
                    // Exercise list
                    ScrollView {
                        LazyVStack(spacing: GymTheme.Spacing.xs) {
                            ForEach(filteredExercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    ExerciseRow(
                                        name: exercise.name,
                                        muscleGroup: exercise.muscleGroup.rawValue
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, GymTheme.Spacing.md)
                        .padding(.bottom, GymTheme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gymPrimary)
                }
            }
        }
    }
}

#Preview {
    let workout = Workout(name: "Push Day")
    return WorkoutView(workout: workout)
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}

