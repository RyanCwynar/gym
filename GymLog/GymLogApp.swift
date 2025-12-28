import SwiftUI
import SwiftData

@main
struct GymLogApp: App {
    @StateObject private var syncService = ConvexSyncService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            ExerciseHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If schema migration fails, delete old store and create fresh
            print("Failed to create ModelContainer, attempting to recover: \(error)")
            
            // Get the default store URL and delete it
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            // Also remove the write-ahead log and shared memory files
            let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            try? FileManager.default.removeItem(at: walURL)
            try? FileManager.default.removeItem(at: shmURL)
            
            // Try again with fresh database
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after recovery attempt: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncService)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Sync when app becomes active
                        Task {
                            await syncService.syncIfNeeded(
                                modelContext: sharedModelContainer.mainContext
                            )
                        }
                    }
                }
                .onAppear {
                    // Initial sync on launch
                    Task {
                        await syncService.syncIfNeeded(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

