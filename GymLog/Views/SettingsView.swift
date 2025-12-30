import SwiftUI

struct SettingsView: View {
    @ObservedObject private var convex = ConvexAPI.shared
    @State private var apiKeyInput: String = ""
    @State private var showingSaveConfirmation = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var isTestingConnection = false
    
    enum ConnectionStatus {
        case unknown
        case testing
        case connected
        case failed(String)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GymTheme.Spacing.lg) {
                        // Convex Connection Section
                        convexSection
                        
                        // About Section
                        aboutSection
                    }
                    .padding(.horizontal, GymTheme.Spacing.md)
                    .padding(.bottom, GymTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                convex.loadApiKeyId()
                apiKeyInput = convex.apiKeyId ?? ""
            }
        }
    }
    
    // MARK: - Convex Section
    private var convexSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            Label("Cloud Sync", systemImage: "cloud.fill")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
                Text("API Key ID")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                
                HStack(spacing: GymTheme.Spacing.sm) {
                    TextField("Enter your Convex API Key ID", text: $apiKeyInput)
                        .font(GymTheme.Typography.body)
                        .foregroundColor(.gymText)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(GymTheme.Spacing.md)
                        .background(Color.gymSurface)
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                }
                
                // Connection status indicator
                connectionStatusView
                
                // Save button
                Button {
                    saveApiKey()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save API Key")
                    }
                    .font(GymTheme.Typography.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GymTheme.Spacing.md)
                    .background(
                        apiKeyInput.isEmpty ? Color.gymTextSecondary : Color.gymPrimary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                }
                .disabled(apiKeyInput.isEmpty)
                
                // Test connection button
                if convex.isAuthenticated {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gymSecondary))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wifi")
                            }
                            Text("Test Connection")
                        }
                        .font(GymTheme.Typography.subheadline)
                        .foregroundColor(.gymSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, GymTheme.Spacing.sm)
                        .background(Color.gymSecondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
                    }
                    .disabled(isTestingConnection)
                }
                
                // Help text
                Text("Get your API Key ID by running:\nnpx convex run apiKeys:createApiKey '{\"name\": \"My Device\"}'")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
                    .padding(.top, GymTheme.Spacing.xs)
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
    }
    
    // MARK: - Connection Status View
    @ViewBuilder
    private var connectionStatusView: some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            switch connectionStatus {
            case .unknown:
                if convex.isAuthenticated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gymSuccess)
                    Text("API Key saved")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymSuccess)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.gymWarning)
                    Text("No API Key configured")
                        .font(GymTheme.Typography.caption)
                        .foregroundColor(.gymWarning)
                }
            case .testing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gymSecondary))
                    .scaleEffect(0.7)
                Text("Testing connection...")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymTextSecondary)
            case .connected:
                Image(systemName: "wifi")
                    .foregroundColor(.gymSuccess)
                Text("Connected to Convex")
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymSuccess)
            case .failed(let error):
                Image(systemName: "wifi.slash")
                    .foregroundColor(.gymError)
                Text(error)
                    .font(GymTheme.Typography.caption)
                    .foregroundColor(.gymError)
            }
            
            Spacer()
        }
        .padding(.vertical, GymTheme.Spacing.xs)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: GymTheme.Spacing.md) {
            Label("About", systemImage: "info.circle.fill")
                .font(GymTheme.Typography.title3)
                .foregroundColor(.gymText)
            
            VStack(alignment: .leading, spacing: GymTheme.Spacing.sm) {
                HStack {
                    Text("Version")
                        .foregroundColor(.gymTextSecondary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gymText)
                }
                .font(GymTheme.Typography.body)
                
                Divider()
                    .background(Color.gymSurface)
                
                HStack {
                    Text("Backend")
                        .foregroundColor(.gymTextSecondary)
                    Spacer()
                    Text("Convex")
                        .foregroundColor(.gymText)
                }
                .font(GymTheme.Typography.body)
            }
            .padding(GymTheme.Spacing.md)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
        }
    }
    
    // MARK: - Actions
    private func saveApiKey() {
        let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        convex.setApiKeyId(trimmedKey)
        connectionStatus = .unknown
        showingSaveConfirmation = true
        
        // Auto-dismiss confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaveConfirmation = false
        }
    }
    
    private func testConnection() {
        connectionStatus = .testing
        isTestingConnection = true
        
        Task {
            do {
                let connected = try await convex.testConnection()
                await MainActor.run {
                    connectionStatus = connected ? .connected : .failed("Connection failed")
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failed(error.localizedDescription)
                    isTestingConnection = false
                }
            }
        }
    }
    
}

#Preview {
    SettingsView()
}
