import Foundation
import MultipeerConnectivity

/// Mode 1: 2-student collaboration (Builder A/B).
@MainActor
final class CollaborativeBuilderViewModel: ObservableObject {

    // UI state
    @Published private(set) var role: BuilderRole?
    @Published private(set) var sessionState: BuilderSessionState
    @Published private(set) var lastValidation: BuilderValidationBroadcast?

    @Published var statusText: String = "Not connected"

    private let mpc: MPCSessionManager
    private let chemService: CoreMLChemistryServiceProtocol

    init(mpc: MPCSessionManager,
         chemService: CoreMLChemistryServiceProtocol = CoreMLChemistryServiceFactory.createService()) {
        self.mpc = mpc
        self.chemService = chemService
        self.sessionState = BuilderSessionState(
            sessionID: UUID(),
            structure: ChemicalStructure(carbonChainLength: 3),
            updatedAt: Date(),
            revision: 0
        )

        self.mpc.onMessage = { [weak self] msg, peer in
            self?.handle(msg, from: peer)
        }
    }

    // MARK: - Hosting / joining

    func startHosting() {
        statusText = "Advertising…"
        mpc.startAdvertising(discoveryInfo: ["mode": "builder"])
        // Host assigns role locally as Builder A.
        role = .builderA
    }

    func startJoining() {
        statusText = "Browsing…"
        mpc.startBrowsing()
        // Joiner will be assigned Builder B by host after connection.
    }

    func sendJoin() {
        guard let role else {
            // Joiner announces intent; host will assign.
            let join = BuilderJoin(sessionID: sessionState.sessionID, displayName: UIDevice.current.name)
            if let msg = try? MPCMessage(type: .builderJoin, payload: join) {
                mpc.send(msg)
            }
            return
        }

        let join = BuilderJoin(sessionID: sessionState.sessionID, displayName: UIDevice.current.name)
        if let msg = try? MPCMessage(type: .builderJoin, payload: join) {
            mpc.send(msg)
        }

        statusText = "Joined as \(role.rawValue)"
    }

    // MARK: - Local edit APIs (called by SwiftUI)

    func setCarbonChainLength(_ length: Int) {
        guard role == .builderA else { return }
        applyLocalPatch(
            BuilderPatch(
                op: .setCarbonChainLength,
                actorRole: .builderA,
                updatedAt: Date(),
                carbonChainLength: length,
                bondFrom: nil, bondTo: nil, bondType: nil,
                functionalGroup: nil, carbonPosition: nil
            )
        )
    }

    func setBond(from: Int, to: Int, type: BondType) {
        guard role == .builderA else { return }
        applyLocalPatch(
            BuilderPatch(
                op: .setBond,
                actorRole: .builderA,
                updatedAt: Date(),
                carbonChainLength: nil,
                bondFrom: from, bondTo: to, bondType: type,
                functionalGroup: nil, carbonPosition: nil
            )
        )
    }

    func addFunctionalGroup(_ group: FunctionalGroup, at position: Int) {
        guard role == .builderB else { return }
        applyLocalPatch(
            BuilderPatch(
                op: .addFunctionalGroup,
                actorRole: .builderB,
                updatedAt: Date(),
                carbonChainLength: nil,
                bondFrom: nil, bondTo: nil, bondType: nil,
                functionalGroup: group, carbonPosition: position
            )
        )
    }

    func removeFunctionalGroup(_ group: FunctionalGroup, at position: Int) {
        guard role == .builderB else { return }
        applyLocalPatch(
            BuilderPatch(
                op: .removeFunctionalGroup,
                actorRole: .builderB,
                updatedAt: Date(),
                carbonChainLength: nil,
                bondFrom: nil, bondTo: nil, bondType: nil,
                functionalGroup: group, carbonPosition: position
            )
        )
    }

    // MARK: - Patch pipeline

    private func applyLocalPatch(_ patch: BuilderPatch) {
        // Apply locally
        applyPatch(patch)

        // Broadcast patch
        if let msg = try? MPCMessage(type: .builderPatch, payload: patch) {
            mpc.send(msg, reliably: false) // low latency for live edits
        }

        // Recompute + broadcast validation + IUPAC (host is authority for MVP)
        if role == .builderA {
            broadcastValidation()
        }
    }

    private func applyPatch(_ patch: BuilderPatch) {
        var structure = sessionState.structure

        switch patch.op {
        case .setCarbonChainLength:
            if let len = patch.carbonChainLength {
                structure = ChemicalStructure(carbonChainLength: len)
            }

        case .setBond:
            guard let from = patch.bondFrom, let to = patch.bondTo, let type = patch.bondType else { break }
            structure.bonds.removeAll { ($0.fromCarbon == min(from,to) && $0.toCarbon == max(from,to)) }
            structure.bonds.append(Bond(from: from, to: to, type: type))

        case .addFunctionalGroup:
            guard let group = patch.functionalGroup, let pos = patch.carbonPosition else { break }
            structure.functionalGroups.removeAll { $0.group == group && $0.carbonPosition == pos }
            structure.functionalGroups.append(FunctionalGroupAttachment(position: pos, group: group))

        case .removeFunctionalGroup:
            guard let group = patch.functionalGroup, let pos = patch.carbonPosition else { break }
            structure.functionalGroups.removeAll { $0.group == group && $0.carbonPosition == pos }
        }

        sessionState.structure = structure
        sessionState.updatedAt = patch.updatedAt
        sessionState.revision += 1
    }

    private func broadcastValidation() {
        let (isValid, message) = sessionState.structure.isValid()
        let iupac = chemService.explainIUPAC(from: sessionState.structure).finalName

        let broadcast = BuilderValidationBroadcast(
            sessionID: sessionState.sessionID,
            isValid: isValid,
            message: message,
            iupacName: iupac,
            updatedAt: Date(),
            revision: sessionState.revision
        )

        lastValidation = broadcast

        if let msg = try? MPCMessage(type: .builderValidation, payload: broadcast) {
            mpc.send(msg, reliably: true)
        }
    }

    // MARK: - Incoming messages

    private func handle(_ message: MPCMessage, from peer: MCPeerID) {
        switch message.type {
        case .builderJoin:
            // Host assigns Builder B to the joiner.
            guard role == .builderA else { return }
            let assigned = BuilderRoleAssigned(sessionID: sessionState.sessionID, role: .builderB)
            if let msg = try? MPCMessage(type: .builderRoleAssigned, payload: assigned) {
                mpc.send(msg, to: [peer], reliably: true)
            }

            // Host also sends the current full state.
            if let stateMsg = try? MPCMessage(type: .builderState, payload: sessionState) {
                mpc.send(stateMsg, to: [peer], reliably: true)
            }

            broadcastValidation()
            statusText = "Connected (pair mode)"

        case .builderRoleAssigned:
            if let assigned = try? message.decodePayload(BuilderRoleAssigned.self) {
                role = assigned.role
                statusText = "Assigned role: \(assigned.role.rawValue)"

                // Send join ack
                sendJoin()
            }

        case .builderState:
            if let state = try? message.decodePayload(BuilderSessionState.self) {
                // Authority: host for MVP. Accept latest revision.
                if state.revision >= sessionState.revision {
                    sessionState = state
                }
            }

        case .builderPatch:
            if let patch = try? message.decodePayload(BuilderPatch.self) {
                // Accept remote patch.
                applyPatch(patch)

                // Host remains authority for validation broadcast.
                if role == .builderA {
                    broadcastValidation()
                }
            }

        case .builderValidation:
            if let v = try? message.decodePayload(BuilderValidationBroadcast.self) {
                if v.revision >= (lastValidation?.revision ?? 0) {
                    lastValidation = v
                }
            }

        default:
            break
        }
    }
}
