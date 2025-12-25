import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Header Card
                        headerCard
                        
                        // Stats Row
                        statsRow
                        
                        // Exercises
                        exercisesSection
                        
                        // Notes
                        if !workout.notes.isEmpty {
                            notesSection
                        }
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, GymTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gymText)
                    }
                }
            }
            .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWorkout()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditSheet) {
                WorkoutView(workout: workout)
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            // Status badge
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(workout.isCompleted ? Color.gymSuccess : Color.gymWarning)
                        .frame(width: 8, height: 8)
                    
                    Text(workout.isCompleted ? "COMPLETED" : "IN PROGRESS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(workout.isCompleted ? .gymSuccess : .gymWarning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((workout.isCompleted ? Color.gymSuccess : Color.gymWarning).opacity(0.15))
                .clipShape(Capsule())
                
                Spacer()
            }
            
            // Workout name and date
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(GymTheme.Typography.title1)
                    .foregroundColor(.gymText)
                
                Text(workout.date.formatted(date: .complete, time: .shortened))
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            DetailStatCard(
                icon: "clock.fill",
                value: workout.formattedDuration,
                label: "Duration",
                color: .gymPrimary
            )
            
            DetailStatCard(
                icon: "dumbbell.fill",
                value: "\(workout.exercises.count)",
                label: "Exercises",
                color: .gymSecondary
            )
            
            DetailStatCard(
                icon: "square.stack.fill",
                value: "\(workout.totalSets)",
                label: "Sets",
                color: .gymAccent
            )
            
            DetailStatCard(
                icon: "scalemass.fill",
                value: formatVolume(workout.totalVolume),
                label: "Volume",
                color: .gymSuccess
            )
        }
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            Text("Exercises")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            if workout.exercises.isEmpty {
                EmptyStateView(
                    icon: "dumbbell.fill",
                    title: "No exercises",
                    message: "This workout has no exercises logged"
                )
            } else {
                ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                    ExerciseDetailCard(exercise: exercise)
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
            Text("Notes")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            Text(workout.notes)
                .font(GymTheme.Typography.body)
                .foregroundColor(.gymTextSecondary)
                .padding(GymTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        }
    }
    
    // MARK: - Helpers
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        dismiss()
    }
}

// MARK: - Detail Stat Card
struct DetailStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(GymTheme.Typography.headline)
                .foregroundColor(.gymText)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gymTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let exercise: Exercise
    
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
                
                if let best = exercise.bestSet {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Best Set")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gymTextSecondary)
                        
                        Text("\(String(format: "%.0f", best.weight)) × \(best.reps)")
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymPrimary)
                    }
                }
            }
            
            // Sets
            if !exercise.sets.isEmpty {
                VStack(spacing: GymTheme.Spacing.xs) {
                    // Header row
                    HStack {
                        Text("SET")
                            .frame(width: 40, alignment: .leading)
                        Text("LBS")
                            .frame(width: 60, alignment: .center)
                        Text("REPS")
                            .frame(width: 50, alignment: .center)
                        Spacer()
                        Text("VOL")
                            .frame(width: 60, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gymTextSecondary.opacity(0.7))
                    
                    Divider()
                        .background(Color.gymTextSecondary.opacity(0.2))
                    
                    // Set rows
                    ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            HStack(spacing: 4) {
                                if set.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gymSuccess)
                                }
                                Text("\(index + 1)")
                                    .foregroundColor(.gymTextSecondary)
                            }
                            .frame(width: 40, alignment: .leading)
                            
                            Text(String(format: "%.0f", set.weight))
                                .foregroundColor(.gymText)
                                .frame(width: 60, alignment: .center)
                            
                            Text("\(set.reps)")
                                .foregroundColor(.gymText)
                                .frame(width: 50, alignment: .center)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f", set.volume))
                                .foregroundColor(.gymTextSecondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .font(GymTheme.Typography.subheadline)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
}

#Preview {
    let workout = Workout(name: "Push Day", isCompleted: true)
    return WorkoutDetailView(workout: workout)
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}

