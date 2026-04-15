//
//  CompoundStorageService.swift
//  Materia
//
//  Service for managing compound storage using Core Data
//

import Foundation
import CoreData

final class CompoundStorageService {
    private let dataManager = DataManager()
    private let userDefaults = UserDefaults.standard
    private let savedCompoundsKey = "SavedCompounds"
    private var hasMigrated = false
    
    // MARK: - Fetch
    func fetchAllCompounds() -> [IdentifiedCompound] {
        // First, migrate from UserDefaults if needed
        migrateFromUserDefaults()
        
        // Load from Core Data (file system)
        let compounds = dataManager.fetchAll()
        
        // If no compounds, return empty array
        if compounds.isEmpty {
            return []
        }
        
        return compounds
    }
    
    // MARK: - Save
    func saveCompound(_ compound: IdentifiedCompound) {
        dataManager.save(compound)
    }
    
    // MARK: - Update
    func updateCompound(_ compound: IdentifiedCompound) {
        dataManager.save(compound)
    }
    
    // MARK: - Delete
    func deleteCompound(_ compound: IdentifiedCompound) {
        dataManager.delete(compound)
    }
    
    // MARK: - Migration from UserDefaults
    private func migrateFromUserDefaults() {
        guard !hasMigrated else { return }
        hasMigrated = true
        
        // Check if there's old UserDefaults data
        guard let data = userDefaults.data(forKey: savedCompoundsKey) else {
            return
        }
        
        do {
            let oldCompounds = try JSONDecoder().decode([IdentifiedCompound].self, from: data)
            
            // Save all old compounds to Core Data
            for compound in oldCompounds {
                dataManager.save(compound)
            }
            
            // Remove old UserDefaults data
            userDefaults.removeObject(forKey: savedCompoundsKey)
            
            print("✅ Migrated \(oldCompounds.count) compounds from UserDefaults to Core Data")
        } catch {
            print("Failed to migrate from UserDefaults: \(error)")
        }
    }
    
    // MARK: - Load Sample Compounds
    func loadSampleCompounds() -> [IdentifiedCompound] {
        // Create sample compounds for demonstration
        let ethanolStructure = ChemicalStructure(carbonChainLength: 2)
        var ethanol = ethanolStructure
        ethanol.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .alcohol))
        
        let aceticAcidStructure = ChemicalStructure(carbonChainLength: 2)
        var aceticAcid = aceticAcidStructure
        aceticAcid.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .carboxylicAcid))
        
        return [
            IdentifiedCompound(structure: ethanol, name: "Ethanol", iupacName: "ethanol", formula: "C₂H₆O", category: "Organic"),
            IdentifiedCompound(structure: aceticAcid, name: "Acetic Acid", iupacName: "ethanoic acid", formula: "C₂H₄O₂", category: "Organic")
        ]
    }
}
