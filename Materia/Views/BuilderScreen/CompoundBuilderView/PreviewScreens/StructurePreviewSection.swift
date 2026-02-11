//
//  StructurePreviewSection.swift
//  Materia
//
//  2D structure preview for the compound builder
//

import SwiftUI

struct StructurePreviewSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.largeGap) {
            Text(AppStrings.structurePreview)
                .font(.headline)
                .fontWeight(.semibold)
            
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
    }
}


#Preview {
    StructurePreviewSection(viewModel: CompoundBuilderViewModel())
}
