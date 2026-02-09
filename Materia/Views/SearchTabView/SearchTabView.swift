//
//  SearchTabView.swift
//  Materia
//
//  Search tab using native searchable modifier with List

import SwiftUI

struct SearchTabView: View {
    @StateObject private var searchService = CompoundSearchService()
    @State private var searchText = ""
    @State private var selectedCompound: IdentifiedCompound?
    @State private var selectedPreSavedCompound: PreSavedCompound?
    
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
                Button(action: {
                    if result.isPreSaved {
                        // For pre-saved compounds, find the full data
                        selectedPreSavedCompound = searchService.getPreSavedCompound(id: result.id)
                    } else {
                        // For user-saved compounds - need to get from sourceCompound
                        if let identifiedCompound = result.sourceCompound as? IdentifiedCompound {
                            selectedCompound = identifiedCompound
                        }
                    }
                }) {
                    SearchCompoundRowView(result: result)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Search Compounds")
            .searchable(text: $searchText, prompt: "Name, formula...")
            .onChange(of: searchText) { _, newValue in
                searchService.search(query: newValue)
            }
        }
        .sheet(item: $selectedCompound) { compound in
            CompoundDetailView(compound: compound)
        }
        .sheet(item: $selectedPreSavedCompound) { compound in
            PreSavedCompoundDetailView(compound: compound)
        }
    }
}

// MARK: - Search Row View (Similar to CompoundRowView)
struct SearchCompoundRowView: View {
    let result: CompoundSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(result.iupacName)
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                    
                    Text(result.formula)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(result.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        // Pre-saved indicator
                        Image(systemName: result.isPreSaved ? "checkmark.circle.fill" : "bookmark.fill")
                            .foregroundColor(result.isPreSaved ? .green : .orange)
                            .font(.caption)
                    }
                    
                    // Molar mass
                    if let molarMass = result.molarMass {
                        HStack(spacing: 2) {
                            Image(systemName: "scalemass.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text("\(String(format: "%.2f", molarMass)) g/mol")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View for Pre-saved Compounds
struct PreSavedCompoundDetailView: View {
    let compound: PreSavedCompound
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Text(compound.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        HStack(spacing: 8) {
                            Text(compound.category)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text("Pre-saved")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Information Card
                    VStack(spacing: 16) {
                        InfoRowDetail(title: "Common Name", value: compound.name)
                        Divider()
                        InfoRowDetail(title: "IUPAC Name", value: compound.iupacName)
                        Divider()
                        InfoRowDetail(title: "Molecular Formula", value: compound.formula)
                        Divider()
                        InfoRowDetail(title: "Molar Mass", value: "\(String(format: "%.2f", compound.molarMass)) g/mol")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Properties (if available)
                    if let boilingPoint = compound.boilingPoint, boilingPoint > 0 {
                        VStack(spacing: 12) {
                            Text("Physical Properties")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if boilingPoint > 0 {
                                InfoRowDetail(title: "Boiling Point", value: "\(String(format: "%.2f", boilingPoint))°C")
                            }
                            if let meltingPoint = compound.meltingPoint, meltingPoint > -1000 {
                                Divider()
                                InfoRowDetail(title: "Melting Point", value: "\(String(format: "%.2f", meltingPoint))°C")
                            }
                            if let density = compound.density, density > 0 {
                                Divider()
                                InfoRowDetail(title: "Density", value: "\(String(format: "%.3f", density)) g/cm³")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Description
                    if !compound.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(compound.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Compound Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct InfoRowDetail: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    SearchTabView()
}
