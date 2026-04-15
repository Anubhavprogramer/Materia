//
//  CoreDataModels.swift
//  Materia
//
//  Core Data NSManagedObject definitions
//

import CoreData
import Foundation

// MARK: - CompoundEntity
@objc(CompoundEntity)
final class CompoundEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var compoundName: String
    @NSManaged var iupacName: String
    @NSManaged var molecularFormula: String
    @NSManaged var category: String
    @NSManaged var confidence: Double
    @NSManaged var isValidated: Bool
    @NSManaged var identifiedAt: Date
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Relationships
    @NSManaged var structure: ChemicalStructureEntity?
    @NSManaged var notes: NSSet
    
    // MARK: - Initialization
    @discardableResult
    static func create(
        from compound: IdentifiedCompound,
        in context: NSManagedObjectContext
    ) -> CompoundEntity {
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "CompoundEntity",
            into: context
        ) as! CompoundEntity
        
        entity.id = compound.id
        entity.compoundName = compound.compoundName
        entity.iupacName = compound.iupacName
        entity.molecularFormula = compound.molecularFormula
        entity.category = compound.category
        entity.confidence = compound.confidence ?? 0.0
        entity.isValidated = compound.isValidated ?? false
        // Don't assign identifiedAt, createdAt, updatedAt - let them use default values
        
        // Create structure
        let structureEntity = ChemicalStructureEntity.create(
            from: compound.structure,
            in: context
        )
        entity.structure = structureEntity
        
        // Create notes
        for note in compound.notes {
            let noteEntity = CompoundNoteEntity.create(
                from: note,
                in: context
            )
            entity.addToNotes(noteEntity)
        }
        
        return entity
    }
    
    // MARK: - Conversion
    
    func toIdentifiedCompound() -> IdentifiedCompound? {
        guard let structure = structure?.toChemicalStructure() else { return nil }
        
        var compound = IdentifiedCompound(
            structure: structure,
            name: compoundName,
            iupacName: iupacName,
            formula: molecularFormula,
            category: category,
            confidence: confidence > 0 ? confidence : nil,
            isValidated: isValidated
        )
        
        // Note: identifiedAt is already set in the IdentifiedCompound initializer
        // We don't need to reassign it here since it's immutable
        
        // Add notes
        let noteArray = notes.allObjects as? [CompoundNoteEntity] ?? []
        for noteEntity in noteArray {
            if let note = noteEntity.toCompoundNote() {
                compound.notes.append(note)
            }
        }
        
        return compound
    }
    
    // MARK: - Updates
    
    func update(from compound: IdentifiedCompound) {
        self.iupacName = compound.iupacName
        self.molecularFormula = compound.molecularFormula
        self.category = compound.category
        self.confidence = compound.confidence ?? 0.0
        self.isValidated = compound.isValidated ?? false
        self.updatedAt = Date()
    }
    
    // MARK: - Notes Management
    
    func addToNotes(_ noteEntity: CompoundNoteEntity) {
        var notes = self.notes as? Set<CompoundNoteEntity> ?? []
        notes.insert(noteEntity)
        self.notes = notes as NSSet
    }
    
    func removeFromNotes(_ noteEntity: CompoundNoteEntity) {
        var notes = self.notes as? Set<CompoundNoteEntity> ?? []
        notes.remove(noteEntity)
        self.notes = notes as NSSet
    }
    
    func getNotesArray() -> [CompoundNoteEntity] {
        let notes = self.notes.allObjects as? [CompoundNoteEntity] ?? []
        return notes.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - ChemicalStructureEntity
@objc(ChemicalStructureEntity)
final class ChemicalStructureEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var carbonChainLength: Int16
    @NSManaged var bondsData: Data? // JSON encoded
    @NSManaged var functionalGroupsData: Data? // JSON encoded
    @NSManaged var createdAt: Date
    
    // Relationship
    @NSManaged var compound: CompoundEntity?
    
    // MARK: - Initialization
    @discardableResult
    static func create(
        from structure: ChemicalStructure,
        in context: NSManagedObjectContext
    ) -> ChemicalStructureEntity {
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "ChemicalStructureEntity",
            into: context
        ) as! ChemicalStructureEntity
        
        entity.id = UUID()
        entity.carbonChainLength = Int16(structure.carbonChainLength)
        entity.createdAt = Date()
        
        // Encode bonds and functional groups to JSON
        do {
            entity.bondsData = try JSONEncoder().encode(structure.bonds)
            entity.functionalGroupsData = try JSONEncoder().encode(structure.functionalGroups)
        } catch {
            print("❌ Error encoding structure data: \(error)")
        }
        
        return entity
    }
    
    // MARK: - Conversion
    
    func toChemicalStructure() -> ChemicalStructure? {
        var structure = ChemicalStructure(carbonChainLength: Int(carbonChainLength))
        
        // Decode bonds
        if let bondsData = bondsData {
            do {
                structure.bonds = try JSONDecoder().decode([Bond].self, from: bondsData)
            } catch {
                print("❌ Error decoding bonds: \(error)")
            }
        }
        
        // Decode functional groups
        if let functionalGroupsData = functionalGroupsData {
            do {
                structure.functionalGroups = try JSONDecoder().decode(
                    [FunctionalGroupAttachment].self,
                    from: functionalGroupsData
                )
            } catch {
                print("❌ Error decoding functional groups: \(error)")
            }
        }
        
        return structure
    }
}

// MARK: - CompoundNoteEntity
@objc(CompoundNoteEntity)
final class CompoundNoteEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var compoundId: UUID
    @NSManaged var content: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Relationship
    @NSManaged var compound: CompoundEntity?
    
    // MARK: - Initialization
    @discardableResult
    static func create(
        from note: CompoundNote,
        in context: NSManagedObjectContext
    ) -> CompoundNoteEntity {
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "CompoundNoteEntity",
            into: context
        ) as! CompoundNoteEntity
        
        entity.id = note.id
        entity.compoundId = note.compoundId
        entity.content = note.content
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        return entity
    }
    
    // MARK: - Conversion
    
    func toCompoundNote() -> CompoundNote? {
        var note = CompoundNote(compoundId: compoundId, content: content)
        // Note: createdAt and updatedAt are already set by CompoundNote initializer
        // We don't need to reassign immutable properties
        return note
    }
    
    // MARK: - Updates
    
    func update(content: String) {
        self.content = content
        self.updatedAt = Date()
    }
}

// MARK: - NSManagedObject Extension
extension NSManagedObject {
    static var entityName: String {
        String(describing: Self.self)
    }
}
