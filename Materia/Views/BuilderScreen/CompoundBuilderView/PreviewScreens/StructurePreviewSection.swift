//
//  StructurePreviewSection.swift
//  Materia
//
//  2D structure preview for the compound builder
//

import SwiftUI

struct StructurePreviewSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    @State private var show3DViewer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.largeGap) {
            HStack {
                Text(AppStrings.structurePreview)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 3D View Button
                Button(action: { show3DViewer = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cube.transparent")
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.actionButtonText)
                    .padding(.horizontal, AppConstants.defaultPadding)
                    .padding(.vertical, AppConstants.smallPadding)
                }
                .background(
                        RoundedRectangle(cornerRadius: AppConstants.largeCornerRadius)
                            .fill(.ultraThinMaterial)
                )
                .overlay(
                    // Glass edge highlight
                    RoundedRectangle(cornerRadius: AppConstants.largeCornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            
            VStack(spacing: AppConstants.largeGap) {
                // 2D Structure Visualization
                StructureDiagramView(structure: viewModel.structure)
                    .frame(height: 200)
                    .background(AppColors.Card)
                    .cornerRadius(AppConstants.largeCornerRadius)
                
                // SMILES-like representation
                VStack(alignment: .leading, spacing: AppConstants.defaultGap) {
                    Text(AppStrings.structureNotation)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(viewModel.structure.toSMILESLike())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .sheet(isPresented: $show3DViewer) {
            if let compound = createCompoundForPreview() {
                Model3DViewerScreen(compound: compound)
            }
        }
    }
    
    private func createCompoundForPreview() -> IdentifiedCompound? {
        return IdentifiedCompound(
            structure: viewModel.structure,
            name: "Structure Preview",
            iupacName: "Structure",
            formula: "C\(viewModel.structure.carbonChainLength)H\((viewModel.structure.carbonChainLength * 2) + 2)",
            category: "Preview",
            confidence: 1.0,
            isValidated: false
        )
    }
}


#Preview {
    StructurePreviewSection(viewModel: CompoundBuilderViewModel())
}
