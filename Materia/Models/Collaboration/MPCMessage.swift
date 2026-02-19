import Foundation

/// Generic envelope for all messages sent over Multipeer Connectivity.
/// Keeping a single `type` + `payload` makes forward/backward compatibility easier.
struct MPCMessage: Codable {
    enum MessageType: String, Codable {
        // Mode 1 (Student-Student builder)
        case builderJoin
        case builderRoleAssigned
        case builderState
        case builderPatch
        case builderValidation
        
        // Mode 2 (Teacher-Student classroom)
        case classroomJoin
        case classroomRoster
        case classroomQuestion
        case classroomAnswer
        case classroomResults
        
        case ping
        case pong
    }

    let id: UUID
    let type: MessageType
    let sentAt: Date
    let payload: Data

    init<T: Codable>(type: MessageType, payload: T) throws {
        self.id = UUID()
        self.type = type
        self.sentAt = Date()
        self.payload = try JSONEncoder().encode(payload)
    }

    func decodePayload<T: Codable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: payload)
    }
}
