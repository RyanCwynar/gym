import SwiftUI
import Combine

// MARK: - Home View (Convex-backed)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingExercisePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Connection status (if not connected)
                        if !viewModel.isConnected {
                            connectionBanner
                        }
                        
                        // Today's Work Time Summary (only show if there are sets)
                        if viewModel.totalSets > 0 {
                            workTimeSummary
                        }
                        
                        // Add Exercise Button
                        addExerciseButton
                        
                        // Today's exercises grouped
                        if !viewModel.allExerciseGroups.isEmpty {
                            todaysSetsSection
                        } else if viewModel.isConnected {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet { exerciseName, muscleGroup in
                    viewModel.addExercise(name: exerciseName, muscleGroup: muscleGroup)
                }
            }
            .onAppear {
                viewModel.startSubscription()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                
                Text(greeting)
                    .font(GymTheme.Typography.largeTitle)
                    .foregroundColor(.gymText)
            }
            
            Spacer()
        }
        .padding(.top, GymTheme.Spacing.lg)
    }
    
    // MARK: - Connection Banner
    private var connectionBanner: some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.gymWarning)
            
            Text(ConvexAPI.shared.isAuthenticated ? "Connecting to server..." : "Set API Key in Settings")
                .font(GymTheme.Typography.caption)
                .foregroundColor(.gymWarning)
            
            Spacer()
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymWarning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
    
    // MARK: - Work Time Summary
    private var workTimeSummary: some View {
        HStack(spacing: GymTheme.Spacing.lg) {
            // Work time
            HStack(spacing: GymTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.gymSuccess.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gymSuccess)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Work Time")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                    
                    Text(formatTotalTime(viewModel.totalWorkTime))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.gymText)
                }
            }
            
            Spacer()
            
            // Sets completed
            VStack(alignment: .trailing, spacing: 2) {
                Text("Sets")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                
                Text("\(viewModel.completedSets)/\(viewModel.totalSets)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gymSuccess)
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
    
    // MARK: - Add Exercise Button
    private var addExerciseButton: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                
                Text("Add Exercise")
                    .font(GymTheme.Typography.headline)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(GymTheme.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "FF8C5A")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Today's Sets Section
    private var todaysSetsSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            // Summary stats (only show if there are sets)
            if viewModel.totalSets > 0 {
                HStack(spacing: GymTheme.Spacing.lg) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gymSecondary)
                        Text("\(viewModel.allExerciseGroups.count)")
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymText)
                    }
                    .fixedSize()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gymAccent)
                        Text("\(viewModel.completedSets)/\(viewModel.totalSets)")
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymText)
                    }
                    .fixedSize()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 12))
                            .foregroundColor(.gymSuccess)
                        Text("\(viewModel.totalReps)")
                            .font(GymTheme.Typography.subheadline)
                            .foregroundColor(.gymText)
                    }
                    .fixedSize()
                }
                .frame(maxWidth: .infinity)
                .padding(GymTheme.Spacing.md)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            }
            
            // Exercise cards with sets from Convex
            ForEach(viewModel.groupedSets, id: \.exerciseName) { group in
                ConvexExerciseCard(
                    exerciseName: group.exerciseName,
                    exerciseType: group.exerciseType,
                    sets: group.sets,
                    onAddSet: {
                        print("🟡 onAddSet triggered for: \(group.exerciseName)")
                        Task {
                            await viewModel.addSet(
                                exerciseName: group.exerciseName,
                                muscleGroup: muscleGroupFromType(group.exerciseType)
                            )
                        }
                    },
                    onDeleteSet: { setId in
                        Task {
                            await viewModel.deleteSet(setId: setId)
                        }
                    },
                    onDeleteExercise: {
                        viewModel.removeExercise(name: group.exerciseName)
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.gymTextSecondary.opacity(0.5))
            
            Text("No exercises yet")
                .font(GymTheme.Typography.headline)
                .foregroundColor(.gymTextSecondary)
            
            Text("Tap \"Add Exercise\" to start your workout")
                .font(GymTheme.Typography.caption)
                .foregroundColor(.gymTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GymTheme.Spacing.xxl)
    }
    
    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Late night gains"
        }
    }
    
    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func muscleGroupFromType(_ type: String) -> String {
        switch type {
        case "cardio": return "Cardio"
        case "calisthenics": return "Core"
        default: return "Other"
        }
    }
}

// MARK: - Pending Exercise (added but no sets yet)
struct PendingExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscleGroup: String
    let exerciseType: String
    let addedAt: Date
}

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var sets: [ConvexSet] = []
    @Published var pendingExercises: [PendingExercise] = []
    @Published var isConnected = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // All exercises to display (pending + those with sets from Convex)
    var allExerciseGroups: [ExerciseGroup] {
        // Get exercises from Convex sets
        let grouped = Dictionary(grouping: sets) { $0.exerciseName }
        var groups = grouped.map { name, sets in
            ExerciseGroup(
                exerciseName: name,
                exerciseType: sets.first?.exerciseType ?? "resistance",
                sets: sets.sorted { ($0.setOrder ?? 0) < ($1.setOrder ?? 0) }
            )
        }
        
        // Add pending exercises that don't have sets yet
        let exercisesWithSets = Set(groups.map { $0.exerciseName })
        for pending in pendingExercises {
            if !exercisesWithSets.contains(pending.name) {
                groups.append(ExerciseGroup(
                    exerciseName: pending.name,
                    exerciseType: pending.exerciseType,
                    sets: []
                ))
            }
        }
        
        // Sort by creation time (pending at end, or by first set creation time)
        return groups.sorted { a, b in
            let aTime = a.sets.first?._creationTime ?? Double.greatestFiniteMagnitude
            let bTime = b.sets.first?._creationTime ?? Double.greatestFiniteMagnitude
            return aTime < bTime
        }
    }
    
    // For backward compatibility
    var groupedSets: [ExerciseGroup] {
        allExerciseGroups
    }
    
    var totalWorkTime: TimeInterval {
        sets.reduce(0) { $0 + TimeInterval($1.workTime ?? 0) + TimeInterval($1.duration ?? 0) }
    }
    
    var totalSets: Int {
        sets.count
    }
    
    var completedSets: Int {
        sets.filter { $0.isCompleted == true }.count
    }
    
    var totalReps: Int {
        sets.reduce(0) { $0 + ($1.reps ?? 0) }
    }
    
    func startSubscription() {
        guard ConvexAPI.shared.isAuthenticated else {
            print("❌ Not authenticated - cannot subscribe")
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        print("🔵 Starting Convex subscription for today's sets...")
        
        ConvexAPI.shared.subscribeToSetsByDay(dayStart: startOfDay, dayEnd: endOfDay)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSets in
                if let sets = newSets {
                    print("✅ Received \(sets.count) sets from Convex")
                    self?.sets = sets
                    self?.isConnected = true
                    
                    // Remove pending exercises that now have sets
                    let exercisesWithSets = Set(sets.map { $0.exerciseName })
                    self?.pendingExercises.removeAll { exercisesWithSets.contains($0.name) }
                }
            }
            .store(in: &cancellables)
    }
    
    // Add exercise (shows empty card)
    func addExercise(name: String, muscleGroup: String) {
        let exerciseType = ConvexAPI.exerciseTypeString(for: muscleGroup)
        
        // Check if already exists
        let existingNames = Set(allExerciseGroups.map { $0.exerciseName })
        guard !existingNames.contains(name) else {
            print("⚠️ Exercise '\(name)' already exists")
            return
        }
        
        let pending = PendingExercise(
            name: name,
            muscleGroup: muscleGroup,
            exerciseType: exerciseType,
            addedAt: Date()
        )
        pendingExercises.append(pending)
        print("✅ Added pending exercise: \(name)")
    }
    
    // Add set to exercise (creates in Convex)
    func addSet(exerciseName: String, muscleGroup: String) async {
        print("🔵 addSet called - exerciseName: \(exerciseName), muscleGroup: \(muscleGroup)")
        
        guard ConvexAPI.shared.isAuthenticated else {
            print("❌ Not authenticated - cannot create set")
            return
        }
        
        do {
            let existingSetCount = allExerciseGroups.first { $0.exerciseName == exerciseName }?.sets.count ?? 0
            let exerciseType = ConvexAPI.exerciseType(for: muscleGroup)
            
            print("🔵 Creating set with: exerciseType=\(exerciseType.rawValue), setOrder=\(existingSetCount)")
            
            let setId = try await ConvexAPI.shared.createSet(
                exerciseName: exerciseName,
                exerciseType: exerciseType,
                reps: 8, // default reps
                setOrder: existingSetCount
            )
            print("✅ Created set: \(setId)")
        } catch {
            print("❌ Error creating set: \(error)")
        }
    }
    
    func deleteSet(setId: String) async {
        do {
            try await ConvexAPI.shared.deleteSet(setId: setId)
            print("✅ Deleted set: \(setId)")
        } catch {
            print("❌ Error deleting set: \(error)")
        }
    }
    
    func removeExercise(name: String) {
        // Remove from pending
        pendingExercises.removeAll { $0.name == name }
        
        // Delete all sets for this exercise from Convex
        let setsToDelete = sets.filter { $0.exerciseName == name }
        for set in setsToDelete {
            Task {
                await deleteSet(setId: set._id)
            }
        }
    }
}

// MARK: - Exercise Group (for display)
struct ExerciseGroup {
    let exerciseName: String
    let exerciseType: String
    let sets: [ConvexSet]
}

// MARK: - Convex Exercise Card
struct ConvexExerciseCard: View {
    let exerciseName: String
    let exerciseType: String
    let sets: [ConvexSet]
    let onAddSet: () -> Void
    let onDeleteSet: (String) -> Void
    let onDeleteExercise: () -> Void
    
    @State private var isExpanded = true
    @State private var showingDeleteConfirm = false
    
    private var isCardio: Bool {
        exerciseType == "cardio"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: GymTheme.Spacing.md) {
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(exerciseColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(exerciseColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exerciseName)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                    
                    if sets.isEmpty {
                        Text("No sets yet")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    } else {
                        Text(isCardio ? "Cardio" : "\(sets.count) set\(sets.count == 1 ? "" : "s")")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    }
                }
                
                Spacer()
                
                // Delete exercise button
                Button {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gymTextSecondary.opacity(0.5))
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
            
            if isExpanded {
                Divider()
                    .background(Color.gymTextSecondary.opacity(0.2))
                
                VStack(spacing: GymTheme.Spacing.sm) {
                    // Empty state
                    if sets.isEmpty {
                        Text("Tap \"Add Set\" to get started")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary.opacity(0.7))
                            .padding(.vertical, GymTheme.Spacing.sm)
                    }
                    
                    // Sets
                    ForEach(Array(sets.enumerated()), id: \.element._id) { index, set in
                        ConvexSetRow(
                            set: set,
                            setNumber: index + 1,
                            onDelete: { onDeleteSet(set._id) }
                        )
                    }
                    
                    // Add set button
                    Button {
                        print("🟢 Add Set button tapped for: \(exerciseName)")
                        onAddSet()
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
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.bottom, GymTheme.Spacing.md)
            }
        }
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        .confirmationDialog("Delete \(exerciseName)?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Exercise", role: .destructive) {
                onDeleteExercise()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all sets for this exercise.")
        }
    }
    
    private var exerciseColor: Color {
        switch exerciseType {
        case "cardio": return Color(hex: "F38181")
        case "calisthenics": return Color(hex: "95E1D3")
        default: return Color(hex: "FF6B6B")
        }
    }
    
    private var exerciseIcon: String {
        switch exerciseType {
        case "cardio": return "heart.fill"
        case "calisthenics": return "figure.core.training"
        default: return "dumbbell.fill"
        }
    }
}

// MARK: - Convex Set Row
struct ConvexSetRow: View {
    let set: ConvexSet
    let setNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            // Set number with completion indicator
            ZStack {
                Circle()
                    .stroke(set.isCompleted == true ? Color.gymSuccess : Color.gymTextSecondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 28, height: 28)
                
                if set.isCompleted == true {
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
            
            // Set details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let weight = set.weight, weight > 0 {
                        Text("\(Int(weight)) lbs")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gymText)
                        
                        Text("×")
                            .foregroundColor(.gymTextSecondary)
                    }
                    
                    if let reps = set.reps, reps > 0 {
                        Text("\(reps) reps")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gymText)
                    }
                    
                    if set.exerciseType == "cardio", let duration = set.duration, duration > 0 {
                        Text(formatDuration(duration))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gymText)
                    }
                }
                
                // Work time if present
                if let workTime = set.workTime, workTime > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text(formatWorkTime(workTime))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.gymTextSecondary)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.gymError.opacity(0.7))
            }
        }
        .padding(.vertical, GymTheme.Spacing.xs)
    }
    
    private func formatWorkTime(_ time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%d:%02d:%02d", hours, mins, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    HomeView()
}
