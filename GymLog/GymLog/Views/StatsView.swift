import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var filteredWorkouts: [Workout] {
        let completed = workouts.filter { $0.isCompleted }
        
        switch selectedTimeRange {
        case .week:
            let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
            return completed.filter { $0.date >= startOfWeek }
        case .month:
            let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
            return completed.filter { $0.date >= startOfMonth }
        case .year:
            let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date())) ?? Date()
            return completed.filter { $0.date >= startOfYear }
        case .all:
            return completed
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Time Range Picker
                        timeRangePicker
                        
                        // Overview Stats
                        overviewSection
                        
                        // Activity Chart
                        activitySection
                        
                        // Muscle Group Breakdown
                        muscleGroupSection
                        
                        // Personal Records
                        personalRecordsSection
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        HStack(spacing: GymTheme.Spacing.xs) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(GymTheme.Typography.footnote)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedTimeRange == range ? Color.gymPrimary : Color.gymSurfaceElevated)
                        .foregroundColor(selectedTimeRange == range ? .black : .gymText)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, GymTheme.Spacing.md)
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Overview")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: GymTheme.Spacing.sm) {
                BigStatCard(
                    value: "\(filteredWorkouts.count)",
                    label: "Workouts",
                    icon: "figure.strengthtraining.traditional",
                    color: .gymPrimary
                )
                
                BigStatCard(
                    value: formatDuration(totalDuration),
                    label: "Total Time",
                    icon: "clock.fill",
                    color: .gymSecondary
                )
                
                BigStatCard(
                    value: formatVolume(totalVolume),
                    label: "Total Volume",
                    icon: "scalemass.fill",
                    color: .gymAccent
                )
                
                BigStatCard(
                    value: "\(totalSets)",
                    label: "Total Sets",
                    icon: "square.stack.fill",
                    color: .gymSuccess
                )
            }
        }
    }
    
    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Activity")
            
            VStack(spacing: GymTheme.Spacing.sm) {
                // Simple bar chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(activityData, id: \.day) { data in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(data.count > 0 ? Color.gymPrimary : Color.gymSurfaceElevated)
                                .frame(width: 36, height: max(4, CGFloat(data.count) * 40))
                            
                            Text(data.day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gymTextSecondary)
                        }
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .padding(GymTheme.Spacing.md)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
                
                // Average stats
                HStack(spacing: GymTheme.Spacing.md) {
                    AverageStatPill(
                        label: "Avg Duration",
                        value: formatDuration(averageDuration)
                    )
                    
                    AverageStatPill(
                        label: "Avg Exercises",
                        value: String(format: "%.1f", averageExercises)
                    )
                    
                    AverageStatPill(
                        label: "Avg Sets",
                        value: String(format: "%.0f", averageSets)
                    )
                }
            }
        }
    }
    
    // MARK: - Muscle Group Section
    private var muscleGroupSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Muscle Groups")
            
            if muscleGroupBreakdown.isEmpty {
                Text("Complete workouts to see muscle group breakdown")
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(GymTheme.Spacing.lg)
                    .background(Color.gymSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
            } else {
                VStack(spacing: GymTheme.Spacing.xs) {
                    ForEach(muscleGroupBreakdown.prefix(6), id: \.group) { item in
                        MuscleGroupProgressRow(
                            group: item.group,
                            count: item.count,
                            maxCount: muscleGroupBreakdown.first?.count ?? 1
                        )
                    }
                }
                .padding(GymTheme.Spacing.md)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
            }
        }
    }
    
    // MARK: - Personal Records Section
    private var personalRecordsSection: some View {
        VStack(spacing: GymTheme.Spacing.md) {
            SectionHeader(title: "Personal Records")
            
            if personalRecords.isEmpty {
                Text("Complete workouts to track personal records")
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(GymTheme.Spacing.lg)
                    .background(Color.gymSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
            } else {
                LazyVStack(spacing: GymTheme.Spacing.xs) {
                    ForEach(personalRecords.prefix(5), id: \.exercise) { record in
                        PRRow(record: record)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalDuration: TimeInterval {
        filteredWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    private var totalVolume: Double {
        filteredWorkouts.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var totalSets: Int {
        filteredWorkouts.reduce(0) { $0 + $1.totalSets }
    }
    
    private var averageDuration: TimeInterval {
        guard !filteredWorkouts.isEmpty else { return 0 }
        return totalDuration / Double(filteredWorkouts.count)
    }
    
    private var averageExercises: Double {
        guard !filteredWorkouts.isEmpty else { return 0 }
        return Double(filteredWorkouts.reduce(0) { $0 + $1.exercises.count }) / Double(filteredWorkouts.count)
    }
    
    private var averageSets: Double {
        guard !filteredWorkouts.isEmpty else { return 0 }
        return Double(totalSets) / Double(filteredWorkouts.count)
    }
    
    private var activityData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -6 + offset, to: Date()) ?? Date()
            let dayIndex = calendar.component(.weekday, from: date) - 1
            let count = filteredWorkouts.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            return (days[dayIndex], count)
        }
    }
    
    private var muscleGroupBreakdown: [(group: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for workout in filteredWorkouts {
            for exercise in workout.exercises {
                counts[exercise.muscleGroup, default: 0] += 1
            }
        }
        
        return counts.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }
    
    private var personalRecords: [(exercise: String, weight: Double, reps: Int, date: Date)] {
        var records: [String: (weight: Double, reps: Int, date: Date)] = [:]
        
        for workout in workouts.filter({ $0.isCompleted }) {
            for exercise in workout.exercises {
                for set in exercise.sets where set.isCompleted {
                    let volume = set.weight * Double(set.reps)
                    if let existing = records[exercise.name] {
                        let existingVolume = existing.weight * Double(existing.reps)
                        if volume > existingVolume {
                            records[exercise.name] = (set.weight, set.reps, workout.date)
                        }
                    } else {
                        records[exercise.name] = (set.weight, set.reps, workout.date)
                    }
                }
            }
        }
        
        return records.map { ($0.key, $0.value.weight, $0.value.reps, $0.value.date) }
            .sorted { ($0.weight * Double($0.reps)) > ($1.weight * Double($1.reps)) }
    }
    
    // MARK: - Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000000 {
            return String(format: "%.1fM", volume / 1000000)
        } else if volume >= 1000 {
            return String(format: "%.0fK", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Big Stat Card
struct BigStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(GymTheme.Typography.title1)
                .foregroundColor(.gymText)
            
            Text(label)
                .font(GymTheme.Typography.caption)
                .foregroundColor(.gymTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
}

// MARK: - Average Stat Pill
struct AverageStatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(GymTheme.Typography.headline)
                .foregroundColor(.gymText)
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gymTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GymTheme.Spacing.sm)
        .background(Color.gymSurface)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

// MARK: - Muscle Group Progress Row
struct MuscleGroupProgressRow: View {
    let group: String
    let count: Int
    let maxCount: Int
    
    var progress: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
    
    var body: some View {
        HStack(spacing: GymTheme.Spacing.md) {
            Text(group)
                .font(GymTheme.Typography.subheadline)
                .foregroundColor(.gymText)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gymSurface)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gymPrimary)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            
            Text("\(count)")
                .font(GymTheme.Typography.footnote)
                .foregroundColor(.gymTextSecondary)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.vertical, GymTheme.Spacing.xs)
    }
}

// MARK: - PR Row
struct PRRow: View {
    let record: (exercise: String, weight: Double, reps: Int, date: Date)
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gymAccent)
                
                Text("\(String(format: "%.0f", record.weight)) × \(record.reps)")
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymPrimary)
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}

