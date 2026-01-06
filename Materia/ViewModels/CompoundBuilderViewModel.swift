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
    var LOAD: String = "Compound Builder ViewModel"
    @Published var carbonChainLength: Int = 3
    @Published var structure: ChemicalStructure
    @Published var validationError: String?
    @Published var isBuilding: Bool = false
    @Published var validationResult: StructureValidationResult?
    @Published var isValidating: Bool = false
    
    private let coreMLService: CoreMLChemistryServiceProtocol
    
    init(coreMLService: CoreMLChemistryServiceProtocol? = nil) {
        self.coreMLService = coreMLService ?? CoreMLChemistryServiceFactory.createService()
        self.structure = ChemicalStructure(carbonChainLength: 3)
    }
    
    init(initialStructure: ChemicalStructure, coreMLService: CoreMLChemistryServiceProtocol? = nil) {
        self.coreMLService = coreMLService ?? CoreMLChemistryServiceFactory.createService()
        self.structure = initialStructure
        self.carbonChainLength = initialStructure.carbonChainLength

        // Ensure validation state is up-to-date.
        validateStructure()
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
        
        // Perform CoreML validation in background
        if isValid {
            performCoreMLValidation()
        } else {
            validationResult = nil
        }
    }
    
    private func performCoreMLValidation() {
        isValidating = true
        
        Task {
            do {
                let result = try await coreMLService.validateStructure(structure)
                await MainActor.run {
                    self.validationResult = result
                    self.isValidating = false
                    
                    // Update validation error if CoreML says it's invalid
                    if !result.isValid {
                        self.validationError = result.validationMessage
                    }
                }
            } catch {
                await MainActor.run {
                    self.isValidating = false
                    CommonFunctions.debugPrint(load: LOAD, message: "CoreML validation failed: \(error)")
                }
            }
        }
    }
    
    var isValidStructure: Bool {
        if let coreMLResult = validationResult {
            return validationError == nil && coreMLResult.isValid
        }
        return validationError == nil
    }
    
    // MARK: - Structure Building
    func buildCompound() async -> IdentifiedCompound? {
        guard isValidStructure else { return nil }
        
        isBuilding = true
        defer { isBuilding = false }
        
        do {
            // Use CoreML service to analyze compound
            let result = try await coreMLService.analyzeCompound(from: structure)
            
            return IdentifiedCompound(
                structure: structure,
                name: result.commonName,
                iupacName: result.iupacName,
                formula: result.molecularFormula,
                category: result.category,
                confidence: result.confidence,
                isValidated: result.isValid
            )
            
        } catch {
            CommonFunctions.debugPrint(load: LOAD, message: "Failed to analyze compound:\(error)")
            return nil
        }
    }
}
