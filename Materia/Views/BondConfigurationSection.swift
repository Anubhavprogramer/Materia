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
        .padding(.horizontal)
    }
}

struct BondConfigRow: View {
    let fromCarbon: Int
    let toCarbon: Int
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        HStack {
            Text("C\(fromCarbon) — C\(toCarbon)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(BondType.allCases, id: \.self) { bondType in
                    Button(action: {
                        viewModel.addBond(from: fromCarbon, to: toCarbon, type: bondType)
                    }) {
                        Text(bondType.symbol)
                            .font(.title3)
                            .fontWeight(.medium)
                            .frame(width: 40, height: 32)
                            .background(
                                viewModel.getBondType(from: fromCarbon, to: toCarbon) == bondType
                                    ? Color.blue
                                    : Color(.systemGray5)
                            )
                            .foregroundColor(
                                viewModel.getBondType(from: fromCarbon, to: toCarbon) == bondType
                                    ? .white
                                    : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BondConfigurationSection(viewModel: CompoundBuilderViewModel())
}