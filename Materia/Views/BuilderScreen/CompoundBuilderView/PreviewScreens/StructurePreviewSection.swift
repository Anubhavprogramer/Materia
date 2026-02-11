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
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.structurePreview)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // 2D Structure Visualization
                StructureDiagramView(structure: viewModel.structure)
                    .frame(height: 200)
                    .background(AppColors.Card)
                    .cornerRadius(AppConstants.largeCornerRadius)
                
                // SMILES-like representation
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppStrings.structureNotation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.structure.toSMILESLike())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}


#Preview {
    StructurePreviewSection(viewModel: CompoundBuilderViewModel())
}
