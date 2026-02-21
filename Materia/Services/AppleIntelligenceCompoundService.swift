//
//  AppleIntelligenceCompoundService.swift
//  Materia
//

import Foundation
import FoundationModels

@available(iOS 18.0, *)
@Generable
struct GeneratedCompoundStory {

    @Guide(description: "Step-by-step explanation of how the compound is constructed.")
    let howItsBuilt: String

    @Guide(description: "Important chemistry learning points.")
    let keyPoints: [String]

    @Guide(description: "Scientific explanation of bonding and molecular theory.")
    let chemicalBasis: String

    @Guide(description: "Key structural characteristics of the molecule.")
    let structuralFeatures: [String]

    @Guide(description: "Helpful real-world insights for students.")
    let learningInsights: [String]
}

@available(iOS 18.0, *)
final class AppleIntelligenceCompoundService {

    static let shared = AppleIntelligenceCompoundService()

    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession?

    private init() {}

    // MARK: - Availability

    func availability() -> SystemLanguageModel.Availability {
        model.availability
    }

    func isAvailable() -> Bool {
        model.availability == .available
    }

    // MARK: - Session Setup

    private func createSession() {

        let instructions = Instructions {
            "You are an expert organic chemistry tutor."
            "Explain compounds clearly and scientifically."
            "Do not hallucinate formulas or structural data."
            "Base explanations strictly on provided input."
            "Be educational and structured."
        }

        session = LanguageModelSession(instructions: instructions)
    }

    // MARK: - Streaming Story Generation

    func streamStory(
        compound: IdentifiedCompound,
        structure: ChemicalStructure
    ) -> AsyncThrowingStream<GeneratedCompoundStory.PartiallyGenerated, Error> {

        AsyncThrowingStream { continuation in

            Task {
                do {
                    guard self.isAvailable() else {
                        throw NSError(domain: "FoundationModelUnavailable", code: 1)
                    }

                    self.createSession()

                    let prompt = self.buildPrompt(
                        compound: compound,
                        structure: structure
                    )

                    let stream = self.session!.streamResponse(
                        to: prompt,
                        generating: GeneratedCompoundStory.self,
                        includeSchemaInPrompt: false
                    )

                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Prompt Builder

    private func buildPrompt(
        compound: IdentifiedCompound,
        structure: ChemicalStructure
    ) -> Prompt {

        Prompt {
            "Explain the compound \(compound.iupacName)."

            "Compound Name: \(compound.compoundName)"
            "Molecular Formula: \(compound.molecularFormula)"
            "Carbon Chain Length: \(structure.carbonChainLength)"
            "Total Bonds: \(structure.bonds.count)"
            "Functional Groups: \(structure.functionalGroups.map { $0.group.displayName }.joined(separator: ", "))"

            "Provide:"
            "1. Step-by-step construction"
            "2. Key learning points"
            "3. Bonding explanation"
            "4. Structural characteristics"
            "5. Real-world learning insights"

            "Keep it scientifically accurate."
        }
    }

    // MARK: - Performance

    func prewarm() {
        session?.prewarm()
    }
}
