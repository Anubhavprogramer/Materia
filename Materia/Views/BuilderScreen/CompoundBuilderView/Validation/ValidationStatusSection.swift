//
//  ValidationStatusSection.swift
//  Materia
//
//  Real-time structure validation display using CoreML
//

import SwiftUI

struct ValidationStatusSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    var load = "ValidationStatusSection"
    
    // Calculate combined confidence from basic validation and CoreML
    private var combinedConfidence: Double {
        let basicValidationScore: Double = viewModel.isValidStructure ? 1.0 : 0.0
        CommonFunctions.debugPrint(load: load, message: "\(String(describing: viewModel.validationResult?.confidence))")
        let coreMLConfidence = viewModel.validationResult?.confidence ?? 0.0
        
        // If basic validation passes, boost confidence based on CoreML result
        if viewModel.validationError == nil {
            // Average basic validation (100%) with CoreML confidence
            return (basicValidationScore + coreMLConfidence) / 2.0
        } else {
            return coreMLConfidence
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.structureAnalysis)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Basic Validation Status
                HStack {
                    Image(systemName: viewModel.isValidStructure ? AppIcons.checkmark : AppIcons.xmark)
                        .foregroundColor(viewModel.isValidStructure ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppStrings.basicValidation)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(viewModel.validationError ?? AppStrings.basicValidationMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // CoreML Validation Status
                HStack {
                    Group {
                        if viewModel.isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let result = viewModel.validationResult {
                            Image(systemName: result.isValid ? AppIcons.brain : AppIcons.exclamation )
                                .foregroundColor(result.isValid ? .blue : .orange)
                        } else {
                            Image(systemName: AppIcons.brain)
                                .foregroundColor(.gray)
                        }
                    }
                    .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(AppStrings.aiAnalysis)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let result = viewModel.validationResult {
                                Text("\(Int(result.confidence * 100))%")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(validationStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Detailed Analysis (if available)
                if let result = viewModel.validationResult, !viewModel.isValidating {
                    VStack(spacing: 12) {
                        Divider()
                        
                        HStack {
                            Text(AppStrings.validationDetails)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        // Combined Confidence Bar
                        VStack(spacing: 8) {
                            HStack {
                                Text(result.isValid ? AppStrings.overallConfidence : AppStrings.structureIssues)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(result.isValid ? .green : .red)
                                
                                Spacer()
                                
                                Text("\(Int(combinedConfidence * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(result.isValid ? .green : .red)
                            }
                            
                            ProgressView(value: combinedConfidence)
                                .progressViewStyle(LinearProgressViewStyle(tint: result.isValid ? .green : .red))
                                .frame(height: 6)
                        }
                        
                        // Confidence Breakdown
                        VStack(spacing: 10) {
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: AppIcons.checkmark)
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Text(AppStrings.basicRules)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text(AppStrings.basicRulesConfidence)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    HStack {
                                        Text(AppStrings.aiAnalysis)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: AppIcons.brain)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("\(Int(result.confidence * 100))%")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private var validationStatusText: String {
        if viewModel.isValidating {
            return AppStrings.aiAnalysisInProgress
        } else if let result = viewModel.validationResult {
            return result.validationMessage ?? (result.isValid ? AppStrings.aiAnalysisComplete : AppStrings.aiAnalysisIssues)
        } else {
            return AppStrings.aiAnalysisWaiting
        }
    }
}

#Preview {
    ValidationStatusSection(viewModel: CompoundBuilderViewModel())
}
