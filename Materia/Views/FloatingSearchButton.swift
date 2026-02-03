//
//  FloatingSearchButton.swift
//  Materia
//
//  Floating search button with glass morphism effect

import SwiftUI

struct FloatingSearchButton: View {
    @State private var isShowingSearch = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
            
            // Floating Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isShowingSearch.toggle()
                }
            }) {
                ZStack {
                    // Glass background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.primary.opacity(0.3),
                                    AppColors.primary.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            Circle()
                                .fill(AppColors.surface.opacity(0.2))
                                .blur(radius: 5)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppColors.primary.opacity(0.6),
                                            AppColors.primary.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    // Icon
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 56, height: 56)
                .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(16)
            .sheet(isPresented: $isShowingSearch) {
                GlobalSearchModalView(isPresented: $isShowingSearch)
                    .presentationDetents([.large])
                    .presentationBackground(.clear)
            }
        }
    }
}

// MARK: - Glass Modal Search View
struct GlobalSearchModalView: View {
    @Binding var isPresented: Bool
    @StateObject private var searchService = CompoundSearchService()
    @State private var searchQuery: String = ""
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
        ZStack {
            // Glass morphism background
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.surface.opacity(0.85),
                            AppColors.surface.opacity(0.75)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header with close button
                HStack {
                    Text("Search Compounds")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.primary.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 14, weight: .semibold))
                    
                    TextField("Search by name, formula...", text: $searchQuery)
                        .onChange(of: searchQuery) { _, newValue in
                            searchService.search(query: newValue)
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                    
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
                .padding(.horizontal, 20)
                
                // Category Filters
                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: { selectedCategory = nil }) {
                                Text("All")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedCategory == nil ? .white : AppColors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == nil ? AppColors.primary : AppColors.primaryFaded)
                                    .cornerRadius(8)
                            }
                            
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedCategory == category ? .white : AppColors.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? AppColors.primary : AppColors.primaryFaded)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Results
                ScrollView {
                    if searchQuery.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.primaryMuted)
                            
                            Text("Search Compounds")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Enter a compound name or formula")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if filteredResults.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.primaryMuted)
                            
                            Text("No Results Found")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Try different keywords")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredResults) { result in
                                NavigationLink(destination: CompoundDetailSearchView(result: result)) {
                                    CompoundSearchResultCard(result: result)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("MateriaBackground").opacity(0.95),
                Color("MateriaSecondary").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        FloatingSearchButton()
    }
}
// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("MateriaBackground").opacity(0.95),
                Color("MateriaSecondary").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        FloatingSearchButton()
    }
}
