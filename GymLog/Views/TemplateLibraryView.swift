import SwiftUI
import SwiftData

struct TemplateLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.lastUsed, order: .reverse) private var allTemplates: [WorkoutTemplate]

    @State private var searchText = ""
    @State private var selectedFilter: TemplateFilter = .all
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingEditor = false

    enum TemplateFilter: String, CaseIterable {
        case all = "All"
        case premade = "Pre-made"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .premade: return "star.fill"
            case .custom: return "person.fill"
            }
        }
    }

    var filteredTemplates: [WorkoutTemplate] {
        var filtered = allTemplates

        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .premade:
            filtered = filtered.filter { !$0.isCustom }
        case .custom:
            filtered = filtered.filter { $0.isCustom }
        }

        return filtered
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gymTextSecondary)

                        TextField("Search templates", text: $searchText)
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

                    // Filter Pills
                    HStack(spacing: GymTheme.Spacing.xs) {
                        ForEach(TemplateFilter.allCases, id: \.self) { filter in
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
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.vertical, GymTheme.Spacing.md)

                    // Templates Grid
                    if filteredTemplates.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "doc.text",
                            title: searchText.isEmpty ? "No templates yet" : "No results",
                            message: searchText.isEmpty
                                ? "Create your first custom template"
                                : "Try adjusting your search"
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: GymTheme.Spacing.md) {
                                ForEach(filteredTemplates) { template in
                                    TemplateCard(template: template) {
                                        selectedTemplate = template
                                    }
                                }
                            }
                            .padding(.horizontal, GymTheme.Spacing.md)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Workout Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gymPrimary)
                    }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
            .sheet(isPresented: $showingEditor) {
                TemplateEditorView(template: nil)
            }
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
                // Header
                HStack {
                    if !template.isCustom {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gymAccent)
                    }

                    Spacer()

                    Text(template.category)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gymTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gymSurface)
                        .clipShape(Capsule())
                }

                // Template Name
                Text(template.name)
                    .font(GymTheme.Typography.headline)
                    .foregroundColor(.gymText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Stats
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 10))
                        Text("\(template.templateExercises.count) exercises")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gymTextSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(formatDuration(template.estimatedDuration))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gymTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let lastUsed = template.lastUsed {
                    Text("Last used: \(lastUsed.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 10))
                        .foregroundColor(.gymTextSecondary.opacity(0.7))
                }
            }
            .padding(GymTheme.Spacing.md)
            .frame(height: 180)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) min"
    }
}

#Preview {
    TemplateLibraryView()
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
