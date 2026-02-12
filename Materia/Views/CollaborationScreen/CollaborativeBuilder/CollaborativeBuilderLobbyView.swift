import SwiftUI

struct CollaborativeBuilderLobbyView: View {
    @Environment(\.dismiss) private var dismiss

    // Keep one MPC manager for the sheet lifecycle.
    @StateObject private var mpc = MPCSessionManager(configuration: .init(serviceType: "materia-bldr"))
    @StateObject private var viewModel: CollaborativeBuilderViewModel

    @State private var isHost = true

    init() {
        let mpc = MPCSessionManager(configuration: .init(serviceType: "materia-bldr"))
        _mpc = StateObject(wrappedValue: mpc)
        _viewModel = StateObject(wrappedValue: CollaborativeBuilderViewModel(mpc: mpc))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Picker("Role", selection: $isHost) {
                    Text("Host (Builder A)").tag(true)
                    Text("Join (Builder B)").tag(false)
                }
                .pickerStyle(.segmented)
                .background(AppColors.accentLight)

                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let err = mpc.lastError {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if mpc.mode == .browsing {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nearby peers")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if mpc.foundPeers.isEmpty {
                            Text("Searching… Make sure the other device is hosting.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(mpc.foundPeers, id: \.self) { p in
                                HStack {
                                    Text(p.displayName)
                                    Spacer()
                                    Button("Invite") {
                                        mpc.invite(p)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                HStack(spacing: 12) {
                    Button(isHost ? "Start Hosting" : "Start Joining") {
                        if isHost {
                            viewModel.startHosting()
                        } else {
                            viewModel.startJoining()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accent)


                    Button("Connect") {
                        mpc.connectToFirstFoundPeer()
                    }
                    .buttonStyle(.bordered)
                    .disabled(mpc.foundPeers.isEmpty)

                    Button("Send Join") {
                        viewModel.sendJoin()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(AppColors.accent)
                }

                Divider()

                // Live view
                CollaborativeBuilderLiveView(viewModel: viewModel)

                Spacer()
            }
            .padding()
            .navigationTitle(AppStrings.pairMode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        mpc.shutdown()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                mpc.shutdown()
            }
        }
    }
}
