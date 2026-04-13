//
//  CoreDataStack.swift
//  Materia
//
//  Manages Core Data initialization and context management
//

import CoreData
import Foundation

class CoreDataStack {
    // MARK: - Singleton
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    private let modelName = "Materia"
    private let container: NSPersistentContainer
    private(set) var viewContext: NSManagedObjectContext
    
    // MARK: - Initialization
    private init() {
        // Load the data model
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load Core Data model: \(modelName)")
        }
        
        // Create persistent container
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        // Configure for SQLite with encryption
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(NSNumber(value: true), forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription?.setOption(NSNumber(value: true), forKey: NSInferMappingModelAutomaticallyOption)
        
        // Enable encryption
        #if targetEnvironment(simulator)
        // No encryption on simulator for performance
        #else
        storeDescription?.setOption(FileProtectionType.complete, forKey: NSFileProtectionKey)
        #endif
        
        // Load persistent stores
        var loadError: Error? = nil
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ Core Data Error Loading Store: \(error)")
                print("  Domain: \(error.domain)")
                print("  Code: \(error.code)")
                loadError = error
            }
        }
        
        if let error = loadError {
            fatalError("Core Data failed to load: \(error)")
        }
        
        // Configure view context
        viewContext = container.viewContext
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("✅ Core Data Stack initialized successfully")
    }
    
    // MARK: - Main Context Operations
    
    /// Get a background context for background operations
    func backgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    /// Save the view context
    func save() throws {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Context saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Error saving context: \(nsError)")
                throw nsError
            }
        }
    }
    
    /// Save a background context
    func saveBackgroundContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Background context saved")
            } catch {
                let nsError = error as NSError
                print("❌ Error saving background context: \(nsError)")
                throw nsError
            }
        }
    }
    
    /// Delete all data (useful for testing)
    func deleteAllData() throws {
        let entities = ["CompoundEntity", "ChemicalStructureEntity", "CompoundNoteEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount
            
            do {
                try viewContext.execute(deleteRequest)
                print("✅ Deleted all \(entityName) records")
            } catch {
                let nsError = error as NSError
                print("❌ Error deleting \(entityName): \(nsError)")
                throw nsError
            }
        }
        
        try save()
    }
    
    // MARK: - Fetch Request Helpers
    
    /// Fetch all objects of a given entity
    func fetch<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        context: NSManagedObjectContext? = nil
    ) throws -> [T] {
        let context = context ?? viewContext
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
        
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        if let sortDescriptors = sortDescriptors {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            let nsError = error as NSError
            print("❌ Fetch error for \(entityType): \(nsError)")
            throw nsError
        }
    }
    
    /// Fetch a single object
    func fetchOne<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate,
        context: NSManagedObjectContext? = nil
    ) throws -> T? {
        let results = try fetch(entityType: entityType, predicate: predicate, context: context)
        return results.first
    }
    
    /// Count objects of a given entity
    func count<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) throws -> Int {
        let context = context ?? viewContext
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
        
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            let nsError = error as NSError
            print("❌ Count error for \(entityType): \(nsError)")
            throw nsError
        }
    }
}
