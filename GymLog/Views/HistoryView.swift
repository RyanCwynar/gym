import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var selectedWorkout: Workout?
    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .thisWeek: return "calendar"
            case .thisMonth: return "calendar.badge.clock"
            }
        }
    }
    
    // Filter workouts that have exercises (exclude today - today is shown on Home)
    var filteredWorkouts: [Workout] {
        let calendar = Calendar.current
        var filtered = workouts.filter { 
            !$0.exercises.isEmpty && !calendar.isDateInToday($0.date)
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.exercises.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply time filter
        switch selectedFilter {
        case .all:
            break
        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
            filtered = filtered.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
            filtered = filtered.filter { $0.date >= startOfMonth }
        }
        
        return filtered
    }
    
    var groupedByDay: [(String, [Workout])] {
        let calendar = Calendar.current
        var groups: [String: [Workout]] = [:]
        
        for workout in filteredWorkouts {
            let key: String
            if calendar.isDateInYesterday(workout.date) {
                key = "Yesterday"
            } else if calendar.isDate(workout.date, equalTo: Date(), toGranularity: .weekOfYear) {
                key = "This Week"
            } else if calendar.isDate(workout.date, equalTo: Date(), toGranularity: .month) {
                key = "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                key = formatter.string(from: workout.date)
            }
            
            groups[key, default: []].append(workout)
        }
        
        // Sort groups by most recent first
        let order = ["Yesterday", "This Week", "This Month"]
        return groups.sorted { first, second in
            let firstIndex = order.firstIndex(of: first.key) ?? Int.max
            let secondIndex = order.firstIndex(of: second.key) ?? Int.max
            
            if firstIndex != Int.max || secondIndex != Int.max {
                return firstIndex < secondIndex
            }
            
            return first.value.first?.date ?? Date() > second.value.first?.date ?? Date()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter
                    VStack(spacing: GymTheme.Spacing.sm) {
                        // Search Bar
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
                        
                        // Filter Pills
                        HStack(spacing: GymTheme.Spacing.xs) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: filter.icon)
                                            .font(.system(size: 12))
                                        Text(filter.rawValue)
                                            .font(GymTheme.Typography.footnote)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.gymPrimary : Color.gymSurfaceElevated)
                                    .foregroundColor(selectedFilter == filter ? .black : .gymText)
                                    .clipShape(Capsule())
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.top, GymTheme.Spacing.md)
                    
                    // Content
                    if filteredWorkouts.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "clock.fill",
                            title: searchText.isEmpty ? "No activity yet" : "No results",
                            message: searchText.isEmpty 
                                ? "Log your first exercise to see it here"
                                : "Try adjusting your search or filters"
                        )
                        Spacer()
                    } else {
                        // Stats Summary
                        statsSummary
                        
                        // Activity List by Day
                        ScrollView {
                            LazyVStack(spacing: GymTheme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                                ForEach(groupedByDay, id: \.0) { group, days in
                                    Section {
                                        ForEach(days) { workout in
                                            DayActivityCard(workout: workout) {
                                                selectedWorkout = workout
                                            }
                                        }
                                    } header: {
                                        HStack {
                                            Text(group)
                                                .font(GymTheme.Typography.subheadline)
                                                .foregroundColor(.gymTextSecondary)
                                            Spacer()
                                            Text("\(days.count) day\(days.count == 1 ? "" : "s")")
                                                .font(GymTheme.Typography.caption)
                                                .foregroundColor(.gymTextSecondary.opacity(0.7))
                                        }
                                        .padding(.vertical, GymTheme.Spacing.xs)
                                        .padding(.horizontal, GymTheme.Spacing.md)
                                        .background(Color.gymBackground)
                                    }
                                }
                            }
                            .padding(.horizontal, GymTheme.Spacing.md)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedWorkout) { workout in
                DayDetailView(workout: workout)
            }
        }
    }
    
    // MARK: - Stats Summary
    private var statsSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GymTheme.Spacing.sm) {
                MiniStatCard(
                    value: "\(filteredWorkouts.count)",
                    label: "Days",
                    color: .gymPrimary
                )
                
                MiniStatCard(
                    value: formatTotalWorkTime,
                    label: "Work Time",
                    color: .gymSecondary
                )
                
                MiniStatCard(
                    value: formatTotalVolume,
                    label: "Volume",
                    color: .gymAccent
                )
                
                MiniStatCard(
                    value: "\(totalExercises)",
                    label: "Exercises",
                    color: .gymSuccess
                )
            }
            .padding(.horizontal, GymTheme.Spacing.md)
            .padding(.vertical, GymTheme.Spacing.sm)
        }
    }
    
    private var formatTotalWorkTime: String {
        let totalSeconds = filteredWorkouts.reduce(0) { $0 + $1.savedWorkTime }
        let hours = Int(totalSeconds) / 3600
        if hours > 0 {
            return "\(hours)h"
        }
        let minutes = Int(totalSeconds) / 60
        return "\(minutes)m"
    }
    
    private var formatTotalVolume: String {
        let total = filteredWorkouts.reduce(0) { $0 + $1.totalVolume }
        if total >= 1000000 {
            return String(format: "%.1fM", total / 1000000)
        } else if total >= 1000 {
            return String(format: "%.0fK", total / 1000)
        }
        return String(format: "%.0f", total)
    }
    
    private var totalExercises: Int {
        filteredWorkouts.reduce(0) { $0 + $1.exercises.count }
    }
}

// MARK: - Mini Stat Card
struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(GymTheme.Typography.headline)
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gymTextSecondary)
        }
        .padding(.horizontal, GymTheme.Spacing.md)
        .padding(.vertical, GymTheme.Spacing.sm)
        .background(Color.gymSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
