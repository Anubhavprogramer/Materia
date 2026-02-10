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
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                CustomSlider(
                    value: Binding(
                        get: { Double(viewModel.carbonChainLength) },
                        set: { viewModel.updateCarbonChainLength(Int($0)) }
                    ),
                    in: 1...10,
                    step: 1,
                    label: "Chain Length",
                    tintColor: AppColors.accent,
                    trackHeight: 8
                )
                
                // Carbon chain visualization
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...viewModel.carbonChainLength, id: \.self) { carbon in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(AppColors.carbon)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("C\(carbon)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.carbonTextColor)
                                    )
                            }
                            
                            if carbon < viewModel.carbonChainLength {
                                Rectangle()
                                    .fill(AppColors.carbon.opacity(0.7))
                                    .frame(width: 20, height: 2)
                            }
                        }
                    }
//                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
//        .padding(.horizontal)
    }
}
