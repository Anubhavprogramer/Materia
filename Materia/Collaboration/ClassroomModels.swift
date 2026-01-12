import Foundation

enum ClassroomRole: String, Codable {
    case teacher
    case student
}

struct ClassroomJoin: Codable {
    let classroomID: UUID
    let displayName: String
}

struct ClassroomRoster: Codable {
    let classroomID: UUID
    let students: [String]
    let updatedAt: Date
}

struct ClassroomQuestion: Codable, Identifiable {
    let id: UUID
    let classroomID: UUID
    let prompt: String
    let kind: Kind
    let createdAt: Date

    enum Kind: String, Codable {
        case iupacFromStructure
        case structureFromIupac
        case multipleChoice
    }

    // Optional: provide the structure for structure-based questions.
    let structure: ChemicalStructure?
    let choices: [String]?
}

struct ClassroomAnswer: Codable {
    let questionID: UUID
    let classroomID: UUID
    let studentName: String
    let submittedAt: Date
    let answerText: String
}

struct ClassroomResults: Codable {
    let questionID: UUID
    let classroomID: UUID
    let totalSubmissions: Int
    let correctSubmissions: Int
    let correctnessRate: Double
    let answers: [ClassroomAnswer]
    let updatedAt: Date
}
