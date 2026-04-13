//
//  CDCompound+Mapping.swift
//  Materia
//
//  Created by Anubhav Dubey on 09/04/26.
//

import Foundation


// MARK: - Identified Compound
struct IdentifiedCompound: Identifiable, Codable {
    var id: UUID
    var structure: ChemicalStructure
    var compoundName: String
    var iupacName: String
    var molecularFormula: String
    var category: String
    var identifiedAt: Date
    var confidence: Double?
    var isValidated: Bool?
    var notes: [CompoundNote]
    
    init(structure: ChemicalStructure, name: String, iupacName: String, formula: String, category: String, confidence: Double? = nil, isValidated: Bool? = nil) {
        self.id = UUID()
        self.structure = structure
        self.compoundName = name
        self.iupacName = iupacName
        self.molecularFormula = formula
        self.category = category
        self.identifiedAt = Date()
        self.confidence = confidence
        self.isValidated = isValidated
        self.notes = []
    }
    
    mutating func addNote(content: String) {
        let note = CompoundNote(compoundId: self.id, content: content)
        self.notes.append(note)
    }
    
    mutating func updateNote(_ note: CompoundNote) {
        if let index = self.notes.firstIndex(where: { $0.id == note.id }) {
            self.notes[index] = note
        }
    }
    
    mutating func deleteNote(_ noteId: UUID) {
        self.notes.removeAll { $0.id == noteId }
    }
}


//MARK: - Core Data to App Model
extension IdentifiedCompound {
    init?(from entity: CDCompound){
        guard let id = entity.id,
              let compoundName = entity.compoundName,
              let molecularFormula = entity.molecularFormula,
              let category = entity.category,
              let identifiedAt = entity.identifiedAt,
              let createdAt = entity.createdAt,
              let iupac = entity.iupac,
              let data = entity.structure else {
            return nil
        }
        
        self.id = id
        self.compoundName = compoundName
        self.molecularFormula = molecularFormula
        self.category = category
        self.identifiedAt = identifiedAt
        self.iupacName = iupac
        self.confidence = entity.confidence
        self.isValidated = entity.isValidated
        
        //Decode structure
        
        if let data = entity.structure,
           let decoded = StructureCoder.decoder(data){
            self.structure = decoded
        } else {
            self.structure = ChemicalStructure(carbonChainLength: 0)
        }
        
        if let data = entity.notes,
           let decoded = NoteCoder.decoder(data){
            self.notes = decoded
        } else {
            self.notes = []
        }
        
    }
}

//MARK: - App Model to CoreData
extension CDCompound {
    func update(form model: IdentifiedCompound){
        self.id = model.id
        self.compoundName = model.compoundName
        self.iupac = model.iupacName
        self.molecularFormula = model.molecularFormula
        self.category = model.category
        self.identifiedAt = model.identifiedAt
        self.confidence = model.confidence ?? 0
        self.isValidated = model.isValidated ?? false
        
        //Encode structrue
        self.structure = StructureCoder.encoder(model.structure)
        self.notes = NoteCoder.encoder(model.notes)
    }
}
