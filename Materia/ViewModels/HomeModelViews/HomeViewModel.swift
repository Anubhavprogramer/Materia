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
    
    private let storageService = CompoundStorageService()
    
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
        storageService.saveCompound(compound)
        
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
            storageService.updateCompound(compound)
            
            CommonFunctions.debugNoteSave(
                compoundId: compound.id.uuidString,
                noteCount: compound.notes.count
            )
        }
    }
    
    func deleteCompound(_ compound: IdentifiedCompound) {
        savedCompounds.removeAll { $0.id == compound.id }
        storageService.deleteCompound(compound)
    }
    
    func deleteCompound(at indexSet: IndexSet) {
        let compoundsToDelete = indexSet.map { savedCompounds[$0] }
        compoundsToDelete.forEach { storageService.deleteCompound($0) }
        savedCompounds.remove(atOffsets: indexSet)
    }
    
    // MARK: - Persistence
    func loadSavedCompounds() {
        isLoading = true
        defer { isLoading = false }
        
        // Load from storage service
        savedCompounds = storageService.fetchAllCompounds()
        
        // If no compounds, load samples
        if savedCompounds.isEmpty {
            let sampleCompounds = storageService.loadSampleCompounds()
            savedCompounds = sampleCompounds
            
            // Save samples to storage
            sampleCompounds.forEach { storageService.saveCompound($0) }
        }
    }
    
    // MARK: - Computed Properties
    var hasCompounds: Bool {
        !savedCompounds.isEmpty
    }
    
    var compoundCount: Int {
        savedCompounds.count
    }
}
