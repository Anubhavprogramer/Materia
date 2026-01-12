import Foundation
import MultipeerConnectivity

/// A small wrapper around MCSession + advertiser + browser.
/// - Uses encryptionRequired to ensure peer session encryption.
/// - Exposes received data on the main thread.
@MainActor
final class MPCSessionManager: NSObject, ObservableObject {

    struct Configuration: Sendable {
        let serviceType: String
        let myDisplayName: String

        init(serviceType: String, myDisplayName: String = UIDevice.current.name) {
            self.serviceType = serviceType
            self.myDisplayName = myDisplayName
        }
    }

    enum Mode {
        case idle
        case advertising
        case browsing
        case connected
    }

    // MARK: Published state
    @Published private(set) var mode: Mode = .idle
    @Published private(set) var connectedPeers: [MCPeerID] = []
    @Published private(set) var foundPeers: [MCPeerID] = []
    @Published var lastError: String?

    // MARK: MPC primitives
    private let peerID: MCPeerID
    private let serviceType: String
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Prevent double-stop and teardown races during view dismissal.
    private var isStopping = false

    // Callbacks
    var onMessage: ((MPCMessage, MCPeerID) -> Void)?

    init(configuration: Configuration) {
        self.peerID = MCPeerID(displayName: configuration.myDisplayName)
        self.serviceType = configuration.serviceType
        super.init()

        // Require encryption.
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
    }

    /// IMPORTANT: Don't do async teardown in `deinit`. Swift can release `self` while the task is still pending,
    /// and Multipeer may still call delegates during shutdown, causing EXC_BAD_ACCESS.
    /// Call `shutdown()` from the owning view's `.onDisappear` instead.

    /// Call when the collaboration flow is ending.
    func shutdown() {
        stop(disconnectSession: true)
        onMessage = nil
    }

    func startAdvertising(discoveryInfo: [String: String]? = nil) {
        stop(disconnectSession: false)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        mode = .advertising
    }

    func startBrowsing() {
        stop(disconnectSession: false)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        foundPeers = []
        mode = .browsing
    }

    /// Stops discovery/advertising. Optionally disconnects the session.
    ///
    /// EXC_BAD_ACCESS on dismissal is commonly caused by delegate callbacks arriving
    /// while advertiser/browser are being torn down. We make teardown idempotent and
    /// clear delegates before stopping.
    func stop(disconnectSession: Bool = false) {
        guard !isStopping else { return }
        isStopping = true
        defer { isStopping = false }

        // Snapshot to local vars to avoid any weirdness if properties change mid-call.
        let advertiserToStop = advertiser
        let browserToStop = browser
        let sessionToDisconnect = session

        // Clear first to prevent re-entrancy / callbacks referencing partially-torn-down state.
        advertiser = nil
        browser = nil

        advertiserToStop?.delegate = nil
        advertiserToStop?.stopAdvertisingPeer()

        browserToStop?.delegate = nil
        browserToStop?.stopBrowsingForPeers()

        foundPeers = []

        if disconnectSession {
            // Prevent further delegate callbacks from using this object.
            sessionToDisconnect?.delegate = nil
            sessionToDisconnect?.disconnect()
            connectedPeers = []
        }

        mode = .idle
    }

    func connectToFirstFoundPeer(timeout: TimeInterval = 12) {
        guard let peer = foundPeers.first else {
            lastError = "No peers found yet"
            return
        }
        invite(peer, timeout: timeout)
    }

    func invite(_ peer: MCPeerID, context: Data? = nil, timeout: TimeInterval = 12) {
        guard let browser else { return }
        browser.invitePeer(peer, to: session, withContext: context, timeout: timeout)
    }

    func send(_ message: MPCMessage, to peers: [MCPeerID]? = nil, reliably: Bool = true) {
        let targets = peers ?? session.connectedPeers
        guard !targets.isEmpty else { return }

        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: targets, with: reliably ? .reliable : .unreliable)
        } catch {
            lastError = "Send failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCSessionDelegate
extension MPCSessionManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.connectedPeers = session.connectedPeers
            if session.connectedPeers.isEmpty {
                self.mode = (self.mode == .advertising || self.mode == .browsing) ? self.mode : .idle
            } else {
                self.mode = .connected
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let message = try JSONDecoder().decode(MPCMessage.self, from: data)
                self.onMessage?(message, peerID)
            } catch {
                self.lastError = "Decode failed: \(error.localizedDescription)"
            }
        }
    }

    // Unused in this MVP
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // Accept; encryption is already required. Real classrooms can add custom trust here.
        certificateHandler(true)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MPCSessionManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept for MVP. For production: show UI ("Accept connection?")
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MPCSessionManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // For MVP we don't auto-invite. UI will decide.
        Task { @MainActor in
            if !self.foundPeers.contains(peerID) {
                self.foundPeers.append(peerID)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.foundPeers.removeAll { $0 == peerID }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.lastError = "Browsing failed: \(error.localizedDescription)"
        }
    }
}
