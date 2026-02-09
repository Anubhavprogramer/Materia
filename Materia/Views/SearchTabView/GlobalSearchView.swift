//
//  GlobalSearchView.swift
//  Materia
//
//  Global search interface for compounds

import SwiftUI

struct GlobalSearchView: View {
    @StateObject private var searchService = CompoundSearchService()
    @State private var searchQuery: String = ""
    @State private var selectedResult: CompoundSearchResult?
    @State private var selectedCategory: String?
    
    var filteredResults: [CompoundSearchResult] {
        if let category = selectedCategory {
            return searchService.searchResults.filter { $0.category == category }
        }
        return searchService.searchResults
    }
    
    var categories: [String] {
        searchService.getCategories().sorted()
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
                
                VStack(spacing: 0) {
                    // MARK: - Search Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: 16, weight: .semibold))
                            
                            TextField("Search compounds...", text: $searchQuery)
                                .onChange(of: searchQuery) { _, newValue in
                                    searchService.search(query: newValue)
                                }
                                .textFieldStyle(.roundedBorder)
                            
                            if !searchQuery.isEmpty {
                                Button(action: {
                                    searchQuery = ""
                                    searchService.search(query: "")
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // MARK: - Category Filter
                    if !categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "All" button
                                Button(action: { selectedCategory = nil }) {
                                    Text("All")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedCategory == nil ? .white : AppColors.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == nil ? AppColors.primary : AppColors.primaryFaded)
                                        .cornerRadius(8)
                                }
                                
                                // Category buttons
                                ForEach(categories, id: \.self) { category in
                                    Button(action: { selectedCategory = category }) {
                                        Text(category)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(selectedCategory == category ? .white : AppColors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == category ? AppColors.primary : AppColors.primaryFaded)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(AppColors.surface.opacity(0.5))
                    }
                    
                    // MARK: - Results List
                    if searchQuery.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.primaryMuted)
                            
                            Text("Start Searching")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Search by compound name, formula, or category")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredResults.isEmpty {
                        // No Results State
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.primaryMuted)
                            
                            Text("No Results Found")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Try a different search term or browse categories")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Results List
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredResults) { result in
                                    NavigationLink(destination: CompoundDetailSearchView(result: result)) {
                                        CompoundSearchResultCard(result: result)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Compound Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // This would be called when the view appears to sync user saved compounds
            // searchService.updateUserSavedCompounds(userSavedCompounds)
        }
    }
}

// MARK: - Result Card Component
struct CompoundSearchResultCard: View {
    let result: CompoundSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(result.iupacName)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(result.formula)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                        .lineLimit(1)
                    
                    Text(result.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accentLight)
                        .cornerRadius(6)
                }
            }
            
            if let molarMass = result.molarMass {
                Divider()
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Molar Mass")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(String(format: "%.2f g/mol", molarMass))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    if result.isPreSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Pre-saved")
                                .font(.caption2)
                        }
                        .foregroundColor(AppColors.primary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 12))
                            Text("Your Compound")
                                .font(.caption2)
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.primaryMuted, lineWidth: 1)
        )
    }
}

// MARK: - Compound Detail View from Search
struct CompoundDetailSearchView: View {
    let result: CompoundSearchResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primary)
                                
                                Text(result.iupacName)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(result.category)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColors.accentLight)
                                .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Formula Card
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Molecular Formula", systemImage: "molecule")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(result.formula)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                            .padding(12)
                            .background(AppColors.primaryFaded)
                            .cornerRadius(8)
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Properties Card
                    if let molarMass = result.molarMass {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Properties", systemImage: "info.circle")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                PropertyRow(label: "Molar Mass", value: String(format: "%.2f g/mol", molarMass))
                            }
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - Helper Components
struct PropertyRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    GlobalSearchView()
}
