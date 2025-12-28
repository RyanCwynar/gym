import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate

    @State private var showingEditor = false
    @State private var showingDeleteAlert = false
    @State private var startingWorkout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Template Header
                        headerSection

                        // Exercise List
                        exerciseListSection

                        // Stats Section
                        statsSection
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
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.gymTextSecondary)
                }

                if template.isCustom {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingEditor = true
                            } label: {
                                Label("Edit Template", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Template", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.gymText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                TemplateEditorView(template: template)
            }
            .alert("Delete Template?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTemplate()
                }
            } message: {
                Text("This action cannot be undone. Past workouts using this template will not be affected.")
            }
            .fullScreenCover(isPresented: $startingWorkout) {
                if let workout = createWorkoutFromTemplate() {
                    WorkoutView(workout: workout)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            HStack {
                if !template.isCustom {
                    Image(systemName: "star.fill")
                        .foregroundColor(.gymAccent)
                }

                Text(template.category)
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gymSurface)
                    .clipShape(Capsule())

                Spacer()
            }

            Text(template.name)
                .font(GymTheme.Typography.largeTitle)
                .foregroundColor(.gymText)

            if !template.templateDescription.isEmpty {
                Text(template.templateDescription)
                    .font(GymTheme.Typography.body)
                    .foregroundColor(.gymTextSecondary)
            }
        }
        .padding(.top, GymTheme.Spacing.lg)
    }

    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Exercises")

            VStack(spacing: GymTheme.Spacing.xs) {
                ForEach(template.templateExercises.sorted(by: { $0.order < $1.order })) { exercise in
                    TemplateExerciseRow(exercise: exercise)
                }
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Details")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: GymTheme.Spacing.sm) {
                StatCard(
                    title: "Exercises",
                    value: "\(template.templateExercises.count)",
                    icon: "dumbbell.fill",
                    color: .gymPrimary
                )

                StatCard(
                    title: "Est. Time",
                    value: formatDuration(template.estimatedDuration),
                    icon: "clock.fill",
                    color: .gymSecondary
                )

                StatCard(
                    title: "Times Used",
                    value: "\(template.timesUsed)",
                    icon: "repeat",
                    color: .gymAccent
                )

                if let lastUsed = template.lastUsed {
                    StatCard(
                        title: "Last Used",
                        value: lastUsed.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar",
                        color: .gymSuccess
                    )
                }
            }
        }
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        Button {
            startingWorkout = true
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("Start Workout from Template")
            }
            .font(GymTheme.Typography.buttonText)
            .foregroundColor(.black)
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
        .padding(GymTheme.Spacing.md)
        .background(
            Color.gymBackground
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }

    // MARK: - Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }

    private func createWorkoutFromTemplate() -> Workout? {
        let workout = Workout(
            name: template.name,
            templateId: template.id,
            templateName: template.name
        )

        // Update template usage
        template.lastUsed = Date()
        template.timesUsed += 1

        // Create exercises from template
        for templateExercise in template.templateExercises.sorted(by: { $0.order < $1.order }) {
            let exercise = Exercise(
                name: templateExercise.exerciseName,
                muscleGroup: templateExercise.muscleGroup,
                order: templateExercise.order,
                targetSets: templateExercise.targetSets,
                targetReps: templateExercise.targetReps
            )

            // Fetch previous performance
            let progressionService = ExerciseProgressionService(context: modelContext)
            if let lastPerformance = progressionService.getLastPerformance(exerciseName: templateExercise.exerciseName) {
                exercise.previousBest = progressionService.formatPreviousPerformance(lastPerformance)
            }

            // Add default sets based on target
            for i in 0..<templateExercise.targetSets {
                let set = ExerciseSet(order: i)

                // Pre-fill with previous performance if available
                if let suggestedWeight = progressionService.suggestStartingWeight(exerciseName: templateExercise.exerciseName),
                   let suggestedReps = progressionService.suggestStartingReps(exerciseName: templateExercise.exerciseName) {
                    set.previousWeight = suggestedWeight
                    set.previousReps = suggestedReps
                }

                exercise.sets.append(set)
                set.exercise = exercise
            }

            workout.exercises.append(exercise)
            exercise.workout = workout
        }

        modelContext.insert(workout)

        do {
            try modelContext.save()
            return workout
        } catch {
            print("Error creating workout from template: \(error)")
            return nil
        }
    }

    private func deleteTemplate() {
        modelContext.delete(template)
        dismiss()
    }
}

// MARK: - Template Exercise Row
struct TemplateExerciseRow: View {
    let exercise: TemplateExercise

    var body: some View {
        HStack(spacing: GymTheme.Spacing.md) {
            // Order Number
            Text("\(exercise.order + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gymTextSecondary)
                .frame(width: 28, height: 28)
                .background(Color.gymSurface)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)

                Text(exercise.muscleGroup)
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
            }

            Spacer()

            // Target Sets x Reps
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(exercise.targetSets) × \(exercise.targetReps)")
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymPrimary)

                Text("sets × reps")
                    .font(.system(size: 10))
                    .foregroundColor(.gymTextSecondary)
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

#Preview {
    let template = WorkoutTemplate(
        name: "Total Body Workout A",
        templateDescription: "Balanced full-body workout",
        category: "Total Body"
    )

    return TemplateDetailView(template: template)
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
