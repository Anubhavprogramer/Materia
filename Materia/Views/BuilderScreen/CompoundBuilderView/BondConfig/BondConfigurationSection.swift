//
//  BondConfigurationSection.swift
//  Materia
//
//  Bond configuration UI for the compound builder
//

import SwiftUI

struct BondConfigurationSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bond Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.carbonChainLength > 1 {
                VStack(spacing: 12) {
                    ForEach(1..<viewModel.carbonChainLength, id: \.self) { carbon in
                        BondConfigRow(
                            fromCarbon: carbon,
                            toCarbon: carbon + 1,
                            viewModel: viewModel
                        )
                    }
                }
            } else {
                Text("Add more carbons to configure bonds")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
//        .padding(.horizontal)
    }
}



#Preview {
    BondConfigurationSection(viewModel: CompoundBuilderViewModel())
}
