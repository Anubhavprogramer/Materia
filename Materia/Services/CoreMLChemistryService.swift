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

// MARK: - IUPAC Naming Engine
class IUPACNamer {
    private let alkaneNames = [
        "", "meth", "eth", "prop", "but", "pent", 
        "hex", "hept", "oct", "non", "dec"
    ]
    
    private let functionalGroupSuffixes: [String: String] = [
        "alcohol": "ol",
        "carboxylicAcid": "oic acid", 
        "aldehyde": "al",
        "ketone": "one",
        "amine": "amine",
        "thiol": "thiol"
    ]
    
    func generateIUPACName(from structure: ChemicalStructure) -> String {
        let chainLength = structure.carbonChainLength
        let baseName = getBaseName(chainLength: chainLength)
        
        // Analyze bond types
        let doubleBonds = structure.bonds.filter { $0.type == .double }
        let tripleBonds = structure.bonds.filter { $0.type == .triple }
        
        // Analyze functional groups
        let functionalGroups = analyzeFunctionalGroups(structure)
        
        // Determine principal functional group
        let principalGroup = getPrincipalGroup(functionalGroups)
        
        // Generate name based on bond types and functional groups
        var suffix = ""
        var prefix = ""
        
        // Handle unsaturation first
        if !tripleBonds.isEmpty {
            // Triple bonds take priority over double bonds
            if tripleBonds.count == 1 {
                suffix = "yne"
                if tripleBonds[0].fromCarbon > 1 {
                    prefix = "\(tripleBonds[0].fromCarbon)-"
                }
            } else {
                suffix = "yne" // Multiple triple bonds would need more complex naming
            }
        } else if !doubleBonds.isEmpty {
            // Double bonds
            if doubleBonds.count == 1 {
                suffix = "ene"
                if doubleBonds[0].fromCarbon > 1 {
                    prefix = "\(doubleBonds[0].fromCarbon)-"
                }
            } else {
                suffix = "ene" // Multiple double bonds would need more complex naming
            }
        } else {
            // Saturated compound
            suffix = "ane"
        }
        
        // Override suffix if there's a principal functional group
        if let principal = principalGroup,
           let functionalSuffix = functionalGroupSuffixes[principal] {
            // Modify the base suffix for functional groups
            if suffix == "ane" {
                suffix = functionalSuffix
            } else if suffix == "ene" {
                suffix = functionalSuffix.replacingOccurrences(of: "ane", with: "ene")
                    .replacingOccurrences(of: "oic acid", with: "enoic acid")
                    .replacingOccurrences(of: "al", with: "enal")
                    .replacingOccurrences(of: "one", with: "enone")
                    .replacingOccurrences(of: "ol", with: "enol")
            } else if suffix == "yne" {
                suffix = functionalSuffix.replacingOccurrences(of: "ane", with: "yne")
                    .replacingOccurrences(of: "oic acid", with: "ynoic acid")
                    .replacingOccurrences(of: "al", with: "ynal")
                    .replacingOccurrences(of: "one", with: "ynone")
                    .replacingOccurrences(of: "ol", with: "ynol")
            }
        }
        
        return prefix + baseName + suffix
    }
    
    private func getBaseName(chainLength: Int) -> String {
        if chainLength <= alkaneNames.count - 1 {
            return alkaneNames[chainLength]
        } else {
            return "\(chainLength)-carbon"
        }
    }
    
    private func analyzeFunctionalGroups(_ structure: ChemicalStructure) -> [String: [Int]] {
        var groups: [String: [Int]] = [:]
        
        for attachment in structure.functionalGroups {
            let groupType = classifyFunctionalGroup(attachment.group)
            if groups[groupType] == nil {
                groups[groupType] = []
            }
            groups[groupType]?.append(attachment.carbonPosition)
        }
        
        return groups
    }
    
    private func classifyFunctionalGroup(_ group: FunctionalGroup) -> String {
        switch group {
        case .alcohol: return "alcohol"
        case .carboxylicAcid: return "carboxylicAcid"
        case .aldehyde: return "aldehyde"
        case .ketone: return "ketone"
        case .amine: return "amine"
        case .thiol: return "thiol"
        default: return "other"
        }
    }
    
    private func getPrincipalGroup(_ groups: [String: [Int]]) -> String? {
        let priorities = [
            "carboxylicAcid": 4,
            "aldehyde": 3,
            "ketone": 2,
            "alcohol": 1
        ]
        
        var highestPriority = 0
        var principalGroup: String?
        
        for (group, _) in groups {
            if let priority = priorities[group], priority > highestPriority {
                highestPriority = priority
                principalGroup = group
            }
        }
        
        return principalGroup
    }
    
    func getNameComponents() -> [String] {
        return ["alkane", "alcohol", "carboxylic acid", "aldehyde", "ketone"]
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
@MainActor
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
            // Extract structure features (5-dimensional for compatibility)
            let features = extractCompatibleStructureFeatures(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [5], dataType: .float32)
            for (index, value) in features.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try validator.prediction(structure_features: input)
            let validationOutput = prediction.validation_result
            
            // Parse results - our model outputs a single probability
            let validProb = validationOutput[0].doubleValue
            let isValid = validProb > 0.5
            let confidence = abs(validProb - 0.5) * 2.0 // Convert to 0-1 confidence
            
            let message = isValid ? 
                "Structure appears chemically valid" : 
                "Structure may have valency or stability issues"
            
            return StructureValidationResult(
                isValid: isValid,
                confidence: confidence,
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
        
        guard let preprocessingInfo = preprocessingInfo,
              let scalerMean = preprocessingInfo["scaler_mean"] as? [Double],
              let scalerScale = preprocessingInfo["scaler_scale"] as? [Double] else {
            throw CoreMLChemistryError.featureExtractionFailed
        }
        
        do {
            // Extract structure features (5-dimensional for compatibility)
            let features = extractCompatibleStructureFeatures(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [5], dataType: .float32)
            for (index, value) in features.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try predictor.prediction(structure_features: input)
            let properties = prediction.predicted_properties
            
            // Denormalize predictions using scaler info
            var denormalizedProperties: [Double] = []
            for i in 0..<min(properties.count, scalerMean.count) {
                let normalizedValue = properties[i].doubleValue
                let denormalizedValue = (normalizedValue * scalerScale[i]) + scalerMean[i]
                denormalizedProperties.append(max(0, denormalizedValue)) // Ensure non-negative
            }
            
            // Parse results with fallback values
            let molecularWeight = denormalizedProperties.count > 0 ? denormalizedProperties[0] : calculateEstimatedMW(from: structure)
            let logP = denormalizedProperties.count > 1 ? denormalizedProperties[1] : estimateLogP(from: structure)
            let hBondDonors = denormalizedProperties.count > 2 ? Int(max(0, denormalizedProperties[2])) : countHBondDonors(from: structure)
            let hBondAcceptors = denormalizedProperties.count > 3 ? Int(max(0, denormalizedProperties[3])) : countHBondAcceptors(from: structure)
            let rotatableBonds = denormalizedProperties.count > 4 ? Int(max(0, denormalizedProperties[4])) : countRotatableBonds(from: structure)
            let tpsa = denormalizedProperties.count > 5 ? max(0, denormalizedProperties[5]) : estimateTPSA(from: structure)
            let aromaticRings = denormalizedProperties.count > 6 ? Int(max(0, denormalizedProperties[6])) : 0
            let heavyAtoms = denormalizedProperties.count > 7 ? Int(max(0, denormalizedProperties[7])) : countHeavyAtoms(from: structure)
            
            // Calculate derived properties
            let isLargeMolecule = molecularWeight > 500
            let isLipophilic = logP > 3.0
            let hasHighHBondCount = (hBondDonors + hBondAcceptors) > 10
            
            // Calculate Lipinski violations
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
            
        } catch {
            throw CoreMLChemistryError.predictionFailed("Property prediction failed: \(error.localizedDescription)")
        }
    }
    
    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult {
        // Use rule-based IUPAC naming engine
        let systematicName = iupacNamer.generateIUPACName(from: structure)
        let nameComponents = iupacNamer.getNameComponents()
        
        return IUPACNameResult(
            systematicName: systematicName,
            nameComponents: nameComponents,
            confidence: 1.0 // Rule-based system has high confidence
        )
    }
}

// MARK: - Feature Extraction Methods
extension CoreMLChemistryService {
    
    private func extractCompatibleStructureFeatures(from structure: ChemicalStructure) -> [Float] {
        // Extract 5-dimensional features compatible with Neural Network constraints
        var features = Array(repeating: Float(0), count: 5)
        
        // Feature 0: Carbon chain length (normalized)
        features[0] = Float(structure.carbonChainLength) / 10.0
        
        // Feature 1: Number of functional groups (normalized)
        features[1] = Float(structure.functionalGroups.count) / 5.0
        
        // Feature 2: Bond unsaturation level (normalized)
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        let unsaturationLevel = doubleBonds + (tripleBonds * 2) // Triple bonds count double
        features[2] = Float(unsaturationLevel) / 5.0
        
        // Feature 3: Oxygen-containing groups count
        var oxygenCount = 0
        for group in structure.functionalGroups {
            switch group.group {
            case .alcohol, .carboxylicAcid, .aldehyde, .ketone:
                oxygenCount += 1
            default:
                break
            }
        }
        features[3] = Float(oxygenCount) / 3.0
        
        // Feature 4: Nitrogen-containing groups count
        var nitrogenCount = 0
        for group in structure.functionalGroups {
            switch group.group {
            case .amine:
                nitrogenCount += 1
            default:
                break
            }
        }
        features[4] = Float(nitrogenCount) / 2.0
        
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
    
    private func calculateEstimatedMW(from structure: ChemicalStructure) -> Double {
        var mw = Double(structure.carbonChainLength) * 12.01 // Carbon atoms
        
        // Calculate hydrogen count accounting for unsaturation
        var hydrogenCount = structure.carbonChainLength * 2 + 2 // Base alkane formula
        
        // Subtract hydrogens for double and triple bonds
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        hydrogenCount -= (doubleBonds * 2) // Each double bond removes 2 H
        hydrogenCount -= (tripleBonds * 4) // Each triple bond removes 4 H
        
        mw += Double(max(0, hydrogenCount)) * 1.008 // Add hydrogen mass
        
        // Add functional group contributions
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol:
                mw += 16.0 - 1.008 // OH - H
            case .carboxylicAcid:
                mw += 45.0 - 1.008 // COOH - H
            case .amine:
                mw += 14.0 + 1.008 // NH2 - H
            case .aldehyde:
                mw += 16.0 - 1.008 // CHO - H
            case .ketone:
                mw += 16.0 - 2.016 // CO - 2H
            case .chlorine:
                mw += 35.45 - 1.008 // Cl - H
            case .bromine:
                mw += 79.9 - 1.008 // Br - H
            case .fluorine:
                mw += 19.0 - 1.008 // F - H
            case .iodine:
                mw += 126.9 - 1.008 // I - H
            default:
                break
            }
        }
        
        return max(16.0, mw) // Minimum MW for methane
    }
    
    private func estimateLogP(from structure: ChemicalStructure) -> Double {
        // Simple LogP estimation based on structure
        var logP = Double(structure.carbonChainLength) * 0.5 // Base hydrophobicity
        
        // Account for unsaturation (double and triple bonds increase lipophilicity)
        let doubleBonds = structure.bonds.filter { $0.type == .double }.count
        let tripleBonds = structure.bonds.filter { $0.type == .triple }.count
        logP += Double(doubleBonds) * 0.1 // Double bonds slightly increase LogP
        logP += Double(tripleBonds) * 0.15 // Triple bonds increase LogP more
        
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol:
                logP -= 1.15 // Hydrophilic
            case .carboxylicAcid:
                logP -= 0.6 // Hydrophilic
            case .amine:
                logP -= 1.0 // Hydrophilic
            case .aldehyde:
                logP -= 0.65 // Slightly hydrophilic
            case .ketone:
                logP -= 0.55 // Slightly hydrophilic
            case .chlorine:
                logP += 0.06 // Slightly hydrophobic
            case .bromine:
                logP += 0.20 // Hydrophobic
            case .fluorine:
                logP -= 0.38 // Hydrophilic
            default:
                break
            }
        }
        
        return logP
    }
    
    private func countHBondDonors(from structure: ChemicalStructure) -> Int {
        var count = 0
        for attachment in structure.functionalGroups {
            switch attachment.group {
            case .alcohol, .carboxylicAcid:
                count += 1
            case .amine:
                count += 2 // NH2 has 2 donors
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
                count += 2 // COOH has 2 acceptors
            case .aldehyde, .ketone:
                count += 1 // C=O oxygen
            case .amine:
                count += 1 // NH2 nitrogen
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
        // Topological Polar Surface Area estimation
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
            default:
                break
            }
        }
        return tpsa
    }
    
    private func countHeavyAtoms(from structure: ChemicalStructure) -> Int {
        var count = structure.carbonChainLength // Carbon atoms
        
        for attachment in structure.functionalGroups {
            switch attachment.group {
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
            case .chlorine, .bromine, .fluorine, .iodine:
                count += 1 // Halogen
            default:
                break
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
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon"
        
        if hasTripleBond {
            return baseName.replacingOccurrences(of: "ane", with: "yne")
        } else if hasDoubleBond {
            return baseName.replacingOccurrences(of: "ane", with: "ene")
        } else {
            return carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Alkane"
        }
    }
    
    private func getAlcoholName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Methanol", "Ethanol", "Propanol", "Butanol", "Pentanol", "Hexanol", "Heptanol", "Octanol", "Nonanol", "Decanol"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Alcohol"
        
        if hasTripleBond {
            return baseName.replacingOccurrences(of: "anol", with: "ynol")
        } else if hasDoubleBond {
            return baseName.replacingOccurrences(of: "anol", with: "enol")
        } else {
            return baseName
        }
    }
    
    private func getCarboxylicAcidName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Formic Acid", "Acetic Acid", "Propanoic Acid", "Butanoic Acid", "Pentanoic Acid", "Hexanoic Acid", "Heptanoic Acid", "Octanoic Acid", "Nonanoic Acid", "Decanoic Acid"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Carboxylic Acid"
        
        if hasTripleBond {
            return baseName.replacingOccurrences(of: "anoic", with: "ynoic")
        } else if hasDoubleBond {
            return baseName.replacingOccurrences(of: "anoic", with: "enoic")
        } else {
            return baseName
        }
    }
    
    private func getAldehydeName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        let baseNames = ["", "Formaldehyde", "Acetaldehyde", "Propanal", "Butanal", "Pentanal", "Hexanal", "Heptanal", "Octanal", "Nonanal", "Decanal"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Aldehyde"
        
        if hasTripleBond {
            return baseName.replacingOccurrences(of: "anal", with: "ynal")
        } else if hasDoubleBond {
            return baseName.replacingOccurrences(of: "anal", with: "enal")
        } else {
            return baseName
        }
    }
    
    private func getKetoneName(carbonCount: Int, hasDoubleBond: Bool = false, hasTripleBond: Bool = false) -> String {
        if carbonCount < 3 { return "Invalid Ketone" }
        let baseNames = ["", "", "", "Acetone", "Butanone", "Pentanone", "Hexanone", "Heptanone", "Octanone", "Nonanone", "Decanone"]
        let baseName = carbonCount <= 10 ? baseNames[carbonCount] : "\(carbonCount)-Carbon Ketone"
        
        if hasTripleBond {
            return baseName.replacingOccurrences(of: "anone", with: "ynone")
        } else if hasDoubleBond {
            return baseName.replacingOccurrences(of: "anone", with: "enone")
        } else {
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
    @MainActor
    static func createService() -> CoreMLChemistryServiceProtocol {
        return CoreMLChemistryService()
    }
}
