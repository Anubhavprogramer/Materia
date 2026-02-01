//
//  SavedCompoundsTabView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct SavedCompoundsTabView: View {
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
