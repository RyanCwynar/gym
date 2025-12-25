import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingNewWorkout = false
    @State private var activeWorkout: Workout?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Active Workout Banner (if exists)
                        if let active = workouts.first(where: { !$0.isCompleted }) {
                            activeWorkoutBanner(active)
                        }
                        
                        // Quick Start Section
                        quickStartSection
                        
                        // Recent Workouts
                        recentWorkoutsSection
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewWorkout) {
                WorkoutView(workout: createNewWorkout())
            }
            .sheet(item: $activeWorkout) { workout in
                WorkoutView(workout: workout)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                
                Text("Let's crush it! 💪")
                    .font(GymTheme.Typography.largeTitle)
                    .foregroundColor(.gymText)
            }
            
            Spacer()
            
            // Streak indicator
            VStack(spacing: 2) {
                Text("🔥")
                    .font(.system(size: 24))
                Text("\(currentStreak)")
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymPrimary)
            }
            .padding(12)
            .background(Color.gymSurfaceElevated)
            .clipShape(Circle())
        }
        .padding(.top, GymTheme.Spacing.lg)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: GymTheme.Spacing.sm) {
            StatCard(
                title: "This Week",
                value: "\(workoutsThisWeek)",
                icon: "calendar",
                color: .gymPrimary
            )
            
            StatCard(
                title: "Total Volume",
                value: formattedTotalVolume,
                icon: "scalemass.fill",
                color: .gymSecondary
            )
            
            StatCard(
                title: "Total Workouts",
                value: "\(workouts.filter { $0.isCompleted }.count)",
                icon: "figure.strengthtraining.traditional",
                color: .gymAccent
            )
            
            StatCard(
                title: "This Month",
                value: "\(workoutsThisMonth)",
                icon: "chart.bar.fill",
                color: .gymSuccess
            )
        }
    }
    
    // MARK: - Active Workout Banner
    private func activeWorkoutBanner(_ workout: Workout) -> some View {
        Button {
            activeWorkout = workout
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.gymSuccess)
                            .frame(width: 8, height: 8)
                        Text("WORKOUT IN PROGRESS")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymSuccess)
                    }
                    
                    Text(workout.name)
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                    
                    Text("\(workout.exercises.count) exercises • \(workout.totalSets) sets")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gymPrimary)
            }
            .padding(GymTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: GymTheme.Radius.large)
                    .fill(Color.gymSurfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: GymTheme.Radius.large)
                            .stroke(Color.gymSuccess.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Quick Start")
            
            Button {
                showingNewWorkout = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Empty Workout")
                            .font(GymTheme.Typography.headline)
                            .foregroundColor(.gymText)
                        
                        Text("Begin a new workout from scratch")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(.gymTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FF6B35"), Color(hex: "FF8C5A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(GymTheme.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1F1F32"), Color(hex: "2D2D44")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Recent Workouts", actionTitle: "See All") {
                // Navigate to history
            }
            
            if workouts.isEmpty {
                EmptyStateView(
                    icon: "dumbbell.fill",
                    title: "No workouts yet",
                    message: "Start your fitness journey by logging your first workout!"
                )
            } else {
                ForEach(workouts.prefix(5)) { workout in
                    WorkoutCard(workout: workout) {
                        activeWorkout = workout
                    }
                }
            }
        }
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
    
    private var currentStreak: Int {
        // Calculate workout streak
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        while true {
            let hasWorkout = workouts.contains { workout in
                Calendar.current.isDate(workout.date, inSameDayAs: currentDate) && workout.isCompleted
            }
            
            if hasWorkout {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if streak == 0 {
                // Check yesterday if no workout today
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                let hadYesterday = workouts.contains { workout in
                    Calendar.current.isDate(workout.date, inSameDayAs: currentDate) && workout.isCompleted
                }
                if !hadYesterday {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var workoutsThisWeek: Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return workouts.filter { $0.date >= startOfWeek && $0.isCompleted }.count
    }
    
    private var workoutsThisMonth: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        return workouts.filter { $0.date >= startOfMonth && $0.isCompleted }.count
    }
    
    private var formattedTotalVolume: String {
        let totalVolume = workouts.filter { $0.isCompleted }.reduce(0) { $0 + $1.totalVolume }
        if totalVolume >= 1000000 {
            return String(format: "%.1fM", totalVolume / 1000000)
        } else if totalVolume >= 1000 {
            return String(format: "%.1fK", totalVolume / 1000)
        }
        return String(format: "%.0f", totalVolume)
    }
    
    private func createNewWorkout() -> Workout {
        let workout = Workout(name: "Workout")
        modelContext.insert(workout)
        return workout
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}

