//
//  QuickStartSection.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//

import SwiftUI

struct QuickStartSection: View {
    let onSelect: (ChemicalStructure) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                
            Text(AppStrings.quickStart)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(AppStrings.quickStartTemplates)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppConstants.largeGap) {
                    QuickStartChip(
                        title: AppStrings.ethanol,
                        structure: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .alcohol))
                            return s
                        }(),
                        action: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .alcohol))
                            onSelect(s)
                        }
                    )

                    QuickStartChip(
                        title: AppStrings.ethene,
                        structure: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.bonds.removeAll()
                            s.bonds.append(Bond(from: 1, to: 2, type: .double))
                            return s
                        }(),
                        action: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.bonds.removeAll()
                            s.bonds.append(Bond(from: 1, to: 2, type: .double))
                            onSelect(s)
                        }
                    )

                    QuickStartChip(
                        title: AppStrings.ethene,
                        structure: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.bonds.removeAll()
                            s.bonds.append(Bond(from: 1, to: 2, type: .triple))
                            return s
                        }(),
                        action: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.bonds.removeAll()
                            s.bonds.append(Bond(from: 1, to: 2, type: .triple))
                            onSelect(s)
                        }
                    )

                    QuickStartChip(
                        title: AppStrings.aceticAcid,
                        structure: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .carboxylicAcid))
                            return s
                        }(),
                        action: {
                            var s = ChemicalStructure(carbonChainLength: 2)
                            s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .carboxylicAcid))
                            onSelect(s)
                        }
                    )
                }
            }
        }
    }
}
