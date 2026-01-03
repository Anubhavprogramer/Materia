//
//  UpdatedCoreMLChemistryService.swift
//  Materia
//
//  Updated CoreML-based chemistry analysis service using custom trained models
//

import Foundation
import CoreML

// MARK: - Updated Service Protocol
protocol CoreMLChemistryServiceProtocol {
    func analyzeCompound(from structure: ChemicalStructure) async throws -> CompoundAnalysisResult
    func validateStructure(_ structure: ChemicalStructure) async throws -> StructureValidationResult
    func predictProperties(from structure: ChemicalStructure) async throws -> MolecularPropertiesResult
    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult
}

// MARK: - Updated Result Types
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
        
        // Analyze functional groups
        let functionalGroups = analyzeFunctionalGroups(structure)
        
        // Determine principal functional group
        let principalGroup = getPrincipalGroup(functionalGroups)
        
        // Generate name
        if let principal = principalGroup,
           let suffix = functionalGroupSuffixes[principal] {
            return baseName + suffix
        } else {
            return baseName + "ane"
        }
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

// MARK: - Updated CoreML Service Implementation
@MainActor
class CoreMLChemistryService: CoreMLChemistryServiceProtocol {
    
    // MARK: - Models
    private var propertyPredictor: Materia_PropertyPredictor?
    private var structureValidator: Materia_StructureValidator?
    private var iupacNamer: IUPACNamer
    
    // MARK: - Preprocessing Info
    private var targetProperties: [String] = []
    private var scalerMean: [Double] = []
    private var scalerScale: [Double] = []
    
    // MARK: - Initialization
    init() {
        self.iupacNamer = IUPACNamer()
        Task {
            await loadModels()
            await loadPreprocessingInfo()
        }
    }
    
    private func loadModels() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPropertyPredictor() }
            group.addTask { await self.loadStructureValidator() }
        }
    }
    
    private func loadPropertyPredictor() async {
        do {
            propertyPredictor = try Materia_PropertyPredictor()
            print("✅ Custom Property Predictor loaded successfully")
        } catch {
            print("❌ Failed to load Custom Property Predictor: \(error)")
        }
    }
    
    private func loadStructureValidator() async {
        do {
            structureValidator = try Materia_StructureValidator()
            print("✅ Custom Structure Validator loaded successfully")
        } catch {
            print("❌ Failed to load Custom Structure Validator: \(error)")
        }
    }
    
    private func loadPreprocessingInfo() async {
        guard let path = Bundle.main.path(forResource: "preprocessing_info", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️  Could not load preprocessing info, using defaults")
            setupDefaultPreprocessing()
            return
        }
        
        targetProperties = json["target_properties"] as? [String] ?? []
        scalerMean = json["scaler_mean"] as? [Double] ?? []
        scalerScale = json["scaler_scale"] as? [Double] ?? []
        
        print("✅ Preprocessing info loaded")
    }
    
    private func setupDefaultPreprocessing() {
        targetProperties = [
            "molecular_weight", "logp", "hbd", "hba", 
            "tpsa", "rotatable_bonds", "aromatic_rings", "heavy_atoms"
        ]
        // Default scaling parameters (would be replaced with actual values)
        scalerMean = Array(repeating: 0.0, count: targetProperties.count)
        scalerScale = Array(repeating: 1.0, count: targetProperties.count)
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
            // Generate molecular fingerprint
            let fingerprint = generateMolecularFingerprint(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [1, 2048], dataType: .float32)
            for (index, value) in fingerprint.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try validator.prediction(molecular_fingerprint: input)
            
            // Extract probability (assuming single output)
            let outputName = prediction.featureNames.first ?? "output"
            let outputValue = prediction.featureValue(for: outputName)
            
            let validityProbability = outputValue?.doubleValue ?? 0.5
            let isValid = validityProbability > 0.5
            
            let message = isValid ? 
                "Structure appears chemically valid" : 
                "Structure may have valency or stability issues"
            
            return StructureValidationResult(
                isValid: isValid,
                confidence: abs(validityProbability - 0.5) * 2, // Convert to 0-1 confidence
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
            // Generate molecular fingerprint
            let fingerprint = generateMolecularFingerprint(from: structure)
            
            // Prepare input
            let input = try MLMultiArray(shape: [1, 2048], dataType: .float32)
            for (index, value) in fingerprint.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            // Make prediction
            let prediction = try predictor.prediction(molecular_fingerprint: input)
            
            // Extract predictions (assuming single output array)
            let outputName = prediction.featureNames.first ?? "output"
            let outputValue = prediction.featureValue(for: outputName)
            
            guard let outputArray = outputValue?.multiArrayValue else {
                throw CoreMLChemistryError.predictionFailed("Could not extract prediction array")
            }
            
            // Inverse transform predictions using scaler
            var scaledProperties: [Double] = []
            for i in 0..<min(outputArray.count, targetProperties.count) {
                let scaledValue = outputArray[i].doubleValue
                let originalValue = scaledValue * scalerScale[i] + scalerMean[i]
                scaledProperties.append(originalValue)
            }
            
            // Map to result structure
            let molecularWeight = scaledProperties.count > 0 ? scaledProperties[0] : 0.0
            let logP = scaledProperties.count > 1 ? scaledProperties[1] : 0.0
            let hbd = scaledProperties.count > 2 ? Int(max(0, scaledProperties[2])) : 0
            let hba = scaledProperties.count > 3 ? Int(max(0, scaledProperties[3])) : 0
            let tpsa = scaledProperties.count > 4 ? max(0, scaledProperties[4]) : 0.0
            let rotatableBonds = scaledProperties.count > 5 ? Int(max(0, scaledProperties[5])) : 0
            let aromaticRings = scaledProperties.count > 6 ? Int(max(0, scaledProperties[6])) : 0
            let heavyAtoms = scaledProperties.count > 7 ? Int(max(0, scaledProperties[7])) : 0
            
            // Calculate derived properties
            let lipinskiViolations = [
                molecularWeight > 500,
                logP > 5,
                hbd > 5,
                hba > 10
            ].filter { $0 }.count
            
            return MolecularPropertiesResult(
                molecularWeight: molecularWeight,
                logP: logP,
                hBondDonors: hbd,
                hBondAcceptors: hba,
                rotatableBonds: rotatableBonds,
                tpsa: tpsa,
                aromaticRings: aromaticRings,
                heavyAtoms: heavyAtoms,
                isLargeMolecule: molecularWeight > 500,
                isLipophilic: logP > 3,
                hasHighHBondCount: (hbd + hba) > 10,
                lipinskiViolations: lipinskiViolations,
                isDrugLike: lipinskiViolations <= 1
            )
            
        } catch {
            throw CoreMLChemistryError.predictionFailed("Property prediction failed: \(error.localizedDescription)")
        }
    }
    
    func generateIUPACName(from structure: ChemicalStructure) async throws -> IUPACNameResult {
        // Use rule-based IUPAC namer
        let systematicName = iupacNamer.generateIUPACName(from: structure)
        let components = iupacNamer.getNameComponents()
        
        return IUPACNameResult(
            systematicName: systematicName,
            nameComponents: components,
            confidence: 0.95  // High confidence for rule-based approach
        )
    }
}

// MARK: - Feature Extraction Methods
extension CoreMLChemistryService {
    
    private func generateMolecularFingerprint(from structure: ChemicalStructure) -> [Float] {
        var fingerprint = Array(repeating: Float(0), count: 2048)
        
        // Generate fingerprint based on structure
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
        
        // Functional group patterns (one-hot encoding)
        fingerprint[10] = structure.functionalGroups.contains { $0.group == .alcohol } ? 1.0 : 0.0
        fingerprint[11] = structure.functionalGroups.contains { $0.group == .carboxylicAcid } ? 1.0 : 0.0
        fingerprint[12] = structure.functionalGroups.contains { $0.group == .amine } ? 1.0 : 0.0
        fingerprint[13] = structure.functionalGroups.contains { $0.group == .aldehyde } ? 1.0 : 0.0
        fingerprint[14] = structure.functionalGroups.contains { $0.group == .ketone } ? 1.0 : 0.0
        fingerprint[15] = structure.functionalGroups.contains { $0.group == .chlorine } ? 1.0 : 0.0
        fingerprint[16] = structure.functionalGroups.contains { $0.group == .bromine } ? 1.0 : 0.0
        fingerprint[17] = structure.functionalGroups.contains { $0.group == .fluorine } ? 1.0 : 0.0
        fingerprint[18] = structure.functionalGroups.contains { $0.group == .iodine } ? 1.0 : 0.0
        
        // Hash-based features for remaining positions
        let hash = smiles.hashValue
        for i in 20..<2048 {
            fingerprint[i] = Float((hash >> (i % 32)) & 1)
        }
        
        return fingerprint
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

// MARK: - Error Types
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

// MARK: - Service Factory
class CoreMLChemistryServiceFactory {
    @MainActor
    static func createService() -> CoreMLChemistryServiceProtocol {
        return CoreMLChemistryService()
    }
}