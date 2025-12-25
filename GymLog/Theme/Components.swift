import SwiftUI

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(GymTheme.Typography.title2)
                .foregroundColor(.gymText)
            
            Text(title)
                .font(GymTheme.Typography.caption)
                .foregroundColor(.gymTextSecondary)
        }
        .padding(GymTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let name: String
    let muscleGroup: String
    let setsInfo: String?
    let onTap: (() -> Void)?
    
    init(name: String, muscleGroup: String, setsInfo: String? = nil, onTap: (() -> Void)? = nil) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.setsInfo = setsInfo
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: GymTheme.Spacing.md) {
                Circle()
                    .fill(muscleGroupColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: muscleGroupIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(muscleGroupColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                    
                    Text(muscleGroup)
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
                
                Spacer()
                
                if let setsInfo = setsInfo {
                    Text(setsInfo)
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymTextSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gymTextSecondary)
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        }
        .buttonStyle(.plain)
    }
    
    private var muscleGroupColor: Color {
        switch muscleGroup.lowercased() {
        case "chest": return Color(hex: "FF6B6B")
        case "back": return Color(hex: "4ECDC4")
        case "shoulders": return Color(hex: "45B7D1")
        case "biceps": return Color(hex: "96CEB4")
        case "triceps": return Color(hex: "FFEAA7")
        case "legs": return Color(hex: "DDA0DD")
        case "core": return Color(hex: "98D8C8")
        case "cardio": return Color(hex: "F7DC6F")
        default: return Color.gymPrimary
        }
    }
    
    private var muscleGroupIcon: String {
        switch muscleGroup.lowercased() {
        case "chest": return "figure.arms.open"
        case "back": return "figure.walk"
        case "shoulders": return "figure.boxing"
        case "biceps": return "figure.strengthtraining.traditional"
        case "triceps": return "figure.strengthtraining.functional"
        case "legs": return "figure.run"
        case "core": return "figure.core.training"
        case "cardio": return "heart.fill"
        default: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Workout Card
struct WorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(GymTheme.Typography.cardTitle)
                            .foregroundColor(.gymText)
                        
                        Text(workout.date.formatted(date: .abbreviated, time: .shortened))
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
                
                HStack(spacing: GymTheme.Spacing.lg) {
                    Label("\(workout.exercises.count)", systemImage: "dumbbell.fill")
                        .font(GymTheme.Typography.footnote)
                        .foregroundColor(.gymTextSecondary)
                    
                    Label("\(workout.totalSets)", systemImage: "square.stack.fill")
                        .font(GymTheme.Typography.footnote)
                        .foregroundColor(.gymTextSecondary)
                    
                    Label(workout.formattedDuration, systemImage: "clock.fill")
                        .font(GymTheme.Typography.footnote)
                        .foregroundColor(.gymTextSecondary)
                }
                
                if !workout.exercises.isEmpty {
                    Text(workout.exercises.prefix(3).map { $0.name }.joined(separator: " • "))
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Set Input Row
struct SetInputRow: View {
    let setNumber: Int
    @Binding var weight: String
    @Binding var reps: String
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: GymTheme.Spacing.md) {
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.gymSuccess : Color.gymTextSecondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if isCompleted {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                
                TextField("0", text: $weight)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .padding(.vertical, 8)
                    .background(Color.gymSurface)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            }
            
            Text("×")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymTextSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                
                TextField("0", text: $reps)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(.vertical, 8)
                    .background(Color.gymSurface)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.gymError.opacity(0.7))
            }
        }
        .padding(GymTheme.Spacing.sm)
        .background(isCompleted ? Color.gymSuccess.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: GymTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.gymTextSecondary.opacity(0.5))
            
            VStack(spacing: GymTheme.Spacing.xs) {
                Text(title)
                    .font(GymTheme.Typography.title3)
                    .foregroundColor(.gymText)
                
                Text(message)
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(GymTheme.Spacing.xl)
    }
}

// MARK: - Muscle Group Chip
struct MuscleGroupChip: View {
    let muscleGroup: MuscleGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: muscleGroup.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(muscleGroup.rawValue)
                    .font(GymTheme.Typography.footnote)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.gymPrimary : Color.gymSurfaceElevated)
            .foregroundColor(isSelected ? .black : .gymText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymPrimary)
                }
            }
        }
    }
}

