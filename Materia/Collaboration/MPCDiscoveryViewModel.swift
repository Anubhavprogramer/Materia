import Foundation
import MultipeerConnectivity

/// Simple peer discovery helper for browsing UI.
@MainActor
final class MPCDiscoveryViewModel: NSObject, ObservableObject {

    @Published private(set) var foundPeers: [MCPeerID] = []

    private let mpc: MPCSessionManager

    init(mpc: MPCSessionManager) {
        self.mpc = mpc
        super.init()
    }

    func attachBrowserDelegate() {
        // NOTE: In this MVP, MPCSessionManager keeps its own browser delegate.
        // For a production browser UI, MPCSessionManager should surface found/lost peers.
        // This file exists as a placeholder for the next step.
    }
}
