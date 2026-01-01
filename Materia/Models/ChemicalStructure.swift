//
//  ChemicalStructure.swift
//  Materia
//
//  Core data models for chemical structures and compounds
//

import Foundation

// MARK: - Bond Types
enum BondType: String, CaseIterable, Codable {
    case single = "single"
    case double = "double"
    case triple = "triple"
    
    var symbol: String {
        switch self {
        case .single: return "—"
        case .double: return "="
        case .triple: return "≡"
        }
    }
    
    var bondCount: Int {
        switch self {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }
}

// MARK: - Functional Groups
enum FunctionalGroup: String, CaseIterable, Codable {
    case methyl = "CH3"
    case alcohol = "OH"
    case amine = "NH2"
    case carboxylicAcid = "COOH"
    case aldehyde = "CHO"
    case ketone = "CO"
    case nitrile = "CN"
    case nitro = "NO2"
    case thiol = "SH"
    case fluorine = "F"
    case chlorine = "Cl"
    case bromine = "Br"
    case iodine = "I"
    
    var displayName: String {
        switch self {
        case .methyl: return "Methyl (CH₃)"
        case .alcohol: return "Alcohol (OH)"
        case .amine: return "Amine (NH₂)"
        case .carboxylicAcid: return "Carboxylic Acid (COOH)"
        case .aldehyde: return "Aldehyde (CHO)"
        case .ketone: return "Ketone (CO)"
        case .nitrile: return "Nitrile (CN)"
        case .nitro: return "Nitro (NO₂)"
        case .thiol: return "Thiol (SH)"
        case .fluorine: return "Fluorine (F)"
        case .chlorine: return "Chlorine (Cl)"
        case .bromine: return "Bromine (Br)"
        case .iodine: return "Iodine (I)"
        }
    }
    
    var bondCount: Int {
        switch self {
        case .methyl, .alcohol, .amine, .thiol, .fluorine, .chlorine, .bromine, .iodine:
            return 1
        case .carboxylicAcid, .aldehyde, .ketone, .nitrile, .nitro:
            return 1 // Simplified for this implementation
        }
    }
}

// MARK: - Bond Structure
struct Bond: Identifiable, Codable {
    let id = UUID()
    let fromCarbon: Int
    let toCarbon: Int
    let type: BondType
    
    init(from: Int, to: Int, type: BondType = .single) {
        self.fromCarbon = min(from, to)
        self.toCarbon = max(from, to)
        self.type = type
    }
}

// MARK: - Functional Group Attachment
struct FunctionalGroupAttachment: Identifiable, Codable {
    let id = UUID()
    let carbonPosition: Int
    let group: FunctionalGroup
    
    init(position: Int, group: FunctionalGroup) {
        self.carbonPosition = position
        self.group = group
    }
}

// MARK: - Chemical Structure
struct ChemicalStructure: Identifiable, Codable {
    let id = UUID()
    let carbonChainLength: Int
    var bonds: [Bond]
    var functionalGroups: [FunctionalGroupAttachment]
    let createdAt: Date
    
    init(carbonChainLength: Int) {
        self.carbonChainLength = carbonChainLength
        self.bonds = []
        self.functionalGroups = []
        self.createdAt = Date()
        
        // Add default single bonds between adjacent carbons
        for i in 1..<carbonChainLength {
            bonds.append(Bond(from: i, to: i + 1))
        }
    }
    
    // MARK: - Validation
    func isValid() -> (Bool, String?) {
        // Check carbon valency (max 4 bonds per carbon)
        var carbonBondCounts = Array(repeating: 0, count: carbonChainLength + 1)
        
        // Count bonds between carbons
        for bond in bonds {
            carbonBondCounts[bond.fromCarbon] += bond.type.bondCount
            carbonBondCounts[bond.toCarbon] += bond.type.bondCount
        }
        
        // Count functional group bonds
        for attachment in functionalGroups {
            carbonBondCounts[attachment.carbonPosition] += attachment.group.bondCount
        }
        
        // Check for violations
        for (index, bondCount) in carbonBondCounts.enumerated() {
            if index > 0 && bondCount > 4 {
                return (false, "Carbon \(index) has too many bonds (\(bondCount)/4)")
            }
        }
        
        return (true, nil)
    }
    
    // MARK: - SMILES-like representation
    func toSMILESLike() -> String {
        var result = ""
        
        // Build basic carbon chain
        for i in 1...carbonChainLength {
            result += "C"
            
            // Add functional groups at this position
            let groupsAtPosition = functionalGroups.filter { $0.carbonPosition == i }
            for group in groupsAtPosition {
                result += "(\(group.group.rawValue))"
            }
            
            // Add bond to next carbon if not last
            if i < carbonChainLength {
                let bondToNext = bonds.first { $0.fromCarbon == i && $0.toCarbon == i + 1 }
                if let bond = bondToNext, bond.type != .single {
                    result += bond.type.symbol
                }
            }
        }
        
        return result
    }
}

// MARK: - Identified Compound
struct IdentifiedCompound: Identifiable, Codable {
    let id = UUID()
    let structure: ChemicalStructure
    let compoundName: String
    let molecularFormula: String
    let category: String
    let identifiedAt: Date
    
    init(structure: ChemicalStructure, name: String, formula: String, category: String) {
        self.structure = structure
        self.compoundName = name
        self.molecularFormula = formula
        self.category = category
        self.identifiedAt = Date()
    }
}