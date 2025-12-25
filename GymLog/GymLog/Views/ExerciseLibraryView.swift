import SwiftUI

struct ExerciseLibraryView: View {
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    
    var filteredExercises: [ExerciseTemplate] {
        var exercises = ExerciseLibrary.exercises
        
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup }
        }
        
        if !searchText.isEmpty {
            exercises = exercises.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return exercises
    }
    
    var groupedExercises: [(MuscleGroup, [ExerciseTemplate])] {
        if selectedMuscleGroup != nil {
            return []
        }
        
        var groups: [MuscleGroup: [ExerciseTemplate]] = [:]
        
        for exercise in filteredExercises {
            groups[exercise.muscleGroup, default: []].append(exercise)
        }
        
        return MuscleGroup.allCases.compactMap { group in
            guard let exercises = groups[group], !exercises.isEmpty else { return nil }
            return (group, exercises)
        }
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
                    
                    // Muscle group filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: GymTheme.Spacing.xs) {
                            FilterChip(
                                title: "All",
                                icon: "square.grid.2x2",
                                isSelected: selectedMuscleGroup == nil
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedMuscleGroup = nil
                                }
                            }
                            
                            ForEach(MuscleGroup.allCases, id: \.self) { group in
                                FilterChip(
                                    title: group.rawValue,
                                    icon: group.icon,
                                    isSelected: selectedMuscleGroup == group
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMuscleGroup = group
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, GymTheme.Spacing.md)
                    }
                    .padding(.vertical, GymTheme.Spacing.md)
                    
                    // Exercise count
                    HStack {
                        Text("\(filteredExercises.count) exercises")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, GymTheme.Spacing.xs)
                    
                    // Exercise list
                    ScrollView {
                        if selectedMuscleGroup != nil || !searchText.isEmpty {
                            // Flat list when filtered
                            LazyVStack(spacing: GymTheme.Spacing.xs) {
                                ForEach(filteredExercises) { exercise in
                                    ExerciseLibraryRow(exercise: exercise)
                                }
                            }
                            .padding(.horizontal, GymTheme.Spacing.md)
                        } else {
                            // Grouped list
                            LazyVStack(spacing: GymTheme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                                ForEach(groupedExercises, id: \.0) { group, exercises in
                                    Section {
                                        ForEach(exercises) { exercise in
                                            ExerciseLibraryRow(exercise: exercise)
                                        }
                                    } header: {
                                        HStack {
                                            Image(systemName: group.icon)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(muscleGroupColor(group))
                                            
                                            Text(group.rawValue)
                                                .font(GymTheme.Typography.headline)
                                                .foregroundColor(.gymText)
                                            
                                            Spacer()
                                            
                                            Text("\(exercises.count)")
                                                .font(GymTheme.Typography.caption)
                                                .foregroundColor(.gymTextSecondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.gymSurfaceElevated)
                                                .clipShape(Capsule())
                                        }
                                        .padding(.vertical, GymTheme.Spacing.sm)
                                        .padding(.horizontal, GymTheme.Spacing.md)
                                        .background(Color.gymBackground)
                                    }
                                }
                            }
                            .padding(.horizontal, GymTheme.Spacing.md)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
        }
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

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(title)
                    .font(GymTheme.Typography.footnote)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.gymPrimary : Color.gymSurfaceElevated)
            .foregroundColor(isSelected ? .black : .gymText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Library Row
struct ExerciseLibraryRow: View {
    let exercise: ExerciseTemplate
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: GymTheme.Spacing.md) {
                    Circle()
                        .fill(muscleGroupColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: exercise.muscleGroup.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(muscleGroupColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(exercise.name)
                                .font(GymTheme.Typography.headline)
                                .foregroundColor(.gymText)
                            
                            if exercise.isPrimary {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gymAccent)
                            }
                        }
                        
                        Text(exercise.muscleGroup.rawValue)
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gymTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(GymTheme.Spacing.md)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
                    Divider()
                        .background(Color.gymTextSecondary.opacity(0.2))
                    
                    if !exercise.description.isEmpty {
                        Text(exercise.description)
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymTextSecondary)
                    }
                    
                    // Tips section (placeholder for future enhancement)
                    HStack(spacing: GymTheme.Spacing.md) {
                        Label("Primary", systemImage: exercise.isPrimary ? "checkmark.circle.fill" : "circle")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(exercise.isPrimary ? .gymSuccess : .gymTextSecondary)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.bottom, GymTheme.Spacing.md)
            }
        }
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
    
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup {
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
    ExerciseLibraryView()
}

