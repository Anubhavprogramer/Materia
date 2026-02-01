//
//  CompoundBuilderView.swift
//  Materia
//
//  Main compound builder interface
//

import SwiftUI

struct CompoundBuilderView: View {
    @StateObject private var viewModel: CompoundBuilderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult = false
    @State private var identifiedCompound: IdentifiedCompound?
    
    let onCompoundSaved: (IdentifiedCompound) -> Void
    
    init(initialStructure: ChemicalStructure? = nil,
         onCompoundSaved: @escaping (IdentifiedCompound) -> Void) {
        // Use a custom init so we can seed the builder.
        if let initialStructure {
            _viewModel = StateObject(wrappedValue: CompoundBuilderViewModel(initialStructure: initialStructure))
        } else {
            _viewModel = StateObject(wrappedValue: CompoundBuilderViewModel())
        }
        self.onCompoundSaved = onCompoundSaved
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Carbon Chain Section
                    CarbonChainSection(viewModel: viewModel)
                    
                    // Bond Configuration Section
                    BondConfigurationSection(viewModel: viewModel)
                    
                    // Functional Groups Section
                    FunctionalGroupsSection(viewModel: viewModel)
                    
                    // Validation Status
                    ValidationStatusSection(viewModel: viewModel)
                    
                    // Structure Preview
                    StructurePreviewSection(viewModel: viewModel)
                    
                    // Validation Error
                    if let error = viewModel.validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Build Button
                    Button(action: buildCompound) {
                        HStack {
                            if viewModel.isBuilding {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(.white)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }

                            Text(viewModel.isBuilding ? "Identifying..." : "Identify Compound")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.isValidStructure || viewModel.isBuilding)
                    .liquidGlassPrimaryButton(
                        tint: viewModel.isValidStructure && !viewModel.isBuilding ? .blue : .gray,
                        size: .large,
                        isEnabled: viewModel.isValidStructure && !viewModel.isBuilding
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
           
        }
        .sheet(isPresented: $showingResult) {
            if let compound = identifiedCompound {
                CompoundResultView(compound: compound) { savedCompound in
                    onCompoundSaved(savedCompound)
                    dismiss()
                }
            }
        }
    }
    
    private func buildCompound() {
        Task {
            identifiedCompound = await viewModel.buildCompound()
            if identifiedCompound != nil {
                showingResult = true
            }
        }
    }
}

// MARK: - Carbon Chain Section

#Preview {
    CompoundBuilderView { _ in }
}
