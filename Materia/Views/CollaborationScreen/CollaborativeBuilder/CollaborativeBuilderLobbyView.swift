import SwiftUI
import MultipeerConnectivity

struct CollaborativeBuilderLobbyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager

    @StateObject private var mpc = MPCSessionManager(configuration: .init(serviceType: "materia-bldr"))
    @StateObject private var viewModel: CollaborativeBuilderViewModel

    @State private var isHost = true
    @State private var isActive = false

    init() {
        let mpc = MPCSessionManager(configuration: .init(serviceType: "materia-bldr"))
        _mpc = StateObject(wrappedValue: mpc)
        _viewModel = StateObject(wrappedValue: CollaborativeBuilderViewModel(mpc: mpc))
    }

    var body: some View {
        NavigationStack {
            // Show builder view if connected
            if mpc.connectedPeers.count > 0 {
                CollaborativeBuilderLiveView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                stopAll()
                                dismiss()
                            }
                            .foregroundColor(AppColors.accent)
                        }
                    }
            } else {
                // Show connection lobby
                connectionLobbyView
            }
        }
        .onDisappear {
            stopAll()
        }
    }
    
    private var connectionLobbyView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.gradientStart.opacity(0.1),
                    AppColors.gradientEnd.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect & Build")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Collaborate on molecular structures in real-time")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppConstants.defaultPadding)
                .padding(.vertical, AppConstants.defaultPadding)
                
                ScrollView {
                    VStack(spacing: AppConstants.defaultPadding) {
                        // Step 1: Choose Role
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "1.circle.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.accent)
                                
                                Text("Select Your Role")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            // Two button options
                            HStack(spacing: 12) {
                                Button(action: { isHost = true; resetState() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill.badge.plus")
                                        Text("Host")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(isHost ? AppColors.accent : Color(.systemGray6))
                                    .foregroundColor(isHost ? AppColors.white : AppColors.textPrimary)
                                    .cornerRadius(AppConstants.defaultCornerRadius)
                                }
                                
                                Button(action: { isHost = false; resetState() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill.checkmark")
                                        Text("Join")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(!isHost ? AppColors.accent : Color(.systemGray6))
                                    .foregroundColor(!isHost ? AppColors.white : AppColors.textPrimary)
                                    .cornerRadius(AppConstants.defaultCornerRadius)
                                }
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.Card)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal, AppConstants.defaultPadding)
                        
                        // Step 2: Start/Stop Action
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "2.circle.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.accent)
                                
                                Text(isHost ? "Host a Session" : "Find a Session")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Button(action: toggleActive) {
                                HStack {
                                    Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16))
                                    
                                    Text(isActive ? (isHost ? "Stop Hosting" : "Stop Searching") : (isHost ? "Start Hosting" : "Start Searching"))
                                        .fontWeight(.semibold)
                                }
                            }
                            .liquidGlassButton(
                                color: isActive ? .red : AppColors.accent,
                                size: .regular,
                                isEnabled: true
                            )
                            
                            InfoCardView(
                                icon: isHost ? "wifi.router" : "magnifyingglass",
                                title: isHost ? "Hosting Ready" : "Searching Ready",
                                message: isHost
                                    ? "Tap 'Start Hosting' to broadcast your session"
                                    : "Tap 'Start Searching' to find nearby sessions",
                                accentColor: AppColors.accent,
                                backgroundColor: AppColors.accent.opacity(0.1),
                                borderColor: AppColors.accent.opacity(0.3)
                            )
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.Card)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal, AppConstants.defaultPadding)
                        
                        // Step 3: Connection Status (Join mode only)
                        if !isHost && isActive {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "3.circle.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppColors.accent)
                                    
                                    Text("Available Hosts")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                
                                if mpc.foundPeers.isEmpty {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .tint(AppColors.accent)
                                        
                                        Text("Searching for sessions...")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(AppConstants.defaultPadding)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(AppConstants.defaultCornerRadius)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(mpc.foundPeers, id: \.self) { peer in
                                            Button(action: { connectToPeer(peer) }) {
                                                HStack(spacing: 12) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(peer.displayName)
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(AppColors.textPrimary)
                                                        
                                                        Text("Tap to connect")
                                                            .font(.caption)
                                                            .foregroundColor(AppColors.textSecondary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "arrow.right.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(AppColors.accent)
                                                }
                                                .padding(AppConstants.defaultPadding)
                                                .background(AppColors.accent.opacity(0.1))
                                                .cornerRadius(AppConstants.defaultCornerRadius)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(AppConstants.defaultPadding)
                            .background(AppColors.Card)
                            .cornerRadius(AppConstants.defaultCornerRadius)
                            .padding(.horizontal, AppConstants.defaultPadding)
                        }
                        
                        // Status Display
                        if !viewModel.statusText.isEmpty {
                            InfoCardView(
                                icon: "info.circle.fill",
                                title: "Status",
                                message: viewModel.statusText,
                                accentColor: AppColors.primary,
                                backgroundColor: AppColors.primary.opacity(0.1),
                                borderColor: AppColors.primary.opacity(0.3)
                            )
                            .padding(.horizontal, AppConstants.defaultPadding)
                        }
                        
                        if let error = mpc.lastError {
                            InfoCardView(
                                icon: "exclamationmark.circle.fill",
                                title: "Error",
                                message: error,
                                accentColor: .red,
                                backgroundColor: .red.opacity(0.1),
                                borderColor: .red.opacity(0.3)
                            )
                            .padding(.horizontal, AppConstants.defaultPadding)
                        }
                        
                        Spacer()
                            .frame(height: AppConstants.largePadding)
                    }
                    .padding(.vertical, AppConstants.defaultPadding)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    stopAll()
                    dismiss()
                }
                .foregroundColor(AppColors.accent)
            }
        }
    }
    
    private func toggleActive() {
        if isActive {
            stopAll()
        } else {
            startSession()
        }
    }
    
    private func startSession() {
        isActive = true
        if isHost {
            viewModel.startHosting()
            toastManager.show("Now hosting a session", type: .success)
        } else {
            viewModel.startJoining()
            toastManager.show("Searching for sessions", type: .info)
        }
    }
    
    private func stopAll() {
        isActive = false
        mpc.shutdown()
        let action = isHost ? "Hosting stopped" : "Search stopped"
        toastManager.show(action, type: .info)
    }
    
    private func connectToPeer(_ peer: MCPeerID) {
        // Set joiner as Builder B before inviting
        viewModel.setRole(.builderB)
        mpc.invite(peer)
        toastManager.show("Connecting to \(peer.displayName) as Builder B...", type: .success)
    }
    
    private func resetState() {
        if isActive {
            stopAll()
        }
    }
}

