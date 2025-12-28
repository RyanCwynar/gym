import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var syncService: ConvexSyncService
    @Environment(\.modelContext) private var modelContext
    
    @State private var convexUrl: String = ""
    @State private var apiKey: String = ""
    @State private var showingApiKeyInput = false
    @State private var isValidating = false
    @State private var validationMessage: String = ""
    @State private var showValidationAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Sync Status Section
                Section {
                    HStack {
                        Image(systemName: syncService.isOnline ? "wifi" : "wifi.slash")
                            .foregroundColor(syncService.isOnline ? .green : .red)
                        Text(syncService.isOnline ? "Online" : "Offline")
                        Spacer()
                    }
                    
                    if syncService.isSyncing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Syncing...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if syncService.pendingSyncCount > 0 {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("\(syncService.pendingSyncCount) items pending sync")
                        }
                    }
                    
                    if let lastSync = syncService.lastSyncDate {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Sync Status")
                }
                
                // API Key Section
                Section {
                    if syncService.isApiKeyValid {
                        // Valid key - show name and masked key
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(syncService.apiKeyName)
                                    .font(.headline)
                                Text(syncService.maskedApiKey)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontDesign(.monospaced)
                            }
                            Spacer()
                            Button("Change") {
                                showingApiKeyInput = true
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if syncService.hasApiKey {
                        // Has key but not validated
                        HStack {
                            if syncService.isValidatingApiKey {
                                ProgressView()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(syncService.isValidatingApiKey ? "Validating..." : "Key Not Validated")
                                    .font(.headline)
                                Text(syncService.maskedApiKey)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontDesign(.monospaced)
                            }
                            Spacer()
                            if !syncService.isValidatingApiKey {
                                Button("Validate") {
                                    Task {
                                        await syncService.validateApiKey()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        // Option to change key
                        Button {
                            showingApiKeyInput = true
                        } label: {
                            Label("Change API Key", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } else {
                        // No key saved
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter your API key to sync your workout data across devices.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button {
                                showingApiKeyInput = true
                            } label: {
                                Label("Add API Key", systemImage: "key.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("API Key")
                } footer: {
                    if syncService.isApiKeyValid {
                        Text("Connected and syncing to your account.")
                    } else if syncService.hasApiKey {
                        Text("Tap Validate to verify your API key with the server.")
                    } else {
                        Text("Your API key identifies your data on the server. Create one from the Convex dashboard.")
                    }
                }
                
                // Convex URL Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Convex URL", text: $convexUrl)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onAppear {
                                if let url = UserDefaults.standard.string(forKey: "convexUrl") {
                                    convexUrl = url
                                }
                            }
                        
                        Button("Save URL") {
                            syncService.setConvexUrl(convexUrl)
                        }
                        .buttonStyle(.bordered)
                        .disabled(convexUrl.isEmpty)
                    }
                } header: {
                    Text("Server Configuration")
                } footer: {
                    Text("Enter your Convex deployment URL (e.g., https://your-app.convex.cloud)")
                }
                
                // Manual Sync Section
                Section {
                    Button {
                        Task {
                            await syncService.syncIfNeeded(modelContext: modelContext)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                    }
                    .disabled(!syncService.isConfigured || syncService.isSyncing)
                } header: {
                    Text("Actions")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://convex.dev")!) {
                        HStack {
                            Text("Powered by Convex")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingApiKeyInput) {
                apiKeyInputSheet
            }
            .alert("API Key", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                // Auto-validate if we have a key but it's not validated yet
                if syncService.hasApiKey && !syncService.isApiKeyValid && !syncService.isValidatingApiKey {
                    Task {
                        await syncService.validateApiKey()
                    }
                }
            }
        }
    }
    
    private var apiKeyInputSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Enter API Key")
                } footer: {
                    Text("Paste your full API key here. It will be validated with the server.")
                }
                
                if isValidating {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Validating...")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        apiKey = ""
                        showingApiKeyInput = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveApiKey()
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func saveApiKey() {
        isValidating = true
        
        syncService.setApiKey(apiKey)
        
        // Wait a moment for validation
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                isValidating = false
                
                if syncService.isApiKeyValid {
                    validationMessage = "API key validated successfully! Connected as \(syncService.apiKeyName)."
                    apiKey = ""
                    showingApiKeyInput = false
                } else {
                    validationMessage = "API key validation failed. Please check your key and try again."
                }
                showValidationAlert = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConvexSyncService.shared)
}

