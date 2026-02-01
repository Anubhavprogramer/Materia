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
            Text("Structure Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // 2D Structure Visualization
                StructureDiagramView(structure: viewModel.structure)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // SMILES-like representation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Structure Notation:")
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}


#Preview {
    StructurePreviewSection(viewModel: CompoundBuilderViewModel())
}
