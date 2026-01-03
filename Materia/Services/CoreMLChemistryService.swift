//
//  CoreMLChemistryService.swift
//  Materia
//
//  CoreML-based chemistry analysis service using ChemAI models
//

import Foundation
import CoreML

// MARK: - CoreML Service Protocol
protocol CoreMLChemistryServiceProtocol {
    func analyzeCompound(from structure: ChemicalStructure) async throws -> CompoundAnalysisResult
    func validateStructure(_ structure: ChemicalStructure) async throws -> StructureValidationResult
    func predictProperties(from structure: ChemicalStructure) async throws -> MolecularPropertiesResult
    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult
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
    let invalidProbability: Double
    let validProbability: Double
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
    let isLargeMolecule: Bool
    let isLipophilic: Bool
    let hasHighHBondCount: Bool
}

struct IUPACNameResult {
    let systematicName: String
    let nameComponents: [String]
    let confidence: Double
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
@MainActor
class CoreMLChemistryService: CoreMLChemistryServiceProtocol {
    
    // MARK: - Models
    private var propertyPredictor: ChemAI_PropertyPredictor?
    private var iupacNamer: ChemAI_IUPACNamer?
    private var structureValidator: ChemAI_StructureValidator?
    private var reactionPredictor: ChemAI_ReactionPredictor?
    var LOAD: String = "CoreML Chemistry Service"
    
    // MARK: - Initialization
    init() {
        Task {
            await loadModels()
        }
    }
    
    private func loadModels() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPropertyPredictor() }
            group.addTask { await self.loadIUPACNamer() }
            group.addTask { await self.loadStructureValidator() }
            group.addTask { await self.loadReactionPredictor() }
        }
    }
    
    private func loadPropertyPredictor() async {
        do {
            propertyPredictor = try ChemAI_PropertyPredictor()
            CommonFunctions.MessagePrint(load: LOAD, message: "✅ Property Predictor loaded successfully")
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load Property Predictor: \(error)")
        }
    }
    
    private func loadIUPACNamer() async {
        do {
            iupacNamer = try ChemAI_IUPACNamer()
            CommonFunctions.MessagePrint(load: LOAD, message: "✅ IUPAC Namer loaded successfully")
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load IUPAC Namer: \(error)")
        }
    }
    
    private func loadStructureValidator() async {
        do {
            structureValidator = try ChemAI_StructureValidator()
            CommonFunctions.MessagePrint(load: LOAD, message: "✅ Structure Validator loaded successfully")
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load Structure Validator: \(error)")
        }
    }
    
    private func loadReactionPredictor() async {
        do {
            reactionPredictor = try ChemAI_ReactionPredictor()
            CommonFunctions.MessagePrint(load: LOAD, message: "✅ Reaction Predictor loaded successfully")
        } catch {
            CommonFunctions.MessagePrint(load: LOAD, message: "❌ Failed to load Reaction Predictor: \(error)")
        }
    }
    
    // MARK: - Public Methods
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
        
        do {
            // Extract structure features
            let features = extractStructureFeatures(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [1, 50], dataType: .float32)
            for (index, value) in features.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try validator.prediction(structure_features: input)
            let validationOutput = prediction.validation_result
            
            // Parse results
            let invalidProb = validationOutput[0].doubleValue
            let validProb = validationOutput[1].doubleValue
            
            let isValid = validProb > invalidProb
            let confidence = max(validProb, invalidProb)
            
            let message = isValid ? 
                "Structure appears chemically valid" : 
                "Structure may have valency or stability issues"
            
            return StructureValidationResult(
                isValid: isValid,
                confidence: confidence,
                invalidProbability: invalidProb,
                validProbability: validProb,
                validationMessage: message
            )
            
        } catch {
            throw CoreMLChemistryError.predictionFailed("Structure validation failed: \(error.localizedDescription)")
        }
    }
    
    func predictProperties(from structure: ChemicalStructure) async throws -> MolecularPropertiesResult {
        guard let predictor = propertyPredictor else {
            throw CoreMLChemistryError.modelNotLoaded("PropertyPredictor")
        }
        
        do {
            // Create molecular fingerprint
            let fingerprint = createMolecularFingerprint(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [1, 2048], dataType: .float32)
            for (index, value) in fingerprint.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try predictor.prediction(molecular_fingerprint: input)
            let properties = prediction.predicted_properties
            
            // Parse results
            return MolecularPropertiesResult(
                molecularWeight: properties[0].doubleValue,
                logP: properties[1].doubleValue,
                hBondDonors: Int(properties[2].doubleValue),
                hBondAcceptors: Int(properties[3].doubleValue),
                rotatableBonds: Int(properties[4].doubleValue),
                tpsa: properties[5].doubleValue,
                aromaticRings: Int(properties[6].doubleValue),
                isLargeMolecule: properties[7].doubleValue > 0.5,
                isLipophilic: properties[8].doubleValue > 0.5,
                hasHighHBondCount: properties[9].doubleValue > 0.5
            )
            
        } catch {
            throw CoreMLChemistryError.predictionFailed("Property prediction failed: \(error.localizedDescription)")
        }
    }
    
    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult {
        guard let namer = iupacNamer else {
            throw CoreMLChemistryError.modelNotLoaded("IUPACNamer")
        }
        
        do {
            // Extract structure features
            let features = extractStructureFeatures(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [1, 50], dataType: .float32)
            for (index, value) in features.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try namer.prediction(structure_features: input)
            let nameTokens = prediction.name_tokens
            
            // Parse name tokens
            let result = parseNameTokens(nameTokens, structure: structure)
            
            return result
            
        } catch {
            throw CoreMLChemistryError.predictionFailed("IUPAC naming failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Feature Extraction Methods
extension CoreMLChemistryService {
    
    private func extractStructureFeatures(from structure: ChemicalStructure) -> [Float] {
        var features = Array(repeating: Float(0), count: 50)
        
        // Basic structure features
        features[0] = Float(structure.carbonChainLength)
        features[1] = Float(structure.functionalGroups.count)
        features[2] = Float(structure.bonds.count)
        
        // Functional group counts (one-hot encoding)
        let functionalGroupTypes: [FunctionalGroup] = [
            .methyl, .alcohol, .amine, .carboxylicAcid, .aldehyde, 
            .ketone, .chlorine, .bromine, .fluorine, .iodine
        ]
        
        for (index, groupType) in functionalGroupTypes.enumerated() {
            let count = structure.functionalGroups.filter { $0.group == groupType }.count
            features[3 + index] = Float(count)
        }
        
        // Bond type distribution
        let singleBonds = structure.bonds.filter { $0.type == .single }.count
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        
        features[13] = Float(singleBonds)
        features[14] = Float(doubleBonds)
        features[15] = Float(tripleBonds)
        
        // Functional group flags
        features[16] = structure.functionalGroups.contains { $0.group == .alcohol } ? 1.0 : 0.0
        features[17] = structure.functionalGroups.contains { $0.group == .carboxylicAcid } ? 1.0 : 0.0
        features[18] = structure.functionalGroups.contains { $0.group == .amine } ? 1.0 : 0.0
        features[19] = structure.functionalGroups.contains { $0.group == .aldehyde } ? 1.0 : 0.0
        features[20] = structure.functionalGroups.contains { $0.group == .ketone } ? 1.0 : 0.0
        
        // Additional structural features
        features[21] = Float(structure.carbonChainLength) / 10.0  // Normalized chain length
        features[22] = Float(structure.bonds.count) / Float(max(structure.carbonChainLength - 1, 1))  // Bond density
        
        return features
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
    
    private func parseNameTokens(_ tokens: MLMultiArray, structure: ChemicalStructure) -> IUPACNameResult {
        // Create IUPAC vocabulary (simplified)
        let vocabulary = createIUPACVocabulary()
        
        // Find top probability tokens
        var topTokens: [(index: Int, probability: Double)] = []
        
        for i in 0..<min(tokens.count, vocabulary.count) {
            let prob = tokens[i].doubleValue
            if prob > 0.1 {
                topTokens.append((index: i, probability: prob))
            }
        }
        
        // Sort by probability
        topTokens.sort { $0.probability > $1.probability }
        
        // Convert to name components
        let nameComponents = topTokens.prefix(5).compactMap { 
            vocabulary[safe: $0.index] 
        }
        
        // Construct systematic name
        let systematicName = constructIUPACName(from: structure, components: nameComponents)
        let confidence = topTokens.first?.probability ?? 0.0
        
        return IUPACNameResult(
            systematicName: systematicName,
            nameComponents: nameComponents,
            confidence: confidence
        )
    }
    
    private func createIUPACVocabulary() -> [String] {
        return [
            "meth", "eth", "prop", "but", "pent", "hex", "hept", "oct", "non", "dec",
            "ane", "ene", "yne", "ol", "al", "one", "oic", "acid", "amine", "yl",
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
            "chloro", "bromo", "fluoro", "iodo", "hydroxy", "amino", "carboxy",
            "methyl", "ethyl", "propyl", "butyl", "pentyl"
        ]
    }
    
    private func constructIUPACName(from structure: ChemicalStructure, components: [String]) -> String {
        // Simplified IUPAC name construction
        let carbonCount = structure.carbonChainLength
        let hasAlcohol = structure.functionalGroups.contains { $0.group == .alcohol }
        let hasCarboxylicAcid = structure.functionalGroups.contains { $0.group == .carboxylicAcid }
        let hasAldehyde = structure.functionalGroups.contains { $0.group == .aldehyde }
        let hasKetone = structure.functionalGroups.contains { $0.group == .ketone }
        
        // Base name
        let baseName = getBaseName(carbonCount: carbonCount)
        
        // Suffix based on functional groups
        var suffix = "ane"
        if hasCarboxylicAcid {
            suffix = "anoic acid"
        } else if hasAldehyde {
            suffix = "anal"
        } else if hasKetone {
            suffix = "anone"
        } else if hasAlcohol {
            suffix = "anol"
        }
        
        return baseName + suffix
    }
    
    private func getBaseName(carbonCount: Int) -> String {
        let baseNames = ["", "meth", "eth", "prop", "but", "pent", "hex", "hept", "oct", "non", "dec"]
        return carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-carbon"
    }
    
    private func generateCommonName(from structure: ChemicalStructure, properties: MolecularPropertiesResult) -> String {
        let carbonCount = structure.carbonChainLength
        let hasAlcohol = structure.functionalGroups.contains { $0.group == .alcohol }
        let hasCarboxylicAcid = structure.functionalGroups.contains { $0.group == .carboxylicAcid }
        let hasAldehyde = structure.functionalGroups.contains { $0.group == .aldehyde }
        let hasKetone = structure.functionalGroups.contains { $0.group == .ketone }
        
        if hasCarboxylicAcid {
            return getCarboxylicAcidName(carbonCount: carbonCount)
        } else if hasAldehyde {
            return getAldehydeName(carbonCount: carbonCount)
        } else if hasKetone {
            return getKetoneName(carbonCount: carbonCount)
        } else if hasAlcohol {
            return getAlcoholName(carbonCount: carbonCount)
        } else {
            return getAlkaneName(carbonCount: carbonCount)
        }
    }
    
    private func getAlkaneName(carbonCount: Int) -> String {
        let names = ["", "Methane", "Ethane", "Propane", "Butane", "Pentane", "Hexane", "Heptane", "Octane", "Nonane", "Decane"]
        return carbonCount <= 10 ? names[carbonCount] : "\(carbonCount)-Carbon Alkane"
    }
    
    private func getAlcoholName(carbonCount: Int) -> String {
        let names = ["", "Methanol", "Ethanol", "Propanol", "Butanol", "Pentanol", "Hexanol", "Heptanol", "Octanol", "Nonanol", "Decanol"]
        return carbonCount <= 10 ? names[carbonCount] : "\(carbonCount)-Carbon Alcohol"
    }
    
    private func getCarboxylicAcidName(carbonCount: Int) -> String {
        let names = ["", "Formic Acid", "Acetic Acid", "Propanoic Acid", "Butanoic Acid", "Pentanoic Acid", "Hexanoic Acid", "Heptanoic Acid", "Octanoic Acid", "Nonanoic Acid", "Decanoic Acid"]
        return carbonCount <= 10 ? names[carbonCount] : "\(carbonCount)-Carbon Carboxylic Acid"
    }
    
    private func getAldehydeName(carbonCount: Int) -> String {
        let names = ["", "Formaldehyde", "Acetaldehyde", "Propanal", "Butanal", "Pentanal", "Hexanal", "Heptanal", "Octanal", "Nonanal", "Decanal"]
        return carbonCount <= 10 ? names[carbonCount] : "\(carbonCount)-Carbon Aldehyde"
    }
    
    private func getKetoneName(carbonCount: Int) -> String {
        if carbonCount < 3 { return "Invalid Ketone" }
        let names = ["", "", "", "Acetone", "Butanone", "Pentanone", "Hexanone", "Heptanone", "Octanone", "Nonanone", "Decanone"]
        return carbonCount <= 10 ? names[carbonCount] : "\(carbonCount)-Carbon Ketone"
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
    @MainActor
    static func createService() -> CoreMLChemistryServiceProtocol {
        return CoreMLChemistryService()
    }
}
