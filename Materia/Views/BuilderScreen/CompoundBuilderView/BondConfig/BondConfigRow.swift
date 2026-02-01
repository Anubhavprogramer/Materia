//
//  BondConfigRow.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

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
