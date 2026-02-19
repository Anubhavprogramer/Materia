//
//  SearchTabView.swift
//  Materia
//
//  Search tab using native searchable modifier with List

import SwiftUI

struct SearchTabView: View {
    @StateObject private var searchService = CompoundSearchService()
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedCompound: IdentifiedCompound?
    @Environment(\.scenePhase) private var scenePhase
    
    var filteredResults: [IdentifiedCompound] {
        if searchText.isEmpty {
            // Return all pre-saved compounds + user-saved compounds
            var allCompounds: [IdentifiedCompound] = []
            
            // Add converted pre-saved compounds
            allCompounds.append(contentsOf: searchService.preSavedCompounds.compactMap { preCompound in
                convertPreSavedToIdentifiedCompound(preCompound)
            })
            
            // Add user-saved compounds
            allCompounds.append(contentsOf: homeViewModel.savedCompounds)
            
            return allCompounds
        }
        
        // Convert CompoundSearchResult to IdentifiedCompound
        var results: [IdentifiedCompound] = []
        
        results.append(contentsOf: searchService.searchResults.compactMap { result in
            if let identifiedCompound = result.sourceCompound as? IdentifiedCompound {
                return identifiedCompound
            } else if let preSavedCompound = result.sourceCompound as? PreSavedCompound {
                return convertPreSavedToIdentifiedCompound(preSavedCompound)
            }
            return nil
        })
        
        return results.filter { compound in
            // Ensure compound has valid data
            !compound.compoundName.isEmpty && !compound.iupacName.isEmpty
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List(filteredResults, id: \.id) { compound in
                    Button(action: {
                        selectedCompound = compound
                    }) {
                        CompoundRowView(compound: compound)
                    }
                    .listRowBackground(Color.clear)
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Name, formula...")
            .onChange(of: searchText) { _, newValue in
                // Update search service with user-saved compounds
                searchService.updateUserSavedCompounds(homeViewModel.savedCompounds)
                searchService.search(query: newValue)
        }
        }
        .sheet(item: $selectedCompound) { compound in
            CompoundDetailView(compound: compound)
                .environmentObject(homeViewModel)
        }
        .onAppear {
            searchService.loadPreSavedCompounds()
            searchService.updateUserSavedCompounds(homeViewModel.savedCompounds)
            homeViewModel.loadSavedCompounds()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                searchService.loadPreSavedCompounds()
                homeViewModel.loadSavedCompounds()
                searchService.updateUserSavedCompounds(homeViewModel.savedCompounds)
            }
        }
    }
    
    // Convert PreSavedCompound to IdentifiedCompound
    private func convertPreSavedToIdentifiedCompound(_ preCompound: PreSavedCompound) -> IdentifiedCompound {
        let structure = searchService.convertStructure(preCompound.structure)
        var identifiedCompound = IdentifiedCompound(
            structure: structure,
            name: preCompound.name,
            iupacName: preCompound.iupacName,
            formula: preCompound.formula,
            category: preCompound.category,
            confidence: nil,
            isValidated: true
        )
        identifiedCompound.notes = []
        return identifiedCompound
    }
}

#Preview {
    SearchTabView()
}
