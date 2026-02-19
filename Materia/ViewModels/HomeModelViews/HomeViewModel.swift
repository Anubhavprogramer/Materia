//
//  HomeViewModel.swift
//  Materia
//
//  ViewModel for the home screen
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    var LOAD: String = "HOME VIEW MODEL"
    @Published var savedCompounds: [IdentifiedCompound] = []
    @Published var isLoading: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let savedCompoundsKey = "SavedCompounds"
    
    init() {
        loadSavedCompounds()
    }
    
    // MARK: - Compound Management
    func saveCompound(_ compound: IdentifiedCompound) {
        CommonFunctions.debugNote(
            action: "SAVE_NEW",
            noteId: "N/A",
            compoundId: compound.id.uuidString,
            message: "Saving new compound with \(compound.notes.count) notes"
        )
        
        savedCompounds.append(compound)
        persistCompounds()
        
        CommonFunctions.debugNoteSave(
            compoundId: compound.id.uuidString,
            noteCount: compound.notes.count
        )
    }
    
    func updateCompound(_ compound: IdentifiedCompound) {
        if let index = savedCompounds.firstIndex(where: { $0.id == compound.id }) {
            CommonFunctions.debugNote(
                action: "UPDATE",
                noteId: "N/A",
                compoundId: compound.id.uuidString,
                message: "Updating compound with \(compound.notes.count) notes"
            )
            
            savedCompounds[index] = compound
            persistCompounds()
            
            CommonFunctions.debugNoteSave(
                compoundId: compound.id.uuidString,
                noteCount: compound.notes.count
            )
        }
    }
    
    func deleteCompound(_ compound: IdentifiedCompound) {
        savedCompounds.removeAll { $0.id == compound.id }
        persistCompounds()
    }
    
    func deleteCompound(at indexSet: IndexSet) {
        savedCompounds.remove(atOffsets: indexSet)
        persistCompounds()
    }
    
    // MARK: - Persistence
    func loadSavedCompounds() {
        isLoading = true
        defer { isLoading = false }
        
        guard let data = userDefaults.data(forKey: savedCompoundsKey) else {
            // Load sample compounds for demonstration
            loadSampleCompounds()
            return
        }
        
        do {
            savedCompounds = try JSONDecoder().decode([IdentifiedCompound].self, from: data)
        } catch {
            CommonFunctions.debugPrint(load: LOAD, message: "Failed to load saved compounds: \(error)")
            loadSampleCompounds()
        }
    }
    
    private func persistCompounds() {
        do {
            let data = try JSONEncoder().encode(savedCompounds)
            userDefaults.set(data, forKey: savedCompoundsKey)
        } catch {
//            print("Failed to save compounds: \(error)")
            CommonFunctions.debugPrint(load: LOAD, message: "Failed to save compounds: \(error)")
        }
    }
    
    private func loadSampleCompounds() {
        // Create sample compounds for demonstration
        let ethanolStructure = ChemicalStructure(carbonChainLength: 2)
        var ethanol = ethanolStructure
        ethanol.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .alcohol))
        
        let aceticAcidStructure = ChemicalStructure(carbonChainLength: 2)
        var aceticAcid = aceticAcidStructure
        aceticAcid.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .carboxylicAcid))
        
        savedCompounds = [
            IdentifiedCompound(structure: ethanol, name: "Ethanol", iupacName: "ethanol", formula: "C₂H₆O", category: "Organic"),
            IdentifiedCompound(structure: aceticAcid, name: "Acetic Acid", iupacName: "ethanoic acid", formula: "C₂H₄O₂", category: "Organic")
        ]
    }
    
    // MARK: - Computed Properties
    var hasCompounds: Bool {
        !savedCompounds.isEmpty
    }
    
    var compoundCount: Int {
        savedCompounds.count
    }
}
