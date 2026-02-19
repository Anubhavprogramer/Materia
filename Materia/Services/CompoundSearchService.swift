//
//  CompoundSearchService.swift
//  Materia
//
//  Service for searching compounds from both pre-saved and user-saved collections

import Foundation

// MARK: - Pre-saved Compound Model
struct PreSavedCompound: Identifiable, Codable {
    let id: String
    let name: String
    let iupacName: String
    let formula: String
    let category: String
    let description: String
    let commonNames: [String]
    let molarMass: Double
    let boilingPoint: Double?
    let meltingPoint: Double?
    let density: Double?
    let heatCapacity: Double?
    let structure: CompoundStructureData?
}

struct CompoundStructureData: Codable {
    let carbonChainLength: Int
    let bonds: [BondData]
    let functionalGroups: [FunctionalGroupData]
}

struct BondData: Codable {
    let fromCarbon: Int
    let toCarbon: Int
    let type: String
}

struct FunctionalGroupData: Codable {
    let carbonPosition: Int
    let group: String
}

struct PreSavedCompoundsJSON: Codable {
    let compounds: [PreSavedCompound]
}

// MARK: - Search Result
struct CompoundSearchResult: Identifiable {
    let id: String
    let name: String
    let iupacName: String
    let formula: String
    let category: String
    let molarMass: Double?
    let isPreSaved: Bool
    let sourceCompound: Any? // Can be PreSavedCompound or IdentifiedCompound
}

// MARK: - Search Service
@MainActor
class CompoundSearchService: ObservableObject {
    @Published var preSavedCompounds: [PreSavedCompound] = []
    @Published var searchResults: [CompoundSearchResult] = []
    @Published var isLoading: Bool = false
    
    private var userSavedCompounds: [IdentifiedCompound] = []
    
    init() {
        loadPreSavedCompounds()
    }
    
    // MARK: - Load Pre-saved Compounds
    func loadPreSavedCompounds() {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = Bundle.main.url(forResource: "PreSavedCompounds", withExtension: "json") else {
            CommonFunctions.debugPrint(load: "CompoundSearchService", message: "Could not find PreSavedCompounds.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let json = try decoder.decode(PreSavedCompoundsJSON.self, from: data)
            self.preSavedCompounds = json.compounds
            CommonFunctions.debugPrint(load: "CompoundSearchService", message: "Loaded \(json.compounds.count) pre-saved compounds")
        } catch {
            CommonFunctions.debugPrint(load: "CompoundSearchService", message: "Failed to load pre-saved compounds: \(error)")
        }
    }
    
    // MARK: - Convert PreSavedCompound to ChemicalStructure
    func convertStructure(_ structureData: CompoundStructureData?) -> ChemicalStructure {
        guard let structureData = structureData else {
            return ChemicalStructure(carbonChainLength: 0)
        }
        
        var structure = ChemicalStructure(carbonChainLength: structureData.carbonChainLength)
        
        // Convert bonds
        structure.bonds = structureData.bonds.map { bondData in
            let bondType = BondType(rawValue: bondData.type) ?? .single
            return Bond(from: bondData.fromCarbon, to: bondData.toCarbon, type: bondType)
        }
        
        // Convert functional groups
        structure.functionalGroups = structureData.functionalGroups.compactMap { fgData in
            guard let group = FunctionalGroup(rawValue: fgData.group) else { return nil }
            return FunctionalGroupAttachment(position: fgData.carbonPosition, group: group)
        }
        
        return structure
    }
    
    // MARK: - Update User Saved Compounds
    func updateUserSavedCompounds(_ compounds: [IdentifiedCompound]) {
        self.userSavedCompounds = compounds
    }
    
    // MARK: - Search Functionality
    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        var results: [CompoundSearchResult] = []
        
        // Search in pre-saved compounds
        for compound in preSavedCompounds {
            if matches(compound: compound, query: trimmedQuery) {
                let result = CompoundSearchResult(
                    id: compound.id,
                    name: compound.name,
                    iupacName: compound.iupacName,
                    formula: compound.formula,
                    category: compound.category,
                    molarMass: compound.molarMass,
                    isPreSaved: true,
                    sourceCompound: compound
                )
                results.append(result)
            }
        }
        
        // Search in user-saved compounds
        for compound in userSavedCompounds {
            if matches(compound: compound, query: trimmedQuery) {
                let result = CompoundSearchResult(
                    id: compound.id.uuidString,
                    name: compound.compoundName,
                    iupacName: compound.iupacName,
                    formula: compound.molecularFormula,
                    category: compound.category,
                    molarMass: nil,
                    isPreSaved: false,
                    sourceCompound: compound
                )
                results.append(result)
            }
        }
        
        // Sort by relevance (exact matches first)
        searchResults = results.sorted { a, b in
            let aExactName = a.name.lowercased() == trimmedQuery
            let bExactName = b.name.lowercased() == trimmedQuery
            
            if aExactName && !bExactName { return true }
            if !aExactName && bExactName { return false }
            
            return a.name.lowercased().hasPrefix(trimmedQuery) && !b.name.lowercased().hasPrefix(trimmedQuery)
        }
    }
    
    // MARK: - Private Helper Methods
    private func matches(compound: PreSavedCompound, query: String) -> Bool {
        let searchableText = [
            compound.name.lowercased(),
            compound.iupacName.lowercased(),
            compound.formula.lowercased(),
            compound.category.lowercased(),
            compound.description.lowercased(),
            compound.commonNames.map { $0.lowercased() }.joined(separator: " ")
        ].joined(separator: " ")
        
        return searchableText.contains(query)
    }
    
    private func matches(compound: IdentifiedCompound, query: String) -> Bool {
        let searchableText = [
            compound.compoundName.lowercased(),
            compound.iupacName.lowercased(),
            compound.molecularFormula.lowercased(),
            compound.category.lowercased()
        ].joined(separator: " ")
        
        return searchableText.contains(query)
    }
    
    // MARK: - Get Compound Details
    func getPreSavedCompound(id: String) -> PreSavedCompound? {
        return preSavedCompounds.first { $0.id == id }
    }
    
    // MARK: - Filter and Sorting
    func filterByCategory(_ category: String) -> [CompoundSearchResult] {
        return searchResults.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    func getCategories() -> [String] {
        var categories = Set<String>()
        
        for compound in preSavedCompounds {
            categories.insert(compound.category)
        }
        
        for compound in userSavedCompounds {
            categories.insert(compound.category)
        }
        
        return Array(categories).sorted()
    }
}
