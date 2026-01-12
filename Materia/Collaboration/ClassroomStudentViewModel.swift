import Foundation
import MultipeerConnectivity

/// Mode 2: Student peer.
@MainActor
final class ClassroomStudentViewModel: ObservableObject {

    @Published private(set) var currentQuestion: ClassroomQuestion?
    @Published private(set) var roster: ClassroomRoster?
    @Published private(set) var lastResults: ClassroomResults?

    @Published var studentName: String
    @Published var statusText: String = "Not connected"

    private let classroomID: UUID
    private let mpc: MPCSessionManager

    init(classroomID: UUID, mpc: MPCSessionManager, studentName: String = UIDevice.current.name) {
        self.classroomID = classroomID
        self.mpc = mpc
        self.studentName = studentName

        self.mpc.onMessage = { [weak self] msg, peer in
            self?.handle(msg, from: peer)
        }
    }

    func startJoining() {
        statusText = "Browsing for teacher…"
        mpc.startBrowsing()
    }

    func sendJoin() {
        let join = ClassroomJoin(classroomID: classroomID, displayName: studentName)
        if let msg = try? MPCMessage(type: .classroomJoin, payload: join) {
            mpc.send(msg, reliably: true)
        }
    }

    func submitAnswer(_ text: String) {
        guard let q = currentQuestion else { return }

        let ans = ClassroomAnswer(
            questionID: q.id,
            classroomID: q.classroomID,
            studentName: studentName,
            submittedAt: Date(),
            answerText: text
        )

        if let msg = try? MPCMessage(type: .classroomAnswer, payload: ans) {
            mpc.send(msg, reliably: true)
        }
    }

    private func handle(_ message: MPCMessage, from peer: MCPeerID) {
        switch message.type {
        case .classroomRoster:
            roster = try? message.decodePayload(ClassroomRoster.self)
            statusText = "Connected"

        case .classroomQuestion:
            currentQuestion = try? message.decodePayload(ClassroomQuestion.self)
            lastResults = nil
            statusText = "Question received"

        case .classroomResults:
            lastResults = try? message.decodePayload(ClassroomResults.self)

        default:
            break
        }
    }
}
