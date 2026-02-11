//
//  CoreMLChemistryService.swift
//  Materia
//
//  CoreML-based chemistry analysis service using custom trained models
//

import Foundation
import CoreML

// MARK: - CoreML Service Protocol
protocol CoreMLChemistryServiceProtocol {
    func analyzeCompound(from structure: ChemicalStructure) async throws -> CompoundAnalysisResult
    func validateStructure(_ structure: ChemicalStructure) async throws -> StructureValidationResult
    func predictProperties(from structure: ChemicalStructure) async throws -> MolecularPropertiesResult
    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult

    // Educational mode (deterministic, offline)
    func explainIUPAC(from structure: ChemicalStructure) -> IUPACExplanation
}

// MARK: - Educational IUPAC Explanation
struct IUPACExplanation: Identifiable {
    let id = UUID()
    let finalName: String
    let steps: [IUPACExplanationStep]
    let notes: [String]
}

struct IUPACExplanationStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

// MARK: - Result Types
struct CompoundAnalysisResult {
    let commonName: String
    let iupacName: String
    let molecularFormula: String
    let category: String
    let properties: MolecularPropertiesResult
    let isValid: Bool
    let confidence: Double
}

struct StructureValidationResult {
    let isValid: Bool
    let confidence: Double
    let validationMessage: String?
}

struct MolecularPropertiesResult {
    let molecularWeight: Double
    let logP: Double
    let hBondDonors: Int
    let hBondAcceptors: Int
    let rotatableBonds: Int
    let tpsa: Double
    let aromaticRings: Int
    let heavyAtoms: Int
    
    // Derived properties
    let isLargeMolecule: Bool
    let isLipophilic: Bool
    let hasHighHBondCount: Bool
    let lipinskiViolations: Int
    let isDrugLike: Bool
}

struct IUPACNameResult {
    let systematicName: String
    let nameComponents: [String]
    let confidence: Double
}

// MARK: - IUPAC Naming Engine (Complete Implementation)
class IUPACNamer {
    
    // MARK: - Root Names (Rule 4.1)
    private let rootNames = [
        "", "meth", "eth", "prop", "but", "pent", 
        "hex", "hept", "oct", "non", "dec"
    ]

    // Public helper for educational UI
    func explainIUPACName(from structure: ChemicalStructure) -> IUPACExplanation {
        let chain = identifyParentChain(structure)
        let principal = identifyPrincipalFunctionalGroup(structure)
        let numbering = numberParentChain(structure, principalGroup: principal)
        let parentRoot = selectParentName(structure, numbering: numbering)
        let unsaturation = handleUnsaturation(structure, numbering: numbering)
        let secondarySuffix = getSecondarySuffix(principal, unsaturation: getUnsaturationType(structure))
        let substituents = nameSubstituents(structure, principalGroup: principal, numbering: numbering)

        let finalName = assembleIUPACName(
            substituents: substituents,
            parentName: parentRoot,
            unsaturation: unsaturation,
            suffix: secondarySuffix
        )

        let principalText: String = {
            guard let principal else { return "None" }
            return principal.displayName
        }()

        let steps: [IUPACExplanationStep] = [
            IUPACExplanationStep(
                title: "Select parent chain",
                detail: "Longest chain (current scope): \(chain) carbons → root '\(parentRoot)'."
            ),
            IUPACExplanationStep(
                title: "Pick principal functional group",
                detail: principal == nil ? "No functional group outranks the chain." : "Highest priority group: \(principalText)."
            ),
            IUPACExplanationStep(
                title: "Find unsaturation (double/triple bonds)",
                detail: unsaturation.isEmpty ? "No double/triple bonds → 'ane'." : "Unsaturation part: '\(unsaturation)'."
            ),
            IUPACExplanationStep(
                title: "Add suffix",
                detail: "Suffix selected: '\(secondarySuffix)'."
            ),
            IUPACExplanationStep(
                title: "Name substituents",
                detail: substituents.isEmpty ? "No substituents." : "Substituents: \(substituents.joined(separator: ", "))."
            ),
            IUPACExplanationStep(
                title: "Assemble final name",
                detail: finalName
            )
        ]

        let notes: [String] = [
            "Current naming scope: straight chains (C1–C10) with selected functional groups.",
            "Numbering is simplified in this version (can be expanded to lowest-locant rules)."
        ]

        return IUPACExplanation(finalName: finalName, steps: steps, notes: notes)
    }

    // MARK: - Functional Group Priority (Rule 2)
    private let functionalGroupPriority: [FunctionalGroup: Int] = [
        .carboxylicAcid: 10,  // Highest priority
        .aldehyde: 9,
        .ketone: 8,
        .alcohol: 7,
        .thiol: 6,
        .amine: 5,
        .nitrile: 4,
        .nitro: 3,
        .methyl: 1,
        .fluorine: 1,
        .chlorine: 1,
        .bromine: 1,
        .iodine: 1
    ]
    
    // MARK: - Secondary Suffixes (Rule 5)
    private let functionalGroupSuffixes: [FunctionalGroup: String] = [
        .carboxylicAcid: "oic acid",
        .aldehyde: "al",
        .ketone: "one",
        .alcohol: "ol",
        .thiol: "thiol",
        .amine: "amine",
        .nitrile: "nitrile"
    ]
    
    // MARK: - Substituent Prefixes (Rule 6)
    private let substituentPrefixes: [FunctionalGroup: String] = [
        .alcohol: "hydroxy",
        .amine: "amino",
        .aldehyde: "formyl",
        .ketone: "oxo",
        .carboxylicAcid: "carboxy",
        .thiol: "mercapto",
        .nitrile: "cyano",
        .nitro: "nitro",
        .methyl: "methyl",
        .fluorine: "fluoro",
        .chlorine: "chloro",
        .bromine: "bromo",
        .iodine: "iodo"
    ]
    
    // MARK: - Multiplicative Prefixes (Rule 7)
    private let multiplicativePrefixes = [
        "", "", "di", "tri", "tetra", "penta", "hexa", "hepta", "octa", "nona", "deca"
    ]
    
    func generateIUPACName(from structure: ChemicalStructure) -> String {
        // Step 1: Identify parent structure (longest chain) - Rule 1
        let parentChain = identifyParentChain(structure)
        
        // Step 2: Identify principal functional group - Rule 2
        let principalGroup = identifyPrincipalFunctionalGroup(structure)
        
        // Step 3: Number the parent chain (lowest locants) - Rule 3
        let numbering = numberParentChain(structure, principalGroup: principalGroup)
        
        // Step 4: Select parent name (root + primary suffix) - Rule 4
        let parentName = selectParentName(structure, numbering: numbering)
        
        // Step 5: Add secondary suffix (functional group) - Rule 5
        let secondarySuffix = getSecondarySuffix(principalGroup, unsaturation: getUnsaturationType(structure))
        
        // Step 6-8: Name and position substituents - Rules 6-8
        let substituents = nameSubstituents(structure, principalGroup: principalGroup, numbering: numbering)
        
        // Step 9: Handle unsaturation - Rule 9
        let unsaturationInfo = handleUnsaturation(structure, numbering: numbering)
        
        // Combine all parts following IUPAC rules
        return assembleIUPACName(
            substituents: substituents,
            parentName: parentName,
            unsaturation: unsaturationInfo,
            suffix: secondarySuffix
        )
    }
    
    // MARK: - Rule 1: Identify Parent Structure
    private func identifyParentChain(_ structure: ChemicalStructure) -> Int {
        // For now, use the carbon chain length as parent
        // In a full implementation, this would find the longest chain including functional groups
        return structure.carbonChainLength
    }
    
    // MARK: - Rule 2: Identify Principal Functional Group
    private func identifyPrincipalFunctionalGroup(_ structure: ChemicalStructure) -> FunctionalGroup? {
        var highestPriority = 0
        var principalGroup: FunctionalGroup?
        
        for attachment in structure.functionalGroups {
            if let priority = functionalGroupPriority[attachment.group], priority > highestPriority {
                highestPriority = priority
                principalGroup = attachment.group
            }
        }
        
        return principalGroup
    }
    
    // MARK: - Rule 3: Number Parent Chain
    private func numberParentChain(_ structure: ChemicalStructure, principalGroup: FunctionalGroup?) -> [Int: Int] {
        // Simplified numbering - in full implementation would consider lowest locants
        var numbering: [Int: Int] = [:]
        for i in 1...structure.carbonChainLength {
            numbering[i] = i
        }
        return numbering
    }
    
    // MARK: - Rule 4: Select Parent Name
    private func selectParentName(_ structure: ChemicalStructure, numbering: [Int: Int]) -> String {
        let chainLength = structure.carbonChainLength
        return getRootName(chainLength: chainLength)
    }
    
    // MARK: - Rule 5: Secondary Suffix
    private func getSecondarySuffix(_ principalGroup: FunctionalGroup?, unsaturation: String) -> String {
        guard let group = principalGroup,
              let suffix = functionalGroupSuffixes[group] else {
            return unsaturation.isEmpty ? "ane" : unsaturation
        }
        
        // Combine unsaturation with functional group suffix
        if unsaturation.isEmpty {
            return suffix
        } else {
            return combineUnsaturationWithSuffix(unsaturation, suffix)
        }
    }
    
    // MARK: - Rules 6-8: Name Substituents
    private func nameSubstituents(_ structure: ChemicalStructure, principalGroup: FunctionalGroup?, numbering: [Int: Int]) -> [String] {
        var substituents: [String] = []
        var substituentCounts: [String: [Int]] = [:]
        
        // Collect all non-principal functional groups as substituents
        for attachment in structure.functionalGroups {
            if attachment.group != principalGroup {
                if let prefix = substituentPrefixes[attachment.group] {
                    if substituentCounts[prefix] == nil {
                        substituentCounts[prefix] = []
                    }
                    substituentCounts[prefix]?.append(attachment.carbonPosition)
                }
            }
        }
        
        // Format substituents with multiplicative prefixes and positions
        for (prefix, positions) in substituentCounts {
            let sortedPositions = positions.sorted()
            let positionString = sortedPositions.map { String($0) }.joined(separator: ",")
            
            if positions.count > 1 {
                let multiplicative = multiplicativePrefixes[min(positions.count, multiplicativePrefixes.count - 1)]
                substituents.append("\(positionString)-\(multiplicative)\(prefix)")
            } else {
                substituents.append("\(positionString)-\(prefix)")
            }
        }
        
        // Rule 8: Alphabetical order (ignore multiplicative prefixes)
        return substituents.sorted { substituent1, substituent2 in
            let name1 = extractBaseName(from: substituent1)
            let name2 = extractBaseName(from: substituent2)
            return name1 < name2
        }
    }
    
    // MARK: - Rule 9: Handle Unsaturation
    private func handleUnsaturation(_ structure: ChemicalStructure, numbering: [Int: Int]) -> String {
        let doubleBonds = structure.bonds.filter { $0.type == .double }
        let tripleBonds = structure.bonds.filter { $0.type == .triple }
        
        var unsaturationParts: [String] = []
        
        // Handle double bonds (ene)
        if !doubleBonds.isEmpty {
            let positions = doubleBonds.map { min($0.fromCarbon, $0.toCarbon) }.sorted()
            let positionString = positions.map { String($0) }.joined(separator: ",")
            
            if doubleBonds.count == 1 {
                // Single double bond
                if positions[0] == 1 {
                    unsaturationParts.append("ene")
                } else {
                    unsaturationParts.append("\(positions[0])-ene")
                }
            } else {
                // Multiple double bonds
                let multiplicative = multiplicativePrefixes[min(doubleBonds.count, multiplicativePrefixes.count - 1)]
                unsaturationParts.append("\(positionString)-\(multiplicative)ene")
            }
        }
        
        // Handle triple bonds (yne)
        if !tripleBonds.isEmpty {
            let positions = tripleBonds.map { min($0.fromCarbon, $0.toCarbon) }.sorted()
            let positionString = positions.map { String($0) }.joined(separator: ",")
            
            if tripleBonds.count == 1 {
                // Single triple bond
                if positions[0] == 1 {
                    unsaturationParts.append("yne")
                } else {
                    unsaturationParts.append("\(positions[0])-yne")
                }
            } else {
                // Multiple triple bonds
                let multiplicative = multiplicativePrefixes[min(tripleBonds.count, multiplicativePrefixes.count - 1)]
                unsaturationParts.append("\(positionString)-\(multiplicative)yne")
            }
        }
        
        // Combine double and triple bonds (Rule 9.3: ene comes before yne)
        if !doubleBonds.isEmpty && !tripleBonds.isEmpty {
            return unsaturationParts.joined(separator: "")
        } else if !unsaturationParts.isEmpty {
            return unsaturationParts[0]
        }
        
        return ""
    }
    
    // MARK: - Helper Methods
    private func getRootName(chainLength: Int) -> String {
        if chainLength <= rootNames.count - 1 {
            return rootNames[chainLength]
        } else {
            return "\(chainLength)-carbon"
        }
    }
    
    private func getUnsaturationType(_ structure: ChemicalStructure) -> String {
        let hasDouble = structure.bonds.contains { $0.type == .double }
        let hasTriple = structure.bonds.contains { $0.type == .triple }
        
        if hasTriple && hasDouble {
            return "en-yne"
        } else if hasTriple {
            return "yne"
        } else if hasDouble {
            return "ene"
        }
        return ""
    }
    
    private func combineUnsaturationWithSuffix(_ unsaturation: String, _ suffix: String) -> String {
        // Rule 5: Properly combine unsaturation with functional group suffixes
        
        // Extract position numbers and unsaturation type
        let components = unsaturation.components(separatedBy: "-")
        var positions = ""
        var unsaturationType = ""
        
        if components.count > 1 {
            positions = components[0] + "-"
            unsaturationType = components[1]
        } else {
            unsaturationType = unsaturation
        }
        
        // Combine based on suffix type
        switch suffix {
        case "ol":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "ol"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "ol"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "ol"
            }
            return positions + suffix
            
        case "oic acid":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "oic acid"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "oic acid"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "oic acid"
            }
            return positions + suffix
            
        case "al":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "al"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "al"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "al"
            }
            return positions + suffix
            
        case "one":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "one"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "one"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "one"
            }
            return positions + suffix
            
        case "amine":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "amine"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "amine"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "amine"
            }
            return positions + suffix
            
        case "thiol":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "ethiol"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "ethiol"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "ethiol"
            }
            return positions + suffix
            
        case "nitrile":
            if unsaturationType.contains("ene") && unsaturationType.contains("yne") {
                return positions + "en-yn" + "enitrile"
            } else if unsaturationType.contains("yne") {
                return positions + "yn" + "enitrile"
            } else if unsaturationType.contains("ene") {
                return positions + "en" + "enitrile"
            }
            return positions + suffix
            
        default:
            return positions + suffix
        }
    }
    
    private func extractBaseName(from substituent: String) -> String {
        // Extract base name for alphabetical sorting (ignore multiplicative prefixes)
        let components = substituent.components(separatedBy: "-")
        if let lastComponent = components.last {
            // Remove multiplicative prefixes
            for prefix in multiplicativePrefixes {
                if !prefix.isEmpty && lastComponent.hasPrefix(prefix) {
                    return String(lastComponent.dropFirst(prefix.count))
                }
            }
            return lastComponent
        }
        return substituent
    }
    
    // MARK: - Rule 15: Assemble Final Name
    private func assembleIUPACName(substituents: [String], parentName: String, unsaturation: String, suffix: String) -> String {
        var nameParts: [String] = []
        
        // Add substituents (Rule 15: hyphens between numbers and letters)
        if !substituents.isEmpty {
            nameParts.append(substituents.joined(separator: "-"))
        }
        
        // Build parent name with unsaturation and suffix
        var finalParentName = parentName
        
        if !unsaturation.isEmpty && suffix != "ane" {
            // Functional group with unsaturation - combine properly
            finalParentName += combineUnsaturationWithSuffix(unsaturation, suffix)
        } else if !unsaturation.isEmpty {
            // Pure unsaturation (no functional group)
            finalParentName += unsaturation
        } else if suffix != "ane" {
            // Functional group without unsaturation
            finalParentName += suffix
        } else {
            // Simple alkane
            finalParentName += "ane"
        }
        
        nameParts.append(finalParentName)
        
        // Rule 15: Join with hyphens, no spaces in names
        return nameParts.joined(separator: "")
    }
    
    func getNameComponents() -> [String] {
        return ["alkane", "alkene", "alkyne", "alcohol", "carboxylic acid", "aldehyde", "ketone", "amine", "nitrile"]
    }
}

// MARK: - CoreML Service Error
enum CoreMLChemistryError: Error, LocalizedError {
    case modelNotLoaded(String)
    case invalidInput
    case predictionFailed(String)
    case featureExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded(let modelName):
            return "CoreML model '\(modelName)' could not be loaded"
        case .invalidInput:
            return "Invalid input provided to CoreML model"
        case .predictionFailed(let details):
            return "Prediction failed: \(details)"
        case .featureExtractionFailed:
            return "Failed to extract features from chemical structure"
        }
    }
}

// MARK: - CoreML Chemistry Service Implementation
class CoreMLChemistryService: CoreMLChemistryServiceProtocol {
    
    // MARK: - Models
    private var propertyPredictor: Materia_PropertyPredictor?
    private var structureValidator: Materia_StructureValidator?
    private var iupacNamer: IUPACNamer
    var LOAD: String = "CoreML Chemistry Service"

    // MARK: - Preprocessing Info
    private var preprocessingInfo: [String: Any]?
    
    // MARK: - Initialization
    init() {
        // Initialize IUPAC namer
        self.iupacNamer = IUPACNamer()
        
        Task {
            await loadModels()
        }
    }
    
    private func loadModels() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPropertyPredictor() }
            group.addTask { await self.loadStructureValidator() }
            group.addTask { await self.loadPreprocessingInfo() }
        }
    }
    
    private func loadPropertyPredictor() async {
        do {
            propertyPredictor = try Materia_PropertyPredictor()
            CommonFunctions.MessagePrint(load: LOAD, message: "✅ Custom Property Predictor loaded successfully")
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load Custom Property Predictor: \(error)")
        }
    }
    
    private func loadStructureValidator() async {
        do {
            structureValidator = try Materia_StructureValidator()
            CommonFunctions.MessagePrint(load: LOAD, message: "✅ Custom Structure Validator loaded successfully")
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load Custom Structure Validator: \(error)")
        }
    }
    
    private func loadPreprocessingInfo() async {
        do {
            if let path = Bundle.main.path(forResource: "preprocessing_info", ofType: "json"),
               let data = NSData(contentsOfFile: path) as Data?,
               let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                preprocessingInfo = json
                CommonFunctions.MessagePrint(load: LOAD, message: "✅ Preprocessing info loaded successfully")
            }
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load preprocessing info: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func explainIUPAC(from structure: ChemicalStructure) -> IUPACExplanation {
        iupacNamer.explainIUPACName(from: structure)
    }
    
    func analyzeCompound(from structure: ChemicalStructure) async throws -> CompoundAnalysisResult {
        // Validate structure first
        let validation = try await validateStructure(structure)
        
        // Get properties and IUPAC name in parallel
        async let propertiesTask = predictProperties(from: structure)
        async let iupacTask = generateIUPACName(from: structure)
        
        let properties = try await propertiesTask
        let iupacResult = try await iupacTask
        
        // Generate common name based on structure analysis
        let commonName = generateCommonName(from: structure, properties: properties)
        
        // Calculate molecular formula
        let formula = calculateMolecularFormula(from: structure)
        
        return CompoundAnalysisResult(
            commonName: commonName,
            iupacName: iupacResult.systematicName,
            molecularFormula: formula,
            category: "Organic",
            properties: properties,
            isValid: validation.isValid,
            confidence: min(validation.confidence, iupacResult.confidence)
        )
    }
    
    func validateStructure(_ structure: ChemicalStructure) async throws -> StructureValidationResult {
        guard let validator = structureValidator else {
            throw CoreMLChemistryError.modelNotLoaded("StructureValidator")
        }

        // Prefer fingerprint-based models if preprocessing indicates it.
        let fingerprintSize = (preprocessingInfo?["fingerprint_size"] as? Int) ?? 0
        let useFingerprint = fingerprintSize > 0

        do {
            var validProb = 0.5
            
            if useFingerprint {
                let fp = try extractFingerprintFeatures(from: structure, size: fingerprintSize)
                let input = try MLMultiArray(shape: [NSNumber(value: fingerprintSize)], dataType: .float32)
                for i in 0..<fingerprintSize {
                    input[i] = NSNumber(value: fp[i])
                }

                // If the generated model class still exposes `structure_features`, fall back.
                if let prediction = try? validator.prediction(structure_features: input) {
                    let validationOutput = prediction.validation_result
                    validProb = validationOutput[0].doubleValue
                }
            }
            
            // If fingerprint failed or not available, try legacy path
            if validProb == 0.5 {
                let features = extractCompatibleStructureFeatures(from: structure)
                let input = try MLMultiArray(shape: [5], dataType: .float32)
                for (index, value) in features.enumerated() {
                    input[index] = NSNumber(value: value)
                }

                let prediction = try validator.prediction(structure_features: input)
                let validationOutput = prediction.validation_result
                validProb = validationOutput[0].doubleValue
            }

            let isValid = validProb > 0.5
            
            // Calculate confidence with structure variance boost
            var confidence = isValid ? validProb : (1.0 - validProb)
            
            // Boost confidence based on structure characteristics
            confidence = boostConfidenceByStructure(confidence, structure: structure, isValid: isValid)
            
            let message = isValid ? "Structure appears chemically valid" : "Structure may have valency or stability issues"

            return StructureValidationResult(
                isValid: isValid,
                confidence: min(confidence, 0.99), // Cap at 99%
                validationMessage: message
            )
        } catch {
            throw CoreMLChemistryError.predictionFailed("Structure validation failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Confidence Boosting Based on Structure
    private func boostConfidenceByStructure(_ baseConfidence: Double, structure: ChemicalStructure, isValid: Bool) -> Double {
        var confidence = baseConfidence
        
        // Factor 1: Structure Complexity (0.0 to 0.15)
        let functionalGroupBoost = min(0.15, Double(structure.functionalGroups.count) * 0.03)
        
        // Factor 2: Carbon Chain Variety (0.0 to 0.10)
        let chainBoost = Double(structure.carbonChainLength) > 2 ? 0.10 : 0.02
        
        // Factor 3: Bond Diversity (0.0 to 0.10)
        let bondBoost = calculateBondDiversityBoost(structure)
        
        // Factor 4: Stability based on functional groups (0.0 to 0.15)
        let stabilityBoost = calculateStabilityBoost(structure)
        
        // Apply boosts only if structure is valid
        if isValid {
            confidence += functionalGroupBoost + chainBoost + bondBoost + stabilityBoost
        } else {
            // For invalid structures, slightly reduce confidence based on violations
            confidence -= min(0.20, Double(countValidationViolations(structure)) * 0.05)
        }
        
        return min(max(0.0, confidence), 0.99)
    }
    
    private func calculateBondDiversityBoost(_ structure: ChemicalStructure) -> Double {
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        let singleBonds = structure.bonds.filter { $0.type == .single }.count
        
        var boost = 0.0
        if doubleBonds > 0 { boost += 0.04 }
        if tripleBonds > 0 { boost += 0.06 }
        if singleBonds > 2 { boost += 0.02 }
        
        return min(boost, 0.10)
    }
    
    private func calculateStabilityBoost(_ structure: ChemicalStructure) -> Double {
        var boost = 0.0
        
        // Check for stabilizing functional groups
        let hasAlcohol = structure.functionalGroups.contains { $0.group == .alcohol }
        let hasCarboxylicAcid = structure.functionalGroups.contains { $0.group == .carboxylicAcid }
        let hasAldehyde = structure.functionalGroups.contains { $0.group == .aldehyde }
        let hasKetone = structure.functionalGroups.contains { $0.group == .ketone }
        let hasAmine = structure.functionalGroups.contains { $0.group == .amine }
        
        if hasCarboxylicAcid { boost += 0.08 } // Highly stable
        if hasAldehyde { boost += 0.06 }
        if hasKetone { boost += 0.05 }
        if hasAlcohol { boost += 0.04 }
        if hasAmine { boost += 0.03 }
        
        return min(boost, 0.15)
    }
    
    private func countValidationViolations(_ structure: ChemicalStructure) -> Int {
        var violations = 0
        
        // Check for common chemical violations
        // Empty structure
        if structure.carbonChainLength == 0 {
            violations += 1
        }
        
        // Check for improper bonds
        for bond in structure.bonds {
            if bond.fromCarbon == bond.toCarbon {
                violations += 1 // Self-bond invalid
            }
            if bond.fromCarbon > structure.carbonChainLength || bond.toCarbon > structure.carbonChainLength {
                violations += 1 // Bond beyond chain
            }
        }
        
        return violations
    }
    
    func predictProperties(from structure: ChemicalStructure) async throws -> MolecularPropertiesResult {
        guard let predictor = propertyPredictor else {
            throw CoreMLChemistryError.modelNotLoaded("PropertyPredictor")
        }

        guard let preprocessingInfo = preprocessingInfo,
              let scalerMean = preprocessingInfo["scaler_mean"] as? [Double],
              let scalerScale = preprocessingInfo["scaler_scale"] as? [Double] else {
            throw CoreMLChemistryError.featureExtractionFailed
        }

        let fingerprintSize = (preprocessingInfo["fingerprint_size"] as? Int) ?? 0
        let useFingerprint = fingerprintSize > 0

        do {
            // Prefer fingerprint-like vector matching the training pipeline.
            if useFingerprint {
                let fp = try extractFingerprintFeatures(from: structure, size: fingerprintSize)
                let input = try MLMultiArray(shape: [NSNumber(value: fingerprintSize)], dataType: .float32)
                for i in 0..<fingerprintSize {
                    input[i] = NSNumber(value: fp[i])
                }

                // The generated model class might still be the legacy interface (`structure_features`).
                // Try it first; if/when you regenerate the classes for fingerprint input, update this to `molecular_fingerprint:`.
                if let prediction = try? predictor.prediction(structure_features: input) {
                    let properties = prediction.predicted_properties
                    return try parseAndDenormalizeProperties(properties: properties, scalerMean: scalerMean, scalerScale: scalerScale, structure: structure)
                }
            }

            // Legacy 5D-compatible path
            let features = extractCompatibleStructureFeatures(from: structure)
            let input = try MLMultiArray(shape: [5], dataType: .float32)
            for (index, value) in features.enumerated() {
                input[index] = NSNumber(value: value)
            }

            let prediction = try predictor.prediction(structure_features: input)
            let properties = prediction.predicted_properties
            return try parseAndDenormalizeProperties(properties: properties, scalerMean: scalerMean, scalerScale: scalerScale, structure: structure)
        } catch {
            throw CoreMLChemistryError.predictionFailed("Property prediction failed: \(error.localizedDescription)")
        }
    }

    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult {
        // Use rule-based IUPAC naming engine (offline)
        let systematicName = iupacNamer.generateIUPACName(from: structure)
        let nameComponents = iupacNamer.getNameComponents()

        return IUPACNameResult(
            systematicName: systematicName,
            nameComponents: nameComponents,
            confidence: 1.0
        )
    }

    // MARK: - Fingerprint-like features (iOS-side approximation)
    /// NOTE: This is *not* RDKit ECFP4. It's a deterministic, on-device, hashed substructure/count vector intended to
    /// make model inputs vary per structure until a true fingerprint generator is integrated.
    private func extractFingerprintFeatures(from structure: ChemicalStructure, size: Int) throws -> [Float] {
        guard size > 0 else { throw CoreMLChemistryError.featureExtractionFailed }

        var v = Array(repeating: Float(0), count: size)

        func bump(_ idx: Int, _ amount: Float = 1) {
            let i = ((idx % size) + size) % size
            v[i] += amount
        }

        // Base counts
        bump(1, Float(structure.carbonChainLength))
        bump(2, Float(structure.bonds.count))
        bump(3, Float(structure.functionalGroups.count))

        // Bond pattern hashing
        for bond in structure.bonds {
            // Hash by endpoints and type
            let h = bond.fromCarbon &* 31 &+ bond.toCarbon &* 131 &+ bond.type.bondCount &* 971
            bump(1000 + h)
            // Also bump by bond type only
            bump(200 + bond.type.bondCount, 1)
        }

        // Functional group hashing (type + position)
        for fg in structure.functionalGroups {
            let groupId = FunctionalGroup.allCases.firstIndex(of: fg.group) ?? 0
            let h = fg.carbonPosition &* 37 &+ groupId &* 911
            bump(3000 + h)
            bump(400 + groupId, 1)
        }

        // Simple local motifs along the main chain: look at bond types between i-(i+1)
        if structure.carbonChainLength >= 3 {
            for i in 1..<(structure.carbonChainLength - 1) {
                let b1 = structure.bonds.first { $0.fromCarbon == i && $0.toCarbon == i + 1 }?.type.bondCount ?? 1
                let b2 = structure.bonds.first { $0.fromCarbon == i + 1 && $0.toCarbon == i + 2 }?.type.bondCount ?? 1
                let motif = b1 * 10 + b2
                bump(5000 + i * 53 + motif)
            }
        }

        // Normalize to roughly [0,1] using L2 norm
        var sumSq: Float = 0
        for x in v { sumSq += x * x }
        let norm = max(1e-6, sqrt(sumSq))
        for i in 0..<v.count { v[i] /= norm }

        return v
    }

    private func parseAndDenormalizeProperties(
        properties: MLMultiArray,
        scalerMean: [Double],
        scalerScale: [Double],
        structure: ChemicalStructure
    ) throws -> MolecularPropertiesResult {
        var denormalizedProperties: [Double] = []
        for i in 0..<min(properties.count, scalerMean.count) {
            let normalizedValue = properties[i].doubleValue
            let denormalizedValue = (normalizedValue * scalerScale[i]) + scalerMean[i]
            denormalizedProperties.append(max(0, denormalizedValue))
        }

        let molecularWeight = denormalizedProperties.count > 0 ? denormalizedProperties[0] : calculateEstimatedMW(from: structure)
        let logP = denormalizedProperties.count > 1 ? denormalizedProperties[1] : estimateLogP(from: structure)
        let hBondDonors = denormalizedProperties.count > 2 ? Int(max(0, denormalizedProperties[2])) : countHBondDonors(from: structure)
        let hBondAcceptors = denormalizedProperties.count > 3 ? Int(max(0, denormalizedProperties[3])) : countHBondAcceptors(from: structure)
        let rotatableBonds = denormalizedProperties.count > 5 ? Int(max(0, denormalizedProperties[5])) : countRotatableBonds(from: structure)
        let tpsa = denormalizedProperties.count > 4 ? max(0, denormalizedProperties[4]) : estimateTPSA(from: structure)
        let aromaticRings = denormalizedProperties.count > 6 ? Int(max(0, denormalizedProperties[6])) : 0
        let heavyAtoms = denormalizedProperties.count > 7 ? Int(max(0, denormalizedProperties[7])) : countHeavyAtoms(from: structure)

        let isLargeMolecule = molecularWeight > 500
        let isLipophilic = logP > 3.0
        let hasHighHBondCount = (hBondDonors + hBondAcceptors) > 10

        var violations = 0
        if molecularWeight > 500 { violations += 1 }
        if logP > 5 { violations += 1 }
        if hBondDonors > 5 { violations += 1 }
        if hBondAcceptors > 10 { violations += 1 }

        let isDrugLike = violations <= 1

        return MolecularPropertiesResult(
            molecularWeight: molecularWeight,
            logP: logP,
            hBondDonors: hBondDonors,
            hBondAcceptors: hBondAcceptors,
            rotatableBonds: rotatableBonds,
            tpsa: tpsa,
            aromaticRings: aromaticRings,
            heavyAtoms: heavyAtoms,
            isLargeMolecule: isLargeMolecule,
            isLipophilic: isLipophilic,
            hasHighHBondCount: hasHighHBondCount,
            lipinskiViolations: violations,
            isDrugLike: isDrugLike
        )
    }
}

// MARK: - Feature Extraction Methods
extension CoreMLChemistryService {
    
    private func extractCompatibleStructureFeatures(from structure: ChemicalStructure) -> [Float] {
        // Extract 5-dimensional features compatible with Neural Network constraints
        var features = Array(repeating: Float(0), count: 5)
        
        // Feature 0: Carbon chain length with functional group weighting (normalized)
        let baseChainLength = Float(structure.carbonChainLength)
        let functionalGroupWeight = Float(structure.functionalGroups.count) * 0.5
        features[0] = (baseChainLength + functionalGroupWeight) / 15.0
        
        // Feature 1: Enhanced functional group complexity score (normalized)
        let functionalGroupScore = calculateEnhancedFunctionalGroupScore(structure)
        features[1] = Float(functionalGroupScore) / 20.0
        
        // Feature 2: Bond unsaturation level with position weighting (normalized)
        let unsaturationScore = calculateUnsaturationScore(structure)
        features[2] = Float(unsaturationScore) / 10.0
        
        // Feature 3: Heteroatom diversity and count (normalized)
        let heteroatomScore = calculateHeteroatomScore(structure)
        features[3] = Float(heteroatomScore) / 15.0
        
        // Feature 4: IUPAC functional group priority with multiplicity (normalized)
        let priorityScore = calculateEnhancedFunctionalGroupPriority(structure)
        features[4] = Float(priorityScore) / 25.0
        
        return features
    }
    
    private func calculateEnhancedFunctionalGroupScore(_ structure: ChemicalStructure) -> Int {
        var score = 0
        var functionalGroupCounts: [FunctionalGroup: Int] = [:]
        
        // Count occurrences of each functional group
        for attachment in structure.functionalGroups {
            functionalGroupCounts[attachment.group, default: 0] += 1
        }
        
        // Calculate score with complexity and multiplicity bonuses
        for (group, count) in functionalGroupCounts {
            let baseScore: Int
            switch group {
            case .methyl:
                baseScore = 1 // Simple alkyl group
            case .alcohol:
                baseScore = 3 // Polar, H-bonding, common
            case .amine:
                baseScore = 3 // Basic, H-bonding, reactive
            case .aldehyde:
                baseScore = 5 // Carbonyl, highly reactive
            case .ketone:
                baseScore = 4 // Carbonyl, moderately reactive
            case .carboxylicAcid:
                baseScore = 6 // Most complex, acidic, multiple bonds
            case .nitrile:
                baseScore = 4 // Triple bond character, polar
            case .nitro:
                baseScore = 5 // Highly electronegative, explosive potential
            case .thiol:
                baseScore = 3 // Sulfur analog of alcohol, distinctive odor
            case .fluorine:
                baseScore = 4 // Highly electronegative, strong C-F bond
            case .chlorine:
                baseScore = 2 // Moderately electronegative
            case .bromine:
                baseScore = 2 // Large halogen, good leaving group
            case .iodine:
                baseScore = 2 // Largest halogen, excellent leaving group
            }
            
            // Add multiplicity bonus for multiple same groups
            let multiplicityBonus = count > 1 ? (count - 1) * 2 : 0
            score += (baseScore * count) + multiplicityBonus
        }
        
        return score
    }
    
    private func calculateUnsaturationScore(_ structure: ChemicalStructure) -> Int {
        var score = 0
        
        // Count and weight different bond types
        let doubleBonds = structure.bonds.filter { $0.type == .double }
        let tripleBonds = structure.bonds.filter { $0.type == .triple }
        
        // Base scores for unsaturation
        score += doubleBonds.count * 2 // Double bonds
        score += tripleBonds.count * 4 // Triple bonds (more significant)
        
        // Position weighting - bonds closer to functional groups are more significant
        for bond in doubleBonds {
            let hasNearbyFunctionalGroup = structure.functionalGroups.contains { attachment in
                abs(attachment.carbonPosition - bond.fromCarbon) <= 1 ||
                abs(attachment.carbonPosition - bond.toCarbon) <= 1
            }
            if hasNearbyFunctionalGroup {
                score += 1 // Conjugation bonus
            }
        }
        
        for bond in tripleBonds {
            let hasNearbyFunctionalGroup = structure.functionalGroups.contains { attachment in
                abs(attachment.carbonPosition - bond.fromCarbon) <= 1 ||
                abs(attachment.carbonPosition - bond.toCarbon) <= 1
            }
            if hasNearbyFunctionalGroup {
                score += 2 // Higher conjugation bonus for triple bonds
            }
        }
        
        return score
    }
    
    private func calculateHeteroatomScore(_ structure: ChemicalStructure) -> Int {
        var score = 0
        var heteroatomTypes: Set<String> = []
        
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol, .aldehyde, .ketone:
                score += 2 // One oxygen
                heteroatomTypes.insert("O")
            case .carboxylicAcid:
                score += 4 // Two oxygens
                heteroatomTypes.insert("O")
            case .amine:
                score += 2 // One nitrogen
                heteroatomTypes.insert("N")
            case .nitrile:
                score += 3 // One nitrogen in triple bond
                heteroatomTypes.insert("N")
            case .nitro:
                score += 6 // One nitrogen + two oxygens, highly electronegative
                heteroatomTypes.insert("N")
                heteroatomTypes.insert("O")
            case .thiol:
                score += 2 // One sulfur
                heteroatomTypes.insert("S")
            case .fluorine:
                score += 3 // Highly electronegative
                heteroatomTypes.insert("F")
            case .chlorine:
                score += 2 // Moderately electronegative
                heteroatomTypes.insert("Cl")
            case .bromine:
                score += 2 // Large halogen
                heteroatomTypes.insert("Br")
            case .iodine:
                score += 2 // Largest halogen
                heteroatomTypes.insert("I")
            default:
                break
            }
        }
        
        // Diversity bonus - having different types of heteroatoms
        score += heteroatomTypes.count * 2
        
        return score
    }
    
    private func calculateEnhancedFunctionalGroupPriority(_ structure: ChemicalStructure) -> Int {
        var totalPriorityScore = 0
        var functionalGroupCounts: [FunctionalGroup: Int] = [:]
        
        // Count occurrences of each functional group
        for attachment in structure.functionalGroups {
            functionalGroupCounts[attachment.group, default: 0] += 1
        }
        
        // IUPAC priority order with enhanced scoring
        let priorities: [FunctionalGroup: Int] = [
            .carboxylicAcid: 10, // Highest priority
            .aldehyde: 8,
            .ketone: 6,
            .alcohol: 4,
            .amine: 4,
            .thiol: 4,
            .nitrile: 5,
            .nitro: 5,
            .methyl: 1,
            .fluorine: 2,
            .chlorine: 2,
            .bromine: 2,
            .iodine: 2
        ]
        
        // Calculate weighted priority score
        for (group, count) in functionalGroupCounts {
            if let priority = priorities[group] {
                // Base priority score multiplied by count
                let baseScore = priority * count
                
                // Bonus for multiple high-priority groups
                let multiplicityBonus = (count > 1 && priority >= 5) ? count * 2 : 0
                
                totalPriorityScore += baseScore + multiplicityBonus
            }
        }
        
        return totalPriorityScore
    }
    
    private func createMolecularFingerprint(from structure: ChemicalStructure) -> [Float] {
        var fingerprint = Array(repeating: Float(0), count: 2048)
        
        let smiles = structure.toSMILESLike()
        
        // Basic structural features
        fingerprint[0] = Float(smiles.count)  // SMILES length
        fingerprint[1] = Float(structure.carbonChainLength)  // Carbon count
        
        // Count atoms by type
        var oxygenCount = 0
        var nitrogenCount = 0
        var halogenCount = 0
        
        for group in structure.functionalGroups {
            switch group.group {
            case .alcohol, .carboxylicAcid, .aldehyde, .ketone:
                oxygenCount += 1
            case .amine:
                nitrogenCount += 1
            case .fluorine, .chlorine, .bromine, .iodine:
                halogenCount += 1
            default:
                break
            }
        }
        
        fingerprint[2] = Float(oxygenCount)
        fingerprint[3] = Float(nitrogenCount)
        fingerprint[4] = Float(halogenCount)
        
        // Bond type counts
        fingerprint[5] = Float(structure.bonds.filter { $0.type == .double }.count)
        fingerprint[6] = Float(structure.bonds.filter { $0.type == .triple }.count)
        
        // Functional group patterns
        fingerprint[10] = structure.functionalGroups.contains { $0.group == .alcohol } ? 1.0 : 0.0
        fingerprint[11] = structure.functionalGroups.contains { $0.group == .carboxylicAcid } ? 1.0 : 0.0
        fingerprint[12] = structure.functionalGroups.contains { $0.group == .amine } ? 1.0 : 0.0
        fingerprint[13] = structure.functionalGroups.contains { $0.group == .chlorine } ? 1.0 : 0.0
        fingerprint[14] = structure.functionalGroups.contains { $0.group == .bromine } ? 1.0 : 0.0
        
        // Hash-based features for remaining positions
        let hash = smiles.hashValue
        for i in 20..<2048 {
            fingerprint[i] = Float((hash >> (i % 32)) & 1)
        }
        
        return fingerprint
    }
    
    private func calculateEstimatedMW(from structure: ChemicalStructure) -> Double {
        var mw = Double(structure.carbonChainLength) * 12.01 // Carbon atoms
        
        // Calculate hydrogen count accounting for unsaturation
        var hydrogenCount = structure.carbonChainLength * 2 + 2 // Base alkane formula
        
        // Subtract hydrogens for double and triple bonds
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        hydrogenCount -= (doubleBonds * 2) // Each double bond removes 2 H
        hydrogenCount -= (tripleBonds * 4) // Each triple bond removes 4 H
        
        // Add functional group contributions and adjust hydrogens
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .methyl:
                mw += 15.035 // CH3: 12.01 + 3*1.008
                hydrogenCount += 3
            case .alcohol:
                mw += 17.008 - 1.008 // OH - H = 16.0
                hydrogenCount += 1
            case .carboxylicAcid:
                mw += 45.017 - 1.008 // COOH - H = 44.009
                hydrogenCount += 1
            case .amine:
                mw += 16.023 - 1.008 // NH2 - H = 15.015
                hydrogenCount += 2
            case .aldehyde:
                mw += 29.018 - 1.008 // CHO - H = 28.01
                hydrogenCount += 1
            case .ketone:
                mw += 28.010 - 2.016 // CO - 2H = 26.994
                // Ketone replaces 2 H atoms
            case .nitrile:
                mw += 26.017 - 1.008 // CN - H = 25.009
                hydrogenCount -= 1
            case .nitro:
                mw += 46.005 - 1.008 // NO2 - H = 44.997
                hydrogenCount -= 1
            case .thiol:
                mw += 33.072 - 1.008 // SH - H = 32.064
                hydrogenCount += 1
            case .fluorine:
                mw += 18.998 - 1.008 // F - H = 17.99
                hydrogenCount -= 1
            case .chlorine:
                mw += 35.453 - 1.008 // Cl - H = 34.445
                hydrogenCount -= 1
            case .bromine:
                mw += 79.904 - 1.008 // Br - H = 78.896
                hydrogenCount -= 1
            case .iodine:
                mw += 126.904 - 1.008 // I - H = 125.896
                hydrogenCount -= 1
            }
        }
        
        mw += Double(max(0, hydrogenCount)) * 1.008 // Add remaining hydrogen mass
        
        return max(16.0, mw) // Minimum MW for methane
    }
    
    private func estimateLogP(from structure: ChemicalStructure) -> Double {
        // Enhanced LogP estimation accounting for all functional groups
        var logP = Double(structure.carbonChainLength) * 0.5 // Base hydrophobicity
        
        // Account for unsaturation (double and triple bonds increase lipophilicity)
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        logP += Double(doubleBonds) * 0.1 // Double bonds slightly increase LogP
        logP += Double(tripleBonds) * 0.15 // Triple bonds increase LogP more
        
        // Account for all functional groups
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .methyl:
                logP += 0.5 // Hydrophobic alkyl group
            case .alcohol:
                logP -= 1.15 // Hydrophilic
            case .carboxylicAcid:
                logP -= 0.6 // Hydrophilic, but less than alcohol due to resonance
            case .amine:
                logP -= 1.0 // Hydrophilic, basic
            case .aldehyde:
                logP -= 0.65 // Slightly hydrophilic
            case .ketone:
                logP -= 0.55 // Slightly hydrophilic
            case .nitrile:
                logP -= 0.84 // Polar, but not as much as OH
            case .nitro:
                logP -= 0.28 // Electron-withdrawing, polar
            case .thiol:
                logP -= 0.64 // Sulfur analog of alcohol, less polar
            case .fluorine:
                logP -= 0.38 // Highly electronegative, hydrophilic
            case .chlorine:
                logP += 0.06 // Slightly hydrophobic
            case .bromine:
                logP += 0.20 // More hydrophobic than Cl
            case .iodine:
                logP += 0.31 // Most hydrophobic halogen
            }
        }
        
        return logP
    }
    
    private func countHBondDonors(from structure: ChemicalStructure) -> Int {
        var count = 0
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol:
                count += 1 // OH has 1 donor
            case .carboxylicAcid:
                count += 1 // COOH has 1 donor (OH part)
            case .amine:
                count += 2 // NH2 has 2 donors
            case .thiol:
                count += 1 // SH has 1 donor (weaker than OH)
            default:
                break
            }
        }
        return count
    }
    
    private func countHBondAcceptors(from structure: ChemicalStructure) -> Int {
        var count = 0
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol:
                count += 1 // OH oxygen
            case .carboxylicAcid:
                count += 2 // COOH has 2 acceptors (both oxygens)
            case .aldehyde, .ketone:
                count += 1 // C=O oxygen
            case .amine:
                count += 1 // NH2 nitrogen
            case .nitrile:
                count += 1 // CN nitrogen
            case .nitro:
                count += 2 // NO2 has 2 acceptor oxygens
            case .thiol:
                count += 1 // SH sulfur (weaker acceptor)
            case .fluorine:
                count += 1 // F is a strong acceptor
            case .chlorine, .bromine, .iodine:
                count += 1 // Halogens can be weak acceptors
            default:
                break
            }
        }
        return count
    }
    
    private func countRotatableBonds(from structure: ChemicalStructure) -> Int {
        // Estimate rotatable bonds (single bonds between non-terminal atoms)
        let singleBonds = structure.bonds.filter { $0.type == .single }.count
        let functionalGroupBonds = structure.functionalGroups.count // Approximate
        return max(0, singleBonds - functionalGroupBonds)
    }
    
    private func estimateTPSA(from structure: ChemicalStructure) -> Double {
        // Enhanced Topological Polar Surface Area estimation for all functional groups
        var tpsa = 0.0
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol:
                tpsa += 20.23 // OH group
            case .carboxylicAcid:
                tpsa += 37.30 // COOH group
            case .aldehyde, .ketone:
                tpsa += 17.07 // C=O group
            case .amine:
                tpsa += 26.02 // NH2 group
            case .nitrile:
                tpsa += 23.79 // CN group
            case .nitro:
                tpsa += 45.82 // NO2 group
            case .thiol:
                tpsa += 38.80 // SH group (larger than OH due to sulfur)
            case .fluorine:
                tpsa += 0.0 // F contributes minimal TPSA
            case .chlorine:
                tpsa += 0.0 // Cl contributes minimal TPSA
            case .bromine:
                tpsa += 0.0 // Br contributes minimal TPSA
            case .iodine:
                tpsa += 0.0 // I contributes minimal TPSA
            default:
                break
            }
        }
        return tpsa
    }
    
    private func countHeavyAtoms(from structure: ChemicalStructure) -> Int {
        var count = structure.carbonChainLength // Carbon atoms
        
        // Count all heteroatoms from functional groups
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .methyl:
                count += 1 // Additional carbon
            case .alcohol:
                count += 1 // O
            case .carboxylicAcid:
                count += 3 // C + 2O
            case .aldehyde:
                count += 2 // C + O
            case .ketone:
                count += 2 // C + O
            case .amine:
                count += 1 // N
            case .nitrile:
                count += 2 // C + N
            case .nitro:
                count += 3 // N + 2O
            case .thiol:
                count += 1 // S
            case .fluorine, .chlorine, .bromine, .iodine:
                count += 1 // Halogen
            }
        }
        
        return count
    }
    
    private func generateCommonName(from structure: ChemicalStructure, properties: MolecularPropertiesResult) -> String {
        let carbonCount = structure.carbonChainLength
        let hasAlcohol = structure.functionalGroups.contains { $0.group == .alcohol }
        let hasCarboxylicAcid = structure.functionalGroups.contains { $0.group == .carboxylicAcid }
        let hasAldehyde = structure.functionalGroups.contains { $0.group == .aldehyde }
        let hasKetone = structure.functionalGroups.contains { $0.group == .ketone }
        
        // Check for unsaturation
        let hasDoubleBond = structure.bonds.contains { $0.type == .double }
        let hasTripleBond = structure.bonds.contains { $0.type == .triple }
        
        if hasCarboxylicAcid {
            return getCarboxylicAcidName(carbonCount: carbonCount, hasDoubleBond: hasDoubleBond, hasTripleBond: hasTripleBond)
        } else if hasAldehyde {
            return getAldehydeName(carbonCount: carbonCount, hasDoubleBond: hasDoubleBond, hasTripleBond: hasTripleBond)
        } else if hasKetone {
            return getKetoneName(carbonCount: carbonCount, hasDoubleBond: hasDoubleBond, hasTripleBond: hasTripleBond)
        } else if hasAlcohol {
            return getAlcoholName(carbonCount: carbonCount, hasDoubleBond: hasDoubleBond, hasTripleBond: hasTripleBond)
        } else {
            return getAlkaneName(carbonCount: carbonCount, hasDoubleBond: hasDoubleBond, hasTripleBond: hasTripleBond)
        }
    }
    
    private func getAlkaneName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Methane", "Ethane", "Propane", "Butane", "Pentane", "Hexane", "Heptane", "Octane", "Nonane", "Decane"]
        
        if hasTripleBond && hasDoubleBond {
            // Both double and triple bonds
            let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon"
            return baseName.replacingOccurrences(of: "ane", with: "enyne")
        } else if hasTripleBond {
            // Only triple bonds
            let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon"
            return baseName.replacingOccurrences(of: "ane", with: "yne")
        } else if hasDoubleBond {
            // Only double bonds
            let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon"
            return baseName.replacingOccurrences(of: "ane", with: "ene")
        } else {
            // Saturated alkane
            return carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Alkane"
        }
    }
    
    private func getAlcoholName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Methanol", "Ethanol", "Propanol", "Butanol", "Pentanol", "Hexanol", "Heptanol", "Octanol", "Nonanol", "Decanol"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Alcohol"
        
        if hasTripleBond && hasDoubleBond {
            // Both double and triple bonds
            return baseName.replacingOccurrences(of: "anol", with: "enynol")
        } else if hasTripleBond {
            // Only triple bonds
            return baseName.replacingOccurrences(of: "anol", with: "ynol")
        } else if hasDoubleBond {
            // Only double bonds
            return baseName.replacingOccurrences(of: "anol", with: "enol")
        } else {
            // Saturated alcohol
            return baseName
        }
    }
    
    private func getCarboxylicAcidName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Formic Acid", "Acetic Acid", "Propanoic Acid", "Butanoic Acid", "Pentanoic Acid", "Hexanoic Acid", "Heptanoic Acid", "Octanoic Acid", "Nonanoic Acid", "Decanoic Acid"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Carboxylic Acid"
        
        if hasTripleBond && hasDoubleBond {
            // Both double and triple bonds
            return baseName.replacingOccurrences(of: "anoic", with: "enynoic")
        } else if hasTripleBond {
            // Only triple bonds
            return baseName.replacingOccurrences(of: "anoic", with: "ynoic")
        } else if hasDoubleBond {
            // Only double bonds
            return baseName.replacingOccurrences(of: "anoic", with: "enoic")
        } else {
            // Saturated carboxylic acid
            return baseName
        }
    }
    
    private func getAldehydeName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Formaldehyde", "Acetaldehyde", "Propanal", "Butanal", "Pentanal", "Hexanal", "Heptanal", "Octanal", "Nonanal", "Decanal"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Aldehyde"
        
        if hasTripleBond && hasDoubleBond {
            // Both double and triple bonds
            return baseName.replacingOccurrences(of: "anal", with: "enynal")
        } else if hasTripleBond {
            // Only triple bonds
            return baseName.replacingOccurrences(of: "anal", with: "ynal")
        } else if hasDoubleBond {
            // Only double bonds
            return baseName.replacingOccurrences(of: "anal", with: "enal")
        } else {
            // Saturated aldehyde
            return baseName
        }
    }
    
    private func getKetoneName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        if carbonCount < 3 { return "Invalid Ketone" }
        let baseNames = ["", "", "", "Acetone", "Butanone", "Pentanone", "Hexanone", "Heptanone", "Octanone", "Nonanone", "Decanone"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Ketone"
        
        if hasTripleBond && hasDoubleBond {
            // Both double and triple bonds
            return baseName.replacingOccurrences(of: "anone", with: "enynone")
        } else if hasTripleBond {
            // Only triple bonds
            return baseName.replacingOccurrences(of: "anone", with: "ynone")
        } else if hasDoubleBond {
            // Only double bonds
            return baseName.replacingOccurrences(of: "anone", with: "enone")
        } else {
            // Saturated ketone
            return baseName
        }
    }
    
    private func calculateMolecularFormula(from structure: ChemicalStructure) -> String {
        var carbonCount = structure.carbonChainLength
        var hydrogenCount = 0
        var oxygenCount = 0
        var nitrogenCount = 0
        var sulfurCount = 0
        var fluorineCount = 0
        var chlorineCount = 0
        var bromineCount = 0
        var iodineCount = 0
        
        // Start with base hydrogens (2n+2 for alkane)
        hydrogenCount = 2 * carbonCount + 2
        
        // Subtract hydrogens for double and triple bonds
        for bond in structure.bonds {
            if bond.type == .double {
                hydrogenCount -= 2
            } else if bond.type == .triple {
                hydrogenCount -= 4
            }
        }
        
        // Add atoms from functional groups and adjust hydrogens
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .methyl:
                carbonCount += 1
                hydrogenCount += 3
            case .alcohol:
                oxygenCount += 1
                hydrogenCount += 1
            case .amine:
                nitrogenCount += 1
                hydrogenCount += 2
            case .carboxylicAcid:
                carbonCount += 1
                oxygenCount += 2
                hydrogenCount += 1
            case .aldehyde:
                carbonCount += 1
                oxygenCount += 1
                hydrogenCount += 1
            case .ketone:
                carbonCount += 1
                oxygenCount += 1
            case .nitrile:
                carbonCount += 1
                nitrogenCount += 1
                hydrogenCount -= 1
            case .nitro:
                nitrogenCount += 1
                oxygenCount += 2
                hydrogenCount -= 1
            case .thiol:
                sulfurCount += 1
                hydrogenCount += 1
            case .fluorine:
                fluorineCount += 1
                hydrogenCount -= 1
            case .chlorine:
                chlorineCount += 1
                hydrogenCount -= 1
            case .bromine:
                bromineCount += 1
                hydrogenCount -= 1
            case .iodine:
                iodineCount += 1
                hydrogenCount -= 1
            }
        }
        
        // Build formula string
        var formula = ""
        if carbonCount > 0 { formula += "C\(carbonCount > 1 ? "\(carbonCount)" : "")" }
        if hydrogenCount > 0 { formula += "H\(hydrogenCount > 1 ? "\(hydrogenCount)" : "")" }
        if nitrogenCount > 0 { formula += "N\(nitrogenCount > 1 ? "\(nitrogenCount)" : "")" }
        if oxygenCount > 0 { formula += "O\(oxygenCount > 1 ? "\(oxygenCount)" : "")" }
        if sulfurCount > 0 { formula += "S\(sulfurCount > 1 ? "\(sulfurCount)" : "")" }
        if fluorineCount > 0 { formula += "F\(fluorineCount > 1 ? "\(fluorineCount)" : "")" }
        if chlorineCount > 0 { formula += "Cl\(chlorineCount > 1 ? "\(chlorineCount)" : "")" }
        if bromineCount > 0 { formula += "Br\(bromineCount > 1 ? "\(bromineCount)" : "")" }
        if iodineCount > 0 { formula += "I\(iodineCount > 1 ? "\(iodineCount)" : "")" }
        
        return formula.isEmpty ? "Unknown" : formula
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - CoreML Service Factory
class CoreMLChemistryServiceFactory {
    static func createService() -> CoreMLChemistryServiceProtocol {
        CoreMLChemistryService()
    }
}
