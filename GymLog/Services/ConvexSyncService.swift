import Foundation
import SwiftData
import Network

// MARK: - Convex Sync Service
/// Handles offline-first sync with Convex backend
@MainActor
class ConvexSyncService: ObservableObject {
    static let shared = ConvexSyncService()
    
    // Convex deployment URL - set this after running `npx convex dev`
    private var convexUrl: String {
        UserDefaults.standard.string(forKey: "convexUrl") ?? ""
    }
    
    // API key for identifying this user/device
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var pendingSyncCount = 0
    @Published var isOnline = true
    @Published var isApiKeyValid = false
    @Published var isValidatingApiKey = false
    @Published var apiKeyName: String = ""
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    /// Check if an API key is saved (even if not yet validated)
    var hasApiKey: Bool {
        !apiKey.isEmpty
    }
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                
                // Auto-sync when coming online
                if path.status == .satisfied {
                    // Small delay to let network stabilize
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await self?.syncIfNeeded()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Sync Methods
    
    /// Validate the current API key with the server
    func validateApiKey() async {
        guard !convexUrl.isEmpty, !apiKey.isEmpty else {
            isApiKeyValid = false
            apiKeyName = ""
            return
        }
        
        isValidatingApiKey = true
        defer { isValidatingApiKey = false }
        
        do {
            let result = try await callMutation(
                path: "apiKeys:validateKey",
                args: ["key": apiKey]
            )
            
            if let valid = result["valid"] as? Bool, valid {
                isApiKeyValid = true
                apiKeyName = result["name"] as? String ?? ""
                print("ConvexSyncService: API key validated - \(apiKeyName)")
            } else {
                isApiKeyValid = false
                apiKeyName = ""
                let error = result["error"] as? String ?? "Unknown error"
                print("ConvexSyncService: API key invalid - \(error)")
            }
        } catch {
            print("ConvexSyncService: API key validation failed - \(error)")
            isApiKeyValid = false
            apiKeyName = ""
        }
    }
    
    /// Check if there are items to sync and sync them
    func syncIfNeeded(modelContext: ModelContext? = nil) async {
        guard !convexUrl.isEmpty else {
            print("ConvexSyncService: No Convex URL configured")
            return
        }
        
        guard !apiKey.isEmpty else {
            print("ConvexSyncService: No API key configured")
            return
        }
        
        guard isOnline else {
            print("ConvexSyncService: Offline, skipping sync")
            return
        }
        
        guard !isSyncing else {
            print("ConvexSyncService: Already syncing")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // We need a model context - if not provided, we can't sync
            guard let context = modelContext else {
                print("ConvexSyncService: No model context provided")
                return
            }
            
            // Get items that need sync
            let logsToSync = try await getUnsyncedLogs(context: context)
            
            if logsToSync.isEmpty {
                print("ConvexSyncService: Nothing to sync")
                pendingSyncCount = 0
                return
            }
            
            pendingSyncCount = logsToSync.count
            print("ConvexSyncService: Syncing \(logsToSync.count) items")
            
            // Send to Convex
            let success = try await sendToConvex(logs: logsToSync)
            
            if success {
                // Mark as synced
                try await markAsSynced(logs: logsToSync, context: context)
                lastSyncDate = Date()
                pendingSyncCount = 0
                print("ConvexSyncService: Sync completed successfully")
            }
        } catch {
            print("ConvexSyncService: Sync failed - \(error)")
        }
    }
    
    /// Get all exercise sets and cardio exercises that need syncing
    private func getUnsyncedLogs(context: ModelContext) async throws -> [ExerciseLogDTO] {
        var logs: [ExerciseLogDTO] = []
        
        // Fetch sets that need sync
        let setDescriptor = FetchDescriptor<ExerciseSet>(
            predicate: #Predicate { $0.needsSync == true }
        )
        let unsyncedSets = try context.fetch(setDescriptor)
        
        for set in unsyncedSets {
            guard let exercise = set.exercise else { continue }
            
            logs.append(ExerciseLogDTO(
                clientId: set.id.uuidString,
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                exerciseType: "strength",
                reps: set.reps,
                weight: set.weight,
                setNumber: set.order + 1,
                duration: nil,
                workTime: set.workTime,
                performedAt: set.performedAt.timeIntervalSince1970,
                isCompleted: set.isCompleted
            ))
        }
        
        // Fetch cardio exercises that need sync
        let exerciseDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.needsSync == true && $0.muscleGroup == "Cardio" }
        )
        let unsyncedExercises = try context.fetch(exerciseDescriptor)
        
        for exercise in unsyncedExercises {
            logs.append(ExerciseLogDTO(
                clientId: exercise.id.uuidString,
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                exerciseType: "cardio",
                reps: nil,
                weight: nil,
                setNumber: nil,
                duration: exercise.duration,
                workTime: exercise.duration,
                performedAt: exercise.performedAt.timeIntervalSince1970,
                isCompleted: exercise.isCompleted
            ))
        }
        
        return logs
    }
    
    /// Generic Convex function call (works for queries and mutations)
    private func callMutation(path: String, args: [String: Any]) async throws -> [String: Any] {
        // Convert path from "module:function" to URL path "module/function"
        let urlPath = path.replacingOccurrences(of: ":", with: "/")
        guard let url = URL(string: "\(convexUrl)/api/run/\(urlPath)") else {
            throw SyncError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convex HTTP API expects args directly in the body
        request.httpBody = try JSONSerialization.data(withJSONObject: args)
        
        print("ConvexSyncService: Calling \(path) at \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No data"
        print("ConvexSyncService: Response (\(httpResponse.statusCode)): \(responseString)")
        
        guard httpResponse.statusCode == 200 else {
            throw SyncError.serverError(statusCode: httpResponse.statusCode, message: responseString)
        }
        
        // Convex HTTP API returns the result directly as JSON
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        
        return [:]
    }
    
    /// Send logs to Convex via HTTP mutation
    private func sendToConvex(logs: [ExerciseLogDTO]) async throws -> Bool {
        guard let url = URL(string: "\(convexUrl)/api/run/exerciseLogs/syncLogs") else {
            throw SyncError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convex HTTP API expects args directly in body
        let body = SyncArgs(apiKey: apiKey, logs: logs)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("ConvexSyncService: Syncing \(logs.count) logs to \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No data"
        print("ConvexSyncService: Sync response (\(httpResponse.statusCode)): \(responseString)")
        
        if httpResponse.statusCode == 200 {
            // Check if the response indicates success
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool {
                return success
            }
            return true
        } else {
            print("ConvexSyncService: Server error - \(responseString)")
            throw SyncError.serverError(statusCode: httpResponse.statusCode, message: responseString)
        }
    }
    
    /// Mark logs as synced in local database
    private func markAsSynced(logs: [ExerciseLogDTO], context: ModelContext) async throws {
        let now = Date()
        
        for log in logs {
            guard let uuid = UUID(uuidString: log.clientId) else { continue }
            
            if log.exerciseType == "strength" {
                // Find and update the set
                let descriptor = FetchDescriptor<ExerciseSet>(
                    predicate: #Predicate { $0.id == uuid }
                )
                if let set = try context.fetch(descriptor).first {
                    set.needsSync = false
                    set.lastSyncedAt = now
                }
            } else {
                // Find and update the exercise
                let descriptor = FetchDescriptor<Exercise>(
                    predicate: #Predicate { $0.id == uuid }
                )
                if let exercise = try context.fetch(descriptor).first {
                    exercise.needsSync = false
                    exercise.lastSyncedAt = now
                }
            }
        }
        
        try context.save()
    }
    
    // MARK: - Configuration
    
    /// Set the Convex deployment URL
    func setConvexUrl(_ url: String) {
        UserDefaults.standard.set(url, forKey: "convexUrl")
    }
    
    /// Set the API key
    func setApiKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "apiKey")
        // Validate the key after setting
        Task {
            await validateApiKey()
        }
    }
    
    /// Get the current API key (for display, masked)
    var maskedApiKey: String {
        guard !apiKey.isEmpty else { return "" }
        let key = apiKey
        if key.count > 12 {
            return "\(key.prefix(8))...\(key.suffix(4))"
        }
        return key
    }
    
    /// Get the full API key (use carefully)
    var currentApiKey: String {
        apiKey
    }
    
    /// Clear the API key
    func clearApiKey() {
        UserDefaults.standard.removeObject(forKey: "apiKey")
        isApiKeyValid = false
        apiKeyName = ""
    }
    
    /// Check if Convex is configured
    var isConfigured: Bool {
        !convexUrl.isEmpty && !apiKey.isEmpty
    }
    
    /// Check if only URL is configured (no API key yet)
    var isUrlConfigured: Bool {
        !convexUrl.isEmpty
    }
}

// MARK: - Data Transfer Objects

struct ExerciseLogDTO: Codable {
    let clientId: String
    let exerciseName: String
    let muscleGroup: String
    let exerciseType: String
    let reps: Int?
    let weight: Double?
    let setNumber: Int?
    let duration: TimeInterval?
    let workTime: TimeInterval?
    let performedAt: TimeInterval
    let isCompleted: Bool
}

struct SyncArgs: Codable {
    let apiKey: String
    let logs: [ExerciseLogDTO]
}

struct ConvexSyncRequest: Codable {
    let path: String
    let args: SyncArgs
}

// MARK: - Errors

enum SyncError: Error {
    case invalidUrl
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case noData
}

