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
        VStack(alignment: .leading, spacing: AppConstants.mediumGap) {
            Text(AppStrings.bondConfiguration)
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.carbonChainLength > 1 {
                VStack(spacing: AppConstants.mediumGap) {
                    ForEach(1..<viewModel.carbonChainLength, id: \.self) { carbon in
                        BondConfigRow(
                            fromCarbon: carbon,
                            toCarbon: carbon + 1,
                            viewModel: viewModel
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(AppStrings.noCarbonAtoms)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppConstants.defaultPadding)
        .background(AppColors.Card)
        .cornerRadius(AppConstants.largeCornerRadius)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



#Preview {
    BondConfigurationSection(viewModel: CompoundBuilderViewModel())
}
