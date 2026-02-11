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
            Text("Structure Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Basic Validation Status
                HStack {
                    Image(systemName: viewModel.isValidStructure ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(viewModel.isValidStructure ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Basic Validation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(viewModel.validationError ?? "Structure follows basic chemistry rules")
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
                            Image(systemName: result.isValid ? "brain.head.profile" : "exclamationmark.triangle.fill")
                                .foregroundColor(result.isValid ? .blue : .orange)
                        } else {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.gray)
                        }
                    }
                    .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("AI Analysis")
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
                            Text("Validation Details")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        // Combined Confidence Bar
                        VStack(spacing: 8) {
                            HStack {
                                Text(result.isValid ? "Overall Confidence" : "Structure Issues")
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
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Text("Basic Rules")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("100%")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    HStack {
                                        Text("AI Analysis")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "brain.head.profile")
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
//        .padding(.horizontal)
    }
    private var validationStatusText: String {
        if viewModel.isValidating {
            return "Analyzing structure with AI models..."
        } else if let result = viewModel.validationResult {
            return result.validationMessage ?? (result.isValid ? "Structure appears chemically feasible" : "Structure may have issues")
        } else {
            return "Waiting for structure analysis"
        }
    }
}

#Preview {
    ValidationStatusSection(viewModel: CompoundBuilderViewModel())
}
