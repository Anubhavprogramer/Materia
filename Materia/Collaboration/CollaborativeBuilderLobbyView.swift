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
                Text("Collaborative Builder")
                    .font(.title2)
                    .fontWeight(.semibold)

                Picker("Role", selection: $isHost) {
                    Text("Host (Builder A)").tag(true)
                    Text("Join (Builder B)").tag(false)
                }
                .pickerStyle(.segmented)

                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button(isHost ? "Start Hosting" : "Start Joining") {
                        if isHost {
                            viewModel.startHosting()
                        } else {
                            viewModel.startJoining()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Send Join") {
                        viewModel.sendJoin()
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                // Live view
                CollaborativeBuilderLiveView(viewModel: viewModel)

                Spacer()
            }
            .padding()
            .navigationTitle("Pair Mode")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
