//
//  CarbonChainSection.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct CarbonChainSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Carbon Chain")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Length: \(viewModel.carbonChainLength) carbons")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.carbonChainLength) },
                        set: { viewModel.updateCarbonChainLength(Int($0)) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .tint(.blue)
                
                // Carbon chain visualization
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...viewModel.carbonChainLength, id: \.self) { carbon in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("C\(carbon)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    )
                            }
                            
                            if carbon < viewModel.carbonChainLength {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 20, height: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
