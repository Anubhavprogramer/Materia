import Foundation
import MultipeerConnectivity

/// Mode 2: Teacher host.
@MainActor
final class ClassroomHostViewModel: ObservableObject {

    @Published private(set) var classroomID: UUID = UUID()
    @Published private(set) var connectedStudents: [String] = []
    @Published private(set) var currentQuestion: ClassroomQuestion?
    @Published private(set) var lastResults: ClassroomResults?
    @Published private(set) var isHosting: Bool = false

    @Published var statusText: String = "Not hosting"

    private let mpc: MPCSessionManager
    private let chemService: CoreMLChemistryServiceProtocol

    private var answersByQuestion: [UUID: [ClassroomAnswer]] = [:]

    init(mpc: MPCSessionManager,
         chemService: CoreMLChemistryServiceProtocol = CoreMLChemistryServiceFactory.createService()) {
        self.mpc = mpc
        self.chemService = chemService

        self.mpc.onMessage = { [weak self] msg, peer in
            self?.handle(msg, from: peer)
        }
    }

    func startHosting() {
        statusText = "Hosting classroom…"
        isHosting = true
        mpc.startAdvertising(discoveryInfo: ["mode": "classroom", "role": "teacher"])
    }

    func stopHosting() {
        statusText = "Not hosting"
        isHosting = false
        connectedStudents = []
        currentQuestion = nil
        lastResults = nil
        mpc.shutdown()
    }

    func sendQuestion(prompt: String, structure: ChemicalStructure? = nil) {
        let q = ClassroomQuestion(
            id: UUID(),
            classroomID: classroomID,
            prompt: prompt,
            kind: .iupacFromStructure,
            createdAt: Date(),
            structure: structure,
            choices: nil
        )
        currentQuestion = q
        answersByQuestion[q.id] = []
        lastResults = nil

        if let msg = try? MPCMessage(type: .classroomQuestion, payload: q) {
            mpc.send(msg, reliably: true)
        }
    }

    func endQuestion() {
        currentQuestion = nil
        lastResults = nil
    }

    private func broadcastRoster() {
        let roster = ClassroomRoster(classroomID: classroomID, students: connectedStudents.sorted(), updatedAt: Date())
        if let msg = try? MPCMessage(type: .classroomRoster, payload: roster) {
            mpc.send(msg, reliably: false)
        }
    }

    private func updateResults(for questionID: UUID) {
        guard let answers = answersByQuestion[questionID], let q = currentQuestion, q.id == questionID else { return }

        // For MVP correctness: if structure exists, compare to generated IUPAC (case-insensitive, trimmed).
        let expected: String? = {
            guard let s = q.structure else { return nil }
            return chemService.explainIUPAC(from: s).finalName
        }()

        let correct = answers.filter { ans in
            guard let expected else { return false }
            return ans.answerText.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let total = answers.count
        let correctCount = correct.count
        let rate = total == 0 ? 0 : Double(correctCount) / Double(total)

        let results = ClassroomResults(
            questionID: questionID,
            classroomID: classroomID,
            totalSubmissions: total,
            correctSubmissions: correctCount,
            correctnessRate: rate,
            answers: answers,
            updatedAt: Date()
        )

        lastResults = results

        if let msg = try? MPCMessage(type: .classroomResults, payload: results) {
            mpc.send(msg, reliably: false)
        }
    }

    private func handle(_ message: MPCMessage, from peer: MCPeerID) {
        switch message.type {
        case .classroomJoin:
            if let join = try? message.decodePayload(ClassroomJoin.self), join.classroomID == classroomID {
                if !connectedStudents.contains(join.displayName) {
                    connectedStudents.append(join.displayName)
                }
                broadcastRoster()
                statusText = "Students connected: \(connectedStudents.count)"
            }

        case .classroomAnswer:
            if let ans = try? message.decodePayload(ClassroomAnswer.self) {
                answersByQuestion[ans.questionID, default: []].append(ans)
                updateResults(for: ans.questionID)
            }

        default:
            break
        }
    }
}
