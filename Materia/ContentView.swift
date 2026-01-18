//
//  ContentView.swift
//  Materia
//
//  Main navigation view for the chemistry app
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BuildTabView()
                .tabItem {
                    Label("Build", systemImage: "plus.circle")
                }

            CollaborationTabView()
                .tabItem {
                    Label("Live", systemImage: "person.2.wave.2")
                }

            SavedCompoundsTabView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
        }
    }
}

// MARK: - Collaboration Tab
private struct CollaborationTabView: View {
    var body: some View {
        NavigationStack {
            MateriaLiveEntryView()
                .navigationTitle("Materia Live")
        }
    }
}

// MARK: - Build Tab
private struct BuildTabView: View {
    @StateObject private var homeVM = HomeViewModel()

    /// Used to reset the embedded builder view model when switching quick-start templates.
    @State private var builderSessionID = UUID()
    @State private var initialStructure: ChemicalStructure?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "atom")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Materia")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Chemical Structure Identifier")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    QuickStartSection { structure in
                        initialStructure = structure
                        builderSessionID = UUID() // reset builder
                    }

                    // Embedded builder (no separate "Build Compound" button)
                    CompoundBuilderView(initialStructure: initialStructure) { compound in
                        homeVM.saveCompound(compound)
                    }
                    .id(builderSessionID)

                    // Small hint to access saved compounds
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Your saved compounds are available in the Saved tab.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.top)
            }
            .navigationTitle("Build")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        initialStructure = nil
                        builderSessionID = UUID()
                    }
                }
            }
        }
    }
}

// MARK: - Saved Tab
private struct SavedCompoundsTabView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedCompound: IdentifiedCompound?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading compounds...")
                } else if viewModel.hasCompounds {
                    List {
                        Section {
                            ForEach(viewModel.savedCompounds) { compound in
                                Button {
                                    selectedCompound = compound
                                } label: {
                                    CompoundRowView(compound: compound)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete(perform: viewModel.deleteCompound)
                        } header: {
                            HStack {
                                Text("Saved Compounds")
                                Spacer()
                                Text("\(viewModel.compoundCount)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No Saved Compounds")
                            .font(.headline)
                        Text("Build and save a compound from the Build tab.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Saved")
        }
        .sheet(item: $selectedCompound) { compound in
            CompoundDetailView(compound: compound)
        }
    }
}

#Preview {
    ContentView()
}
