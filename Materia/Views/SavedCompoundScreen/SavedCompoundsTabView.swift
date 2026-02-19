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
    @State private var editingCompound: IdentifiedCompound?
    @Environment(\.scenePhase) private var scenePhase

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
                
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading compounds...")
                            .tint(AppColors.primary)
                    } else if viewModel.hasCompounds {
                        List {
                            Section {
                                ForEach(viewModel.savedCompounds) { compound in
                                    Button {
                                        editingCompound = compound
                                    } label: {
                                        CompoundRowView(compound: compound)
                                    }
                                    .listRowBackground(Color.clear)
//                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewModel.deleteCompound(compound)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundColor(AppColors.primary)

                                    Text("Saved Compounds")
                                        .fontWeight(.semibold)

                                    Spacer()

                                    Text("\(viewModel.compoundCount)")
                                        .foregroundColor(AppColors.primary)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)

                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 44))
                                .foregroundColor(AppColors.primaryMuted)
                            Text("No Saved Compounds")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("Build and save a compound from the Build tab.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Saved")
        }
        .sheet(item: $editingCompound) { compound in
            CompoundDetailView(compound: compound)
                .environmentObject(viewModel)
        }
        .onAppear {
            // Reload when tab appears
            viewModel.loadSavedCompounds()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Reload when scene becomes active
            if newPhase == .active {
                viewModel.loadSavedCompounds()
            }
        }
    }
}
