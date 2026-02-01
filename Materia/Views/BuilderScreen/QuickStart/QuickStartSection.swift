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
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Quick Start")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text("Tap an example to prefill the builder")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    QuickStartChip(title: "Ethanol", subtitle: "C₂H₆O") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .alcohol))
                        onSelect(s)
                    }

                    QuickStartChip(title: "Ethene", subtitle: "C₂H₄") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.bonds.removeAll()
                        s.bonds.append(Bond(from: 1, to: 2, type: .double))
                        onSelect(s)
                    }

                    QuickStartChip(title: "Ethyne", subtitle: "C₂H₂") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.bonds.removeAll()
                        s.bonds.append(Bond(from: 1, to: 2, type: .triple))
                        onSelect(s)
                    }

                    QuickStartChip(title: "Acetic acid", subtitle: "C₂H₄O₂") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .carboxylicAcid))
                        onSelect(s)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}
