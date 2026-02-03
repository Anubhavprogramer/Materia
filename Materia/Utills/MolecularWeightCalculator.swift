//
//  MolecularWeightCalculator.swift
//  Materia
//
//  Calculates molecular weight of compounds
//

import Foundation

// MARK: - Atomic Masses (in g/mol)
struct AtomicMass {
    static let carbon: Double = 12.011
    static let hydrogen: Double = 1.008
    static let oxygen: Double = 15.999
    static let nitrogen: Double = 14.007
    static let sulfur: Double = 32.06
    static let fluorine: Double = 18.998
    static let chlorine: Double = 35.45
    static let bromine: Double = 79.904
    static let iodine: Double = 126.90
}

// MARK: - Molecular Weight Calculator
class MolecularWeightCalculator {
    
    /// Calculate total molecular weight from a chemical structure
    static func calculateMolecularWeight(
        carbonChainLength: Int,
        bonds: [Bond],
        functionalGroups: [FunctionalGroupAttachment]
    ) -> Double {
        var weight: Double = 0.0
        
        // Add carbon atoms
        weight += Double(carbonChainLength) * AtomicMass.carbon
        
        // Calculate hydrogen count
        let hydrogenCount = calculateHydrogenCountInternal(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: functionalGroups
        )
        weight += Double(hydrogenCount) * AtomicMass.hydrogen
        
        // Add functional group atoms
        for attachment in functionalGroups {
            weight += getGroupAtomicWeight(attachment.group)
        }
        
        return weight
    }
    
    /// Calculate hydrogen atoms in the structure (internal)
    private static func calculateHydrogenCountInternal(
        carbonChainLength: Int,
        bonds: [Bond],
        functionalGroups: [FunctionalGroupAttachment]
    ) -> Int {
        var hydrogenCount = 0
        var carbonBondCounts = Array(repeating: 0, count: carbonChainLength + 1)
        
        // Count bonds between carbons
        for bond in bonds {
            carbonBondCounts[bond.fromCarbon] += bond.type.bondCount
            carbonBondCounts[bond.toCarbon] += bond.type.bondCount
        }
        
        // Count functional group bonds
        var groupHydrogens = 0
        for attachment in functionalGroups {
            carbonBondCounts[attachment.carbonPosition] += attachment.group.bondCount
            groupHydrogens += getGroupHydrogenCount(attachment.group)
        }
        
        // Calculate remaining hydrogens on carbons (max 4 bonds per carbon)
        for (index, bondCount) in carbonBondCounts.enumerated() {
            if index > 0 {
                let remainingBonds = 4 - bondCount
                hydrogenCount += remainingBonds
            }
        }
        
        // Add hydrogens from functional groups
        hydrogenCount += groupHydrogens
        
        return max(0, hydrogenCount)
    }
    
    /// Get atomic weight of a functional group (excluding the bond to carbon)
    private static func getGroupAtomicWeight(_ group: FunctionalGroup) -> Double {
        switch group {
        case .methyl:           return 2 * AtomicMass.hydrogen  // CH₃ minus C already counted
        case .alcohol:          return AtomicMass.oxygen + AtomicMass.hydrogen
        case .amine:            return AtomicMass.nitrogen + 2 * AtomicMass.hydrogen
        case .carboxylicAcid:   return AtomicMass.carbon + 2 * AtomicMass.oxygen + AtomicMass.hydrogen
        case .aldehyde:         return AtomicMass.carbon + AtomicMass.oxygen + AtomicMass.hydrogen
        case .ketone:           return AtomicMass.carbon + AtomicMass.oxygen
        case .nitrile:          return AtomicMass.carbon + AtomicMass.nitrogen
        case .nitro:            return 2 * AtomicMass.oxygen + AtomicMass.nitrogen
        case .thiol:            return AtomicMass.sulfur + AtomicMass.hydrogen
        case .fluorine:         return AtomicMass.fluorine
        case .chlorine:         return AtomicMass.chlorine
        case .bromine:          return AtomicMass.bromine
        case .iodine:           return AtomicMass.iodine
        }
    }
    
    /// Get hydrogen count contributed by a functional group
    private static func getGroupHydrogenCount(_ group: FunctionalGroup) -> Int {
        switch group {
        case .methyl:           return 3
        case .alcohol:          return 1
        case .amine:            return 2
        case .carboxylicAcid:   return 1
        case .aldehyde:         return 1
        case .ketone:           return 0
        case .nitrile:          return 0
        case .nitro:            return 0
        case .thiol:            return 1
        case .fluorine:         return 0
        case .chlorine:         return 0
        case .bromine:          return 0
        case .iodine:           return 0
        }
    }
    
    /// Get molecular formula as a string
    static func getMolecularFormula(
        carbonChainLength: Int,
        bonds: [Bond],
        functionalGroups: [FunctionalGroupAttachment]
    ) -> String {
        let hydrogenCount = calculateHydrogenCountInternal(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: functionalGroups
        )
        
        var formula = "C\(carbonChainLength)"
        if hydrogenCount > 0 {
            formula += "H\(hydrogenCount)"
        }
        
        // Add heteroatoms from functional groups
        var oxygenCount = 0
        var nitrogenCount = 0
        var sulfurCount = 0
        var halogens: [String: Int] = ["F": 0, "Cl": 0, "Br": 0, "I": 0]
        
        for attachment in functionalGroups {
            switch attachment.group {
            case .alcohol, .aldehyde, .ketone:
                oxygenCount += 1
            case .carboxylicAcid:
                oxygenCount += 2
            case .amine:
                nitrogenCount += 1
            case .nitro:
                nitrogenCount += 1
                oxygenCount += 2
            case .nitrile:
                nitrogenCount += 1
            case .thiol:
                sulfurCount += 1
            case .fluorine:
                halogens["F"]! += 1
            case .chlorine:
                halogens["Cl"]! += 1
            case .bromine:
                halogens["Br"]! += 1
            case .iodine:
                halogens["I"]! += 1
            case .methyl:
                break  // Already in carbon count
            }
        }
        
        if oxygenCount > 0 {
            formula += "O\(oxygenCount)"
        }
        if nitrogenCount > 0 {
            formula += "N\(nitrogenCount)"
        }
        if sulfurCount > 0 {
            formula += "S\(sulfurCount)"
        }
        
        for (element, count) in halogens.sorted(by: { $0.key < $1.key }) {
            if count > 0 {
                formula += "\(element)\(count)"
            }
        }
        
        return formula
    }
    
    /// Public method to calculate hydrogen count
    static func calculateHydrogenCount(
        carbonChainLength: Int,
        bonds: [Bond],
        functionalGroups: [FunctionalGroupAttachment]
    ) -> Int {
        return calculateHydrogenCountInternal(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: functionalGroups
        )
    }
}
