import SwiftUI
import SwiftData

// MARK: - Inline Exercise Card (with sets shown directly)
struct InlineExerciseCard: View {
    @Bindable var exercise: Exercise
    let onDelete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded = true
    @State private var showingDeleteConfirm = false
    @State private var activeSetId: UUID?
    
    // Check if this is a cardio exercise
    private var isCardio: Bool {
        exercise.muscleGroup == "Cardio"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Exercise header
            exerciseHeader
            
            if isExpanded {
                Divider()
                    .background(Color.gymTextSecondary.opacity(0.2))
                
                if isCardio {
                    // Cardio: Just show duration timer
                    cardioContent
                } else {
                    // Strength: Show sets with weight/reps
                    strengthContent
                }
            }
        }
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        .alert("Delete Exercise?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will remove \(exercise.name).")
        }
    }
    
    // MARK: - Exercise Header
    private var exerciseHeader: some View {
        HStack(spacing: GymTheme.Spacing.md) {
            // Exercise icon
            ZStack {
                Circle()
                    .fill(muscleGroupColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: muscleGroupIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(muscleGroupColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                
                if isCardio {
                    Text("Cardio")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                } else {
                    Text("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
            }
            
            Spacer()
            
            // Delete button
            Button {
                showingDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.gymTextSecondary)
            }
            
            // Expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gymTextSecondary)
            }
        }
        .padding(GymTheme.Spacing.md)
    }
    
    // MARK: - Cardio Content (Duration Timer)
    private var cardioContent: some View {
        CardioTimerView(exercise: exercise)
            .padding(.horizontal, GymTheme.Spacing.md)
            .padding(.bottom, GymTheme.Spacing.md)
    }
    
    // MARK: - Strength Content (Sets)
    private var strengthContent: some View {
        VStack(spacing: GymTheme.Spacing.sm) {
            ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                InlineSetRow(
                    set: set,
                    setNumber: index + 1,
                    isActive: activeSetId == set.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeSetId = activeSetId == set.id ? nil : set.id
                        }
                    },
                    onDone: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeSetId = nil
                        }
                    },
                    onDelete: {
                        deleteSet(set)
                    }
                )
            }
            
            // Add set button
            Button {
                addSet()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Set")
                        .font(GymTheme.Typography.subheadline)
                }
                .foregroundColor(.gymPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GymTheme.Spacing.sm)
            }
        }
        .padding(.horizontal, GymTheme.Spacing.md)
        .padding(.bottom, GymTheme.Spacing.md)
    }
    
    private func addSet() {
        let newOrder = (exercise.sets.map { $0.order }.max() ?? -1) + 1
        let lastSet = exercise.sets.last
        let newSet = ExerciseSet(
            reps: lastSet?.reps ?? 8,
            weight: lastSet?.weight ?? 0,
            order: newOrder
        )
        exercise.sets.append(newSet)
        newSet.exercise = exercise
        
        // Automatically make the new set active
        withAnimation(.easeInOut(duration: 0.2)) {
            activeSetId = newSet.id
        }
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        if activeSetId == set.id {
            activeSetId = nil
        }
        modelContext.delete(set)
    }
    
    private var muscleGroupColor: Color {
        guard let group = MuscleGroup(rawValue: exercise.muscleGroup) else {
            return .gymPrimary
        }
        switch group {
        case .chest: return Color(hex: "FF6B6B")
        case .back: return Color(hex: "4ECDC4")
        case .shoulders: return Color(hex: "FFE66D")
        case .biceps: return Color(hex: "FF8C5A")
        case .triceps: return Color(hex: "FF8C5A")
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

