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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
//                Image(systemName: "bolt.fill")
//                    .foregroundColor(AppColors.primary)
                
                Text("Quick Start")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            Text("Tap an example to prefill the builder")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    QuickStartChip(
                        title: "Ethanol",
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
                        title: "Ethene",
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
                        title: "Ethyne",
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
                        title: "Acetic acid",
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
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.secondaryLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primaryMuted, lineWidth: 1)
                )
        )
    }
}
