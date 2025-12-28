import SwiftUI

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

