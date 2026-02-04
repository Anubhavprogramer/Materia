//
//  SearchTabView.swift
//  Materia
//
//  Search tab using native searchable modifier with List

import SwiftUI

struct SearchTabView: View {
    @StateObject private var searchService = CompoundSearchService()
    @State private var searchText = ""
    
    var filteredResults: [CompoundSearchResult] {
        if searchText.isEmpty {
            return searchService.preSavedCompounds.map { compound in
                CompoundSearchResult(
                    id: compound.id,
                    name: compound.name,
                    iupacName: compound.iupacName,
                    formula: compound.formula,
                    category: compound.category,
                    molarMass: compound.molarMass,
                    isPreSaved: true,
                    sourceCompound: compound
                )
            }
        }
        return searchService.searchResults
    }
    
    var body: some View {
        NavigationStack {
            List(filteredResults, id: \.id) { result in
                NavigationLink(destination: CompoundDetailSearchView(result: result)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(result.iupacName)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(result.formula)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(AppColors.primary)
                                
                                Text(result.category)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppColors.primary.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if let molarMass = result.molarMass {
                            Text("M: \(String(format: "%.2f", molarMass)) g/mol")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Search Compounds")
            .searchable(text: $searchText, prompt: "Name, formula...")
            .onChange(of: searchText) { _, newValue in
                searchService.search(query: newValue)
            }
        }
    }
}

#Preview {
    SearchTabView()
}
