import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate?  // nil for new template

    @State private var name: String
    @State private var templateDescription: String
    @State private var category: String
    @State private var exercises: [TemplateExerciseData]
    @State private var showingExercisePicker = false

    init(template: WorkoutTemplate?) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _templateDescription = State(initialValue: template?.templateDescription ?? "")
        _category = State(initialValue: template?.category ?? "Total Body")
        _exercises = State(initialValue: template?.templateExercises.sorted(by: { $0.order < $1.order }).map {
            TemplateExerciseData(from: $0)
        } ?? [])
    }

    var isValid: Bool {
        !name.isEmpty && !exercises.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Basic Info Section
                        basicInfoSection

                        // Exercises Section
                        exercisesSection

                        // Add Exercise Button
                        addExerciseButton
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gymTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(isValid ? .gymPrimary : .gymTextSecondary)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exerciseTemplate in
                    addExercise(from: exerciseTemplate)
                }
            }
        }
    }

    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Template Info")

            VStack(spacing: GymTheme.Spacing.sm) {
                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)

                    TextField("e.g., Upper Body Day", text: $name)
                        .font(GymTheme.Typography.body)
                        .foregroundColor(.gymText)
                        .padding(GymTheme.Spacing.sm)
                        .background(Color.gymSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                }

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description (Optional)")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)

                    TextField("Brief description", text: $templateDescription, axis: .vertical)
                        .font(GymTheme.Typography.body)
                        .foregroundColor(.gymText)
                        .lineLimit(2...4)
                        .padding(GymTheme.Spacing.sm)
                        .background(Color.gymSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                }

                // Category
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)

                    Menu {
                        ForEach(["Total Body", "Push", "Pull", "Legs", "Upper Body", "Lower Body", "Custom"], id: \.self) { cat in
                            Button(cat) {
                                category = cat
                            }
                        }
                    } label: {
                        HStack {
                            Text(category)
                                .font(GymTheme.Typography.body)
                                .foregroundColor(.gymText)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gymTextSecondary)
                        }
                        .padding(GymTheme.Spacing.sm)
                        .background(Color.gymSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                    }
                }
            }
        }
        .padding(.top, GymTheme.Spacing.md)
    }

    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Exercises (\(exercises.count))")

            if exercises.isEmpty {
                Text("No exercises added yet. Tap the button below to add exercises.")
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                    .padding(GymTheme.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(Color.gymSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
            } else {
                VStack(spacing: GymTheme.Spacing.xs) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        TemplateExerciseEditorRow(
                            exercise: binding(for: index),
                            index: index,
                            onDelete: {
                                deleteExercise(at: index)
                            },
                            onMoveUp: index > 0 ? {
                                moveExercise(from: index, to: index - 1)
                            } : nil,
                            onMoveDown: index < exercises.count - 1 ? {
                                moveExercise(from: index, to: index + 1)
                            } : nil
                        )
                    }
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

    // MARK: - Helpers
    private func binding(for index: Int) -> Binding<TemplateExerciseData> {
        Binding(
            get: { exercises[index] },
            set: { exercises[index] = $0 }
        )
    }

    private func addExercise(from exerciseTemplate: ExerciseTemplate) {
        let newExercise = TemplateExerciseData(
            exerciseName: exerciseTemplate.name,
            muscleGroup: exerciseTemplate.muscleGroup.rawValue,
            order: exercises.count,
            targetSets: 3,
            targetReps: 10
        )
        exercises.append(newExercise)
    }

    private func deleteExercise(at index: Int) {
        exercises.remove(at: index)
        // Reorder remaining exercises
        for i in 0..<exercises.count {
            exercises[i].order = i
        }
    }

    private func moveExercise(from source: Int, to destination: Int) {
        let exercise = exercises.remove(at: source)
        exercises.insert(exercise, at: destination)
        // Reorder all exercises
        for i in 0..<exercises.count {
            exercises[i].order = i
        }
    }

    private func saveTemplate() {
        if let existingTemplate = template {
            // Update existing template
            existingTemplate.name = name
            existingTemplate.templateDescription = templateDescription
            existingTemplate.category = category

            // Remove old exercises
            existingTemplate.templateExercises.forEach { modelContext.delete($0) }

            // Add new exercises
            for exerciseData in exercises {
                let exercise = exerciseData.toTemplateExercise()
                exercise.template = existingTemplate
                existingTemplate.templateExercises.append(exercise)
                modelContext.insert(exercise)
            }
        } else {
            // Create new template
            let newTemplate = WorkoutTemplate(
                name: name,
                templateDescription: templateDescription,
                isCustom: true,
                category: category
            )

            for exerciseData in exercises {
                let exercise = exerciseData.toTemplateExercise()
                exercise.template = newTemplate
                newTemplate.templateExercises.append(exercise)
            }

            modelContext.insert(newTemplate)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving template: \(error)")
        }
    }
}

// MARK: - Template Exercise Data
struct TemplateExerciseData: Identifiable {
    let id = UUID()
    var exerciseName: String
    var muscleGroup: String
    var order: Int
    var targetSets: Int
    var targetReps: Int
    var restSeconds: Int
    var notes: String

    init(from templateExercise: TemplateExercise) {
        self.exerciseName = templateExercise.exerciseName
        self.muscleGroup = templateExercise.muscleGroup
        self.order = templateExercise.order
        self.targetSets = templateExercise.targetSets
        self.targetReps = templateExercise.targetReps
        self.restSeconds = templateExercise.restSeconds
        self.notes = templateExercise.notes
    }

    init(exerciseName: String, muscleGroup: String, order: Int, targetSets: Int, targetReps: Int) {
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = 90
        self.notes = ""
    }

    func toTemplateExercise() -> TemplateExercise {
        TemplateExercise(
            exerciseName: exerciseName,
            muscleGroup: muscleGroup,
            order: order,
            targetSets: targetSets,
            targetReps: targetReps,
            restSeconds: restSeconds,
            notes: notes
        )
    }
}

// MARK: - Template Exercise Editor Row
struct TemplateExerciseEditorRow: View {
    @Binding var exercise: TemplateExerciseData
    let index: Int
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Row
            HStack(spacing: GymTheme.Spacing.md) {
                // Order Number
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gymTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.gymSurface)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)

                    Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }

                Spacer()

                // Reorder Buttons
                VStack(spacing: 2) {
                    if let onMoveUp = onMoveUp {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12))
                                .foregroundColor(.gymPrimary)
                        }
                    }

                    if let onMoveDown = onMoveDown {
                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gymPrimary)
                        }
                    }
                }

                // Expand/Delete Buttons
                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .foregroundColor(.gymText)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.gymError)
                    }
                }
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)

            // Expanded Details
            if isExpanded {
                VStack(spacing: GymTheme.Spacing.sm) {
                    HStack(spacing: GymTheme.Spacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sets")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymTextSecondary)

                            HStack {
                                Button {
                                    if exercise.targetSets > 1 {
                                        exercise.targetSets -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.gymTextSecondary)
                                }

                                Text("\(exercise.targetSets)")
                                    .font(GymTheme.Typography.headline)
                                    .foregroundColor(.gymText)
                                    .frame(width: 40)

                                Button {
                                    exercise.targetSets += 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.gymPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(GymTheme.Spacing.sm)
                        .background(Color.gymSurface)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymTextSecondary)

                            HStack {
                                Button {
                                    if exercise.targetReps > 1 {
                                        exercise.targetReps -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.gymTextSecondary)
                                }

                                Text("\(exercise.targetReps)")
                                    .font(GymTheme.Typography.headline)
                                    .foregroundColor(.gymText)
                                    .frame(width: 40)

                                Button {
                                    exercise.targetReps += 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.gymPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(GymTheme.Spacing.sm)
                        .background(Color.gymSurface)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
                    }
                }
                .padding(GymTheme.Spacing.md)
                .background(Color.gymSurface)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

#Preview {
    TemplateEditorView(template: nil)
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
