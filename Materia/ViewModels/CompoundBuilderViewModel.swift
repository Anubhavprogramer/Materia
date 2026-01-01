//
//  CompoundBuilderViewModel.swift
//  Materia
//
//  ViewModel for the compound builder screen
//

import Foundation
import SwiftUI

@MainActor
class CompoundBuilderViewModel: ObservableObject {
    @Published var carbonChainLength: Int = 3
    @Published var structure: ChemicalStructure
    @Published var validationError: String?
    @Published var isBuilding: Bool = false
    
    init() {
        self.structure = ChemicalStructure(carbonChainLength: 3)
    }
    
    // MARK: - Carbon Chain Management
    func updateCarbonChainLength(_ length: Int) {
        carbonChainLength = length
        structure = ChemicalStructure(carbonChainLength: length)
        validateStructure()
    }
    
    // MARK: - Bond Management
    func addBond(from: Int, to: Int, type: BondType) {
        // Remove existing bond between these carbons
        structure.bonds.removeAll { bond in
            (bond.fromCarbon == from && bond.toCarbon == to) ||
            (bond.fromCarbon == to && bond.toCarbon == from)
        }
        
        // Add new bond
        structure.bonds.append(Bond(from: from, to: to, type: type))
        validateStructure()
    }
    
    func removeBond(from: Int, to: Int) {
        structure.bonds.removeAll { bond in
            (bond.fromCarbon == from && bond.toCarbon == to) ||
            (bond.fromCarbon == to && bond.toCarbon == from)
        }
        validateStructure()
    }
    
    func getBondType(from: Int, to: Int) -> BondType? {
        return structure.bonds.first { bond in
            (bond.fromCarbon == from && bond.toCarbon == to) ||
            (bond.fromCarbon == to && bond.toCarbon == from)
        }?.type
    }
    
    // MARK: - Functional Group Management
    func addFunctionalGroup(_ group: FunctionalGroup, at position: Int) {
        // Remove existing groups of the same type at this position
        structure.functionalGroups.removeAll { attachment in
            attachment.carbonPosition == position && attachment.group == group
        }
        
        // Add new functional group
        structure.functionalGroups.append(FunctionalGroupAttachment(position: position, group: group))
        validateStructure()
    }
    
    func removeFunctionalGroup(_ group: FunctionalGroup, at position: Int) {
        structure.functionalGroups.removeAll { attachment in
            attachment.carbonPosition == position && attachment.group == group
        }
        validateStructure()
    }
    
    func getFunctionalGroups(at position: Int) -> [FunctionalGroup] {
        return structure.functionalGroups
            .filter { $0.carbonPosition == position }
            .map { $0.group }
    }
    
    // MARK: - Validation
    func validateStructure() {
        let (isValid, error) = structure.isValid()
        validationError = isValid ? nil : error
    }
    
    var isValidStructure: Bool {
        validationError == nil
    }
    
    // MARK: - Structure Building
    func buildCompound() async -> IdentifiedCompound? {
        guard isValidStructure else { return nil }
        
        isBuilding = true
        defer { isBuilding = false }
        
        // Simulate Apple Intelligence processing
        // In a real app, this would call Apple Intelligence API
        let result = await identifyCompound(from: structure)
        return result
    }
    
    // MARK: - Mock Apple Intelligence Service
    private func identifyCompound(from structure: ChemicalStructure) async -> IdentifiedCompound {
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Simple compound identification logic
        let smiles = structure.toSMILESLike()
        let (name, formula, category) = identifyFromSMILES(smiles, structure: structure)
        
        return IdentifiedCompound(
            structure: structure,
            name: name,
            formula: formula,
            category: category
        )
    }
    
    private func identifyFromSMILES(_ smiles: String, structure: ChemicalStructure) -> (String, String, String) {
        // Basic compound identification based on structure patterns
        let carbonCount = structure.carbonChainLength
        let hasAlcohol = structure.functionalGroups.contains { $0.group == .alcohol }
        let hasCarboxylicAcid = structure.functionalGroups.contains { $0.group == .carboxylicAcid }
        let hasAldehyde = structure.functionalGroups.contains { $0.group == .aldehyde }
        let hasKetone = structure.functionalGroups.contains { $0.group == .ketone }
        let hasAmine = structure.functionalGroups.contains { $0.group == .amine }
        
        var name: String
        var category = "Organic"
        
        // Identify based on functional groups
        if hasCarboxylicAcid {
            name = getCarboxylicAcidName(carbonCount: carbonCount)
        } else if hasAldehyde {
            name = getAldehydeName(carbonCount: carbonCount)
        } else if hasKetone {
            name = getKetoneName(carbonCount: carbonCount)
        } else if hasAlcohol {
            name = getAlcoholName(carbonCount: carbonCount)
        } else if hasAmine {
            name = getAmineName(carbonCount: carbonCount)
        } else {
            name = getAlkaneName(carbonCount: carbonCount)
        }
        
        // Calculate molecular formula
        let formula = calculateMolecularFormula(structure: structure)
        
        return (name, formula, category)
    }
    
    // MARK: - Compound Naming Helpers
    private func getAlkaneName(carbonCount: Int) -> String {
        let prefixes = ["", "Methane", "Ethane", "Propane", "Butane", "Pentane", 
                       "Hexane", "Heptane", "Octane", "Nonane", "Decane"]
        return carbonCount <= 10 ? prefixes[carbonCount] : "\(carbonCount)-Carbon Alkane"
    }
    
    private func getAlcoholName(carbonCount: Int) -> String {
        let prefixes = ["", "Methanol", "Ethanol", "Propanol", "Butanol", "Pentanol",
                       "Hexanol", "Heptanol", "Octanol", "Nonanol", "Decanol"]
        return carbonCount <= 10 ? prefixes[carbonCount] : "\(carbonCount)-Carbon Alcohol"
    }
    
    private func getCarboxylicAcidName(carbonCount: Int) -> String {
        let prefixes = ["", "Formic Acid", "Acetic Acid", "Propanoic Acid", "Butanoic Acid", 
                       "Pentanoic Acid", "Hexanoic Acid", "Heptanoic Acid", "Octanoic Acid", 
                       "Nonanoic Acid", "Decanoic Acid"]
        return carbonCount <= 10 ? prefixes[carbonCount] : "\(carbonCount)-Carbon Carboxylic Acid"
    }
    
    private func getAldehydeName(carbonCount: Int) -> String {
        let prefixes = ["", "Formaldehyde", "Acetaldehyde", "Propanal", "Butanal", 
                       "Pentanal", "Hexanal", "Heptanal", "Octanal", "Nonanal", "Decanal"]
        return carbonCount <= 10 ? prefixes[carbonCount] : "\(carbonCount)-Carbon Aldehyde"
    }
    
    private func getKetoneName(carbonCount: Int) -> String {
        if carbonCount < 3 { return "Invalid Ketone" }
        let prefixes = ["", "", "", "Acetone", "Butanone", "Pentanone",
                       "Hexanone", "Heptanone", "Octanone", "Nonanone", "Decanone"]
        return carbonCount <= 10 ? prefixes[carbonCount] : "\(carbonCount)-Carbon Ketone"
    }
    
    private func getAmineName(carbonCount: Int) -> String {
        let prefixes = ["", "Methylamine", "Ethylamine", "Propylamine", "Butylamine", 
                       "Pentylamine", "Hexylamine", "Heptylamine", "Octylamine", 
                       "Nonylamine", "Decylamine"]
        return carbonCount <= 10 ? prefixes[carbonCount] : "\(carbonCount)-Carbon Amine"
    }
    
    // MARK: - Molecular Formula Calculation
    private func calculateMolecularFormula(structure: ChemicalStructure) -> String {
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