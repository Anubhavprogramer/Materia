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
