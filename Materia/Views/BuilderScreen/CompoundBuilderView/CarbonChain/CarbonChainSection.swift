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
            Text(AppStrings.carbonChain)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    
                    HStack {
                        Text(AppStrings.carbonChainLength)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(viewModel.carbonChainLength)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.actionButtonText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.accent.opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.carbonChainLength) },
                            set: { viewModel.updateCarbonChainLength(Int($0)) }
                        ),
                        in: 1...Double(AppConstants.carbonAttomNumber),
                        step: 1
                    )
                    .tint(AppColors.accent) // 🔥 this replaces your custom tint
                }
                
                // Carbon chain visualization
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...viewModel.carbonChainLength, id: \.self) { carbon in
                            VStack(spacing: 4) {
                                ZStack {
                                    // Glass background
                                    Circle()
                                        .fill(.ultraThinMaterial) // ✅ real system glass
                                        .background(
                                            Circle()
                                                .fill(AppColors.carbon.opacity(0.25)) // tint behind glass
                                        )

                                    // Content
                                    Text("C\(carbon)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .frame(width: AppConstants.carbonAtomSize, height: AppConstants.carbonAtomSize)
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
        .padding(AppConstants.defaultPadding)
        .background(AppColors.Card)
        .cornerRadius(AppConstants.largeCornerRadius)
//        .padding(.horizontal)
    }
}
