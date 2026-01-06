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
                    // Header
                    VStack(spacing: 8) {
                        Text("Compound Builder")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Build a molecular structure to identify the compound")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
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
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            
                            Text(viewModel.isBuilding ? "Identifying..." : "Identify Compound")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.isValidStructure && !viewModel.isBuilding
                                ? LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValidStructure || viewModel.isBuilding)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
struct CarbonChainSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Carbon Chain")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Length: \(viewModel.carbonChainLength) carbons")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.carbonChainLength) },
                        set: { viewModel.updateCarbonChainLength(Int($0)) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .tint(.blue)
                
                // Carbon chain visualization
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...viewModel.carbonChainLength, id: \.self) { carbon in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("C\(carbon)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    )
                            }
                            
                            if carbon < viewModel.carbonChainLength {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 20, height: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    CompoundBuilderView { _ in }
}