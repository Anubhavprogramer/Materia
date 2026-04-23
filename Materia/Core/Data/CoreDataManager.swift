//
//  CoreDataManager.swift
//  Materia
//
//  Singleton for managing Core Data container
//

import Foundation
import CoreData

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Compounds")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data not loaded properly: \(error)")
            }
        }
        
        return container
    }()
    
    // MARK: - Context
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Save
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }
}
