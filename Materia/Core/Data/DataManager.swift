//
//  DataManager.swift
//  Materia
//
//  Created by Anubhav Dubey on 09/04/26.
//

import Foundation

final class DataManager {
    private let fileName = "compounds.json"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Save
    func save(_ model: IdentifiedCompound) {
        var compounds = fetchAll()
        
        // Remove if exists (for updates)
        compounds.removeAll { $0.id == model.id }
        
        // Add new/updated compound
        compounds.append(model)
        
        // Persist to file
        saveToFile(compounds)
    }
    
    // MARK: - Fetch
    func fetchAll() -> [IdentifiedCompound] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let compounds = try JSONDecoder().decode([IdentifiedCompound].self, from: data)
            return compounds
        } catch {
            print("Error fetching compounds: \(error)")
            return []
        }
    }
    
    // MARK: - Delete
    func delete(_ model: IdentifiedCompound) {
        var compounds = fetchAll()
        compounds.removeAll { $0.id == model.id }
        saveToFile(compounds)
    }
    
    // MARK: - Private Helper
    private func saveToFile(_ compounds: [IdentifiedCompound]) {
        do {
            let data = try JSONEncoder().encode(compounds)
            try data.write(to: fileURL, options: .atomic)
            print("✅ Saved \(compounds.count) compounds to JSON file")
        } catch {
            print("Error saving compounds: \(error)")
        }
    }
}
