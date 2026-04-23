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
    @State private var compoundNotes: [CompoundNote] = []
    
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
                VStack(alignment: .leading, spacing: AppConstants.mediumGap) {
                    
                    Text(AppStrings.build)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
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
                    HStack(alignment: .center){
                        Spacer()
                        Button(action: buildCompound) {
                            HStack {
                                if viewModel.isBuilding {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .tint(.white)
                                }

                                Text(viewModel.isBuilding ? AppStrings.identifying : AppStrings.identifyCompound)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(!viewModel.isValidStructure || viewModel.isBuilding)
                        .liquidGlassButton(
                            color: viewModel.isValidStructure && !viewModel.isBuilding ? AppColors.accent : Color.gray,
                            size: .large,
                            isEnabled: viewModel.isValidStructure && !viewModel.isBuilding
                        )
                        .padding(.bottom)
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
           
        }
        .sheet(isPresented: $showingResult) {
            if let compound = identifiedCompound {
                NavigationStack {
                    CompoundResultView(compound: compound, notes: $compoundNotes) { savedCompound in
                        onCompoundSaved(savedCompound)
                        dismiss()
                    }
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
