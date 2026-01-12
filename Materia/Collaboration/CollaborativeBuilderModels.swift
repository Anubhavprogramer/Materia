import Foundation

// MARK: - Builder roles

enum BuilderRole: String, Codable {
    case builderA // carbon chain + bonds
    case builderB // functional groups
}

/// Shared session state for Mode 1.
struct BuilderSessionState: Codable {
    var sessionID: UUID
    var structure: ChemicalStructure
    var updatedAt: Date
    var revision: Int
}

/// A small patch type to keep messages low-latency.
/// For MVP we implement a minimal set of operations.
struct BuilderPatch: Codable {
    enum Operation: String, Codable {
        case setCarbonChainLength
        case setBond // between adjacent carbons
        case addFunctionalGroup
        case removeFunctionalGroup
    }

    let op: Operation
    let actorRole: BuilderRole
    let updatedAt: Date

    // op payload (single union struct keeps encoding simple)
    let carbonChainLength: Int?
    let bondFrom: Int?
    let bondTo: Int?
    let bondType: BondType?
    let functionalGroup: FunctionalGroup?
    let carbonPosition: Int?
}

struct BuilderRoleAssigned: Codable {
    let sessionID: UUID
    let role: BuilderRole
}

struct BuilderJoin: Codable {
    let sessionID: UUID
    let displayName: String
}

struct BuilderValidationBroadcast: Codable {
    let sessionID: UUID
    let isValid: Bool
    let message: String?
    let iupacName: String
    let updatedAt: Date
    let revision: Int
}
